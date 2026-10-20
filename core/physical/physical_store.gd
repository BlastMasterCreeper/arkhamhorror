class_name PhysicalStore
extends RefCounted

## 物理层桌面快照：玩家 · 卡 · 卡区 · 独立标记区。
## 不含框架语义（当前密谋名、交战等）；信息层读此快照再贴标签。

var players: Dictionary = {}  # StringName -> PhysicalPlayer
var cards: Dictionary = {}  # StringName -> PhysicalCard
var card_regions: Dictionary = {}  # StringName -> CardRegion
var marker_regions: Dictionary = {}  # StringName -> MarkerRegion

var _next_region_serial: int = 0


func alloc_region_id(prefix: StringName) -> StringName:
	_next_region_serial += 1
	return StringName("%s_%d" % [String(prefix), _next_region_serial])


func get_player(player_id: StringName) -> PhysicalPlayer:
	return players.get(player_id) as PhysicalPlayer


func get_card(card_id: StringName) -> PhysicalCard:
	return cards.get(card_id) as PhysicalCard


func get_card_region(region_id: StringName) -> CardRegion:
	return card_regions.get(region_id) as CardRegion


func get_marker_region(region_id: StringName) -> MarkerRegion:
	return marker_regions.get(region_id) as MarkerRegion
