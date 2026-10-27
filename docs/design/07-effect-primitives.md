# 07a — 效果原子与地址模型 (Effect Primitives)

> **依赖**：[01-game-state-zones.md](01-game-state-zones.md)  
> **被依赖**：[07-effect-resolution.md](07-effect-resolution.md)（组合执行、语义包装）、[12-card-script-api.md](12-card-script-api.md)（`CardDefinition` · §0.1 三档译法）  
> **状态**：v0.3.28 · 2026-10-24 — Register 只写 Buff；Gain 衍生行为 / 能力挂载

---

## 0. 术语：效果 · 原语 · 两层结算（已裁决 2026-10-24）

### 0.0 什么是「原语」（总判据）

> **原语 = 能对游戏造成影响的结算。** 关键是 **结算**——执行时 **必须做点什么**，dry-run 可标 **CREATED**。  
> **不是原语**：只读查询、投影、缓存、Eligibility 前段、场合信封、印刷 Spec、步间 `RulesMemory`、**仅改可见性**——**不结算**。

#### 为何 Register 必须是原语（发起有效性）

> **已裁决**：发起有效性与原语结算同一尺子——**必须干了点什么**（[07-composition §4](07-composition.md)）。

```text
可发起  ⟺  …成本等过门…
        AND  dry-run(效果体).has_any_CREATED

CREATED ∈ {
  物理原语结算成功,
  Register 插入 Registration（创建了 Buff/标记）成功,
  Chronicle 记事写入成功,   # 薄
  Interrupt/Replace 等成功
}

空结算 = 没有任何物理原语能结算
       ∧ 没有任何 Register 创建 Buff
       ∧ （亦无 Chronicle 等其它 CREATED）
     → FIZZLE → **禁止发起**
```

只改 `FaceAudience`、只跑控制流、只读查询 → **不够**。  
把 Register 留在原语外，会导致「纯挂 lasting / cannot / 延时」的合法效果体被判空结算——故 **Register 必须是信息原语结算叶**。

**空效果体（锚 09125）**：打出无正文时效果体编译 **`EmptySettle`**（框架完备，非 FAQ 门特例）。L7/发起认 CREATED；不写入局面。见 [07-composition §4.1.2](07-composition.md)。

结算两层 + 权限层（非结算）：

| 层 | 是结算？ | 计入发起 CREATED？ |
|---|---|---|
| **物理原语** | **是** | **是** |
| **Register**（主量信息原语） | **是** | **是**（插入即 CREATED；不查 Buff 日后是否开火） |
| **Chronicle**（日志∪记住） | **是**（薄） | **是** |
| **可见性 Audience** | **否** | **否** |

```text
命名流程 seq.*
  └─ RESOLVE ↓ 结算叶（可 CREATED）

  ├─ 物理     ①区/序  ②标记  ③形态
  └─ 不可见   ≈ Register（主量）+ Chronicle（薄）

并行（非结算 · 不计 CREATED）：FaceAudience
```

**控制权**不单立原语：经 Register Buff。Forced/reaction 是 **能力**，不是 Buff（[06 §2.3](06-registration-buff-model.md)）。

**揭示（纸面 Reveal）vs 翻面 vs 可见性**：

| | **纸面 Reveal 手续** | **Flip** | **FaceAudience** |
|---|---|---|---|
| 是什么 | 命名流程/卡面步（常伴翻面或入手） | 状态原语 ③ | 权限写入 |
| 结算？ | 手续里的 **其它**结算才 CREATED | **是** | **否**（政策同步） |

**地点「揭示」**：物理翻面 + 线索等组合；可见性若变，仍是政策，不是地点旗原语。

### 0.1 规则参数字段（RuleParameter · 信息型卡面描述）

> **Grimoire / RR 对照**：敌人段落 *enemy instructions (spawn and prey)*；Patrol 括号内 *designated target*（p.18）。  
> **详细译法**：Spawn → [15 §17.4.1b](15-timing-entry-catalog.md)；Prey → §0.1.2 / [08 §3–§4](08-enemy-engagement.md)；Patrol → §0.1.3。

卡面上有一部分文本 **不向 `Composition.execute` 提交效果**，也 **不** 作为 Card Ability 进入 Initiation / timing entry；导入时编译为 **`CardDefinition` 上的只读 Spec**，由 **`Resolver` 在规则内核内同步查询**，为**已在进行中的** mandatory 流程 **提供 WHERE / WHO / 目标** 等参数。

**三档译法（已裁决）** — 译卡时先定档；**Prey 等纯参数禁止 nest / LISTENER**：

```text
① 规则参数（RuleParameter）  Spec + Resolver；不执行效果；不 nest、不 Register
② 规则砖块（Rule kernel）     mandatory seq.* 步（spawn 内核、auto engage、treachery discard…）
③ 编译订阅（Compiled）        keyword → REGISTER / LISTENER @ TimingCatalog slot
```

| 档 | Prey | Spawn – | 险境 | Hunter 移动 |
|---|---|---|---|---|
| 归属 | **①** | **①**（在 **②** spawn 内核读） | **③** RESTRICTION | **③** LISTENER @ 3.2 |
| nest？ | **否** | **②** G4 砖块 | nest Register | nest RESOLVE 移动 |
| 执行效果？ | **否** | L0 进场在 **②** | RESTRICTION 查询 | L0 move 在 **③** |

```text
卡面信息（边界）
  ├─ 效果（§0 上表）           → L0 Atom / Register / Composition
  ├─ Card Ability（06 §2）     → timing entry + Initiation + 效果树
  ├─ 规则参数（§0.1 · ①）      → CardDefinition.*Spec；Resolver 内联读
  ├─ 规则砖块（§0.1 · ②）      → seq.* mandatory 步；可读 ① 的 Spec
  ├─ 编译订阅（§0.1 · ③）      → AbilityCompiler → Register / LISTENER
  └─ 静态印刷 / 构筑元数据      → cost、traits、slots…
```

#### 0.1.1 与相邻概念的分界

| 概念 | 是否规则参数 | 引擎译法 | 典型例子 |
|---|---|---|---|
| **规则参数（①）** | **是** | `*Spec` + `*Resolver` **同步读**；**不 nest** | Spawn –、Prey (…)、Patrol 括号 |
| **规则砖块（②）** | — | mandatory `seq.*` 内核 | G4 spawn、auto engage、treachery discard |
| **编译订阅（③）** | 否 | REGISTER / LISTENER @ catalog | 险境、涌动、Hunter/Patrol **移动** |
| **Card Ability** | 否 | `AbilitySpec` + timing / seq | Forced、Revelation、`[reaction]` |
| **印刷数值 / 特征** | 否 | `CardDefinition` 标量 / `traits` | cost、health、Victory X、🧑 乘数 |

**判据（① 纯参数）**：只改 **已在进行的** mandatory 流程里的 **选点 / 选人**，**本身不执行任何效果**、**无独立 timing** → `*Spec` + Resolver；**禁止** nest、LISTENER、Register。  
**判据（③）**：关键词 **自身触发** 可结算行为（移动、再抽、Register RESTRICTION）→ AbilityCompiler 模板 + catalog slot；括号参数（Patrol）仍在 handler **内** 调 Resolver（**①**）。

#### 0.1.2 敌人指令：Spawn 与 Prey（已裁决）

RR *enemy instructions (spawn and prey)* — 引擎 **均为 ① 规则参数**；**消费内核不同**。

| | **Spawn –** | **Prey –** |
|---|---|---|
| **提供** | **WHERE** | **WHO**（同地点 / 等距多选时） |
| **Spec** | `SpawnInstructionSpec` | `PreyInstructionSpec` |
| **读参内核（②）** | **Spawn 内核** · G4 / enters play · `SpawnLocationResolver` | **Engage 内核** · `auto_engage_at_location` · Hunter **等距**分支 · `PreyResolver` |
| **执行效果？** | 否（参数）；L0 进场在 spawn 砖块 | **否** — 仅排序/过滤候选 |
| **nest Prey/Spawn？** | G4 **规则砖块** nest（非 Spec nest） | **禁止** — 无独立结算体 |
| **魔典** | *spawn instruction resolves as enemy enters play* | *Prey has no immediate effect on spawn location* |

```gdscript
class CardDefinition:
    var spawn_instruction: SpawnInstructionSpec | null
    var prey_instruction:  PreyInstructionSpec  | null
```

**Spawn**：无 Spawn 文本 → spawn 内核 **默认生成**；有 Spawn – → 同内核读 spec 改 location。**唯一**在规则砖块内读 **印刷指令** 的敌人字段（G4 族）。

**Prey**：**不** 进入 G4 spawn 分支；**不** 编译 LISTENER。仅在 **auto engage**（敌人已在 location、多调查员须选 engage 目标）及 **Hunter 等距**（**③** 移动 LISTENER 的 handler **内**一行 `PreyResolver`）同步读 spec。

```text
G4 spawn 砖块（②）
  … SpawnLocationResolver(spec) … spawn_at_location …
  if not aloof:
    auto_engage_at_location(enemy, loc)     # ② engage 内核
      candidates := investigators_at(loc)
      target := PreyResolver.best_match(prey_instruction, candidates)  # ① 同步读
      … engage L0 …                         # 效果在 engage，不在 Prey

seq.enemy.3_2 RESOLVE hunter LISTENER（③）
  … move …
  if equidistant.size() > 1:
    pick := PreyResolver.best_match(prey_instruction, equidistant)  # ① 内联，非 Prey nest
```

**Prey 标签**：魔典条目或写 keyword ability；**引擎裁定为指令**（与 Spawn 同列），**不** 译 LISTENER / 关键词 Buff — **标签 + 括号** → `PreyInstructionSpec`（**①**）。

#### 0.1.3 Patrol：移动编译（③）+ 括号参数（①）

| 轨 | 归类 | 引擎 |
|---|---|---|
| **Patrol 移动** | **③** LISTENER @ `(seq.enemy.3_2, WHEN)` | AbilityCompiler 共享模板；L0 move 1 步 |
| **Patrol (…)** 括号 | **①** `PatrolTargetSpec` | LISTENER handler **内** `PatrolTargetResolver` — **不** 为括号 nest |

**禁止**：Prey / Patrol 括号 **独立** nest；把 Prey 当 Forced；Patrol 括号单独 Register。

#### 0.1.4 导入与运行时

| 阶段 | 规则参数（①） | 编译订阅（③） |
|---|---|---|
| **导入** | 解析段落 → `*Spec` 挂 `CardDefinition` | keyword → `RegistrationTemplate` |
| **dry-run** | **不参与** CREATED | Register / Atom 可 CREATED |
| **运行时** | 规则 / LISTENER handler 内 **`Resolver.*` 同步调用** | `emit` → COLLECT → Initiation → Composition |
| **玩家窗口** | Resolver 需 Lead **打破并列** → [16](16-player-interaction.md) Choice | ResponseWindow 等 |

#### 0.1.5 刻意不归入 ① 的卡面信息

| 内容 | 归类 | 说明 |
|---|---|---|
| Victory X、Bearer、My Collection | 静态 / 路由元数据 | defeat、weakness、构筑 |
| 🧣 per investigator | 印刷值缩放 | setup 乘数 |
| Hidden、险境、涌动等 keyword | **③** 编译为三种 Buff（[06 §3.2.5](06-registration-buff-model.md#325-实现路径指令--参数--关键词-buff已裁决)） | RESTRICTION / LISTENER / MODIFIER；KEYWORD 标记只表示拥有 |
| 技能图标 `[willpower]` 等 | `skills_icons` | commit / 检定，见 [04](04-skill-test-engine.md) |

#### 0.1.6 指令 / 参数 / 关键词 Buff（与三档正交）

详细接线表：[06 §3.2.5](06-registration-buff-model.md#325-实现路径指令--参数--关键词-buff已裁决)。

| 卡面 | 档 | 落地 |
|---|---|---|
| **指令** Spawn – / Prey – | **①**（Spawn 的 L0 进场在 **②**） | Spec + 内核 Resolver；**不是关键词** |
| **参数** 括号 / X / type | **①** | 挂在指令或关键词的 Spec 上；handler 内读 |
| **关键词** 对局行为 | **③** | 编译为 `MODIFIER` / `RESTRICTION` / `LISTENER` |
| **Fast.** 快速 | 打出形式（非能力） | 窗口/花费对称触发；种类始终 `PLAY_CARD`（[06 §4.2](06-ability-initiation.md#42-打出与触发对称fast打出-不是-能力)） |
| Uses / Victory / Seal | L0 / Domain | 仍是关键词，不走三种 Buff |
| 构筑关键词 | 11 | 对局不消费 |

**禁止**：把猎物/生成写进 KeywordProfile；为括号单独 nest；为关键词新增 BuffType。LISTENER 注册/注销绑已有 `seq.*` 砖或 zone 变迁，禁止 `PERIL_CHECK` 一类独立场合节点。见 [06 §3.2.6](06-registration-buff-model.md#326-listener--buff-的注册与注销场合已裁决)。

---

## 1. 目标

定义规则引擎可执行的 **结算叶**。Grimoire 局面变更在 **Composition / 命名流程** 内归约为：

1. **状态原语**（物理，看得见）；
2. **信息原语**（不可见结算：Register · Log · Remember…）；可见性见 §5.4.1（非结算）；
3. 外加命名流程 / Wrapper（派生索引随物理维护，见 §5.4）。

**禁止**原语叶子当 Timing 订阅面。卡牌脚本与 YAML **不得**直接调 `GameStateStore` / `PhysicalOps` 可变 API。

---

## 2. 核心命题

> 复杂效果 = **物理结算** + **不可见结算（信息原语）**，经命名流程组合。

「标记」包含：

- 物理 token（damage、horror、doom、clue、uses/charges/ammo…）
- 非 token 计数（`resource_pool`、`actions_remaining`、`clues_on_location`…）

二者统一用 **MarkerSlot** 寻址，用 **Transfer**（∞ 供给池）变更；**禁止 Adjust**。

---

## 3. 三层边界

| 层 | 名称 | 职责 | 示例 |
|---|---|---|---|
| **物理原语** | `PhysicalOps` / `StateMutator` | **状态原语**三类 | `move_card`, `transfer_marker`, `set_face`, `set_exhausted` |
| **信息原语** | Register / Log·Remember / `InformationExecutor` | **不可见结算**各族 | `seq.effect.register`；log；remember；`reveal_to_*` |
| **派生索引** | Domain 缓存 | 随物理维护；非原语 | `location_tag`, threat 成员, `attached_to` |
| **命名流程** | `SequenceCatalog` + 堆栈 | 组合效果叶 | `seq.effect.take_horror`, `seq.enter_hand` |
| **L1** | Composition | 原语 + Register 树 | Then draw + horror |
| **L2** | Semantics / Wrapper | 规则书语义；nest `seq.*` | DealDamage；PlayCard = Initiation |

```
CardScript / YAML  →  L2 Wrapper/Macro  →  L1 CompositionTree  →  L0 Atoms  →  GameStateStore
```

**TimingBus**（Cancel / Replacement / After）挂在 **L1 执行框架** 与 **L2 PendingResolution**，不属于 L0。

---

## 4. 地址类型

### 4.1 `CardSlot` — 卡牌容器中的位置

```gdscript
class CardSlot:
    var pile: PileKind
    var owner_id: StringName      # 调查员 id | &"encounter" | 地点 id | &"scenario" | &"global"
    var zone: Zone                # 与 pile 一致或冗余校验
    var index: InsertIndex        # 见 §4.1.1

enum PileKind {
    INV_DECK, INV_HAND, INV_DISCARD, INV_PLAY_AREA, INV_THREAT_AREA,
    ENCOUNTER_DECK, ENCOUNTER_DISCARD,
    LOCATION_ENEMIES, LOCATION_OTHER,   # 地点上的遭遇卡
    SET_ASIDE, VICTORY_DISPLAY, REMOVED_FROM_GAME,
    CURRENT_ACT, CURRENT_AGENDA, ACT_DECK, AGENDA_DECK,
    ATTACHED_TO,                      # owner_id = 宿主卡 instance_id
    LIMBO,                            # owner_id = 结算控制者
    SCENARIO_REFERENCE,
}

class InsertIndex:
    enum Mode { TOP, BOTTOM, AT, RANDOM }
    var mode: Mode
    var at: int = 0                  # Mode == AT
```

**解析规则**：`(pile, owner_id, index)` 唯一确定手牌第 3 张、遭遇弃牌堆顶等。`Zone` 与 `PileKind` 一一对应，便于校验。

#### 4.1.1 顺序语义

| Mode | 含义 |
|---|---|
| `TOP` | 栈顶：deck 顶 = index 0；discard 顶 = 0 |
| `BOTTOM` | 栈底 |
| `AT` | 明确下标（手牌插入） |
| `RANDOM` | 洗牌内随机位置（仅 Domain 工具调用，效果层少用） |

---

### 4.2 `MarkerSlot` — 标记 / 计数所在

```gdscript
enum MarkerKind {
    DAMAGE, HORROR, DOOM, CLUE,
    RESOURCE,                      # investigator.resource_pool
    ACTION,                        # investigator.actions_remaining（本回合）
    USES,                          # sub_key = "ammo" | "charges" | ...
    SHROUD,                        # location.shroud（revealed 后）
    CLUES_ON_LOCATION,             # location.clues_on_location
    CLUES_ON_INVESTIGATOR,         # investigator.clues_on_card
    DOOM_ON_AGENDA,                # 全局 agenda 计数
    POOL_DAMAGE, POOL_HORROR, POOL_CLUE, POOL_RESOURCE,  # global_token_pool
}

class MarkerSlot:
    var kind: MarkerKind
    var bearer_kind: BearerKind
    var bearer_id: StringName       # 空 = 全局
    var sub_key: StringName = &""   # USES 专用

enum BearerKind {
    CARD, INVESTIGATOR, LOCATION, ACT, AGENDA, GLOBAL, CHAOS_BAG,
}
```

**映射表（v1 必须实现）**：

| MarkerKind | 存储位置 |
|---|---|
| DAMAGE / HORROR / DOOM / CLUE / USES | `CardInstance.tokens` |
| RESOURCE / ACTION / CLUES_ON_INVESTIGATOR | `InvestigatorState` 对应字段 |
| CLUES_ON_LOCATION / SHROUD | `LocationState` |
| DOOM_ON_AGENDA | `GameStateStore.doom_on_agenda` |
| POOL_* | `GameStateStore.global_token_pool` |
| CHAOS_BAG | `ChaosBagSystem` 内部序列（见 §6.2） |

---

### 4.3 `FlagSlot` / `RefSlot` — 离散状态

```gdscript
enum FlagField {
    EXHAUSTED, IS_HIDDEN, FACE,           # CardFace A/B
    ELIMINATED, RESIGNED, IS_ACTIVE_TURN, # Investigator
    REVEALED,                             # Location
}

enum RefField {
    LOCATION,          # investigator.location_id
    ATTACHED_TO,       # attachment.attached_to
    ENGAGED_WITH,      # enemy → investigator（双向由 Domain 维护）
    SLOT_ACCESSORY, SLOT_HEAD, SLOT_BODY, SLOT_ALLY, SLOT_HAND, SLOT_ARCANE,
    CONTROLLER,        # 罕见；遭遇卡 drawn 后
}
```

---

## 5. 状态原语（L0 · 仅物理层）

> **已裁决（2026-10-23）**：状态原语 **只保留在物理层**——桌面实体的区/序、标记、形态。  
> **禁止**把信息层（`FaceAudience`、地点指称、淘汰旗、交战引用等）算进状态原语三类。  
> 信息层最小写入仍可由框架 / Composition 调用，且 Grimoire Reveal **仍是效果**（dry-run **CREATED**），但归属见 §5.4，**不是** L0 ③。  
> **状态原语 ⊂ 效果**；**Register ⊂ 效果** 但 **⊄ 状态原语**。见 §0。

| 类（L0） | 改什么（物理） | 实现 |
|---|---|---|
| **① 卡牌地址** | 所在区域、次序（牌堆/手牌/场…） | `AtomMoveCard`；洗牌等区序工具 |
| **② 标记/计数地址** | 标记所在与数量（含 ∞ 供给池） | **`AtomTransferMarker` only** |
| **③ 卡牌形态** | 正反面；横置 / 重整（约 90°） | `AtomFlipCard`（`CardFace`）；`AtomSetExhausted` |

**另：** **Register** 写 `RegistrationStore`（Buff），**是效果**，经 Composition L2，**不是** L0 状态原语。

共 **3 类状态原语（物理）** + **信息原语（可见性 / 知识，§5.4）** + **Register** + Domain 工厂。命名流程在其上组合。

### 5.1 ① 卡牌地址 — `AtomMoveCard`

```gdscript
class AtomMoveCard:
    var card_id: StringName
    var to: CardSlot
    var insert: InsertIndex.Mode
    # 可选：expected_from 仅用于 dry-run / 断言，执行时不强制
```

**做什么**：将 `card_id` 从当前 pile **移除**，插入 `to` pile 的指定位置；更新 `CardInstance.zone`、容器数组顺序。

**不做什么**：

- 不抽目标（Search / Draw 宏负责选 `card_id`）
- 不支付 cost
- 不触发 [reaction] / Forced（由 L1 执行器在 commit 后通知 TimingBus）

**Domain 边界转换（同一事务内强制）**：

当 `MoveCard` 跨越 In-Play ↔ Out-of-Play 边界时，`StateMutator` **必须**在同一原子事务内应用 [01 §5.1/5.2](01-game-state-zones.md) 的不变量，**不**拆成多个可选原子：

| 转换 | 强制附带 |
|---|---|
| → **Enters Play** | 更新 in-play 索引；记录 `enters_play` 待 emit（L1 commit 后 emit） |
| → **Leaves Play** | 卡上 token → `global_token_pool`；attachments → 各 owner discard；lasting 过期；再迁入目标 pile |

因此：**Discard 一张在场 Asset** = 单个 `AtomMoveCard`（Domain 内部完成 leave 捆绑），而不是 Wrapper 手动 Transfer 所有 token。

**Limbo**：进入/离开 `PileKind.LIMBO` 不触发 enters/leaves play（Grimoire Limbo）。

**放置关系**（旁置 / 附着 / 垫下 / 牌库）：见 [01 §3.5.1](01-game-state-zones.md)。`MoveCard` 的目标须带齐 PlacementKind + 宿主（若有）；**ATTACHED ≠ UNDER**；离场默认捆绑可用 `LeavePlayPolicy` 保留标记/附着/垫下。

---

### 5.2 ② 标记/计数地址 — `AtomTransferMarker`（已裁决 · 无穷池 2026-10-23）

**类职责**：`MarkerSlot` 上桌面 token 的变更。**唯一** L0 = **`AtomTransferMarker`**（1 源 → 1 目标）。

**无穷供给池（physical `supply` / Domain `TokenPool`）**：

- damage / horror / clue / resource / doom 等桌面标记 **始终**有来源或去向 = 供给池。
- 池 **无穷**：取出永不因库存失败；回池 **不累加**库存计数（湮入供给）。
- **禁止**从虚无创造 / 向虚无湮灭的单端 Adjust 作为桌面标记原语。

#### `AtomTransferMarker`

```gdscript
class AtomTransferMarker:
    var kind: MarkerKind
    var amount: int                  # > 0
    var from: MarkerSlot
    var to: MarkerSlot
    var sub_key: StringName = &""    # USES 时两边一致
```

**做什么**：`from` 减 `amount`，`to` 加 `amount`。池端按无穷模型；承载者端改 Domain 计数并镜像物理层。  
**粒度硬约束**：**仅 1 源 → 1 目标**。禁止在单次 L0 内吞多源多目标。

**多来源 / 多目标**：包装层 `MarkerTransferBatch` 展开为若干条本原子。再分配 / Move 伤恐共用；**不**另铸 `seq.effect.transfer_*`。  
命名流程侧：`seq.effect.deal` / `discover_clue` 可一次压栈带 `legs[]`，handler 内仍逐腿调本原子——**seq 多目标 ≠ L0 多目标**。伤+恐待分配走 `deal.assignable` 同帧同时 Apply。

| 语义 | Transfer |
|---|---|
| Deal / place affliction | `POOL_*` → bearer |
| Heal / 回池 | bearer → `POOL_*` |
| Move / 再分配 | bearer A → bearer B |
| Discover clue | location → investigator（或经池，视地址模型） |
| Gain resource | `POOL_RESOURCE` → investigator |

**禁止** `adjust_marker` / 虚无 delta 糖：调用方必须显式写 `transfer_marker(kind, n, from, to)`（含 `MarkerSlot.supply(kind)` 池端点）。  
**不检查** defeat（上层 `CheckDefeat`）。  
heal 相关 [reaction]：TimingBus 看语义标签，非原子自身。

#### ~~`AtomAdjustMarker`~~（废止）

已删除。桌面标记只经 `AtomTransferMarker`。

---

### 5.3 ③ 卡牌形态 — `AtomFlipCard` / `AtomSetExhausted`

**类职责**：桌上卡牌的 **物理形态**——哪一面朝上、是否横置。对应 `PhysicalOps.set_face` / `set_exhausted`（经 Domain 镜像）。

#### `AtomFlipCard`（翻面）

```gdscript
class AtomFlipCard:
    var card_id: StringName
    var face: CardFace                 # A | B
```

**做什么**：写物理 `PhysicalCard.face`（及 Domain 镜像若有）。  
**不做什么**：**不**写 `FaceAudience`；不决定「谁可知牌面」。

| 场景 | 形态 |
|---|---|
| 双面地点 / Act / Agenda 翻到另一面 | `face = B`（或回 `A`） |
| 抽牌后把牌翻到正面朝上 | 常伴随信息层 Reveal，但本原子只翻面 |

#### `AtomSetExhausted`（横置 / 重整）

```gdscript
class AtomSetExhausted:
    var card_id: StringName
    var exhausted: bool                # true = 横置（约 90°）；false = 重整
```

**做什么**：写物理 orientation + Domain `exhausted`（现经 `ExhaustReadyFlow` / `PhysicalBinding.mirror_exhausted`）。  
**入口**：规则书手续多为 `seq.effect.exhaust` / `seq.effect.ready`（命名流程），RESOLVE 内落地本原子——**不是**信息层 SetFlag 冒充形态。

---

### 5.4 信息原语 = 不可见结算（**不是**状态原语）

> **对齐**：除开物理层以外、**仍算结算**的那些——Register / Log / Remember…  
> **可见性不在此列**（见 §5.4.1）。

dry-run **CREATED**；**不是** Timing 订阅面。

#### 5.4.0 族谱（不可见结算 · 收束）

| 族 | 写哪里 | 说明 | 状态 |
|---|---|---|---|
| **A. Register** | `RegistrationStore` | lasting / 延时 / cannot / gain / blank / 挂能力 / **有效控制**… | **主量**（[06](06-registration-buff-model.md)） |
| **B. Chronicle（记事）** | 场景/战役记事库 | 「在日志中记录…」∪「记住…」；键值/条目，**无**三种 Buff | **薄**；≠ `RulesMemory` |

控制权、纯规则拓扑、Gain 特征等：**优先 Register Buff**，不单立信息原语族。

**不是结算**：FaceAudience（权限）；物理三族；派生索引；`RulesMemory`；印刷 Spec；`effective_*` 查询。

#### 5.4.1 可见性 = 权限 / 卡牌信息管理（**不是原语**）

> **裁决（2026-10-24）**：牌面可见性是为游戏性服务的 **玩家权限式信息管理**，**不是**结算原语。  
> 某些结算或命名流程步会 **自动同步** 可见性；**改变可见性本身不算一种结算**，dry-run **不**因仅改 Audience 而标 **CREATED**。

```text
结算 / 手续步（CREATED 看这些）
  Move 入手 · 进弃牌 · Search 取牌 · Register · …
        │
        ▼ 可附带（政策，非效果叶）
  FaceAudience / known_to   ← 谁被允许知道这张牌的牌面
```

| 问题 | 答 |
|---|---|
| 可见性纳入原语吗？ | **否** |
| 改可见性算结算吗？ | **否**；是权限同步 |
| 为何还有 `reveal_to_*` API？ | 手续/政策入口（D2/E2、窥探、Search 结束 hide）；**写权限**，不冒充效果叶 |
| 纸面「Reveal the top card」？ | 常是 **手续步**（或伴物理翻面）；有意义的 CREATED 来自其后的取/弃/检定等，或根本无 CREATED |
| Cancel revelation？ | Cancel 的是 **显现能力体**（Composition 效果），不是「取消 Audience 写入」；G4 仍 discard（FAQ） |

与物理翻面 **正交**：面朝下仍可对控制者可知（隐私）；翻面是形态结算，Audience 是权限。

实现可保留 `InformationExecutor.reveal_to_*` / `hide_from_all` 作为 **政策写入**；Composition 若仍有 reveal 节点，标注为 **权限同步**，L7 **不计** CREATED。

#### 5.4.2 Register · 设计解剖（结算面 vs 载荷面）

> 详：[06 §2–§5 / §9](06-registration-buff-model.md)。此处回答：**形态是什么、原语语境下还能不能拆。**

```text
┌─ 结算面（信息原语 · 仅此）─────────────────────┐
│  Register / Unregister                         │
│  = 插入或卸下一条 Registration                 │
│  CREATED ⇔ 插入成功（Unload 亦为结算）           │
└────────────────────────────────────────────────┘
         │ 写出
         ▼
┌─ Registration（壳）────────────────────────────┐
│  source · lifetime · scope · tags              │
│  lasting vs 延时 = 只改 lifetime，不是两种原语  │
└────────────────────────────────────────────────┘
         │ 内含
         ▼
┌─ Buff 载荷（非原语 · Register 唯一可写物）─────┐
│  行为三型：MODIFIER | RESTRICTION | LISTENER   │
│  Gain 特征族：KEYWORD · TRAIT · ICON · ABILITY │
│  扩展：有效控制、blank…                        │
│  Gain 创建 → 可【衍生】再挂行为 Buff / 能力挂载 │
└────────────────────────────────────────────────┘
```

| 轴 | 有什么 | 是原语吗？ |
|---|---|---|
| **结算** | Register · Unregister（**只能**写/卸 Buff） | **是** |
| **壳参数** | lifetime · scope · source | **否** |
| **载荷** | 行为三型 + Gain 特征族 | **否** |
| **衍生** | Gain → 行为 Buff / Lifecycle mount | **否**（创建副作用；子项仍是 Buff 或挂载） |
| **消费** | collect / COLLECT / ModifierEngine… | **否** |

**行为三型**：

| BuffType | 消费 | 典型 |
|---|---|---|
| **MODIFIER** | ModifierEngine | until… +1；伤害/发现量等 |
| **RESTRICTION** | Eligibility / Intent | cannot；SKIP_AOO… |
| **LISTENER** | Catalog → Composition | 「until… after…」；延时；**或** keyword Gain **衍生** |
| **BLANK**（非 MODIFIER） | 压制印刷文本框 | 见 06；**不**走加减法 |

**Gain 特征 Buff**（[06 §3.2](06-registration-buff-model.md)）：Register 写出「拥有」；**文本能力 / 行为 keyword** 在创建时 **衍生**（非改叫 LISTENER）：

| 档 | Gain 载荷 | 衍生 |
|---|---|---|
| 只读 | TRAIT / ICON / 部分 KEYWORD | 通常无 |
| 文本能力 / 行为 keyword | `ABILITY`+AbilitySpec 或 KEYWORD | Lifecycle mount；Profile → LISTENER/RESTRICTION/MODIFIER |

**印刷能力不是 Buff**（进场挂载，不经 Register）。**效果 gains 能力** = Gain Buff → 衍生挂载。禁止 Register 旁路挂裸 AbilitySpec；禁止把印刷 Forced 举例成 LISTENER。详见 [06 §2.3 / §3.2.1a](06-registration-buff-model.md)。

持续 vs 延时：**同一 Register**，差在 `DURATION/WHILE_*` vs `UNTIL_FIRED`（[06 §4](06-registration-buff-model.md)）。多 Buff 可同壳一次 Register（§5.4）。

##### 原语语境下 Register 还能拆吗？

| 拆法 | 结论 |
|---|---|
| 按 BuffType 拆成 3 个结算原语 | **否** — 共享壳与 Store；差别在载荷 |
| 拆 lasting / delayed 两套原语 | **否** — 已并 lifetime |
| 拆 Register vs Unregister | **可选** 语法糖；语义上是一对互逆写 |
| 拆「拥有标记」vs「行为 Buff」为两套 Store | **不建议** — 同为 Registration；查询已分 `has_effective` / collect(type) |
| 把 Chronicle 并进 Register（FACT Buff） | **可但不必** — 记事无 lifetime/三型消费，保持薄库更干净 |

**裁决倾向**：**信息原语结算面不再拆**——就是 Register（± Unregister）。复杂度留在 **Buff 形态与 Lifetime**，不要再增殖结算动词。

**与发起有效性**：Register 留在原语内，正是为了 L7 dry-run——「只挂 Buff、不动子」仍算干了点什么；空效果体另用 `EmptySettle`（§4.1.2 composition）；真挂 Buff 仍靠 Register。

卡面创建经 `seq.effect.register`；禁止真空 `RegistrationStore.register`。

#### 5.4.2b Register 作为信息原语：怎么包装 / 丰富

> 结算面保持极薄；**丰富发生在壳参数与 Buff 载荷**，不增殖 `seq.effect.*` 结算动词。

```text
Composition / 卡面
  └─ nest 或内联 → seq.effect.register | unregister     ← 唯一结算包装
        params: RegistrationTemplate
          ├─ 壳：source · lifetime · scope · tags · referents…
          └─ buffs[]：BuffSpec { type, payload, … }
                ├─ MODIFIER      → ModifierEngine
                ├─ RESTRICTION   → Eligibility / Intent
                ├─ LISTENER      → Catalog fire → Composition（效果创造的延时/持续壳内听）
                └─ 拥有标记      → has_effective_*（再按需挂行为 Buff）
```

| 层 | 包装什么 | 丰富方向 | 不要塞什么 |
|---|---|---|---|
| **结算 API** | `register(template)` / `unregister(id\|filter)` | 保持两动词；CREATED=插入成功 | 按 BuffType 拆 `seq.effect.modifier` 等 |
| **壳 Lifetime** | `WHILE_*` / `DURATION` / `UNTIL_FIRED` / `UNTIL_CONDITION` | 补齐纸面 until/while；tick 边界先于同界 Listener | 另开 LastingStore |
| **壳 Scope / source** | 谁受益、绑哪张源卡 | 有效控制、宿主离场卸 | 真空改 `controller_id` 当原语 |
| **MODIFIER payload** | stat · op · value · stacking | 技能/费用/伤害量等数值 | 把 **blank** 塞进 MODIFIER |
| **BLANK payload** | 空白哪些框/面 | 视为空白印刷文本 | 当数值修正；抹 gained（RR：不抹） |
| **RESTRICTION payload** | RestrictionKind + 参数 | cannot 族、SKIP_AOO、冷漠、交战、**有效控制**、拓扑限制 | 把 Prey/Spawn 指令做成 Restriction |
| **LISTENER payload** | timing slot + Composition / nest seq | 效果创造的「until… after…」与纯延时 | 印刷 Forced / `[reaction]`（能力） |
| **Gain 族** | 几乎全部能力类型（含 Forced、关键词）+ TRAIT/ICON/数值 | Grant → AbilitySpec / 标记 / MODIFIER | 把 Gain 收成仅 KEYWORD |
| **糖 template** | `lasting_modifier` / `skip_aoo` / `gained_keyword…` | 编译期/Builder 展开为完整 Template | 运行时糖 Atom 吞多步 |

**包装纪律（与物理原语对称）**：

1. **薄结算、厚载荷** — 信息原语对外只有 Register/Unregister；花样全在 Template。  
2. **一律经命名流程** — `seq.effect.register` / `unregister`；Composition 叶禁止直写 Store。  
3. **一次 Register 可多 Buff 同壳** — 同一 lifetime 罩住 +1 与「每次…」（[06 §5.4](06-registration-buff-model.md)）。  
4. **查询不是原语** — `collect` / `has_effective_*` / ModifierEngine 为厚读。  
5. **与 Chronicle 分家** — 日志/记住不进 BuffType；需要时另叶。  
6. **与 EmptySettle 分家** — 无正文事件用不写入的空叶过发起门；有 lasting 正文仍 Register。

**优先丰富清单**（不改结算动词）：

| 优先级 | 丰富点 | 用途 |
|---|---|---|
| P0 | RestrictionKind 报表完备 | cannot / 入口改道（SKIP_AOO 等） |
| P0 | Lifetime 与离场/帧 tick 对齐 | 险境、隐私、UNTIL_FIRED |
| P1 | 有效控制；**BLANK** 独立载荷（≠ MODIFIER） | 文本框空白进 effective 公式 |
| P1 | LISTENER payload 与 AbilitySpec 边界测试 | 防 Forced 误编进 Buff |
| P2 | Template 工厂覆盖纸面句式 | 编译器少手写壳字段 |

#### 5.4.3 Chronicle（记事）· 日志 ∪ 记住

简单、无 Buff 三型：追加/写入条目或键值；后文「若日志有… / 若记得…」只读。  
≠ 事件回放 UI；≠ 步间 `RulesMemory`。可进 Composition 为薄结算叶；**不是** Register 的第四 BuffType。

#### 派生索引 vs 直读（策略裁决）

实体规模小（1–4 调查员、场面卡数十张量级），**直读物理 / 经投影函数扫描的开销通常可接受**。单独做「延迟失效缓存」要挂的更新点反而多（Move、交战进出威胁区、附着、击败退场、翻面、线索 Transfer…），漏一处 = 静默错局面，代价高于多几次扫描。

| 策略 | 何时用 | 风险 |
|---|---|---|
| **A. 直读投影**（默认） | `enemies_at(loc)`、`cards_in(region)` 每次从物理区算 | 热路径上重复扫描；逻辑简单、无陈旧 |
| **B. 咽喉双写** | 仅在 `StateMutator.move_card` / `transfer_marker` / `flip` **同一事务**写 Domain 索引 | 可接受；**不是**散落 listener 缓存 |
| **C. 延迟失效缓存** | **默认不用** | 触发面大、易漏；仅 profile 证明热点后再考虑，且失效必须挂咽喉而非各 flow |

**裁决**：默认 **A**；现有 `location_tag` / threat 列表若保留，按 **B** 在 Mutator 咽喉维护，文档称 **派生索引**，不称信息原语。禁止演进成 C。

| 字段（例） | 权威 | 维护 |
|---|---|---|
| 位置 / 威胁区 / 附着 | 物理区 | A 直读，或 B 咽喉索引 |
| `LocationState.revealed` | 形态 + 线索标记 | 同上 |
| 常规 `controller` | 手牌/场地区属主 | 同上；隐私例外可与 audience 绑定 |

#### 卡牌信息解析（厚读 · **非**新写原语）

卡面印刷与生效特征 **是信息**，但走 **目录 + Register 查询**，不新增「图标原语」：

```text
effective(card) =
    printed(CardDefinition)          # 技能投入图标、连接、特性、关键词、能力文本…
      ∪ gained(Register)             # Gain 图标/特性/关键词/能力（Grimoire：视为具备）
      − blank_printed(Register)      # 文本框 blank：抹印刷；gained 不被 blank（RR）
```

| 来源 | 归属 | 说明 |
|---|---|---|
| 印刷图标 / 连接 / 特性 | `CardDefinition` 只读目录 | 导入期；信息层 **读** |
| Gain … | **Register**（创建经 `seq.effect.register`） | 查询须区分 `is_printed_*` vs `has_effective_*`（[06 §Gain](06-registration-buff-model.md)） |
| 视为空白 blank | **Register · BLANK**（**不是** MODIFIER） | 压制 **印刷** 文本框；不抹 gained；改的是 effective 读径，不是 +/− 数值 |
| 谁看得到牌面 | **权限层** `FaceAudience`（非原语） | 与印刷/生效特征正交 |

检定 commit、连接图、关键词开火等：**只问 `effective_*`**，禁止手续直接假定「等于印刷」。

#### 厚读 ≠ 不可见结算

| 厚（不结算） | 不可见结算叶（信息原语） |
|---|---|
| 直读投影、Eligibility、场合、`RulesMemory`、**Audience 权限** | A Register · B Log · C Remember · … |
| `effective_*` **查询** | Gain / blank **创建** = A |
| Register / log / 记忆的 **读取** | 对应库的 **写入** |
| 印刷 Spec | — |

---

### 5.5 Domain 工厂（非效果原子）

| 操作 | 归属 | 说明 |
|---|---|---|
| `CreateCardInstance(def_id, owner)` | Domain factory | 生成 `EntityId`，**不**放入任何 pile |
| `DestroyInstance(card_id)` | Domain factory | 仅测试/场景清理；正式规则用 `REMOVED_FROM_GAME` |

Spawn 敌人/Asset = `Create` + `AtomMoveCard`（Wrapper 或 Simultaneous 组）。

---

## 6. 明确 **不是** 原子

以下必须在 L1/L2；**禁止** 加入 L0 enum：

| 类别 | 示例 | 应如何实现 |
|---|---|---|
| **选择/搜索** | search top 5, choose card | L1 `Choice` + 查询 API；选中后 `MoveCard` |
| **洗牌** | shuffle deck | Domain 工具 `PileOps.shuffle`；宏 `Shuffle(deck)` 调用之 |
| **伤害 Assign** | assign、direct、prevent | `DamageWrapper` 步骤；输出多个 Adjust/Transfer |
| **检定** | ST.1–ST.8 | `SkillTestEngine` |
| **Initiation** | pay cost, AOO | `AbilityInitiationPipeline` |
| **Timing** | Cancel, Replacement, After | `TimingBus` |
| **组合逻辑** | then, for each, simultaneously | L1 节点 |
| **宏语义** | draw 1, discover 1, defeat enemy | L2 展开为原子树 |
| **连接图变更** | 锁门、增边 | L2 `LocationGraphWrapper` → 可能仅 `SetRef`/`SetFlag` on edge store |
| **Chaos 揭示** | reveal token | L2 `ChaosBagWrapper`（内部 1–2 个专用 Domain op，见 §6.2） |

### 6.1 「Draw 1」为何不是原子

```
Draw(1) := Choice? + MoveCard(deck.TOP → hand.BOTTOM)
```

抽哪张由 **pile 顺序** 决定；无需 `AtomDraw`。

### 6.2 Chaos Bag 边界

混沌 token **不在** `MarkerSlot` 体系内（揭示前无 bearer）。

| 操作 | 层级 |
|---|---|
| 组装 bag / 冒险重置 | Setup / Scenario |
| Reveal 1 token | `ChaosBagMutator.reveal()` — **Domain 专用 op**，等价「从 bag 序列 Pop + 放入 revealed 缓冲区」 |
| Return token | `ChaosBagMutator.return_token()` |

对 L1 表现为 **伪原子** `ChaosReveal` / `ChaosReturn`，文档上记为 **Domain 扩展 op**，**不**与 Marker 原子混用。v1 可暂不纳入 `StateMutator` 主表。

### 6.3 Defeat / Advance Act

| 语义 | 展开 |
|---|---|
| **Defeat enemy** | `MoveCard` → discard + Wrapper `CheckDefeat` + 可能 `SetFlag` |
| **Advance act** | `MoveCard` current act → discard + `MoveCard` next → `CURRENT_ACT` + 可能 `SetFlag(FACE)` |

---

## 7. 原子事务与 EventRecord

每个原子 commit 产生一条 **atomic record**：

```gdscript
class AtomicRecord:
    var seq: int
    var atom_kind: StringName    # move_card | transfer_marker | flip_card | set_exhausted | (+ info: reveal_audience …)
    var payload: Dictionary      # 地址 + 数值 + card_id
    var state_hash: String
```

L2 Wrapper 额外写 **semantic record**（`semantic=deal_damage`, `amount=3`）便于 UI，但 **回放/回归以 atomic 为准**。

**Simultaneous 组**：组内多条 atomic record 共享 `group_id`；组 commit 后才 flush `after`。

---

## 8. Dry-run

对 L1 组合树 **符号执行**：

1. Fork `GameStateStore`（浅拷贝容器 + 共享不可变 def）
2. 按序/按组应用 **三类** L0 子操作
3. 不 emit TimingBus（Forced/[reaction] 不跑）
4. 返回 `ResolvableReport`：哪些原子会失败、是否至少一条成功

Initiation dry-run（OQ-06-02）= 对 **整棵 Wrapper 树** 做上述模拟。

---

## 9. 与旧 `EffectOp` 的关系

`EffectOp` **降级** 为 L2 宏 ID / 日志标签；**执行路径**：

```gdscript
MacroRegistry.compile(op, params) -> CompositionTree
CompositionExecutor.run(tree)
```

| 旧 EffectOp | 展开 |
|---|---|
| DRAW_CARDS | `Repeat(n, MoveCard deck→hand)` |
| GAIN_RESOURCE | `TransferMarker(POOL_RESOURCE → inv.RESOURCE, n)` |
| HEAL | `TransferMarker(bearer → POOL_*, n)` + semantic heal |
| TRANSFER_AFFLICTION | `MarkerTransferBatch` → 若干 `TransferMarker`（每腿 1:1） |
| DEAL_DAMAGE | `DamagePipeline` → Assign → 若干 `TransferMarker(POOL → bearer)` |
| DISCOVER_CLUE | `TransferMarker(CLUES_ON_LOCATION, n, loc, inv)` |
| EXHAUST / READY | `SetFlag(EXHAUSTED, true/false)` |
| MOVE_INVESTIGATOR | `SetRef(LOCATION, loc)` + enter Wrapper 可选 |

---

## 10. v1 实现检查清单

| 优先级 | 交付 |
|---|---|
| P0 | `CardSlot` / `MarkerSlot` 解析 + 单元测试 |
| P0 | `StateMutator` **三类** L0 原子 + leave/enter 捆绑 |
| P0 | `CompositionExecutor`: Seq, Simultaneous |
| P1 | Macro: Draw, GainResource, Discover, Heal, Transfer |
| P1 | `DamageWrapper` |
| P2 | Choice, ForEach, Optional |
| P2 | YAML → CompositionTree 编译 |

---

## 11. 开放问题（原子层）

| ID | 问题 | 建议默认 |
|---|---|---|
| OQ-PRIM-01 | Leave play 时 attachment discard 顺序是否可见 | 否；Simultaneous 组内原子，无顺序依赖 |
| OQ-PRIM-02 | heal 超过当前 damage（浪费） | Transfer 量夹到当前值；多余不取 |
| OQ-PRIM-03 | Engage 是否一个 `SetRef` 还是 Ref+MoveCard 两个原子 | **两个原子** Seq；Wrapper `Engage` 保证顺序 |
| OQ-PRIM-04 | 调查员 defeated 时 clues 归地点 | Wrapper：`TransferMarker` CLUES_ON_INVESTIGATOR → CLUES_ON_LOCATION |
| OQ-PRIM-05 | 控制/归属是否单立 E 族 | 无区 Move 时倾向 **是** |
| OQ-PRIM-06 | 纯规则改图是否单立 F 族 | 无物理标记时倾向 **是** |
| OQ-PRIM-07 | Log 与 Remember 是否合并为一个「记忆库」原子族 | 纸面常分写；存储可同后端不同 API |

---

## 12. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-10-24 | v0.3.28 | Register 只写 Buff；Gain 创建可衍生行为 Buff / 能力挂载 |
| 2026-10-24 | v0.3.27 | Gain 分档：只读特征 vs 文本能力（注册+初始化，同印刷挂载） |
| 2026-10-24 | v0.3.26 | Gain 可含 Forced/触发/Constant/关键词等几乎全部能力类型 |
| 2026-10-24 | v0.3.25 | §5.4.2：Gain 特征族含触发/永续能力；纠正「只有 KEYWORD 标记」 |
| 2026-10-24 | v0.3.24 | §5.4.2b：Register 包装/丰富 — 薄 API、厚壳与 Buff；优先 RestrictionKind/Lifetime/控制 |
| 2026-10-24 | v0.3.23 | §0：Register 作原语 ↔ 发起有效性；物理∧Register 皆无 CREATED = 空结算禁发起 |
| 2026-10-24 | v0.3.22 | §5.4.2：LISTENER Buff 举例改为 lasting/延时；Forced/reaction = 能力 |
| 2026-10-24 | v0.3.21 | §5.4：信息原语≈Register+Chronicle；控制走 Buff；Register 结算面不按 BuffType 拆 |
| 2026-10-24 | v0.3.20 | §0/§5.4.1：FaceAudience = 权限/信息管理，非结算原语；不单独 CREATED |
| 2026-10-24 | v0.3.19 | §5.4.2：Register = 结算动词；Buff = Registration 载荷（非第二套原语） |
| 2026-10-24 | v0.3.18 | §0/§5.4：信息原语 = 不可见结算；含 Register·Log·Remember·Audience；废「只有 Audience + Register 旁路」 |
| 2026-10-24 | v0.3.17 | §5.4.0：信息原语盘点（后由 v0.3.18 改对齐） |
| 2026-10-24 | v0.3.16 | §0.0：原语 = 能影响游戏的结算（必须做事）；厚读 ≠ 原语 |
| 2026-10-24 | v0.3.15 | §5.4：直读优先 vs 咽喉双写；卡牌生效特征 = 印刷∪Gain−blank（读路径） |
| 2026-10-23 | v0.3.14 | §5.4 收薄：信息原语主轴仅可见性；引用/多数旗 → 物理派生索引 |
| 2026-10-23 | v0.3.13 | §0/§5.4：信息原语初稿（后收薄为 v0.3.14） |
| 2026-10-23 | v0.3.12 | §0/§5：状态原语仅物理层；③=翻面/横置；Reveal/`FaceAudience`/SetRef → §5.4 信息层 |
| 2026-10-23 | v0.3.11 | §5.2：桌面标记仅 Transfer；供给池无穷；废止 Adjust 为桌面 L0 |
| 2026-09-21 | v0.3.10 | §3：L2 宏展开为 `seq.effect.*`（纸面无名也铸造）；07-composition §1.3.3 |
| 2026-09-21 | v0.3.9 | Fast 只改打出窗口/花费；种类始终 `PLAY_CARD`，不是能力 |
| 2026-09-21 | v0.3.8 | Fast 打出与触发对称；不新增 BuffType |
| 2026-09-21 | v0.3.7 | 链 06 §3.2.6：注册绑已有 seq 砖 / zone 变迁，禁止独立场合节点 |
| 2026-09-21 | v0.3.6 | 链 06 §3.2.6：关键词/能力 LISTENER 不只有进场/离场 |
| 2026-09-21 | v0.3.5 | **§0.1.6** 指令 / 参数 / 关键词 Buff 分轨 |
| 2026-09-21 | v0.3.4 | **§0.1.6** 关键词编译为三种 Buff；猎物/生成为指令 |
| 2026-09-21 | v0.3.3 | **§0.1.6** 关键词 `consume_shape` 与三档正交；仅 NEST_SEQ nest `seq.keyword.*` |
| 2026-06-18 | v0.3.2 | §0.1 **三档译法**；Prey **①** engage 内核读参（不 nest）；Spawn **②** G4；Hunter/Patrol **③** |
| 2026-06-18 | v0.3 | ③ **揭示与离散** 合并为三类 L0；AtomRevealCard（Grimoire Reveal） |
| 2026-05-25 | v0.1 | 初稿：地址模型 + 非原子清单 |
