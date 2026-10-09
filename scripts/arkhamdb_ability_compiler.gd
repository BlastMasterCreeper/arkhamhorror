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
			return CompositionNode.nest_take_horror(
				bind.controller_id,
				int(params.get("amount", 1)),
				bool(params.get("direct", false)),
				StringName(str(params.get("target", "controller"))),
				bind.card_id
			)
		"take_damage":
			return CompositionNode.nest_take_damage(
				bind.controller_id,
				int(params.get("amount", 1)),
				bool(params.get("direct", false)),
				StringName(str(params.get("target", "controller"))),
				bind.card_id
			)
		"lose_resources":
			return CompositionNode.nest_lose_resources(
				bind.controller_id, int(params.get("amount", 1))
			)
		"lose_all_resources":
			return CompositionNode.nest_lose_all_resources(bind.controller_id)
		"lose_action":
			return CompositionNode.nest_lose_action(
				bind.controller_id, int(params.get("amount", 1))
			)
		"heal":
			return CompositionNode.nest_heal(
				bind.controller_id,
				StringName(str(params.get("kind", "damage"))),
				int(params.get("amount", 1))
			)
		"discard_source":
			return CompositionNode.nest_discard_card(bind.card_id, bind.controller_id)
		"no_provoke_aoo":
			return CompositionNode.no_provoke_aoo(bind.controller_id)
		"leave_clues_at_location":
			return CompositionNode.leave_clues_at_location(bind.controller_id)
		"eliminate":
			return CompositionNode.eliminate(bind.controller_id)
		"set_flag":
			return CompositionNode.set_flag(
				bind.controller_id,
				_flag_field_from_raw(params.get("field", "resigned")),
				bool(params.get("value", true))
			)
		"resign":
			## 兼容旧 JSON；新编译应已是 leave_clues → set_flag → eliminate。
			return CompositionNode.resign(bind.controller_id)
		"nest_resign":
			return CompositionNode.nest_resign(bind.controller_id)
		"pick_target", "select", "pick_multi":
			## 通用选择：filter 可为预设字符串或对象；见 21-selection-spec。
			var sel_params := params.duplicate()
			if template_id == "pick_multi":
				if not sel_params.has("max") and not sel_params.has("max_picks"):
					sel_params["min_picks"] = int(
						sel_params.get("min_picks", sel_params.get("min", 1))
					)
					sel_params["max_picks"] = int(
						sel_params.get("max_picks", sel_params.get("amount", 2))
					)
				if not sel_params.has("memory_key") and not sel_params.has("bind_key"):
					sel_params["memory_key"] = "picked_enemies"
				if not sel_params.has("prompt_id"):
					sel_params["prompt_id"] = "pick:multi"
			var spec := SelectionSpec.from_pick_target_params(sel_params)
			if template_id == "pick_multi":
				spec.choice_kind = AhcEnums.ChoiceKind.PICK_MULTI
				spec.bind_shape = &"entity_list"
				return CompositionNode.select_entities(bind.controller_id, spec, bind.card_id)
			if template_id == "select":
				return CompositionNode.select_entities(bind.controller_id, spec, bind.card_id)
			return CompositionNode.pick_target(
				bind.controller_id,
				spec,
				spec.prompt_id,
				spec.bind_key,
				bind.card_id
			)
		"for_each_memory", "for_each_entities":
			return _build_for_each_memory(params, bind)
		"move_enemy_to":
			return CompositionNode.move_enemy_to(
				bind.controller_id,
				StringName(str(params.get("enemy", "memory:picked_enemy"))),
				StringName(str(params.get("location", "source_location"))),
				bind.card_id
			)
		"engage_target":
			return CompositionNode.engage_target(
				bind.controller_id,
				StringName(str(params.get("enemy", "memory:picked_enemy"))),
				bind.card_id
			)
		"suppress_auto_engage":
			return CompositionNode.suppress_auto_engage(
				bind.controller_id,
				StringName(str(params.get("enemy", "memory:picked_enemy"))),
				bind.card_id
			)
		"nest_enemy_move_to":
			## 移入走正常 auto-engage 入口；抑制靠先前的 SUPPRESS_AUTO_ENGAGE 限制。
			return CompositionNode.nest_enemy_move_to(
				bind.controller_id,
				StringName(str(params.get("enemy", "memory:picked_enemy"))),
				StringName(str(params.get("location", "source_location"))),
				true,
				bind.card_id
			)
		"nest_engage":
			return CompositionNode.nest_engage(
				bind.controller_id,
				StringName(str(params.get("enemy", "memory:picked_enemy"))),
				StringName(str(params.get("mode", params.get("engage_mode", "effect")))),
				bind.card_id
			)
		"engage_from_connecting":
			## 兼容旧 JSON；编译产物应已是 seq 三步。
			return CompositionNode.engage_from_connecting(
				bind.controller_id, bind.card_id
			)
		"spend_clues_group":
			return CompositionNode.spend_clues_group(
				bind.controller_id,
				int(params.get("amount", 1)),
				bool(params.get("per_investigator", false))
			)
		"discard_card":
			return CompositionNode.nest_discard_card(
				StringName(str(params.get("card_id", ""))),
				bind.controller_id,
				StringName(str(params.get("trait", ""))),
				StringName(str(params.get("at", ""))),
				StringName(str(params.get("mode", "choose")))
			)
		"discard_from_hand":
			return CompositionNode.nest_discard_from_hand(
				bind.controller_id,
				int(params.get("amount", 1)),
				StringName(str(params.get("mode", "random")))
			)
		"draw":
			return CompositionNode.nest_draw_investigator(
				bind.controller_id,
				int(params.get("amount", 1))
			)
		"attach_nearest_without_same":
			return CompositionNode.nest_attach(
				bind.card_id, bind.controller_id, &"nearest_without_same"
			)
		"attach_controller_location":
			return CompositionNode.nest_attach(
				bind.card_id, bind.controller_id, &"controller_location"
			)
		"deal_damage":
			return CompositionNode.nest_deal_damage(
				bind.controller_id,
				int(params.get("amount", 1)),
				StringName(str(params.get("target", "controller"))),
				bind.card_id,
				bool(params.get("per_investigator", false))
			)
		"enter_threat_area":
			return CompositionNode.enter_threat_area(bind.card_id, bind.controller_id)
		"grant_surge":
			return CompositionNode.grant_keyword(bind.card_id, &"surge")
		"if_else":
			return _build_if_else(params, bind)
		"seq":
			return _build_seq(params, bind)
		"place_doom_nearest_enemy_without_doom":
			return CompositionNode.nest_place_doom(
				bind.controller_id, bind.card_id, &"nearest_enemy_without_doom"
			)
		"place_doom_on_source":
			return CompositionNode.nest_place_doom(
				bind.controller_id, bind.card_id, &"source"
			)
		"place_doom_nearest_to_source":
			return CompositionNode.nest_place_doom(
				bind.controller_id,
				bind.card_id,
				&"nearest_enemy_without_doom_to_source"
			)
		"choice_must":
			return _build_choice_must(params, bind)
		"choice_optional", "optional":
			return _build_choice_optional(params, bind)
		"place_doom_on_current_agenda":
			return CompositionNode.nest_mythos_place_doom(
				bool(params.get("may_advance_agenda", false))
			)
		"place_clue_on_location":
			return CompositionNode.nest_place_clue(bind.controller_id)
		"skill_test":
			return _build_skill_test(params, bind)
		"repeat_fail_by":
			return _build_repeat_fail_by(params, bind)
		"resolve_location":
			return _build_resolve_location(params, bind)
		"nest_enemy_move":
			return _build_nest_enemy_move(params, bind)
		"nest_enemy_attack":
			return _build_nest_enemy_attack(params, bind)
		"exhaust_source":
			return CompositionNode.exhaust_card(bind.card_id)
		"exhaust_enemy":
			return CompositionNode.exhaust_enemy(
				bind.controller_id,
				StringName(str(params.get("enemy", "memory:picked_enemy"))),
				bind.card_id
			)
		"nest_move_connecting":
			## 兼容旧 JSON：展开为 select + nest_move_to。
			return CompositionNode.move_to_connecting(bind.controller_id)
		"nest_move_to", "move_to":
			return CompositionNode.nest_move_to(
				bind.controller_id,
				StringName(str(params.get("location", params.get("destination", "memory:picked_location")))),
				bind.card_id
			)
		"move_to_connecting":
			return CompositionNode.move_to_connecting(bind.controller_id)
		"lead_draw_topmost_encounter_discard_copy":
			return CompositionNode.lead_draw_topmost_encounter_discard_copy(
				StringName(str(params.get("definition_id", "12129")))
			)
		"gain_resources":
			return CompositionNode.nest_gain_resource(
				bind.controller_id, int(params.get("amount", 1))
			)
	return null


static func _build_resolve_location(params: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var target := StringName(str(params.get("target", "drawer_location")))
	return CompositionNode.nest_enemy_resolve_location(bind.controller_id, target)


static func _build_nest_enemy_move(params: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var exclude: Array[StringName] = []
	for trait_name in params.get("trait_exclude", []):
		exclude.append(StringName(str(trait_name)))
	return CompositionNode.nest_enemy_move(bind.controller_id, exclude)


static func _build_nest_enemy_attack(params: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var enemy_spec := str(params.get("enemy", ""))
	var target_spec := str(params.get("target", ""))
	if enemy_spec == "source" or enemy_spec == "self" or target_spec == "controller":
		return CompositionNode.nest_enemy_attack(bind.card_id, bind.controller_id)
	return CompositionNode.nest_enemy_attack_last()


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


static func _build_for_each_memory(params: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var list_key := StringName(str(params.get("memory_key", params.get("list_key", "picked_enemies"))))
	var each_key := StringName(str(params.get("each_key", params.get("bind_key", "picked_enemy"))))
	var body: CompositionNode = null
	var body_entry: Variant = params.get("body", null)
	if body_entry is Dictionary:
		body = build_composition(str((body_entry as Dictionary).get("template", "")), body_entry, bind)
	elif params.get("steps", null) is Array:
		body = _build_seq(params, bind)
	if body == null:
		return null
	return CompositionNode.for_each_memory(bind.controller_id, list_key, body, each_key)


## Optional / may：body 或 steps[] → OPTIONAL_EFFECT（默认跳过）。
static func _build_choice_optional(params: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var body: CompositionNode = null
	var body_entry: Variant = params.get("body", null)
	if body_entry is Dictionary:
		var body_dict := body_entry as Dictionary
		body = build_composition(str(body_dict.get("template", "")), body_dict, bind)
	elif params.get("steps", null) is Array and not (params.get("steps") as Array).is_empty():
		body = _build_seq(params, bind)
	if body == null:
		## 兼容：options[0] 当作唯一 body
		var options: Variant = params.get("options", [])
		if options is Array and not (options as Array).is_empty():
			var first: Variant = (options as Array)[0]
			if first is Dictionary:
				var opt := first as Dictionary
				body = build_composition(str(opt.get("template", "")), opt, bind)
	if body == null:
		return null
	var prompt_id := StringName(str(params.get("prompt_id", "composition:choice_optional")))
	var memory_key := StringName(str(params.get("memory_key", params.get("bind_key", ""))))
	return CompositionNode.choice_optional(body, bind.controller_id, prompt_id, memory_key)


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
	var register_as := str(entry.get("register_as", ""))
	var template_id := str(entry.get("template", ""))
	if template_id == "":
		return false
	var ability_id := StringName(str(entry.get("ability_id", "%s:0" % register_as)))
	var params := _params_from_entry(entry)
	var builder := func(bind: AbilityBindContext) -> CompositionNode:
		return build_composition(template_id, params, bind)
	if register_as == "revelation":
		CardRegistry.register_revelation(definition_id, ability_id, builder)
		return true
	if register_as == "free" or register_as == "action":
		var provokes: Variant = null
		if entry.has("provokes_aoo"):
			provokes = bool(entry.get("provokes_aoo"))
		CardRegistry.register_triggered(
			definition_id,
			ability_id,
			&"",
			AhcEnums.SequencePhase.AFTER,
			StringName(register_as),
			builder,
			int(entry.get("resource_cost", 0)),
			int(entry.get("action_cost", 0)),
			bool(entry.get("optional", false)),
			StringName(str(entry.get("window", "any_player_window"))),
			_action_types_from_entry(entry),
			provokes
		)
		return true
	if register_as == "forced" or register_as == "reaction":
		var match_kind := StringName(str(entry.get("match_kind", "")))
		if match_kind == &"":
			return false
		CardRegistry.register_triggered(
			definition_id,
			ability_id,
			match_kind,
			TriggeredAbilityDescriptor.phase_from_raw(entry.get("phase", "AFTER")),
			StringName(register_as),
			builder,
			int(entry.get("resource_cost", 0)),
			int(entry.get("action_cost", 0)),
			bool(entry.get("optional", false)),
			&"",
			_action_types_from_entry(entry),
			null
		)
		return true
	return false


static func _action_types_from_entry(entry: Dictionary) -> Array:
	var out: Array = []
	var raw: Variant = entry.get("action_types", [])
	if not raw is Array:
		return out
	for item in raw:
		out.append(str(item).to_lower())
	return out


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
		"window",
		"trait_exclude",
		"target",
		"enemy",
		"kind",
		"mode",
		"may_advance_agenda",
		"definition_id",
		"match_kind",
		"phase",
		"timing",
		"trait",
		"at",
		"card_id",
		"action_types",
		"per_investigator",
		"filter",
		"memory_key",
		"auto_engage",
		"location",
		"investigator",
		"translation",
		"field",
		"value",
		"flow_id",
		"mode",
	]:
		if entry.has(key):
			params[key] = entry[key]
	return params


static func _flag_field_from_raw(raw: Variant) -> AhcEnums.FlagField:
	match str(raw).to_lower():
		"eliminated":
			return AhcEnums.FlagField.ELIMINATED
		_:
			return AhcEnums.FlagField.RESIGNED
