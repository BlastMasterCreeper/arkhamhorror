class_name ResourceGainService
extends RefCounted

var _catalog: SequenceCatalog


func _init(catalog: SequenceCatalog) -> void:
	_catalog = catalog


func gain(
	game_ctx: GameContext,
	controller_id: StringName,
	base_amount: int,
	source_tags: Array[StringName]
) -> int:
	var result := _catalog.run(
		game_ctx,
		&"seq.gain_resource",
		{
			"controller_id": controller_id,
			"base_amount": base_amount,
			"source_tags": source_tags,
		}
	)
	return int(result.get("amount", base_amount))
