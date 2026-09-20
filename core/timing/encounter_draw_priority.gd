class_name EncounterDrawPriority
extends RefCounted

## ENCOUNTER_CARD_DRAWN · FrameworkPriority（15 §4.0.5.2 / §3.1）
## Would（G1 pop 前，zone=DECK）与 When（95，默认 zone=LIMBO）对齐同一 TC。
## 步骤差 = G1 发起 impact；100 险境是更高档剩余 impact；90 显现是 When 之后的剩余 impact。

const PERIL_REGISTER: int = 100
const PLAYER_WHEN_DRAW: int = 95
const REVELATION: int = 90
const G4_TYPE_RESOLVE: int = 80
const AFTER_CARD: int = 75
const SURGE_KEYWORD: int = 70
