class_name SwarmingKeywordFlow
extends RefCounted

## 蜂拥（Swarming X）延时开火：进场结算之后垫 X 张集群卡牌（代理+投影）。
## 集群卡牌不结算 Swarming；独特主体跳过垫牌；库不足则尽其所能。


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	return fire_pad(game_ctx, params.get("card_id", params.get("enemy_id", &"")) as StringName)


static func try_fire_after_enter_play(game_ctx: GameContext, card_id: StringName) -> Dictionary:
	if game_ctx == null or card_id == &"":
		return {"ok": true, "padded": 0, "skipped": true}
	if not KeywordMount.is_keyword_armed(game_ctx, card_id, &"swarming"):
		return {"ok": true, "padded": 0, "skipped": true}
	if VirtualCard.is_swarm_card_id(game_ctx, card_id):
		return {"ok": true, "padded": 0, "skipped": true, "reason": &"swarm_card"}
	## 独特 + 蜂拥 → 不垫牌。
	if CharacteristicMount.has_effective_unique(game_ctx, card_id) or UniqueTitle.is_unique(
		_definition_id(game_ctx, card_id)
	):
		_disarm(game_ctx, card_id)
		return {"ok": true, "padded": 0, "skipped": true, "reason": &"unique"}
	if (
		game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(KeywordProfileTable.FLOW_KEYWORD_SWARMING)
	):
		return game_ctx.sequence_catalog.nest(
			game_ctx,
			KeywordProfileTable.FLOW_KEYWORD_SWARMING,
			{"card_id": card_id, "enemy_id": card_id}
		)
	return fire_pad(game_ctx, card_id)


static func fire_pad(game_ctx: GameContext, host_id: StringName) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or host_id == &"":
		return {"ok": false, "padded": 0}
	if VirtualCard.is_swarm_card_id(game_ctx, host_id):
		_disarm(game_ctx, host_id)
		return {"ok": true, "padded": 0, "skipped": true, "reason": &"swarm_card"}
	if CharacteristicMount.has_effective_unique(game_ctx, host_id) or UniqueTitle.is_unique(
		_definition_id(game_ctx, host_id)
	):
		_disarm(game_ctx, host_id)
		return {"ok": true, "padded": 0, "skipped": true, "reason": &"unique"}
	var host := game_ctx.state.registry.get_enemy(host_id)
	if host == null:
		_disarm(game_ctx, host_id)
		return {"ok": false, "padded": 0, "error": "host_not_enemy"}
	var amount := CardRegistry.swarming_count(_definition_id(game_ctx, host_id))
	if amount <= 0:
		_disarm(game_ctx, host_id)
		return {"ok": true, "padded": 0, "skipped": true, "reason": &"no_x"}
	var donor := _donor_investigator(game_ctx, host_id)
	if donor == &"":
		_disarm(game_ctx, host_id)
		return {"ok": false, "padded": 0, "error": "no_donor"}
	var created: Array[StringName] = []
	for _i in range(amount):
		var sid := _pad_one(game_ctx, host_id, host, donor)
		if sid == &"":
			break
		created.append(sid)
	_disarm(game_ctx, host_id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"keyword:swarming",
			{
				"host_id": host_id,
				"padded": created.size(),
				"requested": amount,
				"donor": donor,
				"swarm_ids": created,
			}
		)
	return {
		"ok": true,
		"padded": created.size(),
		"requested": amount,
		"host_id": host_id,
		"swarm_ids": created,
		"donor": donor,
	}


static func _pad_one(
	game_ctx: GameContext,
	host_id: StringName,
	host: EnemyState,
	donor_id: StringName
) -> StringName:
	var inv := game_ctx.state.registry.get_investigator(donor_id)
	if inv == null or inv.deck.is_empty():
		return &""
	var proxy_id: StringName = inv.deck[0]
	## 离库但不入手：直接从牌库抽出为集群代理。
	inv.deck.erase(proxy_id)
	var card := game_ctx.state.registry.get_card(proxy_id)
	if card == null:
		return &""
	card.owner_id = donor_id
	card.controller_id = donor_id
	card.zone = AhcEnums.Zone.PLAY_AREA
	card.face_visibility.audience = AhcEnums.FaceAudience.HIDDEN_ALL
	## 投影主体对战面 → 独立 EnemyState。
	var enemy := EnemyState.new()
	enemy.id = proxy_id
	enemy.location_tag = host.location_tag
	enemy.fight = host.fight
	enemy.evade = host.evade
	enemy.health = host.health
	enemy.attack_damage = host.attack_damage
	enemy.attack_horror = host.attack_horror
	enemy.exhausted = host.exhausted
	enemy.aloof = host.aloof
	enemy.massive = host.massive
	enemy.engaged_with = host.engaged_with
	enemy.auto_engage_suppressed = host.auto_engage_suppressed
	game_ctx.state.registry.register_enemy(enemy)
	SwarmPack.bind_swarm(game_ctx, host_id, proxy_id)
	if host.engaged_with != &"":
		var eng := game_ctx.state.registry.get_investigator(host.engaged_with)
		if eng != null and not eng.threat_area.has(proxy_id):
			eng.threat_area.append(proxy_id)
		EngagementStatus.grant(game_ctx, proxy_id, host.engaged_with)
	## 个体轴关键词可共享挂载；同步轴关键词也共享，结算时合并。
	_mount_shared_keywords(game_ctx, host_id, proxy_id)
	return proxy_id


static func _mount_shared_keywords(
	game_ctx: GameContext,
	host_id: StringName,
	swarm_id: StringName
) -> void:
	## 共享文本侧关键词；Swarming 永不挂到集群卡牌。
	for kw in [&"hunter", &"patrol", &"retaliate", &"alert", &"elusive", &"doomed", &"massive", &"aloof"]:
		if KeywordMount.is_keyword_armed(game_ctx, host_id, kw):
			KeywordMount.mount_gained(game_ctx, swarm_id, kw)


static func _donor_investigator(game_ctx: GameContext, host_id: StringName) -> StringName:
	var host := game_ctx.state.registry.get_enemy(host_id)
	if host != null and host.engaged_with != &"":
		var eng := game_ctx.state.registry.get_investigator(host.engaged_with)
		if eng != null and not eng.eliminated:
			return host.engaged_with
	if game_ctx.lead_investigator_id != &"":
		return game_ctx.lead_investigator_id
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv != null and not inv.eliminated:
			return inv_id
	return &""


static func _disarm(game_ctx: GameContext, card_id: StringName) -> void:
	if game_ctx == null or game_ctx.registrations == null or card_id == &"":
		return
	game_ctx.registrations.unregister_keyword_buffs(card_id, &"swarming")


static func _definition_id(game_ctx: GameContext, card_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return &""
	return card.id.definition_id
