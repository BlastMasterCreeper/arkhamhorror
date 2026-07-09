class_name ArkhamDbAbilityCompiler
extends RefCounted

static var _registered_definitions: Dictionary = {}


static func apply_to_registry(definition_id: StringName, src: Dictionary) -> Dictionary:
	var stats := {
		"segments": 0,
		"compiled": 0,
		"registered": 0,
	}
	var segments: Variant = src.get("ability_segments", [])
	if segments is Array:
		stats["segments"] = segments.size()
	var compiled: Variant = src.get("compiled_abilities", [])
	if not compiled is Array or compiled.is_empty():
		return stats
	stats["compiled"] = compiled.size()
	if _registered_definitions.has(definition_id):
		return stats
	for entry in compiled:
		if entry is Dictionary:
			if _register_entry(definition_id, entry as Dictionary):
				stats["registered"] += 1
	if int(stats["registered"]) > 0:
		_registered_definitions[definition_id] = true
	return stats


static func build_composition(
	template_id: String,
	params: Dictionary,
	bind: AbilityBindContext
) -> CompositionNode:
	match template_id:
		"take_horror":
			return CompositionNode.adjust_marker(
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.HORROR_TAKEN),
				int(params.get("amount", 1))
			)
		"take_damage":
			return CompositionNode.adjust_marker(
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.DAMAGE),
				int(params.get("amount", 1))
			)
		"lose_resources":
			return CompositionNode.adjust_marker(
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.RESOURCE),
				-int(params.get("amount", 1))
			)
		"lose_all_resources":
			return CompositionNode.lose_all_resources(bind.controller_id)
		"enter_threat_area":
			return CompositionNode.enter_threat_area(bind.card_id, bind.controller_id)
		"grant_surge":
			return CompositionNode.grant_keyword(bind.card_id, &"surge")
		"if_else":
			return _build_if_else(params, bind)
		"seq":
			return _build_seq(params, bind)
		"place_doom_nearest_enemy_without_doom":
			return CompositionNode.place_doom_nearest_enemy_without_doom(
				bind.card_id, bind.controller_id
			)
		"choice_must":
			return _build_choice_must(params, bind)
		"place_doom_on_current_agenda":
			return CompositionNode.place_doom_on_current_agenda(
				bool(params.get("may_advance_agenda", false))
			)
		"place_clue_on_location":
			return CompositionNode.place_clue_on_investigator_location(bind.controller_id)
		"skill_test":
			return _build_skill_test(params, bind)
		"repeat_fail_by":
			return _build_repeat_fail_by(params, bind)
		"resolve_location":
			return _build_resolve_location(params, bind)
		"nest_enemy_move":
			return _build_nest_enemy_move(params, bind)
		"nest_enemy_attack":
			return CompositionNode.nest_enemy_attack_last()
	return null


static func _build_resolve_location(params: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var target := StringName(str(params.get("target", "drawer_location")))
	return CompositionNode.nest_enemy_resolve_location(bind.controller_id, target)


static func _build_nest_enemy_move(params: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var exclude: Array[StringName] = []
	for trait_name in params.get("trait_exclude", []):
		exclude.append(StringName(str(trait_name)))
	return CompositionNode.nest_enemy_move(bind.controller_id, exclude)


static func _build_seq(params: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var steps: Variant = params.get("steps", [])
	if not steps is Array or (steps as Array).is_empty():
		return null
	var nodes: Array[CompositionNode] = []
	for step in steps:
		if step is Dictionary:
			var step_dict := step as Dictionary
			var node := build_composition(
				str(step_dict.get("template", "")),
				step_dict,
				bind
			)
			if node != null:
				nodes.append(node)
	if nodes.is_empty():
		return null
	return CompositionNode.seq(nodes)


static func _build_choice_must(params: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var options: Variant = params.get("options", [])
	if not options is Array or (options as Array).is_empty():
		return null
	var branches: Array = []
	var option_ids: Array[StringName] = []
	for entry in options:
		if not entry is Dictionary:
			continue
		var opt := entry as Dictionary
		var branch := build_composition(str(opt.get("template", "")), opt, bind)
		if branch == null:
			continue
		branches.append(branch)
		var oid := str(opt.get("id", ""))
		if oid != "":
			option_ids.append(StringName(oid))
	if branches.is_empty():
		return null
	var prompt_id := StringName(str(params.get("prompt_id", "composition:choice_must")))
	return CompositionNode.must_choose(branches, bind.controller_id, option_ids, prompt_id)


static func _build_skill_test(params: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var skill := _skill_from_compile_id(str(params.get("skill", "willpower")))
	var difficulty := int(params.get("difficulty", 0))
	var plan := _build_st7_plan(params, bind)
	return CompositionNode.nest_skill_test(
		bind.controller_id, skill, difficulty, bind.card_id, plan
	)


static func _build_st7_plan(params: Dictionary, bind: AbilityBindContext) -> SkillTestSt7Plan:
	var st7_entry: Variant = params.get("st7", {})
	if st7_entry is Dictionary and not (st7_entry as Dictionary).is_empty():
		return SkillTestSt7Plan.from_compile_dict(
			st7_entry as Dictionary,
			bind,
			build_composition
		)
	# 兼容旧键 st7_fail_by（12126 竖切）
	var legacy: Variant = params.get("st7_fail_by", {})
	if legacy is Dictionary and not (legacy as Dictionary).is_empty():
		var plan := SkillTestSt7Plan.new()
		plan.on_fail_by_each = build_composition(
			str((legacy as Dictionary).get("template", "")),
			legacy as Dictionary,
			bind
		)
		return plan
	return null


static func _build_repeat_fail_by(params: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var body_entry: Variant = params.get("body", {})
	if not body_entry is Dictionary:
		return null
	var body := build_composition(
		str((body_entry as Dictionary).get("template", "")),
		body_entry as Dictionary,
		bind
	)
	if body == null:
		return null
	return CompositionNode.repeat_fail_by(body)


static func _skill_from_compile_id(skill_id: String) -> AhcEnums.SkillType:
	match skill_id.to_lower():
		"intellect":
			return AhcEnums.SkillType.INTELLECT
		"combat":
			return AhcEnums.SkillType.COMBAT
		"agility":
			return AhcEnums.SkillType.AGILITY
		_:
			return AhcEnums.SkillType.WILLPOWER


static func _build_if_else(params: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var condition_id := str(params.get("condition", ""))
	var cond := Condition.from_compile_id(condition_id, bind.controller_id, bind.card_id)
	if cond == null:
		return null
	var then_entry: Variant = params.get("then", {})
	var else_entry: Variant = params.get("else", {})
	var then_node: CompositionNode = null
	var else_node: CompositionNode = null
	if then_entry is Dictionary:
		then_node = build_composition(
			str((then_entry as Dictionary).get("template", "")),
			then_entry as Dictionary,
			bind
		)
	if else_entry is Dictionary:
		var else_tpl := str((else_entry as Dictionary).get("template", ""))
		if else_tpl != "" and else_tpl != "uncompiled":
			else_node = build_composition(else_tpl, else_entry as Dictionary, bind)
	return CompositionNode.if_else(cond, then_node, else_node, bind.controller_id)


static func _register_entry(definition_id: StringName, entry: Dictionary) -> bool:
	if str(entry.get("register_as", "")) != "revelation":
		return false
	var template_id := str(entry.get("template", ""))
	if template_id == "":
		return false
	var ability_id := StringName(str(entry.get("ability_id", "revelation:0")))
	var params := _params_from_entry(entry)
	CardRegistry.register_revelation(
		definition_id,
		ability_id,
		func(bind: AbilityBindContext) -> CompositionNode:
			return build_composition(template_id, params, bind)
	)
	return true


static func _params_from_entry(entry: Dictionary) -> Dictionary:
	var params := {}
	for key in [
		"amount",
		"direct",
		"trigger",
		"status",
		"if_kind",
		"evaluate",
		"condition",
		"then",
		"else",
		"steps",
		"options",
		"prompt_id",
		"body",
		"skill",
		"difficulty",
		"st7_fail_by",
		"st7",
	]:
		if entry.has(key):
			params[key] = entry[key]
	return params
