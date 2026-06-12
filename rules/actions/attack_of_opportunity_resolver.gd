class_name AttackOfOpportunityResolver
extends RefCounted

var _state: GameStateStore
var _combat: CombatResolver


func _init(state: GameStateStore, combat: CombatResolver) -> void:
	_state = state
	_combat = combat


static func provokes(action_type: AhcEnums.ActionType) -> bool:
	match action_type:
		AhcEnums.ActionType.FIGHT, AhcEnums.ActionType.EVADE, AhcEnums.ActionType.RESIGN:
			return false
		_:
			return true


func resolve(investigator_id: StringName, action_type: AhcEnums.ActionType) -> Dictionary:
	if not provokes(action_type):
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
