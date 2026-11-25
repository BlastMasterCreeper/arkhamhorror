# 37 — 世界结构（分类 · 键名 · 类型）

> **状态**：设计草案 v0.34 · 2026-11-25  
> **地位**：函数运算的自变量/返回值形状；与 [24](24-functional-world.md)、[30](30-functional-primer.md)、[34](34-registration-index-cache.md)、[35](35-legal-interest.md) 对齐。  
> **函数世界定义**：[38-functional-data-world](38-functional-data-world.md)（`World_FP ≜ Data`；本文 `world/facts/constraints` = Data 分区表）。  

> **约定**：键名为 **snake_case 英文**（进代码）；类型用基础型：`Int` · `String` · `Bool` · `Array<T>` · `Map<K,V>` · 具名枚举。空 id 用 `""`。不用的字段可省略。  
> **token**：堆只存 **类型 → 数量**；静态表含 `dual_of` 与 `represent_as`；桌面变更 **仅 Transfer**（[07 §5.2](07-effect-primitives.md)）；翻面走 `FlipToken` / seq。  
> **简洁**：权威唯一、少冗余；同质实体不因规则绰号另开放置面（封印混乱 = 宿主上的 token 堆）。  
> **on vs at**：`on` = 物理放置（区成员）；`at` = 绑定关系（登记等），不作地点放置槽名。  
> **实现**：`arkham_rules` crate（M1：`Snapshot`+`commit`；M2：`Eff`/`step`/`Nest` 抽牌）。  
> **口径（已拍板）**：**世界 = 窄物理**；Facts/Constraints 是权威伴件不是世界；CREATED = 写入伴件（Audience 除外）。

---

## 0. 总形

**「世界」= 窄物理**；权威伴件 = **World × Facts × Constraints**（Audience 旁路；Run/Catalog 在闭包外）。  
**禁止**再把 lasting/cannot/交战称作「也在世界里」——它们分别在 Constraints / Facts。

```text
Snapshot = {
  auth:     Auth,      -- World × Facts × Constraints (+ Audience)
  derived:  Derived,   -- 派生：可重建；transit 末尾刷新
  run:      Run,       -- 进度：step/answer/bind；可含临时 as-if 叠镜
  gen:      Int
}

Auth = {
  world:         World,         -- 窄世界：物理 + 框架钟
  facts:         Facts,         -- 断言关系 · Gain · Chronicle
  constraints:   Constraints,   -- 运作叠层（Policy）
  audience:      Map<CardId, Audience>,  -- 权限旁路；不计 CREATED
  next_id:       Int
}
```

`Catalog` **外置**。内核闭包：`World × Facts × Constraints × Run × Catalog`（Audience 可读；写 Audience ≠ CREATED）。

| 袋 | 判据 | 丢了 |
|---|---|---|
| **world** | 看得见的桌上实体与席位/框架钟 | 物理局面坏 |
| **facts** | 非物理但「为真」的断言 | 交战/拥有/记住丢 |
| **constraints** | 改写 query/legal/plan/原流程的态射 | lasting/cannot/延时丢 |
| **audience** | 谁可见哪面 | 权限坏；**非**结算 |
| **derived** | 由伴件(+run.focus) 可重建 | 可 rebuild |
| **run** | 手续游标与步间指称 | 手续结束可清 |

**CREATED**（发起有效性 / L7）= dry-run 时成功写入 **World ∨ Facts ∨ Constraints ∨ Chronicle** 任一层；**Audience 除外**。纯挂 lasting/cannot/延时 = `ConstraintInsert` 成功 → 已 CREATED。  
口诀：旧「放进世界才算生效」→ **「写入权威伴件即算生效」**。

口语「快照」= `Snapshot`；口语「世界」**仅** `auth.world`（窄物理）。

---

## 1. `auth.world` — 窄世界（物理）

```text
World = {
  cards:          Map<CardId, Card>,
  regions:        Map<RegionId, Region>,
  seats:          Map<CardId, Seat>,   -- 调查员席位；键=调查员卡 id
  framework:      Framework,           -- 必要框架钟
  limits:         LimitStore           -- 次数/配额钟
}
```

| 键 | 说明 |
|---|---|
| `cards` | 卡脊骨（身份·控制·形态③）；放置只在 regions |
| `regions` | **唯一放置面**：卡序① + token 堆② |
| `seats` | 回合经济与退场/撤退 |
| `framework` | round / 主·当前调查员 / 场景·密谋游标 |
| `limits` | 次数与配额计数 |

**不设** `world.tokens` / 区上 `token_ids`。token **不是**带 id 的可再挂载实体。

**Token 本质**：只表示 **堆键 + 数量**；是放置的**终端**。

放置权威只在 **`world.regions`**（`host_card_id` + `place`）。**禁止** Card 再存 `owned_regions`。  
**禁止**用规则术语 **slot** 给区命名。禁止 `Card.markers` / `location_id` / `engaged_with`。

---

### 1.1 `Card`（脊骨）

卡脊骨只承载：**身份、所有/控制、形态③、地点连通**。  
**不**承载回合经济与退场/撤退（见 §1.1.1 `Seat`）；**不**承载放置指针。

```text
Card = {
  id:                       String,
  definition_id:            String,
  card_type:                CardType,
  owner_id:                 String,
  controller_id:            String,
  face:                     Face,
  exhausted:                Bool,
  connections:              Array<String>         -- 仅 location：连通图（非「放置」）
}
```

| 键 | 类型 | 说明 |
|---|---|---|
| `id` / `definition_id` / `card_type` | `String` / `String` / `CardType` | 身份 |
| `owner_id` / `controller_id` | `String` | 所有/控制（[24](24-functional-world.md)：不单立原语） |
| `face` | `Face` | `"A"` \| `"B"`（形态③） |
| `exhausted` | `Bool` | 横置（形态③） |
| `connections` | `Array<String>` | 地点连通（拓扑，不是区内实体） |

**已迁出 Card**：席位态 → `world.seats`；放置指针 → 仅 `world.regions`（旧 `owned_regions` 升 **derived**）。  
**已删**：`display_order`——同区展示序以 `Region.card_ids` 序为准。

**`CardType`**：`"investigator"` \| `"asset"` \| `"event"` \| `"skill"` \| `"enemy"` \| `"treachery"` \| `"location"` \| `"act"` \| `"agenda"`

### 1.1.1 `Seat`（调查员席位态 · ∈ World）

每个在场（或已退场仍占座）的调查员一条；键 = 该调查员 **卡 id**（与 `world.cards` 中 `card_type=investigator` 对齐）。

```text
Seat = {
  actions_remaining:         Int,     -- 本回合剩余行动
  actions_bonus_next_turn:   Int,     -- 下回合额外行动（跨回合；亦可日后改 Register）
  actions_penalty_next_turn: Int,     -- 下回合惩罚（与现有 InvestigatorState 对齐）
  eliminated:                Bool,
  resigned:                  Bool
}
```

键 = 调查员卡 id；**不**再存 `investigator_id` 字段（与 map 键双源）。

| 为何不在 Card | |
|---|---|
| 回合经济 | 框架/席位机，非卡形态或放置 |
| 退场/撤退 | 冒险内结局标志，与 face/exhausted/区成员正交 |
| 查询 | `world.seats[inv_id].actions_remaining`，不读 `world.cards[inv]` |

`world.framework.active_investigator_id` / `lead_investigator_id` 仍是游标；**经济与结局**在 `world.seats`。

#### 推荐放置名（`Region.place`）

按 **放置面角色** 开区，不按 token 种类开。伤/恐/线索/毁灭/充能/封印混乱… 同进宿主 `tokens` 的 `token_stacks`，靠堆键区分。  
**例外**：每位调查员的 **资源池** 是独立 `place=resource_pool` 区——**不**写进调查员卡的 `tokens`（纸面资源不放在调查员卡牌身上）。

**`place` ≠ 规则资产槽（slot）**：Hand/Ally/Arcane/Body… 是进场占用约束，另模；不要写成 `Region.place`。

| place | 谁有 | 区内存什么 |
|---|---|---|
| `hand` / `deck` / `discard` / `play` / `threat` | investigator | 卡 |
| `resource_pool` | investigator（每位一条） | **该调查员的资源池**：`token_stacks["resource"]`；**不是**卡上 token |
| `tokens` | 会承 token 的卡 | **该宿主卡上** token 堆（伤/恐/线索/毁灭/充能/**封印的混乱符号**/卡上放置的 resource…） |
| `on` | location | **物理放在该地点上的**调查员/敌人卡 id（放置，非绑定） |
| `attachments` / `under` / `beside` | 任意宿主 | 附着/垫下/旁置的卡 |
| `chaos` | 冒险公共 | 混乱袋（堆） |
| `revealed`（可选） | 公共 | 检定中已揭示、尚未归袋/封印的混乱堆（中性放置；≠ 另类 token） |
| `encounter_deck` / `encounter_discard` | 公共 | 卡 |

**不要**开 `sealed` / `augury` 专用放置面：封印在卡上的混乱与伤/线索同质——都是宿主 `tokens` 里的 `token_stacks` 键；检定揭示若需桌上堆，只用一个公共 `revealed`（术语「占兆」可作该区 **id**，不必新 place）。  
**不要**开 `token_supply` 区：运算端点 `$supply` 即可。

读「调查员资源池有多少」= 该调查员 `place=resource_pool` 区的 `token_stacks["resource"]`（**不是** `tokens`）。  
读「某卡上有多少伤 / 封印了几个 skull / 卡上放了几个 resource」= 该宿主 `place=tokens` 区的 `token_stacks[…]`。  
读「伤」同区——**不要**再开 `damage`/`horror`/`sealed` 放置面；资源池单独用 `resource_pool`。  
读「调查员物理在哪」= 哪个地点的 **`on`** 区的 `card_ids` 含该 id（派生索引可加速）。  
**禁止**用 `at` 作地点放置名：`at` 留给绑定关系；`on` 才是物理放置。  
「交战」= **Facts.Relation** `Engagement`，不进 Card 字段、不进 `on`；威胁区是 World 区成员。

#### 资源池（resource pool）——独立区；唯一源

旧 Godot `InvestigatorState.resource_pool` / 07 `MarkerSlot.RESOURCE` 在本结构中的落点：

| 口语 | 权威落点 | 不是 |
|---|---|---|
| 调查员的资源池 | **独立** `Region`：`host_card_id=调查员` · `place=resource_pool` · `token_stacks["resource"]` | **不是**调查员卡 `tokens`；**不是** `Seat` 字段；**不是** Card 标量 |
| 盒中无穷供应（gain/spend 的池端） | Intent 端点 `$supply`（`TOKEN_SUPPLY`） | **不**在 Snapshot 里存库存计数 |
| 卡上放置的 resource（支援 uses 等） | 该宿主卡 `place=tokens` 的 `token_stacks["resource"]` | 与资源池分源；勿混读 |
| 地点上的线索等 | 地点宿主 `tokens` 堆 | 同理勿开 `clues_on_location` 字段 |

`host_card_id` 只表示 **归属**（与 `hand`/`deck` 同形），**不**表示「token 放在调查员卡面上」。每位调查员恰好一条 `resource_pool` 区（例 id `pool_I`）。

读写例：

```text
读：  regions[host=I, place=resource_pool].token_stacks["resource"]
得：  TransferToken { type:"resource", n, from:"$supply", to: pool_I }
花：  TransferToken { type:"resource", n, from: pool_I, to:"$supply" }
```

对齐 [07 §5.2](07-effect-primitives.md) Transfer-only：`POOL_RESOURCE → inv.RESOURCE` / 回池；FP 里 `inv.RESOURCE` = 该席的 `resource_pool` 区，而非卡上 `tokens`。

---

### 1.2 `Region`（卡与 token 堆的放置面）

```text
Region = {
  id:             String,
  shape:          RegionShape,
  host_card_id:   String,
  place:          String,              -- 放置面角色；≠ 资产槽 slot
  card_ids:       Array<String>,
  token_stacks:   Map<String, Int>,    -- type → count；token 的唯一权威
  limbo_kind:     LimboKind
}
```

| 键 | 类型 | 说明 |
|---|---|---|
| `id` | `String` | 区 id |
| `shape` | `RegionShape` | `"deck"` \| `"flat"` \| `"bag"` |
| `host_card_id` | `String` | 宿主卡；公共 `""` |
| `place` | `String` | 放置面角色；**不是**资产槽 |
| `card_ids` | `Array<String>` | 卡序；`"deck"` 时 `[0]` 为顶 |
| `token_stacks` | `Map<String, Int>` | **全部** token（含仅 1 枚的） |
| `limbo_kind` | `LimboKind` | `""` \| `"resolving"` \| `"committed"` |

**Touched**：`region:<id>:members`（卡）与/或 `region:<id>:stack:<key>`（token 堆）。

---

### 1.2.1 Token = 类型 + 数量（终端）

不在 `auth` 单列 token 表。区上的堆即全部权威：

```text
token_stacks: Map<String, Int>   -- type → count
```

**桌上只此二事**：类型、数量。键就是类型名，不拼复合串、不设 `mold_id`。许多标记直接用实体类型（伤/线索/毁灭…）本身当类型。

| 类型（例） | |
|---|---|
| 伤/恐/线索/毁灭/资源 | `damage` · `horror` · `clue` · `doom` · `resource` |
| 充能 | `ammo` · `charge` · … |
| 混乱 | `numeric_0` · `skull` · `cultist` · `tablet` · `elder_thing` · `auto_fail` · `elder_sign` · `bless` · `curse` |

#### 静态关系表（外置 · 不进 Snapshot）

双面、原类型、代表类型**不**编码进堆键；用静态字段维护（可挂 Catalog / 常量表）：

```text
TokenTypeStatic = {
  dual_of:      Map<String, String>,  -- type → 另一面（对称；仅有双面的类型）
  represent_as: Map<String, String>   -- 原类型 → 代表实体类型（例 ammo → resource）
}
```

只留 **一个** 替代映射：`represent_as`（原 → 实体代表）。需要反查时对这张表扫描/建临时索引，不在静态稿里再存一份 `original_of`。  
堆键仍记**原类型**；`represent_as` 只说明盒中用哪类实体筹码表现/取用（常为 `resource`）。  
**`dual_of`**：另一轴——特定混乱符号互为两面；与替代无关。

#### 翻面 = 专用 seq / 运算

`seq.effect.flip_token`（名可再定）：查 `dual_of[type]` → 目标区 `stacks[type]-=n`、`stacks[other]+=n`。  
**不是**键形的一部分；放置/移动/揭示不必懂双面。

#### 混乱 / 揭示 / 封印（仍是堆 · Transfer）

```text
chaos.token_stacks["skull"] = 2
-- 揭示：Transfer chaos → revealed（或规则指定宿主）
-- 封印：Transfer → 宿主 tokens（与放置伤/线索同形；≠ 资源池区）
-- 翻面：FlipToken / flip seq（查 dual_of）
```

无个体 id。同类型多枚不可区分。**封印不是新实体种类，也不是新放置面。**

#### 放置伤/线索 = Transfer（禁止 Adjust）

对齐 [07 §5.2](07-effect-primitives.md)：桌面 token **唯一**权威写法 = **1 源 → 1 目标** 的 `TransferToken`。  
**禁止**单端 `AdjustToken` / 虚无 delta（已废止的 `AtomAdjustMarker`）。

| 语义 | Intent |
|---|---|
| 放置 / deal | `TransferToken { type, n, from: "$supply", to: bearer_tokens }` |
| 治愈 / 回池 | `TransferToken { …, from: bearer_tokens, to: "$supply" }` |
| 再分配 / 发现线索 | 承载区 → 承载区（仍 1→1） |

`$supply`（常量 `TOKEN_SUPPLY`）：无穷供给端点——**取出永不因库存失败**；**回池不累加**库存计数。可不建真实 `Region` 行。  
运算端点 `$supply`；**不**另建 `token_supply` 区。

术语：全文用 **token**。

---

### 1.3 `Facts` — 断言伴件

```text
Facts = {
  relations:  Map<RelId, Relation>,
  gains:      Map<GainId, GainedCharacteristic>,
  chronicle:  Chronicle
}

InfoShell = {
  id, source_card_id, subject, lifetime, bound_id
}

Subject =
  | { tag: "bound",    card_id: String }
  | { tag: "matching", filter_id: String, filter_args: Map<String, String> }

Relation = { shell: InfoShell, body: RelationBody }

RelationBody =
  | { kind: "engagement", enemy_id, investigator_id }
```

**Lifetime**：`"while_in_play"` \| `"while_committed"` \| `"this_skill_test"` \| `"this_turn"` \| `"while_drawn_card_resolving"`

控制者 = `world.cards[source_card_id].controller_id`（壳上不另存）。

#### 交战（默认）

| 情况 | 落点 |
|---|---|
| 真实交战 / lasting **视为交战** | `Facts.relations` · `Engagement`（CREATED） |
| 威胁区成员 | `World.regions`（物理）；**不等于**交战 |
| **庞大**虚拟交战 | **派生默认**：Massive∧未横置∧同地点 → 查询；**不**默认物化 Relation（**待裁 A**） |
| 手续内临时 as if | **Run 叠镜**默认（**待裁 B**）；非存档 Fact |

`is_engaged_with` 读 Relations；庞大虚拟另径。Fight 转嫁等仍按威胁区前提（08 §6.6）。

**待裁（交战相关 · 不挡本版）**

| 代号 | 问题 | 本版默认 |
|---|---|---|
| **A** | 庞大虚拟：纯派生 vs 物化 Relation | 纯派生（`is_massive_virtually_engaged`） |
| **B** | 手续内 as if：Run 叠镜 vs 短命 Relation | Run 叠镜 |
| **C** | 部分「视为」是否 scoped Relation | 暂一律全布尔 Engagement；译卡前再问 |
| **D** | 统一 `is_engaged_with` 是否并入庞大析取 | API 分径；总公式待裁 |


#### Gain

```text
GainedCharacteristic = {
  id, card_id, kind, characteristic_id, source_kind, lifetime
}
```

拥有标记 ∈ Facts；行为 keyword 可**衍生** Constraints.Policy。见 [06](06-registration-payload-model.md)。

#### Chronicle

薄：`log` ∪ `remembered`。写入计 CREATED；无 Policy 消费代数。

---

### 1.3.1 `Constraints` — 运作叠层

```text
Constraints = {
  policies: Map<PolId, Policy>
}

Policy = { shell: InfoShell, body: PolicyBody }

PolicyBody =
  | { kind: "fold_stat",    fold: ModifierPayload }      -- 查询站 fold
  | { kind: "guard_intent", gate: GatePayload }          -- cannot / Eligibility
  | { kind: "divert_flow",  divert: DirectivePayload }   -- 原流程读后改道
  | { kind: "on_timing",    on_timing: ListenerPayload } -- 时点 → Composition
```

Deps / 索引 aspect 由 body **派生**。对照旧五类：modifier/gate/directive/listener → 上表四变体；**status 升格为 Facts.Relation，不再是 Policy**。消费细节仍对齐 [06](06-registration-payload-model.md)。

#### `ModifierPayload`（FoldStat 体）

**不分型**：域 A/B/C 与 SCALAR / CONSUME 共用同一形。异质靠 `apply_mode` / `plan_kind` / `stat`。

```text
ModifierPayload = {
  stat, op, value, condition, plan_kind, apply_mode
}
```

#### `GatePayload`（GuardIntent 体）

```text
GatePayload =
  | { kind: "forbid_draw",            subject_id }
  | { kind: "forbid_play",            scope: GateScope }
  | { kind: "forbid_trigger",         scope: GateScope }
  | { kind: "forbid_commit_to_test",  scope: GateScope }
  | { kind: "forbid_leave_hand",      subject_id }
  | { kind: "forbid_discover_clue",   subject_id }
  | { kind: "forbid_spend_clue",      subject_id }
  | { kind: "forbid_attack",          subject_id }

GateScope =
  | { tag: "subject", subject_id }
  | { tag: "peril", drawer_id, drawn_card_id, encounter_frame_id }
```

#### `DirectivePayload`（DivertFlow 体）

```text
DirectivePayload =
  | { kind: "skip_aoo",              drawer_id, drawn_card_id, subject_id }
  | { kind: "suppress_auto_engage",  subject_id }
  | { kind: "assign_constraint",     assign: AssignConstraintBody }
  | { kind: "skill_redirect",        redirect_from, redirect_to, subject_id }
```

#### `ListenerPayload`（OnTiming 体）

```text
ListenerPayload = { timing, composition }
```

印刷 Forced/反应仍是 AbilitySpec，**不是** OnTiming。

结算 Intent：`FactInsert` / `ConstraintInsert` / `CompanionRemove`（+ 物理族）。**不**按 Policy 种拆 `seq.effect.*`。

---

### 1.4 `Audience` · `Framework`（Framework/Limits 在 World）

```text
Chronicle = {
  log:         Array<LogEntry>,
  remembered:  Map<String, String>
}
LogEntry = { text: String, round: Int }

Audience = "hidden_all" | "controller" | "all"

Framework = {
  round:                   Int,
  lead_investigator_id:    String,
  active_investigator_id:  String,
  current_act_id:          String,
  current_agenda_id:       String
}
```

**精简集**：只保留存档仍有意义、且**不是**区成员 / Catalog / Run 游标的局面级指针。

| 不进 Framework | 落点 | 理由 |
|---|---|---|
| `act_deck` / `agenda_deck` | `regions`（公共牌库） | 区/序原语，勿在框架再存一份 |
| `doom_threshold` | Catalog（当前密谋 definition） | 印刷规格外置 |
| `scenario_reference_id` | 冒险装载 / Catalog 绑定 | 非回合游标；需要时另字段，不塞 Framework |
| `phase_id`（Mythos/Action…） | `run.timing_phase` | 执行信封相位；手续内临时步更在 `Run.stack` |
| 席位行动 / eliminated | `world.seats` | 已离 Card，也不进 Framework |

混乱与其它 token 的 `stack_key`：见 §1.2.1。

---

### 1.5 `LimitStore` — 限制/配额（权威）

先前草案用 `Map<LimitId, Int>` **不够**：Grimoire 有 per round / per game / per card / group limit / Max in play 等，键必须带**周期 + 范围 + 主体**，并支持清零与封顶。

印刷规格在 Catalog（`LimitSpec`）；局面只存**已发生计数**与必要时的活跃「Max」占用。

```text
LimitStore = {
  counters:     Map<String, LimitCounter>,  -- limit_key → 计数条
  occupancies:  Map<String, Occupancy>      -- 可选；Max N in play 类占用
}

LimitCounter = {
  limit_key:     String,       -- 稳定键，见编码（≠ 规则资产槽 slot）
  spec_id:       String,       -- Catalog LimitSpec id / ability_id
  period:        LimitPeriod,
  scope:         LimitScope,
  subject_id:    String,       -- 按 scope：调查员 / 卡实例 / ""(group)
  used:          Int,          -- 已用次数
  cap:           Int,          -- 上限（来自 spec 快照；便于读权威）
  window_id:     String        -- 周期实例：round 号、test_id、""(game)…
}

Occupancy = {
  limit_key:     String,       -- 如 title / exceptional 键
  kind:          MaxKind,      -- "in_play_by_title" | "committed_per_test" | …
  subject_id:    String,       -- 检定 id / "" 
  holders:       Array<String>,-- 当前占用的 card_id
  cap:           Int
}
```

**命名**：限额键用 `limit_key` / 表名 `occupancies`，**禁止**再用 `slot_id`/`max_slots`——`slot` 已留给规则资产槽（Hand/Ally…）；放置面用 `place`。

**`LimitPeriod`**：`"per_round"` \| `"per_turn"` \| `"per_phase"` \| `"per_game"` \| `"per_skill_test"` \| `"while_in_play"` \| `"per_card_enter"`  

**`LimitScope`**：`"controller"` \| `"owner"` \| `"card_instance"` \| `"group"` \| `"title"`  

**`MaxKind`**：`"in_play_by_title"` \| `"committed_per_test"` \| `"other"`

#### `limit_key` 编码（权威键）

```text
limit_key = spec_id + "|" + period + "|" + scope + "|" + subject_id + "|" + window_id
```

例：

| 纸面 | `limit_key` 意象 |
|---|---|
| Joe：Limit once per round | `joe_react\|per_round\|controller\|I\|round:3` |
| Group limit once per game | `orne_act\|per_game\|group\|\|game` |
| Limit once per card（进场重置） | `ability_x\|while_in_play\|card_instance\|card:C9\|` |
| Max 1 committed per test | `occupancies`：`committed_per_test` + `test_id` → `holders` |

#### 运算

| 动作 | 写什么 |
|---|---|
| L5 检查 | 读 `counters[key].used < cap`（无条视为 0） |
| 成功发起 / 决议记次 | `used += 1`（政策钉在 commence 或 resolve 后，见 06 OQ） |
| 新回合 / 新回合窗 | 清或作废 `period=per_round` 且 `window_id` 过期的条 |
| 卡进场 | `per_card_enter` / `while_in_play` 按实例建或重置 |
| 卡离场 | 删该 `card_instance` 条；`occupancies.holders` 移除 |
| Max in play | 进场写入 `holders`；离场移除；超 cap 则发起/进场门槛失败 |

`window_id` 与 `world.framework.round`、`run.skill_tests[].test_id` 对齐，便于 Touched：`limit:<limit_key>`。

**不做**：把 Limit 规格正文存进局面；用单个全局 `Int` 糊所有能力。

---

## 2. `derived` — 派生

```text
Derived = {
  index:         RegIndex,
  feasibility:   Feasibility
}
```

### 2.1 `RegIndex`

```text
RegIndex = {
  by_bound:             Map<String, Array<String>>,           -- card_id → reg_ids
  by_aspect:            Map<String, Array<String>>,           -- aspect → reg_ids
  by_bound_aspect:      Map<String, Array<String>>,           -- "card_id\\taspect" → reg_ids
  matching_by_aspect:   Map<String, Array<String>>,
  by_source:            Map<String, Array<String>>            -- source_card_id → reg_ids
}
```

值侧用 `Array<String>` 表示 id 集合（实现可换持久 Set）。均可由 `facts.relations` ∪ `constraints.policies` 重建。

### 2.2 `Feasibility`（Φ）

```text
Feasibility = {
  focus_fp:   String,                         -- 焦点指纹（与 run.focus 对齐）
  answers:    Map<String, LegalAnswer>,       -- op_id → 答案
  deps:       Map<String, Array<String>>,     -- op_id → Key 编码串列表
  reverse:    Map<String, Array<String>>      -- Key 编码 → op_ids
}

LegalAnswer = {
  data_ok:    Bool,
  effect_ok:  Bool
}
```

| 键 | 类型 | 说明 |
|---|---|---|
| `focus_fp` | `String` | 当前宇宙焦点戳 |
| `answers` | `Map<String, LegalAnswer>` | 发起/must 绑定的可行性 |
| `deps` | `Map<String, Array<String>>` | 依赖集（Key 的稳定编码） |
| `reverse` | `Map<String, Array<String>>` | 倒排 |

`legal = data_ok ∧ effect_ok`。算 `legalTracked` 时**禁止**读 `answers`。

---

## 3. `run` — 进度

```text
Run = {
  stack:          Array<Frame>,
  open_choice:    ChoiceState | null,
  skill_tests:    Array<SkillTest>,
  memory:         Map<String, Map<String, String>>,  -- controller_id → (key → value)
  focus:          Focus,
  timing_phase:   String                             -- 信封相位摘要（Mythos/Action…）；无则 ""
}

Focus = {
  window:                 String,   -- PlayerWindow 名或 ""
  controller_id:          String,
  open_must_ask_id:       String,   -- 无则 ""；≠ open_choice
  initiation_pool_ids:    Array<String>,  -- InitiationPool 粘性成员（16）
  response_pool_ids:      Array<String>   -- ResponsePool 粘性成员（16）
}

Frame = {
  flow_id:        String,
  env:            Map<String, String>,
  step_index:     Int,
  cancelled:      Bool,
  created:        Bool,
  cont_after:     String            -- 续算句柄/编码；实现可换
}

ChoiceState = {
  ask_id:         String,           -- = ChoiceRequest.prompt_id
  kind:           String,           -- ChoiceKind 名
  controller_id:  String,           -- decider（谁确认）
  bind_key:       String,           -- 答案写入 run.memory[controller][bind_key]
  default_value:  String,           -- 逾期默认（有限期确认；16 §3.1）
  candidates:     Array<String>     -- 选项 id / 实体 id
}

SkillTest = {
  test_id:         String,
  investigator_id: String,
  skill:           String,
  difficulty:      Int,
  committed_ids:   Array<String>,   -- Run 索引；与区成员同步（见下）
  st_step:         String,          -- "st1"…"st8"；未开则 ""
  success:         Bool | null,     -- ST.6 前为 null
  fail_by:         Int              -- ST.6 后有意义；此前 0
}
```

| 键 | 类型 | 说明 |
|---|---|---|
| `stack` | `Array<Frame>` | 手续栈；末元素为顶 |
| `open_choice` | `ChoiceState \| null` | 效果体内 **有限期确认**（PI）；与 Focus.must 正交；NeedAsk 时写入 |
| `skill_tests` | `Array<SkillTest>` | 检定栈（可嵌套） |
| `memory` | `Map<String, Map<String, String>>` | 步间指称（含险境 frame id 等）；**不**另开 encounter_frames 袋 |
| `focus` | `Focus` | Φ 宇宙焦点（[35](35-legal-interest.md)） |
| `timing_phase` | `String` | 信封相位摘要；**不是** Frame 内 ST/RESOLVE 微步 |

#### Frame / ChoiceState / SkillTest 字段边界

| 保留 | 理由 |
|---|---|
| Frame.`cancelled` / `created` | Cancel 剪枝；发起 CREATED（07） |
| Frame.`cont_after` | 续算句柄；**不**常驻整棵 Eff |
| ChoiceState.`controller_id` / `bind_key` / `default_value` | 对齐 Ask + [16](16-player-interaction.md) 有限期确认 |
| SkillTest.`st_step` | ST.1–8 游标（独立于 Framework / `timing_phase`） |
| SkillTest.`committed_ids` | 本次检定投入索引（[04](04-skill-test-engine.md)） |

| 不进这些记录 | 落点 |
|---|---|
| Choice `deadline_ms` / UI prompt 文案 | **驱动层**（不纯）；结果进 answer |
| SkillTest 回调 / `modifier_breakdown` | Catalog plan / 查询重算；勿存权威 |
| SkillTest `revealed_tokens` 个体表 | 公共 `revealed` 堆 +/或检定帧记忆；勿第二套 token 个体 |
| Frame.`phase`（Would/When/…） | Catalog 步表 + `step_index` |

**投入区**：纸面裁决 OQ-01-03 为 commit 后仍 HAND 至 ST.8；`Region.limbo_kind=committed` 若用于投入，须与 01/04 **另轮统一**——本版 `committed_ids` 只保证 Run 索引与区成员可对拍。

#### Focus / Run 精简边界

| 保留 | 理由 |
|---|---|
| `focus.window` / `controller_id` / `open_must_ask_id` | 换宇宙键；`stepFocus` 触发 Φ 重建 |
| `initiation_pool_ids` / `response_pool_ids` | **粘性池**权威成员（16）；非 auth 派生缓存，属 Run |
| `open_choice` | 中途 Ask；可与 must 并存但语义不同 |
| `timing_phase` | 存档级信封相位；微步只在 `stack[].step_index` |

| 不进 Run | 落点 |
|---|---|
| `memory.cancelled_keys` / `encounter_frames` 专用袋（24 旧） | `memory` 扁平键 或 Gate/Frame.env |
| Frame.`phase`（Would/When/…） | 由 `flow_id`+`step_index` / Catalog 步表表达；勿与 `timing_phase` 双写 |
| 完整 `cont: Eff` 树常驻 | `cont_after` 句柄；树在 Catalog / 续算外置 |
| 池的可行性答案 | `derived.feasibility`（禁止派生喂派生） |

---

## 4. 依赖 / 触碰用的 `Key`（封闭代数 · 与 [35](35-legal-interest.md) 对齐）

Deps / Touched **同一**键空间；编码进 `feasibility.deps` 的字符串。禁止未登记键；禁止读 `feasibility.answers`。

```text
Key =
  | CardField(card_id, field)       -- face / exhausted / …（禁止 location_id / engaged_with）
  | RegionMembers(region_id)        -- 卡序容器
  | RegionStack(region_id, type)    -- token 堆（替代旧 Marker(card, kind)）
  | QueryFp(query_id, args_fp)      -- enemies_on(L) / hand(I)…
  | Reg(reg_id)
  | RegAspect(aspect)               -- fight / gate.play / …
  | SeatField(inv_id, field)        -- actions_remaining / eliminated / …
  | FrameworkField(name)
  | LimitCounter(limit_key)
  | ChronicleKey(name)
  | RunFocus
  | RunMemory(controller, mem_key)
  | RunSkillTest(test_id, field)    -- 读 success / difficulty / committed 时
  | RunChoice                       -- 读 open_choice 时
```

| 构造 | 编码例 | 权威路径 |
|---|---|---|
| CardField | `card:<id>:exhausted` | `world.cards[id].exhausted` |
| RegionMembers | `region:<id>:members` | `regions[id].card_ids` |
| RegionStack | `region:<id>:stack:damage` | `token_stacks["damage"]` |
| QueryFp | `query:enemies_on:<loc>` | 地点 `on` 等投影 |
| Reg | `reg:<id>` | `facts.relations[id]` 或 `constraints.policies[id]` |
| RegAspect | `aspect:fight` | 索引 / 多条登记 |
| SeatField | `seat:<inv>:actions_remaining` | `world.seats[inv]…` |
| FrameworkField | `fw:active_investigator_id` | `world.framework…` |
| LimitCounter | `limit:<limit_key>` | `world.limits…` |
| ChronicleKey | `chron:remembered:<k>` | `facts.chronicle.remembered[k]` |
| RunFocus | `run:focus` | `run.focus` |
| RunMemory | `run:mem:<ctrl>:<k>` | `run.memory[ctrl][k]` |
| RunSkillTest | `run:st:<test_id>:success` | `run.skill_tests[…]` |
| RunChoice | `run:choice` | `run.open_choice` |

读「卡上伤害」→ `RegionStack`（宿主 `tokens` 区），**禁止**已废的 `card.markers` / `Marker(card,…)`。  
读「交战」→ `Reg` / `RegAspect`（STATUS），**禁止** `CardField(…, engaged_with)`。  
读「所在地点」→ 含该 id 的 `on` 区之 `RegionMembers` 或 `QueryFp`，**禁止** `CardField(…, location_id)`。

---

## 5. 谁写谁读

| 分类 | 写入 | 读取 |
|---|---|---|
| `auth` | 仅 `commit(Intent[])` | 一切查询 / `legalTracked` / 投影 |
| `derived` | `transit` 末尾 `refresh*` | 交互读 feasibility；索引加速查询 |
| `run` | `step` / `answer` / `bind` | 议程、Ask、宇宙枚举 |
| `Catalog` | 装载期 | 印刷、Eff 树、`TokenTypeStatic` |

---

## 5.1 `Intent`（权威唯一写法 · M1 子集）

```text
Intent =
  | TransferToken { token_type, amount, from_region, to_region }
      -- amount>0；`$supply` = 无穷池端（07 Transfer）
  | FlipToken   { region_id, from_type, to_type, n } -- 同区双面键重标；查 Catalog.dual_of
  | MoveCard    { card_id, from_region, to_region }
  | RegInsert   { registration }
  | RegRemove   { reg_id }
  | SetExhausted{ card_id, exhausted }
  | SetSeatActions { investigator_id, actions_remaining }
  | SetSeatOutcome { investigator_id, eliminated?, resigned? }
  | FactInsert { relation }            -- Facts.relations；CREATED
  | ConstraintInsert { policy }        -- Constraints.policies；CREATED
  | CompanionRemove { id }
  -- 后续：GainInsert/Remove、AudienceSet、LimitBump、FrameworkSet…
  -- 禁止：AdjustToken / 单端 delta
```

`commit(Snapshot, Intent[]) → Snapshot'`：顺序应用；任一条失败则整批拒绝（M1）；成功则 `gen += 1`。  
实现：`arkham_rules::commit`。

---

## 6. 最小实例（权威节选）

```text
Snapshot {
  gen: 1
  auth: {
    next_id: 8
    world: {
      cards: { "I": { card_type:"investigator", … }, "L": { … } }
      seats: { "I": { actions_remaining:3, … } }
      regions: {
        "hand_I":  { host_card_id:"I", place:"hand", … }
        "pool_I":  { host_card_id:"I", place:"resource_pool",
                     token_stacks:{ "resource":5 }, … }
        "tok_I":   { host_card_id:"I", place:"tokens",
                     token_stacks:{ "damage":0, "horror":0 }, … }
        "on_L":    { host_card_id:"L", place:"on", card_ids:["I"], … }
        "tok_L":   { host_card_id:"L", place:"tokens", token_stacks:{ "clue":1 }, … }
        "chaos":   { place:"chaos", shape:"bag", token_stacks:{ … }, … }
      }
      framework: { round:1, lead_investigator_id:"I", … }
      limits: { counters:{}, occupancies:{} }
    }
    facts: { relations:{}, gains:{}, chronicle:{ log:[], remembered:{} } }
    constraints: { policies:{} }
    audience: { … }
  }
  derived: { … }
  run: { … }
}
```

---

## 7. 修订

| 日期 | 说明 |
|---|---|
| 2026-11-24 | v0.1：Snapshot=auth/derived/run；全键名与基础类型；Key 编码表 |
| 2026-11-24 | v0.2：`limits` 升为 `LimitStore`（period/scope/subject/window + MaxSlot） |
| 2026-11-24 | v0.3：token 命名；Region 放卡+token；Card.slot_regions；废 markers/location_id/engaged_with 字段；混乱袋为区 |
| 2026-11-24 | v0.4：标明 `token_supply` 区为放置原子来源池；与 `auth.tokens` 个体表分流 |
| 2026-11-24 | v0.5：混乱袋默认 `token_stacks` 多重集；揭示/封印才晋升个体 |
| 2026-11-24 | v0.6：双面 token：`faces`+`face`，有效类型为投影；堆键含朝向或走个体 |
| 2026-11-24 | v0.7：token 一律堆（类型+数量）；废 auth.tokens/token_ids；双面按面分堆；token 为放置终端 |
| 2026-11-24 | v0.8：有朝向统一为 `faced:<mold>:<face>` + Catalog `MoldSpec`；面数任意（双面/骰子/…）；`Reorient` 为键间转移 |
| 2026-11-24 | v0.9：收回多面泛化；本游戏仅双面 `dual:<mold>:<A\|B>`；多面标记物留待后需再扩 |
| 2026-11-24 | v0.10：不为 token 种类分槽；宿主统一 `tokens` 区，种类只走 `token_stacks` 键 |
| 2026-11-24 | v0.11：地点放置槽 `at`→`on`（物理放置）；`at` 保留给绑定关系语义 |
| 2026-11-24 | v0.12：废 `mold_id`/`dual:` 复合键；堆键仅为实体类型；双面配对只在 Catalog |
| 2026-11-24 | v0.13：堆仅 type→count；双面/原类型/代表类型用静态表；翻面专用 seq |
| 2026-11-24 | v0.14：标明 `represent_as` = 有限实体标记替代（非 dual 逆表）；堆键仍用原类型 |
| 2026-11-24 | v0.15：去掉 `original_of`；替代关系只保留 `represent_as` 单向 |
| 2026-11-24 | v0.16：Registration 去掉 `controller_id`；自 `source_card_id` 解引用 |
| 2026-11-24 | v0.17：Registration 字段为 `payloads` / `RegistrationKind` |
| 2026-11-24 | v0.18：合入 registration-payload；术语/06 文件名与载荷口径对齐 |
| 2026-11-24 | v0.19：正文去掉已弃用俗称残留 |
| 2026-11-24 | v0.20：`Region.slot`/`slot_regions` → `place`/`owned_regions`；slot 留给规则资产槽 |
| 2026-11-24 | v0.21：补全 `RegistrationPayload` 分型及五类 body 字段 |
| 2026-11-25 | v0.22：`auth.gains`；Intent M1 子集；`arkham_rules` Snapshot+commit 骨架 |
| 2026-11-25 | v0.23：M2 Eff 子集（Do/Seq/If/Nest/Ask）+ 抽牌 Flow；primer Intent 改 AdjustToken |
| 2026-11-25 | v0.24：席位态离 Card → `auth.seats`；删 Card.display_order（序=区 card_ids） |
| 2026-11-25 | v0.25：Seat 补 `actions_penalty_next_turn`；LimitStore `slot_id`/`max_slots`→`limit_key`/`occupancies`（slot 留给资产槽）；例中混乱键统一 `numeric_0` |
| 2026-11-25 | v0.26：废 `AdjustToken`→`TransferToken`+`$supply`（对齐 07 Transfer-only）；`DirectivePayload` 按 kind 分型收瘦 |
| 2026-11-25 | v0.27：`GatePayload` 按 kind 分型 + `GateScope`（subject｜peril）；24 W2 对齐 auth 扁平物理 |
| 2026-11-25 | v0.28：Framework 钉五字段精简集（排除 deck/threshold/phase）；ModifierPayload **明确不分型** |
| 2026-11-25 | v0.29：Run/Focus 精简边界；Listener 不分型；StatusPayload 单变体 `engagement`；24 Run 对齐 |
| 2026-11-25 | v0.30：ChoiceState 对齐 Ask；SkillTest+`st_step`；Key 封闭代数对拍 35（RegionStack/Seat/RunST） |
| 2026-11-25 | v0.31：无冗余 — 废 Card.owned_regions/Seat.investigator_id；封印并入宿主 tokens；去掉 sealed/augury/token_supply 放置名 |
| 2026-11-25 | v0.32：标明 resource pool = 宿主 `tokens` 的 `resource` 堆 + `$supply`；非 Seat/独立区 |
| 2026-11-25 | v0.33：纠正 — 资源池 = 独立 `place=resource_pool` 区（非调查员卡 `tokens`）；卡上 resource 仍走 `tokens` |
