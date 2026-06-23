# 06 — 能力与 Initiation 管线 (AbilitySystem)

> **依赖**：[02-framework-flow.md](02-framework-flow.md), [07-effect-resolution.md](07-effect-resolution.md), **[07-composition.md](07-composition.md)**, **[15-timing-entry-catalog.md](15-timing-entry-catalog.md)**  
> **引擎统一模型**：[06-registration-buff-model.md](06-registration-buff-model.md)（Register / Buff / Context）  
> **规则来源**：Grimoire Ability, Triggered Abilities, Initiation Sequence (p.31)  
> **符号记法**：[`[reaction]` / `[action]` 等](../reference/arkham-symbol-notation.md)（ArkhamDB 标准）  
> **状态**：v0.3 · 2026-05-25

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
    TRIGGERED_FREE,     # [free]
    TRIGGERED_REACTION, # [reaction]
    TRIGGERED_ACTION,   # [action]
    KEYWORD,            # Fast, Surge, ...
    SPAWN,              # Enemy spawn instruction
}
```

| 类型 | 发起者 | 时机 |
|---|---|---|
| Constant | 引擎 | 查询 modifier 时 |
| Forced | 引擎 | timing point 自动 |
| Revelation | 引擎 | 按 **能力** + **cardtype** 分流：遭遇 E4 / 玩家 D3 `seq.enter_hand`（`has_revelation`）；weakness 路由见 [11 §10](11-investigator-campaign.md) |
| Free `[free]` | 玩家 | Player Window 或文本指定 |
| Reaction `[reaction]` | 玩家 | when/at/after 条件 |
| Action `[action]` | 玩家 | Activate action |
| Keyword | 引擎 | 规则 shorthand |
| Spawn | 引擎 | enemy enters play |

---

## 3. AbilityDefinition

> **v0.3+** 运行时统一为 **AbilitySpec**（§4）：Hook / 情景 / 费用 / 效果；本节保留 Grimoire 对照字段。

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

## 4. 能力规格：Hook / 情景 / 费用 / 效果

卡面四段在编译期映射为：

```gdscript
class AbilitySpec:
    var hook: AbilityHook           # 结构：挂在哪、怎么走（见 §4.1）
    var situational: Condition      # 卡面 If / While…（玩家口中的「条件」）
    var limits: LimitSpec
    var costs: Array[CostSpec]      # 见 §5 L6 CostPipeline
    var effect: CompositionNode

class AbilityHook:
    var sequence_id: StringName           # RuleSequence / 事件族 id（见 15）
    var slot: TimingSlot                  # WOULD | WHEN | AFTER
    var tier: AbilityTier                 # FORCED | TRIGGERED | LISTENER
```

> **v0.3 兼容**：旧字段 `event_family` + `SequencePhase` 迁移为 `(sequence_id, slot)`，见 [15 §2–§3](15-timing-entry-catalog.md)。

| 部分 | 引擎含义 | 参与订阅？ | 参与门槛？ |
|---|---|---|---|
| **Hook** | catalog 入口 `(sequence_id, slot)` + tier | ✅ L0 | ✅ L2 |
| **情景** | 卡面特殊情景 | ❌ | ✅ L3 |
| **费用** | Initiation 支付 | ❌ | ✅ L6（Initiation 专段） |
| **效果** | Composition resolve | ❌ | ✅ L7 dry_run |

**修正值**无 Hook：仅在 `ModifierEngine.compute` 时用 **L3 情景** + scope。

### 4.1 订阅键 vs 情景（L0 vs L3）

**订阅键（L0）** = catalog 的 `(sequence_id, slot)`。完整规范见 **[15-timing-entry-catalog.md](15-timing-entry-catalog.md)**。

| 用作 L0 订阅 | 不作订阅键（L3 Condition） |
|---|---|
| `sequence_id` + `WOULD` / `WHEN` / `AFTER` | tags、framework_step 细项 |
| | controller、Domain 事实、payload、referents |
| | zone / location（**禁止**用 zone 推导触发） |

例：调查员「仅 Upkeep 4.4 框架 gain +1」→ 订阅 `seq.action.gain_resource`, `AFTER`；L3：`framework_step == UPKEEP_4_4` 且 tags 含 `framework`。

详见 [06-registration-buff-model §12](06-registration-buff-model.md)。

---

## 5. Eligibility 关卡（L0–L7）

以 **能力能否被考虑 / 能否 Initiation** 为标准，门槛像关卡一样 **由便宜到贵** 排序。**玩家选用不是关卡**（见 §6）。

### 5.1 总览

```text
L0  订阅匹配        — 引入监听（索引，非门槛）
L1  注册存续
L2  结构钩子
L3  情景条件        — 卡面 If / While…
L4  规则限制        — RESTRICTION buff
L5  次数配额
        ─── 收集阶段（COLLECT）到此为止 ───
L6  费用            — CostPipeline（修正后）
L7  合法性终检      — dry_run（终端关，最后一步）
        ─── Initiation 专段 ───
```

```gdscript
enum EligibilityStage { COLLECT, PRE_INITIATE, PRE_RESOLVE }

class GateReport:
    var level: int           # 1–7；L0 单独为 listen
    var passed: bool
    var reason: StringName   # situational_fail, limit_reached, cannot_pay…

class EligibilityPipeline:
    func run(spec: AbilitySpec, ctx: ApplicationContext, stage: EligibilityStage) -> Array[GateReport]
```

| 阶段 | 跑到哪一关 | 何时 |
|---|---|---|
| `COLLECT` | L1–L5 | 窗口打开、refresh 每轮、obligation 放出 |
| `PRE_INITIATE` | L1–L6 | 强制自动发起前；[reaction] 控制者确认使用后 |
| `PRE_RESOLVE` | L1–L7 | Initiation resolve 前（L7 仅当前面全过） |

**原则：** L7 dry_run **绝不**在 COLLECT 阶段对全量候选运行；L6 费用 **不**在 COLLECT 阶段检查（资源费用虽简单，但与耗尽/弃牌等统一放在 Initiation）。

### 5.2 各关说明

| 关 | 问什么 | 典型检查 |
|---|---|---|
| **L0** | 此刻是否叫醒这类能力？ | 阶段+事件族 / `after_*` / 框架窗口 |
| **L1** | 注册还有效？ | 源卡在场、Lifetime、UNTIL_FIRED |
| **L2** | 结构位置对吗？ | tier、禁自响应、Forced vs [reaction] 槽位 |
| **L3** | 卡面情景满足？ | `Condition.matches(ctx)` |
| **L4** | 全局规则禁止？ | **RESTRICTION buff**（含 E3 险境 Register）；`RestrictionEvaluator`；**cannot 绝对** |
| **L5** | 次数还有？ | Limit / Max；Forced 不过→跳过；[reaction] 不过→不出候选 |
| **L6** | 费用可付？ | 分类型 Evaluator（见 §5.3） |
| **L7** | 效果能落地？ | `CompositionDryRunner`；目标仍合法 |

### 5.3 L6 · CostPipeline（非通用 Condition）

费用种类各异，**不做订阅、不进 L0–L5**，Initiation 内专用管道：

```text
apply_cost_modifiers(intent)
  → ResourceCostEvaluator
  → ExhaustCostEvaluator
  → DiscardCostEvaluator
  → MarkerCostEvaluator（doom、线索…）
  → CustomCostEvaluator（卡脚本）
  → 全部 can_pay → pay
```

### 5.4 能力形态 · 过哪些关

| 形态 | COLLECT L1–L5 | Initiation L6–L7 |
|---|---|---|
| 修正值 | 仅 L3（查询时） | — |
| RESTRICTION | L3–L4 | — |
| 延时监听 | L0–L5 | 通常无；效果内发起再 L6–L7 |
| 强制 | L0–L5 | ✓ |
| 反应 [reaction] | L0–L5 | 控制者选用 **后** ✓ |
| 行动 [action] | 另走 Action Initiation | ✓ |

### 5.5 与 Initiation 步骤对照

| Initiation 步 | 对应关卡 |
|---|---|
| Pre-restrictions | L3–L5 已在 COLLECT 做过；可选用后 **可快速复核** L3–L5 |
| Apply cost modifiers + Pay | **L6** |
| Dry-run / legality | **L7**（终端） |
| Commence + Resolve | 效果执行 |

---

## 6. ResponseWindow（窗口交互，非门槛）

**EligibilityPipeline** 只回答客观问题：「这条能力 eligible 吗？Initiation 能过 L6–L7 吗？」  
**ResponseWindow** 处理玩家 / 流程主观决策 — **不计入 L0–L7**。

```text
COLLECT（L0–L5）→ eligible 集合
        │
        ▼
ResponseWindow
  ├─ Forced：eligible → 自动 PRE_INITIATE（L6–L7）→ resolve
  ├─ [reaction]：控制者对每条 eligible **选用 / 不选用**
  │      · 选用 → 必须 Initiation（L6–L7）→ resolve
  │      · 不选用 → 不发起（非 gate fail）
  ├─ ≥2 条 [reaction] 均选用 → **队长**排顺序 → 逐条 Initiation
  └─ **关闭时点 / 结束本轮响应** → 结束当前 response_round
        │
        ▼
窗口仍 open → refresh → 再 COLLECT（nest 后新 eligible）
```

| 行为 | 层 | 说明 |
|---|---|---|
| 控制者选用 [reaction] | ResponseWindow | 授权发起，不是门槛 |
| 控制者不选用某 [reaction] | ResponseWindow | 仅不发起 |
| 关闭时点（本轮不再响应） | ResponseWindow | 结束轮次，非某能力 L3 失败 |
| 「May」跳过整条强制 | ResponseWindow | 可选强制的不发起 |
| eligible 但 L6 失败 | Eligibility | Initiation 中止 |

队长 **不**替其他调查员决定用不用 [reaction]；只排 **均已选用** 的多条顺序。见 [14-nested-sequences §5](14-nested-sequences.md)。

Presentation：`ResponsePrompt`（`core/timing/response_prompt.gd`）供 UI / headless 共用。

---

## 7. Initiation Sequence（Grimoire V）

```gdscript
class AbilityInitiationPipeline:
    func initiate(intent: InitiationIntent, ctx: GameContext) -> InitiationResult:
        event_log.record_initiation(INIT_PRE_RESTRICTIONS, intent)
        # L1–L5 快速复核（可选用后场面可能已变）
        if not eligibility.passes_through(intent.spec, ctx, EligibilityStage.PRE_INITIATE, up_to_level = 5):
            return ABORT
        event_log.record_initiation(INIT_1_APPLY_MODIFIERS, intent)
        apply_cost_modifiers(intent)                    # L6 前半
        event_log.record_initiation(INIT_2_PAY_COSTS, intent)
        if not cost_pipeline.pay(intent): return ABORT  # L6
        event_log.record_initiation(INIT_2B_AOO, intent)
        resolve_attacks_of_opportunity(intent)
        if cancel_before_initiate(intent): return CANCELLED
        if not legality.dry_run(intent, ctx).passes:     # L7 终端
            return ABORT
        event_log.record_initiation(INIT_3_COMMENCE, intent)
        commence_play_or_ability(intent)
        event_log.record_initiation(INIT_4_RESOLVE, intent)
        resolve_effects(intent)
        return SUCCESS
```

Initiation 各步 **完整写入 EventRecord**，与 Framework 同级（已裁决 OQ-IDX-02）。

### 7.1 步骤对照

| Step | Grimoire | 实现 |
|---|---|---|
| Pre | Play restrictions + 效果可结算性 | Eligibility **L3–L5** 复核；**L7** `dry_run()` |
| Pre | Cost feasibility | **L6** `CostPipeline`（含 modifier 后） |
| 1 | Apply cost modifiers | L6 前半 |
| 2 | Pay costs | L6 支付 |
| 2b | AOO | `AttackOfOpportunityResolver` |
| 3 | Commence play / ability | Limbo, enter play |
| 4 | Resolve effects | `CompositionExecutor`（见 [07-composition](07-composition.md)） |

**In-play 卡 leave play during initiation**：initiation **仍完成**（Grimoire p.31）。

### 7.2 合法性 Dry-run（已裁决 OQ-06-02，v0.2 细化）

打出 / 发动能力前须 **dry-run**（**Eligibility L7，终端关**）；**仅当效果组合中至少有一段「把效果创建出来」** 时才算合法。COLLECT 阶段 **不** 对候选批量 dry_run。

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

UI 高亮、AI、headless 在 **Initiation PRE_RESOLVE** 调用 `dry_run()`；COLLECT 仅用 L1–L5。**禁止**仅用静态 restriction 表。

---

## 8. TimingBus 与优先级

> **collect eligible** 走 `EligibilityPipeline.run(..., COLLECT)`（L0–L5），见 §5。窗口交互见 §6、[14 §5、§8](14-nested-sequences.md)。  
> **同时点竞争**总览（含 **替换竞争** / Replacement）见 [07 §3.2–§3.4](07-effect-resolution.md)。

**两层模型（必须区分）：**

| 层 | 名称 | 裁决者 | 含义 |
|---|---|---|---|
| **A** | **类别优先级**（`AbilityCategoryTier`） | **引擎** | 不同**能力类别**之间的整体先后；**跨类不可**由玩家对调 |
| **B** | **同类内顺序** | **玩家 / 流程** | **仅当**两条能力 **同属一类 tier** 时，才进入选用、队长选序、注册序等 |

```text
COLLECT → eligible（按 tier 分组）
  → 先 resolve 整个 FORCED 类（类内自排）
  → 再 resolve 整个 FRAMEWORK 类（类内自排）
  → 再 TRIGGERED 类 …
  → 禁止「一条 [reaction] 插进 Forced 批次中间」
```

### 8.1 类别优先级（跨类 · 引擎固定）

同一 Timing Window 内，**类别**按下列顺序 **整批** 推进；**上一类全部 resolve 完** 才进入下一类：

| 顺序 | `AbilityCategoryTier` | 典型能力 |
|---|---|---|
| 1 | **FORCED** | Forced – when/after/at；显现（Revelation）nest |
| 2 | **FRAMEWORK** | 框架步内嵌 forced / 规则流程 |
| 3 | **TRIGGERED** | `[reaction]` / `[action]` / `[free]` 触发 |
| 4 | **DELAYED** | 延时替换、延时监听（timing 匹配时） |
| 5 | **LISTENER** | `after_timing` 放出（AFTER-B） |

```gdscript
## 与 SequenceHandler.Tier 对齐；数值越小越先（整类 batch）。
enum AbilityCategoryTier { FORCED, FRAMEWORK, TRIGGERED, DELAYED, LISTENER }
```

> **与 Cannot / Silver Rule / Replacement 分工**：**Cannot** 非竞争、绝对拦截（07 §3.2）。**同时点竞争** 含 **替换竞争**（Instead：最后 initiate，§3.4）与 **能力竞争**（本节 tier + 类内自排）。**Silver Rule** 仅文本无法调和。

### 8.2 同类内顺序（仅同 tier · 玩家自排）

**不得**用「队长选序」跨越 §8.1 的类别边界。同类内规则：

| 同类情况 | 自排规则 |
|---|---|
| 多个 **replacement** 同 trigger 且 **conflict** | **不**自排；**最后 initiate** 自动生效（07 §3.4）。Forced 同时时 **先** 队长定 initiate 顺序 |
| 多个 **Forced** | **Lead Investigator** 选结算顺序；无可选 UI 时 → 注册顺序 |
| 多个 **[reaction]** eligible | **控制者**对每条 **选用 / 不选用**（非队长） |
| 多个 **[reaction]** **均已选用** | **Lead Investigator** 在 **TRIGGERED 类内** 排顺序（OQ-06-03） |
| 多个 **LISTENER** | 默认注册顺序；若设计师要求可选则另定 |
| **enter_hand** 多张牌显现（均属 FORCED 类） | `EnterHandTimingPolicy` 管 **类内** 牌序（见 [15 §16.4.1](15-timing-entry-catalog.md)） |

### 8.3 When / At / After

| 词 | 相对 timing |
|---|---|
| when | 触发后、impact 前；**打断** resolution |
| at / if | 与 impact **同时** |
| after | impact **之后**、下一步之前 |

### 8.4 Then 优先

效果文本含 **then**：then 前段完全 resolve 后，then 后段优先于该前段间接产生的 **after** 触发（Grimoire Then）。

---

## 9. Limit / Max 追踪

```gdscript
class LimitTracker:
    var counters: Dictionary  # key = ability_id + period + player/group

    func can_trigger(spec: LimitSpec, ctx: GameContext) -> bool
    func record_trigger(spec: LimitSpec) -> void
    func reset_on_enter_play(card: EntityId) -> void   # Limit X per card 重置
```

| 类型 | 示例 |
|---|---|
| Limit once per round | Joe [reaction] investigate |
| Group limit once per game | Orne Library [action][action] |
| Max 1 in play by title | Exceptional |
| Max 1 committed per test | Perception |

---

## 10. AbilityRegistry

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

## 11. Play Restrictions 常见类型

- Fast event：指定 window / when 条件
- Asset：slots 可用、unique 不在场
- Activate：来源合法、exhausted 否（若 cost 含 exhaust）
- Target 存在且 valid

---

## 12. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| B-01 | Ward of Protection fast cancel treachery | revelation cancelled; 仍 take horror |
| B-02 | Forced before [reaction] After draw | Forced 先 |
| B-03 | Limit once per round 第二次 | L5 拒绝 |
| B-04 | Pay cost fail mid-initiate | L6 失败；无 cost 已付 |
| B-05 | Then 链 vs After draw | Then 段优先 |
| B-06 | Card leaves play during initiate | 效果仍 resolve |
| ELIG-01 | COLLECT 不跑 dry_run | 仅 L1–L5 |
| ELIG-02 | [reaction] 选用后进 L6–L7 | 选用非 gate |
| ELIG-03 | 关闭时点 vs 不选用 | 轮次结束 vs 单条跳过 |

---

## 13. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-06-04 | P1 | Forced [reaction] 是否存在？（通常无，但 scenario 卡） |
| OQ-06-05 | P2 | Constant ability 在 out-of-play 被引用（少数卡）— 如何标记 `references_out_of_play`？ |
| OQ-06-06 | P1 | Ignore 效果仍计 Limit — 触发时 record 还是 resolve 后 record？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-06-01 | Replacement 冲突：**最后 initiate**。见 [07 §3.4、§7](07-effect-resolution.md)。 | 2026-06-18 |
| OQ-06-02 | 打出/发动须 **dry-run**（**L7 终端**）；COLLECT 不批量 dry-run。见 §7.2。 | 2026-05-25 |
| OQ-06-03 | 多个 [reaction] 同时选用后：**Lead Investigator** 选顺序；选用权在控制者。见 §8.2。 | 2026-05-25 |
| OQ-IDX-02 | Initiation 各步完整 **EventRecord**，与 Framework 同级。见 §4 pipeline。 | 2026-05-25 |

---

## 14. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-06-01/02 裁决：Replacement 优先级 + Initiation dry-run |
| 2026-05-25 | v0.3 | AbilitySpec；Eligibility L0–L7；ResponseWindow；Hook→(sequence_id,slot)；链到 15 |
| 2026-06-18 | v0.4 | **§8** 两层优先级：类别整批 vs 同类内自排 |
| 2026-06-18 | v0.4.1 | 移除 Replacement→Silver Rule 误链；指向 07 §3.2 Cannot |
| 2026-06-18 | v0.4.2 | §8 链 07 同时点竞争；§8.2 replacement 类内自动最近 initiate |
