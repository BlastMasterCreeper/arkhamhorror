class_name FleeDestinationQuery
extends RefCounted

## 逃逸目的地：连接地点里优先没有调查员的，否则任一连接。


static func pick(game_ctx: GameContext, from_location: StringName) -> StringName:
	if game_ctx == null or game_ctx.state == null or from_location == &"":
		return &""
	var loc := game_ctx.state.registry.get_location(from_location)
	if loc == null:
		return &""
	var empty: Array[StringName] = []
	var occupied: Array[StringName] = []
	for conn_id in loc.connections:
		if game_ctx.state.registry.get_location(conn_id) == null:
			continue
		if _has_investigator_at(game_ctx, conn_id):
			occupied.append(conn_id)
		else:
			empty.append(conn_id)
	if not empty.is_empty():
		return empty[0]
	if not occupied.is_empty():
		return occupied[0]
	return &""


static func _has_investigator_at(game_ctx: GameContext, location_tag: StringName) -> bool:
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv != null and not inv.eliminated and inv.location_tag == location_tag:
			return true
	return false
