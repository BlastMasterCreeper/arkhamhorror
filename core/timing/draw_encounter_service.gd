class_name DrawEncounterService
extends RefCounted

var _catalog: SequenceCatalog


func _init(catalog: SequenceCatalog) -> void:
	_catalog = catalog


func draw_one(game_ctx: GameContext, drawer_id: StringName) -> Dictionary:
	return _catalog.run(
		game_ctx,
		&"seq.draw.encounter",
		{"drawer_id": drawer_id}
	)
