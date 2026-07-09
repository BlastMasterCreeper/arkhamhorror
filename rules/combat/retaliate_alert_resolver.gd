class_name RetaliateAlertResolver
extends RefCounted

## 反击（Retaliate）/ 警戒（Alert）触发 + 时点层（08 §6 · OQ-03-02）。
##
## Grimoire：均在 skill test **全部结果 apply 之后**（ST.7 步骤完成之后、ST.8 之前）才
## `perform_attack`；**不属于** ST.7 `on_fail` 后果链内的同步结算。
## - Retaliate：Fight 检定失败
## - Alert：Evade 检定失败


static func try_retaliate(
	game_ctx: GameContext,
	enemy_id: StringName,
	investigator_id: StringName
) -> Dictionary:
	if not _can_trigger(game_ctx, enemy_id, investigator_id, &"retaliate"):
		return {"ok": true, "triggered": false}
	return _perform(game_ctx, enemy_id, investigator_id, AhcEnums.AttackKind.RETALIATE)


static func try_alert(
	game_ctx: GameContext,
	enemy_id: StringName,
	investigator_id: StringName
) -> Dictionary:
	if not _can_trigger(game_ctx, enemy_id, investigator_id, &"alert"):
		return {"ok": true, "triggered": false}
	return _perform(game_ctx, enemy_id, investigator_id, AhcEnums.AttackKind.ALERT)


static func resolve_post_st7(game_ctx: GameContext, test: SkillTestContext) -> void:
	if game_ctx == null or test == null or test.success:
		return
	if test.target_enemy_id == &"":
		return
	var performer := test.performing_investigator
	match test.skill:
		AhcEnums.SkillType.COMBAT:
			try_retaliate(game_ctx, test.target_enemy_id, performer)
			ElusiveResolver.try_flee_was_attacked(game_ctx, test.target_enemy_id)
		AhcEnums.SkillType.AGILITY:
			try_alert(game_ctx, test.target_enemy_id, performer)


static func _can_trigger(
	game_ctx: GameContext,
	enemy_id: StringName,
	investigator_id: StringName,
	keyword: StringName
) -> bool:
	if game_ctx == null or game_ctx.state == null or enemy_id == &"" or investigator_id == &"":
		return false
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	var inv := game_ctx.state.registry.get_investigator(investigator_id)
	if enemy == null or inv == null or enemy.exhausted:
		return false
	if not enemy.is_at_location(inv.location_tag):
		return false
	var def_id := _definition_id(game_ctx, enemy_id)
	match keyword:
		&"retaliate":
			return CardRegistry.is_retaliate(def_id)
		&"alert":
			return CardRegistry.is_alert(def_id)
	return false


static func _perform(
	game_ctx: GameContext,
	enemy_id: StringName,
	investigator_id: StringName,
	kind: AhcEnums.AttackKind
) -> Dictionary:
	if game_ctx.combat == null:
		return {"ok": false, "triggered": false}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "triggered": false}
	var strike := EnemyAttack.enemy_strike(
		enemy_id,
		investigator_id,
		enemy.attack_damage,
		enemy.attack_horror,
		false,
		kind
	)
	game_ctx.combat.perform_attack(strike)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:keyword_attack:%s" % kind,
			{
				"enemy_id": enemy_id,
				"target": investigator_id,
				"damage": enemy.attack_damage,
				"horror": enemy.attack_horror,
			}
		)
	return {"ok": true, "triggered": true, "kind": kind}


static func _definition_id(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null:
		return enemy_id
	return card.id.definition_id
