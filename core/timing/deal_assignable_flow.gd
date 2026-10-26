class_name DealAssignableFlow
extends RefCounted

## seq.effect.deal.assignable · 待分配「造成伤害/恐惧」一条手续。
## 伤与恐可同时入参；同帧 Assign（可分步 PI）后 **同时** Apply。
## 禁止伤、恐各 nest 一条 assignable。
## 无分配已定 → seq.effect.deal。
## 多目标候选不限卡种：敌人 / 有生命·神智（或 GRANT_CAPACITY）的场上卡 / 调查员。


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
		&"enemy", &"enemies", &"subjects", &"among_candidates":
			return _among_subjects(game_ctx, params, dmg, hor, inv_id)
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


## 在候选主体间分配 damage（默认全量归 primary）；horror 仅落可承恐主体。
## candidates / primary 可为敌人、场上卡、调查员混装。
static func _among_subjects(
	game_ctx: GameContext,
	params: Dictionary,
	damage_amt: int,
	horror_amt: int,
	controller_id: StringName
) -> Dictionary:
	var primary: StringName = params.get(
		"primary_id", params.get("enemy_id", params.get("card_id", &""))
	)
	var candidates: Array = params.get("candidates", [])
	var subject_ids: Array[StringName] = _normalize_subjects(primary, candidates)
	if subject_ids.is_empty():
		return {"ok": false, "amount": 0, "error": "missing_primary"}
	var d_legs := _default_among(game_ctx, subject_ids, damage_amt, controller_id)
	var h_legs: Array = []
	if horror_amt > 0:
		## 恐惧：仅落到可承恐的卡/调查员（敌人跳过）。
		var horror_subjects: Array[StringName] = []
		for sid in subject_ids:
			var kind := DealSubject.classify(game_ctx, sid)
			if kind == DealSubject.KIND_CARD or kind == DealSubject.KIND_INVESTIGATOR:
				horror_subjects.append(sid)
		if not horror_subjects.is_empty():
			h_legs = _default_among(game_ctx, horror_subjects, horror_amt, controller_id)
	var applied_d := 0
	var applied_h := 0
	for raw in d_legs:
		if not (raw is Dictionary):
			continue
		var sid: StringName = (raw as Dictionary).get("id", &"")
		var amt := int((raw as Dictionary).get("amount", 0))
		applied_d += DealSubject.apply(game_ctx, &"damage", sid, amt)
	for raw2 in h_legs:
		if not (raw2 is Dictionary):
			continue
		var sid2: StringName = (raw2 as Dictionary).get("id", &"")
		var amt2 := int((raw2 as Dictionary).get("amount", 0))
		applied_h += DealSubject.apply(game_ctx, &"horror", sid2, amt2)
	var result := {
		"ok": applied_d > 0 or applied_h > 0,
		"amount": applied_d + applied_h,
		"damage": applied_d,
		"horror": applied_h,
		"kind": &"damage" if applied_d > 0 else &"horror",
		"target": &"subjects",
		"legs": d_legs,
		"legs_horror": h_legs,
		"assignable": true,
		"controller_id": controller_id,
		"simultaneous": damage_amt > 0 and horror_amt > 0,
	}
	_log(game_ctx, result, params)
	return result


static func _normalize_subjects(
	primary: StringName, candidates: Array
) -> Array[StringName]:
	var out: Array[StringName] = []
	var seen: Dictionary = {}
	if primary != &"":
		out.append(primary)
		seen[primary] = true
	for raw in candidates:
		var sid: StringName = &""
		if raw is StringName or raw is String:
			sid = StringName(str(raw))
		elif raw is Dictionary:
			sid = (raw as Dictionary).get(
				"id", (raw as Dictionary).get("enemy_id", (raw as Dictionary).get("card_id", &""))
			)
		if sid == &"" or seen.has(sid):
			continue
		seen[sid] = true
		out.append(sid)
	return out


## 默认分配（Gate 待接）：全量归 primary（首个合格主体）。
static func _default_among(
	_game_ctx: GameContext,
	subjects: Array[StringName],
	amount: int,
	_controller_id: StringName
) -> Array:
	var total := maxi(amount, 0)
	var empty: Array = []
	if total <= 0 or subjects.is_empty():
		return empty
	return [{"id": subjects[0], "amount": total}]


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
