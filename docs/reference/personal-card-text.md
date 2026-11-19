# 个人版卡面改写（Personal Card Text）

> **性质**：仓库维护者个人版；**不是**官方 errata / FAQ。  
> **用途**：让「持续效果 / 延时 / 仍投入才生效」从描述自明，供编译与引擎对齐。  
> **冲突时**：引擎设计可采个人版；对照栏仍保留官方印刷与 FAQ。

---

## 默认模型（技能）

技能更接近 **检定期间仍投入才生效的「支援」**，不是事件那种打出即结算完毕。

区划对齐 Grimoire（OQ-01-03 重裁）：投入 → **`LIMBO` / `LimboKind.COMMITTED`**（与显现用的 `RESOLVING` 分子区）；能力寿命 **`WHILE_COMMITTED`** = 留在该子区。

| | 事件 | 技能（个人版默认） | 支援 |
|---|---|---|---|
| 区 | 打出 → LIMBO/`RESOLVING` | 投入 → LIMBO/`COMMITTED` | PLAY |
| 文本何时有效 | 结算中效果体 | **仍在 COMMITTED 子区** | WHILE_IN_PLAY |
| 成功/失败 / *After this test ends* | — | 能力，绑投入；**不**先造延时 | — |
| 回收到手 / 离开投入 | 通常已结算完 | 离开 COMMITTED → **能力关闭** | Constant 卸 |

仅当卡面写出 **创建时刻 + 寿命**（如 *When you commit… gains … for the duration of…*）时，才编译为 **持续效果**（Gain/Lose + `DURATION`），源牌可离 LIMBO 仍活。

---

## 06111 · Daring（大胆）

### 官方印刷（ArkhamDB）

> Commit only to a skill test during an attack or evasion attempt against an enemy. That enemy gains retaliate and alert for the duration of this skill test. After this test ends, draw 1 card.

### 官方 FAQ（v2.0 · Silas 收回）

- *gains retaliate and alert for the duration…* → **持续效果**，收回手牌后仍保留至检定结束。  
- *After this test ends, draw 1 card* → **技能能力**（非延时）；须仍投入该次检定才结算。

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
| After this test ends, draw 1 | 技能能力（仍投入） | 离开 LIMBO/`COMMITTED` → 不结算；**不是** `UNTIL_FIRED` 延时 |

---

## 变更记录

| 日期 | 卡 / 主题 | 摘要 |
|---|---|---|
| 2026-11-19 | 区划 | 投入进 LIMBO/`COMMITTED`；与 `RESOLVING` 分子区（对齐 OQ-01-03 重裁） |
| 2026-11-19 | 06111 | 个人版加 *When you commit* /「投入后」，显式创建持续；抽牌句仍绑投入 |
