class_name EngageFlow
extends RefCounted

## 通用交战命名流程 `seq.engage`。
##
## 只有两条路径（`mode`）：
## - **auto**：框架区域变更后的自动交战（Prey/Lead；冷漠/横置跳过）
## - **effect**：效果交战（卡面 nest、以及基础 Engage 行动外壳 nest）
##
## 交战状态 = RestrictionKind.ENGAGEMENT Buff（与威胁区场面脱钩）。
## enter_threat：场面进威胁区 + Register Buff；grant：仅 Register Buff（视为交战）。
## 禁止另铸 `seq.enemy.auto_engage` 等按场合拆名。


const MODE_AUTO: StringName = &"auto"
const MODE_EFFECT: StringName = &"effect"

const PLACEMENT_ENTER_THREAT: StringName = &"enter_threat"
const PLACEMENT_GRANT: StringName = &"grant"


static func resolve(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.enemy == null:
		return {"ok": false}
	var normalized := _normalize_params(params)
	match normalized["mode"] as StringName:
		MODE_AUTO:
			return _resolve_auto(game_ctx, normalized)
		MODE_EFFECT:
			return _resolve_effect(game_ctx, normalized)
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
		"mode": MODE_AUTO,
		"placement": PLACEMENT_ENTER_THREAT,
		"location_tag": location_tag,
		"cause": cause,
		"require_same_location": true,
	}
	if enemy_id != &"":
		params["enemy_id"] = enemy_id
	if game_ctx.sequence_catalog == null:
		return resolve(game_ctx, params)
	return game_ctx.sequence_catalog.nest(game_ctx, &"seq.engage", params)


static func _normalize_params(params: Dictionary) -> Dictionary:
	var out := params.duplicate()
	## 历史 `source` / `mode=action` → effect（行动交战 = 效果交战）。
	var raw: StringName = out.get("mode", out.get("source", MODE_AUTO)) as StringName
	var mode := MODE_AUTO
	if raw == MODE_AUTO or raw == &"":
		mode = MODE_AUTO
	else:
		## effect、action、以及其它明示交战入口 → effect
		mode = MODE_EFFECT
	out["mode"] = mode
	out.erase("source")
	out.erase("initiation")
	var placement: StringName = out.get("placement", PLACEMENT_ENTER_THREAT) as StringName
	if placement == &"":
		placement = PLACEMENT_ENTER_THREAT
	out["placement"] = placement
	if not out.has("require_same_location"):
		out["require_same_location"] = placement != PLACEMENT_GRANT
	return out


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
			return {
				"ok": true,
				"mode": MODE_AUTO,
				"placement": PLACEMENT_ENTER_THREAT,
				"location_tag": location_tag,
				"engaged": [],
				"investigator_id": &"",
			}
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
			if enemy.massive or enemy.aloof:
				continue
			if EngagementStatus.is_engaged(game_ctx, enemy_id):
				continue
			if enemy.exhausted or enemy.auto_engage_suppressed:
				continue
			var one := _auto_engage_enemy(game_ctx, enemy_id, location_tag)
			if one.get("investigator_id", &"") != &"":
				engaged.append(one)
				last_inv = one.get("investigator_id", &"") as StringName
	return {
		"ok": true,
		"mode": MODE_AUTO,
		"placement": PLACEMENT_ENTER_THREAT,
		"location_tag": location_tag,
		"cause": params.get("cause", &"location"),
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


static func _resolve_effect(game_ctx: GameContext, params: Dictionary) -> Dictionary:
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
	var placement: StringName = params.get("placement", PLACEMENT_ENTER_THREAT)
	var require_same: bool = bool(params.get("require_same_location", true))
	if EngagementStatus.is_engaged_with(game_ctx, enemy_id, inv_id):
		return {"ok": false, "reason": &"already_engaged", "error": "already_engaged"}
	if require_same and not enemy.is_at_location(inv.location_tag):
		return {"ok": false, "reason": &"wrong_location", "error": "wrong_location"}
	## enter_threat：场面进威胁区 + Buff；grant：仅交战状态 Buff（视为交战）。
	var enter_threat := placement != PLACEMENT_GRANT
	game_ctx.enemy.apply_engage(enemy_id, inv_id, enter_threat, game_ctx)
	return {
		"ok": true,
		"enemy_id": enemy_id,
		"investigator_id": inv_id,
		"mode": MODE_EFFECT,
		"placement": placement,
		"engagement_buff": true,
		"enter_threat": enter_threat,
	}


static func _definition_id(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null:
		return &""
	return card.id.definition_id
