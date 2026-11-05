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
## 结算个人 XP 调整队列（正=额外获得；负=减少获得）；Count 后清空。
## 例：06160 +1；03308 Obol +2；12006 Dead Ends −2；Hospital Debts −2。
var pending_resolution_xp_bonuses: Array = []


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


## Bearer / 剧情奖励入组：忽略 options，且不计 deck size（Grimoire Bearer）。
func add_bearer_card(card: DeckCardView) -> void:
	if card == null:
		return
	card.ignore_deckbuilding = true
	deck.append(card)


func counted_deck_size() -> int:
	var n := 0
	for c in deck:
		if c.counts_toward_deck_size():
			n += 1
	return n


## 登记结算时个人 XP 调整（可正可负；或用 queue_resolution_xp_penalty）。
func queue_resolution_xp_bonus(amount: int, source: StringName = &"") -> void:
	pending_resolution_xp_bonuses.append(ExperienceCount.delta(amount, source))


## 「earn N fewer experience」→ 排队 −N。
func queue_resolution_xp_penalty(fewer: int, source: StringName = &"") -> void:
	pending_resolution_xp_bonuses.append(ExperienceCount.penalty(fewer, source))


func take_resolution_xp_bonuses() -> Array:
	var out: Array = pending_resolution_xp_bonuses.duplicate()
	pending_resolution_xp_bonuses.clear()
	return out
