class_name EncounterDrawPriority
extends RefCounted

## 遭遇抽 · ENCOUNTER_CARD_DRAWN 队列（15 §4.0.5.2）。
## Would = pop 前（DECK · 不可见）。When 打开后按本表 dequeue：
##   对抽取者揭示 → Hidden 检测/公开揭示 → 险境 → 玩家 When/Fast → 显现 → G4 → AFTER。
## 无 Hidden 时公开揭示后，其他玩家可在 95 窗发起取消显现等。

## 向抽取者自动揭示（最高）。必须先于险境与公开。
const REVEAL_TO_DRAWER: int = 110
## Hidden 检测：无 Hidden → 向全体公开；有 Hidden → 保持仅抽取者可知。
const REVEAL_PUBLIC: int = 108
const PERIL_REGISTER: int = 100
const PLAYER_WHEN_DRAW: int = 95
const REVELATION: int = 90
const G4_TYPE_RESOLVE: int = 80
const AFTER_CARD: int = 75
## 涌动不再进本队列；消费槽见 KeywordProfileTable.SLOT_AFTER_DRAWN_CARD → seq.keyword.surge。

## 兼容旧名：整段「揭示档」取顶格（对抽取者揭示）。
const REVEAL: int = REVEAL_TO_DRAWER
