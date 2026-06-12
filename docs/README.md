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
8. [design/06-ability-initiation.md](design/06-ability-initiation.md) — 能力与 Initiation
9. [design/06-registration-buff-model.md](design/06-registration-buff-model.md) — **Registration / Buff 统一模型**
10. [design/07-composition.md](design/07-composition.md) — **效果组合 Composition + dry-run**
11. [design/07-effect-resolution.md](design/07-effect-resolution.md) — 效果解析（组合与包装）
12. [design/07-effect-primitives.md](design/07-effect-primitives.md) — **效果原子（L0）**
13. [design/08-enemy-engagement.md](design/08-enemy-engagement.md) — 敌人与交战
14. [design/09-location-graph.md](design/09-location-graph.md) — 地点与线索
15. [design/10-scenario-encounter.md](design/10-scenario-encounter.md) — 遭遇与 Act/Agenda
16. [design/11-investigator-campaign.md](design/11-investigator-campaign.md) — 调查员与战役
17. [design/12-card-script-api.md](design/12-card-script-api.md) — 卡牌脚本 API

## 规则疑点

请审阅并填写：[open-questions-master.md](open-questions-master.md)（81 条，含 P0/P1/P2 分级；与子文档同步）

## 规则来源

- `ahc100_rulebook-web.pdf`（2026 Core Set Rulebook）
- `arkham_grimoire-web.pdf`（Grimoire v1.0）

## 版本

设计草案 v0.3 · 2026-05-25（共 16 份文档 + 81 条 Open Questions）
