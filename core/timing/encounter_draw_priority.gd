class_name EncounterDrawPriority
extends RefCounted

## ENCOUNTER_CARD_DRAWN · FrameworkPriority（15 §4.0.5.2 / §3）
## Would / When / After 钉抽取步骤（G1）：Would 在 pop 前 zone=DECK；When 95 默认 zone=LIMBO。
## 抽取步骤 After = G1 结束、显现/G4 前（与 When 窗紧邻；TimingCatalog 待 emit）。
## AFTER_CARD 75 = after_encounter_card_resolved（该牌结算完毕），不是「抽取后」。
## 100 险境属卡牌结算（先于 When）；90 显现是抽取步骤之后的后续步骤。

const PERIL_REGISTER: int = 100
const PLAYER_WHEN_DRAW: int = 95
const REVELATION: int = 90
const G4_TYPE_RESOLVE: int = 80
const AFTER_CARD: int = 75
const SURGE_KEYWORD: int = 70
