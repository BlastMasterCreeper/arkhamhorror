# 07 — 效果解析与修饰 (EffectResolutionGraph)

> **依赖**：[01-game-state-zones.md](01-game-state-zones.md), [06-ability-initiation.md](06-ability-initiation.md), **[07-effect-primitives.md](07-effect-primitives.md)（L0 原子）**, **[07-composition.md](07-composition.md)（效果组合）**  
> **规则来源**：Grimoire Dealing Damage/Horror, Effects, Target, Instead, Cancel, Modifiers

---

## 0. 与原子层 / 效果组合的关系

- **L0 原子**：`MoveCard` / `TransferMarker` / … — 见 [07-effect-primitives.md](07-effect-primitives.md)
- **效果组合 Composition**：L0/L1/L2 组合树 + dry-run — 见 [07-composition.md](07-composition.md)
- **Registration / Buff**：规则表 — 见 [06-registration-buff-model.md](06-registration-buff-model.md)

下文 `EffectOp`、`EffectRequest` 在实现上应 **编译为 CompositionTree**，而非与原子并列的第三套执行分支。

---

## 1. 目标

将所有游戏效果统一为 **EffectRequest DAG**，处理 Target、Cancel/Ignore/Instead、Then、For each、Damage 两步、Modifiers 重算。

---

## 2. EffectRequest 原语

```gdscript
enum EffectOp {
    DEAL_DAMAGE,
    DEAL_HORROR,
    DEAL_DIRECT_DAMAGE,
    DEAL_DIRECT_HORROR,
    HEAL,
    TRANSFER_AFFLICTION,       # Moving damage/horror；不算 heal（OQ-07-02）
    DISCOVER_CLUE,
    PLACE_CLUE,
    SPEND_CLUE,
    GAIN_RESOURCE,
    SPEND_RESOURCE,
    DRAW_CARDS,
    DISCARD_CARDS,
    MOVE_INVESTIGATOR,
    MOVE_ENEMY,
    SPAWN_ENEMY,
    ENGAGE,
    DISENGAGE,
    EVADE_AUTO,
    DEFEAT,
    EXHAUST,
    READY,
    ATTACH,
    ADVANCE_ACT,
    ADVANCE_AGENDA,
    PLACE_DOOM,
    REMOVE_DOOM,
    SEARCH_DECK,
    SHUFFLE,
    EXILE,
    CUSTOM,                    # CardScript 扩展
}

class EffectRequest:
    var op: EffectOp
    var source: EffectSource
    var controller: StringName
    var targets: Array[EntityId]
    var amount: int
    var options: Dictionary      # skill, location, filters, ...
    var then_chain: Array[EffectRequest]
    var is_optional: bool
    var replacement_id: StringName
```

卡牌脚本通过 `EffectBuilder` 构建，**禁止**直接改 `GameStateStore`。

```gdscript
EffectBuilder.deal_horror(1).to_investigator(id).from_source(src).submit(ctx)
EffectBuilder.discover_clue(1).at_location(loc).submit(ctx)
```

---

## 3. 解析管线

```gdscript
class EffectResolutionGraph:
    func submit(request: EffectRequest) -> EffectResult
    func submit_batch(requests: Array[EffectRequest], simultaneous: bool) -> Array[EffectResult]
```

### 3.1 单请求流程

```
1. Validate targets
2. 若本请求已被 Cancel（见 §6.1）→ abort（视为未发生）
3. 若 Replacement 已生效（见 §7.1）→ 执行替换后效果，跳过原 op
4. Check Cannot — RESTRICTION / 卡面「cannot」绝对拦截（§3.2）
5. Pay embedded costs（若有）
6. Execute op
7. Emit timing events（after/when）
8. Process then_chain（then 优先于 step 7 产生的 after）
```

**Cancel 与 Replacement 的先后**不在此线性步骤内硬编码，而在 **TimingBus 触发顺序** 中裁决（§6.1、§7.1）。

### 3.2 冲突与竞争：总览

Grimoire 无单一「平级竞争总表」；引擎将 **不同机制** 分型。**Cannot** 与 **同时点竞争** 不是同一类——前者 **禁止**，后者 **多条 handler 争同一 impact**。

```text
同一 pending / timing 窗口
  ├─ 0. Cannot（非竞争）→ X 不得发生
  ├─ 1. 同时点竞争（§3.3）→ 子类型各有裁决器
  ├─ 2. Cancel / Ignore vs Replacement → resolve 先后（§6.1）
  ├─ 3. 跨类 tier 整批（06 §8.1）
  ├─ 4. Silver Rule → 两卡文本无法调和（非 replacement 栈）
  └─ 5. 合法多选 → Lead / 控制者（Grim 不参与）
```

| 机制 | Grimoire | 是否「同时点竞争」 | 裁决 |
|---|---|---|---|
| **Cannot** | *Cannot* | **否**（绝对禁止） | 不得 countermand |
| **Replacement** | *Instead* | **是**（子类 **替换竞争**） | **最后 initiate** 的一条（§3.4、§7） |
| **Forced / Triggered 等同窗** | Ability + *Priority of Simultaneous Resolution* | **是**（**能力竞争**） | 跨类 tier；类内队长/控制者自排（06 §8） |
| **Cancel / Ignore** | Cancel 词条 | 打断 pending，非平级表 | 与 Replacement **看谁先 resolve** |
| **Silver Rule** | *The Silver Rule* | **否**（文本命题冲突） | 遭遇 > 玩家；同类 → 队长 |
| **合法多选** | Locked Door 先例 | **否** | Lead / 控制者任选 valid |
| **Grim Rule** | *The Grim Rule* | — | **实体**查书受阻兜底；**电子版**见 [00 §6](../00-architecture-overview.md) |

**Cannot 示例**（非 Silver、非 replacement 竞争）：

```text
「你不能受到 horror。」+「受到 2 horror。」→ horror 不发生；无需 Silver Rule。
险境（Peril）帧内：非 drawer **cannot** play asset/event、**cannot** trigger、**cannot** commit skill 到 drawer 检定 → 不进入 tier 竞争；[fast] 亦无效。见 [04 §4](04-skill-test-engine.md)。
```

### 3.3 同时点竞争（Same-timing competition）

**定义**：同一 **triggering condition** / **Timing Window** 内，多条能力或效果 **同时成为 handler**（含 LISTENER、Forced、[reaction]、**Replacement**），且不能全部按原文成立。

Replacement **是** 同时点上的 listener/能力；与 Forced、[reaction] 共享窗口，但 **冲突裁决** 走 **Instead**，不是 Silver Rule，也 **不是** encounter>player 泛化规则。

| 子类型 | 典型 | 同优先级？ | 裁决 | 玩家自排？ |
|---|---|---|---|---|
| **替换竞争** | 多条 `instead` / `would` 改同一 trigger 的 resolution | 是（同属 replacement） | **最后 initiate 的一条**（§3.4） | **否**（自动）；Forced 同时时 **先** 由队长定 initiate/resolve **顺序**，顺序决定「最近」 |
| **Forced 类内** | 多个 Forced 同 timing | 是（同属 FORCED tier） | 队长选 resolve 顺序（*Priority of Simultaneous Resolution*） | **是**（队长） |
| **Triggered 类内** | 多个 [reaction] 均已选用 | 是（同属 TRIGGERED tier） | 队长选顺序（OQ-06-03） | 选用：控制者；顺序：队长 |
| **跨类** | Forced vs [reaction] | **否** | FORCED 批 **整类先于** TRIGGERED 批（06 §8.1） | **不可**跨类对调 |

**Grimoire · Priority of Simultaneous Resolution**（与 Instead **配合**，非替代）：

- 遭遇 Forced **先于** 玩家 Forced initiate/resolve；
- 多个 Forced **同时** → 队长定 **顺序**；
- 若其中多条为 **冲突的 replacement**，在该顺序下 **后 initiate / 后 resolve 的那条** = Instead 的 **most recent**。

### 3.4 Replacement：「最近」= 最后 initiate

Grimoire *Instead*（[`arkham-grimoire-v1.0.md`](../reference/arkham-grimoire-v1.0.md) · **Instead**）：

> …multiple replacement effects are **initiated** against the **same triggering condition** and **create a conflict**… the **most recent** replacement effect is used…

**引擎定义（OQ-06-01 / OQ-REPL-01）**：

| 术语 | 含义 |
|---|---|
| **initiated** | 该 replacement 能力 **开始 Initiation Sequence**（Forced 自动发起；Triggered 经控制者选用后发起） |
| **most recent** | 同一 `triggering_condition_id` 上、已 initiate 且 **resolution 互斥** 的 replacement 集合中，**`initiation_seq` 最大** 的一条 |
| **conflict** | 对同一 triggering condition 的 resolve 路径 **不能同时成立**（非所有同 trigger 的 instead 都竞争） |

```gdscript
## 单调序号：每次 Initiation COMMENCE 对 pending_trigger 递增。
var initiation_seq: int

func resolve_replacement_conflict(
    candidates: Array[ReplacementCandidate]
) -> ReplacementCandidate:
    candidates.sort_custom(func(a, b): return a.initiation_seq < b.initiation_seq)
    return candidates[candidates.size() - 1]
```

**Would 层（先于「最近」比较）**：`When X would occur` **先于** `When X occurs`；would-replacement **改变** condition 性质后，**不得**再引用 **原始** condition——后续 when 型 replacement 可能 **不进入** 竞争集合。

**不是「最近」**：卡牌注册序、LIFO nest pop 序、encounter cardtype（除非走 Silver Rule 文本冲突）。

```gdscript
func check_cannot(req: EffectRequest, ctx: ApplicationContext) -> bool:
    return RestrictionEvaluator.blocks(req, ctx.registrations)
```

---

## 4. Deal Damage / Horror（两步）

Grimoire p.8：

### Step 1 Assign

- 确定 amount
- Investigator 可分配到 eligible assets（有 health/sanity）
- 不超过 asset 将 defeat 的量
- 剩余 → investigator 卡
- Direct：必须 investigator 卡

**Between 1 and 2**：prevent / reduce / reassign 能力

### Step 2 Apply

- 同时放置 tokens
- 若未 apply 任何 → 未 successfully dealt
- 检查 defeat：investigator / enemy / asset

```gdscript
class DamagePipeline:
    func deal(dealt: DamageDealt) -> void:
        var assignment := assign(dealt)      # 可插入 prevent
        apply(assignment)                     # 同时 apply
        check_defeat(assignment.affected)
```

### 4.1 Moving damage / horror（已裁决 OQ-07-02）

卡牌文本 **Move / Move 1 damage / Move 1 horror**（从 A 转移到 B）使用独立原语 **`EffectOp.TRANSFER_AFFLICTION`**，**不算 heal**。

| | `HEAL` | `TRANSFER_AFFLICTION` |
|---|---|---|
| 语义 | 移除 affliction（治疗） | 在实体间 **移动** 已有 token |
| 触发「After heal」等 | 是 | **否** |
| 走 DamagePipeline assign | 否 | 否（源减、目标加，原子操作） |
| defeat 检查 | 视 heal 规则 | 转移后双方检查 |

```gdscript
enum AfflictionKind { DAMAGE, HORROR }

class TransferAfflictionRequest:
    var from: EntityId
    var to: EntityId
    var kind: AfflictionKind
    var amount: int

func execute_transfer(req: TransferAfflictionRequest) -> void:
    remove_tokens(req.from, req.kind, req.amount)
    add_tokens(req.to, req.kind, req.amount)
    check_defeat([req.from, req.to])
    timing_bus.emit("affliction_transferred", req)   # 非 "healed"
```

```gdscript
EffectBuilder.transfer_damage(1).from(asset_a).to(asset_b).submit(ctx)
EffectBuilder.transfer_horror(1).from(inv).to(enemy).submit(ctx)
```

---

## 5. Target 规则

- 无 valid target → 效果 **fail to initiate**（整个 ability 不可启动）
- 多 target 同时选
- 「Any number」不可选 0
- 多效果 on 一 target：至少一个可改变 state 则 valid
- 「Each enemy」：至少一个 valid 即可 initiate，invalid 跳过

---

## 6. Cancel vs Ignore

### 6.0 统一译法（Cancel / Ignore 卡面）

**一切** Cancel / Ignore 类 Card Ability 均译为 **`seq.interrupt.*` 命名流程**，携带同一 **`InterruptTarget`** 描述符；**禁止**为单卡保留 `cancel_revelation` 等平行 Service。

```text
Cancel / Ignore 卡面
  → AbilityCompiler 选定 timing entry（[reaction] / Forced when…）
  → composition 内 nest 或 L2 Interrupt 节点
  → seq.interrupt.cancel | seq.interrupt.ignore { target: InterruptTarget }
  → InterruptHandler 按 target.kind 分发到对应运行时
```

| 卡面 archetype | catalog | `InterruptTarget.kind` | bind 示例 |
|---|---|---|---|
| Cancel revelation / treachery | `seq.interrupt.cancel` | **SEQUENCE** | `flow_id: seq.encounter.revelation`, `bind: { card_id }` |
| Cancel 某 initiation | `seq.interrupt.cancel` | **SEQUENCE** | `flow_id` + RulesMemory referent |
| Ignore costs | `seq.interrupt.ignore` | **COST** | `bind: { cost_slot, ability_id }` |
| Ignore Retaliate / Alert 等 | `seq.interrupt.ignore` | **KEYWORD** | `keyword: retaliate`, `scope: { fight_id }` |
| Ignore chaos token modifier | `seq.interrupt.ignore` | **CHAOS_TOKEN** | `scope: { skill_test_id, token_id }` |
| 竖切：pending EffectOp | 同上 | **IMPACT** | `pending_id`（占位；非卡面长期译法） |

**Mode 与 Kind 分离**：

- **Mode**（`cancel` / `ignore`）= 卡面 Cancel 词条 vs Ignore 词条 → 选 `seq.interrupt.cancel` 或 `.ignore`。
- **Kind** = 运行时 **绑定对象**；同一 Mode 下不同 Kind 走不同分支（见 §6 表）。

```gdscript
class InterruptTarget:
    enum Kind { SEQUENCE, IMPACT, COST, KEYWORD, CHAOS_TOKEN }
    var kind: Kind
    var flow_id: StringName      # SEQUENCE
    var pending_id: StringName   # IMPACT 竖切占位
    var keyword: StringName      # KEYWORD
    var bind: Dictionary
    var scope: Dictionary
```

**Composition 对齐**（[07-composition §3](07-composition.md)）：

- 推荐：`catalog.nest(game_ctx, &"seq.interrupt.cancel", { "target": … })`
- 等价：`CompositionNode.interrupt_cancel(InterruptTarget.sequence(...))`
- `cancel_pending` / `ignore_pending` Builder API **保留为** `InterruptTarget.pending_impact` 的语法糖（测试 / 竖切）。

**与关键词三档译法**（[07-effect-primitives §0.1](07-effect-primitives.md)）：

| 目标 | 译法档 | 说明 |
|---|---|---|
| Ignore **keyword** 行为 | ③ + `seq.interrupt.ignore` | 在 keyword LISTENER 入口查 IgnoreMask |
| Cancel **Card Ability initiation** | Card Ability + `seq.interrupt.cancel` | 打断 **SEQUENCE**，非 Register |
| Ignore **单条 impact** | `seq.interrupt.ignore` · IMPACT | 保留 initiate，resolve 不施加 |

**运行时接线状态**（2026-07）：

| Kind | 状态 |
|---|---|
| IMPACT（`pending_id`） | 已接 `PendingResolutionStore` |
| SEQUENCE（`flow_id` + bind） | 已接 `RulesMemory.cancel_sequence` → G3 跳过 composition |
| COST / KEYWORD / CHAOS_TOKEN | 待接 Initiation / keyword / chaos 子系统 |

### 6.0.1 样例：Ward of Protection（Cancel · SEQUENCE）

> **卡面（2026 Core）**：*Fast. Play when you draw a non-weakness treachery card. Cancel that card's revelation effect and take 1 horror.*

**译法要点**：

- Cancel 对象是 **显现能力**（Revelation Card Ability），不是抽牌本身 → `InterruptTarget.kind = SEQUENCE`，`flow_id = seq.encounter.revelation`。
- 遭遇 treachery **已 draw**（G1 pop → **limbo**）；Cancel 仅 **注销 G3 显现子流程** 的可结算体（Grimoire *Cancel* = interrupt initiation of the effect）。
- **显现被取消 ≠ 抽牌未发生**；**G4 强制步仍执行** — 牌 **仍进遭遇弃牌堆**（见下「收尾不变量」）。
- `take 1 horror` 是 **独立效果步**，与 interrupt **同 composition Seq** 顺序 resolve（Then 语义）。

**收尾不变量（已裁决 · FAQ）**：

> *If the effects of a treachery card are canceled, the card is still regarded as having been drawn, and it is still placed in the encounter discard pile.*

| 步骤 | Cancel revelation 后 |
|---|---|
| G3 `seq.encounter.revelation` | **未施加**显现效果（或 composition 空跑）；**不在 G3 discard** |
| G4 treachery 落点 | **G4** 调用 `finalize_limbo_discard`（仍 limbo → 按 `limbo_discard_pile`）；**非** 独立 move 砖块 |
| Surge / peril 等 | 按原 draw 事务继续（若显现未改 card 状态） |

**引擎约束**：`seq.interrupt.cancel` bind `seq.encounter.revelation` 时 **不得** pop/abort 父帧 `seq.draw.encounter`；仅跳过/注销显现 resolve，**保留** G4 砖块。Hidden treachery 等 **卡面特规 discard** 仍走各自分支，不因 Cancel 泛化跳过。

**测试**： [06 §12 B-01](06-ability-initiation.md) — revelation 未 resolve；**牌在 encounter discard**；仍 take 1 horror。

```yaml
ability_id: ward_cancel_revelation
kind: FAST_EVENT
timing_entry:
  # 「when you draw treachery」落在 draw 事务 WHEN 窗内（含 D3 显现前/中）· 15 §16.3
  sequence_id: seq.draw.investigator
  slot: WHEN
eligibility:
  - card_type: treachery
  - not: weakness
composition:
  kind: SEQ
  children:
    - atom: nest
      flow_id: seq.interrupt.cancel
      params:
        controller_id: $initiator
        target:
          kind: sequence
          flow_id: seq.encounter.revelation
          bind:
            card_id: $trigger.card_id      # 本次 draw 绑定的 treachery
            controller_id: $trigger.controller_id
    - atom: nest
      flow_id: seq.deal.horror           # 未来 catalog；竖切可用 L0 Atom
      params:
        controller_id: $initiator
        amount: 1
provenance:
  definition_id: ward_of_protection
  ability_id: ward_cancel_revelation
```

**等价 Builder API**：

```gdscript
CompositionNode.seq([
    CompositionNode.interrupt_cancel(
        InterruptTarget.sequence(
            &"seq.encounter.revelation",
            {"card_id": trigger_card_id, "controller_id": initiator_id}
        )
    ),
    # deal 1 horror …
])
```

**勿译成**：

| 误译 | 原因 |
|---|---|
| `InterruptTarget.IMPACT` + pending draw | Cancel 的不是单条 EffectOp，而是 **Card Ability 显现 seq** |
| `seq.interrupt.cancel` bind `seq.draw.investigator` | 抽牌已发生；规则只取消 **revelation effect** |
| 单卡 `WardCancelService` | 违反 [effect-translation](../.cursor/rules/effect-translation.mdc) |

### 6.1 规则语义对照

| | Cancel | Ignore |
|---|---|---|
| **序列登记** | **未结算前注销** pending（`PendingResolutionStore` 移除；视为从未登记可结算序列） | **保留** pending 登记（initiate 仍成立；可对 initiate 响应） |
| **结算** | 不可再 resolve（`unknown_pending`） | resolve 时 **不施加** op（`ignored: true`, `applied: false`） |
| Initiation | 打断，未发生 | 已 initiate |
| 后续反应 | 不可 react | 可 react to initiate |
| Chaos token | 视为未 draw | 已 draw，modifier/effect 不应用 |
| **遭遇 treachery（Cancel revelation）** | 显现效果未发生；**仍视为已 draw** | — |
| **遭遇 treachery 落点** | **G4 仍 discard → encounter discard pile** | — |

Exile/remove from game **不可** ignore。

### 6.2 Cancel 与 Replacement 交互（已裁决 OQ-07-06）

**看两者触发先后**；Replacement 效果一般为 **Delayed 延时效果**，与 **Forced** 同优先级 tier（见 §10、`06 §5.1`）。

| 谁先触发 / 结算 | 结果 |
|---|---|
| **Replacement 先** | 原「可结算效果」已被替换；针对原效果的 **Cancel 无法发动**（无可取消的 pending resolution） |
| **Cancel 先** | 原效果视为未发生；**Replacement 不结算** — Replacement 替换的是「即将可结算的效果」，已被 Cancel 则无可替换对象 |

```gdscript
# TimingBus 在同一 timing 内：
# 1. Forced + Delayed（含 Replacement 注册的延时替换）按 06 §5.1 顺序 resolve
# 2. 玩家 [reaction] Cancel 在对应 window 内 initiate
# 3. 以实际 resolve 先后为准，非 DAG 内固定 Cancel-before-Replacement

func on_pending_effect(pending: EffectRequest) -> void:
    # Replacement 作为 DelayedEffect 挂到 pending 的 resolve timing
    # Cancel 作为 Reaction 打断 pending 的 initiation / resolution
    pass
```

**引擎要点**：Cancel 绑定 **原始 pending effect 的 identity**；Replacement 先生效则该 identity 的 resolution 路径已改写 → Cancel 失效。Cancel 先生效则 pending 标记 `cancelled` → 后续 Replacement callback **fizzle**。

---

## 7. Instead / Would（Replacement · 替换竞争）

> **归类**：§3.3 **同时点竞争** 之子类型 **替换竞争**。

### 7.0 统一译法（Instead / Would 卡面）

**一切** Instead / Would 类 Card Ability 均译为 **`seq.replace.instead`**（Would 层见下），携带 **`ReplacementTarget`** + **`replacement` 载荷**；**禁止**单卡 `*InsteadPolicy`。

```text
Instead / Would 卡面
  → AbilityCompiler 选定 timing entry（Forced when… / Delayed when X would…）
  → composition 内 nest 或 L2 Replace 节点
  → seq.replace.instead {
       target: ReplacementTarget,
       replacement: EffectRequest | nest seq.*,
       source_ability_id
     }
  → ReplacementHandler → PendingResolutionStore（most recent initiation_seq）
```

| 卡面 archetype | catalog | `ReplacementTarget.kind` | 说明 |
|---|---|---|---|
| Instead of resolving X, do Y | `seq.replace.instead` | **PENDING** | 替换 pending impact 的 resolve 路径 |
| Instead of treachery revelation… | `seq.replace.instead` | **SEQUENCE** | 替换命名流程 resolve（待接 Stack） |
| When X **would** happen… | `seq.replace.instead` | **WOULD_TRIGGER** | Would 层；先于 When 同 trigger |
| 竖切：register replacement | 同上 | **PENDING** | `pending_id` 占位 |

**与 Interrupt 的分工**（§6.0）：

| 机制 | catalog 族 | 语义 |
|---|---|---|
| **Cancel / Ignore** | `seq.interrupt.*` | 打断或跳过施加 |
| **Instead / Would** | `seq.replace.instead` | **改写**即将 resolve 的路径；多条竞争 → **最后 initiate** |

```gdscript
class ReplacementTarget:
    enum Kind { PENDING, SEQUENCE, WOULD_TRIGGER }
    var kind: Kind
    var pending_id: StringName
    var flow_id: StringName
    var triggering_condition_id: StringName
    var bind: Dictionary
```

**Composition 对齐**：

- 推荐：`catalog.nest(game_ctx, &"seq.replace.instead", { target, replacement, source_ability_id })`
- 等价：`CompositionNode.replace_instead(ReplacementTarget.pending(...), EffectRequest...)`
- `replace_pending` **保留为** `ReplacementTarget.pending` 语法糖。

**竞争裁决**（不变）：同一 `triggering_condition_id` + 冲突 replacement → `initiation_seq` 最大者胜出（§7.2）。

**运行时接线状态**（2026-07）：

| Kind | 状态 |
|---|---|
| PENDING | 已接 `PendingResolutionStore.register_replacement` |
| SEQUENCE | 待接 `ResolutionSequenceStack` resolve 改写 |
| WOULD_TRIGGER | 待接 Would 窗口 / condition 层 |

### 7.0.1 样例：遭遇库顶 Instead（Would · WOULD_TRIGGER）

> **教学范例**（概括常见 encounter-draw instead 句式，非 Core 单卡逐字原文）：  
> *When you would draw the top card of the encounter deck, instead draw the top card of the encounter discard pile.*

**译法要点**：

- 卡面含 **would draw** → 订阅 **`seq.draw.encounter` 的 WOULD 槽**（D1 pop 前 · [15 §16.3.1](15-timing-entry-catalog.md)）。
- 替换的是 **「从哪里 pop 遭遇牌」** 这一 **triggering condition 的 resolve 路径**，子 seq 尚未 push → `ReplacementTarget.kind = **WOULD_TRIGGER**`。
- `replacement` 载荷 = **另一条命名流程**（或带 `source: discard_pile` 参数的 draw 变体），**不是** `EffectRequest` 单 op。

**AbilityCompiler 产出（示意）**：

```yaml
ability_id: draw_encounter_discard_instead
kind: FORCED   # 或 [reaction]；取决于印刷
timing_entry:
  sequence_id: seq.draw.encounter
  slot: WOULD
composition:
  atom: nest
  flow_id: seq.replace.instead
  params:
    controller_id: $initiator
    target:
      kind: would_trigger
      triggering_condition_id: draw_encounter
      bind:
        drawer_id: $trigger.drawer_id
    replacement:
      nest: seq.draw.encounter.from_discard   # 未来 catalog 条目
      params:
        drawer_id: $trigger.drawer_id
    source_ability_id: $ability.ref
provenance:
  definition_id: example_draw_discard_instead
```

**运行时序（目标）**：

```text
seq.draw.encounter RUN
  D1 collect · emit WOULD
    → [Listener] seq.replace.instead 登记 replacement
    → winning replacement 改写 pop 来源：discard pile top 而非 deck top
  D2+ 按改写后的路径继续（reveal / spawn / discard 等砖块不变）
```

### 7.0.2 样例对照：Instead 改 revelation（SEQUENCE · 非 Would）

> **教学范例**：*Instead of resolving that treachery's revelation ability, discard that treachery.*

与 §7.0.1 **对比** — 此处 **显现子流程已在栈上/可绑定**，替换 **已 nest 的 seq** 而非 Would 层 pop 来源：

```yaml
timing_entry:
  sequence_id: seq.enter_hand          # 或 seq.encounter.revelation 的 WHEN
  slot: WHEN
composition:
  atom: nest
  flow_id: seq.replace.instead
  params:
    target:
      kind: sequence
      flow_id: seq.encounter.revelation
      bind:
        card_id: $trigger.card_id
    replacement:
      nest: seq.discard.from_hand
      params:
        card_id: $trigger.card_id
        pile: encounter_discard
    source_ability_id: $ability.ref
```

### 7.0.3 选型：`WOULD_TRIGGER` vs `SEQUENCE` vs `PENDING`

| 问 | 选 Kind | 典型卡面 |
|---|---|---|
| 替换点在 **TC 成立前/之际**，原 resolve 体 **尚未** 作为独立 seq 存在？ | **WOULD_TRIGGER** | *When you **would** draw… instead…* |
| 替换 **已在进行** 的命名子流程（revelation、spawn…）？ | **SEQUENCE** | *Instead of **resolving** revelation…* |
| 仅替换 **单条 pending EffectOp**（如 gain 9 → gain 5）？ | **PENDING** | 竖切 / 简单资源替换；无独立 seq 名 |

```text
would draw encounter deck top
  └─ WOULD_TRIGGER @ (seq.draw.encounter, WOULD)
       replacement = 改 pop 来源的 seq 变体

draw treachery → revelation 进行中
  └─ SEQUENCE @ seq.encounter.revelation
       replacement = discard /  alternate composition

begin_pending(gain 9) 窗口内
  └─ PENDING @ pending_id
       replacement = EffectRequest.gain(5)
```

### 7.1 规则出处

| 条目 | 内容 |
|---|---|
| **Instead** | `instead` = replacement；同 trigger + conflict → **most recent** |
| **Would** | `When X would` 先于 `When X`；可替换 condition 性质并封锁原 condition |
| **Priority of Simultaneous Resolution** | 遭遇 Forced 先于玩家 Forced；多 Forced 同时 → 队长定 resolve **顺序**（顺序参与「最近」） |

### 7.2 冲突条件与裁决

三条 **同时** 满足才走「最近一条」：

1. 同一 **`triggering_condition_id`**
2. 均为 **replacement**（已 **initiate**）
3. 对 **如何 resolve** 产生 **conflict**

| 规则 | 说明 |
|---|---|
| **最近 = 最后 initiate** | `initiation_seq` 最大者生效（§3.4） |
| **Would 层** | would 窗口先于 when；改 condition 后原 condition 上的 replacement 可能失效 |
| **非 conflict** | 多条 instead 可并存时不适用「最近」 |

```gdscript
class ReplacementCandidate:
    var source_ability_id: StringName
    var triggering_condition_id: StringName
    var initiation_seq: int
    var with_resolution: Callable  # 替换后的 resolve 路径
```

> **勿与 Silver Rule 混淆**：cardtype **不**决定 replacement 胜负。  
> **勿与 Cannot 混淆**：cannot 绝对禁止，**不是** replacement 竞争。

### 7.3 Replacement 与 Cancel（已裁决 OQ-07-06）

Replacement 能力通常实现为 **DelayedEffect**（到达指定 timing 时以 Forced 级优先级介入），与 Cancel [reaction] 的交互见 **§6.1**：

- 非「Cancel 替换前还是替换后」的二选一，而是 **谁先在该 timing 实际 resolve**
- Replacement 先 → Cancel 不能发动
- Cancel 先 → Replacement 不结算（无可替换的可结算效果）

---

## 7.5 同时效果组（已裁决 OQ-01-02）

与 [01-game-state-zones.md §5.3](01-game-state-zones.md) 一致。

| 规则 | 引擎行为 |
|---|---|
| 「simultaneously / 同时」 | 同一 `TimingPoint` 内开始结算 |
| 「效果 A and 效果 B」 | A、B 归入同一 `SimultaneousEffectGroup` |
| `after` 触发 | **组 commit 完成后**才排队 |
| Unique 遭遇 vs 玩家同名 | 极少见；走同一机制，非专用分支 |

```gdscript
# EffectResolutionGraph 内
func resolve_group(effects: Array[EffectRequest]) -> void:
    var group := SimultaneousEffectGroup.new(current_timing)
    for e in effects:
        group.add(e)
    group.commit()  # 抑制组内 after；commit 后统一 flush after 队列
```

`submit_batch(..., simultaneous: true)` 应委托至 `SimultaneousEffectGroup`，与 For each 的 SIMULTANEOUS 模式区分：后者是**数值合并**，前者是**时点与 after 优先级**。

---

## 8. For Each 合并判定

Grimoire For each / For every：

| 可 simultaneous | 必须逐步 |
|---|---|
| 纯数值 horror（fail by X） | 每点选 lose action OR horror |
| 可一次算总量 | 含 choice / 多步依赖 |

```gdscript
func classify_for_each(template: EffectTemplate) -> ForEachMode:
    if template.has_player_choice_per_iter(): return SEQUENTIAL
    return SIMULTANEOUS
```

---

## 9. Modifiers 重算

Grimoire Modifiers p.16：

- 新 modifier 加入时 **从头重算**
- Additive/subtractive **先于** double/halve
- 分数向上取整
- 功能值不低于 0（excess negative 仍「存在」）

```gdscript
class ModifierEngine:
    func compute(base: int, mods: Array[Modifier]) -> int
    func compute_skill(inv: StringName, skill: SkillType, ctx: SkillTestContext) -> int
```

---

## 10. Lasting / Delayed

> **v0.2+**：统一为 [Registration + LifetimeSpec](06-registration-buff-model.md)。Lasting = `DURATION`；Delayed = `UNTIL_FIRED`；持续壳内 Listener 见该文档 §5。

```gdscript
class LastingEffect:
    var id: StringName
    var duration: DurationSpec      # until end of phase, for this skill test, ...
    var modifier: Modifier
    var affected_filter: Callable

class DelayedEffect:
    var timing: TimingPoint
    var effect: EffectRequest
    var kind: DelayedKind = GENERIC   # REPLACEMENT | GENERIC | ...
    var replaces_pending: EffectRequestId   # Replacement 专用：指向被替换的 pending 效果
    # 到达 timing 时以 Forced 同级优先级自动 resolve（OQ-07-06）
```

Lasting expires **before**「at end of phase」abilities（Grimoire Lasting Effects）。

---

## 11. 常见效果映射

| 卡牌文本模式 | EffectOp |
|---|---|
| draw 1 card | DRAW_CARDS amount=1 |
| gain 1 resource | GAIN_RESOURCE |
| discover 1 clue | DISCOVER_CLUE |
| place 1 doom on agenda | PLACE_DOOM target=agenda |
| heal 2 damage | HEAL type=damage |
| move 1 damage from X to Y | TRANSFER_AFFLICTION kind=damage |
| move 1 horror from X to Y | TRANSFER_AFFLICTION kind=horror |
| search top 5 | SEARCH_DECK |
| advance act | ADVANCE_ACT |

复杂分支 → `CUSTOM` + CardScript handler。

---

## 12. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| E-01 | 3 damage, Bodyguard soak 2 | 1 on investigator |
| E-02 | Direct horror 1 | 必须 investigator |
| E-03 | Cancel revelation | treachery 未 resolve |
| E-04 | Then draw then horror | horror before After draw |
| E-05 | For each fail by 3 horror | 一次 3 horror |
| E-06 | For each fail: lose action or horror | 3 次独立选择 |
| E-07 | Replacement 先于 Cancel resolve | Cancel 无法发动 |
| E-08 | Cancel 先于 Replacement resolve | Replacement fizzle |
| E-09 | Move 1 damage A→B | TRANSFER_AFFLICTION；不触发 After heal |

---

## 13. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-07-01 | P1 | 伤害分配 UI：何时必须玩家选 vs AI 默认（最保护 investigator？）？ |
| OQ-07-03 | P1 | Assign 阶段 prevent 部分 damage：剩余是否 re-assign 还是 fizzle？ |
| OQ-07-04 | P2 | Simultaneous discard 多张：owner 选顺序是否影响后续 search？ |
| OQ-07-05 | P1 | 「As much as possible resolve」— partial target invalid 时 DAG 如何剪枝？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-06-01 | 多条 Replacement 同 triggering condition 冲突 | **最后 initiate**（`initiation_seq` 最大）。见 §3.4、§7。 |
| OQ-REPL-01 | `initiation_seq` 边界（嵌套 initiate、would 改 condition） | v0：COMMENCE 单调序号；见 §3.4。 |
| OQ-07-06 | **看触发先后。** Replacement 一般为 Delayed，与 Forced 同优先级。Replacement 先 → Cancel 无法发动；Cancel 先 → Replacement 不结算（无可替换的可结算效果）。见 §6.1、§7.1。 | 2026-05-25 |
| OQ-07-02 | **是。** 独立 `EffectOp.TRANSFER_AFFLICTION`；**不算 heal**，不触发 heal 相关 [reaction]。见 §4.1。 | 2026-05-25 |

---

## 14. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-06-01：Replacement 最近一条（对齐 Grimoire Instead） |
| 2026-05-25 | v0.3 | OQ-07-06 裁决：Cancel vs Replacement 看触发先后 |
| 2026-06-18 | v0.4 | **§3.2** 冲突裁决栈；**Cannot 绝对优先**；修正 Replacement ≠ Silver Rule |
| 2026-06-18 | v0.4.1 | Grim 移出主路径；对齐 00 §6 电子版完备规则 |
| 2026-06-18 | v0.5 | **§3.2–§3.4** 同时点竞争分型；Replacement=最后 initiate；链 Grimoire Instead + Simultaneous Resolution |
| 2026-07-05 | v0.6 | **§6.0.1** Ward Cancel 样例；**§7.0.1–§7.0.3** Instead/Would 样例与 Kind 选型 |
| 2026-07-05 | v0.6.1 | **§6.0.1 / §6.1** Cancel revelation 后 G4 仍 discard（FAQ 不变量） |
| 2026-05-25 | v0.4 | OQ-07-02 裁决：TRANSFER_AFFLICTION 独立且不算 heal |
