class_name AgendaAdvanceFlow
extends RefCounted

## seq.agenda.advance · 清 doom → flip/advance 当前密谋（Grimoire · 10 §4.2）。


static func run(game_ctx: GameContext, params: Dictionary = {}) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "advanced": false, "reason": &"invalid_context"}
	var source: StringName = params.get("source", &"unknown")
	var explicit: bool = bool(params.get("explicit", false))
	if not _may_advance(game_ctx, source, explicit):
		return {"ok": true, "advanced": false, "reason": &"not_allowed"}
	if not AgendaDoomPolicy.meets_threshold(game_ctx.state):
		return {"ok": true, "advanced": false, "reason": &"below_threshold"}
	var from_agenda := game_ctx.state.current_agenda_number
	var cleared := AgendaDoomPolicy.clear_all_doom(game_ctx)
	if game_ctx.state.current_agenda_card_id == &"":
		game_ctx.state.current_agenda_number = from_agenda + 1
		if game_ctx.log != null:
			game_ctx.log.log(
				AhcEnums.LogCategory.SCENARIO,
				"agenda:advanced",
				{
					"from": from_agenda,
					"to": game_ctx.state.current_agenda_number,
					"source": source,
					"doom_cleared": cleared,
					"legacy": true,
				}
			)
		return {
			"ok": true,
			"advanced": true,
			"from_agenda": from_agenda,
			"to_agenda": game_ctx.state.current_agenda_number,
			"doom_cleared": cleared,
			"legacy": true,
		}
	var flip := ActAgendaFlipFlow.flip_agenda(game_ctx)
	if not flip.get("flipped", false):
		return {"ok": false, "advanced": false, "reason": flip.get("reason", &"flip_failed")}
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"agenda:advanced",
			{
				"from": from_agenda,
				"to": game_ctx.state.current_agenda_number,
				"source": source,
				"doom_cleared": cleared,
				"current_card": game_ctx.state.current_agenda_card_id,
				"threshold": game_ctx.state.agenda_threshold,
			}
		)
	return {
		"ok": true,
		"advanced": true,
		"from_agenda": from_agenda,
		"to_agenda": game_ctx.state.current_agenda_number,
		"doom_cleared": cleared,
		"flip": flip,
	}


static func _may_advance(game_ctx: GameContext, source: StringName, explicit: bool) -> bool:
	if source == &"mythos_1_3":
		return true
	if explicit:
		return true
	if game_ctx.framework != null:
		return (
			game_ctx.framework.current_step
			== AhcEnums.FrameworkStep.MYTHOS_1_3_CHECK_DOOM_THRESHOLD
		)
	return false
