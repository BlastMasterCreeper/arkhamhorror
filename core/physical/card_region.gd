class_name CardRegion
extends RefCounted

## 通用卡区。形态仅 deck（有序）| flat（无规则序操作）。

enum Shape { DECK, FLAT }

var id: StringName = &""
var shape: int = Shape.FLAT
## 可选属主玩家；&"" = 无属主（桌面公共区等）
var owner_player_id: StringName = &""
## 卡 id 列表。deck：index 0 = 顶。flat：无规则序，可与卡上 display_order 配合。
var card_ids: Array[StringName] = []


func is_empty() -> bool:
	return card_ids.is_empty()


func size() -> int:
	return card_ids.size()


func contains(card_id: StringName) -> bool:
	return card_ids.has(card_id)
