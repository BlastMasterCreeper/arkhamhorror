# 39 · Chuck 09072 — Constant 额外费用 → 第二条发起路径

> **竖切**：AHLP-12 · PR 枝 `cursor/fp-chuck-path-18b0`  
> **权威卡面**：[`personal-card-text.md` · 09072](../reference/personal-card-text.md)  
> **Prefs**：Fast = Constant「额外费用 → 第二条发起路径」；**不用** Would / 时点改写  
> **代码**：`arkham_rules/src/initiation/mod.rs`

---

## 0. 一句话

打出 Tactic/Trick 时，**不要**先按无 Fast 的 `PLAY_CARD` 发起再「获得快速」；而是由 Chuck 的 **Constant** 打开一条 **带额外费用的第二条发起路径**，该路径从一开始就是 Fast，从而 **减免整个发起（广义打出）的 Play 行动花费**。

---

## 1. 为什么印刷读法会失败

官方 / Taboo：

> When you play a Tactic or Trick event, exhaust Chuck Fergus: Choose one —  
> That event gains: "Fast. Play only during your turn."

### 失败读法 A：先发起，再 gains Fast

```text
选默认 PLAY_CARD (PlayAction)
  → 有效性：play_action_cost = 1（已定）
  → 发起时点打开…
  → 「gains Fast」
  → 太晚：行动花费盖不住
```

### 失败读法 B：Would 改写已开的发起

- Would 只是提前批时序，**不是**另开时点（prefs）。
- 有效性不过 → **没有**发起时点可改写。
- 鸡生蛋：要靠 Would 把「无 Fast 发起」改成 Fast，但无 Fast 发起已经按耗行动评估过了。

### 个人版正解

```text
Constant（Chuck ready in play）打开路径目录
  ├─ 路径① default     PlayForm::PlayAction   额外费用∅     → cost 1 action
  └─ 路径② chuck_fast  PlayForm::FastWindow   Exhaust(Chuck) → cost 0 action
                         + DuringControllerTurn（Taboo）
选② → 在「发起有效性」阶段就知道 Fast，横置 Chuck，然后才打开发起
```

- **广义打出** = 整个发起流程；**狭义打出** = 结算那一步。个人版额外费用挂在路径上，覆盖广义。
- 种类始终 `PLAY_CARD`（打出不是能力，见 06 §4.2）。

---

## 2. 类型与字段

### `PlayForm`

| 变体 | 含义 | `waives_play_action` |
|---|---|---|
| `PlayAction` | 无 Fast；对称激活触发 | false → cost **1** |
| `FastWindow` | Fast、无时点；Player Window；Taboo 限回合 | true → cost **0** |
| `FastTiming` | Fast + when/after（本竖切未用） | true → cost **0** |

### `AdditionalCost`

个人版「路径额外费用」（**不是** RR「狭义打出结算步才付的 additional cost」）：

- 目前仅 `Exhaust { card_id }`（横置 Chuck）

### `InitiationPath`

一条合法的打出发起方式：

| 字段 | Chuck Fast 取值 | 含义 |
|---|---|---|
| `id` | `path.play.chuck_fast:{chuck}:{event}` | 路径标识 |
| `kind` | `PlayCard` | 仍是打出 |
| `subject_id` | 事件实例 | 被打出的牌 |
| `play_form` | `FastWindow` | 整次发起按 Fast |
| `additional_costs` | `[Exhaust(chuck)]` | 选此路径的价 |
| `window` | `DuringControllerTurn` | Taboo |
| `opened_by` | `Some(chuck)` | Constant 来源 |

默认路径：`opened_by = None`，`additional_costs = []`，`play_form` 跟印刷 Fast 走。

### `PathEvaluation`

选路径后、**打开发起时点之前**的费用视图：

- `play_action_cost: i32` — 广义打出要花的 Play 行动数（Fast → 0）
- `cost_intents: Vec<Intent>` — 付路径额外费用的结算 Intent（如 `SetExhausted`）

---

## 3. API 运行时序

```text
1. 玩家要打出 event E
2. 调用方判断 Chuck 是否 Constant 适用
     （在场、未横置、E 为 Tactic/Trick、同控制器…）
     → chuck_ready_id: Option<&str>
3. offer_play_paths(E, printed_fast, chuck_ready_id)
     → PathOffer { paths: [default, ?chuck_fast] }
4. 玩家选一条 path（PI；本竖切不实现 Gate）
5. evaluate_path(data, path, during_controller_turn)
     → Ok(PathEvaluation) | Err(PathError)
6. 有效性通过后：
     commit(cost_intents)           // 横置 Chuck（CREATED）
     按 play_action_cost 扣行动     // Fast → 不扣
     再进入 PLAY_CARD 发起/七步…   // 本竖切未接
```

### `chuck_fast_path`

直接构造路径②：`FastWindow` + `Exhaust(Chuck)` + `DuringControllerTurn`。

### `evaluate_path` 判定序

1. 窗：`DuringControllerTurn` 且 `!during_controller_turn` → `WindowNotOpen`
2. 逐个 `AdditionalCost`：
   - 卡不存在 → `MissingCard`
   - 已横置 → `SourceExhausted`
   - 否则推入 `SetExhausted { exhausted: true }`
3. `play_action_cost = play_form.waives_play_action() ? 0 : 1`

**关键不变量**：`evaluate_path` 必须在任何发起时点打开之前成功；否则根本不发起（prefs：有效性不过 → 无发起时点）。

### `is_would_rewrite`

恒返回 `false`。路径是**另开的发起**，不是对已开 `PlayAction` 发起的 Would/OnTiming 改写。

---

## 4. 与错误模型对照

| 错误做法 | 本竖切 |
|---|---|
| `[reaction] When you play` 给 Fast | Constant 打开路径目录 |
| RR additional cost 挂在狭义结算步 | `AdditionalCost` 挂在路径上，有效性阶段评估/支付 |
| Would 把 PlayAction 改成 Fast | 直接选 `play_form = FastWindow` 的路径② |
| 先扣 1 action 再 gains Fast | 路径② 的 `play_action_cost = 0` |

---

## 5. 测试（`initiation::tests`）

| 测 | 断言 |
|---|---|
| `default_path_costs_play_action` | 无 Fast → cost 1；无 cost_intents |
| `chuck_fast_path_waives_action_whole_initiation` | FastWindow + 回合窗；cost 0；intent = 横置 Chuck |
| `offer_lists_default_and_chuck_when_ready` | 两路径；第二条 `opened_by = chuck` |
| `offer_only_default_without_chuck` | 仅默认 |
| `exhausted_chuck_blocks_fast_path` | `SourceExhausted` |
| `taboo_window_requires_controller_turn` | `WindowNotOpen` |
| `paying_additional_cost_exhausts_chuck_created` | commit → CREATED + 已横置；再 evaluate 失败 |
| `not_would_by_construction` | `!is_would_rewrite`；`play_form ≠ PlayAction` |

跑：`cd arkham_rules && cargo test initiation`

---

## 6. 非范围（刻意不做）

- 减 2 资源 / +2 技能 另两条选项（可同形再加路径）
- 完整 Initiation 七步、AOO、打出效果体 Composition
- Trait / 所有权自动查询（调用方传 `chuck_ready_id`）
- `PlayerInteractionGate` 选路径
- gdext / Godot 竖切

---

## 7. 文件清单

| 路径 | 角色 |
|---|---|
| `docs/reference/personal-card-text.md` · 09072 | 卡面 SoT |
| `docs/design/39-chuck-initiation-path.md` | 本走查 |
| `arkham_rules/src/initiation/mod.rs` | 类型 + API + 测 |
| `arkham_rules/src/lib.rs` | `pub mod initiation` + re-export |
