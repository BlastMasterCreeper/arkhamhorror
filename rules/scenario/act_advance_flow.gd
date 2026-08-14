class_name ActAdvanceFlow
extends RefCounted

## seq.act.advance · 花费线索（可选）→ flip 当前场景（Grimoire · 10 §3）。


static func run(game_ctx: GameContext, params: Dictionary = {}) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "advanced": false, "reason": &"invalid_context"}
	if game_ctx.state.current_act_card_id == &"":
		return {"ok": false, "advanced": false, "reason": &"no_current_act"}
	var required: int = int(params.get("clues_required", game_ctx.state.act_clue_threshold))
	var skip_spend: bool = bool(params.get("skip_clue_spend", false))
	if required > 0 and not skip_spend:
		if not _spend_clues_as_group(game_ctx, required):
			return {"ok": true, "advanced": false, "reason": &"insufficient_clues"}
	var flip := ActAgendaFlipFlow.flip_act(game_ctx)
	if not flip.get("flipped", false):
		return {"ok": false, "advanced": false, "reason": flip.get("reason", &"flip_failed")}
	return {
		"ok": true,
		"advanced": true,
		"from_act": int(game_ctx.state.current_act_number) - 1,
		"to_act": game_ctx.state.current_act_number,
		"flip": flip,
	}


static func _spend_clues_as_group(game_ctx: GameContext, amount: int) -> bool:
	if amount <= 0:
		return true
	var total := 0
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv != null and not inv.eliminated:
			total += inv.clues_on_card
	if total < amount:
		return false
	var remaining := amount
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		if remaining <= 0:
			break
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null or inv.eliminated or inv.clues_on_card <= 0:
			continue
		var spend := mini(inv.clues_on_card, remaining)
		inv.clues_on_card -= spend
		remaining -= spend
	return remaining <= 0
