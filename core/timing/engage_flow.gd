class_name EngageFlow
extends RefCounted

## 通用 engage 命名流程 · 执行时以 mode 区分自动交战 / 行动 / 效果。
##
## 自动交战（mode=auto）由 **区域变更** 嵌套触发，不限于地点移动：
## - 调查员 / 敌人 **地点** 变化后同地点相遇
## - **交战状态** 变化（如脱离）后敌人仍与调查员同地点 → 重新按 Prey/Lead 选目标
## - **重整**（横置 → 未横置）后同地点有调查员 → 自动交战（Upkeep 4.3 等）
## 效果导致的脱离常附带「暂不能自动交战」抑制，避免死循环（见 EnemyState.auto_engage_suppressed）。
## 术语：躲避（Evade）成功 → 敌人横置（exhausted），横置期间不参与自动交战。


static func resolve(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.enemy == null:
		return {"ok": false}
	var mode: StringName = params.get("mode", &"auto")
	match mode:
		&"auto":
			return _resolve_auto(game_ctx, params)
		&"action", &"effect":
			return _resolve_explicit(game_ctx, params)
		_:
			return {"ok": false, "reason": &"unknown_mode"}


static func nest_after_area_change(
	game_ctx: GameContext,
	location_tag: StringName,
	enemy_id: StringName = &"",
	cause: StringName = &"location"
) -> Dictionary:
	if game_ctx == null or location_tag == &"":
		return {"ok": true, "skipped": true}
	var params := {
		"mode": &"auto",
		"location_tag": location_tag,
		"cause": cause,
	}
	if enemy_id != &"":
		params["enemy_id"] = enemy_id
	if game_ctx.sequence_catalog == null:
		return resolve(game_ctx, params)
	return game_ctx.sequence_catalog.nest(game_ctx, &"seq.engage", params)


static func _resolve_auto(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var location_tag: StringName = params.get("location_tag", &"")
	var focus_enemy: StringName = params.get("enemy_id", &"")
	if location_tag == &"" and focus_enemy != &"":
		var enemy := game_ctx.state.registry.get_enemy(focus_enemy)
		if enemy != null:
			location_tag = enemy.location_tag
	if location_tag == &"":
		return {"ok": true, "skipped": true}
	var engaged: Array[Dictionary] = []
	var last_inv := &"" as StringName
	if focus_enemy != &"":
		var focus := game_ctx.state.registry.get_enemy(focus_enemy)
		if focus != null and focus.massive:
			MassiveEngagement.sync_at_location(game_ctx, location_tag)
			return {"ok": true, "location_tag": location_tag, "engaged": [], "investigator_id": &""}
		var one := _auto_engage_enemy(game_ctx, focus_enemy, location_tag)
		if one.get("investigator_id", &"") != &"":
			engaged.append(one)
			last_inv = one.get("investigator_id", &"") as StringName
	else:
		MassiveEngagement.sync_at_location(game_ctx, location_tag)
		for enemy_id in game_ctx.state.registry.all_enemy_ids():
			var enemy := game_ctx.state.registry.get_enemy(enemy_id)
			if enemy == null or enemy.location_tag != location_tag:
				continue
			if enemy.massive or enemy.aloof or enemy.engaged_with != &"":
				continue
			if enemy.exhausted or enemy.auto_engage_suppressed:
				continue
			var one := _auto_engage_enemy(game_ctx, enemy_id, location_tag)
			if one.get("investigator_id", &"") != &"":
				engaged.append(one)
				last_inv = one.get("investigator_id", &"") as StringName
	return {
		"ok": true,
		"location_tag": location_tag,
		"engaged": engaged,
		"investigator_id": last_inv,
	}


static func _auto_engage_enemy(
	game_ctx: GameContext,
	enemy_id: StringName,
	location_tag: StringName
) -> Dictionary:
	var def_id := _definition_id(game_ctx, enemy_id)
	var result := game_ctx.enemy.auto_engage_at_location(
		game_ctx, enemy_id, location_tag, def_id
	)
	if result.get("investigator_id", &"") == &"":
		return {}
	return {
		"enemy_id": enemy_id,
		"investigator_id": result.get("investigator_id", &""),
	}


static func _resolve_explicit(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var enemy_id: StringName = params.get("enemy_id", &"")
	var inv_id: StringName = params.get(
		"investigator_id", params.get("target_investigator", &"")
	)
	if enemy_id == &"" or inv_id == &"":
		return {"ok": false, "reason": &"missing_pair"}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if enemy == null or inv == null:
		return {"ok": false, "reason": &"unknown_entity"}
	if not enemy.is_at_location(inv.location_tag):
		return {"ok": false, "reason": &"wrong_location"}
	game_ctx.enemy.apply_engage(enemy_id, inv_id)
	return {"ok": true, "enemy_id": enemy_id, "investigator_id": inv_id}


static func _definition_id(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null:
		return &""
	return card.id.definition_id
