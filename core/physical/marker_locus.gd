class_name MarkerLocus
extends RefCounted

## 标记所属：独立标记区，或某张卡上。

enum Kind { REGION, CARD }

var kind: int = Kind.REGION
var id: StringName = &""


static func region(region_id: StringName) -> MarkerLocus:
	var loc := MarkerLocus.new()
	loc.kind = Kind.REGION
	loc.id = region_id
	return loc


static func card(card_id: StringName) -> MarkerLocus:
	var loc := MarkerLocus.new()
	loc.kind = Kind.CARD
	loc.id = card_id
	return loc
