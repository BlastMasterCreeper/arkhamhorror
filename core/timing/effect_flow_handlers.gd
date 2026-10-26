class_name EffectFlowHandlers
extends RefCounted

## 纸面无名效果句的命名流程 handler（seq.effect.* · 07-composition §1.3.3）。
## L0 写入只出现在这里，不出现在卡面 Composition 树当效果本身。


## 无分配造成伤害/恐惧（seq.effect.deal）：已定 legs / 敌·支援单点；**不含** Assign。
## 单 kind 用 params.kind + legs；伤+恐 → legs_damage + legs_horror（可单边空）。
## 待分配 → `seq.effect.deal.assignable`。
static func damage(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var kind := StringName(str(params.get("kind", "damage")))
	var target := StringName(str(params.get("target", "controller")))
	var inv_id := _controller_id(game_ctx, params)
	if game_ctx == null or game_ctx.mutator == null:
		return {"ok": false, "amount": 0}
	var is_direct := bool(params.get("direct", false))
	var raw_ld: Variant = params.get("legs_damage", null)
	var raw_lh: Variant = params.get("legs_horror", null)
	if raw_ld is Array or raw_lh is Array:
		var d_legs: Array = raw_ld as Array if raw_ld is Array else []
		var h_legs: Array = raw_lh as Array if raw_lh is Array else []
		return _damage_determined_bundle(
			game_ctx, params, target, inv_id, is_direct, d_legs, h_legs
		)
	var raw_legs: Variant = params.get("legs", null)
	if raw_legs is Array and not (raw_legs as Array).is_empty():
		var legs_arr := raw_legs as Array
		if target == &"controller" or params.get("assign_format", &"") == &"pipeline":
			return _damage_investigator_determined_legs(
				game_ctx, params, kind, inv_id, is_direct, legs_arr
			)
		return _damage_legs(game_ctx, params, kind, target, inv_id, is_direct, legs_arr)
	## 无 legs 的调查员承伤 / 地点广播 = 待分配 → 拒（须走 assignable）。
	if (
		target == &"controller"
		or target == &""
		or target == &"each_at_controller_location"
		or target == &"each_at_source_location"
	):
		return {
			"ok": false,
			"amount": 0,
			"error": "use_seq.effect.deal.assignable",
			"kind": kind,
			"target": target,
		}
	var amount := maxi(int(params.get("amount", 1)), 1)
	## 单点已定：若可归类为主体 id，走 PreImpact；否则旧扫场路径。
	var override_id: StringName = params.get(
		"enemy_id", params.get("card_id", params.get("primary_id", &""))
	)
	if (
		override_id != &""
		and DealSubject.classify(game_ctx, override_id) != &""
		and target != &"non_elite_with_health_at_attached_location"
	):
		return _damage_legs(
			game_ctx,
			params,
			kind,
			target,
			inv_id,
			is_direct,
			[{"id": override_id, "amount": amount}]
		)
	var applied := _damage_one(game_ctx, params, kind, target, inv_id, is_direct, amount, &"")
	_log(
		game_ctx,
		"effect:damage",
		{
			"kind": kind,
			"target": target,
			"amount": applied,
			"source": params.get("source", params.get("card_id", &"")),
			"direct": is_direct,
		}
	)
	return {"ok": applied > 0, "amount": applied, "kind": kind, "target": target}


static func _damage_determined_bundle(
	game_ctx: GameContext,
	params: Dictionary,
	target: StringName,
	inv_id: StringName,
	is_direct: bool,
	damage_legs: Array,
	horror_legs: Array
) -> Dictionary:
	## 单边空载兼容单类型；两侧皆空 → 拒。
	var d_sum := 0
	var h_sum := 0
	for leg in damage_legs:
		if leg is Dictionary:
			d_sum += maxi(int((leg as Dictionary).get("amount", 0)), 0)
	for leg2 in horror_legs:
		if leg2 is Dictionary:
			h_sum += maxi(int((leg2 as Dictionary).get("amount", 0)), 0)
	if d_sum <= 0 and h_sum <= 0:
		return {"ok": false, "amount": 0, "damage": 0, "horror": 0, "error": "empty_legs"}
	var use_pipeline := (
		target == &"controller"
		or target == &""
		or params.get("assign_format", &"") == &"pipeline"
	)
	var result: Dictionary
	if use_pipeline:
		result = DamagePipeline.apply_investigator_bundle_legs(
			game_ctx,
			inv_id,
			damage_legs,
			horror_legs,
			bool(params.get("direct_damage", is_direct)),
			bool(params.get("direct_horror", is_direct))
		)
		result["target"] = &"controller"
	else:
		var scope: StringName = inv_id if inv_id != &"" else &"deal_out"
		result = DealPreImpact.apply_bundle(game_ctx, damage_legs, horror_legs, scope)
		result["target"] = target
		result["multi"] = true
	var applied := int(result.get("amount", 0))
	_log(
		game_ctx,
		"effect:damage",
		{
			"kind": &"damage" if d_sum > 0 else &"horror",
			"target": result.get("target", target),
			"amount": applied,
			"damage": int(result.get("damage", 0)),
			"horror": int(result.get("horror", 0)),
			"determined_bundle": true,
			"source": params.get("source", params.get("card_id", &"")),
			"direct": is_direct,
		}
	)
	result["ok"] = applied > 0
	return result


static func _damage_investigator_determined_legs(
	game_ctx: GameContext,
	params: Dictionary,
	kind: StringName,
	inv_id: StringName,
	is_direct: bool,
	legs: Array
) -> Dictionary:
	var result := DamagePipeline.apply_investigator_legs(
		game_ctx, inv_id, kind, 0, is_direct, legs
	)
	var applied := int(result.get("amount", 0))
	_log(
		game_ctx,
		"effect:damage",
		{
			"kind": kind,
			"target": &"controller",
			"amount": applied,
			"determined_legs": true,
			"source": params.get("source", params.get("card_id", &"")),
			"direct": is_direct,
		}
	)
	return {
		"ok": applied > 0,
		"amount": applied,
		"kind": kind,
		"target": &"controller",
		"legs": result.get("legs", []),
		"legs_damage": result.get("legs_damage", []),
		"legs_horror": result.get("legs_horror", []),
		"damage": int(result.get("damage", 0)),
		"horror": int(result.get("horror", 0)),
		"prevented": bool(result.get("prevented", false)),
	}


static func _damage_legs(
	game_ctx: GameContext,
	params: Dictionary,
	kind: StringName,
	target: StringName,
	inv_id: StringName,
	is_direct: bool,
	legs: Array
) -> Dictionary:
	## 已定主体腿：PreImpact WOULD→WHEN→Apply（与承伤对称）。
	var scope: StringName = inv_id if inv_id != &"" else &"deal_out"
	var pre := DealPreImpact.apply_legs(game_ctx, kind, legs, scope)
	var applied := int(pre.get("amount", 0))
	var final_legs: Array = pre.get("legs", []) as Array
	var subjects: Array[StringName] = []
	for raw in final_legs:
		if raw is Dictionary:
			var sid: StringName = (raw as Dictionary).get("id", &"")
			if sid != &"":
				subjects.append(sid)
	_log(
		game_ctx,
		"effect:damage",
		{
			"kind": kind,
			"target": target,
			"amount": applied,
			"multi": true,
			"subjects": subjects,
			"source": params.get("source", params.get("card_id", &"")),
			"direct": is_direct,
			"preimpact": true,
		}
	)
	return {
		"ok": applied > 0,
		"amount": applied,
		"kind": kind,
		"target": target,
		"subjects": subjects,
		"legs": final_legs,
		"multi": true,
		"prevented": bool(pre.get("prevented", false)),
	}


static func _damage_one(
	game_ctx: GameContext,
	params: Dictionary,
	kind: StringName,
	target: StringName,
	inv_id: StringName,
	is_direct: bool,
	amount: int,
	override_id: StringName
) -> int:
	match target:
		&"each_at_controller_location", &"each_at_source_location":
			## 地点广播属待分配 → 无分配帧拒；走 assignable。
			return 0
		&"non_elite_with_health_at_attached_location":
			if kind != &"damage":
				return 0
			return _deal_non_elite_with_health_at_attached(game_ctx, params, amount)
		&"enemy", &"enemies", &"subjects", &"among_candidates":
			var sid: StringName = override_id
			if sid == &"":
				sid = params.get(
					"enemy_id", params.get("card_id", params.get("primary_id", &""))
				)
			return DealSubject.apply(game_ctx, kind, sid, amount)
		&"asset", &"card":
			var asset_id: StringName = override_id
			if asset_id == &"":
				asset_id = params.get("card_id", params.get("asset_id", &""))
			return DealSubject.apply(game_ctx, kind, asset_id, amount)
		_:
			## 调查员承伤无 legs = 待分配，无分配帧不写。
			return 0


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
	game_ctx.mutator.transfer_marker(
		AhcEnums.MarkerKind.RESOURCE,
		actual,
		MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.RESOURCE),
		MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE)
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
	game_ctx.mutator.transfer_marker(
		marker,
		actual,
		MarkerSlot.investigator(inv_id, marker),
		MarkerSlot.supply(marker)
	)
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


## 统一弃牌：`from=hand` 按 amount/mode 选手牌；否则弃指定/寻址到的单张。
static func discard_card(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null:
		return {"ok": false, "error": "invalid_params"}
	var from_zone := StringName(str(params.get("from", "")))
	if from_zone == &"hand":
		return _discard_cards_from_hand(game_ctx, params)
	var inv_id := _controller_id(game_ctx, params)
	var card_id: StringName = params.get("card_id", &"")
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
		{
			"card": card_id,
			"inv": inv_id,
			"from": from_zone,
			"zone": card.zone if card != null else &"",
		}
	)
	return {"ok": ok, "card_id": card_id, "amount": 1 if ok else 0, "from": from_zone}


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
	var at_filter := StringName(str(params.get("at", "")))
	if at_filter == &"controlled_assets":
		return _controlled_asset_candidates(game_ctx, inv_id)
	var trait_filter := str(params.get("trait", "")).strip_edges()
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


static func _controlled_asset_candidates(
	game_ctx: GameContext,
	inv_id: StringName
) -> Array[StringName]:
	var out: Array[StringName] = []
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null:
		return out
	for card_id in inv.play_area:
		var card := game_ctx.state.registry.get_card(card_id)
		if card == null:
			continue
		if CardRegistry.card_type(card.id.definition_id) != &"asset":
			continue
		out.append(card_id)
	return out


static func _matches_trait_or_title(definition_id: StringName, needle: String) -> bool:
	var want := needle.to_lower()
	if str(CardRegistry.title(definition_id)).to_lower() == want:
		return true
	for trait_name in CardRegistry.traits(definition_id):
		if str(trait_name).to_lower() == want:
			return true
	return false


## 兼容旧调用：转发到统一 discard_card（from=hand）。
static func discard_from_hand(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var p := params.duplicate()
	p["from"] = &"hand"
	return discard_card(game_ctx, p)


static func _discard_cards_from_hand(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var inv_id := _controller_id(game_ctx, params)
	var amount := maxi(int(params.get("amount", 1)), 1)
	var mode := StringName(str(params.get("mode", "random")))
	if game_ctx == null or game_ctx.mutator == null or inv_id == &"":
		return {"ok": false, "amount": 0, "from": &"hand"}
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null or inv.hand.is_empty():
		return {"ok": false, "amount": 0, "inv_id": inv_id, "from": &"hand"}
	var discarded: Array[StringName] = []
	var n := mini(amount, inv.hand.size())
	for _i in n:
		var pick: StringName = &""
		if mode == &"random":
			pick = inv.hand[randi() % inv.hand.size()] as StringName
		elif game_ctx.interaction != null:
			var chosen: Variant = game_ctx.interaction.ask_pick_target(
				inv.hand.duplicate(), inv_id, &"pick:discard_card", game_ctx
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
		"effect:discard_card",
		{"inv": inv_id, "amount": discarded.size(), "mode": mode, "from": &"hand"}
	)
	return {
		"ok": not discarded.is_empty(),
		"amount": discarded.size(),
		"cards": discarded,
		"from": &"hand",
	}


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
	amount: int,
	is_direct: bool = false
) -> int:
	## 仅 non_elite 等已定扫场回退；规范承伤走 damage.assignable。
	var result := DamagePipeline.deal_investigator(
		game_ctx,
		inv_id,
		kind,
		amount,
		is_direct
	)
	return int(result.get("amount", 0))


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
