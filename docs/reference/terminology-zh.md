# 简中术语对照（引擎 / 设计文档）

> **维护**：与 [`.cursor/rules/terminology-zh.mdc`](../../.cursor/rules/terminology-zh.mdc) 同步；用户补充译名时两处一并更新。  
> **用法**：设计文档、测试说明、对话用 **简中规范名**；代码标识符（类名、`flow_id`、枚举、Grimoire 英文引文）保持英文。

---

## 卡牌与效果

| English | 简中（规范） | 备注 |
|---------|-------------|------|
| **Revelation** | **显现** | 能力类型 `Revelation –`；≠ weakness 子类型 |
| Surge | 涌动 | 遭遇显现/涌动链 |
| Peril | 险境 | 遭遇帧内持续 Cannot |
| Play (card) | **打出** | **仅 asset / event**；≠ skill |
| Commit (skill) | **投入** | skill 投入检定；Grimoire：**不能**称 play |
| **state primitive** | **状态原语** | L0 三类 GameState 写入 |
| **effect** | **效果** | dry-run 可 CREATED |
| **Reveal (card)** | **揭示（卡牌）** | L0 `AtomRevealCard` |
| **Player Interaction** | **玩家交互** | `PlayerInteractionGate` |
| **Hidden** | **隐私** | 秘密入手；见 [grimoire-glossary-extract §隐私](grimoire-glossary-extract.md) |

---

## 调查员行动与状态

| English | 简中（规范） | 备注 |
|---------|-------------|------|
| **Fight** | **攻击** | Fight action；`seq.action.fight`；≠ 敌人 perform attack |
| **Evade** | **躲避** | `seq.action.evade`；≠「闪避」「规避」 |
| **Investigate** | **调查** | `seq.action.investigate` |
| **Engage** | **接战** | 主动交战；`seq.action.engage` / `seq.engage` |
| **Move** | **移动** | `seq.action.move` |
| **Exhaust** | **横置** | `exhausted` = 已横置 |
| **Ready** | **重整** | Upkeep 4.3 重整横置卡；**未横置** = `!exhausted` 状态表述 |
| **Doom** | **毁灭** | doom 标记；密谋推进 |

---

## 敌人攻击与关键词

| English | 简中（规范） | 备注 |
|---------|-------------|------|
| **Attack of Opportunity** | **借机攻击** | AOO；`AttackKind.OPPORTUNITY` |
| **Retaliate** | **反击** | Fight 失败 vs **未横置**带 retaliate → **ST.7 apply 完成后**攻击；不横置 |
| **Alert** | **警戒** | Evade 失败 vs **未横置**带 alert → **ST.7 apply 完成后**攻击；可不 engaged；不横置 |
| **Hunter** | **猎手** | Enemy Phase 3.2 向最近调查员移动 |
| **Patrol** | **巡逻** | Enemy Phase 3.2 向 designated target 移动 |
| **Massive** | **庞大** | **未横置**时虚拟交战同地点全体；**永不**进威胁区 |
| **Elusive** | **逃逸** | 敌人 **攻击**（含借机）或被 **攻击**（Fight）resolve 后 flee |
| **Doomed** | **厄运降临** | 敌人 **被击败**（defeat）时当前密谋 +1 **毁灭**；discard 不算 defeat |
| **Aloof** | **冷漠** | 不自动 engage |
| **Prey** | **猎物** | `*Prey –`* 指令；engage / Hunter 等距；**不 nest** |

实现细节：[08-enemy-engagement §6](../design/08-enemy-engagement.md)（OQ-03-02 · OQ-08-03）。

---

## 勿混用

| 易混 | 规范 |
|------|------|
| Revelation | **显现**；≠ 弱点子类型；≠ 非规范的「揭示」「暴露」 |
| Skill | **投入**检定；不能 **打出** |
| Evade | **躲避**；≠ 闪避 / 规避 |
| Exhaust / Ready | **横置** / **重整**；未横置 = `!exhausted`；≠ 耗尽 / 疲劳 / 竖置 / 就绪 |
| Fight action vs enemy attack | 调查员 **攻击**行动 ≠ 敌人 **perform attack**（借机攻击 / 反击 / 警戒 / 阶段攻击） |
| Retaliate vs Alert | **反击** / **警戒** 均在 **ST.7 apply 完成后**（post-ST7）；均须敌人 **未横置**；≠ ST.7 `on_fail` 内的失败转嫁 |
| Doom | **毁灭**；≠ 厄运 |

---

## 对话与文档表述

- 每次使用英文专用词，须在同句或括号内附中文说明。
- 设计文档：中文正文为主；首次出现可「中文（English）」。
- 代码 / Catalog：保留英文 API（如 `CardRegistry.is_retaliate`、`AttackKind.RETALIATE`）。
