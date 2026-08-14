class_name ScenarioSetupFlow
extends RefCounted

## Setup 14 · When the game begins · 10 §2.1。

const WHEN_GAME_BEGINS: StringName = &"when_the_game_begins"


static func run_game_begins(game_ctx: GameContext) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	if game_ctx.state.setup_game_begins_resolved:
		return {"ok": true, "skipped": true, "reason": &"already_resolved"}
	var resolved := _resolve_deferred_revelations(game_ctx)
	if game_ctx.timing != null:
		game_ctx.timing.emit_timing(WHEN_GAME_BEGINS, {"resolved_cards": resolved})
	game_ctx.state.setup_game_begins_resolved = true
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"setup:game_begins",
			{"deferred_revelations": resolved}
		)
	return {"ok": true, "deferred_revelations": resolved}


static func _resolve_deferred_revelations(game_ctx: GameContext) -> int:
	var queue := game_ctx.state.deferred_setup_revelations.duplicate()
	game_ctx.state.deferred_setup_revelations.clear()
	var count := 0
	for card_id in queue:
		var card := game_ctx.state.registry.get_card(card_id)
		if card == null:
			continue
		if game_ctx.sequence_catalog != null:
			game_ctx.sequence_catalog.run(
				game_ctx,
				&"seq.draw.encounter.resolve_bound",
				{"drawer_id": &"setup_14", "card_id": card_id}
			)
			count += 1
		elif game_ctx.draw_encounter != null:
			DrawEncounterFlow.resolve_bound(game_ctx, &"setup_14", card_id)
			count += 1
	return count
