class_name MythosFlow
extends RefCounted

## Mythos 1.2–1.3 命名流程 · 框架步与 ScenarioService 共用。


static func place_doom(game_ctx: GameContext) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "reason": &"invalid_context"}
	if game_ctx.mutator == null:
		return {"ok": false, "reason": &"no_mutator"}
	if not game_ctx.mutator.transfer_marker(
		AhcEnums.MarkerKind.DOOM,
		1,
		MarkerSlot.supply(AhcEnums.MarkerKind.DOOM),
		MarkerSlot.agenda_doom()
	):
		return {"ok": false, "reason": &"transfer_failed"}
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


## 卡面 / Doomed：在当前密谋放置 1 doom（经 `seq.mythos.place_doom`）；
## `may_advance_agenda` 时显式 nest 推进（原 EncounterAgendaDoomPlacement）。
static func place_on_current_agenda(
	game_ctx: GameContext,
	may_advance_agenda: bool = false
) -> bool:
	if game_ctx == null or game_ctx.state == null:
		return false
	var placed := false
	if game_ctx.sequence_catalog != null:
		var result := game_ctx.sequence_catalog.nest(
			game_ctx, &"seq.mythos.place_doom", {}
		)
		placed = bool(result.get("ok", false))
	elif game_ctx.mutator != null:
		placed = game_ctx.mutator.transfer_marker(
			AhcEnums.MarkerKind.DOOM,
			1,
			MarkerSlot.supply(AhcEnums.MarkerKind.DOOM),
			MarkerSlot.agenda_doom()
		)
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
