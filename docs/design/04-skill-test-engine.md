# 04 — 技能检定引擎 (SkillTestEngine)

> **依赖**：[02-framework-flow.md](02-framework-flow.md), [05-chaos-bag.md](05-chaos-bag.md), [06-ability-initiation.md](06-ability-initiation.md), [07-effect-resolution.md](07-effect-resolution.md), [15-timing-entry-catalog.md](15-timing-entry-catalog.md)  
> **规则来源**：Grimoire IV. Skill Test Timing (p.30)

---

## 1. 目标

实现 ST.1–ST.8 完整检定流程，支持 commit、chaos 揭示、嵌套检定、自动成功/失败。步骤 ID 使用 **独立 `SkillTestStep` 枚举**（不并入 `FrameworkStep`，已裁决 OQ-IDX-01）。

```gdscript
enum SkillTestStep {
    ST_1_BEGIN, ST_2_COMMIT, ST_3_REVEAL, ST_4_SYMBOL,
    ST_5_CALCULATE, ST_6_RESOLVE_RESULT, ST_7_APPLY, ST_8_END,
}
```

每步推进写入 `EventRecord`（`kind = "skill_test_step"`）。

---

## 2. SkillTestContext

```gdscript
enum SkillType { WILLPOWER, INTELLECT, COMBAT, AGILITY }

class SkillTestContext:
    var id: StringName
    var performing_investigator: StringName
    var skill: SkillType                    # ST.1 确定
    var difficulty: int
    var source: EffectSource                #  initiating card/action
    var committed: Array[CommittedCard]
    var revealed_tokens: Array[ChaosToken]
    var modifier_breakdown: Array[ModifierEntry]
    var success: bool
    var fail_by: int                          # ST.6 计算；ST.7 条件 fail 效果读取
    var nested_depth: int
    var on_success: Callable                  # ST.7 callbacks
    var on_fail: Callable
    var peril: bool                           # 镜像 frame.peril；L4 走 RestrictionEvaluator（§4）
    var auto_fail: bool
    var auto_success: bool
    var encounter_resolution_id: StringName   # 非空 = 仍在某次 encounter 结算帧内
```

---

## 3. ST.1 – ST.8 逐步 API

```gdscript
class SkillTestEngine:
    func begin_test(ctx: SkillTestContext) -> SkillTestHandle
    func step_commit(handle, cards: Array[CommittedCard]) -> Result      # ST.2
    func step_reveal_token(handle) -> ChaosToken                        # ST.3
    func step_apply_symbol_effects(handle) -> Result                     # ST.4
    func step_calculate_modified_value(handle) -> int                    # ST.5
    func step_determine_success(handle) -> bool                          # ST.6
    func step_apply_results(handle) -> Result                            # ST.7
    func step_end(handle) -> void                                        # ST.8

    func run_full_test(ctx: SkillTestContext) -> SkillTestResult         # 编排上述步骤
```

### 3.1 ST.1 Determine skill

- 基础行动固定 skill；Fight/Evade 等可在 `([combat] or [agility])` 中由 performing investigator 择一
- 发起 `TimingBus`: `skill_test_begins`
- Push `GameContext.skill_test_stack`

### 3.2 ST.2 Commit

- Performing investigator：任意张 eligible（matching icon 或 wild）
- 同地点其他 investigator：**1 张**（险境时 **Cannot**，见 §4）
- 每张 matching icon +1 skill value
- Max committed per test 限制（如 Perception max 1）
- 不付 resource cost
- **Player Window**：`PW_SKILL_TEST_AFTER_COMMIT`（ST.2 完成后、进入 ST.3 之前）

### 3.3 ST.3 Reveal

- 从 chaos bag 随机取 1 token
- **无 Player Window**（见 [00-framework-step-index.md](00-framework-step-index.md)）

### 3.4 ST.4 Symbol effects

- Skull/Cultist/Tablet/Elder Thing → ScenarioReference 能力
- Elder Sign → investigator 卡 printed **Elder Sign** 能力（揭示 [elder_sign] token 时）
- Campaign symbol → campaign guide
- Auto-fail → `auto_fail = true`
- 「Reveal another token」→ **仅递归 ST.3 → ST.4**；**不**回到 ST.2，**不**开启任何 Player Window（已裁决 OQ-04-01）
- 全部 token 揭示且 symbol 效果结算完毕后 → **Player Window**：`PW_SKILL_TEST_AFTER_REVEAL`（进入 ST.5 之前，**仅一次**）

```gdscript
func resolve_reveal_chain(handle: SkillTestHandle) -> void:
    while true:
        step_reveal_token(handle)           # ST.3 — 无 Window
        var again := step_apply_symbol_effects(handle)  # ST.4
        if not again:                       # 无 "Reveal another token"
            break
    open_player_window(PW_SKILL_TEST_AFTER_REVEAL)  # 整链结束后一次
    step_calculate_modified_value(handle)   # ST.5
```

### 3.5 ST.5 Modified skill value

```
base = investigator.get_skill(skill)
+ sum(committed icons)
+ sum(active modifiers from cards)
+ sum(chaos token modifiers)
→ apply modifier rules（additive before double/halve, floor at 0 functional）
```

### 3.6 ST.6 Success / Failure

- `modified >= difficulty` → success
- Auto-success：difficulty 视为 0
- Auto-fail：modified 视为 0，仍 fail even if >= difficulty
- 若 fail：计算 `fail_by = difficulty - modified`（供 ST.7 条件效果使用；**不在 ST.6 执行 fail by 后果**）

### 3.7 ST.7 Apply results

- 发起方文本 success/fail 后果
- **Fail by 条件效果**（如 Spreading Flames Skull「fail by 2+ draw Fire!」）作为 **失败效果的一部分** 在此结算（已裁决 OQ-05-03）
- Committed skill 卡「If this test is successful...」
- 调查员选顺序（多个 ST.7 结果）

### 3.8 ST.8 End

- Committed cards → discard
- Revealed tokens → return to bag
- Pop skill_test_stack
- `skill_test_ends`

---

## 4. Peril（险境 · 持续 Cannot）

> **规则来源**：Grimoire *Peril*、Framework 1.4 step 2；[15 §17 E3](15-timing-entry-catalog.md)、[15 §4.0.5.2](15-timing-entry-catalog.md)。  
> **已裁决**：OQ-04-02 — peril RESTRICTION 生命周期 = **`WHILE_DRAWN_CARD_RESOLVING(card_id)`**；**不跨 Surge**（G4 完 Unregister，G5 再抽前）。

### 4.1 规则语义

Grimoire *Peril*（*cannot* 措辞）：

- **drawer** **cannot confer**；**其他调查员** **cannot** play / trigger / commit 到 drawer 的 skill test(s)；
- 约束持续于 **「the peril encounter is resolving」** — 引擎 = **该张 drawn 卡 G2–G4 期间** RESTRICTION 在 Store 中 active。

| 属性 | 说明 |
|---|---|
| **触发** | **ENCOUNTER_CARD_DRAWN** timing · priority **100** · 卡带 peril 关键词 |
| **生命周期** | **`WHILE_DRAWN_CARD_RESOLVING(card_id)`** — **G4（spawn/discard）完成时 Unregister** |
| **不跨 Surge** | G5 Surge 在 **上一张 G4 后**；下一张 G1 = **新** ENCOUNTER_CARD_DRAWN，**无** 上一张 peril |
| **performing** | 该张卡 resolve 期间 skill test performing = drawer |

**不是**：跨 Surge 帧级 sticky、`WHILE_ENCOUNTER_FRAME` 级 peril Register。

### 4.2 引擎定位：**RESTRICTION Cannot**，非竞争

对齐 [07-effect-resolution §3.2](07-effect-resolution.md) 冲突链 **第 0 步**；险境与卡面 *cannot* **同路径** — `RegistrationStore` + `RestrictionEvaluator`（[06 §7](06-registration-buff-model.md)）。

```text
同一时刻有玩家/能力想行动
  0. RESTRICTION Cannot（含 E3 险境 Register）→ **不得发生**
  1. 同时点竞争（Replacement / Forced / Triggered tier …）
  …
```

| 对比 | Peril（译后） | Replacement 竞争 | Silver Rule |
|---|---|---|---|
| 机制类 | **RESTRICTION**（E3 Register） | 同时点 **替换竞争** | 文本不可调和 |
| 能否 countermand | **否**（Grimoire *Cannot*） | 最后 initiate 赢 | 队长 / 遭遇优先 |
| drawer 打出 asset/event | **允许** | — | — |
| 队友 [fast] 打出 asset/event | **禁止**（`FORBID_PLAY`） | 不进入竞争 | — |
| 队友 commit skill 到 drawer 检定 | **禁止**（`FORBID_COMMIT_TO_TEST`） | — | — |

**Invariant**：任何卡牌能力 **不得** countermand 已挂 RESTRICTION；无需 Silver Rule / Grim Rule。

### 4.3 EncounterResolutionFrame 与 per-card peril

`EncounterResolutionFrame` 保留 **drawer / surge_depth / cards_resolved**（诊断、嵌套检定 bind）。**peril 裁决只看 RegistrationStore**（`WHILE_DRAWN_CARD_RESOLVING`），**不** 用帧级 `peril` 粘性跨 Surge。

```gdscript
class EncounterResolutionFrame:
    var id: StringName
    var drawer_id: StringName
    var cards_resolved: Array[StringName]
    var surge_depth: int = 0
    # 已删除 frame.peril 粘性 — 见 PERIL-04 测试迁移
```

```text
push frame (E0) — 可跨 Surge 圈（仅 drawer 上下文）
  per card: ENCOUNTER_CARD_DRAWN → priority 100 Register peril (card_id)
            → … 90 revelation → 80 G4 → Unregister peril(card_id)
            → 75 AFTER → 70 surge?
pop frame (E7)
```

### 4.4 E3 · peril priority 100 · Register RESTRICTION

> **术语**：**子时点** = 遭遇结算 WHEN 内的 commit 边界；**Register 结算** = G2 Register 写入 RegistrationStore。

**与显现的区别**：E3 nest **Register RESTRICTION**（peril 检测子时点触发）；E4 nest Forced。见 [15 §4.0.5.1–§4.0.5.2](15-timing-entry-catalog.md)。

**禁止** `PerilPolicy` / 平行 cannot 分支。E3 = **nest** 内 `composition.execute(register_template)`：

```gdscript
## RegistrationTemplate.peril_drawn_card(drawer_id, card_id)
## Lifetime: WHILE_DRAWN_CARD_RESOLVING(card_id) — G4 完 Unregister
## Buffs: FORBID_PLAY / FORBID_TRIGGER / FORBID_COMMIT_TO_TEST（actor != drawer_id）

class EncounterPeril:
    static func apply_peril_register(game_ctx, drawer_id, card_id, has_peril_keyword) -> void
    static func unregister_for_card(game_ctx, card_id) -> void   # priority 80 后
```

`AbilityUnitRef.from_framework(&"seq.draw.encounter")` 作 provenance（E3 内联步）。

### 4.5 禁止清单（actor × action）

| Actor | Play asset/event | Trigger 能力 | Commit skill 到 drawer 检定 | Confer |
|---|---|---|---|---|
| **drawer** | ✓ | ✓ | ✓（performing） | ✗ 规则（Presentation） |
| **其他调查员** | **Cannot** | **Cannot** | **Cannot** | — |
| **Forced（他人控）** | — | **Cannot** initiate | — | — |
| **Encounter Forced** | — | 引擎 E4 自动 resolve | — | — |

Player Window 仍可出现；COLLECT / Initiation 在 **L4** 经 `RestrictionEvaluator` 使他人能力 **不进 eligible**。

### 4.6 拦截点（统一 `RestrictionEvaluator`）

完整 **Intent × 入口** 主表见 [06-registration-buff-model §16.4](06-registration-buff-model.md#164-restriction--intent--入口主表)。下表为 skill test / peril 相关子集：

| 入口 | 检查时机 | Intent |
|---|---|---|
| **EligibilityPipeline L4** | COLLECT / PRE_INITIATE | `PLAY` / `TRIGGER` |
| **ActionSystem.play_asset / play_event** | 付 cost 前 | `PLAY` |
| **SkillTestEngine.commit_card** | commit 前 | `COMMIT_TO_TEST` |
| **CompositionExecutor draw atom** | execute 前 | `DRAW` |
| **EffectResolutionGraph** step 4 | submit 前 | 按 op 映射 Intent（§16.4.3） |

```gdscript
var reason := RestrictionEvaluator.block_reason(
    RestrictionEvaluator.Intent.COMMIT_TO_TEST,
    actor_id, game_ctx.registrations, skill_test)
if reason != &"":
    return fail(reason)   # L4 / commit / play 等同语义
```

### 4.7 SkillTestContext.peril 与 frame 同步

- `begin_test` → `EncounterPeril.sync_test_context_from_frame`：`ctx.peril = frame.peril`（**镜像**，供 Condition）。
- **commit 裁决**只查 `RestrictionEvaluator`，**禁止**仅读 `ctx.peril`。
- 嵌套检定：自 frame 复制 `peril` 镜像；RESTRICTION 仍 active 直至 frame pop。

### 4.8 测试

| ID | 场景 | 预期 |
|---|---|---|
| ST-06 / PERIL-01 | E3 Register 后队友 commit | `peril_no_assist` |
| PERIL-02 | 队友 play asset | `restriction_forbid_play`（待接 ActionSystem） |
| PERIL-03 | 队友 [reaction] | L4 `FORBID_TRIGGER` fail |
| PERIL-04 | Surge 第二圈无 peril 关键词 | **无** 上一张 RESTRICTION；新 card_id 单独 Register |
| PERIL-05 | G4 完、G5 Surge 前 | peril Unregister；他人 commit **允许** |
| PERIL-06 | drawer play / trigger | 允许 |

---

## 4.9 RulesMemory：遭遇帧栈

```gdscript
func push_encounter_frame(frame: EncounterResolutionFrame) -> void
func pop_encounter_frame() -> EncounterResolutionFrame
func peek_encounter_frame() -> EncounterResolutionFrame
func top_encounter_frame_if_peril() -> EncounterResolutionFrame
```

| 时机 | 调用 |
|---|---|
| `seq.draw.encounter` RESOLVE 开头 | `push_encounter_frame(...)` |
| E3 | `EncounterPeril.apply_e3_check(game_ctx, frame, has_peril)` |
| E7 | `GameContext.pop_encounter_resolution_frame()` → pop + Unregister |

---

## 4.10 ApplicationContext 与 tags

`top_encounter_frame_if_peril()` 非空时注入 `peril_active`、`referents["encounter_drawer_id"]` — **仅 L3 / UI**；L4 **仍走 RestrictionEvaluator**。

---

## 4.11 E3 · 内联接线（resolve_card_body）

```text
seq.draw.encounter → resolve_card_body (内联)
  …
  EncounterPeril.apply_e3_check(game_ctx, memory.peek_encounter_frame(), has_keyword(peril))
  …
```

| 文件 | 职责 |
|---|---|
| `rules/encounter/encounter_peril.gd` | E3 Register / detach / test sync |
| `rules/registration/restriction_evaluator.gd` | 统一 Cannot 裁决 |
| `rules/registration/registration_template.gd` | `peril_encounter_frame` |
| `core/timing/encounter_resolution_frame.gd` | 帧 + peril 粘性镜像 |
| `rules/skill_test/skill_test_engine.gd` | commit → RestrictionEvaluator |

**待接**：ActionSystem play、Eligibility L4、EffectGraph step 4（同一 evaluator）。

---

## 5. Commit 规则详表

| 规则 | 实现 |
|---|---|
| Wild [wild] | 匹配任意 skill |
| 无 matching icon | 不可 commit |
| Peril | 仅 performing 可 commit（**Cannot**，§4） |
| Max N committed | 按 title 计数 |
| Commit 归属 | **`SkillTestContext.committed` 列表**；卡 **zone 仍为 HAND** 直至 ST.8 discard（已裁决 OQ-01-03）。不用 LIMBO |
| LIMBO | 仅 **Event/Treachery 显现结算中** 等场景；与 committed skill **无关** |

---

## 6. 嵌套检定（已裁决 OQ-04-02）

当 ST.4 / ST.7 文本发起新检定时：

1. **不**在父检定中途插入；**入队**，待父检定 **ST.8 完成**后执行（父检定 ST.5–ST.7 **不等待**子检定，见 OQ-04-03）
2. 子检定独立 committed / tokens / difficulty
3. 子检定 `peril` 自 **EncounterResolutionFrame** 复制（§4.7）；队友 **Cannot** commit

```gdscript
func queue_nested_test(parent: SkillTestHandle, child_ctx: SkillTestContext) -> void:
    child_ctx.nested_depth = parent.ctx.nested_depth + 1
    if parent.ctx.encounter_resolution_id != &"":
        var frame := state.get_encounter_frame(parent.ctx.encounter_resolution_id)
        child_ctx.encounter_resolution_id = frame.id
        child_ctx.peril = frame.peril
    frame.pending_nested_tests.append(child_ctx)
```

---

## 7. SkillTestAPI（Script 门面）

```gdscript
class SkillTestAPI:
    func get_performing_investigator() -> StringName
    func get_skill() -> SkillType
    func get_difficulty() -> int
    func get_modified_value() -> int
    func is_successful() -> bool
    func add_modifier(delta: int, source: EffectSource) -> void
    func commit_card(from_inv: StringName, card: EntityId) -> Result
    func cancel_test() -> Result                    # 仅当有 cancel 效果
    func set_auto_fail() -> void
```

---

## 8. 与 ActionSystem 集成

| 行动 | 检定 |
|---|---|
| Investigate | Intellect vs shroud |
| Fight | Combat vs fight |
| Evade | Agility vs evade |
| Card ability | 文本指定 |

Action 在 AOO 之后调用 `SkillTestEngine.run_full_test`。

---

## 9. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| T-01 | 成功 investigate | discover 1 clue |
| T-02 | Auto-fail token | fail regardless |
| T-03 | 队友 commit 1 张 | +1 modifier |
| T-04 | Peril treachery test | 队友不可 commit（§4 · PERIL-01） |
| T-05 | Deduction committed 成功 investigate | +1 clue（ST.7） |
| T-06 | 空 deck draw during test 引发 horror | 与检定独立 |

---

## 10. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-04-04 | P1 | Cancel 整个 skill test vs Cancel 单个 chaos token：状态回滚深度？ |
| OQ-04-05 | P2 | 同时 reveal 多 token（极少数卡）：ST.3 扩展协议？ |
| OQ-04-06 | P1 | Committed 的 skill 在 ST.7 前被 discard 的 edge case（Limbo 保护）？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-04-01 | Player Window 在 **ST.2 前后**（commit 后一次）及 **ST.3–ST.4 整链结束后**（`PW_SKILL_TEST_AFTER_REVEAL`，进入 ST.5 前一次）。「Reveal another token」**仅递归 ST.3→ST.4**，不回 ST.2，递归中 **无 Player Window**。 | 2026-05-25 |
| OQ-04-02 | **Peril = 遭遇帧内持续 Cannot**（§4）；嵌套检定 ST.8 后入队仍不可协助。见 §4、§6。 | 2026-05-25 |
| OQ-04-03 | **否。** 子检定入队，父检定继续 ST.5→ST.8；子检定于父 **ST.8 后**执行。 | 2026-05-25 |
| OQ-05-03 | **Fail by 条件效果在 ST.7 结算**（ST.6 仅算 `fail_by`）。 | 2026-05-25 |
| OQ-PERIL-01 | drawer **confer** 仅 Presentation / 联机礼仪；引擎不阻断 drawer 行动。 | 2026-06-18 |

---

## 11. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-04-01 裁决；修正 ST.3 无 Window、ST.4 后 Window 仅整链一次 |
| 2026-05-25 | v0.3 | OQ-04-02 裁决：Peril 覆盖 encounter 结算帧；嵌套检定 ST.8 后入队仍不可协助 |
| 2026-05-25 | v0.4 | OQ-05-03 裁决：fail by 效果在 ST.7 |
| 2026-06-18 | v0.6 | **§4 收紧**：险境 = E3 Register RESTRICTION；删 `PerilPolicy`；统一 `RestrictionEvaluator` |
| 2026-06-18 | v0.5 | **§4 Peril 重设计**：持续 Cannot、L4/07 冲突链第 0 步；PERIL-01～06 |
| 2026-06-18 | v0.5.1 | **§4.9–11** 帧栈 / AppContext / E3 catalog；`EncounterResolutionFrame`；PERIL-01/04/05 测试 |
