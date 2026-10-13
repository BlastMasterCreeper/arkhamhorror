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
| **Forced Ability** | **强制能力** | `Forced –`；引擎直执 |
| **Free triggered ability** | **免费触发能力** | 魔典 `[free]`；ArkhamDB 玩家牌常标 `[fast]`；Player Window |
| **Reaction triggered ability** | **反应触发能力** | `[reaction]` |
| **Action triggered ability** | **激活触发能力** | `[action]`；经 Activate |

---

## 调查员行动与状态

| English | 简中（规范） | 备注 |
|---------|-------------|------|
| **Fight** | **攻击** | Fight action；`seq.action.fight`；≠ 敌人 perform attack |
| **Evade (action)** | **躲避** | 行动种类；`seq.action.evade`；≠「闪避」「规避」；≠ 躲避尝试 / 躲避效果 |
| **Evasion attempt** | **躲避尝试** | 躲避行动等衍生的技能检定（通常敏捷）；≠ 自动躲避 |
| **Evade (effect)** | **躲避效果** | 解除交战 + 横置；入口含成功躲避尝试、自动躲避等 |
| **Automatically evade** | **自动躲避** | 包装并**产生**躲避效果：无检定、非「自动成功」的尝试 |
| **Investigate** | **调查** | `seq.action.investigate` |
| **Engage** | **接战** | 主动交战；`seq.action.engage` / `seq.engage` |
| **Move** | **移动** | 狭义地点变更且**遵守连接**；`seq.effect.move` + `move_kind=move`；≠ 移动到地点；≠ 广义区划转移；≠ 地点交换 |
| **Move to (a location)** | **移动到地点** | 狭义地点变更但**无视连接**；同核 `move_kind=move_to` |
| **Exhaust** | **横置** | 改平放区卡牌/在场敌人 `exhausted`；`seq.effect.exhaust`；≠ 费用中的 exhaust |
| **Ready** | **重整** | 同上反向；`seq.effect.ready`；Upkeep 4.3；**未横置** = `!exhausted` |
| **Doom** | **毁灭** | doom 标记；密谋推进 |
| **Story asset** | **剧情支援** | 有遭遇组；正面仍是玩家 cardtype；背面可为遭遇卡背 |
| **Scenario card**（引擎） | **冒险卡牌** | 有遭遇组的卡；≠「遭遇 cardtype」 |
| **Encounter cardtype** | **遭遇卡牌类型** | enemy / treachery / location |
| **Player card back** | **玩家卡背** | `card_back=player`；无文本背面 / 牌库外观 |
| **Encounter card back** | **遭遇卡背** | `card_back=encounter`；同上 |
| **Card back (kind)** | **卡背类型** | **仅**背面轴；≠ 正面 cardtype；≠ CardFace A/B |
| **Search** | **搜寻** | `seq.effect.search`；搜牌库须洗（整库或顶 N）；弃牌堆不洗；≠ look at / find |
| **Enter play** / put into play | **进场** | 广义移动（`seq.zone.move`）结果：场外→场上；听 L0 区划+过滤；**不是效果**；不铸 `seq.effect.enter_play` |
| **Defeat** | **击败** | **效果**；伤/恐上限或卡面击败；主体含敌人/调查员/支援；成功后 nest 退场 |
| **Leave play** / 退场 | **退场** | 广义移动场上→场外；支援/敌人进弃牌堆 ≠ discard 效果包装 |
| **Player cardtype** | **玩家卡牌类型** | asset / event / skill 等 |

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
| Evade 四层 | **躲避**行动 ≠ **躲避尝试** ≠ **躲避效果** ≠ **自动躲避**；效果入口含成功尝试与自动躲避；自动躲避 ≠ 自动成功的尝试 |
| Evade | **躲避**；≠ 闪避 / 规避 |
| Exhaust / Ready | **横置** / **重整**；未横置 = `!exhausted`；≠ 耗尽 / 疲劳 / 竖置 / 就绪 |
| Fight action vs enemy attack | 调查员 **攻击**行动 ≠ 敌人 **perform attack**（借机攻击 / 反击 / 警戒 / 阶段攻击） |
| Retaliate vs Alert | **反击** / **警戒** 均在 **ST.7 apply 完成后**（post-ST7）；均须敌人 **未横置**；≠ ST.7 `on_fail` 内的失败转嫁 |
| Doom | **毁灭**；≠ 厄运 |
| Encounter vs Scenario | FAQ 常混用；三轴：正面 **cardtype** / **卡背类型** / **遭遇组**。剧情支援 = 有遭遇组 + 玩家正面类型（卡背常为遭遇卡背） |
| 卡背类型 | **仅**无文本背面；勿与正面类型或翻面（CardFace）混用；**无**双面皆卡背 |
| 剧情支援 Activate | 同地点遭遇卡可触发 ≠ 剧情支援自动可触发；后者常靠卡面「该地点调查员可…」 |

---

## 对话与文档表述

- 每次使用英文专用词，须在同句或括号内附中文说明。
- 设计文档：中文正文为主；首次出现可「中文（English）」。
- 代码 / Catalog：保留英文 API（如 `CardRegistry.is_retaliate`、`AttackKind.RETALIATE`）。
