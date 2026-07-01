# 10 — 遭遇、Act/Agenda 与场景 (ScenarioSystem)

> **依赖**：[02-framework-flow.md](02-framework-flow.md), [08-enemy-engagement.md](08-enemy-engagement.md), [05-chaos-bag.md](05-chaos-bag.md)  
> **规则来源**：Grimoire Mythos 1.4, Act/Agenda, Encounter Draw, Winning and Losing

---

## 1. 目标

管理 **Encounter Deck 抽取管线**、Act/Agenda 推进、Scenario Reference、Victory Display、Resolution `(→R#)`。

---

## 2. Encounter Draw 管线（Mythos 1.4 / 能力 draw）

> **规范流程**：[15-timing-entry-catalog.md §17](15-timing-entry-catalog.md)（`seq.draw.encounter`）。本节保留 **ScenarioSystem 委托形状** 与 **帧语义** 摘要。

```gdscript
func resolve_encounter_draw(drawer: StringName, amount: int = 1) -> void:
    sequence_catalog.run(&"seq.draw.encounter", {
        "drawer_id": drawer,
        "amount": amount,
    })
```

**引擎内 RESOLVE 形状**（Surge 同帧，不 proliferate Service）：

```text
seq.draw.encounter
  push EncounterResolutionFrame(drawer)
  repeat amount times:
    surge loop:
      collect_one_step (内联 E1)
      resolve_card_body (内联 E2/E3/E5 discard + nest E4/E5 spawn)
      if surge: continue loop
  pop frame → AFTER
```

| Step | Catalog / 说明 |
|---|---|
| E1+E2 Draw | **G1** 内联 collect + reveal 子步 |
| E3 Peril | **G2** priority **100** Register RESTRICTION |
| E4 Revelation | **G3** priority **90** nest Forced |
| E5 Treachery | **G4** priority **80** discard |
| E5 Enemy | **G4** priority **80** · 默认/指令 `spawn_from_encounter_draw` |
| E6 Surge | **G5** priority **70** evaluate + 再抽 G1 |
| Weakness 重定向 | `seq.draw.encounter.resolve_bound` → 同 priority 队列（skip G1） |

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
| ENC-01 | 遭遇空库洗弃，无 horror | discard → deck |
| ENC-02 | Surge treachery | 同 frame 第二圈 E1 |
| ENC-03 | Peril test | 他人不可 commit（04 §4.1） |
| ENC-04 | encounter weakness 从 inv deck | `resolve_bound`，非 enter_hand |
| ENC-08 | 无 Spawn enemy | spawn_engaged；无 Engage 子流程 |
| ENC-11 | Spawn 无合法 location | encounter discard（`discard_spawn_failed`） |

---

## 10. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-10-02 | P1 | Objective must advance 无 window — 自动 advance 还是暂停提示？ |
| OQ-10-03 | P1 | Agenda 非 1.3 advance（卡牌 explicit）— 框架如何插入 ad-hoc advance 步？ |
| OQ-10-05 | P1 | Act b side 变 Enemy — 是否立即 spawn 还是入 encounter 区？ |
| OQ-10-06 | P2 | Forbidden Secrets surge 条件 — 引擎 evaluate 时机在 revelation 前还是后？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-10-01 | Setup 1–13 **不结算显现** → **无 Setup surge 链**（原场景不存在）。若有 setup 显现/涌动，仅在 **Setup 14「When the game begins」** 结算。见 §2.1。 | 2026-05-25 |
| OQ-10-04 | **collect 立即洗**；嵌套效果内 deck 抽空 → **defer shuffle 至子树 pop 后**。见 [15 §17.11](15-timing-entry-catalog.md)。 | 2026-06-18 |

---

## 11. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-10-01 裁决：Setup 不结算显现；game begins 时结算 |
| 2026-06-18 | v0.3 | §2 对齐 [15 §17](15-timing-entry-catalog.md) SequenceCatalog 映射；ENC-01～04 |
| 2026-06-18 | v0.3.1 | E5 enemy spawn 术语：`spawn_engaged` vs `auto_engage_at_location`（15 §17.4.1 / 08 §7） |
| 2026-06-18 | v0.3.2 | `resolve_card` 共享子 flow；E5 dispatch / Hidden / Treachery（15 §17.4–12） |
