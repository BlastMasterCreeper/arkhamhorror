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
	## REST-E-EFFECT：交战期间 FORBID_DISCOVER_CLUE（01121b 等）。
	if (
		game_ctx.registrations != null
		and RestrictionEvaluator.blocks_discover_clue(inv_id, game_ctx.registrations)
	):
		return {
			"ok": false,
			"error": "restriction_forbid_discover_clue",
			"amount": 0,
			"location_id": location_id,
			"inv_id": inv_id,
		}
	## 0 量不结算（与 AmountPlan / 06 §16.3.2 同向；禁止 maxi(amount,1) 抬升）。
	if amount <= 0:
		return {
			"ok": false,
			"error": "zero_amount",
			"amount": 0,
			"location_id": location_id,
			"inv_id": inv_id,
		}
	var moved := 0
	var n := amount
	if game_ctx.mutator == null:
		return {"ok": false, "error": "no_mutator", "amount": 0}
	while moved < n and loc.clues > 0:
		if not game_ctx.mutator.transfer_marker(
			AhcEnums.MarkerKind.CLUE,
			1,
			MarkerSlot.location(location_id, AhcEnums.MarkerKind.CLUE),
			MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.CLUE)
		):
			break
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
