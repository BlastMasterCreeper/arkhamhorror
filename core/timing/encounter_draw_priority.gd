class_name EncounterDrawPriority
extends RefCounted

## 遭遇抽 · ENCOUNTER_CARD_DRAWN 队列（15 §4.0.5.2）。
## Would = pop 前（DECK · 不可见）。When 打开后按本表 dequeue：
##   揭示（最高·自动）→ 险境 → 玩家 When/Fast → 显现 → G4 → AFTER。
## 险境只需低于揭示、高于玩家反应与显现；WHEN 开窗瞬间是否可见无影响（揭示先跑）。

## 向抽取者/全体自动揭示（隐私：不公开）。必须先于险境。
const REVEAL: int = 110
const PERIL_REGISTER: int = 100
const PLAYER_WHEN_DRAW: int = 95
const REVELATION: int = 90
const G4_TYPE_RESOLVE: int = 80
const AFTER_CARD: int = 75
## 涌动不再进本队列；消费槽见 KeywordProfileTable.SLOT_AFTER_DRAWN_CARD → seq.keyword.surge。
