class_name EnemyAttackFlow
extends RefCounted

## 敌人攻击效果核 · `seq.enemy.attack` RESOLVE 体（及 Trigger 直调）。
## 原 `CombatResolver.perform_attack` 并入此处；触发器只构造 `EnemyAttack` 再交本类。


static func perform(game_ctx: GameContext, attack: EnemyAttack) -> void:
	if attack == null or game_ctx == null or game_ctx.state == null:
		return
	var inv := game_ctx.state.registry.get_investigator(attack.target_investigator)
	if inv == null:
		return
	## 伤+恐同一条 seq.effect.deal.assignable（禁止各 nest 一次）。
	if attack.damage > 0 or attack.horror > 0:
		_deal_via_seq(game_ctx, attack)
	else:
		inv.damage_taken += attack.damage
		inv.horror_taken += attack.horror
	if game_ctx.log != null:
		game_ctx.log.log(
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
	if attack.damage > 0 or attack.horror > 0:
		DefeatFlow.check_investigator_caps(game_ctx, attack.target_investigator)
	if game_ctx.timing != null:
		game_ctx.timing.emit_timing(
			&"enemy_attack_completed",
			{"enemy": attack.enemy_id, "target": attack.target_investigator, "kind": attack.kind}
		)
	if attack.exhaust_after:
		ExhaustReadyFlow.nest_or_run_exhaust(
			game_ctx,
			{
				"target_kind": ExhaustReadyFlow.TARGET_ENEMY,
				"enemy_id": attack.enemy_id,
				"trigger_area_change": false,
			}
		)
	ElusiveTrigger.try_flee_after_enemy_attack(game_ctx, attack.enemy_id)


static func _deal_via_seq(game_ctx: GameContext, attack: EnemyAttack) -> void:
	var params := {
		"controller_id": attack.target_investigator,
		"damage": attack.damage,
		"horror": attack.horror,
		"source": attack.enemy_id,
		"target": &"controller",
	}
	if (
		game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(&"seq.effect.deal.assignable")
	):
		game_ctx.sequence_catalog.nest(
			game_ctx, &"seq.effect.deal.assignable", params
		)
		return
	if (
		game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(&"seq.effect.damage.assignable")
	):
		game_ctx.sequence_catalog.nest(
			game_ctx, &"seq.effect.damage.assignable", params
		)
		return
	DamagePipeline.deal_investigator_bundle(
		game_ctx,
		attack.target_investigator,
		attack.damage,
		attack.horror,
		false,
		false
	)
