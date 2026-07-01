class_name SpawnLocationResolver
extends RefCounted


static func resolve(
	spec: SpawnInstructionSpec,
	drawer_id: StringName,
	game_ctx: GameContext
) -> StringName:
	if spec == null or game_ctx == null:
		return &""
	match spec.selector_kind:
		SpawnInstructionSpec.SelectorKind.DRAWER_LOCATION:
			return _drawer_location(game_ctx, drawer_id)
		SpawnInstructionSpec.SelectorKind.NAMED_LOCATION:
			return _named_location(game_ctx, spec.location_tag)
	return &""


static func _drawer_location(game_ctx: GameContext, drawer_id: StringName) -> StringName:
	var inv := game_ctx.state.registry.get_investigator(drawer_id)
	if inv == null or inv.location_tag == &"":
		return &""
	if game_ctx.state.registry.get_location(inv.location_tag) == null:
		return &""
	return inv.location_tag


static func _named_location(game_ctx: GameContext, location_tag: StringName) -> StringName:
	if location_tag == &"":
		return &""
	if game_ctx.state.registry.get_location(location_tag) == null:
		return &""
	return location_tag
