# 38 — 函数世界（Data）说明

> **状态**：说明稿 v0.1 · 2026-11-25  
> **目的**：用数学 / FP 口径定义「世界」是什么；**不是**桌上模拟隐喻。  
> **形状落地**：[37-world-structure](37-world-structure.md)（字段与类型）  
> **Eff / 步骤**：[25-functional-eff](25-functional-eff.md)  
> **CREATED / 原语**：[07-effect-primitives](07-effect-primitives.md)

---

## 0. 一句话

**函数眼里的世界 = `Data`：**  
一次 `query` / `plan` / `commit` / `step` 所闭包的、**可被 Intent 改写**的全部权威载体。

```text
World_FP  ≜  Data
```

卡在哪个区、token 堆、交战 Relation、lasting +1、cannot、延时听——**凡满足下面三条的，都在世界里**：

1. **要进存档 / 重放**（丢掉则局面不可还原）；  
2. **`commit(Intent)` 可以改它**；  
3. **改或不改会改变未来的** `query` / `legal` / `step`。

---

## 1. 主划分（运算闭包）

```text
Snapshot = {
  data:     Data,       -- 函数世界（权威载体）
  control:  Control,    -- Run：栈 / 选择 / 焦点 / 步间 memory
  derived:  Derived,    -- 由 data（+ control.focus）唯一可算
  gen:      Int
}

Catalog ∉ Snapshot      -- 静态理论（印刷、flow 定义）；对局中不变
```

| 袋 | 是世界吗？ | 角色 |
|---|---|---|
| **Data** | **是（World_FP）** | Intent 的唯一改写对象 |
| **Control（Run）** | 否 | 解释器拉链；手续结束可清 |
| **Derived** | 否 | 视图 / 索引 / Φ；可 rebuild |
| **Catalog** | 否 | 外置常量 |

运算形：

```text
query  : Data × Catalog × Spec → Answer
plan   : Data × Control × Catalog × Eff → Intent[]
commit : Data × Intent[] → Data              -- 唯一改世界
step   : Data × Control × Catalog × Eff
           → (Data × Control) | NeedAsk
```

**CREATED**（发起有效性 / L7 dry-run）= 某次（沙盒）`commit` 使 **Data** 在结算排序上发生了变化。  
Audience 可标成 Data 内的**非结算排序**（改可见性 ≠ CREATED）——见 07。

---

## 2. Data 内部：按代数角色分拣

世界不是「只有物理」；物理只是 Data 里一类 **sort**。按**行的签名与消费方式**分：

| Sort | 代数角色 | 例子 | 典型 Intent / 读法 |
|---|---|---|---|
| **Placement** | 容器与序 | `regions.card_ids`、威胁区成员 | `MoveCard` |
| **Measure** | 可加计数 | `token_stacks`、资源池 | `TransferToken` |
| **Form** | 有限属性 | `face` / `exhausted` | `SetExhausted` / Flip |
| **Clock** | 离散钟与游标 | round、席位行动、limits | Seat / Framework |
| **Proposition** | 可判定命题（常带寿命） | `Engagement`、Gain 标记 | `FactInsert`；`is_engaged_with` |
| **Endomorphism** | 解释上的可结合变换（带寿命） | FoldStat / Guard / Divert / OnTiming | `ConstraintInsert`；query/legal 折叠 |
| **Log** | 近似只增 | Chronicle | 记住 / 日志 |
| **Permission** | 正交权限（可非结算） | Audience | 可见性 |

实现上可以是多个 `Map`，也可以一个带 tag 的行表——那是模块边界，不改变「它们同属 Data / 同属函数世界」。

### 2.1 Proposition（命题行）

**是什么**：Data 里一条可判定的原子事实——问的是「是否成立」，不是「怎么改算法」。

```text
Proposition 行 ≈ {
  id, source, lifetime, subject,
  body:  Engagement(enemy, inv) | HasKeyword(card, surge) | …
}

判据：  holds(data, φ) ∈ {true, false}
```

| 特征 | |
|---|---|
| 消费 | **查询命题**：`is_engaged_with`、`has_effective_keyword` |
| 不消费为 | 不直接改 `stat` 公式、不单独拦 Intent（拦 Intent 的是 Guard ∈ Endomorphism） |
| 写入 | `FactInsert` / 卸 lifetime → CREATED |
| 寿命 | 常有（`WHILE_IN_PLAY`、until…）；到期从 Data 删掉，命题变假 |

**典型**：

- **交战** `Engagement(E, I)`：真实交战或 lasting「视为交战」——权威命题；威胁区是 Placement，另事。  
- **Gain 标记**（拥有 surge / trait…）：「这张卡现在有没有这个特征」；行为往往再**衍生** Endomorphism 行。  
- （可扩展）Blanked、ConsideredX…——仍是命题，不是态射。

**不是 Proposition**：

- 「+1 fight」——那是改数值解释 → Endomorphism。  
- 「cannot play」——那是对 Intent 的谓词变换 → Endomorphism（Guard）。  
- 庞大虚拟交战——若仅由 Massive∧ready∧同地算出 → **Derived**，不存行。

**和 Placement 的分工（交战）**：

```text
在威胁区？     → Placement 查询
交战命题成立？ → Proposition 查询
规则说「engaged」→ 查询层可析取（含庞大派生）；存档权威仍是 Proposition 行（+ 派生规则）
```

---

### 2.2 Endomorphism（态射行 · 数据化的变换）

**是什么**：把「对解释的修改」存成 Data 里的行。数学上接近 **自同态**（集合到自身的映射）或 **可结合的变换**：解释器有一个底层读法，再被这些行依次（或按规范序）折叠。

```text
Endomorphism 行 ≈ {
  id, source, lifetime, subject,
  body: FoldStat | GuardIntent | DivertFlow | OnTiming
}

底层：   base = Catalog ⊕ Placement/Form/…
折叠：   interpret(data) = fold( endomorphisms(data), base )
```

四类 body（与 37 PolicyBody 对齐）= 四类**消费口**：

| Body | 变换的对象 | 人话 | 旧名 |
|---|---|---|---|
| **FoldStat** | `Stat → Value` 的计算 | 在查询站给数值 +N / set / 改 AmountPlan | modifier |
| **GuardIntent** | `Intent → Ok \| Forbid` | cannot play / peril 等拦发起 | gate |
| **DivertFlow** | 命名流程的分支读法 | SKIP_AOO、压制 auto-engage | directive |
| **OnTiming** | 时点 → 额外 Eff | lasting「after X, do Y」 | listener |

```text
query_stat(data, k) = fold( folds(data), base_stat(catalog, data, k) )
legal(intent, data) = ∀ g ∈ guards(data). allows(g, intent)
flow_read(step, data) = apply_diverts(diverts(data), default_read(step))
on_timing(t, data)    = base_handlers(t) ++ on_timings(data, t)
```

| 特征 | |
|---|---|
| 消费 | **折叠进解释**，不是「问 φ 真假」一条就完 |
| 写入 | `ConstraintInsert` → CREATED（纯挂 lasting 也算生效） |
| 代码里的系统 | **不变**；变的是表里的行 |
| 印刷 Forced/反应 | AbilitySpec ∈ Catalog/挂载管线，**不是** OnTiming 行（除非效果 gains 出延时听） |

**为何叫 Endomorphism 而不是「规则代码」**：规则代码（解释器）固定；卡面效果安装的是**可存档的变换参数**。卸 lifetime = 从表拿掉一行，解释自动回到少折叠一次的状态。

---

### 2.3 二者对照（易混点）

| | **Proposition** | **Endomorphism** |
|---|---|---|
| 问句 | 「是否成立？」 | 「解释怎么改？」 |
| 代数 | 原子命题 / 关系 | 对查询·合法性·流程·时点的变换 |
| 例子 | 交战、拥有 surge 标记 | +1 fight、cannot play、SKIP_AOO、after evade draw |
| 37 分区 | 多在 `facts.relations` / `gains` | `constraints.policies` |
| 常一起出现 | Gain 标记（命题）衍生出 Policy（态射） | Guard「engaged 时 cannot discover」**读**交战命题 |

**口诀**：Proposition = 局面上的**真假句**；Endomorphism = 挂在解释器上的**可装卸滤镜**。

---

## 3. 和「桌上模拟」口径的关系

| 模拟隐喻（曾用） | FP 归宿 |
|---|---|
| 「窄世界 = 物理」 | Data 的 Placement ∪ Measure ∪ Form ∪ Clock |
| 「Facts 伴件」 | Data 的 Proposition ∪ Log |
| 「Constraints 运作叠层」 | Data 的 Endomorphism |
| 口语「世界 = 只有物理」 | **废弃作函数定义**；至多作文档分区名 |

37 里若仍见 `auth.world` / `facts` / `constraints` 顶层字段：把它们读作 **Data 的分区表**，合起来才是 `World_FP`。  
**不要**再说「只有物理那一袋叫世界」。

---

## 4. 派生：什么不要塞进世界

| 存进 Data | 放 Derived / 查询时算 |
|---|---|
| 不能由其余行唯一还原，或必须保留寿命/来源 | 由 Data 唯一可算 |
| 真实交战、lasting 视为交战（Proposition 行） | 庞大虚拟交战（Massive∧未横置∧同地） |
| lasting Policy 行 | 倒排索引、可行性 Φ |

威胁区成员 ∈ Placement；交战 ∈ Proposition；统一「是否交战」是**查询层析取**，不是把两件事捏成同一种桌上物。

---

## 5. 最小对照例

| 规则现象 | 在不在函数世界 | Sort |
|---|---|---|
| 调查员在地点 L | 是 | Placement |
| 资源池 5 | 是 | Measure |
| 与敌人 E 交战（含视为） | 是 | Proposition |
| until EOT +1 fight | 是 | Endomorphism |
| 印刷 fight 值 4 | 否（Catalog） | — |
| 「本手续选中的目标」 | 否（Control.memory） | — |
| 庞大「算交战」且未单独 grant | 否（Derived 查询） | — |

---

## 6. 阅读指引

1. 先读本文定 **World_FP = Data**。  
2. 字段名与类型 → [37](37-world-structure.md)（分区表形状以 37 为准；语义以本文「合起来是 Data」为准）。  
3. 怎么改 Data → Intent / [25](25-functional-eff.md)。  
4. 什么算结算 CREATED → [07](07-effect-primitives.md)。

---

## 7. 修订

| 日期 | 说明 |
|---|---|
| 2026-11-25 | v0.1：定义 World_FP≜Data；主划分 Data×Control；Data 内代数分拣；对照模拟隐喻 |
| 2026-11-25 | v0.2：细讲 Proposition / Endomorphism（定义、消费、对照、交战与 Gain） |
