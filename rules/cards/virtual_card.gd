class_name VirtualCard
extends RefCounted

## 虚拟卡牌：桌上实体代理 + 投影源（数值/文本/角色）。
## 集群卡牌、04192 式「视为另一张」等同族；展示可用牌背，域模型不靠 UNDER 区。

const ROLE_NONE: StringName = &""
const ROLE_SWARM_CARD: StringName = &"swarm_card"
const ROLE_AS_ASSET: StringName = &"as_asset"

const META_ROLE: StringName = &"virtual_role"
const META_PROJECTION_OF: StringName = &"virtual_projection_of"
const META_HOST: StringName = &"swarm_host_id"
const META_MEMBERS: StringName = &"swarm_member_ids"

## 移动 / 接战 / 横置对齐整包时防重入。流程自己走成员。
static var pack_align_depth: int = 0


static func bind(
	card: CardInstance,
	role: StringName,
	projection_of: StringName
) -> void:
	if card == null or role == &"":
		return
	card.set_meta(META_ROLE, role)
	card.set_meta(META_PROJECTION_OF, projection_of)
	## 默认不可见牌面（电子不还原翻看归属）。
	if card.face_visibility != null:
		card.face_visibility.audience = AhcEnums.FaceAudience.HIDDEN_ALL


static func clear(card: CardInstance) -> void:
	if card == null:
		return
	if card.has_meta(META_ROLE):
		card.remove_meta(META_ROLE)
	if card.has_meta(META_PROJECTION_OF):
		card.remove_meta(META_PROJECTION_OF)


static func role_of(card: CardInstance) -> StringName:
	if card == null or not card.has_meta(META_ROLE):
		return ROLE_NONE
	return card.get_meta(META_ROLE) as StringName


static func projection_of(card: CardInstance) -> StringName:
	if card == null or not card.has_meta(META_PROJECTION_OF):
		return &""
	return card.get_meta(META_PROJECTION_OF) as StringName


static func is_swarm_card(card: CardInstance) -> bool:
	return role_of(card) == ROLE_SWARM_CARD


static func is_swarm_card_id(game_ctx: GameContext, card_id: StringName) -> bool:
	if game_ctx == null or game_ctx.state == null or card_id == &"":
		return false
	return is_swarm_card(game_ctx.state.registry.get_card(card_id))


static func host_of(game_ctx: GameContext, member_id: StringName) -> StringName:
	if game_ctx == null or game_ctx.state == null or member_id == &"":
		return &""
	if not is_swarm_card_id(game_ctx, member_id):
		if _member_list(game_ctx, member_id).size() > 0:
			return member_id
		return &""
	var card := game_ctx.state.registry.get_card(member_id)
	var host := projection_of(card)
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
	bind(swarm_card, ROLE_SWARM_CARD, host_id)
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
		clear(swarm_card)
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


static func owner_swarm_counts(game_ctx: GameContext, host_id: StringName) -> Dictionary:
	var counts := {}
	for sid in swarm_ids(game_ctx, host_id):
		var card := game_ctx.state.registry.get_card(sid)
		if card == null:
			continue
		var owner: StringName = card.owner_id
		counts[owner] = int(counts.get(owner, 0)) + 1
	return counts


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
