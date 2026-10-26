class_name DamageAssignableFlow
extends RefCounted

## seq.effect.damage.assignable · 待分配伤害（Assign PI + 应用 封为一条）。
## 与 seq.effect.damage（已定 legs / 单点、无分配）分开。
## 帧内：Assign → WOULD/WHEN → Apply；TC.kind 仍为 damage（时点响应面）。


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.mutator == null:
		return {"ok": false, "amount": 0}
	var kind := StringName(str(params.get("kind", "damage")))
	var amount := maxi(int(params.get("amount", 0)), 0)
	if amount <= 0:
		return {"ok": false, "amount": 0, "error": "zero_amount"}
	var target := StringName(str(params.get("target", "controller")))
	var inv_id: StringName = params.get(
		"controller_id", params.get("inv_id", &"")
	)
	var is_direct := bool(params.get("direct", false))
	match target:
		&"enemy", &"enemies":
			return _enemies(game_ctx, params, kind, amount, inv_id)
		&"each_at_controller_location", &"each_at_source_location":
			return _each_at_location(game_ctx, params, kind, amount, is_direct, target)
		&"asset", &"card":
			## 单卡候选退化：Assign 候选={该卡} 后应用（经管线）。
			return _investigator_take(game_ctx, params, kind, amount, inv_id, is_direct)
		_:
			return _investigator_take(game_ctx, params, kind, amount, inv_id, is_direct)


static func _investigator_take(
	game_ctx: GameContext,
	params: Dictionary,
	kind: StringName,
	amount: int,
	inv_id: StringName,
	is_direct: bool
) -> Dictionary:
	if inv_id == &"" or game_ctx.state.registry.get_investigator(inv_id) == null:
		return {"ok": false, "amount": 0, "error": "unknown_investigator"}
	## Assign PI + WOULD/WHEN + Apply（同帧封死）。
	var result := DamagePipeline.deal_investigator(
		game_ctx, inv_id, kind, amount, is_direct
	)
	_log(game_ctx, result, kind, &"controller", params)
	result["assignable"] = true
	result["target"] = &"controller"
	return result


static func _enemies(
	game_ctx: GameContext,
	params: Dictionary,
	kind: StringName,
	amount: int,
	controller_id: StringName
) -> Dictionary:
	if kind != &"damage":
		return {"ok": false, "amount": 0, "error": "horror_not_supported_for_enemy"}
	## 敌侧 Assign PI：Gate 待接；headless 整量 → primary。
	var primary: StringName = params.get(
		"primary_id", params.get("enemy_id", params.get("card_id", &""))
	)
	var candidates: Array = params.get("candidates", [])
	if primary == &"" and not candidates.is_empty():
		primary = candidates[0] as StringName
	if primary == &"":
		return {"ok": false, "amount": 0, "error": "missing_primary"}
	var legs: Array = [{"id": primary, "amount": amount}]
	## 同帧应用已定腿（无再开无分配 seq；分配与应用封在本手续内）。
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
		"kind": kind,
		"target": &"enemy",
		"legs": legs,
		"assignable": true,
		"controller_id": controller_id,
	}
	_log(game_ctx, result, kind, &"enemy", params)
	return result


static func _each_at_location(
	game_ctx: GameContext,
	params: Dictionary,
	kind: StringName,
	amount: int,
	is_direct: bool,
	target: StringName
) -> Dictionary:
	var loc_id := _location_for_target(game_ctx, params, target)
	if loc_id == &"":
		return {"ok": false, "amount": 0}
	var applied := 0
	for other_id in game_ctx.state.registry.all_investigator_ids():
		var other := game_ctx.state.registry.get_investigator(other_id)
		if other == null or other.eliminated or other.resigned:
			continue
		if other.location_tag != loc_id:
			continue
		var one := DamagePipeline.deal_investigator(
			game_ctx, other_id, kind, amount, is_direct
		)
		applied += int(one.get("amount", 0))
	var result := {
		"ok": applied > 0,
		"amount": applied,
		"kind": kind,
		"target": target,
		"assignable": true,
	}
	_log(game_ctx, result, kind, target, params)
	return result


static func _location_for_target(
	game_ctx: GameContext, params: Dictionary, target: StringName
) -> StringName:
	## 与 EffectFlowHandlers._location_for_target 同构（避免跨类私有调用）。
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


static func _log(
	game_ctx: GameContext,
	result: Dictionary,
	kind: StringName,
	target: StringName,
	params: Dictionary
) -> void:
	if game_ctx == null or game_ctx.log == null:
		return
	game_ctx.log.log(
		AhcEnums.LogCategory.CARD,
		"effect:damage.assignable",
		{
			"kind": kind,
			"target": target,
			"amount": int(result.get("amount", 0)),
			"source": params.get("source", params.get("card_id", &"")),
			"direct": bool(params.get("direct", false)),
		}
	)
