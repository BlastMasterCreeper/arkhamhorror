# 36 — 兴趣点宇宙清单（对照现流程与代码）

> **状态**：设计草案 v0.1 · 2026-11-24  
> **依赖**：[35-legal-interest](35-legal-interest.md)、[06-ability-initiation](06-ability-initiation.md)、[16-player-interaction](16-player-interaction.md)、[21-selection-spec](21-selection-spec.md)、[03-action-system](03-action-system.md)  
> **代码锚**：`InitiationIntent` · `AbilityInitiationPipeline.can_initiate` · `CompositionDryRunner` · `CandidateViability` · `AhcEnums.PlayerWindow` / `ChoiceKind` / `ActionType`  
> **目的**：回答「哪些东西要进 \(\mathrm{Universe}\)，用兴趣点维护可行性」。不是把所有 `ChoiceKind` 都当发起可行性。

---

## 0. 分层

| 层 | 问什么 | 进兴趣点宇宙？ |
|---|---|---|
| **A. 发起可行性** | 这条打出/能力/基础行动**能否进入**付费与管道（`dataOK ∧ wouldCreate(效果)`） | **要**；有限枚举 |
| **B. must / 目标可行性** | 某个候选绑定下效果会不会改变世界（V 层） | **要**；宇宙 = 当前 Ask 的候选集 |
| **C. 意愿 / 排序 / 付费方式** | 用不用、谁先谁后、弃哪张付费 | **一般不**做 `wouldCreate` 兴趣点（PI）；候选可由 A/B 预筛 |

06 §5：**L7 不在 COLLECT 对全量候选跑**；兴趣点表服务的是「当前焦点下已枚举的发起项 / 当前 must 候选」，不是全游戏所有假设。

---

## 1. 焦点 → 宇宙 A（发起）

焦点 \(f\) 首先来自打开的窗 / 池（代码与 16 对齐）。

### 1.1 玩家时间段窗 → `InitiationPool`

`AhcEnums.PlayerWindow`（`core/types/ahc_enums.gd`）：

| 窗口 | 宇宙里典型 op |
|---|---|
| `PW_INV_BEFORE_ACTION` / `PW_INV_AFTER_ACTION` | 当前调查员：基础行动入口；手牌 `PLAY_CARD`；场上 `[action]` / `[free]`；窗内可打的 Fast 打出 |
| `PW_INV_AFTER_PHASE_BEGIN` / `PW_INV_BEFORE_TURN_END` | 同上子集（以该窗允许的发起种类为准） |
| `PW_MYTHOS_*` / `PW_ENEMY_*` / `PW_UPKEEP_AFTER_READY` | 窗内允许的 `[free]` / Fast 打出 / 文本指定免费触发 |
| `PW_SKILL_TEST_AFTER_COMMIT` / `AFTER_REVEAL` | 检定窗内可发起的快速/反应对称打出与 `[free]`；**投入**见 §1.3 |

每一条宇宙元素对应可组装的 `InitiationIntent`（现码只有 `ABILITY` | `PLAY_CARD`）或基础 `ActionRequest`（Fight/Move/…，经行动系统再进管道）。

**代码**：`AbilityInitiationPipeline.can_initiate` = 限制 + 打出前置 + `can_pay` + `_passes_dry_run`（`InitiationLegalityChecker` → `CompositionDryRunner`）。兴趣点维护的正是这类 `can_initiate(op)` 布尔。

### 1.2 时点响应窗 → 入池前 / 放行前

响应池（16 §7.1）里每条候选能力：

| 阶段 | 检测 |
|---|---|
| COLLECT 入池 | L1–L5（现 `EligibilityPipeline`；**不含** L7） |
| 控制者 `USE_ABILITY` 点「用」之后、真正 initiate 前 | `PRE_INITIATE`…`PRE_RESOLVE`：L6 + **L7 `wouldCreate`** |

兴趣点宇宙 B 侧：池中每条「若选用则会 initiate 的 op」。  
`USE_ABILITY` 本身是意愿（层 C）；**亮不亮「可合法用」** 可由层 A 预计算（可选 UX）。

Forced：无「不用」；仍要 L7，失败则 fizzle（27 / 06）。宇宙 = 当前 Forced 批内每条。

### 1.3 检定 ST.2 投入

| op | 可行性 |
|---|---|
| `COMMIT_TO_TEST` 每张候选技能/手牌 | `dataOK`（区、图标、`FORBID_COMMIT` 等）+ 若投入带须落地的 on_commit 效果则 `wouldCreate`；纯投入修饰常以 data 为主 |

宇宙 = 当前检定下，主检者（及协助规则允许时）手牌/可投入集合——有限。

### 1.4 基础行动（客户端 → Rules）

`ActionType`：`FIGHT` / `EVADE` / `ENGAGE` / `MOVE` / `INVESTIGATE` / `DRAW` / `RESOURCE` / `ACTIVATE` / `PLAY` / `PARLEY` / `RESIGN`…

| 入口 | 宇宙元素 | 有效性要点 |
|---|---|---|
| Fight / Evade / Engage | 「对该敌人做该行动」（隐式目标时常先枚举敌人） | 无合法目标 → 整行动 L7 失败（21 §3.2）；Aloof 等走限制 |
| Move | 每个连结地点一步 | 连通 + 限制 |
| Investigate | 当前地点（或卡面改写） | 限制 / 线索相关 |
| Activate / Play | 归入 §1.1 的 `ACTIVATE_ABILITY` / `PLAY_CARD` | 同发起管道 |
| Draw / Resource | 单条基础行动 | 牌库空等 → L7 / 限制 |

调查阶段行动窗内，基础行动条数 ≈ 类型 ×（目标候选或 1），仍有限。

---

## 2. 宇宙 B（must / 目标 / 选项可行性）

打开某次 Gate 且规则要求 **must** 或目标必须能被改变时：

| 来源（16 / 21） | 宇宙元素 | 代码 |
|---|---|---|
| `PICK_TARGET` / `PICK_MULTI` | 每个候选实体 id | `CandidateViability.filter_viable`：bind → dry 效果尾 → `has_any_created` |
| `PICK_OPTION`（must 多支） | 每个选项支 | dry 该支；须能改变局面（16 §5.2） |
| 卡面 `choice_must` / ST.7 must | 同上 | Composition dry；12126 等锚 |
| Fight/Evade **隐式选敌** | 每个粗候选敌人 | 无合法 → 行动失败 |

**May / Optional**：层 C 允许「不选」；若要对**某一个**选项显示「选了有没有用」，仍可用同一 `wouldCreate`，但不阻塞「跳过」。

Search / Discard / Assign 等：先做结构合法集；仅当规则要求「选了必须改变局面」时才进 V；分配伤害等以约束与池为主，不一定走效果 CREATED。

---

## 3. 不进可行性兴趣点（层 C）

这些是交互，不是「效果会否改变世界」的发起门槛：

| Kind | 原因 |
|---|---|
| `USE_ABILITY` / `OPTIONAL_EFFECT`（意愿） | 在 A 已通过的前提下问「要不要」 |
| `ORDER_*` / `TIE_BREAK` / `SILVER_RULE` | 排序与冲突，不裁定效果空转 |
| `PAY_COST` / `PAY_X` | L6 如何付；候选枚举 ≠ L7 |
| `CONFIRM_STEP` / `SETUP_CHOICE` / `CAMPAIGN_DECISION` | 流程确认 |
| `CHAOS_PICK` / `INSTEAD_PICK` | 混乱/替换选择（另有竞争规则） |
| `JOIN_POOL` / `PICK_RESPONSE`（队长放行） | 池调度；条目合法性在入池/发起前已用 A |

---

## 4. 与现实现的差距（兴趣点落地时）

| 现况 | 兴趣点策略要求 |
|---|---|
| `can_initiate` 每次全做限制+费用+dry | `commitPlus` 写入 `World.feasibility`；按 \(\mathrm{Interest}\) 重算（35 v0.2） |
| COLLECT 故意不跑 L7（06） | **保持**：宇宙 A 的 L7 只对当前池/窗已列出的 op，不在「所有订阅能力」上扫 |
| `CandidateViability` 每次对全候选 dry | 宇宙 B：按 \(\mathrm{Deps}\cap\mathrm{Touched}\) 只重算脏候选 |
| `InitiationIntent.Kind` 仅 ABILITY/PLAY_CARD | 基础行动可作平行 op 键，或经 Activate/Play 归一 |
| 判据 `has_any_created` | 与「效果后 \(\pi(w')\neq\pi(w)\)」对齐（费用不计入效果） |

---

## 5. 规模（为何开销不大）

| 宇宙 | 量级（典型） |
|---|---|
| 手牌打出 | ≤ 手牌张数（常 ≤10） |
| 场上 [action]/[free] | 每名调查员数张支援 × 条数 |
| 基础行动 × 目标 | 行动种类 × 同地点敌人数等 |
| 响应池条目 | 单时点同时合法反应，通常个位数 |
| must 候选 | U–N 后的选项，通常个位数到十几 |

\(\mathrm{Interest}\) 求交可忽略；重算次数 ≤ 上表。全量重算宇宙 A 本身也可接受；兴趣点避免的是**无关 \(\Delta\) 后的重复全检**。

---

## 6. 清单（实现对照用）

**必须进宇宙并维护 `legal` / `viable`：**

1. 当前 `InitiationPool` 内每条可尝试：`PLAY_CARD`、`ACTIVATE_ABILITY` / `[free]`、Fast 打出  
2. 当前行动窗：每条基础 `ActionType` 入口（含隐式目标展开后的每条）  
3. 当前响应池 / Forced 批：每条将发起的能力 op（L7 在选用或强制发起前）  
4. ST.2：每张可投入候选（data + 如有 on_commit 效果则 wouldCreate）  
5. 打开中的 must：`PICK_TARGET`/`PICK_MULTI`/`PICK_OPTION` 的每个候选绑定（V）

**不进可行性兴趣点：** 意愿、排序、并列、确认、战役/Setup、纯付费方式选择。

---

## 7. 裁决

| # | 裁决 |
|---|---|
| U1 | 兴趣点宇宙 = **当前焦点下有限发起项 ∪ 当前 must 候选**，对照 16 目录与现枚举 |
| U2 | L7 / `wouldCreate` 只挂在这些 op/绑定上；COLLECT 全量能力仍不跑 L7 |
| U3 | `CandidateViability` 与 `can_initiate` dry 同判据：效果改变世界（不计费用） |
| U4 | ChoiceKind 中意愿/排序类不建 wouldCreate 兴趣表 |

---

## 8. 修订

| 日期 | 说明 |
|---|---|
| 2026-11-24 | v0.1：对照 PlayerWindow / Initiation / ChoiceKind / 代码锚列宇宙 A·B·C |
