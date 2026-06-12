# 04 — 技能检定引擎 (SkillTestEngine)

> **依赖**：[02-framework-flow.md](02-framework-flow.md), [05-chaos-bag.md](05-chaos-bag.md), [07-effect-resolution.md](07-effect-resolution.md)  
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
    var peril: bool                           # 禁止协助；见 §4 Peril 范围
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

- 基础行动固定 skill；`(🕯 or 🕑)` 由 performing investigator 选择
- 发起 `TimingBus`: `skill_test_begins`
- Push `GameContext.skill_test_stack`

### 3.2 ST.2 Commit

- Performing investigator：任意张 eligible（matching icon 或 wild）
- 同地点其他 investigator：**1 张**（Peril 时禁止）
- 每张 matching icon +1 skill value
- Max committed per test 限制（如 Perception max 1）
- 不付 resource cost
- **Player Window**：`PW_SKILL_TEST_AFTER_COMMIT`（ST.2 完成后、进入 ST.3 之前）

### 3.3 ST.3 Reveal

- 从 chaos bag 随机取 1 token
- **无 Player Window**（见 [00-framework-step-index.md](00-framework-step-index.md)）

### 3.4 ST.4 Symbol effects

- Skull/Cultist/Tablet/Elder Thing → ScenarioReference 能力
- Elder Sign → investigator 卡 🕯 能力
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

## 4. Commit 规则详表

| 规则 | 实现 |
|---|---|
| Wild 🌐 | 匹配任意 skill |
| 无 matching icon | 不可 commit |
| Peril | 仅 performing 可 commit（见 §4.1） |
| Max N committed | 按 title 计数 |
| Commit 归属 | **`SkillTestContext.committed` 列表**；卡 **zone 仍为 HAND** 直至 ST.8 discard（已裁决 OQ-01-03）。不用 LIMBO |
| LIMBO | 仅 **Event/Treachery 显现结算中** 等场景；与 committed skill **无关** |

### 4.1 Peril 范围（已裁决 OQ-04-02）

**Peril 覆盖该 encounter 的整个结算期间**，不限于首张 skill test。

| 范围 | 说明 |
|---|---|
| **Encounter 结算帧** | 从 draw → revelation → spawn/discard → surge 递归，直至该 encounter **完全结算完毕** |
| **Peril 约束** | 帧内**所有** skill test：仅 **performing investigator**（通常为 drawer）可 commit / play cards / 被咨询 |
| **嵌套检定** | ST.4/ST.7 等触发的后续检定须等**前一检定 ST.8 完成后**才开始；但仍在 encounter 结算帧内 → **仍不可协助** |

```gdscript
class EncounterResolutionFrame:
    var drawer: StringName
    var encounter: EntityId
    var peril: bool
    var pending_nested_tests: Array[SkillTestContext]  # 父检定 ST.8 后依次执行

func can_commit(from_inv: StringName, test: SkillTestContext) -> bool:
    if test.peril and from_inv != test.performing_investigator:
        return false
    return ...  # 常规 matching icon 等
```

嵌套检定**不**继承父检定的 committed / tokens / difficulty；**Peril 状态**继承自当前 encounter 结算帧（若 `encounter_resolution_id` 仍 active 且 `peril == true`）。

---

## 5. 嵌套检定（已裁决 OQ-04-02）

当 ST.4 / ST.7 文本发起新检定时：

1. **不**在父检定中途插入；**入队**，待父检定 **ST.8 完成**后执行（父检定 ST.5–ST.7 **不等待**子检定，见 OQ-04-03）
2. 子检定独立 committed / tokens / difficulty
3. 若父检定处于 **Peril encounter 结算帧**内，子检定 `peril = true`，队友仍不可 commit

```gdscript
func queue_nested_test(parent: SkillTestHandle, child_ctx: SkillTestContext) -> void:
    child_ctx.nested_depth = parent.ctx.nested_depth + 1
    if parent.ctx.encounter_resolution_id != "":
        var frame := state.get_encounter_frame(parent.ctx.encounter_resolution_id)
        child_ctx.encounter_resolution_id = frame.id
        child_ctx.peril = frame.peril
    frame.pending_nested_tests.append(child_ctx)
    # 父检定继续 ST.5–ST.8；ST.8 后 drain pending_nested_tests
```

---

## 6. SkillTestAPI（Script 门面）

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

## 7. 与 ActionSystem 集成

| 行动 | 检定 |
|---|---|
| Investigate | Intellect vs shroud |
| Fight | Combat vs fight |
| Evade | Agility vs evade |
| Card ability | 文本指定 |

Action 在 AOO 之后调用 `SkillTestEngine.run_full_test`。

---

## 8. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| T-01 | 成功 investigate | discover 1 clue |
| T-02 | Auto-fail token | fail regardless |
| T-03 | 队友 commit 1 张 | +1 modifier |
| T-04 | Peril treachery test | 队友不可 commit |
| T-05 | Deduction committed 成功 investigate | +1 clue（ST.7） |
| T-06 | 空 deck draw during test 引发 horror | 与检定独立 |

---

## 9. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-04-04 | P1 | Cancel 整个 skill test vs Cancel 单个 chaos token：状态回滚深度？ |
| OQ-04-05 | P2 | 同时 reveal 多 token（极少数卡）：ST.3 扩展协议？ |
| OQ-04-06 | P1 | Committed 的 skill 在 ST.7 前被 discard 的 edge case（Limbo 保护）？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-04-01 | Player Window 在 **ST.2 前后**（commit 后一次）及 **ST.3–ST.4 整链结束后**（`PW_SKILL_TEST_AFTER_REVEAL`，进入 ST.5 前一次）。「Reveal another token」**仅递归 ST.3→ST.4**，不回 ST.2，递归中 **无 Player Window**。 | 2026-05-25 |
| OQ-04-02 | **Peril 覆盖 encounter 整个结算期间。** 嵌套检定须等前一检定 **ST.8** 后开始，但仍在结算帧内 → **仍不可协助 commit**。见 §4.1、§5。 | 2026-05-25 |
| OQ-04-03 | **否。** 子检定入队，父检定继续 ST.5→ST.8；子检定于父 **ST.8 后**执行。由 OQ-04-02 嵌套时序推出。 | 2026-05-25 |
| OQ-05-03 | **Fail by 条件效果在 ST.7 结算**（作为失败效果的一部分）。ST.6 仅计算 `fail_by`。见 05 §5。 | 2026-05-25 |

---

## 10. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-04-01 裁决；修正 ST.3 无 Window、ST.4 后 Window 仅整链一次 |
| 2026-05-25 | v0.3 | OQ-04-02 裁决：Peril 覆盖 encounter 结算帧；嵌套检定 ST.8 后入队仍不可协助 |
| 2026-05-25 | v0.4 | OQ-05-03 裁决：fail by 效果在 ST.7 |
