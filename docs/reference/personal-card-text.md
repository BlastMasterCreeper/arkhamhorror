# 个人版卡面改写（Personal Card Text）

> **性质**：仓库维护者个人版；**不是**官方 errata / FAQ。  
> **用途**：让「持续效果 / 延时 / 仍投入才生效 / `may` 辖域」从描述自明，供编译与引擎对齐。  
> **冲突时**：引擎设计可采个人版；对照栏仍保留官方印刷与 FAQ。

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
| When you commit → gains retaliate + alert | `seq.effect.grant`（KEYWORD×2） | `DURATION(THIS_SKILL_TEST)`；**不**随收回手牌卸 |
| After this test ends, draw 1 | **延时** `skill_test_ends`（`UNTIL_FIRED`） | commit 武装；**提前** uncommit → 卸；ST.8 弃置后开火（不要求当时仍 LIMBO） |

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

## 变更记录

| 日期 | 卡 / 主题 | 摘要 |
|---|---|---|
| 2026-11-23 | After this test ends | 改裁为延时 @ `skill_test_ends`（ST.8 弃置后；提前 uncommit 取消） |
| 2026-11-22 | may…and you get | 裁决读法 B；08101 / 10077（及同模 08090）个人版改为 *and get* |
| 2026-11-20 | Constant | 扩展：持续句可 Constant + 非 in-play 寿命（含 `WHILE_COMMITTED`） |
| 2026-11-19 | 区划 | 投入进 LIMBO/`COMMITTED`；与 `RESOLVING` 分子区（对齐 OQ-01-03 重裁） |
| 2026-11-19 | 06111 | 个人版加 *When you commit* /「投入后」，显式创建持续；抽牌句仍绑投入 |
