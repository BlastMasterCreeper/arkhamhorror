class_name EnemyDefeatResolver
extends RefCounted

## 敌人 defeat / discard-from-play · 08 §8
##
## - damage >= health → 常态检测 → `DefeatFlow`（`seq.effect.defeat`）
## - 卡面击败：`defeat(..., cause=effect)` 无视伤量
## - 击败成功后 nest 退场（`finalize_leave_play`）；Cancel → 无退场
## - discard_from_play：仅离场，不算 defeat


static func deal_damage(
	game_ctx: GameContext,
	enemy_id: StringName,
	amount: int
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or enemy_id == &"" or amount <= 0:
		return {"ok": false, "defeated": false}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "defeated": false}
	enemy.damage += amount
	if enemy.damage < enemy.health:
		return {"ok": true, "defeated": false, "damage": enemy.damage}
	return DefeatFlow.check_enemy_damage_cap(game_ctx, enemy_id)


## 默认按伤害上限检测；卡面击败传 `DefeatFlow.CAUSE_EFFECT`。
static func defeat(
	game_ctx: GameContext,
	enemy_id: StringName,
	cause: StringName = DefeatFlow.CAUSE_DAMAGE_CAP
) -> Dictionary:
	if cause == DefeatFlow.CAUSE_EFFECT:
		return DefeatFlow.defeat_enemy_effect(game_ctx, enemy_id)
	return DefeatFlow.nest_or_run(
		game_ctx,
		{
			"subject": DefeatFlow.SUBJECT_ENEMY,
			"enemy_id": enemy_id,
			"cause": cause,
		}
	)


## 击败成功后的退场（由 `seq.defeat.leave_play` nest 调用）。
static func finalize_leave_play(
	game_ctx: GameContext,
	enemy_id: StringName,
	definition_id: StringName = &""
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or enemy_id == &"":
		return {"ok": false, "defeated": false}
	if game_ctx.state.registry.get_enemy(enemy_id) == null:
		return {"ok": false, "defeated": false}
	_clear_engagement(game_ctx, enemy_id)
	DoomedResolver.try_on_defeat(game_ctx, enemy_id)
	var routed := _route_after_defeat(game_ctx, enemy_id)
	game_ctx.state.registry.unregister_enemy(enemy_id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:defeated",
			{"enemy_id": enemy_id, "victory_display": routed.get("victory_display", false)}
		)
	var card := game_ctx.state.registry.get_card(enemy_id)
	var def_id := definition_id
	if def_id == &"" and card != null:
		def_id = card.id.definition_id
	if card != null and bool(routed.get("victory_display", false)):
		ScenarioObjectiveFlow.check_enemy_defeated(game_ctx, def_id)
	return {
		"ok": true,
		"defeated": true,
		"enemy_id": enemy_id,
		"victory_display": routed.get("victory_display", false),
		"subject": DefeatFlow.SUBJECT_ENEMY,
	}


static func discard_from_play(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or enemy_id == &"":
		return {"ok": false, "discarded": false}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "discarded": false}
	_clear_engagement(game_ctx, enemy_id)
	_route_to_discard(game_ctx, enemy_id)
	game_ctx.state.registry.unregister_enemy(enemy_id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:discarded_from_play",
			{"enemy_id": enemy_id}
		)
	return {"ok": true, "discarded": true, "enemy_id": enemy_id}


static func _clear_engagement(game_ctx: GameContext, enemy_id: StringName) -> void:
	if game_ctx.enemy != null:
		game_ctx.enemy.disengage(game_ctx, enemy_id, false, false)
		return
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return
	if enemy.engaged_with != &"":
		var prev := game_ctx.state.registry.get_investigator(enemy.engaged_with)
		if prev != null:
			prev.threat_area.erase(enemy_id)
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv != null:
			inv.threat_area.erase(enemy_id)
	enemy.engaged_with = &""


static func _route_after_defeat(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	## 去向：Victory/复仇指示 → 胜利区；否则按所有者（遭遇弃牌 / 玩家弃牌 / 无主→置一边）。
	var def_id := _definition_id(game_ctx, enemy_id)
	if CardRegistry.routes_to_victory_display(def_id):
		var moved := _route_to_victory_display(game_ctx, enemy_id)
		return {"victory_display": moved, "dest": &"victory_display"}
	return _route_to_discard(game_ctx, enemy_id)


static func _definition_id(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card != null:
		return card.id.definition_id
	return enemy_id


static func _route_to_victory_display(game_ctx: GameContext, enemy_id: StringName) -> bool:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null or game_ctx.mutator == null:
		return false
	return game_ctx.mutator.move_card(enemy_id, CardSlot.victory_display())


static func _route_to_discard(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null or game_ctx.mutator == null:
		return {"victory_display": false, "dest": &""}
	## 弱点敌人 → 所有者弃牌堆。
	if game_ctx.state.registry.get_investigator(card.owner_id) != null:
		game_ctx.mutator.move_card(enemy_id, CardSlot.discard_top(card.owner_id))
		return {"victory_display": false, "dest": &"owner_discard"}
	## 遭遇敌人 → 遭遇弃牌堆。
	if card.owner_id == &"encounter":
		game_ctx.mutator.move_card(enemy_id, CardSlot.encounter_discard_top())
		return {"victory_display": false, "dest": &"encounter_discard"}
	## 无玩家/遭遇所有者 → 置一边（少见；剧情体主要走支援路径）。
	game_ctx.mutator.move_to_set_aside(enemy_id)
	return {"victory_display": false, "dest": &"set_aside"}
