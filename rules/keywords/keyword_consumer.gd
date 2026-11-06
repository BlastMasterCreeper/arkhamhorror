class_name KeywordConsumer
extends RefCounted

## LISTENER 竖切（06 §3.2.7）：按 consume_slot 收集，**fire_priority 升序**开火；
## payload 为命名 seq 时 nest。挂载时点 ≠ 开火锚；流程本身不管理关键词体。


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
		"moved": false,
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
		if profile.buff_type != &"LISTENER" or profile.consume_flow_id == &"":
			continue
		if not _armed_for_consume(game_ctx, card_id, def_id, profile.keyword):
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
	## 开火只认武装标记；涌动开火后卸抽牌期标记。
	var armed := KeywordMount.is_keyword_armed(game_ctx, card_id, keyword)
	if keyword == &"surge" and armed:
		KeywordMount.unmount_gained_for_card(game_ctx, card_id)
	return armed


## REPLACE 竖切（庞大）：按 slot 收集 TIER_REPLACE；武装则 nest consume_flow（redirect payload）。
## 返回 redirected=true 时父 RESOLVE 体被替换，不再跑原攻击叶。
static func try_redirect(
	game_ctx: GameContext,
	slot: StringName,
	card_id: StringName,
	params: Dictionary = {}
) -> Dictionary:
	var out := {"redirected": false, "ok": true, "attacks": 0}
	if game_ctx == null or card_id == &"":
		return out
	var def_id := _definition_id(game_ctx, card_id)
	var catalog := game_ctx.sequence_catalog
	for profile in KeywordProfileTable.profiles_for_slot(slot):
		if profile.category_tier != KeywordProfileTable.TIER_REPLACE:
			continue
		if profile.consume_flow_id == &"":
			continue
		if not _armed_for_consume(game_ctx, card_id, def_id, profile.keyword):
			continue
		## 庞大：仅 PHASE 攻击 redirect；AOO 等仍单次。
		if profile.keyword == &"massive":
			var attack_kind: int = int(params.get("attack_kind", AhcEnums.AttackKind.OPPORTUNITY))
			if attack_kind != AhcEnums.AttackKind.PHASE:
				continue
		if catalog == null or not catalog.has_flow(profile.consume_flow_id):
			continue
		## redirect payload：替换目标 = 当前攻击序列；替换体 = profile.consume_flow_id。
		var redirect := {
			"target": ReplacementTarget.sequence(
				KeywordProfileTable.FLOW_ENEMY_ATTACK,
				{"enemy_id": card_id, "card_id": card_id}
			),
			"replacement_flow_id": profile.consume_flow_id,
			"keyword": profile.keyword,
		}
		var nested: Dictionary = catalog.nest(
			game_ctx,
			profile.consume_flow_id,
			{
				"drawer_id": params.get("drawer_id", &""),
				"card_id": card_id,
				"enemy_id": card_id,
				"def_id": def_id,
				"redirect": redirect,
			}
		)
		out["redirected"] = true
		out["ok"] = bool(nested.get("ok", true))
		out["attacks"] = int(nested.get("attacks", 0))
		out["interrupted"] = bool(nested.get("interrupted", false))
		out["redirect"] = redirect
		_merge_nested(out, nested)
		## 同 slot 只取一条 REPLACE（fire_priority 已排序）。
		break
	return out


## LISTENER 消费：只认 Registration KEYWORD 武装（进场 WHEN 已挂；不懒读 Definition）。
static func _armed_for_consume(
	game_ctx: GameContext,
	card_id: StringName,
	_def_id: StringName,
	keyword: StringName
) -> bool:
	return KeywordMount.is_keyword_armed(game_ctx, card_id, keyword)


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
	if bool(nested.get("moved", false)):
		merged["moved"] = true
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
