# 20 — 卡面翻译层规范（Compiled Ability Schema）

> **依赖**：[07-composition.md](07-composition.md)、[15-timing-entry-catalog.md](15-timing-entry-catalog.md) §4.0.5、[16-player-interaction.md](16-player-interaction.md)、[06-registration-buff-model.md](06-registration-buff-model.md) §16、[18-arkhamdb-card-data.md](18-arkhamdb-card-data.md)  
> **实现**：`tools/arkhamdb_abilities.py` → `data/arkhamdb/imported/*.json` → `ArkhamDbAbilityCompiler`  
> **状态**：v0.4 · 2026-09-29 — 挂接 21 SelectionSpec

---

## 1. 目标

1. 卡面 `compiled_abilities` **只描述静态规格**，供框架装载与解释；运行时场面与玩家选择 **不进 JSON**。
2. **禁止**为单卡或一时方便发明布尔开关（如 `auto_engage: false`、`provokes_aoo: false` 当机制）。
3. 复杂限制、命名流程拼合、参数记录与消费，一律走 **四类一等构件**（下表），可增长、可审计。

| 构件 | 翻译层形态 | 运行时 |
|---|---|---|
| **A. 目标 / 确认** | `select` / `pick_*` / `choice_*` → [SelectionSpec](21-selection-spec.md) | Gate 有限期确认 → `ChoiceBind` → `RulesMemory` |
| **B. Buff 创建** | `register` / 具名限制叶 / nest `seq.effect.register` | `RegistrationStore`；入口 **读取** 分支或拦 Intent |
| **C. 命名流程信封** | `nest_*` + **`flow_id`** | `catalog.nest(flow_id, params)` |
| **D. 效果参数** | 字面量 + **指称键**（`memory:` / bind） | 解释时解析 → 填入 nest `params` 或 L0 |

卡面树 **不** 展开信封内部 RESOLVE（那是 handler / Catalog 的事）；只需框架能识别 nest 哪条 `seq.*`。

---

## 2. 步节点统一外形

每个 `steps[]` 元素（及 `then` / `else` / 选项体）是一个 **字典**：

```text
{
  "template": "<叶种类>",   # 必填：决定构件类 A/B/C/D/控制流
  …规格字段…                 # 仅下列白名单；见 §3–§6
}
```

### 2.1 字段白名单（增长表）

| 字段 | 用途 | 允许出现在 |
|---|---|---|
| `template` | 叶种类 | 所有步 |
| `flow_id` | nest 目标命名流程 | **仅** nest 叶（C） |
| `filter` / `trait` / `at` / `trait_exclude` / `traits` / `keywords` / `exhausted` | [CandidateFilter](21-selection-spec.md)（预设字符串或对象） | A |
| `min` / `max` / `min_picks` / `max_picks` | 选择基数 | A（`pick_multi` / `select`） |
| `bind` | `{key, shape}` ChoiceBind；或扁平 `memory_key` | A |
| `prompt_id` | Gate 提示键 | A |
| `memory_key` | bind.key 糖（单实体） | A |
| `enemy` / `investigator` / `location` / `target` / `card_id` | **指称规格**（见 §6） | B、C、D |
| `amount` / `skill` / `difficulty` / `kind` / `direct` / `mode` / `per_investigator` | 字面效果参数 | D、部分 C |
| `if_kind` / `evaluate` / `condition` / `then` / `else` | 控制流 | 控制流叶 |
| `options` / `steps` / `st7` / `on_success` / `on_fail*` | 子树 / 检定计划 | 控制流、skill_test |
| `field` / `value` | 仅 L0 `set_flag` 等离散原子 | 内联 L0（少用；优先进信封 handler） |

**禁止**（非白名单即非法，除非本表增行并同步编译器）：

- 机制开关：`auto_engage`、`provokes_aoo`、`skip_*` 布尔覆盖
- 运行时答案：具体 `enemy_id` 实例、本次选了谁
- 第二套语义：`policy` / `service` / 卡号专用 atom

需要新行为时：**扩 RestrictionKind / 新具名限制叶 / 新铸造 `seq.*`**，不要加布尔字段。

### 2.2 `template` 命名约定

| 前缀 / 形态 | 含义 |
|---|---|
| `pick_*` / `choice_*` | **A** 玩家确认 |
| `no_provoke_aoo` / `suppress_auto_engage` / `grant_*` | **B** 具名 Buff（编译为 Register） |
| `nest_*` | **C** nest 命名流程；**必须**带 `flow_id` |
| 其余（`take_horror`、`deal_damage`…） | **D** 效果叶：编译为内联或 nest（§4.0.5）；若 nest 则同时写 `flow_id` |
| `seq` / `if_else` / `skill_test` | 控制流 |

---

## 3. A · 目标与确认

### 3.1 何时用 PI

卡面 **choose / select / may（选目标）** → **A**，不是 nest、不是 Then。通用规格见 **[21-selection-spec](21-selection-spec.md)**。

| 卡面语义 | template 例 | 必填规格 |
|---|---|---|
| 选 1 / N 实体（区域·特性·关键词·横置…） | `select` / `pick_target` / `pick_multi` | `filter`（预设或对象）、`prompt_id`、`bind`/`memory_key` |
| must 二选一效果支 | `choice_must` | `options[]`（各含子树）、`prompt_id` |
| Optional / may 做不做 | （装载层 / USE_ABILITY；或 `choice_optional` 待扩） | bind.shape=bool |

### 3.2 确认与否

| 情况 | 译法 |
|---|---|
| **需要确认**（并列候选或 choose） | `pick_*` / `choice_*` → Gate；`default_*` 由 Gate/Resolver 策略提供（可不进 JSON） |
| **唯一合法目标、规则自动** | **不写** pick；效果叶 `target` / `enemy` 用 **寻址规格**（如 `nearest_without_doom`、`controller`） |
| **卡面已指定「you / this enemy」** | 指称：`investigator: controller` 或 bind 的来源卡；**无** PI |

期内未确认 → **采用默认**（[16 §3.1](16-player-interaction.md)），流程不挂死。

### 3.3 确认结果的记录

```text
pick_target
  filter: enemy_at_connecting
  prompt_id: pick:engage_connecting
  memory_key: picked_enemy          # 写入 RulesMemory[controller][key]
```

- **只记键名与 TargetSpec**，不记本次选中的 id。
- 后续步用 `"enemy": "memory:picked_enemy"` **消费**（§6）。

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

| | `auto_engage_at_location` | `seq.engage` mode=effect/action |
|---|---|---|
| 冷漠（Aloof） | **不**交战 | **可以**交战 |
| 横置（exhausted） | **不**交战 | **可以**交战 |
| 多调查员 WHO | Prey → Lead | 卡面指定（如 controller） |

因此 **禁止**用「给自动交战塞 forced target」替代明示交战——冷漠/横置场合自动路径根本不会开火，卡面「engages you」会丢。

也 **禁止**把自动交战挪到 move/能力的 After 来省掉 suppress：子帧 After 仍先于父树下一步；且与 *immediately* 冲突（调研结论）。

正确拼合：`suppress_auto_engage` → nest move（入口仍在，读限制后分支）→ nest `seq.engage` mode=effect（覆盖冷漠/横置/指定 WHO）。

### 4.3 具名限制叶的参数

只允许 **指称规格**（谁受限制），例如：

```json
{ "template": "suppress_auto_engage", "enemy": "memory:picked_enemy" }
```

`no_provoke_aoo` 无目标参数（作用域 = 本次行动的 controller）；由 Initiation 挂载，不必在 JSON 重复 controller。

---

## 5. C · 命名流程拼合（nest）

### 5.1 形态

```json
{
  "template": "nest_engage",
  "flow_id": "seq.engage",
  "enemy": "memory:picked_enemy",
  "investigator": "controller",
  "mode": "effect"
}
```

| 字段 | 规则 |
|---|---|
| `template` | 编译器入口（可含糖解析）；须能映射到唯一 `flow_id` |
| `flow_id` | **权威**：Catalog 登记的命名流程 id；框架只认这个压栈 |
| 其余 | 该 flow 的 **静态 params 规格**（字面量 + 指称键）；解释时解析成实体 id 再 `nest` |

卡面 **不** 展开 `seq.effect.resign` 内部留置线索等；信封体在 handler。

### 5.2 何时 nest vs 内联

只按 [15 §4.0.5](15-timing-entry-catalog.md)：上一步是否触发本步时点锚。  
铸造了 `seq.effect.*` ≠ 必须 nest。

### 5.3 拼合顺序（示例 · 12113）

```text
no_provoke_aoo                         # B · SKIP_AOO（行动开始挂）
pick_target → memory:picked_enemy      # A · 确认并记录
suppress_auto_engage @ memory:…        # B · 抑制自动交战
nest seq.enemy.move                    # C · 移入（仍进 auto-engage 入口；B 使其分支）
nest seq.engage mode=effect            # C · 明示交战（消费同一指称）
```

### 5.4 对照落地（imported JSON）

**12113** `action:0`（字段 ⊆ §2.1；无机制布尔）：

| 步 | 构件 | 关键规格 |
|---|---|---|
| `no_provoke_aoo` | B | 无参；Initiation 挂 `SKIP_AOO` |
| `pick_target` | A | `filter` / `prompt_id` / `memory_key` |
| `suppress_auto_engage` | B | `enemy: memory:picked_enemy` |
| `nest_enemy_move_to` | C | `flow_id: seq.enemy.move` + 指称 |
| `nest_engage` | C | `flow_id: seq.engage` + `mode: effect` |

**12112** Resign 段：仅 `nest_resign` + `flow_id: seq.effect.resign`；借机豁免靠 `action_types: [activate, resign]`（§7），**不**挂 `no_provoke_aoo`。

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

## 7. 能力外壳字段（非 steps）

`compiled_abilities[]` 条目级：

| 字段 | 用途 |
|---|---|
| `register_as` | `action` / `free` / `forced` / `revelation` / `reaction` |
| `action_types` | 行动类型全集（含 designator）；**借机类型层**由此判定 |
| `action_cost` / `resource_cost` / `window` / `match_kind` / `phase` | 装载与 Eligibility |
| `translation` | `full_expand` 等审计标记 |
| `status` | `full` / `partial` |

**不再使用**条目级 `provokes_aoo` 覆盖。类型豁免（Fight/Evade/Parley/Resign）走 `action_types`；卡面「does not provoke」走 **B · `no_provoke_aoo`**。

---

## 8. 反例 → 正例

| 违和 / 禁止 | 改为 |
|---|---|
| `"auto_engage": false` | `suppress_auto_engage` + 正常 nest move（入口读限制） |
| `"provokes_aoo": false` | Resign 靠 `action_types`；Engage 卡面靠 `no_provoke_aoo` |
| 卡面 steps 内联拆光 `seq.effect.resign` 体 | nest `flow_id: seq.effect.resign` |
| 为选目标 nest `seq.choose.*` | `pick_target`（A） |
| JSON 写 `"enemy": "enemy_conn"` | `"enemy": "memory:picked_enemy"` 或寻址规格 |

---

## 9. 编译器 / 解释器检查清单

1. steps 字段 ⊆ §2.1 白名单。  
2. 每个 `nest_*` 有 `flow_id` 且 Catalog 已 `register_run`。  
3. 每个 `memory:` 消费前，同树有 produce（`pick_*` / 约定叶）。  
4. 具名限制叶 ↔ 已登记 `RestrictionKind` + 唯一读取入口。  
5. 无布尔机制开关；无实例 id。  
6. 三分法：A / 内联 / nest 标注可追溯（代码注释或 `translation`）。

---

## 10. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-09-28 | v0.1 | 初稿：A/B/C/D 四构件；白名单；12113 类限制走 Buff 非翻译开关 |
| 2026-09-28 | v0.2 | §4.2.1：抑制+明示交战不可被 forced-auto / After 替代（冷漠/横置） |
| 2026-09-29 | v0.3 | §4.1：具名限制叶落地一律 `seq.effect.register`（禁真空 Store） |
| 2026-09-29 | v0.4 | §3：挂接 21 SelectionSpec；白名单扩 filter 对象 / bind / 基数 |
