# 10 — 遭遇、Act/Agenda 与场景 (ScenarioSystem)

> **依赖**：[02-framework-flow.md](02-framework-flow.md), [08-enemy-engagement.md](08-enemy-engagement.md), [05-chaos-bag.md](05-chaos-bag.md)  
> **规则来源**：Grimoire Mythos 1.4, Act/Agenda, Encounter Draw, Winning and Losing

---

## 1. 目标

管理 **Encounter Deck 抽取管线**、Act/Agenda 推进、Scenario Reference、Victory Display、Resolution `(→R#)`。

---

## 2. Encounter Draw 管线（Mythos 1.4 / 能力 draw）

```gdscript
func resolve_encounter_draw(drawer: StringName) -> void:
    var frame := EncounterResolutionFrame.new(drawer)
    push_encounter_frame(frame)
    loop:
        card = encounter_deck.draw()
        if peril(card):
            frame.peril = true              # 覆盖本 encounter 整个结算帧
        resolve_revelation(card)            # Forced, may skill test; 嵌套检定 ST.8 后入队
        drain_pending_nested_tests(frame)   # 帧内 Peril 约束延续
        if enemy(card): enemy_system.spawn(card, drawer)
        elif treachery(card): discard_unless_in_play(card)
        if surge(card): continue loop
        else: break
    pop_encounter_frame(frame)
```

| Step | 说明 |
|---|---|
| Draw | deck 空 → shuffle discard |
| Peril | **覆盖该 encounter 整个结算期间**（含 revelation 触发的嵌套检定）；仅 drawer 可 commit/play/咨询。见 [04-skill-test-engine.md §4.1](04-skill-test-engine.md) |
| Revelation | 遭遇 treachery/enemy 等；**encounter cardtype weakness** 走本管线（≠ 玩家牌入手显现） |
| Enemy spawn | 见 EnemySystem |
| Treachery | 默认 discard；可入 threat/play |
| Surge | 仅 **Revelation 已结算** 后触发；Setup 1–13 **不**结算显现 → **无 Setup surge 链**（见 §2.1） |

### 2.1 Setup 与显现 / Surge（已裁决 OQ-10-01）

| 阶段 | Revelation | Surge |
|---|---|---|
| **Setup 步骤 1–13** | **不结算**显现（Revelation） | **不存在**后续 Surge 链 — **原疑点场景不成立** |
| **Setup 14「When the game begins」** | 若 setup 指令/卡牌需显现，**在此**结算 | 随显现在此结算；走正常 encounter 管线（仍无 player window，除非文本指定） |
| **游戏中**（Mythos 1.4 等） | 正常 `resolve_encounter_draw` | 正常 Surge 递归 |

```gdscript
func setup_step_14_game_begins() -> void:
    # 仅此时结算 setup 期间积攒的「When the game begins」显现 / 涌动
    timing_bus.emit("when_the_game_begins")
    resolve_deferred_setup_revelations()   # 若有；否则 no-op
```

**引擎/UI**：无需为「Setup 无 window 的 nested surge」设计特殊分支；Setup 1–13 不进入 `resolve_encounter_draw` 的 revelation 链。

## 3. Act Deck

### 3.1 Advance 条件

- Group spend clues ≥ act threshold（[per_investigator] 或 flat）
- Objective –  override/additional requirements
- Forced advance when conditions met（must vs may）

### 3.2 Advance 步骤

```
1. Remove all tokens from advancing act
2. Flip to b side; follow instructions（a 面 constant/forced 仍 active）
3. b 若为 encounter 类型 → 按 encounter 规则
4. 指定 next act 或 sequential next
5. advancing act removed from game; new current act
6. 若 (→R#) → scenario_resolution
```

### 3.3 Spend clues advance

- [free] player ability during any investigator turn player window
- Any/all investigators contribute

---

## 4. Agenda Deck

### 4.1 Doom placement

- Mythos 1.2：+1 doom on current agenda
- Doom on other cards counts toward threshold

### 4.2 Advance 时机

**默认仅 Mythos 1.3**（除非卡牌 explicitly can advance agenda）。

```
doom_in_play >= agenda_threshold → advance
→ remove ALL doom from play
→ flip agenda, follow b side
→ next agenda or specified
```

Agenda flip 时 investigator 未 defeated 且无 remaining agenda → 1 mental or physical trauma（Grimoire Scenario Resolution）。

---

## 5. Objective 语义

| 文本 | 行为 |
|---|---|
| Objective – must advance when... | 条件满足必须 advance（指定 timing 或 any [free] window） |
| Objective – may advance | 可选；无 timing 则 any [free] window |
| Override clues | 覆盖或追加 spend 要求 |

---

## 6. Victory Display

```gdscript
class VictoryDisplay:
    func add(card: EntityId, reason: VictoryReason) -> void
    func total_victory_points() -> int   # scenario end XP
```

来源：defeat enemy victory X、treachery victory X、location end condition、player asset victory X（罕见）。

---

## 7. ScenarioDefinition

```gdscript
class ScenarioDefinition:
    var id: StringName
    var encounter_sets: Array[StringName]
    var act_deck: Array[StringName]          # ordered card ids
    var agenda_deck: Array[StringName]
    var reference_easy: ScenarioReferenceDefinition
    var reference_hard: ScenarioReferenceDefinition
    var setup_script: ScenarioScript
    var codex_entries: Dictionary[int, String]
```

---

## 8. ScenarioSystem API

```gdscript
class ScenarioSystem:
    func setup_from_definition(def: ScenarioDefinition, guide: CampaignGuideSetup) -> void
    func advance_act() -> Result
    func advance_agenda() -> Result
    func check_scenario_end() -> int          # R# or -1
    func build_encounter_deck() -> void
```

---

## 9. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| SC-01 | Surge treachery | draw 2nd |
| SC-02 | Peril test | 他人不可 commit |
| SC-03 | Act spend [per_investigator] clues 4p | threshold ×4 |
| SC-04 | Agenda doom advance | all doom cleared |
| SC-05 | Defeat Victory 2 enemy | victory display +2 |
| SC-06 | (→R1) on act 3b | resolution 1 |

---

## 10. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-10-02 | P1 | Objective must advance 无 window — 自动 advance 还是暂停提示？ |
| OQ-10-03 | P1 | Agenda 非 1.3 advance（卡牌 explicit）— 框架如何插入 ad-hoc advance 步？ |
| OQ-10-04 | P2 | Encounter deck shuffle mid-ability — 先 resolve 完再 shuffle？ |
| OQ-10-05 | P1 | Act b side 变 Enemy — 是否立即 spawn 还是入 encounter 区？ |
| OQ-10-06 | P2 | Forbidden Secrets surge 条件 — 引擎 evaluate 时机在 revelation 前还是后？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-10-01 | Setup 1–13 **不结算显现** → **无 Setup surge 链**（原场景不存在）。若有 setup 显现/涌动，仅在 **Setup 14「When the game begins」** 结算。见 §2.1。 | 2026-05-25 |

---

## 11. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-10-01 裁决：Setup 不结算显现；game begins 时结算 |
