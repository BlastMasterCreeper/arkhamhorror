class_name AgendaDoomPolicy
extends RefCounted

## 密谋 doom 阈值检测与清场 · Mythos 1.3 / 卡面 explicit advance（OQ-ADB-08）。


static func doom_in_play(state: GameStateStore) -> int:
	if state == null:
		return 0
	return state.doom_in_play()


static func meets_threshold(state: GameStateStore) -> bool:
	if state == null:
		return false
	return doom_in_play(state) >= state.agenda_threshold


static func clear_all_doom(game_ctx: GameContext) -> int:
	if game_ctx == null or game_ctx.state == null:
		return 0
	var cleared := doom_in_play(game_ctx.state)
	game_ctx.state.doom_on_agenda = 0
	for enemy_id in game_ctx.state.registry.all_enemy_ids():
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy != null and enemy.doom > 0:
			enemy.doom = 0
	if game_ctx.log != null and cleared > 0:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"agenda:clear_all_doom",
			{"cleared": cleared}
		)
	return cleared


static func try_nest_advance_if_needed(
	game_ctx: GameContext,
	source: StringName,
	explicit: bool = false
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"advanced": false, "reason": &"invalid_context"}
	if not meets_threshold(game_ctx.state):
		return {"advanced": false, "reason": &"below_threshold"}
	if game_ctx.sequence_catalog == null:
		return {"advanced": false, "reason": &"no_catalog"}
	return game_ctx.sequence_catalog.nest(
		game_ctx,
		&"seq.agenda.advance",
		{"source": source, "explicit": explicit}
	)
