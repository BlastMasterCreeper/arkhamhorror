# 21 — 通用选择规格（SelectionSpec）与参数传递

> **依赖**：[16-player-interaction.md](16-player-interaction.md)、[20-card-translation-schema.md](20-card-translation-schema.md) §3/§6、[07-composition.md](07-composition.md) §1.4  
> **实现**：`rules/choices/selection_spec.gd` · `candidate_filter.gd` · `candidate_enumerator.gd` · `PlayerInteractionGate`  
> **状态**：v0.5 · 2026-09-29 — 隐式目标（Fight→Attack / Evade→evasion attempt）

---

## 1. 目标

卡面与规则中的「选择」形态很多，但运行时应收敛为 **同一套规格 → Gate → bind → 消费**：

| 情形 | ChoiceKind | 规格要点 |
|---|---|---|
| 选 1 / N 张（区域·特性·关键词·横置…） | `PICK_TARGET` / `PICK_MULTI` | `CandidateFilter` + 基数 |
| 多项效果支（must / may 选支） | `PICK_OPTION` | `options[]` 子树；dry-run 过滤 |
| 是否发动（reaction / may 整段） | `USE_ABILITY` / `OPTIONAL_EFFECT` | bool；默认常为否 |
| 排序 / 分配 / Search… | 既有 Kind | 仍走 Gate；bind 形状见 §5 |

**禁止**：为每种卡面约束新加布尔字段；为「选敌人」nest `seq.choose.*`；把本次答案写进静态树。

与 [20 §A](20-card-translation-schema.md) 对齐：翻译层只写 **问什么**；答在 Gate；指称进 `RulesMemory`。

---

## 2. 三件套

```text
SelectionSpec          # 静态：问什么、基数、默认、bind
  └─ CandidateFilter   # 静态：如何枚举合法候选（实体类）
       ↓ resolve 时
CandidateEnumerator    # 客观枚举 → options[]
       ↓
PlayerInteractionGate.ask(ChoiceRequest)
       ↓
ChoiceBind → RulesMemory
       ↓
后续叶 / nest params 用 memory: 消费
```

| 构件 | 职责 | 非职责 |
|---|---|---|
| **SelectionSpec** | 翻译/编译期规格 | 不含本次选中的 id |
| **CandidateFilter** | 合法集形状（可组合约束） | 不做玩家决策 |
| **ChoiceBind** | 结果写入 Memory 的键与形状 | 不改 Domain |

---

## 3. `CandidateFilter`（实体候选）

可组合字典 / 资源字段（增长表；非白名单字段非法）：

| 字段 | 类型 | 含义 |
|---|---|---|
| `entity` | `enemy` / `investigator` / `location` / `card` | 候选实体类（必填） |
| `zones` | `hand` / `play` / `threat` / `encounter_discard` / … | 卡牌所在区（`card` 用） |
| `at` | 寻址规格 | 地点约束：`controller_location` / `source_location` / `connecting` / `memory:<key>` / 具名地点 |
| `traits` / `trait_exclude` | `StringName[]` | 须含 / 须不含 |
| `keywords` / `keyword_exclude` | `StringName[]` | 印刷或 gained keyword |
| `card_types` | `asset` / `event` / `skill` / … | 卡牌类型 |
| `exhausted` | `bool?` | `true`=仅横置；`false`=仅未横置；省略=不限 |
| `engaged` | `bool?` | 敌人交战态 |
| `exclude_massive` | `bool` | 默认 true（非巨大交战选敌时常排除） |
| `exclude_aloof` | `bool` | 可选；Fight 入口等 |
| `owned_by` | `controller` / `any` / inv id 规格 | 控制者约束 |
| `preset` | 短 id | 糖：展开为上表字段（如 `enemy_at_connecting`） |

**预设（兼容旧 `pick_target.filter` 字符串）**：

| preset | 展开 |
|---|---|
| `enemy_at_connecting` | `entity=enemy` + `at=connecting` + `exclude_massive=true` |
| `enemy_at_controller_location` | `entity=enemy` + `at=controller_location` + `exclude_massive=true` |
| `location_connecting` | `entity=location` + `at=connecting` |

枚举在 **客观层**完成（Domain + Restriction）；Gate 只在已枚举的 `options` 上确认。

---

## 3.1 候选范围：分层谓词管线（难点 · 已裁决方向）

选择交互本身简单；**难的是合法集**。卡面约束混杂：

| 约束类 | 例子 | 读哪 |
|---|---|---|
| **结构 / 局面** | 手牌、连结地点、Humanoid、Hunter、未横置、已交战 | Domain / CardRegistry / EnemyState |
| **数值** | fight ≤ 2、剩余 sanity ≥ 1、线索最多、本回合第 3 次行动 | 实体字段比较 / [StatQuery](06c-stat-projections.md) |
| **限制类 Buff** | cannot fight 未交战 aloof、cannot discard、peril 禁 commit | **并入 V**：dry-run 走与活结算相同的 Restriction 入口 |
| **效果可改变目标状态** | 「choose and exhaust」不能选已横置；对目标多效果时至少一条能改 | CompositionDryRunner（**V 层 · 规范要求**） |

**禁止**：为每种卡面约束加布尔（`only_ready`、`fight_le_2`）；在 Enumerator 里 `match effect_text`；把 Restriction 译成 LISTENER「挡候选」。

### 3.1.1 管线（固定顺序）

```text
U  Universe     粗宇宙：entity + zones/at → 原始 id 集
S  Structural   结构谓词：traits / keywords / exhausted / engaged / card_types / owned_by
N  Numeric      数值谓词：字段比较 + StatQuery
V  Viability    L7 dry-run：绑定候选 → 跑依赖该目标的效果（内含 Restriction 入口）
                 → 对该目标能否 CREATED（改变局面）
     ↓
options[] → Gate
```

| 层 | 输入 | 失败 = 剔除 | 实现钩子 |
|---|---|---|---|
| **U** | `filter.entity` + `at`/`zones` | 不在宇宙 | `CandidateEnumerator` 现有 |
| **S** | 白名单结构字段 | 不匹配 | 同左；增长表 |
| **N** | `preds[]` 数值条 | 比较失败 | §3.1.2 |
| **V** | 绑定候选 + 效果尾 / 能力体 | 无 CREATED（含被 Restriction 挡住） | §3.1.4 · DryRunner |

前一层输出是后一层输入；**短路**：空集立即停，不 ask。U–N 先廉价剔除，再对剩余做 V。

**限制类不单独成「真相层」**：对 choose 目标而言，RESTRICTION 的语义后果是「效果无法改变该目标 / 无法落地」→ dry-run 无 CREATED → V 剔除。可选的 `for_intent` 预筛（原 §3.1.3）仅作**性能优化**，必须与 V 结论一致，禁止两套互相矛盾的判定。

### 3.1.2 数值谓词（`preds`）

不造并行「数值 DSL 宇宙」：复用实体字段与已有 `StatQuery`。

```json
"preds": [
  { "on": "candidate", "field": "fight", "op": "le", "value": 2 },
  { "on": "controller", "field": "sanity_remaining", "op": "ge", "value": 1 },
  { "on": "candidate", "stat_query": "clues_on_location_ge", "value": 1 }
]
```

| 字段 | 含义 |
|---|---|
| `on` | `candidate` / `controller` / `lead` / `memory:<key>` |
| `field` | 稳定投影名（`fight` / `health_remaining` / `clues` / `resources` …）增长表 |
| `op` | `eq` `ne` `lt` `le` `gt` `ge` |
| `value` | 字面量，或 `memory:` / `per_investigator` 规格 |
| `stat_query` | 可选；走 `StatQuery` + 投影（回合行动次数等） |

**并列最值**（most clues / nearest）：U+S 后在 Enumerator 内 **折叠** 成并列子集，再交 Gate（或队长 `TIE_BREAK`）；不是又一层 PI Kind。

### 3.1.3 Restriction 与 dry-run（已裁决）

**结论：目标选择场景下，限制类 Buff 的检测放在 V 的 dry-run 里做，不另建独立 R 真相层。**

**口径（已裁决）**：Restriction **不直接**把实体标成「不可选」；它在结算路径上拦住写入 → **不产生对该目标的结算 / 无 CREATED** → V 不通过 → **间接**不成合法目标。与「直接从名单剔除」结果常等价，但 dry-run 能覆盖多效果 OR、Then、费用后局面、条件支等组合，无需为每种限制再写候选特例。

| | |
|---|---|
| **机制** | 活路 REST-E-* / 效果入口拦写入；dry-run 走**同一入口** → 无 CREATED → 非法目标 |
| **硬条件** | 模拟路径必须接 `RestrictionEvaluator`（或等价）；禁止 dry-run「假装无 Restriction」 |
| **不进 V 当失败的** | `SKIP_AOO` / `SUPPRESS_AUTO_ENGAGE` 等 **原流程分支**（不挡成为目标，只改入口分支） |
| **仍留在 Initiation L4 的** | 能力整体能否发起（`FORBID_TRIGGER` / peril 禁 play…）— 「这条能力」，不是「这个候选」 |
| **可选预筛** | `for_intent` + `block_reason` 仅优化；与 V 冲突时以 V 为准 |

```json
{
  "filter": { "preset": "enemy_at_controller_location" },
  "for_intent": "FIGHT"
}
```

`for_intent` 缺省：只靠 V。行动宏（Fight 选敌）可带预筛，但 aloof 等最终仍以 dry-run「对该敌 CREATED？」为准。

### 3.1.4 Viability（L7 dry-run · **目标选择规范要求**）

**规则（Grimoire / 2026 Rulebook · Target）**：

> If a target’s state cannot be changed by the resolution of an ability or game effect, then that target is not a valid target or choice for that effect.  
> （例：已横置敌人不是「choose and exhaust an enemy」的合法目标。）  
> 对同一目标有多条效果时：至少一条能改变其状态 → 仍合法；不能改变的那几条不结算。

这与「能力须有 potential to change the game state 才能 initiate」同族，应用 **同一套 dry-run / CREATED**（Initiation L7 · `CompositionDryRunner`），不是另造「目标 Policy」。

#### 做法（已裁决）

```text
对每个过了 U–R 的候选 c：
  1. 临时 ChoiceBind：memory[bind_key] = c（或注入 AbilityBindContext）
  2. dry-run「依赖该目标的效果」——通常为 select 之后的同能力尾树，
     或编译期标注的 viability_tail / 整段效果体（已付 cost 不重演）
  3. 判定：对该目标至少一处 CREATED（状态原语或 Register 成功写入模拟）
     → 保留；否则剔除
  4. 撤销临时 bind，试下一个 c
```

| 要点 | |
|---|---|
| **与发起 L7 同源** | 同一 `CompositionDryRunner` + CREATED 定义（[07 §4.1](07-composition.md)） |
| **Restriction 在此检测** | dry-run 命中 REST-E / 效果入口 → 无写入 → 无 CREATED → 非法目标（§3.1.3） |
| **评估口径** | 看效果是否**有潜力**改变该目标状态；不计入其他能力连锁后果（对齐 RR 发起时「不计其他 ability interactions」的精神） |
| **多效果同一目标** | dry-run 尾树内 **OR**：任一条对该目标 CREATED 即合法 |
| **空合法集** | 不得 initiate / 本步不 ask（Grimoire：至少一合法目标才能发起） |
| **any number** | `min_picks≥1` 时选 0 不合法；V 后 options 仍空则不能发起 |
| **「each X」非 choose** | 不经单选 Gate；发起条件=至少一合法；结算时对非法个体跳过——仍可用同一 V 谓词逐个标 valid |
| **可不跑 V** | 纯排序 / 无效果依赖的确认（`CONFIRM_STEP`）；**choose 目标供效果结算 → 必须 V** |

must 多支选一：支级 dry-run（已有）与目标级 V **同引擎、不同绑定粒度**（支 = 子树；目标 = 同一树换 bind）。

### 3.1.5 与 Eligibility L0–L7 的关系

| | 能力 Initiation Eligibility | 选择候选管线 |
|---|---|---|
| 问什么 | 这条能力能否发起 | 这个实体能否进入 options |
| Restriction | L4 拦 TRIGGER/PLAY…（整能力） | **在 V dry-run 内**拦「对该目标的效果」；可选 `for_intent` 预筛 |
| L7 dry-run | 整棵效果树（无合法目标则整能力不能发） | **V**：逐候选 bind 后 dry-run；options 空 → 能力侧 L7 也失败 |

共享 Condition / StatQuery / RestrictionEvaluator / DryRunner。典型顺序：U–N 粗筛 → V（内含 Restriction）→ 合法集空则不能发起 / 本步 fizzle。

### 3.1.6 翻译层怎么写（扩展 filter）

```json
{
  "template": "select",
  "filter": {
    "entity": "enemy",
    "at": "controller_location",
    "traits": ["Monster"],
    "exhausted": false,
    "preds": [{ "on": "candidate", "field": "fight", "op": "le", "value": 3 }]
  },
  "prompt_id": "pick:weak_monster",
  "bind": { "key": "picked_enemy", "shape": "entity" }
}
```

结构字段仍在 `CandidateFilter`；`preds` / `for_intent` / `viability` 为管线扩展（白名单增长，见 20 §2.1）。

### 3.2 隐式目标（Implicit Target · Fight / Evade）

卡面未必出现 *Target* / *choose* 字样，但规则仍要求选定敌人，且适用同一套「合法目标 / 状态可被改变 / 无合法则不能发起」：

| 行动 / 能力 | 衍生结算 | 隐式目标 | 默认宇宙（U） |
|---|---|---|---|
| **Fight**（基础或 bold Fight） | **攻击（Attack）** → 通常为 combat 检定 | 被攻击的敌人 | 同地点敌人（含自己/他人威胁区、同地点 unengaged）；见 [03 §6.8](03-action-system.md) |
| **Evade**（基础或 bold Evade） | **躲避尝试（evasion attempt）** → 通常为 agility 检定 | 被躲避的敌人 | 默认仅与自己交战的敌人；见 [03 §6.7](03-action-system.md) |

| 裁决 | |
|---|---|
| **与明示 Target 同构** | 仍走 U–N → V（dry-run / CREATED）；Restriction 间接挡；可 PI 确认或唯一候选默认 |
| **文本无 choose** | 不因此跳过目标规格；编译为隐式 `SelectionSpec`（`role: implicit_attack` / `implicit_evade`）或行动内核内建 filter |
| **自动躲避例外** | 能力「automatically evade」：**不**做 evasion attempt / 不做检定，也不要求「成功躲避」语义；直接 exhaust + disengage（Grimoire）。此类 **无** 衍生检定隐式目标管线 |
| **极少无衍生检定的 Evade** | 卡面显式取消检定或改写步骤时，按文本；默认 Evade **伴随** evasion attempt |
| **Aloof 等** | 未交战 aloof 非法 Fight 目标：活路/dry-run 同入口 → 无 CREATED → 不进合法集 |

#### 3.2.1 发起 L7：整段能力 vs 仅 Attack/Evade 内核

**不是**「只要 Attack 此刻没有合法敌人，带 Fight designator 的能力一律不能发」。

| 形态 | Initiation L7（整段能否发起） | 隐式攻击/躲避目标 |
|---|---|---|
| **基础 Fight / Evade**（行动≈衍生检定本身） | 合法敌人集空 → **整行动不可发起** | 与 L7 同一条件 |
| **Fight/Evade 能力 = 前置效果 + 衍生 Attack/evasion**（例：先 choose 移动，再 Attack） | dry-run **整棵效果树**：任一前序效果能 CREATED（如移动可执行）→ **可通过 L7**，即使目的地可无敌人、Attack 随后不能发 | Attack/evasion 在**轮到该步**时再取合法集；空则该步不发起/不结算，**不回溯撤销**已发起的行动与已结算的移动 |

```text
例：Fight 能力「Move to a connecting location. Fight that… / Attack」
  L7 dry-run 整树
    → 移动可选且能改局面（目的地不必有敌人）→ CREATED → 整段 Fight 可发起
  付费、结算移动后
    → 若新地点无合法攻击目标 → 衍生 Attack 不发起（无检定）
    → 移动仍然有效；不是「整次 Fight 从未合法」
```

| 要点 | |
|---|---|
| **L7 粒度** | 外层 Initiation = 整段 Composition；内层 Attack/evasion attempt = 各自发起时再检隐式目标 |
| **与 Target 通则一致** | 「有目标的效果」无合法目标则**该效果**不能发起；前面无目标依赖的效果仍可让**能力**具备 change-state 潜力 |
| **V 仍用于** | 选移动目的地、选攻击敌人等每一步自己的候选；不把「Attack 的 V」误当成整段 Fight 的唯一 L7 |

```text
Fight / Evade（基础）Initiation（L7）
  → 隐式目标合法集空 → 不可发起

Fight / Evade 能力（多步）Initiation（L7）
  → dry-run 整树（含前置 move 等）→ 有 CREATED 则可发起
  → RESOLVE … 至 Attack/evasion 步
       → 再 enumerate + V 隐式敌人；空 → 跳过该衍生检定
```

**禁止**：因未印 Target 就省略敌人参数；把基础 Fight/Evade 的「无敌人」做成付费后中途才发现不能打（基础行动应在发起失败）；把「前置可移动」误判成「Attack 无目标则整段 Fight L7 失败」。

---

## 4. `SelectionSpec`

| 字段 | 含义 |
|---|---|
| `choice_kind` | `AhcEnums.ChoiceKind`（实体选 / 分支 / optional…） |
| `filter` | `CandidateFilter`（仅实体类 Kind 需要） |
| `min_picks` / `max_picks` | 基数；单选 = 1/1；`up to N` = 0..N 或 1..N 按卡面 |
| `prompt_id` | 稳定提示键 |
| `decider` | `controller`（默认）/ `lead` / 指称 |
| `default_policy` | `first_option` / `skip`（optional）/ `lead_tiebreak` |
| `deadline_ms` | 有限期；`-1` = 策略默认 |
| `bind` | `ChoiceBind`（§5） |
| `options` | 仅 `PICK_OPTION`：编译期分支 id / 子树（非实体枚举） |
| `role` | 可选：`explicit_choose` / `implicit_attack` / `implicit_evade`（§3.2） |

### 4.1 翻译层 template

| template | 映射 |
|---|---|
| `select` | 通用；带完整 SelectionSpec 字段 |
| `pick_target` | 糖 → `select` + `PICK_TARGET` + filter preset/对象 + bind.entity |
| `pick_multi` | 糖 → `select` + `PICK_MULTI` + min/max |
| `choice_must` | 糖 → `PICK_OPTION` + must + options 子树 |
| `choice_optional` / Optional 节点 | `OPTIONAL_EFFECT`；bind.shape=bool |
| `ask_use`（装载层） | `USE_ABILITY`；通常不进卡面 steps |

旧 JSON 仅写 `"filter": "enemy_at_connecting"` 仍合法（preset）。

---

## 5. `ChoiceBind` — 参数传递

### 5.1 写入（produce）

| `shape` | Memory 值 | 典型 Kind |
|---|---|---|
| `entity` | 单个 `StringName` id | `PICK_TARGET` |
| `entity_list` | `Array[StringName]` | `PICK_MULTI` / discard / commit |
| `option_id` | 分支 id / index | `PICK_OPTION` |
| `bool` | 是否发动 | `OPTIONAL_EFFECT` / `USE_ABILITY` |
| `order` | 重排后的 id 列表 | `ORDER_*` |

```text
bind:
  key: picked_enemy          # RulesMemory[decider 或 controller][key]
  shape: entity
```

### 5.2 消费（consume）

| 写法 | 含义 |
|---|---|
| `memory:<key>` | 读单个 entity / option_id / bool |
| `memory:<key>[]` | 读 list（ForEach / nest_batch） |
| `memory:<key>.0` | list 首项（少用；优先进 ForEach） |

规则同 [20 §6](20-card-translation-schema.md)：nest 子帧 params **拷贝**已解析值；本趟手续结束指称失效。

### 5.3 与「无 PI」寻址的分工

| | PI + bind | 纯寻址（无 Gate） |
|---|---|---|
| 何时 | 并列候选 / choose / may | 唯一合法或规则自动（nearest、controller） |
| Memory | 写入所选 | 可不写；效果叶直接解析 `nearest_*` |

---

## 6. 运行时管线

```text
1. 从 Composition 叶得到 SelectionSpec（糖已展开）
2. 若需候选：CandidateEnumerator.enumerate(filter, ctx, AbilityBindContext)
3. 空集 → 本步 fizzle（或 Optional 跳过）；不 ask
4. 唯一候选且 min=max=1 → 可默认确认（仍写 bind；可跳过 UI）
5. Gate.ask(ChoiceRequest{ kind, options, min/max, default, deadline, prompt_id })
6. ChoiceBind.write(memory, picked)
7. 父 RESOLVE 继续；后续叶读 memory:
```

**仍不是** nest；不占用 Would/When/After。

---

## 7. 反例

| 禁止 | 改为 |
|---|---|
| `"only_ready": true` 布尔散落 | `filter.exhausted: false` |
| 每张卡一个 `pick_humanoid_enemy` atom | `filter.traits: [Humanoid]` |
| 选完写进 Domain 临时槽 | `bind` → RulesMemory |
| `seq.choose.enemy` | `select` / `pick_target`（PI） |

---

## 8. 落地进度

| 项 | 状态 |
|---|---|
| 本文规格 | ✅ v0.2（含 §3.1 候选管线） |
| `CandidateFilter` / `SelectionSpec` / Enumerator | ✅ 骨架（U+部分 S） |
| `pick_target` 经 Enumerator（preset + 对象 filter） | ✅ |
| Gate `ask_selection` + Memory bind 形状 | ✅ 骨架 |
| **N** 数值 `preds` + field/StatQuery | 待接 |
| **V** 候选级 dry-run（含 Restriction；目标须能被改变） | **规范已裁**；待接 DryRunner 逐候选 bind + 模拟路径接 RestrictionEvaluator |
| `for_intent` 预筛 | 可选优化；不得与 V 分叉 |
| **隐式目标** Fight/Evade（§3.2） | 规范已裁；行动 L7 绑合法集 |
| `pick_multi` / 特性·关键词·横置全量 | 增量 |
| `choice_optional` 编译糖 | 待扩 |
| 12116 内嵌 PI 拆为独立 select | 债（19 §3.1） |

---

## 9. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-09-29 | v0.4 | **§3.1.3**：目标侧 Restriction **在 V dry-run 内检测**；取消独立 R 真相层（预筛仅优化） |
| 2026-09-29 | v0.5 | **§3.2** 隐式目标：Fight/Evade 衍生检定与 Target 同构；无合法则整行动 L7 失败 |
| 2026-09-29 | v0.4.1 | 明确：Restriction **间接**挡（无结算→无 CREATED）；dry-run 适应复杂组合 |
| 2026-09-29 | v0.3 | **§3.1.4**：目标合法=状态可被改变；V=与 Initiation L7 同源 dry-run（规范要求，非可选） |
| 2026-09-29 | v0.2 | **§3.1** 候选范围分层：U/S/N/R/V；数值 preds；Restriction via `for_intent` |
| 2026-09-29 | v0.1 | 初稿：SelectionSpec / CandidateFilter / ChoiceBind；与 16/20 对齐 |
