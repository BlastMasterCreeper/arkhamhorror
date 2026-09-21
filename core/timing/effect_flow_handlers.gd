class_name EffectFlowHandlers
extends RefCounted

## 纸面无名效果句的命名流程 handler（seq.effect.* · 07-composition §1.3.3）。
## L0 写入只出现在这里，不出现在卡面 Composition 树当效果本身。


static func take_horror(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var amount := maxi(int(params.get("amount", 1)), 1)
	var target := StringName(str(params.get("target", "controller")))
	if game_ctx == null or game_ctx.mutator == null:
		return {"ok": false, "amount": 0}
	var applied := 0
	match target:
		&"each_at_controller_location", &"each_at_source_location":
			var loc_id := _location_for_target(game_ctx, params, target)
			if loc_id == &"":
				return {"ok": false, "amount": 0}
			for other_id in game_ctx.state.registry.all_investigator_ids():
				var other := game_ctx.state.registry.get_investigator(other_id)
				if other == null or other.eliminated or other.resigned:
					continue
				if other.location_tag != loc_id:
					continue
				game_ctx.mutator.take_horror(other_id, amount)
				applied += amount
		_:
			var inv_id := _controller_id(game_ctx, params)
			if inv_id == &"" or game_ctx.state.registry.get_investigator(inv_id) == null:
				return {"ok": false, "amount": 0, "error": "unknown_investigator"}
			game_ctx.mutator.take_horror(inv_id, amount)
			applied = amount
	_log(
		game_ctx,
		"effect:take_horror",
		{"target": target, "amount": applied, "direct": bool(params.get("direct", false))}
	)
	return {"ok": applied > 0, "amount": applied, "target": target}


static func take_damage(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var amount := maxi(int(params.get("amount", 1)), 1)
	var target := StringName(str(params.get("target", "controller")))
	if game_ctx == null or game_ctx.mutator == null:
		return {"ok": false, "amount": 0}
	var applied := 0
	match target:
		&"each_at_controller_location", &"each_at_source_location":
			var loc_id := _location_for_target(game_ctx, params, target)
			if loc_id == &"":
				return {"ok": false, "amount": 0}
			for other_id in game_ctx.state.registry.all_investigator_ids():
				var other := game_ctx.state.registry.get_investigator(other_id)
				if other == null or other.eliminated or other.resigned:
					continue
				if other.location_tag != loc_id:
					continue
				game_ctx.mutator.adjust_marker(
					MarkerSlot.investigator(other_id, AhcEnums.MarkerKind.DAMAGE),
					amount
				)
				applied += amount
		_:
			var inv_id := _controller_id(game_ctx, params)
			if inv_id == &"" or game_ctx.state.registry.get_investigator(inv_id) == null:
				return {"ok": false, "amount": 0, "error": "unknown_investigator"}
			game_ctx.mutator.adjust_marker(
				MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.DAMAGE),
				amount
			)
			applied = amount
	_log(
		game_ctx,
		"effect:take_damage",
		{"target": target, "amount": applied, "direct": bool(params.get("direct", false))}
	)
	return {"ok": applied > 0, "amount": applied, "target": target}


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


static func discard_card(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var card_id: StringName = params.get("card_id", &"")
	var inv_id := _controller_id(game_ctx, params)
	if game_ctx == null or card_id == &"":
		return {"ok": false, "error": "invalid_params"}
	var card := game_ctx.state.registry.get_card(card_id) if game_ctx.state != null else null
	if card == null:
		return {"ok": false, "error": "unknown_card"}
	var ok := false
	if card.owner_id == &"encounter":
		ok = EncounterCardDiscard.discard_from_investigator_to_encounter_pile(
			game_ctx, card_id, inv_id if inv_id != &"" else card.controller_id
		)
	elif game_ctx.mutator != null:
		ok = game_ctx.mutator.discard_from_hand(card_id, inv_id)
		if not ok:
			ok = game_ctx.mutator.move_card(card_id, CardSlot.discard_top(inv_id))
	if ok and game_ctx.triggered_abilities != null:
		game_ctx.triggered_abilities.uninstall_by_source(card_id)
	_log(game_ctx, "effect:discard_card", {"card": card_id, "inv": inv_id})
	return {"ok": ok, "card_id": card_id}


static func discard_from_hand(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var inv_id := _controller_id(game_ctx, params)
	var amount := maxi(int(params.get("amount", 1)), 1)
	var mode := StringName(str(params.get("mode", "random")))
	if game_ctx == null or game_ctx.mutator == null or inv_id == &"":
		return {"ok": false, "amount": 0}
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null or inv.hand.is_empty():
		return {"ok": false, "amount": 0, "inv_id": inv_id}
	var discarded: Array[StringName] = []
	var n := mini(amount, inv.hand.size())
	for _i in n:
		var pick: StringName = &""
		if mode == &"random":
			pick = inv.hand[randi() % inv.hand.size()] as StringName
		elif game_ctx.interaction != null:
			var chosen: Variant = game_ctx.interaction.ask_pick_target(
				inv.hand.duplicate(), inv_id, &"pick:discard_from_hand", game_ctx
			)
			if chosen != null:
				pick = chosen as StringName
		if pick == &"" and not inv.hand.is_empty():
			pick = inv.hand[0] as StringName
		if pick == &"":
			break
		if game_ctx.mutator.discard_from_hand(pick, inv_id):
			discarded.append(pick)
	_log(
		game_ctx,
		"effect:discard_from_hand",
		{"inv": inv_id, "amount": discarded.size(), "mode": mode}
	)
	return {"ok": not discarded.is_empty(), "amount": discarded.size(), "cards": discarded}


static func attach(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var card_id: StringName = params.get("card_id", &"")
	var inv_id := _controller_id(game_ctx, params)
	var target := StringName(str(params.get("target", "nearest_without_same")))
	if game_ctx == null or card_id == &"":
		return {"ok": false}
	var ok := false
	match target:
		&"controller_location":
			var inv := game_ctx.state.registry.get_investigator(inv_id)
			if inv != null and inv.location_tag != &"":
				ok = EncounterAttachment.attach_limbo_to_location(
					game_ctx, card_id, inv.location_tag
				)
		_:
			ok = EncounterAttachment.attach_limbo_to_nearest_location_without(
				game_ctx, card_id, inv_id
			)
	if ok and game_ctx.triggered_abilities != null:
		game_ctx.triggered_abilities.install_card(
			inv_id if inv_id != &"" else &"encounter", card_id
		)
	_log(game_ctx, "effect:attach", {"card": card_id, "target": target, "ok": ok})
	return {"ok": ok, "card_id": card_id, "target": target}


static func deal_damage(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var amount := maxi(int(params.get("amount", 1)), 1)
	var target := StringName(str(params.get("target", "controller")))
	var inv_id := _controller_id(game_ctx, params)
	if game_ctx == null or game_ctx.mutator == null:
		return {"ok": false, "amount": 0}
	var dealt := 0
	match target:
		&"each_at_controller_location":
			var origin := game_ctx.state.registry.get_investigator(inv_id)
			if origin == null or origin.location_tag == &"":
				return {"ok": false, "amount": 0}
			for other_id in game_ctx.state.registry.all_investigator_ids():
				var other := game_ctx.state.registry.get_investigator(other_id)
				if other == null or other.eliminated or other.resigned:
					continue
				if other.location_tag != origin.location_tag:
					continue
				game_ctx.mutator.adjust_marker(
					MarkerSlot.investigator(other_id, AhcEnums.MarkerKind.DAMAGE),
					amount
				)
				dealt += amount
		&"non_elite_with_health_at_attached_location":
			dealt = _deal_non_elite_with_health_at_attached(game_ctx, params, amount)
		&"enemy":
			var enemy_id: StringName = params.get("enemy_id", params.get("card_id", &""))
			var enemy := game_ctx.state.registry.get_enemy(enemy_id)
			if enemy == null:
				return {"ok": false, "amount": 0}
			var result := EnemyDefeatResolver.deal_damage(game_ctx, enemy_id, amount)
			dealt = amount if bool(result.get("ok", false)) else 0
		_:
			if inv_id == &"" or game_ctx.state.registry.get_investigator(inv_id) == null:
				return {"ok": false, "amount": 0}
			game_ctx.mutator.adjust_marker(
				MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.DAMAGE),
				amount
			)
			dealt = amount
	_log(
		game_ctx,
		"effect:deal_damage",
		{"target": target, "amount": dealt, "inv": inv_id}
	)
	return {"ok": dealt > 0, "amount": dealt, "target": target}


static func _deal_non_elite_with_health_at_attached(
	game_ctx: GameContext,
	params: Dictionary,
	amount: int
) -> int:
	var loc_id := _attached_location_id(game_ctx, params.get("card_id", &"") as StringName)
	if loc_id == &"":
		return 0
	var dealt := 0
	for other_id in game_ctx.state.registry.all_investigator_ids():
		var other := game_ctx.state.registry.get_investigator(other_id)
		if other == null or other.eliminated or other.resigned:
			continue
		if other.location_tag != loc_id:
			continue
		game_ctx.mutator.adjust_marker(
			MarkerSlot.investigator(other_id, AhcEnums.MarkerKind.DAMAGE),
			amount
		)
		dealt += amount
	for enemy_id in game_ctx.state.registry.all_enemy_ids():
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy == null or enemy.location_tag != loc_id:
			continue
		var card := game_ctx.state.registry.get_card(enemy_id)
		if card != null and _has_elite_trait(card.id.definition_id):
			continue
		var result := EnemyDefeatResolver.deal_damage(game_ctx, enemy_id, amount)
		if bool(result.get("ok", false)):
			dealt += amount
	return dealt


static func _location_for_target(
	game_ctx: GameContext,
	params: Dictionary,
	target: StringName
) -> StringName:
	if target == &"each_at_source_location":
		var source_id: StringName = params.get("card_id", params.get("enemy_id", &""))
		var enemy := game_ctx.state.registry.get_enemy(source_id)
		if enemy != null:
			return enemy.location_tag
		var card := game_ctx.state.registry.get_card(source_id)
		if card != null and card.attached_to != null:
			return _attached_location_id(game_ctx, source_id)
	var inv_id := _controller_id(game_ctx, params)
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null:
		return &""
	return inv.location_tag


static func _attached_location_id(game_ctx: GameContext, card_id: StringName) -> StringName:
	if game_ctx == null or card_id == &"":
		return &""
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null or card.attached_to == null:
		return &""
	var host_id := card.attached_to.instance_id
	if game_ctx.state.registry.get_location(host_id) != null:
		return host_id
	if game_ctx.state.registry.get_location(card.attached_to.definition_id) != null:
		return card.attached_to.definition_id
	return host_id


static func _has_elite_trait(definition_id: StringName) -> bool:
	for trait_name in CardRegistry.traits(definition_id):
		if str(trait_name).to_lower() == "elite":
			return true
	return false


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
