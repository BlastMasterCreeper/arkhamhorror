class_name ScenarioSystem
extends RefCounted

var _state: GameStateStore
var _log: GameLog
var _draw_encounter: DrawEncounterService = null
var _mythos: MythosService = null
var _game_ctx: GameContext = null


func _init(state: GameStateStore, log: GameLog) -> void:
	_state = state
	_log = log


func bind_context(ctx: GameContext) -> void:
	_game_ctx = ctx
	if ctx != null:
		_draw_encounter = ctx.draw_encounter
		_mythos = ctx.mythos


func place_mythos_doom() -> Dictionary:
	if _game_ctx != null and _mythos != null:
		return _mythos.place_doom(_game_ctx)
	return {}


func check_agenda_doom_threshold() -> Dictionary:
	if _game_ctx != null and _mythos != null:
		return _mythos.check_doom_threshold(_game_ctx)
	return {}


func resolve_encounter_draw(drawer: StringName) -> void:
	_log.log(AhcEnums.LogCategory.SCENARIO, "encounter_draw", {"drawer": drawer})
	if _game_ctx != null and _draw_encounter != null:
		_draw_encounter.draw_one(_game_ctx, drawer)
