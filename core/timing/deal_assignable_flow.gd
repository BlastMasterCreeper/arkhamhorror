class_name DealAssignableFlow
extends RefCounted

## seq.effect.deal.assignable · 待分配「造成伤害/恐惧」一条手续。
## 伤与恐可同时入参；同帧 Assign（可分步 PI）后 **同时** Apply。
## 禁止伤、恐各 nest 一条 assignable。
## 无分配已定 → seq.effect.deal。


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.mutator == null:
		return {"ok": false, "amount": 0}
	var dmg := _amount_of(params, &"damage")
	var hor := _amount_of(params, &"horror")
	## 兼容旧单 kind+amount。
	if dmg <= 0 and hor <= 0:
		var kind := StringName(str(params.get("kind", "damage")))
		var amount := maxi(int(params.get("amount", 0)), 0)
		if kind == &"horror":
			hor = amount
		else:
			dmg = amount
	if dmg <= 0 and hor <= 0:
		return {"ok": false, "amount": 0, "error": "zero_amount"}
	var target := StringName(str(params.get("target", "controller")))
	var inv_id: StringName = params.get(
		"controller_id", params.get("inv_id", &"")
	)
	var is_direct := bool(params.get("direct", false))
	var direct_dmg := bool(params.get("direct_damage", is_direct))
	var direct_hor := bool(params.get("direct_horror", is_direct))
	match target:
		&"enemy", &"enemies":
			return _enemies(game_ctx, params, dmg, inv_id)
		&"each_at_controller_location", &"each_at_source_location":
			return _each_at_location(
				game_ctx, params, dmg, hor, direct_dmg, direct_hor, target
			)
		_:
			return _investigator_take(
				game_ctx, params, dmg, hor, inv_id, direct_dmg, direct_hor
			)


static func _amount_of(params: Dictionary, kind: StringName) -> int:
	if kind == &"horror":
		return maxi(
			int(params.get("horror", params.get("horror_amount", 0))),
			0
		)
	return maxi(
		int(params.get("damage", params.get("damage_amount", 0))),
		0
	)


static func _investigator_take(
	game_ctx: GameContext,
	params: Dictionary,
	damage_amt: int,
	horror_amt: int,
	inv_id: StringName,
	direct_dmg: bool,
	direct_hor: bool
) -> Dictionary:
	if inv_id == &"" or game_ctx.state.registry.get_investigator(inv_id) == null:
		return {"ok": false, "amount": 0, "error": "unknown_investigator"}
	var result := DamagePipeline.deal_investigator_bundle(
		game_ctx,
		inv_id,
		damage_amt,
		horror_amt,
		direct_dmg,
		direct_hor
	)
	_log(game_ctx, result, params)
	result["assignable"] = true
	result["target"] = &"controller"
	result["simultaneous"] = damage_amt > 0 and horror_amt > 0
	return result


static func _enemies(
	game_ctx: GameContext,
	params: Dictionary,
	damage_amt: int,
	controller_id: StringName
) -> Dictionary:
	if damage_amt <= 0:
		return {"ok": false, "amount": 0, "error": "horror_not_supported_for_enemy"}
	var primary: StringName = params.get(
		"primary_id", params.get("enemy_id", params.get("card_id", &""))
	)
	var candidates: Array = params.get("candidates", [])
	if primary == &"" and not candidates.is_empty():
		primary = candidates[0] as StringName
	if primary == &"":
		return {"ok": false, "amount": 0, "error": "missing_primary"}
	var legs: Array = [{"id": primary, "amount": damage_amt}]
	var applied := 0
	for raw in legs:
		if not (raw is Dictionary):
			continue
		var eid: StringName = (raw as Dictionary).get("id", &"")
		var amt := int((raw as Dictionary).get("amount", 0))
		if eid == &"" or amt <= 0:
			continue
		if game_ctx.state.registry.get_enemy(eid) == null:
			continue
		var one := EnemyDefeatResolver.deal_damage(game_ctx, eid, amt)
		if bool(one.get("ok", false)):
			applied += amt
	var result := {
		"ok": applied > 0,
		"amount": applied,
		"damage": applied,
		"horror": 0,
		"kind": &"damage",
		"target": &"enemy",
		"legs": legs,
		"assignable": true,
		"controller_id": controller_id,
	}
	_log(game_ctx, result, params)
	return result


static func _each_at_location(
	game_ctx: GameContext,
	params: Dictionary,
	damage_amt: int,
	horror_amt: int,
	direct_dmg: bool,
	direct_hor: bool,
	target: StringName
) -> Dictionary:
	var loc_id := _location_for_target(game_ctx, params, target)
	if loc_id == &"":
		return {"ok": false, "amount": 0}
	var applied_d := 0
	var applied_h := 0
	for other_id in game_ctx.state.registry.all_investigator_ids():
		var other := game_ctx.state.registry.get_investigator(other_id)
		if other == null or other.eliminated or other.resigned:
			continue
		if other.location_tag != loc_id:
			continue
		var one := DamagePipeline.deal_investigator_bundle(
			game_ctx, other_id, damage_amt, horror_amt, direct_dmg, direct_hor
		)
		applied_d += int(one.get("damage", 0))
		applied_h += int(one.get("horror", 0))
	var result := {
		"ok": applied_d > 0 or applied_h > 0,
		"amount": applied_d + applied_h,
		"damage": applied_d,
		"horror": applied_h,
		"target": target,
		"assignable": true,
		"simultaneous": damage_amt > 0 and horror_amt > 0,
	}
	_log(game_ctx, result, params)
	return result


static func _location_for_target(
	game_ctx: GameContext, params: Dictionary, target: StringName
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
			var host_id := card.attached_to.instance_id
			if game_ctx.state.registry.get_location(host_id) != null:
				return host_id
			if game_ctx.state.registry.get_location(card.attached_to.definition_id) != null:
				return card.attached_to.definition_id
			return host_id
	var inv_id: StringName = params.get(
		"controller_id", params.get("inv_id", &"")
	)
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	return inv.location_tag if inv != null else &""


static func _log(game_ctx: GameContext, result: Dictionary, params: Dictionary) -> void:
	if game_ctx == null or game_ctx.log == null:
		return
	game_ctx.log.log(
		AhcEnums.LogCategory.CARD,
		"effect:deal.assignable",
		{
			"damage": int(result.get("damage", 0)),
			"horror": int(result.get("horror", 0)),
			"amount": int(result.get("amount", 0)),
			"simultaneous": bool(result.get("simultaneous", false)),
			"source": params.get("source", params.get("card_id", &"")),
		}
	)
