class_name EnemyPhaseService
extends RefCounted

var _catalog: SequenceCatalog


func _init(catalog: SequenceCatalog) -> void:
	_catalog = catalog


func run_3_2(game_ctx: GameContext) -> Dictionary:
	## Framework 3.2 基础手续（枚举 / resolve Hunter·Patrol）；非关键词平行流程。
	return _catalog.run(game_ctx, &"seq.enemy.3_2", {})


func run_phase_attacks(game_ctx: GameContext, investigator_id: StringName) -> Dictionary:
	## Framework 3.3 基础手续；Massive 经 seq.keyword.massive 替换，无平行流程。
	return _catalog.run(
		game_ctx,
		&"seq.enemy.phase_attacks",
		{"investigator_id": investigator_id}
	)
