# 17 — 命名流程运行时 (seq.* Runtime)

> **依赖**：[14-nested-sequences.md](14-nested-sequences.md)、[15-timing-entry-catalog.md](15-timing-entry-catalog.md)、[06-ability-initiation.md](06-ability-initiation.md)、[16-player-interaction.md](16-player-interaction.md)、[effect-translation.mdc](../../.cursor/rules/effect-translation.mdc)  
> **状态**：v0.4.22 · 2026-09-22 — seq 时点 vs 条件；统一 damage / skill_test / lose_resources

---

## 1. 目标

定义一条 **`seq.*` 要在游戏里真正跑起来**，除 handler 内 RESOLVE 砖块外，还必须具备哪些 **运行时横切件**；并列出 **当前实现缺口**（相对完整 LCG 回合）。

**命名流程（named flow / `seq.*`）** = 规则书里那套 **有名字、可复用、带时点** 的手续：`SequenceCatalog` 条目 + `ResolutionSequenceStack` 上的 WOULD / WHEN → RESOLVE → AFTER + 可 `nest` 子 flow。抽牌、遭遇抽牌、检定、行动内核、入手/显现入口、共享 Cancel/Instead 都是命名流程。

**不是命名流程**：卡牌正文（译效果组合）、打出（`PLAY_CARD`）。能力只 **订阅** 某条 seq 的槽当 hook；effect 仍是 Composition。禁止为每张卡登记 `seq.card…`。与效果组合的逐项对照见 [07-composition §1.2](07-composition.md#12-与命名流程对照)。

### 1.1 命名与粒度（已裁决 2026-09-22）

1. **按魔典章节 / 词条分类** `flow_id` 前缀（`seq.skill_test`、`seq.draw.*`、`seq.framework.*`、`seq.effect.damage` …），勿把无关手续平铺成一串同级 `seq.effect.*` 而不标明词条归属。
2. **`seq.*` 只做时点切分**（WOULD/WHEN/RESOLVE/AFTER 与因果 nest）。**禁止**把条件写进 `flow_id`（技能类型、目标过滤、Elite、pile、amount=all 等）。
3. **条件 / 视角差异 → `params`**（及 Eligibility / Scope / 目标解析）。例：
   - `seq.skill_test` + `params.skill`（勿 `seq.skill_test.willpower|…`）
   - **造成伤害/恐惧**（Dealing Damage/Horror）：`seq.effect.damage` + `kind` + `source` + `target`；纸面 “take / deal” 只是视角，**同一条 seq**
   - `seq.effect.lose_resources` + `all: true`（勿另开 `lose_all_resources`）
4. Forced 订阅 **时点 seq 的 kind**；「是不是附着地点上的非 Elite」等过滤留在 params / 解析器，不铸造 `seq.fire_damage`。

---

## 2. 运行时栈（已裁决）

```text
入口（Framework / Action / Composition 树 nest 已有 seq）
  → SequenceCatalog.run / nest / nest_batch
       → ResolutionSequenceStack
            ├─ TriggeringCondition（锚点 + after_timing）
            ├─ WHEN：TimingWindow + Eligibility COLLECT + ResponseWindow（待接）
            ├─ RESOLVE：handler（L0 / Composition / nest 子 seq）
            ├─ AFTER-A：同上 WHEN 类窗口
            └─ AFTER-B：TimingBus.emit → LISTENER
       → RulesMemory / ApplicationContext / EventRecord
```

**原则**：规则手续 = **seq handler 顺序 + nest**；卡牌正文 = **Composition**（在 seq 的 EFFECT 砖或 Initiation resolve 里 execute；调用抽牌/检定等时再 nest 已有 seq）；禁止与 Catalog 平行的第二套 dispatch，也禁止 `seq.card…`（见 effect-translation.mdc）。

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
| T1 | **WOULD** | 该次流程 PreImpact（抽牌：这条指令尚未发生；任何一张 pop 前牌在 **DECK**） |
| T2 | **WHEN** | 发起 impact 之后的打断槽（抽牌：抽取步骤；同一指令的 N 张已同时抽到，不覆盖显现 / G4） |
| T3 | **AFTER** | 该次流程整段结算完毕（抽牌：同时抽出组的显现 / G4 都完。涌动是之后的延时，另开指令） |
| T4 | `TimingCatalog` 行 | `(sequence_id, WOULD\|WHEN\|AFTER)`；抽牌按卡面转译钉语义；**v1 未实现** |
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
| I2 | 禁止裸 resolve | 按 07 §1.2.1：树在 **已压栈的手续** 里解释。现状 `AbilityInitiationPipeline` **直接** `composition.execute` 绕栈，待收 |
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
| **① 内联 G3** | handler 内顺序砖块 / Composition | **不** push 子帧 | **流程连续**；抽取步骤发起 impact（D2→D3 物理入手） |
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

**禁止**（15 §4.0.2）：同段既 G3 内联又 nest 同一语义；子 seq 在无父 RESOLVE 下 `catalog.run` 却假定父 When 槽仍开（除非 ④ 顶层 Delegate）。

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

### 4.4 Timing：父槽 vs 子窗口

| 概念 | 规则 | 实现状态 |
|---|---|---|
| **父 Would / When** | 卡面 draw 转译：Would = 这次抽取 PreImpact；When = 抽取步骤（15 §3） | **未实现**：现栈 WHEN→整段 RESOLVE；无 WOULD 相 |
| **发起 impact** | Would 与 When **之间** 的内联 L0（reveal / 入手 / G1） | ✅ handler 内联 |
| **子独立 WHEN** | `TriggeringCondition.enter_hand` 每张显现 | ✅ `sequences.nest(enter_hand, …)` |
| **AFTER merge** | 父 **仅** SUBSEQUENCE 且无 post brick → 只 emit 父 AFTER（15 §7） | **未实现** |
| **AFTER 顺序** | 子树 pop 后父 AFTER | 部分（stack pop ✅；defer ❌） |

**Invariant**：Eligibility 订阅 **`(sequence_id, slot)`** 时，**子 kind 不继承父** unless 显式 tags。抽牌 When **不**用栈默认「RESOLVE 前 WHEN」代替抽取步骤 When。Would = 这次抽取 PreImpact。After = 结算完毕。

**实例对照表** → [15 §16.3.1](15-timing-entry-catalog.md)（`seq.draw.investigator`）。

### 4.5 Checklist 补充（含子 seq 时）

| # | 项 |
|---|---|
| C0 | 每 nest 点有 **因果理由**（新 TC）；连续段 **未** 误 nest |
| C1 | 子 flow **RUN** vs **NEST_BATCH** 登记正确 |
| C2 | 子 `build_trigger` 的 **kind** 与 15 §18 订阅键一致 |
| C3 | 父 handler **仅** `nest` / `nest_batch`，不 duplicate 子 RESOLVE 体 |
| C4 | 父 AFTER / Would·When 砖块边界与 15 §3、§16/§17 对照 |
| C5 | `params` / `provenance_flow_id` 向下传递 |
| C6 | 测试：**NS-01**（depth）+ **TIM-***（slot 开闭）+ 域测试（ENT-*） |

---

## 5. 当前已注册 flow（代码）

| flow_id | 用途 | 入口 |
|---|---|---|
| `seq.draw.investigator` | 调查员抽牌 D* | `DrawInvestigatorService`、`ActionSystem` DRAW、`Composition` draw |
| `seq.draw.encounter` | 遭遇抽牌（抽取步骤 + 卡牌结算；不含涌动） | `DrawEncounterService`、Mythos 1.4 `ScenarioSystem` |
| `seq.keyword.surge` | 涌动 LISTENER 开火：卸标记并 nest 新的遭遇抽牌 | `KeywordConsumer` @ `seq.draw.encounter` AFTER；06 §3.2.6 |
| `seq.draw.empty_piles_defeated` | 两堆空 defeated（因果 nest） | nest from D1 内联 collect |
| `seq.enter_hand` | 显现 batch | nest from investigator |
| `seq.gain_resource` | 获资源 + MODIFIER | `ResourceGainService`、可框架 |
| `seq.effect.discover_clue` | 发现线索（纸面无名，引擎铸造） | 调查成功 nest；Forced AFTER 可订阅 |
| `seq.effect.damage` | **造成伤害/恐惧**（Dealing Damage/Horror；take/deal 同 seq） | `kind` + `source` + `target`；卡面 / 显现 / Fire! |
| `seq.effect.lose_resources` | 失去资源（含全部：`all: true`） | 卡面；CREATED = 实际扣到 |
| `seq.effect.heal` | 治疗伤害或恐惧（`kind` 参数） | 卡面 |
| `seq.effect.lose_action` | 失去行动 | 卡面 |
| `seq.effect.place_doom` | 卡面放置毁灭（敌人 / 来源；**不是** `seq.mythos.place_doom`） | 显现 / Forced nest |
| `seq.effect.place_clue` | 把调查员线索放到地点 | 检定 fail-by 等 |
| `seq.effect.register` | **创建 Buff / Registration** | 卡面 lasting、gains surge、Cannot；参数 = template |
| `seq.effect.unregister` | 卸 Buff | 与创建对称；不是 `on_card_leave_play` 那种管线注销场合 |
| `seq.effect.discard_card` | 弃置指定牌（手牌 / 威胁区 / 遭遇） | 弱点自弃、成功弃附着 |
| `seq.effect.discard_from_hand` | 弃手牌（`amount` / `mode=random|pick`） | fail-by 二选一 |
| `seq.effect.attach` | limbo 附着地点（最近无同名 / 本地点） | Fire! / Flash Flood / Arcane Lock 显现 |
| `seq.skill_test` | Skill Test Timing（**一条**；`params.skill`） | 显现内检定、行动检定 nest |
| `seq.framework.investigation_phase_ends` | 调查阶段结束钩子（WHEN/AFTER） | Fire! / 地点 Forced |

**已有横切**：`ResolutionSequenceStack`、`RulesMemory`、`ApplicationContext`（gain）、`TimingBus`+LISTENER、`EnterHandTimingPolicy`（仅 SOURCE_ORDER）。

**已移除（并入 params）**：`seq.effect.take_horror` / `take_damage` / `deal_damage` → `seq.effect.damage`；`seq.effect.lose_all_resources` → `lose_resources`+`all`；`seq.skill_test.{willpower,intellect,combat,agility}` → `seq.skill_test`。

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
| **TimingCatalog** | 规范 WOULD/WHEN/AFTER emit（15 §18）；抽牌按卡面转译钉语义 |
| **draw SPLIT 槽** | WOULD = 这次抽取 PreImpact；WHEN = 抽取步骤；AFTER = 整段结算完毕 |
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
4. draw SPLIT：卡面 draw 转译 WHEN=抽取步骤、WOULD=这次抽取 PreImpact  ← 与 15 §3.1 一致
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
| OQ-SEQ-03 | **已裁决 2026-09-21**：卡牌正文 = Composition，Initiation resolve **直接** `composition.execute`；不为每张卡 nest custom seq，也不统一包一层 `seq.resolve.effect.*` / `seq.card…`。调用抽牌/检定等规则手续时，由树节点 nest 已有 seq。 |
| OQ-SEQ-04 | SPLIT 的 When 由 seq 政策表在抽取步骤砖块边界 emit；Would = 这次抽取 PreImpact。见 15 §3.1、§6。 |
| OQ-SEQ-05 | AFTER **defer**（15 §7 仅 SUBSEQUENCE 无 post brick）实现策略 |

---

## 10. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-09-22 | v0.4.22 | §1.1：时点 vs 条件；统一 `seq.effect.damage` / `seq.skill_test` / `lose_resources`+`all` |
| 2026-09-21 | v0.4.21 | §5：`seq.framework.investigation_phase_ends`；deal_damage 附着地点非 Elite |
| 2026-09-21 | v0.4.20 | §5：落地 `seq.effect.discard_card` / `discard_from_hand` / `attach` / `deal_damage`（A1） |
| 2026-09-21 | v0.4.19 | §5：落地 `seq.effect.take_horror/damage/heal/lose_* /place_doom/place_clue/register/unregister` |
| 2026-09-21 | v0.4.18 | §5：Buff 创建/注销 = `seq.effect.register` / `unregister` |
| 2026-09-21 | v0.4.17 | §5：`seq.effect.*` 覆盖纸面无名的可解释效果；种类铸造、禁止 `seq.card…` |
| 2026-09-21 | v0.4.16 | I2：裸 resolve 与「seq 才是压栈形态」对齐（07 §1.2.1） |
| 2026-09-21 | v0.4.15 | §1 链 07-composition §1.2 对照表 |
| 2026-09-21 | v0.4.14 | 命名流程 = 规则手续；卡牌正文 = Composition；裁决 OQ-SEQ-03 |
| 2026-06-18 | v0.4.1 | D1 collect 内联；移除 `seq.draw.collect_one` |
| 2026-06-18 | v0.4 | §4.0.5 内联=流程连续、nest=因果关系 |
| 2026-06-18 | v0.4 | 移除 SequenceFlowTree；§4 改为 slot 驱动内联/nest |
| 2026-06-18 | v0.3 | ~~SequenceFlowTree~~（已删除） |
| 2026-06-18 | v0.2 | §4 包含关系四种形态、draw 实例 |
| 2026-06-18 | v0.1 | 初稿：checklist、已注册 flow、缺口分层、实施顺序 |
| 2026-09-20 | v0.4.2 | SPLIT Would/When 在 RESOLVE 砖块边界；OQ-SEQ-04 裁决 |
| 2026-09-20 | v0.4.3 | T4：`(seq, slot)` = 同一命名流程的槽修饰 |
| 2026-09-20 | v0.4.4 | T2：抽取时钉抽取步骤 |
| 2026-09-20 | v0.4.5 | T3：抽牌 After = 整段抽取结算完毕；抽取时仍只钉步骤 |
| 2026-09-20 | v0.4.6 | T1：Would = 这次抽取 PreImpact |
| 2026-09-21 | v0.4.13 | 涌动 LISTENER 绑 `seq.draw.encounter` AFTER；场合见 06 §3.2.6 |
| 2026-09-21 | v0.4.12 | 涌动 LISTENER 注册/注销场合见 06 §3.2.6 |
| 2026-09-21 | v0.4.11 | 涌动 = LISTENER 延时竖切；关键词走三种 Buff；猎物/生成为指令 |
| 2026-09-21 | v0.4.10 | `seq.keyword.*` 仅 NEST_SEQ；其它关键词形状见 06 §3.2.5 |
| 2026-09-21 | v0.4.9 | 涌动消费 nest `seq.keyword.surge`；抽牌管线不再内联 G5 |
