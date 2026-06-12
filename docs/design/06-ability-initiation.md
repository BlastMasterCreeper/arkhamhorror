# 06 — 能力与 Initiation 管线 (AbilitySystem)

> **依赖**：[02-framework-flow.md](02-framework-flow.md), [07-effect-resolution.md](07-effect-resolution.md), **[07-composition.md](07-composition.md)**  
> **引擎统一模型**：[06-registration-buff-model.md](06-registration-buff-model.md)（Register / Buff / Context）  
> **规则来源**：Grimoire Ability, Triggered Abilities, Initiation Sequence (p.31)

---

## 1. 目标

分类并实现全部 **Card Ability** 类型，以及 Grimoire **Initiation Sequence** 七步管线；管理 Limit/Max、触发优先级。

---

## 2. 能力分类

```gdscript
enum AbilityKind {
    CONSTANT,           # 无图标，always active in play
    FORCED,             # Forced – when/after/at/if
    REVELATION,         # Treachery/Weakness 抽到时
    TRIGGERED_FREE,     # 🕤
    TRIGGERED_REACTION, # 🕭
    TRIGGERED_ACTION,   # 🕮
    KEYWORD,            # Fast, Surge, ...
    SPAWN,              # Enemy spawn instruction
}
```

| 类型 | 发起者 | 时机 |
|---|---|---|
| Constant | 引擎 | 查询 modifier 时 |
| Forced | 引擎 | timing point 自动 |
| Revelation | 引擎 | encounter/weakness draw |
| Free 🕤 | 玩家 | Player Window 或文本指定 |
| Reaction 🕭 | 玩家 | when/at/after 条件 |
| Action 🕮 | 玩家 | Activate action |
| Keyword | 引擎 | 规则 shorthand |
| Spawn | 引擎 | enemy enters play |

---

## 3. AbilityDefinition

```gdscript
class AbilityDefinition:
    var id: StringName
    var kind: AbilityKind
    var source_card: EntityId
    var text: String
    var triggering_condition: TriggerCondition   # when/at/after/if + event
    var costs: Array[Cost]
    var play_restrictions: Array[Restriction]
    var targets: TargetSpec
    var effects: Array[EffectTemplate]
    var limits: LimitSpec                        # Limit once per round, Max 1 in play, ...
    var designators: Array[ActionType]
    var is_optional: bool                        # "may"
```

---

## 4. Initiation Sequence（Grimoire V）

```gdscript
class AbilityInitiationPipeline:
    func initiate(intent: InitiationIntent) -> InitiationResult:
        event_log.record_initiation(INIT_PRE_RESTRICTIONS, intent)
        var dry := legality_checker.dry_run(intent)
        if not dry.passes: return ABORT

        event_log.record_initiation(INIT_1_APPLY_MODIFIERS, intent)
        apply_cost_modifiers(intent)
        event_log.record_initiation(INIT_2_PAY_COSTS, intent)
        if not pay_costs(intent): return ABORT

        event_log.record_initiation(INIT_2B_AOO, intent)
        resolve_attacks_of_opportunity(intent)

        if cancel_before_initiate(intent): return CANCELLED

        event_log.record_initiation(INIT_3_COMMENCE, intent)
        commence_play_or_ability(intent)
        event_log.record_initiation(INIT_4_RESOLVE, intent)
        resolve_effects(intent)
        return SUCCESS
```

Initiation 各步 **完整写入 EventRecord**，与 Framework 同级（已裁决 OQ-IDX-02）。

### 4.1 步骤对照

| Step | Grimoire | 实现 |
|---|---|---|
| Pre | Play restrictions + 效果可结算性 | `InitiationLegalityChecker.dry_run()` |
| Pre | Cost feasibility | `CostCalculator.can_pay`（含于 dry-run） |
| 1 | Apply cost modifiers | Ignore cost 等 |
| 2 | Pay costs | resources, exhaust, damage, ... |
| 2b | AOO | `AttackOfOpportunityResolver` |
| 3 | Commence play / ability | Limbo, enter play |
| 4 | Resolve effects | `CompositionExecutor`（见 [07-composition](07-composition.md)） |

**In-play 卡 leave play during initiation**：initiation **仍完成**（Grimoire p.31）。

### 4.2 合法性 Dry-run（已裁决 OQ-06-02，v0.2 细化）

打出 / 发动能力前须 **dry-run**；**仅当效果组合中至少有一段「把效果创建出来」** 时才算合法。

完整规则见 **[07-composition.md §4](07-composition.md)**。要点：

| 检查项 | 说明 |
|---|---|
| Play restrictions | RESTRICTION buff + play restriction |
| Cost feasibility | 能否支付（含 modifier 后） |
| **效果创建** | fork 上至少一个组合节点 **CREATED** |

**「创建」的定义**（仅此，不查创建后是否退化）：

| 节点 | CREATED = |
|---|---|
| **Register** | `RegistrationStore` **成功插入**一条 Registration |
| **Atom** | `StateMutator` **执行成功** |
| **CancelPending / ReplacePending** | 对存在的 pending **操作成功** |

**明确不查**：Register 后 MODIFIER 是否用到、Listener 将来是否触发、延时触发时牌堆是否为空、+0 modifier 等。

**Seq / Choice（合法性）**：子分支 **OR**——任一段 CREATED 即可发起。  
**Then（真实结算）**：仍顺序 resolve；前段 fizzle 可挡后段（Grimoire Then）。

```gdscript
class InitiationLegalityChecker:
    func dry_run(intent: InitiationIntent) -> DryRunResult:
        var sim := GameSimulator.fork(context)   # state + registrations + pending
        simulate_pre_restrictions(intent, sim)
        simulate_cost_modifiers_and_payability(intent, sim)
        var comp := CompositionDryRunner.simulate(intent.composition, sim)
        return DryRunResult.new(
            passes = comp.has_any_created,
            violations = ...
        )
```

UI 高亮、AI、headless 均调用 `dry_run()`；**禁止**仅用静态 restriction 表。

---

## 5. TimingBus 与优先级

### 5.1 同一 Timing Point 顺序

```
1. Forced abilities（全部 resolve 完）
2. Framework 内嵌效果
3. Triggered abilities（玩家选择顺序，见下）
4. Delayed effects（若 timing 匹配）
```

### 5.2 Forced vs Reaction

- Forced **优先于** 引用同一 timing 的 🕭
- 多个 Forced：**Lead Investigator** 选顺序（若无可选则按注册顺序）
- 多个 🕭 同时 eligible：**Lead Investigator** 选顺序（已裁决 OQ-06-03）

### 5.3 When / At / After

| 词 | 相对 timing |
|---|---|
| when | 触发后、impact 前；**打断** resolution |
| at / if | 与 impact **同时** |
| after | impact **之后**、下一步之前 |

### 5.4 Then 优先

效果文本含 **then**：then 前段完全 resolve 后，then 后段优先于该前段间接产生的 **after** 触发（Grimoire Then）。

---

## 6. Limit / Max 追踪

```gdscript
class LimitTracker:
    var counters: Dictionary  # key = ability_id + period + player/group

    func can_trigger(spec: LimitSpec, ctx: GameContext) -> bool
    func record_trigger(spec: LimitSpec) -> void
    func reset_on_enter_play(card: EntityId) -> void   # Limit X per card 重置
```

| 类型 | 示例 |
|---|---|
| Limit once per round | Joe 🕭 investigate |
| Group limit once per game | Orne Library 🕮🕮 |
| Max 1 in play by title | Exceptional |
| Max 1 committed per test | Perception |

---

## 7. AbilityRegistry

```gdscript
class AbilityRegistry:
    func register_from_card(def: CardDefinition, script: CardScript) -> void
    func get_constants_affecting(entity: EntityId) -> Array[AbilityDefinition]
    func get_forced_listeners(timing: TimingPoint) -> Array[AbilityDefinition]
    func get_triggered_candidates(timing: TimingPoint, inv: StringName) -> Array[AbilityDefinition]
```

Constant abilities 在 modifier 计算时 lazy 查询，不注册 listener。

> **v0.2+**：Constant / Lasting / Delayed 统一为 [RegistrationStore](06-registration-buff-model.md)；`AbilityRegistry.get_constants_affecting` 等价于 `collect(MODIFIER, ctx)`。下文 AbilityKind 表保留 Grimoire 对照。

---

## 8. Play Restrictions 常见类型

- Fast event：指定 window / when 条件
- Asset：slots 可用、unique 不在场
- Activate：来源合法、exhausted 否（若 cost 含 exhaust）
- Target 存在且 valid

---

## 9. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| B-01 | Ward of Protection fast cancel treachery | revelation cancelled; 仍 take horror |
| B-02 | Forced before 🕭 After draw | Forced 先 |
| B-03 | Limit once per round 第二次 | 拒绝 |
| B-04 | Pay cost fail mid-initiate | 无 cost 已付 |
| B-05 | Then 链 vs After draw | Then 段优先 |
| B-06 | Card leaves play during initiate | 效果仍 resolve |

---

## 10. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-06-04 | P1 | Forced 🕭 是否存在？（通常无，但 scenario 卡） |
| OQ-06-05 | P2 | Constant ability 在 out-of-play 被引用（少数卡）— 如何标记 `references_out_of_play`？ |
| OQ-06-06 | P1 | Ignore 效果仍计 Limit — 触发时 record 还是 resolve 后 record？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-06-01 | Replacement 冲突：**Encounter 卡 > 玩家卡**；同优先级 **Lead Investigator** 选择。见 [07 §7](07-effect-resolution.md)。 | 2026-05-25 |
| OQ-06-02 | 打出/发动须 **dry-run**；**仅当干运行产出可结算效果** 时合法。见 §4.2。 | 2026-05-25 |
| OQ-06-03 | 多个 🕭 同时 eligible：**Lead Investigator** 选顺序。见 §5.2。 | 2026-05-25 |
| OQ-IDX-02 | Initiation 各步完整 **EventRecord**，与 Framework 同级。见 §4 pipeline。 | 2026-05-25 |

---

## 11. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-06-01/02 裁决：Replacement 优先级 + Initiation dry-run |
