# 官方规则参考（PDF + Markdown + ArkhamDB）

本目录存放 **2026 Core Set** 官方 PDF、**可检索 Markdown 全文**，以及 **[ArkhamDB 规则合集](https://zh.arkhamdb.com/rules)** 离线镜像。引擎规格仍以 [`../design/`](../design/) 为准。

## 权威层级

| 优先级 | 来源 | 说明 |
|---|---|---|
| **1** | [`arkham-grimoire-v1.0.pdf`](arkham-grimoire-v1.0.pdf) / [`.md`](arkham-grimoire-v1.0.md) | **2026 Grimoire** — 本项目裁定优先 |
| **2** | [`2026-core-rulebook.pdf`](2026-core-rulebook.pdf) / [`.md`](2026-core-rulebook.md) | 2026 入门规则书 |
| **3** | [ArkhamDB 规则](https://zh.arkhamdb.com/rules) / [`arkhamdb-rules-reference.md`](arkhamdb-rules-reference.md) | 第一版 RR + FAQ + 扩增订；**中文可读**；与 2.0 RR **几乎无出入**（社区经验）。与 Grimoire 冲突时 **以 Grimoire 为准** |

## 文件索引

| 文件 | 来源 | 用途 |
|---|---|---|
| [`2026-core-rulebook.pdf`](2026-core-rulebook.pdf) | AHC100 入门规则书 | 新手流程、回合概览 |
| [`2026-core-rulebook.md`](2026-core-rulebook.md) | PDF 提取 | grep / 全文检索 |
| [`arkham-grimoire-v1.0.pdf`](arkham-grimoire-v1.0.pdf) | Grimoire v1.0 | **权威裁定** |
| [`arkham-grimoire-v1.0.md`](arkham-grimoire-v1.0.md) | PDF 提取 | 引擎常查首选 |
| [`arkhamdb-rules-reference.md`](arkhamdb-rules-reference.md) | [zh.arkhamdb.com/rules](https://zh.arkhamdb.com/rules) | 英文 RR+FAQ 镜像；**`[symbol]` 记法来源** |
| [`arkham-symbol-notation.md`](arkham-symbol-notation.md) | 本项目约定 | design 文档统一符号表 |
| [`grimoire-glossary-extract.md`](grimoire-glossary-extract.md) | 手工策展 | 高频条目 + 引擎映射草案 |

## 刷新离线镜像

```powershell
python -m pip install pypdf
python tools/pdf_to_markdown.py
python tools/fetch_arkhamdb_rules.py
```

## 与 `design/` 文档的分工

| 层次 | 位置 |
|---|---|
| 官方原文 | PDF |
| 可检索全文 | 本目录 `.md` |
| 引擎抽象 / API | [`../design/`](../design/) |
| 未裁决疑点 | [`../open-questions-master.md`](../open-questions-master.md) |

## Grimoire 关键章节（引擎常查）

| 主题 | Grimoire | ArkhamDB（近似条目） |
|---|---|---|
| **Drawing Cards** | [p.9–10](arkham-grimoire-v1.0.md) | `## Drawing Cards` |
| When / After / Triggering | p.4–5, p.23–25 | Glossary + Appendix I–II |
| 同时结算 | p.19 | `Priority of Simultaneous Resolution` |
| Initiation + AOO | p.31 | `Appendix I: Initiation Sequence` |
| Framework / Mythos 1.4 | p.27–29 | `Appendix II: Timing and Gameplay` |
| Skill Test ST.1–ST.8 | p.30 | Skill Test Timing |

### 已知与 2026 Grimoire 可能存在的差异（查疑时用）

| 主题 | ArkhamDB（旧 FAQ/RR） | 2026 Grimoire |
|---|---|---|
| 空库抽牌 + horror | 完成 **整次 draw 后** 再受 1 horror（FAQ 2.x 表述） | horror 与抽牌 **同时**（p.10 bullet） |
| 同时抽 ≥2 张 | 两来源均写 simultaneously + mid-draw shuffle | Grimoire 额外：带 Revelation 的牌 **按入手顺序** resolve（不限 weakness） |

> 2026 Grimoire 退役旧 FAQ；上表仅作 **迁移对照**，实现以 Grimoire 为准。

## 版本

- Grimoire v1.0 · 2026 Core Set
- ArkhamDB 镜像：随 `fetch_arkhamdb_rules.py` 更新
