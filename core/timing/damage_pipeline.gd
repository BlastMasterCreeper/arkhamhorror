class_name DamagePipeline
extends RefCounted

## Dealing Damage/Horror（07-effect-resolution §4）：
## Assign → WHEN（prevent/reduce）→ Apply → defeat 检测。
## v1 Assign：全部落到调查员卡（asset soak / ASSIGN_* PI 后补）。


const PENDING_AMOUNT := &"pending_damage_amount"
const PENDING_KIND := &"pending_damage_kind"
const PENDING_DIRECT := &"pending_damage_direct"


## 对调查员造成伤害/恐惧：走 Assign → 中段 WHEN → Apply。
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
	## Step 1 Assign（v1：全量 → 调查员卡）。
	_set_pending(game_ctx, inv_id, kind, requested, is_direct)
	## Between 1–2：prevent / reduce（卡面 when-take 钉此槽）。
	if game_ctx.sequences != null:
		game_ctx.sequences.offer_slot(AhcEnums.SequencePhase.WHEN)
	var final_amount := pending_amount(game_ctx, inv_id)
	_clear_pending(game_ctx, inv_id)
	if final_amount <= 0:
		return {"ok": false, "amount": 0, "kind": kind, "prevented": true}
	## Step 2 Apply。
	if kind == &"horror":
		game_ctx.mutator.take_horror(inv_id, final_amount)
	else:
		game_ctx.mutator.adjust_marker(
			MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.DAMAGE),
			final_amount
		)
	DefeatFlow.check_investigator_caps(game_ctx, inv_id)
	return {"ok": true, "amount": final_amount, "kind": kind, "prevented": false}


static func pending_amount(game_ctx: GameContext, inv_id: StringName) -> int:
	if game_ctx == null or game_ctx.memory == null:
		return 0
	return int(game_ctx.memory.get_referent(inv_id, PENDING_AMOUNT))


static func pending_kind(game_ctx: GameContext, inv_id: StringName) -> StringName:
	if game_ctx == null or game_ctx.memory == null:
		return &""
	return game_ctx.memory.get_referent(inv_id, PENDING_KIND) as StringName


## WHEN 窗内：降低尚未 Apply 的分配量（prevent 用 `by >= pending`）。
static func reduce_pending(game_ctx: GameContext, inv_id: StringName, by: int) -> int:
	if game_ctx == null or game_ctx.memory == null or by <= 0:
		return pending_amount(game_ctx, inv_id)
	var cur := pending_amount(game_ctx, inv_id)
	var next_amount := maxi(cur - by, 0)
	game_ctx.memory.set_referent(inv_id, PENDING_AMOUNT, next_amount)
	return next_amount


static func prevent_pending(game_ctx: GameContext, inv_id: StringName) -> void:
	reduce_pending(game_ctx, inv_id, pending_amount(game_ctx, inv_id))


static func _set_pending(
	game_ctx: GameContext,
	inv_id: StringName,
	kind: StringName,
	amount: int,
	is_direct: bool
) -> void:
	if game_ctx.memory == null:
		return
	game_ctx.memory.set_referent(inv_id, PENDING_AMOUNT, amount)
	game_ctx.memory.set_referent(inv_id, PENDING_KIND, kind)
	game_ctx.memory.set_referent(inv_id, PENDING_DIRECT, is_direct)


static func _clear_pending(game_ctx: GameContext, inv_id: StringName) -> void:
	if game_ctx.memory == null:
		return
	game_ctx.memory.set_referent(inv_id, PENDING_AMOUNT, 0)
	game_ctx.memory.set_referent(inv_id, PENDING_KIND, &"")
	game_ctx.memory.set_referent(inv_id, PENDING_DIRECT, false)
