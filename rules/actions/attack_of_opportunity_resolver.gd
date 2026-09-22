class_name AttackOfOpportunityResolver
extends RefCounted

var _state: GameStateStore
var _combat: CombatResolver


func _init(state: GameStateStore, combat: CombatResolver) -> void:
	_state = state
	_combat = combat


static func provokes(action_type: AhcEnums.ActionType) -> bool:
	return provokes_for_types([action_type])


## 一次行动可带多种行动类型；任一豁免类型（Fight/Evade/Parley/Resign）则不借机。
static func provokes_for_types(action_types: Array) -> bool:
	if action_types.is_empty():
		return true
	for raw in action_types:
		var action_type: AhcEnums.ActionType = int(raw) as AhcEnums.ActionType
		match action_type:
			AhcEnums.ActionType.FIGHT, \
			AhcEnums.ActionType.EVADE, \
			AhcEnums.ActionType.PARLEY, \
			AhcEnums.ActionType.RESIGN:
				return false
	return true


func resolve(investigator_id: StringName, action_type: AhcEnums.ActionType) -> Dictionary:
	return resolve_for_types(investigator_id, [action_type])


func resolve_for_types(investigator_id: StringName, action_types: Array) -> Dictionary:
	if not provokes_for_types(action_types):
		return {"ok": true, "attacks": 0}
	var enemies := get_ready_engaged_enemies(investigator_id)
	var count := 0
	for enemy_id in enemies:
		var enemy := _state.registry.get_enemy(enemy_id)
		if enemy == null:
			continue
		var attack := EnemyAttack.opportunity(
			enemy_id, investigator_id, enemy.attack_damage, enemy.attack_horror
		)
		_combat.perform_attack(attack)
		count += 1
	return {"ok": true, "attacks": count}


func get_ready_engaged_enemies(investigator_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for enemy_id in _state.registry.all_enemy_ids():
		var enemy := _state.registry.get_enemy(enemy_id)
		if enemy == null:
			continue
		if enemy.is_engaged_with(investigator_id) and not enemy.exhausted:
			out.append(enemy_id)
	return out
