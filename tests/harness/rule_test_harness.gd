class_name RuleTestHarness
extends RefCounted

var ctx: GameContext


func _init(p_seed: int = 42) -> void:
	ctx = GameBootstrap.create(p_seed)
	GameBootstrap.setup_minimal_investigator(ctx, &"inv_1")


func run_setup() -> void:
	GameBootstrap.run_setup_through_game_begins(ctx)


func take_resource_action() -> Dictionary:
	return ctx.actions.execute(AhcEnums.ActionType.RESOURCE, &"inv_1")


func draw_action(extra: Dictionary = {}) -> Dictionary:
	return ctx.actions.execute(AhcEnums.ActionType.DRAW, &"inv_1", extra)


func prepare_action_phase(chaos_tokens: Array[ChaosToken] = []) -> bool:
	run_setup()
	if not advance_to_action_phase():
		return false
	if not chaos_tokens.is_empty():
		GameBootstrap.setup_chaos_bag(ctx, chaos_tokens)
	else:
		GameBootstrap.setup_chaos_bag(ctx, [ChaosToken.numeric(0)])
	ctx.state.registry.get_investigator(&"inv_1").actions_remaining = 1
	return true


func investigate_action(extra: Dictionary = {}) -> Dictionary:
	return ctx.actions.execute(AhcEnums.ActionType.INVESTIGATE, &"inv_1", extra)


func fight_action(extra: Dictionary = {}) -> Dictionary:
	return ctx.actions.execute(AhcEnums.ActionType.FIGHT, &"inv_1", extra)


func evade_action(extra: Dictionary = {}) -> Dictionary:
	return ctx.actions.execute(AhcEnums.ActionType.EVADE, &"inv_1", extra)


func engage_action(extra: Dictionary = {}) -> Dictionary:
	return ctx.actions.execute(AhcEnums.ActionType.ENGAGE, &"inv_1", extra)


func move_action(extra: Dictionary = {}) -> Dictionary:
	return ctx.actions.execute(AhcEnums.ActionType.MOVE, &"inv_1", extra)


func framework_step() -> AhcEnums.FrameworkStep:
	return ctx.framework.current_step


func event_count(kind: AhcEnums.EventRecordKind) -> int:
	var n := 0
	for rec in ctx.events.get_records():
		if rec.kind == kind:
			n += 1
	return n


func close_windows() -> void:
	while ctx.framework.waiting_player_window:
		ctx.framework.close_player_window_and_continue()


func auto_advance(max_hops: int = 256) -> void:
	var hops := 0
	while hops < max_hops:
		if ctx.framework.is_action_phase():
			break
		if ctx.framework.waiting_player_window:
			close_windows()
		else:
			ctx.framework.advance()
		hops += 1


func advance_to_action_phase() -> bool:
	auto_advance()
	return ctx.framework.is_action_phase()


func end_turn() -> void:
	close_windows()
	ctx.framework.end_investigator_turn()
	close_windows()


func run_through_step(target: AhcEnums.FrameworkStep, max_hops: int = 512) -> bool:
	var hops := 0
	while ctx.framework.current_step != target and hops < max_hops:
		if ctx.framework.is_action_phase():
			return false
		if ctx.framework.waiting_player_window:
			close_windows()
		else:
			ctx.framework.advance()
		hops += 1
	return ctx.framework.current_step == target


func run_full_round_one_investigator() -> bool:
	return run_full_round_investigators(1)


func run_full_round_investigators(count: int) -> bool:
	if count < 1:
		return false
	if not advance_to_action_phase():
		return false
	for i in count:
		end_turn()
		if i < count - 1 and not advance_to_action_phase():
			return false
	return run_through_step(AhcEnums.FrameworkStep.UPKEEP_4_6_PHASE_ENDS)
