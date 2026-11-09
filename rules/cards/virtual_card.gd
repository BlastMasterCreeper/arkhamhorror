class_name VirtualCard
extends RefCounted

## 虚拟卡牌：桌上实体代理 + 投影源（数值/文本/角色）。
## 集群卡牌、04192 式「视为另一张」等同族；展示可用牌背，域模型不靠 UNDER 区。

const ROLE_NONE: StringName = &""
const ROLE_SWARM_CARD: StringName = &"swarm_card"
const ROLE_AS_ASSET: StringName = &"as_asset"

const META_ROLE: StringName = &"virtual_role"
const META_PROJECTION_OF: StringName = &"virtual_projection_of"


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
