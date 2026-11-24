# 35 — 操作合法性的兴趣点（确定可解）

> **状态**：设计草案 v0.2 · 2026-11-24  
> **依赖**：[24-functional-world](24-functional-world.md)、[33-candidate-functions](33-candidate-functions.md)、[34-registration-index-cache](34-registration-index-cache.md)、[25-functional-eff](25-functional-eff.md)、[07 §0 CREATED](07-effect-primitives.md)  
> **裁决**：\(\mathrm{Interest}(\Delta)\) 由 \(\mathrm{Deps}\cap\mathrm{Touched}\) **唯一确定**。`wouldCreate` ⊆ `legal(op)`。  
> **修订 v0.2**：**可行性是函数计算结果的一部分，写入局面派生字段**；不是提交后再维护的会话旁路 `LegalTable`。  
> **宇宙清单**：[36-interest-universe-inventory](36-interest-universe-inventory.md)。

---

## 0. 一句话

`commit` / `step` 的纯函数结果里，就已经带上更新后的可行性。交互端读的是局面值上的派生切片，不是另一张表。

兴趣点只决定**这次结果里重算哪些 op**，不决定「可行性活在何处」。

---

## 0.1 可行性进局面值（v0.2 裁决）

先前 §2 把 `LegalTable` 写成会话态——那是实现顺手的旁路，**不是**你要的模型。改正如下：

```text
World = {
  … physical, registrations, chronicle, audience, framework, …
  index,           -- 登记倒排（派生，可重建）
  feasibility,     -- 发起/must 可行性（派生，可重建）
  meta.gen,
}
```

\[
\mathrm{commit}^+(w,r,\Delta)=(w\{\ldots,\ \Phi\mapsto\Phi'\},\ r')
\]

其中 \(\Phi'\) 由兴趣点算法从 \(\Phi\) 与 \(\Delta\) 算出，与物理/登记写入**同一拍、同一返回值**。

| 性质 | 说明 |
|---|---|
| **派生** | 可由 `(w 去掉 Φ, r, 焦点)` 全量重建；不进「印刷真相」，但进**不可变局面值** |
| **与登记同级管理** | 像 `index`：权威效果仍是 regs/物理；\(\Phi\) 是为查询/交互准备的确定投影 |
| **焦点戳** | \(\Phi.\mathrm{focus\_fp}\) 记录枚举宇宙时的窗/控制者/打开的 must；焦点变了 → 在 `step` 里换宇宙并重填，仍写回 `World.feasibility` |
| **存档** | 可存可不存；加载后若缺则重建。禁止与 regs 冲突时「信 Φ 不信 regs」 |

进度-only 的 bind：若只改 `Run`，函数是

\[
\mathrm{bind}^+(w,r,x)=(w\{\Phi\mapsto\Phi''\},\ r')
\]

must 宇宙的 `viable` 仍写进 **同一** `w.feasibility`（或 `feasibility.B`），不是宿主局部变量。

**交互端**：`getLegalSlice` = 读 `w.feasibility` 在当前 `focus_fp` 下的答案；无第二套 dry_run，无会话表与局面双真相。

---

## 1. 定义

操作 \(\mathit{op}\)：当前焦点下一条**已钉参数**的发起（含种类、控制者、源卡、已绑目标等）。  
焦点 \(f\) 给出宇宙：

\[
\mathrm{Universe}(w,r,f)=\mathrm{enumerateOps}(w,r,f)
\]

（例如：当前打出窗 = 手牌每张可尝试的打出；攻击 = 每个合法粗目标一条 Fight op。宇宙有限、由规则枚举，不靠猜。）

合法性（单一函数，含后果门槛）：

\[
\mathrm{legal}(\mathit{op},w,r)
=
\mathrm{dataOK}(\mathit{op},w,r)
\land
\mathrm{wouldCreate}(\mathit{op},w,r)
\]

\(\mathrm{wouldCreate}\) = 对应该 op 效果树的 dry `interpret` / `plan`（不 `commit`），CREATED 判定与真结算同构。

读集（求值时录制）：

\[
\mathrm{Deps}(\mathit{op})\subseteq\mathrm{Key}
\]

\(\mathrm{Key}\) = 局面键 ∪ 进度键（卡 id、区 id、登记 id、aspect、窗口类、记忆键…）的可列集合。

写入触碰：

\[
\mathrm{Touched}(\Delta)=\bigcup_{i\in\Delta}\mathrm{writes}(i)
\]

每个 `Intent` 的 `writes` **静态可知**（`AddMarker(e,k,_)` → `{card.e.markers.k}`；`RegInsert` → 该登记及倒排键；`PlaceEntity` → 区与卡放置键）。

兴趣点：

\[
\mathrm{Interest}(\Delta)
=
\{\mathit{op}\in\mathrm{Universe}
\mid
\mathrm{Deps}(\mathit{op})\cap\mathrm{Touched}(\Delta)\neq\emptyset\}
\]

**定理（正确性条件）**：若 \(\mathrm{Deps}(\mathit{op})\) 包含上次算出 \(\mathrm{legal}(\mathit{op})\) 时的全部读键，则

\[
\mathrm{Touched}(\Delta)\cap\mathrm{Deps}(\mathit{op})=\emptyset
\implies
\mathrm{legal}(\mathit{op},w',r)=\mathrm{legal}(\mathit{op},w,r)
\]

（\(w'=\mathrm{commit}(w,\Delta)\)，且 \(r\) 的相关键亦未落入 \(\mathrm{Touched}\)；进度-only 的 bind 另算 \(\mathrm{Touched}_{run}\)。）

故：重算且仅重算 \(\mathrm{Interest}\)（外加新建进入 \(\mathrm{Universe}\) 的 op）是**充分必要**的最小重算集——在「Universe 固定、Deps 完整」前提下唯一确定。

---

## 2. 策略（可执行步骤）

### S0. 键空间钉死

规定 `Key` 的代数（有限构造子），例如：

```text
Key =
  | CardField(card_id, field)       -- face, exhausted, location_id, …
  | Marker(card_id, kind)
  | Region(region_id)               -- 成员多重集指纹或 gen 子计数
  | Reg(reg_id) | RegAspect(aspect)
  | FrameworkField(…)
  | RunWindow | RunMemory(key)
  | CatalogConst                    -- 印刷；通常不进 Touched
```

`writes(Intent)` / 读钩子都映射到此代数。无「字符串随便写」。

### S1. 带读环境的合法性

```text
legalTracked(op, w, r) → (Bool, Set Key)
  在读 w/r 的原语上挂钩：每次读记入 ReadSet
  dataOK 与 wouldCreate（dry interpret）共用同一钩子
  返回 (答案, ReadSet) 作为 Deps(op)
```

禁止无钩子的旁路读 Store。

### S2. 局面内的可行性字段（派生）

```text
World.feasibility Φ = {
  focus_fp,                       -- 窗 / 控制者 / 打开的 must Ask
  answers:  Map OpId → { data_ok, effect_ok },
  deps:     Map OpId → Set Key,
  reverse:  Map Key → Set OpId,
}
```

`reverse` 便于 \(\mathrm{O}(|\mathrm{Touched}|)\) 求兴趣点：

\[
\mathrm{Interest}
=
\bigcup_{k\in\mathrm{Touched}}\Phi.\mathrm{reverse}[k]
\cap\mathrm{Universe}
\]

### S3. 融入 `commit` / `step`（不是事后补表）

```text
commitPlus(w, r, Δ) → (w', r'):
  w1 = commit(w, Δ)                     -- 物理 / 登记 / …
  T  = Touched(Δ) ∪ TouchedRun
  U' = enumerateOps(w1, r, focus(r))
  Φ' = refreshFeasibility(w1.feasibility, w1, r, T, U')
  w' = w1 { feasibility ↦ Φ' }
  return (w', r)

refreshFeasibility(Φ, w, r, T, U'):
  new = U' \ dom(Φ.answers); gone = dom(Φ.answers) \ U'
  I = (∪ reverse[k] for k∈T) ∩ U'
  R = I ∪ new
  if |R| too large or deps broken: R = U'
  for op in R:
    (ans, D) = legalTracked(op, w, r)   -- 读 w 时不读 Φ.answers
    写入新的 answers/deps/reverse（持久结构共享）
  drop gone
  return Φ'
```

`legalTracked` **禁止**读 `w.feasibility.answers`（避免派生喂派生）。只读物理、登记、目录与 `Run`。

### S4. 焦点切换

换窗 / 控制者 / 打开 must → `focus_fp` 变：

\[
(w',r')=\mathrm{stepFocus}(w,r,f')
\]

\(w'.\mathrm{feasibility}\) 换宇宙并初次填满；可结构共享旧焦点的另一份缓存切片（可选），但**当前**焦点切片必须完整。

### S5. 静态过近似（可选）

同前：\(\mathrm{Deps}_\supseteq\) 只允许多脏；真算后换成精确读集。

---

## 2.1 更新策略（融入函数，而非旁路）

### 触发（皆为纯函数换新 `World`）

| 事件 | 函数 | \(\Phi\) |
|---|---|---|
| 非空 `commit(Δ)` | `commitPlus` | 按 Interest 刷新 |
| `answer` bind | `bindPlus` | 脏 must 的 viable |
| 换窗 / 开 must Gate | `stepFocus` | 换宇宙并填满 |
| 关 Gate | `stepFocus` | 丢掉 B 宇宙行 |
| 读档缺 \(\Phi\) | `rebuildFeasibility` | 全量 |
| 对拍失败 | 同上兜底 | 全量 |

纯 `view(w)`：**不**改 \(w\)；直接读 \(w.\mathrm{feasibility}\)。

### A / B 同字段分区

```text
OpId = InitOp(...) | BindOp(ask_id, candidate_id)
answers[op] = { data_ok, effect_ok }
```

发起要两者皆真；UI 可分色。费用不进 `effect_ok`。

### 交互端

读 `w.feasibility.answers`（当前 `focus_fp`）。  
`step`/`answer` 返回的新 `World` 已含新 \(\Phi\)——可行性已在函数结果里，无需「先回 UI 再异步更新表」。

### 不变式

1. 任一对外暴露的 `World`：若焦点匹配，则 `Universe` 内每条 op 在 \(\Phi.answers\) 中有值。  
2. \(\Phi\) 与 regs/物理冲突时，以 regs/物理为准并重建 \(\Phi\)。  
3. `legalTracked` 不读 \(\Phi.answers\)。

---

## 3. 与「人为兴趣点」的关系

| | 人为兴趣域 | 本策略 |
|---|---|---|
| 定义 | 经验桶（手牌、交战…） | \(\mathrm{Interest}(\Delta)\) 公式 |
| 对错 | 可能过脏或漏脏 | Deps 完整 ⇒ 不漏；过脏只来自过近似 |
| 角色 | 可作 `enumerateOps` 的**宇宙边界** | 宇宙内谁脏，交给公式 |

人为方法留下的价值：界定 **Universe**（当前玩家关心的操作集）。  
桶内增量：交给 \(\mathrm{Deps}\cap\mathrm{Touched}\)。

---

## 4. 复杂度（确定性）

设 \(t=|\mathrm{Touched}|\)，\(d\) 为平均反向扇出，\(c\) 为单次 `legalTracked` 代价：

\[
\mathrm{T}_{update}=\mathrm{O}(t\cdot d\cdot c)\quad\text{（重算 }|\mathrm{Interest}|\text{ 次）}
\]

全量重算则为 \(\mathrm{O}(|\mathrm{Universe}|\cdot c)\)。  
策略不改变单次 `legal` 的语义代价，只把次数从 \(|\mathrm{Universe}|\) 降到 \(|\mathrm{Interest}|\)，且集合可算。

---

## 5. 验收

| ID | 条件 |
|---|---|
| L1 | 随机 \(\Delta\)：跳过重算的 op，其 `legal` 与全量重算逐位相等 |
| L2 | `Touched`∩`Deps`≠∅ 的 op 必须出现在 `Interest` |
| L3 | 无钩子读路径（审计：测试下读计数器） |
| L4 | `wouldCreate` 与真 `interpret` 同树；禁止 UI 第二套 dry_run |

---

## 6. 裁决

| # | 裁决 |
|---|---|
| J1 | \(\mathrm{Interest}(\Delta)\) 由 \(\mathrm{Deps}\) 与 \(\mathrm{Touched}\) 的交**唯一确定**（Universe 给定、Deps 完整时） |
| J2 | `wouldCreate` ∈ `legal`；兴趣点策略覆盖全部试算次数，不覆盖掉试算语义 |
| J3 | 依赖以 **动态录读** 为权威；静态分析仅作过近似引导 |
| J4 | **可行性 \(\Phi\) 是 `World` 派生字段**；由 `commitPlus`/`step` 一并算出；可重建，不与 regs 双真相 |
| J5 | 人为兴趣域只界定 Universe，不替代 \(\mathrm{Interest}\) |
| J6 | 禁止会话旁路 `LegalTable` 与 `World.feasibility` 并存为两套答案 |

---

## 7. 修订

| 日期 | 说明 |
|---|---|
| 2026-11-24 | v0.1：定义、定理条件、S0–S5 步骤、倒排 Interest、验收 |
| 2026-11-24 | v0.2：可行性融入局面值；废「会话 LegalTable 为主」；`commitPlus` |
