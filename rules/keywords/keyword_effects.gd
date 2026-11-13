class_name KeywordEffects
extends RefCounted

## 关键词与建局规则的开火体解释器。
## 规格写在 KeywordProfile.effect_*（静态 nest，与卡面 Composition 的 nest 叶同一语言）。
## 关键词在 seq.keyword.* 里解释；规则在 seq.rule.* 里解释。不为每条再写实现类。


## 规格门不成立时不压栈。
static func matches(game_ctx: GameContext, keyword: StringName, bind: Dictionary) -> bool:
	var profile := _profile(keyword)
	if profile == null:
		return false
	var card_id: StringName = bind.get("card_id", bind.get("enemy_id", &""))
	return _when_matches(profile.effect_when, bind, game_ctx, card_id)


static func resolve(game_ctx: GameContext, keyword: StringName, bind: Dictionary) -> Dictionary:
	var profile := _profile(keyword)
	if profile == null or (profile.effect_flow_id == &"" and profile.effect_steps.is_empty()):
		return {"ok": false, "reason": &"no_effect_spec", "keyword": keyword}
	var card_id: StringName = bind.get("card_id", bind.get("enemy_id", &""))
	_bind_owner(game_ctx, bind, card_id)
	if not _when_matches(profile.effect_when, bind, game_ctx, card_id):
		return {"ok": true, "skipped": true, "triggered": false, "keyword": keyword}
	if profile.effect_report == &"surge":
		var armed := KeywordMount.is_surge_armed(game_ctx, card_id)
		KeywordMount.unmount_gained_for_card(game_ctx, card_id)
		if not armed:
			return _surge_empty()
		if game_ctx == null or game_ctx.sequence_catalog == null:
			return _surge_empty(true)
	if not profile.effect_steps.is_empty():
		var last := {"ok": true}
		var any_moved := false
		for raw in profile.effect_steps:
			var step: Dictionary = raw
			var flow_id: StringName = step.get("flow_id", &"")
			var spec: Dictionary = step.get("params", {})
			last = _nest(game_ctx, flow_id, _bind_params(spec, bind, card_id))
			if bool(last.get("moved", false)):
				any_moved = true
		if any_moved:
			last["moved"] = true
		return last
	var params := _bind_params(profile.effect_params, bind, card_id)
	var nested := _nest(game_ctx, profile.effect_flow_id, params)
	if profile.effect_report == &"surge":
		return _surge_report(nested)
	return nested


static func _when_matches(
	when: Dictionary,
	bind: Dictionary,
	game_ctx: GameContext,
	card_id: StringName
) -> bool:
	if when.is_empty():
		return true
	if when.has("success") and bool(bind.get("success", false)) != bool(when["success"]):
		return false
	if when.has("skill") and int(bind.get("skill", -1)) != int(when["skill"]):
		return false
	if _action_is_exempt(when, bind):
		return false
	if bool(when.get("respect_skip_aoo", false)):
		var skip_inv: StringName = bind.get("investigator_id", &"")
		if (
			game_ctx != null
			and game_ctx.registrations != null
			and game_ctx.registrations.read_skip_aoo(skip_inv)
		):
			return false
	if bool(when.get("fight_damage_positive", false)) and int(bind.get("fight_damage", 0)) <= 0:
		return false
	if bool(when.get("not_massive", false)) or bool(when.get("other_threat_holder", false)):
		if game_ctx == null or game_ctx.state == null:
			return false
		var ruled_enemy := game_ctx.state.registry.get_enemy(card_id)
		if ruled_enemy == null:
			return false
		if bool(when.get("not_massive", false)) and ruled_enemy.massive:
			return false
		if bool(when.get("other_threat_holder", false)):
			var attacker_id: StringName = bind.get("investigator_id", &"")
			if ThreatAreaQuery.other_engaged_holder(game_ctx, card_id, attacker_id) == &"":
				return false
	if not bool(when.get("ready", false)) and not bool(when.get("same_location", false)):
		return true
	if game_ctx == null or game_ctx.state == null:
		return false
	var enemy := game_ctx.state.registry.get_enemy(card_id)
	if enemy == null:
		return false
	if bool(when.get("ready", false)) and enemy.exhausted:
		return false
	if bool(when.get("same_location", false)):
		var inv_id: StringName = bind.get("investigator_id", &"")
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null or not enemy.is_at_location(inv.location_tag):
			return false
	return true


static func _profile(keyword: StringName) -> KeywordProfile:
	var profile := KeywordProfileTable.profile_for(keyword)
	if profile != null:
		return profile
	return RuleProfileTable.profile_for(keyword)


static func _action_is_exempt(when: Dictionary, bind: Dictionary) -> bool:
	if not when.has("exempt_actions"):
		return false
	var types: Variant = bind.get("action_types", [])
	if not (types is Array) or (types as Array).is_empty():
		return false
	var exempt: Array = when["exempt_actions"]
	for raw in types:
		var kind := int(raw)
		for item in exempt:
			if int(item) == kind:
				return true
	return false


static func _nest(game_ctx: GameContext, flow_id: StringName, params: Dictionary) -> Dictionary:
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(flow_id)
	):
		## 入手是 NEST_BATCH，不是 RUN。
		if flow_id == &"seq.enter_hand":
			return game_ctx.sequence_catalog.nest_batch(game_ctx, flow_id, params)
		return game_ctx.sequence_catalog.nest(game_ctx, flow_id, params)
	if flow_id == &"seq.effect.move":
		return MoveFlow.run(game_ctx, params)
	return {"ok": false, "reason": &"missing_flow", "flow_id": flow_id}


## 卡能反查拥有者。规格里的 `$owner_id` 用这名调查员当检索控制者。
static func _bind_owner(game_ctx: GameContext, bind: Dictionary, card_id: StringName) -> void:
	if str(bind.get("owner_id", "")) != "":
		return
	if game_ctx == null or game_ctx.state == null or card_id == &"":
		return
	var card := game_ctx.state.registry.get_card(card_id)
	if card != null and card.owner_id != &"":
		bind["owner_id"] = card.owner_id


static func _bind_params(
	spec: Dictionary,
	bind: Dictionary,
	card_id: StringName
) -> Dictionary:
	var out := {}
	for key in spec.keys():
		var value: Variant = spec[key]
		if value is String or value is StringName:
			var text := str(value)
			if text.begins_with("$"):
				var ref := text.substr(1)
				if ref == "card_id":
					out[key] = card_id
				elif ref == "enemy_id":
					var enemy_id: StringName = bind.get("enemy_id", &"")
					out[key] = enemy_id if enemy_id != &"" else card_id
				else:
					out[key] = bind.get(ref, bind.get(StringName(ref), &""))
				continue
		out[key] = value
	return out


static func _surge_report(nested: Dictionary) -> Dictionary:
	var cards: Array[StringName] = []
	var revelations: Array[StringName] = []
	var spawn_failed: Array[StringName] = []
	_append_ids(cards, nested.get("cards", []))
	_append_ids(revelations, nested.get("revelations", []))
	_append_ids(spawn_failed, nested.get("spawn_failed_discards", []))
	return {
		"ok": bool(nested.get("ok", false)),
		"surged": true,
		"cards": cards,
		"surge_depth": 1 + int(nested.get("surge_depth", 0)),
		"revelations": revelations,
		"spawn_failed_discards": spawn_failed,
		"shuffles": int(nested.get("shuffles", 0)),
	}


static func _surge_empty(surged: bool = false) -> Dictionary:
	return {
		"ok": true,
		"surged": surged,
		"cards": [] as Array[StringName],
		"surge_depth": 1 if surged else 0,
		"revelations": [] as Array[StringName],
		"spawn_failed_discards": [] as Array[StringName],
		"shuffles": 0,
	}


static func _append_ids(dst: Array[StringName], src: Variant) -> void:
	if not (src is Array):
		return
	for item in src:
		dst.append(item as StringName)
