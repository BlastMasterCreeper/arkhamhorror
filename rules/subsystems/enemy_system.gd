class_name EnemySystem
extends RefCounted

var _state: GameStateStore
var _log: GameLog


func _init(state: GameStateStore, log: GameLog) -> void:
	_state = state
	_log = log


func hunter_patrol_move() -> void:
	_log.log(AhcEnums.LogCategory.SCENARIO, "hunter_patrol_move", {})


func resolve_phase_attacks_for(investigator_id: StringName) -> void:
	_log.log(AhcEnums.LogCategory.SCENARIO, "enemy_phase_attacks", {"inv": investigator_id})
