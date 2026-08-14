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


func setup_act_agenda_decks(
	act_definition_ids: Array,
	agenda_definition_ids: Array
) -> Dictionary:
	if _game_ctx == null:
		return {"ok": false}
	return ScenarioDeckSetup.install_decks(_game_ctx, act_definition_ids, agenda_definition_ids)


func run_setup_agenda_deck() -> Dictionary:
	if _game_ctx == null or _state == null:
		return {"ok": false}
	if _state.current_agenda_card_id != &"":
		return {"ok": true, "skipped": true, "reason": &"already_installed"}
	var resolved := ScenarioSetupCatalog.resolve(_game_ctx.config)
	if _game_ctx.config != null and _game_ctx.config.setup_scenario_id != &"":
		ScenarioSetupCatalog.prepare_definitions(_game_ctx.config.setup_scenario_id)
	var agenda_ids: Array = resolved.get("agenda", [])
	if agenda_ids.is_empty():
		return {"ok": true, "skipped": true, "reason": &"no_agenda_config"}
	var result := ScenarioDeckSetup.install_decks(_game_ctx, [], agenda_ids)
	if _log != null and result.get("ok", false):
		_log.log(
			AhcEnums.LogCategory.SCENARIO,
			"setup:agenda_deck",
			{
				"current": result.get("current_agenda", &""),
				"remaining": result.get("agenda_remaining", 0),
				"threshold": _state.agenda_threshold,
			}
		)
	return result


func run_setup_act_deck() -> Dictionary:
	if _game_ctx == null or _state == null:
		return {"ok": false}
	if _state.current_act_card_id != &"":
		return {"ok": true, "skipped": true, "reason": &"already_installed"}
	var resolved := ScenarioSetupCatalog.resolve(_game_ctx.config)
	if _game_ctx.config != null and _game_ctx.config.setup_scenario_id != &"":
		ScenarioSetupCatalog.prepare_definitions(_game_ctx.config.setup_scenario_id)
	var act_ids: Array = resolved.get("act", [])
	if act_ids.is_empty():
		return {"ok": true, "skipped": true, "reason": &"no_act_config"}
	var result := ScenarioDeckSetup.install_decks(_game_ctx, act_ids, [])
	if _log != null and result.get("ok", false):
		_log.log(
			AhcEnums.LogCategory.SCENARIO,
			"setup:act_deck",
			{
				"current": result.get("current_act", &""),
				"remaining": result.get("act_remaining", 0),
				"clue_threshold": _state.act_clue_threshold,
			}
		)
	return result


func run_setup_scenario_layout() -> Dictionary:
	if _game_ctx == null or _state == null:
		return {"ok": false}
	if _state.scenario_layout_installed:
		return {"ok": true, "skipped": true, "reason": &"already_installed"}
	if _game_ctx.config == null or _game_ctx.config.setup_scenario_id == &"":
		return {"ok": true, "skipped": true, "reason": &"no_scenario_config"}
	ScenarioSetupCatalog.prepare_definitions(_game_ctx.config.setup_scenario_id)
	var layout := ScenarioSetupCatalog.resolve_layout(_game_ctx.config)
	return ScenarioLayoutSetup.install(_game_ctx, layout)


func run_setup_scenario_reference() -> Dictionary:
	if _game_ctx == null or _state == null:
		return {"ok": false}
	if _state.scenario_reference_card_id != &"":
		return {"ok": true, "skipped": true, "reason": &"already_installed"}
	if _game_ctx.config == null or _game_ctx.config.setup_scenario_id == &"":
		return {"ok": true, "skipped": true, "reason": &"no_scenario_config"}
	var layout := ScenarioSetupCatalog.resolve_layout(_game_ctx.config)
	var ref_id: StringName = layout.get("reference_card", &"")
	if ref_id == &"":
		return {"ok": true, "skipped": true, "reason": &"no_reference"}
	ScenarioSetupCatalog.prepare_definitions(_game_ctx.config.setup_scenario_id)
	return ScenarioLayoutSetup.install_reference_card(_game_ctx, ref_id)


func run_setup_game_begins() -> Dictionary:
	if _game_ctx == null or _state == null:
		return {"ok": false}
	if _game_ctx.config == null or _game_ctx.config.setup_scenario_id == &"":
		return {"ok": true, "skipped": true, "reason": &"no_scenario_config"}
	return ScenarioSetupFlow.run_game_begins(_game_ctx)


func place_mythos_doom() -> Dictionary:
	if _game_ctx != null and _mythos != null:
		return _mythos.place_doom(_game_ctx)
	return {}


func check_agenda_doom_threshold() -> Dictionary:
	if _game_ctx != null and _mythos != null:
		return _mythos.check_doom_threshold(_game_ctx)
	return {}


func advance_act(params: Dictionary = {}) -> Dictionary:
	if _game_ctx == null:
		return {"ok": false}
	if _game_ctx.sequence_catalog != null:
		return _game_ctx.sequence_catalog.run(_game_ctx, &"seq.act.advance", params)
	return ActAdvanceFlow.run(_game_ctx, params)


func advance_agenda(params: Dictionary = {}) -> Dictionary:
	if _game_ctx == null:
		return {"ok": false}
	if _game_ctx.sequence_catalog != null:
		return _game_ctx.sequence_catalog.run(_game_ctx, &"seq.agenda.advance", params)
	return AgendaAdvanceFlow.run(_game_ctx, params)


func check_scenario_end() -> int:
	if _state == null:
		return -1
	return _state.scenario_resolution


func resolve_encounter_draw(drawer: StringName) -> void:
	_log.log(AhcEnums.LogCategory.SCENARIO, "encounter_draw", {"drawer": drawer})
	if _game_ctx != null and _draw_encounter != null:
		_draw_encounter.draw_one(_game_ctx, drawer)
