class_name NearestLocationResolver
extends RefCounted

## 最近地点 · 等距时由 drawer 选目标（16 §7.2.1）。


static func candidates_without_attachment(
	game_ctx: GameContext,
	drawer_id: StringName,
	attachment_definition_id: StringName
) -> Array[StringName]:
	if game_ctx == null or game_ctx.state == null:
		return []
	var from := _drawer_location_tag(game_ctx, drawer_id)
	if from == &"":
		return []
	var best_dist := 999999
	var best: Array[StringName] = []
	for loc_id in _locations_in_play(game_ctx):
		if _location_has_attachment_definition(game_ctx, loc_id, attachment_definition_id):
			continue
		var dist := EnemyPathfinding.shortest_path_distance(from, loc_id, game_ctx)
		if dist < 0:
			continue
		if dist < best_dist:
			best_dist = dist
			best = [loc_id]
		elif dist == best_dist:
			best.append(loc_id)
	return best


static func pick_nearest_without_attachment(
	game_ctx: GameContext,
	drawer_id: StringName,
	attachment_definition_id: StringName
) -> StringName:
	var candidates := candidates_without_attachment(
		game_ctx, drawer_id, attachment_definition_id
	)
	if candidates.is_empty():
		return &""
	if candidates.size() == 1:
		return candidates[0]
	if game_ctx.interaction != null:
		var pick: Variant = game_ctx.interaction.ask_pick_target(
			candidates,
			drawer_id,
			&"pick:nearest_location_tie",
			game_ctx
		)
		if pick is StringName:
			return pick as StringName
		if pick != null:
			return StringName(str(pick))
	return candidates[0]


static func location_has_attachment_definition(
	game_ctx: GameContext,
	location_id: StringName,
	attachment_definition_id: StringName
) -> bool:
	return _location_has_attachment_definition(
		game_ctx, location_id, attachment_definition_id
	)


static func _locations_in_play(game_ctx: GameContext) -> Array[StringName]:
	var out: Array[StringName] = []
	for loc_id in game_ctx.state.registry.all_location_ids():
		var card := game_ctx.state.registry.get_card(loc_id)
		if card != null and card.zone == AhcEnums.Zone.LOCATION_AREA:
			out.append(loc_id)
	return out


static func _location_has_attachment_definition(
	game_ctx: GameContext,
	location_id: StringName,
	attachment_definition_id: StringName
) -> bool:
	if attachment_definition_id == &"":
		return false
	var host := game_ctx.state.registry.get_card(location_id)
	if host == null:
		return false
	for attached_eid in host.attachments:
		var attached := game_ctx.state.registry.get_card(attached_eid.instance_id)
		if attached != null and attached.id.definition_id == attachment_definition_id:
			return true
	return false


static func _drawer_location_tag(game_ctx: GameContext, drawer_id: StringName) -> StringName:
	var inv := game_ctx.state.registry.get_investigator(drawer_id)
	if inv == null or inv.location_tag == &"":
		return &""
	if game_ctx.state.registry.get_location(inv.location_tag) == null:
		return &""
	return inv.location_tag
