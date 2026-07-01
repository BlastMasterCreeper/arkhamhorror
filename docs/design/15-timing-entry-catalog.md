# 15 — 规范时点入口 (Timing Entry Catalog)

> **依赖**：[06-ability-initiation.md](06-ability-initiation.md), [14-nested-sequences.md](14-nested-sequences.md), [06-registration-buff-model.md](06-registration-buff-model.md), [07-effect-primitives.md](07-effect-primitives.md)  
> **符号记法**：[ArkhamDB 标准](../reference/arkham-symbol-notation.md)  
> **状态**：v0.6 · 2026-06-18

---

## 1. 目标

为 Grimoire 的 **Would / When / After** 与卡牌能力订阅，提供 **唯一权威的 Timing Entry Catalog**。规则书行文可简略；**引擎以 catalog + Triggering Anchor Policy 为准**，不临时 `emit_timing` 字符串。

---

## 2. 核心概念

| 概念 | 含义 |
|---|---|
| **RuleSequence（规则序列 / 事件族）** | 规则定义的、由 **brick**（效果 / 信息 / 子序列 / 框架步）组成的序列模板；运行时 `push → … → pop` |
| **TimingEntry** | catalog 登记项：`(sequence_id, slot)` |
| **TimingOffer** | 运行时一次 emit：`entry + ApplicationContext` |
| **push / pop** | 嵌套栈压入 / 弹出；**pop 时** 发出 `AFTER`（遵守 merge 规则） |
| **Triggering Anchor** | 序列 **WHEN** 槽在 RESOLVE 内的 **规范时刻**（**不**由 zone 坐标推导） |

```gdscript
enum TimingSlot { WOULD, WHEN, AFTER }

class TimingSubscription:
    var sequence_id: StringName
    var slot: TimingSlot

class TimingOffer:
    var sequence_id: StringName
    var slot: TimingSlot
    var instance_id: StringName
    var app_ctx: ApplicationContext
```

**订阅键（Eligibility L0）** = `(sequence_id, slot)`。  
**情景、tags、framework_step** → `ApplicationContext` + Condition（L3），见 [06 §4.1](06-ability-initiation.md)、[06b §12](06-registration-buff-model.md)。

---

## 3. 三槽语义：Would / When / After

| Slot | 语义 | 与序列 / pop 的关系 |
|---|---|---|
| **WOULD** | 将要；PreImpact；序列 **未 push** 或 **信息未对控制者成立**（见 §6） | **不** bind pop |
| **WHEN** | 当…时；序列 **已 push**；**具体区间由 sequence 定义**（draw 为 D2–D3，§16） | **不** bind pop |
| **AFTER** | …之后；**本序列 RESOLVE + nest + AFTER 响应完毕**，**pop** | **bind pop** |

```text
[WOULD]  optional emit（PreImpact 前段；draw 见 §16）
push(sequence)
RESOLVE  bricks…
[WHEN]   open/close 区间因 sequence 而异（draw：D2 完成 → D3 完成，§16）
[AFTER]  AFTER 响应 → pop → emit
```

**After** 是唯一与 **序列完成（pop）** 强绑定的 slot。  
**Would / When** 的 **精确区间** 写在各 `RuleSequenceDef`；多数 action 可 ALIAS，**draw 必须 SPLIT**（§16）。

---

## 4. RuleSequence 与 Brick

### 4.0 拼合原则（设计重心）

> **已裁决**：Grimoire 中 **凡有名称的规范规则序列**，均须译成 `SequenceCatalog` 的 `seq.*` + 砖块拼步 + L0 三类原子落地；**不得**为段落保留平行 Service / Policy / 原文分支 dispatch。详见 [.cursor/rules/effect-translation.mdc](../../.cursor/rules/effect-translation.mdc) §「Grimoire 命名规则序列」。

Grimoire 译成引擎时：

1. **先定砖块粒度（G0–G3，§4.0.2）** — 小序列 = **同一条 `seq.*` 内多砖顺序拼**，**不必** register 子 `seq.*`。
2. **再拼 Grimoire 命名流程** — 仅 **有正式名称的规范流程** → `seq.*`；其 `RuleSequenceDef.bricks` = 砖块列表 + Would/When/After 政策。
3. **跨入口复用** — 同一内核仅在被 **多条命名 seq** 共用时，才用 **SUBSEQUENCE** nest 已有 `seq.*`（可选，非升格）。

**翻译自检**：

| 问 | 期望 |
|---|---|
| Grimoire 是否给了 **顶层**流程名？ | 有 → 一条 `seq.*`；**内部步骤 = 砖块**，不是子 seq 清单 |
| 子步骤（D1 collect、shuffle+pop） | **G0–G3 砖块**拼在同一 `seq.*` 内；**禁止**仅为子步骤 register `seq.*` |
| 同一内核被 action 与效果等多处调用？ | 可选 `SUBSEQUENCE` nest **已有** `seq.*` |
| 某步只改 GameState？ | EFFECT（G0/G1）→ L0 三类 |
| 某步改规则 / reveal？ | G2 REGISTER 或 **REVEAL** |
|  tempted 新建 Service 包整段？ | **否** → 砖块 + handler 拼接模式（§4.0.4） |

**RESTRICTION / MODIFIER / LISTENER** 是 **REGISTER 砖块** 写入 `RegistrationStore`；生效查询在 **触发该砖块语义的入口**，不是序列外第二套本体。

### 4.0.1 效果原子 vs 砖块：定义与边界

两套名词 **不同层级**，不互相替代：

| | **效果原子（Atom · L0）** | **砖块（Brick · Catalog 步）** |
|---|---|---|
| **定义** | 对 `GameStateStore` 的 **唯一合法、不可再拆** 的状态写入 | 命名 RuleSequence 里的 **一步规范流程** |
| **文档** | [07-effect-primitives §5](07-effect-primitives.md) | 本节 §4.1 |
| **代码** | `StateMutator` / `AtomOp` | `SequenceCatalog` handler、`RuleSequenceDef.bricks` |
| **粒度** | **最细**（一次 move / transfer / adjust / set_flag / set_ref） | **G0–G3 四档**（§4.0.2）；**单砖上界 G2** |
| **谁发明** | 引擎底座，**封闭枚举**，极少新增 | Catalog 设计步；**小序列 = 砖块列表，不必升格 seq** |
| **时序 / WHEN** | **无** | G2 / **REVEAL** 可定步骤边界；整段 WHEN 由 **seq 政策** 定 |
| **典型** | `pop_deck_top`、`transfer_marker` | G0 `pop_deck_top`、G1 `reveal_batch`、G2 E3 REGISTER、G3 collect 循环 |

```text
Grimoire 规范流程
  → RuleSequence（seq.*）由 **砖块** 列出步骤顺序
       → 砖块 EFFECT 展开为 Composition / L0 **原子**
            → StateMutator 执行
```

**卡牌效果**不走单独原子表：编译为 **Composition 树**（同样落地 L0）；**嵌 nest** 已有 `seq.*` 时，外层是砖块 SUBSEQUENCE，内层是卡面 Composition。

#### 状态原语（L0）— 三类（07-primitives §2、§5）

[07-effect-primitives §2](07-effect-primitives.md) **已裁决**：复杂效果 = **卡牌地址 + 标记/计数 + 揭示与离散**：

| 类 | 改什么 | 典型子操作 |
|---|---|---|
| **① 卡牌地址** | `CardSlot`、zone、顺序 | `AtomMoveCard` |
| **② 标记/计数地址** | `MarkerSlot`；含 pool 端点 | `AtomTransferMarker`；`AtomAdjustMarker` |
| **③ 揭示与离散** | `FaceAudience`；标志/引用 | **`AtomRevealCard`** → `reveal_to_*`；`AtomSetFlag`；`AtomSetRef` |

**Register** 是效果但 **不是** L0；整流程 **Draw/DealDamage/Play** = 命名 `seq.*` 展开为 L0 + Register。

`CompositionNode.atom_name` 是 **调用包装**，必须归约到 L0（含 **Reveal**）或 Register 路径。

#### 砖块（Brick）— 边界

四类（§4.1 `BrickKind`）：

| Brick | 改 GameState？ | 改 Registration？ | 典型 |
|---|---|---|---|
| **EFFECT** | 是（经 L0/L1，含 **Reveal**） | 可（Register 节点） | `reveal_batch`、`commit_enter_hand`、E3 RESTRICTION |
| **REVEAL** | **是**（③ `AtomRevealCard`，类内子操作） | 否 | D2/E2 `reveal_to_*`（Grimoire Reveal 步） |
| **SUBSEQUENCE** | 委托子 seq | 委托 | `nest seq.draw.empty_piles_defeated`、`nest seq.enter_hand` |
| **FRAMEWORK_STEP** | 经框架通道 | — | Upkeep 步进、阶段切换 |

#### 砖块（Brick）— 种类与上界

四类（§4.1 `BrickKind`）：

| Brick | 改 GameState？ | 改 Registration？ | 典型 |
|---|---|---|---|
| **EFFECT** | 是（经 L0/L1） | 可（L2 Register） | G0–G2：`pop_deck_top`、`shuffle_and_horror`、E3 RESTRICTION |
| **REVEAL** | **是**（③ 揭示与离散） | 否 | D2/E2 `reveal_to_*` |
| **SUBSEQUENCE** | 委托 | 委托 | nest 已有 `seq.*` |
| **FRAMEWORK_STEP** | 经框架通道 | — | Upkeep 步进 |

**单砖上界（已裁决）**：最大粒度 = **G2 RuleStep**（含 Register 或 **Reveal** 边界的 **一步** Grimoire 步骤）。更长流程 = **同一条 `seq.*` 内多砖顺序拼（G3 SubFlow）**，**不** register 子 `seq.*`。

**不是砖块**：Eligibility L0–L7、Player Window、`RestrictionEvaluator` 查询、TimingBus emit — **执行框架**（Buff 查询见 [06 §16](06-registration-buff-model.md)）。

### 4.0.2 砖块粒度分类（G0–G3）

| 等级 | 名称 | 展开 | 独立 Grimoire 步 / timing 边界？ | 例子 |
|---|---|---|---|---|
| **G0** | AtomWrap | 单次 L0（或 atom_name 包装） | 否 | `pop_deck_top`、`commit_enter_hand` |
| **G1** | Compose | L1 Composition（多 L0 + Seq/Choice） | 通常否 | `shuffle_and_horror`、`reveal_batch` |
| **G2** | RuleStep | G1 + **L2 Register**，或 **Reveal 砖** 对应的一步 | **是** | E3 peril REGISTER；D2 **Reveal** |
| **G3** | SubFlow | handler 内 **有序多砖**（G0–G2），可 `×N` 循环 | 由 **最外层 G2** 或 seq 政策定 | D1「collect 一张」= G1→G0 两砖 × N |

```text
上界链：L0  ⊂  G0/G1 EFFECT  ⊂  G2 RuleStep  ⊂  G3 SubFlow（多砖）  ⊂  seq.*（命名流程）
                              ↑ 单砖最大到这里          ↑ 小序列到此为止，不必升格
```

**G3 不是 BrickKind**：是 **文档/handler 分组**——同一 `seq.*` RESOLVE 里连续执行的砖块序列（含 loop）。  
**SUBSEQUENCE 不是 G4**：仅 **跨 Catalog 入口复用** 或 **因果上成立新的 triggering condition** 时 nest 已有 `seq.*`；**禁止**把 G3 默认升格为子 `seq.*`。

### 4.0.5 内联 vs 嵌套：**流程连续** vs **时点触发的结算**（已裁决）

> **术语**：**结算**（resolve）= 可 **CREATED** 的写入（L0 状态原语、G2 **Register**、卡面 Composition 等，见 [07-composition §4](07-composition.md)）；**遭遇结算时点** = `seq.draw.encounter` 的 WHEN 区间（E2 后–E5 前）及其 **子时点 commit**（peril 检测、牌实例 bind、after card resolved 等）。

划分内联 / nest 的 **操作判据**（一条即可）：

> **上一步是否触发了本步结算所依附的时点锚点？**  
> **是** → **nest**（新 TC / 新 `(sequence_id, slot)`；本步作为 **独立结算** 入栈）  
> **否** — 只是同一 encounter WHEN 内的 **连续 then**（无独立子时点）→ **内联**

| | **内联** | **嵌套** |
|---|---|---|
| **语义** | 同一 WHEN 内的 **then**（流程连续） | 子时点 **触发** 一段 **独立结算** |
| **TriggeringCondition** | 不新建 | 新建（或 `sequences.nest` 等价 TC） |
| **典型** | E2 reveal、E5 默认 discard | Register Buff、显现 Forced、spawn、涌动再抽 |

```text
内联：  A ──then──► B ──then──► C     （B 无独立子时点锚；同一 WHEN 内连续）
嵌套：  A ──emit/commit 子时点──► nest B   （B 是依附该子时点的结算，含 Register）
```

**Register 也是结算**：向 `RegistrationStore` 写入 Buff（G2 Register）与 L0 move、卡面 Composition **同属 resolve**。**Buff 创建可 nest**，触发源是 **遭遇结算子时点**，不必等「有没有玩家响应窗」。

**与旧判据的关系**：「上一步是否触发了 **响应** 时点」是子集；**Forced / Register / 关键词 LISTENER fire** 只要锚在子时点上，均 **nest**。

**示例（调查员 `seq.draw.investigator`）**：

| 段 | 内联 / nest | 理由 |
|---|---|---|
| D1 collect / D2→D3 物理入手 | **内联** | 同一 draw WHEN 内连续；**未** commit 独立子时点 |
| D3 `commit_enter_hand` 后带 Revelation | **nest** `enter_hand` | **入手子时点** 触发显现结算 |
| 两堆皆空 | **nest** `empty_piles_defeated` | **抽牌失败子时点** 触发 defeated 结算 |

**示例（遭遇 `seq.draw.encounter` · priority 队列）**：

| 段 | Priority | 说明 |
|---|---|---|
| E1+E2 Draw | emit timing | G1 → `ENCOUNTER_CARD_DRAWN` |
| E3 peril | **100** | Register RESTRICTION |
| E4 显现 | **90** | nest Forced |
| E5 enemy / treachery | **80** | spawn 默认/指令 或 discard |
| AFTER | **75** | emit |
| E6 Surge | **70** | 再抽 G1 |

**禁止**：为 Grimoire 段落 **proliferate** 平行 `seq.encounter.check_peril` 等 **命名流程**（handler 内 nest + `composition.execute(register)` 即可）；把 **已由子时点触发的 Register/Forced** 压进内联（漏 slot / provenance）。

#### 4.0.5.1 险境 / 显现 / 涌动：同锚点、异优先级（已裁决）

三者均订阅 **`ENCOUNTER_CARD_DRAWN`（抽取遭遇牌时）**；Grimoire G2–G5 由 **FrameworkPriority** 排序（§4.0.5.2）。显现 = Forced；险境 = Register RESTRICTION；涌动 = priority 70；**敌人进场（默认 / 指令 Spawn）与 treachery discard = 同档 priority 80**，指令只改 spawn 分支。

#### 4.0.5.1a 险境 vs 显现（Buff 类型对照 · 保留）

> **术语**：**timing entry** = 时点条目；**Register** = 注册 Buff；**RESTRICTION** = 限制类 Buff；**encounter resolution frame** = 遭遇结算帧（drawer / surge 诊断，**不** 承载 peril）。

两者在遭遇结算时间线上 **十分接近**（同在 `resolve_card_body` 内、常与入手前后衔接），但 **不是同一类引擎事件**：

| | **险境 E3** | **显现 E4** |
|---|---|---|
| **魔典语义** | 只规定结算期间限制 **已生效**（*while resolving*）；**未** 规定 Register 写入时刻 | Forced 能力须 **resolve**（结算）；订在 encounter draw / 入手等 entry |
| **规则性质** | **帧内不变量**（frame-scoped invariant） | **完整 timing entry**（卡面 Forced / 订阅窗） |
| **引擎做什么** | nest：**Register RESTRICTION** 结算（peril 检测子时点触发） | nest：Forced Composition 结算 |
| **能力订阅** | RESTRICTION 供 L4 **查询**；子时点可登记 TimingCatalog | 卡面订 Revelation / encounter draw 等 entry |
| **结构** | **nest** Register（非独立 `seq.check_peril`） | **nest** `seq.encounter.revelation` |
| **内联/nest 判据** | **是** — 遭遇结算 **peril 子时点** 触发 Register 结算 | **是** — 显现 **子时点** 触发 Forced 结算 |

**Grimoire 读法**：peril 只规定区间内限制 **成立**，未规定 Register 时刻；引擎在 **peril 检测子时点** nest Register 以满足不变量。RESTRICTION **生效**仍靠 L4 查询，不靠 nest 开窗给玩家响应。

```text
resolve_card_body（时间线相近）
  E2 reveal ──then──► nest E3 Register RESTRICTION（peril 子时点 · 结算）
                           ──then──► nest E4 revelation（显现子时点 · 结算）
```

**勿混淆**：E3 nest 的是 **Register 这段结算**，不是另开 Grimoire 命名 `seq.*`；与 E4 nest 显现 **同型**（子时点 → 独立结算入栈），Buff 类型不同（RESTRICTION vs Forced Composition）。

**帧边界（已裁决）**：险境 RESTRICTION **不跨 Surge** — 生命周期 **`WHILE_DRAWN_CARD_RESOLVING(card_id)`**，**G4 完成、G5 Surge 再抽前** Unregister；与魔典 *that peril encounter* / Surge *after resolves* 一致。

#### 4.0.5.2 抽取遭遇牌：单一时点 + 优先级排序（已裁决）

> **术语**：**ENCOUNTER_CARD_DRAWN** = 抽取遭遇牌时（G1 Draw commit 触发的 timing entry）；**FrameworkPriority** = 框架优先级（同 timed 下结算体的自动排序键）。

**已裁决**：**险境、显现、涌动、敌人进场（spawn）、诡雷弃置（discard）** 均锚在 **同一 timing entry — 抽取遭遇牌时**（`ENCOUNTER_CARD_DRAWN`）。Grimoire G2–G5 由 **FrameworkPriority** dequeue；**Spawn 指令（Spawn – 文本）只改进场方式，不另开 timing entry**。

| 结算体 | Buff / 类型 | FrameworkPriority | Grimoire | 生命周期 / 备注 |
|---|---|---|---|---|
| **险境 Register** | RESTRICTION | **100** `PERIL_KEYWORD` | G2 | **`WHILE_DRAWN_CARD_RESOLVING(card_id)`** — G4 完 Unregister |
| 玩家 When draw [reaction] | LISTENER / TRIGGERED | **95** | When 示例 | peril 已生效 |
| **显现 Forced** | Composition | **90** `REVELATION_FORCED` | G3 | 同 timing |
| **G4 类型落点** | L0 Composition | **80** `ENCOUNTER_TYPE_RESOLVE` | G4 | 见下表；**含** 敌人进场 + treachery discard |
| emit **AFTER(card)** | — | **75** | After draw | G4 后、Surge **前** |
| **Surge 再抽** | keyword flow | **70** `SURGE_KEYWORD` | G5 | evaluate `has_surge`（含 E4 赋予） |

**Priority 80 · G4 分支**（同一 dequeue 档；**非** 独立 timing）：

| 卡类 | 条件 | 进场 / 落点模式 | L0 路径（[08 §7](08-enemy-engagement.md)） |
|---|---|---|---|
| **Treachery** | 默认 | 遭遇弃牌堆 | `discard_to_encounter_pile` |
| **Treachery** | Hidden 已在 hand | 跳过 discard | E4 Composition 已处理 |
| **Enemy** | **无** `Spawn –` 文本，非 Aloof | **默认生成** · engaged with drawer | `spawn_engaged(drawer)` |
| **Enemy** | **无** Spawn 文本，**Aloof** | 默认生成 · unengaged at drawer.location | `spawn_at_location` |
| **Enemy** | **有** `Spawn –` 文本 | **指令生成** · 解析 instruction → 选 location | `resolve_spawn_location` → `spawn_at_location` |
| **Enemy** | 有 Spawn，非 Aloof | 指令生成 + auto engage | 上式 + `auto_engage_at_location` |
| **Enemy** | 无合法 location | spawn 失败 | `discard_spawn_failed`（owner 堆） |

```text
G1 Draw commit → emit ENCOUNTER_CARD_DRAWN
  priority_queue.dequeue_all():
    100 peril Register
    95  player When draw
    90  revelation Forced
    80  G4: treachery discard | enemy spawn（instruction 分支在 handler 内）
         → Unregister peril(card_id)
    75  AFTER(card)
    70  surge? → 下一张 G1
```

**Spawn 指令语义**：`CardDefinition.spawn_instruction` / 牌面 `Spawn –` 文本 → **仅修改** `seq.encounter.spawn` handler 内 `spawn_from_encounter_draw` 的分支（location 解析、auto engage）；**不** 注册第二 timing hook。

**与 nest 的关系**：priority 80 的 enemy 结算 **nest `seq.encounter.spawn`** 入栈（与 E4 nest `seq.encounter.revelation` 同型）；**触发源仍** 为 `ENCOUNTER_CARD_DRAWN`，与 treachery discard **同档不同支**。默认生成与指令生成 **共用** 同一条 nest，handler 内分支。

**禁止**：`WHILE_ENCOUNTER_FRAME` 承载 peril；`seq.encounter.spawn` 作为 **与 draw 平行的 timing entry**（禁止单独 `catalog.run` 脱离遭遇抽牌）；为默认/指令 spawn 各建 **两条** `seq.*`。

### 4.0.6 流程推进：**嵌套结束 → 回到内联下一步**（已裁决）

**游戏流程在 RESOLVE 内如何前进**：

| 层 | 推进方式 |
|---|---|
| **内联** | 同栈帧 RESOLVE 内的 **顺序步骤**（G0–G3 砖块、loop、`execute`）— **流程连续** |
| **嵌套** | 某内联步 **导致** 新 TC → **暂停** 内联游标 → 子栈 **整段** WHEN→RESOLVE→AFTER（可再嵌套）→ pop |
| **恢复** | 一串嵌套 **全部结束**（子帧 pop 回父帧）→ **继续父 RESOLVE 的下一内联步** |

```text
父 RESOLVE（内联程序）
  step₁ 内联
  step₂ 内联 ──causes──► nest 子 A
                            子 A RESOLVE
                              … nest 孙 B …
                              孙 B pop
                            子 A AFTER → pop
  step₃ 内联   ◄── 嵌套链结束后才执行
  step₄ 内联
父 AFTER → pop
```

**要点**：

1. **嵌套不替换内联** — 子栈是在 **父 RESOLVE 中途** 插入的因果支链；pop 后 **不是** 开新 seq，而是 **接着跑** 父 handler 里尚未执行的内联步。  
2. **LIFO 只作用于嵌套** — 多层 nest 先完最深子帧；**同一层内联** 仍是 **FIFO 顺序**（then）。  
3. **实现（v0）** — `catalog.nest` / `sequences.nest` **同步**调用 `run()`，子树跑完 **return** 到父 resolve 回调的 **下一行**（见 `draw_investigator_flow.gd`：`collect_one_step` 内 nest `empty_piles` 返回后继续 loop 或 `reveal_batch`）。  
4. **实现（目标）** — `RuleSequenceDef.bricks` + 帧上 **内联游标**；nest 时保存游标，pop 后 **advance 到下一块**（与现 handler 语义等价）。

**`seq.draw.investigator` 示例**：

```text
[内联] while collect_one_step …
         └─[nest] empty_piles? → pop → return defeated / 继续 loop
[内联] reveal_batch
[内联] enter_hand_batch
[nest_batch] enter_hand
         └─ foreach: [nest] enter_hand 逐张 → pop → 下一张
（内联结束）
父 AFTER
```

**禁止**：子 pop 后 **跳过** 父 RESOLVE 剩余内联步直接父 AFTER（除非父 RESOLVE 已显式 abort）；在 AFTER 关闭后 **异步** 补 nest（14 §7）。

**何时拆砖**：

1. Grimoire **单独成步**（E3、D2 Reveal）→ **独立 G2 砖**（REVEAL 或 REVEAL + 后续 EFFECT）。  
2. **打开/关闭 WHEN 区间** → G2 **REVEAL** 或 seq 政策锚点。  
3. 仅 L0 一次调用、无独立时点 → **并入 G1**，不单独占砖。  
4. 多步 **仅在本流程内**、**无新 triggering condition**（流程连续）→ **G3 砖列表**，不 register 子 seq。

### 4.0.3 蕴含关系（⊂ / ⊥）

```text
seq.*  (RuleSequenceDef)
  ⊃  BrickList[]           有序；G3 = 连续片段，非新类型
       ├─ EFFECT  ⊃  Composition?  ⊃  L0*
       │            ⊃  RegisterNode?  → RegistrationStore（挂 Buff；查在 Intent 入口）
       ├─ REVEAL       ⊃  reveal_to_*     → StateMutator / AtomRevealCard
       ├─ SUBSEQUENCE  ⊃  run(other seq.*)   可选；⊄「砖块升格」
       └─ FRAMEWORK_STEP  ⊃  FrameworkChannel

MoveCard ⊥ Reveal          正交：zone 变更 ≠ 揭示状态（分砖顺序拼，如 D2→D3）
G3  ⊃  ≥2 逻辑砖           仍在同一 seq.* 栈帧内
Buff 查询  ⊄  Brick         RESTRICTION 在 [06 §16](06-registration-buff-model.md) Intent 入口
```

| 关系 | 含义 |
|---|---|
| **seq ⊃ bricks** | 仅 **Grimoire 顶层命名流程** 占 `sequence_id` + push/pop |
| **EFFECT ⊃ L0** | 每个 EFFECT 砖 **必须** 能归约到三类 L0（或 L2 Register） |
| **G1 ⊃ G0×n** | Compose 砖 **蕴含** 多个 L0，对外仍 **一步** |
| **G3 ⊃ brick×n** | 小序列 **蕴含** 多步，**不** 蕴含新 `seq.*` |
| **SUBSEQUENCE ⊃ seq** | **因果** 上调用已有命名 seq（新 TC）；与 G3 **互斥**于同一逻辑段 |

### 4.0.4 拼接模式

| 模式 | 结构 | WHEN / emit | 例子 |
|---|---|---|---|
| **Linear** | `B₁ → B₂ → … → Bₙ` | 首个 G2 或 seq 政策 | E1→E2→E3 encounter |
| **Batch** | `repeat G3)` 或 `nest_batch` | 父 seq WHEN 覆盖整段 | draw N：collect G3 × N |
| **RevealSandwich** | `REVEAL` → `EFFECT*` → 关闭区间 | REVEAL 开 WHEN；末 EFFECT 关 | D2 reveal → enter_hand |
| **RegisterPoint** | 单 G2 EFFECT（Register） | 常单点 emit | E3 peril |
| **Delegate** | `SUBSEQUENCE` → 已有 `seq.*` | 继承 **子 seq** 政策 | `seq.action.draw` → `seq.draw.investigator` |

Handler 实现：`RuleSequenceDef.bricks` 定 **Linear / InfoSandwich / RegisterPoint**；**Batch** 用 loop 或 `catalog.nest_batch` 调 **同 seq 内** G3 逻辑；**Delegate** 才 `catalog.run(other_seq)`。

#### L1 / L2 与砖块的关系

| 层 | 名称 | 与砖块 |
|---|---|---|
| **L1** | Composition 控制流 | **G1+ EFFECT** 的展开体 |
| **L2** | Register / CancelPending / ReplacePending | **G2 EFFECT** 内节点 |
| **L3** | 宏（Draw、DealDamage…） | 编译期展开为砖块列表；不进运行时 tree |

#### 砖块 vs 命名 RuleSequence

| | **砖块** | **`seq.*`** |
|---|---|---|
| **角色** | 步骤 | Grimoire **顶层**命名流程 |
| **栈帧** | 无独立 id | push / pop |
| **LISTENER 订阅** | 不单独订 | `(seq.*, slot)` |
| **小序列** | **G3 多砖拼成** | 不为此单独开 seq |

**RuleSequence 不覆盖的**：Eligibility、Player Window、`RestrictionEvaluator` — **执行框架**。

#### 竖切对照（调查员抽牌 · 砖块拼成，不必子 seq）

```text
seq.draw.investigator                    ← 唯一命名 seq（Grimoire Draw Cards）
  [G3 × N] collect 小序列（两砖，**内联**于 `seq.draw.investigator`）
      [G1 EFFECT] shuffle_and_horror
      [G0 EFFECT] pop_deck_top
  [G1 EFFECT] reveal_batch               ← D2
  [G1 EFFECT] enter_hand_batch           ← D3（可 nest seq.enter_hand 作 Delegate）

seq.action.draw                          ← 另一命名 seq（耗 action）
  [SUBSEQUENCE Delegate] → seq.draw.investigator
```

### 4.1 Brick 种类

```gdscript
enum BrickKind {
    EFFECT,          # L0 原子 / Composition 落地（改 zone、伤害等）
    REVEAL,          # AtomRevealCard：写 FaceAudience（Grimoire Reveal；是 L0 效果）
    SUBSEQUENCE,     # 嵌套另一条 RuleSequence
    FRAMEWORK_STEP,  # 框架步（框架通道）
}
```

| Brick | 是否「效果施加」 | 典型 |
|---|---|---|
| **EFFECT** | 是 | G0–G2：MoveCard、Register RESTRICTION、`enter_hand` |
| **REVEAL** | **是**（③ AtomRevealCard） | `FaceAudience` → CONTROLLER / ALL（[01 §3.6](01-game-state-zones.md)） |
| **SUBSEQUENCE** | — | **Delegate**：跨命名 seq 复用（如 action.draw → draw.investigator） |
| **FRAMEWORK_STEP** | — | Upkeep 步进、阶段切换 |

### 4.2 RuleSequenceDef

```gdscript
class RuleSequenceDef:
    var id: StringName                    # seq.action.draw_cards
    var bricks: Array[SequenceBrick]
    var run_via: RunVia                   # SEQUENCE_STACK | FRAMEWORK_ENGINE | …
    var when_anchor: WhenAnchorPolicy     # §5
    var pre_impact: PreImpactSlotPolicy   # §6
    var after_merge: AfterMergePolicy     # §7
    var zone_semantics: String            # 文档：给人读的 zone 说明
```

---

## 5. Triggering Anchor Policy（引擎裁定）

**原则：触发时机 ≠ 区域坐标。**  
Grimoire 未定义 deck→hand、leave→enter 中间态时，**不**用 zone 推导 When；用 **Committed / Atomic 意图** 对齐桌游直觉，用 **单 brick 事务** 对齐严格实现。

### 5.1 全局 When 规则（默认）

> **多数行动序列：`WHEN` = push 之后、RESOLVE 内第一个 **EFFECT** brick 执行之前 emit 一次。**  
> **例外：`seq.draw.investigator` 使用 **WHEN 区间 D2–D3**（§16），非单点 emit。

### 5.2 政策表（v0）

| Policy | 适用 sequence | 含义 |
|---|---|---|
| **DRAW_WHEN_SPAN_D2_D3** | `seq.draw.investigator` | WHEN **窗口** = 控制者 **CONTROLLER**（D2 后）至 ENTER_HAND 完成（D3 后，含显现 nest） |
| **DRAW_WOULD_BEFORE_D2** | `seq.draw.investigator` | WOULD = instance 已 bind（D1 后）、**D2 信息 reveal 前** |
| **DRAW_ENCOUNTER_WOULD_BEFORE_G1** | `seq.draw.encounter` | WOULD = E0 意图后、**G1 pop 前** |
| **DRAW_ENCOUNTER_WHEN_SPAN_G1_G4** | `seq.draw.encounter` | WHEN = **G1 Draw 完成后** → **G4 完成后**（非 E2 后） |
| **ENCOUNTER_CARD_DRAWN** | `seq.draw.encounter` | **抽取遭遇牌时**（G1 commit）；险境/显现/涌动 **同锚点** + FrameworkPriority |
| **ENCOUNTER_REVELATION_COMMITTED** | `seq.encounter.revelation` | 遭遇显现 nest；priority **90**；**非** `seq.enter_hand` |
| **MOVE_INTENT_COMMITTED** | `seq.action.move` | from/to **已确定**；leave+enter **规则上同时**（一个 brick） |
| **FIGHT_COMMITTED** | `seq.action.fight` | Fight 行动 **开始 RESOLVE**；默认与内嵌 test 的 AFTER **merge**（§7） |
| **GAIN_COMMITTED** | `seq.gain_resource`（设计别名 `seq.action.gain_resource`） | 一次 gain 结算 commit（已实现竖切） |
| **REVEAL_COMMITTED** | `seq.encounter.reveal` | 遭遇显现；`pre_impact=SPLIT` |

### 5.3 Move 事务

**Move — `move_transaction`（一个 EFFECT brick）：**

```text
inv.location := to    # leave + enter 一次提交；不拆 leave/enter 两个 entry
```

**禁止**用 `card.zone == HAND` / `inv.location` 判断「是否算 draw/move 时」；draw 用 **CardFaceVisibility**（§16、[01 §3.6](01-game-state-zones.md)）。

---

## 6. Would 与 When：PreImpact 政策

| Policy | 含义 | 典型 sequence |
|---|---|---|
| **WHEN_ONLY** | 只登记 WHEN | 多数 action |
| **WOULD_AND_WHEN_ALIAS** | would/when **可互换**；编译映射同一 PreImpact；**无**结构分叉 | fight、gain、move（默认） |
| **WOULD_AND_WHEN_SPLIT** | would/when **不可互换**；有 **明确步骤分界** | **`seq.draw.investigator`**、**`seq.draw.encounter`**、encounter reveal |

**要点：**

- 大多数序列 **would/when 可 ALIAS**；差别是 **印刷 / 编译**。  
- **Cancel/Replace** 绑 **pending 生命周期**（`replaceable_until`），不绑 would/when 字面。  
- **Draw** 必须 SPLIT：WOULD / WHEN / AFTER 各有 **规范步骤区间**（§16）。

---

## 7. After 与嵌套 merge（Fight / ST.8）

**原则：一个 pop 一次 AFTER offer**（同帧 merge 除外）。

| 情况 | 行为 |
|---|---|
| 父序列 **仅含** 一个 SUBSEQUENCE brick，且 pop 子序列后 **无后续 brick** | **只 emit 父 AFTER**；子 AFTER **defer**（默认 Fight ≈ attack test） |
| 子序列 pop 后 **还有** post brick（如「本次 attack 后」追加效果） | **先 emit 子 AFTER**，父 pop 时再 emit 父 AFTER |
| 独立 Event 检定 | 仅 `seq.skill_test.*` 的 AFTER |

**Fight 与 ST.8：** 不是「哲学上两个入口」，而是 **bricks 是否延伸** 决定是否两个 pop、两个 AFTER。默认 **对齐 merge**；延伸 Fight 才分叉。

---

## 8. emit 唯一出口（TBD）

> **状态**：流程明细稳定后再建 **TimingCatalog** 索引表；本节仅保留接口形状。

```gdscript
class TimingCatalog:
    func emit(sequence_id: StringName, slot: TimingSlot, app_ctx: ApplicationContext) -> void
    # → EligibilityPipeline COLLECT (L0–L5)
    # → ResponseWindow
    # → Initiation L6–L7（若适用）
```

**Invariant（目标）**：旁路 `TimingBus.emit_timing("after_*")` 逐步废除；emit 只从 **已登记流程** 的边界发出。

---

## 9. Catalog 准入（TBD）

流程 `RuleSequenceDef` 定稿后再写准入四问与索引表。见 §17。

---

## 10. 与 Eligibility / ResponseWindow 的分工

| 层 | 职责 |
|---|---|
| **TimingCatalog.emit**（TBD） | L0 叫醒 |
| **EligibilityPipeline** | L1–L5 收集；L6–L7 Initiation（[06 §5](06-ability-initiation.md)） |
| **ResponseWindow** | `[reaction]` 选用、队长排序、关闭时点 — **不是关卡**（[06 §6](06-ability-initiation.md)） |

---

---

## 16. 调查员抽牌：`seq.draw.investigator`（规范流程）

> **定义**：将一张或多张牌从牌库顶经 **信息揭示** 移入手牌的过程（Grimoire **Drawing Cards**）。  
> **一次指令**（`amount` 张）= **一次** `sequences.run`；`amount ≥ 2` 且同一 ability/game step → **同时** reveal + 入手（非 N 次独立 push）。  
> **Draw 行动** = `amount = 1` 的特例（外壳见 [03-action-system §6.1](03-action-system.md)）。

### 16.1 牌面可见性（Domain）

见 **[01-game-state-zones §3.6](01-game-state-zones.md)**。抽牌使用 **FaceAudience**，与 zone **正交**。

| 步骤 | 对 **控制者** 的牌面 | 对 **其他调查员** |
|---|---|---|
| D0–D1 | HIDDEN_ALL | HIDDEN_ALL |
| **D2 后** | **CONTROLLER**（已知牌面） | HIDDEN_ALL（仍只见手牌/牌背或未知） |
| D3 后（在手牌） | CONTROLLER | HIDDEN_ALL |
| 效果「全体揭示牌库顶」 | ALL | ALL |

```gdscript
# REVEAL 砖（D2）示意
func reveal_to_controller(card_id, controller_id):
    card.face.audience = FaceAudience.CONTROLLER
    card.controller_id = controller_id  # 若尚未设置
```

**牌面首次对控制者可见 = D2 结束**（**Reveal** 原语写入 `CONTROLLER`）。**不是** D3 进 hand 时才首次可见。

### 16.2 步骤 D0–D5

```text
D0  抽牌意图成立（push 前 / push 瞬间）
    信息：HIDDEN_ALL（控制者亦不知牌面）
    区域：未动牌

D1  收集单张（**内联 G3** 循环 `collect_one_step`，直至 `amount` 或终止）
    · 牌库非空 → `pop_deck_top` → 写入 `RulesMemory.draw_pending`
    · 空库 → L1 `shuffle_and_horror`（`shuffle_discard_into_deck` + `HORROR_TAKEN`）→ 再 pop
    · 两堆皆空 → nest `seq.draw.empty_piles_defeated` → 本张 draw 终止
    信息：HIDDEN_ALL（控制者亦不知牌面）

D2  REVEAL — `reveal_batch`（L1 Composition of `reveal_to_controller`）
    牌面：HIDDEN_ALL → **CONTROLLER**（控制者）  ★ D2 ★
    区域：仍可 deck / Limbo（实现）；触发不读 zone

D3  ENTER_HAND — `enter_hand_batch`（L1 Composition of `commit_enter_hand`）
    信息：CONTROLLER（控制者）；他人仍 HIDDEN_ALL
    区域：→ HAND（或卡定义 `enter_zone`，如 LIMBO）
    · **全部** pending 牌 D2 完成后 **批量** reveal；再 **批量** commit 入手
    · 入手后 `nest_batch seq.enter_hand`：对 **具备 Revelation 能力** 的牌逐张 nest timing `enter_hand`
      （Forced；**不是** D5 之后、**不是** 独立 D4 尾巴）
      · **Weakness ⊄ Revelation**：弱点不一定有显现；无显现则仅 timing 跳过
      · **Revelation ⊄ Weakness**：Dilemma 等玩家牌亦可有显现；同一 `seq.enter_hand` 规则

D5  pop → emit AFTER
    「After you draw」；含 D3 内各 Revelation nest 全部完成后
```

**无 D4。** **Revelation 结算**是 **D3 入手事务的一部分**（仅当该 instance 带 Revelation 能力），不是抽牌 pop 之后的附带步。

### 16.3 Would / When / After 的 **准确位置**

| Slot | 步骤区间 | 控制者牌面 | 说明 |
|---|---|---|---|
| **WOULD** | **D1 完成后 → D2 开始前** | HIDDEN_ALL | 「将要抽」；instance 可已 bind |
| **WHEN** | **D2 完成后 → D3 完成后** | **CONTROLLER** | 「抽牌时」= **D2–D3 整段**（含入手、Revelation nest） |
| **AFTER** | **D5 pop 后** | CONTROLLER，已在 hand | 各 Revelation nest 已返回 |

**WHEN 是区间，不是 D2 与 D3 之间的单点：**

```text
open TimingWindow(seq.draw.investigator, WHEN)   # D2 Reveal 完成
  … 可 refresh；D3 内 `seq.enter_hand` nest 显现 …
close TimingWindow                              # D3 ENTER_HAND + seq.enter_hand nest 完成
```

**「When you draw」** 能力在 **控制者已为 CONTROLLER 之后、draw 序列 pop 之前** 均可响应，**包括** 正在入手与 **显现结算期间**（仍在 D3 内）。

**「When you would draw」** → 订阅 **WOULD**（D2 前）。

### 16.3.1 Slot / 步骤 / 结构对照（模板）

译 flow 时 **先判因果边界，再列 slot，再选内联或 nest**（§4.0.5）。能力订阅 **`(sequence_id, slot)`**（§2）。

| 步骤 | 内联/嵌套 | 因果 vs 连续 | 应 emit 的 TimingEntry | 典型能力 | 实现 |
|---|---|---|---|---|---|
| D0 push | 根 `run` | 整段 draw **开始** | — | — | ✅ |
| D1 collect ×N | **内联** | **连续**（同一次 draw 收集） | 父 **WOULD** | would draw | ⚠️ WOULD 未 emit |
| D1 两堆空 | **nest** | **因果**：空库 **导致** defeated | （abort；无父 AFTER） | — | ✅ |
| D2 reveal | **内联** | **连续**：draw 事务一步 | 父 **WHEN open** | when you draw | ❌ |
| D3 enter_hand | **内联** | **连续**：draw 事务一步 | 父 WHEN 仍开 | 同上 | ❌ |
| D3 显现 | **nest** | **因果**：入手 **触发** Revelation | 子 `(enter_hand, slot)` | Revelation | ✅ nest |
| D5 pop | 父 pop | draw **结束** | 父 **AFTER** | after you draw | ✅ pop；❌ offer |

**结构决策（因果优先）**：

| 逻辑段 | 选择 | 理由 |
|---|---|---|
| D2 + D3 物理入手 | **内联** | **流程连续**，同一 draw TC |
| D3 显现 | **nest** | **因果关系**，新 `enter_hand` TC |
| D1 collect 循环 | **内联** | **流程连续**，G1 shuffle + G0 pop |

新 `seq.*` 可复制本表格式写入对应 §16/§17 节。

### 16.4 Bricks 与 SequenceCatalog 映射

**原则**：规则步骤 = **SequenceCatalog 条目** + **L1 Composition 树**；不为每个 flow  proliferate Service。薄 facade（`DrawInvestigatorService`）仅 `catalog.run(flow_id, params)`。

```text
seq.draw.investigator          # RUN · catalog.register_run
  RESOLVE:
    init RulesMemory (draw_pending / draw_shuffles / draw_horror_taken)
    while pending.size < amount:
      collect_one_step (内联 G3)        # shuffle+horror / pop；两堆空 → nest empty_piles
    execute reveal_batch              # L1 · D2
    execute enter_hand_batch          # L1 · D3 物理落点
    nest_batch seq.enter_hand         # NEST_BATCH · D3 显现 timing

seq.draw.empty_piles_defeated  # RUN · 因果 nest 于 D1 内
  RESOLVE:
    set_flag(ELIMINATED)

seq.enter_hand                 # NEST_BATCH · 所有「进入手牌」来源共用
  for card_id in card_ids (按顺序):
    if has_revelation(card_id):
      nest TriggeringCondition.enter_hand
      CardAbilityService.resolve_revelations → Composition
    if still LIMBO → finalize_limbo_discard
```

**Timing emit（目标，待 TimingCatalog）**：

```text
  WOULD  — after collect 绑定 instance、before D2 reveal_batch
  WHEN   — open after D2; close after nest_batch(seq.enter_hand)
  AFTER  — on seq.draw.investigator pop
```

#### 16.4.2 框架 Upkeep 4.4（`UPKEEP_4_4_DRAW_AND_RESOURCE` · 已实现）

Grimoire 补给：**每位调查员抽 1 张 + 获 1 资源**。引擎 **不** 内联改 `resource_pool`，经 Catalog **Delegate** 已有 seq：

```text
FrameworkFlowEngine._resolve_upkeep_draw_and_resource()
  foreach inv_id in player_order:
    [Delegate · 连续] draw_investigator.draw_cards(amount=1, tags=[framework, upkeep_4_4])
    [Delegate · 连续] resource_gain.gain(base=1, tags=[framework, upkeep_4_4])
```

| 步 | 内联/nest | 因果 | seq |
|---|---|---|---|
| 抽 1 | Delegate → 完整 draw seq | 连续（框架编排） | `seq.draw.investigator` |
| +1 资源 | Delegate → 完整 gain seq | 连续 | `seq.gain_resource` |

**tags**：`framework` + `upkeep_4_4`；`gain_resource` / `draw_investigator` 由 `TriggeringCondition` 自动附加。L3 能力可绑 `framework_step == UPKEEP_4_4`（见 06 §4.1）。

代码：`rules/framework/framework_flow_engine.gd` · `GameBootstrap` 绑定 `GameContext`。

```gdscript
# seq.enter_hand handler 示意（已实现）
func nest_enter_hand(game_ctx, params):
    for card_id in params.card_ids:
        if not abilities.has_revelation(game_ctx, card_id):
            continue
        game_ctx.sequences.nest(
            TriggeringCondition.enter_hand(controller_id, card_id, tags),
            func(): abilities.resolve_revelations(game_ctx, controller_id, card_id, provenance_flow_id)
        )
```

### 16.4.1 显现结算顺序（设计师待定 · 可配置占位）

**状态**：Grimoire / 设计师 **尚未最终裁定** `enter_hand` 时点多张牌、多条显现能力之间的 **同类内** 顺序。引擎 **不硬编码** 最终规则，通过 `RulesConfig.enter_hand_timing`（`EnterHandTimingPolicy`）集中配置。

**与 [06 §8](06-ability-initiation.md) 两层模型对齐**：

| 层 | enter_hand 语境 | v0 |
|---|---|---|
| **类别优先级** | 显现（Revelation）nest 属 **FORCED 类**；整类先于同窗口 TRIGGERED [reaction] | 引擎 tier；`revelation_forced_sub_tier` 占位 |
| **同类内顺序** | 多张牌 / 单卡多条显现单元 **均在 FORCED 类内** 的自排 | 默认 `SOURCE_ORDER` + Registry 登记序 |

| 维度 | v0 默认 | 预留（**仅同类内**） |
|---|---|---|
| **多张牌同时入手** | `SOURCE_ORDER`：按来源 `card_ids` 顺序 | `CONTROLLER_CHOICE`；`DEFINITION_PRIORITY` |
| **单卡多条 Revelation 单元** | `CardRegistry` 登记序 | `order_ability_units()` |
| **显现 vs 其他 enter_hand [reaction]** | **跨类**：FORCED 批整体先于 TRIGGERED | 非玩家自排；见 06 §8.1 |

```gdscript
# rules/config/enter_hand_timing_policy.gd
class EnterHandTimingPolicy:
    enum CardRevelationOrder { SOURCE_ORDER, CONTROLLER_CHOICE, DEFINITION_PRIORITY }
    var card_revelation_order = CardRevelationOrder.SOURCE_ORDER
    var revelation_forced_sub_tier: int = 100   # ForcedSubTier.REVELATION_FORCED

# RulesConfig
var enter_hand_timing: EnterHandTimingPolicy = EnterHandTimingPolicy.new()
```

**调用链**：`seq.enter_hand` → `order_cards_for_revelation()` → 逐张 nest → `order_ability_units()` → Composition execute。

**Open Question**：OQ-TIMING-05（见 [open-questions-master](../open-questions-master.md)）。

### 16.5 与遭遇抽牌、Weakness 分流

| | `seq.draw.investigator` | `seq.draw.encounter`（§17） |
|---|---|---|
| 来源 | 调查员 deck | encounter deck（或 weakness 重定向，§17.6） |
| 牌面默认 | D2 → **CONTROLLER** | E2 → **ALL**（Hidden 例外，§17.2） |
| Revelation | **D3** 经 `nest_batch seq.enter_hand` | E4 经 **`seq.encounter.revelation`** |
| 空库 | 洗弃 + 1 horror | 洗遭遇弃牌堆，**无 horror** |
| Surge | — | E6 同帧内回到 E1 |
| WHEN 区间 | D2–D3（本节） | E2–E5（§17.3） |

**Weakness（卡子类型）** 与 **Revelation（能力类型）** 正交（Grimoire Glossary 分列）。  
**Weakness 按 cardtype 分流**（Grimoire *Weakness*）：**仅 encounter cardtype**（enemy / treachery）走遭遇管线；**player cardtype**（asset / event / skill 等）走调查员 draw + 入手。

| Weakness cardtype | 从调查员 deck 抽出时 | Revelation | 入手后 |
|---|---|---|---|
| **Enemy / Treachery**（遭遇型） | **重定向** §17.6 → `resolve_bound`；**非** D2–D3 | E4 `seq.encounter.revelation` | enemy spawn / treachery discard 等（§17 E5） |
| **Asset**（支援型弱点） | **本节** D2–D3 | 若有 → D3 `seq.enter_hand` | 作 **asset** 使用（play 进 play area / 槽位） |
| **Event**（事件型弱点） | **本节** D2–D3 | 若有 → D3 `seq.enter_hand` | 作 **event** 从 hand play |
| **Skill**（技能型弱点） | **本节** D2–D3 | 若有 → D3 `seq.enter_hand` | 作 **skill** commit 至检定（**不能** play） |
| **任意 player 型，无 Revelation** | D2–D3 仅 zone→hand | 无 nest | 留在 hand；**不可** 主动 discard（除非卡牌另说） |

| 情况（非 weakness 维度） | 行为 |
|---|---|
| 玩家牌 **有 Revelation**（含 Dilemma 等非 weakness） | D3 `nest_batch seq.enter_hand` |
| 玩家牌 **无 Revelation** | D3 仅 zone→hand |

> 详表与 `CardDefinition` 判定：[11 §10](11-investigator-campaign.md)、[15 §17.6](15-timing-entry-catalog.md)。

### 16.6 实现状态（Domain 竖切）

| 已有 | 待建 |
|---|---|
| `CardFaceVisibility` + `FaceAudience`（[01 §3.6](01-game-state-zones.md)） | `TimingCatalog` / WOULD·WHEN 区间 emit（TIM-01～04） |
| L0：`pop_deck_top`、`shuffle_discard_into_deck`、`commit_enter_hand`、`reveal_to_controller` | `seq.draw.encounter` |
| L1：`DrawInvestigatorComposition`（`shuffle_and_horror`、`reveal_batch`、`enter_hand_batch`） | 设计别名 `seq.action.gain_resource` → 代码 `seq.gain_resource` 对齐（可选） |
| `SequenceCatalog`：`seq.draw.investigator`、`seq.draw.empty_piles_defeated`、`seq.enter_hand`、`seq.gain_resource` | `TimingCatalog` 索引表（§17） |
| `DrawInvestigatorFlow` + `DrawSubflowHandlers`；`DrawInvestigatorService` → `catalog.run` | D1 per-card instance bind（当前以 `card_id` + pending 列表） |
| `CardRegistry.register_revelation` → Composition；ENT-01～03 测试 | encounter draw 共用 `seq.enter_hand` |
| `StateMutator.execute_draw_instruction` dry-run 回退（`run_mutator_only`） | |

**测试**：VIS-01/02、ACT-13～15、DRAW-02/03、ENT-01～03 已通过；TIM-01～04 待 TimingCatalog 后补测。

---

## 17. 遭遇抽牌：`seq.draw.encounter`（规范流程）

> **定义**：将一张或多张牌从 **遭遇牌库顶** 抽出，并按 Grimoire **Framework 1.4** / **Drawing encounter cards** 逐步结算的过程。  
> **一次指令**（`amount` 张）= **一次** `sequences.run`；每张牌 **完整** 走 E1–E6（含 Surge 链）后再抽批量中的下一张。  
> **Mythos 1.4** = `drawer_id` + `amount = 1` 的特例；Surge **不**另 push 外层序列。

> **依赖**：[10-scenario-encounter.md §2](10-scenario-encounter.md)、[04-skill-test-engine.md §4.1](04-skill-test-engine.md)（Peril 帧）、[08-enemy-engagement.md](08-enemy-engagement.md)（Spawn）。

### 17.1 牌面可见性（Domain）

遭遇牌 **默认公开**；与调查员抽牌（D2→CONTROLLER）不同。

| 步骤 | 对 **全体调查员** | 对 **drawer** | 说明 |
|---|---|---|---|
| E0–E1 | HIDDEN_ALL | HIDDEN_ALL | 尚未 bind 具体牌 |
| **E2 后（默认）** | **ALL** | **ALL** | 遭遇 draw 后全体见牌面 |
| **Hidden 关键词** | HIDDEN_ALL | CONTROLLER | 显现 **秘密** 入手；E2 **跳过** 公开 reveal |
| E5 后 enemy 在场 | ALL（公开 enemy） | — | zone 迁移；audience 随进场策略 |

```gdscript
# REVEAL 砖（E2 默认）示意
func reveal_encounter_drawn(card_id: StringName) -> void:
    card.face.audience = FaceAudience.ALL
```

**Hidden** 由卡定义/register 在 E4 分支处理，**不**在 E2 对全体 `ALL`。

### 17.2 步骤 E0–E7 与 Grimoire Framework 1.4 对齐

> **权威逐步流程**（Grimoire p.27 · Mythos 1.4）：  
> **G1** Draw → **G2** Check peril → **G3** Resolve revelation → **G4** Spawn / discard → **G5** Surge → restart G1。  
> Framework 1.4 **摘要句**（先写 revelation 再写 type）以 **编号逐步列表** 为准；摘要 **省略** G2 peril。

#### 17.2.1 引擎步骤 ↔ Grimoire 对照

| Grimoire | 引擎 | 说明 |
|---|---|---|
| — | **E0** 意图 / push 帧 | 引擎信封；魔典无对应步 |
| **G1 Draw** | **E1** `collect_one_step` + **E2** `reveal_encounter` | E2 为 G1 的 **L0 子步**（公开牌面）；魔典 **无** 独立 reveal 步；Hidden **跳过** E2 |
| **G2 Check peril** | **E3** nest Register RESTRICTION | **紧接 G1**，在 G3 **之前**（Framework step 2） |
| **G3 Revelation** | **E4** nest `seq.encounter.revelation` | treachery 在 **limbo**（暂存区）结算 |
| **G4 Spawn / discard** | **E5** nest spawn / 内联 discard | 二分，非并行 |
| **G5 Surge** | **E6** nest（evaluate + 再抽 → E1） | **G4 全部完成后**；含 E4 动态赋予 surge |
| — | **E7** pop 帧 + 外层 AFTER | 整链 Surge + 批量 `amount` 完成后 |

```text
E0  遭遇抽牌意图成立（push 帧前）
    drawer_id 已知；EncounterResolutionFrame 将创建

E1  G1 · Draw（内联 collect）
    · pop_encounter_deck_top → bind 牌实例
    · 空库 → shuffle_encounter_discard（无 horror）
    · 两堆皆空 → RULES_GAP（OQ-ENC-01）
    · E2 reveal_encounter — G1 子步（Hidden 跳过；非独立 Grimoire 步）

[WOULD 窗结束]

open WHEN   # G1 Draw 完成即开（非 E2 后）—「When you draw encounter」

E3  G2 · nest Register RESTRICTION（peril 子时点）
E4  G3 · nest revelation
E5  G4 · nest spawn / 内联 treachery discard

close WHEN

emit AFTER(card)    # 「After you draw an encounter card」— G4 后、G5 前

E6  G5 · nest Surge（evaluate has_surge → 再抽 E1；同一帧）

E7  无 Surge 且批量完成 → pop 帧 → 外层 AFTER
```

**无 enter_hand。** 玩家牌显现仍仅经 `seq.enter_hand`（§16）；遭遇显现 **永不** 复用该 nest。

### 17.3 Would / When / After 的 **准确位置**（对齐 Grimoire）

| Slot | 步骤区间 | 牌面（默认） | 说明 |
|---|---|---|---|
| **WOULD** | **E0 意图后 → G1 pop 前** | HIDDEN_ALL | 「When you **would** draw an encounter card」 |
| **WHEN** | **G1 Draw 完成后 → G4 完成后** | 非 Hidden：**ALL**（E2 后）；Hidden：drawer 见 E4 | 「When you draw…」；When 词条示例：**G1 后、G3 前**（*before revelation*） |
| **AFTER** | **G4 完成后 → G5 Surge 再抽 G1 前** | ALL 或已落场 | 每张牌 **独立** AFTER；Surge **不**合并 |

**Mandatory 步 vs 玩家窗**：G2 peril、G3 revelation、G4 spawn/discard 为 **框架强制步**（nest 结算）；玩家 **[reaction] When draw** 在 WHEN 窗内、**G3 nest 之前** initiate（Grimoire *When* p.24 示例）。G2 后 peril RESTRICTION 已生效 → 他人 **仍 cannot** play/trigger/commit（与 When 窗 **并存**）。

**Surge 链**：每一圈 **独立** ENCOUNTER_CARD_DRAWN + priority 队列；`EncounterResolutionFrame` 仅保留 drawer / surge_depth 等 **诊断**，**不** 承载 peril 粘性。

**peril 不跨 Surge（已裁决）**：G5 在 **上一张 G4 完成后**；该张 peril RESTRICTION 已在 priority **80 档结束** 时 Unregister → 下一张 G1 是 **全新** 抽取时点。

```text
[WOULD] …
G1 Draw → emit ENCOUNTER_CARD_DRAWN
  priority dequeue: 100 peril → 90 revelation → 80 spawn|discard（Unregister peril）
  → 75 AFTER(card)
  → 70 surge? → 下一张 G1 …
```

#### 17.3.2 FrameworkPriority 配置（占位）

```gdscript
# rules/config/encounter_draw_priority.gd — 设计师可调；默认对齐 Grimoire G2–G5
class EncounterDrawPriorityPolicy:
    const PERIL_KEYWORD := 100
    const PLAYER_WHEN_DRAW := 95
    const REVELATION_FORCED := 90
    const ENCOUNTER_TYPE_RESOLVE := 80
    const SURGE_KEYWORD := 70
    const AFTER_DRAW_EMIT := 75
```

**配置入口**：`RulesConfig.encounter_draw_priority`（与 `enter_hand_timing` 同型占位）。

### 17.3.1 Slot / 步骤 / 结构对照（模板）

译 flow：G1 commit → **ENCOUNTER_CARD_DRAWN** → **FrameworkPriority** 排序（§4.0.5.2、§17.3.2）。各档可 nest 结算入栈。

| 步骤 | Grimoire | Priority | 结算体 | 说明 |
|---|---|---|---|---|
| E1+E2 | **G1 Draw** | （开 timing） | L0 collect + reveal | emit ENCOUNTER_CARD_DRAWN |
| **E3** | **G2 Peril** | **100** | nest Register RESTRICTION | `WHILE_DRAWN_CARD_RESOLVING(card_id)` |
| — | When draw | **95** | 玩家 [reaction] | 可选 |
| **E4** | **G3 Revelation** | **90** | nest Forced | |
| **E5 G4** | **G4** | **80** | nest `seq.encounter.spawn` / 内联 treachery discard | enemy：**nest 生成**（无 Spawn→默认；有 Spawn→指令）；treachery：discard；**Unregister peril** |
| AFTER | — | **75** | emit AFTER(card) | G4 后、Surge 再抽前 |
| **E6** | **G5 Surge** | **70** | evaluate + 再抽 G1 | 新 ENCOUNTER_CARD_DRAWN |

**Hidden treachery**：G1 跳过 E2 公开 reveal → G3 nest revelation（Composition 内秘密 `commit_enter_hand`）→ G4 **跳过** 默认 discard。

**结构决策**：

| 逻辑段 | 选择 | 理由 |
|---|---|---|
| E1+E2 | G1 内联 | 魔典 step 1；E2 非独立 timing 边界 |
| E3/E4/E6 | priority nest 结算 | Register / Forced / Surge |
| E5 G4 | priority **80** handler | enemy：**nest `seq.encounter.spawn`**；treachery 内联 discard |
| `resolve_card_body` | orchestrator | dequeue `ENCOUNTER_CARD_DRAWN` 队列 |

### 17.4 Bricks 与 SequenceCatalog 映射

**原则**：`ENCOUNTER_CARD_DRAWN` + **FrameworkPriority**（§4.0.5.2）；`EncounterResolutionFrame` 跨 Surge 圈（仅 drawer 诊断）。

```text
seq.draw.encounter                 # RUN
  RESOLVE:
    push EncounterResolutionFrame(drawer_id)
    for i in amount:
      surge loop:
        collect_one_step (G1)
        emit ENCOUNTER_CARD_DRAWN → priority dequeue（G2–G5）
        if surge: continue
    pop frame → E7 AFTER

seq.encounter.spawn              # RUN · nest · priority 80 结算体（非第二 timing 锚）
  RESOLVE:
    spawn_from_encounter_draw(enemy_id, drawer_id)
    # 默认生成（无 Spawn 文本）→ spawn_engaged | spawn_at_location(Aloof)
    # 指令生成（Spawn –）→ resolve_spawn_location → spawn_at_location + optional auto_engage

seq.draw.encounter.resolve_bound   # RUN · weakness 重定向
  bind card_id → 同上 priority 队列（skip G1）

seq.encounter.revelation           # RUN · nest · priority 90 结算体（非第二 timing 锚）
```

> **架构说明**：`seq.encounter.spawn` **不是** 与 `seq.draw.encounter` **平行** 的 timing entry；**是** G4 priority 80 的 **nest 结算体**（同型于 `seq.encounter.revelation` @ 90）。~~`check_peril`~~ / ~~`dispatch`~~ 等 **独立 seq** 仍禁止 proliferate。

### 17.4.1 G4 Enemy：`spawn_engaged` vs 指令 `Spawn –`

Grimoire Framework 1.4 step 4 / *Spawning an Enemy*：**均在 `ENCOUNTER_CARD_DRAWN` · priority 80** 结算。`Spawn –` **指令** 只改 location 解析与是否 `auto_engage_at_location`；**默认生成**（无 Spawn 文本）走 `spawn_engaged`（非 Aloof）或 Aloof 落点。

| 条件 | 引擎路径 | Domain 结果 |
|---|---|---|
| 无 Spawn，非 Aloof | **`spawn_engaged(drawer)`** | `engaged_with = drawer`；threat area；location = drawer.location |
| 无 Spawn，**Aloof** | **`spawn_at_location`** | drawer.location；**unengaged**；不进 threat area |
| 有 Spawn 文本，非 Aloof | spawn_at_location → **`auto_engage_at_location`** | 同地点多人 → Lead / Prey（[08 §3](08-enemy-engagement.md)） |
| 有 Spawn 文本，Aloof | spawn_at_location only | unengaged at location |
| **无合法 spawn location** | **`discard_spawn_failed`** | **owner 对应 discard pile**；不 enter play（[08 §7.4](08-enemy-engagement.md)） |

```gdscript
func spawn_from_encounter_draw(enemy_id: StringName, drawer_id: StringName) -> void:
    var instruction := card.spawn_instruction(enemy_id)
    if instruction.is_empty():
        var loc := drawer_location(drawer_id)
        if loc == null:
            discard_spawn_failed(enemy_id)
            return
        if card.aloof(enemy_id):
            spawn_at_location(enemy_id, loc)
        else:
            spawn_engaged(enemy_id, drawer_id)   # 禁止调用 engage() / auto_engage
    else:
        var loc := resolve_spawn_location(instruction, drawer_id)
        if loc == null:
            discard_spawn_failed(enemy_id)
            return
        spawn_at_location(enemy_id, loc)
        if not card.aloof(enemy_id):
            auto_engage_at_location(enemy_id, loc)
```

**Invariant**：`spawn_engaged` **不得** nest `ActionSystem.engage` 或 `auto_engage_at_location` — drawer 已由规则唯一确定。

#### 17.4.1b 指令生成（Spawn –）vs 普通生成：译法（已裁决）

> **术语**：**普通生成** = Grimoire Framework 1.4 默认进场（无 `Spawn –` 文本）；**指令生成** = 牌面 **Spawn –** 段落（卡牌描述）。

| | **普通生成** | **指令生成** |
|---|---|---|
| **来源** | **规则流程**（Framework） | **卡牌描述**（printed Spawn） |
| **编译** | **无** 卡面字段；priority 80 handler 内固定分支 | 导入时编译 → **`SpawnInstructionSpec`**（非 Ability） |
| **运行时** | `EnemySystem.spawn_default_from_draw` | `composition.execute(spawn_composition)` 或 `spawn_with_spec` |
| **时点** | 同 **`ENCOUNTER_CARD_DRAWN` · priority 80** | **同左** — 指令 **不** 另订 timing hook |
| **Hook** | 无卡面 AbilityHook | **无独立** `(sequence_id, slot)` — 由框架 G4 **调用** 卡面编译体 |

**分工（已裁决）**：

```text
卡面 Spawn 文本  →  编译期解析（禁止运行时 match 原文）
  → SpawnLocationSelector（枚举/结构化 spec：your location / nearest empty / 具名 location …）
  → 可选 Composition 子树：ChoiceLocation · ResolveTargets

Framework G4（priority 80）→  固定后缀（规则流程，非卡面）
  → spawn_at_location(enemy, loc)
  → if not Aloof: auto_engage_at_location
  → if 无合法 loc: discard_spawn_failed
```

**与显现（Revelation）对照**：显现 = 完整 Forced **Composition**（priority 90）；Spawn 指令 = **受限卡面 spec**（主要是 **WHERE**）+ **Framework 标准后缀**（进场态 / engage / 失败 discard）。**不是** 把 Spawn 文本译成独立 `seq.*` timing entry。

**不是能力、不是 Buff（已裁决）**：

| 不是 | 理由 |
|---|---|
| **Card Ability** | 无 Forced/[reaction] Hook；不 Register；不进入 Initiation / Eligibility 订阅 |
| **MODIFIER** | 不改数值查询；仅 G4 内联分支读 **WHERE** |
| **RESTRICTION / LISTENER** | 不挂 RegistrationStore；不订独立 timing |
| **独立 seq.*** | 并入 `seq.draw.encounter` priority **80** handler |

**CardDefinition 形状（示意）**：

```gdscript
class SpawnInstructionSpec:   # 非 AbilitySpec
    var mode: SpawnMode   # FRAMEWORK_DEFAULT | INSTRUCTION
    var selector: SpawnLocationSelector   # 编译产物；非 raw string
    # composition: CompositionNode  # 仅 selector 需 Choice 时
```

**priority 80 handler 分支**：

```gdscript
func resolve_g4_enemy(enemy_id: StringName, drawer_id: StringName) -> void:
    var spec := CardRegistry.spawn_spec(card.definition_id)
    if spec.mode == SpawnMode.FRAMEWORK_DEFAULT:
        EnemySystem.spawn_default_from_draw(enemy_id, drawer_id)
    else:
        var loc := SpawnLocationResolver.resolve(spec.selector, drawer_id, game_ctx)
        if loc == null:
            EnemySystem.discard_spawn_failed(enemy_id)
            return
        EnemySystem.spawn_at_location(enemy_id, loc)
        if not card.aloof(enemy_id):
            EnemySystem.auto_engage_at_location(enemy_id, loc)
    unregister_peril_for_card(card_id)
```

**provenance**：指令路径 `AbilityUnitRef.from_card_instruction("seq.encounter.spawn", def_id, &"spawn")`；普通生成 `from_framework("seq.encounter.spawn")`（经 `seq.draw.encounter` G4 nest）。

**禁止**：运行时 `match spawn_text`；`SpawnPolicy`；`seq.encounter.spawn` 作为 **与 draw 平行的 timing entry**；Register / MODIFIER。

#### 17.4.1c 猎物指令（Prey –）：engage 内核读参（已裁决）

> **术语**：RR *enemy instructions* 含 Spawn 与 Prey；二者 **均为 ① 规则参数**（[07 §0.1.2](07-effect-primitives.md#012-敌人指令spawn-与-prey已裁决)）。**Prey 不执行任何效果** — **禁止** nest、LISTENER、Register、独立 timing。

| | **Spawn –** | **Prey –** |
|---|---|---|
| **提供** | **WHERE** | **WHO**（同地点 / 等距多选） |
| **Spec** | `SpawnInstructionSpec` | `PreyInstructionSpec` |
| **读参内核** | **②** spawn · G4 · `SpawnLocationResolver` | **②** `auto_engage_at_location`；**③** Hunter 等距 handler 内 `PreyResolver` |
| **进入 G4 spawn 分支？** | **是** | **否**（*no effect on spawn location*） |
| **nest？** | G4 **nest `seq.encounter.spawn`** | **禁止** |

```text
CardDefinition
  spawn_instruction: SpawnInstructionSpec | null
  prey_instruction:  PreyInstructionSpec  | null

② auto_engage_at_location（engage 内核 — 可因响应链 nest seq.engage.auto，但 Prey 仍只是 kernel 内 Resolver 调用）
  candidates := investigators_at(loc)
  target := PreyResolver.best_match(prey_instruction, candidates)   # 同步，不 nest Prey
  engage_l0(enemy, target)

③ choose_hunter_target 在 Hunter LISTENER handler 内
  equidistant := …
  PreyResolver.best_match(prey_instruction, equidistant)
```

**Keyword Prey 标签** → `PreyInstructionSpec`（**①**）；**不** 译 LISTENER。

**禁止**：`PreyPolicy`；Prey 独立 timing / nest；G4 handler 读 `prey_instruction`；把 Prey 当 Forced Register。

### 17.4.2 E5 Treachery 与非 Enemy 落点

Grimoire Framework 1.4 Step 4：**treachery → encounter discard pile**，除非能力另有指示。

| 分支 | 条件 | E5 行为 | 弃牌堆 |
|---|---|---|---|
| **默认 treachery** | E4 后 zone **非** hand | `discard_to_encounter_pile` | encounter discard |
| **留场 / threat** | Revelation 或 constant 将牌 put into play / threat | 按 Composition 已写入的 zone | — |
| **Hidden 已在 hand** | E4 秘密入手（§17.4.3） | **跳过** 默认 discard | — |
| **spawn 失败 enemy** | 无合法 location | `discard_spawn_failed` | **owner** 堆（08 §7.4） |
| **story asset** | CardDefinition | 默认 play area 或 scenario 脚本 | owner / encounter 视定义 |

```gdscript
func dispatch_treachery(card_id: StringName, drawer_id: StringName) -> void:
    if card.is_hidden and card.zone == Zone.HAND:
        return   # Hidden 已在手；E4 已处理
    if card.zone == Zone.IN_PLAY or card.in_threat_area:
        return   # 能力已留场
    mutator.discard_to_encounter_pile(card_id)
```

**Cancel treachery 效果**：Grimoire — 仍视为 **已 draw**；仍进 encounter discard（能力取消 **不** 取消「已抽」事实）。E5 在 cancel 解析完成后执行 discard，除非 cancel 文本明确改落点。

### 17.4.3 隐私（Hidden）关键词

**规则出处**：Grimoire p.14 · *Hidden*；Dream-Eaters 修订见 [`arkhamdb-rules-reference.md`](../reference/arkhamdb-rules-reference.md) · *Hidden*。

**中文裁定名**：**隐私**（英文卡牌关键词 **`Hidden`**）。`CardDefinition.keywords` / 代码仍用 `&"hidden"`；Domain 真值 `CardInstance.is_hidden`。

#### 规则译文（Grimoire + Dream-Eaters FAQ）

带 **隐私** 关键词的遭遇牌或弱点，具有 **显现（Revelation）能力**，将该牌 **秘密** 加入调查员手牌——**不得**向其他调查员公开该牌或其文本。

隐私牌在调查员 **手牌** 期间：

| 条目 | 规则 |
|---|---|
| **手牌上限** | 计入调查员最大手牌数 |
| **离手限制** | **除该卡牌面能力所述方式外，不能以任何方式离开手牌**（Grimoire：*cannot leave … except those described on the card*） |
| **弃置落点** | 进入 **遭遇弃牌堆** |
| **淘汰** | 调查员被淘汰时，手牌中的隐私遭遇牌 → 遭遇弃牌堆（FAQ 1.22，同威胁区遭遇牌） |

**手牌期间 · 按 cardtype 分支**（Dream-Eaters 修订；Grimoire 早期将 treachery 与 enemy 合并表述「视为威胁区」，引擎按下列拆分）：

| 卡类 | hand 期间语义 |
|---|---|
| **隐私 treachery** | **视为**威胁区（constant / triggered 可用）；**仅**控制者 |
| **隐私 enemy** | **不** engaged、**不**在 threat area、**不**攻击（除非卡面另说）；constant / triggered **仅**控制者 |

**显现与隐私**：隐私 **绑定于显现能力**——E4 通过 `commit_hidden_enter_hand` 秘密入手并设 `is_hidden=true`；**不是** spawn / discard 步骤的属性。后续若卡面 **暴露** 再 **生成**，须 composition 内 **显现先于生成**（`expose_hidden` → `spawn_encounter_enemy`）。

#### 遭遇抽牌管线差异（G1–G5）

| 步骤 | 与默认 encounter draw 的差异 |
|---|---|
| **E2** | **跳过** `reveal_encounter`（ALL）；他人保持 HIDDEN_ALL |
| **E3 Peril** | 照常 |
| **E4** | nest `seq.encounter.revelation` → `commit_hidden_enter_hand` + `is_hidden=true` + CONTROLLER |
| **G4** | **跳过 Framework 默认离手**（见下） |

#### 为何 G4 跳过自动生成 / 默认弃置

G4 对非隐私牌的 **默认路径** 会把牌 **离开 hand**：

- treachery → 默认 **discard**（进遭遇弃牌堆）
- enemy → 默认 **spawn**（进 play / 威胁区）

隐私牌的 **离手限制** 禁止 Framework 代劳上述操作，故：

```gdscript
# G4 · 隐私 treachery：已在 hand，禁止 Framework discard
if card.is_hidden and card.zone == Zone.HAND:
    return

# G4 · 隐私 enemy：禁止 Framework spawn（须卡面能力 expose + spawn）
if _hidden_enemy_skips_spawn(card, def_id):
    return
```

**仅**该卡牌面 composition 所描述的能力（如 `expose_hidden` + `spawn_encounter_enemy`、或卡面自定义 discard 文本）可将隐私牌合法离手。

```gdscript
func reveal_encounter_step(card_id: StringName, drawer_id: StringName) -> void:
    if CardRegistry.is_hidden(def_id):  # 隐私
        return
    executor.execute(DrawEncounterComposition.reveal_to_all(card_id))
```

#### 引擎映射

| 规则 | 引擎 |
|---|---|
| 秘密入手 | E4 · `commit_hidden_enter_hand` |
| **除卡面能力外不得离手** | E4 Register **`FORBID_LEAVE_HAND`** · `WHILE_HIDDEN_IN_HAND(card_id)`；`RestrictionEvaluator` @ `move_card` |
| 禁止 Framework 离手 | G4 skip discard / spawn（Framework 不发起非法 Intent；RESTRICTION 为规范真源） |
| `is_hidden` + Eligibility | constant / triggered 过滤；Presentation 牌名 |
| 卡面暴露 + 生成 | `expose_hidden` → `spawn_encounter_enemy` → unregister → nest `seq.encounter.spawn` |
| hand → LIMBO（spawn 前） | `prepare_hand_card_for_encounter_spawn`（**仅**域转换，不含显现） |

**测试**：ENC-12 / ENC-22（秘密入手 + RESTRICTION）；ENC-24（`move_card` 拦截）；ENC-23（卡面 expose → spawn → unregister）。

### 17.4.4 Surge 与 Then / AFTER 边界（规范）

```text
单张牌生命周期（对齐 G1–G5）:
  [WOULD]
  G1 Draw（E1+E2）→ open WHEN
  nest G2 peril
  （When draw [reaction] — 可选，G3 前）
  nest G3 revelation
  G4 spawn | discard
  close WHEN
  emit AFTER(card)
  nest G5 surge? → 下一圈 G1

效果文本: 「Draw encounter. Then, X」
  → G4 完成 → Then X → 然后 AFTER(card)（Grimoire Then 优先）
```

Surge **不**合并多张牌的 AFTER；每张 **独立** AFTER，均在 **G5 再抽 G1 之前**。

**Timing emit（目标，待 TimingCatalog）**：

```text
  WOULD  — E0 意图后、G1 pop 前
  WHEN   — open after G1（E1+E2）；close after G4（E5）
  AFTER  — per card, after G4, before G5 next G1
  OUTER AFTER — on seq.draw.encounter pop (E7)
```

**与调查员 draw 子 flow 对照**：

| 调查员 | 遭遇 |
|---|---|
| D1 内联 `collect_one_step` | E1 内联 `collect_one_step` |
| D2–E3 内联 | E2–E3 内联 |
| nest 显现（入手/抽牌触发） | ENCOUNTER_CARD_DRAWN + priority（peril/revelation/surge） |
| `nest empty_piles_defeated` | （无）两堆空 → RULES_GAP |

### 17.5 EncounterResolutionFrame

```gdscript
class EncounterResolutionFrame:
    var drawer_id: StringName
    var cards_resolved: Array[StringName]
    var surge_depth: int = 0             # 诊断；peril 见 RegistrationStore per card_id

# RulesMemory referents（frame 级，key = drawer_id 或 frame_id）
const ENCOUNTER_PENDING := &"encounter_pending"
const ENCOUNTER_SHUFFLES := &"encounter_shuffles"
```

**Peril** = priority **100** Register · **`WHILE_DRAWN_CARD_RESOLVING(card_id)`**；G4 完 Unregister；**不跨 Surge**。

**嵌套检定**：revelation 内 skill test 走 `seq.skill_test.*` nest；ST.8 后入队仍属 **同一 frame**（OQ-04-02 已裁决）。

### 17.6 Weakness 与跨管线重定向

> **Grimoire**：*Weaknesses are resolved differently depending upon their **cardtype**.*  
> **Encounter cardtype**（enemy / treachery weakness）≈ 遭遇抽牌；**Player cardtype**（asset / event / skill weakness）≈ 调查员抽牌 + 入手。

#### 17.6.1 路由判定（引擎）

**第一键 = `CardDefinition.cardtype`**，**第二键 = `is_weakness` 子类型**；**不**用 weakness 子类型 alone 推断管线。

```gdscript
enum WeaknessRoute { INVESTIGATOR_DRAW, ENCOUNTER_DRAW, AS_IF_ENCOUNTER }

func weakness_route(def: CardDefinition) -> WeaknessRoute:
    if not def.is_weakness:
        return INVESTIGATOR_DRAW   # 非 weakness；普通玩家牌
    match def.cardtype:
        AhcEnums.CardType.ENEMY, AhcEnums.CardType.TREACHERY:
            return ENCOUNTER_DRAW
        AhcEnums.CardType.ASSET, AhcEnums.CardType.EVENT, AhcEnums.CardType.SKILL:
            return INVESTIGATOR_DRAW
        _:
            return INVESTIGATOR_DRAW   # 其它 player 印刷类型；默认调查员线
```

| cardtype | 典型印刷 | 管线 | 牌面 reveal（从 deck 抽） |
|---|---|---|---|
| **ENEMY** weakness | 弱点敌人 | `resolve_bound` → E2–E6 | E2 **ALL**（遭遇规则） |
| **TREACHERY** weakness | 弱点诡计 | 同上 | E2 ALL 或 Hidden 分支 |
| **ASSET** weakness | 诅咒资产、故事弱点资产 | D2–D3 + `seq.enter_hand` | D2 **CONTROLLER** |
| **EVENT** weakness | 事件型弱点 | D2–D3 + `seq.enter_hand` | D2 CONTROLLER |
| **SKILL** weakness | 技能型弱点 | D2–D3 + `seq.enter_hand` | D2 CONTROLLER |

**Player cardtype weakness** 入手后按 **该 cardtype** 正常打牌（Grimoire：*used as any other player card of its cardtype*）；**不**进 encounter discard（除非 defeat 等另定规则）。

#### 17.6.2 来源与入口

| 来源 | 路由 |
|---|---|
| Mythos 1.4 / 效果「draw encounter」 | 正常 `seq.draw.encounter` |
| 调查员 deck **D1 pop** + **encounter cardtype** weakness | **重定向** `resolve_bound`；skip E1；abort 调查员 D2 |
| 调查员 deck **D1 pop** + **player cardtype** weakness | **不**重定向；完整 D2–D3 + `seq.enter_hand`（若有 Revelation） |
| Weakness **非 draw** 入手（search/add 等） | player 型：`seq.enter_hand` / as-if-drawn 调查员线；encounter 型：`resolve_bound`（Grimoire as if drawn from encounter deck） |
| Setup mulligan 抽到 weakness | set aside redraw；**不** resolve（[11 §6](11-investigator-campaign.md)） |

```text
seq.draw.investigator RESOLVE (D1 collect_one_step):
  card_id := pop_deck_top(...)
  match weakness_route(card.definition):
    ENCOUNTER_DRAW:
      nest seq.draw.encounter.resolve_bound
        { drawer_id: inv_id, card_id, skip_collect: true }
      return   # 本张 **不** 进入 draw_pending / D2 reveal_batch
    INVESTIGATOR_DRAW:
      append draw_pending; continue  # 含 asset/event/skill weakness
```

`resolve_bound` → **`resolve_card_body`**（§17.4）；与主循环 **同一** E2–E6 实现。

#### 17.6.3 Owner 与弃牌堆（spawn 失败 / defeat）

| Weakness cardtype | `owner_id` | spawn 失败 discard | defeat 默认 |
|---|---|---|---|
| Encounter 型 | **bearer** 调查员 | bearer **discard**（08 §7.4） | owner discard 或 encounter discard 视 defeat 规则 |
| Player 型 | bearer | 不适用（无 spawn） | owner discard |

---

### 17.7 与 ScenarioSystem / Framework 的边界

| 调用方 | 入口 |
|---|---|
| Mythos 1.4（每位调查员） | `ScenarioSystem.resolve_encounter_draw(inv)` → `catalog.run(seq.draw.encounter, {drawer_id, amount: 1})` |
| 卡牌效果「draw N encounter cards」 | 同上，`amount = N` |
| Setup 14 game begins | 仅结算 **deferred** 显现；Setup 1–13 **不**进入本管线（OQ-10-01） |
| Act/Agenda b 面 encounter | 按 encounter cardtype 规则；可 nest 同一 `seq.encounter.*` 子 flow |

`ScenarioSystem` **不** proliferate 逐步逻辑；只做 framework 步进与 `catalog.run` 委托（对齐 [10 §2](10-scenario-encounter.md)）。

### 17.8 DrawEncounterComposition（L0 / L1）

与 [§16.4 `DrawInvestigatorComposition`](15-timing-entry-catalog.md) 对称；**不** proliferate Service。

| Brick | 层级 | 说明 |
|---|---|---|
| `pop_encounter_deck_top` | L0 | deck → limbo/pending；append `encounter_pending` |
| `shuffle_encounter_discard_into_deck` | L0 | 遭遇弃牌堆洗回牌库 |
| `shuffle_encounter_discard` | L1 Seq | 仅洗弃，**无** horror marker |
| `reveal_to_all` | L0 **AtomRevealCard** | `FaceAudience.ALL` |
| `discard_to_encounter_pile` | L0 | treachery 默认 E5 |
| `discard_spawn_failed` | L0 | owner 路由（委托 08 §7.4） |

```gdscript
class_name DrawEncounterComposition
extends RefCounted

const PENDING_KEY := &"encounter_pending"
const SHUFFLES_KEY := &"encounter_shuffles"
const RESOLVED_KEY := &"encounter_cards_resolved"

static func shuffle_encounter_discard() -> CompositionNode:
    return CompositionNode.shuffle_encounter_discard_into_deck()

static func reveal_to_all(card_id: StringName) -> CompositionNode:
    return CompositionNode.reveal_to_all(card_id)   # 待增 L0 factory

static func discard_treachery_default(card_id: StringName) -> CompositionNode:
    return CompositionNode.move_card(card_id, CardSlot.encounter_discard_top())
```

**RulesMemory**（frame 作用域，key 建议 `frame_id` 或 `drawer_id + frame_generation`）：

| Referent | 用途 |
|---|---|
| `encounter_pending` | 当前 E2–E6 处理的 `card_id` |
| `encounter_shuffles` | 本 frame 内洗弃次数 |
| `encounter_cards_resolved` | 已完成 E5 的 card_id 列表（含 Surge 链） |
| `encounter_frame_id` | 栈顶 frame 关联 |

### 17.9 DrawEncounterFlow 与 Facade

```gdscript
class_name DrawEncounterFlow
extends RefCounted

## E1 内联 collect + resolve_card_body（E2/E3 内联；仅 revelation/spawn nest）

static func run(game_ctx: GameContext, drawer_id: StringName, amount: int) -> Dictionary

static func resolve_card_body(
	game_ctx: GameContext,
	drawer_id: StringName,
	card_id: StringName,
	catalog: SequenceCatalog
) -> Dictionary

class_name DrawEncounterSubflowHandlers
extends RefCounted

## E1 内联 collect（对标 DrawSubflowHandlers.collect_one_step）。

static func collect_one_step(
	game_ctx: GameContext,
	drawer_id: StringName,
	catalog: SequenceCatalog = null
) -> Dictionary

class_name DrawEncounterService
extends RefCounted
## 薄 facade → catalog.run(&"seq.draw.encounter", …)

func draw_encounter_cards(
    game_ctx: GameContext,
    drawer_id: StringName,
    amount: int,
    source_tags: Array[StringName] = []
) -> Dictionary
```

**返回形状**（与调查员 draw 对齐，便于测试 harness）：

```gdscript
{
    "ok": true,
    "drawn": Array[StringName],      # 本 run 全部 resolved card（含 Surge）
    "drew": bool,
    "shuffled": bool,
    "shuffles": int,
    "surge_depth_max": int,
    "peril_card_ids": Array[StringName],  # 本 run 曾带 peril 的 card_id（诊断）
    "spawn_failed_discards": Array[StringName],
    "revelations": Array[StringName], # 有 encounter revelation 的 card_id
}
```

`DrawEncounterSubflowHandlers.collect_one_step` / `DrawEncounterFlow.resolve_card_body` — 对标调查员 D1 内联 + D2–D3 编排。

### 17.10 TriggeringCondition 与 ApplicationContext tags

```gdscript
static func draw_encounter(
	drawer_id: StringName,
	amount: int,
	source_tags: Array[StringName] = [],
	after_timing: StringName = &"after_draw_encounter"
) -> TriggeringCondition
# kind = &"draw_encounter"; controller_id = drawer_id; payload = {amount}

static func encounter_revelation(
    drawer_id: StringName,
    card_id: StringName
) -> TriggeringCondition
# kind = &"encounter_revelation"; nest 于 E4

static func draw_encounter_resolve_bound(
    drawer_id: StringName,
    card_id: StringName
) -> TriggeringCondition
# weakness 重定向；tags 含 &"weakness_encounter"
```

**ApplicationContext.tags**（frame 注入，供 Peril / Eligibility）：

| Tag | 何时 |
|---|---|
| `draw_encounter` | 整个 `seq.draw.encounter` frame |
| `peril_active` | 当前 resolving card_id 在 Store 中有 peril RESTRICTION |
| `encounter_drawer:{id}` | drawer 身份 |
| `surge_chain` | Surge 循环内（可选，诊断） |

### 17.11 空库洗弃与 mid-ability shuffle（OQ-10-04）

| 场景 | v0 政策 |
|---|---|
| **E1 collect_one_step**，牌库空、弃牌堆非空 | **立即** `shuffle_encounter_discard` 再 pop（Framework 1.4 常规 draw） |
| **Revelation / 嵌套效果**执行中牌库抽空 | Grimoire：该 **效果完全 resolve 后** 再 shuffle；frame 设 `deferred_encounter_shuffle`，当前 Composition 子树 **不** 中断 |
| 两堆皆空 | **RULES_GAP**（OQ-ENC-01） |

```text
collect_one_step:  empty deck → shuffle now → pop
nested effect:   empty deck → flag defer → on subtree pop → shuffle → 若效果还需 draw 则再 collect
```

### 17.12 CardAbilityService：遭遇 vs 玩家显现

| 方法 | 用于 | flow_id | finalize |
|---|---|---|---|
| `resolve_revelations` | **玩家牌** `seq.enter_hand` | `seq.enter_hand` / draw provenance | `finalize_limbo_discard` → hand |
| `resolve_encounter_revelations` | **E4** 遭遇显现 | `seq.encounter.revelation` | **不** 走 enter_hand；按 Composition 落点 |

```gdscript
func resolve_encounter_revelations(
    game_ctx: GameContext,
    drawer_id: StringName,
    card_id: StringName,
    flow_id: StringName = &"seq.encounter.revelation"
) -> bool:
    # 同 resolve_revelations 结构；register 用 revelation_units_at
    # Forced tier；encounter 先于 player（06 §8 / Grimoire Priority）
    # 不调用 finalize_limbo_discard 除非 builder 显式 enter_hand（Hidden）
```

**禁止** E4 调用 `seq.enter_hand` nest — 订阅键 `(seq.enter_hand, slot)` 与遭遇 draw WHEN 窗口 **不同**。

### 17.13 实现状态与竖切顺序

| 已有（可复用） | 待建 |
|---|---|
| `EncounterResolutionFrame`（`core/timing/encounter_resolution_frame.gd`） | `DrawEncounterFlow` + `DrawEncounterComposition` |
| `ResolutionSequenceStack` nest / run | L0：`pop_encounter_deck_top`、`reveal_to_all`、`shuffle_encounter_discard` |
| `DrawInvestigatorFlow` / `DrawSubflowHandlers` **内联/nest 样板** | `DrawEncounterSubflowHandlers.collect_one_step` |
| `CardAbilityService.resolve_revelations` | `resolve_encounter_revelations` |
| `DrawInvestigatorService` facade | `DrawEncounterService` + Catalog 登记（§17.4） |
| `ScenarioSystem.resolve_encounter_draw`（**仅 log**） | Mythos 1.4 → `catalog.run` |
| `FrameworkFlowEngine` Mythos 1.4 | `EncounterPeril.apply_e3_check`（内联）、spawn nest |

**推荐竖切（实现顺序）**：

```text
P-ENC-1  L0 + DrawEncounterComposition + collect_one_step（内联 E1）
P-ENC-2  EncounterDrawPriorityPolicy + peril Register（WHILE_DRAWN_CARD_RESOLVING）
P-ENC-3  seq.draw.encounter RUN + DrawEncounterService + ScenarioSystem 接线
P-ENC-4  revelation nest + priority 80 spawn（默认/指令分支）
P-ENC-5  Surge priority 70 + peril 不跨 Surge 断言（PERIL-04/05）
P-ENC-6  resolve_bound（weakness 重定向）+ 11 §10 路由
P-ENC-7  ENC-01～07 测试 + Mythos 1.4 框架集成测试
```

| 测试 ID | 断言 |
|---|---|
| ENC-01 | E1 pop + shuffle（无 horror） |
| ENC-02 | E2 ALL reveal；Hidden 跳过 |
| ENC-03 | E5 treachery → encounter discard |
| ENC-04 | peril priority 100 Register；G4 后 Unregister；Surge 下一张 **无** 上一张 peril |
| ENC-05 | E4 走 `seq.encounter.revelation`，**非** enter_hand |
| ENC-06 | Surge 同 frame 第二圈 E1 |
| ENC-07 | Mythos 1.4 框架步 → catalog.run |

---

## 18. Timing Entry Catalog 索引表（TBD）

> **原则**：先定 **§16 等流程明细** 与 Domain brick；catalog 表在流程稳定后 **反推登记**，不在此过早填全。

**已实现 SequenceCatalog 条目（v0.3 部分索引）**：

| flow_id | kind | 说明 |
|---|---|---|
| `seq.draw.investigator` | RUN | 调查员抽 N 张；D1 内联 collect；`nest_batch seq.enter_hand` |
| `seq.draw.empty_piles_defeated` | RUN（因果 nest） | 两堆皆空 → ELIMINATED |
| `seq.enter_hand` | NEST_BATCH | 入手 timing + Revelation Composition（全来源共用） |
| `seq.gain_resource` | RUN | 资源 gain + modifier |

占位：move / fight / skill_test 的 `(sequence_id, slot)` 将在流程评审通过后写入。

**已设计 / 待实现 SequenceCatalog 条目（v0.4 部分索引）**：

| flow_id | kind | 说明 |
|---|---|---|
| `seq.draw.investigator` | RUN | 调查员抽 N 张；D1 内联 collect；`nest_batch seq.enter_hand` |
| `seq.draw.empty_piles_defeated` | RUN（因果 nest） | 两堆皆空 → ELIMINATED |
| `seq.enter_hand` | NEST_BATCH | 入手 timing + Revelation Composition（**玩家牌**） |
| `seq.gain_resource` | RUN | 资源 gain + modifier |
| `seq.draw.encounter` | RUN | 遭遇抽 N；E1 内联；Surge 同 frame |
| `seq.draw.encounter.resolve_bound` | RUN（重定向） | weakness → `resolve_card_body` |
| `seq.encounter.revelation` | RUN（nest） | priority **90** 结算体（`ENCOUNTER_CARD_DRAWN`） |
| `seq.encounter.spawn` | RUN（nest） | priority **80** 敌人生成结算体（`ENCOUNTER_CARD_DRAWN`）；默认/指令共用 |

---

## 19. 测试建议

| ID | 场景 |
|---|---|
| VIS-01 | D2 reveal 后控制者可见、牌仍在 deck |
| VIS-02 | 抽牌后仅控制者 `face_known_to` |
| TIM-01 | draw：WOULD 在 D2 前；WHEN 窗口覆盖 D2–D3 |
| TIM-02 | draw：D2 后 REVEALED；D3 前 zone 可仍 deck/limbo |
| TIM-03 | 有 Revelation 的玩家牌：nest 在 ENTER_HAND（D3），非 draw AFTER 之后 |
| TIM-04 | draw AFTER 在 D3 内各 Revelation nest pop 之后 |
| TIM-05 | move：单 brick；无 leave/enter 双 entry |
| TIM-06 | fight 默认：仅一次 AFTER（merge） |
| TIM-07 | 能力触发 **不** 断言 zone，只断言 entry + slot + information level |
| ENC-01 | 遭遇空库洗弃；**无** horror |
| ENC-02 | Surge：第二圈在 **同一 frame** 内 E1，外层不 pop |
| ENC-03 | AFTER 在本张 E5 后、Surge 下一 E1 前 |
| ENC-04 | peril per card_id；G4 后 Unregister；Surge 下一张无上一张 peril |
| ENC-05 | 遭遇 revelation 走 `seq.encounter.revelation`，**非** `seq.enter_hand` |
| ENC-21 | 遭遇 enemy 走 `seq.encounter.spawn` nest（`phase_trace` 含 `encounter_spawn`） |
| ENC-22 | 隐私 enemy 秘密入手；**不** nest spawn（Framework 离手禁止） |
| ENC-23 | 隐私 enemy：卡面 `expose_hidden` → `spawn_encounter_enemy` → unregister |
| ENC-24 | 隐私牌 Register `FORBID_LEAVE_HAND`；`move_card` 离手被拦 |
| ENC-06 | E2 默认 ALL；Hidden 不公开 |
| ENC-07 | encounter cardtype weakness 从 inv deck 重定向 resolve_bound |
| ENC-08 | 无 Spawn enemy draw | `spawn_engaged`；不调用 auto engage / Engage action |
| ENC-09 | 有 Spawn + 非 Aloof | spawn_at_location 后 `auto_engage_at_location` |
| ENC-10 | Aloof encounter draw（无 Spawn） | unengaged at drawer location；不进 threat area |
| ENC-11 | Spawn 目标 location 未进场 | `discard_spawn_failed` → encounter discard |
| ENC-12 | Weakness enemy spawn 失败 | → bearer **investigator discard** |
| ENC-13 | Hidden treachery | E2 不 ALL；E4 秘密 hand；E5 不 discard |
| ENC-14 | Cancel treachery 效果 | 仍 encounter discard；仍算 drawn |
| ENC-15 | `resolve_bound` vs 主 draw | 同一 `resolve_card_body` |
| WKN-01 | Asset weakness + Revelation | 调查员 D3 `enter_hand`；非 encounter 管线 |
| WKN-02 | Event weakness 无 Revelation | D3 hand only |
| WKN-03 | Enemy weakness from inv deck | `resolve_bound` / E5 spawn |
| WKN-04 | Skill weakness | D3 hand；player cardtype 规则 |

---

## 20. Open Questions（引擎政策）

| ID | 问题 | v0 默认 |
|---|---|---|
| OQ-TIMING-01 | When you draw 锚点 | **D2–D3 区间**（§16.3） |
| OQ-TIMING-02 | Move leave/enter | **MOVE_ATOMIC**，单 entry |
| OQ-TIMING-03 | Draw would/when | **SPLIT**；WOULD=D1 后 D2 前；WHEN=D2–D3 |
| OQ-TIMING-04 | 玩家牌 **Revelation 能力** 于入手时 nest 时点 | **ENTER_HAND（D3）**；`seq.enter_hand` + `TriggeringCondition.enter_hand`；**按能力判定**，非 weakness 卡类型 |
| OQ-TIMING-05 | `enter_hand` 时点多张牌 / 多条显现的 **同类内** 顺序 | **待定**；属 FORCED **类内** 自排；`EnterHandTimingPolicy`，默认 `SOURCE_ORDER`。跨类见 06 §8.1。 |
| OQ-TIMING-06 | 遭遇 draw WHEN 区间 | **E2–E5**（§17.3）；Surge 每圈独立 WHEN |
| OQ-TIMING-07 | 遭遇 draw WOULD 锚点 | **E1 bind 后、E2 前**（§17.3） |
| OQ-TIMING-08 | `amount > 1` encounter draw | **顺序** full resolve（含 Surge 链）再下一张；非 batch reveal |
| OQ-ENC-01 | 遭遇 deck + discard **皆空** | v0：**RULES_GAP**；非正常 scenario 状态 |
| OQ-ENC-02 | drawer 无 location 时 `spawn_engaged` | v0：**`discard_spawn_failed`**（同 spawn 失败，[08 §7.4](08-enemy-engagement.md)） |
| OQ-10-04 | Encounter deck shuffle mid-ability | v0：**collect 立即洗**；嵌套效果内抽空 → **defer 至子树 pop 后**（§17.11）。 |

---

## 21. 实现映射（当前 / 待建）

| 已有 | 待建 |
|---|---|
| `CardFaceVisibility`、`StateMutator` L0 原子 | `TimingCatalog` |
| `CompositionExecutor` + `DrawInvestigatorComposition` | WOULD/WHEN emit（draw WHEN 区间） |
| `SequenceCatalog` + `SequenceCatalogBootstrap`（draw 子 flow、`seq.enter_hand`、`seq.gain_resource`） | **`seq.draw.encounter` 全家桶**（§17.4） |
| `ResolutionSequenceStack` push/pop/nest + `SequenceCatalog.nest` / `nest_batch` | `EncounterResolutionFrame` |
| `DrawInvestigatorService` / `ResourceGainService` 薄 facade → `catalog.run` | `DrawEncounterFlow` / `DrawEncounterComposition` |
| `CardAbilityService` + `CardRegistry.register_revelation` | `resolve_encounter_revelations`（或复用 + flow_id 分支） |
| `EnterHandTimingPolicy`（显现顺序占位，默认 SOURCE_ORDER） | L0 遭遇 pop/shuffle；`ScenarioSystem.resolve_encounter_draw` |
| | §18 完整 Timing 索引表 |
| | ENC-01～15 测试 |

---

## 22. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿：RuleSequence、三槽、Anchor Policy、Brick、merge、PreImpact |
| 2026-05-25 | v0.2 | **§16 调查员抽牌**：D0–D5；D2 牌面 CONTROLLER；WHEN=D2–D3；Revelation=D3 入手 |
| 2026-05-25 | v0.2.1 | §16.1 对齐 [01 §3.6](01-game-state-zones.md) FaceAudience 三档 |
| 2026-05-25 | v0.2.2 | Catalog §8–9、§17 标 TBD；Domain D2/D3 竖切 |
| 2026-06-18 | v0.3 | **§16.4** SequenceCatalog 映射（collect_one / empty_piles / enter_hand）；显现统一 `seq.enter_hand`；§16.6/§20 对齐代码 |
| 2026-06-18 | v0.3.1 | **§16.4.1** 显现顺序 `EnterHandTimingPolicy` 占位；OQ-TIMING-05 |
| 2026-06-18 | v0.4 | **§17 遭遇抽牌**：E0–E7；`seq.encounter.revelation`；Surge 同帧；weakness 重定向；ENC-01～07 |
| 2026-06-18 | v0.4.2 | D1 collect **内联**；移除 `seq.draw.collect_one` |
| 2026-06-18 | v0.4.2 | spawn 失败 **`discard_spawn_failed`**（owner 弃牌堆）；ENC-11～12；OQ-ENC-02 |
| 2026-06-18 | v0.5.2 | §4.0.5 **上一步触发时点**；E3 peril 内联；仅 revelation/spawn nest |
| 2026-06-18 | v0.5 | **§17.4** `resolve_card` 共享子 flow；§17.4.2–4 Treachery/Hidden/Surge；§17.8–12 Composition/Flow/Trigger/shuffle/CardAbility；ENC-13～15；OQ-10-04 |
| 2026-06-18 | v0.6 | **§4** 砖块 G0–G3；**③ AtomRevealCard**（Grimoire Reveal）；小序列 = 砖块拼成 |
| 2026-06-18 | v0.5.1 | **§17.6.1–3** Weakness 全 cardtype 路由（asset/event/skill vs enemy/treachery）；WKN-01～04；对齐 [11 §10](11-investigator-campaign.md) |
| 2026-06-18 | v0.6.1 | **§17.4.1c** Prey **engage 内核**读参；禁止 nest/LISTENER；对齐 [07 §0.1.2](07-effect-primitives.md) |
