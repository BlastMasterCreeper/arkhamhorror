class_name KeywordEffects
extends RefCounted

## 关键词 / 固定规则的开火体解释器。
## 规格写在 KeywordProfile.effect_*（静态 nest，与卡面 Composition 的 nest 叶同一语言）。
## 框架在已压栈的 seq.keyword.* 里代入 `$参数` 并 nest 已有 seq，不为每个关键词再写实现类。


static func resolve(game_ctx: GameContext, keyword: StringName, bind: Dictionary) -> Dictionary:
	var profile := KeywordProfileTable.profile_for(keyword)
	if profile == null or profile.effect_flow_id == &"":
		return {"ok": false, "reason": &"no_effect_spec", "keyword": keyword}
	var card_id: StringName = bind.get("card_id", bind.get("enemy_id", &""))
	if profile.effect_report == &"surge":
		var armed := KeywordMount.is_surge_armed(game_ctx, card_id)
		KeywordMount.unmount_gained_for_card(game_ctx, card_id)
		if not armed:
			return _surge_empty()
		if game_ctx == null or game_ctx.sequence_catalog == null:
			return _surge_empty(true)
	var params := _bind_params(profile.effect_params, bind, card_id)
	var nested := _nest(game_ctx, profile.effect_flow_id, params)
	if profile.effect_report == &"surge":
		return _surge_report(nested)
	return nested


static func _nest(game_ctx: GameContext, flow_id: StringName, params: Dictionary) -> Dictionary:
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(flow_id)
	):
		return game_ctx.sequence_catalog.nest(game_ctx, flow_id, params)
	if flow_id == &"seq.effect.move":
		return MoveFlow.run(game_ctx, params)
	return {"ok": false, "reason": &"missing_flow", "flow_id": flow_id}


static func _bind_params(
	spec: Dictionary,
	bind: Dictionary,
	card_id: StringName
) -> Dictionary:
	var out := {}
	for key in spec.keys():
		var value: Variant = spec[key]
		if value is String or value is StringName:
			var text := str(value)
			if text.begins_with("$"):
				var ref := text.substr(1)
				if ref == "card_id":
					out[key] = card_id
				elif ref == "enemy_id":
					var enemy_id: StringName = bind.get("enemy_id", &"")
					out[key] = enemy_id if enemy_id != &"" else card_id
				else:
					out[key] = bind.get(ref, bind.get(StringName(ref), &""))
				continue
		out[key] = value
	return out


static func _surge_report(nested: Dictionary) -> Dictionary:
	var cards: Array[StringName] = []
	var revelations: Array[StringName] = []
	var spawn_failed: Array[StringName] = []
	_append_ids(cards, nested.get("cards", []))
	_append_ids(revelations, nested.get("revelations", []))
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


static func _surge_empty(surged: bool = false) -> Dictionary:
	return {
		"ok": true,
		"surged": surged,
		"cards": [] as Array[StringName],
		"surge_depth": 1 if surged else 0,
		"revelations": [] as Array[StringName],
		"spawn_failed_discards": [] as Array[StringName],
		"shuffles": 0,
	}


static func _append_ids(dst: Array[StringName], src: Variant) -> void:
	if not (src is Array):
		return
	for item in src:
		dst.append(item as StringName)
