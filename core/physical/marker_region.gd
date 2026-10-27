class_name MarkerRegion
extends RefCounted

## 独立标记区：仅 counts map。卡上标记在 PhysicalCard.markers，不经本类。
## `infinite`：无穷供给（如桌面 token supply）；取用不扣库存，放入不累加。

var id: StringName = &""
var infinite: bool = false
## MarkerKey → int（0 省略）；infinite 区不维护有意义库存
var counts: Dictionary = {}


func is_empty() -> bool:
	if infinite:
		return true
	return counts.is_empty()


func get_count(key: StringName) -> int:
	if infinite:
		return 0
	return int(counts.get(key, 0))


func set_count(key: StringName, amount: int) -> void:
	if infinite:
		return
	if amount <= 0:
		counts.erase(key)
	else:
		counts[key] = amount
