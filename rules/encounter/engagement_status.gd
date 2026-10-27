class_name EngagementStatus
extends RefCounted

## 交战状态（成对 Buff）门面。
## 权威：RegistrationStore · RestrictionKind.ENGAGEMENT。
## 威胁区是区划占位（检测用），不是本 Buff；勿把「在威胁区」当成交战状态存储。
## 庞大仍可用虚拟同地点查询。


## 赋予交战状态 Buff（真实交战与「视为交战」共用）。
static func grant(
	game_ctx: GameContext,
	enemy_id: StringName,
	investigator_id: StringName
) -> StringName:
	if game_ctx == null or game_ctx.registrations == null:
		return &""
	if enemy_id == &"" or investigator_id == &"":
		return &""
	## 一对一：先卸该敌旧对。
	game_ctx.registrations.clear_engagement(enemy_id)
	var forbid_clues := false
	if game_ctx.state != null:
		var card := game_ctx.state.registry.get_card(enemy_id)
		if card != null:
			forbid_clues = CardRegistry.forbids_clues_while_engaged(card.id.definition_id)
	var template := RegistrationTemplate.engagement_pair(
		enemy_id, investigator_id, forbid_clues
	)
	if (
		game_ctx.sequence_catalog == null
		or not game_ctx.sequence_catalog.has_flow(&"seq.effect.register")
	):
		push_error("EngagementStatus.grant: seq.effect.register missing; vacuum refused")
		return &""
	var result := game_ctx.sequence_catalog.nest(
		game_ctx,
		&"seq.effect.register",
		{"template": template}
	)
	return result.get("reg_id", &"") as StringName


## 注销该敌人的交战状态 Buff。
static func clear(game_ctx: GameContext, enemy_id: StringName) -> void:
	if game_ctx == null or game_ctx.registrations == null:
		return
	game_ctx.registrations.clear_engagement(enemy_id)


## 是否成对交战：Buff 优先；庞大可虚拟同地点；Domain engaged_with 仅兼容迁移。
static func is_engaged_with(
	game_ctx: GameContext,
	enemy_id: StringName,
	investigator_id: StringName
) -> bool:
	if enemy_id == &"" or investigator_id == &"":
		return false
	if game_ctx != null and game_ctx.registrations != null:
		if game_ctx.registrations.has_engagement(enemy_id, investigator_id):
			return true
	if game_ctx == null or game_ctx.state == null:
		return false
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return false
	if enemy.massive:
		return MassiveEngagement.is_virtually_engaged_with(enemy, investigator_id, game_ctx)
	## 迁移兼容：尚无 Buff 时读 Domain。
	return enemy.engaged_with == investigator_id


## 该敌人当前交战伙伴（Buff → Domain → 空）。
static func partner(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	if game_ctx != null and game_ctx.registrations != null:
		var from_buff := game_ctx.registrations.engagement_partner(enemy_id)
		if from_buff != &"":
			return from_buff
	if game_ctx == null or game_ctx.state == null:
		return &""
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return &""
	return enemy.engaged_with


## 是否已有交战状态（任一伙伴）。
static func is_engaged(game_ctx: GameContext, enemy_id: StringName) -> bool:
	return partner(game_ctx, enemy_id) != &""
