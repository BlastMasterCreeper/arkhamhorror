# 28 — 函数化方案总纲（完备草案）

> **状态**：设计草案 v0.1 · 2026-11-23  
> **地位**：函数化的 **总索引与缺口收口**。[24](24-functional-world.md)–[27](27-eff-eval-detail.md) 是分册；**与分册冲突时以本文声明的修订为准**。  
> **依赖**：01–23 现行规则设计（尤其 02 框架、03 行动、04 检定、05 混乱袋、06 发起、07 效果、08 敌人、15 时点、16 交互、17 运行时、22 粒度）。  
> **非目标**：本文件不替换那些规则裁决；只规定 **它们在纯函数内核里落在哪一类函数**。不要求立刻改 Godot。

---

## 0. 自审（24–27 漏了什么）

| 已写 | 实际只覆盖 | 漏掉（本文补） |
|---|---|---|
| 24 `World`/`Run` | 单局局面袋 vs 游标 | **剧本**（Campaign）跨场；**Limit 计数**；检定/混乱袋/分配管线的 **专用状态值** |
| 25 `Eff` | 卡面与手续体代数 | **费用不是 Eff**；`Par` 提交与 After 冲洗；**Then 优先于组 After**；fizzle/CREATED 作用域 |
| 26 种类表 | 卡面叶 Nest `seq.effect.*` | **非 effect 全目录**（行动外壳、检定步、混乱、框架、敌人攻击）的函数归属 |
| 27 信封 + Forced + 响应池 | 单 Flow 的 Would→WhenForced→Pool→Resolve | **过平**：缺 **按 Flow 定制的议程（Agenda）**、**类别整批屏障**、**显现独立类**、**险境管线档**；缺 **玩家时间段窗 / 发起池**；缺 **Initiation L0–L7**；缺 **独立检定机 ST.1–ST.8**；缺 **混乱揭示链**；缺 **伤恐分配**；缺 **击败常态检测**；缺 **借机攻击**；缺 **Limit**；缺 **Cancel 竞争**；缺 **重放迹** |

用户点出的「Forced 也有 Ask / 同优先排序」只是 27 里的一处。下面按 **函数种类** 把规则面收全，避免再靠对话补洞。

---

## 1. 总原则

```text
Catalog（静态 · 永不进 World）
World（局面值） × Run（游标值） × MachineState（专用过程值）
        │
        ├─ Query          只读
        ├─ Agenda         本 Flow 的相位表（数据，不是全局 if）
        ├─ interpret Eff  树
        ├─ Machines       框架 / 窗 / 发起 / 检定 / 混乱 / 分配 / …
        └─ commit Intent  唯一写 World
Session 握 current 引用 + 时钟；解 NeedAsk
```

| # | 原则 |
|---|---|
| S1 | **不是一切皆 Eff**。框架步进、检定步进、发起门槛、查询、寿命 tick 是 **具名状态机函数**，体里才 `Nest`/`interpret` |
| S2 | **一切玩家决策 ∈ `AskKind`**（含 Forced 排序、入池、放行、费用支付方式、ST.7 序、分配腿） |
| S3 | **写 World 只经 `commit(Intent[])`**；`Ask` 只写 `Run` / `MachineState` |
| S4 | **每个具名 Flow 自带 Agenda**（相位列表 + 每相调用哪个函数）。禁止用 27 那条写死的 WhenForced→Pool 冒充所有手续 |
| S5 | **类别整批**：同一时点窗内 FORCED 整类先于 FRAMEWORK 再先于 TRIGGERED…（[06 §8.1](06-ability-initiation.md)）。类内才 Ask 排序。**显现不进该窗 Forced 批**（§8.1.1） |
| S6 | **铸造种类的卡面叶仍默认 Nest**（[26](26-eff-kind-table.md)） |
| S7 | **真空禁止**：`interpret` 必有栈帧或根机器步 |

---

## 2. 函数种类（完备分类）

| 类 | 记号 | 纯？ | 例子 |
|---|---|---|---|
| **Q 查询** | `Q : World × Ctx → A` | 是 | Eligibility L0–L5、有效关键词、in-play、连通、Prey 比较、Limit 剩余、能否付费、CREATED 谓词 |
| **C 提交** | `commit : World × Intent[] → World` | 是 | 物理三类 + Register + Chronicle；Audience 写入但不计 CREATED |
| **P 规划** | `plan : World × Env × Eff → Plan` | 是 | dry-run / L7；`Plan{intents, created, asks}` |
| **E 解释** | `interpret : Ctx × Eff → Outcome` | 内核纯 | `Do/Seq/Par/If/Nest/Ask/ForEach/Empty/Pass` |
| **N 入帧** | `nestEnter : Ctx × FlowId × Env × Cont → Outcome` | 是 | push + 按该 Flow 的 **Agenda** 走 |
| **A 议程** | `advance : Ctx → Outcome` | 是 | 读 `Catalog[flow].agenda[phase]` |
| **M 机器** | `stepX : Ctx × XState → Outcome` | 是 | 框架、窗、发起、检定、混乱链、分配、击败检测 |
| **K 寿命** | `tick : World × TickEvent → World` | 是 | ST.8、阶段末、离场卸 Registration |
| **S 会话** | 驱动循环 | 否 | 时钟、默认超时、存档、UI |

`Outcome = Next Ctx | NeedAsk { req, resume: Answer → Ctx } | Halt`

---

## 3. 值模型补全（相对 24）

```text
World ⊇ 24 的袋
  + limits: Map LimitKey → Count          -- 本场已用次数
  + campaign_ref: CampaignId | None       -- 不内嵌整本剧本

Campaign  -- 跨场；独立值，不塞进单场 World
  log, trauma, xp, story_assets, …

Run ⊎ MachineState
  stack: [Frame]
  memory: referents / cancel keys / encounter frames
  tests: [SkillTestValue]                 -- 嵌套检定栈
  chaos_chain: ChaosChain | None          -- 本次揭示意图
  assign: AssignState | None
  window: PlayerWindow | None             -- 时间段窗或时点窗
  initiation: InitiationState | None

Frame
  flow_id, env, agenda_ix, body, cont_after,
  cancelled, created_trace, slot_cursor
```

**作用域**：`created_trace` 属于 **当前帧**；父 `If(previous_not_created)` 读的是父帧 trace，不是子帧内部碎步（子 Nest 只把「子手续是否 CREATED」汇总回父）。

---

## 4. Flow = 信封数据 + 体 + **Agenda**

27 把相位写死在 `advanceEnvelope`。修订：

```text
Flow = {
  id,
  timing: { would, when, after, split_impact? },
  agenda: [ AgendaStep ],     -- 本手续专用顺序
  body: Eff
}

AgendaStep =
  | CollectSlot { slot, classes: [Tier] }   -- 按 06 §8.1 整类
  | Pipeline   { id, fn }                   -- 险境 Register、G4、显现 nest…
  | ImpactInline
  | ResolveBody
  | Machine    { name }                     -- 例如检定把 ST 步挂进议程
  | Tick       { event }
```

### 4.1 通用「能力时点窗」议程（When 或 After 槽）

```text
Would：替换竞争（§8）→ 若未取消则 Impact（若本 Flow 有）
slot:
  FORCED 整类     → runClassBatch(FORCED)      -- ≥2：Ask ORDER_FORCED；不可 decline
  FRAMEWORK 整类  → runClassBatch(FRAMEWORK)
  TRIGGERED 整类  → runResponsePool            -- 16 §7.1 粘性池；每次放行 1
  DELAYED 整类
  LISTENER 整类   -- 默注册序；若设计要求可选再 Ask
然后下一议程步（常 ResolveBody 或 Exit）
```

**禁止**：一条 reaction 插进 Forced 类中间。  
**显现**：不出现在上表；见遭遇抽牌议程。

### 4.2 遭遇抽牌议程（示例 · 非通用窗）

对齐 15 G 队列，**不是** §8.1 那张表硬套：

```text
Would 抽取 PreImpact
Impact：离库 + reveal → LIMBO
Pipeline peril @100（父砖 Register，K3，不 Nest 卡面 register）
When 槽 @95（Fast / reaction when you draw）  -- 此处是 TRIGGERED/打出窗，不是先跑完全部 Forced 再挡 Ward
Pipeline revelation @90 → Nest seq.encounter.revelation
Pipeline G4 @80 discard/spawn
After @75
Surge 另开一条 draw（不在本议程循环里）
```

玩家入手显现走 `seq.enter_hand` 子时点，同样 **REVELATION 独立类**。

### 4.3 其它手续

各自一张 Agenda（实现时填表，方案上 **必须有表**）：`seq.draw.investigator`、`seq.effect.deal`、`seq.effect.move`、`seq.skill_test.*`、`seq.action.*`、`seq.interrupt.cancel`、`seq.replace.instead`。  
27 的 WhenForced→WhenPool **降为** `CollectSlot` 的默认模板，仅当 Flow 声明 `agenda = standard_ability_window` 时使用。

---

## 5. `interpret` 补全（相对 25）

| 构造 | 运算 |
|---|---|
| `Do` | `plan` 单意图 → `commit`；记入帧 `created_trace` |
| `Seq` | 左完（含其 Nest **整段议程 Exit**）再右；`NeedAsk` 用续体闭包 |
| `Par` | 组内按规范序 `commit`；**组结束后才** flush 该组 After；组内不插父 After |
| `If` | 只解释选中支；`previous_created` 读本帧 trace |
| `Nest` | `nestEnter`；父右支 = `cont_after`，**不**插入子议程中间 |
| `Ask` | `NeedAsk`；见 §6 |
| `ForEach` | 展开为 `Seq`（或同时则 `Par`）；候选来自 `Q` |
| `Empty` | 不写 World；发起 L7 记 CREATED |
| `Pass` | 无 CREATED |

**Then**：`Seq` 不是时点。前段产生的 After **Flush 点**在该 `Seq` 节点结束之后，且 **后段先于该 After**（07 Then 优先）。实现：`Seq` 节点带 `defer_after: true`，结束时再跑被推迟的 After 议程。

**Cancel 显现**：子 revelation `cancelled`；父抽牌议程 **仍执行 G4**（议程数据保证，不靠删父帧）。

---

## 6. `AskKind` 总表（完备）

在 27 的种类上补全。全部 `NeedAsk`；default 必有；超时由 Session 填。

| `AskKind` | decline？ | 谁 | 出现处 |
|---|---|---|---|
| `ORDER_FORCED` | 否 | 队长 | Forced 类内 ≥2 |
| `ORDER_CLASS` | 否 | 队长或注册序 | 其它需自排的类 |
| `ORDER_ST7` | 否 | 发起者/规则 | ST.7 多单元 |
| `JOIN_POOL` | 是 | 控制者 | 响应池 |
| `PICK_RESPONSE` | 池空则收窗 | 队长放行 1 | 响应池 |
| `WITHDRAW_POOL` | 是 | 控制者 | 锁前 |
| `INITIATE_OR_NOT` | 是 | 控制者 | **发起池**（时间段窗） |
| `PICK_PLAY` | 是 | 控制者 | 窗内打出 |
| `PAY_COST` | 否若已发起 | 控制者 | Initiation 支付方式 |
| `PICK_TARGET` / `PICK_OPTION` / `PICK_MULTI` | 视 must | 控制者 | 效果体 / 分配 |
| `OPTIONAL_EFFECT` | 是（默认跳过） | 控制者 | may |
| `ORDER_WOULD` / `PICK_INSTEAD` | 否 | 规则：最后发起；Forced 先定 initiate 序 | Would |
| `ASSIGN_LEG` | 否（必须分完或规则允许剩余） | 控制者 | `deal.assignable` |
| `COMMIT_CARD` / `UNCOMMIT` | 是 | 参与者 | ST.2 |
| `MULLIGAN` | 是 | 各调查员 | Setup |
| `DISCARD_TO_HAND_SIZE` | 否 | 控制者 | Upkeep 4.5 |
| `SEARCH_TAKE` | 视 must | 控制者 | search 体内 |

Forced：**无** `INITIATE_OR_NOT`。可选反应：**有**。

---

## 7. 机器一览（S1 的主体）

每台机器：`State` 值 + `step` 函数 + 会 `Nest` 的 Flow + 会发出的 `AskKind`。细则仍以原设计文档为规则源。

### 7.1 框架 `stepFramework`

- **State**：`World.framework` + 当前 `FrameworkStep`（00 索引）。  
- **步**：强制砖 `Nest` 对应 seq（1.2 doom、1.4 每人抽、3.2 移动、4.3 ready、4.4 抽+资源…）。  
- **窗**：步间 `openPlayerWindow(id)`（§7.2），不是 Eff。  
- **第 1 回合**：跳过 Mythos（数据：round==1 的议程跳步）。  
- **终局**：`SCENARIO_RESOLUTION` → 写 Campaign，不继续 round。

### 7.2 玩家时间段窗 `stepInitiationPool`

与响应池 **不同机器**（16 §7.0）。

```text
while window open:
  COLLECT 可主动发起（打出 / free / activate 窗口内…）
  Ask INITIATE_OR_NOT | 偏好自动
  选中 → stepInitiation
  直至无人再发起或窗策略关闭
```

响应池是 **时点被动**；发起池是 **时间段主动**。二者都 `NeedAsk`，状态字段分开。

### 7.3 发起 `stepInitiation`

对齐 00 Initiation / 06 §5–§7：

```text
Q 限制与费用可行 (L0–L5, PRE)
Ask PAY_COST（若支付有分支）
commit 费用 Intent（包装=cost，不是 lose_resources 效果）
INIT_2B：若会借机且无 SKIP_AOO → Nest 敌人攻击（借机）
INIT_3 commence
INIT_4：interpret(effect) 必在已有帧内；§4.0.5 为是则 Nest
L7：plan(effect).created 否则 fizzle，不进入 2–4
```

打出 **不是能力**：`PlayForm` 决定窗口与费用对称（06 §4.2），效果体仍是 `Eff`。

### 7.4 检定机 `stepSkillTest`（独立枚举，不并入 FrameworkStep）

```text
ST.1  Q 定技能/难度；可自动成功/失败标记
ST.2  投入循环：Ask COMMIT/UNCOMMIT；commit 进 LIMBO/COMMITTED
      on_commit → Nest register（lasting）
      after_test_ends → 武装延时（提前 uncommit 则卸）
      窗 PW_SKILL_TEST_AFTER_COMMIT
ST.3–4 stepChaosChain（§7.5）；链结束才 PW_AFTER_REVEAL
      「再揭示」只再进 ST.3–4，不回 ST.2，递归中无窗
ST.5  Q 修正技能值（Modifier fold）
ST.6  Q 成功/失败 + fail_by；**不**跑成败 Eff
ST.7  COLLECT 单元（发起方、投入技能、符号 fail-by、延时 LISTENER）
      Ask ORDER_ST7 若 ≥2
      按序 interpret（内联；单元内可再 Nest deal/draw）
      然后 post-ST7：Retaliate/Alert → Nest perform_attack（未横置）
ST.8  弃仍投入的牌；token 回袋；tick THIS_SKILL_TEST
      发 skill_test_ends（延时 after_test_ends 在此开火）
      pop tests
```

嵌套检定：`tests` 栈；内层 ST.8 只清内层。

### 7.5 混乱链 `stepChaosChain`

- Would 揭示：替换意图（seal instead、Olive 等）纯收集后按序。  
- 离袋入账本 = ST.3（可一批）。  
- 对 **resolved** 每枚：ST.4 Nest/发起符号能力（参考卡）。  
- Cancel 的标记不计 revealed/resolved（既有裁决）。  
- 改 `World.entropy` 只经 Intent（移出袋 / 回袋）。

### 7.6 伤害分配 `stepAssign`

`seq.effect.deal.assignable` 的 Resolve **内部**调用本机，不是卡面糖 Atom：

```text
Would 改量（reduce/increase pending）
Ask ASSIGN_LEG（Gate；脚本腿可跳过 Ask）
Par 应用各腿 → commit
After  affliction / 再 Nest defeat 检测
```

无分配的 `seq.effect.deal`：跳过 Ask，直接 commit。  
Heal / 非 heal 剥记分 Flow，避免 AFTER 冒充。

### 7.7 击败常态检测 `watchDefeat`

**不是**每步都 Nest。`commit` 标记后：

```text
Q 伤/恐达印刷上限？ → 是则 Nest seq.effect.defeat
卡面「击败」→ 直接 Nest defeat
defeat 成功 → Nest seq.defeat.leave_play（不内联弃置）
Cancel defeat → 无退场；上限仍在则检测可再触
```

### 7.8 借机 / 敌人阶段攻击

- 借机：Initiation 2b，`Q` 读 `SKIP_AOO`；否则 `Nest` perform attack。  
- 3.3：按交战序 `Nest` 攻击；Massive 另序（Ask 或规则序）。  
- 攻击结算是 Flow + Agenda，不是 `seq.effect` 碎步堆。

### 7.9 移动 / 交战 / 猎手

- 狭义移动：`Nest seq.effect.move`（26）。  
- 自动交战：move 议程内 **读** `SUPPRESS_AUTO_ENGAGE` 后分支；明示「engages you」另 `Nest seq.engage mode=effect`。  
- Hunter/Patrol：3.2 机器 `Q` 最近/指定目标（Prey 只是比较函数，不 Nest）再 `Nest move`。  
- 进场：**不**铸 `seq.effect.enter_play`；听 `seq.zone.move` 谓词。

### 7.10 寿命 `tick`

| 事件 | 卸 |
|---|---|
| 离场 | `WHILE_IN_PLAY` + 默认附着/垫下策略（01） |
| uncommit | `WHILE_COMMITTED` + 该卡 `after_test_ends`；**留** `THIS_SKILL_TEST` |
| ST.8 | `THIS_SKILL_TEST` |
| 阶段/回合末 | 对应 `DURATION` |
| G4 完 | peril `WHILE_DRAWN_CARD_RESOLVING` |

### 7.11 Limit

`Q.limitAllows` 在 COLLECT/发起前；成功发起后 `commit` 递增 `World.limits`。不把次数藏进闭包。

### 7.12 关键词挂载

进场/获得：profile 表决定 **衍生** Register（常在父议程砖，K3）或卡面 `Nest seq.effect.register`（K1）。  
开火（Surge、Retaliate 时机等）是另一 Flow，不把创建和开火并成一个 Eff。

---

## 8. 查询层（必须纯、必须列举）

| 查询 | 读什么 | 不做什么 |
|---|---|---|
| `eligible` L0–L5 | World + hook + 情景 | 不 Register |
| `restrictionBlocks` | RESTRICTION Buff | 不 Cancel |
| `effectiveKeyword` | 印刷 ∪ Gain | 不写回 World |
| `inPlay` | placement + 区域规格 | |
| `canPay` | 资源/横置/封印门槛 | 不扣 |
| `preyCompare` / `nearest` | 地点图 + 指令 Spec | 不 Nest |
| `created?` | 帧 trace | |
| `faceKnown` | audience × observer | 表现层用；规则头保持全知 |

Modifier 数值 = `fold` 查询，不是效果。

---

## 9. Cancel / Instead / Cannot（函数，不是光学）

| 机制 | 函数 |
|---|---|
| Cannot | `Q.restrictionBlocks`；发起直接 Halt/拒绝 |
| Cancel/Ignore | `Nest seq.interrupt.*`；改目标帧 `cancelled` 或忽略子树 |
| Instead | 收集 Would 候选；**最后发起**者生效（Forced 多个则先 `ORDER_FORCED` 定 initiate 序）；`Nest seq.replace.instead` 换 `cont` |
| 竞争失败 | 纯函数选 winner；平局才 `Ask` |
| Silver | 仅文本无法调和时的显式 Halt + 日志；不进热路径 |

---

## 10. 重放与随机

```text
TraceEntry = Intent | AskResolved { kind, answer, used_default } | Phase { flow, agenda_ix }
```

- 同 `World₀` + 同 Trace ⇒ 同 `Worldₙ`（S 会话不参与规则分支）。  
- 随机只来自 `entropy` 或已注入序列；`Ask` 的答案算 Trace 的一部分。  
- Campaign 变更是单独 Trace 流。

---

## 11. 覆盖矩阵（自审清单）

| 子系统 | 函数类 | 分册 | 本文 |
|---|---|---|---|
| 局面/区划/可见性 | World + C + Q | 24 · 01 | §3 |
| 效果树 / 种类 Nest | E + N + 26 | 25 · 26 | §5 |
| 通用时点窗 tier | A + M | 27 过平 | **§4.1 修订** |
| 遭遇抽牌/显现/险境/涌动 | Agenda 专用 | 15 | **§4.2** |
| 响应池 | M | 27 · 16 | §4.1 |
| 发起池 / 时间段窗 | M | **27 无** | **§7.2** |
| Initiation / 费用 / 借机 / 打出 | M | **27 无** | **§7.3** |
| 检定 ST.1–8 / ST.7 序 | M | 04 · 26 K4 | **§7.4** |
| 混乱袋 | M | 05 | **§7.5** |
| 伤恐分配 / 治愈 | M + Flow | 07 | **§7.6** |
| 击败 / 退场 | M + Nest | 22 G5 | **§7.7** |
| 敌人交战/猎手/反击/警戒 | M + Q + Nest | 08 | §7.8–7.9 |
| 地点图 / 揭示地点 | Q + Nest | 09 | 26 行 + Q |
| 场景密谋推进 | M Nest agenda/act | 10 | 框架机调用 |
| 剧本日志 | Campaign 值 | 11 | §3 |
| Limit | World + Q | 06 §9 | **§7.11** |
| 关键词创建/开火 | K3/K1 + Nest | 06 | §7.12 |
| 寿命 | K | 24 | §7.10 |
| Cancel/Instead/Cannot | N + Q | 07 | §9 |
| 同时 / Then / After 冲洗 | E | 07 | §5 |
| 重放 | Trace | 00 A-04 | §10 |

空格不应再出现「未归类」。新增规则时：**先定函数类，再写 Agenda 或 Eff**。

---

## 12. 对 27 的修订声明

1. 相位机改为 **`Flow.agenda` 驱动**；`standard_ability_window` 只是一种模板。  
2. When 槽内顺序 = **§8.1 整类**，不是「Forced 函数然后立刻 Pool」忽略 FRAMEWORK/DELAYED/LISTENER。  
3. 遭遇抽牌 **不用** 该模板（§4.2）。  
4. Forced 排序 Ask **保留**（27 §5 仍有效）但嵌入 `runClassBatch(FORCED)`。  
5. **补** 发起池、Initiation、检定机、混乱链、分配、击败检测、Limit、Trace。

25/26 的代数与「卡面叶默认 Nest」**不改**。

---

## 13. 落地顺序（仍不在本文件编码）

1. ~~Agenda 数据~~ → [29-flow-agendas](29-flow-agendas.md)（标准能力窗 + 遭遇抽牌 + 调查员抽牌）。  
2. `interpret` + `NeedAsk` 金样（Seq / Nest / ORDER_FORCED）。  
3. `stepSkillTest` 金样（ST.7 序 + ST.8 tick）。  
4. `stepInitiation` 费用 vs lose 分轨金样。  
5. 再考虑 Godot 适配层。

---

## 14. 变更记录

| 日期 | 摘要 |
|---|---|
| 2026-11-23 | v0.1：自审 24–27；七类函数；Agenda 取代写死相位；机器总表；AskKind 补全；覆盖矩阵 |
