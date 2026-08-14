class_name ActAgendaBackCompiler
extends RefCounted

## 将 CardRegistry `back_effects` 编译为 Composition 树 · 10 §3.2 / §4.2。


static func compile(definition_id: StringName, back_text: String = "") -> CompositionNode:
	var children: Array[CompositionNode] = []
	var has_resolution_step := false
	for raw in CardRegistry.back_effects(definition_id):
		if raw is not Dictionary:
			continue
		var node := _compile_effect(raw as Dictionary, definition_id)
		if node == null:
			continue
		if node.atom_name == &"nest_scenario_resolution":
			has_resolution_step = true
		children.append(node)
	if not _contains_atom(children, &"discard_all_enemies_in_play"):
		if _text_has_discard_all_enemies(back_text):
			children.insert(0, CompositionNode.discard_all_enemies_in_play())
	if not has_resolution_step:
		var resolution := ScenarioResolutionParser.parse(back_text)
		if resolution > 0:
			children.append(
				CompositionNode.nest_scenario_resolution(resolution, definition_id)
			)
	return CompositionNode.seq(children)


static func _compile_effect(effect: Dictionary, source_definition_id: StringName) -> CompositionNode:
	var kind: StringName = effect.get("kind", &"")
	match kind:
		&"discard_all_enemies":
			return CompositionNode.discard_all_enemies_in_play()
		&"put_locations_into_play":
			return CompositionNode.put_locations_into_play(
				effect.get("location_ids", [])
			)
		&"spawn_set_aside_enemy":
			return CompositionNode.spawn_set_aside_enemy_at(
				effect.get("enemy_id", &""),
				effect.get("location_id", &""),
			)
		&"attach_set_aside_to_location":
			return CompositionNode.attach_set_aside_to_host(
				effect.get("definition_id", &""),
				effect.get("location_id", &""),
				int(effect.get("count", 1)),
			)
		&"discard_set_aside_to_encounter_discard":
			return CompositionNode.discard_set_aside_to_encounter_discard(
				effect.get("definition_id", &""),
				int(effect.get("count", -1)),
			)
		&"trigger_scenario_resolution":
			return CompositionNode.nest_scenario_resolution(
				int(effect.get("resolution", -1)),
				source_definition_id,
			)
		&"each_investigator_skill_test":
			return _compile_each_investigator_skill_test(effect)
		&"defeat_surviving_non_resigned":
			return CompositionNode.defeat_surviving_non_resigned(
				int(effect.get("physical_trauma", 0)),
				int(effect.get("mental_trauma", 0)),
			)
		&"heal_and_set_aside_enemy":
			return CompositionNode.heal_and_set_aside_enemy(
				effect.get("definition_id", &""),
			)
		&"remove_location_from_game":
			return CompositionNode.remove_location_from_game(
				effect.get("location_id", &""),
			)
		&"put_story_asset_from_set_aside":
			return CompositionNode.put_story_asset_from_set_aside(
				effect.get("definition_id", &""),
				effect.get("controller_id", &"lead_investigator"),
			)
		&"place_clues_on_location":
			return CompositionNode.place_clues_on_location(
				effect.get("location_id", &""),
				int(effect.get("printed_clues", 0)),
			)
		&"lead_search_draw_encounter_copies":
			return CompositionNode.lead_search_draw_encounter_copies(
				effect.get("definition_id", &""),
				bool(effect.get("per_investigator", false)),
			)
		_:
			return null


static func _compile_each_investigator_skill_test(effect: Dictionary) -> CompositionNode:
	var skill := _skill_from_name(StringName(str(effect.get("skill", "willpower"))))
	var difficulty := int(effect.get("difficulty", 0))
	var on_fail: Dictionary = effect.get("on_fail", {})
	var fail_kind: StringName = on_fail.get("kind", &"")
	var amount := int(on_fail.get("amount", 1))
	var steps: Array[CompositionNode] = [
		CompositionNode.nest_skill_test(
			CompositionNode.INV_EACH, skill, difficulty
		),
	]
	if fail_kind == &"horror":
		steps.append(
			CompositionNode.if_else(
				Condition.last_skill_test_failed(),
				CompositionNode.take_horror(CompositionNode.INV_EACH, amount),
				null,
				CompositionNode.INV_EACH,
			)
		)
	elif fail_kind == &"damage":
		steps.append(
			CompositionNode.if_else(
				Condition.last_skill_test_failed(),
				CompositionNode.take_damage(CompositionNode.INV_EACH, amount),
				null,
				CompositionNode.INV_EACH,
			)
		)
	return CompositionNode.for_each_player_order(CompositionNode.seq(steps))


static func _skill_from_name(name: StringName) -> AhcEnums.SkillType:
	match name:
		&"intellect":
			return AhcEnums.SkillType.INTELLECT
		&"combat":
			return AhcEnums.SkillType.COMBAT
		&"agility":
			return AhcEnums.SkillType.AGILITY
		_:
			return AhcEnums.SkillType.WILLPOWER


static func _contains_atom(nodes: Array[CompositionNode], atom_name: StringName) -> bool:
	for node in nodes:
		if node != null and node.atom_name == atom_name:
			return true
	return false


static func _text_has_discard_all_enemies(text: String) -> bool:
	return text.to_lower().contains("discard each enemy")
