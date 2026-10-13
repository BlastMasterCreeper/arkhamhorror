class_name SurgeKeywordFlow
extends RefCounted

## seq.keyword.surge · 抽取并结算后的关键词消费：卸标记，再 nest 一条新的遭遇抽牌。


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var drawer_id: StringName = params.get("drawer_id", &"")
	var card_id: StringName = params.get("card_id", &"")
	var def_id: StringName = params.get("def_id", &"")
	if def_id == &"":
		def_id = _definition_id(game_ctx, card_id)
	var should_surge := EffectiveCharacteristicQuery.has_effective_keyword(
		game_ctx, card_id, def_id, &"surge"
	)
	EncounterGainedKeyword.unregister_for_card(game_ctx, card_id)
	if not should_surge:
		return _empty_result()
	if game_ctx == null or game_ctx.sequence_catalog == null:
		return {
			"ok": true,
			"surged": true,
			"cards": [] as Array[StringName],
			"surge_depth": 1,
			"revelations": [] as Array[StringName],
			"spawn_failed_discards": [] as Array[StringName],
			"shuffles": 0,
		}
	var nested: Dictionary = game_ctx.sequence_catalog.nest(
		game_ctx,
		&"seq.draw.encounter",
		{"drawer_id": drawer_id}
	)
	var cards: Array[StringName] = []
	_append_ids(cards, nested.get("cards", []))
	var revelations: Array[StringName] = []
	_append_ids(revelations, nested.get("revelations", []))
	var spawn_failed: Array[StringName] = []
	_append_ids(spawn_failed, nested.get("spawn_failed_discards", []))
	return {
		"ok": bool(nested.get("ok", false)),
		"surged": true,
		"cards": cards,
		"surge_depth": 1 + int(nested.get("surge_depth", 0)),
		"revelations": revelations,
		"spawn_failed_discards": spawn_failed,
		"shuffles": int(nested.get("shuffles", 0)),
	}


static func _empty_result() -> Dictionary:
	return {
		"ok": true,
		"surged": false,
		"cards": [] as Array[StringName],
		"surge_depth": 0,
		"revelations": [] as Array[StringName],
		"spawn_failed_discards": [] as Array[StringName],
		"shuffles": 0,
	}


static func _definition_id(game_ctx: GameContext, card_id: StringName) -> StringName:
	if game_ctx == null or game_ctx.state == null:
		return &""
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return &""
	return card.id.definition_id


static func _append_ids(dst: Array[StringName], src: Variant) -> void:
	if not (src is Array):
		return
	for item in src:
		dst.append(item as StringName)
