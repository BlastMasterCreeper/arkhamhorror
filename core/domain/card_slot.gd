class_name CardSlot
extends RefCounted

var pile: AhcEnums.PileKind = AhcEnums.PileKind.INV_DECK
var owner_id: StringName = &""
var insert: AhcEnums.InsertMode = AhcEnums.InsertMode.BOTTOM


static func deck_top(inv_id: StringName) -> CardSlot:
	var s := CardSlot.new()
	s.pile = AhcEnums.PileKind.INV_DECK
	s.owner_id = inv_id
	s.insert = AhcEnums.InsertMode.TOP
	return s


static func hand_bottom(inv_id: StringName) -> CardSlot:
	var s := CardSlot.new()
	s.pile = AhcEnums.PileKind.INV_HAND
	s.owner_id = inv_id
	s.insert = AhcEnums.InsertMode.BOTTOM
	return s


static func discard_top(inv_id: StringName) -> CardSlot:
	var s := CardSlot.new()
	s.pile = AhcEnums.PileKind.INV_DISCARD
	s.owner_id = inv_id
	s.insert = AhcEnums.InsertMode.TOP
	return s


static func encounter_discard_top() -> CardSlot:
	var s := CardSlot.new()
	s.pile = AhcEnums.PileKind.INV_DISCARD
	s.owner_id = &"encounter"
	s.insert = AhcEnums.InsertMode.TOP
	return s


static func victory_display() -> CardSlot:
	var s := CardSlot.new()
	s.owner_id = &"victory_display"
	return s
