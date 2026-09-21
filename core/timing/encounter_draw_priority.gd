class_name EncounterDrawPriority
extends RefCounted

## 卡面 draw 转译：Would = 这次抽取 PreImpact（pop 前 zone=DECK）。
## When = 抽取步骤（95 档，默认 zone=LIMBO）。
## AFTER_CARD 75 = 抽取后 = 该次抽取整段结算完毕（after_encounter_card_resolved）。
## 100 险境属卡牌结算（先于 When）；90 显现是 When 之后的结算剩余。

const PERIL_REGISTER: int = 100
const PLAYER_WHEN_DRAW: int = 95
const REVELATION: int = 90
const G4_TYPE_RESOLVE: int = 80
const AFTER_CARD: int = 75
## 涌动不再进本队列；消费槽见 KeywordProfileTable.SLOT_AFTER_DRAWN_CARD → seq.keyword.surge。
