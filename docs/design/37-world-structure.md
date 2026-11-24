# 37 — 世界结构（分类 · 键名 · 类型）

> **状态**：设计草案 v0.12 · 2026-11-24  
> **地位**：函数运算的自变量/返回值形状；与 [24](24-functional-world.md)、[30](30-functional-primer.md)、[34](34-registration-index-cache.md)、[35](35-legal-interest.md) 对齐。  
> **约定**：键名为 **snake_case 英文**（进代码）；类型用基础型：`Int` · `String` · `Bool` · `Array<T>` · `Map<K,V>` · 具名枚举。空 id 用 `""`。不用的字段可省略。  
> **token**：一律 `token_stacks`；堆键 = **实体类型**（伤/线索/混乱符号…）；不为种类另开槽；无 `mold_id` / 无 `auth.tokens` / `token_ids`。双面配对只在 Catalog，翻面在类型键间转移。  
> **on vs at**：`on` = 物理放置（区成员）；`at` = 绑定关系（登记等），不作地点放置槽名。

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
  registrations:  Map<RegId, Registration>,
  chronicle:      Chronicle,
  audience:       Map<CardId, Audience>,
  limits:         LimitStore,
  framework:      Framework,
  next_id:        Int
}
```

| 键 | 类型 | 说明 |
|---|---|---|
| `cards` | `Map<String, Card>` | 卡实体脊骨 |
| `regions` | `Map<String, Region>` | **唯一放置面**：卡序 + **token 堆** |
| `registrations` | `Map<String, Registration>` | 信息层（含交战等） |
| `chronicle` | `Chronicle` | 日志∪记住 |
| `audience` | `Map<String, Audience>` | 牌面可见档 |
| `limits` | `LimitStore` | 次数/配额；见 §1.5 |
| `framework` | `Framework` | 回合与场景/密谋游标 |
| `next_id` | `Int` | 下一分配序号（卡/区/登记） |

**不设** `auth.tokens` / 区上 `token_ids`。token **不是**带 id 的可再挂载实体。

**Token 本质**：只表示 **堆键 + 数量**；是放置的**终端**——其上不再放置卡、不再绑登记主体。即使桌上该类只有 1 枚，仍用 `token_stacks[key]=1`。双面件把当前面编进堆键，不另开个体。

卡通过 `slot_regions` 挂区。禁止 `Card.markers` / `location_id` / `engaged_with`。

---

### 1.1 `Card`（脊骨 + 槽位区指针）

```text
Card = {
  id:                       String,
  definition_id:            String,
  card_type:                CardType,
  owner_id:                 String,
  controller_id:            String,
  face:                     Face,
  exhausted:                Bool,
  display_order:            Int,
  slot_regions:             Map<String, String>,  -- 槽名 → region_id
  connections:              Array<String>,        -- 仅 location：连通图（非「放置」）
  actions_remaining:        Int,                  -- 仅 investigator：回合经济
  actions_bonus_next_turn:  Int,
  eliminated:               Bool,
  resigned:                 Bool
}
```

| 键 | 类型 | 说明 |
|---|---|---|
| `id` / `definition_id` / `card_type` | `String` / `String` / `CardType` | 身份 |
| `owner_id` / `controller_id` | `String` | 所有/控制 |
| `face` | `Face` | `"A"` \| `"B"` |
| `exhausted` | `Bool` | 横置（形态③） |
| `display_order` | `Int` | 同区展示序 |
| `slot_regions` | `Map<String, String>` | **卡拥有的区**；见下表 |
| `connections` | `Array<String>` | 地点连通（拓扑，不是区内实体） |
| `actions_*` / `eliminated` / `resigned` | `Int`/`Bool` | 调查员回合/胜负态 |

**`CardType`**：`"investigator"` \| `"asset"` \| `"event"` \| `"skill"` \| `"enemy"` \| `"treachery"` \| `"location"` \| `"act"` \| `"agenda"`

#### 推荐槽名（`slot_regions` 的键）

槽按 **放置面角色** 开，不按 token 种类开。伤/恐/线索/毁灭/资源/充能… 同进一区的 `token_stacks`，靠堆键区分。

| 槽名 | 谁有 | 区内存什么 |
|---|---|---|
| `hand` / `deck` / `discard` / `play` / `threat` | investigator | 卡 |
| `tokens` | 会承 token 的卡 | **该宿主上全部** token 堆（伤/恐/线索/毁灭/资源/充能…） |
| `on` | location | **物理放在该地点上的**调查员/敌人卡 id（放置，非绑定） |
| `attachments` / `under` / `beside` | 任意宿主 | 附着/垫下/旁置的卡 |
| `chaos` | 冒险公共 | 混乱袋（另一放置面；仍是堆） |
| `augury` / `sealed` | 公共或卡槽 | 占兆 / 封印（不同放置面，非按种类分槽） |
| `encounter_deck` / `encounter_discard` | 公共 | 卡 |

读「某卡上有多少资源」= 读 `regions[card.slot_regions["tokens"]].token_stacks["resource"]`。  
读「伤」同区 `token_stacks["damage"]`——**不要**再开 `damage`/`horror`/`resource` 槽。  
读「调查员物理在哪」= 哪个地点的 **`on`** 区的 `card_ids` 含该 id（派生索引可加速）。  
**禁止**用槽名 `at` 表示地点放置：`at` 留给绑定关系（登记查询）；`on` 才是物理放置。  
「交战」= **登记** `ENGAGEMENT`（或等价 Buff），不进 Card 字段、不进 `on`。

---

### 1.2 `Region`（卡与 token 堆的放置面）

```text
Region = {
  id:             String,
  shape:          RegionShape,
  host_card_id:   String,
  slot:           String,
  card_ids:       Array<String>,
  token_stacks:   Map<String, Int>,    -- stack_key → 数量；token 的唯一权威
  limbo_kind:     LimboKind
}
```

| 键 | 类型 | 说明 |
|---|---|---|
| `id` | `String` | 区 id |
| `shape` | `RegionShape` | `"deck"` \| `"flat"` \| `"bag"` |
| `host_card_id` | `String` | 宿主卡；公共 `""` |
| `slot` | `String` | 槽名 |
| `card_ids` | `Array<String>` | 卡序；`"deck"` 时 `[0]` 为顶 |
| `token_stacks` | `Map<String, Int>` | **全部** token（含仅 1 枚的） |
| `limbo_kind` | `LimboKind` | `""` \| `"resolving"` \| `"committed"` |

**Touched**：`region:<id>:members`（卡）与/或 `region:<id>:stack:<key>`（token 堆）。

---

### 1.2.1 Token = 实体类型键 + 数量（终端）

不在 `auth` 单列 token 表。区上的堆即全部权威：

```text
token_stacks: Map<String, Int>   -- token_type → count
```

**堆键 = 当前朝上的实体类型**。桌上只有这几种类型键；不设 `mold_id`，不拼 `dual:…` 复合串。许多「标记」直接用实体类型代替（伤/线索/毁灭 = 类型本身）。

| 类型键 | 例 |
|---|---|
| 伤/恐/线索/毁灭/资源 | `"damage"` \| `"horror"` \| `"clue"` \| `"doom"` \| `"resource"` |
| 充能等 | `"ammo"` \| `"charge:<用途>"` \| … |
| 混乱符号 | `"numeric:<mod>"` \| `"skull"` \| `"cultist"` \| `"tablet"` \| `"elder_thing"` \| `"auto_fail"` \| `"elder_sign"` \| `"bless"` \| `"curse"` |

**双面**（仅 Catalog，不进 Snapshot 键形）：某对类型互为两面，例如 `tablet` ↔ `elder_thing`。  
`Flip` = 同区（或按规则）朝上类型 `-1`、另一面类型 `+1`。权威始终是「现在朝上哪类有几枚」。

**终端性**：token 堆上不可再放卡、不可作登记 `subject` 去挂其它实体。

#### 混乱 / 占兆 / 封印（全是堆移动）

```text
chaos.token_stacks["skull"] = 2
-- 揭示：chaos "skull" -= 1 ; augury "skull" += 1
-- 封印：augury "skull" -= 1 ; sealed "skull" += 1
-- 双面翻：chaos "tablet" -= 1 ; chaos "elder_thing" += 1   （配对查 Catalog）
```

无个体 id、无晋升。同类型多枚不可区分。

#### 放置伤/线索

`PlaceToken` / `RemoveToken`：只改目标区 `token_stacks[type]`（盒装供应默认永够）。

术语：全文用 **token**。

---

### 1.3 `Registration`

```text
Registration = {
  id:              String,
  controller_id:   String,
  source_card_id:  String,
  subject:         Subject,
  lifetime:        Lifetime,
  bound_id:        String,
  buffs:           Array<Buff>
}

Subject =
  | { tag: "bound",    card_id: String }
  | { tag: "matching", filter_id: String, filter_args: Map<String, String> }

Buff = {
  buff_type:  BuffType,
  keyword:    String,
  stat:       String,
  amount:     Int,
  aspect:     String,           -- 供索引 / Deps：如 "fight" / "gate.play_card"
  payload:    Map<String, String>  -- 限制等扩展；简单情况可空
}
```

| 键 | 类型 | 说明 |
|---|---|---|
| `id` | `String` | 登记 id |
| `controller_id` | `String` | 控制者 |
| `source_card_id` | `String` | 来源卡 |
| `subject` | `Subject` | 钉死目标或动态 Matching |
| `lifetime` | `Lifetime` | 见下 |
| `bound_id` | `String` | 寿命绑定的检定/卡 id；不需要则 `""` |
| `buffs` | `Array<Buff>` | 载荷列表 |

**`Lifetime`**：`"while_in_play"` \| `"while_committed"` \| `"this_skill_test"` \| `"this_turn"` \| `"while_drawn_card_resolving"`

**`BuffType`**：`"keyword"` \| `"modifier"` \| `"restriction"` \| `"listener"` \| `"trait"` \| `"icon"` \| `"ability"`

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

混乱与其它 token 的 `stack_key`：见 §1.2.1。

---

### 1.5 `LimitStore` — 限制/配额（权威）

先前草案用 `Map<LimitId, Int>` **不够**：Grimoire 有 per round / per game / per card / group limit / Max in play 等，键必须带**周期 + 范围 + 主体**，并支持清零与封顶。

印刷规格在 Catalog（`LimitSpec`）；局面只存**已发生计数**与必要时的活跃「Max」占用。

```text
LimitStore = {
  counters:   Map<String, LimitCounter>,   -- slot_id → 计数条
  max_slots:  Map<String, MaxSlot>         -- 可选；Max N in play 类占用
}

LimitCounter = {
  slot_id:       String,       -- 稳定键，见编码
  spec_id:       String,       -- Catalog LimitSpec id / ability_id
  period:        LimitPeriod,
  scope:         LimitScope,
  subject_id:    String,       -- 按 scope：调查员 / 卡实例 / ""(group)
  used:          Int,          -- 已用次数
  cap:           Int,          -- 上限（来自 spec 快照；便于读权威）
  window_id:     String        -- 周期实例：round 号、test_id、""(game)…
}

MaxSlot = {
  slot_id:       String,       -- 如 title / exceptional 键
  kind:          MaxKind,      -- "in_play_by_title" | "committed_per_test" | …
  subject_id:    String,       -- 检定 id / "" 
  holders:       Array<String>,-- 当前占用的 card_id
  cap:           Int
}
```

**`LimitPeriod`**：`"per_round"` \| `"per_turn"` \| `"per_phase"` \| `"per_game"` \| `"per_skill_test"` \| `"while_in_play"` \| `"per_card_enter"`  

**`LimitScope`**：`"controller"` \| `"owner"` \| `"card_instance"` \| `"group"` \| `"title"`  

**`MaxKind`**：`"in_play_by_title"` \| `"committed_per_test"` \| `"other"`

#### `slot_id` 编码（权威键）

```text
slot_id = spec_id + "|" + period + "|" + scope + "|" + subject_id + "|" + window_id
```

例：

| 纸面 | `slot_id` 意象 |
|---|---|
| Joe：Limit once per round | `joe_react\|per_round\|controller\|I\|round:3` |
| Group limit once per game | `orne_act\|per_game\|group\|\|game` |
| Limit once per card（进场重置） | `ability_x\|while_in_play\|card_instance\|card:C9\|` |
| Max 1 committed per test | `max_slots`：`committed_per_test` + `test_id` → `holders` |

#### 运算

| 动作 | 写什么 |
|---|---|
| L5 检查 | 读 `counters[slot].used < cap`（无条视为 0） |
| 成功发起 / 决议记次 | `used += 1`（政策钉在 commence 或 resolve 后，见 06 OQ） |
| 新回合 / 新回合窗 | 清或作废 `period=per_round` 且 `window_id` 过期的条 |
| 卡进场 | `per_card_enter` / `while_in_play` 按实例建或重置 |
| 卡离场 | 删该 `card_instance` 条；`max_slots.holders` 移除 |
| Max in play | 进场写入 `holders`；离场移除；超 cap 则发起/进场门槛失败 |

`window_id` 与 `auth.framework.round`、`run.skill_tests[].test_id` 对齐，便于 Touched：`limit:<slot_id>`。

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
  timing_phase:   String                             -- 顶帧相位名；无则 ""
}

Focus = {
  window:                 String,   -- PlayerWindow 名或 ""
  controller_id:          String,
  open_must_ask_id:       String,   -- 无则 ""
  initiation_pool_ids:    Array<String>,
  response_pool_ids:      Array<String>
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
  ask_id:         String,
  kind:           String,           -- AskKind / ChoiceKind 名
  default_value:  String,
  candidates:     Array<String>
}

SkillTest = {
  test_id:        String,
  investigator_id:String,
  skill:          String,
  difficulty:     Int,
  committed_ids:  Array<String>,
  success:        Bool | null,
  fail_by:        Int
}
```

| 键 | 类型 | 说明 |
|---|---|---|
| `stack` | `Array<Frame>` | 手续栈；末元素为顶 |
| `open_choice` | `ChoiceState \| null` | 当前 NeedAsk |
| `skill_tests` | `Array<SkillTest>` | 检定栈 |
| `memory` | `Map<String, Map<String, String>>` | 步间指称 |
| `focus` | `Focus` | 枚举宇宙用 |
| `timing_phase` | `String` | 信封相位摘要 |

---

## 4. 依赖 / 触碰用的 `Key` 编码（与 auth 对齐）

Deps / Touched 使用同一键空间；编码进 `feasibility.deps` 的字符串，例如：

| 构造 | 编码例 | 对应权威路径 |
|---|---|---|
| 卡字段 | `card:<id>:exhausted` | `auth.cards[id].exhausted` |
| 区成员 | `region:<id>:members` | 卡序 ∪ token 堆/序的指纹 |
| token 堆 | `region:<id>:stack:damage` | `token_stacks["damage"]` |
| token 堆 | `region:<id>:stack:<key>` | `token_stacks[key]` |
| 查询指纹 | `query:enemies_on:<loc>` | 地点 `on` 区等投影 |
| 登记 | `reg:<id>` | `auth.registrations[id]` |
| 方面 | `aspect:fight` | 索引 / 多条登记 |
| 框架 | `fw:active_investigator_id` | `auth.framework…` |
| 限额 | `limit:<slot_id>` | `auth.limits…` |
| 记事 | `chron:remembered:<k>` | `auth.chronicle.remembered[k]` |
| 焦点 | `run:focus` | `run.focus` |
| 记忆 | `run:mem:<ctrl>:<k>` | `run.memory[ctrl][k]` |

读「卡上伤害」→ 宿主 `tokens` 槽区的 `token_stacks["damage"]`。禁止再依赖已废除的 `card.markers`。

---

## 5. 谁写谁读

| 分类 | 写入 | 读取 |
|---|---|---|
| `auth` | 仅 `commit(Intent[])` | 一切查询 / `legalTracked` / 投影 |
| `derived` | `transit` 末尾 `refresh*` | 交互读 feasibility；索引加速查询 |
| `run` | `step` / `answer` / `bind` | 议程、Ask、宇宙枚举 |
| `Catalog` | 装载期 | 印刷与 Eff 树 |

---

## 6. 最小实例（权威节选）

```text
Snapshot {
  gen: 1
  auth: {
    next_id: 8
    cards: {
      "I": { card_type:"investigator",
             slot_regions:{ "hand":"hand_I", "deck":"deck_I", "tokens":"tok_I", … }, … }
      "L": { card_type:"location", slot_regions:{ "on":"on_L", "tokens":"tok_L" }, connections:[], … }
    }
    regions: {
      "hand_I":  { host_card_id:"I", slot:"hand", card_ids:[], token_stacks:{}, … }
      "tok_I":   { host_card_id:"I", slot:"tokens", card_ids:[],
                   token_stacks:{ "resource":5, "damage":0, "horror":0 }, … }
      "on_L":    { host_card_id:"L", slot:"on", card_ids:["I"], token_stacks:{}, … }
      "tok_L":   { host_card_id:"L", slot:"tokens", card_ids:[], token_stacks:{ "clue":1 }, … }
      "chaos":   { host_card_id:"", slot:"chaos", shape:"bag",
                   token_stacks:{ "numeric:0": 2, "skull": 1, "auto_fail": 1 }, … }
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
