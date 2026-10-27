class_name ElderSignBinder
extends RefCounted

## 将调查员定义上的 `[elder_sign] effect` 装成印刷符号能力。


static func bind_investigator(game_ctx: GameContext, inv_id: StringName) -> int:
	if game_ctx == null or game_ctx.state == null or inv_id == &"":
		return 0
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null:
		return 0
	_clear_printed_elder_sign(inv)
	var effect: Dictionary = CardRegistry.elder_sign_effect(inv.definition_id)
	if effect.is_empty():
		return 0
	var ab := ChaosSymbolAbility.from_effect_dict(
		AhcEnums.ChaosTokenKind.ELDER_SIGN,
		effect,
		inv_id,
		StringName("elder_sign:%s" % String(inv.definition_id))
	)
	inv.symbol_abilities.append(ab)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.CARD,
			"setup:elder_sign_bound",
			{"inv": inv_id, "definition": inv.definition_id}
		)
	return 1


static func _clear_printed_elder_sign(inv: InvestigatorState) -> void:
	if inv == null:
		return
	var kept: Array = []
	for raw in inv.symbol_abilities:
		var ab: ChaosSymbolAbility = raw as ChaosSymbolAbility
		if ab == null:
			continue
		if ab.printed and ab.symbol_kind == AhcEnums.ChaosTokenKind.ELDER_SIGN:
			continue
		kept.append(ab)
	inv.symbol_abilities = kept
