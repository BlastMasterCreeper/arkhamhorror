class_name MythosFlow
extends RefCounted

## Mythos 1.2–1.3 命名流程 · 框架步与 ScenarioSystem 共用。


static func place_doom(game_ctx: GameContext) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "reason": &"invalid_context"}
	game_ctx.state.doom_on_agenda += 1
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"mythos:place_doom",
			{
				"doom_on_agenda": game_ctx.state.doom_on_agenda,
				"doom_in_play": AgendaDoomPolicy.doom_in_play(game_ctx.state),
				"threshold": game_ctx.state.agenda_threshold,
			}
		)
	return {
		"ok": true,
		"doom_on_agenda": game_ctx.state.doom_on_agenda,
		"doom_in_play": AgendaDoomPolicy.doom_in_play(game_ctx.state),
	}


static func check_doom_threshold(game_ctx: GameContext) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "reason": &"invalid_context"}
	if not AgendaDoomPolicy.meets_threshold(game_ctx.state):
		if game_ctx.log != null:
			game_ctx.log.log(
				AhcEnums.LogCategory.SCENARIO,
				"mythos:check_doom_threshold",
				{
					"doom_in_play": AgendaDoomPolicy.doom_in_play(game_ctx.state),
					"threshold": game_ctx.state.agenda_threshold,
					"advanced": false,
				}
			)
		return {
			"ok": true,
			"advanced": false,
			"doom_in_play": AgendaDoomPolicy.doom_in_play(game_ctx.state),
		}
	var advance := AgendaDoomPolicy.try_nest_advance_if_needed(
		game_ctx, &"mythos_1_3", false
	)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"mythos:check_doom_threshold",
			{
				"doom_in_play": AgendaDoomPolicy.doom_in_play(game_ctx.state),
				"threshold": game_ctx.state.agenda_threshold,
				"advanced": bool(advance.get("advanced", false)),
			}
		)
	return {
		"ok": true,
		"advanced": bool(advance.get("advanced", false)),
		"advance": advance,
	}
