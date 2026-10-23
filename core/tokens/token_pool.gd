class_name TokenPool
extends RefCounted

## 无穷供给池（已裁决）：桌面标记（damage / horror / clue / resource / doom）
## 取自本池、回池均不维护有限库存。字段保留仅为兼容旧快照/测试读数，恒为 0。

var damage_available: int = 0
var horror_available: int = 0
var clue_available: int = 0
var resource_available: int = 0


static func is_table_token_kind(kind: AhcEnums.MarkerKind) -> bool:
	match kind:
		AhcEnums.MarkerKind.DAMAGE, AhcEnums.MarkerKind.POOL_DAMAGE:
			return true
		AhcEnums.MarkerKind.HORROR, AhcEnums.MarkerKind.HORROR_TAKEN, AhcEnums.MarkerKind.POOL_HORROR:
			return true
		AhcEnums.MarkerKind.CLUE, AhcEnums.MarkerKind.POOL_CLUE:
			return true
		AhcEnums.MarkerKind.RESOURCE, AhcEnums.MarkerKind.POOL_RESOURCE:
			return true
		AhcEnums.MarkerKind.DOOM:
			return true
	return false


## 无穷池：取用永不因库存失败。
func can_take(kind: AhcEnums.MarkerKind, amount: int) -> bool:
	return amount > 0 and is_table_token_kind(kind)


func take(kind: AhcEnums.MarkerKind, amount: int) -> bool:
	return can_take(kind, amount)


## 回池：湮入无穷供给，不累加计数。
func give(_kind: AhcEnums.MarkerKind, _amount: int) -> void:
	pass
