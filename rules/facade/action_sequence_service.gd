class_name ActionSequenceService
extends RefCounted

var _catalog: SequenceCatalog


func _init(catalog: SequenceCatalog) -> void:
	_catalog = catalog


func draw(
	game_ctx: GameContext,
	inv_id: StringName,
	amount: int = 1,
	source_tags: Array[StringName] = []
) -> Dictionary:
	return _catalog.run(
		game_ctx,
		&"seq.action.draw",
		{
			"inv_id": inv_id,
			"amount": amount,
			"source_tags": source_tags,
		}
	)


func gain_resource(
	game_ctx: GameContext,
	controller_id: StringName,
	base_amount: int = 1,
	source_tags: Array[StringName] = []
) -> Dictionary:
	return _catalog.run(
		game_ctx,
		&"seq.action.gain_resource",
		{
			"controller_id": controller_id,
			"base_amount": base_amount,
			"source_tags": source_tags,
		}
	)


func move(
	game_ctx: GameContext,
	inv_id: StringName,
	extra: Dictionary = {}
) -> Dictionary:
	return _catalog.run(
		game_ctx,
		&"seq.action.move",
		{"inv_id": inv_id, "extra": extra}
	)


func investigate(
	game_ctx: GameContext,
	inv_id: StringName,
	extra: Dictionary = {}
) -> Dictionary:
	return _catalog.run(
		game_ctx,
		&"seq.action.investigate",
		{"inv_id": inv_id, "extra": extra}
	)


func fight(
	game_ctx: GameContext,
	inv_id: StringName,
	extra: Dictionary = {}
) -> Dictionary:
	return _catalog.run(
		game_ctx,
		&"seq.action.fight",
		{"inv_id": inv_id, "extra": extra}
	)


func engage(
	game_ctx: GameContext,
	inv_id: StringName,
	extra: Dictionary = {}
) -> Dictionary:
	return _catalog.run(
		game_ctx,
		&"seq.action.engage",
		{"inv_id": inv_id, "extra": extra}
	)


func evade(
	game_ctx: GameContext,
	inv_id: StringName,
	extra: Dictionary = {}
) -> Dictionary:
	return _catalog.run(
		game_ctx,
		&"seq.action.evade",
		{"inv_id": inv_id, "extra": extra}
	)
