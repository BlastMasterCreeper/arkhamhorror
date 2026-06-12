class_name CommittedCard
extends RefCounted

var card_id: StringName = &""
var from_investigator: StringName = &""
var icon_bonus: int = 1


static func create(card_id: StringName, from_investigator: StringName, icon_bonus: int = 1) -> CommittedCard:
	var c := CommittedCard.new()
	c.card_id = card_id
	c.from_investigator = from_investigator
	c.icon_bonus = icon_bonus
	return c
