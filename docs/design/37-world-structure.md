# 37 — 世界结构（分类 · 键名 · 类型）

> **状态**：设计草案 v0.1 · 2026-11-24  
> **地位**：函数运算的自变量/返回值形状；与 [24](24-functional-world.md)、[30](30-functional-primer.md)、[34](34-registration-index-cache.md)、[35](35-legal-interest.md) 对齐。  
> **约定**：键名为 **snake_case 英文**（进代码）；类型用基础型：`Int` · `String` · `Bool` · `Array<T>` · `Map<K,V>` · 具名枚举。空 id 用 `""`。不用的字段可省略。

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
  limits:         Map<LimitId, Int>,
  framework:      Framework,
  chaos_bag:      Array<ChaosToken>,
  next_id:        Int
}
```

| 键 | 类型 | 说明 |
|---|---|---|
| `cards` | `Map<String, Card>` | 一切实体：调查员/地点/敌人/支援… |
| `regions` | `Map<String, Region>` | 区：牌库、手牌、场、威胁、遭遇库… |
| `registrations` | `Map<String, Registration>` | 信息层登记 |
| `chronicle` | `Chronicle` | 日志∪记住 |
| `audience` | `Map<String, Audience>` | 牌面可见档 |
| `limits` | `Map<String, Int>` | 能力已用次数；键为 limit/ability id |
| `framework` | `Framework` | 回合与当前场景/密谋游标 |
| `chaos_bag` | `Array<ChaosToken>` | 袋内剩余标记（序有意义） |
| `next_id` | `Int` | 下一分配序号，只增不减 |

`CardId` / `RegionId` / `RegId` / `LimitId` 均为 `String`。

---

### 1.1 `Card`

统一卡记录；某 `card_type` 不用的键省略。

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
  markers:                  Map<String, Int>,
  location_id:              String,              -- investigator / enemy
  engaged_with:             String,              -- enemy → investigator；未交战 ""
  connections:              Array<String>,       -- location → location ids
  region_ids:               Map<String, String>, -- investigator → 逻辑区名 → region_id
  actions_remaining:        Int,                 -- investigator
  actions_bonus_next_turn:  Int,
  eliminated:               Bool,
  resigned:                 Bool
}
```

| 键 | 类型 | 说明 |
|---|---|---|
| `id` | `String` | 卡实例 id |
| `definition_id` | `String` | 目录键 |
| `card_type` | `CardType` | 见下枚举 |
| `owner_id` | `String` | 所有者；公共 `""`；遭遇侧常用 `"encounter"` |
| `controller_id` | `String` | 控制者卡 id |
| `face` | `Face` | `"A"` \| `"B"` |
| `exhausted` | `Bool` | 是否横置 |
| `display_order` | `Int` | 同区展示序 |
| `markers` | `Map<String, Int>` | 标记；0 可省略键 |
| `location_id` | `String` | 所在地点卡 id |
| `engaged_with` | `String` | 交战对象 |
| `connections` | `Array<String>` | 地点连接 |
| `region_ids` | `Map<String, String>` | 键：`"hand"`\|`"deck"`\|`"discard"`\|`"play"`\|`"threat"`… |
| `actions_remaining` | `Int` | 剩余行动 |
| `actions_bonus_next_turn` | `Int` | 下回合额外行动 |
| `eliminated` | `Bool` | 已消灭 |
| `resigned` | `Bool` | 已撤退 |

**`CardType`**：`"investigator"` \| `"asset"` \| `"event"` \| `"skill"` \| `"enemy"` \| `"treachery"` \| `"location"` \| `"act"` \| `"agenda"`

**`markers` 常用键**：`"damage"` \| `"horror"` \| `"doom"` \| `"clue"` \| `"resource"` \| 充能用途字符串；值 `Int`。

---

### 1.2 `Region`

```text
Region = {
  id:          String,
  shape:       RegionShape,
  owner_id:    String,
  card_ids:    Array<String>,
  limbo_kind:  LimboKind,
  host_id:     String
}
```

| 键 | 类型 | 说明 |
|---|---|---|
| `id` | `String` | 区 id |
| `shape` | `RegionShape` | `"deck"` \| `"flat"`；`"deck"` 时 `card_ids[0]` 为顶 |
| `owner_id` | `String` | 属主卡 id；公共 `""` |
| `card_ids` | `Array<String>` | 区内卡序 |
| `limbo_kind` | `LimboKind` | `""` \| `"resolving"` \| `"committed"` |
| `host_id` | `String` | 附着/垫下/旁置宿主；否则 `""` |

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

### 1.4 `Chronicle` · `Audience` · `Framework` · `ChaosToken`

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

ChaosToken = {
  id:        String,
  kind:      ChaosKind,
  modifier:  Int
}
```

**`ChaosKind`**：`"numeric"` \| `"skull"` \| `"cultist"` \| `"tablet"` \| `"elder_thing"` \| `"auto_fail"` \| `"elder_sign"` \| `"bless"` \| `"curse"`

| 结构 | 键 | 类型 |
|---|---|---|
| `chronicle.log` | — | `Array<{text:String, round:Int}>` |
| `chronicle.remembered` | `String` → `String` | 卡面「记住」 |
| `audience` | `CardId` → `Audience` | 可见档 |
| `framework.round` | — | `Int` |
| `framework.*_id` | — | `String`（卡 id） |
| `chaos_bag[]` | — | `ChaosToken` |

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
| 标记 | `marker:<id>:damage` | `auth.cards[id].markers["damage"]` |
| 区成员 | `region:<id>:members` | `auth.regions[id].card_ids`（多重集） |
| 查询指纹 | `query:enemies_at:<loc>` | 由 auth 投影 |
| 登记 | `reg:<id>` | `auth.registrations[id]` |
| 方面 | `aspect:fight` | 索引 / 多条登记 |
| 框架 | `fw:active_investigator_id` | `auth.framework…` |
| 限额 | `limit:<id>` | `auth.limits[id]` |
| 记事 | `chron:remembered:<k>` | `auth.chronicle.remembered[k]` |
| 焦点 | `run:focus` | `run.focus` |
| 记忆 | `run:mem:<ctrl>:<k>` | `run.memory[ctrl][k]` |

枚举/计数集合时 **必须** 记 `region:…:members` 或 `query:…`，不得只记当时看到的实体 id（见 [35 §1.1](35-legal-interest.md)）。

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
    next_id: 4
    cards: { "I": {… investigator …}, "L": {… location …}, "C1": {… skill …} }
    regions: { "deck_I": {…}, "hand_I": {…} }
    registrations: {}
    chronicle: { log: [], remembered: {} }
    audience: { "C1": "controller" }
    limits: {}
    framework: { round:1, lead_investigator_id:"I", active_investigator_id:"I",
                 current_act_id:"", current_agenda_id:"" }
    chaos_bag: [ { id:"t0", kind:"numeric", modifier:0 } ]
  }
  derived: {
    index: { by_bound:{}, by_aspect:{}, by_bound_aspect:{}, matching_by_aspect:{}, by_source:{} }
    feasibility: { focus_fp:"", answers:{}, deps:{}, reverse:{} }
  }
  run: {
    stack: [], open_choice: null, skill_tests: [], memory: {},
    focus: { window:"", controller_id:"", open_must_ask_id:"",
             initiation_pool_ids:[], response_pool_ids:[] },
    timing_phase: ""
  }
}
```

---

## 7. 修订

| 日期 | 说明 |
|---|---|
| 2026-11-24 | v0.1：Snapshot=auth/derived/run；全键名与基础类型；Key 编码表 |
