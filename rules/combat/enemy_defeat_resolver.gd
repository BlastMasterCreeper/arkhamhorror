class_name EnemyDefeatResolver
extends RefCounted

## 敌人 defeat / discard-from-play · 08 §8
##
## - damage >= health → defeat（触发 Doomed 等 defeat 关键词）
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
	return defeat(game_ctx, enemy_id)


static func defeat(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or enemy_id == &"":
		return {"ok": false, "defeated": false}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "defeated": false}
	if enemy.damage < enemy.health:
		return {"ok": true, "defeated": false}
	var location_id := enemy.location_tag
	var definition_id := _definition_id(game_ctx, enemy_id)
	## 先收集 When/After defeated（仍 WHILE_IN_PLAY），再离场。
	if (
		game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(&"seq.enemy.defeat")
	):
		game_ctx.sequence_catalog.run(
			game_ctx,
			&"seq.enemy.defeat",
			{
				"enemy_id": enemy_id,
				"location_id": location_id,
				"definition_id": definition_id,
			}
		)
	return _finalize_defeat(game_ctx, enemy_id, definition_id)


static func _finalize_defeat(
	game_ctx: GameContext,
	enemy_id: StringName,
	definition_id: StringName = &""
) -> Dictionary:
	if game_ctx.state.registry.get_enemy(enemy_id) == null:
		return {"ok": false, "defeated": false}
	_clear_engagement(game_ctx, enemy_id)
	DoomedResolver.try_on_defeat(game_ctx, enemy_id)
	var routed := _route_after_defeat(game_ctx, enemy_id)
	if game_ctx.triggered_abilities != null:
		game_ctx.triggered_abilities.uninstall_by_source(enemy_id)
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
	}


static func _definition_id(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card != null:
		return card.id.definition_id
	return enemy_id


static func discard_from_play(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or enemy_id == &"":
		return {"ok": false, "discarded": false}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "discarded": false}
	_clear_engagement(game_ctx, enemy_id)
	_route_to_discard(game_ctx, enemy_id)
	if game_ctx.triggered_abilities != null:
		game_ctx.triggered_abilities.uninstall_by_source(enemy_id)
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
	var def_id := _definition_id(game_ctx, enemy_id)
	if CardRegistry.victory_points(def_id) > 0:
		var moved := _route_to_victory_display(game_ctx, enemy_id)
		return {"victory_display": moved}
	_route_to_discard(game_ctx, enemy_id)
	return {"victory_display": false}


static func _route_to_victory_display(game_ctx: GameContext, enemy_id: StringName) -> bool:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null or game_ctx.mutator == null:
		return false
	return game_ctx.mutator.move_card(enemy_id, CardSlot.victory_display())


static func _route_to_discard(game_ctx: GameContext, enemy_id: StringName) -> void:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null or game_ctx.mutator == null:
		return
	if card.owner_id == &"encounter":
		game_ctx.mutator.move_card(enemy_id, CardSlot.encounter_discard_top())
		return
	if game_ctx.state.registry.get_investigator(card.owner_id) != null:
		game_ctx.mutator.move_card(enemy_id, CardSlot.discard_top(card.owner_id))
		return
	## 无弃牌堆去向 → 从游戏中移除。
	card.zone = AhcEnums.Zone.REMOVED_FROM_GAME
	if not game_ctx.state.removed_from_game.has(enemy_id):
		game_ctx.state.removed_from_game.append(enemy_id)
