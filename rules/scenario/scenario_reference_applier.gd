class_name ScenarioReferenceApplier
extends RefCounted

## ST.4：从参考卡实例上的隐式符号能力施加 modifier / reveal_another / ST.7。
## 印刷能力受 text_box_blank 约束；无卡/无能力时回退兼容旧硬编码。


static func apply_token(
	game_ctx: GameContext,
	ctx: SkillTestContext,
	token: ChaosToken,
	state: GameStateStore = null
) -> void:
	if token == null or ctx == null:
		return
	match token.kind:
		AhcEnums.ChaosTokenKind.NUMERIC:
			ctx.chaos_modifier += token.modifier
			return
		AhcEnums.ChaosTokenKind.AUTO_FAIL:
			ctx.auto_fail = true
			return
		AhcEnums.ChaosTokenKind.AUTO_SUCCESS:
			ctx.auto_success = true
			return
		AhcEnums.ChaosTokenKind.BLESS, AhcEnums.ChaosTokenKind.CURSE, AhcEnums.ChaosTokenKind.FROST:
			ctx.chaos_modifier += token.modifier
			return
		_:
			pass
	var store := state
	if store == null and game_ctx != null:
		store = game_ctx.state
	var ability := _lookup_ability(game_ctx, store, token.kind)
	if ability == null:
		## 无活动符号能力：skull 回退 –act（兼容旧硬编码）；其它用 token.modifier。
		## 空白参考卡（有印刷条但不发起）≠「无定义」——不回退。
		if _had_printed_but_blank(game_ctx, store, token.kind):
			return
		if token.kind == AhcEnums.ChaosTokenKind.SKULL and store != null:
			ctx.chaos_modifier -= maxi(store.current_act_number, 1)
		else:
			ctx.chaos_modifier += token.modifier
		return
	var effect := ability.to_effect_dict()
	ctx.chaos_modifier += _resolve_modifier(effect.get("modifier", 0), store)
	if bool(effect.get("reveal_another", false)):
		token.reveal_another = true
	_register_st7(game_ctx, ctx, effect)


static func _lookup_ability(
	game_ctx: GameContext,
	store: GameStateStore,
	kind: AhcEnums.ChaosTokenKind
) -> ChaosSymbolAbility:
	var card := _reference_card(game_ctx, store)
	if card != null:
		var ab := card.active_symbol_ability(kind)
		if ab != null:
			return ab
		## 卡已装但未绑能力时，尝试即时装载（测试旁路）。
		if card.symbol_abilities.is_empty() and game_ctx != null and card.id != null:
			ScenarioReferenceBinder.bind_to_card(game_ctx, card.id.instance_id)
			return card.active_symbol_ability(kind)
		return null
	## 无参考卡实例：从 JSON 临时构造（不挂卡；兼容未 setup 场景）。
	var effect := _lookup_effect_dict(game_ctx, store, kind)
	if effect.is_empty():
		return null
	return ChaosSymbolAbility.from_effect_dict(kind, effect, &"", &"transient")


static func _had_printed_but_blank(
	game_ctx: GameContext,
	store: GameStateStore,
	kind: AhcEnums.ChaosTokenKind
) -> bool:
	var card := _reference_card(game_ctx, store)
	if card == null or not card.text_box_blank:
		return false
	for raw in card.symbol_abilities:
		var ab: ChaosSymbolAbility = raw as ChaosSymbolAbility
		if ab != null and ab.printed and ab.symbol_kind == kind:
			return true
	return false


static func _reference_card(game_ctx: GameContext, store: GameStateStore) -> CardInstance:
	if store == null or store.scenario_reference_card_id == &"":
		return null
	return store.registry.get_card(store.scenario_reference_card_id)


static func _lookup_effect_dict(
	game_ctx: GameContext,
	store: GameStateStore,
	kind: AhcEnums.ChaosTokenKind
) -> Dictionary:
	var def: ScenarioReferenceDefinition = null
	if store != null:
		def = store.scenario_reference
	if def == null and game_ctx != null and game_ctx.config != null:
		def = ScenarioReferenceCatalog.load_for_scenario(game_ctx.config.setup_scenario_id)
		if store != null:
			store.scenario_reference = def
	if def == null:
		return {}
	var diff := &"easy_standard"
	if game_ctx != null and game_ctx.config != null and game_ctx.config.chaos_difficulty != &"":
		diff = game_ctx.config.chaos_difficulty
	return def.effect_for(diff, kind)


static func _resolve_modifier(raw: Variant, store: GameStateStore) -> int:
	if typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT:
		return int(raw)
	if typeof(raw) != TYPE_DICTIONARY:
		return 0
	var d: Dictionary = raw
	var expr := str(d.get("expr", ""))
	var act := 1
	if store != null:
		act = maxi(store.current_act_number, 1)
	match expr:
		"neg_act":
			return -act
		"neg_act_plus_1":
			return -(act + 1)
		"act":
			return act
		"act_plus_1":
			return act + 1
		_:
			return int(d.get("value", 0))


static func _register_st7(
	game_ctx: GameContext,
	ctx: SkillTestContext,
	effect: Dictionary
) -> void:
	if game_ctx == null or game_ctx.composition == null:
		return
	var on_fail_raw: Variant = effect.get("on_fail", {})
	if on_fail_raw is Dictionary and not (on_fail_raw as Dictionary).is_empty():
		var fail_node := _build_body(on_fail_raw as Dictionary, game_ctx, ctx)
		if fail_node != null:
			var prior := ctx.on_fail
			var body := fail_node
			ctx.on_fail = func(st: SkillTestContext) -> void:
				if prior.is_valid():
					prior.call(st)
				game_ctx.composition.execute(body)
	var fail_by_raw: Variant = effect.get("on_fail_by", {})
	if fail_by_raw is Dictionary and not (fail_by_raw as Dictionary).is_empty():
		var fb: Dictionary = fail_by_raw
		var threshold := maxi(int(fb.get("threshold", 1)), 1)
		var body_raw: Variant = fb.get("body", {})
		if body_raw is Dictionary:
			var by_node := _build_body(body_raw as Dictionary, game_ctx, ctx)
			if by_node != null:
				var thr := threshold
				var body2 := by_node
				ctx.st7_fail_by_effects.append(
					func(st: SkillTestContext) -> void:
						if st.success or st.fail_by < thr:
							return
						game_ctx.composition.execute(body2)
				)


static func _build_body(
	params: Dictionary,
	game_ctx: GameContext,
	ctx: SkillTestContext
) -> CompositionNode:
	var template := str(params.get("template", ""))
	if template.is_empty():
		return null
	var bind := AbilityBindContext.new()
	bind.controller_id = ctx.performing_investigator if ctx != null else &""
	bind.card_id = &""
	if game_ctx != null and game_ctx.state != null:
		bind.card_id = game_ctx.state.scenario_reference_card_id
	return ArkhamDbAbilityCompiler.build_composition(template, params, bind)
