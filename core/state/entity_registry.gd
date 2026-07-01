class_name EntityRegistry
extends RefCounted

var _cards: Dictionary = {}  # instance_id -> CardInstance
var _investigators: Dictionary = {}  # id -> InvestigatorState
var _locations: Dictionary = {}  # id -> LocationState
var _enemies: Dictionary = {}  # id -> EnemyState
var _next_seq: int = 0


func register_investigator(state: InvestigatorState) -> void:
	_investigators[state.id] = state


func get_investigator(inv_id: StringName) -> InvestigatorState:
	return _investigators.get(inv_id) as InvestigatorState


func all_investigator_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for k in _investigators.keys():
		ids.append(k)
	return ids


func register_card(card: CardInstance) -> void:
	_cards[card.id.instance_id] = card


func get_card(instance_id: StringName) -> CardInstance:
	return _cards.get(instance_id) as CardInstance


func all_card_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for k in _cards.keys():
		ids.append(k)
	return ids


func allocate_instance_id(prefix: StringName = &"ent") -> StringName:
	_next_seq += 1
	return StringName("%s_%d" % [prefix, _next_seq])


func register_location(state: LocationState) -> void:
	_locations[state.id] = state


func get_location(location_id: StringName) -> LocationState:
	return _locations.get(location_id) as LocationState


func register_enemy(state: EnemyState) -> void:
	_enemies[state.id] = state


func get_enemy(enemy_id: StringName) -> EnemyState:
	return _enemies.get(enemy_id) as EnemyState


func unregister_enemy(enemy_id: StringName) -> void:
	_enemies.erase(enemy_id)


func all_enemy_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for k in _enemies.keys():
		ids.append(k)
	return ids

