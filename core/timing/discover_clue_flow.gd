class_name DiscoverClueFlow
extends RefCounted

## seq.effect.discover_clue · 发现线索（调查成功 nest；Forced AFTER 可听到）。


static func run(
	game_ctx: GameContext,
	inv_id: StringName,
	location_id: StringName,
	amount: int = 1
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "invalid_context"}
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	var loc := game_ctx.state.registry.get_location(location_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator"}
	if loc == null:
		return {"ok": false, "error": "unknown_location"}
	var moved := 0
	var n := maxi(amount, 1)
	while moved < n and loc.clues > 0:
		loc.clues -= 1
		inv.clues_on_card += 1
		moved += 1
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.CARD,
			"effect:discover_clue",
			{"inv": inv_id, "location": location_id, "amount": moved}
		)
	return {
		"ok": moved > 0,
		"amount": moved,
		"location_id": location_id,
		"inv_id": inv_id,
	}
