class_name EncounterDrawPriority
extends RefCounted

## ENCOUNTER_CARD_DRAWN · FrameworkPriority（15 §4.0.5.2 / §3）
## Would / When 钉抽取步骤（G1）：Would 在 pop 前 zone=DECK；When 95 默认 zone=LIMBO。
## AFTER_CARD 75 = 抽取后 = 该次抽取整段结算完毕（after_encounter_card_resolved）。
## 不在 G1 结束处另开 After。100 险境属卡牌结算（先于 When）；90 显现是 When 之后的结算剩余。

const PERIL_REGISTER: int = 100
const PLAYER_WHEN_DRAW: int = 95
const REVELATION: int = 90
const G4_TYPE_RESOLVE: int = 80
const AFTER_CARD: int = 75
const SURGE_KEYWORD: int = 70
