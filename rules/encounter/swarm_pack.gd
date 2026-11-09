class_name SwarmPack
extends RefCounted

## 蜂拥包绑定：主体敌人 ↔ 集群卡牌。框架只有绑定；UI 可另做展示区。
## 同步轴：移动 / 接战 / 横置·重整 — 整包同时结算一次（防重入）。

const META_HOST: StringName = &"swarm_host_id"
const META_MEMBERS: StringName = &"swarm_member_ids"

static var _sync_depth: int = 0


static func is_swarm_card(game_ctx: GameContext, card_id: StringName) -> bool:
	return VirtualCard.is_swarm_card_id(game_ctx, card_id)


static func host_of(game_ctx: GameContext, member_id: StringName) -> StringName:
	if game_ctx == null or game_ctx.state == null or member_id == &"":
		return &""
	if not is_swarm_card(game_ctx, member_id):
		## 主体：若挂有成员列表则自身即 host。
		if _member_list(game_ctx, member_id).size() > 0:
			return member_id
		return &""
	var card := game_ctx.state.registry.get_card(member_id)
	var host := VirtualCard.projection_of(card)
	if host != &"":
		return host
	if card != null and card.has_meta(META_HOST):
		return card.get_meta(META_HOST) as StringName
	return &""


static func swarm_ids(game_ctx: GameContext, host_id: StringName) -> Array[StringName]:
	return _member_list(game_ctx, host_id)


static func has_swarm_cards(game_ctx: GameContext, host_id: StringName) -> bool:
	return not swarm_ids(game_ctx, host_id).is_empty()


static func pack_ids(game_ctx: GameContext, any_id: StringName) -> Array[StringName]:
	var host := host_of(game_ctx, any_id)
	if host == &"":
		## 无包：单独个体。
		if game_ctx != null and game_ctx.state != null and game_ctx.state.registry.get_enemy(any_id) != null:
			return [any_id] as Array[StringName]
		return [] as Array[StringName]
	var out: Array[StringName] = [host]
	for sid in swarm_ids(game_ctx, host):
		if sid != host and not out.has(sid):
			out.append(sid)
	return out


static func bind_swarm(game_ctx: GameContext, host_id: StringName, swarm_id: StringName) -> void:
	if game_ctx == null or game_ctx.state == null or host_id == &"" or swarm_id == &"":
		return
	var host_card := game_ctx.state.registry.get_card(host_id)
	var swarm_card := game_ctx.state.registry.get_card(swarm_id)
	if host_card == null or swarm_card == null:
		return
	VirtualCard.bind(swarm_card, VirtualCard.ROLE_SWARM_CARD, host_id)
	swarm_card.set_meta(META_HOST, host_id)
	var members := _member_list(game_ctx, host_id)
	if not members.has(swarm_id):
		members.append(swarm_id)
	host_card.set_meta(META_MEMBERS, members)


static func unbind_swarm(game_ctx: GameContext, swarm_id: StringName) -> void:
	if game_ctx == null or game_ctx.state == null or swarm_id == &"":
		return
	var host := host_of(game_ctx, swarm_id)
	var swarm_card := game_ctx.state.registry.get_card(swarm_id)
	if swarm_card != null:
		VirtualCard.clear(swarm_card)
		if swarm_card.has_meta(META_HOST):
			swarm_card.remove_meta(META_HOST)
	if host == &"":
		return
	var host_card := game_ctx.state.registry.get_card(host)
	if host_card == null:
		return
	var members := _member_list(game_ctx, host)
	members.erase(swarm_id)
	if members.is_empty():
		if host_card.has_meta(META_MEMBERS):
			host_card.remove_meta(META_MEMBERS)
	else:
		host_card.set_meta(META_MEMBERS, members)


## 所有者可见的集群卡牌数量（不可查内容）。
static func owner_swarm_counts(game_ctx: GameContext, host_id: StringName) -> Dictionary:
	var counts := {}
	for sid in swarm_ids(game_ctx, host_id):
		var card := game_ctx.state.registry.get_card(sid)
		if card == null:
			continue
		var owner: StringName = card.owner_id
		counts[owner] = int(counts.get(owner, 0)) + 1
	return counts


static func sync_location(game_ctx: GameContext, source_id: StringName) -> void:
	if _sync_depth > 0 or game_ctx == null or game_ctx.state == null:
		return
	var pack := pack_ids(game_ctx, source_id)
	if pack.size() <= 1:
		return
	var src := game_ctx.state.registry.get_enemy(source_id)
	if src == null:
		return
	_sync_depth += 1
	for mid in pack:
		if mid == source_id:
			continue
		var other := game_ctx.state.registry.get_enemy(mid)
		if other != null:
			other.location_tag = src.location_tag
	_sync_depth -= 1


static func sync_engagement(game_ctx: GameContext, source_id: StringName) -> void:
	if _sync_depth > 0 or game_ctx == null or game_ctx.state == null:
		return
	var pack := pack_ids(game_ctx, source_id)
	if pack.size() <= 1:
		return
	var src := game_ctx.state.registry.get_enemy(source_id)
	if src == null:
		return
	_sync_depth += 1
	var engaged_with := src.engaged_with
	for mid in pack:
		if mid == source_id:
			continue
		var other := game_ctx.state.registry.get_enemy(mid)
		if other == null:
			continue
		other.engaged_with = engaged_with
		other.location_tag = src.location_tag
		if engaged_with == &"":
			## 脱离：清威胁区占位 + Buff。
			for inv_id in game_ctx.state.registry.all_investigator_ids():
				var inv := game_ctx.state.registry.get_investigator(inv_id)
				if inv != null:
					inv.threat_area.erase(mid)
			EngagementStatus.clear(game_ctx, mid)
		else:
			## 对齐 Buff；威胁区由 EnterThreatAreaFlow 进入（已在则 enter_if_needed 跳过）。
			for inv_id in game_ctx.state.registry.all_investigator_ids():
				if inv_id == engaged_with:
					continue
				var inv := game_ctx.state.registry.get_investigator(inv_id)
				if inv != null:
					inv.threat_area.erase(mid)
			EngagementStatus.grant(game_ctx, mid, engaged_with)
			EnterThreatAreaFlow.enter_if_needed(
				game_ctx, mid, engaged_with, EnterThreatAreaFlow.FROM_IN_PLAY
			)
	_sync_depth -= 1


static func sync_exhausted(game_ctx: GameContext, source_id: StringName) -> void:
	if _sync_depth > 0 or game_ctx == null or game_ctx.state == null:
		return
	var pack := pack_ids(game_ctx, source_id)
	if pack.size() <= 1:
		return
	var src := game_ctx.state.registry.get_enemy(source_id)
	if src == null:
		return
	_sync_depth += 1
	for mid in pack:
		if mid == source_id:
			continue
		var other := game_ctx.state.registry.get_enemy(mid)
		if other == null:
			continue
		other.exhausted = src.exhausted
		var card := game_ctx.state.registry.get_card(mid)
		if card != null:
			card.exhausted = src.exhausted
	_sync_depth -= 1


## 同步轴相关 gate：打在任一个体上按整包成员展开。
static func expand_sync_axis_targets(
	game_ctx: GameContext,
	target_id: StringName
) -> Array[StringName]:
	return pack_ids(game_ctx, target_id)


static func _member_list(game_ctx: GameContext, host_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	if game_ctx == null or game_ctx.state == null or host_id == &"":
		return out
	var host_card := game_ctx.state.registry.get_card(host_id)
	if host_card == null or not host_card.has_meta(META_MEMBERS):
		return out
	var raw: Variant = host_card.get_meta(META_MEMBERS)
	if not (raw is Array):
		return out
	for item in raw:
		out.append(item as StringName)
	## 过滤已离场。
	var alive: Array[StringName] = []
	for sid in out:
		if game_ctx.state.registry.get_enemy(sid) != null:
			alive.append(sid)
	if alive.size() != out.size() and host_card != null:
		if alive.is_empty():
			if host_card.has_meta(META_MEMBERS):
				host_card.remove_meta(META_MEMBERS)
		else:
			host_card.set_meta(META_MEMBERS, alive)
	return alive
