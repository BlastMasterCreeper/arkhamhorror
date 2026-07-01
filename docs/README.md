# Arkham Horror LCG — 规则引擎设计文档

本目录为 2026 Core Set + Grimoire v1.0 规则引擎的设计规格。

**实现代码**见项目根目录 [`README.md`](../README.md)（`core/`、`rules/`、`tests/run_headless.gd`）。

## 阅读顺序

1. [00-architecture-overview.md](00-architecture-overview.md) — 四层架构与模块划分
2. [design/00-framework-step-index.md](design/00-framework-step-index.md) — Grimoire Framework Step 完整索引
3. [design/01-game-state-zones.md](design/01-game-state-zones.md) — 状态与区域
4. [design/02-framework-flow.md](design/02-framework-flow.md) — 框架流程引擎
5. [design/03-action-system.md](design/03-action-system.md) — 行动与借机攻击
6. [design/04-skill-test-engine.md](design/04-skill-test-engine.md) — 技能检定 ST.1–ST.8
7. [design/05-chaos-bag.md](design/05-chaos-bag.md) — 混沌袋与场景参考
8. [design/06-ability-initiation.md](design/06-ability-initiation.md) — 能力、Initiation、**Eligibility L0–L7**、ResponseWindow
9. [design/06-registration-buff-model.md](design/06-registration-buff-model.md) — **Registration / Buff 统一模型**（**§16 Buff 应用场合清单**）
10. [design/06c-stat-projections.md](design/06c-stat-projections.md) — **StatProjection**（L3 历史谓词 · Register 对齐 · demand 升温）
11. [design/07-composition.md](design/07-composition.md) — **效果组合 Composition + dry-run**
12. [design/07-effect-resolution.md](design/07-effect-resolution.md) — 效果解析（**§3.2–§3.4 同时点竞争 / Replacement**）
13. [design/07-effect-primitives.md](design/07-effect-primitives.md) — **§0.1 三档译法**（Spawn/Prey 参数；Prey 仅 engage 内核）；§5.3 Reveal + 离散
14. [design/08-enemy-engagement.md](design/08-enemy-engagement.md) — 敌人与交战
15. [design/09-location-graph.md](design/09-location-graph.md) — 地点与线索
16. [design/10-scenario-encounter.md](design/10-scenario-encounter.md) — 遭遇与 Act/Agenda
17. [design/11-investigator-campaign.md](design/11-investigator-campaign.md) — 调查员与战役
18. [design/12-card-script-api.md](design/12-card-script-api.md) — 卡牌脚本 API
19. [design/14-nested-sequences.md](design/14-nested-sequences.md) — **嵌套序列 ResolutionSequenceStack**
20. [design/15-timing-entry-catalog.md](design/15-timing-entry-catalog.md) — **规范时点入口**（含 **§16 调查员抽牌 D0–D5**）
21. [design/16-player-interaction.md](design/16-player-interaction.md) — **玩家交互**（§5 完整目录）
22. [design/17-seq-runtime.md](design/17-seq-runtime.md) — **命名流程运行时**（seq.* checklist · 缺口 · 实施顺序）

## 规则疑点

请审阅并填写：[open-questions-master.md](open-questions-master.md)（81 条，含 P0/P1/P2 分级；与子文档同步）

## 官方规则 PDF

见 [`reference/`](reference/README.md)（2026 PDF/Markdown、[ArkhamDB 规则](https://zh.arkhamdb.com/rules) 镜像）。

**符号记法**（`[reaction]`、`[action]`、`[willpower]` 等）：[`reference/arkham-symbol-notation.md`](reference/arkham-symbol-notation.md)

## 规则来源（引擎设计基准）

| 优先级 | 来源 |
|---|---|
| **1** | [`reference/arkham-grimoire-v1.0.pdf`](reference/arkham-grimoire-v1.0.pdf) — 2026 Grimoire（**裁定优先**） |
| **2** | [`reference/2026-core-rulebook.pdf`](reference/2026-core-rulebook.pdf) — 2026 Core Set Rulebook |
| **3** | [ArkhamDB 规则合集（中文站）](https://zh.arkhamdb.com/rules) · 离线 [`arkhamdb-rules-reference.md`](reference/arkhamdb-rules-reference.md) — 第一版 RR+FAQ；与 2.0 **几乎无出入**；与 Grimoire 冲突时以 Grimoire 为准 |

## 版本

设计草案 v0.3 · 2026-06-18（共 18 份文档 + 81 条 Open Questions；§06c StatProjection · §15 draw 子 flow）
