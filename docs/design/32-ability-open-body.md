# 32 — 能力的函数重抽象：开口 + 执行

> **状态**：设计草案 v0.1 · 2026-11-24  
> **依赖**：[06-ability-initiation](06-ability-initiation.md)、[06-registration-payload-model](06-registration-payload-model.md)、[07-composition](07-composition.md)、[27-eff-eval-detail](27-eff-eval-detail.md)、[28-functional-scheme](28-functional-scheme.md)、[30-functional-primer](30-functional-primer.md)  
> **裁决**：印刷上的 Constant / Forced / 反应 / 免费 / 激活 / 显现，以及「看起来一直生效」的数值句，**一律**抽象成 **开口（Open）+ 执行（Body）**。不存在「无时点、只悬浮在局面上的魔法」。  
> **候选**：[33-candidate-functions](33-candidate-functions.md)（合法集 = 纯函数；确认 = Ask）。

---

## 0. 一句话

**时点与效果执行分开**（大信封 vs `Eff`）之后，能力侧也必须同一刀：

\[
\mathrm{Ability}
=
\{\,\mathrm{open}:\mathrm{OpenSpec},\ \mathrm{body}:\mathrm{Body}\,\}
\]

- **开口**：规则允许这句话**说话**的求值点（显式槽，或隐式查询/门槛点）。  
- **执行**：开口成立后做什么——嵌套/`Eff` 结算，或纯投影折叠（改读数、贡献限制）。

纸面的 AbilityKind（Constant、Forced…）是**编译标签**，不是第二套运行时分支。运行时只认 `OpenSpec` 落在哪一类开口点。

---

## 1. 为何 Constant 仍是「时点 + 执行」

Grimoire 写 Constant 为持续生效，读起来像「没有 When」。抽象后：

| 纸面感觉 | 函数事实 |
|---|---|
| 「你的战斗 +1」一直在 | 每次 **读有效战斗值** 时开口；body = 把 `+1` 折进投影 |
| 「你不能打出事件」一直在 | 每次 **发起打出 / Eligibility** 时开口；body = 贡献一条 RESTRICTION |
| 「视为拥有猎手」 | 每次 **有效关键词查询** 或 Enemy 3.2 收集猎手时开口 |

「持续」描述的是 **寿命（lifetime）**：在场期间，这些开口点**反复**可触发。  
不是描述「引擎后台无限循环跑效果」。

因此 **隐式时点（implicit timing）** = 规则书没写成 When/After，但引擎求值时仍必须留出的开口点。

---

## 2. 开口点分类（OpenKind）

```text
OpenKind =
  | Slot(flow_id, slot)           -- 显式：Would / When / After / Resolve 砖
  | AtQuery(query_id)             -- 隐式：读投影时（技能、生命、关键词、连通…）
  | AtGate(gate_id)               -- 隐式：Eligibility / Intent / L7 / 费用门
  | AtWindow(window_kind)         -- 玩家窗：发起池 / 响应池加入候选
  | AtFramework(step_id)          -- 框架步砖（如 Upkeep 4.3 重整收集）
```

| OpenKind | 谁驱动 | 典型能力 |
|---|---|---|
| `Slot` | 大信封议程走到该槽 → COLLECT | Forced、`[reaction]`、部分 Delayed LISTENER |
| `AtQuery` | `view` / `effective_*` 被调用 | Constant 数值、KEYWORD 并集、部分「视为」 |
| `AtGate` | 发起/门槛求值 | Constant Cannot、Fast 窗口限制、commit_only |
| `AtWindow` | 打开发起池或响应池 | `[free]`、无时点快速打出对称、`[action]` 经 Activate |
| `AtFramework` | 框架议程某砖 | 阶段强制收集、猎手移动砖 |

**规则**：凡能改「玩家看见的规则答案」或「能否发起」的印刷句，必须能指出一个 `OpenKind`。说不出开口 = 翻译未完成。

---

## 3. 执行体分类（Body）

开口之后，body 只有两类（可再组合）：

```text
Body =
  | Settle(Eff)              -- 要结算：走 interpret；常 Nest 已有 seq
  | Fold(ProjectionDelta)    -- 只参与本次投影/门槛：MODIFIER / RESTRICTION / 特征并集
```

| Body | 改 `World`？ | CREATED？ | 例子 |
|---|---|---|---|
| `Settle(Eff)` | 经 `commit` 可以 | 按叶原语 | Forced 抽 1；反应造成伤害；显现树 |
| `Fold(Δ)` | **否**（本次调用纯） | 否 | +1 fight；cannot；有效关键词 |

Constant **绝大多数**是 `Fold`。  
若 Constant 文案实际在某时点强制做事（少见，常被误标），编译时应改挂 `Slot` + `Settle`，不要假装成 Fold。

登记（Register）出来的 lasting：

- 数值 / 限制 → 仍是 `AtQuery` / `AtGate` + `Fold`（寿命未到期则每次开口都在候选集里）  
- 「直到回合结束，成功躲避后抽 1」→ `Slot(…, AFTER)` + `Settle`（行为 LISTENER；≠ 印刷 Forced 这个标签）

---

## 4. 印刷能力类型 → (Open, Body)

| 印刷 / 标签 | 默认 Open | 默认 Body | 备注 |
|---|---|---|---|
| **Constant**（数值） | `AtQuery(stat)` | `Fold(MODIFIER)` | 「持续」= lifetime ∩ 在场 |
| **Constant**（Cannot / 只可…） | `AtGate(intent)` | `Fold(RESTRICTION)` | 原流程读限制后改道，不是 Cancel |
| **Constant**（视为关键词/特性） | `AtQuery(keyword\|trait)` | `Fold(并集)` | 与 Gain 特征查询同形 |
| **Forced** | `Slot(seq, WHEN\|AFTER)` | `Settle(Eff)`；可先 `ORDER_FORCED` | 窗到自动；≥2 条同优先要 Ask 排序 |
| **`[reaction]`** | `Slot` → 进响应池 | `Settle`；先 `PICK_RESPONSE` | 可选 |
| **`[free]`** | `AtWindow(player)` 或文本 Slot | `Settle` + 费用门 | ArkhamDB 文本 `[fast]` 常指这类 |
| **`[action]`** | Activate / `AtWindow` + 耗行动 | `Settle` | 经行动外壳 |
| **显现 Revelation** | `Slot(revelation 入口, RESOLVE)` | `Settle` | 遭遇 vs 入手入口不同，body 仍是树 |
| **打出** | **不是能力**；`PLAY_CARD` 包装时点 | 效果体 `Settle` | Fast 只改窗口/花费对称 |
| **关键词 ③**（猎手、涌动…） | `AtFramework` 或父手续砖 / Slot | `Settle` 或衍生挂载 | ① 参数、② 原流程读、③ 订阅，见 07 §0.1 |
| **Spawn / Prey 指令** | 非 Ability；砖内读 Spec | — | 不 nest 成能力 |

编译期 tags 仍可保留 Grimoire 名，便于对照；**求值器只看 Open/Body**。

---

## 5. 隐式时点目录（第一批）

这些开口必须进 Catalog（与 `seq.*` 并列的 **QueryId / GateId**），禁止靠「读卡面自然语言」临时分支。

| Id | 何时开口 | 收集谁 | 合并规则 |
|---|---|---|---|
| `query.stat.fight` 等 | 读有效技能/固定值 | 匹配的 Constant / MODIFIER | 求和或规范层 |
| `query.keyword` | `has_effective_keyword` | 印刷 ∪ Gain KEYWORD ∪ 视为 | 并集；Surge 等另有不叠加律 |
| `query.trait` | 特性查询 | 同上 | 并集 |
| `gate.play_card` | 打出 Eligibility | Cannot / 只可 / Fast 窗 | RESTRICTION 层 + Silver Rule |
| `gate.commit` | 投入门槛 | commit_only 等 | 同上 |
| `gate.initiate` | 能力发起 L0–L5 | 限制与情景 | 见 06 |
| `framework.enemy_3_2` | 敌方阶段猎手/巡逻砖 | 有效猎手/巡逻 | 框架议程内 Settle 移动 |

扩表原则：**每加一种「读规则答案」的 API，就加一条 OpenId**；Constant 编译时绑定到具体 OpenId，而不是挂一个虚空「always」。

---

## 6. 与大信封、登记的关系

```text
大信封议程（手续时点）
  └─ Slot 开口：COLLECT 显式能力 → Ask? → Nest/interpret(Settle)

查询 / 门槛（隐式时点）
  └─ AtQuery / AtGate：COLLECT Fold 候选 → 纯函数折进 Answer
       （不 push 手续帧；不 commit）

Register
  └─ 只改变「哪些 Ability/Δ 仍在候选集」（寿命）
       不代替 Open；不发明第二套「持续引擎」
```

禁止：

- 把 Constant 做成每帧 tick 的 `Settle`  
- 把「查询时折 MODIFIER」写成真空改 `World`  
- 为 Constant 单卡建 `seq.card…`  
- 说「Constant 没有时点所以函数化管不了」

---

## 7. 函数接口

```text
collect(open, world, env) → List(AbilityRef)     -- 纯：按 OpenId + lifetime + 情景

fold(open, world, env, base) → Answer            -- 纯：对 Fold body 规范合并

fire(open, world, run, ref) → Outcome            -- Settle：常 Nest；可 NeedAsk
```

显式槽的 `fire` 走既有信封/池回路。  
隐式查询只调用 `collect` + `fold`，**永不**在 `view` 里 `commit`。

---

## 8. 对现文档的修订声明

| 原文感觉 | 本裁决 |
|---|---|
| 06：Constant 在「查询 modifier 时」发起 | **保留**；上升为正式 `OpenKind::AtQuery`，与 Slot 并列 |
| 06：Constant lazy、不注册 listener | **保留其意**：不进响应池；改为「绑在 QueryId 上的 Fold 候选」 |
| 07：hook 订 `(seq, slot)` | **显式能力**的 Open；Constant 的 hook 是 `AtQuery`/`AtGate`，不是空 hook |
| 「持续效果」口语 | 一律拆成 **lifetime + Open + Body** |

---

## 9. 裁决表

| # | 裁决 |
|---|---|
| A1 | 一切能力（含 Constant）= **Open + Body** |
| A2 | 「持续」只描述 **lifetime**，不描述无开口的悬浮语义 |
| A3 | 隐式时点必须 **Catalog 化**（QueryId / GateId / Framework 砖） |
| A4 | Constant 默认 **Fold**；真要结算则重挂 **Slot + Settle** |
| A5 | 查询路径 **只读**；禁止在 `view`/`effective_*` 里 `commit` |
| A6 | 印刷 AbilityKind 是标签；求值只认 Open/Body |

---

## 10. 修订

| 日期 | 说明 |
|---|---|
| 2026-11-24 | v0.1：Open/Body；隐式时点；Constant 重抽象；能力类型对照表 |
