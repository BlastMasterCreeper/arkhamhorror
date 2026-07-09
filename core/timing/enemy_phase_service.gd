class_name EnemyPhaseService
extends RefCounted

var _catalog: SequenceCatalog


func _init(catalog: SequenceCatalog) -> void:
	_catalog = catalog


func run_hunter_patrol(game_ctx: GameContext) -> Dictionary:
	return _catalog.run(game_ctx, &"seq.enemy.3_2_hunter_patrol", {})


func run_patrol(game_ctx: GameContext) -> Dictionary:
	return _catalog.run(game_ctx, &"seq.enemy.3_2_patrol", {})


func run_phase_attacks(game_ctx: GameContext, investigator_id: StringName) -> Dictionary:
	return _catalog.run(
		game_ctx,
		&"seq.enemy.phase_attacks",
		{"investigator_id": investigator_id}
	)


func run_massive_phase_attacks(game_ctx: GameContext) -> Dictionary:
	return _catalog.run(game_ctx, &"seq.enemy.massive_phase_attacks", {})
