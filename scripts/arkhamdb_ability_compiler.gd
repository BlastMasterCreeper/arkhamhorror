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


## 统一 IR（20 §2）：优先读 `op`；旧 `template` 糖仍可走。
static func build_node(node: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	if node.has("op"):
		return _build_op_node(node, bind)
	if node.has("effect") and node["effect"] is Dictionary:
		return build_node(node["effect"] as Dictionary, bind)
	var template_id := str(node.get("template", ""))
	if template_id == "":
		return null
	return build_composition(template_id, node, bind)


static func _build_op_node(node: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var op := str(node.get("op", ""))
	match op:
		"seq":
			return _build_seq(node, bind)
		"simultaneous":
			return _build_simultaneous(node, bind)
		"if":
			return _build_if_else(node, bind)
		"pi":
			return _build_pi(node, bind)
		"invoke", "nest":
			## invoke = 翻译层「调用命名流程」；nest 仅过渡别名（≠ 规则嵌套序列）。
			return _build_invoke_flow(node, bind)
		"inline":
			var atom := str(node.get("atom", ""))
			var inline_params: Dictionary = {}
			if node.get("params", null) is Dictionary:
				inline_params = (node["params"] as Dictionary).duplicate()
			else:
				inline_params = node.duplicate()
				inline_params.erase("op")
				inline_params.erase("atom")
			return build_composition(atom, inline_params, bind)
	return null


static func _build_pi(node: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var kind := str(node.get("kind", "select")).to_lower()
	var params := node.duplicate()
	params.erase("op")
	match kind:
		"multi":
			return build_composition("pick_multi", params, bind)
		"option":
			return build_composition("choice_must", params, bind)
		"optional":
			return build_composition("choice_optional", params, bind)
		_:
			return build_composition("pick_target", params, bind)


static func _build_invoke_flow(node: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var flow_id := str(node.get("flow_id", ""))
	var params: Dictionary = {}
	if node.get("params", null) is Dictionary:
		params = (node["params"] as Dictionary).duplicate()
	else:
		## 过渡：扁平字段当 params。
		params = node.duplicate()
		params.erase("op")
		params.erase("flow_id")
		params.erase("params")
	match flow_id:
		"seq.effect.place_token":
			return build_composition("place_token", params, bind)
		"seq.effect.spend_token":
			return build_composition("spend_token", params, bind)
		"seq.effect.register":
			if params.has("stat"):
				return build_composition("register_modifier", params, bind)
			return build_composition("register_modifier", params, bind)
		"seq.skill_test":
			return build_composition("nest_skill_test", params, bind)
		"seq.effect.damage":
			## 敌人目标 → deal_damage_enemy；其余 nest_deal_damage / take。
			var target := str(params.get("target", params.get("enemy", "")))
			var kind := str(params.get("kind", "damage")).to_lower()
			if kind == "horror":
				var horror_params := params.duplicate()
				horror_params["target"] = target if target != "" else "controller"
				return build_composition("take_horror", horror_params, bind)
			if target.begins_with("memory:") or target == "memory:picked_enemy":
				var enemy_params := params.duplicate()
				enemy_params["enemy"] = target
				return build_composition("deal_damage_enemy", enemy_params, bind)
			if str(params.get("enemy", "")) != "":
				return build_composition("deal_damage_enemy", params, bind)
			var dmg_params := params.duplicate()
			dmg_params["target"] = target if target != "" else "controller"
			return build_composition("deal_damage", dmg_params, bind)
		"seq.draw.investigator":
			return build_composition("nest_draw_investigator", params, bind)
		"seq.engage":
			return build_composition("nest_engage", params, bind)
		"seq.effect.move":
			var subject := str(params.get("subject", "investigator"))
			if subject == "enemy":
				return build_composition("nest_enemy_move_to", params, bind)
			return build_composition("nest_move_to", params, bind)
		"seq.effect.resign":
			return build_composition("nest_resign", params, bind)
		"seq.effect.discover_clue":
			return build_composition("discover_clue", params, bind)
		"seq.effect.exhaust":
			var exh_card := str(params.get("card_id", "source"))
			if exh_card == "source" or exh_card == "":
				return build_composition("exhaust_source", params, bind)
			return CompositionNode.exhaust_card(StringName(exh_card))
	## 未映射 flow：尝试用旧 template 糖名（若有）。
	var legacy := str(node.get("template", ""))
	if legacy != "":
		return build_composition(legacy, params, bind)
	return null


static func build_composition(
	template_id: String,
	params: Dictionary,
	bind: AbilityBindContext
) -> CompositionNode:
	## 仅空 template 时走 IR；已指定 template 时忽略残留 `op`，避免 pi→build_composition 死循环。
	if template_id == "" and params.has("op"):
		return build_node(params, bind)
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
			## kind 默认 damage；target 默认 controller；source = 装载 card_id。
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
		"discard_card", "discard_from_hand":
			## 统一 nest seq.effect.discard_card；discard_from_hand 糖 → from=hand。
			var discard_from := StringName(str(params.get("from", "")))
			if template_id == "discard_from_hand" and discard_from == &"":
				discard_from = &"hand"
			var discard_mode := str(params.get("mode", "choose" if discard_from == &"" else "random"))
			var discard_card_id := str(params.get("card_id", ""))
			if discard_card_id == "source":
				discard_card_id = str(bind.card_id)
			return CompositionNode.nest_discard_card(
				StringName(discard_card_id),
				bind.controller_id,
				StringName(str(params.get("trait", ""))),
				StringName(str(params.get("at", ""))),
				StringName(discard_mode),
				discard_from,
				int(params.get("amount", 1))
			)
		"nest_draw_investigator", "draw":
			## draw = 旧 JSON 别名；新译用 nest_draw_investigator + flow_id。
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
		"deal_damage_enemy":
			return CompositionNode.deal_damage_enemy(
				bind.controller_id,
				StringName(str(params.get("enemy", "memory:picked_enemy"))),
				int(params.get("amount", 1)),
				bind.card_id
			)
		"place_token":
			var place_card := str(params.get("card_id", "source"))
			var place_id := bind.card_id if place_card == "source" or place_card == "" else StringName(place_card)
			return CompositionNode.nest_place_token(
				bind.controller_id,
				place_id,
				StringName(str(params.get("kind", "ammo"))),
				int(params.get("amount", 1))
			)
		"spend_token":
			var spend_card := str(params.get("card_id", "source"))
			var spend_id := bind.card_id if spend_card == "source" or spend_card == "" else StringName(spend_card)
			return CompositionNode.nest_spend_token(
				bind.controller_id,
				spend_id,
				StringName(str(params.get("kind", "ammo"))),
				int(params.get("amount", 1))
			)
		"discover_clue":
			return CompositionNode.nest_discover_clue(
				bind.controller_id,
				StringName(str(params.get("location_id", params.get("location", "")))),
				int(params.get("amount", 1))
			)
		"register_modifier":
			return _build_register_modifier(params, bind)
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
		"pick_option":
			var oids: Array = []
			for raw in params.get("options", []):
				if raw is Dictionary:
					oids.append(StringName(str((raw as Dictionary).get("id", raw))))
				else:
					oids.append(StringName(str(raw)))
			return CompositionNode.pick_option(
				bind.controller_id,
				oids,
				StringName(str(params.get("prompt_id", "pick:option"))),
				StringName(str(params.get("memory_key", "picked_option")))
			)
		"place_doom_on_current_agenda":
			return CompositionNode.nest_mythos_place_doom(
				bool(params.get("may_advance_agenda", false))
			)
		"place_clue_on_location":
			return CompositionNode.nest_place_clue(bind.controller_id)
		"skill_test", "nest_skill_test":
			## nest_skill_test：应展尽展（JSON 带 flow_id: seq.skill_test）。
			return _build_skill_test(params, bind)
		"repeat_fail_by":
			return _build_repeat_fail_by(params, bind)
		"nest_enemy_resolve_location", "resolve_location":
			## resolve_location = 旧 JSON 别名；须带 flow_id。
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
			var node := build_node(step as Dictionary, bind)
			if node != null:
				nodes.append(node)
	if nodes.is_empty():
		return null
	return CompositionNode.seq(nodes)


static func _build_simultaneous(params: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	## CompositionNodeKind 尚无 SIMULTANEOUS；翻译层已区分 op，运行时暂降为 seq。
	return _build_seq(params, bind)


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
		body = build_node(body_entry as Dictionary, bind)
	elif params.get("steps", null) is Array and not (params.get("steps") as Array).is_empty():
		body = _build_seq(params, bind)
	if body == null:
		## 兼容：options[0] 当作唯一 body
		var options: Variant = params.get("options", [])
		if options is Array and not (options as Array).is_empty():
			var first: Variant = (options as Array)[0]
			if first is Dictionary:
				body = build_node(first as Dictionary, bind)
	if body == null:
		return null
	var prompt_id := StringName(str(params.get("prompt_id", "composition:choice_optional")))
	var memory_key := StringName(str(params.get("memory_key", params.get("bind_key", ""))))
	return CompositionNode.choice_optional(body, bind.controller_id, prompt_id, memory_key)


static func _build_skill_test(params: Dictionary, bind: AbilityBindContext) -> CompositionNode:
	var difficulty := int(params.get("difficulty", 0))
	var difficulty_source := StringName(str(params.get("difficulty_source", "")))
	var enemy_spec := StringName(str(params.get("enemy", "")))
	var location_spec := StringName(str(params.get("location", params.get("location_id", ""))))
	var plan := _build_st7_plan(params, bind)
	var choices: Variant = params.get("skill_choices", [])
	## skill_choices：PI 只选技能类型 → 单次 skill_test（体不重复）。
	if choices is Array and not (choices as Array).is_empty():
		var option_ids: Array = []
		for raw in choices as Array:
			option_ids.append(StringName(str(raw)))
		var mem_key := StringName(str(params.get("memory_key", "picked_skill")))
		var prompt := StringName(str(params.get("prompt_id", "skill_test:choose_skill")))
		var pick := CompositionNode.pick_option(
			bind.controller_id, option_ids, prompt, mem_key
		)
		var first_skill := _skill_from_compile_id(str(option_ids[0]))
		var test := CompositionNode.nest_skill_test(
			bind.controller_id,
			first_skill,
			difficulty,
			bind.card_id,
			plan,
			difficulty_source,
			StringName("memory:%s" % str(mem_key)),
			enemy_spec,
			location_spec
		)
		return CompositionNode.seq([pick, test])
	var skill_raw := str(params.get("skill", "willpower"))
	var skill_spec := StringName(&"")
	if skill_raw.begins_with("memory:"):
		skill_spec = StringName(skill_raw)
	var skill := _skill_from_compile_id(skill_raw)
	return CompositionNode.nest_skill_test(
		bind.controller_id,
		skill,
		difficulty,
		bind.card_id,
		plan,
		difficulty_source,
		skill_spec,
		enemy_spec,
		location_spec
	)


static func _build_register_modifier(
	params: Dictionary,
	bind: AbilityBindContext
) -> CompositionNode:
	var amount := int(params.get("amount", 1))
	if amount == 0:
		return null
	var stat := _stat_ref_from_compile_id(str(params.get("stat", "combat")))
	var duration := _duration_from_compile_id(str(params.get("duration", "this_skill_test")))
	var payload := ModifierPayload.add_skill(stat, amount)
	var template := RegistrationTemplate.lasting_modifier(
		bind.controller_id, duration, payload
	)
	return CompositionNode.nest_effect_register(template)


static func _stat_ref_from_compile_id(stat_id: String) -> AhcEnums.StatRef:
	match stat_id.to_lower():
		"intellect":
			return AhcEnums.StatRef.SKILL_INTELLECT
		"combat":
			return AhcEnums.StatRef.SKILL_COMBAT
		"agility":
			return AhcEnums.StatRef.SKILL_AGILITY
		_:
			return AhcEnums.StatRef.SKILL_WILLPOWER


static func _duration_from_compile_id(duration_id: String) -> AhcEnums.DurationAnchorKind:
	match duration_id.to_lower():
		"this_turn":
			return AhcEnums.DurationAnchorKind.THIS_TURN
		"this_phase":
			return AhcEnums.DurationAnchorKind.THIS_PHASE
		"this_round":
			return AhcEnums.DurationAnchorKind.THIS_ROUND
		_:
			return AhcEnums.DurationAnchorKind.THIS_SKILL_TEST


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
		then_node = build_node(then_entry as Dictionary, bind)
	if else_entry is Dictionary:
		var else_dict := else_entry as Dictionary
		var else_tpl := str(else_dict.get("template", ""))
		if else_dict.has("op") or (else_tpl != "" and else_tpl != "uncompiled"):
			else_node = build_node(else_dict, bind)
	return CompositionNode.if_else(cond, then_node, else_node, bind.controller_id)


static func _register_entry(definition_id: StringName, entry: Dictionary) -> bool:
	var register_as := str(entry.get("register_as", ""))
	var template_id := str(entry.get("template", ""))
	var effect_entry: Variant = entry.get("effect", null)
	var has_effect := effect_entry is Dictionary and not (effect_entry as Dictionary).is_empty()
	if template_id == "" and not has_effect:
		return false
	var ability_id := StringName(str(entry.get("ability_id", "%s:0" % register_as)))
	var params := _params_from_entry(entry)
	var builder := func(bind: AbilityBindContext) -> CompositionNode:
		if has_effect:
			return build_node(effect_entry as Dictionary, bind)
		return build_composition(template_id, params, bind)
	if register_as == "revelation":
		CardRegistry.register_revelation(definition_id, ability_id, builder)
		return true
	if register_as == "keyword":
		var hook: Variant = entry.get("hook", {})
		var hook_seq := &"seq.zone.move"
		var hook_slot := &"ENTER_PLAY"
		if hook is Dictionary:
			if str((hook as Dictionary).get("sequence_id", "")) != "":
				hook_seq = StringName(str((hook as Dictionary).get("sequence_id")))
			if str((hook as Dictionary).get("slot", "")) != "":
				hook_slot = StringName(str((hook as Dictionary).get("slot")))
		CardRegistry.register_keyword_ability(
			definition_id,
			ability_id,
			StringName(str(entry.get("keyword", ""))),
			hook_seq,
			hook_slot,
			builder
		)
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
			provokes,
			_spend_token_costs_from_gates(entry)
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
			null,
			_spend_token_costs_from_gates(entry)
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


## gates[] → Initiation spend_token_costs（L6）；token 字段映射为 kind。
static func _spend_token_costs_from_gates(entry: Dictionary) -> Array:
	var out: Array = []
	var gates: Variant = entry.get("gates", [])
	if not gates is Array:
		return out
	for raw in gates:
		if not raw is Dictionary:
			continue
		var g: Dictionary = raw
		if str(g.get("kind", "")) != "cost":
			continue
		if str(g.get("cost", "")) != "spend_token":
			continue
		var token := str(g.get("token", g.get("kind_token", "ammo")))
		out.append(
			{
				"kind": token,
				"amount": maxi(int(g.get("amount", 1)), 1),
				"card_id": str(g.get("card_id", "source")),
			}
		)
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
		"skill_choices",
		"difficulty",
		"difficulty_source",
		"st7_fail_by",
		"st7",
		"window",
		"trait_exclude",
		"target",
		"enemy",
		"kind",
		"mode",
		"from",
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
		"stat",
		"duration",
		"hook",
		"keyword",
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
