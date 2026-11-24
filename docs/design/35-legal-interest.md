# 35 — 操作合法性的兴趣点（确定可解）

> **状态**：设计草案 v0.1 · 2026-11-24  
> **依赖**：[33-candidate-functions](33-candidate-functions.md)、[34-registration-index-cache](34-registration-index-cache.md)、[25-functional-eff](25-functional-eff.md)、[07 §0 CREATED](07-effect-primitives.md)  
> **裁决**：\(\mathrm{Interest}(\Delta)\) **不是**凭经验砍负载的启发式；在已定 `Universe` 与录读语义下，它由集合运算**唯一确定**。后果门槛（`wouldCreate`）⊆ `legal(op)`，不另开旁路试算。

---

## 0. 一句话

每次局面写入后，只重算「依赖集与本次写入触碰集相交」的那些操作合法性。交谁、不算谁，由公式给出，不是调参。

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

### S2. 维护表（会话态，非权威 World）

```text
LegalTable = {
  universe_id,                    -- 当前焦点指纹
  answers:  Map OpId → Bool,
  deps:     Map OpId → Set Key,
  reverse:  Map Key → Set OpId,   -- 倒排：键 → 谁依赖它
  world_gen, run_fp
}
```

`reverse` 由 `deps` 派生，便于 \(\mathrm{O}(|\mathrm{Touched}|)\) 求兴趣点：

\[
\mathrm{Interest}
=
\bigcup_{k\in\mathrm{Touched}}\mathrm{reverse}[k]
\cap\mathrm{Universe}
\]

### S3. 提交后更新

```text
onCommit(Δ):
  T = Touched(Δ) ∪ TouchedRunIfAny
  I = ∪ { reverse[k] | k ∈ T }
  # Universe 可能变（入手/打出）：
  U' = enumerateOps(w', r, f)
  new = U' \ U
  gone = U \ U'
  drop gone from tables
  for op in (I ∩ U') ∪ new:
    (ans, D) = legalTracked(op, w', r)
    update answers[op], deps[op], reverse
  # 不在 I∪new 中的 op：answers 保持不变（由 §1 定理）
```

### S4. 焦点切换

换窗 / 换控制者 → 新 `Universe`：对尚未有 `deps` 的 op **初次** `legalTracked`；旧宇宙可丢或按焦点缓存多份表。

### S5. 静态过近似（可选加速首次）

对 Catalog 模板做 \(\mathrm{Deps}_\supseteq(\mathrm{template})\)（效果树可能读的键上界）。  
尚未动态录过的 op 先用过近似进 `reverse`，宁可多进 \(\mathrm{Interest}\)，不可漏。第一次真算后换成精确 `Deps`。

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
| J4 | `LegalTable` 是会话派生态；不进存档级 `World` |
| J5 | 人为兴趣域只界定 Universe，不替代 \(\mathrm{Interest}\) |

---

## 7. 修订

| 日期 | 说明 |
|---|---|
| 2026-11-24 | v0.1：定义、定理条件、S0–S5 步骤、倒排 Interest、验收 |
