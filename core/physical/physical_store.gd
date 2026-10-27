class_name PhysicalStore
extends RefCounted

## 物理层桌面快照：玩家 · 卡 · 卡区 · 独立标记区。
## 不含框架语义（当前密谋名、交战等）；信息层读此快照再贴标签。
##
## 实体 id（卡 / 玩家）由本 store 单调分配，与 definition_id（牌面编号）分离。
## 销毁只从字典抹掉，**不复用**已发出的 id。

var players: Dictionary = {}  # StringName -> PhysicalPlayer
var cards: Dictionary = {}  # StringName -> PhysicalCard
var card_regions: Dictionary = {}  # StringName -> CardRegion
var marker_regions: Dictionary = {}  # StringName -> MarkerRegion

var _next_entity_serial: int = 0
var _next_region_serial: int = 0


## 运行时实体 id（卡、玩家）。≠ definition_id。
func alloc_entity_id(kind_prefix: StringName = &"e") -> StringName:
	_next_entity_serial += 1
	return StringName("%s_%d" % [String(kind_prefix), _next_entity_serial])


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
