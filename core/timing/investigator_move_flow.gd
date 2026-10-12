class_name InvestigatorMoveFlow
extends RefCounted

## 狭义调查员移动内核 · `seq.effect.move`。
## 已位于某地点的调查员，从当前地点移到新地点（leave+enter 同时）。
## 不含：场内外区域广义转移；两地点实体交换（原子、不可 nest、不触发移动时点）。


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	var inv_id: StringName = params.get(
		"investigator_id", params.get("inv_id", &"")
	)
	var dest_id: StringName = params.get(
		"destination_id", params.get("to", &"")
	)
	if inv_id == &"" or dest_id == &"":
		return {"ok": false, "error": "missing_investigator_or_destination"}
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator"}
	var dest := game_ctx.state.registry.get_location(dest_id)
	if dest == null:
		return {"ok": false, "error": "unknown_location"}
	var from_id: StringName = inv.location_tag
	if from_id == &"":
		return {"ok": false, "error": "not_at_location"}
	var require_connected := bool(params.get("require_connected", true))
	if require_connected:
		var current := game_ctx.state.registry.get_location(from_id)
		if current == null:
			return {"ok": false, "error": "not_at_location"}
		if not _is_connected(current, dest_id):
			return {"ok": false, "error": "not_connected"}
	if from_id == dest_id:
		return {
			"ok": true,
			"skipped": true,
			"investigator_id": inv_id,
			"from": from_id,
			"to": dest_id,
		}
	inv.location_tag = dest_id
	if bool(params.get("reveal_on_enter", true)) and not dest.revealed:
		dest.revealed = true
		dest.clues = maxi(dest.clues, 1)
	## 移入后区域变更 → 自动交战（狭义移动的后果，不是广义转移）。
	if bool(params.get("auto_engage_after", true)):
		EngageFlow.nest_after_area_change(game_ctx, dest_id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"effect:move",
			{"investigator_id": inv_id, "from": from_id, "to": dest_id}
		)
	return {
		"ok": true,
		"investigator_id": inv_id,
		"from": from_id,
		"to": dest_id,
		"destination_id": dest_id,
	}


static func _is_connected(from_loc: LocationState, to_id: StringName) -> bool:
	if from_loc.id == to_id:
		return true
	return from_loc.connections.has(to_id)
