# 16 — 玩家交互 (Player Interaction)

> **依赖**：[06-ability-initiation.md](06-ability-initiation.md)（Eligibility / ResponseWindow）、[07-composition.md](07-composition.md)（Choice / Optional）、[14-nested-sequences.md](14-nested-sequences.md)（同窗口多响应）、[00-architecture-overview.md](../00-architecture-overview.md)  
> **规则来源**：Grimoire Initiation、Effects · Target、Simultaneously；ArkhamDB RR · Lead Investigator / Choices  
> **状态**：v0.5.2 · 2026-10-22 — §7.1 响应池 / §7.3 发动池；§7.3.4 窗温度（交互层，实现后补）；目标选择 V 层 dry-run（[21 §3.1.4](21-selection-spec.md)）  
> **选择规格**：[21-selection-spec.md](21-selection-spec.md)

---

## 1. 目标

将 **需人类裁决** 的规则步骤纳入 **同一套引擎接口**，使 headless 测试与 UI 客户端 **共用** 决策路径，且 **不污染** Domain / Rules 客观层。

**玩家交互（player interaction）** 回答：**在客观合法的前提下，谁、以什么顺序、选哪一支、是否发动** — 不是 Eligibility 关卡（L0–L7）。

**范围**：凡 Grimoire / RR 写「choose / may / decides / in … order / select」且 **非纯自动** 的步，均应能归到本目录；**禁止** 在 Rules 各模块散落 `ui_*` 回调。

### 1.1 与内联 / nest 的边界（已裁决 2026-09-28）

玩家选择 **不是** 命名流程的 nest，也 **不是** Composition 的内联 Then。展开时用 **三分法**：

| 形态 | 何时 | 玩家选择？ |
|---|---|---|
| **内联** | §4.0.5「否」— 同帧连续 then | 否 |
| **nest** | §4.0.5「是」— 新时点锚 | 否 |
| **玩家确认（本文件）** | choose / 选目标 / may / 排序 | **是** |

运行模型 = **有限期目标确认**：

```text
合法候选（Eligibility）
    → Gate.ask(ChoiceRequest)   # 含 default_* + deadline
    → 期内确认 → RulesMemory 写入指称 → 继续父 RESOLVE（内联或 nest 下一步）
    → 期内未确认 → 采用默认选择 → 同上（流程不挂死）
```

**禁止**：为「选一个敌人」铸造/ nest `seq.choose.*`；把 Choice 节点当成 nest 子手续；无默认、无限期等待。

---

## 2. 两层分工（已裁决）

```text
┌─────────────────────────────────────────────────────────┐
│  Eligibility（客观） L0–L7                               │
│  「这条能力/效果 *能否* 被考虑 / 发起 / 落地？」          │
└───────────────────────────┬─────────────────────────────┘
                            │ eligible 集合
                            ▼
┌─────────────────────────────────────────────────────────┐
│  Player Interaction（主观）                              │
│  · 宏观：打什么行动 / 打哪张牌 / 激活哪条 [action]        │
│  · 窗口：[reaction] 选用、PlayerWindow 内 fast/action     │
│  · May / Optional / must 选改变局面的支                  │
│  · 检定：commit 哪些牌、检定中触发能力                    │
│  · 费用：弃哪张、耗哪个槽、X 取多少                       │
│  · 目标 / Search / 多选 discard                           │
│  · 伤害·恐怖分配；同时 defeated 选 trauma 类型            │
│  · 队长：同时点排序、并列 tie-break、Massive 攻击序       │
│  · Instead / 选 chaos token / 战役·Setup 分支            │
└───────────────────────────┬─────────────────────────────┘
                            ▼
                    Initiation / Composition resolve
                            ▼
                      GameStateStore（L0 写入）
```

| 问题 | 层 | 组件 |
|---|---|---|
| 牌堆空能否 draw？ | Eligibility **L7** | `CompositionDryRunner` |
| cannot play？ | Eligibility **L4** | `RestrictionEvaluator` |
| **要不要** 用这条 [reaction]？ | Interaction | `ChoiceKind.USE_ABILITY` |
| **May** heal 2 — 做不做？ | Interaction | `ChoiceKind.OPTIONAL_EFFECT` |
| 两条 [reaction] 都用 — **谁先**？ | Interaction | `ChoiceKind.ORDER_SIMULTANEOUS` |
| Deal 1 damage — **打谁**？ | Interaction | `ChoiceKind.PICK_TARGET` |
| 3 点伤害 — **怎么分**？ | Interaction | `ChoiceKind.ASSIGN_DAMAGE` |

**禁止**：在 `StateMutator`、Buff 查询或 Eligibility 内写 `if ui_clicked`；**禁止** Presentation 直接改 `GameStateStore`；**禁止** 把本次选择写进静态效果组合树（树只描述问什么，答在 Gate，指称进 `RulesMemory`）。见 [07-composition §1.4](07-composition.md#14-树的力度树上带什么动态数据放哪已裁决-2026-09-21)。

---

## 3. 统一入口：`PlayerInteractionGate`

Rules 层 **唯一** 向「玩家」索取决策的入口（headless 与 UI 相同）：

```gdscript
class PlayerInteractionGate:
    var resolver: ChoiceResolver

    func ask(request: ChoiceRequest, ctx: GameContext) -> Variant
```

`GameContext.interaction` 持有 gate；`CompositionExecutor`、`ResolutionSequenceStack` 响应轮、`DamagePipeline` 等 **只调 gate**，不调 UI。

`ask` **同步返回**选定结果（或默认）；**不** push 子 seq，**不**占用 Would/When/After。

**EventRecord**：每次 `ask` 写入 `INTERACTION_CHOICE`（或 `GameLog` `INTERACTION`），payload 含 `kind`、`decider_id`、`option_ids`、`picked`、`used_default`。

### 3.1 有限期确认 + 默认（已裁决 2026-09-28）

| 字段 / 行为 | 含义 |
|---|---|
| `deadline_ms` / `deadline_policy` | 确认窗口时限（UI 倒计时；headless 可立即 default） |
| `default_index` / `default_pick` | 未确认时采用的选项；**必须**有定义（规则指定 > 队长 tie-break 惯例 > 索引 0） |
| 期内确认 | 回填 `picked`；`used_default = false` |
| 逾期 / 放弃 | 采用默认；`used_default = true`；**父流程继续** |
| May / Optional | 默认常为「不发动 / 跳过」；must choose 默认 = 过滤后第一支可执行 |

Headless：`DefaultChoiceResolver` / `ScriptingChoiceResolver` 在无脚本应答时走同一默认路径，保证自动化不挂死。

### 3.2 电子版自动选择（`AutoChoiceMode`）

桌面规则常把同级并列交给玩家选序 / 选目标；电子版可配置 **自行决策**，免去每次弹窗。价值评估（利于 / 不利于玩家）较复杂，**后补**；当前仅中立策略：

| `RulesConfig.auto_choice_mode` | 行为 |
|---|---|
| **`ASK`**（默认） | UI 弹出 `ChoiceModal`；headless `DefaultChoiceResolver` 仍走 §3.1 `default_index` / 原序，不挂死 |
| **`REGISTRATION_ORDER`** | 不询问：候选按 COLLECT / 注册序取 `default_index`（多为 0）；`ORDER_*` 保持原序 |
| **`RANDOM`** | 不询问：在合法选项中随机（`DefaultChoiceResolver.rng`；`GameBootstrap` 用 `p_seed` 可复现） |

```gdscript
# rules/config/rules_config.gd
var auto_choice_mode: AhcEnums.AutoChoiceMode = AhcEnums.AutoChoiceMode.ASK
```

- **接线**：`GameBootstrap` → `DefaultChoiceResolver.mode` / `.rng`；沙盒 `UiChoiceResolver.configure_from_context` 读同一配置，非 `ASK` 时跳过模态。
- **测试覆盖**：`ScriptingChoiceResolver` 仍优先；未命中回落 `compute_default`（注册序）。测 `RANDOM` 时注入 `DefaultChoiceResolver` 并固定 `rng.seed`。
- **非**：不替代 Grim Rule；不绕过 Eligibility；不新增 `seq.choose.*`。
- **预留**：`FAVOR` / `DISFAVOR`（局面价值评估）待设计，不进本枚举直至有可测定义。

---

## 4. `ChoiceKind` — 核心枚举

> 下列为 **请求形状** 稳定的 kind；同 kind 可经 `context` 区分场景（如 Search vs discard）。

| Kind | 简中 | 典型决策者 | 场景摘要 |
|---|---|---|---|
| `USE_ABILITY` | 是否发动能力 | 能力**控制者** | [reaction] / 窗口内 triggered |
| `OPTIONAL_EFFECT` | 是否结算「可以」 | 效果**控制者** | May 整段；Optional 节点 |
| `PLAY_CARD` | 打哪张牌 | 调查员 | Play asset/event；选 hand 实例 |
| `ACTIVATE_ABILITY` | 激活哪条能力 | 调查员 | 多张 asset 均有 [action] |
| `COMMIT_TO_TEST` | 投入哪些牌 | 调查员 / 协助者 | ST.2；`PW_SKILL_TEST_AFTER_*` 前 |
| `PAY_COST` | 如何支付费用 | 调查员 | 弃牌 cost、选 asset 弃、exhaust 谁 |
| `PAY_X` | X 取多少 | 调查员 | Letter X；ignore cost 时 X=0 |
| `PICK_TARGET` | 选 1 个目标 | 控制者或卡面指定 | enemy / inv / location |
| `PICK_MULTI` | 选多个目标 | 控制者 | exactly N / up to N / any number |
| `PICK_OPTION` | 选分支 | 控制者 | Composition `Choice`；二选一文本 |
| `SEARCH_TAKE` | Search 取留 | 控制者 | 看顶 N 张：拿哪些、其余回置 |
| `DISCARD_SELECT` | 选弃哪些牌 | 控制者 | discard N from hand/play |
| `ASSIGN_DAMAGE` | 分配伤害 | 控制者 | Assign 到 asset；direct 到 inv |
| `ASSIGN_HORROR` | 分配/承受恐怖 | 控制者 | 同上；同时 defeated 前 |
| `CHOOSE_TRAUMA` | 选创伤类型 | 调查员 | 同时 health→0 与 sanity→0 |
| `ORDER_SIMULTANEOUS` | 同时能力排序 | **队长** | 多条 forced/triggered 同时 |
| `ORDER_CARDS` | 卡牌顺序 | 控制者 / 队长 | 同时入手；同时弃入弃牌堆 |
| `ORDER_PLAYER` | 调查员顺序 | **队长**（首动）+ 顺时针 | in player order |
| `ORDER_ATTACKS` | 攻击结算顺序 | **队长** / 触发者 | Massive 多调查员；AOO 多张 |
| `TIE_BREAK` | 并列裁决 | **队长** | 最远距离并列、prey 并列、spawn 点并列 |
| `CHAOS_PICK` | 选 chaos token | 控制者 | seal 选哪个；Olive 式选 2 解 1 |
| `INSTEAD_PICK` | 选 Replacement | 控制者 | 多条 instead 均可 initiate 时（若规则允许选） |
| `CONFIRM_STEP` | 确认继续 | 控制者 / 队长 | 关 PlayerWindow；结束 response round |
| `SILVER_RULE` | 文本冲突 | **队长** | 两卡无法调和 |
| `SETUP_CHOICE` | Setup 选项 | 玩家组 / 队长 | 难度、队长、起始位置、mulligan |
| `CAMPAIGN_DECISION` | 战役分支 | 玩家组 / 队长 | 升级、换调查员、guide 分支 |

**不在 `ChoiceKind` 内（客户端意图层）**：「我要 Investigate / Fight」→ 组装 `ActionRequest` 再进 Rules；Eligibility 校验 **之后** 才可能有 `PLAY_CARD` / `COMMIT_TO_TEST` 等细粒度 ask。

扩展新规：**先加本表 + §5 一行**，再实现 gate；**禁止** 新 `*PlayerPolicy` 类。

---

## 5. 完整交互目录（按域）

### 5.1 行动与 Framework（[03-action-system](03-action-system.md)）

| 交互 | Kind / 入口 | 决策者 | Grimoire 要点 |
|---|---|---|---|
| 选 **基础/衍生行动**（Investigate、Fight…） | *客户端* → `ActionRequest` | 当前调查员 | 非 token 内的 Parley 等走 Play/Activate |
| **Play** 哪张 asset/event | `PLAY_CARD` | 调查员 | hand 中 eligible（L7 + play restriction） |
| **Activate** 哪张 asset 哪条 [action] | `ACTIVATE_ABILITY` | 调查员 | 多 asset 同时 eligible |
| 额外行动 **算哪种** additional action | `PICK_OPTION` | 调查员 | **FAQ Game Play 1.10**（ArkhamDB RR）；Grimoire 正文 **待核对** → [OQ-PI-06](#13-开放问题) |
| **Resign** | `OPTIONAL_EFFECT` 或专用 confirm | 调查员 | 通常显式按钮 |
| 行动阶段 **结束回合** | `CONFIRM_STEP` | 调查员 | `PW_INV_BEFORE_TURN_END` 后 |
| **借机攻击 AOO** 多敌顺序 | `ORDER_ATTACKS` | **触发 AOO 的调查员** | Grimoire：触发者选序 |
| 行动后 **PlayerWindow** 内能力 | `USE_ABILITY` | 各控制者 | 同 §6.1 ResponseWindow |

### 5.2 Initiation · 费用（[06-ability-initiation](06-ability-initiation.md)）

| 交互 | Kind | 决策者 | 要点 |
|---|---|---|---|
| [reaction] **用不用** | `USE_ABILITY` | 控制者 | 非 Eligibility |
| **May** 整条能力/效果 | `OPTIONAL_EFFECT` | 控制者 | 可不选任何支（Grimoire May） |
| **Must** 多支选一 | `PICK_OPTION` | 控制者 | 须选 **能改变局面** 的支 |
| 弃牌 / exhaust / 耗 clue **付 cost** | `PAY_COST` | 调查员 | L6 前；候选由 CostPipeline 枚举 |
| **X** 费用取值 | `PAY_X` | 调查员 | ignore cost → X=0 |
| 多段 cost **顺序**（若文本要求） | `ORDER_SIMULTANEOUS` | 控制者 | 少见；Then 内固定顺序优先 |

### 5.3 技能检定 ST（[04-skill-test-engine](04-skill-test-engine.md)）

| 交互 | Kind | 决策者 | 要点 |
|---|---|---|---|
| ST.1 **([combat] or [agility])** 择一 | `PICK_OPTION` | performing inv | Fight/Evade 变体 |
| ST.2 **commit 哪些牌** | `COMMIT_TO_TEST` | performing inv | 任意张 eligible |
| 同地点 **协助 commit 1 张** | `COMMIT_TO_TEST` | 协助调查员 | 险境时 RESTRICTION 挡；非 PI |
| `PW_SKILL_TEST_AFTER_COMMIT` 窗口能力 | `USE_ABILITY` | 控制者 | fast/reaction |
| ST.3–4 揭示链 | *无* | 引擎 | 无 PlayerWindow（OQ-04-01） |
| `PW_SKILL_TEST_AFTER_REVEAL` 窗口能力 | `USE_ABILITY` | 控制者 | 进 ST.5 前 |
| Olive / **选 reveal 哪些 token** | `CHAOS_PICK` | 控制者 | 选 subset 结算 |
| **Seal** 哪个 token | `CHAOS_PICK` | 控制者 | 「choice of which token to seal」 |

### 5.4 效果 · 目标 · Search（[07-effect-resolution](07-effect-resolution.md)、Composition）

| 交互 | Kind | 决策者 | 要点 |
|---|---|---|---|
| choose **1** enemy/inv/location | `PICK_TARGET` | 控制者 | Target 段；候选管线 U–R + **V dry-run**（目标状态须能被改变 · [21 §3.1.4](21-selection-spec.md)） |
| choose **N / up to N / any number** | `PICK_MULTI` | 控制者 | min_picks / max_picks；同样经 V |
| Search 顶 X **拿哪些** | `SEARCH_TAKE` | 控制者 | 未拿的 **回置顺序** 可另 ask |
| **Choice** 分支（卡面「或」） | `PICK_OPTION` | 控制者 | dry-run OR；resolve 单选 |
| **Optional** 子树 | `OPTIONAL_EFFECT` | 控制者 | |
| attach **并列 location** | `TIE_BREAK` | **队长** | Locked Door 式 |
| spawn enemy **并列地点** | `TIE_BREAK` | **队长** / spawner | RR spawn |
| **Explore** 失败是否继续抽 | `OPTIONAL_EFFECT` | 控制者 | 重复 explore 行动 |

### 5.5 伤害 · 恐怖 · 线索 · Token

| 交互 | Kind | 决策者 | 要点 |
|---|---|---|---|
| Assign damage **到哪些 asset** | `ASSIGN_DAMAGE` | 控制者 | 每点 / 每 asset 上限 |
| Direct damage **仍选 inv** | `PICK_TARGET` | 控制者 | 仅 inv 卡 |
| Assign horror | `ASSIGN_HORROR` | 控制者 | 同 damage 两步 |
| 同时 defeated：**physical vs mental trauma** | `CHOOSE_TRAUMA` | 调查员 | RR |
| discover / place clue **并列地点** | `TIE_BREAK` | **队长** | farthest / most clues 并列 |
| **Uses/charges** 减哪个 sub_key | `PICK_OPTION` | 控制者 | 多 ammo 槽 |

### 5.6 同时点 · 顺序（[14-nested-sequences](14-nested-sequences.md)、[07 §3.4](07-effect-resolution.md)）

| 交互 | Kind | 决策者 | 要点 |
|---|---|---|---|
| 多条 **[reaction] 均选用** 的 resolve 序 | `ORDER_SIMULTANEOUS` | **队长** | 同类 TRIGGERED 内 |
| 多条 **Forced** 同时 resolve | `ORDER_SIMULTANEOUS` | **队长** | RR / Grimoire |
| **Constant / lasting** 不能同时应用 | `ORDER_SIMULTANEOUS` | **队长** | 应用顺序 |
| **in player order** 整段 | `ORDER_PLAYER` | 队长先动 + 顺时针 | 框架 1.4 等 |
| 同时 draw 弱点 **进 hand 序** | `ORDER_CARDS` | 控制者 | simultaneous draw |
| 同时 discard **弃牌堆顶序** | `ORDER_CARDS` | 控制者 / **队长**（遭遇） | RR |
| 多张显现 **Revelation 序** | `ORDER_CARDS` | 控制者 | EnterHandTimingPolicy |
| **Massive** 攻击多调查员序 | `ORDER_ATTACKS` | **队长** | 每调查员各一次 full attack |
| **Replacement** 竞争（若玩家可选 instead） | `INSTEAD_PICK` | 控制者 | 默认引擎 **most recent** 自动 |

### 5.7 敌人 · Hunter · Prey（[08-enemy-engagement](08-enemy-engagement.md)）

| 交互 | Kind | 决策者 | 要点 |
|---|---|---|---|
| Hunter **等距** 多 inv | `TIE_BREAK` | **队长** | 或 prey 最佳者 |
| Prey 指令 **多人并列** | `TIE_BREAK` | **队长** | |
| 自动 engage **多人并列** | `TIE_BREAK` | **队长** | spawn / move 后 |
| Fight/Evade/Engage **选哪个敌人** | `PICK_TARGET`（常为**隐式目标**） | 调查员 | 文本未必写 Target；与 Attack / evasion attempt 同构；无合法 → 整行动 L7 失败（[21 §3.2](21-selection-spec.md)） |

### 5.8 Cancel · Instead · Silver · Grim

| 交互 | Kind | 决策者 | 要点 |
|---|---|---|---|
| Silver Rule **哪张优先** | `SILVER_RULE` | **队长** | 非 Cannot |
| Grim Rule **选最差** | `ChoiceResolver` + `GrimRuleMode` | 引擎 / 暂停 | **非** LI 常规 tie-break |
| 玩家 **Cancel** 自己的 pending | `OPTIONAL_EFFECT` | 控制者 | 若文本允许 |

### 5.9 Setup · 战役 · 局外（[11-investigator-campaign](11-investigator-campaign.md)）

| 交互 | Kind | 决策者 | 要点 |
|---|---|---|---|
| 选 **难度** | `SETUP_CHOICE` | 玩家组 | chaos bag 配方 |
| 选 **队长** | `SETUP_CHOICE` | 玩家组 | 无法一致则随机 |
| **Mulligan** / 起始手牌调 | `SETUP_CHOICE` | 调查员 | |
| 调查员 eliminated → **新队长** | `SETUP_CHOICE` | 剩余玩家 | |
| killed/insane → **新调查员** + 新 deck | `CAMPAIGN_DECISION` | 该玩家 | |
| **升级** 哪张 / 换级 | `CAMPAIGN_DECISION` | 调查员 | experience |
| Campaign guide **分支** | `CAMPAIGN_DECISION` | **队长** / 组 | 记录 campaign log |
| Partner / Lola **role** 等扩展 | `CAMPAIGN_DECISION` / `SETUP_CHOICE` | 调查员 | 扩展战役 |

### 5.10 **不是** 玩家交互（勿误接入 Gate）

| 现象 | 归属 |
|---|---|
| Hunter **最短路径**移动 | 引擎路径算法 |
| Prey **唯一**最近且满足 | 自动 |
| **Most recent** Instead（无选） | `PendingResolution` |
| Forced eligible | 自动 Initiation |
| 牌库顶 **顺序**决定抽到哪张 | Domain pile |
| Hidden **honor** 不共享信息 | 桌谈 / Presentation；**不写** Domain |
| Headless **全知** `definition_id` | 测试策略；≠ 玩家交互 |

---

## 6. 决策者矩阵（速查）

| 决策者 | 典型 Kind |
|---|---|
| **效果/能力控制者** | USE_ABILITY, OPTIONAL_EFFECT, PAY_*, PICK_*, ASSIGN_*, PLAY_CARD, COMMIT_TO_TEST |
| **Performing investigator** | ST 内 commit；([combat] or [agility]) |
| **Lead Investigator（队长）** | ORDER_SIMULTANEOUS, ORDER_PLAYER, ORDER_ATTACKS（Massive）, TIE_BREAK, SILVER_RULE, 部分 SETUP/CAMPAIGN |
| **AOO 触发调查员** | ORDER_ATTACKS（多敌 AOO） |
| **Encounter spawner** | TIE_BREAK（spawn 并列地点；文本指定时） |
| **引擎 / Grim** | GrimRuleMode；无合法 target → fizzle（Eligibility，非 PI） |

---

## 7. 与现有组件的映射

### 7.0 双池定名（已裁决 2026-10-22）

| 窗口 | 中文 | 英文（目标 API） | 语义 |
|---|---|---|---|
| 时点响应窗 | **响应池** | `ResponsePool` | **被动**：时点到了，选不选响 |
| 玩家时间段窗 | **发动池** | `ActivationPool` | **主动**：窗开着，选不选发起 |

**禁止**用 `ActionPool`：规则术语 **Action / 行动** 专指调查员行动。  
**实现现状**：代码仍用 `willingness_*` / `PlayerWindowIntentPool` 标识符，**待重命名**为上表；语义以本表为准。

### 7.1 ResponseWindow（时点响应窗 · 响应池）（已裁决 2026-10-22）

见 [06 §6](06-ability-initiation.md)、[14 §5](14-nested-sequences.md)。  
**形态**：某 when/after 条件打开的时点窗。因 nest 返回后可能冒出新响应，**不**采用「一轮内全部选用再整批 `ORDER_SIMULTANEOUS`」；改用 **粘性响应池**（`ResponsePool`）。

#### 7.1.1 回路

```text
TimingWindow open
  → Forced / 必须结算批：eligible → 自动 Initiation（不进响应池；≥2 条队长选序或 AutoChoice）
  → 响应池 loop：
        1. COLLECT 潜在可选响应（未进池、本窗未结算）
        2. 各控制者决定是否加入响应池（§7.1.3 响应模式；ASK 时经 Gate）
        3. 池非空 → 队长从池中选 1 条（或 AutoChoice）→ 锁 → 重验 → Initiation → nest
        4. nest 返回：非法自动出池；合法未结算者保留；再 COLLECT 未入池者
     until：本轮无人新加入 且 池空
TimingWindow close
```

| 规则 | 说明 |
|---|---|
| **Forced 不进池** | 强制整类优先于可选响应池；仍须过 COLLECT（含 L4） |
| **粘性** | 入池后挂着，避免每个时点反复全员轮询 |
| **可撤回** | 入池后、被选中锁池结算前，控制者可撤 |
| **每次放行 1 条** | 队长（或 `AutoChoiceMode`）从池中挑 1 条 nest；**不**整批锁死总序 |
| **结算中不接新条目** | 锁池期间串行；结束后再 COLLECT / 入池 |
| **本窗不重复** | 与 `_resolved_in_window` 一致；同一 handler 本窗不刷屏 |
| **重验失败** | 丢出池、提示、不关窗，继续 loop |

`ResponsePrompt`（`core/timing/response_prompt.gd`）仍为单次选用轻量 DTO；完整元数据走 `ChoiceRequest`。池内「选哪一条」可用 `PICK_OPTION` / `PICK_TARGET`（条目），**不必**再整批 `ORDER_SIMULTANEOUS`（Forced 批内多条选序仍可用 ORDER）。

#### 7.1.2 与旧「整批 ORDER」对照

| 旧（已废） | 新（响应池） |
|---|---|
| 一轮全部 `USE_ABILITY` → 一次 `ORDER_SIMULTANEOUS` → 按序全跑 | 入池粘住 → 每次队长放行 1 条 → nest 后可再入池 |
| nest 后新反应难插入已锁总序 | nest 返回后对未入池者再轮询加入 |

#### 7.1.3 能力响应模式（可选响应）

电子版减负：按 `definition_id` + `ability_id` 存偏好（会话可覆盖）。**仅可选**入口（反应触发、有时点快速打出、带选用的延时支）；**Forced 不受影响**。

| 模式 | 时点响应窗（响应池） |
|---|---|
| `ASK`（默认） | 首次 eligible 时问是否入池 |
| `AUTO_JOIN` | eligible 则静默入池 |
| `AUTO_DECLINE` | 不问、不入池 |

挂在能力规格 / 运行时偏好表，经 Gate；**禁止**新 `*Policy` 类。全局 `AutoChoiceMode`（§3.2）只管「池内选谁」，不管「进不进池」。

### 7.2 Composition（效果体内）

| 节点 | Interaction |
|---|---|
| `Optional` | resolve 前 `OPTIONAL_EFFECT`；否 → 跳过子树 |
| `Choice` | `PICK_OPTION`；选项来自编译期分支 + dry-run 过滤 |
| `ForEach` + 玩家选目标 | `PICK_TARGET` / `PICK_MULTI`（候选由 L7 合法集预筛） |
| `Then` | **无** 交互；顺序由规则固定 |

dry-run：**Choice** 仍 OR 任一支 CREATED 即可发起；**真实 resolve** 必须 `ask` 后执行选中支。

#### 7.2.1 Must choose · 可执行选项（已裁决 2026-07-07）

Grimoire / FAQ：**必须选择一项可以执行的选项**。

| 阶段 | 行为 |
|---|---|
| **选项枚举** | 编译期分支 → 对每个 option `CompositionDryRunner.simulate` |
| **过滤** | 剔除 **FIZZLE**（无任何 CREATED）的 option |
| **仅一支可执行** | 自动选中，可不弹 UI（headless 默认） |
| **多支可执行** | `PlayerInteractionGate.ask(PICK_OPTION)`；**Lead Investigator** 代选 tie-break 类目标时见 §7.4 |
| **零支可执行** | 整个 Choice **跳过**或 ability fizzle（按外层 Initiation L7；Forced revelation 通常仍 resolve 可执行部分） |

**12124** *You must either (choose one)* — 强制 Choice + 过滤。  
**12126** fail-by *either … or …* — 印刷漏 must；按本表 **must** 语义。

| **12160** *nearest enemy* 等距 → **当前交互玩家**（遭遇显现 = drawer / controller）`PICK_TARGET`。见 16 §7.2.1。

---

### 7.3 PlayerWindow（玩家时间段窗 · 发动池）（已裁决 2026-10-22）

`FrameworkFlowEngine` / `SkillTestEngine` 的 `PlayerWindow` = **开放区间**：允许快速打出、免费触发等，**不是**某条件刚触发的响应批。  
**交互**：拉取式清单 + **发动池**（`ActivationPool`）+ **主表倒计时**；玩家竞争式自行开火，**不是**时点窗响应池（§7.1）。  
**勿**称 Action 池：规则 **Action / 行动** 另有专义。

| Window | 典型可入池内容 |
|---|---|
| `PW_INV_BEFORE/AFTER_ACTION` | 快速打出、`[free]`；宏观 **行动** 仍走客户端 `ActionRequest`（非本池） |
| `PW_SKILL_TEST_AFTER_COMMIT` / `AFTER_REVEAL` | 检定窗合法 `[free]` / 快速 |
| Mythos / Enemy / Upkeep 各 `PW_*` | 同上（窗内合法集） |

#### 7.3.1 节拍

```text
PlayerWindow open → 刷新 eligible 清单 → 主表倒计时（仅当发动池大小 ≤ 1）
玩家将当前通过门槛的能力放入发动池（快速卡 / [free]；可撤回）
  · 池 ≥ 2 → 主表暂停 → 争议宽限（可撤）
       → 宽限尽仍 ≥ 2 → 队长从池中选 1 条（或 AutoChoice）
  · 主表尽 + 池 0 → 关闭整个 PlayerWindow
  · 主表尽 + 池 1 → 锁池 → 重验 → 结算该条目 → 解锁 → 刷新主表（窗仍开）
结算（锁池）期间不接新条目；结束后清单 refresh
```

| 规则 | 说明 |
|---|---|
| **串行权威** | 同时只结算一条；前端清单是预览，提交时重验；失败整条丢弃，无半结算 |
| **可撤回** | 入池后、锁池前控制者可撤；撤到 ≤1 则取消争议、恢复主表逻辑 |
| **争议出口** | ≥2 不得无限停表；宽限 + 队长挑 1（headless 宽限=0 + AutoChoice） |
| **空池超时关窗** | 电子节拍；配置见 `RulesConfig`（可接 `player_window_auto_close_ms`） |
| **每控制器池内上限 1**（建议） | 减少故意双挂冻表；第二条等结算后再加 |

#### 7.3.2 入池次数 `n`（白名单）

入池条目形如 `{ ability_ref, controller, n }`。默认 **`n = 1`**。  
**仅**能力规格声明可批打时（如 `pw_intent_batch` / `max_batch`）才开放次数步进——例：01017《体能训练》检定窗连花资源加值。

| 可批打（白名单） | 保持 `n = 1` |
|---|---|
| 无目标 / 固定自身；无 Choice；每次同构；失败模式单纯 | 要选目标/分支；nest 长手续；限次；快速事件打出 |

锁池后连续 Initiation 最多 `n` 次；中途不再 eligible 则停。竞争单位是**整条条目（含 n）**，不是拆开抢每一次。

#### 7.3.3 能力响应模式在玩家窗的含义

同 §7.1.3 字段，语义不同：

| 模式 | 玩家时间段窗（发动池） |
|---|---|
| `ASK` | eligible 时出现在清单，由玩家决定是否入池 |
| `AUTO_JOIN` | **不**自动发动；最多置顶/高亮建议（开放窗禁止静默连打乱序） |
| `AUTO_DECLINE` | 不进建议列表（完整列表仍可手动找） |

关窗：空池主表超时，或规则指定关闭者 `CONFIRM_STEP` / 全员 Pass（与节拍并存时，超时为空窗快进主路径）。

#### 7.3.4 窗温度与少打扰（交互层 · 已裁决方向 2026-10-22）

玩家时间段 **又碎又开放**（非「一人一轮」的行动次序，却遍布神话/敌人/检定/升级）。规则层发动池解决「怎么抢、怎么关」；**展示与唤起**按窗温度收敛自由——**实现属交互层，本竖切后补**。

| 温度 | 例子 | 默认策略 |
|---|---|---|
| **冷** | 神话开始后、升级重整后等常空手 | eligible 为空 → 不进交互面，直接过 |
| **温** | 行动前后、敌人阶段间隙 | 短主表；仅 **有合法发动** 的控制者被唤起 |
| **热** | 检定 commit / reveal 后 | 较长主表；置顶检定相关 `[free]` |

交互层目标策略（不改规则语义）：

1. **有货才唤起** — 开窗先 COLLECT；无候选的控制者静默 Pass。  
2. **阶段级免打扰**（可选）— 本阶段持续无 eligible 则自动跳过后续冷/温窗；热窗可破例。  
3. **窗配置表** — 按 `PlayerWindow` 配 `main_ms` / `contention_ms` / `skip_if_empty` / `wake_only_eligible`。  
4. **Nest 后定点刷新** — 只通知新获得 eligible 的控制者。  
5. **公平模式**（可选）— 倒计时抢池 vs 玩家序 Pass，与发动池并存。

原则：**默认收敛自由，有需要时再放开**；与响应池（被动、事件驱动）对照，发动池（主动、窗内发起）靠温度表减扰。

### 7.4 伤害 · 目标 · Action 入口

`EffectResolutionGraph` / `DamageWrapper` / `ActionSystem`：

1. 枚举 **合法目标集**（Domain + cannot）
2. `ask(PICK_TARGET | PICK_MULTI | ASSIGN_DAMAGE | ASSIGN_HORROR | TIE_BREAK)`
3. `StateMutator` / Initiation resolve

**Assign 合法性**在 Domain；**怎么分**在 Interaction。`ActionRequest.targets` 可由 UI 预填或经 `PICK_TARGET` 在 `ActionSystem.execute` 内补问。

---

## 8. `ChoiceRequest` 形状

```gdscript
class ChoiceRequest:
    var kind: AhcEnums.ChoiceKind
    var decider_id: StringName       # 谁有权点确认
    var prompt_id: StringName        # 稳定 id（测试 / 日志）
    var prompt: String               # 展示文案（UI）；headless 可空
    var options: Array               # 选项 payload（见下）
    var min_picks: int = 1
    var max_picks: int = 1
    var context: Dictionary          # provenance：flow_id, ability_id, window…
    var default_index: int = 0       # 未确认时的默认选项（硬要求）
    var deadline_ms: int = -1        # >0 = 有限期确认；-1 = 策略层默认（headless 立即 default）
```

**选项 payload 约定**：

| Kind | `options[i]` |
|---|---|
| `USE_ABILITY` | `SequenceHandler` 或 `{handler, label}` |
| `ORDER_SIMULTANEOUS` | 待排序项数组（初始顺序 = COLLECT 顺序） |
| `PICK_TARGET` | `EntityId` 或 `{entity_id, label}` |
| `PICK_OPTION` | `{branch_index, composition_subtree_ref}` |
| `PICK_MULTI` | `EntityId` 或 card_id 数组；`min_picks` / `max_picks` 约束 |
| `COMMIT_TO_TEST` | `{card_id, committed_by}` |
| `PAY_COST` | `{cost_slot, candidates[]}` |
| `SEARCH_TAKE` | `{revealed_ids[], must_take, may_take}` |
| `TIE_BREAK` | 同 `PICK_TARGET`；`decider_id` = lead |

---

## 9. `ChoiceResolver` 与 headless

```text
UI 客户端     →  UiChoiceResolver（ASK 等点击；非 ASK 走 auto_choice_mode）
Headless 测试 →  ScriptingChoiceResolver（按 prompt_id / 队列应答）
默认 / AI     →  DefaultChoiceResolver（mode：ASK/REGISTRATION_ORDER≈原序；RANDOM）
```

测试注入：

```gdscript
ctx.interaction.resolver = ScriptingChoiceResolver.new([
    {"prompt_id": &"reaction:use:card_01001", "pick": true},
    {"prompt_id": &"order:triggered", "pick": [1, 0]},
])
```

**Grim Rule**（`GrimRuleMode.AUTO_WORST`）仅当 **规则书无答案且 lookup 失败** 时在 resolver 层选最差项；**不**替代 Lead Investigator 有明确答案的排序（ArkhamDB RR）。

---

## 10. 队长（Lead Investigator）边界

| 队长 **可以** | 队长 **不可以** |
|---|---|
| 多条 **均已选用** 的 [reaction] **类内** 顺序 | 替他人决定 **用不用** [reaction] |
| 强制多选一且文本无唯一解（合法目标并列） | 越过 Forced 批次优先级 |
| Silver Rule 二选一 | 改 Eligibility 结果 |
| **Forced 同时** resolve 顺序 | **ORDER_SIMULTANEOUS** |
| **Massive** 攻击调查员顺序 | **ORDER_ATTACKS** |
| **in player order** 谁先动 | **ORDER_PLAYER**（队长首动） |

`ctx.lead_investigator_id` / `state.lead_investigator_id` 为 ORDER_* / TIE_BREAK / SILVER_RULE 的 `decider_id`。

---

## 11. 与命名流程 `seq.*` 的关系

玩家交互 **不** 注册新 `seq.*`；嵌在 seq handler 的 **RESOLVE 步** 内作 **确认闸**，确认后继续该步的内联 / nest：

```text
seq.draw.investigator
  D2  reveal …                    # L0，无交互
  D3  enter_hand
        └─ 多弱点 simultaneous → ORDER_CARDS（控制者/队长，见 EnterHandTimingPolicy）

seq.encounter.revelation
  …
  E4  nest 显现
        └─ Optional 子效果 → OPTIONAL_EFFECT（有限期；默认=跳过）

卡面「Engage an enemy at a connecting location」
  PI  PICK_TARGET（连结地点敌人；默认=合法集首项）
  → 内联/nest 移入 + 交战内核（按 §4.0.5；禁止糖 Atom）
```

---

## 12. 实现清单（v1 进度）

| 优先级 | 交付 | 状态 |
|---|---|---|
| P0 | `ChoiceKind` + `ChoiceRequest` + `PlayerInteractionGate.ask` | 骨架 |
| P0 | `DefaultChoiceResolver` / `ScriptingChoiceResolver` | 骨架 |
| P0 | **有限期确认 + default_***（§3.1） | ✅ 默认自动选用（`compute_default` / `resolve_choice` / `used_default` + EventRecord）；**deadline UI 倒计时暂缓** |
| P0 | **§5 完整目录**（本文件） | v0.2 |
| P0 | **SelectionSpec / CandidateFilter / ChoiceBind**（[21](21-selection-spec.md)） | ✅ 骨架；`pick_target`/`select` 已接 Enumerator |
| P1 | 时点响应窗：粘性意愿池 + 队长每次放行 1 条（§7.1） | ✅ 最小竖切（`player_initiated` TRIGGERED；RW-01～03）；响应模式三态待接 |
| P1 | 玩家时间段窗：意图池 + 主表/争议倒计时（§7.3） | ✅ `PlayerWindowIntentPool.pulse`（headless 到期）；PW-01～03；UI 倒计时展示待接 |
| P1 | 能力响应模式 `ASK` / `AUTO_JOIN` / `AUTO_DECLINE` | ✅ `AbilityResponsePreferences` + RW-MODE-01/02 |
| P1 | Composition：`Optional` / `Choice` → Gate（非 nest） | ✅ `OPTIONAL`→`OPTIONAL_EFFECT`；`CHOICE` must→`PICK_OPTION` |
| P1 | ST.2 `COMMIT_TO_TEST` + 检定窗；白名单 `[free]` 入池 `×n`（锚 01017） | ✅ `pw_intent_batch` + PW-BATCH-01；检定窗可 list/enqueue free |
| P2 | §7.3.4 窗温度 / `wake_only_eligible` / 阶段免打扰 | **交互层**（规则语义不变；本竖切只定方向） |
| P2 | 标识符重命名 `willingness_*`→`ResponsePool`、`PlayerWindowIntentPool`→`ActivationPool` | 待接（语义以 §7.0 为准） |
| P2 | `ActionSystem`：`PLAY_CARD` / `PICK_TARGET` | 待接 |
| P2 | `PAY_COST` / `PAY_X` 接 CostPipeline | 待接 |
| P2 | Damage：`ASSIGN_*` / `CHOOSE_TRAUMA` | 待接 |
| P2 | `TIE_BREAK` / `ORDER_ATTACKS` / Hunter spawn | 待接 |
| P3 | `SEARCH_TAKE` / `SETUP_CHOICE` / `CAMPAIGN_DECISION` | 待接 |
| P3 | `INTERACTION_CHOICE` EventRecord（含 `used_default`） | ✅ Gate.ask 写入 |

---

## 13. 开放问题

| ID | 说明 | v1 默认 |
|---|---|---|
| OQ-PI-01 | Optional Forced「may take 1 horror」 | 仍 `OPTIONAL_EFFECT`；控制者选；默认=跳过 |
| OQ-PI-02 | 多调查员各有一条 eligible [reaction] | **已裁决 §7.1**：入意愿池；每次队长（或 AutoChoice）放行 1 条；可撤 |
| OQ-PI-03 | AI 默认 ORDER | 池内选谁见 §3.2；进池见 §7.1.3 响应模式 |

| OQ-PI-04 | Search 未拿牌的 **回置顺序** | 默认保持 reveal 序；可选 `ORDER_CARDS` |
| OQ-PI-05 | `CAMPAIGN_DECISION` 是否独立进程 | v1 与 Setup 同 resolver；战役服务发起 ask |
| OQ-PI-06 | 多种 **additional action** 择一 | 来源 **FAQ 1.10**（[`arkhamdb-rules-reference.md`](../reference/arkhamdb-rules-reference.md) Action 段）；2026 Grimoire 未在仓库 md 中检出同句 |
| OQ-PI-07 | UI `deadline_ms` / 玩家窗主表·争议宽限具体数值 | v1：`RulesConfig`；headless 立即 default / 宽限=0 |
| OQ-PI-08 | 玩家窗每控制器池内上限是否强制为 1 | v1 **建议强制 1**（§7.3.1） |
| OQ-PI-09 | `pw_intent_batch` 白名单字段名与编译位置 | 待挂 [20](20-card-translation-schema.md)；锚 01017 |

---

## 14. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-10-22 | v0.5.2 | **§7.0** 定名响应池/`ResponsePool`·发动池/`ActivationPool`（禁 ActionPool）；**§7.3.4** 窗温度与少打扰（交互层方向，实现后补） |
| 2026-10-22 | v0.5.1 | 落地：意愿池 / 响应模式 / `PlayerWindowIntentPool.pulse` / 01017 `pw_intent_batch` |
| 2026-10-22 | v0.5.0 | **§7.1 意愿池**（时点响应窗）；**§7.3 意图池+倒计时**（玩家时间段窗）；响应模式；`×n` 白名单 |
| 2026-10-21 | v0.4.3 | **§3.2 `AutoChoiceMode`**：`ASK` / `REGISTRATION_ORDER` / `RANDOM`；FAVOR/DISFAVOR 后补 |
| 2026-10-10 | v0.4.2 | **默认自动选用**：`compute_default` / `resolve_choice` / `used_default` + `INTERACTION_CHOICE`；deadline UI 暂缓 |
| 2026-09-29 | v0.4.0 | 挂接 [21-selection-spec](21-selection-spec.md)：通用 filter / 基数 / Memory bind |
| 2026-09-28 | v0.3.0 | **§1.1 / §3.1**：玩家选择=有限期确认+默认；≠ nest/内联；ChoiceRequest 加 deadline |
| 2026-09-21 | v0.2.1 | §2：Gate 的答不写进 Composition 树；指称进 RulesMemory（07 §1.4） |
| 2026-06-18 | v0.2 | **§5 完整交互目录**（10 域）；扩展 `ChoiceKind`；决策者矩阵 |
| 2026-06-18 | v0.1 | 初稿：Interaction vs Eligibility；Gate / Resolver |
