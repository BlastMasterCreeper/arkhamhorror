class_name EncounterAgendaDoomPlacement
extends RefCounted

## 12124 等 · 当前密谋卡放置 1 doom；explicit 时可 nest `seq.agenda.advance`（OQ-ADB-08）。


static func place_on_current_agenda(
	game_ctx: GameContext,
	may_advance_agenda: bool = false
) -> bool:
	## 统一 nest `seq.mythos.place_doom`，使 AFTER / Forced（如 12108）可听到任意密谋放置毁灭。
	if game_ctx == null or game_ctx.state == null:
		return false
	var placed := false
	if game_ctx.sequence_catalog != null:
		var result := game_ctx.sequence_catalog.nest(
			game_ctx, &"seq.mythos.place_doom", {}
		)
		placed = bool(result.get("ok", false))
	else:
		game_ctx.state.doom_on_agenda += 1
		placed = true
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"encounter:place_doom_agenda",
			{
				"doom_on_agenda": game_ctx.state.doom_on_agenda,
				"doom_in_play": game_ctx.state.doom_in_play(),
				"threshold": game_ctx.state.agenda_threshold,
				"may_advance": may_advance_agenda,
			}
		)
	if may_advance_agenda:
		AgendaDoomPolicy.try_nest_advance_if_needed(
			game_ctx, &"card_effect", true
		)
	return placed
