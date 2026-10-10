class_name CompositionExecutor
extends RefCounted

var _state: GameStateStore
var _registrations: RegistrationStore
var _mutator: StateMutator
var _log: GameLog
var _game_ctx: GameContext
var _draw: DrawInvestigatorService
var _dry_runner: CompositionDryRunner = CompositionDryRunner.new()
var _last_step_created: bool = false
var _last_skill_test_fail_by: int = 0
var _last_step_enemy_id: StringName = &""
var _last_step_engaged_investigator: StringName = &""
var _last_resolved_location: StringName = &""
var _inv_override_stack: Array[StringName] = []


func _init(
	state: GameStateStore,
	registrations: RegistrationStore,
	mutator: StateMutator,
	log: GameLog
) -> void:
	_state = state
	_registrations = registrations
	_mutator = mutator
	_log = log


func bind_game_context(ctx: GameContext) -> void:
	_game_ctx = ctx
	if ctx:
		_draw = ctx.draw_investigator


## Seq 内上一子步是否 CREATED（after_step If · 07 §3.3 / §4.4）。
func last_step_created() -> bool:
	return _last_step_created


func last_step_engaged_investigator() -> StringName:
	return _last_step_engaged_investigator


func last_skill_test_fail_by() -> int:
	return _last_skill_test_fail_by


func execute(node: CompositionNode) -> void:
	_last_step_created = false
	_last_skill_test_fail_by = 0
	_last_step_enemy_id = &""
	_last_step_engaged_investigator = &""
	_last_resolved_location = &""
	_inv_override_stack.clear()
	_run_node(node)


func _run_node(node: CompositionNode) -> void:
	_stamp_provenance(node)
	match node.kind:
		AhcEnums.CompositionNodeKind.SEQ:
			_run_seq(node)
		AhcEnums.CompositionNodeKind.ATOM:
			_last_step_created = _execute_atom(node)
			_record_composition_step(node, _last_step_created)
		AhcEnums.CompositionNodeKind.REGISTER:
			_last_step_created = _execute_register(node)
			_record_composition_step(node, _last_step_created)
		AhcEnums.CompositionNodeKind.IF:
			_execute_if(node)
		AhcEnums.CompositionNodeKind.CHOICE:
			_execute_choice(node)
		AhcEnums.CompositionNodeKind.OPTIONAL:
			_execute_optional(node)
		AhcEnums.CompositionNodeKind.REPEAT:
			_execute_repeat(node)
		AhcEnums.CompositionNodeKind.FOR_EACH:
			_execute_for_each(node)


## SEQ：select/pick_target 后的兄弟作为 viability_tail（未显式标注且未 skip）。
func _run_seq(node: CompositionNode) -> void:
	for i in node.children.size():
		var child: CompositionNode = node.children[i]
		_maybe_attach_viability_tail(child, node.children, i)
		_run_node(child)


func _maybe_attach_viability_tail(
	child: CompositionNode, siblings: Array, index: int
) -> void:
	if child == null or child.kind != AhcEnums.CompositionNodeKind.ATOM:
		return
	if child.atom_name != &"pick_target" and child.atom_name != &"select":
		return
	var spec := _selection_spec_of(child)
	if spec == null or spec.skip_viability or spec.viability_tail != null:
		return
	var rest: Array[CompositionNode] = []
	for j in range(index + 1, siblings.size()):
		rest.append(siblings[j] as CompositionNode)
	if rest.is_empty():
		return
	## pick_multi + for_each_memory：V 用 each 体 + 单数 bind（非空列表）。
	spec.viability_tail = _viability_tail_from_rest(rest)
	child.selection_spec = spec


func _viability_tail_from_rest(rest: Array[CompositionNode]) -> CompositionNode:
	if rest.is_empty():
		return null
	var first: CompositionNode = rest[0]
	if (
		first != null
		and first.kind == AhcEnums.CompositionNodeKind.FOR_EACH
		and first.for_each_source == &"memory_list"
		and not first.children.is_empty()
	):
		var body: CompositionNode = first.children[0]
		if rest.size() == 1:
			return body
		var seq_nodes: Array[CompositionNode] = [body]
		for i in range(1, rest.size()):
			seq_nodes.append(rest[i])
		return CompositionNode.seq(seq_nodes)
	return first if rest.size() == 1 else CompositionNode.seq(rest)


func _resolve_inv(node: CompositionNode) -> StringName:
	if node.inv_id == CompositionNode.INV_EACH and not _inv_override_stack.is_empty():
		return _inv_override_stack[_inv_override_stack.size() - 1]
	return node.inv_id


func _execute_for_each(node: CompositionNode) -> void:
	if node.children.is_empty() or _game_ctx == null:
		return
	if node.for_each_source == &"memory_list":
		_execute_for_each_memory(node)
		return
	if _game_ctx.framework == null:
		return
	var order: Array[StringName] = []
	if node.for_each_source == &"player_order":
		order = _game_ctx.framework.player_order.duplicate()
	else:
		order = _state.registry.all_investigator_ids()
	for inv_id in order:
		var inv := _state.registry.get_investigator(inv_id)
		if inv == null or inv.eliminated or inv.resigned:
			continue
		_inv_override_stack.append(inv_id)
		_run_node(node.children[0])
		_inv_override_stack.pop_back()


## 遍历 entity_list：每轮写入 for_each_bind_key，body 读 memory: 单数指称。
func _execute_for_each_memory(node: CompositionNode) -> void:
	if _game_ctx.memory == null:
		return
	var controller := _ability_controller(_resolve_inv(node))
	var list_key := node.memory_key if node.memory_key != &"" else &"picked_enemies"
	var each_key := (
		node.for_each_bind_key if node.for_each_bind_key != &"" else &"picked_enemy"
	)
	var raw: Variant = _game_ctx.memory.get_referent(controller, list_key)
	var items: Array = []
	if raw is Array:
		items = raw as Array
	elif raw != null and str(raw) != "":
		items = [raw]
	for item in items:
		var eid := StringName(str(item))
		if eid == &"":
			continue
		_game_ctx.memory.set_referent(controller, each_key, eid)
		_last_step_enemy_id = eid
		node.children[0].provenance = node.provenance
		_run_node(node.children[0])


func _stamp_provenance(node: CompositionNode) -> void:
	if node.provenance == null:
		return
	_log.log(
		AhcEnums.LogCategory.ABILITY,
		"composition:provenance",
		node.provenance.to_log_dict()
	)


func _record_composition_step(node: CompositionNode, created: bool) -> void:
	if _game_ctx == null or _game_ctx.events == null:
		return
	var payload := {
		"created": created,
		"inv_id": node.inv_id,
		"card_id": node.card_id,
	}
	if node.kind == AhcEnums.CompositionNodeKind.ATOM:
		payload["atom"] = node.atom_name
	var rec := _game_ctx.events.append(
		AhcEnums.EventRecordKind.COMPOSITION_STEP,
		payload,
		_state.compute_state_hash() if _state else ""
	)
	if _game_ctx.stat_projections != null:
		_game_ctx.stat_projections.on_event(rec)


func _execute_atom(node: CompositionNode) -> bool:
	match node.atom_name:
		&"draw":
			if RestrictionEvaluator.blocks_draw(node.inv_id, _registrations):
				_log.log(AhcEnums.LogCategory.CARD, "composition:draw_blocked", {"inv": node.inv_id})
				return false
			var amount := maxi(node.draw_amount, 1)
			if _draw and _game_ctx:
				_draw.draw_cards(_game_ctx, node.inv_id, amount, [&"composition_draw"])
			else:
				_mutator.execute_draw_instruction(node.inv_id, amount)
			_log.log(AhcEnums.LogCategory.CARD, "composition:draw", {"inv": node.inv_id, "amount": amount})
			return true
		&"move_card":
			if node.to_slot != null:
				_mutator.move_card(node.card_id, node.to_slot)
				_log.log(AhcEnums.LogCategory.CARD, "composition:move_card", {"card": node.card_id})
				return true
			return false
		&"adjust_marker":
			if node.marker_slot != null:
				_mutator.adjust_marker(node.marker_slot, node.marker_delta)
				_log.log(
					AhcEnums.LogCategory.CARD,
					"composition:adjust_marker",
					{"delta": node.marker_delta}
				)
				return true
			return false
		&"set_flag":
			_mutator.set_flag(node.inv_id, node.flag_field, node.flag_value)
			_log.log(AhcEnums.LogCategory.CARD, "composition:set_flag", {"bearer": node.inv_id})
			return true
		&"reveal_to_controller":
			_mutator.reveal_to_controller(node.card_id, node.inv_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:reveal_to_controller",
				{"card": node.card_id, "controller": node.inv_id}
			)
			return true
		&"reveal_to_all":
			_mutator.reveal_to_all(node.card_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:reveal_to_all",
				{"card": node.card_id}
			)
			return true
		&"pop_deck_top":
			var card_id := _mutator.pop_deck_top(node.inv_id)
			if _game_ctx != null and _game_ctx.memory != null and card_id != &"":
				DrawInvestigatorComposition.append_pending(_game_ctx.memory, node.inv_id, card_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:pop_deck_top",
				{"inv": node.inv_id, "card": card_id}
			)
			return card_id != &""
		&"shuffle_discard_into_deck":
			if _mutator.deck_is_empty(node.inv_id) and not _mutator.discard_is_empty(node.inv_id):
				_mutator.shuffle_discard_into_deck(node.inv_id)
				_log.log(AhcEnums.LogCategory.CARD, "composition:shuffle_discard", {"inv": node.inv_id})
				return true
			return false
		&"commit_enter_hand":
			_mutator.commit_enter_hand(node.card_id, node.inv_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:commit_enter_hand",
				{"inv": node.inv_id, "card": node.card_id}
			)
			return true
		&"enter_threat_area":
			var entered := _mutator.commit_enter_threat_area(node.card_id, node.inv_id)
			if entered and _game_ctx != null and _game_ctx.triggered_abilities != null:
				_game_ctx.triggered_abilities.install_card(node.inv_id, node.card_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:enter_threat_area",
				{"inv": node.inv_id, "card": node.card_id}
			)
			return entered
		&"lose_all_resources", &"nest_lose_all_resources":
			return _execute_nest_lose_resources(node)
		&"commit_hidden_enter_hand":
			_mutator.commit_hidden_enter_hand(node.card_id, node.inv_id)
			if _game_ctx != null:
				EncounterPrivacy.register_leave_hand_restriction(
					_game_ctx, node.card_id, node.inv_id
				)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:commit_hidden_enter_hand",
				{"inv": node.inv_id, "card": node.card_id}
			)
			return true
		&"expose_hidden":
			_mutator.expose_hidden_card(node.card_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:expose_hidden",
				{"card": node.card_id}
			)
			return true
		&"spawn_encounter_enemy":
			if _game_ctx != null and _game_ctx.sequence_catalog != null:
				_game_ctx.sequence_catalog.nest(
					_game_ctx,
					&"seq.encounter.spawn",
					{
						"drawer_id": node.inv_id,
						"card_id": node.card_id,
						"from_hand": true,
					}
				)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:spawn_encounter_enemy",
				{"inv": node.inv_id, "card": node.card_id}
			)
			return true
		&"discard_encounter_from_hand":
			if _game_ctx != null:
				EncounterCardDiscard.discard_from_investigator_to_encounter_pile(
					_game_ctx, node.card_id, node.inv_id
				)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:discard_encounter_from_hand",
				{"inv": node.inv_id, "card": node.card_id}
			)
			return true
		&"cancel_pending":
			if _game_ctx != null and _game_ctx.effects != null:
				_game_ctx.effects.cancel_pending(node.pending_id)
				return node.pending_id != &""
			return false
		&"ignore_pending":
			if _game_ctx != null and _game_ctx.effects != null:
				_game_ctx.effects.ignore_pending(node.pending_id)
				return node.pending_id != &""
			return false
		&"interrupt":
			if _game_ctx != null and _game_ctx.effects != null and node.interrupt_target != null:
				if node.interrupt_mode == &"ignore":
					_game_ctx.effects.apply_interrupt_ignore(node.interrupt_target)
				else:
					_game_ctx.effects.apply_interrupt_cancel(node.interrupt_target)
				return true
			return false
		&"replace_pending":
			if _game_ctx != null and _game_ctx.effects != null and node.effect_request != null:
				_game_ctx.effects.register_replacement(
					node.pending_id,
					node.effect_request,
					node.source_ability_id
				)
				return node.pending_id != &""
			return false
		&"replace_instead":
			if (
				_game_ctx != null
				and _game_ctx.effects != null
				and node.replace_target != null
				and node.effect_request != null
			):
				_game_ctx.effects.apply_replace_instead(
					node.replace_target,
					node.effect_request,
					node.source_ability_id
				)
				return true
			return false
		&"resolve_pending":
			if _game_ctx != null and _game_ctx.effects != null:
				_game_ctx.effects.resolve_pending(node.pending_id)
				return node.pending_id != &""
			return false
		&"place_doom_nearest_enemy_without_doom", &"nest_place_doom":
			return _execute_nest_place_doom(node)
		&"place_doom_on_current_agenda", &"nest_mythos_place_doom":
			return _execute_nest_mythos_place_doom(node)
		&"place_clue_on_investigator_location", &"nest_place_clue":
			return _execute_nest_place_clue(node)
		&"nest_skill_test":
			return _execute_nest_skill_test(node)
		&"pick_option":
			return _execute_pick_option(node)
		&"nest_enemy_resolve_location":
			return _execute_nest_enemy_resolve_location(node)
		&"nest_enemy_move":
			return _execute_nest_enemy_move(node)
		&"nest_enemy_attack":
			return _execute_nest_enemy_attack(node)
		&"exhaust_card":
			return _execute_exhaust_card(node)
		&"exhaust_enemy":
			return _execute_exhaust_enemy(node)
		&"deal_damage_enemy":
			return _execute_deal_damage_enemy(node)
		&"disengage_enemy":
			return _execute_disengage_enemy(node)
		&"no_provoke_aoo":
			## 行动开始已挂限制类 SKIP_AOO；INIT_2B 已由原流程读取分支。resolve 体不再重复挂载。
			_log.log(AhcEnums.LogCategory.CARD, "composition:no_provoke_aoo", {
				"controller": node.inv_id,
			})
			return true
		&"suppress_auto_engage":
			return _execute_suppress_auto_engage(node)
		&"leave_clues_at_location":
			return _execute_leave_clues_at_location(node)
		&"eliminate":
			return _execute_eliminate(node)
		&"resign":
			## 兼容旧树：整段撤退；新编译应已是三步展开。
			return _execute_resign_inline(node)
		&"nest_resign":
			return _execute_nest_resign(node)
		&"pick_target", &"select":
			return _execute_pick_target(node)
		&"move_enemy_to":
			return _execute_move_enemy_to_inline(node)
		&"engage_target":
			return _execute_engage_target_inline(node)
		&"nest_enemy_move_to":
			return _execute_nest_enemy_move_to(node)
		&"nest_engage":
			return _execute_nest_engage(node)
		&"spend_clues_group":
			return _execute_spend_clues_group(node)
		&"nest_move_connecting":
			## 兼容旧单 Atom；新树应为 select + nest_move_to。
			return _execute_nest_move_connecting_legacy(node)
		&"nest_move_to":
			return _execute_nest_move_to(node)
		&"nest_gain_resource":
			return _execute_nest_gain_resource(node)
		&"take_horror", &"nest_take_horror", &"take_damage", &"nest_take_damage", &"nest_deal_damage", &"nest_damage":
			return _execute_nest_damage(node)
		&"nest_lose_resources":
			return _execute_nest_lose_resources(node)
		&"nest_heal":
			return _execute_nest_heal(node)
		&"nest_lose_action":
			return _execute_nest_lose_action(node)
		&"nest_effect_register":
			return _execute_nest_effect_register(node)
		&"nest_effect_unregister":
			return _execute_nest_effect_unregister(node)
		&"nest_discard_card":
			return _execute_nest_discard_card(node)
		&"nest_discard_from_hand":
			## 兼容旧 atom 名：等同 nest_discard_card + from=hand。
			return _execute_nest_discard_card(node)
		&"nest_draw_investigator":
			return _execute_nest_draw_investigator(node)
		&"discard_all_enemies_in_play":
			return ScenarioCompositionAtoms.discard_all_enemies_in_play(_game_ctx)
		&"put_locations_into_play":
			return ScenarioCompositionAtoms.put_locations_into_play(
				_game_ctx, node.location_ids
			)
		&"spawn_set_aside_enemy_at":
			return ScenarioCompositionAtoms.spawn_set_aside_enemy_at(
				_game_ctx, node.definition_id, node.location_target
			)
		&"attach_set_aside_to_host":
			return ScenarioCompositionAtoms.attach_set_aside_to_host(
				_game_ctx, node.definition_id, node.card_id, node.atom_count
			)
		&"attach_limbo_to_nearest_location_without", &"nest_attach":
			return _execute_nest_attach(node)
		&"discard_set_aside_to_encounter_discard":
			return ScenarioCompositionAtoms.discard_set_aside_to_encounter_discard(
				_game_ctx, node.definition_id, node.atom_count
			)
		&"nest_scenario_resolution":
			var resolution := node.scenario_resolution
			if resolution <= 0 and node.definition_id != &"":
				resolution = ScenarioResolutionParser.parse(
					CardRegistry.back_text(node.definition_id)
				)
			return ScenarioCompositionAtoms.trigger_scenario_resolution(
				_game_ctx, resolution, node.definition_id
			)
		&"defeat_surviving_non_resigned":
			return ScenarioCompositionAtoms.defeat_surviving_non_resigned(
				_game_ctx, node.marker_delta, node.draw_amount
			)
		&"heal_and_set_aside_enemy":
			return ScenarioCompositionAtoms.heal_and_set_aside_enemy(
				_game_ctx, node.definition_id
			)
		&"remove_location_from_game":
			return ScenarioCompositionAtoms.remove_location_from_game(
				_game_ctx, node.card_id
			)
		&"put_story_asset_from_set_aside":
			return ScenarioCompositionAtoms.put_story_asset_from_set_aside(
				_game_ctx, node.definition_id, node.location_target
			)
		&"place_clues_on_location":
			return ScenarioCompositionAtoms.place_clues_on_location(
				_game_ctx, node.location_target, node.atom_count
			)
		&"lead_search_draw_encounter_copies":
			return ScenarioCompositionAtoms.lead_search_draw_encounter_copies(
				_game_ctx, node.definition_id, bool(node.flag_value)
			)
		&"lead_draw_topmost_encounter_discard_copy":
			return ScenarioCompositionAtoms.lead_draw_topmost_encounter_discard_copy(
				_game_ctx, node.definition_id
			)
		_:
			push_warning("CompositionExecutor: unknown atom %s" % node.atom_name)
			return false


func _execute_choice(node: CompositionNode) -> void:
	if node.children.is_empty():
		return
	var indices: Array[int] = []
	if _game_ctx != null:
		var sim := GameSimulator.from_context(_game_ctx)
		if node.choice_must:
			indices = _dry_runner.filter_executable_indices(node, sim)
		else:
			for i in node.children.size():
				indices.append(i)
	else:
		for i in node.children.size():
			indices.append(i)
	if indices.is_empty():
		_log.log(
			AhcEnums.LogCategory.CARD,
			"composition:choice_skip",
			{"must": node.choice_must, "prompt": node.choice_prompt_id}
		)
		return
	var pick_idx: int = indices[0]
	if indices.size() > 1:
		var option_ids: Array = []
		for idx in indices:
			var oid: StringName = (
				node.choice_option_ids[idx]
				if idx < node.choice_option_ids.size()
				else StringName("opt_%d" % idx)
			)
			option_ids.append(oid)
		var picked: Variant = null
		if _game_ctx != null and _game_ctx.interaction != null:
			picked = _game_ctx.interaction.ask_pick_option(
				option_ids,
				node.inv_id,
				node.choice_prompt_id,
				_game_ctx
			)
		if picked == null:
			pick_idx = indices[0]
		else:
			pick_idx = indices[0]
			for j in indices.size():
				var idx_at: int = indices[j]
				var oid_at: StringName = (
					node.choice_option_ids[idx_at]
					if idx_at < node.choice_option_ids.size()
					else StringName("opt_%d" % idx_at)
				)
				if oid_at == picked or str(oid_at) == str(picked):
					pick_idx = idx_at
					break
	var branch: CompositionNode = node.children[pick_idx]
	if branch != null:
		branch.provenance = node.provenance
		_run_node(branch)


## Optional / may：body 可执行才 ask；默认跳过；是 → 跑子树（16 §7.2）。
func _execute_optional(node: CompositionNode) -> void:
	if node.children.is_empty():
		return
	var body: CompositionNode = node.children[0]
	if body == null:
		return
	var executable := true
	if _game_ctx != null:
		var sim := GameSimulator.from_context(_game_ctx)
		executable = _dry_runner.simulate(body, sim).has_any_created
	if not executable:
		_log.log(
			AhcEnums.LogCategory.CARD,
			"composition:optional_skip",
			{"reason": &"fizzle", "prompt": node.choice_prompt_id}
		)
		_last_step_created = false
		return
	var use := false
	if _game_ctx != null and _game_ctx.interaction != null:
		use = _game_ctx.interaction.ask_optional_effect(
			node.inv_id,
			node.choice_prompt_id,
			_game_ctx,
			false
		)
	if node.memory_key != &"" and _game_ctx != null and _game_ctx.memory != null:
		_game_ctx.memory.set_referent(node.inv_id, node.memory_key, use)
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:optional",
		{"use": use, "prompt": node.choice_prompt_id, "bind": node.memory_key}
	)
	if not use:
		_last_step_created = false
		return
	body.provenance = node.provenance
	_run_node(body)


func _execute_repeat(node: CompositionNode) -> void:
	if node.children.is_empty():
		return
	var count := _resolve_repeat_count(node)
	for _i in count:
		var body: CompositionNode = node.children[0]
		if body != null:
			body.provenance = node.provenance
			_run_node(body)


func _resolve_repeat_count(node: CompositionNode) -> int:
	if node.repeat_count_source == &"last_skill_test_fail_by":
		return _last_skill_test_fail_by
	if node.repeat_count_fixed > 0:
		return node.repeat_count_fixed
	return 0


## PI：只选 option id（技能类型等）→ RulesMemory；不展开子树。
func _execute_pick_option(node: CompositionNode) -> bool:
	if node.choice_option_ids.is_empty():
		return false
	var controller := _ability_controller(_resolve_inv(node))
	var picked: Variant = node.choice_option_ids[0]
	if _game_ctx != null and _game_ctx.interaction != null:
		## 唯一选项也走 ask → 默认自动选用并记 used_default。
		var ask: Variant = _game_ctx.interaction.ask_pick_option(
			node.choice_option_ids,
			controller,
			node.choice_prompt_id,
			_game_ctx
		)
		if ask != null and str(ask) != "":
			picked = ask
	var key := node.memory_key if node.memory_key != &"" else &"picked_option"
	if _game_ctx != null and _game_ctx.memory != null and controller != &"":
		_game_ctx.memory.set_referent(controller, key, StringName(str(picked)))
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:pick_option",
		{"prompt": node.choice_prompt_id, "picked": picked, "bind": key}
	)
	return true


func _execute_nest_skill_test(node: CompositionNode) -> bool:
	if _game_ctx == null or _game_ctx.sequence_catalog == null:
		return false
	var inv_id := _resolve_inv(node)
	if inv_id == &"":
		return false
	var skill := _resolve_test_skill(node, inv_id)
	var difficulty := _resolve_test_difficulty(node, inv_id)
	var flow_id := SkillTestFlowHandlers.flow_id_for_skill(skill)
	var result := _game_ctx.sequence_catalog.nest(
		_game_ctx,
		flow_id,
		{
			"inv_id": node.inv_id,
			"skill": skill,
			"difficulty": difficulty,
			"card_id": node.card_id,
			"st7_plan": node.st7_plan,
		}
	)
	_last_skill_test_fail_by = int(result.get("fail_by", 0))
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:nest_skill_test",
		{
			"flow": flow_id,
			"inv": node.inv_id,
			"skill": skill,
			"skill_spec": node.test_skill_spec,
			"difficulty": difficulty,
			"difficulty_source": node.test_difficulty_source,
			"fail_by": _last_skill_test_fail_by,
			"success": bool(result.get("success", false)),
		}
	)
	return bool(result.get("ok", false))


## 空=用 test_skill；`memory:picked_skill` 或字面 willpower/…。
func _resolve_test_skill(node: CompositionNode, inv_id: StringName) -> AhcEnums.SkillType:
	var spec := node.test_skill_spec
	if spec == &"":
		return node.test_skill
	var raw := str(spec)
	if raw.begins_with("memory:"):
		var mem_key := StringName(raw.substr(7))
		var controller := _ability_controller(inv_id)
		if _game_ctx != null and _game_ctx.memory != null and controller != &"":
			var from_mem: Variant = _game_ctx.memory.get_referent(controller, mem_key)
			if from_mem != null and str(from_mem) != "":
				return _skill_type_from_id(StringName(str(from_mem)))
		return node.test_skill
	return _skill_type_from_id(spec)


func _skill_type_from_id(skill_id: StringName) -> AhcEnums.SkillType:
	match skill_id:
		&"intellect":
			return AhcEnums.SkillType.INTELLECT
		&"combat":
			return AhcEnums.SkillType.COMBAT
		&"agility":
			return AhcEnums.SkillType.AGILITY
		_:
			return AhcEnums.SkillType.WILLPOWER


## 固定难度或动态源（如 hand_count = 手牌张数）。
func _resolve_test_difficulty(node: CompositionNode, inv_id: StringName) -> int:
	if node.test_difficulty_source == &"hand_count":
		if _state == null:
			return 0
		var inv := _state.registry.get_investigator(inv_id)
		if inv == null:
			return 0
		return maxi(inv.hand.size(), 0)
	return maxi(node.test_difficulty, 0)


func _execute_nest_enemy_resolve_location(node: CompositionNode) -> bool:
	if _game_ctx == null or _game_ctx.sequence_catalog == null:
		return false
	var target := node.location_target if node.location_target != &"" else &"drawer_location"
	var result := _game_ctx.sequence_catalog.nest(
		_game_ctx,
		&"seq.enemy.resolve_location",
		{"target": target, "drawer_id": node.inv_id, "controller_id": node.inv_id}
	)
	_last_resolved_location = result.get("location_tag", &"") as StringName
	return bool(result.get("ok", false)) and _last_resolved_location != &""


func _execute_nest_enemy_move(node: CompositionNode) -> bool:
	if _game_ctx == null or _game_ctx.sequence_catalog == null:
		return false
	if _last_resolved_location == &"":
		return false
	var enemy_id := NearestEnemyResolver.pick_nearest_enemy_toward_investigator(
		_game_ctx, node.inv_id, node.trait_exclude, false
	)
	if enemy_id == &"":
		return false
	var result := _game_ctx.sequence_catalog.nest(
		_game_ctx,
		&"seq.enemy.move",
		{
			"enemy_id": enemy_id,
			"target_location": _last_resolved_location,
			"steps": 1,
		}
	)
	_last_step_enemy_id = enemy_id
	_last_step_engaged_investigator = result.get("engaged_investigator", &"") as StringName
	_last_step_created = enemy_id != &""
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:nest_enemy_move",
		{
			"enemy": _last_step_enemy_id,
			"location": _last_resolved_location,
			"engaged": _last_step_engaged_investigator,
			"moved": bool(result.get("moved", false)),
		}
	)
	return _last_step_created


func _execute_nest_enemy_attack(node: CompositionNode) -> bool:
	if _game_ctx == null or _game_ctx.sequence_catalog == null:
		return false
	var enemy_id := node.enemy_ref_id if node.enemy_ref_id != &"" else _last_step_enemy_id
	var target := (
		node.target_investigator_id
		if node.target_investigator_id != &""
		else _last_step_engaged_investigator
	)
	if enemy_id == &"" or target == &"":
		return false
	var result := _game_ctx.sequence_catalog.nest(
		_game_ctx,
		&"seq.enemy.attack",
		{"enemy_id": enemy_id, "target_investigator": target, "exhaust_after": false}
	)
	return bool(result.get("ok", false))


func _execute_exhaust_card(node: CompositionNode) -> bool:
	if _state == null or node.card_id == &"":
		return false
	var card := _state.registry.get_card(node.card_id)
	if card == null or card.exhausted:
		return false
	card.exhausted = true
	_log.log(AhcEnums.LogCategory.CARD, "composition:exhaust_card", {"card": node.card_id})
	return true


## L0 · 横置敌人；已横置则无 CREATED（目标 V / Grimoire Target）。
func _execute_exhaust_enemy(node: CompositionNode) -> bool:
	if _game_ctx == null or _game_ctx.enemy == null:
		return false
	var inv_id := _ability_controller(_resolve_inv(node))
	var enemy_id := _resolve_enemy_spec(node, inv_id)
	if enemy_id == &"":
		return false
	var enemy := _state.registry.get_enemy(enemy_id) if _state != null else null
	if enemy == null or enemy.exhausted:
		return false
	var result := _game_ctx.enemy.set_enemy_exhausted(_game_ctx, enemy_id, true, false)
	var ok := bool(result.get("ok", false)) and enemy.exhausted
	if ok:
		_last_step_enemy_id = enemy_id
		_log.log(
			AhcEnums.LogCategory.CARD,
			"composition:exhaust_enemy",
			{"enemy": enemy_id, "inv": inv_id}
		)
	return ok


func _execute_deal_damage_enemy(node: CompositionNode) -> bool:
	if _game_ctx == null:
		return false
	var inv_id := _ability_controller(_resolve_inv(node))
	var enemy_id := _resolve_enemy_spec(node, inv_id)
	if enemy_id == &"":
		return false
	var amount := maxi(node.marker_delta, 1)
	var result := EnemyDefeatResolver.deal_damage(_game_ctx, enemy_id, amount)
	var ok := bool(result.get("ok", false))
	if ok:
		_last_step_enemy_id = enemy_id
		_log.log(
			AhcEnums.LogCategory.CARD,
			"composition:deal_damage_enemy",
			{"enemy": enemy_id, "amount": amount}
		)
	return ok


func _execute_disengage_enemy(node: CompositionNode) -> bool:
	if _game_ctx == null or _game_ctx.enemy == null:
		return false
	var inv_id := _ability_controller(_resolve_inv(node))
	var enemy_id := _resolve_enemy_spec(node, inv_id)
	if enemy_id == &"":
		return false
	var enemy := _state.registry.get_enemy(enemy_id) if _state != null else null
	if enemy == null or enemy.engaged_with == &"":
		return false
	var result := _game_ctx.enemy.disengage(_game_ctx, enemy_id, false, false)
	var ok := bool(result.get("ok", false))
	if ok:
		_last_step_enemy_id = enemy_id
		_log.log(
			AhcEnums.LogCategory.CARD,
			"composition:disengage_enemy",
			{"enemy": enemy_id, "inv": inv_id}
		)
	return ok


## Resign 第一步：线索留在所在地点。
func _execute_leave_clues_at_location(node: CompositionNode) -> bool:
	var inv_id := _ability_controller(_resolve_inv(node))
	if inv_id == &"" or _game_ctx == null or _game_ctx.state == null:
		return false
	var inv := _game_ctx.state.registry.get_investigator(inv_id)
	if inv == null or inv.eliminated:
		return false
	var clues_left := inv.clues_on_card
	if clues_left > 0 and inv.location_tag != &"":
		var loc := _game_ctx.state.registry.get_location(inv.location_tag)
		if loc != null:
			loc.clues += clues_left
		inv.clues_on_card = 0
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:leave_clues_at_location",
		{"inv": inv_id, "clues": clues_left}
	)
	return true


## Resign 第三步：淘汰清理（威胁区/手牌隐私遭遇 + ELIMINATED）。
func _execute_eliminate(node: CompositionNode) -> bool:
	var inv_id := _ability_controller(_resolve_inv(node))
	if inv_id == &"" or _game_ctx == null:
		return false
	var result := InvestigatorElimination.eliminate(_game_ctx, inv_id)
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:eliminate",
		{"inv": inv_id, "ok": bool(result.get("eliminated", false))}
	)
	return bool(result.get("eliminated", false))


## 兼容旧单 Atom 撤退（无新时点锚）。
func _execute_resign_inline(node: CompositionNode) -> bool:
	var inv_id := _ability_controller(_resolve_inv(node))
	if inv_id == &"" or _game_ctx == null:
		return false
	var result := InvestigatorElimination.resign(_game_ctx, inv_id)
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:resign",
		{"inv": inv_id, "ok": bool(result.get("ok", false))}
	)
	return bool(result.get("ok", false))


## 仅 §4.0.5「是」：nest `seq.effect.resign`。
func _execute_nest_resign(node: CompositionNode) -> bool:
	var inv_id := _ability_controller(_resolve_inv(node))
	if inv_id == &"" or _game_ctx == null:
		return false
	var result: Dictionary = {}
	if (
		_game_ctx.sequence_catalog != null
		and _game_ctx.sequence_catalog.has_flow(&"seq.effect.resign")
	):
		result = _game_ctx.sequence_catalog.nest(
			_game_ctx, &"seq.effect.resign", {"investigator_id": inv_id}
		)
	else:
		result = InvestigatorElimination.resign(_game_ctx, inv_id)
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:nest_resign",
		{"inv": inv_id, "ok": bool(result.get("ok", false))}
	)
	return bool(result.get("ok", false))


## PI 有限期确认 → ChoiceBind 写入 RulesMemory（21-selection-spec）。
func _execute_pick_target(node: CompositionNode) -> bool:
	if _game_ctx == null or _state == null:
		return false
	var inv_id := _ability_controller(_resolve_inv(node))
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return false
	var spec := _selection_spec_of(node)
	if spec == null or spec.filter == null:
		return false
	var candidates := CandidateEnumerator.enumerate(
		spec.filter, _game_ctx, inv_id, node.card_id
	)
	## V：逐候选 dry-run；多选时 tail 仍按单数 bind_key 试（与单选同源）。
	var v_bind := spec.bind_key
	if (
		spec.choice_kind == AhcEnums.ChoiceKind.PICK_MULTI
		and spec.bind_shape == &"entity_list"
	):
		## 列表尾树常用 memory:picked_enemy；V 注入单数键。
		v_bind = &"picked_enemy" if spec.bind_key == &"picked_enemies" else spec.bind_key
	if (
		not spec.skip_viability
		and spec.viability_tail != null
		and not candidates.is_empty()
	):
		candidates = CandidateViability.filter_viable(
			candidates, _game_ctx, inv_id, v_bind, spec.viability_tail
		)
	if candidates.size() < spec.min_picks:
		return false
	if candidates.is_empty() and spec.min_picks > 0:
		return false
	var picked: Variant = null
	if _game_ctx.interaction != null:
		picked = _game_ctx.interaction.ask_selection(spec, candidates, inv_id, _game_ctx)
	else:
		picked = (
			candidates[0]
			if spec.max_picks <= 1
			else candidates.slice(0, mini(spec.max_picks, candidates.size()))
		)
	if picked == null:
		return false
	## min=0 选空列表：步成功但无 CREATED 目标（仍写 bind=[]）。
	if picked is Array and (picked as Array).is_empty() and spec.min_picks <= 0:
		_apply_choice_bind(inv_id, spec, picked)
		_last_step_created = false
		return true
	if picked is Array and (picked as Array).size() < spec.min_picks:
		return false
	_apply_choice_bind(inv_id, spec, picked)
	if typeof(picked) == TYPE_STRING_NAME or typeof(picked) == TYPE_STRING:
		_last_step_enemy_id = StringName(str(picked))
	elif picked is Array and not (picked as Array).is_empty():
		_last_step_enemy_id = StringName(str((picked as Array)[0]))
	_last_step_created = true
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:select",
		{
			"inv": inv_id,
			"kind": spec.choice_kind,
			"filter": spec.filter.preset if spec.filter.preset != &"" else spec.filter.at,
			"picked": picked,
			"bind": spec.bind_key,
			"min": spec.min_picks,
			"max": spec.max_picks,
		}
	)
	return true


func _selection_spec_of(node: CompositionNode) -> SelectionSpec:
	if node.selection_spec != null:
		return node.selection_spec
	var filter_id := node.target_filter if node.target_filter != &"" else &"enemy_at_connecting"
	var mem := node.memory_key if node.memory_key != &"" else &"picked_enemy"
	var prompt := node.choice_prompt_id if node.choice_prompt_id != &"" else &"pick:target"
	return SelectionSpec.pick_entity(
		CandidateFilter.from_preset(filter_id), prompt, mem
	)


func _apply_choice_bind(
	controller_id: StringName, spec: SelectionSpec, picked: Variant
) -> void:
	if _game_ctx == null or _game_ctx.memory == null or spec == null:
		return
	var key := spec.bind_key if spec.bind_key != &"" else &"picked"
	match spec.bind_shape:
		&"entity_list", &"order":
			var list: Array[StringName] = []
			if picked is Array:
				for item in picked:
					list.append(StringName(str(item)))
			elif picked != null:
				list.append(StringName(str(picked)))
			_game_ctx.memory.set_referent(controller_id, key, list)
		&"bool":
			_game_ctx.memory.set_referent(controller_id, key, bool(picked))
		_:
			## entity / option_id
			if picked is Array and not (picked as Array).is_empty():
				_game_ctx.memory.set_referent(
					controller_id, key, StringName(str((picked as Array)[0]))
				)
			else:
				_game_ctx.memory.set_referent(controller_id, key, StringName(str(picked)))


## 同帧内联移敌（L0 location_tag；不自动交战、不压栈）。
func _execute_move_enemy_to_inline(node: CompositionNode) -> bool:
	if _game_ctx == null or _state == null:
		return false
	var inv_id := _ability_controller(_resolve_inv(node))
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return false
	var enemy_id := _resolve_enemy_spec(node, inv_id)
	if enemy_id == &"":
		return false
	var dest := _resolve_location_spec(node, inv)
	if dest == &"":
		return false
	var enemy := _state.registry.get_enemy(enemy_id)
	if enemy == null:
		return false
	enemy.location_tag = dest
	_last_step_enemy_id = enemy_id
	_last_step_created = true
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:move_enemy_to",
		{"enemy": enemy_id, "location": dest}
	)
	return true


## 同帧内联交战（L0 apply_engage）。
func _execute_engage_target_inline(node: CompositionNode) -> bool:
	if _game_ctx == null or _game_ctx.enemy == null:
		return false
	var inv_id := _ability_controller(_resolve_inv(node))
	if inv_id == &"":
		return false
	var enemy_id := _resolve_enemy_spec(node, inv_id)
	if enemy_id == &"":
		return false
	var enemy := _state.registry.get_enemy(enemy_id)
	var inv := _state.registry.get_investigator(inv_id)
	if enemy == null or inv == null:
		return false
	if not enemy.is_at_location(inv.location_tag):
		return false
	_game_ctx.enemy.apply_engage(enemy_id, inv_id, true, _game_ctx)
	_last_step_enemy_id = enemy_id
	_last_step_engaged_investigator = inv_id
	_last_step_created = true
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:engage_target",
		{"enemy": enemy_id, "inv": inv_id}
	)
	return true


## 仅 §4.0.5「是」：nest `seq.enemy.move`。
func _execute_nest_enemy_move_to(node: CompositionNode) -> bool:
	if _game_ctx == null or _state == null or _game_ctx.sequence_catalog == null:
		return false
	var inv_id := _ability_controller(_resolve_inv(node))
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return false
	var enemy_id := _resolve_enemy_spec(node, inv_id)
	if enemy_id == &"":
		return false
	var dest := _resolve_location_spec(node, inv)
	if dest == &"":
		return false
	var result := _game_ctx.sequence_catalog.nest(
		_game_ctx,
		&"seq.enemy.move",
		{
			"enemy_id": enemy_id,
			"target_location": dest,
			"steps": 1,
			"auto_engage": node.auto_engage,
		}
	)
	_last_step_enemy_id = enemy_id
	_last_step_engaged_investigator = result.get("engaged_investigator", &"") as StringName
	_last_step_created = bool(result.get("ok", false))
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:nest_enemy_move_to",
		{
			"enemy": enemy_id,
			"location": dest,
			"auto_engage": node.auto_engage,
			"engaged": _last_step_engaged_investigator,
		}
	)
	return _last_step_created


## nest `seq.engage`（mode=effect 明示交战控制者）。
func _execute_nest_engage(node: CompositionNode) -> bool:
	if _game_ctx == null or _game_ctx.sequence_catalog == null:
		return false
	var inv_id := _ability_controller(_resolve_inv(node))
	if inv_id == &"":
		return false
	var enemy_id := _resolve_enemy_spec(node, inv_id)
	if enemy_id == &"":
		return false
	## 卡面 nest 与行动交战同属效果交战；历史 engage_mode=action 亦收成 effect。
	var mode := EngageFlow.MODE_EFFECT
	if node.engage_mode == EngageFlow.MODE_AUTO:
		mode = EngageFlow.MODE_AUTO
	var placement := (
		node.engage_placement if node.engage_placement != &""
		else EngageFlow.PLACEMENT_ENTER_THREAT
	)
	var require_same := placement != EngageFlow.PLACEMENT_GRANT
	var result := _game_ctx.sequence_catalog.nest(
		_game_ctx,
		&"seq.engage",
		{
			"mode": mode,
			"placement": placement,
			"require_same_location": require_same,
			"enemy_id": enemy_id,
			"investigator_id": inv_id,
		}
	)
	## 明示交战完成：清掉未在 auto-engage 入口读掉的抑制限制。
	if _game_ctx.registrations != null:
		_game_ctx.registrations.clear_suppress_auto_engage(enemy_id)
	_last_step_enemy_id = enemy_id
	_last_step_engaged_investigator = inv_id if bool(result.get("ok", false)) else &""
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:nest_engage",
		{"enemy": enemy_id, "inv": inv_id, "mode": mode, "ok": bool(result.get("ok", false))}
	)
	return bool(result.get("ok", false))


## Register SUPPRESS_AUTO_ENGAGE（限制类）经 `seq.effect.register`；auto-engage 入口读取后分支。
func _execute_suppress_auto_engage(node: CompositionNode) -> bool:
	if _game_ctx == null or _game_ctx.registrations == null:
		return false
	var inv_id := _ability_controller(_resolve_inv(node))
	var enemy_id := _resolve_enemy_spec(node, inv_id)
	if enemy_id == &"":
		return false
	if _game_ctx.registrations.has_suppress_auto_engage(enemy_id):
		return true
	var template := RegistrationTemplate.suppress_auto_engage_until_fired(enemy_id)
	template.controller_id = inv_id
	var ok := _register_via_effect_seq(template)
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:suppress_auto_engage",
		{"enemy": enemy_id, "via": &"seq.effect.register", "ok": ok}
	)
	return ok


func _resolve_enemy_spec(node: CompositionNode, controller_id: StringName) -> StringName:
	var spec := node.enemy_ref_id
	if spec == &"" or spec == &"memory:picked_enemy":
		var key := node.memory_key if node.memory_key != &"" else &"picked_enemy"
		if _game_ctx != null and _game_ctx.memory != null:
			var from_mem: Variant = _game_ctx.memory.get_referent(controller_id, key)
			if from_mem != null and str(from_mem) != "":
				return from_mem as StringName
		return _last_step_enemy_id
	if str(spec).begins_with("memory:"):
		var mem_key := StringName(str(spec).substr(7))
		if _game_ctx != null and _game_ctx.memory != null:
			var v: Variant = _game_ctx.memory.get_referent(controller_id, mem_key)
			if v != null and str(v) != "":
				return v as StringName
		return _last_step_enemy_id
	return spec


func _resolve_location_spec(node: CompositionNode, inv: InvestigatorState) -> StringName:
	var spec := node.location_target
	if str(spec).begins_with("memory:"):
		var mem_key := StringName(str(spec).substr(7))
		var controller := _ability_controller(_resolve_inv(node))
		if controller == &"" and inv != null:
			controller = inv.id
		if _game_ctx != null and _game_ctx.memory != null and controller != &"":
			var from_mem: Variant = _game_ctx.memory.get_referent(controller, mem_key)
			if from_mem != null and str(from_mem) != "":
				return StringName(str(from_mem))
		return &""
	match spec:
		&"source_location", &"":
			return _resolve_source_location(node, inv)
		&"controller_location":
			return inv.location_tag if inv != null else &""
		_:
			if _state != null and _state.registry.get_location(spec) != null:
				return spec
			return _resolve_source_location(node, inv)


func _resolve_source_location(node: CompositionNode, inv: InvestigatorState) -> StringName:
	if node.card_id != &"":
		var card := _state.registry.get_card(node.card_id)
		if card != null:
			if _state.registry.get_location(card.id.instance_id) != null:
				return card.id.instance_id
			if _state.registry.get_location(card.id.definition_id) != null:
				return card.id.definition_id
	if inv != null:
		return inv.location_tag
	return &""


## 群体花费线索：按玩家顺序各出 1，直至凑够总量（交互分配后补）。
func _execute_spend_clues_group(node: CompositionNode) -> bool:
	if _game_ctx == null or _state == null:
		return false
	var base := maxi(node.marker_delta, 1)
	var need := base
	if bool(node.flag_value):
		need = PerInvestigatorScale.scale(_state, base)
	var spent := 0
	var order: Array = []
	if _game_ctx != null and _game_ctx.framework != null and not _game_ctx.framework.player_order.is_empty():
		order = _game_ctx.framework.player_order.duplicate()
	else:
		order = _state.registry.all_investigator_ids()
	for inv_id in order:
		if spent >= need:
			break
		var inv := _state.registry.get_investigator(inv_id)
		if inv == null or inv.eliminated or inv.resigned or inv.clues_on_card <= 0:
			continue
		var take := mini(1, mini(inv.clues_on_card, need - spent))
		inv.clues_on_card -= take
		spent += take
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:spend_clues_group",
		{"need": need, "spent": spent}
	)
	return spent >= need


## 旧单 Atom：内嵌选地点（仅兼容；新编译勿用）。
func _execute_nest_move_connecting_legacy(node: CompositionNode) -> bool:
	if _game_ctx == null or _state == null:
		return false
	var inv_id := _resolve_inv(node)
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null or inv.location_tag == &"":
		return false
	var current := _state.registry.get_location(inv.location_tag)
	if current == null:
		return false
	var candidates: Array[StringName] = []
	for conn in current.connections:
		candidates.append(conn)
	if candidates.is_empty():
		return false
	var dest_id: StringName = candidates[0]
	if _game_ctx.interaction != null:
		var picked: Variant = _game_ctx.interaction.ask_pick_target(
			candidates, inv_id, &"pick:move_connecting", _game_ctx
		)
		if picked != null:
			dest_id = StringName(str(picked))
	return _perform_investigator_move(inv_id, dest_id)


func _execute_nest_move_to(node: CompositionNode) -> bool:
	if _game_ctx == null or _state == null:
		return false
	var inv_id := _resolve_inv(node)
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return false
	var dest_id := _resolve_location_spec(node, inv)
	if dest_id == &"":
		return false
	return _perform_investigator_move(inv_id, dest_id)


func _perform_investigator_move(inv_id: StringName, dest_id: StringName) -> bool:
	if _game_ctx == null or _state == null or _game_ctx.skill_tests == null:
		return false
	var resolver := BasicActionResolver.new(_state, _game_ctx.skill_tests)
	var move_result := resolver.move(_game_ctx, inv_id, {"destination_id": dest_id})
	if not bool(move_result.get("ok", false)):
		return false
	EngageFlow.nest_after_area_change(_game_ctx, dest_id)
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:nest_move_to",
		{"inv": inv_id, "destination": dest_id}
	)
	return true


func _execute_nest_gain_resource(node: CompositionNode) -> bool:
	if _game_ctx == null or _game_ctx.sequence_catalog == null:
		return false
	var inv_id := _ability_controller(_resolve_inv(node))
	if inv_id == &"":
		return false
	var amount := maxi(node.marker_delta, 1)
	var result := _game_ctx.sequence_catalog.nest(
		_game_ctx,
		&"seq.effect.gain_resource",
		{
			"controller_id": inv_id,
			"base_amount": amount,
			"source_tags": [&"card_ability"],
		}
	)
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:nest_gain_resource",
		{"inv": inv_id, "amount": int(result.get("amount", amount))}
	)
	return int(result.get("amount", 0)) > 0 or amount > 0


func _execute_nest_damage(node: CompositionNode) -> bool:
	var inv_id := _ability_controller(_resolve_inv(node))
	if inv_id == &"" and node.location_target == &"":
		return false
	var target := node.location_target if node.location_target != &"" else &"controller"
	var kind := node.definition_id if node.definition_id == &"horror" else &"damage"
	## 兼容旧 atom 名：take_horror / nest_take_horror 未写 definition_id 时仍为 horror。
	if (
		kind != &"horror"
		and (node.atom_name == &"take_horror" or node.atom_name == &"nest_take_horror")
	):
		kind = &"horror"
	var amount := maxi(node.marker_delta, 1)
	if bool(node.flag_value) and _state != null:
		amount = PerInvestigatorScale.scale(_state, amount)
	var enemy_id := node.enemy_ref_id
	if target == &"enemy_at_controller_location" and enemy_id == &"":
		enemy_id = _pick_enemy_at_controller_location(inv_id)
		target = &"enemy"
	var result := _nest_or_direct(
		&"seq.effect.damage",
		{
			"controller_id": inv_id,
			"kind": kind,
			"amount": amount,
			"direct": node.is_direct,
			"target": target,
			"source": node.card_id,
			"card_id": node.card_id,
			"enemy_id": enemy_id,
		}
	)
	if result.is_empty() and _mutator != null and target == &"controller":
		if kind == &"horror":
			_mutator.take_horror(inv_id, amount)
		else:
			_mutator.adjust_marker(
				MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.DAMAGE),
				amount
			)
		return true
	return bool(result.get("ok", false))


func _pick_enemy_at_controller_location(inv_id: StringName) -> StringName:
	if _state == null:
		return &""
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null or inv.location_tag == &"":
		return &""
	var candidates: Array[StringName] = []
	for enemy_id in _state.registry.all_enemy_ids():
		var enemy := _state.registry.get_enemy(enemy_id)
		if enemy != null and enemy.location_tag == inv.location_tag:
			candidates.append(enemy_id)
	if candidates.is_empty():
		return &""
	if candidates.size() == 1:
		return candidates[0]
	if _game_ctx != null and _game_ctx.interaction != null:
		var chosen: Variant = _game_ctx.interaction.ask_pick_target(
			candidates, inv_id, &"pick:enemy_at_location", _game_ctx
		)
		if chosen != null:
			return chosen as StringName
	return candidates[0]


func _execute_nest_lose_resources(node: CompositionNode) -> bool:
	var inv_id := _ability_controller(_resolve_inv(node))
	if inv_id == &"":
		return false
	var all_mode := (
		node.definition_id == &"all"
		or node.atom_name == &"lose_all_resources"
		or node.atom_name == &"nest_lose_all_resources"
	)
	var params := {"controller_id": inv_id, "all": all_mode}
	if not all_mode:
		params["amount"] = maxi(node.marker_delta, 1)
	return bool(_nest_or_direct(&"seq.effect.lose_resources", params).get("ok", false))


func _execute_nest_heal(node: CompositionNode) -> bool:
	var inv_id := _ability_controller(_resolve_inv(node))
	if inv_id == &"":
		return false
	var kind := &"damage"
	if node.marker_slot != null and node.marker_slot.kind == AhcEnums.MarkerKind.HORROR_TAKEN:
		kind = &"horror"
	return bool(
		_nest_or_direct(
			&"seq.effect.heal",
			{"controller_id": inv_id, "kind": kind, "amount": maxi(node.marker_delta, 1)}
		).get("ok", false)
	)


func _execute_nest_lose_action(node: CompositionNode) -> bool:
	var inv_id := _ability_controller(_resolve_inv(node))
	if inv_id == &"":
		return false
	return bool(
		_nest_or_direct(
			&"seq.effect.lose_action",
			{"controller_id": inv_id, "amount": maxi(node.marker_delta, 1)}
		).get("ok", false)
	)


func _execute_nest_place_doom(node: CompositionNode) -> bool:
	var inv_id := _ability_controller(_resolve_inv(node))
	var target := node.place_doom_target
	if target == &"":
		target = &"nearest_enemy_without_doom"
	return bool(
		_nest_or_direct(
			&"seq.effect.place_doom",
			{
				"controller_id": inv_id,
				"drawer_id": inv_id,
				"origin_id": inv_id,
				"card_id": node.card_id,
				"target": target,
				"amount": maxi(node.marker_delta, 1),
			}
		).get("ok", false)
	)


func _execute_nest_mythos_place_doom(node: CompositionNode) -> bool:
	if _game_ctx == null:
		return false
	return EncounterAgendaDoomPlacement.place_on_current_agenda(
		_game_ctx, node.may_advance_agenda
	)


func _execute_nest_place_clue(node: CompositionNode) -> bool:
	var inv_id := _ability_controller(_resolve_inv(node))
	if inv_id == &"":
		return false
	return bool(
		_nest_or_direct(
			&"seq.effect.place_clue",
			{"controller_id": inv_id, "inv_id": inv_id}
		).get("ok", false)
	)


func _execute_nest_effect_register(node: CompositionNode) -> bool:
	return _register_via_effect_seq(node.register_template)


func _execute_nest_effect_unregister(node: CompositionNode) -> bool:
	if node.pending_id == &"":
		return false
	return bool(
		_nest_or_direct(
			&"seq.effect.unregister",
			{"reg_id": node.pending_id, "controller_id": _resolve_inv(node)}
		).get("ok", false)
	)


func _execute_nest_discard_card(node: CompositionNode) -> bool:
	var inv_id := _ability_controller(_resolve_inv(node))
	if inv_id == &"":
		return false
	var from_zone := node.from_zone
	## 旧 nest_discard_from_hand：mode 曾写在 location_target，无 from_zone。
	if from_zone == &"" and node.atom_name == &"nest_discard_from_hand":
		from_zone = &"hand"
	var mode := node.place_doom_target
	if mode == &"":
		if from_zone == &"hand":
			mode = node.location_target if node.location_target != &"" else &"random"
		else:
			mode = &"choose"
	var at_filter := node.location_target
	if from_zone == &"hand":
		at_filter = &""
	return bool(
		_nest_or_direct(
			&"seq.effect.discard_card",
			{
				"controller_id": inv_id,
				"card_id": node.card_id,
				"trait": node.definition_id,
				"at": at_filter,
				"mode": mode,
				"from": from_zone,
				"amount": maxi(node.marker_delta, 1),
			}
		).get("ok", false)
	)


func _execute_nest_draw_investigator(node: CompositionNode) -> bool:
	if _game_ctx == null or _game_ctx.sequence_catalog == null:
		return false
	var inv_id := _ability_controller(_resolve_inv(node))
	if inv_id == &"":
		return false
	if RestrictionEvaluator.blocks_draw(inv_id, _registrations):
		_log.log(AhcEnums.LogCategory.CARD, "composition:draw_blocked", {"inv": inv_id})
		return false
	var amount := maxi(node.draw_amount, 1)
	var result := _game_ctx.sequence_catalog.nest(
		_game_ctx,
		&"seq.draw.investigator",
		{
			"inv_id": inv_id,
			"amount": amount,
			"source_tags": [&"card_ability"],
		}
	)
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:nest_draw_investigator",
		{"inv": inv_id, "amount": amount, "ok": bool(result.get("ok", false))}
	)
	return bool(result.get("ok", false))


func _execute_nest_attach(node: CompositionNode) -> bool:
	var inv_id := _ability_controller(_resolve_inv(node))
	var target := node.location_target if node.location_target != &"" else &"nearest_without_same"
	return bool(
		_nest_or_direct(
			&"seq.effect.attach",
			{
				"controller_id": inv_id,
				"card_id": node.card_id,
				"target": target,
			}
		).get("ok", false)
	)


func _nest_or_direct(flow_id: StringName, params: Dictionary) -> Dictionary:
	if _game_ctx == null or _game_ctx.sequence_catalog == null:
		return {}
	return _game_ctx.sequence_catalog.nest(_game_ctx, flow_id, params)


func _ability_controller(inv_id: StringName) -> StringName:
	if _state != null and _state.registry.get_investigator(inv_id) != null:
		return inv_id
	if _game_ctx != null and _game_ctx.sequences != null:
		var trigger := _game_ctx.sequences.current_trigger()
		if trigger != null and _state != null:
			if _state.registry.get_investigator(trigger.controller_id) != null:
				return trigger.controller_id
	return inv_id


func _execute_if(node: CompositionNode) -> void:
	if node.branch_condition == null:
		return
	var take_then := node.branch_condition.matches_domain(_game_ctx, node.inv_id)
	var branch: CompositionNode = node.then_branch if take_then else node.else_branch
	if branch != null:
		branch.provenance = node.provenance
		_run_node(branch)


func _execute_register(node: CompositionNode) -> bool:
	## 禁止真空 RegistrationStore：统一经 `seq.effect.register`。
	var ok := _register_via_effect_seq(node.register_template)
	_log.log(AhcEnums.LogCategory.ABILITY, "composition:register", {
		"via": &"seq.effect.register",
		"ok": ok,
	})
	return ok


## 卡面 Buff 创建唯一落地：nest/run `seq.effect.register`（Catalog 缺失才直写 Store）。
func _register_via_effect_seq(template: RegistrationTemplate) -> bool:
	if template == null:
		return false
	var result := _nest_or_direct(
		&"seq.effect.register",
		{
			"controller_id": template.controller_id,
			"card_id": template.drawn_card_id,
			"template": template,
		}
	)
	if result.is_empty() and _registrations != null:
		return _registrations.register(template) != &""
	return bool(result.get("ok", false))
