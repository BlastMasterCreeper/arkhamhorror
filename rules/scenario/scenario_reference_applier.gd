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
			ChaosSkillModifier.apply(game_ctx, ctx, token.modifier)
			return
		AhcEnums.ChaosTokenKind.AUTO_FAIL:
			ctx.auto_fail = true
			return
		AhcEnums.ChaosTokenKind.AUTO_SUCCESS:
			ctx.auto_success = true
			return
		AhcEnums.ChaosTokenKind.BLESS, AhcEnums.ChaosTokenKind.CURSE:
			## 规则自带能力：由 BlessCurseRules 处理，不查参考卡。
			return
		AhcEnums.ChaosTokenKind.FROST:
			ChaosSkillModifier.apply(game_ctx, ctx, token.modifier)
			return
		AhcEnums.ChaosTokenKind.ELDER_SIGN:
			_apply_elder_sign(game_ctx, ctx, token, state)
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
			ChaosSkillModifier.apply(game_ctx, ctx, -maxi(store.current_act_number, 1))
		else:
			ChaosSkillModifier.apply(game_ctx, ctx, token.modifier)
		return
	_apply_symbol_ability(game_ctx, ctx, token, ability, store)


static func _apply_elder_sign(
	game_ctx: GameContext,
	ctx: SkillTestContext,
	token: ChaosToken,
	state: GameStateStore
) -> void:
	var store := state
	if store == null and game_ctx != null:
		store = game_ctx.state
	var ability := _lookup_elder_sign(game_ctx, store, ctx)
	if ability == null:
		## 无印刷 Elder Sign：旧印默认 +0（无额外效果）。
		var elder_mod := token.modifier if token != null else 0
		ChaosSkillModifier.apply(game_ctx, ctx, elder_mod)
		return
	_apply_symbol_ability(game_ctx, ctx, token, ability, store)


static func _apply_symbol_ability(
	game_ctx: GameContext,
	ctx: SkillTestContext,
	token: ChaosToken,
	ability: ChaosSymbolAbility,
	store: GameStateStore
) -> void:
	var effect := ability.to_effect_dict()
	ChaosSkillModifier.apply(game_ctx, ctx, _resolve_modifier(effect.get("modifier", 0), store))
	if bool(effect.get("reveal_another", false)) and token != null:
		token.reveal_another = true
	_execute_immediate(game_ctx, ctx, effect, ability)
	_register_st7(game_ctx, ctx, effect, ability)


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


static func _lookup_elder_sign(
	game_ctx: GameContext,
	store: GameStateStore,
	ctx: SkillTestContext
) -> ChaosSymbolAbility:
	if store == null or ctx == null:
		return null
	var inv := store.registry.get_investigator(ctx.performing_investigator)
	if inv == null:
		return null
	var ab := inv.active_symbol_ability(AhcEnums.ChaosTokenKind.ELDER_SIGN)
	if ab != null:
		return ab
	## 空白：有印刷但不发起。
	if inv.text_box_blank and _inv_had_printed_elder_sign(inv):
		return null
	## 懒装载定义。
	if game_ctx != null:
		ElderSignBinder.bind_investigator(game_ctx, inv.id)
		return inv.active_symbol_ability(AhcEnums.ChaosTokenKind.ELDER_SIGN)
	return null


static func _inv_had_printed_elder_sign(inv: InvestigatorState) -> bool:
	if inv == null:
		return false
	for raw in inv.symbol_abilities:
		var ab: ChaosSymbolAbility = raw as ChaosSymbolAbility
		if (
			ab != null
			and ab.printed
			and ab.symbol_kind == AhcEnums.ChaosTokenKind.ELDER_SIGN
		):
			return true
	## 空白前可能已卸；以定义为准。
	return not CardRegistry.elder_sign_effect(inv.definition_id).is_empty()


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


static func _execute_immediate(
	game_ctx: GameContext,
	ctx: SkillTestContext,
	effect: Dictionary,
	ability: ChaosSymbolAbility = null
) -> void:
	if game_ctx == null or game_ctx.composition == null:
		return
	var imm_raw: Variant = effect.get("immediate", {})
	if not (imm_raw is Dictionary) or (imm_raw as Dictionary).is_empty():
		return
	var node := _build_body(imm_raw as Dictionary, game_ctx, ctx, ability)
	if node != null:
		CompositionMount.resolve_ability(
			game_ctx, node, ctx.performing_investigator if ctx != null else &""
		)


static func _register_st7(
	game_ctx: GameContext,
	ctx: SkillTestContext,
	effect: Dictionary,
	ability: ChaosSymbolAbility = null
) -> void:
	if game_ctx == null or game_ctx.composition == null:
		return
	var on_ok_raw: Variant = effect.get("on_success", {})
	if on_ok_raw is Dictionary and not (on_ok_raw as Dictionary).is_empty():
		var ok_node := _build_body(on_ok_raw as Dictionary, game_ctx, ctx, ability)
		if ok_node != null:
			var prior_ok := ctx.on_success
			var body_ok := ok_node
			ctx.on_success = func(st: SkillTestContext) -> void:
				if prior_ok.is_valid():
					prior_ok.call(st)
				CompositionMount.resolve_ability(
					game_ctx, body_ok, st.performing_investigator
				)
	var on_fail_raw: Variant = effect.get("on_fail", {})
	if on_fail_raw is Dictionary and not (on_fail_raw as Dictionary).is_empty():
		var fail_node := _build_body(on_fail_raw as Dictionary, game_ctx, ctx, ability)
		if fail_node != null:
			var prior := ctx.on_fail
			var body := fail_node
			ctx.on_fail = func(st: SkillTestContext) -> void:
				if prior.is_valid():
					prior.call(st)
				CompositionMount.resolve_ability(
					game_ctx, body, st.performing_investigator
				)
	var fail_by_raw: Variant = effect.get("on_fail_by", {})
	if fail_by_raw is Dictionary and not (fail_by_raw as Dictionary).is_empty():
		var fb: Dictionary = fail_by_raw
		var threshold := maxi(int(fb.get("threshold", 1)), 1)
		var body_raw: Variant = fb.get("body", {})
		if body_raw is Dictionary:
			var by_node := _build_body(body_raw as Dictionary, game_ctx, ctx, ability)
			if by_node != null:
				var thr := threshold
				var body2 := by_node
				ctx.st7_fail_by_effects.append(
					func(st: SkillTestContext) -> void:
						if st.success or st.fail_by < thr:
							return
						CompositionMount.resolve_ability(
							game_ctx, body2, st.performing_investigator
						)
				)


static func _build_body(
	params: Dictionary,
	game_ctx: GameContext,
	ctx: SkillTestContext,
	ability: ChaosSymbolAbility = null
) -> CompositionNode:
	var template := str(params.get("template", ""))
	if template.is_empty():
		return null
	var bind := AbilityBindContext.new()
	bind.controller_id = ctx.performing_investigator if ctx != null else &""
	bind.card_id = &""
	if ability != null and ability.source_card_id != &"":
		bind.card_id = ability.source_card_id
	elif game_ctx != null and game_ctx.state != null:
		bind.card_id = game_ctx.state.scenario_reference_card_id
	return ArkhamDbAbilityCompiler.build_composition(template, params, bind)
