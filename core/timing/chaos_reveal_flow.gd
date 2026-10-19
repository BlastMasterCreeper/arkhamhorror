class_name ChaosRevealFlow
extends RefCounted

## seq.chaos.reveal · ST.3：WHEN 窗收集替换体 → RESOLVE 同时离袋（意图规划）。


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "invalid_context"}
	var ctx: SkillTestContext = params.get("skill_test_ctx") as SkillTestContext
	if ctx == null and game_ctx.skill_tests != null:
		ctx = game_ctx.skill_tests.current_context()
	if ctx == null:
		return {"ok": false, "error": "no_skill_test"}
	var abilities: Array = ctx.pending_reveal_replace.duplicate()
	ctx.pending_reveal_replace.clear()
	var gate: PlayerInteractionGate = game_ctx.interaction
	var plan: Dictionary = ChaosRevealIntentPlanner.plan_and_reveal(
		game_ctx.state.chaos_bag,
		1,
		abilities,
		gate,
		game_ctx,
		ctx.performing_investigator,
		&"skill_test"
	)
	ctx.last_reveal_intent = plan
	var resolved: Array = plan.get("resolved", [])
	for item in resolved:
		if item is ChaosToken:
			ctx.revealed_tokens.append(item as ChaosToken)
	return {
		"ok": not (plan.get("tokens", []) as Array).is_empty() or abilities.is_empty(),
		"leaf_count": int(plan.get("leaf_count", 0)),
		"resolved_count": resolved.size(),
		"ignored_count": (plan.get("ignored", []) as Array).size(),
		"order": plan.get("order", []),
	}
