# 30 — 函数化可读说明：值的类型与运算公式

> **状态**：说明稿 v0.1 · 2026-11-24  
> **给谁看**：要把 [24](24-functional-world.md)–[29](29-flow-agendas.md) 读成「代入即能算」的人。  
> **规则裁决仍以 01–23 与 28 为准**；本文只把词、类型、公式写直。  
> **实现宿主**：[31-functional-host](31-functional-host.md)（规则内核 Rust，Godot 只做桥与表现）。  
> **结构总表**：[37-world-structure](37-world-structure.md)（分类 · 键名 · 类型）。

黑话第一次出现都写成：**中文（英文原词）**。后文用中文。

---

## 0. 词表

| 词 | 人话 |
|---|---|
| 局面（World） | 这一局桌上现在有什么：牌在哪、标记多少、持续效果还在不在 |
| 进度（Run） | 算到哪了：手续堆得多深、刚才选了谁、正在等谁回答 |
| 目录（Catalog） | 印刷与流程说明书。不随打牌改变 |
| 效果树（Eff） | 一张卡或一条手续「要做的事」的树，本身不是局面 |
| 手续（Flow） | 有名字的一整段规则，例如「抽一张遭遇牌」「造成伤害」 |
| 议程（Agenda） | 这条手续规定的步骤清单，按序号做 |
| 帧（Frame） | 堆栈里的一层：正在做哪条手续、做到第几步 |
| 意图（Intent） | 一条准备落地的改动，例如「敌人 E 的伤害 +1」 |
| 提交（commit） | 把意图真正写进新局面 |
| 内联（Seq） | 同一层里先做完左边，再做右边。不新开一层手续 |
| 嵌套（Nest） | 新开一层手续，走完那一层的议程，再回到这里 |
| 询问（Ask） | 停下来等人选；选出答案后再继续算 |
| 查询（Query） | 只看局面，不改局面 |

四类值不要混：

| 类 | 会不会被打牌改掉 | 例子 |
|---|---|---|
| 局面 | 会，而且每次改完是一份新局面 | 伤害标记 |
| 进度 | 会，但是「算到哪」 | 当前帧、已选敌人 |
| 目录 | 不会 | 卡牌印刷生命、手续议程 |
| 结果 | 这一步函数的返回值 | 继续算 / 等人选 / 停下 |

---

## 1. 数据类型

这一节只用这些基本类型：

| 写法 | 含义 |
|---|---|
| 整型 | 整数，例如 `0`、`1`、`-1` |
| 字符串 | 文本。所有 id 都是字符串，例如 `"E1"`、`"06111"` |
| 布尔 | `true` 或 `false` |
| 数组 | 有序列表，例如 `["C1","C2"]`。下标从 0 起 |
| 字典 | 键值表。键是字符串，值的类型在字段里写明 |
| 枚举 | 只能取列出的那几个字符串 |

空 id 用空字符串 `""`。没有可选记录时，字段直接省略或写成 `null`。

### 1.1 局面怎么构造

Board 里**只有一种实体：卡**。调查员、地点、敌人、支援、事件、技能、场景、密谋都是 `board.cards` 里的一条，用字段 `card_type` 区分。没有第二张「调查员表」或「敌人表」。

印刷数字（技能值、生命上限、隐蔽值）在目录里，按 `definition_id` 查，类型是整型。局面上不复制一份。

**值要分类**（见 [24](24-functional-world.md) / [37](37-world-structure.md) / [38](38-functional-data-world.md)）：**Data**（Board / Facts / Constraints）/ 派生 / 进度。驱动持有整份 **Snapshot**；口语「世界」= 整个 `data`（World_FP），**不是**只有 Board。

```text
Snapshot = {
  data: {                     -- World_FP
    board, facts, constraints, audience, next_id
  }
  derived: { index, feasibility }
  run: { … }
}
-- CREATED = 改 Data（Audience 除外）
```

下面展开 `data`：

```text
data = {
  board: {                    -- 物理分区（不叫「世界」）
    cards, regions, seats, framework, limits
  }
  facts: {                    -- Proposition / Gain / Chronicle
    relations, gains, chronicle
  }
  constraints: {              -- Endomorphism
    policies                  -- FoldStat | GuardIntent | DivertFlow | OnTiming
  }
  audience:      字典         -- 权限旁路；不计 CREATED
  next_id:       整型
}
```

#### 卡

每张卡都是同一条记录。某个 `card_type` 用不到的键不写。权威形状以 [37](37-world-structure.md) 为准。  
卡脊骨**不**放回合行动数、eliminated/resigned（`seats`）；**不**放放置指针（权威在 `board.regions` 的 `host_card_id`+`place`）。同区序 = `Region.card_ids`。

```text
卡 = {
  id:             字符串
  definition_id:  字符串
  card_type:      枚举
  owner_id:       字符串    谁的牌；公共牌用 ""；遭遇牌用 "encounter"
  controller_id:  字符串
  face:           枚举      "A" 或 "B"
  exhausted:      布尔
  connections:    数组      地点：相连地点的卡 id
}
```

#### 席位（Seat）

调查员一条；键 = 该调查员卡 id（不再另存 investigator_id 字段）。读行动数 / 是否已退场 → `data.board.seats[inv]`。

```text
席位 = {
  actions_remaining: 整型   -- 本回合标准剩余
  eliminated:        布尔
  resigned:          布尔
}
-- 跨回合 ±action → Constraints OnTiming @ turn begin（不进 Seat）
-- 本回合 additional → Constraints Grant（WHILE_IN_PLAY 等）；立刻 take → Run nest
```

`card_type` 取值：`"investigator"`、`"asset"`、`"event"`、`"skill"`、`"enemy"`、`"treachery"`、`"location"`、`"act"`、`"agenda"`。

**不设** `markers` / `location_id` / `engaged_with`。伤/恐/线索/封印混乱等在宿主 `place=tokens` 区的 `token_stacks`（不另开 sealed）。每位**玩家**的 **资源池** 是独立 `place=resource_pool` 区（`host_player_id` + `token_stacks["resource"]` + 盒端 `$supply`）——**绑玩家**，**不**绑调查员卡，**不**放在任何卡 `tokens` 上，也 **不是**席位字段。物理所在地点 = 某地点 `on` 区的成员。交战 = `facts.relations` · Engagement（威胁区是物理区成员；庞大虚拟默认派生）。

地点是否已揭示用 `face`：未揭示 `"A"`，已揭示 `"B"`。

#### 区

区不是卡。它是卡序 + token 堆的放置面。

```text
区 = {
  id:             字符串
  shape:          枚举     "deck" | "flat" | "bag"
  host_card_id:   字符串   卡宿主；玩家宿主/公共为 ""
  host_player_id: 字符串   玩家宿主（resource_pool）；卡宿主/公共为 ""
  place:          字符串   放置面角色（≠ 资产槽 slot）
  card_ids:       数组     卡 id
  token_stacks:   字典     类型 → 数量
  limbo_kind:     字符串   "resolving" | "committed" | ""
}
-- 宿主互斥：卡 | 玩家 | 公共
```

`shape = "deck"` 时，`card_ids[0]` 是顶。资源池用 `host_player_id`，勿填调查员卡 id。

#### Data 分区：Board / Facts / Constraints

| 袋 | 放什么 | 是不是「世界」 |
|---|---|---|
| **Board** | 区、token、横置/翻面、席位、框架钟、限额钟 | 与下两项合称 **Data = 世界**；单独不叫世界 |
| **Facts** | 交战 Relation、Gain 拥有、Chronicle 记事 | 同左 |
| **Constraints** | lasting/+N/cannot/延时等 Policy | 同左 |
| **Audience** | 谁看得见牌面 | 在 Data 内，但改之**不计** CREATED |

```text
记事（∈ Facts.chronicle）= {
  log:        数组    元素是 { text: 字符串, round: 整型 }
  remembered: 字典    键 字符串，值 字符串
}

Relation = { shell: InfoShell, body: Engagement { enemy_id, investigator_id } }
Policy   = { shell: InfoShell, body: FoldStat | GuardIntent | DivertFlow | OnTiming }
```

壳含 `source_card_id` / `lifetime` / `subject`。  
**CREATED** = 写入 World **或** Facts **或** Constraints（含 Chronicle）；Audience 除外。  
`remembered` 是卡面「记住」；手续里「刚才选了哪张」写在 `run.memory`，不进 chronicle。

#### 可见性、框架、限额

```text
可见档 = 枚举 "hidden_all" | "controller" | "all"   -- data.audience

框架（∈ board.framework）= {
  round, lead_investigator_id, active_investigator_id,
  current_act_id, current_agenda_id
}
```

（仅此五字段；牌库在区、毁灭阈值在目录、阶段名在 `run.timing_phase`——见 37。）  
限额 ∈ `board.limits`。混乱符号是区 `chaos` 上的 `token_stacks`。FoldStat 的 `ModifierPayload` **不分型**。

#### 一份最小构造

调查员、地点、技能牌都在 `cards` 里；token 在区上。混乱袋是 `place:"chaos"` 的区（堆），不是卡数组。

```text
data = {
  next_id: 8
  board: {
    cards: { "I":…, "L":…, "C1":… }
    seats: { "I": { actions_remaining:3, … } }
    regions: {
      "deck_I": { place:"deck", host_card_id:"I", card_ids:["C1"], … }
      "hand_I": { place:"hand", host_card_id:"I", … }
      "pool_P1":{ place:"resource_pool", host_player_id:"P1",
                  token_stacks:{ "resource":5 } }
      "tok_I":  { place:"tokens", host_card_id:"I",
                  token_stacks:{ "damage":0, "horror":0 } }
      "on_L":   { place:"on", host_card_id:"L", card_ids:["I"], … }
      "tok_L":  { place:"tokens", host_card_id:"L", token_stacks:{ "clue":1 } }
      "chaos":  { place:"chaos", shape:"bag", token_stacks:{ "numeric_0":1 } }
    }
    framework: { round:1, lead_investigator_id:"I", … }
    limits: { counters:{}, occupancies:{} }
  }
  facts: { relations:{}, gains:{}, chronicle:{ log:[], remembered:{} } }
  constraints: { policies:{} }
  audience: { "C1":"controller" }
}
```

密谋上的毁灭是密谋卡 `tokens` 区的 `token_stacks["doom"]`。阈值在目录里。

抽一张牌：`MoveCard` 改两个区的 `card_ids`；`board.cards["C1"]` 身份不变。

### 1.2 进度

\[
\mathrm{Run}
=
\mathrm{List}(\mathrm{Frame})
\times
\mathrm{Memory}
\times
\mathrm{List}(\mathrm{Test})
\times
\mathrm{Window}_?
\]

| 字段 | 类型 | 人话 |
|---|---|---|
| 帧 Frame | `{手续号, 环境, 步号, 剩余树, 已取消, 本层有没有写成}` | 堆栈一层 |
| 环境 Env | `{控制者, 卡号, 能力号, 目标表, 数量}` | 这一层的参数 |
| 记忆 Memory | `Map(控制者, Map(键, 值))` | 「刚才选的敌人」这类指称。手续结束可清 |
| 检定 Test | 技能、难度、已投入牌、成败、失败点数 | 只在检定进行时有 |
| 窗口 Window | 响应池或发起池，可空 | 正在等人选能力时才有 |

步号是整数，指向该手续议程的第几行。

### 1.3 目录与效果树

目录是函数，不是局面：

\[
\mathrm{Catalog} : \mathrm{FlowId} \to \mathrm{Flow}
\]

\[
\mathrm{Flow} = \mathrm{List}(\mathrm{AgendaStep}) \times \mathrm{Eff}
\]

效果树：

\[
\begin{align*}
\mathrm{Eff}
&= \mathrm{Do}(\mathrm{Intent}) \\
&\mid \mathrm{Empty} \\
&\mid \mathrm{Pass} \\
&\mid \mathrm{Seq}(\mathrm{Eff},\mathrm{Eff}) \\
&\mid \mathrm{Par}(\mathrm{Eff},\mathrm{Eff}) \\
&\mid \mathrm{If}(\mathrm{Pred},\mathrm{Eff},\mathrm{Eff}) \\
&\mid \mathrm{Nest}(\mathrm{FlowId},\mathrm{Env}) \\
&\mid \mathrm{Ask}(\mathrm{Spec},\ \mathrm{Answer}\to\mathrm{Eff})
\end{align*}
\]

| 构造 | 人话 |
|---|---|
| Do | 做一条改动 |
| Empty | 空效果，但算「有做过」（空打出也算完整） |
| Pass | 什么都不做，也不算做过 |
| Seq | 先左后右，同一层 |
| Par | 同时组：组内按固定顺序写完，组外的「之后」等组完再来 |
| If | 看一个只读条件，只走一边 |
| Nest | 打开一条手续 |
| Ask | 等人选，答案决定下一截树 |

意图的类型（只列本说明用到的；权威见 [37 §5.1](37-world-structure.md)）：

\[
\mathrm{Intent}
=
\mathrm{TransferToken}(\mathrm{Type},\mathbb{N}^+,\mathrm{FromRegion},\mathrm{ToRegion})
\mid
\mathrm{MoveCard}(\mathrm{CardId},\mathrm{FromRegion},\mathrm{ToRegion})
\mid
\mathrm{FactInsert}(\mathrm{Relation})
\mid
\mathrm{ConstraintInsert}(\mathrm{Policy})
\mid
\mathrm{CompanionRemove}(\mathrm{Id})
\]

`FromRegion`/`ToRegion` 可为承载区 id，或无穷供给端点 `$supply`（对齐 [07 §5.2](07-effect-primitives.md) Transfer-only；**禁止**单端 Adjust）。

### 1.4 运算上下文与返回值

一次运算看到的全部输入（Data = 函数世界；Run = 控制）：

\[
\mathrm{Ctx} = \mathrm{Data} \times \mathrm{Run}
\]
（Data 内含 Board×Facts×Constraints×Audience；Catalog 外置；写 Audience 不计 CREATED。）

返回值三选一：

\[
\mathrm{Outcome}
=
\mathrm{Next}(\mathrm{Ctx})
\mid
\mathrm{NeedAsk}(\mathrm{Ctx},\ \mathrm{Request},\ \mathrm{Answer}\to\mathrm{Ctx})
\mid
\mathrm{Halt}(\mathrm{原因})
\]

| 返回 | 人话 |
|---|---|
| Next | 这一步算完了，拿新的局面和进度继续 |
| NeedAsk | 停住等人。答案代回后续函数 |
| Halt | 规则上走不下去（少见） |

询问请求：

\[
\mathrm{Request}
=
\{\mathrm{种类}:\mathrm{AskKind},\ \mathrm{候选}:\mathrm{List}(X),\ \mathrm{默认}:X\}
\]

`AskKind` 是询问种类的名字，例如「选目标」「给强制能力排顺序」「要不要发动」。种类表见 [28 §6](28-functional-scheme.md)。

---

## 2. 运算公式

下面的 \(\llbracket e \rrbracket\) 表示「解释效果树 e」。\(\mathrm{adv}\) 表示「做议程的当前一步」。

### 2.1 提交

\[
\mathrm{commit} : \mathrm{World} \times \mathrm{List}(\mathrm{Intent}) \to \mathrm{World}
\]

\[
\mathrm{commit}(w,\ [\,]) = w
\]

\[
\mathrm{commit}(w,\ i :: is) = \mathrm{commit}(\mathrm{apply}(w,i),\ is)
\]

`apply` 只改对应分量。例如从供给池放到卡的 `tokens` 区（\(R=\) 宿主 `place=tokens` 的区 id）：

\[
\mathrm{apply}(w,\ \mathrm{TransferToken}(k,n,\texttt{\$supply},R)).\mathrm{regions}[R].\mathrm{token\_stacks}[k]
=
w.\mathrm{regions}[R].\mathrm{token\_stacks}[k] + n
\]

（`$supply` 端不读写库存。）其它分量原样保留（结构共享：没改的部分仍指向旧数据）。

### 2.2 先左后右（内联）

\[
\llbracket \mathrm{Seq}(a,b) \rrbracket(c)
=
\llbracket a \rrbracket(c) \mathbin{>\!=\!} \llbracket b \rrbracket
\]

连接运算 \(>\!\!=\!\)（读作「然后」）：

\[
\mathrm{Next}(c') \mathbin{>\!=\!} k = k(c')
\]

\[
\mathrm{NeedAsk}(c,r,resume) \mathbin{>\!=\!} k
=
\mathrm{NeedAsk}(c,\ r,\ \lambda x.\; resume(x) \mathbin{>\!=\!} k)
\]

人话：左边若还在等人，右边先挂在答案后面，不插进左边中间。

### 2.3 条件

\[
\llbracket \mathrm{If}(p,t,e) \rrbracket(w,r)
=
\begin{cases}
\llbracket t \rrbracket(w,r) & \text{若 } p(w,r)=\mathrm{true}\\
\llbracket e \rrbracket(w,r) & \text{若 } p(w,r)=\mathrm{false}
\end{cases}
\]

\(p\) 的类型是 \(\mathrm{World}\times\mathrm{Run}\to\{\mathrm{true},\mathrm{false}\}\)，不准改局面。

### 2.4 一条改动

\[
\llbracket \mathrm{Do}(i) \rrbracket(w,r)
=
\mathrm{Next}(\mathrm{commit}(w,[i]),\ r\{本层写成 \mapsto \mathrm{true}\})
\]

\[
\llbracket \mathrm{Pass} \rrbracket(w,r) = \mathrm{Next}(w,r)
\]

\[
\llbracket \mathrm{Empty} \rrbracket(w,r) = \mathrm{Next}(w,\ r\{本层写成 \mapsto \mathrm{true}\})
\]

`Empty` 不改桌子，但「写成」为真。`Pass` 连这个标记都不抬。

### 2.5 打开一层手续（嵌套）

\[
\llbracket \mathrm{Nest}(f,\varepsilon) \rrbracket(w,r)
=
\mathrm{adv}(w,\ \mathrm{push}(r,\ \mathrm{frame}(f,\varepsilon,0)))
\]

\[
\mathrm{frame}(f,\varepsilon,0)
=
\{\mathrm{手续}=f,\ \mathrm{环境}=\varepsilon,\ \mathrm{步号}=0,\ \mathrm{已取消}=\mathrm{false},\ \mathrm{写成}=\mathrm{false}\}
\]

\[
\mathrm{push}(r,\phi) = r\{\mathrm{栈} \mapsto r.\mathrm{栈} \mathbin{+\kern-0.2em+} [\phi]\}
\]

议程走完才弹栈，然后做外层剩下的树：

\[
\mathrm{advExit}(w,r)
=
\mathrm{Next}(w,\ \mathrm{pop}(r))
\]

弹栈之后，外层的 \(\mathrm{Seq}\) 右边才开始。子手续的「将要 / 时 / 之后」都发生在弹栈之前。

### 2.6 议程前进一步

设当前栈顶步号为 \(n\)，该手续议程为 \(A\)，\(A_n\) 是第 \(n\) 步。

\[
\mathrm{adv}(w,r)
=
\mathrm{runStep}(A_n,\ w,\ r)
\mathbin{>\!=\!}
\mathrm{bump}
\]

\[
\mathrm{bump}(w,r)
=
\begin{cases}
\mathrm{advExit}(w,r) & \text{若 } n+1 = |A|\\
\mathrm{adv}(w,\ r\{\mathrm{步号}\mapsto n+1\}) & \text{否则}
\end{cases}
\]

等人时步号不加：

\[
\mathrm{runStep}(\ldots)=\mathrm{NeedAsk}(\ldots)
\quad\text{则先不调用 bump}
\]

答案回来后，若这一步已结束，再 bump。

### 2.7 询问

\[
\llbracket \mathrm{Ask}(s,k) \rrbracket(w,r)
=
\mathrm{NeedAsk}(w,\ r,\ \mathrm{req}(s,w,r),\ \lambda x.\; \llbracket k(x) \rrbracket(w,\ \mathrm{bind}(r,x)))
\]

\[
\mathrm{req}(s,w,r)
=
\{\mathrm{种类}=s.\mathrm{kind},\ \mathrm{候选}=\mathrm{legal}(w,r,s),\ \mathrm{默认}=s.\mathrm{default}\}
\]

`legal` 即候选函数 \(\mathrm{candidates}\)（四层过滤，见 [33](33-candidate-functions.md)）。`bind` 把答案写进进度的记忆，不写局面。

驱动层（唯一不纯的地方）做的事：

\[
\mathrm{drive}(\mathrm{NeedAsk}(c,q,resume))
=
resume(\mathrm{answerOrDefault}(q))
\]

超时就用 \(q.\mathrm{默认}\)。

### 2.8 同一类里多条强制能力

设本槽强制能力集合为 \(F\)。

\[
\mathrm{batch}(F)
=
\begin{cases}
\mathrm{Next} & \text{若 } F=\emptyset\\
\mathrm{fire}(a) & \text{若 } F=\{a\}\\
\mathrm{NeedAsk}(\mathrm{排序},\ \mathrm{默认}=\mathrm{稳定序}(F),\ \lambda \pi.\; \mathrm{fire}^*(\pi)) & \text{若 } |F|\ge 2
\end{cases}
\]

\[
\mathrm{fire}^*(a :: rest)
=
\mathrm{fire}(a) \mathbin{>\!=\!} (\_ \mapsto \mathrm{fire}^*(rest))
\]

`fire` 会去解释那条能力自己的效果树，常常再套一层嵌套。这里没有「不发动」这个答案。可选反应才有「发动或不发动」。

---

## 3. 代入：选一个敌人，造成 1 点伤害，若还在场就抽 1 张

### 3.1 效果树

\[
\begin{align*}
e_0
&=
\mathrm{Ask}(\mathrm{选敌人}, \lambda x.\; e_1(x))\\
e_1(x)
&=
\mathrm{Seq}(\mathrm{Nest}(\mathrm{造成伤害},\ \{目标=x,\ 伤=1\}),\ e_2(x))\\
e_2(x)
&=
\mathrm{If}(\mathrm{在场}(x),\ \mathrm{Nest}(\mathrm{调查员抽牌},\ \{谁, 数量=1\}),\ \mathrm{Pass})
\end{align*}
\]

「造成伤害」「调查员抽牌」是目录里的手续号。造成伤害套标准能力窗；效果体是 \(\mathrm{TransferToken}(\mathrm{damage},1,\texttt{\$supply},R_{\mathrm{目标tokens}})\)。

### 3.2 起始值

\[
w_0.\mathrm{regions}[R_E].\mathrm{token\_stacks}[\mathrm{damage}]=0,\quad
w_0.\mathrm{on}(E)=\mathrm{在场},\quad
w_0.\mathrm{deck}(I)=[C_1,C_2],\quad
w_0.\mathrm{hand}(I)=[\,]
\]

\[
r_0.\mathrm{栈}=[\ \phi_{\mathrm{显现}}\ ],\quad
r_0.\mathrm{记忆}=\emptyset
\]

候选只有 \(E\)。默认也是 \(E\)。

### 3.3 逐步

**步 A.** 解释 \(e_0\)。公式 2.7：

\[
\llbracket e_0 \rrbracket(w_0,r_0)
=
\mathrm{NeedAsk}(w_0,r_0,\ \{选目标,[E],默认 E\},\ resume)
\]

局面未变。进度未改。

**步 B.** 人选 \(E\)。驱动层：

\[
resume(E)=(w_0,\ r_1),\quad r_1.\mathrm{记忆}(\mathrm{所选})=E
\]

下一截树是 \(e_1(E)\)。

**步 C.** 公式 2.2，先做左边的嵌套。公式 2.5：压入一帧，步号 0。

\[
r_2.\mathrm{栈}=[\phi_{\mathrm{显现}},\ \phi_{\mathrm{造成伤害}}(\mathrm{步号}=0,\ 目标=E)]
\]

标准窗前面的「将要 / 当时」这里假设没有人响应，步号一路加到「解释效果体」。这些步的公式都是 2.6，且 \(\mathrm{commit}\) 还没发生，所以 \(w\) 仍是 \(w_0\)。

**步 D.** 效果体是 \(\mathrm{Do}(\mathrm{TransferToken}(\mathrm{damage},1,\texttt{\$supply},R_E))\)。公式 2.4 与 2.1：

\[
w_1 = \mathrm{commit}(w_0,[\mathrm{TransferToken}(\mathrm{damage},1,\texttt{\$supply},R_E)])
\]

\[
w_1.\mathrm{regions}[R_E].\mathrm{token\_stacks}[\mathrm{damage}]=1
\]

然后伤害这层议程走到「之后」（仍假设没人），再公式 2.5 的退出：弹出伤害帧。

\[
r_3.\mathrm{栈}=[\phi_{\mathrm{显现}}]
\]

**步 E.** 右边 \(e_2(E)\)。查询：

\[
\mathrm{在场}(E)(w_1,r_3)=\mathrm{true}
\]

公式 2.3 选「抽牌」那一支。再嵌套抽牌手续。抽牌议程里的离库与入手是若干 \(\mathrm{Do}(\mathrm{MoveCard})\)：

\[
w_2.\mathrm{deck}(I)=[C_2],\qquad w_2.\mathrm{hand}(I)=[C_1]
\]

抽牌帧弹出。\(e_1\) 左右都完了。

**步 F.** 返回：

\[
\mathrm{Next}(w_2,\ r_4),\quad r_4.\mathrm{栈}=[\phi_{\mathrm{显现}}]
\]

相对 \(w_0\)：伤害从 0 变成 1，牌库少 \(C_1\)，手牌多 \(C_1\)。选敌人只进了记忆，没有进局面。

### 3.4 若这一下把敌人击败

在步 D 的 \(\mathrm{commit}\) 之后做查询「伤是否达到生命上限」。达到则再嵌套「击败」手续；击败成功后再嵌套「退场」。退场会改放置。回到步 E 时：

\[
\mathrm{在场}(E)(w')=\mathrm{false}
\]

公式 2.3 选 \(\mathrm{Pass}\)。手牌不变。

---

## 4. 和「全部写成裸 TransferToken」差在哪

若伤害不嵌套，而写成 \(\mathrm{Do}(\mathrm{TransferToken}(\ldots))\)：

\[
\mathrm{commit}\ \text{的结果可以相同}
\]

议程不同：标准窗的「当时 / 之后」不会发生，别的卡听不到「造成伤害时」。所以卡面写「造成伤害」时，公式用的是 2.5（嵌套），不是直接 2.4。`TransferToken` 只出现在伤害手续自己的效果体里。

---

## 5. 阅读顺序

1. 本文 §1 对一下类型。  
2. 用 §2 的公式看一棵树会返回 `Next` 还是 `NeedAsk`。  
3. 具体某条手续有哪些步，查 [29](29-flow-agendas.md)。  
4. 词和机器全表查 [28](28-functional-scheme.md)。

---

## 6. 变更记录

| 日期 | 摘要 |
|---|---|
| 2026-11-24 | v0.1：词表、四类值、类型、提交/顺序/嵌套/询问/议程公式、伤害后抽牌代入 |
