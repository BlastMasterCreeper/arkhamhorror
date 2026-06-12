# 06b — Registration 与 Buff 规格 (统一能力模型)

> **依赖**：[06-ability-initiation.md](06-ability-initiation.md), [07-effect-primitives.md](07-effect-primitives.md), [07-composition.md](07-composition.md)  
> **被依赖**：TimingBus、ModifierEngine、Initiation dry-run  
> **状态**：v0.2 · 2026-05-25

---

## 1. 目标

用 **Register / Unregister + Buff + Context** 统一理解全部能力与持续/延时效果。

- **印刷能力类型**（Constant / Forced / 🕭 / 🕮）→ 编译期 **tags**，不是运行时分支。
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
    RESTRICTION,    # 被动禁止/允许
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

**Until end of investigation phase, you get +1 🕓, and after you discover a clue, draw 1.**

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

Initiation **dry-run** 与行动合法性：能否打出、移动、commit 等。

```gdscript
class RestrictionPayload:
    var kind: RestrictionKind
    var params: Dictionary
    var polarity: Polarity
```

---

## 8. LISTENER

在 **TimingPoint** 执行 **Composition**（[07-composition](07-composition.md)）。

```gdscript
class ListenerPayload:
    var timing: TimingPoint
    var trigger: TriggerKind      # when | at | after
    var composition: CompositionNode
    var player_initiated: bool    # 🕭 / 🕤
    var optional: bool
    var limit: LimitSpec
    var initiation_meta: Dictionary
```

| 来源 | Register 时机 | 典型 Lifetime |
|---|---|---|
| 印刷 Forced | enter_play | WHILE_IN_PLAY |
| 印刷 🕭 | enter_play | WHILE_IN_PLAY |
| 效果创建 lasting | effect resolve | DURATION |
| 效果创建 delayed | effect resolve | UNTIL_FIRED |

**TimingBus**（06 §5.1）：Forced/Delayed 级 Listener → Framework → 🕭；`UNTIL_FIRED` 的 Registration 在 listener 执行后 Unregister。

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

```gdscript
class ApplicationContext:
    var timing: TimingPoint
    var framework_step: FrameworkStep
    var modifier_query: ModifierQuery
    var initiation: InitiationIntent
    var skill_test: SkillTestContext
    var pending: PendingResolution
    var payload: Dictionary
```

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
| Forced / 🕭 | Register + LISTENER（或 enter_play template） |
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

## 16. 开放问题

| ID | v1 默认 |
|---|---|
| OQ-BUFF-03 | Forced/Delayed Listener **直跑 Composition**；🕭 **完整 Initiation** |
| OQ-BUFF-04 | Lasting 默认 **不** 随源卡 leave play 结束；`WHILE_SOURCE_IN_PLAY` 才绑源卡 |

---

## 17. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | Buff 三种；删 FRAME/PENDING；持续/延时=Lifetime；持续壳内 Listener 详述；dry-run 见 07-composition |
