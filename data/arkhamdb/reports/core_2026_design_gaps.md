# Core 2026 → 设计表回填线索

基于 `data/arkhamdb/pack/core/*.json` 自动统计。

> **Phase 4 详表**：见 [`phase4_core_2026_backfill.md`](phase4_core_2026_backfill.md)（基于 `imported/*.json`；Surge 仅计首行关键词，12124 Cosmic Evils 为 Peril + 正文「gains surge」）。

## 1. 关键词 / seq（15 §17 · 06 §16.2）

| 模式 | 命中 | 引擎路由 | 样例 |
|---|---:|---|---|
| `surge_text` | 3 | Surge 链 · seq.draw.encounter | 12126 Forbidden Secrets, 12160 Raising Suspicions, 12163 Aerial Pursuit |
| `peril_text` | 2 | peril Register · REST E3 | 12124 Cosmic Evils, 12195 Torment |
| `hidden_flag` | 1 | 隐私 E4 · FORBID_LEAVE_HAND | — |
| `hidden_text` | 0 | 隐私（文本） | — |
| `aloof_text` | 6 | FORBID_ATTACK / engage 条件 | 12099 The Nameless Lurker, 12139 David Renfield, 12143 Abigail Foreman |
| `hunter_text` | 13 | Hunter listener | 12009 Black Chamber Operative, 12074 Hunter's Instinct, 12114 Servant of Flame |
| `retaliate_text` | 9 | Retaliate handler | 12114 Servant of Flame, 12121 Cantor of Flame, 12138 Servant of Flame |
| `massive_text` | 2 | engage 拒绝 | 12179 Elokoss, 12179b Elokoss |
| `spawn_line` | 0 | SpawnInstructionSpec | — |
| `prey_line` | 0 | PreyInstructionSpec | — |
| `patrol_paren` | 0 | PatrolTargetSpec | — |

## 2. 能力类型（06 §2）

| 模式 | 命中 | 管线 |
|---|---:|---|
| `revelation_bold` | 32 | REVELATION |
| `forced_bold` | 33 | FORCED · 不经 Initiation |
| `reaction` | 29 | TRIGGERED_REACTION · Initiation |
| `action` | 49 | TRIGGERED_ACTION · Initiation+AOO |
| `fast` | 17 | Fast / Player Window |
| `elder_sign` | 5 | Elder Sign · ST 子流程 |
| `limit_once` | 15 | LimitSpec · L5 |

## 3. RESTRICTION 线索（06 §16.4.2）

| 模式 | 命中 | 备注 |
|---|---:|---|
| `cannot` | 12 | 需 NLP/人工细分为 FORBID_* |
| `immune` | 0 | EffectGraph step 4 |

## 4. MODIFIER 查询站需求（06 §16.3）

Core 2026 卡面含大量 `+N [skill]`、`+N damage`、`-N cost` 类文本；需在编译期映射到
`StatRef` 增长表（SKILL 已实现，SHROUD/DAMAGE/HORROR/COST 待 enum）。

## 5. 待人工译码优先队列（建议）

1. 全部 `<b>Revelation</b>` treachery（遭遇管线 ENT/ENC）
2. `[reaction]` / `[action]` 资产（TriggeredAbilityService + Initiation）
3. Spawn/Prey 敌人
4. Hidden / Surge / Peril 关键词遭遇
5. Agenda/Act `forced` 场景能力（场景脚本，非卡牌 Initiation）
