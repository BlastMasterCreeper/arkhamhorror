# 14 — 嵌套序列 (Nested Sequences)

> **依赖**：[06-ability-initiation.md](06-ability-initiation.md), **[15-timing-entry-catalog.md](15-timing-entry-catalog.md)**, [07-effect-resolution.md](07-effect-resolution.md), [06-registration-buff-model.md](06-registration-buff-model.md)  
> **规则来源**：Grimoire Glossary · When / After / Triggering Condition / Then / Effects；旧 FAQ §1.4（操作模型仍适用）  
> **官方 PDF**：[../reference/arkham-grimoire-v1.0.pdf](../reference/arkham-grimoire-v1.0.pdf)

---

## 1. 目标

实现 Grimoire **触发条件三段式**与 **LIFO 嵌套返回**，作为 TimingBus / Pending / Listener 之下的**执行骨架**。Flat `emit_timing()` 不足以保证 when → resolve → after 的暂停与返回顺序。

---

## 2. 规则模型（Grimoire）

每次 **triggering condition** 成立时：

```text
(1) When  — 打断；impact resolve 之前
(2) Resolve — 该 condition 的 impact（框架/卡牌/pending 落地）
(3) After — 与该 condition 相关的全部效果完成后；进入下一步之前
```

若在 (1)(2)(3) 内 **Forced / [reaction] / 框架** 产生 **新的 triggering condition**：

```text
暂停父序列 → 子序列完整跑 (1)(2)(3) → 回到父序列暂停点继续 → LIFO（后进先出）
```

| 条目 | 引擎含义 |
|---|---|
| **When** | `SequencePhase.WHEN` |
| **After** | `SequencePhase.AFTER`（全部 pertaining 效果完成后） |
| **Then** | Composition `Seq`；后段优先于前段间接产生的 after |
| **Forced 优先于 [reaction]** | WHEN/AFTER 窗口内 handler tier |
| **Initiation Sequence** | 独立管线；费用 L6、dry_run L7（见 [06 §5–§7](06-ability-initiation.md)） |

---

## 3. 与 Flat TimingBus 的分工

| 组件 | 职责 |
|---|---|
| **ResolutionSequenceStack** | when / resolve / after 三阶段、LIFO 嵌套、phase trace |
| **TimingWindow** | 开放窗口 + 多轮 refresh（§8） |
| **TimingCatalog** | 规范 emit 唯一出口（[15](15-timing-entry-catalog.md)） |
| **EligibilityPipeline** | 收集候选 L0–L5；Initiation L6–L7（[06 §5](06-ability-initiation.md)） |
| **ResponseWindow** | [reaction] 选用、队长排序、关闭时点（**非门槛**） |
| **TimingBus + ListenerDispatcher** | AFTER-B 放出 `after_timing` 后 dispatch 延时监听 |
| **ApplicationContext** | 栈帧 + tags + framework_step；供 Condition / MODIFIER |
| **RulesMemory** | referents、phase trace |

```text
sequences.run(trigger, resolve_fn)
  → WHEN：ResponseWindow + Eligibility COLLECT（L0–L5）
  → RESOLVE(resolve_fn)
  → AFTER-A：ResponseWindow + Eligibility COLLECT（反应 [reaction]）
  → AFTER-B：flush after_timing → 延时监听 COLLECT
```

---

## 4. 核心类型

```gdscript
enum SequencePhase { WHEN, RESOLVE, AFTER }

class TriggeringCondition:
    var id: StringName
    var kind: StringName              # 事件族；L0 订阅键之一
    var controller_id: StringName
    var tags: Array[StringName]       # L3 情景，非 L0 订阅键
    var after_timing: StringName      # AFTER-B 放出名
    var payload: Dictionary

class SequenceHandler:
    var source_id: StringName         # 禁自响应（§9）
    var controller_id: StringName
    var tier: Tier                    # FORCED | TRIGGERED | …
```

---

## 5. 同窗口多响应：Eligibility + ResponseWindow

### 5.1 决策权

| 决策 | 谁 | 层 |
|---|---|---|
| **[reaction] 是否选用** | **该能力所在卡的控制者** | ResponseWindow |
| **多条 [reaction] 均选用时的顺序** | **Lead Investigator（队长）** | ResponseWindow |
| **Forced 是否触发** | eligible 则必须发起 | Eligibility + 自动 Initiation |
| **关闭时点 / 结束本轮** | 调查员 / 流程 | ResponseWindow |

队长 **不**替其他调查员决定「用不用 [reaction]」。**选用不是 Eligibility 关卡**；选用后必须 Initiation（L6–L7）。

### 5.2 Tier（同一轮 collect 内）

```text
1. Forced
2. Framework 内嵌
3. [reaction] Triggered
4. LISTENER（after_timing，AFTER-B）
```

### 5.3 窗口流水线

```text
打开 TimingWindow
  → EligibilityPipeline COLLECT（L0–L5）→ eligible 集合
  → ResponseWindow：
       Forced：自动 Initiation → resolve（可 nest）
       [reaction]：控制者选用 → Initiation → resolve
       多条选用：队长排序
       或：关闭本轮响应
  → nest 返回 → 若窗口仍 open → refresh → 再 COLLECT
关闭 TimingWindow
```

---

## 6. 订阅键 vs 情景（与 06 §4.1 一致）

| L0 订阅（引入监听） | L3 情景（Condition，非订阅） |
|---|---|
| `WHEN` / `AFTER` + `trigger.kind` | tags、`framework_step` 细项 |
| `after_<event>` | Domain 事实、payload、referents |

---

## 7. nest() 语义

```gdscript
sequences.nest(child_trigger, child_resolve)
# 暂停父 RESOLVE / 父响应轮次 → 完整 run(child) → pop 恢复
```

子序列 **AFTER-B flush** 先于父 AFTER-A 继续。禁止在 AFTER 窗口关闭后异步补跑子序列。

---

## 8. TimingWindow 与 refresh

时点 **不是一次性 signal**，而是 **开放窗口**。嵌套返回后若窗口仍 open，**重新 COLLECT（L0–L5）**。

```text
open(XX, phase)
resolved_handlers = {}
loop:
    response_round += 1
    eligible = EligibilityPipeline.run(COLLECT) \ resolved_handlers
    if eligible.empty(): break
    ResponseWindow.resolve_batch(eligible)   # 内含 Initiation + nest
    mark resolved
close(XX)
```

引擎：`ResolutionSequenceStack._run_response_loop`；`_resolved_in_window` 防同窗口重复结算。

---

## 9. [reaction] 不得响应自身能力的效果结算

```gdscript
sequences.begin_ability_resolution(source_id)
# ... nest 产生的 triggering condition ...
sequences.end_ability_resolution()
# COLLECT L2：handler.source_id ∈ causation_stack → 排除
```

| 场景 | 结果 |
|---|---|
| A 的能力结算中抽牌 → A 的 [reaction]「after you draw」 | **不 eligible** |
| refresh 后 B 的 [reaction] | 控制者正常选用 |

---

## 10. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| NS-01 | RESOLVE 中 nest 子 trigger | LIFO phase trace |
| NS-02 | 父 AFTER 在子 AFTER 之后 | 子 AFTER 先 |
| NS-03 | MODIFIER 仅 framework upkeep gain | L3 tags + framework_step |
| NS-04 | gain + after LISTENER | AFTER-B flush |
| NS-05 | nest 返回后 refresh WHEN | 新 handler 第 2 轮 COLLECT |
| NS-06 | 自身能力结算中 | 同源 [reaction] 不 eligible |

---

## 11. 实现映射

| 文件 | 内容 |
|---|---|
| `core/timing/resolution_sequence_stack.gd` | Stack + response loop + causation |
| `core/timing/timing_window.gd` | 开放窗口 / response_round |
| `core/timing/sequence_handler.gd` | source_id / controller / tier |
| `core/timing/response_prompt.gd` | ResponseWindow UI 骨架 |
| `core/timing/resource_gain_service.gd` | gain 统一入口 |
| `core/timing/triggering_condition.gd` | `kind` → 将映射 `sequence_id` |
| （待建）`TimingCatalog` | 规范 emit（[15](15-timing-entry-catalog.md)） |

---

## 12. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿；SequenceStack 竖切 |
| 2026-05-25 | v0.2 | TimingWindow refresh；[reaction] 禁自响应；控制者 vs 队长 |
| 2026-05-25 | v0.3 | Eligibility 分工；链到 15 TimingCatalog |
