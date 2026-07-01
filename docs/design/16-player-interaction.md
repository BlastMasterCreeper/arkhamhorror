# 16 — 玩家交互 (Player Interaction)

> **依赖**：[06-ability-initiation.md](06-ability-initiation.md)（Eligibility / ResponseWindow）、[07-composition.md](07-composition.md)（Choice / Optional）、[14-nested-sequences.md](14-nested-sequences.md)（同窗口多响应）、[00-architecture-overview.md](../00-architecture-overview.md)  
> **规则来源**：Grimoire Initiation、Effects · Target、Simultaneously；ArkhamDB RR · Lead Investigator / Choices  
> **状态**：v0.2 · 2026-06-18 — 扩展 **完整交互目录** §5

---

## 1. 目标

将 **需人类裁决** 的规则步骤纳入 **同一套引擎接口**，使 headless 测试与 UI 客户端 **共用** 决策路径，且 **不污染** Domain / Rules 客观层。

**玩家交互（player interaction）** 回答：**在客观合法的前提下，谁、以什么顺序、选哪一支、是否发动** — 不是 Eligibility 关卡（L0–L7）。

**范围**：凡 Grimoire / RR 写「choose / may / decides / in … order / select」且 **非纯自动** 的步，均应能归到本目录；**禁止** 在 Rules 各模块散落 `ui_*` 回调。

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

**禁止**：在 `StateMutator`、Buff 查询或 Eligibility 内写 `if ui_clicked`；**禁止** Presentation 直接改 `GameStateStore`。

---

## 3. 统一入口：`PlayerInteractionGate`

Rules 层 **唯一** 向「玩家」索取决策的入口（headless 与 UI 相同）：

```gdscript
class PlayerInteractionGate:
    var resolver: ChoiceResolver

    func ask(request: ChoiceRequest, ctx: GameContext) -> Variant
```

`GameContext.interaction` 持有 gate；`CompositionExecutor`、`ResolutionSequenceStack` 响应轮、`DamagePipeline` 等 **只调 gate**，不调 UI。

**EventRecord**：每次 `ask` 写入 `INTERACTION_CHOICE`（或 `GameLog` `INTERACTION`），payload 含 `kind`、`decider_id`、`option_ids`、`picked`。

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
| choose **1** enemy/inv/location | `PICK_TARGET` | 控制者 | Target 段；L7 预筛合法集 |
| choose **N / up to N / any number** | `PICK_MULTI` | 控制者 | min_picks / max_picks |
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
| Fight/Evade/Engage **选哪个敌人** | `PICK_TARGET` | 调查员 | Action 入口已带 target 时可省略 |

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

### 7.1 ResponseWindow（能力窗口）

见 [06 §6](06-ability-initiation.md)、[14 §5](14-nested-sequences.md)。

```text
TimingWindow open
  → Eligibility COLLECT (L1–L5)
  → FORCED 批：自动 Initiation（无 USE_ABILITY）
  → TRIGGERED 批：
        每条 eligible → ask(USE_ABILITY) → 控制者
        选用集合非空 → ask(ORDER_SIMULTANEOUS) → 队长
        按序 Initiation（L6–L7）→ nest
  → refresh 直至 eligible 空或 CONFIRM_STEP 关闭
TimingWindow close
```

`ResponsePrompt`（`core/timing/response_prompt.gd`）为 **单次 USE_ABILITY 结果** 的轻量 DTO；完整元数据走 `ChoiceRequest`。

### 7.2 Composition（效果体内）

| 节点 | Interaction |
|---|---|
| `Optional` | resolve 前 `OPTIONAL_EFFECT`；否 → 跳过子树 |
| `Choice` | `PICK_OPTION`；选项来自编译期分支 + dry-run 过滤 |
| `ForEach` + 玩家选目标 | `PICK_TARGET` / `PICK_MULTI`（候选由 L7 合法集预筛） |
| `Then` | **无** 交互；顺序由规则固定 |

dry-run：**Choice** 仍 OR 任一支 CREATED 即可发起；**真实 resolve** 必须 `ask` 后执行选中支。

### 7.3 Framework · SkillTest `PlayerWindow`

`FrameworkFlowEngine` / `SkillTestEngine` 的 `PlayerWindow` = **「允许发动 [action]/[reaction] 的开放区间」**，不是新决策类型。

| Window | 典型 Interaction |
|---|---|
| `PW_INV_BEFORE/AFTER_ACTION` | `USE_ABILITY`；`PLAY_CARD` / `ACTIVATE_ABILITY`（宏观行动已选后） |
| `PW_SKILL_TEST_AFTER_COMMIT` | `USE_ABILITY`；可选追加 `COMMIT_TO_TEST` |
| `PW_SKILL_TEST_AFTER_REVEAL` | `USE_ABILITY` |
| Mythos / Enemy / Upkeep 窗 | 同 ResponseWindow 批处理 |

`close_player_window` = `CONFIRM_STEP`（或 eligible 空则自动关）。

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
    var default_index: int = 0       # headless 默认策略
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
UI 客户端     →  CustomChoiceResolver（等玩家点击 → 回填）
Headless 测试 →  ScriptingChoiceResolver（按 prompt_id / 队列应答）
默认 / AI     →  DefaultChoiceResolver（default_index；ORDER 保持原序）
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

玩家交互 **不** 注册新 `seq.*`；嵌在 seq handler 的 **RESOLVE 步** 内：

```text
seq.draw.investigator
  D2  reveal …                    # L0，无交互
  D3  enter_hand
        └─ 多弱点 simultaneous → ORDER_CARDS（控制者/队长，见 EnterHandTimingPolicy）

seq.encounter.revelation
  …
  E4  nest 显现
        └─ Optional 子效果 → OPTIONAL_EFFECT
```

---

## 12. 实现清单（v1 进度）

| 优先级 | 交付 | 状态 |
|---|---|---|
| P0 | `ChoiceKind` + `ChoiceRequest` + `PlayerInteractionGate.ask` | 骨架 |
| P0 | `DefaultChoiceResolver` / `ScriptingChoiceResolver` | 骨架 |
| P0 | **§5 完整目录**（本文件） | v0.2 |
| P1 | ResponseWindow：`USE_ABILITY` + `ORDER_SIMULTANEOUS` | 待接 |
| P1 | Composition：`Optional` / `Choice` | 待接 |
| P1 | ST.2 `COMMIT_TO_TEST` + 检定窗 `USE_ABILITY` | 待接 |
| P2 | `ActionSystem`：`PLAY_CARD` / `PICK_TARGET` | 待接 |
| P2 | `PAY_COST` / `PAY_X` 接 CostPipeline | 待接 |
| P2 | Damage：`ASSIGN_*` / `CHOOSE_TRAUMA` | 待接 |
| P2 | `TIE_BREAK` / `ORDER_ATTACKS` / Hunter spawn | 待接 |
| P3 | `SEARCH_TAKE` / `SETUP_CHOICE` / `CAMPAIGN_DECISION` | 待接 |
| P3 | `INTERACTION_CHOICE` EventRecord | 待接 |

---

## 13. 开放问题

| ID | 说明 | v1 默认 |
|---|---|---|
| OQ-PI-01 | Optional Forced「may take 1 horror」 | 仍 `OPTIONAL_EFFECT`；控制者选 |
| OQ-PI-02 | 多调查员各有一条 eligible [reaction] | 并行 USE_ABILITY；仅 **均选用** 的 TRIGGERED 批交队长排序 |
| OQ-PI-03 | AI 默认 ORDER | 保持 COLLECT 顺序 |

| OQ-PI-04 | Search 未拿牌的 **回置顺序** | 默认保持 reveal 序；可选 `ORDER_CARDS` |
| OQ-PI-05 | `CAMPAIGN_DECISION` 是否独立进程 | v1 与 Setup 同 resolver；战役服务发起 ask |
| OQ-PI-06 | 多种 **additional action** 择一 | 来源 **FAQ 1.10**（[`arkhamdb-rules-reference.md`](../reference/arkhamdb-rules-reference.md) Action 段）；2026 Grimoire 未在仓库 md 中检出同句 |

---

## 14. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-06-18 | v0.2 | **§5 完整交互目录**（10 域）；扩展 `ChoiceKind`；决策者矩阵 |
| 2026-06-18 | v0.1 | 初稿：Interaction vs Eligibility；Gate / Resolver |
