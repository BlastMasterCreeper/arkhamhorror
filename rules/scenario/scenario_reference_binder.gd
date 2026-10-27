class_name ScenarioReferenceBinder
extends RefCounted

## 将冒险参考卡 JSON 符号条装成卡实例上的印刷符号能力（空白可卸）。


static func bind_to_card(
	game_ctx: GameContext,
	card_id: StringName,
	def: ScenarioReferenceDefinition = null
) -> int:
	if game_ctx == null or game_ctx.state == null or card_id == &"":
		return 0
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return 0
	if def == null:
		def = game_ctx.state.scenario_reference
	if def == null and game_ctx.config != null:
		def = ScenarioReferenceCatalog.load_for_scenario(game_ctx.config.setup_scenario_id)
		game_ctx.state.scenario_reference = def
	if def == null:
		return 0
	var diff := &"easy_standard"
	if game_ctx.config != null and game_ctx.config.chaos_difficulty != &"":
		diff = game_ctx.config.chaos_difficulty
	## 卸旧印刷符号能力，再按当前难度带重装。
	_clear_printed_symbol_abilities(card)
	var bound := 0
	for kind in [
		AhcEnums.ChaosTokenKind.SKULL,
		AhcEnums.ChaosTokenKind.CULTIST,
		AhcEnums.ChaosTokenKind.TABLET,
		AhcEnums.ChaosTokenKind.ELDER_THING,
	]:
		var effect := def.effect_for(diff, kind)
		if effect.is_empty():
			continue
		var key := ScenarioReferenceDefinition._kind_key(kind)
		var ab := ChaosSymbolAbility.from_effect_dict(
			kind,
			effect,
			card_id,
			StringName("symbol:%s:%s" % [String(diff), key])
		)
		card.symbol_abilities.append(ab)
		bound += 1
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"setup:symbol_abilities_bound",
			{"card_id": card_id, "count": bound, "difficulty": diff}
		)
	return bound


static func _clear_printed_symbol_abilities(card: CardInstance) -> void:
	if card == null:
		return
	var kept: Array = []
	for raw in card.symbol_abilities:
		var ab: ChaosSymbolAbility = raw as ChaosSymbolAbility
		if ab != null and not ab.printed:
			kept.append(ab)
	card.symbol_abilities = kept
