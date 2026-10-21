class_name EnemySystem
extends RefCounted

var _state: GameStateStore
var _log: GameLog
var _game_ctx: GameContext = null


func _init(state: GameStateStore, log: GameLog) -> void:
	_state = state
	_log = log


func bind_context(ctx: GameContext) -> void:
	_game_ctx = ctx


func spawn_from_encounter_draw(
	game_ctx: GameContext,
	card_id: StringName,
	drawer_id: StringName
) -> Dictionary:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return {"ok": false, "error": "unknown_card"}
	var def_id := card.id.definition_id
	var spec := CardRegistry.spawn_spec(def_id)
	var aloof := CardRegistry.is_aloof(def_id)
	if spec.mode == SpawnInstructionSpec.Mode.FRAMEWORK_DEFAULT:
		return spawn_default_from_draw(game_ctx, card_id, drawer_id, aloof, def_id)
	## Spawn – Engaged with Prey：全体调查员中按 Prey 选 WHO，再 spawn_engaged。
	if spec.selector_kind == SpawnInstructionSpec.SelectorKind.ENGAGED_WITH_PREY:
		return _spawn_engaged_with_prey(game_ctx, card_id, drawer_id, def_id)
	var location_tag := SpawnLocationResolver.resolve(spec, drawer_id, game_ctx)
	if location_tag == &"":
		return discard_spawn_failed(game_ctx, card_id)
	var spawn_res := spawn_at_location(game_ctx, card_id, location_tag, def_id)
	if not spawn_res.get("ok", false):
		return spawn_res
	if not aloof:
		if CardRegistry.is_massive(def_id):
			MassiveEngagement.sync_for_enemy(game_ctx, card_id)
		else:
			EngageFlow.nest_after_area_change(game_ctx, location_tag, card_id)
	return {"ok": true, "enemy_id": card_id, "location_tag": location_tag}


func _spawn_engaged_with_prey(
	game_ctx: GameContext,
	card_id: StringName,
	drawer_id: StringName,
	def_id: StringName
) -> Dictionary:
	var candidates: Array[StringName] = []
	for inv_id in _state.registry.all_investigator_ids():
		var inv := _state.registry.get_investigator(inv_id)
		if inv != null and not inv.eliminated:
			candidates.append(inv_id)
	var prey := CardRegistry.prey_spec(def_id)
	## source = 即将进场的实例 id（此时可能尚未 materialize；排除自引用）。
	var target := PreyResolver.best_match(prey, game_ctx, candidates, card_id)
	if target == &"":
		target = drawer_id
	if target == &"":
		target = game_ctx.lead_investigator_id if game_ctx != null else &""
	if target == &"":
		return discard_spawn_failed(game_ctx, card_id)
	return spawn_engaged(game_ctx, card_id, target)


func spawn_default_from_draw(
	game_ctx: GameContext,
	card_id: StringName,
	drawer_id: StringName,
	aloof: bool,
	def_id: StringName = &""
) -> Dictionary:
	if def_id == &"":
		def_id = _definition_id(card_id)
	# Framework 1.4 default draw: non-Aloof enemies atomically enter drawer's threat area.
	if aloof:
		var loc := _drawer_location_tag(drawer_id)
		if loc == &"":
			return discard_spawn_failed(game_ctx, card_id)
		return spawn_at_location(game_ctx, card_id, loc, def_id)
	if CardRegistry.is_massive(def_id):
		var massive_loc := _drawer_location_tag(drawer_id)
		if massive_loc == &"":
			return discard_spawn_failed(game_ctx, card_id)
		var massive_spawn := spawn_at_location(game_ctx, card_id, massive_loc, def_id)
		if not massive_spawn.get("ok", false):
			return massive_spawn
		MassiveEngagement.sync_for_enemy(game_ctx, card_id)
		return {"ok": true, "enemy_id": card_id, "location_tag": massive_loc}
	return spawn_engaged(game_ctx, card_id, drawer_id)


func spawn_engaged(game_ctx: GameContext, card_id: StringName, drawer_id: StringName) -> Dictionary:
	var loc := _drawer_location_tag(drawer_id)
	if loc == &"":
		return discard_spawn_failed(game_ctx, card_id)
	var def_id := _definition_id(card_id)
	var materialize := _materialize_enemy(game_ctx, card_id, def_id, loc)
	if not materialize.get("ok", false):
		return materialize
	var enemy := _state.registry.get_enemy(card_id)
	var inv := _state.registry.get_investigator(drawer_id)
	if enemy == null or inv == null:
		return {"ok": false, "error": "spawn_materialize_failed"}
	## 移入威胁区（区划）+ Register 交战状态 Buff。
	enemy.engaged_with = drawer_id
	if not inv.threat_area.has(card_id):
		inv.threat_area.append(card_id)
	_mark_card_in_play(game_ctx, card_id)
	EngagementStatus.grant(game_ctx, card_id, drawer_id)
	_log.log(
		AhcEnums.LogCategory.SCENARIO,
		"spawn_engaged",
		{"enemy_id": card_id, "drawer_id": drawer_id, "location_tag": loc}
	)
	return {"ok": true, "enemy_id": card_id, "location_tag": loc}


func spawn_at_location(
	game_ctx: GameContext,
	card_id: StringName,
	location_tag: StringName,
	def_id: StringName = &""
) -> Dictionary:
	if def_id == &"":
		def_id = _definition_id(card_id)
	if location_tag == &"" or _state.registry.get_location(location_tag) == null:
		return {"ok": false, "error": "invalid_location"}
	var materialize := _materialize_enemy(game_ctx, card_id, def_id, location_tag)
	if not materialize.get("ok", false):
		return materialize
	_mark_card_in_play(game_ctx, card_id)
	var spawned := _state.registry.get_enemy(card_id)
	if spawned != null and spawned.massive:
		MassiveEngagement.sync_for_enemy(game_ctx, card_id)
	_log.log(
		AhcEnums.LogCategory.SCENARIO,
		"spawn_at_location",
		{"enemy_id": card_id, "location_tag": location_tag}
	)
	return {"ok": true, "enemy_id": card_id, "location_tag": location_tag}


func auto_engage_at_location(
	game_ctx: GameContext,
	enemy_id: StringName,
	location_tag: StringName,
	def_id: StringName = &""
) -> Dictionary:
	var enemy := _state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "error": "unknown_enemy"}
	if enemy.massive:
		MassiveEngagement.sync_for_enemy(game_ctx, enemy_id)
		return {"ok": true, "skipped": true, "massive": true}
	if EngagementStatus.is_engaged(game_ctx, enemy_id):
		return {"ok": true, "skipped": true}
	if enemy.exhausted or enemy.auto_engage_suppressed:
		return {"ok": true, "skipped": true}
	## 限制类 Buff：原流程读取后跳过自动交战（明示交战不受影响）。
	if (
		game_ctx != null
		and game_ctx.registrations != null
		and game_ctx.registrations.read_suppress_auto_engage(enemy_id)
	):
		return {"ok": true, "skipped": true, "restricted_by_suppress_auto_engage": true}
	var candidates := _investigators_at_location(location_tag)
	if candidates.is_empty():
		return {"ok": true, "skipped": true}
	var target := _pick_engage_target(game_ctx, candidates, def_id, enemy_id)
	_apply_engage(game_ctx, enemy_id, target, true)
	return {"ok": true, "enemy_id": enemy_id, "investigator_id": target}


func discard_spawn_failed(game_ctx: GameContext, card_id: StringName) -> Dictionary:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return {"ok": false, "error": "unknown_card"}
	if _state.registry.get_enemy(card_id) != null:
		_state.registry.unregister_enemy(card_id)
	if card.owner_id == &"encounter":
		game_ctx.mutator.move_card(card_id, CardSlot.encounter_discard_top())
	else:
		game_ctx.mutator.move_card(card_id, CardSlot.discard_top(card.owner_id))
	_log.log(AhcEnums.LogCategory.SCENARIO, "spawn_failed_discard", {"card_id": card_id})
	return {"ok": true, "discarded": true, "card_id": card_id}


func enemy_phase_3_2_moves() -> void:
	## Framework 3.2 基础手续：一条 seq.enemy.3_2（含 Hunter + Patrol 关键词 resolve）。
	if _game_ctx != null and _game_ctx.enemy_phase != null:
		_game_ctx.enemy_phase.run_3_2(_game_ctx)
		return
	_log.log(AhcEnums.LogCategory.SCENARIO, "enemy_phase_3_2", {})


func resolve_phase_attacks_for(investigator_id: StringName) -> void:
	## 3.3 基础攻击；Massive 在 phase_attacks 内作效果替换，无独立 massive 遍。
	if _game_ctx != null and _game_ctx.enemy_phase != null:
		_game_ctx.enemy_phase.run_phase_attacks(_game_ctx, investigator_id)
		return
	_log.log(AhcEnums.LogCategory.SCENARIO, "enemy_phase_attacks", {"inv": investigator_id})


func _materialize_enemy(
	game_ctx: GameContext,
	card_id: StringName,
	def_id: StringName,
	location_tag: StringName
) -> Dictionary:
	if _state.registry.get_enemy(card_id) != null:
		return {"ok": true}
	var stats := CardRegistry.enemy_stats(def_id)
	var enemy := EnemyState.new()
	enemy.id = card_id
	enemy.location_tag = location_tag
	enemy.fight = int(stats.get("fight", 2))
	enemy.evade = int(stats.get("evade", 2))
	var base_health := int(stats.get("health", 1))
	if bool(stats.get("health_per_investigator", false)):
		enemy.health = PerInvestigatorScale.scale(_state, base_health)
	else:
		var bonus_per := int(stats.get("health_bonus_per_investigator", 0))
		if bonus_per > 0:
			enemy.health = base_health + bonus_per * PerInvestigatorScale.count(_state)
		else:
			enemy.health = base_health
	enemy.attack_damage = int(stats.get("damage", stats.get("attack_damage", 1)))
	enemy.attack_horror = int(stats.get("horror", stats.get("attack_horror", 0)))
	enemy.aloof = CardRegistry.is_aloof(def_id)
	enemy.massive = CardRegistry.has_keyword(def_id, &"massive") or bool(stats.get("massive", false))
	_state.registry.register_enemy(enemy)
	## 冷漠：Domain 拥有 + FORBID_ATTACK Register（Fight 入口读）。
	if enemy.aloof:
		AloofStatus.ensure_forbid_attack(game_ctx, card_id)
	return {"ok": true}


func _mark_card_in_play(game_ctx: GameContext, card_id: StringName) -> void:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return
	var from_zone := card.zone
	if from_zone == AhcEnums.Zone.PLAY_AREA:
		return
	card.zone = AhcEnums.Zone.PLAY_AREA
	if game_ctx != null:
		ZoneMoveFlow.notify_zone_set(game_ctx, card_id, from_zone, AhcEnums.Zone.PLAY_AREA)


func _drawer_location_tag(drawer_id: StringName) -> StringName:
	var inv := _state.registry.get_investigator(drawer_id)
	if inv == null:
		return &""
	return inv.location_tag


func _definition_id(card_id: StringName) -> StringName:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return &""
	return card.id.definition_id


func _investigators_at_location(location_tag: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for inv_id in _state.registry.all_investigator_ids():
		var inv := _state.registry.get_investigator(inv_id)
		if inv != null and inv.location_tag == location_tag:
			out.append(inv.id)
	return out


func _pick_engage_target(
	game_ctx: GameContext,
	candidates: Array[StringName],
	def_id: StringName,
	source_enemy_id: StringName = &""
) -> StringName:
	if candidates.size() == 1:
		return candidates[0]
	var prey := CardRegistry.prey_spec(def_id)
	var pick := PreyResolver.best_match(prey, game_ctx, candidates, source_enemy_id)
	if pick != &"":
		return pick
	## 无 Prey / 过滤空集：并列仍开 Lead 选择窗（不静默把 Lead 当目标）。
	return PreyResolver.lead_pick(game_ctx, candidates, &"pick:engage_tie")


func apply_engage(
	enemy_id: StringName,
	inv_id: StringName,
	enter_threat: bool = true,
	game_ctx: GameContext = null
) -> void:
	var ctx := game_ctx if game_ctx != null else _game_ctx
	_apply_engage(ctx, enemy_id, inv_id, enter_threat)


func disengage(
	game_ctx: GameContext,
	enemy_id: StringName,
	exhaust: bool = false,
	trigger_area_change: bool = true
) -> Dictionary:
	var enemy := _state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "error": "unknown_enemy"}
	var location_tag := enemy.location_tag
	## 注销交战状态 Buff；若卡在威胁区则移出（区划变化，不是「卸第二套状态」）。
	EngagementStatus.clear(game_ctx, enemy_id)
	if enemy.engaged_with != &"":
		var prev := _state.registry.get_investigator(enemy.engaged_with)
		if prev:
			prev.threat_area.erase(enemy_id)
	enemy.engaged_with = &""
	if exhaust:
		set_enemy_exhausted(game_ctx, enemy_id, true, false)
	_log.log(
		AhcEnums.LogCategory.SCENARIO,
		"enemy:disengage",
		{"enemy_id": enemy_id, "location_tag": location_tag, "exhausted": enemy.exhausted}
	)
	if trigger_area_change and game_ctx != null and location_tag != &"":
		return EngageFlow.nest_after_area_change(
			game_ctx, location_tag, enemy_id, &"engagement"
		)
	return {"ok": true, "enemy_id": enemy_id, "location_tag": location_tag}


func set_enemy_exhausted(
	game_ctx: GameContext,
	enemy_id: StringName,
	exhausted: bool,
	trigger_area_change: bool = true
) -> Dictionary:
	## 接线 → 统一横置/重整核（可被 after_exhaust / after_ready 听到）。
	var params := {
		"target_kind": ExhaustReadyFlow.TARGET_ENEMY,
		"enemy_id": enemy_id,
		"trigger_area_change": trigger_area_change,
	}
	if exhausted:
		return ExhaustReadyFlow.nest_or_run_exhaust(game_ctx, params)
	return ExhaustReadyFlow.nest_or_run_ready(game_ctx, params)


func ready_all_exhausted_enemies(game_ctx: GameContext) -> Dictionary:
	## 保养 4.3：敌人 + 平放区卡牌一并重整。
	return ExhaustReadyFlow.ready_all_in_play(game_ctx)


func deal_damage(game_ctx: GameContext, enemy_id: StringName, amount: int) -> Dictionary:
	return EnemyDefeatResolver.deal_damage(game_ctx, enemy_id, amount)


func defeat_enemy(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	return EnemyDefeatResolver.defeat(game_ctx, enemy_id)


func discard_enemy_from_play(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	return EnemyDefeatResolver.discard_from_play(game_ctx, enemy_id)


func _apply_engage(
	game_ctx: GameContext,
	enemy_id: StringName,
	inv_id: StringName,
	enter_threat: bool = true
) -> void:
	var enemy := _state.registry.get_enemy(enemy_id)
	var inv := _state.registry.get_investigator(inv_id)
	if enemy == null or inv == null:
		return
	## 一律 Register 交战状态 Buff；enter_threat 时再移入威胁区（区划）。
	EngagementStatus.grant(game_ctx, enemy_id, inv_id)
	if not enter_threat:
		return
	if enemy.engaged_with != &"" and enemy.engaged_with != inv_id:
		var prev := _state.registry.get_investigator(enemy.engaged_with)
		if prev:
			prev.threat_area.erase(enemy_id)
	enemy.engaged_with = inv_id
	if not inv.threat_area.has(enemy_id):
		inv.threat_area.append(enemy_id)
