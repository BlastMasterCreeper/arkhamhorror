class_name SurgeKeywordFlow
extends RefCounted

## seq.keyword.surge · 抽取并结算后的关键词消费：只认武装 KEYWORD 标记（不懒读 Definition）。
## 印刷在 WHEN 挂载；gains 幂等补挂；取消全部效果卸标记后此处不发火。


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var drawer_id: StringName = params.get("drawer_id", &"")
	var card_id: StringName = params.get("card_id", &"")
	var should_surge := KeywordMount.is_surge_armed(game_ctx, card_id)
	KeywordMount.unmount_gained_for_card(game_ctx, card_id)
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


static func _append_ids(dst: Array[StringName], src: Variant) -> void:
	if not (src is Array):
		return
	for item in src:
		dst.append(item as StringName)
