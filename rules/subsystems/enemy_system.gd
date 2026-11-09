class_name EnemySystem
extends RefCounted

## 敌人子系统挂点（`GameContext.enemy`）——**已萎缩**。
## 业务入口：
## - 生成 → `SpawnFlow` / `seq.encounter.spawn`
## - 交战 / 脱离 → `EngageFlow` / `seq.engage`
## - 进入威胁区 → `EnterThreatAreaFlow` / `seq.effect.enter_threat_area`
## - 横置/重整 → `ExhaustReadyFlow`
## - 伤/败 → `EnemyDefeatResolver` / `seq.effect.defeat`
## - 敌军阶段 → `EnemyPhaseService`
## 本类不再提供 spawn_* / apply_engage / deal_damage 等语义方法。


var _state: GameStateStore
var _log: GameLog
var _game_ctx: GameContext = null


func _init(state: GameStateStore, log: GameLog) -> void:
	_state = state
	_log = log


func bind_context(ctx: GameContext) -> void:
	_game_ctx = ctx
