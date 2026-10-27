class_name DealPreImpact
extends RefCounted

## 外向 / 已定主体腿的 PreImpact：Assign（若有）之后 → WOULD → WHEN → Apply。
## 与调查员承伤 `DamagePipeline` 对称；腿格式 `{ "id", "amount" }`（可混装敌/卡/调查员）。
## scope_id：RulesMemory 键（通常 controller_id）；嵌套承伤时与 inv pending 分通道。


const PENDING_AMOUNT := &"pending_deal_out_amount"
const PENDING_KIND := &"pending_deal_out_kind"
const PENDING_LEGS := &"pending_deal_out_legs"
const PENDING_HORROR_AMOUNT := &"pending_deal_out_horror_amount"
const PENDING_HORROR_LEGS := &"pending_deal_out_horror_legs"


## 单 kind 已定腿：WOULD→WHEN→Apply。
static func apply_legs(
	game_ctx: GameContext,
	kind: StringName,
	legs: Array,
	scope_id: StringName
) -> Dictionary:
	if game_ctx == null or game_ctx.mutator == null:
		return {"ok": false, "amount": 0, "legs": []}
	var normalized := _normalize_legs(legs)
	var total := _sum_legs(normalized)
	if total <= 0:
		return {"ok": false, "amount": 0, "legs": [], "kind": kind}
	var sid := scope_id if scope_id != &"" else &"deal_out"
	_set_pending(game_ctx, sid, kind, total, normalized, [], 0)
	_offer_preimpact(game_ctx)
	var final_amt := pending_amount(game_ctx, sid)
	var final_legs := pending_legs(game_ctx, sid)
	_clear_pending(game_ctx, sid)
	if final_amt <= 0:
		return {"ok": false, "amount": 0, "kind": kind, "prevented": true, "legs": []}
	var applied := _apply(game_ctx, kind, final_legs)
	if kind == &"horror":
		DealAfflictionReport.patch_current(game_ctx, 0, applied)
	else:
		DealAfflictionReport.patch_current(game_ctx, applied, 0)
	return {
		"ok": applied > 0,
		"amount": applied,
		"kind": kind,
		"prevented": applied <= 0,
		"legs": final_legs,
	}


## 伤+恐已定腿：同帧一次 WOULD/WHEN，再同时 Apply。
static func apply_bundle(
	game_ctx: GameContext,
	damage_legs: Array,
	horror_legs: Array,
	scope_id: StringName
) -> Dictionary:
	if game_ctx == null or game_ctx.mutator == null:
		return {"ok": false, "amount": 0, "damage": 0, "horror": 0}
	var d_norm := _normalize_legs(damage_legs)
	var h_norm := _normalize_legs(horror_legs)
	var d_tot := _sum_legs(d_norm)
	var h_tot := _sum_legs(h_norm)
	if d_tot <= 0 and h_tot <= 0:
		return {"ok": false, "amount": 0, "damage": 0, "horror": 0}
	var sid := scope_id if scope_id != &"" else &"deal_out"
	_set_pending(game_ctx, sid, &"damage" if d_tot > 0 else &"horror", d_tot, d_norm, h_norm, h_tot)
	_offer_preimpact(game_ctx)
	var final_d := 0
	var final_d_legs: Array = []
	var final_h := 0
	var final_h_legs: Array = []
	if d_tot > 0:
		final_d = pending_amount(game_ctx, sid)
		final_d_legs = pending_legs(game_ctx, sid)
	if h_tot > 0:
		final_h = pending_horror_amount(game_ctx, sid)
		final_h_legs = pending_horror_legs(game_ctx, sid)
	_clear_pending(game_ctx, sid)
	var applied_d := 0
	var applied_h := 0
	if final_d > 0:
		applied_d = _apply(game_ctx, &"damage", final_d_legs)
	if final_h > 0:
		applied_h = _apply(game_ctx, &"horror", final_h_legs)
	DealAfflictionReport.patch_current(game_ctx, applied_d, applied_h)
	return {
		"ok": applied_d > 0 or applied_h > 0,
		"amount": applied_d + applied_h,
		"damage": applied_d,
		"horror": applied_h,
		"prevented": applied_d <= 0 and applied_h <= 0 and (d_tot > 0 or h_tot > 0),
		"legs": final_d_legs,
		"legs_damage": final_d_legs,
		"legs_horror": final_h_legs,
		"simultaneous": d_tot > 0 and h_tot > 0,
	}


static func pending_amount(game_ctx: GameContext, scope_id: StringName) -> int:
	if game_ctx == null or game_ctx.memory == null:
		return 0
	return int(game_ctx.memory.get_referent(scope_id, PENDING_AMOUNT))


static func pending_horror_amount(game_ctx: GameContext, scope_id: StringName) -> int:
	if game_ctx == null or game_ctx.memory == null:
		return 0
	return int(game_ctx.memory.get_referent(scope_id, PENDING_HORROR_AMOUNT))


static func pending_legs(game_ctx: GameContext, scope_id: StringName) -> Array:
	if game_ctx == null or game_ctx.memory == null:
		return []
	var raw: Variant = game_ctx.memory.get_referent(scope_id, PENDING_LEGS)
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


static func pending_horror_legs(game_ctx: GameContext, scope_id: StringName) -> Array:
	if game_ctx == null or game_ctx.memory == null:
		return []
	var raw: Variant = game_ctx.memory.get_referent(scope_id, PENDING_HORROR_LEGS)
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


## WOULD：降低尚未写入的外向量；按比例砍腿（末腿优先）。
static func reduce_pending(game_ctx: GameContext, scope_id: StringName, by: int) -> int:
	if game_ctx == null or game_ctx.memory == null or by <= 0:
		return pending_amount(game_ctx, scope_id)
	var cur := pending_amount(game_ctx, scope_id)
	var next_amount := maxi(cur - by, 0)
	var legs := pending_legs(game_ctx, scope_id)
	var trimmed := _trim_legs(legs, next_amount)
	game_ctx.memory.set_referent(scope_id, PENDING_AMOUNT, next_amount)
	game_ctx.memory.set_referent(scope_id, PENDING_LEGS, trimmed)
	var kind: StringName = game_ctx.memory.get_referent(scope_id, PENDING_KIND) as StringName
	if kind == &"horror":
		game_ctx.memory.set_referent(scope_id, PENDING_HORROR_AMOUNT, next_amount)
		game_ctx.memory.set_referent(scope_id, PENDING_HORROR_LEGS, trimmed.duplicate(true))
	return next_amount


static func prevent_pending(game_ctx: GameContext, scope_id: StringName) -> void:
	reduce_pending(game_ctx, scope_id, pending_amount(game_ctx, scope_id))


static func _offer_preimpact(game_ctx: GameContext) -> void:
	if game_ctx.sequences == null:
		return
	game_ctx.sequences.offer_slot(AhcEnums.SequencePhase.WOULD)
	game_ctx.sequences.offer_slot(AhcEnums.SequencePhase.WHEN)


static func _set_pending(
	game_ctx: GameContext,
	scope_id: StringName,
	kind: StringName,
	damage_amt: int,
	damage_legs: Array,
	horror_legs: Array,
	horror_amt: int
) -> void:
	if game_ctx.memory == null:
		return
	game_ctx.memory.set_referent(scope_id, PENDING_HORROR_AMOUNT, horror_amt)
	game_ctx.memory.set_referent(scope_id, PENDING_HORROR_LEGS, horror_legs.duplicate(true))
	if damage_amt > 0:
		game_ctx.memory.set_referent(scope_id, PENDING_AMOUNT, damage_amt)
		game_ctx.memory.set_referent(scope_id, PENDING_KIND, &"damage")
		game_ctx.memory.set_referent(scope_id, PENDING_LEGS, damage_legs.duplicate(true))
	elif horror_amt > 0:
		game_ctx.memory.set_referent(scope_id, PENDING_AMOUNT, horror_amt)
		game_ctx.memory.set_referent(scope_id, PENDING_KIND, &"horror")
		game_ctx.memory.set_referent(scope_id, PENDING_LEGS, horror_legs.duplicate(true))
	else:
		game_ctx.memory.set_referent(scope_id, PENDING_AMOUNT, 0)
		game_ctx.memory.set_referent(scope_id, PENDING_KIND, kind)
		game_ctx.memory.set_referent(scope_id, PENDING_LEGS, [])


static func _clear_pending(game_ctx: GameContext, scope_id: StringName) -> void:
	if game_ctx.memory == null:
		return
	game_ctx.memory.set_referent(scope_id, PENDING_AMOUNT, 0)
	game_ctx.memory.set_referent(scope_id, PENDING_KIND, &"")
	game_ctx.memory.set_referent(scope_id, PENDING_LEGS, [])
	game_ctx.memory.set_referent(scope_id, PENDING_HORROR_AMOUNT, 0)
	game_ctx.memory.set_referent(scope_id, PENDING_HORROR_LEGS, [])


static func _apply(game_ctx: GameContext, kind: StringName, legs: Array) -> int:
	var applied := 0
	for raw in legs:
		if not (raw is Dictionary):
			continue
		var sid: StringName = (raw as Dictionary).get("id", &"")
		var amt := int((raw as Dictionary).get("amount", 0))
		if sid == &"" or amt <= 0:
			continue
		applied += DealSubject.apply(game_ctx, kind, sid, amt)
	return applied


static func _normalize_legs(legs: Array) -> Array:
	var out: Array = []
	for raw in legs:
		if not (raw is Dictionary):
			continue
		var d: Dictionary = raw
		var amt := int(d.get("amount", 0))
		if amt <= 0:
			continue
		var sid: StringName = d.get(
			"id", d.get("enemy_id", d.get("card_id", d.get("subject_id", &"")))
		)
		if sid == &"":
			continue
		out.append({"id": sid, "amount": amt})
	return out


static func _sum_legs(legs: Array) -> int:
	var total := 0
	for raw in legs:
		if raw is Dictionary:
			total += int((raw as Dictionary).get("amount", 0))
	return total


## 从末腿向前砍到 target_total。
static func _trim_legs(legs: Array, target_total: int) -> Array:
	var want := maxi(target_total, 0)
	if want <= 0:
		return []
	var cur := _sum_legs(legs)
	if cur <= want:
		return legs.duplicate(true)
	var need_cut := cur - want
	var kept_rev: Array = []
	for i in range(legs.size() - 1, -1, -1):
		if not (legs[i] is Dictionary):
			continue
		var leg: Dictionary = legs[i] as Dictionary
		var amt := int(leg.get("amount", 0))
		var sid: StringName = leg.get("id", &"")
		if need_cut >= amt:
			need_cut -= amt
			continue
		kept_rev.append({"id": sid, "amount": amt - need_cut})
		need_cut = 0
	var out: Array = []
	for j in range(kept_rev.size() - 1, -1, -1):
		out.append(kept_rev[j])
	return out
