class_name DrawEncounterFlow
extends RefCounted

## seq.draw.encounter · G1–G5 竖切（P-ENC-1～7）+ resolve_bound weakness 重定向。


static func run(game_ctx: GameContext, drawer_id: StringName) -> Dictionary:
	if game_ctx == null or game_ctx.mutator == null:
		return _fail("invalid_context")
	var frame := EncounterResolutionFrame.create(drawer_id)
	game_ctx.memory.push_encounter_frame(frame)
	var resolved_cards: Array[StringName] = []
	var revelations: Array[StringName] = []
	var spawn_failed_discards: Array[StringName] = []
	while true:
		var collect := DrawEncounterSubflowHandlers.collect_one_step(game_ctx, frame)
		if collect.get("rules_gap", false):
			game_ctx.memory.pop_encounter_frame()
			if resolved_cards.is_empty():
				return _fail("encounter_piles_empty")
			break
		if not collect.get("collected", false):
			break
		var card_id: StringName = collect.get("card_id", &"")
		frame.current_card_id = card_id
		var body := _resolve_one_card(game_ctx, frame, drawer_id, card_id)
		resolved_cards.append(card_id)
		frame.append_resolved(card_id)
		for rev_id in body.get("revelations", []):
			revelations.append(rev_id as StringName)
		for failed_id in body.get("spawn_failed_discards", []):
			spawn_failed_discards.append(failed_id as StringName)
		if not bool(body.get("should_surge", false)):
			break
		frame.surge_depth += 1
	game_ctx.memory.pop_encounter_frame()
	return {
		"ok": true,
		"drawer_id": drawer_id,
		"cards": resolved_cards,
		"surge_depth": frame.surge_depth,
		"revelations": revelations,
		"spawn_failed_discards": spawn_failed_discards,
		"shuffles": frame.shuffles,
		"shuffled": frame.shuffles > 0,
	}


## weakness 重定向：skip G1 pop，bind 已有 card_id，走同一 priority 队列。
static func resolve_bound(
	game_ctx: GameContext,
	drawer_id: StringName,
	card_id: StringName
) -> Dictionary:
	if game_ctx == null or game_ctx.mutator == null or card_id == &"":
		return _fail("invalid_bound")
	var frame := game_ctx.memory.peek_encounter_frame()
	var pushed_frame := false
	if frame == null:
		frame = EncounterResolutionFrame.create(drawer_id)
		game_ctx.memory.push_encounter_frame(frame)
		pushed_frame = true
	frame.current_card_id = card_id
	_bind_bound_card(game_ctx, card_id, drawer_id)
	var body := _resolve_one_card(game_ctx, frame, drawer_id, card_id)
	if pushed_frame:
		game_ctx.memory.pop_encounter_frame()
	var revelations: Array[StringName] = []
	var spawn_failed_discards: Array[StringName] = []
	for rev_id in body.get("revelations", []):
		revelations.append(rev_id as StringName)
	for failed_id in body.get("spawn_failed_discards", []):
		spawn_failed_discards.append(failed_id as StringName)
	return {
		"ok": true,
		"drawer_id": drawer_id,
		"card_id": card_id,
		"bound": true,
		"should_surge": bool(body.get("should_surge", false)),
		"revelations": revelations,
		"spawn_failed_discards": spawn_failed_discards,
	}


static func _bind_bound_card(
	game_ctx: GameContext,
	card_id: StringName,
	drawer_id: StringName
) -> void:
	game_ctx.mutator.enter_limbo(card_id, drawer_id)


static func _resolve_one_card(
	game_ctx: GameContext,
	frame: EncounterResolutionFrame,
	drawer_id: StringName,
	card_id: StringName
) -> Dictionary:
	var def_id := _definition_id(game_ctx, card_id)
	_reveal_encounter_drawn(game_ctx, card_id, drawer_id, def_id)
	_emit_encounter_card_drawn(game_ctx, drawer_id, card_id)
	var outcome := {"should_surge": false, "revelations": [], "spawn_failed_discards": []}
	if game_ctx.sequences != null:
		var trigger := TriggeringCondition.encounter_card_drawn(drawer_id, card_id)
		game_ctx.sequences.nest(
			trigger,
			func() -> void:
				var result := _run_priority_queue(game_ctx, frame, drawer_id, card_id, def_id)
				outcome.merge(result, true)
		)
	else:
		outcome = _run_priority_queue(game_ctx, frame, drawer_id, card_id, def_id)
	return outcome


static func _reveal_encounter_drawn(
	game_ctx: GameContext,
	card_id: StringName,
	drawer_id: StringName,
	def_id: StringName
) -> void:
	if game_ctx == null or game_ctx.mutator == null:
		return
	if CardRegistry.is_hidden(def_id):
		game_ctx.mutator.hide_from_all(card_id)  # 隐私 · E2 不公开
		return
	game_ctx.mutator.reveal_to_all(card_id)


static func _emit_encounter_card_drawn(
	game_ctx: GameContext,
	drawer_id: StringName,
	card_id: StringName
) -> void:
	if game_ctx.timing == null:
		return
	game_ctx.timing.emit_timing(
		&"encounter_card_drawn",
		{"drawer_id": drawer_id, "card_id": card_id}
	)


static func _run_priority_queue(
	game_ctx: GameContext,
	frame: EncounterResolutionFrame,
	drawer_id: StringName,
	card_id: StringName,
	def_id: StringName
) -> Dictionary:
	var outcome := {"should_surge": false, "revelations": [], "spawn_failed_discards": []}
	var ctx := {
		"game_ctx": game_ctx,
		"frame": frame,
		"drawer_id": drawer_id,
		"card_id": card_id,
		"def_id": def_id,
		"outcome": outcome,
	}
	var steps: Array[Dictionary] = [
		{
			"priority": EncounterDrawPriority.PERIL_REGISTER,
			"fn": _step_peril_register.bind(ctx),
		},
		{
			"priority": EncounterDrawPriority.REVELATION_FORCED,
			"fn": _step_revelation.bind(ctx),
		},
		{
			"priority": EncounterDrawPriority.G4_TYPE_RESOLVE,
			"fn": _step_g4_resolve.bind(ctx),
		},
		{
			"priority": EncounterDrawPriority.AFTER_CARD,
			"fn": _step_after_card.bind(ctx),
		},
		{
			"priority": EncounterDrawPriority.SURGE_KEYWORD,
			"fn": _step_surge_eval.bind(ctx),
		},
	]
	steps.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("priority", 0)) > int(b.get("priority", 0))
	)
	for step in steps:
		var fn: Callable = step.get("fn", Callable())
		if fn.is_valid():
			fn.call()
	return outcome


static func _step_peril_register(ctx: Dictionary) -> void:
	var game_ctx: GameContext = ctx.get("game_ctx")
	var drawer_id: StringName = ctx.get("drawer_id", &"")
	var card_id: StringName = ctx.get("card_id", &"")
	var def_id: StringName = ctx.get("def_id", &"")
	EncounterPeril.register_if_peril(
		game_ctx,
		drawer_id,
		card_id,
		CardRegistry.has_keyword(def_id, &"peril")
	)


static func _step_revelation(ctx: Dictionary) -> void:
	var game_ctx: GameContext = ctx.get("game_ctx")
	var drawer_id: StringName = ctx.get("drawer_id", &"")
	var card_id: StringName = ctx.get("card_id", &"")
	var def_id: StringName = ctx.get("def_id", &"")
	var outcome: Dictionary = ctx.get("outcome", {})
	if game_ctx == null or game_ctx.card_abilities == null:
		return
	var has_card_revelation := game_ctx.card_abilities.has_revelation(game_ctx, card_id)
	if not has_card_revelation and not CardRegistry.is_hidden(def_id):
		return
	if (
		game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(&"seq.encounter.revelation")
	):
		var nest_result := game_ctx.sequence_catalog.nest(
			game_ctx,
			&"seq.encounter.revelation",
			{"drawer_id": drawer_id, "card_id": card_id}
		)
		if nest_result.get("resolved", false):
			(outcome.get("revelations", []) as Array).append(card_id)
		return
	if game_ctx.card_abilities.resolve_revelations(
		game_ctx, drawer_id, card_id, &"seq.draw.encounter", true
	):
		(outcome.get("revelations", []) as Array).append(card_id)


static func _hidden_enemy_skips_spawn(card: CardInstance, def_id: StringName) -> bool:
	## 隐私 enemy 在手：Framework 默认 spawn 会离手，违反「仅卡面能力可离手」→ G4 跳过。
	if card == null or not CardRegistry.is_hidden(def_id):
		return false
	return card.zone == AhcEnums.Zone.HAND or card.is_hidden


static func _nest_encounter_spawn(
	game_ctx: GameContext,
	drawer_id: StringName,
	card_id: StringName,
	outcome: Dictionary
) -> void:
	if game_ctx == null:
		return
	if (
		game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(&"seq.encounter.spawn")
	):
		var nest_result := game_ctx.sequence_catalog.nest(
			game_ctx,
			&"seq.encounter.spawn",
			{"drawer_id": drawer_id, "card_id": card_id}
		)
		if nest_result.get("discarded", false):
			(outcome.get("spawn_failed_discards", []) as Array).append(card_id)
		return
	if game_ctx.enemy != null:
		var result := game_ctx.enemy.spawn_from_encounter_draw(game_ctx, card_id, drawer_id)
		if result.get("discarded", false):
			(outcome.get("spawn_failed_discards", []) as Array).append(card_id)


static func _step_g4_resolve(ctx: Dictionary) -> void:
	var game_ctx: GameContext = ctx.get("game_ctx")
	var drawer_id: StringName = ctx.get("drawer_id", &"")
	var card_id: StringName = ctx.get("card_id", &"")
	var def_id: StringName = ctx.get("def_id", &"")
	EncounterPeril.unregister_for_card(game_ctx, card_id)
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return
	if CardRegistry.card_type(def_id) == &"enemy":
		if _hidden_enemy_skips_spawn(card, def_id):
			return
		_nest_encounter_spawn(game_ctx, drawer_id, card_id, ctx.get("outcome", {}))
		return
	if card.is_hidden and card.zone == AhcEnums.Zone.HAND:
		return  # 隐私 treachery · Framework 不得离手 → 跳过
	if card.zone == AhcEnums.Zone.HAND or card.zone == AhcEnums.Zone.PLAY_AREA:
		return
	## 遭遇 treachery 默认落点 =「效果结算后仍在 limbo → finalize」（同 seq.enter_hand · 15 §16.4）
	game_ctx.mutator.finalize_limbo_discard(card_id, drawer_id)


static func _step_after_card(ctx: Dictionary) -> void:
	var game_ctx: GameContext = ctx.get("game_ctx")
	var drawer_id: StringName = ctx.get("drawer_id", &"")
	var card_id: StringName = ctx.get("card_id", &"")
	if game_ctx == null or game_ctx.timing == null:
		return
	game_ctx.timing.emit_timing(
		&"after_encounter_card_resolved",
		{"drawer_id": drawer_id, "card_id": card_id}
	)


static func _step_surge_eval(ctx: Dictionary) -> void:
	var game_ctx: GameContext = ctx.get("game_ctx")
	var card_id: StringName = ctx.get("card_id", &"")
	var def_id: StringName = ctx.get("def_id", &"")
	var outcome: Dictionary = ctx.get("outcome", {})
	outcome["should_surge"] = EffectiveCharacteristicQuery.has_effective_keyword(
		game_ctx, card_id, def_id, &"surge"
	)
	EncounterGainedKeyword.unregister_for_card(game_ctx, card_id)


static func _definition_id(game_ctx: GameContext, card_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return &""
	return card.id.definition_id


static func resolve_encounter_card_tail(
	game_ctx: GameContext,
	drawer_id: StringName,
	card_id: StringName
) -> Dictionary:
	## G3 显现 + G4 finalize + AFTER + Surge 评估（Ward 竖切 / 测试）。
	var def_id := _definition_id(game_ctx, card_id)
	var frame := game_ctx.memory.peek_encounter_frame() if game_ctx.memory != null else null
	if frame == null and game_ctx.memory != null:
		frame = EncounterResolutionFrame.create(drawer_id)
		game_ctx.memory.push_encounter_frame(frame)
	var outcome := {"should_surge": false, "revelations": [], "spawn_failed_discards": []}
	var ctx := {
		"game_ctx": game_ctx,
		"frame": frame,
		"drawer_id": drawer_id,
		"card_id": card_id,
		"def_id": def_id,
		"outcome": outcome,
	}
	_step_revelation(ctx)
	_step_g4_resolve(ctx)
	_step_after_card(ctx)
	_step_surge_eval(ctx)
	return outcome


static func _fail(error: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"cards": [],
		"surge_depth": 0,
		"revelations": [],
		"spawn_failed_discards": [],
		"shuffles": 0,
		"shuffled": false,
	}
