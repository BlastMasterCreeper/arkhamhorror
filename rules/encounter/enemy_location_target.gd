class_name EnemyLocationTarget
extends RefCounted

## 卡面/规则文本目标 → 地点 tag（移动的直接目标永远是地点）。


static func resolve(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "reason": &"invalid_context"}
	var target := str(params.get("target", ""))
	var drawer_id: StringName = params.get(
		"drawer_id", params.get("controller_id", &"")
	)
	var location_tag := &"" as StringName
	match target:
		"drawer_location", "your_location", "investigator_location":
			location_tag = _investigator_location(game_ctx, drawer_id)
		_:
			if target != "":
				location_tag = StringName(target)
	if location_tag == &"":
		return {"ok": false, "reason": &"unresolved_location", "target": target}
	if game_ctx.state.registry.get_location(location_tag) == null:
		return {"ok": false, "reason": &"unknown_location", "location_tag": location_tag}
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:resolve_location",
			{"target": target, "location_tag": location_tag, "drawer_id": drawer_id}
		)
	return {"ok": true, "location_tag": location_tag, "target": target}


static func _investigator_location(game_ctx: GameContext, inv_id: StringName) -> StringName:
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null or inv.location_tag == &"":
		return &""
	return inv.location_tag
