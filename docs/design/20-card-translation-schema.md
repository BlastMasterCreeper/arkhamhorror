# 20 — 卡面翻译层规范（Compiled Ability Schema）

> **依赖**：[07-composition.md](07-composition.md)、[15-timing-entry-catalog.md](15-timing-entry-catalog.md) §4.0.5、[16-player-interaction.md](16-player-interaction.md)、[06-registration-buff-model.md](06-registration-buff-model.md) §16、[18-arkhamdb-card-data.md](18-arkhamdb-card-data.md)  
> **实现**：`tools/arkhamdb_abilities.py` → `data/arkhamdb/imported/*.json` → `ArkhamDbAbilityCompiler`  
> **状态**：v0.5.1 · 2026-10-14 — IR `op:invoke`（消歧规则「嵌套序列」）；旧 `op:nest` / `template` 为过渡糖

---

## 1. 目标

1. 卡面 `compiled_abilities` **只描述静态规格**，供框架装载与解释；运行时场面与玩家选择 **不进 JSON**。
2. **禁止**为单卡或一时方便发明布尔开关（如 `auto_engage: false`、`provokes_aoo: false` 当机制）。
3. 命名流程（`seq.*`）已展到比原子高不了几层：翻译层 **提取共性**，用统一节点 IR 拼合，而不是为每条 flow 另起一套扁平字段。
4. 复杂限制、命名流程拼合、参数记录与消费，一律走 **四类一等构件**（下表），可增长、可审计。

| 构件 | 统一 IR（`op`） | 运行时 |
|---|---|---|
| **A. 目标 / 确认** | `pi` → [SelectionSpec](21-selection-spec.md) | Gate 有限期确认 → `ChoiceBind` → `RulesMemory` |
| **B. Buff 创建** | `invoke` `seq.effect.register`（具名限制可作编译糖） | `RegistrationStore`；入口 **读取** 分支或拦 Intent |
| **C. 命名流程信封** | `invoke` + **`flow_id`** + **`params`** | 装载后按时点：`catalog.nest` **或** 同帧内联 |
| **D. 效果参数** | 字面量 + **指称键**（`memory:` / bind）进 `params` | 解释时解析 → 填入调用 `params` 或 L0 |

卡面树 **不** 展开信封内部 RESOLVE（那是 handler / Catalog 的事）；只需框架能识别调用哪条 `seq.*`、参数袋里有什么。

### 1.1 用词消歧：`invoke` ≠ 嵌套序列

| 用语 | 层 | 含义 |
|---|---|---|
| **`op: invoke`** | 翻译 IR | **调用**已铸造的命名流程（`flow_id` + `params`）；**不**断言一定压子帧 |
| **嵌套序列 / `catalog.nest`** | 规则 · 运行时 | `ResolutionSequenceStack` **真压子帧**；子手续整段（含时点）跑完再回父帧 |
| **`op: seq`（Then）** | 翻译 IR | 同段效果体内部先后；**不是**触发因果，也**不是**嵌套 |
| **触发因果** | 时点 | Would/When/After：由命名流程开放槽 + 能力 `hook` 开火；**不**画成卡面树边 |

是否把某次 `invoke` 落成真正的 `catalog.nest`，只按 [15 §4.0.5](15-timing-entry-catalog.md)。翻译层 **禁止**再用 `op: nest` 表示调用（旧 JSON 别名可读，见 §2.4）。

---

## 2. 统一节点 IR（目标形态）

命名流程共性：都是「调用哪条 `seq.*` + 传什么 params」。控制流与玩家确认另有固定外形。  
**每个节点**（含 `effect` 根、`steps[]`、`then`/`else`、选项体、`st7.*`）是下列之一：

```text
{ "op": "seq",          "steps": [Node, ...] }                          # Then · 顺序
{ "op": "simultaneous", "steps": [Node, ...] }                          # 同时 · 须显式
{ "op": "if",           "if_kind"|"evaluate"|"condition", "then", "else"? }
{ "op": "pi",           …SelectionSpec…, "bind"|"memory_key" }          # A · 有限期确认
{ "op": "invoke",       "flow_id": "seq.*", "params": { … } }           # C/D · 调用命名流程
{ "op": "inline",       "atom": "<L0|Register叶>", "params": { … } }    # 少用：§4.0.5 同帧
```

### 2.0 顺序 vs 同时（已裁决）

| 写法 | 语义 |
|---|---|
| `op: seq` 的 `steps[]` | **Then**：严格先后；后步可读前步 CREATED / Memory |
| `op: simultaneous` 的 `steps[]` | **同时** resolve（Composition Simultaneous）；**禁止**用扁平 `steps` 暗示同时 |
| 能力根省略外壳 | 单节点可直接作 `effect`；多步 **必须** 包一层 `seq` 或 `simultaneous` |

### 2.1 能力外壳（条目级）与 `effect` 根

`compiled_abilities[]` 条目：

| 字段 | 用途 |
|---|---|
| `register_as` | `action` / `free` / `forced` / `revelation` / `reaction` / `keyword` |
| `keyword` | 关键词 id（如 `uses`）；仅 `register_as:keyword` |
| `hook` | `{sequence_id, slot}`；关键词 / Forced / Reaction 挂载槽 |
| `action_types` / `action_cost` / `resource_cost` / `window` / … | 装载与 Eligibility（见 §7） |
| `translation` / `status` | 审计 |
| **`effect`** | **唯一效果体根**：一个 Node（常为 `op:seq`） |

**禁止**：效果字段扁平散落在条目根上与外壳混排（过渡期见 §2.4）。关键词 Uses、激活 Fight 等 **同一外壳**：差别只在 `register_as` / `hook` / `effect` 内容。

### 2.2 `invoke`：调用命名流程

```json
{
  "op": "invoke",
  "flow_id": "seq.effect.spend_token",
  "params": {
    "kind": "ammo",
    "amount": 1,
    "card_id": "source"
  }
}
```

| 字段 | 规则 |
|---|---|
| `op` | 恒为 `invoke`（旧糖 `nest` 可读） |
| `flow_id` | Catalog 已 `register_run` 的命名流程 id |
| `params` | 该 flow 的 **静态参数袋**（字面量 + 指称键）；**禁止**把 flow 特有参数抬到与 `op`/`flow_id` 同级 |

`invoke` = 翻译契约「走这条手续的效果体」。装载/解释时：§4.0.5 为「是」→ 运行时 **`catalog.nest`（嵌套序列）**；为「否」→ 同帧 `inline` 同一效果体。**不得**因 JSON 写了 `invoke` 就一律压栈，也 **不得**另发明第二套字段布局。

### 2.3 `pi`：玩家确认

```json
{
  "op": "pi",
  "kind": "select",
  "filter": "enemy_fight_target",
  "prompt_id": "pick:fight_enemy",
  "bind": { "key": "picked_enemy", "shape": "entity" }
}
```

| `kind` | 对应 |
|---|---|
| `select` / `multi` | 选实体；`filter` + 基数 + bind |
| `option` | must 效果支；`options[]` 各含 `effect` 子树 |
| `optional` | may 做不做；bind.shape=bool |

细则见 §3 与 [21](21-selection-spec.md)。**不是** `invoke`，**不是** `seq` 内联冒充。

### 2.4 过渡：旧 `template` / `op:nest` 糖 → 统一 IR

编译器 / imported JSON **当前仍可**发旧外形；装载层应能归一到本 IR。新翻译 **优先写 IR**（`invoke`，勿新写 `op:nest`）。

旧节点：

```text
{ "template": "<叶种类>", …扁平规格字段… }
{ "op": "nest", "flow_id": "...", "params": { … } }   # 仅过渡别名 → invoke
```

| 旧外形 | 统一 IR |
|---|---|
| `seq` + `steps` | `{ "op": "seq", "steps": [...] }` |
| `if_else` / `if` | `{ "op": "if", ... }` |
| `pick_*` / `choice_*` / `select` | `{ "op": "pi", "kind": ..., ... }` |
| `nest_*` / `place_token` / `spend_token` / `register_modifier` / `take_horror` / … 且带 `flow_id` | `{ "op": "invoke", "flow_id", "params": {其余} }` |
| `op: nest` | `{ "op": "invoke", … }`（装载别名） |
| `no_provoke_aoo` / `suppress_auto_engage` | 编译糖 → `invoke` `seq.effect.register` + Restriction 模板；或过渡期保留具名叶再归一 |
| `deal_damage_enemy` 等无独立时点的效果叶 | 目标：`invoke` `seq.effect.damage`（params 含 target/amount）；过渡可 `inline` |
| 条目根上的 `template`+`flow_id`+扁平 params（无 `effect`） | 收入 `effect: { op:invoke, flow_id, params }` |

### 2.5 `params` 与控制字段白名单

**`params` 袋内**（随 `flow_id` 增长；非袋字段勿塞进 `invoke` 节点顶层）：

| 键 | 用途 |
|---|---|
| `enemy` / `investigator` / `location` / `target` / `card_id` / `subject` | 指称规格（§6） |
| `amount` / `skill` / `difficulty` / `difficulty_source` / `kind` / `direct` / `mode` / `per_investigator` / `from` / `stat` / `duration` / `move_kind` | 字面效果参数 |
| `st7` / `on_success` / `on_fail` / `on_fail_by_each` | 检定计划（值为 Node 或 Node 字典） |
| `template`（Register 载荷） | 仅 `seq.effect.register`：Buff / Restriction 模板 id |

**节点顶层**（不进 `params`）：`op`、`flow_id`、`steps`、`then`/`else`、`if_kind`/`evaluate`/`condition`、`kind`（仅 `pi`）、`filter`/`bind`/`prompt_id`/`min`/`max`、以及 `pi` 的 SelectionSpec 字段。

**禁止**（非白名单即非法，除非本表增行并同步编译器）：

- 机制开关：`auto_engage`、`provokes_aoo`、`skip_*` 布尔覆盖
- 运行时答案：具体 `enemy_id` 实例、本次选了谁
- 第二套语义：`policy` / `service` / 卡号专用 atom
- 用扁平 `steps` 表示同时（必须 `op: simultaneous`）

需要新行为时：**扩 RestrictionKind / 新铸造 `seq.*` + 其 params 契约**，不要加布尔字段或新 `template` 前缀动物园。

---

## 3. A · 目标与确认

### 3.1 何时用 PI

卡面 **choose / select / may（选目标）** → **A**，不是 nest、不是 Then。通用规格见 **[21-selection-spec](21-selection-spec.md)**。

| 卡面语义 | IR（旧糖） | 必填规格 |
|---|---|---|
| 选 1 / N 实体（区域·特性·关键词·横置…） | `op:pi` kind=`select`/`multi`（`pick_target` / `pick_multi`） | `filter`、`min`/`max`、`prompt_id`、`bind`（多选 shape=`entity_list`） |
| 遍历已选列表 | `for_each_memory`（控制流；可包在 `seq` 内） | `memory_key`（list）+ `each_key` + `body`/`steps` |
| must 二选一效果支 | `op:pi` kind=`option`（`choice_must`） | `options[]`（各含 `effect` 子树）、`prompt_id` |
| Optional / may 做不做 | `op:pi` kind=`optional`（`choice_optional`）；整段能力仍用装载层 `USE_ABILITY` | bind.shape=bool；默认跳过 |

### 3.2 确认与否

| 情况 | 译法 |
|---|---|
| **需要确认**（并列候选或 choose） | `pick_*` / `choice_*` → Gate；`default_*` 由 Gate/Resolver 策略提供（可不进 JSON） |
| **唯一合法目标、规则自动** | **不写** pick；效果叶 `target` / `enemy` 用 **寻址规格**（如 `nearest_without_doom`、`controller`） |
| **卡面已指定「you / this enemy」** | 指称：`investigator: controller` 或 bind 的来源卡；**无** PI |

期内未确认 → **采用默认**（[16 §3.1](16-player-interaction.md)），流程不挂死。

### 3.3 确认结果的记录

```text
op: pi · kind: select
  filter: enemy_at_connecting
  prompt_id: pick:engage_connecting
  bind: { key: picked_enemy, shape: entity }   # → RulesMemory[controller][key]
```

- **只记键名与 TargetSpec**，不记本次选中的 id。
- 后续步 `params` 用 `"enemy": "memory:picked_enemy"` **消费**（§6）。
- 旧糖 `template: pick_target` + `memory_key` 等价于上形。

---

## 4. B · Buff 创建

### 4.1 统一通道

| 写法 | 何时 |
|---|---|
| 具名限制叶（`no_provoke_aoo`、`suppress_auto_engage`） | 编译糖 → `RegistrationTemplate`；**落地一律** `seq.effect.register` |
| nest `seq.effect.register` + template 载荷 | 通用 lasting / keyword / 任意 Buff；`flow_id: seq.effect.register` |
| 真空 `RegistrationStore.register` / 裸 `REGISTER` 当运行时主路径 | **禁止**（dry-run 可模拟 Store；落地：效果体 nest，Initiation 挂载用 `catalog.run`） |

**落地约定**：

| 场合 | 调用 |
|---|---|
| 效果体 `suppress_auto_engage` / `grant_keyword` / REGISTER 叶 | `catalog.nest(seq.effect.register, {template})` |
| 行动开始挂 `SKIP_AOO`（扫到 `no_provoke_aoo`） | Initiation：`catalog.run(seq.effect.register, …)`（顶层，非真空） |
| resolve 步再遇 `no_provoke_aoo` | **不**重复 Register（provenance；已在付费后挂上） |

### 4.2 限制类：创建 ≠ 入口行为

与 [06 §16.4](06-registration-buff-model.md) 一致：

```text
卡面步：Register RESTRICTION（B）
    →
规范入口读取（REST-E-*）：原流程分支 / 拦 Intent
```

| RestrictionKind | 翻译叶例 | 创建时机 | 读取入口 |
|---|---|---|---|
| `SKIP_AOO` | `no_provoke_aoo` | 行动开始（Initiation 扫描树后挂载） | INIT_2B AOO |
| `SUPPRESS_AUTO_ENGAGE` | `suppress_auto_engage` | 效果体：已有敌人指称之后 | `auto_engage_at_location` |
| `FORBID_*` | nest register / peril 模板 | 按 lifetime | REST-E-PLAY 等 |

**禁止**：用翻译字段关掉入口（`auto_engage: false`）；用 Cancel/Ignore「消掉」自动交战或借机。

#### 4.2.1 为何「移入并 engages you」必须 suppress + 明示交战（已裁决）

自动交战 ≠ 效果/行动交战（[08 §3](08-enemy-engagement.md)、RR Engage）：

| | `auto`（框架自动） | `effect`（卡面 / 基础 Engage 行动） |
|---|---|---|
| 冷漠（Aloof） | **不**交战 | **可以**交战 |
| 横置（exhausted） | **不**交战 | **可以**交战 |
| 多调查员 WHO | Prey → Lead | 卡面指定（如 controller） |
| `placement` | `enter_threat`（常移入威胁区） | 默认同；仅交战 Buff、不移入用 `grant` |

因此 **禁止**用「给自动交战塞 forced target」替代明示交战——冷漠/横置场合自动路径根本不会开火，卡面「engages you」会丢。

也 **禁止**把自动交战挪到 move/能力的 After 来省掉 suppress：子帧 After 仍先于父树下一步；且与 *immediately* 冲突（调研结论）。

正确拼合：`suppress_auto_engage` → invoke move（入口仍在，读限制后分支）→ invoke `seq.engage` mode=effect（覆盖冷漠/横置/指定 WHO）。

### 4.3 具名限制叶的参数

只允许 **指称规格**（谁受限制），例如：

```json
{ "template": "suppress_auto_engage", "enemy": "memory:picked_enemy" }
```

`no_provoke_aoo` 无目标参数（作用域 = 本次行动的 controller）；由 Initiation 挂载，不必在 JSON 重复 controller。

---

## 5. C · 命名流程拼合（`invoke`）

### 5.1 形态（统一 IR）

```json
{
  "op": "invoke",
  "flow_id": "seq.engage",
  "params": {
    "enemy": "memory:picked_enemy",
    "investigator": "controller",
    "mode": "effect"
  }
}
```

旧糖（过渡）：`{ "template": "nest_engage", "flow_id": "seq.engage", "enemy": "...", ... }` → 装载时收入 `params` 并归一为 `invoke`。  
旧 IR 别名 `op: nest` → 同形，读作 `invoke`（§1.1）。

卡面 **不** 展开 `seq.effect.resign` 内部留置线索等；信封体在 handler。

### 5.2 何时真嵌套（`catalog.nest`）vs 内联

只按 [15 §4.0.5](15-timing-entry-catalog.md)：上一步是否触发本步时点锚。  
铸造了 `seq.effect.*` ≠ 必须在运行时压子帧；翻译层仍写 `op:invoke` + 同一 `flow_id`/`params` 契约。  
**嵌套序列**一词 **仅**保留给运行时真压栈；翻译 JSON 不用 `nest` 作 `op`。

### 5.3 拼合顺序（示例 · 12113）

```text
invoke seq.effect.register SKIP_AOO    # B · 行动开始挂（或糖 no_provoke_aoo）
pi select → memory:picked_enemy        # A · 确认并记录
invoke seq.effect.register SUPPRESS_…  # B · 抑制自动交战
invoke seq.effect.move                 # C · 移入 subject=enemy
invoke seq.engage mode=effect          # C · 明示交战
```

### 5.4 对照落地（imported JSON · 过渡糖）

**12113** `action:0`（无机制布尔；目标归一到 §2 IR）：

| 旧 template | 统一 IR |
|---|---|
| `no_provoke_aoo` | B → `invoke` `seq.effect.register`（SKIP_AOO；Initiation 挂） |
| `pick_target` | `op:pi` + filter / bind |
| `suppress_auto_engage` | B → `invoke` `seq.effect.register` |
| `nest_enemy_move_to` / `move_enemy_to` / … | `invoke` `seq.effect.move` + `params.move_kind` / `subject` |
| `nest_engage` | `invoke` `seq.engage` + `params.mode=effect` |

**12112** Resign 段：`invoke` `seq.effect.resign`；借机豁免靠 `action_types: [activate, resign]`（§7），**不**挂 SKIP_AOO。

### 5.5 锚例 · 12019 M1911（新旧对照）

卡面：`Uses (4 ammo).` / `[action] Spend 1 ammo: Fight … +1 combat … +1 damage.`

**旧外形**（扁平 `template` + 参数与控制字段混排；关键词效果散在条目根）：

```json
{
  "register_as": "keyword",
  "keyword": "uses",
  "hook": { "sequence_id": "seq.zone.move", "slot": "ENTER_PLAY" },
  "template": "place_token",
  "flow_id": "seq.effect.place_token",
  "kind": "ammo",
  "amount": 4,
  "card_id": "source"
}
```

```json
{
  "register_as": "action",
  "action_types": ["activate", "fight"],
  "action_cost": 1,
  "template": "seq",
  "steps": [
    { "template": "spend_token", "flow_id": "seq.effect.spend_token", "kind": "ammo", "amount": 1, "card_id": "source" },
    { "template": "pick_target", "filter": "enemy_fight_target", "prompt_id": "pick:fight_enemy", "memory_key": "picked_enemy" },
    { "template": "register_modifier", "flow_id": "seq.effect.register", "stat": "combat", "amount": 1, "duration": "this_skill_test" },
    {
      "template": "nest_skill_test",
      "flow_id": "seq.skill_test",
      "skill": "combat",
      "difficulty_source": "enemy_fight",
      "enemy": "memory:picked_enemy",
      "st7": {
        "on_success": { "template": "deal_damage_enemy", "enemy": "memory:picked_enemy", "amount": 2 }
      }
    }
  ]
}
```

**统一 IR**（外壳 + `effect`；`invoke` 共性 = `flow_id` + `params`；顺序显式 `op:seq`）：

```json
{
  "register_as": "keyword",
  "keyword": "uses",
  "hook": { "sequence_id": "seq.zone.move", "slot": "ENTER_PLAY" },
  "status": "full",
  "translation": "full_expand",
  "effect": {
    "op": "invoke",
    "flow_id": "seq.effect.place_token",
    "params": { "kind": "ammo", "amount": 4, "card_id": "source" }
  }
}
```

```json
{
  "register_as": "action",
  "ability_id": "action:1",
  "window": "during_your_turn",
  "action_cost": 1,
  "action_types": ["activate", "fight"],
  "status": "full",
  "translation": "full_expand",
  "effect": {
    "op": "seq",
    "steps": [
      {
        "op": "invoke",
        "flow_id": "seq.effect.spend_token",
        "params": { "kind": "ammo", "amount": 1, "card_id": "source" }
      },
      {
        "op": "pi",
        "kind": "select",
        "filter": "enemy_fight_target",
        "prompt_id": "pick:fight_enemy",
        "bind": { "key": "picked_enemy", "shape": "entity" }
      },
      {
        "op": "invoke",
        "flow_id": "seq.effect.register",
        "params": { "stat": "combat", "amount": 1, "duration": "this_skill_test" }
      },
      {
        "op": "invoke",
        "flow_id": "seq.skill_test",
        "params": {
          "skill": "combat",
          "difficulty_source": "enemy_fight",
          "enemy": "memory:picked_enemy",
          "st7": {
            "on_success": {
              "op": "invoke",
              "flow_id": "seq.effect.damage",
              "params": {
                "target": "memory:picked_enemy",
                "amount": 2,
                "kind": "damage"
              }
            }
          }
        }
      }
    ]
  }
}
```

| 观察 | |
|---|---|
| 关键词与激活 | **同一外壳**；差别只在 `register_as` / `hook` / `effect` |
| place / spend / register / skill_test | **同一 `invoke` 形**；种类只在 `flow_id` + `params` |
| `steps` | 仅出现在 `op:seq`（或 `simultaneous`）下 → **顺序/同时不再靠猜** |
| 伤害 | 目标 IR 用已铸造 `seq.effect.damage`；旧 `deal_damage_enemy` 为过渡糖 |
| 用词 | `invoke` = 调用手续；是否 `catalog.nest`（嵌套序列）另由 §4.0.5 决定 |

---

## 6. D · 效果参数：记录与消费

### 6.1 三类参数来源

| 来源 | 翻译层写法 | 解析时机 |
|---|---|---|
| **字面量** | `"amount": 1`、`"mode": "effect"` | 编译期已定 |
| **装载绑定** | 隐式：`controller`、来源 `card_id` / 地点 | 装载 `AbilityBindContext` |
| **步间指称** | `"enemy": "memory:picked_enemy"` | 解释期读 `RulesMemory` |

### 6.2 指称键语法（稳定）

| 形式 | 含义 |
|---|---|
| `memory:<key>` | `RulesMemory` 当前 controller 下的 referent |
| `controller` | 能力控制者 |
| `source_location` | 来源卡所在地点（或控制者地点，按叶约定） |
| `nearest_*` / `enemy_at_*` 等 | TargetSpec / 寻址规格 id（**无** PI 时由解释器解析） |

**禁止** JSON 写死实例 id（`enemy_1`）。

### 6.3 记录（produce）与消费（consume）

```text
produce:  pick_target / choice → Memory[key] = entity_id
consume:  后续 B/C/D 叶的 enemy|target|… = "memory:key"
          nest 时：解析后写入 catalog.nest(…, params)
```

| 规则 | |
|---|---|
| 同一 `memory_key` 在单次能力 resolve 内含义稳定 | |
| nest 子帧 params **拷贝**已解析 id，不依赖子帧再读 Memory（除非叶声明再读） | |
| 能力结束 / 栈帧 pop → 本趟 Memory 指称失效（不写回 Domain） | |

### 6.4 与限制类消费的区别

| | Memory 指称 | Restriction Buff |
|---|---|---|
| 存什么 | 选中的实体 id | 规则限制（能否借机 / 能否自动交战…） |
| 谁消费 | 后续效果叶 / nest params | **规范入口**（INIT_2B、auto-engage…） |
| 寿命 | 本趟手续 | Lifetime（常 UNTIL_FIRED：入口读完即卸） |

---

## 7. 能力外壳字段（非 `effect`）

条目级外壳见 §2.1。补充约定：

| 字段 | 用途 |
|---|---|
| `action_types` | 行动类型全集（含 designator）；**借机类型层**由此判定 |
| `action_cost` / `resource_cost` / `window` / `match_kind` / `phase` | 装载与 Eligibility |

**不再使用**条目级 `provokes_aoo` 覆盖。类型豁免（Fight/Evade/Parley/Resign）走 `action_types`；卡面「does not provoke」走 **B · Register SKIP_AOO**（糖 `no_provoke_aoo`）。

效果体 **只** 出现在 `effect`（统一 IR）。过渡期若条目根仍带旧 `template`/`steps`/`flow_id`，装载层视为糖并归一到 `effect`。

---

## 8. 反例 → 正例

| 违和 / 禁止 | 改为 |
|---|---|
| `"auto_engage": false` | Register SUPPRESS + 正常 invoke move（入口读限制） |
| `"provokes_aoo": false` | Resign 靠 `action_types`；Engage 卡面靠 SKIP_AOO Register |
| 卡面 steps 内联拆光 `seq.effect.resign` 体 | `invoke` `flow_id: seq.effect.resign` |
| 为选目标 nest `seq.choose.*` | `op: pi`（A） |
| JSON 写 `"enemy": "enemy_conn"` | `"enemy": "memory:picked_enemy"` 或寻址规格 |
| `place_token` / `spend_token` / `nest_skill_test` 各一套顶层字段 | 统一 `{ op:invoke, flow_id, params }` |
| 用 `op: nest` 表示调用命名流程 | `op: invoke`；**嵌套**仅指运行时 `catalog.nest` |
| 扁平 `steps` 暗示同时结算 | `op: simultaneous` |
| 关键词 Uses 不用能力外壳、只写 Domain `uses` 字段 | `register_as:keyword` + `hook` + `effect` invoke place_token |

---

## 9. 编译器 / 解释器检查清单

1. 每个节点有合法 `op`（或可归一的旧 `template` / `op:nest` 糖）。  
2. 每个 `op:invoke` 有 `flow_id`、Catalog 已 `register_run`；flow 特有键在 `params` 内。  
3. 多步效果有显式 `op:seq` 或 `op:simultaneous`；不靠扁平数组猜同时。  
4. 每个 `memory:` 消费前，同树有 produce（`op:pi` / 约定叶）。  
5. 具名限制 ↔ 已登记 `RestrictionKind` + 唯一读取入口；落地经 `seq.effect.register`。  
6. 无布尔机制开关；无实例 id。  
7. 三分法：`pi` / `inline` / `invoke`（→ 时点决定真嵌套与否）可追溯。  
8. 能力条目：外壳字段与 `effect` 分离；关键词与触发能力同一外壳形状。  
9. 用词：翻译不用 `nest` 作 `op`；规则「嵌套序列」= `catalog.nest` 真压栈。

---

## 10. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-09-28 | v0.1 | 初稿：A/B/C/D 四构件；白名单；12113 类限制走 Buff 非翻译开关 |
| 2026-09-28 | v0.2 | §4.2.1：抑制+明示交战不可被 forced-auto / After 替代（冷漠/横置） |
| 2026-09-29 | v0.3 | §4.1：具名限制叶落地一律 `seq.effect.register`（禁真空 Store） |
| 2026-09-29 | v0.4 | §3：挂接 21 SelectionSpec；白名单扩 filter 对象 / bind / 基数 |
| 2026-10-13 | v0.5 | §2 统一节点 IR（`op` + nest `params`）；§2.0 顺序/同时；§5.5 12019 新旧对照；旧 `template` 降为过渡糖 |
| 2026-10-14 | v0.5.1 | §1.1 / §2.2：IR `op:invoke` 消歧规则「嵌套序列」/`catalog.nest`；`op:nest` 降为过渡别名 |
