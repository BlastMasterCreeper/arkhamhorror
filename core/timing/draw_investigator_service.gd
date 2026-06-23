class_name DrawInvestigatorService
extends RefCounted

var _catalog: SequenceCatalog


func _init(catalog: SequenceCatalog) -> void:
	_catalog = catalog


## 一次「调查员抽牌」指令（amount=1 为 Draw 行动/抽 1 效果）。
func draw_cards(
	game_ctx: GameContext,
	inv_id: StringName,
	amount: int,
	source_tags: Array[StringName] = []
) -> Dictionary:
	if amount <= 0:
		return _empty_ok()
	return _catalog.run(
		game_ctx,
		&"seq.draw.investigator",
		{
			"inv_id": inv_id,
			"amount": amount,
			"source_tags": source_tags,
		}
	)


func _empty_ok() -> Dictionary:
	return {
		"ok": true,
		"drew": false,
		"drawn": [],
		"shuffled": false,
		"shuffles": 0,
		"horror_taken": 0,
		"defeated": false,
		"revelations": [],
	}
