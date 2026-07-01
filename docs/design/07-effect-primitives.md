# 07a — 效果原子与地址模型 (Effect Primitives)

> **依赖**：[01-game-state-zones.md](01-game-state-zones.md)  
> **被依赖**：[07-effect-resolution.md](07-effect-resolution.md)（组合执行、语义包装）、[12-card-script-api.md](12-card-script-api.md)（`CardDefinition` · §0.1 三档译法）  
> **状态**：v0.3.2 · 2026-06-18 — §0.1 三档译法；Prey **仅 engage 内核**读参（不 nest）

---

## 0. 术语：效果 vs 状态原语（已裁决）

| 术语 | 英文 | 是否 **效果** | 说明 |
|---|---|---|---|
| **效果** | effect | — | resolve 可对规则/局面产生 **直接影响**；dry-run 可 **CREATED** 的节点类型 |
| **状态原语** | state primitive | **是**（子集） | 写 `GameStateStore` 的 L0 **三类**；**旧称「效果原子」易与 Grimoire 原子效果混淆** |
| **Register（注册）** | Register | **是** | 写 `RegistrationStore` / Buff；见 [07-composition §4.1](07-composition.md) |
| **揭示（Reveal）卡牌** | Reveal (card) | **是** | Grimoire **明确命名** 的游戏动作；L0 **`AtomRevealCard`** 写 `CardFaceVisibility.audience`；用户交互上公开牌面 |

```text
效果（可 CREATED）
  ├─ 状态原语（StateMutator → GameState）
  │    ├─ ① 卡牌地址（MoveCard）
  │    ├─ ② 标记/计数（Transfer / Adjust）
  │    └─ ③ 揭示与离散（AtomRevealCard；SetFlag / SetRef）
  └─ Register（→ RegistrationStore / Buff）

Presentation / headless
  └─ 只读 Domain 揭示状态；headless 始终保留完整 definition_id
```

**Register 是效果**：发起/打出 **合法性检测（dry-run）** 中，成功 Register 即 **CREATED**，与 Atom 并列（[06-ability-initiation §7](06-ability-initiation.md)、[07-composition §4.1](07-composition.md)）。

**揭示 vs 地点翻面**：**卡牌** Reveal = ③ **`AtomRevealCard`**。**地点** `Reveal location` = ③ **`AtomSetFlag(REVEALED)`** + Adjust 等，经 L2 `RevealLocationWrapper` 展开。

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

**Keyword Prey 标签**：魔典称 keyword ability；引擎 **不** 译 LISTENER — **标签 + 括号** → `PreyInstructionSpec`（**①**）。

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
| Hidden、险境、涌动等 keyword | **③** 编译 | REGISTER / LISTENER @ catalog |
| 技能图标 `[willpower]` 等 | `skills_icons` | commit / 检定，见 [04](04-skill-test-engine.md) |

---

## 1. 目标

定义规则引擎 **唯一可执行** 的 **状态原语（state primitive，L0 域写入）**。Grimoire 上的局面变更，在 **Composition / 命名流程** 内必须 **归约** 为：

1. **状态原语** 的有序/并行组合（含 **揭示状态**）；
2. **Register**（规则/Buff 写入，**是效果**，但不是状态原语）；
3. 外加 **语义包装 (Wrapper)** 在步骤之间插入规则步骤（如伤害 Assign）。

**卡牌揭示** 经 `StateMutator.reveal_to_*`（内部 `InformationExecutor`）写入 Domain；**是 L0 状态原语，是效果**。

**卡牌脚本与 YAML 不得直接调用 `GameStateStore` 的可变 API**；状态原语仅经 `StateMutator` 执行。

---

## 2. 核心命题

> 复杂效果 = **卡牌地址变更** + **标记/计数地址变更** + **揭示与离散字段变更**，再经组合与包装。

「标记」包含：

- 物理 token（damage、horror、doom、clue、uses/charges/ammo…）
- 非 token 计数（`resource_pool`、`actions_remaining`、`clues_on_location`…）

二者统一用 **MarkerSlot** 寻址，用 **Transfer** / **Adjust** 变更。

---

## 3. 三层边界

| 层 | 名称 | 职责 | 示例 |
|---|---|---|---|
| **L0** | Domain / `StateMutator` | 执行 **状态原语**；维护区域不变量 | `move_card`, `reveal_to_controller`, `transfer_marker` |
| **L1** | Composition | 状态原语 + Register 组合（Seq / Choice…） | Then draw + horror |
| **L2** | Semantics / Wrapper | 规则书语义；生成 L1 树；插入 Assign 等中间步骤 | DealDamage, PlayCard, RevealLocation |

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

## 5. 状态原语（L0）

> **已裁决口径（与 §2 一致）**：L0 只有 **三类** `GameStateStore` 写入，称 **状态原语**；`Reveal` / `SetFlag` / `SetRef` 为 ③ 类内 **实现子操作**（`AtomOp` 枚举保留细项）。  
> Grimoire **Reveal（揭示卡牌）** 对应 ③ **`AtomRevealCard`** — 写入 `FaceAudience`，用户交互上公开牌面；**是效果**，dry-run **CREATED**。  
> **状态原语 ⊂ 效果**；**Register ⊂ 效果** 但 **⊄ 状态原语**。见 §0。

| 类（L0） | 改什么 | 实现子操作（代码） |
|---|---|---|
| **① 卡牌地址** | `CardSlot`、顺序、zone | `AtomMoveCard` |
| **② 标记/计数地址** | `MarkerSlot` 间搬运或相对 pool 增减 | `AtomTransferMarker`；`AtomAdjustMarker` |
| **③ 揭示与离散** | 牌面可见性；布尔/枚举/引用（非 pile 顺序） | **`AtomRevealCard`** → `reveal_to_*`；`AtomSetFlag`；`AtomSetRef` |

**另：** **Register** 写 `RegistrationStore`（Buff），**是效果**，经 Composition L2，**不是** L0 状态原语。

共 **3 类状态原语** + **2 个 Domain 工厂**（`Create` / `Destroy`，非效果）。

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

---

### 5.2 ② 标记/计数地址 — `AtomTransferMarker` / `AtomAdjustMarker`

**类职责**：`MarkerSlot` 上的 token/计数变更。守恒搬运用 **Transfer**；单端增减（含 `POOL_*` 端点）用 **Adjust**。桌游语义上 heal/take horror 等优先表为 **Transfer**（bearer ↔ pool），见 OQ-07-02。

#### `AtomTransferMarker`

```gdscript
class AtomTransferMarker:
    var kind: MarkerKind
    var amount: int                  # > 0
    var from: MarkerSlot
    var to: MarkerSlot
    var sub_key: StringName = &""    # USES 时两边一致
```

**做什么**：`from` 减 `amount`，`to` 加 `amount`；**总量守恒**（池 ↔ 卡 ↔ 地点 ↔ 调查员之间搬运）。

**典型语义**：

- Discover clue：`CLUES_ON_LOCATION` → `CLUES_ON_INVESTIGATOR`
- Move 1 damage：`CARD.damage` → `CARD.damage`（另一张卡）
- Place clue from pool：`POOL_CLUE` → `CLUES_ON_LOCATION`

**不做什么**：

- 不 heal（那是 Adjust 负 delta，见下）
- 不 deal damage（Wrapper 在 Assign 后用 Adjust 或 Transfer from pool）
- 不检查 defeat（Wrapper `CheckDefeat`）

**约束**：

- `from` 当前值 `< amount` → 原子 **失败**，整棵组合树中止（除非 Wrapper 声明 partial OK）
- `USES` 必须指定 `sub_key`

---

#### `AtomAdjustMarker`

```gdscript
class AtomAdjustMarker:
    var kind: MarkerKind
    var delta: int                   # 可正可负
    var at: MarkerSlot
    var clamp_min: int = 0
    var clamp_max: int = 2147483647
```

**做什么**：单点 `at` 增减；**不与另一槽位配对**（创造/消灭标记）。

**典型语义**：

- Heal 2 damage：`delta = -2`, `at = card.DAMAGE`, `clamp_min = 0`
- Gain 1 resource：`delta = +1`, `at = inv.RESOURCE`
- Place doom on agenda：`delta = +1`, `at = DOOM_ON_AGENDA`
- Take horror：`delta = +1`, `at = inv 或 card.HORROR`

**与 Transfer 的边界（已裁决 OQ-07-02）**：

| 操作 | 原子 |
|---|---|
| Heal / 移除 affliction | **Adjust** 负 delta |
| Move damage/horror A→B | **Transfer** |
| Deal from 「虚无」 | **Adjust** 正 delta（或 POOL → 卡 用 Transfer） |

**不触发** heal 相关 [reaction] 的判定：由 TimingBus 看 **语义标签**（Wrapper 在 Adjust 前标记 `semantic=heal`），非原子自身。

---

### 5.3 ③ 揭示与离散 — `AtomRevealCard` / `AtomSetFlag` / `AtomSetRef`

**类职责**：非 pile、非 marker 守恒搬运的 **字段写入** — 含 Grimoire **Reveal（揭示卡牌）** 与 exhaust、地点翻面、引用等。

#### `AtomRevealCard`

> 规则 **明确命名** 的 Reveal；**不是** Presentation 旁路。

```gdscript
class AtomRevealCard:
    var card_id: StringName
    var audience: FaceAudience       # CONTROLLER | ALL | HIDDEN_ALL
    var controller_id: StringName    # audience=CONTROLLER 时同步 controller（遭遇 draw 等）
```

**做什么**：写入 `CardInstance.face_visibility.audience`；`CONTROLLER` 时通常同步 `controller_id`。  
**用户交互**：Presentation 读 Domain 后向对应观察者 **公开牌面**。  
**Headless**：规则层始终有完整 `definition_id`；测试 assert `face_known_to(card, observer)`。

| 操作 | audience | 场景 |
|---|---|---|
| `reveal_to_controller` | CONTROLLER | 调查员抽牌 D2；Hidden 对控制者；窥探仅自己可见 |
| `reveal_to_all` | ALL | 遭遇 E2 公开；「全体看牌库顶」 |
| `hide_from_all` | HIDDEN_ALL | Search 展示结束、恢复未知 |

**与 MoveCard 边界**：Reveal **不改 zone**（D2 后 zone 仍可 DECK/Limbo；D3 才 MoveCard 入手）。

**实现**：`StateMutator.reveal_to_*` 委托 `InformationExecutor`（历史类名；语义 = L0 揭示原语）。**dry-run** 成功 → **CREATED**。

#### `AtomSetFlag`

```gdscript
class AtomSetFlag:
    var bearer_id: StringName
    var field: FlagField
    var value: Variant                 # bool 或 CardFace
```

**典型**：Exhaust / Ready、Hidden、Flip Act/Agenda 面（`FACE`）、Location **`REVEALED`**（地点翻面）。

**不做什么**：Reveal 地点的 **放线索、改连接** → `RevealLocationWrapper`（组合 Adjust + SetFlag + 可能 MoveCard）。

#### `AtomSetRef`

```gdscript
class AtomSetRef:
    var bearer_id: StringName
    var field: RefField
    var ref_id: StringName             # 空 = 清除
```

**典型**：

- 调查员移动：`LOCATION` → 新 `location_id`（**不**自动 Reveal 地点；Wrapper 处理 enter）
- Attach：`ATTACHED_TO` + 伴随 `AtomMoveCard` → `ATTACHED_TO` pile
- Engage：`ENGAGED_WITH`（Domain 同步 enemy/investigator 双向集合）

**Slot 占用**：`SLOT_*` 设置时 Domain 校验 slot 类型与互斥；非法则原子失败。

---

### 5.4 Domain 工厂（非效果原子）

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
| **伤害 Assign** | soak、direct、prevent | `DamageWrapper` 步骤；输出多个 Adjust/Transfer |
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
| 组装 bag / 场景重置 | Setup / Scenario |
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
    var atom_kind: StringName    # move_card | reveal_card | transfer_marker | adjust_marker | set_flag | set_ref
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
| GAIN_RESOURCE | `AdjustMarker(RESOURCE, +n)` |
| HEAL | `AdjustMarker(DAMAGE\|HORROR, -n, clamp_min=0)` + semantic heal |
| TRANSFER_AFFLICTION | `TransferMarker(DAMAGE\|HORROR, n, A, B)` |
| DEAL_DAMAGE | `DamageWrapper` → Assign → 若干 `AdjustMarker` |
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
| OQ-PRIM-02 | `AdjustMarker` heal 是否允许超过当前 damage（浪费） | 允许；clamp 在 0，多余 delta 丢弃 |
| OQ-PRIM-03 | Engage 是否一个 `SetRef` 还是 Ref+MoveCard 两个原子 | **两个原子** Seq；Wrapper `Engage` 保证顺序 |
| OQ-PRIM-04 | 调查员 defeated 时 clues 归地点 | Wrapper：`TransferMarker` CLUES_ON_INVESTIGATOR → CLUES_ON_LOCATION |

---

## 12. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-06-18 | v0.3.2 | §0.1 **三档译法**；Prey **①** engage 内核读参（不 nest）；Spawn **②** G4；Hunter/Patrol **③** |
| 2026-06-18 | v0.3 | ③ **揭示与离散** 合并为三类 L0；AtomRevealCard（Grimoire Reveal） |
| 2026-05-25 | v0.1 | 初稿：地址模型 + 非原子清单 |
