class_name KeywordMount
extends RefCounted

## 06 §3.2.5–§3.2.7 · 按 KeywordProfile 在已有 seq 砖 / 区划别名挂载关键词 Buff。
## 拥有 ≠ 行为：先挂 KEYWORD 标记（幂等）；LISTENER 开火由 KeywordConsumer / 专属 resolver 读武装。
## 禁止真空 Register；一律 nest seq.effect.register。


const _IN_PLAY_LISTENERS: Array[StringName] = [
	&"hunter",
	&"patrol",
	&"retaliate",
	&"alert",
	&"elusive",
	&"doomed",
	&"massive",
]


## 在已有流程砖 / 区划别名挂载：遍历 profiles_for_register(flow_id, slot)。
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


## 效果 gains keyword · 按 profile lifetime 选模板；幂等。
static func mount_gained(
	game_ctx: GameContext,
	card_id: StringName,
	keyword: StringName,
	_provenance: AbilityUnitRef = null
) -> void:
	if game_ctx == null or card_id == &"" or keyword == &"":
		return
	if is_keyword_armed(game_ctx, card_id, keyword):
		return
	var template := template_for_grant(card_id, keyword)
	CompositionMount.register_effect(game_ctx, template, &"", card_id)


## gains / 印刷挂载共用的 Register 模板。
static func template_for_grant(card_id: StringName, keyword: StringName) -> RegistrationTemplate:
	var profile := KeywordProfileTable.profile_for(keyword)
	if profile != null and profile.lifetime_kind == KeywordProfileTable.LIFE_IN_PLAY:
		return RegistrationTemplate.keyword_while_in_play(card_id, keyword)
	if _IN_PLAY_LISTENERS.has(keyword):
		return RegistrationTemplate.keyword_while_in_play(card_id, keyword)
	return RegistrationTemplate.gained_keyword_drawn_card_resolving(card_id, keyword)


## 印刷涌动：WHEN 面已知后挂 KEYWORD；与 gains 共用同一标记 → 不叠。
static func mount_surge_printed_if_absent(
	game_ctx: GameContext,
	card_id: StringName,
	def_id: StringName
) -> void:
	if game_ctx == null or card_id == &"":
		return
	if not CardRegistry.has_keyword(def_id, &"surge"):
		return
	mount_gained(game_ctx, card_id, &"surge")


## 开火后 / 取消全部效果：卸本张抽牌结算期 KEYWORD 标记（涌动）。
static func unmount_gained_for_card(game_ctx: GameContext, card_id: StringName) -> void:
	EncounterGainedKeyword.unregister_for_card(game_ctx, card_id)


## 任意 lifetime 上是否已有该 KEYWORD 武装标记。
static func is_keyword_armed(
	game_ctx: GameContext,
	card_id: StringName,
	keyword: StringName
) -> bool:
	if game_ctx == null or game_ctx.registrations == null or card_id == &"" or keyword == &"":
		return false
	return game_ctx.registrations.has_keyword_buff(card_id, keyword)


## 涌动是否已武装（抽牌结算期标记）。
static func is_surge_armed(game_ctx: GameContext, card_id: StringName) -> bool:
	return is_keyword_armed(game_ctx, card_id, &"surge")


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
			mount_surge_printed_if_absent(game_ctx, card_id, def_id)
		&"peril":
			EncounterPeril.register_if_peril(
				game_ctx,
				drawer_id,
				card_id,
				CardRegistry.has_keyword(def_id, &"peril")
			)
		&"aloof":
			if _printed_in_play(def_id, &"aloof"):
				AloofStatus.ensure_forbid_attack(game_ctx, card_id)
		&"hunter", &"patrol", &"retaliate", &"alert", &"elusive", &"doomed", &"massive":
			if _printed_in_play(def_id, profile.keyword):
				mount_gained(game_ctx, card_id, profile.keyword)
		&"permanent":
			mount_permanent_if_absent(game_ctx, card_id, def_id)
		&"starting":
			mount_starting_if_absent(game_ctx, card_id, def_id)
		&"bonded":
			mount_bonded_if_absent(game_ctx, card_id, def_id)
		_:
			pass


## 玩家轴 · 永久：进场挂 FORBID_LEAVE_PLAY（幂等）。
static func mount_permanent_if_absent(
	game_ctx: GameContext,
	card_id: StringName,
	def_id: StringName
) -> void:
	if game_ctx == null or card_id == &"":
		return
	if not CardRegistry.is_permanent(def_id):
		return
	if game_ctx.registrations != null and RestrictionEvaluator.blocks_leave_play(
		card_id, game_ctx.registrations
	):
		return
	CompositionMount.register_effect(
		game_ctx,
		RegistrationTemplate.permanent_forbid_leave_play(card_id),
		&"",
		card_id
	)


## 玩家轴 · 起始：在库挂 KEYWORD 标记（幂等）；开火见 StartingKeyword。
static func mount_starting_if_absent(
	game_ctx: GameContext,
	card_id: StringName,
	def_id: StringName
) -> void:
	if game_ctx == null or card_id == &"":
		return
	if not CardRegistry.is_starting(def_id):
		return
	if is_keyword_armed(game_ctx, card_id, &"starting"):
		return
	CompositionMount.register_effect(
		game_ctx,
		RegistrationTemplate.keyword_while_in_deck(card_id, &"starting"),
		&"",
		card_id
	)


## 玩家轴 · 绑定：set-aside 挂 KEYWORD 标记（幂等）。
static func mount_bonded_if_absent(
	game_ctx: GameContext,
	card_id: StringName,
	def_id: StringName
) -> void:
	if game_ctx == null or card_id == &"":
		return
	if not CardRegistry.is_bonded(def_id):
		return
	if is_keyword_armed(game_ctx, card_id, &"bonded"):
		return
	CompositionMount.register_effect(
		game_ctx,
		RegistrationTemplate.keyword_while_set_aside(card_id, &"bonded"),
		&"",
		card_id
	)


static func _printed_in_play(def_id: StringName, keyword: StringName) -> bool:
	match keyword:
		&"hunter":
			return CardRegistry.is_hunter(def_id)
		&"patrol":
			return CardRegistry.is_patrol(def_id)
		&"retaliate":
			return CardRegistry.is_retaliate(def_id)
		&"alert":
			return CardRegistry.is_alert(def_id)
		&"elusive":
			return CardRegistry.is_elusive(def_id)
		&"doomed":
			return CardRegistry.is_doomed(def_id)
		&"aloof":
			return CardRegistry.is_aloof(def_id)
		&"massive":
			return CardRegistry.is_massive(def_id)
		&"permanent":
			return CardRegistry.is_permanent(def_id)
		_:
			return CardRegistry.has_keyword(def_id, keyword)


static func _definition_id(game_ctx: GameContext, card_id: StringName) -> StringName:
	if game_ctx == null or game_ctx.state == null:
		return &""
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return &""
	return card.id.definition_id
