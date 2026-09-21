class_name EffectFlowHandlers
extends RefCounted

## 纸面无名效果句的命名流程 handler（seq.effect.* · 07-composition §1.3.3）。
## L0 写入只出现在这里，不出现在卡面 Composition 树当效果本身。


static func take_horror(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var inv_id := _controller_id(game_ctx, params)
	var amount := maxi(int(params.get("amount", 1)), 1)
	if game_ctx == null or game_ctx.mutator == null or inv_id == &"":
		return {"ok": false, "amount": 0}
	if game_ctx.state.registry.get_investigator(inv_id) == null:
		return {"ok": false, "amount": 0, "error": "unknown_investigator"}
	game_ctx.mutator.take_horror(inv_id, amount)
	_log(
		game_ctx,
		"effect:take_horror",
		{"inv": inv_id, "amount": amount, "direct": bool(params.get("direct", false))}
	)
	return {"ok": true, "amount": amount, "inv_id": inv_id}


static func take_damage(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var inv_id := _controller_id(game_ctx, params)
	var amount := maxi(int(params.get("amount", 1)), 1)
	if game_ctx == null or game_ctx.mutator == null or inv_id == &"":
		return {"ok": false, "amount": 0}
	if game_ctx.state.registry.get_investigator(inv_id) == null:
		return {"ok": false, "amount": 0, "error": "unknown_investigator"}
	game_ctx.mutator.adjust_marker(
		MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.DAMAGE),
		amount
	)
	_log(
		game_ctx,
		"effect:take_damage",
		{"inv": inv_id, "amount": amount, "direct": bool(params.get("direct", false))}
	)
	return {"ok": true, "amount": amount, "inv_id": inv_id}


static func lose_resources(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var inv_id := _controller_id(game_ctx, params)
	var requested := maxi(int(params.get("amount", 1)), 1)
	if game_ctx == null or game_ctx.mutator == null or inv_id == &"":
		return {"ok": false, "amount": 0}
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "amount": 0, "error": "unknown_investigator"}
	var actual := mini(requested, inv.resource_pool)
	if actual <= 0:
		return {"ok": false, "amount": 0, "inv_id": inv_id}
	game_ctx.mutator.adjust_marker(
		MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.RESOURCE),
		-actual
	)
	_log(game_ctx, "effect:lose_resources", {"inv": inv_id, "amount": actual})
	return {"ok": true, "amount": actual, "inv_id": inv_id}


static func lose_all_resources(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var inv_id := _controller_id(game_ctx, params)
	if game_ctx == null or game_ctx.mutator == null or inv_id == &"":
		return {"ok": false, "amount": 0}
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "amount": 0, "error": "unknown_investigator"}
	var actual: int = inv.resource_pool
	if actual > 0:
		game_ctx.mutator.adjust_marker(
			MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.RESOURCE),
			-actual
		)
	_log(game_ctx, "effect:lose_all_resources", {"inv": inv_id, "amount": actual})
	return {"ok": actual > 0, "amount": actual, "inv_id": inv_id}


static func heal(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var inv_id := _controller_id(game_ctx, params)
	var amount := maxi(int(params.get("amount", 1)), 1)
	var kind := StringName(str(params.get("kind", "damage")))
	if game_ctx == null or game_ctx.mutator == null or inv_id == &"":
		return {"ok": false, "amount": 0}
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "amount": 0, "error": "unknown_investigator"}
	var marker := AhcEnums.MarkerKind.DAMAGE
	var current: int = inv.damage_taken
	if kind == &"horror":
		marker = AhcEnums.MarkerKind.HORROR_TAKEN
		current = inv.horror_taken
	var actual := mini(amount, current)
	if actual <= 0:
		return {"ok": false, "amount": 0, "inv_id": inv_id, "kind": kind}
	game_ctx.mutator.adjust_marker(MarkerSlot.investigator(inv_id, marker), -actual)
	_log(game_ctx, "effect:heal", {"inv": inv_id, "amount": actual, "kind": kind})
	return {"ok": true, "amount": actual, "inv_id": inv_id, "kind": kind}


static func lose_action(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var inv_id := _controller_id(game_ctx, params)
	var requested := maxi(int(params.get("amount", 1)), 1)
	if game_ctx == null or game_ctx.state == null or inv_id == &"":
		return {"ok": false, "amount": 0}
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "amount": 0, "error": "unknown_investigator"}
	var actual := mini(requested, inv.actions_remaining)
	if actual <= 0:
		return {"ok": false, "amount": 0, "inv_id": inv_id}
	inv.actions_remaining -= actual
	_log(game_ctx, "effect:lose_action", {"inv": inv_id, "amount": actual})
	return {"ok": true, "amount": actual, "inv_id": inv_id}


static func place_doom(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var target := StringName(str(params.get("target", "source")))
	var amount := maxi(int(params.get("amount", 1)), 1)
	var card_id: StringName = params.get("card_id", &"")
	var origin_id: StringName = params.get(
		"origin_id", params.get("controller_id", params.get("drawer_id", &""))
	)
	var placed := false
	match target:
		&"nearest_enemy_without_doom":
			placed = EncounterDoomPlacement.place_on_nearest_enemy_without_doom(
				game_ctx, origin_id, card_id
			)
		&"nearest_enemy_without_doom_to_source":
			placed = EncounterDoomPlacement.place_on_nearest_enemy_without_doom_from_origin(
				game_ctx, card_id, origin_id, card_id
			)
		_:
			placed = EncounterDoomPlacement.place_on_source(game_ctx, card_id, amount)
	return {"ok": placed, "target": target, "amount": amount if placed else 0}


static func place_clue(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var inv_id := _controller_id(game_ctx, params)
	var placed := InvestigatorCluePlacement.place_one_on_investigator_location(game_ctx, inv_id)
	return {"ok": placed, "inv_id": inv_id}


static func register_buff(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.registrations == null:
		return {"ok": false, "error": "no_store"}
	var template: Variant = params.get("template", null)
	if template is not RegistrationTemplate:
		return {"ok": false, "error": "invalid_template"}
	var reg_id := game_ctx.registrations.register(template as RegistrationTemplate)
	_log(game_ctx, "effect:register", {"reg": reg_id})
	if game_ctx.memory != null:
		game_ctx.memory.set_referent(
			(template as RegistrationTemplate).controller_id,
			&"last_register_id",
			reg_id
		)
	return {"ok": reg_id != &"", "reg_id": reg_id}


static func unregister_buff(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.registrations == null:
		return {"ok": false, "error": "no_store"}
	var reg_id: StringName = params.get("reg_id", &"")
	if reg_id == &"":
		return {"ok": false, "error": "missing_reg_id"}
	game_ctx.registrations.unregister(reg_id)
	_log(game_ctx, "effect:unregister", {"reg": reg_id})
	return {"ok": true, "reg_id": reg_id}


static func _controller_id(game_ctx: GameContext, params: Dictionary) -> StringName:
	var inv_id: StringName = params.get(
		"controller_id", params.get("inv_id", params.get("drawer_id", &""))
	)
	if inv_id != &"":
		return inv_id
	if game_ctx != null and game_ctx.sequences != null:
		var trigger := game_ctx.sequences.current_trigger()
		if trigger != null:
			return trigger.controller_id
	return &""


static func _log(game_ctx: GameContext, event: String, payload: Dictionary) -> void:
	if game_ctx != null and game_ctx.log != null:
		game_ctx.log.log(AhcEnums.LogCategory.CARD, event, payload)
