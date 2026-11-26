# 38 — 函数世界（Data）说明

> **状态**：说明稿 v0.6 · 2026-11-26  
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

### 1.1 四者对照（判据 · 例子 · 边界）

| | **Data** | **Control** | **Derived** | **Catalog** |
|---|---|---|---|---|
| **一句话** | 函数世界：权威局面载体 | 解释器拉链（Run） | 可重建的视图/索引 | 静态理论（外置） |
| **是 World_FP？** | **是** | 否 | 否 | 否 |
| **进 Snapshot？** | 是（权威） | 是（进度） | 是（可丢可重建） | **否** |
| **谁改它？** | 仅 `commit(Intent)` | `step` / `answer` / bind | transit 末尾按 Data(+focus) 刷新 | 装载期；**对局中不改** |
| **丢掉会怎样？** | 局面不可还原 | 当前手续断掉；存档级局面仍在 | 慢一点，可算回来 | 整套规则/印刷没了 |
| **CREATED？** | 结算排序上的写入计 | 不算（游标） | 不算（投影） | 不算（只读） |

**Data 例子**：卡在哪个区、资源池数量、横置、交战 Relation、until-EOT +1、cannot play、Limit once 已用次数、Chronicle 记住。  
**Control 例子**：手续栈帧、`open_choice`、检定 `st_step`、`memory["chosen"]`、焦点窗、手续内临时 as-if 叠镜。  
**Derived 例子**：登记倒排索引、可行性 Φ、庞大虚拟交战（Massive∧ready∧同地）、「卡在哪」的加速反向索引。  
**Catalog 例子**：印刷 fight=4、费用、能力编译树、`seq.draw.*` 流程体、token `dual_of`、密谋 doom 阈值规格。

**边界（易混）**

| 现象 | 放哪 | 为何 |
|---|---|---|
| 印刷战力 4 | Catalog | 对局中不变；卡上只留 `definition_id` |
| 有效战力 5（+1 lasting） | Data（Endomorphism）+ 查询时 fold Catalog 底 | 变的是 Data 行，不是印刷 |
| 「本手续选中的敌人」 | Control.memory | 步间指称；手续完可清 |
| lasting「视为交战」 | Data（Proposition） | 权威真假，要存档 |
| 庞大「算交战」 | Derived 查询 | 由关键词+形态+地点唯一可算 |
| 威胁区里有这张敌 | Data（Placement） | 区成员是权威 |
| 倒排「谁挂了 FoldStat」 | Derived | 可由 Data 的 Endomorphism 表重建 |
| Audience 可见档 | Data 内 Permission 排序（可非结算） | 权威权限；改之**不计** CREATED |

运算形：

```text
query  : Data × Catalog × Spec → Answer          -- 常只读；可顺带用 Derived 缓存
plan   : Data × Control × Catalog × Eff → Intent[]
commit : Data × Intent[] → Data                  -- 唯一改世界
step   : Data × Control × Catalog × Eff
           → (Data × Control) | NeedAsk
-- transit 末尾：Derived := rebuild(Data, Control.focus)
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
| **Clock** | 离散钟与游标 | round、主/当前调查员、场景·密谋游标 | **`Data.framework`**（**不**进物理 Board）；席位行动暂 `board.seats` |
| **Quota** | 次数/配额已用 | Limit once、Max in play 占用 | **`Data.limits`**（**不**进物理 Board） |
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
| 「窄世界 = 物理」（已废称谓） | Data.**Board**（Placement ∪ Measure ∪ Form；seats 暂留） |
| 「Facts」 | Data.facts（Proposition ∪ Log） |
| 「Constraints」 | Data.constraints（Endomorphism） |
| 次数限制 / 配额 | Data.**limits**（Quota；**不**在 Board） |
| 框架钟 / 场景游标 | Data.**framework**（Clock；**不**在 Board） |
| 口语「世界 = 只有物理」 | **废弃作函数定义**；至多作文档分区名 |

37 的 `data.board` / `facts` / `constraints` / `limits` / `framework`：是 **Data 的分区表**，合起来才是 `World_FP`。物理分区字段名是 **Board**，不要叫世界。  
**不要**再说「只有物理那一袋叫世界」。**不要**把 LimitStore / Framework 塞进 Board。

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
| 2026-11-26 | v0.3：§1.1 四者对照 Data / Control / Derived / Catalog（例子与边界） |
| 2026-11-26 | v0.4：与类型对齐 — Auth→Data；物理袋 Board；37/24/30 同步 |
| 2026-11-26 | v0.5：LimitStore 升出 Board → Data.limits（Quota）；Board 不再含 limits |
| 2026-11-26 | v0.6：Framework 升出 Board → Data.framework（Clock）；Board 不再含 framework |
