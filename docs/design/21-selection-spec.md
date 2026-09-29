# 21 — 通用选择规格（SelectionSpec）与参数传递

> **依赖**：[16-player-interaction.md](16-player-interaction.md)、[20-card-translation-schema.md](20-card-translation-schema.md) §3/§6、[07-composition.md](07-composition.md) §1.4  
> **实现**：`rules/choices/selection_spec.gd` · `candidate_filter.gd` · `candidate_enumerator.gd` · `PlayerInteractionGate`  
> **状态**：v0.1 · 2026-09-29 — 统一实体/分支/是否发动的选择与 Memory bind

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
| 本文规格 | ✅ v0.1 |
| `CandidateFilter` / `SelectionSpec` / Enumerator | ✅ 骨架 |
| `pick_target` 经 Enumerator（preset + 对象 filter） | ✅ |
| Gate `ask_selection` + Memory bind 形状 | ✅ 骨架 |
| `pick_multi` / 特性·关键词·横置全量 | 增量 |
| `choice_optional` 编译糖 | 待扩 |
| 12116 内嵌 PI 拆为独立 select | 债（19 §3.1） |

---

## 9. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-09-29 | v0.1 | 初稿：SelectionSpec / CandidateFilter / ChoiceBind；与 16/20 对齐 |
