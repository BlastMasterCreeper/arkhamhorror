class_name KeywordMount
extends RefCounted

## 06 §3.2.5–§3.2.7 · 按 KeywordProfile 在已有 seq 砖挂载关键词 Buff。
## 拥有 ≠ 行为：gained / 印刷涌动先挂 KEYWORD 标记（幂等）；AFTER 由 KeywordConsumer 开火。
## 禁止真空 Register；一律 nest seq.effect.register。


## 在已有流程砖挂载：遍历 profiles_for_register(flow_id, slot)。
static func mount_at(
	game_ctx: GameContext,
	flow_id: StringName,
	slot: StringName,
	card_id: StringName,
	drawer_id: StringName = &"",
	def_id: StringName = &""
) -> void:
	if game_ctx == null or card_id == &"":
		return
	if def_id == &"":
		def_id = _definition_id(game_ctx, card_id)
	for profile in KeywordProfileTable.profiles_for_register(flow_id, slot):
		_mount_profile(game_ctx, profile, card_id, drawer_id, def_id)


## 效果 gains keyword · 幂等 KEYWORD 标记（印刷已挂则 no-op）。
static func mount_gained(
	game_ctx: GameContext,
	card_id: StringName,
	keyword: StringName,
	_provenance: AbilityUnitRef = null
) -> void:
	EncounterGainedKeyword.register_if_absent(game_ctx, card_id, keyword)


## 印刷涌动：WHEN 面已知后挂 KEYWORD；与 gains 共用同一标记 → 不叠 LISTENER。
static func mount_surge_printed_if_absent(
	game_ctx: GameContext,
	card_id: StringName,
	def_id: StringName
) -> void:
	if game_ctx == null or card_id == &"":
		return
	if not CardRegistry.has_keyword(def_id, &"surge"):
		return
	EncounterGainedKeyword.register_if_absent(game_ctx, card_id, &"surge")


## 开火后 / 取消全部效果：卸本张抽牌结算期 KEYWORD 标记。
static func unmount_gained_for_card(game_ctx: GameContext, card_id: StringName) -> void:
	EncounterGainedKeyword.unregister_for_card(game_ctx, card_id)


## 涌动是否已武装（Registration KEYWORD）——AFTER 开火只认此，不懒读 Definition。
static func is_surge_armed(game_ctx: GameContext, card_id: StringName) -> bool:
	if game_ctx == null or game_ctx.registrations == null or card_id == &"":
		return false
	return game_ctx.registrations.has_keyword_buff(card_id, &"surge")


static func _mount_profile(
	game_ctx: GameContext,
	profile: KeywordProfile,
	card_id: StringName,
	drawer_id: StringName,
	def_id: StringName
) -> void:
	if profile == null:
		return
	match profile.keyword:
		&"surge":
			## LISTENER 延时：WHEN 挂 KEYWORD 标记；gains 同路径幂等。
			mount_surge_printed_if_absent(game_ctx, card_id, def_id)
		&"peril":
			EncounterPeril.register_if_peril(
				game_ctx,
				drawer_id,
				card_id,
				CardRegistry.has_keyword(def_id, &"peril")
			)
		_:
			## 其它关键词仍走既有专属门面（冷漠 / 猎手…）；本服务按 profile 逐步收口。
			pass


static func _definition_id(game_ctx: GameContext, card_id: StringName) -> StringName:
	if game_ctx == null or game_ctx.state == null:
		return &""
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return &""
	return card.id.definition_id
