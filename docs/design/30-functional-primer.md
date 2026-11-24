# 30 — 函数化可读说明：值的类型与运算公式

> **状态**：说明稿 v0.1 · 2026-11-24  
> **给谁看**：要把 [24](24-functional-world.md)–[29](29-flow-agendas.md) 读成「代入即能算」的人。  
> **规则裁决仍以 01–23 与 28 为准**；本文只把词、类型、公式写直。

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

记号：`A × B` 表示两条记录拼在一起；`Map(K,V)` 表示从 K 查到 V；`List(A)` 表示有序列表；`A | B` 表示两种可能之一；`1` 表示空（没有额外数据）。

### 1.1 局面

\[
\mathrm{World}
=
\mathrm{Physical}
\times
\mathrm{Regs}
\times
\mathrm{Chronicle}
\times
\mathrm{Audience}
\times
\mathrm{Framework}
\times
\mathrm{Entropy}
\times
\mathrm{Limits}
\]

| 分量 | 类型 | 里面是什么 |
|---|---|---|
| 物理（Physical） | 见下 | 牌在哪、标记、横置与正反面 |
| 登记（Regs） | `Map(登记号, 登记条)` | 持续效果、限制、监听。带寿命 |
| 记事（Chronicle） | `List(记事条) × Map(键, 值)` | 薄日志和「记住」 |
| 可见性（Audience） | `Map(实体号, 可见档)` | 谁看得见牌面。改它不算一次效果结算 |
| 框架（Framework） | 回合数、当前场景号、当前密谋号、谁的回合 | 存档还认得的回合游标 |
| 随机（Entropy） | `List(混乱标记) × 种子` | 袋里还剩什么 |
| 限额（Limits） | `Map(限额键, 整数)` | 本场某能力已用几次 |

物理再拆开（对应三类能改桌子的基本动作）：

\[
\mathrm{Physical}
=
\mathrm{Map}(\mathrm{Id},\mathrm{Entity})
\times
\mathrm{Map}(\mathrm{Id},\mathrm{Place})
\times
\mathrm{Map}(\mathrm{Id},\mathrm{Markers})
\times
\mathrm{Map}(\mathrm{Id},\mathrm{Form})
\]

| 字段 | 类型 | 人话 |
|---|---|---|
| 实体 Entity | `{种类, 印刷号, 所有者, 控制者}` | 这张牌是谁的、印刷编号是什么 |
| 放置 Place | `区(区号, 序号) \| 悬置(子区) \| 附着(宿主) \| 垫下(宿主, 序号)` | 牌在哪 |
| 标记 Markers | `{伤, 恐, 毁灭, 线索, 资源, 充能表}` | 数 |
| 形态 Form | `{面: A\|B, 已横置: 真\|假}` | 翻面、横置 |

悬置子区只有两种：`结算中`、`已投入检定`。

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

意图的类型（只列本说明用到的）：

\[
\mathrm{Intent}
=
\mathrm{AddMarker}(\mathrm{Id},\mathrm{Kind},\mathbb{Z})
\mid
\mathrm{MoveCard}(\mathrm{Id},\mathrm{Place})
\mid
\mathrm{InsertReg}(\mathrm{登记条})
\mid
\mathrm{RemoveReg}(\mathrm{条件})
\]

### 1.4 运算上下文与返回值

一次运算看到的全部输入：

\[
\mathrm{Ctx} = \mathrm{World} \times \mathrm{Run}
\]

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

`apply` 只改对应分量。例如加标记：

\[
\mathrm{apply}(w,\ \mathrm{AddMarker}(e,k,n)).\mathrm{markers}(e,k)
=
w.\mathrm{markers}(e,k) + n
\]

其它分量原样保留（结构共享：没改的部分仍指向旧数据）。

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

`legal` 是查询。`bind` 把答案写进进度的记忆，不写局面。

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

「造成伤害」「调查员抽牌」是目录里的手续号。造成伤害套标准能力窗；它的效果体是一条加标记。

### 3.2 起始值

\[
w_0.\mathrm{markers}(E,\mathrm{伤})=0,\quad
w_0.\mathrm{place}(E)=\mathrm{在场},\quad
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

**步 D.** 效果体是 \(\mathrm{Do}(\mathrm{AddMarker}(E,\mathrm{伤},1))\)。公式 2.4 与 2.1：

\[
w_1 = \mathrm{commit}(w_0,[\mathrm{AddMarker}(E,\mathrm{伤},1)])
\]

\[
w_1.\mathrm{markers}(E,\mathrm{伤})=1
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

## 4. 和「全部写成加标记」差在哪

若伤害不嵌套，而写成 \(\mathrm{Do}(\mathrm{AddMarker}(\ldots))\)：

\[
\mathrm{commit}\ \text{的结果可以相同}
\]

议程不同：标准窗的「当时 / 之后」不会发生，别的卡听不到「造成伤害时」。所以卡面写「造成伤害」时，公式用的是 2.5（嵌套），不是直接 2.4。加标记只出现在伤害手续自己的效果体里。

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
