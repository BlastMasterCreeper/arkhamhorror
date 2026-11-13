class_name EngageFlow
extends RefCounted

## 通用交战命名流程 `seq.engage`。
##
## 只有两条路径（`mode`）：
## - **auto**：框架区域变更后的自动交战（Prey/Lead；冷漠/横置跳过）
## - **effect**：效果交战（卡面 nest、以及基础 Engage 行动外壳 nest）
##
## 交战状态 = RestrictionKind.ENGAGEMENT Buff（赋予/注销）。
## 交战 ≠ 进入威胁区：本手续在 `placement=enter_threat` 时 **包装** nest
## `seq.effect.enter_threat_area`（`from=in_play` = 场上→威胁区）。`grant` 只 Buff。
## 生成 engaged（场外→威胁区）走 `SpawnFlow.engaged`，不压本条。
## 纸面「交战后」订进入威胁区 AFTER，不订本手续完成。
## 禁止另铸 `seq.enemy.auto_engage`；禁止再挂平行交战门面。


const MODE_AUTO: StringName = &"auto"
const MODE_EFFECT: StringName = &"effect"

const PLACEMENT_ENTER_THREAT: StringName = &"enter_threat"
const PLACEMENT_GRANT: StringName = &"grant"


static func resolve(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
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


## Register Buff；`write_engaged_with` 时写 Domain engaged_with（威胁区另走 EnterThreatAreaFlow）。
static func apply_status(
	game_ctx: GameContext,
	enemy_id: StringName,
	inv_id: StringName,
	write_engaged_with: bool = true
) -> void:
	if game_ctx == null or game_ctx.state == null:
		return
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if enemy == null or inv == null:
		return
	EngagementStatus.grant(game_ctx, enemy_id, inv_id)
	if not write_engaged_with:
		return
	if enemy.engaged_with != &"" and enemy.engaged_with != inv_id:
		var prev := game_ctx.state.registry.get_investigator(enemy.engaged_with)
		if prev:
			prev.threat_area.erase(enemy_id)
	enemy.engaged_with = inv_id


static func auto_at_location(
	game_ctx: GameContext,
	enemy_id: StringName,
	location_tag: StringName,
	def_id: StringName = &"",
	write_engaged_with: bool = true
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "error": "unknown_enemy"}
	if enemy.massive:
		return {"ok": true, "skipped": true, "massive": true}
	if EngagementStatus.is_engaged(game_ctx, enemy_id):
		return {"ok": true, "skipped": true}
	if enemy.exhausted or enemy.auto_engage_suppressed:
		return {"ok": true, "skipped": true}
	if (
		game_ctx.registrations != null
		and game_ctx.registrations.read_suppress_auto_engage(enemy_id)
	):
		return {"ok": true, "skipped": true, "restricted_by_suppress_auto_engage": true}
	var candidates := _investigators_at_location(game_ctx, location_tag)
	if candidates.is_empty():
		return {"ok": true, "skipped": true}
	if def_id == &"":
		def_id = _definition_id(game_ctx, enemy_id)
	var target := _pick_engage_target(game_ctx, candidates, def_id, enemy_id)
	apply_status(game_ctx, enemy_id, target, write_engaged_with)
	return {"ok": true, "enemy_id": enemy_id, "investigator_id": target}


static func disengage(
	game_ctx: GameContext,
	enemy_id: StringName,
	exhaust: bool = false,
	trigger_area_change: bool = true
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "error": "unknown_enemy"}
	var location_tag := enemy.location_tag
	EngagementStatus.clear(game_ctx, enemy_id)
	if enemy.engaged_with != &"":
		var prev := game_ctx.state.registry.get_investigator(enemy.engaged_with)
		if prev:
			prev.threat_area.erase(enemy_id)
	enemy.engaged_with = &""
	if exhaust:
		ExhaustReadyFlow.nest_or_run_exhaust(
			game_ctx,
			{
				"target_kind": ExhaustReadyFlow.TARGET_ENEMY,
				"enemy_id": enemy_id,
				"trigger_area_change": false,
			}
		)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:disengage",
			{"enemy_id": enemy_id, "location_tag": location_tag, "exhausted": enemy.exhausted}
		)
	if trigger_area_change and location_tag != &"":
		return nest_after_area_change(game_ctx, location_tag, enemy_id, &"engagement")
	return {"ok": true, "enemy_id": enemy_id, "location_tag": location_tag}


## 整包解除交战，不触发区域变更自动交战。逃逸规格 nest 本手续。
static func disengage_pack(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	var enemy_id: StringName = params.get("enemy_id", params.get("card_id", &""))
	if enemy_id == &"":
		return {"ok": true, "skipped": true}
	for mid in SwarmPack.pack_ids(game_ctx, enemy_id):
		_disengage_member(game_ctx, mid)
	SwarmPack.sync_engagement(game_ctx, enemy_id)
	return {"ok": true, "enemy_id": enemy_id}


static func _disengage_member(game_ctx: GameContext, enemy_id: StringName) -> void:
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv != null:
			inv.threat_area.erase(enemy_id)
	enemy.engaged_with = &""


static func _normalize_params(params: Dictionary) -> Dictionary:
	var out := params.duplicate()
	var raw: StringName = out.get("mode", out.get("source", MODE_AUTO)) as StringName
	var mode := MODE_AUTO
	if raw == MODE_AUTO or raw == &"":
		mode = MODE_AUTO
	else:
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
			_sync_and_enter_threat(game_ctx, focus_enemy, last_inv)
	else:
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
				_sync_and_enter_threat(game_ctx, enemy_id, last_inv)
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
	var result := auto_at_location(game_ctx, enemy_id, location_tag, def_id, true)
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
	var move_into_threat := placement != PLACEMENT_GRANT
	apply_status(game_ctx, enemy_id, inv_id, move_into_threat)
	SwarmPack.sync_engagement(game_ctx, enemy_id)
	if move_into_threat:
		EnterThreatAreaFlow.enter_pack_if_needed(
			game_ctx, enemy_id, inv_id, EnterThreatAreaFlow.FROM_IN_PLAY
		)
	return {
		"ok": true,
		"enemy_id": enemy_id,
		"investigator_id": inv_id,
		"mode": MODE_EFFECT,
		"placement": placement,
		"engagement_buff": true,
		"moved_into_threat_area": move_into_threat,
	}


static func _sync_and_enter_threat(
	game_ctx: GameContext,
	enemy_id: StringName,
	investigator_id: StringName
) -> void:
	SwarmPack.sync_engagement(game_ctx, enemy_id)
	EnterThreatAreaFlow.enter_pack_if_needed(
		game_ctx, enemy_id, investigator_id, EnterThreatAreaFlow.FROM_IN_PLAY
	)


static func _investigators_at_location(
	game_ctx: GameContext,
	location_tag: StringName
) -> Array[StringName]:
	var out: Array[StringName] = []
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv != null and inv.location_tag == location_tag:
			out.append(inv.id)
	return out


static func _pick_engage_target(
	game_ctx: GameContext,
	candidates: Array[StringName],
	def_id: StringName,
	source_enemy_id: StringName = &""
) -> StringName:
	if candidates.size() == 1:
		return candidates[0]
	var prey := CardRegistry.prey_spec(def_id)
	var pick := PreyQuery.best_match(prey, game_ctx, candidates, source_enemy_id)
	if pick != &"":
		return pick
	return PreyQuery.lead_pick(game_ctx, candidates, &"pick:engage_tie")


static func _definition_id(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null:
		return &""
	return card.id.definition_id
