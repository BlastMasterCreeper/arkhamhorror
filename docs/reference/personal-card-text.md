# 个人版卡面改写（Personal Card Text）

> **性质**：仓库维护者个人版；**不是**官方 errata / FAQ。  
> **用途**：让「持续效果 / 延时 / 仍投入才生效 / `may` 辖域 / 取消攻击时点」从描述自明，供编译与引擎落地。  
> **引擎落地（已裁决 2026-11-28）**：卡面效果实现 **必须** 按本文件个人版正文；官方印刷 / ArkhamDB / FAQ 仅作 **对照**，不直接驱动编译或运行时。  
> **对照栏**：各卡仍保留官方印刷（及 FAQ 摘要）以便对照；与个人版冲突时以个人版为准。

---

## 默认模型（技能）

区划对齐 Grimoire（OQ-01-03 重裁）：投入 → **`LIMBO` / `LimboKind.COMMITTED`**（与显现用的 `RESOLVING` 分子区）。

**Constant 扩展（2026-11-20）**：`AbilityKind.CONSTANT` = 持续生效、无需 Initiation；寿命不必 in play。投入期间**持续句** → Constant + `WHILE_COMMITTED`（与隐私 Constant + `WHILE_HIDDEN_IN_HAND`、场上 Constant + `WHILE_IN_PLAY` 同形）。LIMBO 仍不算 in play——改的是 Constant 种类定义，不是把 LIMBO 算进场。

| | 事件 | 技能 | 支援 |
|---|---|---|---|
| 区 | LIMBO/`RESOLVING` | LIMBO/`COMMITTED` | PLAY |
| 持续句 | — | **Constant** + `WHILE_COMMITTED` | Constant + `WHILE_IN_PLAY` |
| *If succeed/fail* | — | ST.7（非 Constant） | — |
| *After this test ends* | — | **延时** LISTENER @ `skill_test_ends`（ST.8 弃置后开火；提前 uncommit 取消） | — |
| 显式 lasting | — | Gain + `DURATION`（非 Constant） | — |

仅当卡面写出 **创建时刻 + 寿命**（如 *When you commit… gains … for the duration of…*）时，才编译为 **持续效果**（Gain/Lose + `DURATION`），源牌可离 LIMBO 仍活。

---

## 06111 · Daring（大胆）

### 官方印刷（ArkhamDB）

> Commit only to a skill test during an attack or evasion attempt against an enemy. That enemy gains retaliate and alert for the duration of this skill test. After this test ends, draw 1 card.

### 官方 FAQ（v2.0 · Silas 收回）

- *gains retaliate and alert for the duration…* → **持续效果**，收回手牌后仍保留至检定结束。  
- *After this test ends, draw 1 card* → FAQ 称技能能力、须坚持投入到检定结束；**引擎落地为延时**（ST.8 弃置后才 `skill_test_ends`，牌已不在 LIMBO）。Silas 提前收回 → 取消该延时。

现文未写出「投入时创建」；持续身份靠 FAQ 补丁，描述本身不自明。

### 个人版改写（对齐 FAQ 预期且描述自明）

**EN**

> Commit only to a skill test during an attack or evasion attempt against an enemy. **When you commit Daring,** that enemy gains retaliate and alert for the duration of this skill test. After this test ends, draw 1 card.

**ZH**

> 仅可投入对敌人的攻击或躲避尝试中的技能检定。**投入 Daring 后，**该敌人在本次检定期间获得反击（retaliate）和警戒（alert）。本次检定结束后，抽 1 张牌。

### 引擎映射（个人版）

| 句 | 译法 | Lifetime / 条件 |
|---|---|---|
| Commit only… attack or evasion | `commit` + `commit_only.kinds: [fight, evade]` | `test_kind` 不符 → 不可投入 |
| When you commit → gains retaliate + alert | `on_commit` → Gain KEYWORD×2 | `DURATION(THIS_SKILL_TEST)`；**不**随收回手牌卸 |
| After this test ends, draw 1 | **延时** `after_test_ends` @ `skill_test_ends` | commit 武装；**提前** uncommit → 卸；ST.8 弃置后开火（不要求当时仍 LIMBO） |

竖切：`data/arkhamdb/imported/daring_06111.json` · `ADB-06111-*`。

---

## `may … and you get`（技能替换 + 修正）

### 问题

印刷常见：

> you **may use** ⟨A⟩ instead of ⟨B⟩[,] **and you get** +N skill value.

`may` 与直陈 `you get` 并用 `and` 并列时有歧义：

| 读法 | 选「不」换技能时 |
|---|---|
| A · `may` 只罩替换；`+N` 必给 | `and` 连「跳过的方面」与「仍结算的方面」——口语悬空 |
| B · `may` 罩整包（替换 **与** `+N`） | 拒绝则两边都不发生；`and` 始终连可选包内两项 |

对照已自明的印刷（**90063** Trusty Bullwhip）：

> This attack uses ⟨agi⟩ instead of ⟨combat⟩. You get +2 skill value for this attack.

两句、无 `may`：替换与 `+N` 都必结算。后文另有 *you may exhaust … **to** deal +1 **and** automatically evade*——此处 `may` 才真罩住 `and` 两边（同一 `to` 目的语）。

**个人版裁决（2026-11-22）**：对 *may use … instead of … and you get +N* 模板，采 **读法 B**——`may` 辖域含替换与 `+N`；选「不」则本句两方面都不创建。改写时把后项收进情态补语（*and get*），去掉易误导的直陈 *and you get*。

---

## 08101 · Divination（占兆）

### 官方印刷（ArkhamDB）

> [action]: Investigate. For this investigation, you may use [willpower] instead of [intellect], and you get +1 skill value. If you succeed, spend 1 or 2 charges. …

（同循环 **08090** Brand of Cthugha：*For this attack, you may use [willpower] instead of [combat], and you get +1 skill value.* ——同一模板，个人版同裁。）

### 个人版改写

**EN**

> [action]: Investigate. For this investigation, **you may use [willpower] instead of [intellect] and get +1 skill value.** If you succeed, spend 1 or 2 charges. …

**ZH**

> [行动]：调查。本次调查中，**你可以使用意志代替智力，并获得 +1 技能值**（二者同属可选；不选则都不适用）。若成功，花费 1 或 2 充能。…

### 引擎映射（个人版）

| 句 | 译法 |
|---|---|
| may use will instead of int **and get +1** | 一次 PI 确认：接受 → 本调查 skill=will **且** +1；拒绝 → 仍用智力、无此句 +1 |
| 成功后 spend charges / 发现线索 | 仍在检定 ST.7 等原槽；与 `may` 包无关 |

---

## 10077 · British Bull Dog

### 官方印刷（ArkhamDB）

> [action] Spend 1 ammo: Fight. You may use [agility] instead of [combat] for this attack and you get +2 skill value. This attack deals +1 damage. Ignore the aloof keyword for this attack.

（无逗号；仍是 *may use … and you get*。）

### 个人版改写

**EN**

> [action] Spend 1 ammo: Fight. **You may use [agility] instead of [combat] for this attack and get +2 skill value.** This attack deals +1 damage. Ignore the aloof keyword for this attack.

**ZH**

> [行动] 花费 1 弹药：攻击。**你可以使用敏捷代替战斗，并获得 +2 技能值**（同属可选）。本次攻击造成 +1 伤害。本次攻击忽略冷漠（aloof）。

### 引擎映射（个人版）

| 句 | 译法 |
|---|---|
| may use agi instead of combat **and get +2** | 与 08101 同：一包 PI；拒绝则无替换、无此句 +2 |
| deals +1 damage / Ignore aloof | **不在** `may` 包内；发动本 Fight 即适用 |

---

## 08001 · Daniela Reyes（丹妮拉·雷耶斯）

### 官方印刷（ArkhamDB · Edge of the Earth Investigator Expansion）

> [reaction] After an enemy attacks you (except an attack of opportunity you provoked), even if that attack was canceled: Either deal 1 damage to that enemy, or automatically evade it.
> [elder_sign] effect: +1. If you were attacked by an enemy this round, you automatically succeed, instead.

**次数限制**：官方印刷 **无** *Limit once per round*（勿与 2026 Core 重印 Daniela 的不同能力混淆）。

### 问题

官方把 *even if that attack was canceled* 挂在「敌人攻击你后」一条 After-attack 上。引擎侧：

- **Cancel 不会打开一般 After-attack**——被取消的攻击 **未发起成功**，不能假装发起已完成再开 After。
- 「攻击被取消后」是 **另一条时点**，不能靠把取消情形塞进 After-attack 钩来模拟。

### 个人版改写（拆成两条共享效果体的时点钩）

**EN**

> [reaction] After an enemy attacks you (except an attack of opportunity you provoked): Either deal 1 damage to that enemy, or automatically evade it.
>
> [reaction] After an attack against you is canceled (except an attack of opportunity you provoked): Either deal 1 damage to that enemy, or automatically evade it.

**ZH**

> [反应] 一名敌人攻击你后（你引起的借机攻击除外）：对该敌人造成 1 点伤害，或自动躲避它。
>
> [反应] 对你的一次攻击被取消后（你引起的借机攻击除外）：对该敌人造成 1 点伤害，或自动躲避它。

（两条钩 **共享同一效果体**；官方无 once/round → 个人版亦不加跨钩共用次数限制。）

### 引擎映射（个人版）

| 句 | 译法 | 备注 |
|---|---|---|
| After an enemy attacks you（除 AOO you provoked） | 反应钩 @ 一般 After-attack（对你） | Cancel **不**打开此窗 |
| After an attack against you is canceled（同 AOO 例外） | 反应钩 @ **取消对你的攻击后**（新时点） | 不假装 initiate 成功 |
| Either deal 1 damage **or** automatically evade | 共享效果体：PI 二选一 → 伤害 **或** 自动躲避（`seq.effect.evade` / `mode=automatic`） | 两条钩各挂同一 Composition |

**对照（可选）**：05046 Gavriella Mizrah 同有 *even if that attack was canceled*；若采本模板可拆成「攻击你后 / 取消对你的攻击后」两条（该卡官方另有 *Limit once per round*，跨钩共用）。本文件不展开其全文。

---

## 09072 · Chuck Fergus（查克·弗格斯）

### 官方印刷（ArkhamDB · The Scarlet Keys · Taboo 首条）

> When you play a Tactic or Trick event, exhaust Chuck Fergus: Choose one -
>
> - That event gains: "Fast. Play only during your turn."
> - That event costs 2 fewer resources to play.
> - You get +2 skill value while performing a skill test during the resolution of that event.

### 问题

印刷用 *When you play… gains Fast* 易被读成：先按 **无 Fast** 的 `PLAY_CARD` 发起（已评估 Play 行动花费）→ 再在发起/结算中「获得快速」。则：

1. **行动花费已在发起路径上定死**，后加的 Fast **盖不住整个发起**（广义打出），无法减免那 1 点 Play action。
2. 用 Would / 「提前批时序」假装改写已开的发起，违背「时点只由可执行结算产生；有效性不过则无发起时点」。

FAQ（2024-03）：Chuck 给的 Fast **不能**用来在回合外打出——须卡面自带回合外许可；Taboo 已写 *Play only during your turn*。

### 个人版改写（Constant · 额外费用 → 第二条发起路径）

**只改 Fast 选项的模型**；减费 / +2 技能另条（本竖切不展开）。

**EN**

> **Constant** — While Chuck Fergus is ready and in play, you have an **additional way** to play a Tactic or Trick event from your hand:
>
> As an **additional cost** to initiate that play on this path, exhaust Chuck Fergus and choose **Fast**. That initiation uses **Fast** (*Play only during your turn*) for the **entire** play initiation: it does **not** cost a Play action. This is **not** a Would rewrite of a Play-action initiation.

**ZH**

> **Constant** — 当 Chuck Fergus 在场且未横置时，你有一条 **额外的** 打出 Tactic / Trick 事件的发起路径：
>
> 走该路径发起打出时，以 **额外费用** 横置 Chuck Fergus 并选择 **快速**。该次发起全程按 **快速**（*仅可在你的回合打出*）结算：**不**花费 Play 行动。这 **不是** 对「已按行动打出发起」的 Would / 时点改写。

（减费 / +2 技能仍可作同形「选路径」或独立选项；引擎竖切先只落地 Fast 路径。）

### 引擎映射（个人版）

| 句 | 译法 | 备注 |
|---|---|---|
| Constant · ready in play | 持续打开路径目录，**不是** `[reaction] When you play` | 寿命随 Chuck 在场且未横置 |
| additional cost: exhaust Chuck | `AdditionalCost::Exhaust` 挂在 **路径** 上；评估/支付在 **发起有效性** 阶段 | 非 RR「狭义打出结算步才付额外费用」 |
| choose Fast → Fast whole initiation | `InitiationPath` · `PlayForm::FastWindow` + `DuringControllerTurn` | 广义打出；`play_action_cost = 0` |
| kinds still PLAY_CARD | 种类仍是打出，不是能力 | 06 §4.2 |
| **禁止** Would / 时点改写 | `is_would_rewrite ≡ false` | prefs 2026-11-28 |

竖切：`arkham_rules::initiation` · `chuck_fast_path` / `offer_play_paths` / `evaluate_path`。  
详细实现走查：[39-chuck-initiation-path](../design/39-chuck-initiation-path.md)。

---

## 变更记录

| 日期 | 卡 / 主题 | 摘要 |
|---|---|---|
| 2026-11-28 | 09072 Chuck Fergus | Fast = Constant 额外费用→第二条 PLAY_CARD 发起路径（广义打出）；非 Would |
| 2026-11-28 | 页眉裁决 | 引擎/卡面效果落地 **必须** 跟个人版；官方印刷仅对照 |
| 2026-11-28 | 08001 Daniela Reyes | 「even if canceled」拆成 After-attack + After-cancel 两条钩，共享效果体；官方无 once/round |
| 2026-11-23 | After this test ends | 改裁为延时 @ `skill_test_ends`（ST.8 弃置后；提前 uncommit 取消） |
| 2026-11-22 | may…and you get | 裁决读法 B；08101 / 10077（及同模 08090）个人版改为 *and get* |
| 2026-11-20 | Constant | 扩展：持续句可 Constant + 非 in-play 寿命（含 `WHILE_COMMITTED`） |
| 2026-11-19 | 区划 | 投入进 LIMBO/`COMMITTED`；与 `RESOLVING` 分子区（对齐 OQ-01-03 重裁） |
| 2026-11-19 | 06111 | 个人版加 *When you commit* /「投入后」，显式创建持续；抽牌句仍绑投入 |
