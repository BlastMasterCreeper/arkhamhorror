# 规则符号记法（ArkhamDB 标准）

> **来源**：[ArkhamDB 规则页](https://zh.arkhamdb.com/rules) 与 [`arkhamdb-rules-reference.md`](arkhamdb-rules-reference.md)  
> **用途**：本项目 **design/** 文档与引擎注释的统一记法；便于与线上规则对照阅读。  
> **权威措辞**仍以 Grimoire PDF 为准；符号仅作可读性约定。

---

## 1. 触发能力图标

| 记法 | 含义 |
|---|---|
| `[free]` | Free triggered ability；任意 player window |
| `[reaction]` | Reaction triggered ability；when / after 条件 |
| `[action]` | Action triggered ability；Activate 行动花费（可重复，如 `[action][action]` = 2 actions） |
| `[fast]` | **ArkhamDB 文本**：Core 玩家牌用此标记 **Free triggered**（闪电图标）；引擎 `segment.kind=fast` → `register_as:free`。**另**：规则书 Fast **关键词**（快速打出）是独立 keyword，不经本触发分段。 |

**Forced / Revelation** 在规则正文中为 **粗体前缀**（非方括号）：

| 记法 | 含义 |
|---|---|
| **Forced –** | Forced ability |
| **Revelation –** | Revelation ability |

---

## 2. 技能与检定

| 记法 | 含义 |
|---|---|
| `[willpower]` | 意志 |
| `[intellect]` | 智力 |
| `[combat]` | 战斗 |
| `[agility]` | 敏捷 |
| `[wild]` | Wild 技能图标 |

战斗 / 闪避等行动：调查员通常选择 `[combat]` 或 `[agility]` 之一进行检定（见 Rules Reference · Fight / Evade）。

---

## 3. 混沌标记（Chaos token）

| 记法 | 含义 |
|---|---|
| `[skull]` `[cultist]` `[tablet]` `[elder_thing]` | 场景 reference 上定义的符号效果 |
| `[auto_fail]` | 自动失败 |
| `[elder_sign]` | 旧印；触发 performing investigator 卡上的 **Elder Sign** 能力 |

---

## 4. 其他常见符号

| 记法 | 含义 |
|---|---|
| `[per_investigator]` | Per investigator（× 起始调查员人数） |
| `[unique]` | Unique 关键词 |
| `[guardian]` `[seeker]` `[rogue]` `[mystic]` `[survivor]` | 职业图标 |

---

## 5. 引擎文档中的用法

- 描述 **卡面能力** 时写 `[reaction] After you draw a card`，不写 emoji 或「反应图标」。
- 描述 **Initiation 花费** 时写「花费 2 `[action]`」或 `[action][action]`。
- 描述 **Forced / Revelation** 时保留 **Forced –** / **Revelation –** 与 Grimoire 一致。
- 代码枚举名（如 `TRIGGERED_REACTION`）不变；文档面向读者时用本表记法。

---

## 6. 迁移对照（旧文档 → 本标准）

| 旧写法 | 本标准 |
|---|---|
| 🕭 | `[reaction]` |
| 🕮 | `[action]` |
| 🕤 | `[free]` |
| 🕓 | `[willpower]` |
| 🕣 | `[per_investigator]` |
| 🕯（混沌/旧印语境） | `[elder_sign]` |
| 🌐 | `[wild]` |

---

## 7. 变更记录

| 日期 | 说明 |
|---|---|
| 2026-06-18 | 初稿；对齐 ArkhamDB `[symbol]` 格式 |
