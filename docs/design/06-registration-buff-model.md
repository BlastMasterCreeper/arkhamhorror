# 06b — Registration 与 Buff 规格 (统一能力模型)

> **依赖**：[06-ability-initiation.md](06-ability-initiation.md), [07-effect-primitives.md](07-effect-primitives.md), [07-composition.md](07-composition.md)  
> **被依赖**：TimingBus、ModifierEngine、Initiation dry-run  
> **状态**：v0.4 · 2026-06-18

---

## 1. 目标

用 **Register / Unregister + Buff + Context** 统一理解全部能力与持续/延时效果。

- **印刷能力类型**（Constant / Forced / [reaction] / [action]）→ 编译期 **tags**，不是运行时分支。
- **状态变更**由 [07-composition](07-composition.md)（Atom 节点）完成。
- **规则变更**由 **RegisterNode** 写入 `RegistrationStore`。
- **Buff 仅三种**；关键词（Surge、Peril…）、Cancel/Replacement **不是** Buff 类型。

---

## 2. 核心对象

```gdscript
class Registration:
    var id: StringName
    var source: SourceRef
    var lifetime: LifetimeSpec
    var scope: ScopeFilter
    var buffs: Array[BuffSpec]
    var tags: Array[StringName]

class BuffSpec:
    var type: BuffType
    var scope: ScopeFilter
    var condition: Condition
    var priority: BuffPriority
    var payload: Variant
    var tags: Array[StringName]
```

| 原语 | 含义 |
|---|---|
| **Register** | `RegistrationStore.register(reg)` |
| **Unregister** | id / filter / lifetime tick |
| **Buff** | `BuffSpec` + payload |
| **Context** | `ApplicationContext`（§9） |

---

## 3. BuffType（三种）

```gdscript
enum BuffType {
    MODIFIER,       # 被动改数值
    RESTRICTION,    # 被动禁止/允许；编译卡面 "cannot …"；Grimoire：cannot 绝对，不得 countermand（07 §3.2）
    LISTENER,       # timing 到点跑 Composition
}
```

| 非 Buff 机制 | 实现方式 |
|---|---|
| Surge、Peril、Aloof、Massive 等 **关键词** | `CardDefinition.keywords` + 编译为 MODIFIER/RESTRICTION/LISTENER |
| Cancel / Replacement | [07-composition](07-composition.md) 的 `CancelPending` / `ReplacePending` 节点 |
| Skill Test / Encounter 帧 | `SkillTestContext` 字段 + 子系统读 Context |

---

## 4. 持续 vs 延时：只有 Lifetime 不同

**持续效果**与**延时效果**本质都是 **Register**；玩家用语差别在 **`LifetimeSpec`**：

| 玩家说法 | LifetimeSpec | 典型 Buff | Registration 何时消失 |
|---|---|---|---|
| **持续效果** | `DURATION(...)` / `WHILE_*` | MODIFIER、RESTRICTION、LISTENER | 到期或条件满足 |
| **延时效果**（一次性） | `UNTIL_FIRED` | 通常 LISTENER | **第一次** listener 跑完后 Unregister |
| **持续能力（Constant）** | `WHILE_IN_PLAY` | MODIFIER / LISTENER | 源卡 leave play |

**不存在** LastingRegistry / DelayedRegistry；仅 **RegistrationStore**。

### 4.1 合法性（dry-run）

创建 Registration **即** 直接影响（见 [07-composition §4](07-composition.md)）。  
**不**检查创建后 Buff 是否退化、Listener 是否会触发。

---

## 5. 持续生命周期内的 Listener（重要）

### 5.1 一条 Registration，不是两层延时

例：**Until end of your turn, after you fight, draw 1 card.**

```gdscript
Registration {
    lifetime: DURATION(THIS_TURN),
    scope: controller = performer,
    buffs: [
        ListenerBuff {
            timing: AFTER_YOU_FIGHT,
            composition: Draw(1),    # 效果组合，见 07-composition
        },
    ],
}
```

- **持续** = 整条 Registration 活到 **回合结束**（`tick_durations(THIS_TURN)` → Unregister）。
- **Listener** = 生命周期 **内** 每次 `AFTER_YOU_FIGHT` 跑 `Draw(1)`。
- **不是** 内层再 Register 一个 `UNTIL_FIRED` 的「嵌套延时」；就是 **普通 Listener**。

### 5.2 两个时间轴

| 概念 | 含义 |
|---|---|
| **Registration 生命周期** | 规则条 **挂到何时**（turn / phase / test / in-play） |
| **Listener timing** | 生命周期 **内** 哪些时点 **执行** 子 composition |

### 5.3 时间线示例（单回合）

```text
T0  Event resolve → Register（DURATION THIS_TURN + Listener after fight）
T1  Investigate    → 不触发
T2  Fight #1       → Listener → Draw(1)
T3  Fight #2       → Listener → Draw(1)   （除非 Limit once…）
T4  Turn ends      → Unregister → 之后 fight 不再 Draw
```

T0 合法性：Register **已创建** 即通过；**不要求** T2/T3 发生。

### 5.4 多 Buff 同壳

**Until end of investigation phase, you get +1 [willpower], and after you discover a clue, draw 1.**

```text
Registration {
  lifetime: DURATION(THIS_INVESTIGATION_PHASE),
  buffs: [
    Modifier(+1 WILL),
    Listener(AFTER_DISCOVER_CLUE, Draw(1)),
  ],
}
```

一个 Lifecycle 罩住 Modifier + Listener；**一次 RegisterNode**。

### 5.5 与纯延时对比

**At the start of the next mythos phase, draw 1 card.**

```text
Registration {
  lifetime: UNTIL_FIRED,
  buffs: [ Listener(MYTHOS_1_1, Draw(1)) ],
}
```

| | 持续壳 + Listener | 纯延时 |
|---|---|---|
| Lifetime | `DURATION(...)` | `UNTIL_FIRED` |
| Listener 触发次数 | 寿命内 **可多次** | 通常 **一次**（整段 Unregister） |
| 典型文本 | until end of **turn/phase** | at start of **next** …（一次） |

### 5.6 与 Constant 对比

Asset：**After you fight, draw 1**（Constant）

```text
Registration {
  lifetime: WHILE_IN_PLAY,
  buffs: [ Listener(AFTER_YOU_FIGHT, Draw(1)) ],
}
```

与 Event「until end of **your turn**…」结构相同；仅 Lifetime 为 `THIS_TURN` vs `WHILE_IN_PLAY`。

---

## 6. MODIFIER

在 **ModifierQuery** 时改数值（技能、shroud、伤害量、cost…）。Constant 与 Lasting **相同 Payload**，仅 Lifetime 不同。

```gdscript
class ModifierPayload:
    var stat: StatRef
    var op: ModOp
    var value: int
    var stacking: StackingGroup
```

叠加：加算/减算 → 乘除 → ceil → 下限 0（Grimoire Modifiers）。

---

## 7. RESTRICTION

Initiation **dry-run** 与行动合法性：能否打出、移动、commit 等。**统一** `RestrictionEvaluator.block_reason`（L4 / Action / SkillTest / EffectGraph step 4）。

**应用场合**不由规则序列步数决定，而由 **[§16 Buff 应用场合清单](#16-buff-应用场合清单裁决方法)** 的 **Intent × 入口** 主表决定；新增 cannot 时先查 §16.4，再扩 `RestrictionKind` / `Intent` / 接线入口。

```gdscript
class RestrictionPayload:
    var kind: RestrictionKind   # FORBID_DRAW | FORBID_PLAY | FORBID_TRIGGER | FORBID_COMMIT_TO_TEST | …
    var drawer_id: StringName     # 险境 E3：豁免 actor
    var encounter_frame_id: StringName

enum LifetimeKind {
    …
    WHILE_ENCOUNTER_FRAME,   # 非 peril；peril 用 WHILE_DRAWN_CARD_RESOLVING
    WHILE_DRAWN_CARD_RESOLVING,   # 险境 E3 Register；G4 完 Unregister；不跨 Surge
}
```

**险境（Peril）译法** — **ENCOUNTER_CARD_DRAWN** timing · priority **100** · nest Register RESTRICTION；Lifetime **`WHILE_DRAWN_CARD_RESOLVING(card_id)`**（**不跨 Surge**，G4 完 Unregister）。见 [15 §4.0.5.2](15-timing-entry-catalog.md)。

```gdscript
RegistrationTemplate.peril_encounter_frame(drawer_id, frame_id)
# → 1× Registration，3× RESTRICTION buff，Lifetime WHILE_ENCOUNTER_FRAME
# provenance: AbilityUnitRef.from_framework("seq.draw.encounter")  # E3 内联步
```

卡面「本回合不能抽牌」→ `FORBID_DRAW` + `DURATION(THIS_TURN)`。**同 evaluator、同 L4**。

---

## 8. LISTENER

在 **TimingPoint** 执行 **Composition**（[07-composition](07-composition.md)）。

```gdscript
class ListenerPayload:
    var timing: TimingPoint
    var trigger: TriggerKind      # when | at | after
    var composition: CompositionNode
    var player_initiated: bool    # [reaction] / [free]
    var optional: bool
    var limit: LimitSpec
    var initiation_meta: Dictionary
```

| 来源 | Register 时机 | 典型 Lifetime |
|---|---|---|
| 印刷 Forced | enter_play | WHILE_IN_PLAY |
| 印刷 [reaction] | enter_play | WHILE_IN_PLAY |
| 效果创建 lasting | effect resolve | DURATION |
| 效果创建 delayed | effect resolve | UNTIL_FIRED |

**TimingBus**（06 §5.1）：Forced/Delayed 级 Listener → Framework → [reaction]；`UNTIL_FIRED` 的 Registration 在 listener 执行后 Unregister。

**Act flip**（OQ-02-02）：a 面 `WHILE_IN_PLAY` 注销；effect 创建的 `DURATION` / `UNTIL_FIRED` **保留**。

---

## 9. LifetimeSpec

```gdscript
enum LifetimeKind {
    WHILE_IN_PLAY,
    WHILE_SOURCE_IN_PLAY,
    DURATION,
    UNTIL_FIRED,
    UNTIL_CONDITION,
    MANUAL,
}

class DurationAnchor {
    enum Kind {
        THIS_SKILL_TEST, THIS_TURN, THIS_PHASE, THIS_ROUND,
        END_OF_ENCOUNTER, CUSTOM,
    }
}
```

| 卡面信号 | Lifetime |
|---|---|
| until end of **your turn** | `DURATION(THIS_TURN)` |
| until end of **phase** | `DURATION(THIS_PHASE)` |
| for **this skill test** | `DURATION(THIS_SKILL_TEST)` |
| at **start of next mythos**（一次） | `UNTIL_FIRED` |
| 在场 Constant | `WHILE_IN_PLAY` |

**After / When** → Listener 的 `timing`；**until / for** → Registration 的 `lifetime`。

Duration tick **先于** 同边界「at end of phase」的 Listener（Grimoire Lasting Effects）。

---

## 10. Scope / Condition

见 v0.1 §5.1–5.2（ScopeFilter、Condition）；所有 BuffType 共用。

---

## 11. RegistrationStore

```gdscript
class RegistrationStore:
    func register(reg: Registration) -> StringName
    func unregister(id: StringName) -> void
    func collect(type: BuffType, ctx: ApplicationContext) -> Array[BuffSpec]
    func tick_durations(anchor: DurationAnchor.Kind, ctx: ApplicationContext) -> void
    func on_card_enter_play(card_id, templates: Array[RegistrationTemplate]) -> void
    func on_card_leave_play(card_id: StringName) -> void
```

---

## 12. ApplicationContext

**场合 = 正交维度拼凑**；**订阅键**只用其中粗索引（见 [06-ability-initiation §4.1](06-ability-initiation.md)）。修正值 / 监听 / Initiation **共用** `Condition.matches(ctx)`。

```gdscript
class ApplicationContext:
    var timing: StringName              # 粗时点名；L0 辅助
    var framework_step: FrameworkStep
    var controller_id: StringName
    var tags: Array[StringName]         # 开放集合；L3 情景，非封闭 enum
    var trigger: TriggeringCondition
    var payload: Dictionary
    var referents: Dictionary           # RulesMemory；历史条件
    var skill_test: SkillTestContext    # 检定时填充
    var pending: PendingResolution      # Cancel/Replace 窗口
    var initiation: InitiationIntent
```

| 维度 | 典型用途 | 订阅 L0 | 门槛 L3 |
|---|---|---|---|
| `timing` / 阶段+事件族 | 何时叫醒 | ✅ | — |
| `framework_step` | 仅 Upkeep 4.4 等 | ❌ | ✅ |
| `tags` | `framework`、`resource_action` | ❌ | ✅ |
| `controller_id` | 「当你…」 | 注册 scope | ✅ |
| `skill_test` | 本次检定 | ❌ | ✅ |
| `pending` | Instead / Cancel | 特殊 hook | ✅ |
| `payload` / `referents` | 数量、上一次… | ❌ | ✅ |

**不**为每种 stat×场合建枚举（如 `GainSourceKind`）；调查员 Upkeep 4.4 gain +1 = `framework_step` + `tags_all: [framework, gain_resource]`。

实现：`core/timing/application_context.gd`、`core/timing/condition.gd`。Eligibility 关卡见 [06 §5](06-ability-initiation.md)；时点入口见 **[15-timing-entry-catalog.md](15-timing-entry-catalog.md)**。

---

## 13. 编译与进场

```gdscript
class AbilityCompiler:
    func compile_card(def: CardDefinition) -> Array[RegistrationTemplate]:
        # 扫 lifetime 短语 + listener timing；不信 Constant/Forced 标题
        # keywords → MODIFIER/RESTRICTION/LISTENER 模板
        ...
```

`on_card_enter_play` → 展开 template → `register`。

---

## 14. 与旧概念映射

| 旧概念 | 新模型 |
|---|---|
| Constant | Register + WHILE_IN_PLAY |
| Lasting effect | Register + DURATION |
| Delayed effect | Register + UNTIL_FIRED + LISTENER |
| Forced / [reaction] | Register + LISTENER（或 enter_play template） |
| 关键词 Surge 等 | keywords + 编译，非 BuffType |

---

## 15. 实现顺序

| 阶段 | 交付 |
|---|---|
| P1 | BuffType×3、ModifierEngine、RegistrationStore |
| P2 | Lifetime tick、Scope/Condition |
| P3 | RESTRICTION + Initiation dry-run |
| P4 | LISTENER + TimingBus |
| P5 | CompositionExecutor + RegisterNode |
| P6 | AbilityCompiler、keywords |

---

## 16. Buff 应用场合清单（裁决方法）

> **已裁决**：译 Grimoire / 实现卡面时，**用本清单决定 Buff 类型与应用站点**；禁止为段落或 `seq.*` 砖块逐步发明平行查询逻辑。  
> **Intent / StatRef / Timing** 会随实现增长；**入口站点**相对稳定（动作系统、Initiation、Effect 提交、数值查询站）。

### 16.1 总流程（译前先过四问）

```text
Grimoire 条文 / 卡面效果
  │
  ├─ Q1 改数值（+1 skill、gain +1 resource）？
  │     → MODIFIER → §16.3 查询站清单
  │
  ├─ Q2 禁止/允许某类动作或效果（cannot、immune、peril）？
  │     → RESTRICTION → §16.4 Intent×入口；Register 时机见 §16.7
  │
  ├─ Q3 某时点后执行子效果（When/After/Forced/[reaction]）？
  │     → LISTENER → §16.5 Timing 清单（详表 [15 §17](15-timing-entry-catalog.md)）
  │
  └─ Q4 以上皆否？
        → §16.6 非 Buff 路由（Domain 不变量 / L7 dry-run / Pipeline / Setup）
```

**Register 时机**（何时挂 Buff）仍由 **命名规则序列** 的 REGISTER 砖块或卡 `enter_play` 决定（[effect-translation.mdc](../../.cursor/rules/effect-translation.mdc)）；**本清单解决的是「挂好后在哪查、在哪生效」**。

### 16.2 第一关：是否 Buff？

| Grimoire / 卡面现象 | Buff？ | 实际路由 |
|---|---|---|
| cannot play / trigger / draw / commit（含 peril、lasting） | **RESTRICTION** | §16.4 |
| +N skill / shroud / damage amount / gain amount | **MODIFIER** | §16.3 |
| After you X, do Y / Forced / [reaction] | **LISTENER** | §16.5 |
| exhausted 不能再 exhaust | **否** | Domain：`set_flag` / exhaust 入口状态检查 |
| target 不合法不能 initiate | **否** | Eligibility **L7** `CompositionDryRunner` |
| assign 超过 asset 血量 | **否** | `DamagePipeline.assign` 规则 |
| deck 不能带两张同名 | **否** | Setup / deckbuild 校验 |
| Permanent 不能离场 | **混合** | Domain 关键词 + 可能 **MOVE** Intent（§16.4） |
| Immune to treachery / player card effects | **RESTRICTION** | EffectGraph step 4 + `EffectOp`→Intent |
| Aloof 不能攻击未 engage 敌人 | **RESTRICTION** | **FIGHT** Intent + `Condition`（engage 状态） |
| Instead / Cancel | **否** | [07-composition](07-composition.md) `CancelPending` / `ReplacePending` |
| Surge / Massive 流程 | **否** | 关键词 + **命名 seq**（非 BuffType） |
| 抽牌 D2 / 遭遇 E2 **Reveal** | **否**（非 Buff） | L0 **`AtomRevealCard`** / `StateMutator.reveal_to_*`；见 [07 §5.3](07-effect-primitives.md) |

### 16.3 MODIFIER · 查询站清单

**模式**：Register MODIFIER → 在 **下列站点** 调用 `ModifierEngine.compute(base, query, app_ctx)`；`Condition.matches(app_ctx)` 过滤场合。

| 查询站 ID | 何时调用 | `StatRef` | 典型 `ApplicationContext` | 状态 |
|---|---|---|---|---|
| **MOD-Q-SKILL** | 检定 ST.5 算 modified value | `SKILL_WILLPOWER` … `SKILL_AGILITY` | `skill_test` 填充 | **已实现**（`SkillTestEngine.step_calculate_modified_value`） |
| **MOD-Q-GAIN-RES** | `seq.gain_resource` 落 resource 前 | `RESOURCE_GAIN_AMOUNT` | `framework_step` + `tags`（如 `gain_resource`） | **已实现**（`SequenceCatalogBootstrap._resolve_gain_resource`） |
| **MOD-Q-SHROUD** | 地点 investigate 算 difficulty | `SHROUD`（待 enum） | location + tags | 待实现 |
| **MOD-Q-DAMAGE-AMT** | Deal damage Assign 前定 amount | `DAMAGE_AMOUNT`（待 enum） | source、target tags | 待实现 |
| **MOD-Q-HORROR-AMT** | Deal horror Assign 前 | `HORROR_AMOUNT`（待 enum） | 同上 | 待实现 |
| **MOD-Q-COST** | Initiation L6 前 | `ACTION_COST` / resource cost（待 enum） | `initiation` | 待实现 |

**新增 MODIFIER 卡面**：先在本表 **登记查询站**（或复用已有站 + `Condition`），再扩 `StatRef`；**不要**在 `seq.*` handler 内散落 `if card_id`.

### 16.4 RESTRICTION · Intent × 入口主表

**模式**：Register RESTRICTION（`RestrictionKind` + payload）→ 在 **入口** 调 `RestrictionEvaluator.block_reason(intent, actor, store, ctx)`。  
**`Intent`** 对齐 **可被禁止的动作/效果类**（与 `ActionType` / Initiation / 关键 `EffectOp` 同族），**不对齐** `seq.*` 砖块编号。

#### 16.4.1 入口站点（稳定层）

| 入口 ID | 子系统 | 检查时机 | 典型 Intent |
|---|---|---|---|
| **REST-E-PLAY** | `ActionSystem` play asset/event | 付 cost / commit play 前 | `PLAY` |
| **REST-E-TRIGGER** | `EligibilityPipeline` L4 | COLLECT / PRE_INITIATE | `TRIGGER` |
| **REST-E-DRAW** | `CompositionExecutor` draw atom | execute 前 | `DRAW` |
| **REST-E-COMMIT** | `SkillTestEngine.commit_card` | commit 前 | `COMMIT_TO_TEST` |
| **REST-E-ACTION** | `ActionSystem.execute` | 耗 action、发起 basic action 前 | `MOVE` `ENGAGE` `FIGHT` …（待扩） |
| **REST-E-EFFECT** | `EffectResolutionGraph` step 4 / Composition 等价点 | submit `EffectRequest` 前 | 按 `EffectOp`→Intent（待接） |
| **REST-E-ACTIVATE** | Asset `[action]` / `[free]` initiation | Pre-restrictions | `ACTIVATE`（待 enum） |

L4 与专用入口 **双查**（COLLECT 筛 eligible + 动作前再拦）对 **同一 Intent** 均可；payload / `drawer_id` 豁免在 `_matches` 内处理。

#### 16.4.2 Intent 与 RestrictionKind（增长表）

| Intent（`RestrictionEvaluator`） | 对齐 | 典型 `RestrictionKind` | Grimoire / 卡面来源 | 入口 | 状态 |
|---|---|---|---|---|---|
| `DRAW` | 抽牌 | `FORBID_DRAW` | peril 无关；卡面「不能抽牌」 | REST-E-DRAW | **已实现** |
| `PLAY` | 打出 asset/event | `FORBID_PLAY` | peril E3；immune play | REST-E-PLAY | Kind **已实现**；**ActionSystem 待接** |
| `TRIGGER` | initiate 能力 | `FORBID_TRIGGER` | peril E3；[reaction]/Forced | REST-E-TRIGGER | Kind **已实现**；**L4 待接** |
| `COMMIT_TO_TEST` | commit skill | `FORBID_COMMIT_TO_TEST` | peril E3 | REST-E-COMMIT | **已实现** |
| `LEAVE_HAND` | 卡牌离开 HAND（move / discard / spawn 等） | `FORBID_LEAVE_HAND` | 隐私（Hidden）E4 | REST-E-MOVE（`StateMutator.move_card`） | **已实现** |
| `MOVE` | 移动行动 / 效果移动调查员 | `FORBID_MOVE` | 「不能离开地点」 | REST-E-ACTION / REST-E-EFFECT | 待 enum + 接线 |
| `ENGAGE` | engage 行动 | `FORBID_ENGAGE` | aloof 等（常配合 Condition） | REST-E-ACTION | 待 |
| `FIGHT` | fight / 攻击敌人 | `FORBID_ATTACK` | aloof 未 engage | REST-E-ACTION | 待 |
| `INVESTIGATE` | investigate 行动 | `FORBID_INVESTIGATE` | 地点规则 | REST-E-ACTION | 待 |
| `EVADE` | evade 行动 | `FORBID_EVADE` | — | REST-E-ACTION | 待 |
| `ACTIVATE` | 启动 asset 能力 | `FORBID_ACTIVATE` | 「不能启动」 | REST-E-ACTIVATE | 待 |
| `DISCARD` | 从手牌弃牌（非自愿） | `FORBID_DISCARD` | weakness 等 | REST-E-EFFECT | 待 |
| `GAIN_HORROR` | 受到 horror | `FORBID_GAIN_HORROR` | 「不能受到 horror」 | REST-E-EFFECT | 待 |
| `GAIN_DAMAGE` | 受到 damage | `FORBID_GAIN_DAMAGE` | 同上 | REST-E-EFFECT | 待 |
| `SEARCH` | search 牌库/集合 | `FORBID_SEARCH` | — | REST-E-EFFECT | 待 |
| `CONFER` | peril 商议 | —（peril 用 PLAY/TRIGGER/COMMIT 覆盖） | Grimoire peril | — | 不单独 Intent |

**扩 Intent 规程**：① 在本表加一行；② 扩 `AhcEnums.RestrictionKind` + `RestrictionEvaluator._matches`；③ **只接一个入口 ID**；④ 卡面 Register 仍走 REGISTER 砖块，**禁止**新 Policy 类。

#### 16.4.3 EffectOp → Intent（REST-E-EFFECT 映射草案）

| `EffectOp` | Intent | 备注 |
|---|---|---|
| `DRAW_CARDS` | `DRAW` | 与 REST-E-DRAW 同 Intent |
| `GAIN_RESOURCE` | `GAIN_RESOURCE`（待） | 或 MODIFIER 减 amount + RESTRICTION 禁 entirely |
| `DEAL_HORROR` / `DEAL_DIRECT_HORROR` | `GAIN_HORROR`（待） | target 侧查 |
| `DEAL_DAMAGE` / `DEAL_DIRECT_DAMAGE` | `GAIN_DAMAGE`（待） | 同上 |
| `MOVE_INVESTIGATOR` | `MOVE` | |
| `DISCARD_CARDS` | `DISCARD` | |
| `SEARCH_DECK` | `SEARCH` | |
| `EXHAUST` / `READY` | `EXHAUST` / `READY`（待） | 效果层 vs 行动层 |
| `ENGAGE` / `DISENGAGE` | `ENGAGE` / `DISENGAGE`（待） | |

Immune（「immune to player card effects」）→ `RESTRICTION` + `Condition`（source tags）+ REST-E-EFFECT，**不是**新 BuffType。

### 16.5 LISTENER · Timing 订阅清单

**模式**：Register LISTENER → `TimingBus` / `ResolutionSequenceStack` 在 **Catalog 规范时刻** emit → Eligibility L0–L5 → Initiation → Composition。

| 清单项 | 订阅键 | emit 责任 | 文档索引 |
|---|---|---|---|
| 框架 after fight / draw / … | `timing` 字符串 或 `(sequence_id, AFTER)` | 框架 / Combat / draw seq pop | [15 §17](15-timing-entry-catalog.md) |
| 命名 seq WHEN/AFTER | `(sequence_id, WOULD\|WHEN\|AFTER)` | 对应 `seq.*` 砖块边界 | [15 §4](15-timing-entry-catalog.md)、[14](14-nested-sequences.md) |
| 卡面 [reaction] | `ListenerPayload.timing` + `player_initiated` | 同上；COLLECT 开窗 | [06-ability-initiation §5](06-ability-initiation.md) |
| UNTIL_FIRED 延时 | 同 timing；Lifetime 摘 registration | listener 跑完 unregister | §4.1 |

**新增 LISTENER**：先在 [15](15-timing-entry-catalog.md) 登记 TimingEntry / emit 点，再在本节补一行；**不要**为每张卡 invent 新 emit 通道。

### 16.6 非 Buff 路由（Q4 出口）

| 现象 | 机制 |
|---|---|
| 结构 / 牌组合法性 | Setup、deckbuild |
| 目标不存在、效果空转 | Eligibility L7 |
| Assign / prevent / soak | `DamagePipeline` + Wrapper |
| Instead 竞争 | `PendingResolution` + initiation_seq |
| 区域不变量（leave play token→pool） | `StateMutator` / [01 §5](01-game-state-zones.md) |
| 关键词流程（Surge 再抽） | **G5** nest evaluate + 再抽 G1（**G4 后**；不在 G1 Register） |
| **Reveal 卡牌**（D2/E2、窥探） | L0 `reveal_to_*`（**是效果**，非 Buff）；见 [07 §5.3](07-effect-primitives.md) |

### 16.7 Register 时机 vs 查询时机（对照）

| | Register（挂 Buff） | 查询（生效） |
|---|---|---|
| **险境** | E3 砖块 `REGISTER` | REST-E-PLAY / TRIGGER / COMMIT |
| **卡面 lasting cannot draw** | 效果 resolve REGISTER | REST-E-DRAW |
| **Asset Constant +1 Will** | `enter_play` template | MOD-Q-SKILL |
| **Until end of turn after fight draw 1** | 效果 resolve REGISTER | LISTENER timing + MOD/DRAW 子 Composition |

**规则序列多** → Register 时机多；**查询站点**仍按 §16.3–§16.5 **有限入口**扩展，而非每 seq 一步一查。

### 16.8 Core 2026 回填（ArkhamDB · Phase 4）

> **详表**：[`data/arkhamdb/reports/phase4_core_2026_backfill.md`](../../data/arkhamdb/reports/phase4_core_2026_backfill.md)  
> **生成**：`python tools/backfill_design_tables.py`（依赖 `tools/arkhamdb_import.py` 产出）

#### 16.8.1 MODIFIER（§16.3 增长）

| 卡面模式 | Core 2026 命中 | 查询站 |
|---|---:|---|
| `+N [skill]` / fight / evade | 24 | **MOD-Q-SKILL**（已实现） |
| `+N damage` | 11 | **MOD-Q-DAMAGE-AMT**（待 enum） |
| `+N shroud` | 1 | **MOD-Q-SHROUD**（待 enum） |
| `-N cost` | 0 | **MOD-Q-COST**（待 enum） |

#### 16.8.2 RESTRICTION（§16.4.2 样例）

| Intent 分类 | 张数 | 代表卡 |
|---|---:|---|
| `DOMAIN_PERMANENT` | 2 | 12012 The Necronomicon；12098 The Gold Bug |
| `FORBID_PLAY` | 1 | 12193 Langour |
| `FORBID_MOVE` | 1 | 12179 Elokoss（敌人指令 + 调查员禁移动） |
| `IF_YOU_CANNOT` | 5 | 条件分支，**非** Register RESTRICTION |
| `IMMUNITY` | 2 | 12169/12170 attached cannot be damaged |
| 待人工 | 1 | 12179b cannot attack you（回合 scope） |

#### 16.8.3 LISTENER（§16.5 增长）

| 订阅线索 | Core 2026 命中 | 引擎路由 |
|---|---:|---|
| Hunter 关键词 | 13 | 敌人 phase · `hunter_patrol_move`（待接 LISTENER） |
| Retaliate 关键词 | 9 | 攻击后 handler（见 08 §6） |
| `After you discover clues` | 6 | `after_clue` → TimingBus 增长 |
| `When investigation phase ends` | 4 | 框架步 AFTER |

---

## 17. StatProjection（历史谓词读模型）

> **详文**：[06c-stat-projections.md](06c-stat-projections.md)

Eligibility **L3/L5** 所需 **历史谓词**（本 turn action 次数等）**不是** Buff，**不**写入 `RegistrationStore` payload；由并行组件 **StatProjectionStore** 管理读模型：

| 时机 | 行为 |
|---|---|
| `register()` | `StatProjectionStore.attach(reg_id, template.stat_queries, scope)` — **DORMANT** |
| `TimingCatalog` → COLLECT | 首次 demand → **cold fold** `EventRecord` → **HOT** |
| Emitter | `on_event` 仅更新 HOT 投影 |
| `unregister()` / duration tick | `detach(reg_id)` → ref=0 丢弃 HOT |

**权威源** = `EventRecord`；**禁止**从 Domain 压扁字段推导 spend 次数。

`AbilityCompiler.compile_card` 产出 `stat_queries[]`（与 `RegistrationTemplate[]` 并列）。

---

## 18. 开放问题

| ID | v1 默认 |
|---|---|
| OQ-BUFF-03 | Forced/Delayed Listener **直跑 Composition**；[reaction] **完整 Initiation** |
| OQ-BUFF-04 | Lasting 默认 **不** 随源卡 leave play 结束；`WHILE_SOURCE_IN_PLAY` 才绑源卡 |

---

## 19. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-06-18 | v0.4.1 | **§17** StatProjection 读模型；链 [06c](06c-stat-projections.md) |
| 2026-06-18 | v0.4 | **§16** Buff 应用场合清单；Reveal 走 L0 非 Buff |
| 2026-05-25 | v0.3 | ApplicationContext 拼凑式场合；订阅键 vs L3 情景；链到 Eligibility L0–L7 |
| 2026-05-25 | v0.2 | Buff 三种；删 FRAME/PENDING；持续/延时=Lifetime；持续壳内 Listener 详述；dry-run 见 07-composition |
| 2026-05-25 | v0.1 | 初稿 |
