class_name KeywordConsumer
extends RefCounted

## 在规范消费槽 nest 已挂载关键词的 consume seq；抽牌管线只调这一次分发。


static func consume_after_drawn_card(
	game_ctx: GameContext,
	drawer_id: StringName,
	card_id: StringName
) -> Dictionary:
	return consume_at(
		game_ctx,
		KeywordProfileTable.SLOT_AFTER_DRAWN_CARD,
		drawer_id,
		card_id
	)


static func consume_at(
	game_ctx: GameContext,
	slot: StringName,
	drawer_id: StringName,
	card_id: StringName
) -> Dictionary:
	var merged := {
		"ok": true,
		"surged": false,
		"cards": [] as Array[StringName],
		"revelations": [] as Array[StringName],
		"spawn_failed_discards": [] as Array[StringName],
		"surge_depth": 0,
		"shuffles": 0,
	}
	if game_ctx == null or card_id == &"":
		return merged
	var def_id := _definition_id(game_ctx, card_id)
	var catalog := game_ctx.sequence_catalog
	for profile in KeywordProfileTable.profiles_for_slot(slot):
		if not EffectiveCharacteristicQuery.has_effective_keyword(
			game_ctx, card_id, def_id, profile.keyword
		):
			continue
		if catalog == null or not catalog.has_flow(profile.consume_flow_id):
			continue
		var nested: Dictionary = catalog.nest(
			game_ctx,
			profile.consume_flow_id,
			{
				"drawer_id": drawer_id,
				"card_id": card_id,
				"def_id": def_id,
			}
		)
		_merge_nested(merged, nested)
	return merged


static func evaluate_keyword(
	game_ctx: GameContext,
	card_id: StringName,
	keyword: StringName
) -> bool:
	var def_id := _definition_id(game_ctx, card_id)
	var has_kw := EffectiveCharacteristicQuery.has_effective_keyword(
		game_ctx, card_id, def_id, keyword
	)
	if keyword == &"surge":
		EncounterGainedKeyword.unregister_for_card(game_ctx, card_id)
	return has_kw


static func _definition_id(game_ctx: GameContext, card_id: StringName) -> StringName:
	if game_ctx == null or game_ctx.state == null:
		return &""
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return &""
	return card.id.definition_id


static func _merge_nested(merged: Dictionary, nested: Dictionary) -> void:
	if nested.is_empty():
		return
	if bool(nested.get("surged", false)):
		merged["surged"] = true
	merged["surge_depth"] = int(merged.get("surge_depth", 0)) + int(nested.get("surge_depth", 0))
	merged["shuffles"] = int(merged.get("shuffles", 0)) + int(nested.get("shuffles", 0))
	_append_ids(merged, "cards", nested.get("cards", []))
	_append_ids(merged, "revelations", nested.get("revelations", []))
	_append_ids(merged, "spawn_failed_discards", nested.get("spawn_failed_discards", []))


static func _append_ids(merged: Dictionary, key: String, src: Variant) -> void:
	if not (src is Array):
		return
	var dst: Array[StringName] = merged.get(key, [] as Array[StringName])
	for item in src:
		dst.append(item as StringName)
	merged[key] = dst
