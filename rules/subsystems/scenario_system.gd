class_name ScenarioSystem
extends RefCounted

var _state: GameStateStore
var _log: GameLog


func _init(state: GameStateStore, log: GameLog) -> void:
	_state = state
	_log = log


func resolve_encounter_draw(drawer: StringName) -> void:
	_log.log(AhcEnums.LogCategory.SCENARIO, "encounter_draw", {"drawer": drawer})
