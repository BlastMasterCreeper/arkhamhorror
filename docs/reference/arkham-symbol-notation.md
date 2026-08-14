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
| `[unique]` | Unique 关键词（标题前星标） |
| `[codex]` | Codex 条目（`[codex] X`） |
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

## 7. PDF 抽出字形 → 本标准

[`arkham-grimoire-v1.0.md`](arkham-grimoire-v1.0.md) 与 [`2026-core-rulebook.md`](2026-core-rulebook.md) 由 PDF 抽取。官方图标字体落入 Unicode **私用区**，原文会显示成 `` / `󲆍` 等无法检索的方块。抽出脚本（`tools/pdf_to_markdown.py` / `tools/arkham_symbol_escape.py`）按 Grimoire p.47 图标页转义为本表记法。

| PDF 字形（BMP） | 本标准 |
|---|---|
| `U+F25A` | `[free]` |
| `U+F26D` | `[reaction]` |
| `U+F259` | `[action]` |
| `U+F250` / `U+F252` / `U+F253` / `U+F251` / `U+F26C` | `[willpower]` / `[intellect]` / `[combat]` / `[agility]` / `[wild]` |
| `U+F25B` `U+F25C` `U+F260` `U+F25E` | `[skull]` `[cultist]` `[tablet]` `[elder_thing]` |
| `U+F25D` / `U+F25F` | `[auto_fail]` / `[elder_sign]` |
| `U+F263` / `U+F261` / `U+F278` | `[per_investigator]` / `[unique]` / `[codex]` |
| `U+F256` `U+F258` `U+F254` `U+F257` `U+F255` | `[guardian]` `[seeker]` `[rogue]` `[mystic]` `[survivor]` |

规则书封底偶发同一套字形的补充平面副本（BMP + `0xE2F20`，如 `U+F218D` = `[reaction]`），同一脚本处理。

刷新抽出：

```powershell
python tools/pdf_to_markdown.py
# 仅转义已有 Markdown（无需 PDF）：
python tools/pdf_to_markdown.py --rewrite-md
```

---

## 8. 变更记录

| 日期 | 说明 |
|---|---|
| 2026-08-14 | Grimoire / 入门规则书 PDF 私用区字形转义为 `[symbol]` |
| 2026-06-18 | 初稿；对齐 ArkhamDB `[symbol]` 格式 |
