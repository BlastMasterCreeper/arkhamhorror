# Pack 分析：`core_2026`

源文件：`data/arkhamdb/pack/core/core_2026.json`
卡条目数（含 quantity 展开前）：104

### type_code 分布

| 项 | 数量 |
|---|---:|
| `asset` | 87 |
| `?` | 77 |
| `event` | 31 |
| `skill` | 12 |
| `investigator` | 5 |
| `treachery` | 5 |
| `enemy` | 2 |

### subtype_code 分布

| 项 | 数量 |
|---|---:|
| `weakness` | 5 |
| `basicweakness` | 5 |

### faction_code 分布

| 项 | 数量 |
|---|---:|
| `neutral` | 30 |
| `guardian` | 24 |
| `mystic` | 24 |
| `survivor` | 24 |
| `rogue` | 22 |
| `seeker` | 18 |

### 布尔字段

| 项 | 数量 |
|---|---:|
| `is_unique` | 14 |
| `double_sided` | 5 |

### slot（资产槽位）

| 项 | 数量 |
|---|---:|
| `Hand` | 9 |
| `Ally` | 7 |
| `Arcane` | 4 |
| `Hand x2` | 3 |
| `Body` | 2 |
| `Accessory` | 2 |
| `Head` | 2 |

### 卡面文本模式（能力/关键词线索）

| 项 | 数量 |
|---|---:|
| `action` | 23 |
| `reaction` | 21 |
| `fight_bold` | 14 |
| `fast` | 12 |
| `revelation_bold` | 8 |
| `forced_bold` | 8 |
| `investigate_bold` | 8 |
| `cannot` | 6 |
| `elder_sign` | 5 |
| `limit_once` | 4 |
| `limit_per_round` | 4 |
| `evade_bold` | 3 |
| `hunter_text` | 2 |
| `parley_bold` | 1 |
| `aloof_text` | 1 |

### 样例卡（每类最多 5 张）

- **action**：12002 Daniela's Wrench, 12012 The Necronomicon, 12014 Isabelle's Twin .45s, 12019 M1911, 12020 ?
- **aloof_text**：12099 The Nameless Lurker
- **cannot**：12009 Black Chamber Operative, 12012 The Necronomicon, 12059 Cosmic Flame, 12062 Second Sight, 12071 Cosmic Flame
- **elder_sign**：12001 Daniela Reyes, 12004 Joe Diamond, 12007 Trish Scarborough, 12010 Dexter Drake, 12013 Isabelle Barnes
- **evade_bold**：12037 Through the Cracks, 12041 Through the Cracks, 12079 "Shove off!"
- **fast**：12002 Daniela's Wrench, 12013 Isabelle Barnes, 12017 Endurance, 12035 Sharp Rhetoric, 12040 Mysterious Grimoire
- **fight_bold**：12001 Daniela Reyes, 12002 Daniela's Wrench, 12014 Isabelle's Twin .45s, 12019 M1911, 12020 ?
- **forced_bold**：12003 In Harm's Way, 12006 Dead Ends, 12009 Black Chamber Operative, 12064 ?, 12099 The Nameless Lurker
- **hunter_text**：12009 Black Chamber Operative, 12074 Hunter's Instinct
- **investigate_bold**：12031 ?, 12033 Local Map, 12049 ?, 12050 ?, 12062 Second Sight
- **limit_once**：12001 Daniela Reyes, 12004 Joe Diamond, 12010 Dexter Drake, 12013 Isabelle Barnes
- **limit_per_round**：12001 Daniela Reyes, 12004 Joe Diamond, 12010 Dexter Drake, 12013 Isabelle Barnes
- **parley_bold**：12051 Paint the Town Red
- **reaction**：12001 Daniela Reyes, 12004 Joe Diamond, 12005 Detective's Intuition, 12008 Covert Ops, 12010 Dexter Drake
- **revelation_bold**：12003 In Harm's Way, 12012 The Necronomicon, 12015 Breaking Point, 12098 The Gold Bug, 12101 ?
