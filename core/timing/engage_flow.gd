class_name EngageFlow
extends RefCounted

## 通用交战命名流程 `seq.engage`。
##
## 常态：同地点敌人进入调查员威胁区（成对写入 `engaged_with` + `threat_area`）。
## 特殊：可不要求同地点；可不走「从地点进入威胁区」的区划动作，仅赋予成对交战状态
## （`placement=grant`；日后可叠 Register Buff，仍走本 flow）。
##
## 入口来源（`source` / 兼容字段 `mode`）与是否调查员主动（`initiation`）正交：
## - auto：区域变更后的自动交战（initiation=automatic）
## - action：Engage 行动外壳 nest（initiation=investigator）
## - effect：卡牌效果 nest（默认 initiation=investigator；卡面可改）
##
## 禁止另铸 `seq.enemy.auto_engage` 等按场合拆名。


const SOURCE_AUTO: StringName = &"auto"
const SOURCE_ACTION: StringName = &"action"
const SOURCE_EFFECT: StringName = &"effect"

const INITIATION_AUTOMATIC: StringName = &"automatic"
const INITIATION_INVESTIGATOR: StringName = &"investigator"

const PLACEMENT_ENTER_THREAT: StringName = &"enter_threat"
const PLACEMENT_GRANT: StringName = &"grant"


static func resolve(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.enemy == null:
		return {"ok": false}
	var normalized := _normalize_params(params)
	var source: StringName = normalized["source"]
	match source:
		SOURCE_AUTO:
			return _resolve_auto(game_ctx, normalized)
		SOURCE_ACTION, SOURCE_EFFECT:
			return _resolve_explicit(game_ctx, normalized)
		_:
			return {"ok": false, "reason": &"unknown_source"}


static func nest_after_area_change(
	game_ctx: GameContext,
	location_tag: StringName,
	enemy_id: StringName = &"",
	cause: StringName = &"location"
) -> Dictionary:
	if game_ctx == null or location_tag == &"":
		return {"ok": true, "skipped": true}
	var params := {
		"source": SOURCE_AUTO,
		"mode": SOURCE_AUTO,
		"initiation": INITIATION_AUTOMATIC,
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
	## `mode` 为历史字段，与 `source` 同义；二者缺一时互填。
	var source: StringName = out.get("source", out.get("mode", SOURCE_AUTO)) as StringName
	if source == &"":
		source = SOURCE_AUTO
	out["source"] = source
	out["mode"] = source
	if not out.has("initiation") or out.get("initiation", &"") == &"":
		out["initiation"] = (
			INITIATION_AUTOMATIC if source == SOURCE_AUTO else INITIATION_INVESTIGATOR
		)
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
				"source": SOURCE_AUTO,
				"initiation": INITIATION_AUTOMATIC,
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
		"source": SOURCE_AUTO,
		"initiation": INITIATION_AUTOMATIC,
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
	var source: StringName = params.get("source", SOURCE_EFFECT)
	var initiation: StringName = params.get("initiation", INITIATION_INVESTIGATOR)
	var placement: StringName = params.get("placement", PLACEMENT_ENTER_THREAT)
	var require_same: bool = bool(params.get("require_same_location", true))
	## 行动交战：庞大不可被手动交战（魔典）。
	if source == SOURCE_ACTION and enemy.massive:
		return {"ok": false, "reason": &"massive", "error": "massive"}
	if enemy.is_engaged_with(inv_id):
		return {"ok": false, "reason": &"already_engaged", "error": "already_engaged"}
	if require_same and not enemy.is_at_location(inv.location_tag):
		return {"ok": false, "reason": &"wrong_location", "error": "wrong_location"}
	## grant：成对交战状态；enter_threat：进入威胁区（当前 L0 同为 dual-write，语义不同）。
	game_ctx.enemy.apply_engage(enemy_id, inv_id)
	return {
		"ok": true,
		"enemy_id": enemy_id,
		"investigator_id": inv_id,
		"source": source,
		"initiation": initiation,
		"placement": placement,
	}


static func _definition_id(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null:
		return &""
	return card.id.definition_id
