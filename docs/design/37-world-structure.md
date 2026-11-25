# 37 — 世界结构（分类 · 键名 · 类型）

> **状态**：设计草案 v0.31 · 2026-11-25  
> **地位**：函数运算的自变量/返回值形状；与 [24](24-functional-world.md)、[30](30-functional-primer.md)、[34](34-registration-index-cache.md)、[35](35-legal-interest.md) 对齐。  
> **约定**：键名为 **snake_case 英文**（进代码）；类型用基础型：`Int` · `String` · `Bool` · `Array<T>` · `Map<K,V>` · 具名枚举。空 id 用 `""`。不用的字段可省略。  
> **token**：堆只存 **类型 → 数量**；静态表含 `dual_of` 与 `represent_as`；桌面变更 **仅 Transfer**（[07 §5.2](07-effect-primitives.md)）；翻面走 `FlipToken` / seq。  
> **简洁**：权威唯一、少冗余；同质实体不因规则绰号另开放置面（封印混乱 = 宿主上的 token 堆）。  
> **on vs at**：`on` = 物理放置（区成员）；`at` = 绑定关系（登记等），不作地点放置槽名。  
> **实现**：`arkham_rules` crate（M1：`Snapshot`+`commit`；M2：`Eff`/`step`/`Nest` 抽牌）。

---

## 0. 总形

函数运算空间是整份快照，不是「只有物理」：

```text
Snapshot = {
  auth:     Auth,      -- 权威：commit 只写这里（Audience 写入但不计 CREATED）
  derived:  Derived,   -- 派生：可重建；transit 末尾刷新
  run:      Run,       -- 进度：step/answer/bind
  gen:      Int,       -- 快照代数；每次权威或焦点性 progress 变更 +1
}
```

`Catalog` **外置**，不进 `Snapshot`。印刷数字按 `definition_id` 查。

| 分类 | 判据 | 丢了 |
|---|---|---|
| **auth** | 桌上事实；重放 Intent 要还原 | 局面坏 |
| **derived** | 由 auth(+run.focus) 唯一可算 | 可 rebuild |
| **run** | 手续游标与步间指称 | 手续结束可清 |

口语「世界值」= `Snapshot`。

---

## 1. `auth` — 权威

```text
Auth = {
  cards:          Map<CardId, Card>,
  regions:        Map<RegionId, Region>,
  seats:          Map<CardId, Seat>,   -- 调查员席位态；键=调查员卡 id
  registrations:  Map<RegId, Registration>,
  gains:          Map<GainId, GainedCharacteristic>,  -- Gain 特征；≠ payloads
  chronicle:      Chronicle,
  audience:       Map<CardId, Audience>,
  limits:         LimitStore,
  framework:      Framework,
  next_id:        Int
}
```

| 键 | 类型 | 说明 |
|---|---|---|
| `cards` | `Map<String, Card>` | 卡实体脊骨（身份·控制·形态；放置只在 regions） |
| `regions` | `Map<String, Region>` | **唯一放置面**：卡序 + **token 堆** |
| `seats` | `Map<String, Seat>` | **调查员席位**：回合经济与退场/撤退；不进 Card |
| `registrations` | `Map<String, Registration>` | 信息层（含交战等 STATUS） |
| `gains` | `Map<String, GainedCharacteristic>` | Gain 特征（KEYWORD/TRAIT/ICON/ABILITY） |
| `chronicle` | `Chronicle` | 日志∪记住 |
| `audience` | `Map<String, Audience>` | 牌面可见档 |
| `limits` | `LimitStore` | 次数/配额；见 §1.5 |
| `framework` | `Framework` | 回合与场景/密谋游标 |
| `next_id` | `Int` | 下一分配序号（卡/区/登记/席位相关） |

**不设** `auth.tokens` / 区上 `token_ids`。token **不是**带 id 的可再挂载实体。

**Token 本质**：只表示 **堆键 + 数量**；是放置的**终端**——其上不再放置卡、不再绑登记主体。即使桌上该类只有 1 枚，仍用 `token_stacks[key]=1`。双面件把当前面编进堆键，不另开个体。

放置权威只在 **`regions`**（`host_card_id` + `place`）。**禁止**在 Card 再存一份 `owned_regions`（双源）。查询「某卡的 hand 区」= 扫 `regions` 中 `host_card_id=卡 ∧ place=hand`（派生索引可加速，属 `derived`）。  
**禁止**用规则术语 **slot**（资产槽 Hand/Ally/Arcane…）给区命名。禁止 `Card.markers` / `location_id` / `engaged_with`。

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

**已迁出 Card**：席位态 → `seats`；放置指针 → 仅 `regions`（旧 `owned_regions` 升 **derived**）。  
**已删**：`display_order`——同区展示序以 `Region.card_ids` 序为准。

**`CardType`**：`"investigator"` \| `"asset"` \| `"event"` \| `"skill"` \| `"enemy"` \| `"treachery"` \| `"location"` \| `"act"` \| `"agenda"`

### 1.1.1 `Seat`（调查员席位态）

每个在场（或已退场仍占座）的调查员一条；键 = 该调查员 **卡 id**（与 `cards` 中 `card_type=investigator` 对齐）。

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
| 查询 | `seats[inv_id].actions_remaining`，不读 `cards[inv]` |

`framework.active_investigator_id` / `lead_investigator_id` 仍是游标；**经济与结局**在 `seats`。

#### 推荐放置名（`Region.place`）

按 **放置面角色** 开区，不按 token 种类开。伤/恐/线索/毁灭/资源/充能/封印混乱… 同进宿主 `tokens` 的 `token_stacks`，靠堆键区分。

**`place` ≠ 规则资产槽（slot）**：Hand/Ally/Arcane/Body… 是进场占用约束，另模；不要写成 `Region.place`。

| place | 谁有 | 区内存什么 |
|---|---|---|
| `hand` / `deck` / `discard` / `play` / `threat` | investigator | 卡 |
| `tokens` | 会承 token 的卡 | **该宿主上全部** token 堆（伤/恐/线索/毁灭/资源/充能/**封印的混乱符号**…） |
| `on` | location | **物理放在该地点上的**调查员/敌人卡 id（放置，非绑定） |
| `attachments` / `under` / `beside` | 任意宿主 | 附着/垫下/旁置的卡 |
| `chaos` | 冒险公共 | 混乱袋（堆） |
| `revealed`（可选） | 公共 | 检定中已揭示、尚未归袋/封印的混乱堆（中性放置；≠ 另类 token） |
| `encounter_deck` / `encounter_discard` | 公共 | 卡 |

**不要**开 `sealed` / `augury` 专用放置面：封印在卡上的混乱与伤/线索同质——都是宿主 `tokens` 里的 `token_stacks` 键；检定揭示若需桌上堆，只用一个公共 `revealed`（术语「占兆」可作该区 **id**，不必新 place）。  
**不要**开 `token_supply` 区：运算端点 `$supply` 即可。

读「某卡上有多少资源 / 封印了几个 skull」= 该宿主 `place=tokens` 区的 `token_stacks[…]`。  
读「伤」同区——**不要**再开 `damage`/`horror`/`resource`/`sealed` 放置面。  
读「调查员物理在哪」= 哪个地点的 **`on`** 区的 `card_ids` 含该 id（派生索引可加速）。  
**禁止**用 `at` 作地点放置名：`at` 留给绑定关系；`on` 才是物理放置。  
「交战」= **登记载荷** `STATUS`/`ENGAGEMENT`，不进 Card 字段、不进 `on`。

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
-- 封印：Transfer → 宿主 tokens（与放置 resource 同形）
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

### 1.3 `Registration`

登记写入 **`payloads`（Registration 载荷）**。见 [06-registration-payload-model](06-registration-payload-model.md)。

```text
Registration = {
  id:              String,
  source_card_id:  String,
  subject:         Subject,
  lifetime:        Lifetime,
  bound_id:        String,
  payloads:        Array<RegistrationPayload>
}

Subject =
  | { tag: "bound",    card_id: String }
  | { tag: "matching", filter_id: String, filter_args: Map<String, String> }
```

| 键 | 类型 | 说明 |
|---|---|---|
| `id` | `String` | 登记 id |
| `source_card_id` | `String` | 来源卡 |
| `subject` | `Subject` | 钉死目标或动态 Matching |
| `lifetime` | `Lifetime` | 见下 |
| `bound_id` | `String` | 寿命绑定的检定/卡 id；不需要则 `""` |
| `payloads` | `Array<RegistrationPayload>` | **Registration 载荷**列表 |

**不设** `Registration.controller_id`：控制者 = `cards[source_card_id].controller_id`。

**`Lifetime`**：`"while_in_play"` \| `"while_committed"` \| `"this_skill_test"` \| `"this_turn"` \| `"while_drawn_card_resolving"`

**不是** Registration 载荷：KEYWORD/TRAIT/ICON/ABILITY 等 **Gain 特征** → 写 `auth.gains`（`seq.effect.grant`），可再衍生 payloads。

```text
GainedCharacteristic = {
  id:                 String,
  card_id:            String,
  kind:               String,   -- "keyword" | "trait" | "icon" | "ability"
  characteristic_id:  String,
  source_kind:        String,   -- "printed" | "player" | "encounter"
  lifetime:           String
}
```

---

### 1.3.1 `RegistrationPayload`（按 kind 分型）

壳上只有 **kind + 对应 body**（互斥；与实现 `RegistrationPayload` 一致）：

```text
RegistrationPayload =
  | { kind: "modifier",  modifier:  ModifierPayload }
  | { kind: "gate",      gate:      GatePayload }
  | { kind: "directive", directive: DirectivePayload }
  | { kind: "listener",  listener:  ListenerPayload }
  | { kind: "status",    status:    StatusPayload }

RegistrationKind = "modifier" | "gate" | "directive" | "listener" | "status"
```

Deps / 索引的 **aspect** 由 body **派生**（如 `modifier.stat`、`gate.kind`、`status.kind`），不在壳上另存一份。

#### `ModifierPayload`

**不分型**：域 A/B/C 与 SCALAR / CONSUME 共用**同一**载荷形（[06 §6](06-registration-payload-model.md)）。异质靠 `apply_mode` / `plan_kind` / `stat` 判别，**不要**仿 Gate/Directive 拆成多种 payload 变体。

```text
ModifierPayload = {
  stat:       String,    -- value_key / StatRef：willpower / combat / shroud / …
  op:         String,    -- "add" | "set" | …
  value:      Int,
  condition:  String,    -- 条件 id；无则 ""
  plan_kind:  String,    -- "none" | "attack_damage" | "discover" | …
  apply_mode: String     -- "scalar" | "consume_choose_one_leg" | …
}
```

| 何时读哪些键 | |
|---|---|
| `apply_mode = scalar` | `stat`/`op`/`value` 进 `compute`；`plan_kind` 应为 `"none"`（或忽略） |
| `apply_mode = consume_…` | `plan_kind` 选 AmountPlan；无名 +N 改已定效果量 |

#### `GatePayload`（拦 Intent / 合法性 · cannot）

按 **kind 分型**（同 Directive）；禁止扁平塞齐 `drawer_id`/`subject_id`/…。  
险境帧与 lasting 主体用 `GateScope` 区分（对齐 [06 §7 / §16.4](06-registration-payload-model.md)）：

```text
GatePayload =
  | { kind: "forbid_draw",            subject_id }
  | { kind: "forbid_play",            scope: GateScope }
  | { kind: "forbid_trigger",         scope: GateScope }
  | { kind: "forbid_commit_to_test",  scope: GateScope }
  | { kind: "forbid_leave_hand",      subject_id }   -- Hidden 等
  | { kind: "forbid_discover_clue",   subject_id }
  | { kind: "forbid_spend_clue",      subject_id }
  | { kind: "forbid_attack",          subject_id }   -- Aloof 等

GateScope =
  | { tag: "subject", subject_id }                                   -- lasting / 主体 cannot
  | { tag: "peril", drawer_id, drawn_card_id, encounter_frame_id }   -- 险境帧；drawer 豁免

GateKind = 上列 kind 字面量
```

#### `DirectivePayload`（原流程读取后改道 · 非 Intent 拦截）

按 **kind 分型**，禁止把全部字段摊平进一条记录（脊骨过肥）：

```text
DirectivePayload =
  | { kind: "skip_aoo",              drawer_id, drawn_card_id, subject_id }
  | { kind: "suppress_auto_engage",  subject_id }
  | { kind: "assign_constraint",     assign: AssignConstraintBody }
  | { kind: "skill_redirect",        redirect_from, redirect_to, subject_id }

AssignConstraintBody = {
  assign_op:            String,
  assign_affliction:    String,
  assign_direct_scope:  String,
  assign_expand_scope:  String,
  assign_trait:         String,
  assign_amount:        Int,
  assign_if_able:       Bool
}

DirectiveKind =
  "skip_aoo" | "suppress_auto_engage" | "assign_constraint" | "skill_redirect"
```

#### `ListenerPayload`

**不分型**：凡 LISTENER 均为「时点到 → 跑已装载 Composition」（[06 §5](06-registration-payload-model.md)）；异质在 Catalog 树，不在载荷壳。

```text
ListenerPayload = {
  timing:       String,   -- 时点 / 入口 id
  composition:  String    -- 已装载 Composition 树 id / 句柄；Snapshot 外可再解
}
```

#### `StatusPayload`（局面断言）

现仅 **交战**一种局面断言 → **单变体分型**（去掉扁平 `kind` 字符串）。若日后出现第二种 STATUS，再增变体，勿先摊平预留字段。

```text
StatusPayload =
  | { kind: "engagement", subject_id, drawer_id }
      -- subject_id = 敌人；drawer_id = 调查员

StatusKind = "engagement"   -- 目前仅此
```

交战 = `{ kind:"status", status:{ kind:"engagement", subject_id:敌人, drawer_id:调查员 } }`，不进 Card / `on`。

---

### 1.4 `Chronicle` · `Audience` · `Framework`

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
| 席位行动 / eliminated | `seats` | 已离 Card，也不进 Framework |

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

`window_id` 与 `auth.framework.round`、`run.skill_tests[].test_id` 对齐，便于 Touched：`limit:<limit_key>`。

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

值侧用 `Array<String>` 表示 id 集合（实现可换持久 Set）。均可由 `auth.registrations` 重建。

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
| CardField | `card:<id>:exhausted` | `auth.cards[id].exhausted` |
| RegionMembers | `region:<id>:members` | `regions[id].card_ids` |
| RegionStack | `region:<id>:stack:damage` | `token_stacks["damage"]` |
| QueryFp | `query:enemies_on:<loc>` | 地点 `on` 等投影 |
| Reg | `reg:<id>` | `auth.registrations[id]` |
| RegAspect | `aspect:fight` | 索引 / 多条登记 |
| SeatField | `seat:<inv>:actions_remaining` | `auth.seats[inv]…` |
| FrameworkField | `fw:active_investigator_id` | `auth.framework…` |
| LimitCounter | `limit:<limit_key>` | `auth.limits…` |
| ChronicleKey | `chron:remembered:<k>` | `auth.chronicle.remembered[k]` |
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
    cards: {
      "I": { card_type:"investigator", … }
      "L": { card_type:"location", connections:[], … }
      -- 放置只看 regions[].host_card_id + place（无 Card.owned_regions）
    }
    seats: {
      "I": { actions_remaining:3, actions_bonus_next_turn:0,
             actions_penalty_next_turn:0, eliminated:false, resigned:false }
    }
    regions: {
      "hand_I":  { host_card_id:"I", place:"hand", card_ids:[], token_stacks:{}, … }
      "tok_I":   { host_card_id:"I", place:"tokens", card_ids:[],
                   token_stacks:{ "resource":5, "damage":0, "horror":0 }, … }
      "on_L":    { host_card_id:"L", place:"on", card_ids:["I"], token_stacks:{}, … }
      "tok_L":   { host_card_id:"L", place:"tokens", card_ids:[], token_stacks:{ "clue":1 }, … }
      "chaos":   { host_card_id:"", place:"chaos", shape:"bag",
                   token_stacks:{ "numeric_0": 2, "skull": 1, "auto_fail": 1 }, … }
    }
    registrations: {}
    …
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
