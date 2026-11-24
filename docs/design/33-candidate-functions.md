# 33 — 候选目标的函数式表达

> **状态**：设计草案 v0.1 · 2026-11-24  
> **依赖**：[21-selection-spec](21-selection-spec.md)、[16-player-interaction](16-player-interaction.md)、[30-functional-primer](30-functional-primer.md)、[32-ability-open-body](32-ability-open-body.md)  
> **裁决**：合法候选集是 **纯函数**；玩家确认是 **询问**；答案只进进度记忆。不 nest `seq.choose.*`。

---

## 0. 一句话

选谁，先算集合，再问人。集合的计算不改局面。

\[
\mathrm{candidates}(w,r,f)=\mathrm{V}(\mathrm{N}(\mathrm{S}(\mathrm{U}(w,r,f),w,r,f),w,r,f),w,r,f)
\]

其中 \(f\) 是静态过滤规格（`CandidateFilter`），\(w\) 是局面，\(r\) 是进度（只读记忆里已有的指称）。

---

## 1. 类型

\[
\begin{align*}
f &:\ \mathrm{Filter} \\
\mathrm{U},\mathrm{S},\mathrm{N},\mathrm{V}
  &:\ \mathrm{World}\times\mathrm{Run}\times\mathrm{Filter}\times\mathrm{List}(\mathrm{Id})
    \to\mathrm{List}(\mathrm{Id}) \\
\mathrm{candidates}
  &:\ \mathrm{World}\times\mathrm{Run}\times\mathrm{Filter}
    \to\mathrm{List}(\mathrm{Id}) \\
\mathrm{default}
  &:\ \mathrm{List}(\mathrm{Id})\times\mathrm{DefaultPolicy}\to\mathrm{Id}?
\end{align*}
\]

`Filter` 的字段与 [21 §3](21-selection-spec.md) 白名单同构（`entity`、`zones`、`at`、`traits`、`preds`…）。  
编译期定死；**不含**本次选中的 id。

---

## 2. 四层过滤（合成）

记 \(X_0=\mathrm{U}(w,r,f)\)，再

\[
X_{k+1}=P_{k+1}(X_k,w,r,f),\quad P\in\{\mathrm{S},\mathrm{N},\mathrm{V}\}
\]

| 层 | 公式含义 | 读什么 |
|---|---|---|
| \(\mathrm{U}\) | 粗宇宙：按实体类与区/地点寻址列出 id | `cards` / `regions` / `at` |
| \(\mathrm{S}\) | 结构谓词：特性、关键词、横置、交战… | 卡字段 + `AtQuery` 有效关键词 |
| \(\mathrm{N}\) | 数值谓词：`preds` 与投影比较 | `fold` 后的有效值（见 32） |
| \(\mathrm{V}\) | 可行性：对该候选 dry-run 后续体，要能 CREATED | 只读试算；**不** `commit` |

短路：

\[
X_k=[\,]\ \Rightarrow\ \mathrm{candidates}=[\,]
\]

空集 → **不发起 Ask**（整段常 L7 失败或跳过，按入口政策）。

限制类 Buff **不**另开真相层：它使 \(\mathrm{V}\) 对某 id 无 CREATED，从而被剔除。与活结算同入口。

---

## 3. 从候选到询问

\[
\mathrm{req}(s,w,r)
=
\{
  \mathrm{kind}=s.\mathrm{kind},\ 
  \mathrm{候选}=\mathrm{candidates}(w,r,s.f),\ 
  \mathrm{默认}=\mathrm{default}(\mathrm{候选},s.\mathrm{policy})
\}
\]

效果树里的选择节点：

\[
\llbracket \mathrm{Ask}(s,k) \rrbracket(w,r)
=
\begin{cases}
\mathrm{Halt}(\ldots)
  & \text{若 }\mathrm{候选}=[\,]\ \text{且政策要求必须有目标}\\[0.5em]
\mathrm{NeedAsk}(w,r,\mathrm{req}(s,w,r),
  \lambda x.\,\llbracket k(x)\rrbracket(w,\mathrm{bind}(r,x)))
  & \text{否则}
\end{cases}
\]

\[
\mathrm{bind}:\mathrm{Run}\times\mathrm{Id}\to\mathrm{Run}
\]

只改进度记忆（`RulesMemory` 的值对应物）。**不**写 `World`。

超时：

\[
\mathrm{drive}(\mathrm{NeedAsk}(c,q,\mathrm{resume}))
=
\mathrm{resume}(\mathrm{answerOrDefault}(q))
\]

---

## 4. 与能力开口、大信封的关系

| 场景 | 候选函数用在哪 |
|---|---|
| 卡面「选一个连结地点的敌人」 | Resolve 体内 `Ask`；\(f=\) connecting enemy 过滤 |
| When 槽多条 Forced 排序 | 候选是 **能力引用** 列表，不是卡 id；仍是 \(\mathrm{collect}(\mathrm{Slot},\ldots)\) |
| 响应池挑一条 | 候选 = 池内可选项；`PICK_RESPONSE` |
| Constant / 查询 | **无**目标 Ask；是 `fold`，不是 `candidates`→Gate |
| Fight 选敌 | 行动入口的隐式目标：同一 \(\mathrm{candidates}\)，政策「无合法 → 整行动失败」 |

能力 COLLECT 与目标枚举同形，只是元素类型不同：

\[
\mathrm{collect}(\mathrm{open},w,r):\mathrm{List}(\mathrm{AbilityRef})
\]

\[
\mathrm{candidates}(w,r,f):\mathrm{List}(\mathrm{CardId})
\]

都是纯的；前者喂时点议程，后者喂 `Ask`。

---

## 5. 并列最值（most / nearest）

在 \(\mathrm{S}\)（或 \(\mathrm{N}\)）之后、进 Gate 之前：

\[
\mathrm{ties}(X,w,m)=\{x\in X\mid m(w,x)=\max_{y\in X}m(w,y)\}
\]

\(m\) 是纯度量（线索数、距离）。\(\mathrm{ties}\) 仍可能多元素 → Gate 或队长决胜；**不是**新的 nest 手续。

---

## 6. 禁止项（函数版）

| 禁止 | 应写成 |
|---|---|
| `seq.choose.*` nest | `Ask` + \(\mathrm{candidates}\) |
| 枚举时 `match` 卡面自然语言 | 静态 `Filter` 白名单字段 |
| 把本次选中 id 写进静态树 | `bind` 进 \(r.\mathrm{memory}\) |
| 在 \(\mathrm{U}\)–\(\mathrm{V}\) 里 `commit` | dry-run 只读 |
| 为每种约束加机制布尔 | `preds` / 结构字段增长表 |

---

## 7. 裁决

| # | 裁决 |
|---|---|
| C1 | \(\mathrm{candidates}\) 是纯函数；唯一副作用边界是 `NeedAsk` |
| C2 | 四层 \(\mathrm{U}\circ\mathrm{S}\circ\mathrm{N}\circ\mathrm{V}\) 顺序固定；空集短路 |
| C3 | 答案只 \(\mathrm{bind}\) 到进度；消费方读记忆或 nest 环境拷贝 |
| C4 | 与 21 的 SelectionSpec / Gate **同构**；本文给类型与公式 |

---

## 8. 修订

| 日期 | 说明 |
|---|---|
| 2026-11-24 | v0.1：candidates 公式、四层合成、Ask 衔接、与能力 collect 对照 |
