class_name EnemyState
extends RefCounted

var id: StringName = &""
var location_tag: StringName = &""
var fight: int = 0
var evade: int = 0
var health: int = 1
var damage: int = 0
var doom: int = 0
var attack_damage: int = 1
var attack_horror: int = 0
var exhausted: bool = false
var aloof: bool = false
var massive: bool = false
var engaged_with: StringName = &""
## 效果施加：暂不参与自动交战（防止脱离→再交战死循环）。
var auto_engage_suppressed: bool = false


func is_engaged_with(inv_id: StringName) -> bool:
	return engaged_with == inv_id


func is_at_location(location_tag: StringName) -> bool:
	return location_tag != &"" and self.location_tag == location_tag
