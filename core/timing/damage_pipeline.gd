class_name DamagePipeline
extends RefCounted

## Dealing Damage/Horror（07-effect-resolution §4）· 已裁决：
## - **有分配** `seq.effect.damage.assignable`：Assign PI + Apply 同帧封死。
## - **无分配** `seq.effect.damage`：已定 legs / 单点，无 Assign。
## - 分摊约束：`RestrictionKind.ASSIGN_CONSTRAINT`（DamageAssigner 原流程读取）。
## - **WOULD / WHEN 均在 Apply 之前**（栈相位 PreImpact）。
## v1 Assign：`DamageAssigner.default_assignment`（`ASSIGN_*` Gate 后补）。


const PENDING_AMOUNT := &"pending_damage_amount"
const PENDING_KIND := &"pending_damage_kind"
const PENDING_DIRECT := &"pending_damage_direct"
const PENDING_LEGS := &"pending_damage_legs"


## 有分配手续用：Assign PI → WOULD/WHEN → Apply。
static func deal_investigator(
	game_ctx: GameContext,
	inv_id: StringName,
	kind: StringName,
	amount: int,
	is_direct: bool = false
) -> Dictionary:
	if game_ctx == null or game_ctx.mutator == null or inv_id == &"":
		return {"ok": false, "amount": 0}
	if game_ctx.state.registry.get_investigator(inv_id) == null:
		return {"ok": false, "amount": 0, "error": "unknown_investigator"}
	var requested := maxi(amount, 0)
	if requested <= 0:
		return {"ok": false, "amount": 0}
	var legs := DamageAssigner.default_assignment(game_ctx, inv_id, kind, requested, is_direct)
	return apply_investigator_legs(game_ctx, inv_id, kind, requested, is_direct, legs)


## 无分配应用：腿已定（或 Assign 刚钉死）。
static func apply_investigator_legs(
	game_ctx: GameContext,
	inv_id: StringName,
	kind: StringName,
	amount: int,
	is_direct: bool,
	legs: Array
) -> Dictionary:
	if game_ctx == null or game_ctx.mutator == null or inv_id == &"":
		return {"ok": false, "amount": 0}
	if game_ctx.state.registry.get_investigator(inv_id) == null:
		return {"ok": false, "amount": 0, "error": "unknown_investigator"}
	var requested := maxi(amount, 0)
	if requested <= 0:
		requested = 0
		for leg in legs:
			if leg is Dictionary:
				requested += int((leg as Dictionary).get("amount", 0))
	if requested <= 0:
		return {"ok": false, "amount": 0}
	_set_pending(game_ctx, inv_id, kind, requested, is_direct, legs)
	if game_ctx.sequences != null:
		game_ctx.sequences.offer_slot(AhcEnums.SequencePhase.WOULD)
		game_ctx.sequences.offer_slot(AhcEnums.SequencePhase.WHEN)
	var final_amount := pending_amount(game_ctx, inv_id)
	var final_legs := pending_legs(game_ctx, inv_id)
	_clear_pending(game_ctx, inv_id)
	if final_amount <= 0:
		return {"ok": false, "amount": 0, "kind": kind, "prevented": true, "legs": []}
	_apply_legs(game_ctx, inv_id, kind, final_legs)
	DefeatFlow.check_investigator_caps(game_ctx, inv_id)
	return {
		"ok": true,
		"amount": final_amount,
		"kind": kind,
		"prevented": false,
		"legs": final_legs,
	}


static func pending_amount(game_ctx: GameContext, inv_id: StringName) -> int:
	if game_ctx == null or game_ctx.memory == null:
		return 0
	return int(game_ctx.memory.get_referent(inv_id, PENDING_AMOUNT))


static func pending_kind(game_ctx: GameContext, inv_id: StringName) -> StringName:
	if game_ctx == null or game_ctx.memory == null:
		return &""
	return game_ctx.memory.get_referent(inv_id, PENDING_KIND) as StringName


static func pending_direct(game_ctx: GameContext, inv_id: StringName) -> bool:
	if game_ctx == null or game_ctx.memory == null:
		return false
	return bool(game_ctx.memory.get_referent(inv_id, PENDING_DIRECT))


static func pending_legs(game_ctx: GameContext, inv_id: StringName) -> Array:
	if game_ctx == null or game_ctx.memory == null:
		return []
	var raw: Variant = game_ctx.memory.get_referent(inv_id, PENDING_LEGS)
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


## WOULD 窗内：降低尚未写入的量（prevent 用 `by >= pending`）；按剩余量重建默认腿表。
static func reduce_pending(game_ctx: GameContext, inv_id: StringName, by: int) -> int:
	if game_ctx == null or game_ctx.memory == null or by <= 0:
		return pending_amount(game_ctx, inv_id)
	var cur := pending_amount(game_ctx, inv_id)
	var next_amount := maxi(cur - by, 0)
	var kind := pending_kind(game_ctx, inv_id)
	var is_direct := pending_direct(game_ctx, inv_id)
	var legs := DamageAssigner.default_assignment(game_ctx, inv_id, kind, next_amount, is_direct)
	game_ctx.memory.set_referent(inv_id, PENDING_AMOUNT, next_amount)
	game_ctx.memory.set_referent(inv_id, PENDING_LEGS, legs)
	return next_amount


static func prevent_pending(game_ctx: GameContext, inv_id: StringName) -> void:
	reduce_pending(game_ctx, inv_id, pending_amount(game_ctx, inv_id))


## PreImpact 加量（02221 additional）：保留已确认 N 腿，只为增量 K 再分配。
## 候选 = 本次合法全合格集（容量扣掉已占用）；默认算法摊 K（Gate 后补）。
static func increase_pending(game_ctx: GameContext, inv_id: StringName, by: int) -> int:
	if game_ctx == null or game_ctx.memory == null or by <= 0:
		return pending_amount(game_ctx, inv_id)
	var cur := pending_amount(game_ctx, inv_id)
	if cur <= 0:
		## 无已确认实例则不加（「受到 1+」前提）。
		return cur
	var kind := pending_kind(game_ctx, inv_id)
	var is_direct := pending_direct(game_ctx, inv_id)
	var reserved := pending_legs(game_ctx, inv_id)
	var delta_legs := DamageAssigner.assign_delta(
		game_ctx, inv_id, kind, by, is_direct, reserved
	)
	var merged: Array = DamageAssigner.merge_legs(reserved, delta_legs)
	var next_amount := cur + by
	if not DamageAssigner.validate(game_ctx, inv_id, kind, is_direct, next_amount, merged):
		## 防御：K 全归调查员卡，仍保留 N 腿。
		delta_legs = [{"bearer": &"investigator", "id": inv_id, "amount": by}]
		merged = DamageAssigner.merge_legs(reserved, delta_legs)
	game_ctx.memory.set_referent(inv_id, PENDING_AMOUNT, next_amount)
	game_ctx.memory.set_referent(inv_id, PENDING_LEGS, merged)
	return next_amount


## WOULD 窗内改分配：替换腿表（须校验守恒与约束）；供 Key of Ys 等后挂。
static func reassign_pending_legs(game_ctx: GameContext, inv_id: StringName, legs: Array) -> bool:
	if game_ctx == null or game_ctx.memory == null:
		return false
	var total := pending_amount(game_ctx, inv_id)
	var kind := pending_kind(game_ctx, inv_id)
	var is_direct := pending_direct(game_ctx, inv_id)
	if not DamageAssigner.validate(game_ctx, inv_id, kind, is_direct, total, legs):
		return false
	game_ctx.memory.set_referent(inv_id, PENDING_LEGS, legs.duplicate(true))
	return true


static func _set_pending(
	game_ctx: GameContext,
	inv_id: StringName,
	kind: StringName,
	amount: int,
	is_direct: bool,
	legs: Array
) -> void:
	if game_ctx.memory == null:
		return
	game_ctx.memory.set_referent(inv_id, PENDING_AMOUNT, amount)
	game_ctx.memory.set_referent(inv_id, PENDING_KIND, kind)
	game_ctx.memory.set_referent(inv_id, PENDING_DIRECT, is_direct)
	game_ctx.memory.set_referent(inv_id, PENDING_LEGS, legs.duplicate(true))


static func _clear_pending(game_ctx: GameContext, inv_id: StringName) -> void:
	if game_ctx.memory == null:
		return
	game_ctx.memory.set_referent(inv_id, PENDING_AMOUNT, 0)
	game_ctx.memory.set_referent(inv_id, PENDING_KIND, &"")
	game_ctx.memory.set_referent(inv_id, PENDING_DIRECT, false)
	game_ctx.memory.set_referent(inv_id, PENDING_LEGS, [])


static func _apply_legs(
	game_ctx: GameContext,
	inv_id: StringName,
	kind: StringName,
	legs: Array
) -> void:
	for leg in legs:
		if not (leg is Dictionary):
			continue
		var amt := int((leg as Dictionary).get("amount", 0))
		if amt <= 0:
			continue
		var bearer: StringName = (leg as Dictionary).get("bearer", &"")
		var id: StringName = (leg as Dictionary).get("id", &"")
		if bearer == &"investigator":
			var marker := (
				AhcEnums.MarkerKind.HORROR_TAKEN if kind == &"horror" else AhcEnums.MarkerKind.DAMAGE
			)
			var target_id: StringName = id if id != &"" else inv_id
			game_ctx.mutator.transfer_marker(
				marker,
				amt,
				MarkerSlot.supply(marker),
				MarkerSlot.investigator(target_id, marker)
			)
		elif bearer == &"card":
			if kind == &"horror":
				DefeatFlow.deal_horror_to_asset(game_ctx, id, amt)
			else:
				DefeatFlow.deal_damage_to_asset(game_ctx, id, amt)
