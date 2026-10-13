class_name ScenarioObjectiveFlow
extends RefCounted

## Act Objective 检测 · 回合末 / 条件满足时推进 Act。


static func check_end_of_round(game_ctx: GameContext) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "advanced": false}
	if game_ctx.state.current_act_card_id == &"":
		return {"ok": true, "advanced": false}
	var card := game_ctx.state.registry.get_card(game_ctx.state.current_act_card_id)
	if card == null:
		return {"ok": false, "advanced": false}
	var objective := CardRegistry.scenario_objective(card.id.definition_id)
	if objective.is_empty():
		return {"ok": true, "advanced": false}
	match objective.get("kind", &""):
		&"may_spend_clues_end_of_round":
			return _try_spend_clues_advance(game_ctx)
		&"all_undefeated_at_location":
			return _try_all_at_location_advance(
				game_ctx, objective.get("location_id", &"")
			)
		&"may_spend_clues_at_location":
			return _try_spend_clues_at_location_advance(game_ctx, objective)
		&"enemy_defeated":
			return _try_enemy_defeated_advance(
				game_ctx, objective.get("definition_id", &"")
			)
		_:
			return {"ok": true, "advanced": false}


static func check_enemy_defeated(game_ctx: GameContext, definition_id: StringName) -> Dictionary:
	return _try_enemy_defeated_advance(game_ctx, definition_id)


static func _try_spend_clues_advance(game_ctx: GameContext) -> Dictionary:
	var required := game_ctx.state.act_clue_threshold
	if required <= 0:
		return {"ok": true, "advanced": false}
	var total := _total_clues(game_ctx)
	if total < required:
		return {"ok": true, "advanced": false}
	return _run_act_advance(game_ctx, &"objective_spend_clues")


static func _try_all_at_location_advance(
	game_ctx: GameContext,
	location_id: StringName
) -> Dictionary:
	if location_id == &"":
		return {"ok": true, "advanced": false}
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null or inv.eliminated or inv.resigned:
			continue
		if inv.location_tag != location_id:
			return {"ok": true, "advanced": false}
	return _run_act_advance(
		game_ctx, &"objective_all_at_location", {"skip_clue_spend": true}
	)


static func _try_spend_clues_at_location_advance(
	game_ctx: GameContext,
	objective: Dictionary
) -> Dictionary:
	var location_id: StringName = objective.get("location_id", &"")
	var required := game_ctx.state.act_clue_threshold
	if required <= 0 or location_id == &"":
		return {"ok": true, "advanced": false}
	var eligible := false
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null or inv.eliminated or inv.resigned:
			continue
		if inv.location_tag == location_id:
			eligible = true
			break
	if not eligible or _total_clues(game_ctx) < required:
		return {"ok": true, "advanced": false}
	return _run_act_advance(game_ctx, &"objective_location_spend_clues")


static func _try_enemy_defeated_advance(
	game_ctx: GameContext,
	definition_id: StringName
) -> Dictionary:
	if definition_id == &"":
		return {"ok": true, "advanced": false}
	if not _enemy_in_victory_display(game_ctx, definition_id):
		return {"ok": true, "advanced": false}
	return _run_act_advance(
		game_ctx, &"objective_enemy_defeated", {"skip_clue_spend": true}
	)


static func _enemy_in_victory_display(
	game_ctx: GameContext,
	definition_id: StringName
) -> bool:
	for card_id in game_ctx.state.victory_display:
		var card := game_ctx.state.registry.get_card(card_id)
		if card != null and card.id.definition_id == definition_id:
			return true
	return false


static func _total_clues(game_ctx: GameContext) -> int:
	var total := 0
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv != null and not inv.eliminated:
			total += inv.clues_on_card
	return total


static func _run_act_advance(
	game_ctx: GameContext,
	source: StringName,
	extra: Dictionary = {}
) -> Dictionary:
	if game_ctx.sequence_catalog == null:
		return {"ok": false, "advanced": false}
	var params := extra.duplicate()
	params["source"] = source
	var result := game_ctx.sequence_catalog.run(game_ctx, &"seq.act.advance", params)
	return {
		"ok": bool(result.get("ok", false)),
		"advanced": bool(result.get("advanced", false)),
		"result": result,
	}
