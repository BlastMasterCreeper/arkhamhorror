class_name SpawnFlow
extends RefCounted

## 敌人生成拼装（`seq.encounter.spawn` RESOLVE 用）。
## **不是**命名流程 id、也不是交战手续：场外进场 / 进威胁区由本类 + EnterThreatAreaFlow 完成。
## 禁止对外再挂平行 spawn_* 语义 API。


static func from_encounter_draw(
	game_ctx: GameContext,
	card_id: StringName,
	drawer_id: StringName
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return {"ok": false, "error": "unknown_card"}
	var def_id := card.id.definition_id
	var spec := CardRegistry.spawn_spec(def_id)
	var aloof := CardRegistry.is_aloof(def_id)
	if spec.mode == SpawnInstructionSpec.Mode.FRAMEWORK_DEFAULT:
		return default_from_draw(game_ctx, card_id, drawer_id, aloof, def_id)
	## Spawn – Engaged with Prey：全体调查员中按 Prey 选 WHO，再 engaged。
	if spec.selector_kind == SpawnInstructionSpec.SelectorKind.ENGAGED_WITH_PREY:
		return _engaged_with_prey(game_ctx, card_id, drawer_id, def_id)
	var location_tag := SpawnLocationQuery.resolve(spec, drawer_id, game_ctx)
	if location_tag == &"":
		return discard_failed(game_ctx, card_id)
	var spawn_res := at_location(game_ctx, card_id, location_tag, def_id)
	if not spawn_res.get("ok", false):
		return spawn_res
	if not aloof:
		if CardRegistry.is_massive(def_id):
			MassiveEngagement.sync_for_enemy(game_ctx, card_id)
		else:
			EngageFlow.nest_after_area_change(game_ctx, location_tag, card_id)
	return {"ok": true, "enemy_id": card_id, "location_tag": location_tag}


static func default_from_draw(
	game_ctx: GameContext,
	card_id: StringName,
	drawer_id: StringName,
	aloof: bool,
	def_id: StringName = &""
) -> Dictionary:
	if def_id == &"":
		def_id = _definition_id(game_ctx, card_id)
	## Framework 1.4 default：非 Aloof 原子进抽者威胁区。
	if aloof:
		var loc := _drawer_location_tag(game_ctx, drawer_id)
		if loc == &"":
			return discard_failed(game_ctx, card_id)
		return at_location(game_ctx, card_id, loc, def_id)
	if CardRegistry.is_massive(def_id):
		var massive_loc := _drawer_location_tag(game_ctx, drawer_id)
		if massive_loc == &"":
			return discard_failed(game_ctx, card_id)
		var massive_spawn := at_location(game_ctx, card_id, massive_loc, def_id)
		if not massive_spawn.get("ok", false):
			return massive_spawn
		MassiveEngagement.sync_for_enemy(game_ctx, card_id)
		return {"ok": true, "enemy_id": card_id, "location_tag": massive_loc}
	return engaged(game_ctx, card_id, drawer_id)


## 场外 → 威胁区 + Buff（不压 seq.engage）。
static func engaged(
	game_ctx: GameContext,
	card_id: StringName,
	drawer_id: StringName
) -> Dictionary:
	var loc := _drawer_location_tag(game_ctx, drawer_id)
	if loc == &"":
		return discard_failed(game_ctx, card_id)
	var def_id := _definition_id(game_ctx, card_id)
	var materialize := materialize_enemy(game_ctx, card_id, def_id, loc)
	if not materialize.get("ok", false):
		return materialize
	var enemy := game_ctx.state.registry.get_enemy(card_id)
	var inv := game_ctx.state.registry.get_investigator(drawer_id)
	if enemy == null or inv == null:
		return {"ok": false, "error": "spawn_materialize_failed"}
	EngagementStatus.grant(game_ctx, card_id, drawer_id)
	enemy.engaged_with = drawer_id
	mark_card_in_play(game_ctx, card_id)
	EnterThreatAreaFlow.enter_pack_if_needed(
		game_ctx, card_id, drawer_id, EnterThreatAreaFlow.FROM_OUT_OF_PLAY
	)
	_log(
		game_ctx,
		"spawn_engaged",
		{"enemy_id": card_id, "drawer_id": drawer_id, "location_tag": loc}
	)
	return {"ok": true, "enemy_id": card_id, "location_tag": loc}


static func at_location(
	game_ctx: GameContext,
	card_id: StringName,
	location_tag: StringName,
	def_id: StringName = &""
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	if def_id == &"":
		def_id = _definition_id(game_ctx, card_id)
	if location_tag == &"" or game_ctx.state.registry.get_location(location_tag) == null:
		return {"ok": false, "error": "invalid_location"}
	var materialize := materialize_enemy(game_ctx, card_id, def_id, location_tag)
	if not materialize.get("ok", false):
		return materialize
	mark_card_in_play(game_ctx, card_id)
	var spawned := game_ctx.state.registry.get_enemy(card_id)
	if spawned != null and spawned.massive:
		MassiveEngagement.sync_for_enemy(game_ctx, card_id)
	_log(
		game_ctx,
		"spawn_at_location",
		{"enemy_id": card_id, "location_tag": location_tag}
	)
	return {"ok": true, "enemy_id": card_id, "location_tag": location_tag}


static func discard_failed(game_ctx: GameContext, card_id: StringName) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return {"ok": false, "error": "unknown_card"}
	if game_ctx.state.registry.get_enemy(card_id) != null:
		game_ctx.state.registry.unregister_enemy(card_id)
	if game_ctx.mutator == null:
		return {"ok": false, "error": "no_mutator"}
	if card.owner_id == &"encounter":
		game_ctx.mutator.move_card(card_id, CardSlot.encounter_discard_top())
	else:
		game_ctx.mutator.move_card(card_id, CardSlot.discard_top(card.owner_id))
	_log(game_ctx, "spawn_failed_discard", {"card_id": card_id})
	return {"ok": true, "discarded": true, "card_id": card_id}


## L0：注册 EnemyState（进场区划另走 mark_card_in_play）。
static func materialize_enemy(
	game_ctx: GameContext,
	card_id: StringName,
	def_id: StringName,
	location_tag: StringName
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	if game_ctx.state.registry.get_enemy(card_id) != null:
		return {"ok": true}
	var stats := CardRegistry.enemy_stats(def_id)
	var enemy := EnemyState.new()
	enemy.id = card_id
	enemy.location_tag = location_tag
	enemy.fight = int(stats.get("fight", 2))
	enemy.evade = int(stats.get("evade", 2))
	var base_health := int(stats.get("health", 1))
	if bool(stats.get("health_per_investigator", false)):
		enemy.health = PerInvestigatorScale.scale(game_ctx.state, base_health)
	else:
		var bonus_per := int(stats.get("health_bonus_per_investigator", 0))
		if bonus_per > 0:
			enemy.health = base_health + bonus_per * PerInvestigatorScale.count(game_ctx.state)
		else:
			enemy.health = base_health
	enemy.attack_damage = int(stats.get("damage", stats.get("attack_damage", 1)))
	enemy.attack_horror = int(stats.get("horror", stats.get("attack_horror", 0)))
	enemy.aloof = CardRegistry.is_aloof(def_id)
	enemy.massive = CardRegistry.has_keyword(def_id, &"massive") or bool(stats.get("massive", false))
	game_ctx.state.registry.register_enemy(enemy)
	return {"ok": true}


static func mark_card_in_play(game_ctx: GameContext, card_id: StringName) -> void:
	if game_ctx == null or game_ctx.state == null:
		return
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return
	var from_zone := card.zone
	if from_zone == AhcEnums.Zone.PLAY_AREA:
		return
	card.zone = AhcEnums.Zone.PLAY_AREA
	ZoneMoveFlow.notify_zone_set(game_ctx, card_id, from_zone, AhcEnums.Zone.PLAY_AREA)


static func _engaged_with_prey(
	game_ctx: GameContext,
	card_id: StringName,
	drawer_id: StringName,
	def_id: StringName
) -> Dictionary:
	var candidates: Array[StringName] = []
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv != null and not inv.eliminated:
			candidates.append(inv_id)
	var prey := CardRegistry.prey_spec(def_id)
	var target := PreyQuery.best_match(prey, game_ctx, candidates, card_id)
	if target == &"":
		target = drawer_id
	if target == &"":
		target = game_ctx.lead_investigator_id if game_ctx != null else &""
	if target == &"":
		return discard_failed(game_ctx, card_id)
	return engaged(game_ctx, card_id, target)


static func _drawer_location_tag(game_ctx: GameContext, drawer_id: StringName) -> StringName:
	var inv := game_ctx.state.registry.get_investigator(drawer_id)
	if inv == null:
		return &""
	return inv.location_tag


static func _definition_id(game_ctx: GameContext, card_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return &""
	return card.id.definition_id


static func _log(game_ctx: GameContext, event: String, payload: Dictionary) -> void:
	if game_ctx != null and game_ctx.log != null:
		game_ctx.log.log(AhcEnums.LogCategory.SCENARIO, event, payload)
