class_name DamagePipeline
extends RefCounted

## Dealing Damage/Horror（07-effect-resolution §4）· 已裁决：
## - **Assign = 玩家选择（PI）**，不是结算砖，不 emit 时点。
## - 时点挂在 **Apply** 砖：WOULD（将要受到 / prevent）→ L0 写入 → WHEN（已受到）。
## v1 Assign：默认全量 → 调查员卡（`ASSIGN_*` Gate 后补）。


const PENDING_AMOUNT := &"pending_damage_amount"
const PENDING_KIND := &"pending_damage_kind"
const PENDING_DIRECT := &"pending_damage_direct"


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
	## Assign（PI）：v1 默认全量归调查员；不打开时点窗。
	_set_pending(game_ctx, inv_id, kind, requested, is_direct)
	## Apply 砖 PreImpact：will take / prevent·reduce。
	if game_ctx.sequences != null:
		game_ctx.sequences.offer_slot(AhcEnums.SequencePhase.WOULD)
	var final_amount := pending_amount(game_ctx, inv_id)
	_clear_pending(game_ctx, inv_id)
	if final_amount <= 0:
		return {"ok": false, "amount": 0, "kind": kind, "prevented": true}
	## Apply：状态原语写入。
	if kind == &"horror":
		game_ctx.mutator.take_horror(inv_id, final_amount)
	else:
		game_ctx.mutator.adjust_marker(
			MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.DAMAGE),
			final_amount
		)
	## Apply 砖 When：已受到伤害/恐惧后的反应。
	if game_ctx.sequences != null:
		game_ctx.sequences.offer_slot(AhcEnums.SequencePhase.WHEN)
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


## Apply-WOULD 窗内：降低尚未写入的量（prevent 用 `by >= pending`）。
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
