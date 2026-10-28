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
	_state.chaos_bag.begin_reveal_scope(ctx.id)
	## 紧贴 resolved 揭示：袋在 disposition 定案时回调。
	_state.chaos_bag.on_resolved_reveal = _on_bag_resolved_reveal
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
	## ST.3 整帧（含 After）结束后，对批内每枚 nest ST.4；reveal another 在符号帧内再 nest。
	## 不再 while 内联 ST.3→ST.4。
	step_reveal_token(ctx)
	step_apply_symbol_effects(ctx)
	## 揭示链结束 → PW_AFTER_REVEAL → ST.5。
	## *If revealed* 已在各次 resolved 结算时 eager 触发，不再固定时点读账本。
	_open_player_window(ctx, AhcEnums.PlayerWindow.PW_SKILL_TEST_AFTER_REVEAL)


func continue_after_reveal_window(ctx: SkillTestContext) -> void:
	_snapshot_if_revealed(ctx)
	step_calculate_modified_value(ctx)
	step_determine_success(ctx)


## 一枚 token 已定案为 resolved：驱动 if_revealed_watchers（紧贴揭示）。
func notify_resolved_reveal(ctx: SkillTestContext, token: ChaosToken) -> void:
	if ctx == null or token == null:
		return
	_dispatch_if_revealed(ctx, token.kind)


func _on_bag_resolved_reveal(token: ChaosToken, _rec: ChaosRevealRecord) -> void:
	var ctx := current_context()
	if ctx == null:
		return
	notify_resolved_reveal(ctx, token)


func _dispatch_if_revealed(ctx: SkillTestContext, kind: AhcEnums.ChaosTokenKind) -> void:
	var kind_i := int(kind)
	for entry in ctx.if_revealed_watchers:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if not _watcher_matches_kind(entry, kind_i):
			continue
		var cb: Variant = entry.get("on_match")
		if typeof(cb) != TYPE_CALLABLE or not (cb as Callable).is_valid():
			continue
		var mode: StringName = entry.get("mode", &"any")
		if mode == &"each":
			## for-each：每枚 resolved 一次，不自肃。
			(cb as Callable).call(ctx, kind_i, 1)
			continue
		## any / binary：自肃 — 本检定至多一次。
		if bool(entry.get("fired", false)):
			continue
		entry["fired"] = true
		(cb as Callable).call(ctx, kind_i, 1)
	if _timing:
		_timing.emit_timing(
			&"skill_test_if_revealed",
			{"test_id": ctx.id, "kind": kind_i}
		)


func _watcher_matches_kind(entry: Dictionary, kind_i: int) -> bool:
	var kinds_raw: Variant = entry.get("kinds", null)
	if kinds_raw is Array:
		for k in kinds_raw as Array:
			if int(k) == kind_i:
				return true
		return false
	return int(entry.get("kind", -1)) == kind_i


func _snapshot_if_revealed(ctx: SkillTestContext) -> void:
	var bag := _state.chaos_bag
	ctx.if_revealed_snapshot = {
		"scope_id": bag.reveal_scope_id,
		"resolved": bag.resolved_records().duplicate(),
		"revealed": bag.revealed_records().duplicate(),
		"uncanceled": bag.revealed_records().duplicate(),
	}


func step_reveal_token(ctx: SkillTestContext) -> ChaosToken:
	ctx.current_step = AhcEnums.SkillTestStep.ST_3_REVEAL
	ctx.reveal_batch_start = ctx.revealed_tokens.size()
	if _game_ctx != null and _game_ctx.sequence_catalog != null:
		## nest：父检定/符号帧下压 ST.3；无父时 nest≡run。
		_game_ctx.sequence_catalog.nest(
			_game_ctx,
			&"seq.chaos.reveal",
			{
				"inv_id": ctx.performing_investigator,
				"test_id": ctx.id,
				"skill_test_ctx": ctx,
			}
		)
	else:
		var abilities: Array = ctx.pending_reveal_replace.duplicate()
		ctx.pending_reveal_replace.clear()
		var gate: PlayerInteractionGate = _game_ctx.interaction if _game_ctx != null else null
		var plan: Dictionary = ChaosRevealIntentPlanner.plan_and_reveal(
			_state.chaos_bag,
			1,
			abilities,
			gate,
			_game_ctx,
			ctx.performing_investigator,
			&"skill_test"
		)
		ctx.last_reveal_intent = plan
		var resolved_fb: Array = plan.get("resolved", [])
		for item in resolved_fb:
			if item is ChaosToken:
				ctx.revealed_tokens.append(item as ChaosToken)
		_state.chaos_bag.notify_resolved_tokens(resolved_fb)
	_advance_step(AhcEnums.SkillTestStep.ST_3_REVEAL, ctx)
	if ctx.revealed_tokens.is_empty():
		return null
	return ctx.revealed_tokens[ctx.revealed_tokens.size() - 1]


## 对当前批 resolved 逐枚 nest `seq.chaos.symbol`（ST.4）。
## 返回是否有 token 请求 reveal_another（审计；再揭示已在符号帧内 nest）。
func step_apply_symbol_effects(ctx: SkillTestContext) -> bool:
	ctx.current_step = AhcEnums.SkillTestStep.ST_4_SYMBOL
	var again := false
	var start := clampi(ctx.reveal_batch_start, 0, ctx.revealed_tokens.size())
	## 批大小在循环前固定：reveal_another 追加的 token 由符号帧内递归 nest，不在此扫。
	var end := ctx.revealed_tokens.size()
	for i in range(start, end):
		var token: ChaosToken = ctx.revealed_tokens[i]
		if token == null:
			continue
		_initiate_symbol_ability(ctx, token)
		if token.reveal_another:
			again = true
	_advance_step(AhcEnums.SkillTestStep.ST_4_SYMBOL, ctx)
	return again


## 单枚：优先 nest `seq.chaos.symbol`；无 Catalog 时回退内联（仅测试旁路）。
func _initiate_symbol_ability(ctx: SkillTestContext, token: ChaosToken) -> void:
	if (
		_game_ctx != null
		and _game_ctx.sequence_catalog != null
		and _game_ctx.sequence_catalog.has_flow(&"seq.chaos.symbol")
	):
		_game_ctx.sequence_catalog.nest(
			_game_ctx,
			&"seq.chaos.symbol",
			{
				"inv_id": ctx.performing_investigator,
				"test_id": ctx.id,
				"skill_test_ctx": ctx,
				"token": token,
			}
		)
		return
	_apply_token_effect(ctx, token)


func step_calculate_modified_value(ctx: SkillTestContext) -> int:
	ctx.current_step = AhcEnums.SkillTestStep.ST_5_CALCULATE
	var inv := _state.registry.get_investigator(ctx.performing_investigator)
	var base := inv.get_skill(ctx.skill) if inv else 0
	var commit_bonus := 0
	for c in ctx.committed:
		commit_bonus += c.icon_bonus
	## 混乱符号修正已是 THIS_SKILL_TEST MODIFIER Buff，经 ModifierEngine 汇入（勿再加 chaos_modifier）。
	## compute(base+commit) 一次算完：负修正可压低总值；引擎内部 floor≥0。
	var assembled := base + commit_bonus
	if _modifiers:
		var q := ModifierQuery.new()
		q.controller_id = ctx.performing_investigator
		q.stat = _skill_to_stat(ctx.skill)
		assembled = _modifiers.compute(assembled, q)
	ctx.modified_value = assembled
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
	_state.chaos_bag.end_reveal_scope()
	## 卸掉本次检定 THIS_SKILL_TEST 修正（含混乱符号 MODIFIER Buff）。
	var regs: RegistrationStore = null
	if game_ctx != null:
		regs = game_ctx.registrations
	elif _game_ctx != null:
		regs = _game_ctx.registrations
	if regs != null:
		regs.tick_duration(AhcEnums.DurationAnchorKind.THIS_SKILL_TEST)
	if _stack.size() > 0 and _stack[_stack.size() - 1] == ctx:
		_stack.pop_back()
	## 嵌套检定可能仍在栈上；仅栈空时卸回调。
	if _stack.is_empty():
		_state.chaos_bag.on_resolved_reveal = Callable()
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
	continue_after_reveal_window(ctx)
	step_apply_results(ctx)
	if game_ctx != null:
		RetaliateAlertResolver.resolve_post_st7(game_ctx, ctx)
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
	## 旁路：无 Catalog 时与 ChaosSymbolFlow 同序。
	ChaosSymbolFlow.apply_symbol_ability(_game_ctx, ctx, token)


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
	if _game_ctx != null and _game_ctx.player_window_intents != null:
		_game_ctx.player_window_intents.begin_window()


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
