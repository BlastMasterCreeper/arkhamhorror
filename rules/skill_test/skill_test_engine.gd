class_name SkillTestEngine
extends RefCounted

var _state: GameStateStore
var _events: EventRecordLog
var _log: GameLog
var _modifiers: ModifierEngine
var _mutator: StateMutator
var _timing: TimingBus
var _stack: Array[SkillTestContext] = []
var _next_id: int = 0
var _pending_nested: Array[SkillTestContext] = []
var _game_ctx: GameContext = null


func _init(
	state: GameStateStore,
	events: EventRecordLog,
	log: GameLog,
	modifiers: ModifierEngine = null,
	mutator: StateMutator = null,
	timing: TimingBus = null
) -> void:
	_state = state
	_events = events
	_log = log
	_modifiers = modifiers
	_mutator = mutator
	_timing = timing


func begin_test(ctx: SkillTestContext, game_ctx: GameContext = null) -> SkillTestContext:
	_game_ctx = game_ctx
	if game_ctx != null and game_ctx.memory != null:
		EncounterPeril.sync_test_context_from_frame(ctx, game_ctx)
	if ctx.id == &"":
		_next_id += 1
		ctx.id = StringName("skill_test_%d" % _next_id)
	_stack.append(ctx)
	_sync_stack(game_ctx)
	ctx.current_step = AhcEnums.SkillTestStep.ST_1_BEGIN
	_advance_step(AhcEnums.SkillTestStep.ST_1_BEGIN, ctx)
	if _timing:
		_timing.emit_timing(&"skill_test_begins", {"test_id": ctx.id})
	return ctx


func step_commit(ctx: SkillTestContext, commits: Array[CommittedCard]) -> Dictionary:
	if ctx.current_step != AhcEnums.SkillTestStep.ST_1_BEGIN:
		return {"ok": false, "error": "wrong_step"}
	for commit in commits:
		var res := commit_card(ctx, commit.from_investigator, commit.card_id)
		if not res.ok:
			return res
	ctx.current_step = AhcEnums.SkillTestStep.ST_2_COMMIT
	_advance_step(AhcEnums.SkillTestStep.ST_2_COMMIT, ctx)
	_open_player_window(ctx, AhcEnums.PlayerWindow.PW_SKILL_TEST_AFTER_COMMIT)
	return {"ok": true}


func commit_card(ctx: SkillTestContext, from_inv: StringName, card_id: StringName) -> Dictionary:
	var store := _game_ctx.registrations if _game_ctx != null else null
	var peril_reason := RestrictionEvaluator.block_reason(
		RestrictionEvaluator.Intent.COMMIT_TO_TEST,
		from_inv,
		store,
		ctx
	)
	if peril_reason != &"":
		return {"ok": false, "error": RestrictionEvaluator.commit_block_error(peril_reason)}
	var performer := _state.registry.get_investigator(ctx.performing_investigator)
	var committer := _state.registry.get_investigator(from_inv)
	if performer == null or committer == null:
		return {"ok": false, "error": "missing_investigator"}
	if from_inv != ctx.performing_investigator:
		if ctx.ally_committed:
			return {"ok": false, "error": "ally_already_committed"}
		if not performer.shares_location_with(committer):
			return {"ok": false, "error": "not_same_location"}
	var card := _state.registry.get_card(card_id)
	if card == null or card.zone != AhcEnums.Zone.HAND:
		return {"ok": false, "error": "not_in_hand"}
	if card.owner_id != from_inv and card.controller_id != from_inv:
		return {"ok": false, "error": "not_controller"}
	if not committer.hand.has(card_id):
		return {"ok": false, "error": "not_in_hand"}
	var bonus := _matching_icon_bonus(card, ctx.skill)
	if bonus <= 0:
		return {"ok": false, "error": "no_matching_icon"}
	if card.max_committed_per_test >= 0:
		var title_count := _count_committed_by_definition(ctx, card.id.definition_id)
		if title_count >= card.max_committed_per_test:
			return {"ok": false, "error": "max_committed"}
	ctx.committed.append(CommittedCard.create(card_id, from_inv, bonus))
	if from_inv != ctx.performing_investigator:
		ctx.ally_committed = true
	return {"ok": true}


func resolve_reveal_chain(ctx: SkillTestContext) -> void:
	if ctx.current_step != AhcEnums.SkillTestStep.ST_2_COMMIT:
		return
	while true:
		step_reveal_token(ctx)
		var reveal_again := step_apply_symbol_effects(ctx)
		if not reveal_again:
			break
	_open_player_window(ctx, AhcEnums.PlayerWindow.PW_SKILL_TEST_AFTER_REVEAL)
	step_calculate_modified_value(ctx)
	step_determine_success(ctx)


func step_reveal_token(ctx: SkillTestContext) -> ChaosToken:
	ctx.current_step = AhcEnums.SkillTestStep.ST_3_REVEAL
	var token := _state.chaos_bag.draw_random()
	if token:
		ctx.revealed_tokens.append(token)
	_advance_step(AhcEnums.SkillTestStep.ST_3_REVEAL, ctx)
	return token


func step_apply_symbol_effects(ctx: SkillTestContext) -> bool:
	ctx.current_step = AhcEnums.SkillTestStep.ST_4_SYMBOL
	var token := ctx.revealed_tokens[ctx.revealed_tokens.size() - 1] if not ctx.revealed_tokens.is_empty() else null
	if token:
		_apply_token_effect(ctx, token)
	_advance_step(AhcEnums.SkillTestStep.ST_4_SYMBOL, ctx)
	return token != null and token.reveal_another


func step_calculate_modified_value(ctx: SkillTestContext) -> int:
	ctx.current_step = AhcEnums.SkillTestStep.ST_5_CALCULATE
	var inv := _state.registry.get_investigator(ctx.performing_investigator)
	var base := inv.get_skill(ctx.skill) if inv else 0
	var commit_bonus := 0
	for c in ctx.committed:
		commit_bonus += c.icon_bonus
	var reg_bonus := 0
	if _modifiers:
		var q := ModifierQuery.new()
		q.controller_id = ctx.performing_investigator
		q.stat = _skill_to_stat(ctx.skill)
		reg_bonus = _modifiers.compute(0, q)
	ctx.modified_value = base + commit_bonus + reg_bonus + ctx.chaos_modifier
	if ctx.auto_success:
		ctx.modified_value = maxi(ctx.modified_value, ctx.difficulty)
	if ctx.auto_fail:
		ctx.modified_value = 0
	ctx.modified_value = maxi(ctx.modified_value, 0)
	_advance_step(AhcEnums.SkillTestStep.ST_5_CALCULATE, ctx)
	return ctx.modified_value


func step_determine_success(ctx: SkillTestContext) -> bool:
	ctx.current_step = AhcEnums.SkillTestStep.ST_6_RESOLVE_RESULT
	var effective_difficulty := 0 if ctx.auto_success else ctx.difficulty
	if ctx.auto_fail:
		ctx.success = false
	else:
		ctx.success = ctx.modified_value >= effective_difficulty
	if not ctx.success and not ctx.auto_fail:
		ctx.fail_by = maxi(ctx.difficulty - ctx.modified_value, 0)
	else:
		ctx.fail_by = ctx.difficulty if ctx.auto_fail else maxi(ctx.difficulty - ctx.modified_value, 0)
	_advance_step(AhcEnums.SkillTestStep.ST_6_RESOLVE_RESULT, ctx)
	return ctx.success


func step_apply_results(ctx: SkillTestContext) -> Dictionary:
	ctx.current_step = AhcEnums.SkillTestStep.ST_7_APPLY
	if ctx.success:
		if ctx.on_success.is_valid():
			ctx.on_success.call(ctx)
		ctx.success_applied = true
	else:
		if ctx.on_fail.is_valid():
			ctx.on_fail.call(ctx)
		for effect in ctx.st7_fail_by_effects:
			if effect.is_valid():
				effect.call(ctx)
		ctx.fail_applied = true
	_advance_step(AhcEnums.SkillTestStep.ST_7_APPLY, ctx)
	return {"ok": true}


func step_end(ctx: SkillTestContext, game_ctx: GameContext = null) -> void:
	ctx.current_step = AhcEnums.SkillTestStep.ST_8_END
	_discard_committed(ctx)
	_state.chaos_bag.return_all_revealed()
	if _stack.size() > 0 and _stack[_stack.size() - 1] == ctx:
		_stack.pop_back()
	_sync_stack(game_ctx)
	_advance_step(AhcEnums.SkillTestStep.ST_8_END, ctx)
	if _timing:
		_timing.emit_timing(&"skill_test_ends", {"test_id": ctx.id})
	for nested in ctx.pending_nested_tests:
		_pending_nested.append(nested)
	_drain_pending_nested(game_ctx)


func run_full_test(ctx: SkillTestContext, game_ctx: GameContext = null, commits: Array[CommittedCard] = []) -> SkillTestResult:
	begin_test(ctx, game_ctx)
	step_commit(ctx, commits)
	close_player_window(ctx)
	resolve_reveal_chain(ctx)
	close_player_window(ctx)
	step_apply_results(ctx)
	step_end(ctx, game_ctx)
	var result := SkillTestResult.new()
	result.context = ctx
	result.success = ctx.success
	result.modified_value = ctx.modified_value
	result.fail_by = ctx.fail_by
	return result


func close_player_window(ctx: SkillTestContext) -> void:
	ctx.waiting_player_window = false


func queue_nested_test(parent: SkillTestContext, child: SkillTestContext) -> void:
	child.nested_depth = parent.nested_depth + 1
	child.encounter_resolution_id = parent.encounter_resolution_id
	if _game_ctx != null and _game_ctx.memory != null:
		EncounterPeril.sync_test_context_from_frame(child, _game_ctx)
	else:
		child.peril = parent.peril
	parent.pending_nested_tests.append(child)


func current_context() -> SkillTestContext:
	if _stack.is_empty():
		return null
	return _stack[_stack.size() - 1]


func skill_test_step_count(kind: AhcEnums.SkillTestStep) -> int:
	var n := 0
	for rec in _events.get_records():
		if rec.kind == AhcEnums.EventRecordKind.SKILL_TEST_STEP and rec.skill_test_step == kind:
			n += 1
	return n


func _drain_pending_nested(game_ctx: GameContext) -> void:
	while not _pending_nested.is_empty():
		var child: SkillTestContext = _pending_nested.pop_front()
		run_full_test(child, game_ctx)


func _discard_committed(ctx: SkillTestContext) -> void:
	for commit in ctx.committed:
		var card := _state.registry.get_card(commit.card_id)
		if card == null:
			continue
		var inv := _state.registry.get_investigator(commit.from_investigator)
		if inv == null:
			continue
		inv.hand.erase(commit.card_id)
		card.zone = AhcEnums.Zone.DISCARD
		inv.discard.append(commit.card_id)


func _apply_token_effect(ctx: SkillTestContext, token: ChaosToken) -> void:
	match token.kind:
		AhcEnums.ChaosTokenKind.NUMERIC:
			ctx.chaos_modifier += token.modifier
		AhcEnums.ChaosTokenKind.AUTO_FAIL:
			ctx.auto_fail = true
		AhcEnums.ChaosTokenKind.AUTO_SUCCESS:
			ctx.auto_success = true
		AhcEnums.ChaosTokenKind.SKULL:
			ctx.chaos_modifier -= _state.current_act_number
		_:
			ctx.chaos_modifier += token.modifier


func _matching_icon_bonus(card: CardInstance, skill: AhcEnums.SkillType) -> int:
	var key := _skill_icon_key(skill)
	if int(card.skill_icons.get(key, 0)) > 0 or int(card.skill_icons.get(&"wild", 0)) > 0:
		return 1
	return 0


func _count_committed_by_definition(ctx: SkillTestContext, definition_id: StringName) -> int:
	var count := 0
	for commit in ctx.committed:
		var card := _state.registry.get_card(commit.card_id)
		if card and card.id.definition_id == definition_id:
			count += 1
	return count


func _open_player_window(ctx: SkillTestContext, window: AhcEnums.PlayerWindow) -> void:
	ctx.waiting_player_window = true
	ctx.pending_player_window = window


func _advance_step(step: AhcEnums.SkillTestStep, ctx: SkillTestContext) -> void:
	ctx.current_step = step
	_events.append_skill_test(step, _state.compute_state_hash(), {"test_id": ctx.id})
	_log.log(AhcEnums.LogCategory.SKILL_TEST, "st:%s" % step, {"test_id": ctx.id})


func _sync_stack(game_ctx: GameContext) -> void:
	if game_ctx == null:
		return
	game_ctx.skill_test_stack = _stack.duplicate()


func _skill_icon_key(skill: AhcEnums.SkillType) -> StringName:
	match skill:
		AhcEnums.SkillType.WILLPOWER:
			return &"willpower"
		AhcEnums.SkillType.INTELLECT:
			return &"intellect"
		AhcEnums.SkillType.COMBAT:
			return &"combat"
		AhcEnums.SkillType.AGILITY:
			return &"agility"
	return &""


func _skill_to_stat(skill: AhcEnums.SkillType) -> AhcEnums.StatRef:
	match skill:
		AhcEnums.SkillType.WILLPOWER:
			return AhcEnums.StatRef.SKILL_WILLPOWER
		AhcEnums.SkillType.INTELLECT:
			return AhcEnums.StatRef.SKILL_INTELLECT
		AhcEnums.SkillType.COMBAT:
			return AhcEnums.StatRef.SKILL_COMBAT
		AhcEnums.SkillType.AGILITY:
			return AhcEnums.StatRef.SKILL_AGILITY
	return AhcEnums.StatRef.SKILL_WILLPOWER
