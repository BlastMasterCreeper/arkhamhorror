class_name CombatResolver
extends RefCounted

var _state: GameStateStore
var _log: GameLog
var _timing: TimingBus


func _init(state: GameStateStore, log: GameLog, timing: TimingBus = null) -> void:
	_state = state
	_log = log
	_timing = timing


func perform_attack(attack: EnemyAttack) -> void:
	if attack == null:
		return
	var inv := _state.registry.get_investigator(attack.target_investigator)
	if inv == null:
		return
	inv.damage_taken += attack.damage
	inv.horror_taken += attack.horror
	_log.log(
		AhcEnums.LogCategory.DAMAGE,
		"enemy_attack:%s" % attack.kind,
		{
			"enemy": attack.enemy_id,
			"target": attack.target_investigator,
			"damage": attack.damage,
			"horror": attack.horror,
		}
	)
	if _timing:
		_timing.emit_timing(
			&"enemy_attack_completed",
			{"enemy": attack.enemy_id, "target": attack.target_investigator, "kind": attack.kind}
		)
	if attack.exhaust_after:
		var enemy := _state.registry.get_enemy(attack.enemy_id)
		if enemy:
			enemy.exhausted = true
