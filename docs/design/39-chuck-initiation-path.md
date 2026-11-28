# 39 · Chuck 09072 — Constant 额外费用 → 可选发起路径

> **竖切**：AHLP-12 · PR 枝 `cursor/fp-chuck-path-18b0`  
> **权威卡面**：[`personal-card-text.md` · 09072](../reference/personal-card-text.md)  
> **Prefs**：Fast = Constant「额外费用 → 第二条发起路径」；**不用** Would / 时点改写  
> **代码**：`arkham_rules/src/initiation/mod.rs`

---

## 0. 一句话

打出 Tactic/Trick 时，由 Chuck 的 **Constant** 打开带额外费用（横置 Chuck）的**可选发起路径**；选 Fast 则整次发起（广义打出）不耗 Play action；选 −2 资源则在**费用可行性**上对印刷资源费用做路径内折算。**不是**先按默认路径发起再 Would / gains。

---

## 1. 为什么印刷读法会失败（Fast）

官方 / Taboo：*When you play… gains Fast…*

| 失败读法 | 问题 |
|---|---|
| 先无 Fast 发起再 gains Fast | 行动花费已定，Fast 盖不住广义打出 |
| Would 改写已开的发起 | Would ≠ 另开时点；有效性不过则无发起时点 |

减 2 资源同理：若等「已经按印刷费用判过可行性」之后再减，资源不够的牌根本进不了发起池；必须在**路径可行性**里带上 delta。

### 个人版正解

```text
Constant（Chuck ready in play）打开路径目录
  ├─ ① default        PlayAction   delta 0     → 1 action + 印刷资源
  ├─ ② chuck_fast     FastWindow   Exhaust     → 0 action + 印刷资源 + 仅己回合
  └─ ③ chuck_cheap    PlayAction   Exhaust−2   → 1 action + max(0, 印刷−2)
选路径 → evaluate_path（窗 / 横置 / 折后资源）→ 通过后才打开发起
```

完整引擎里目录应随 **InitiationPool 节拍** refresh；本竖切 API 仍是惰性 `offer`/`evaluate`，调用方传 `chuck_ready_id`。

---

## 2. 降低资源费用怎么实现

### 模型

**路径局部折算（path-local fold）**，不是事后 Buff、不是 Would：

```text
effective = max(0, printed_resource_cost + path.resource_cost_delta)
```

- Chuck 减费路径：`resource_cost_delta = -2`
- 默认 / Fast 路径：`resource_cost_delta = 0`
- 折后为 0 → 不生成付费 Intent；仍可能要付路径额外费用（横置）

### 落在可行性的哪一步

| 轴 | 谁改 | 何时看 |
|---|---|---|
| Play 行动 | `PlayForm`（Fast → waive） | `evaluate_path` → `play_action_cost` |
| 资源 | `resource_cost_delta` | 同一次 `evaluate_path` → `effective_resource_cost` |
| 路径额外费用 | `AdditionalCost::Exhaust` | 同一次；不可付 → 路径非法 |

与 AmountPlan 的 FoldStat **同形不同轴**：那边叠伤害/线索量；这里叠**发起费用**。都是「先定轴 → 再 fold → 再 settle」，禁止先按未折算轴发起再改。

### 支付

`effective > 0` 时追加：

`TransferToken { resource, amount: effective, from: player resource_pool, to: $supply }`

（资源池绑 **player**，不绑调查员卡。）

### 和 lasting「费用 −N」的差别（本竖切边界）

| | Chuck 选路径 −2 | 场上 Constant「打出费用 −1」类 |
|---|---|---|
| 寿命 | 单次路径选择 | 常挂 Constraints / FoldCost |
| 互斥 | choose one（与 Fast 等互斥） | 可与多源叠 |
| 本竖切 | `resource_cost_delta` 写在路径上 | **未**做通用 FoldCost 查询 |

通用「打出费用修正」以后可收成对所有路径的 `query_cost` fold；Chuck 的 −2 仍是**选了 cheap 路径才带的 delta**。

---

## 3. 类型与 API

### `InitiationPath` 要点

| 字段 | Fast | Cheap |
|---|---|---|
| `play_form` | `FastWindow` | `PlayAction` |
| `additional_costs` | Exhaust(Chuck) | Exhaust(Chuck) |
| `window` | `DuringControllerTurn` | `None` |
| `resource_cost_delta` | 0 | **−2** |
| `opened_by` | Chuck | Chuck |

### `PathEvalContext`

印刷资源费用、付款玩家、是否己回合 —— 不进静态路径，评估时传入。

### `evaluate_path` 序

1. 窗（仅 Fast Taboo）
2. 额外费用可付？→ exhaust intents
3. `effective = max(0, printed + delta)`；资源够？→ pay intent
4. `play_action_cost = Fast ? 0 : 1`

### `offer_play_paths`

Chuck ready → `[default, chuck_fast, chuck_cheap]`。

---

## 4. 测试

| 测 | 断言 |
|---|---|
| default | action 1；付满印刷资源 |
| chuck_fast | action 0；资源不打折；exhaust + pay |
| chuck_cheap | delta −2；有 2 资源可打印刷 3；默认路径同场面不够 |
| cheap commit | 横置 + 池减少折后量 |
| offer | 三条路径 |
| 已横置 / 非己回合 / 非 Would | 同前 |

`cd arkham_rules && cargo test initiation`

---

## 5. 非范围

- +2 技能选项（多半不改发起费用可行性）
- 通用 lasting FoldCost / 多源叠费
- 完整 Initiation 七步、AOO、效果体；InitiationPool 每拍接线
- Trait 自动过滤；PI 选路径 Gate；gdext

---

## 6. 文件

| 路径 | 角色 |
|---|---|
| `docs/reference/personal-card-text.md` · 09072 | 卡面 SoT |
| `docs/design/39-chuck-initiation-path.md` | 本走查 |
| `arkham_rules/src/initiation/mod.rs` | Fast + cheap |
