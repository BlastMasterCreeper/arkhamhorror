class_name CardInstance
extends RefCounted

var id: EntityId
var owner_id: StringName = &""
var controller_id: StringName = &""
var zone: AhcEnums.Zone = AhcEnums.Zone.DECK
var zone_index: int = 0
var face: AhcEnums.CardFace = AhcEnums.CardFace.A
var exhausted: bool = false
var tokens: TokenBag = TokenBag.new()
var attachments: Array[EntityId] = []
var attached_to: EntityId = null
var lasting_effect_ids: Array[StringName] = []
var is_hidden: bool = false  ## 隐私（Hidden）关键词 · E4 秘密入手后为 true；expose 后 false
var face_visibility: CardFaceVisibility = CardFaceVisibility.new()
var skill_icons: Dictionary = {}
var max_committed_per_test: int = -1
## 印刷文本框视为空白（Grimoire Blank）；印刷能力不发起。
var text_box_blank: bool = false
## 隐式符号能力（OQ-04-07）；印刷条由 ScenarioReferenceBinder 装载。
var symbol_abilities: Array = []


func face_known_to(observer: StringName) -> bool:
	return face_visibility.face_known_to(self, observer)


## 当前可发起的符号能力（空白时跳过 printed）。
func active_symbol_ability(kind: AhcEnums.ChaosTokenKind) -> ChaosSymbolAbility:
	for raw in symbol_abilities:
		var ab: ChaosSymbolAbility = raw as ChaosSymbolAbility
		if ab == null or ab.symbol_kind != kind:
			continue
		if ab.printed and text_box_blank:
			continue
		return ab
	return null
