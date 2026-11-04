class_name InvestigatorCampaignSystem
extends RefCounted

## Experience 购卡窗：报价 / 提交 / 候选目录 / 幕间入口。
## Customizable sheet 延后（P6c）。


static func begin_experience_window(
	record: CampaignInvestigatorRecord,
	earned_xp: int,
	modifiers: Array = []
) -> void:
	if record == null:
		return
	record.unspent_xp += maxi(0, earned_xp)
	record.xp_modifiers = modifiers.duplicate()
	record.experience_window_open = true


static func end_experience_window(record: CampaignInvestigatorRecord) -> void:
	if record == null:
		return
	record.experience_window_open = false
	record.xp_modifiers.clear()


## 返回可购印刷品 definition_id 列表（player cardtype；已过 Profile 准入 dry-run）。
static func list_accessible(
	record: CampaignInvestigatorRecord,
	pool: Array = []
) -> Array[StringName]:
	var out: Array[StringName] = []
	if record == null:
		return out
	var profile := record.profile()
	var ids: Array = pool
	if ids.is_empty():
		ids = CardRegistry.all_definition_ids()
	for id_v in ids:
		var id := StringName(str(id_v))
		var view := DeckCardView.from_registry(id)
		if view.definition_id == &"":
			continue
		if not _is_purchase_cardtype(view.card_type):
			continue
		var check := DeckLegality.can_add_card(record.deck_as_array(), view, profile)
		if bool(check.get("ok", false)):
			out.append(id)
	return out


## 选定目标印刷品 → Offer：{ ok, options: [{ kind, xp, target, source?, remove_ids }] }
static func quote_purchase(
	record: CampaignInvestigatorRecord,
	target_def_id: StringName
) -> Dictionary:
	if record == null:
		return {"ok": false, "reason": "missing_record", "options": []}
	if not record.experience_window_open:
		return {"ok": false, "reason": "window_closed", "options": []}
	var target := DeckCardView.from_registry(target_def_id)
	if target.definition_id == &"":
		## 允许测试直接用已注册数据；若空则失败。
		return {"ok": false, "reason": "unknown_card", "options": []}
	var profile := record.profile()
	var options: Array = []
	var mods: Array = record.xp_modifiers

	## NEW_CARD
	var new_check := DeckLegality.can_add_card(record.deck_as_array(), target, profile)
	if bool(new_check.get("ok", false)):
		## Exceptional 已有同名 → 拒。
		if target.exceptional and _title_count(record, target.title) >= 1:
			pass
		else:
			var xp_new := XpCostCalculator.cost_new_card(target, mods)
			options.append(
				{
					"kind": XpCostCalculator.KIND_NEW_CARD,
					"xp": xp_new,
					"target": target,
					"source": null,
					"remove_ids": [],
					"affordable": xp_new <= record.unspent_xp,
				}
			)

	## UPGRADE：同 title、更低 level 源。
	var seen_levels: Dictionary = {}
	for src in record.deck:
		if src.title.to_lower() != target.title.to_lower():
			continue
		if src.level >= target.level:
			continue
		var lk := src.level
		if seen_levels.has(lk):
			continue
		seen_levels[lk] = true
		var remove: Array = [src]
		var up_check := DeckLegality.can_add_card(
			record.deck_as_array(), target, profile, remove
		)
		if not bool(up_check.get("ok", false)):
			continue
		var xp_up := XpCostCalculator.cost_upgrade(target, src, mods)
		options.append(
			{
				"kind": XpCostCalculator.KIND_UPGRADE,
				"xp": xp_up,
				"target": target,
				"source": src,
				"remove_ids": [src.definition_id],
				"affordable": xp_up <= record.unspent_xp,
			}
		)

	return {"ok": not options.is_empty(), "reason": "" if not options.is_empty() else "no_options", "options": options}


## choice: Offer 中的一条（或 { kind, target_def, source_def?, xp }）。
static func commit_purchase(record: CampaignInvestigatorRecord, choice: Dictionary) -> Dictionary:
	if record == null or not record.experience_window_open:
		return {"ok": false, "reason": "window_closed"}
	var kind: StringName = choice.get("kind", &"")
	var target: DeckCardView = choice.get("target")
	if target == null and choice.has("target_def"):
		target = DeckCardView.from_registry(StringName(str(choice.get("target_def"))))
	if target == null:
		return {"ok": false, "reason": "missing_target"}
	var xp := int(choice.get("xp", -1))
	var source: DeckCardView = choice.get("source")
	var mods: Array = record.xp_modifiers
	if xp < 0:
		if kind == XpCostCalculator.KIND_UPGRADE and source != null:
			xp = XpCostCalculator.cost_upgrade(target, source, mods)
		else:
			xp = XpCostCalculator.cost_new_card(target, mods)
			kind = XpCostCalculator.KIND_NEW_CARD
	if xp > record.unspent_xp:
		return {"ok": false, "reason": "insufficient_xp"}

	var profile := record.profile()
	var remove: Array = []
	if kind == XpCostCalculator.KIND_UPGRADE and source != null:
		remove.append(source)
	var check := DeckLegality.can_add_card(record.deck_as_array(), target, profile, remove)
	if not bool(check.get("ok", false)):
		return {"ok": false, "reason": str(check.get("reason", "illegal"))}

	if kind == XpCostCalculator.KIND_UPGRADE and source != null:
		_remove_one(record, source.definition_id)
	elif kind == XpCostCalculator.KIND_NEW_CARD and target.counts_toward_deck_size():
		## 维持尺寸：仅对计入 size 的卡要求 +1/−1；Permanent / Signature / 弱点 / Bearer 免。
		var remove_ids: Array = choice.get("remove_ids", [])
		if remove_ids.is_empty():
			var counted := _count_for_size(record)
			if counted + 1 > profile.deck_size:
				return {"ok": false, "reason": "need_remove_for_size"}
		else:
			for rid in remove_ids:
				_remove_one(record, StringName(str(rid)))

	record.deck.append(target)
	## Myriad：购一张可再 +≤2 同 level 0 XP 副本；**仍计入 size**，每张额外副本也须维持尺寸。
	if target.myriad and bool(choice.get("myriad_extra", false)):
		var extras := mini(2, int(choice.get("myriad_extra_count", 2)))
		var extra_removes: Array = choice.get("myriad_extra_remove_ids", [])
		var extra_ri := 0
		for _i in extras:
			if _title_count(record, target.title) >= 3:
				break
			if target.counts_toward_deck_size():
				if extra_ri < extra_removes.size():
					_remove_one(record, StringName(str(extra_removes[extra_ri])))
					extra_ri += 1
				elif _count_for_size(record) + 1 > profile.deck_size:
					return {"ok": false, "reason": "need_remove_for_myriad_extra"}
			record.deck.append(DeckCardView.from_definition_dict({
				"definition_id": String(target.definition_id),
				"title": target.title,
				"level": target.level,
				"card_type": String(target.card_type),
				"factions": target.factions.duplicate(),
				"traits": target.traits.duplicate(),
				"myriad": true,
			}, target.definition_id))

	record.unspent_xp -= xp
	return {"ok": true, "kind": kind, "xp_spent": xp, "unspent_xp": record.unspent_xp}


static func _is_purchase_cardtype(card_type: StringName) -> bool:
	var t := String(card_type)
	return t in ["asset", "event", "skill"]


static func _title_count(record: CampaignInvestigatorRecord, title: String) -> int:
	var n := 0
	var key := title.to_lower()
	for c in record.deck:
		if c.title.to_lower() == key:
			n += 1
	return n


static func _count_for_size(record: CampaignInvestigatorRecord) -> int:
	var n := 0
	for c in record.deck:
		if c.counts_toward_deck_size():
			n += 1
	return n


static func _remove_one(record: CampaignInvestigatorRecord, def_id: StringName) -> bool:
	for i in record.deck.size():
		if record.deck[i].definition_id == def_id:
			record.deck.remove_at(i)
			return true
	return false
