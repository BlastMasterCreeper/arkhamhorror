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

### 2.1 Endomorphism 为何仍是「世界里的数据」

卡面挂的「直到回合结束 +1」「cannot play」「after evade, draw 1」= **把态射重化成带寿命的行**，供固定解释器折叠：

```text
query_stat(data, k) = fold( endomorphisms(data), base(catalog, data, k) )
legal(intent, data)  = ∀ g ∈ guards(data). ok(g, intent)
```

**系统 / 解释器在 Catalog 与代码里，对局中不变**；变的是 Data 里的 endomorphism 表。这与「组件是数据、系统是函数」一致。

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
