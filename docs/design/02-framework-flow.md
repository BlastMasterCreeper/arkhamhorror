# 02 — 框架流程引擎 (FrameworkFlowEngine)

> **依赖**：[01-game-state-zones.md](01-game-state-zones.md)  
> **规则来源**：Grimoire III. Timing and Gameplay (pp.27–29), VI. Scenario Setup (p.31)

---

## 1. 目标

实现 Grimoire 定义的 **Framework Event** 强制步骤树与 **Player Window** 插入点。本引擎是游戏中**唯一**允许推进回合结构的组件。

---

## 2. 职责边界

| 负责 | 不负责 |
|---|---|
| Setup 1–14、Round 四阶段、Skill Test ST.1–ST.8 的**框架壳** | 检定内部数值计算（SkillTestEngine） |
| Player Window 开启/关闭 | 玩家能力具体效果 |
| `skip_mythos_round_1` | 卡牌脚本注册 |
| Scenario Resolution 触发 `(→R#)` | Campaign Log 持久化 UI |

---

## 3. FrameworkStep 枚举（完整树）

### 3.1 Setup Phase

```gdscript
enum FrameworkStep {
    # --- Setup (Grimoire VI) ---
    SETUP_01_CHOOSE_INVESTIGATORS,
    SETUP_02_APPLY_TRAUMA,
    SETUP_03_CHOOSE_LEAD_INVESTIGATOR,
    SETUP_04_SHUFFLE_INVESTIGATOR_DECKS,
    SETUP_05_ASSEMBLE_TOKEN_POOL,
    SETUP_06_ASSEMBLE_CHAOS_BAG,
    SETUP_07_STARTING_RESOURCES,
    SETUP_08_OPENING_HANDS_MULLIGAN,
    SETUP_09_READ_SCENARIO_INTRO,
    SETUP_10_SCENARIO_SETUP,
    SETUP_11_SET_AGENDA_DECK,
    SETUP_12_SET_ACT_DECK,
    SETUP_13_PLACE_SCENARIO_REFERENCE,
    SETUP_14_GAME_BEGINS_ABOUT,          # Resolve "When the game begins"

    # --- Round: Mythos (1.x) ---
    MYTHOS_1_1_PHASE_BEGINS,            # = new round begins
    MYTHOS_1_2_PLACE_DOOM,
    MYTHOS_1_3_CHECK_DOOM_THRESHOLD,
    MYTHOS_1_4_DRAW_ENCOUNTER_EACH,     # per investigator, player order
    MYTHOS_1_5_PHASE_ENDS,

    # --- Round: Investigation (2.x) ---
    INV_2_1_PHASE_BEGINS,
    INV_2_2_TURN_BEGINS,                # choose next investigator
    INV_2_2_1_TAKE_ACTION,              # loop entry
    INV_2_2_2_TURN_ENDS,
    INV_2_3_PHASE_ENDS,

    # --- Round: Enemy (3.x) ---
    ENEMY_3_1_PHASE_BEGINS,
    ENEMY_3_2_HUNTER_PATROL_MOVE,
    ENEMY_3_3_ENGAGED_ATTACKS,          # per investigator player order
    ENEMY_3_4_PHASE_ENDS,

    # --- Round: Upkeep (4.x) ---
    UPKEEP_4_1_PHASE_BEGINS,
    UPKEEP_4_2_FLIP_MINI_CARDS,
    UPKEEP_4_3_READY_EXHAUSTED,
    UPKEEP_4_4_DRAW_AND_RESOURCE,
    UPKEEP_4_5_CHECK_HAND_SIZE,
    UPKEEP_4_6_PHASE_ENDS,              # = round ends

    # --- Terminal ---
    SCENARIO_RESOLUTION,
    GAME_OVER,
}
```

### 3.2 Player Window 映射

Player Window **不是** FrameworkStep，而是嵌套在步骤间的 `WindowHandle`：

| Window ID | 位置 |
|---|---|
| `PW_AFTER_MYTHOS_1_1` | 1.1 之后 |
| `PW_AFTER_MYTHOS_1_4_EACH` | 每位调查员抽遭遇后 |
| `PW_BEFORE_MYTHOS_1_5` | 1.5 之前 |
| `PW_AFTER_INV_2_1` | 2.1 之后 |
| `PW_BEFORE_INV_2_2_1` | 每次行动前 |
| `PW_AFTER_INV_2_2_1` | 每次行动后 |
| `PW_BEFORE_INV_2_2_2` | 回合结束前 |
| `PW_AFTER_ENEMY_3_2` | Hunter 移动后 |
| `PW_DURING_ENEMY_3_3` | 每位调查员攻击结算间 |
| `PW_AFTER_UPKEEP_4_3` | Ready 后、抽牌前 |
| `PW_SKILL_TEST_AFTER_COMMIT`, `PW_SKILL_TEST_AFTER_REVEAL` | 检定 ST.2 commit 后；ST.3–ST.4 揭示链**全部完成**后（非 ST.3 后；递归 reveal another 中无 Window） |

```gdscript
enum PlayerWindow {
    PW_MYTHOS_AFTER_BEGIN,
    PW_MYTHOS_AFTER_ENCOUNTER_DRAW,
    PW_MYTHOS_BEFORE_END,
    PW_INV_AFTER_PHASE_BEGIN,
    PW_INV_BEFORE_ACTION,
    PW_INV_AFTER_ACTION,
    PW_INV_BEFORE_TURN_END,
    PW_ENEMY_AFTER_MOVE,
    PW_ENEMY_BETWEEN_ATTACKS,
    PW_UPKEEP_AFTER_READY,
    PW_SKILL_TEST_AFTER_COMMIT,
    PW_SKILL_TEST_AFTER_REVEAL,
}
```

---

## 4. FrameworkFlowEngine API

```gdscript
class FrameworkFlowEngine:
    signal step_entered(step: FrameworkStep)
    signal step_exited(step: FrameworkStep)
    signal player_window_opened(window: PlayerWindow)
    signal player_window_closed(window: PlayerWindow)
    signal scenario_resolution(reached: int)  # R# or -1 for none

    var current_step: FrameworkStep
    var round_number: int
    var skip_mythos: bool                 # true when round_number == 1
    var investigators_acted_this_phase: Array[StringName]
    var pending_action_loop: bool

    func start_setup() -> void
    func advance() -> void                # 内部：下一步 framework
    func open_player_window(w: PlayerWindow) -> void
    func close_player_window_and_continue() -> void

    # 外部请求（由 ActionSystem 等调用）
    func request_investigator_action(action: ActionRequest) -> Result
    func request_advance_act() -> Result
    func request_scenario_end(resolution: int) -> Result
```

### 4.1 推进规则

1. 进入 FrameworkStep → `TimingBus.process_forced(step)` → 执行步骤副作用 → 若有 Player Window 则**暂停** `advance()`。
2. Player Window 内：玩家可发起 Free triggered abilities；**无人响应时自动关闭**（可配置超时，已裁决 OQ-02-04），然后继续。
3. **禁止**在 Window 外发起需 Player Window 的 Free 能力（除非 Fast 卡文本另指定）。

```gdscript
# RulesConfig.player_window_auto_close_ms: int  # 0 = 立即；>0 = 超时后关闭
func close_player_window_if_idle() -> void:
    if not has_pending_free_abilities() and not has_player_input():
        close_player_window_and_continue()
```

### 4.2 首回合跳过 Mythos

```gdscript
func begin_round() -> void:
    round_number += 1
    if round_number == 1:
        skip_mythos = true
        goto(INV_2_1_PHASE_BEGINS)
    else:
        goto(MYTHOS_1_1_PHASE_BEGINS)
```

---

## 5. 各阶段步骤副作用（摘要）

### 5.1 Mythos 1.2–1.3

- 1.2：current agenda +1 doom
- 1.3：若 `doom_in_play >= agenda_threshold` → `ScenarioSystem.advance_agenda()`

**注意**：除非卡牌另说，议程**仅**在 1.3 推进（Grimoire Doom）。

### 5.2 Mythos 1.4

按 player order，每位调查员：

1. Draw encounter
2. Check Peril
3. Resolve Revelation
4. Spawn enemy / discard treachery
5. Surge → 递归从 step 1

委托 `ScenarioSystem.resolve_encounter_draw(inv)`。

### 5.3 Investigation 2.2.x

- 2.2：调查员自选顺序；`actions_remaining = 3 + bonus - penalty`
- 2.2.1：`ActionSystem.execute`；若 actions > 0 且玩家选择继续 → 回到 `PW_BEFORE_ACTION`
- 2.2.2：forfeit 剩余 actions；标记 turn 结束

### 5.4 Enemy 3.2–3.3

- 3.2：`EnemySystem.hunter_patrol_move()`
- 3.3：player order；每位调查员 resolve 其 engaged enemies 攻击 → exhaust attacker

### 5.5 Upkeep 4.3–4.5

- 4.3：ready all exhausted；**同时** unengaged enemy 与同地点 investigator auto-engage
- 4.4：player order draw 1 + gain 1 resource（先全部 draw 再全部 gain，Grimoire 4.4）
- 4.5：hand size > 8 → discard to 8

---

## 6. Setup 14 步详解

| Step | 动作 | Player Window |
|---|---|---|
| 1 | 选调查员，各不同 | 无 |
| 2 | 战役 trauma → damage/horror on investigator | 无 |
| 3 | 选 Lead Investigator | 无 |
| 4 | 洗牌 investigator deck | 无 |
| 5 | 摆放 token pool | 无 |
| 6 | 组装 chaos bag（战役延续则用旧 bag） | 无 |
| 7 | 各 gain 5 resources | 无 |
| 8 | draw 5, mulligan once；weakness 重抽 | 无 |
| 9 | 读 scenario intro；**可能回溯** step 6/7/8（见 §6.1） | 无 |
| 10 | campaign guide scenario setup（**一般固定**，不因 intro 回溯） | 无 |
| 11–12 | agenda/act deck | 无 |
| 13 | scenario reference | 无 |
| 14 | resolve "When the game begins"（**setup 显现/涌动仅在此结算**，见 10 §2.1） | 无 |

Setup 期间（步骤 1–13）**无** action window，**不结算 encounter 显现**（OQ-10-01）；步骤 14 可触发 setup 积攒的显现与 Surge。

### 6.1 Setup 步骤重入（已裁决 OQ-02-01）

Grimoire：step 9（或 setup 期间卡牌/战役效果）若推翻先前步骤，须**重新执行**被影响的步骤。

**资深玩家裁定**：

| 可回溯步骤 | 典型原因 | 频率 |
|---|---|---|
| **6** 混沌袋 | 卡牌效果、战役设置改变 bag 组成 | 有，需支持 |
| **7** 初始资源 | 卡牌效果、战役设置改变起始 resource | 有，需支持 |
| **8** 起手牌 | intro 要求重抽、mulligan 相关变更 | 有（Grimoire 明示） |
| **10** scenario setup | 地点/encounter 布局 | **一般固定**，不因 intro 回溯 |

**实现**：**campaign/scenario 数据驱动** 的通用 `rewind_to(step)`，v1 **不** hardcode 仅 step 8。

```gdscript
## CampaignScript / ScenarioScript 在 intro 或 setup 效果中声明
class SetupRewindRequest:
    var targets: Array[FrameworkStep]  # 如 [SETUP_06, SETUP_07]

func setup_09_read_intro() -> void:
    var effects := campaign.apply_intro_effects()
    for step in effects.rewind_targets:
        rerun_setup_step(step)   # 按 Grimoire 重跑该步及依赖状态
    advance()
```

**触发来源**：step 9 intro 文本、setup 期间卡牌 forced/revelation（若 timing 允许）、战役 guide 的 campaign setup 指令——不限于 step 9。

**step 10**：按 guide 固定执行；若未来扩展包有例外，仍走 `rewind_to` 数据声明，不作 v1 默认路径。

---

## 7. Act/Agenda Flip（已裁决 OQ-02-02）

### 7.1 Flip 流程

```
1. 清除 advancing act/agenda 上 token
2. Flip a → b；a 面视为 **离场（out of play）**
3. 结算 b 面指令
4. advancing 卡 removed from game；sequential next 成为 current
```

**Act 与 Agenda flip 适用相同规则。**

### 7.2 a 面能力在 b 面结算期间（资深玩家裁定）

| 类型 | b 面结算期间 |
|---|---|
| Constant / Forced / Reaction / Action 等 **a 面能力** | **不触发、不生效**（a 面已不在场） |
| a 面能力此前创建的 **Delayed 延时效果** | **继续生效**，不因翻面消失 |
| b 面自身文本 | 正常结算 |

依据：卡牌能力默认仅在与 **in-play** 交互时生效（Grimoire Ability）；flip 后 a 面不在场，故其能力不可触发。Grimoire 写 a 面 constant/forced「remain in effect」在电子化中落实为：**已建立的 Delayed 效果延续**；而非 a 面能力在 b 结算期间仍可被触发。

```gdscript
class ActAgendaFlipContext:
    var advancing_card: EntityId
    var resolving_side_b: bool

    func on_flip_to_b() -> void:
        # a 面 unregister 全部能力；card 暂处 flip 过渡态，不算 in-play
        ability_registry.unregister_all(advancing_card)
        resolving_side_b = true

    func on_flip_complete() -> void:
        resolving_side_b = false
        # delayed_effects 由 DelayedEffectRegistry 独立追踪，不在此清除
```

### 7.3 测试要点

| 场景 | 预期 |
|---|---|
| Act 2a [reaction]「After enemy spawns…」，2b spawn 敌人 | **不**触发 2a Reaction |
| Act 1a Forced 创建的 Delayed「下回合开始时…」 | flip 后 Delayed **仍**在指定 timing 触发 |
| Agenda flip | 同 Act |

---

## 8. Scenario Resolution

触发条件：

- Act/Agenda/Encounter 文本 `(→R#)`
- 全员 eliminated/resigned → `resolution = NO_RESOLUTION`（campaign guide 条目）

```gdscript
func trigger_resolution(r: int) -> void:
    current_step = FrameworkStep.SCENARIO_RESOLUTION
    scenario_resolution.emit(r)
    # 不再 advance 框架；转入 Campaign 结算
```

---

## 9. 与其他子系统接口

```
FrameworkFlowEngine
  ├─► ActionSystem        (INV_2_2_1)
  ├─► SkillTestEngine     (嵌套于 Action/Encounter)
  ├─► ScenarioSystem      (MYTHOS_1_4, agenda advance)
  ├─► EnemySystem         (ENEMY_3_2, 3_3)
  ├─► InvestigatorSystem  (UPKEEP 4.4–4.5)
  └─► TimingBus           (每 step enter/exit)
```

---

## 10. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| F-01 | Round 1 开始 | 跳过 MYTHOS，直接 INV_2_1 |
| F-02 | Round 2 | MYTHOS 1.1–1.5 完整 |
| F-03 | 调查员 3 actions 用完 | 自动 2.2.2 |
| F-04 | 调查员 0 action 结束 turn | 合法 |
| F-05 | Agenda doom threshold 在 1.3 | advance + 清 doom |
| F-06 | Setup 9 触发重抽 opening hand | 回到 step 8 |
| F-07 | `(→R2)` on act flip | SCENARIO_RESOLUTION(2) |

---

## 11. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-02-03 | P1 | `INV_2_2` 选顺序：电子化是否每轮都 UI 选，还是允许「固定顺时针」可选规则？ |
| OQ-02-05 | P2 | Framework 与嵌套 Skill Test 的 EventRecord 层级如何缩进展示？ |
| OQ-02-06 | P1 | 全员淘汰时是否立即 SCENARIO_RESOLUTION 还是完成当前 Framework 步？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-02-01 | 数据驱动 `rewind_to(step)`；可回溯 **6（混沌袋）、7（资源）、8（起手牌）**；**10（scenario setup）一般固定**。卡牌效果与战役设置均可触发重入。 | 2026-05-25 |
| OQ-02-02 | Flip 结算 b 面时 a 面**不在场**，a 面一切能力**不可触发**（含 Reaction）。**例外**：a 面已创建的 **Delayed 延时效果**继续生效。Act/Agenda 同则。见 §7。 | 2026-05-25 |
| OQ-02-04 | Player Window **无人响应时自动关闭**（`player_window_auto_close_ms` 可配置）。见 §4.1。 | 2026-05-25 |

---

## 12. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-02-01 裁决：Setup rewind 6/7/8，数据驱动 |
| 2026-05-25 | v0.3 | OQ-02-02 裁决：Flip 时 a 面不在场；Delayed 延续 |
