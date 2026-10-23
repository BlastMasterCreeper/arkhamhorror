class_name MarkerSlot
extends RefCounted

var kind: AhcEnums.MarkerKind = AhcEnums.MarkerKind.RESOURCE
var bearer_kind: AhcEnums.BearerKind = AhcEnums.BearerKind.INVESTIGATOR
var bearer_id: StringName = &""


static func pool(kind: AhcEnums.MarkerKind) -> MarkerSlot:
	var s := MarkerSlot.new()
	s.kind = kind
	s.bearer_kind = AhcEnums.BearerKind.GLOBAL
	return s


## 桌面标记的无穷供给池端点（按种类归到 POOL_* / DOOM）。
static func supply(kind: AhcEnums.MarkerKind) -> MarkerSlot:
	return pool(TokenPool.supply_kind(kind))


static func investigator(inv_id: StringName, kind: AhcEnums.MarkerKind) -> MarkerSlot:
	var s := MarkerSlot.new()
	s.kind = kind
	s.bearer_kind = AhcEnums.BearerKind.INVESTIGATOR
	s.bearer_id = inv_id
	return s


static func card(card_id: StringName, kind: AhcEnums.MarkerKind) -> MarkerSlot:
	var s := MarkerSlot.new()
	s.kind = kind
	s.bearer_kind = AhcEnums.BearerKind.CARD
	s.bearer_id = card_id
	return s


static func location(location_id: StringName, kind: AhcEnums.MarkerKind) -> MarkerSlot:
	var s := MarkerSlot.new()
	s.kind = kind
	s.bearer_kind = AhcEnums.BearerKind.LOCATION
	s.bearer_id = location_id
	return s


## 当前密谋上的毁灭计数（Domain：`doom_on_agenda`）。
static func agenda_doom() -> MarkerSlot:
	var s := MarkerSlot.new()
	s.kind = AhcEnums.MarkerKind.DOOM
	s.bearer_kind = AhcEnums.BearerKind.AGENDA
	return s
