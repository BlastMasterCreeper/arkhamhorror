class_name CampaignInvestigatorRecord
extends RefCounted

## 剧本侧调查员持久状态（购卡窗 / Trauma / XP）。

var investigator_id: StringName = &""
## 调查员定义 id（含 deck_options）。
var definition_id: StringName = &""
var deck: Array[DeckCardView] = []
var unspent_xp: int = 0
var deckbuilding_choices: Dictionary = {}
var physical_trauma: int = 0
var mental_trauma: int = 0
## 本 spend window 内注入的 XP 修饰器（DtRH 等）；幕间开始时可重建。
var xp_modifiers: Array = []
var experience_window_open: bool = false


func profile() -> DeckbuildingProfile:
	var data := CardRegistry.definition_data(definition_id)
	if data.is_empty():
		## 测试可直接把 options 塞进假定义；无注册时空 Profile。
		return DeckbuildingProfile.from_options([], deckbuilding_choices, 30, definition_id)
	return DeckbuildingProfile.from_investigator_definition(data, deckbuilding_choices)


func deck_as_array() -> Array:
	var out: Array = []
	for c in deck:
		out.append(c)
	return out
