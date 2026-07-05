# Phase 4 · Core 2026 设计表回填

数据源：`data/arkhamdb/imported/core_2026*.json`（Phase 1–3 导入层）。
卡牌数：**166**（两包合计，已跳过 stub）。

回填目标：[06 §16.3–16.5](../design/06-registration-buff-model.md)、[15 §17](../design/15-timing-entry-catalog.md)、[12 §1.1](../design/12-card-script-api.md)。

---

## 1. MODIFIER 查询站（06 §16.3）

| 卡面模式 | 命中卡数 | 建议 StatRef / 查询站 | 样例 |
|---|---:|---|---|
| `+N [skill]` / fight / evade | 24 | **MOD-Q-SKILL** | 12002 Daniela's Wrench；12014 Isabelle's Twin .45s；12166 Whippoorwill |
| `+N damage` | 11 | **MOD-Q-DAMAGE-AMT** | 12002 Daniela's Wrench；12014 Isabelle's Twin .45s |
| `+N horror` | 0 | **MOD-Q-HORROR-AMT** | — |
| `+N shroud` | 1 | **MOD-Q-SHROUD** | 12159 Flash Flood |
| `-N cost` / reduce cost | 0 | **MOD-Q-COST** | — |

## 2. RESTRICTION Intent（06 §16.4.2）

含 `cannot` 卡面：**12** 张（ArkhamDB 统计原为 12，含 back_text / 多句扩展）。

| 卡码 | 卡名 | 建议 Intent | 入口 | 片段 |
|---|---|---|---|---|
| 12009 | Black Chamber Operative | `IF_YOU_CANNOT` | 条件分支 · 非 RESTRICTION Register | If you cannot, this enemy readies, engages you, and makes an immediate attack. |
| 12012 | The Necronomicon | `DOMAIN_PERMANENT` | Domain · Permanent 关键词 | It cannot leave play except by the [action] ability below. |
| 12059 | Cosmic Flame | `IF_YOU_CANNOT` | 条件分支 · 非 RESTRICTION Register | If you reveal a [skull] token during this test, remove 1 charge from Cosmic Flame (if you cannot, ta |
| 12062 | Second Sight | `IF_YOU_CANNOT` | 条件分支 · 非 RESTRICTION Register | If you reveal a [cultist] token during this test, remove 1 charge from Second Sight (if you cannot,  |
| 12071 | Cosmic Flame | `IF_YOU_CANNOT` | 条件分支 · 非 RESTRICTION Register | If you reveal a [skull] token during this test, remove 1 charge from Cosmic Flame (if you cannot, ta |
| 12098 | The Gold Bug | `DOMAIN_PERMANENT` | Domain · Permanent 关键词 | It cannot leave play except by the [action] ability below. |
| 12164 | Rogue Gangster | `IF_YOU_CANNOT` | 条件分支 · 非 RESTRICTION Register | If you cannot, this enemy attacks you. |
| 12169 | A Gathering | `IMMUNITY` | 免疫 · 非 FORBID Intent | attached cannot be damaged. |
| 12170 | A Ritual | `IMMUNITY` | 免疫 · 非 FORBID Intent | attached cannot be damaged. |
| 12179 | Elokoss | `FORBID_MOVE` | REST-E-ACTION / 敌人指令 | Elokoss gets +5 [per_investigator] health, cannot move, and cannot make attacks of opportunity. |
| 12179b | Elokoss | `FORBID_UNCLASSIFIED` | 待人工 | She cannot attack you for the remainder of the round. |
| 12193 | Langour | `FORBID_PLAY` | REST-E-PLAY | Otherwise, you cannot play or commit cards of that type (asset, event, or skill) this round. |

## 3. LISTENER / 关键词（06 §16.5）

### 3.1 引擎关键词（已编译进 CardDefinition）

| 键 | 卡数 | 卡清单（前 12） |
|---|---:|---|
| `keyword_hunter` | 13 | 12009 Black Chamber Operative; 12074 Hunter's Instinct; 12114 Servant of Flame; 12122 Hellhound; 12138 Servant of Flame; 12162 Bat Horror; 12164 Rogue Gangster; 12166 Whippoorwill; 12177 Queen's Knight; 12178 Herald of Flame; 12179b Elokoss; 12180 Servant of Flame |
| `keyword_retaliate` | 9 | 12114 Servant of Flame; 12121 Cantor of Flame; 12138 Servant of Flame; 12141 Naomi O'Bannion; 12164 Rogue Gangster; 12179 Elokoss; 12179b Elokoss; 12180 Servant of Flame; 12189 Dark Magician |

### 3.2 Forced / After 触发片段（LISTENER 增长线索）

| 触发模式 | 命中 | 样例 |
|---|---:|---|
| `after_fight` | 0 | — |
| `after_enemy_defeated` | 0 | — |
| `after_draw` | 1 | 12005 Detective's Intuition |
| `after_reveal` | 2 | 12005 Detective's Intuition; 12081 Timely Intervention |
| `after_engagement` | 4 | 12007 Trish Scarborough; 12009 Black Chamber Operative; 12074 Hunter's Instinct |
| `after_evade` | 3 | 12008 Covert Ops; 12009 Black Chamber Operative; 12179b Elokoss |
| `after_damage_dealt` | 1 | 12003 In Harm's Way |
| `after_clue` | 6 | 12118 Science Hall; 12119 Warren Observatory; 12125 Unspeakable Truths |
| `after_phase` | 4 | 12099 The Nameless Lurker; 12129 Fire!; 12155 Miskatonic University |

## 4. 遭遇管线卡清单（15 §17）

| 分类 | 卡数 | 卡码 · 卡名 |
|---|---:|---|
| Surge 关键词 | 3 | 12126 Forbidden Secrets; 12160 Raising Suspicions; 12163 Aerial Pursuit |
| Peril 关键词 | 2 | 12124 Cosmic Evils; 12195 Torment |
| Hidden 隐私 | 1 | 12179b Elokoss |
| Aloof | 6 | 12099 The Nameless Lurker; 12139 David Renfield; 12143 Abigail Foreman; 12144 Margaret Liu; 12166 Whippoorwill; 12188 Zealot |
| Massive | 2 | 12179 Elokoss; 12179b Elokoss |
| Spawn 指令（已编译） | 1 | 12099 The Nameless Lurker |
| Prey 指令（已编译） | 3 | 12009 Black Chamber Operative; 12114 Servant of Flame; 12164 Rogue Gangster |

## 5. Template vs Script 选型（12 §1.1）

| 选型 | 卡数 | 说明 |
|---|---:|---|
| **Template 全匹配** | 0 | `compiled_abilities` status=full |
| **Template 部分** | 12 | 首句模板 + 条件/检定待 Script |
| **Script 优先** | 113 | 有能力段但未命中 Phase 3 模板 |

### 5.1 Template 全匹配

- —

### 5.2 Script 优先（节选）

- 12001 Daniela Reyes
- 12002 Daniela's Wrench
- 12004 Joe Diamond
- 12005 Detective's Intuition
- 12006 Dead Ends
- 12008 Covert Ops
- 12009 Black Chamber Operative
- 12010 Dexter Drake
- 12013 Isabelle Barnes
- 12014 Isabelle's Twin .45s
- 12016 Bodyguard
- 12017 Endurance
- 12018 Logan Hastings
- 12019 M1911
- 12027 Bodyguard
- 12028 Sledgehammer
- 12029 Winchester Model 12
- 12030 Dorothy Simmons
- 12033 Local Map
- 12035 Sharp Rhetoric

## 6. 卡面驱动 open questions（新增线索）

| ID | 来源卡 | 说明 |
|---|---|---|
| OQ-ADB-01 | 12099 The Nameless Lurker | Farthest empty spawn — blocked path 见 OQ-09-04 |
| OQ-ADB-02 | 12124 Cosmic Evils | Peril + 动态 surge 赋予 — evaluate 时机 |
| OQ-ADB-03 | 12126 Forbidden Secrets | 无 clue 时 gains surge — revelation 前/后 |
| OQ-ADB-04 | 12012 The Necronomicon | cannot leave play + threat area — Permanent 混合 |
| OQ-ADB-05 | 12179b Elokoss | Hidden enemy + spawn 分支 — ENC-22/23 已测 |
