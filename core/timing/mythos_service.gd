class_name MythosService
extends RefCounted

var _catalog: SequenceCatalog


func _init(catalog: SequenceCatalog) -> void:
	_catalog = catalog


func place_doom(game_ctx: GameContext) -> Dictionary:
	return _catalog.run(game_ctx, &"seq.mythos.place_doom", {})


func check_doom_threshold(game_ctx: GameContext) -> Dictionary:
	return _catalog.run(game_ctx, &"seq.mythos.check_doom_threshold", {})
