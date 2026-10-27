class_name ExhaustReadyFlow
extends RefCounted

## 横置 / 重整内核 · `seq.effect.exhaust` / `seq.effect.ready`。
## 修改平放区域卡牌（及在场敌人）的 `exhausted` 状态。
## 不含：费用中的 exhaust（CostPipeline）；非平放区划上的卡。

const TARGET_CARD := &"card"
const TARGET_ENEMY := &"enemy"

## 可横置/重整的平放区划（在场为主）。
const FLAT_ZONES: Array[int] = [
	AhcEnums.Zone.PLAY_AREA,
	AhcEnums.Zone.THREAT_AREA,
	AhcEnums.Zone.ATTACHED,
]


static func nest_or_run_exhaust(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	return _nest_or_run(game_ctx, &"seq.effect.exhaust", params)


static func nest_or_run_ready(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	return _nest_or_run(game_ctx, &"seq.effect.ready", params)


static func _nest_or_run(
	game_ctx: GameContext,
	flow_id: StringName,
	params: Dictionary
) -> Dictionary:
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(flow_id)
	):
		return game_ctx.sequence_catalog.nest(game_ctx, flow_id, params)
	if flow_id == &"seq.effect.exhaust":
		return exhaust(game_ctx, params)
	return ready(game_ctx, params)


static func exhaust(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	return _set_exhausted(game_ctx, params, true)


static func ready(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	return _set_exhausted(game_ctx, params, false)


## 保养 4.3：重整所有在场已横置敌人与平放区卡牌。
static func ready_all_in_play(game_ctx: GameContext) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	var readied: Array[StringName] = []
	for enemy_id in game_ctx.state.registry.all_enemy_ids():
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy == null or not enemy.exhausted:
			continue
		var res := nest_or_run_ready(
			game_ctx,
			{
				"target_kind": TARGET_ENEMY,
				"enemy_id": enemy_id,
				"trigger_area_change": true,
			}
		)
		if bool(res.get("ok", false)) and bool(res.get("changed", false)):
			readied.append(enemy_id)
	for card_id in game_ctx.state.registry.all_card_ids():
		var card := game_ctx.state.registry.get_card(card_id)
		if card == null or not card.exhausted:
			continue
		if not _is_flat_zone(card.zone):
			continue
		## 敌人横置以 EnemyState 为准；有敌状态的实例跳过卡面重复重整。
		if game_ctx.state.registry.get_enemy(card_id) != null:
			continue
		var card_res := nest_or_run_ready(
			game_ctx,
			{
				"target_kind": TARGET_CARD,
				"card_id": card_id,
			}
		)
		if bool(card_res.get("ok", false)) and bool(card_res.get("changed", false)):
			readied.append(card_id)
	return {"ok": true, "readied": readied}


static func resolve_target_kind(params: Dictionary) -> StringName:
	var explicit: StringName = params.get("target_kind", &"") as StringName
	if explicit == TARGET_CARD or explicit == TARGET_ENEMY:
		return explicit
	if params.get("enemy_id", &"") != &"":
		return TARGET_ENEMY
	if params.get("card_id", &"") != &"":
		return TARGET_CARD
	return &""


static func _set_exhausted(
	game_ctx: GameContext,
	params: Dictionary,
	to_exhausted: bool
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	var kind := resolve_target_kind(params)
	match kind:
		TARGET_ENEMY:
			return _set_enemy(game_ctx, params, to_exhausted)
		TARGET_CARD:
			return _set_card(game_ctx, params, to_exhausted)
	return {"ok": false, "error": "missing_target"}


static func _set_enemy(
	game_ctx: GameContext,
	params: Dictionary,
	to_exhausted: bool
) -> Dictionary:
	var enemy_id: StringName = params.get("enemy_id", &"")
	if enemy_id == &"":
		return {"ok": false, "error": "missing_enemy"}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "error": "unknown_enemy"}
	## 在场：有地点（威胁区/地点场面）；无地点则不可横置/重整。
	if enemy.location_tag == &"":
		return {"ok": false, "error": "not_in_play"}
	var was := enemy.exhausted
	if was == to_exhausted:
		return {
			"ok": true,
			"skipped": true,
			"changed": false,
			"enemy_id": enemy_id,
			"exhausted": to_exhausted,
			"target_kind": TARGET_ENEMY,
		}
	enemy.exhausted = to_exhausted
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card != null and _is_flat_zone(card.zone):
		card.exhausted = to_exhausted
		_mirror_exhausted(game_ctx, card, to_exhausted)
	var out := {
		"ok": true,
		"changed": true,
		"enemy_id": enemy_id,
		"exhausted": to_exhausted,
		"target_kind": TARGET_ENEMY,
		"from_exhausted": was,
		"to_exhausted": to_exhausted,
	}
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"effect:ready" if not to_exhausted else "effect:exhaust",
			{"enemy_id": enemy_id, "exhausted": to_exhausted}
		)
	## 重整后区域变更 → 自动交战（与旧 set_enemy_exhausted 对称）。
	if (
		not to_exhausted
		and was
		and bool(params.get("trigger_area_change", true))
		and enemy.location_tag != &""
	):
		enemy.auto_engage_suppressed = false
		var engage := EngageFlow.nest_after_area_change(
			game_ctx, enemy.location_tag, enemy_id, &"ready"
		)
		out["engaged_investigator"] = engage.get("investigator_id", &"")
	return out


static func _set_card(
	game_ctx: GameContext,
	params: Dictionary,
	to_exhausted: bool
) -> Dictionary:
	var card_id: StringName = params.get("card_id", &"")
	if card_id == &"":
		return {"ok": false, "error": "missing_card"}
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return {"ok": false, "error": "unknown_card"}
	if not _is_flat_zone(card.zone):
		return {"ok": false, "error": "not_flat_zone", "zone": card.zone}
	var was := card.exhausted
	if was == to_exhausted:
		return {
			"ok": true,
			"skipped": true,
			"changed": false,
			"card_id": card_id,
			"exhausted": to_exhausted,
			"target_kind": TARGET_CARD,
		}
	## 物理状态原语 ③：经 StateMutator.set_exhausted（Domain + 物理 orientation）。
	if game_ctx.mutator != null:
		if not game_ctx.mutator.set_exhausted(card_id, to_exhausted):
			return {"ok": false, "error": "set_exhausted_failed", "card_id": card_id}
	else:
		card.exhausted = to_exhausted
		_mirror_exhausted(game_ctx, card, to_exhausted)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.CARD,
			"effect:ready" if not to_exhausted else "effect:exhaust",
			{"card_id": card_id, "exhausted": to_exhausted}
		)
	return {
		"ok": true,
		"changed": true,
		"card_id": card_id,
		"exhausted": to_exhausted,
		"target_kind": TARGET_CARD,
		"from_exhausted": was,
		"to_exhausted": to_exhausted,
	}


static func _mirror_exhausted(
	game_ctx: GameContext,
	card: CardInstance,
	to_exhausted: bool
) -> void:
	if game_ctx.state == null or game_ctx.state.physical_binding == null:
		return
	var binding: PhysicalBinding = game_ctx.state.physical_binding
	binding.ensure_physical_card(card)
	binding.mirror_exhausted(card.id.instance_id, to_exhausted)


static func _is_flat_zone(zone: AhcEnums.Zone) -> bool:
	return FLAT_ZONES.has(zone)
