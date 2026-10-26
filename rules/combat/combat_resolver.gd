class_name CombatResolver
extends RefCounted

var _state: GameStateStore
var _log: GameLog
var _timing: TimingBus
var _game_ctx: GameContext = null


func _init(state: GameStateStore, log: GameLog, timing: TimingBus = null) -> void:
	_state = state
	_log = log
	_timing = timing


func bind_game_context(ctx: GameContext) -> void:
	_game_ctx = ctx


func game_context() -> GameContext:
	return _game_ctx


func perform_attack(attack: EnemyAttack) -> void:
	if attack == null:
		return
	var inv := _state.registry.get_investigator(attack.target_investigator)
	if inv == null:
		return
	## 承伤经 seq.effect.damage.assignable（Assign+Apply 同帧）。
	if _game_ctx != null:
		if attack.damage > 0:
			_deal_via_seq(&"damage", attack.damage, attack)
		if attack.horror > 0:
			_deal_via_seq(&"horror", attack.horror, attack)
	else:
		inv.damage_taken += attack.damage
		inv.horror_taken += attack.horror
	_log.log(
		AhcEnums.LogCategory.DAMAGE,
		"enemy_attack:%s" % attack.kind,
		{
			"enemy": attack.enemy_id,
			"target": attack.target_investigator,
			"damage": attack.damage,
			"horror": attack.horror,
		}
	)
	## 伤/恐常态检测（seq 路径内已 check；此处兜底无 catalog 时）。
	if _game_ctx != null and (attack.damage > 0 or attack.horror > 0):
		DefeatFlow.check_investigator_caps(_game_ctx, attack.target_investigator)
	if _timing:
		_timing.emit_timing(
			&"enemy_attack_completed",
			{"enemy": attack.enemy_id, "target": attack.target_investigator, "kind": attack.kind}
		)
	if attack.exhaust_after and _game_ctx != null:
		ExhaustReadyFlow.nest_or_run_exhaust(
			_game_ctx,
			{
				"target_kind": ExhaustReadyFlow.TARGET_ENEMY,
				"enemy_id": attack.enemy_id,
				"trigger_area_change": false,
			}
		)
	elif attack.exhaust_after:
		var enemy := _state.registry.get_enemy(attack.enemy_id)
		if enemy:
			enemy.exhausted = true
	if _game_ctx != null:
		ElusiveResolver.try_flee_after_enemy_attack(_game_ctx, attack.enemy_id)


func _deal_via_seq(kind: StringName, amount: int, attack: EnemyAttack) -> void:
	var params := {
		"controller_id": attack.target_investigator,
		"kind": kind,
		"amount": amount,
		"source": attack.enemy_id,
	}
	if (
		_game_ctx.sequence_catalog != null
		and _game_ctx.sequence_catalog.has_flow(&"seq.effect.damage.assignable")
	):
		_game_ctx.sequence_catalog.nest(
			_game_ctx, &"seq.effect.damage.assignable", params
		)
		return
	DamagePipeline.deal_investigator(
		_game_ctx, attack.target_investigator, kind, amount, false
	)
