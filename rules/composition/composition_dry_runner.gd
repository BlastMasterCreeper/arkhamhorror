class_name CompositionDryRunner
extends RefCounted


func simulate(node: CompositionNode, sim: GameSimulator) -> DryRunResult:
	var result := DryRunResult.new()
	result.has_any_created = _simulate_node(node, sim)
	return result


func _simulate_node(node: CompositionNode, sim: GameSimulator) -> bool:
	match node.kind:
		AhcEnums.CompositionNodeKind.SEQ:
			return _simulate_seq(node, sim)
		AhcEnums.CompositionNodeKind.ATOM:
			var created := _simulate_atom(node, sim)
			sim.last_step_created = created
			return created
		AhcEnums.CompositionNodeKind.REGISTER:
			var created := _simulate_register(node, sim)
			sim.last_step_created = created
			return created
		AhcEnums.CompositionNodeKind.IF:
			return _simulate_if(node, sim)
		AhcEnums.CompositionNodeKind.CHOICE:
			return _simulate_choice(node, sim)
		AhcEnums.CompositionNodeKind.REPEAT:
			return _simulate_repeat(node, sim)
		AhcEnums.CompositionNodeKind.FOR_EACH:
			return _simulate_for_each(node, sim)
	return false


func _simulate_seq(node: CompositionNode, sim: GameSimulator) -> bool:
	var any := false
	for i in node.children.size():
		var child: CompositionNode = node.children[i]
		_maybe_attach_viability_tail(child, node.children, i)
		var created := _simulate_node(child, sim)
		sim.last_step_created = created
		any = any or created
	return any


func _maybe_attach_viability_tail(
	child: CompositionNode, siblings: Array, index: int
) -> void:
	if child == null or child.kind != AhcEnums.CompositionNodeKind.ATOM:
		return
	if child.atom_name != &"pick_target" and child.atom_name != &"select":
		return
	var spec: SelectionSpec = child.selection_spec
	if spec == null:
		var fid := child.target_filter if child.target_filter != &"" else &"enemy_at_connecting"
		spec = SelectionSpec.pick_entity(
			CandidateFilter.from_preset(fid),
			child.choice_prompt_id,
			child.memory_key if child.memory_key != &"" else &"picked_enemy"
		)
		child.selection_spec = spec
	if spec.skip_viability or spec.viability_tail != null:
		return
	var rest: Array[CompositionNode] = []
	for j in range(index + 1, siblings.size()):
		rest.append(siblings[j] as CompositionNode)
	if rest.is_empty():
		return
	spec.viability_tail = rest[0] if rest.size() == 1 else CompositionNode.seq(rest)


func _simulate_for_each(node: CompositionNode, sim: GameSimulator) -> bool:
	if node.children.is_empty() or sim.state == null:
		return false
	var any := false
	for inv_id in sim.state.registry.all_investigator_ids():
		var inv := sim.state.registry.get_investigator(inv_id)
		if inv == null or inv.eliminated or inv.resigned:
			continue
		var fork := sim.fork()
		fork.for_each_inv_override = inv_id
		any = _simulate_node(node.children[0], fork) or any
	return any


func _resolve_sim_inv(node: CompositionNode, sim: GameSimulator) -> StringName:
	if node.inv_id == CompositionNode.INV_EACH and sim.for_each_inv_override != &"":
		return sim.for_each_inv_override
	return node.inv_id


func _resolve_sim_location_spec(
	node: CompositionNode, sim: GameSimulator, inv: InvestigatorState
) -> StringName:
	var spec := node.location_target
	if str(spec).begins_with("memory:"):
		var mem_key := StringName(str(spec).substr(7))
		var controller := _resolve_sim_inv(node, sim)
		var from_mem: Variant = sim.get_referent(controller, mem_key)
		if from_mem != null and str(from_mem) != "":
			return StringName(str(from_mem))
		return &""
	match spec:
		&"source_location", &"":
			return inv.location_tag if inv != null else &""
		&"controller_location":
			return inv.location_tag if inv != null else &""
		_:
			if sim.state != null and sim.state.registry.get_location(spec) != null:
				return spec
			return inv.location_tag if inv != null else &""


func _resolve_sim_enemy_spec(node: CompositionNode, sim: GameSimulator) -> StringName:
	var spec := node.enemy_ref_id
	var controller := _resolve_sim_inv(node, sim)
	if spec == &"" or spec == &"memory:picked_enemy":
		var key := node.memory_key if node.memory_key != &"" else &"picked_enemy"
		var from_mem: Variant = sim.get_referent(controller, key)
		if from_mem != null and str(from_mem) != "":
			return StringName(str(from_mem))
		return sim.last_step_enemy_id
	if str(spec).begins_with("memory:"):
		var mem_key := StringName(str(spec).substr(7))
		var v: Variant = sim.get_referent(controller, mem_key)
		if v != null and str(v) != "":
			return StringName(str(v))
		return sim.last_step_enemy_id
	return spec


## dry-run：U–S 枚举后可选 V；有合法候选即 CREATED（不经 Gate）。
func _simulate_pick_target(node: CompositionNode, sim: GameSimulator) -> bool:
	var pick_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
	if pick_inv == null:
		return false
	var spec: SelectionSpec = node.selection_spec
	if spec == null:
		var fid := node.target_filter if node.target_filter != &"" else &"enemy_at_connecting"
		spec = SelectionSpec.pick_entity(
			CandidateFilter.from_preset(fid),
			node.choice_prompt_id,
			node.memory_key if node.memory_key != &"" else &"picked_enemy"
		)
		node.selection_spec = spec
	if spec.filter == null:
		return false
	var controller := _resolve_sim_inv(node, sim)
	var candidates := CandidateEnumerator.enumerate_on_sim(
		spec.filter, sim, controller, node.card_id
	)
	if not spec.skip_viability and spec.viability_tail != null and not candidates.is_empty():
		candidates = CandidateViability.filter_viable_on_sim(
			candidates, sim, controller, spec.bind_key, spec.viability_tail
		)
	if candidates.is_empty():
		return false
	sim.last_step_enemy_id = candidates[0]
	sim.set_referent(controller, spec.bind_key, candidates[0])
	return true


## Must resolve：返回 dry-run 下至少 CREATED 一项的分支下标（07 §4.2 · 16 §7.2.1）。
func filter_executable_indices(node: CompositionNode, sim: GameSimulator) -> Array[int]:
	var out: Array[int] = []
	if node == null or node.kind != AhcEnums.CompositionNodeKind.CHOICE:
		return out
	for i in node.children.size():
		var fork := sim.fork()
		if _simulate_node(node.children[i], fork):
			out.append(i)
	return out


func _simulate_repeat(node: CompositionNode, sim: GameSimulator) -> bool:
	if node.children.is_empty():
		return false
	var count := _repeat_count_for_sim(node, sim)
	if count <= 0:
		return false
	var any := false
	for _i in count:
		var fork := sim.fork()
		any = any or _simulate_node(node.children[0], fork)
	return any


func _repeat_count_for_sim(node: CompositionNode, sim: GameSimulator) -> int:
	if node.repeat_count_source == &"last_skill_test_fail_by":
		return sim.last_skill_test_fail_by
	if node.repeat_count_fixed > 0:
		return node.repeat_count_fixed
	return 0


func _simulate_choice(node: CompositionNode, sim: GameSimulator) -> bool:
	for child in node.children:
		var fork := sim.fork()
		if _simulate_node(child, fork):
			return true
	return false


func _simulate_if(node: CompositionNode, sim: GameSimulator) -> bool:
	if node.branch_condition == null:
		return false
	var take_then := node.branch_condition.matches_domain_sim(sim, node.inv_id)
	var branch: CompositionNode = node.then_branch if take_then else node.else_branch
	if branch == null:
		return false
	return _simulate_node(branch, sim)


func _simulate_atom(node: CompositionNode, sim: GameSimulator) -> bool:
	match node.atom_name:
		&"draw":
			if RestrictionEvaluator.blocks_draw(node.inv_id, sim.registrations):
				return false
			var draw_result := sim.mutator.execute_draw_instruction(node.inv_id, maxi(node.draw_amount, 1))
			return draw_result.ok and draw_result.drew and not draw_result.defeated
		&"move_card":
			if node.to_slot == null:
				return false
			return sim.mutator.move_card(node.card_id, node.to_slot)
		&"adjust_marker":
			if node.marker_slot == null:
				return false
			return sim.mutator.adjust_marker(node.marker_slot, node.marker_delta)
		&"set_flag":
			return sim.mutator.set_flag(node.inv_id, node.flag_field, node.flag_value)
		&"reveal_to_controller":
			return sim.mutator.reveal_to_controller(node.card_id, node.inv_id)
		&"reveal_to_all":
			return sim.mutator.reveal_to_all(node.card_id)
		&"pop_deck_top":
			var card_id := sim.mutator.pop_deck_top(node.inv_id)
			return card_id != &""
		&"shuffle_discard_into_deck":
			if sim.mutator.deck_is_empty(node.inv_id) and not sim.mutator.discard_is_empty(node.inv_id):
				sim.mutator.shuffle_discard_into_deck(node.inv_id)
				return true
			return false
		&"commit_enter_hand":
			return sim.mutator.commit_enter_hand(node.card_id, node.inv_id)
		&"commit_hidden_enter_hand":
			return sim.mutator.commit_hidden_enter_hand(node.card_id, node.inv_id)
		&"expose_hidden":
			var expose_card := sim.state.registry.get_card(node.card_id)
			return expose_card != null and expose_card.is_hidden
		&"spawn_encounter_enemy":
			var card := sim.state.registry.get_card(node.card_id)
			return (
				card != null
				and card.zone == AhcEnums.Zone.HAND
				and CardRegistry.card_type(card.id.definition_id) == &"enemy"
			)
		&"discard_encounter_from_hand":
			var discard_card := sim.state.registry.get_card(node.card_id)
			return (
				discard_card != null
				and discard_card.zone == AhcEnums.Zone.HAND
				and discard_card.owner_id == &"encounter"
			)
		&"cancel_pending":
			return node.pending_id != &""
		&"ignore_pending":
			return node.pending_id != &""
		&"interrupt":
			return node.interrupt_target != null
		&"replace_pending":
			return node.pending_id != &"" and node.effect_request != null
		&"replace_instead":
			return node.replace_target != null and node.effect_request != null
		&"resolve_pending":
			return node.pending_id != &""
		&"place_doom_nearest_enemy_without_doom", &"nest_place_doom":
			var origin := node.inv_id
			if node.place_doom_target == &"source":
				return sim.state.registry.get_enemy(node.card_id) != null
			var inv := sim.state.registry.get_investigator(origin)
			if node.place_doom_target == &"nearest_enemy_without_doom_to_source":
				var source_enemy := sim.state.registry.get_enemy(node.card_id)
				if source_enemy == null or source_enemy.location_tag == &"":
					return false
			elif inv == null or inv.location_tag == &"":
				return false
			for enemy_id in sim.state.registry.all_enemy_ids():
				if enemy_id == node.card_id and node.place_doom_target == &"nearest_enemy_without_doom_to_source":
					continue
				var enemy := sim.state.registry.get_enemy(enemy_id)
				if enemy != null and enemy.doom == 0 and enemy.location_tag != &"":
					return true
			return false
		&"place_doom_on_current_agenda", &"nest_mythos_place_doom":
			return sim.state != null
		&"place_clue_on_investigator_location", &"nest_place_clue":
			var clue_inv := sim.state.registry.get_investigator(node.inv_id)
			if clue_inv == null or clue_inv.clues_on_card <= 0 or clue_inv.location_tag == &"":
				return false
			return sim.state.registry.get_location(clue_inv.location_tag) != null
		&"nest_skill_test":
			var test_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
			if test_inv == null:
				return false
			sim.last_skill_test_fail_by = _estimate_fail_by(test_inv, node.test_skill, node.test_difficulty)
			if node.st7_plan != null:
				if sim.last_skill_test_fail_by > 0 and node.st7_plan.on_fail_by_each != null:
					var fork := sim.fork()
					return _simulate_node(node.st7_plan.on_fail_by_each, fork)
				if node.st7_plan.on_success != null and sim.last_skill_test_fail_by == 0:
					var fork_ok := sim.fork()
					return _simulate_node(node.st7_plan.on_success, fork_ok)
				if node.st7_plan.on_fail != null and sim.last_skill_test_fail_by > 0:
					var fork_fail := sim.fork()
					return _simulate_node(node.st7_plan.on_fail, fork_fail)
			return sim.last_skill_test_fail_by >= 0
		&"nest_enemy_resolve_location":
			var resolve_inv := sim.state.registry.get_investigator(node.inv_id)
			if resolve_inv == null or resolve_inv.location_tag == &"":
				return false
			sim.last_resolved_location = resolve_inv.location_tag
			return true
		&"nest_enemy_move":
			var move_inv := sim.state.registry.get_investigator(node.inv_id)
			if move_inv == null or move_inv.location_tag == &"":
				return false
			for enemy_id in sim.state.registry.all_enemy_ids():
				var enemy := sim.state.registry.get_enemy(enemy_id)
				if enemy != null and enemy.location_tag != &"":
					sim.last_step_created = true
					sim.last_step_engaged_investigator = node.inv_id
					return true
			return false
		&"nest_enemy_attack":
			if node.enemy_ref_id != &"" and node.target_investigator_id != &"":
				return true
			return sim.last_step_engaged_investigator != &""
		&"exhaust_card":
			var exh := sim.state.registry.get_card(node.card_id) if sim.state != null else null
			if exh == null or exh.exhausted:
				return false
			exh.exhausted = true
			return true
		&"exhaust_enemy":
			var exh_enemy_id := _resolve_sim_enemy_spec(node, sim)
			if exh_enemy_id == &"" or sim.state == null:
				return false
			var exh_enemy := sim.state.registry.get_enemy(exh_enemy_id)
			if exh_enemy == null or exh_enemy.exhausted:
				return false
			exh_enemy.exhausted = true
			sim.last_step_enemy_id = exh_enemy_id
			return true
		&"deal_damage_enemy":
			var dmg_enemy_id := _resolve_sim_enemy_spec(node, sim)
			if dmg_enemy_id == &"" or sim.state == null:
				return false
			var dmg_enemy := sim.state.registry.get_enemy(dmg_enemy_id)
			if dmg_enemy == null:
				return false
			dmg_enemy.damage += maxi(node.marker_delta, 1)
			sim.last_step_enemy_id = dmg_enemy_id
			return true
		&"disengage_enemy":
			var dis_enemy_id := _resolve_sim_enemy_spec(node, sim)
			if dis_enemy_id == &"" or sim.state == null:
				return false
			var dis_enemy := sim.state.registry.get_enemy(dis_enemy_id)
			if dis_enemy == null or dis_enemy.engaged_with == &"":
				return false
			var holder := sim.state.registry.get_investigator(dis_enemy.engaged_with)
			if holder != null:
				holder.threat_area.erase(dis_enemy_id)
			dis_enemy.engaged_with = &""
			sim.last_step_enemy_id = dis_enemy_id
			return true
		&"no_provoke_aoo":
			## 镜像 `seq.effect.register` CREATED（dry-run 不压栈；行动开始挂载等价）。
			var skip_ctrl := _resolve_sim_inv(node, sim)
			if sim.registrations != null and skip_ctrl != &"":
				sim.registrations.register(
					RegistrationTemplate.skip_aoo_for_action(skip_ctrl)
				)
			return true
		&"leave_clues_at_location":
			var leave_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
			if leave_inv == null or leave_inv.eliminated:
				return false
			if leave_inv.clues_on_card <= 0 or leave_inv.location_tag == &"":
				return false
			var leave_loc := sim.state.registry.get_location(leave_inv.location_tag)
			if leave_loc == null:
				return false
			leave_loc.clues += leave_inv.clues_on_card
			leave_inv.clues_on_card = 0
			return true
		&"eliminate":
			var elim_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
			if elim_inv == null or elim_inv.eliminated:
				return false
			elim_inv.eliminated = true
			return true
		&"resign", &"nest_resign":
			## 兼容旧单 Atom；新树应为 leave_clues → set_flag → eliminate。
			var resign_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
			return resign_inv != null and not resign_inv.eliminated and not resign_inv.resigned
		&"pick_target", &"select":
			return _simulate_pick_target(node, sim)
		&"suppress_auto_engage":
			## 镜像 `seq.effect.register` CREATED（dry-run 不压栈）。
			var sup_enemy := sim.last_step_enemy_id
			var sup_spec := str(node.enemy_ref_id)
			if sup_spec != "" and not sup_spec.begins_with("memory:"):
				sup_enemy = node.enemy_ref_id
			if sup_enemy == &"" or sim.state.registry.get_enemy(sup_enemy) == null:
				return false
			if sim.registrations != null:
				var sup_t := RegistrationTemplate.suppress_auto_engage_until_fired(sup_enemy)
				sup_t.controller_id = _resolve_sim_inv(node, sim)
				sim.registrations.register(sup_t)
			return true
		&"move_enemy_to", &"engage_target", &"nest_enemy_move_to", &"nest_engage":
			var move_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
			if move_inv == null:
				return false
			var spec := str(node.enemy_ref_id)
			if spec != "" and not spec.begins_with("memory:"):
				return sim.state.registry.get_enemy(node.enemy_ref_id) != null
			return sim.last_step_enemy_id != &""
		&"engage_from_connecting":
			var eng_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
			if eng_inv == null or eng_inv.location_tag == &"":
				return false
			var eng_loc := sim.state.registry.get_location(eng_inv.location_tag)
			return eng_loc != null and not eng_loc.connections.is_empty()
		&"spend_clues_group":
			var need := maxi(node.marker_delta, 1)
			if bool(node.flag_value):
				need = maxi(need, 1)  # dry-run：至少能花到某个调查员的线索
			var pool := 0
			for inv_id in sim.state.registry.all_investigator_ids():
				var ginv := sim.state.registry.get_investigator(inv_id)
				if ginv != null and not ginv.eliminated and not ginv.resigned:
					pool += ginv.clues_on_card
			return pool >= need
		&"nest_move_connecting":
			var move_free_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
			if move_free_inv == null or move_free_inv.location_tag == &"":
				return false
			var from_loc := sim.state.registry.get_location(move_free_inv.location_tag)
			return from_loc != null and not from_loc.connections.is_empty()
		&"nest_move_to":
			var move_to_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
			if move_to_inv == null:
				return false
			var dest := _resolve_sim_location_spec(node, sim, move_to_inv)
			if dest == &"" or dest == move_to_inv.location_tag:
				return false
			if sim.state.registry.get_location(dest) == null:
				return false
			move_to_inv.location_tag = dest
			return true
		&"nest_gain_resource":
			if sim.state.registry.get_investigator(_resolve_sim_inv(node, sim)) != null:
				return true
			return not sim.state.registry.all_investigator_ids().is_empty()
		&"take_horror", &"take_damage", &"nest_take_horror", &"nest_take_damage", &"nest_deal_damage", &"nest_damage":
			return (
				sim.state.registry.get_investigator(_resolve_sim_inv(node, sim)) != null
				or node.location_target != &""
			)
		&"nest_lose_resources", &"lose_all_resources", &"nest_lose_all_resources":
			var lose_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
			return lose_inv != null and lose_inv.resource_pool > 0
		&"nest_heal":
			var heal_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
			if heal_inv == null:
				return false
			if node.marker_slot != null and node.marker_slot.kind == AhcEnums.MarkerKind.HORROR_TAKEN:
				return heal_inv.horror_taken > 0
			return heal_inv.damage_taken > 0
		&"nest_lose_action":
			var act_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
			return act_inv != null and act_inv.actions_remaining > 0
		&"nest_effect_register":
			return node.register_template != null
		&"nest_effect_unregister":
			return node.pending_id != &""
		&"discard_all_enemies_in_play":
			return ScenarioCompositionAtoms.dry_discard_all_enemies_in_play(sim)
		&"put_locations_into_play":
			return ScenarioCompositionAtoms.dry_put_locations_into_play(sim, node.location_ids)
		&"spawn_set_aside_enemy_at":
			return ScenarioCompositionAtoms.dry_spawn_set_aside_enemy_at(
				sim, node.definition_id, node.location_target
			)
		&"attach_set_aside_to_host":
			return ScenarioCompositionAtoms.dry_attach_set_aside_to_host(
				sim, node.definition_id, node.card_id, node.atom_count
			)
		&"attach_limbo_to_nearest_location_without", &"nest_attach":
			var exclude := node.definition_id
			if exclude == &"" and node.card_id != &"":
				var c := sim.state.registry.get_card(node.card_id) if sim.state != null else null
				if c != null:
					exclude = c.id.definition_id
			if node.location_target == &"controller_location":
				var att_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
				return att_inv != null and att_inv.location_tag != &""
			return EncounterAttachment.dry_attach_limbo_to_nearest_location_without(
				sim, _resolve_sim_inv(node, sim), exclude
			)
		&"nest_discard_card":
			if node.card_id != &"":
				return sim.state.registry.get_card(node.card_id) != null
			## 过滤选目标（如旁人敌人）时，只要有 controller 即可尝试。
			return sim.state.registry.get_investigator(_resolve_sim_inv(node, sim)) != null
		&"nest_discard_from_hand":
			var disc_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
			return disc_inv != null and not disc_inv.hand.is_empty()
		&"nest_draw_investigator":
			var draw_inv_id := _resolve_sim_inv(node, sim)
			var draw_inv := sim.state.registry.get_investigator(draw_inv_id)
			if draw_inv == null:
				return false
			if RestrictionEvaluator.blocks_draw(draw_inv_id, sim.registrations):
				return false
			return not draw_inv.deck.is_empty() or not draw_inv.discard.is_empty()
		&"discard_set_aside_to_encounter_discard":
			return ScenarioCompositionAtoms.dry_discard_set_aside_to_encounter_discard(
				sim, node.definition_id, node.atom_count
			)
		&"nest_scenario_resolution":
			var resolution := node.scenario_resolution
			if resolution <= 0 and node.definition_id != &"":
				resolution = ScenarioResolutionParser.parse(
					CardRegistry.back_text(node.definition_id)
				)
			return ScenarioCompositionAtoms.dry_trigger_scenario_resolution(resolution)
		&"defeat_surviving_non_resigned":
			return ScenarioCompositionAtoms.dry_defeat_surviving_non_resigned(sim)
		&"heal_and_set_aside_enemy":
			return ScenarioCompositionAtoms.dry_heal_and_set_aside_enemy(sim, node.definition_id)
		&"remove_location_from_game":
			return ScenarioCompositionAtoms.dry_remove_location_from_game(sim, node.card_id)
		&"put_story_asset_from_set_aside":
			return ScenarioCompositionAtoms.dry_put_story_asset_from_set_aside(sim, node.definition_id)
		&"place_clues_on_location":
			return ScenarioCompositionAtoms.dry_place_clues_on_location(sim, node.location_target)
		&"lead_search_draw_encounter_copies":
			return ScenarioCompositionAtoms.dry_lead_search_draw_encounter_copies(
				sim, node.definition_id
			)
		&"lead_draw_topmost_encounter_discard_copy":
			return ScenarioCompositionAtoms.dry_lead_draw_topmost_encounter_discard_copy(
				sim, node.definition_id
			)
		_:
			push_warning("CompositionDryRunner: unknown atom %s" % node.atom_name)
			return false
	return false


func _estimate_fail_by(
	inv: InvestigatorState,
	skill: AhcEnums.SkillType,
	difficulty: int
) -> int:
	var base := _investigator_skill_value(inv, skill)
	return maxi(difficulty - base, 0)


func _investigator_skill_value(inv: InvestigatorState, skill: AhcEnums.SkillType) -> int:
	match skill:
		AhcEnums.SkillType.WILLPOWER:
			return inv.skill_willpower
		AhcEnums.SkillType.INTELLECT:
			return inv.skill_intellect
		AhcEnums.SkillType.COMBAT:
			return inv.skill_combat
		AhcEnums.SkillType.AGILITY:
			return inv.skill_agility
	return 0


func _simulate_register(node: CompositionNode, sim: GameSimulator) -> bool:
	if node.register_template == null:
		return false
	sim.registrations.register(node.register_template)
	return true
