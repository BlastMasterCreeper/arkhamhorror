class_name EffectFlowHandlers
extends RefCounted

## 纸面无名效果句的命名流程 handler（seq.effect.* · 07-composition §1.3.3）。
## L0 写入只出现在这里，不出现在卡面 Composition 树当效果本身。


## 造成伤害/恐惧（Dealing Damage/Horror）· take/deal 同 seq；用 kind + source + target。
static func damage(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var kind := StringName(str(params.get("kind", "damage")))
	var amount := maxi(int(params.get("amount", 1)), 1)
	var target := StringName(str(params.get("target", "controller")))
	var inv_id := _controller_id(game_ctx, params)
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
				applied += _apply_to_investigator(game_ctx, other_id, kind, amount)
		&"non_elite_with_health_at_attached_location":
			if kind != &"damage":
				return {"ok": false, "amount": 0, "error": "horror_not_supported_for_target"}
			applied = _deal_non_elite_with_health_at_attached(game_ctx, params, amount)
		&"enemy":
			if kind != &"damage":
				return {"ok": false, "amount": 0, "error": "horror_not_supported_for_enemy"}
			var enemy_id: StringName = params.get("enemy_id", params.get("card_id", &""))
			if game_ctx.state.registry.get_enemy(enemy_id) == null:
				return {"ok": false, "amount": 0}
			var result := EnemyDefeatResolver.deal_damage(game_ctx, enemy_id, amount)
			applied = amount if bool(result.get("ok", false)) else 0
		_:
			if inv_id == &"" or game_ctx.state.registry.get_investigator(inv_id) == null:
				return {"ok": false, "amount": 0, "error": "unknown_investigator"}
			applied = _apply_to_investigator(game_ctx, inv_id, kind, amount)
	_log(
		game_ctx,
		"effect:damage",
		{
			"kind": kind,
			"target": target,
			"amount": applied,
			"source": params.get("source", params.get("card_id", &"")),
			"direct": bool(params.get("direct", false)),
		}
	)
	return {"ok": applied > 0, "amount": applied, "kind": kind, "target": target}


static func take_horror(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var p := params.duplicate()
	p["kind"] = &"horror"
	return damage(game_ctx, p)


static func take_damage(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var p := params.duplicate()
	p["kind"] = &"damage"
	return damage(game_ctx, p)


static func deal_damage(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var p := params.duplicate()
	p["kind"] = &"damage"
	return damage(game_ctx, p)


static func lose_resources(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var inv_id := _controller_id(game_ctx, params)
	if game_ctx == null or game_ctx.mutator == null or inv_id == &"":
		return {"ok": false, "amount": 0}
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "amount": 0, "error": "unknown_investigator"}
	var all_mode := bool(params.get("all", false))
	var requested := inv.resource_pool if all_mode else maxi(int(params.get("amount", 1)), 1)
	var actual := mini(requested, inv.resource_pool)
	if actual <= 0:
		return {"ok": false, "amount": 0, "inv_id": inv_id}
	game_ctx.mutator.adjust_marker(
		MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.RESOURCE),
		-actual
	)
	_log(game_ctx, "effect:lose_resources", {"inv": inv_id, "amount": actual, "all": all_mode})
	return {"ok": true, "amount": actual, "inv_id": inv_id}


static func lose_all_resources(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var p := params.duplicate()
	p["all"] = true
	return lose_resources(game_ctx, p)


static func heal(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var inv_id := _controller_id(game_ctx, params)
	var kind := StringName(str(params.get("kind", "damage")))
	var amount := maxi(int(params.get("amount", 1)), 1)
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
		return {"ok": false, "amount": 0, "inv_id": inv_id}
	game_ctx.mutator.adjust_marker(MarkerSlot.investigator(inv_id, marker), -actual)
	_log(game_ctx, "effect:heal", {"inv": inv_id, "kind": kind, "amount": actual})
	return {"ok": true, "amount": actual, "inv_id": inv_id, "kind": kind}


static func lose_action(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var inv_id := _controller_id(game_ctx, params)
	var amount := maxi(int(params.get("amount", 1)), 1)
	if game_ctx == null or game_ctx.state == null or inv_id == &"":
		return {"ok": false, "amount": 0}
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "amount": 0, "error": "unknown_investigator"}
	var actual := mini(amount, inv.actions_remaining)
	inv.actions_remaining = maxi(inv.actions_remaining - actual, 0)
	_log(game_ctx, "effect:lose_action", {"inv": inv_id, "amount": actual})
	return {"ok": actual > 0, "amount": actual, "inv_id": inv_id}


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
	var inv_id := _controller_id(game_ctx, params)
	var card_id: StringName = params.get("card_id", &"")
	if game_ctx == null:
		return {"ok": false, "error": "invalid_params"}
	if card_id == &"":
		card_id = _pick_discard_target(game_ctx, params, inv_id)
	if card_id == &"":
		return {"ok": false, "error": "no_target", "amount": 0}
	var card := game_ctx.state.registry.get_card(card_id) if game_ctx.state != null else null
	if card == null:
		return {"ok": false, "error": "unknown_card"}
	var ok := _discard_card_instance(game_ctx, card, inv_id)
	if ok and game_ctx.triggered_abilities != null:
		game_ctx.triggered_abilities.uninstall_by_source(card_id)
	_log(
		game_ctx,
		"effect:discard_card",
		{"card": card_id, "inv": inv_id, "zone": card.zone if card != null else &""}
	)
	return {"ok": ok, "card_id": card_id}


## 统一弃牌去向：遭遇单面→遭遇弃牌堆；玩家所属单面→其弃牌堆；否则从游戏中移除。
static func _discard_card_instance(
	game_ctx: GameContext,
	card: CardInstance,
	inv_id: StringName
) -> bool:
	if card == null or game_ctx == null:
		return false
	var card_id := card.id.instance_id if card.id != null else &""
	if card_id == &"":
		return false
	## 场上敌人：先清交战再按归属路由（不算 defeat）。
	if game_ctx.state != null and game_ctx.state.registry.get_enemy(card_id) != null:
		var routed := EnemyDefeatResolver.discard_from_play(game_ctx, card_id)
		return bool(routed.get("ok", false))
	if card.owner_id == &"encounter":
		return EncounterCardDiscard.discard_from_investigator_to_encounter_pile(
			game_ctx, card_id, inv_id if inv_id != &"" else card.controller_id
		)
	if game_ctx.state != null and game_ctx.state.registry.get_investigator(card.owner_id) != null:
		if game_ctx.mutator == null:
			return false
		if game_ctx.mutator.discard_from_hand(card_id, card.owner_id):
			return true
		return game_ctx.mutator.move_card(card_id, CardSlot.discard_top(card.owner_id))
	## 无弃牌堆去向（双面议程/场景等）→ 从游戏中移除。
	card.zone = AhcEnums.Zone.REMOVED_FROM_GAME
	if game_ctx.state != null and not game_ctx.state.removed_from_game.has(card_id):
		game_ctx.state.removed_from_game.append(card_id)
	return true


static func _pick_discard_target(
	game_ctx: GameContext,
	params: Dictionary,
	inv_id: StringName
) -> StringName:
	var candidates := _discard_candidates(game_ctx, params, inv_id)
	if candidates.is_empty():
		return &""
	if candidates.size() == 1:
		return candidates[0]
	var mode := StringName(str(params.get("mode", "choose")))
	if mode == &"random":
		return candidates[randi() % candidates.size()]
	if game_ctx.interaction != null:
		var chosen: Variant = game_ctx.interaction.ask_pick_target(
			candidates, inv_id, &"pick:discard_card", game_ctx
		)
		if chosen != null:
			return chosen as StringName
	return candidates[0]


static func _discard_candidates(
	game_ctx: GameContext,
	params: Dictionary,
	inv_id: StringName
) -> Array[StringName]:
	var out: Array[StringName] = []
	if game_ctx == null or game_ctx.state == null:
		return out
	var trait_filter := str(params.get("trait", "")).strip_edges()
	var at_filter := StringName(str(params.get("at", "")))
	var loc_id := &""
	if at_filter == &"controller_location" or at_filter == &"your_location":
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv != null:
			loc_id = inv.location_tag
	for enemy_id in game_ctx.state.registry.all_enemy_ids():
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy == null:
			continue
		if loc_id != &"" and enemy.location_tag != loc_id:
			continue
		var card := game_ctx.state.registry.get_card(enemy_id)
		if card == null:
			continue
		if trait_filter != "" and not _matches_trait_or_title(card.id.definition_id, trait_filter):
			continue
		out.append(enemy_id)
	return out


static func _matches_trait_or_title(definition_id: StringName, needle: String) -> bool:
	var want := needle.to_lower()
	if str(CardRegistry.title(definition_id)).to_lower() == want:
		return true
	for trait_name in CardRegistry.traits(definition_id):
		if str(trait_name).to_lower() == want:
			return true
	return false


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


static func _apply_to_investigator(
	game_ctx: GameContext,
	inv_id: StringName,
	kind: StringName,
	amount: int
) -> int:
	if kind == &"horror":
		game_ctx.mutator.take_horror(inv_id, amount)
	else:
		game_ctx.mutator.adjust_marker(
			MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.DAMAGE),
			amount
		)
	return amount


static func _deal_non_elite_with_health_at_attached(
	game_ctx: GameContext,
	params: Dictionary,
	amount: int
) -> int:
	var source: StringName = params.get("source", params.get("card_id", &""))
	var loc_id := _attached_location_id(game_ctx, source)
	if loc_id == &"":
		return 0
	var dealt := 0
	for other_id in game_ctx.state.registry.all_investigator_ids():
		var other := game_ctx.state.registry.get_investigator(other_id)
		if other == null or other.eliminated or other.resigned:
			continue
		if other.location_tag != loc_id:
			continue
		dealt += _apply_to_investigator(game_ctx, other_id, &"damage", amount)
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
		var source_id: StringName = params.get(
			"source", params.get("card_id", params.get("enemy_id", &""))
		)
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
	if game_ctx != null and game_ctx.state != null:
		return game_ctx.state.active_investigator_id
	return &""


static func _log(game_ctx: GameContext, event: String, payload: Dictionary) -> void:
	if game_ctx != null and game_ctx.log != null:
		game_ctx.log.log(AhcEnums.LogCategory.CARD, event, payload)
