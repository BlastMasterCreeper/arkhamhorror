class_name ElusiveResolver
extends RefCounted

## 逃逸（Elusive）· Grimoire / 08 §6.5
##
## 两条路径（互斥分类，非同时）：
## - 敌人 **攻击**（阶段 / 借机 / 反击 / 警戒）→ perform_attack 后 try_flee_after_enemy_attack
## - 敌人 **被攻击**（调查员 Fight）→ post-ST7 try_flee_was_attacked
## 借机攻击是敌人发起的攻击，走第一条，不是「被攻击」。


static func try_flee_after_enemy_attack(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	return _try_flee(game_ctx, enemy_id, &"attacks")


static func try_flee_was_attacked(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	return _try_flee(game_ctx, enemy_id, &"was_attacked")


static func _try_flee(
	game_ctx: GameContext,
	enemy_id: StringName,
	cause: StringName
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or enemy_id == &"":
		return {"ok": true, "fled": false}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null or enemy.exhausted:
		return {"ok": true, "fled": false}
	var def_id := _definition_id(game_ctx, enemy_id)
	if not CardRegistry.is_elusive(def_id):
		return {"ok": true, "fled": false}
	var from_loc := enemy.location_tag
	_disengage_all(game_ctx, enemy_id)
	var dest := _pick_flee_destination(game_ctx, from_loc)
	if dest != &"" and dest != from_loc:
		enemy.location_tag = dest
	_disengage_all(game_ctx, enemy_id)
	if game_ctx.enemy != null:
		game_ctx.enemy.set_enemy_exhausted(game_ctx, enemy_id, true, false)
	else:
		enemy.exhausted = true
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:elusive_flee",
			{
				"enemy_id": enemy_id,
				"cause": cause,
				"from": from_loc,
				"to": enemy.location_tag,
			}
		)
	return {"ok": true, "fled": true, "to_location": enemy.location_tag}


static func _disengage_all(game_ctx: GameContext, enemy_id: StringName) -> void:
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return
	if enemy.massive:
		MassiveEngagement.sync_for_enemy(game_ctx, enemy_id)
		enemy.engaged_with = &""
		return
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv != null:
			inv.threat_area.erase(enemy_id)
	enemy.engaged_with = &""


static func _pick_flee_destination(game_ctx: GameContext, from_location: StringName) -> StringName:
	if from_location == &"":
		return &""
	var loc := game_ctx.state.registry.get_location(from_location)
	if loc == null:
		return &""
	var empty: Array[StringName] = []
	var occupied: Array[StringName] = []
	for conn_id in loc.connections:
		if game_ctx.state.registry.get_location(conn_id) == null:
			continue
		if _has_investigator_at(game_ctx, conn_id):
			occupied.append(conn_id)
		else:
			empty.append(conn_id)
	if not empty.is_empty():
		return empty[0]
	if not occupied.is_empty():
		return occupied[0]
	return &""


static func _has_investigator_at(game_ctx: GameContext, location_tag: StringName) -> bool:
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv != null and not inv.eliminated and inv.location_tag == location_tag:
			return true
	return false


static func _definition_id(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null:
		return enemy_id
	return card.id.definition_id
