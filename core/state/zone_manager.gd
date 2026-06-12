class_name ZoneManager
extends RefCounted

var _registry: EntityRegistry


func _init(registry: EntityRegistry) -> void:
	_registry = registry


func move_card(instance_id: StringName, new_zone: AhcEnums.Zone, zone_index: int = -1) -> bool:
	var card := _registry.get_card(instance_id)
	if card == null:
		return false
	card.zone = new_zone
	if zone_index >= 0:
		card.zone_index = zone_index
	return true


func add_to_hand(inv_id: StringName, instance_id: StringName) -> void:
	var inv := _registry.get_investigator(inv_id)
	if inv == null:
		return
	move_card(instance_id, AhcEnums.Zone.HAND, inv.hand.size())
	inv.hand.append(instance_id)


func remove_from_hand(inv_id: StringName, instance_id: StringName) -> void:
	var inv := _registry.get_investigator(inv_id)
	if inv == null:
		return
	inv.hand.erase(instance_id)
