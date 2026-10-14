class_name MarkerSlot
extends RefCounted

var kind: AhcEnums.MarkerKind = AhcEnums.MarkerKind.RESOURCE
var bearer_kind: AhcEnums.BearerKind = AhcEnums.BearerKind.INVESTIGATOR
var bearer_id: StringName = &""
## USES 专用：ammo / charges / supplies / …
var sub_key: StringName = &""


static func pool(kind: AhcEnums.MarkerKind) -> MarkerSlot:
	var s := MarkerSlot.new()
	s.kind = kind
	s.bearer_kind = AhcEnums.BearerKind.GLOBAL
	return s


static func investigator(inv_id: StringName, kind: AhcEnums.MarkerKind) -> MarkerSlot:
	var s := MarkerSlot.new()
	s.kind = kind
	s.bearer_kind = AhcEnums.BearerKind.INVESTIGATOR
	s.bearer_id = inv_id
	return s


static func card(
	card_id: StringName,
	kind: AhcEnums.MarkerKind,
	sub_key: StringName = &""
) -> MarkerSlot:
	var s := MarkerSlot.new()
	s.kind = kind
	s.bearer_kind = AhcEnums.BearerKind.CARD
	s.bearer_id = card_id
	s.sub_key = sub_key
	return s
