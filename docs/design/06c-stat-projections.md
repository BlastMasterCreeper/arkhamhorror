# 06c — 历史谓词与 StatProjection（Eligibility L3/L5）

> **依赖**：[06-ability-initiation.md](06-ability-initiation.md)（Eligibility L0–L7）、[06-registration-buff-model.md](06-registration-buff-model.md)、[15-timing-entry-catalog.md](15-timing-entry-catalog.md)、[00-architecture-overview.md](../00-architecture-overview.md) §7  
> **被依赖**：`AbilityCompiler`、`EligibilityPipeline`、`Condition`、Emitter 目录  
> **状态**：v0.1 · 2026-06-18 — Register 对齐 · 首次 demand cold fold · HOT 增量 · Unregister 降温

---

## 1. 目标

为 **Eligibility COLLECT** 中的 **L3 情景条件** 与部分 **L5 次数配额** 提供 **历史谓词** 查询能力，且：

1. **禁止** 从压扁 Domain 字段推导（如 `budget − actions_remaining`）。
2. **禁止** 整局为本局卡池 union 全程维护全量热统计。
3. **对齐 Registration 生命周期**：Register 时 **attach** 声明；**首次 COLLECT 需要** 时 cold fold；之后 **HOT 增量**；Unregister **detach 并丢弃 HOT**（ref=0）。

**权威事件源** = append-only `EventRecord`；StatProjection 是 **读模型（projection）**，不是第二套 Domain。

---

## 2. 与相邻概念的分界

| 概念 | 职责 | 本模块 |
|---|---|---|
| **Domain（GameStateStore）** | 现态：zone、damage、pile 顺序 | L3 **现态子句** 直读；**不**推导 action 次数 |
| **RegistrationStore** | 规则 overlay：MODIFIER / RESTRICTION / LISTENER | Register/UnRegister **钩子** attach/detach |
| **ApplicationContext** | 单次 TimingOffer 场合快照 | 派生 `EvaluationContext` |
| **RulesMemory.referents** | 单 seq 步间 pending | **不**承担 turn 级 action 史 |
| **EventRecord** | 权威流水 | cold fold 数据源 |
| **StatProjectionStore** | 懒 HOT 读模型 | **本文** |
| **PlayerInteractionGate** | 玩家选择 | 无关 |

---

## 3. 编译期：StatQuery（声明，不存储）

`AbilityCompiler.compile(def)` 除 `RegistrationTemplate[]` 外，从 `AbilitySpec.situational` / `LimitSpec` 抽出：

```gdscript
class StatQuery:
    var key: StatKey              # 标准枚举；禁止 ad-hoc 字符串
    var scope: StatScope          # INV_TURN | INV_ROUND | SKILL_TEST | …
    var op: StatCompareOp         # EQ | GE | EMPTY | …
    var operand: Variant          # 比较右值
    var filters: Dictionary       # spend_kind、action_type、pool_id…

class AbilitySpec:
    var situational: Condition    # domain_clauses + stat_queries[]
    var limits: LimitSpec         # 可含 stat_queries（L5）
```

**StatKey** 用 **有限注册表**（随卡池增长表行，不随卡发明字段）：

| StatKey（示例） | 粒度 | 典型卡面 |
|---|---|---|
| `TURN_ACTION_SPEND_COUNT` | COUNT | After your third action… |
| `TURN_ACTION_SPEND_EMPTY` | EMPTY | First action must be… |
| `TURN_ACTION_SPEND_LIST` | LIST | 需顺序/类型（少见） |
| `TURN_ADDITIONAL_POOL_REMAINING` | POOL | Daisy 额外行动池 |
| `ROUND_ABILITY_COMMENCED_COUNT` | COUNT | Limit once per round（L5 可选 fold） |

Template / CardScript **只声明** query；运行时是否 HOT 由 §5 决定。

---

## 4. 运行时：StatProjection 与三态

```gdscript
enum ProjectionState { DORMANT, HOT }

class StatProjection:
    var key: StatKey
    var scope: StatScope              # 含 inv_id, turn_id, …
    var state: ProjectionState
    var ref_count: int                # 绑定 Registration 数
    var value: Variant                # 由 granularity 决定形状
    var watermark_seq: int            # 已 materialize 到的 EventRecord.seq

class StatProjectionStore:
    var _by_reg: Dictionary           # reg_id -> Array[StatQuery]
    var _hot: Dictionary              # scope_key -> StatProjection

    func attach(reg_id, queries: Array[StatQuery], scope: StatScope) -> void
    func detach(reg_id) -> void
    func ensure_hot(queries, eval_ctx: EvaluationContext) -> Dictionary
    func on_event(event: EventRecord) -> void
```

| 状态 | 含义 |
|---|---|
| **DORMANT** | 仅 attach 声明；无 fold、无 Emitter 增量 |
| **HOT** | 已 cold fold 至少一次；Emitter 对匹配事件 O(1) 更新 |

**scope_key** = `(StatKey, scope 规范化)`，例如 `(TURN_ACTION_SPEND_COUNT, inv_1, turn_3)`。

---

## 5. 生命周期（与 Registration 对齐）

```text
RegistrationStore.register(template)
  → reg_id
  → StatProjectionStore.attach(reg_id, template.stat_queries, scope_from(reg))
  → 投影仍为 DORMANT（或尚未创建 entry）

TimingCatalog.emit → EligibilityPipeline.collect(app_ctx)
  → candidates（L0–L2 后）
  → queries := ⋃ candidate 仍 attach 且仍 Register 的 stat_queries
  → snapshot := StatProjectionStore.ensure_hot(queries, eval_ctx)
       · 对每个 (key, scope) 若未 HOT：
            COLD fold EventRecord 窗口 → value
            state := HOT; watermark := as_of_seq
  → L3: Condition.matches(app_ctx, snapshot)
  → L5: LimitResolver.check(..., snapshot)   # 可选与 L3 共用 fold

Emitter（ACTION_SPEND 等）append EventRecord
  → StatProjectionStore.on_event(event)
       · 仅更新 state==HOT 且 event 匹配的投影

RegistrationStore.unregister(reg_id)
  → StatProjectionStore.detach(reg_id)
       · 各 query scope ref_count -= 1
       · ref_count==0 → 从 _hot 移除；停止对该 key@scope 的 on_event 更新
```

**Invariant**：HOT 投影的生命区间 ⊆ **仍有 Registration attach 且 ref>0** 的区间；并 ⊆ **至少被 COLLECT demand 过一次** 的 query。

---

## 6. EvaluationContext 与 EventIndex

COLLECT 专用；由 `ApplicationContext` 派生：

```gdscript
class EvaluationContext:
    var app: ApplicationContext
    var controller_id: StringName
    var turn_id: int
    var round_id: int
    var phase_id: int
    var as_of_seq: int                # 本次 COLLECT 截止 seq（不含尚未 append 的本步）
    var window: EventWindow           # 来自 EventIndex
```

**EventIndex**（append 时 O(1) 维护，非 StatProjection）：

```gdscript
class EventIndex:
    var turn_spans: Array             # { turn_id, inv_id, start_seq, end_seq }
    var round_spans: Array
    # 可选：kind 二级索引（profiling 后加）
```

**COLD fold**：

```text
window_events = EventRecord[start_seq .. as_of_seq]
value = StatFolder.fold(window_events, query)
```

**禁止** 每次 COLLECT 从 seq=0 扫全 log。

---

## 7. COLLECT 集成（catalog 即时验证）

```text
ResolutionSequenceStack / TimingCatalog
  emit(sequence_id, slot, app_ctx)
    │
    ▼
EligibilityPipeline.collect(app_ctx, stage=COLLECT)
  L0  (sequence_id, slot) 索引
  L1  Registration 仍有效？
  L2  tier / 自响应 / 槽位
  L3  Condition：
        · domain_clauses → 读 GameStateStore
        · stat_queries   → snapshot[key]（ensure_hot）
  L4  RestrictionEvaluator
  L5  LimitSpec + snapshot（或与 LimitCounter 并用）
  ─── 到此为 eligible 集合 → ResponseWindow ───
```

**batch**：同一 COLLECT 窗内对 `queries` union 后 **每个 (key,scope) 最多 cold fold 一次**。

**PRE_INITIATE**：若 `as_of_seq` 未变，可复用同一 snapshot（COLLECT 级 memo）。

---

## 8. Emitter 契约（EventRecord payload）

StatProjection 只认 **结构化 EventKind**；GameLog 字符串不可 fold。

| EventKind | 写入点 | payload 必含 |
|---|---|---|
| `TURN_BEGIN` / `TURN_END` | Framework INV 2.2 | `turn_id`, `inv_id` |
| `ACTION_SPEND` | ActionSystem / Initiation 付 action 成功 | `inv_id`, `pool`, `spend_kind`, `action_type`, `source_id`, `tags` |
| `ACTION_SPEND_VOID` | 行动 rollback | 原 spend 引用 |
| `ACTION_GRANT` | additional action | `pool_id`, `qualifier`, `amount`, `inv_id` |
| `ABILITY_COMMENCED` | Initiation commence | `ability_id`, `inv_id` |

**fast / free** 不 emit `ACTION_SPEND`。

Emitter 写入 EventRecord 后 **同步** 调用 `StatProjectionStore.on_event`（仅 HOT 表）。

---

## 9. ref 计数与共享

多 Registration 共用同一 `(StatKey, scope)` 时 **共享一条 HOT 投影**：

```text
attach(reg_A, [Q])  → Q.ref = 1
attach(reg_B, [Q])  → Q.ref = 2
首次 ensure_hot(Q)  → cold fold → HOT
detach(reg_A)       → ref = 1，仍 HOT
detach(reg_B)       → ref = 0，移除 HOT
```

`attach` / `detach` 与 `RegistrationStore.register` / `unregister` / `tick_duration` **同一事务边界**。

---

## 10. 能力形态与投影预期

| Lifetime | attach | 典型 HOT 时长 |
|---|---|---|
| `WHILE_IN_PLAY` | enter_play | 在场且被 COLLECT 问过后，至 leave_play |
| `DURATION(THIS_TURN)` | 效果 resolve | 本 turn；turn end unregister → detach |
| `UNTIL_FIRED` | 效果 resolve | 常仅 **一次 cold fold**；或来不及 HOT |
| 纯 MODIFIER（无历史 L3） | 无 stat_queries | 不 attach |

---

## 11. 与 L5 Limit 的关系

| 路径 | 何时 |
|---|---|
| **StatFolder** on `ABILITY_COMMENCED` | Limit 与 L3 共用 query；Register 对齐 |
| **LimitCounter**（增量 O(1)） | 高频 L5；trigger 时 increment；仍可由 EventRecord 重建 |

v1 可 L3/L5 均走 StatProjection；优化时再拆 LimitCounter。

---

## 12. 禁止事项

| 禁止 | 原因 |
|---|---|
| `actions_granted - actions_remaining` 当 spend count | 衍生行动语义丢失 |
| Setup 时对本局 union 全开 HOT | 维护区间与 Registration 脱节 |
| Unregister 后仍 on_event 更新 | ref 泄漏 |
| 无 EventKind 的 GameLog 解析 | 不可测试、不可回放 |
| StatKey ad-hoc 字符串 | 无法 union / batch |

---

## 13. 实现顺序（建议）

| 阶段 | 交付 | 状态 |
|---|---|---|
| P1 | `StatKey` / `StatQuery` / `EvaluationContext` / `EventIndex` turn_span | **已实现** · `core/stats/*` |
| P2 | `StatProjectionStore` attach/detach/ensure_hot/on_event | **已实现** · `stat_projection_store.gd` |
| P3 | Emitter：`TURN_*` + `ACTION_SPEND` 写入 EventRecord | **已实现** · `game_stat_emitter.gd` + Framework + ActionSystem |
| P4 | `Condition.matches_with_snapshot` + `EligibilityCollector` | **竖切** · 完整 EligibilityPipeline 待接 |
| P5 | `AbilityCompiler` 抽出 stat_queries | 待做 |
| P6 | 测试 STAT-01～04 | **已通过** |

---

## 14. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-06-18 | v0.1 | 初稿：Register 对齐 · demand 升温 · Unregister 降温 |
