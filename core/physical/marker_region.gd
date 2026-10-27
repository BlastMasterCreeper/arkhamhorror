class_name MarkerRegion
extends RefCounted

## 独立标记区：仅 counts map。卡上标记在 PhysicalCard.markers，不经本类。

var id: StringName = &""
## MarkerKey → int（0 省略）
var counts: Dictionary = {}


func is_empty() -> bool:
	return counts.is_empty()


func get_count(key: StringName) -> int:
	return int(counts.get(key, 0))


func set_count(key: StringName, amount: int) -> void:
	if amount <= 0:
		counts.erase(key)
	else:
		counts[key] = amount
