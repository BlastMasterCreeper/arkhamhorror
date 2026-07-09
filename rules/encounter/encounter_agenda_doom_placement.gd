class_name EncounterAgendaDoomPlacement
extends RefCounted

## 12124 等 · 当前密谋卡放置 1 doom；explicit 时可 nest `seq.agenda.advance`（OQ-ADB-08）。


static func place_on_current_agenda(
	game_ctx: GameContext,
	may_advance_agenda: bool = false
) -> bool:
	if game_ctx == null or game_ctx.state == null:
		return false
	game_ctx.state.doom_on_agenda += 1
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
	return true
