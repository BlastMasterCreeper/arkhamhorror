# 17 — 命名流程运行时 (seq.* Runtime)

> **依赖**：[14-nested-sequences.md](14-nested-sequences.md)、[15-timing-entry-catalog.md](15-timing-entry-catalog.md)、[06-ability-initiation.md](06-ability-initiation.md)、[16-player-interaction.md](16-player-interaction.md)、[effect-translation.mdc](../../.cursor/rules/effect-translation.mdc)  
> **状态**：v0.4 · 2026-06-18

---

## 1. 目标

定义一条 **`seq.*` 要在游戏里真正跑起来**，除 handler 内 RESOLVE 砖块外，还必须具备哪些 **运行时横切件**；并列出 **当前实现缺口**（相对完整 LCG 回合）。

**命名流程（named flow）** = `SequenceCatalog` 条目 + `ResolutionSequenceStack` 上的 WHEN → RESOLVE → AFTER + 可 `nest` 子 flow。

---

## 2. 运行时栈（已裁决）

```text
入口（Framework / Action / 卡面 / Composition 宏）
  → SequenceCatalog.run / nest / nest_batch
       → ResolutionSequenceStack
            ├─ TriggeringCondition（锚点 + after_timing）
            ├─ WHEN：TimingWindow + Eligibility COLLECT + ResponseWindow（待接）
            ├─ RESOLVE：handler（L0 / Composition / nest 子 seq）
            ├─ AFTER-A：同上 WHEN 类窗口
            └─ AFTER-B：TimingBus.emit → LISTENER
       → RulesMemory / ApplicationContext / EventRecord
```

**原则**：长流程 = **seq handler 顺序 + nest**；卡面短效果 = **同 seq 内 Composition 步** 或 **nest 模板 seq**；禁止与 Catalog 平行的第二套 dispatch（见 effect-translation.mdc）。

---

## 3. 每条 seq 的注册清单（Checklist）

译完 / 实现一条新 `seq.*` 前，逐项勾选：

### 3.1 Catalog 与入口

| # | 项 | 说明 |
|---|---|---|
| R1 | `flow_id` 登记 | `SequenceCatalogBootstrap` 或数据驱动 catalog |
| R2 | `RUN` vs `NEST_BATCH` | 整段触发 vs 仅被 nest 的批量步（如 `seq.enter_hand`） |
| R3 | `build_trigger(params)` | `TriggeringCondition`：kind、tags、payload、`after_timing` |
| R4 | 薄 facade | `XxxService` **仅** `catalog.run(flow_id, params)` |
| R5 | 唯一入口 | 框架步 / 行动 / Composition 宏 **不得** 并行 bypass |

### 3.2 Timing 锚点（对照 [15](15-timing-entry-catalog.md)）

| # | 项 | 说明 |
|---|---|---|
| T1 | **WOULD** 要不要 | 如 draw D1 后 D2 前 |
| T2 | **WHEN** 单点 vs **区间** | 如调查员抽牌 **D2–D3**；open/close 锚点 |
| T3 | **AFTER** 与 nest | pop 时机；子 seq AFTER-B 先于父 AFTER-A |
| T4 | `TimingCatalog` 行 | `(sequence_id, WOULD\|WHEN\|AFTER)` — **v1 未实现**，暂用手写 emit |
| T5 | Listener 键 | `after_timing` 与 `RegistrationStore` 订阅一致 |

### 3.3 RESOLVE 砖块

| # | 项 | 说明 |
|---|---|---|
| V1 | handler 步骤表 | G0–G3 或内联顺序（15 §4） |
| V2 | nest 子 seq | 哪些步 `catalog.nest` vs 同 seq 循环 |
| V3 | L0 / Composition / Register | 归约到状态原语 + Buff |
| V4 | `RulesMemory` referents | 步间 pending、encounter 帧等 |
| V5 | `AbilityUnitRef` | framework_step / card ability provenance |

### 3.4 响应窗口（[06 §6](06-ability-initiation.md)、[16](16-player-interaction.md)）

| # | 项 | 说明 |
|---|---|---|
| W1 | Eligibility L0–L5 COLLECT | 订阅 `(sequence_id, slot)` + L3 Condition（历史谓词 → [06c](06c-stat-projections.md) StatProjection）— **未实现 Pipeline** |
| W2 | Tier 批处理 | FORCED → TRIGGERED → …（14 §5.2） |
| W3 | ResponseWindow | USE_ABILITY、ORDER_SIMULTANEOUS — **stack 现 fire 全部 handler** |
| W4 | nest 后 refresh | TimingWindow 仍 open 则再 COLLECT |
| W5 | 能力 resolution 范围 | `begin/end_ability_resolution` 禁自响应 |

### 3.5 限制与查询

| # | 项 | 说明 |
|---|---|---|
| Q1 | RESTRICTION 入口 | draw/play/commit 等（06 §16）；draw 行动 **未接** |
| Q2 | MODIFIER + `ApplicationContext` | tags、framework_step、referents |
| Q3 | 遭遇帧 / Peril | `EncounterResolutionFrame` + E3 — **无 `seq.draw.encounter`** |

### 3.6 Initiation 边界

| # | 项 | 说明 |
|---|---|---|
| I1 | Forced / [reaction] | eligible → Initiation L6–L7 → resolve **nest 进 stack** |
| I2 | 禁止裸 resolve | `AbilityInitiationPipeline` 现 **直接** `composition.execute`，绕 stack |
| I3 | PlayerWindow | Framework / ST 开窗 → 窗口内走 W1–W3 |

### 3.7 测试

| # | 项 | 模板 |
|---|---|---|
| X1 | Stack LIFO / AFTER | NS-01～06 |
| X2 | Domain / 可见性 | VIS-*、DRAW-*、ENT-* |
| X3 | Timing 区间 | TIM-*（**未写**） |
| X4 | 框架 + modifier | NS-03 |
| X5 | 文档 §18 索引行标 **implemented** | 15-timing-entry-catalog |
| X6 | **因果边界 / slot / nest** | [15 §4.0.5](15-timing-entry-catalog.md)、§16.3.1 |

---

## 4. 内联 vs nest：**自然流程** vs **上一步触发的时点**

**操作判据**（[15 §4.0.5](15-timing-entry-catalog.md)）：

> **上一步是否触发了本步所订阅的响应时点？** 是 → nest；否 → 内联（结算自然下一步）。

- **内联** = 同一 RESOLVE 内的 then（如 E3 险境、D2→D3、默认 discard）。  
- **nest** = 显现、priority 80 spawn 等 **同 `ENCOUNTER_CARD_DRAWN` 下的结算体**（可 nest 入栈，非第二 timing 锚）。  
- pop 后 **继续** 下一内联步（§4.0.6）。

**权威**：`ResolutionSequenceStack` LIFO 路径 + 15 各 seq 的 slot 对照表。

### 4.1 四种形态

| 形态 | Catalog API | 栈行为 | 何时用 |
|---|---|---|---|
| **① 内联 G3** | handler 内顺序砖块 / Composition | **不** push 子帧 | **流程连续**；同一 TC / 同一 WHEN 区间（D2→D3） |
| **② SUBSEQUENCE** | `catalog.nest(flow_id)` | push **子帧** | **因果关系**；新 TC / 新 `(seq, slot)`（显现、defeated） |
| **③ NEST_BATCH** | `catalog.nest_batch(flow_id)` | batch 本身无 RUN 帧；handler 内可 **循环 `sequences.nest`** | 同政策下一批（多张显现） |
| **④ Delegate 入口** | 外层 `catalog.run(wrapper)` → 内层 `run(core)` | 顶层新根帧，或父 RESOLVE 内的 run | 多入口共享内核 |

### 4.2 决策（译 flow 时）

```text
上一步是否触发了本步所订阅的响应时点？
  否 → ① 内联 G3
  是 → ② catalog.nest / sequences.nest（显现、G4 spawn、enter_hand…）
一批相同政策、共享父 timing？
  → ③ NEST_BATCH（如多张显现）
仅多入口？
  → ④ Delegate
```

**禁止**（15 §4.0.2）：同段既 G3 内联又 nest 同一语义；子 seq 在无父 RESOLVE 下 `catalog.run` 却假定父 WHEN 区间（除非 ④ 顶层 Delegate）。

### 4.3 运行时语义

**LIFO（嵌套）+ 顺序（内联）** — [14 §2](14-nested-sequences.md)、[15 §4.0.6](15-timing-entry-catalog.md)：

```text
父 RESOLVE（内联 step₁ → step₂ → …）
  step 遇因果 → catalog.nest(子)
       → 子：WHEN → RESOLVE → AFTER → pop
  step₂… 继续（嵌套链结束后才轮到）
→ 父 AFTER
```

`sequences.nest` **同步**跑完子树再 return；父 handler 从 **下一内联步** 继续。

**参数与 provenance** — 父 → 子经 `params` 显式传递：`inv_id` / `controller_id`、`source_tags`、`provenance_flow_id`、`card_ids`。

**ApplicationContext**：栈顶 `current_trigger()`；子帧 push 后 MODIFIER 以 **子 kind/tags** 为准。

### 4.4 Timing：父区间 vs 子窗口

| 概念 | 规则 | 实现状态 |
|---|---|---|
| **父 WHEN 区间** | draw **D2–D3** 覆盖 reveal + enter_hand + 显现 nest | **未实现**：现父 RESOLVE 一次跑完 D1–D3 + nest_batch |
| **子独立 WHEN** | `TriggeringCondition.enter_hand` 每张显现 | ✅ `sequences.nest(enter_hand, …)` |
| **AFTER merge** | 父 **仅** SUBSEQUENCE 且无 post brick → 只 emit 父 AFTER（15 §7） | **未实现** |
| **AFTER 顺序** | 子树 pop 后父 AFTER | 部分（stack pop ✅；defer ❌） |

**Invariant**：Eligibility 订阅 **`(sequence_id, slot)`** 时，**子 kind 不继承父** unless 显式 tags；父 **WHEN 区间** 由 **seq 政策表** 在 **D2 open / D3 close** 锚点控制。

**实例对照表** → [15 §16.3.1](15-timing-entry-catalog.md)（`seq.draw.investigator`）。

### 4.5 Checklist 补充（含子 seq 时）

| # | 项 |
|---|---|
| C0 | 每 nest 点有 **因果理由**（新 TC）；连续段 **未** 误 nest |
| C1 | 子 flow **RUN** vs **NEST_BATCH** 登记正确 |
| C2 | 子 `build_trigger` 的 **kind** 与 15 §18 订阅键一致 |
| C3 | 父 handler **仅** `nest` / `nest_batch`，不 duplicate 子 RESOLVE 体 |
| C4 | 父 AFTER / WHEN 区间与 15 §7、§16/§17 对照 |
| C5 | `params` / `provenance_flow_id` 向下传递 |
| C6 | 测试：**NS-01**（depth）+ **TIM-***（slot 开闭）+ 域测试（ENT-*） |

---

## 5. 当前已注册 flow（代码）

| flow_id | 用途 | 入口 |
|---|---|---|
| `seq.draw.investigator` | 调查员抽牌 D* | `DrawInvestigatorService`、`ActionSystem` DRAW、`Composition` draw |
| `seq.draw.encounter` | 遭遇抽牌 G1–G5（P-ENC-1～3） | `DrawEncounterService`、Mythos 1.4 `ScenarioSystem` |
| `seq.draw.empty_piles_defeated` | 两堆空 defeated（因果 nest） | nest from D1 内联 collect |
| `seq.enter_hand` | 显现 batch | nest from investigator |
| `seq.gain_resource` | 获资源 + MODIFIER | `ResourceGainService`、可框架 |

**已有横切**：`ResolutionSequenceStack`、`RulesMemory`、`ApplicationContext`（gain）、`TimingBus`+LISTENER、`EnterHandTimingPolicy`（仅 SOURCE_ORDER）。

---

## 6. 缺口分层（blocking → 可并行）

### 6.1 P0 — 无则「回合跑不全」

| 缺口 | 现状 | 需要 |
|---|---|---|
| **框架 bypass** | Mythos 1.4 → **`seq.draw.encounter`**（P-ENC-1 ✅）；Upkeep 4.4 已接 catalog | — |
| **遭遇抽牌族** | **`seq.draw.encounter`** 已注册；G4 spawn / surge 完整链待 P-ENC-4+ | priority 队列 + per-card peril ✅ |
| **Initiation ↔ stack** | initiate 裸 Composition | Forced/Reaction resolve nest 进 stack |

### 6.2 P1 — 无则「卡面能力窗口不对」

| 缺口 | 需要 |
|---|---|
| **EligibilityPipeline** | L0–L5 COLLECT；与 RegistrationStore 订阅 |
| **ResponseWindow** | 非 fire-all；接 `PlayerInteractionGate` |
| **TimingCatalog** | 规范 WOULD/WHEN/AFTER emit（15 §18） |
| **D2–D3 WHEN 区间** | `seq.draw.investigator` 拆分 open/close，非一次 RESOLVE 跑完 |
| **卡面 → SequenceHandler** | Forced/[reaction] 从 Buff 自动注册，非测试手填 |

### 6.3 P2 — 丰富度 / 合规

| 缺口 | 需要 |
|---|---|
| **`seq.action.*` wrapper** | 耗 action、AOO 时序、source_tags |
| **draw RESTRICTION** | `ActionSystem` / flow 入口查 06 §16 |
| **`seq.encounter.*`** | revelation、spawn（nest）；peril / discard **内联**于 resolve_card_body |
| **EnterHand CONTROLLER_CHOICE** | 多弱点显现序 → 16 §5.6 ORDER_CARDS |
| **PlayerInteraction** | 16 §12 清单（与 W3 同步） |

### 6.4 刻意后置

- 战役 / Setup `seq.*`（16 SETUP/CAMPAIGN）
- GUI 专用 Presentation
- 全量 TIM-/ENC- 测试矩阵

---

## 7. 推荐实施顺序

```text
1. 框架接线（Upkeep gain/draw → catalog）     ← 证明「回合里 seq 被调用」
2. seq.draw.encounter 竖切（E1–E5 + peril）   ← 神话阶段可玩
3. Eligibility + ResponseWindow 最小版       ← 一条 Forced + 一条 [reaction] 走通
4. D2–D3 WHEN 区间                           ← draw timing 与 15 §16 一致
5. Initiation nest stack                     ← 卡面能力不再绕 stack
6. seq.action.* + RESTRICTION 入口         ← 行动与 cannot 统一
7. PlayerInteraction 按 16 §5 逐项接        ← 与 W3 并行
```

**晚于 3 再大规模接 PlayerInteraction**；否则窗口内 ask 无 eligible 来源。

---

## 8. 「单条 seq Done」定义

同时满足：

1. Catalog 登记 + facade 唯一入口  
2. 至少一条 **框架或行动** 路径在生产代码调用（非仅测试直调）  
3. WHEN/AFTER 与 15 对应节 **一致或 documented gap**  
4. NS-* 类 stack 测试 + 一条 domain 测试  
5. 15 §18 索引表该行注明 **implemented** / **partial**

---

## 9. 开放问题

| ID | 说明 |
|---|---|
| OQ-SEQ-01 | v1 是否实现完整 `TimingCatalog` 类型，或 stack 内 hardcode 政策表 |
| OQ-SEQ-02 | `seq.action.draw` 与 `seq.draw.investigator` 是否同一 RUN + 不同 params/tags |
| OQ-SEQ-03 | Initiation resolve 一律 `sequences.nest(custom, composition_fn)` 还是统一 `seq.resolve.effect.*` |
| OQ-SEQ-04 | 父 **WHEN 区间** 是否由 stack **挂起/恢复** 父帧窗口，还是 seq 政策表显式 open/close |
| OQ-SEQ-05 | AFTER **defer**（15 §7 仅 SUBSEQUENCE 无 post brick）实现策略 |

---

## 10. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-06-18 | v0.4.1 | D1 collect 内联；移除 `seq.draw.collect_one` |
| 2026-06-18 | v0.4 | §4.0.5 内联=流程连续、nest=因果关系 |
| 2026-06-18 | v0.4 | 移除 SequenceFlowTree；§4 改为 slot 驱动内联/nest |
| 2026-06-18 | v0.3 | ~~SequenceFlowTree~~（已删除） |
| 2026-06-18 | v0.2 | §4 包含关系四种形态、draw 实例 |
| 2026-06-18 | v0.1 | 初稿：checklist、已注册 flow、缺口分层、实施顺序 |
