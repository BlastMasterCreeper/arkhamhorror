# 34 — 登记索引与查询缓存

> **状态**：设计草案 v0.1 · 2026-11-24  
> **依赖**：[24-functional-world](24-functional-world.md)、[30-functional-primer](30-functional-primer.md)、[32-ability-open-body](32-ability-open-body.md)、[33-candidate-functions](33-candidate-functions.md)  
> **问题**：Eligibility / L7 / 有效数值会**反复**问「这个目标现在受哪些登记影响」。全表扫 `registrations` 正确但不耐用。  
> **目标**：在 **唯一 `commit` 写入口** 下，给出可与不可变 `World` 共存的索引与缓存。

---

## 0. 分层

```text
权威层   World.registrations          唯一真相
索引层   World.index                  commit 时与权威同步更新（派生，可重建）
缓存层   QueryCache（World 外或 View）  按局面代数记忆 effective / gate 答案
```

| 层 | 丢了怎么办 | 可否进存档 |
|---|---|---|
| 权威 | 不可丢 | 是 |
| 索引 | 可从权威全量重建 | 可选（为少一次重建可随快照） |
| 缓存 | 丢了只变慢 | **否** |

---

## 1. 登记主语与方面（索引键从哪来）

```text
Registration.subject =
  | Bound(card_id)
  | Matching(filter_id)      -- 动态；不能钉死在单一 card_id

索引 aspect **由载荷 body 派生**（非壳字段）：
  | Stat ← modifier.stat
  | Gate ← gate.kind
  | Directive ← directive.kind
  | Status ← status.kind
  | Listener ← listener.timing
  -- Gain 特征不是 Registration 载荷；不进此索引轴
```

查询原语（纯）：

\[
\mathrm{regsAffecting}(w,e,a)=\mathrm{lookup}(w.\mathrm{index},e,a)
\]

\[
\mathrm{effective}(w,e,a)=\mathrm{combine}(\mathrm{printed},\mathrm{regsAffecting}(w,e,a))
\]

---

## 2. 索引结构（随 `World` 一起不可变）

```text
RegIndex = {
  by_id:          Map RegId → Registration      -- 可与 registrations 同表
  by_bound:       Map CardId → Set RegId         -- subject = Bound(e)
  by_aspect:      Map Aspect → Set RegId         -- 该行任一带 aspect 的 payload
  by_bound_aspect:Map (CardId×Aspect) → Set RegId  -- 热路径交叉
  matching_by_aspect: Map Aspect → Set RegId     -- subject = Matching(_)
  by_source:      Map CardId → Set RegId         -- 退场批量卸
  gen:            Nat                            -- 每 commit 一次 +1（见 §4）
}
```

热路径（钉死主语）：

\[
\mathrm{lookup\_bound}(w,e,a)=w.\mathrm{index}.\mathrm{by\_bound\_aspect}[(e,a)]
\]

动态主语：

\[
\mathrm{lookup\_matching}(w,e,a)
=
\{\rho\mid \rho\in w.\mathrm{index}.\mathrm{matching\_by\_aspect}[a],\ \mathrm{covers}(\rho,e,w)\}
\]

\[
\mathrm{regsAffecting}= \mathrm{lookup\_bound}\cup\mathrm{lookup\_matching}
\]

`Matching` 行预期远少于 `Bound`。`covers` 用 [33](33-candidate-functions.md) 的过滤，**不** Ask。

### 2.1 在 `commit` 里更新（路径复制）

只在这些意图上碰索引：

| Intent | 索引动作 |
|---|---|
| `RegInsert(ρ)` | 写入 `by_id`；按 `subject`/`aspects` 插入各 Set（持久集合共享尾部） |
| `RegRemove(ids)` / 按 filter 删 | 从各 Set 去掉；`by_source` 便于退场一次摘清 |
| 其它 Intent（移牌、加标记…） | **索引行内容不变**；只 `gen+1`（因 `Matching.covers` 可能变） |

持久 `Map`/`Set`（分片或 HAMT）下，改一个 `CardId` 的集合是 \(\mathrm{O}(\log n)\)，不是重建整张表。

**不变量**：任意时刻可由 `registrations` 跑 `rebuildIndex(regs)` 得到与 `index` 相同的多集。测试金样：随机 commit 后 `index == rebuild(regs)`。

---

## 3. 缓存（答案记忆，不是第二真相）

Eligibility 同一窗口内会连续问：「能打出吗」「这张事件呢」「dry-run 这个目标」。适合缓存的是**答案**，不是登记行。

```text
QueryCache = {
  world_gen: Nat,                    -- 必须等于 World.index.gen
  effective: Map (CardId×Aspect) → Int 或 Answer
  gate:      Map (CardId×GateId) → Bool  -- 或更细的 Eligibility 切片
  covers:    Map (RegId×CardId) → Bool   -- Matching 命中备忘（可选）
}
```

命中条件：

\[
\mathrm{cacheHit}(c,w,k)\iff c.\mathrm{world\_gen}=w.\mathrm{index}.\mathrm{gen}\land k\in c
\]

未命中则算 \(\mathrm{effective}\) / \(\mathrm{gate}\)，写入**新**缓存值（或原地换缓存，因缓存不在权威 `World` 内）。

### 3.1 缓存放哪

| 方案 | 做法 | 适用 |
|---|---|---|
| **A. View 附带**（推荐默认） | `view(w)` 得到 `(WorldView, QueryCache)`；同一次驱动循环共用 | Godot/Rust 宿主一帧内多次门槛 |
| **B. 线程/会话旁路** | `Run` 旁挂 `QueryCache`，`commit` 后若 `gen` 变则整表丢弃 | 实现简单 |
| **C. 塞进 World** | 禁止把可变答案表当成局面字段 | 易与存档/重放纠缠 |

推荐 **A 或 B**。`World` 只带 **索引**；**缓存**跟「当前正在求值的那次 view」走。

### 3.2 失效策略

| 事件 | 索引 | 缓存 |
|---|---|---|
| `RegInsert` / `RegRemove` | 点状更新 + `gen++` | **整表失效**（或按 `by_bound` 精细剔，见下） |
| `PlaceEntity` / 换区 / 换地点 | 索引内容可不动；`gen++` | 整表失效（`Matching` 与地点门槛） |
| `TransferMarkers` / 纯标记 | `gen++` | 可只剔依赖该标记的 aspect；P0 先整表失效 |
| 纯 `Ask` bind（只改 Run） | 不动 | **可保留**（答案不依赖记忆时） |

P0（先正确再快）：

\[
\mathrm{commit}(w,is)=w'\ \Rightarrow\ \mathrm{cache}'=\mathrm{empty}(\mathrm{gen}(w'))
\]

P1（细粒度）：`RegInsert` 且 `Bound(e)` 时只删 `effective`/`gate` 里键涉及 `e` 的项，以及全局 `Matching` 相关键；移牌则删所有 `matching` 备忘与地点类 gate。

---

## 4. 局面代数 `gen`

```text
World.meta.gen : Nat    -- 或挂在 index.gen
```

每次成功 `commit`（即使 Intent 列表导致索引结构共享未改指针）也 **+1**，只要有任何可能影响投影的物理/信息写入。  
空 `commit(w,[])` 不增加。

缓存与追踪都以 `gen` 为世代。重放：只存 Intent 流 + 权威；索引可重建；缓存不入 Trace。

---

## 5. 热路径伪码

```text
effective(w, cache, e, a):
  if cache.gen != w.index.gen: cache = empty(w.index.gen)
  key = (e, a)
  if key in cache.effective: return cache.effective[key], cache
  regs = w.index.by_bound_aspect[(e,a)]
       ∪ filter covers(w,e) of w.index.matching_by_aspect[a]
  ans = combine(printed(e,a), regs)
  cache.effective[key] = ans
  return ans, cache

gateAllows(w, cache, e, g):
  -- 同形；regs 来自 aspect = Gate(g)
```

Eligibility 一轮对同一 `e` 问多个 gate：第一次填缓存，其后命中。

---

## 6. 与能力挂/卸时点的关系

Constant 等在**登记时点** `commit(RegInsert)` → 索引点状更新 + `gen++` → 缓存失效。  
之后门槛反复检测只走 `lookup` + 缓存，**不再**跑能力 body。

退场 `RegRemove` 经 `by_source[card]` 批量摘索引，避免漏卸。

---

## 7. 度量与验收

| 指标 | P0 目标 |
|---|---|
| `regsAffecting` Bound 热路径 | 不扫全表；经 `by_bound_aspect` |
| 单次 Player Window 内重复 `gate.play` | 同 `gen` 下第二次起缓存命中 |
| `index` 与 `rebuild` | 属性测试恒等 |
| 缓存 | 不进存档；换 `gen` 无脏读 |

---

## 8. 裁决

| # | 裁决 |
|---|---|
| I1 | 索引是 `World` 的派生字段，仅 `commit` 维护，可全量重建 |
| I2 | 缓存在 View/会话，键含 `gen`；P0 任意写入后整表失效 |
| I3 | Bound 走倒排；Matching 走按 aspect 的小表 + `covers` |
| I4 | 退场用 `by_source` 批量卸；禁止只删卡留登记 |
| I5 | 缓存不是真相；调试以 `registrations` 为准 |

---

## 9. 修订

| 日期 | 说明 |
|---|---|
| 2026-11-24 | v0.1：RegIndex 形、commit 维护、QueryCache+gen、热路径与失效 |
