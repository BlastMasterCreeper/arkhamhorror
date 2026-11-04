class_name DeckLegality
extends RefCounted

## 整副牌组合法性 + 单卡 dry-run 准入（购卡报价用）。


## 返回 { ok: bool, errors: Array[String] }
static func validate_deck(cards: Array, profile: DeckbuildingProfile) -> Dictionary:
	var errors: Array[String] = []
	if profile == null:
		return {"ok": false, "errors": ["missing_profile"] as Array[String]}
	if not profile.unresolved_choices.is_empty():
		errors.append("unresolved_deckbuilding_choices")

	var views: Array[DeckCardView] = _to_views(cards)
	var counted_for_size := 0
	var title_counts: Dictionary = {}
	var title_max: Dictionary = {} ## title → max copies（exceptional 1 / myriad 3 / 默认 2）
	var limit_usage: Dictionary = {} ## rule instance id → count
	var faction_counts: Dictionary = {} ## faction → count（非 ignore）

	for card in views:
		## size：Permanent / 弱点 / Signature·Bearer（ignore_deckbuilding）不计；Myriad 计。
		if card.counts_toward_deck_size():
			counted_for_size += 1
		## 副本上限：Signature / Bearer（ignore）同名不占常规 2 上限（Grimoire Signature）。
		if not card.ignore_deckbuilding:
			var title_key := card.title.to_lower()
			title_counts[title_key] = int(title_counts.get(title_key, 0)) + 1
			var allowed := 2
			if card.exceptional:
				allowed = 1
			elif card.myriad:
				allowed = 3
			title_max[title_key] = mini(int(title_max.get(title_key, 99)), allowed)
		if card.ignore_deckbuilding:
			## 仍参与 atleast 职阶分布？Bearer/Signature 一般 ignore；跳过 faction 约束计数。
			pass
		else:
			for f in card.factions:
				var fk := String(f).to_lower()
				faction_counts[fk] = int(faction_counts.get(fk, 0)) + 1

		var access := CardAccessMatcher.classify(card, profile)
		var kind: StringName = access.get("kind", CardAccessMatcher.KIND_NONE)
		if kind == CardAccessMatcher.KIND_FORBIDDEN:
			errors.append("forbidden:%s" % String(card.definition_id))
			continue
		if kind == CardAccessMatcher.KIND_NONE:
			errors.append("no_access:%s" % String(card.definition_id))
			continue
		if kind == CardAccessMatcher.KIND_LIMITED:
			var rule: DeckOptionRule = access.get("rule")
			var key := _rule_key(rule)
			var used := int(limit_usage.get(key, 0)) + 1
			limit_usage[key] = used
			if rule != null and rule.limit >= 0 and used > rule.limit:
				errors.append("limit_exceeded:%s" % key)

	if counted_for_size != profile.deck_size:
		errors.append("deck_size:%d!=%d" % [counted_for_size, profile.deck_size])

	for title_key in title_counts.keys():
		var max_n := int(title_max.get(title_key, 2))
		if int(title_counts[title_key]) > max_n:
			errors.append("copy_limit:%s" % title_key)

	for constraint in profile.deck_constraints:
		_check_atleast(constraint, faction_counts, views, errors)

	return {"ok": errors.is_empty(), "errors": errors}


## 在现有牌组上再加入一张（可选同时移除若干）是否仍可配位。
## 不强制 deck_size（购卡窗常先加后移除）；验 FORBID / access / LIMIT。
static func can_add_card(
	deck: Array,
	new_card: DeckCardView,
	profile: DeckbuildingProfile,
	remove_cards: Array = []
) -> Dictionary:
	if new_card == null or profile == null:
		return {"ok": false, "reason": "missing"}
	var access := CardAccessMatcher.classify(new_card, profile)
	var kind: StringName = access.get("kind", CardAccessMatcher.KIND_NONE)
	if kind == CardAccessMatcher.KIND_FORBIDDEN:
		return {"ok": false, "reason": str(access.get("reason", "forbidden"))}
	if kind == CardAccessMatcher.KIND_NONE:
		return {"ok": false, "reason": "no_access"}

	var views: Array[DeckCardView] = _to_views(deck)
	var remove_ids: Dictionary = {}
	for r in _to_views(remove_cards):
		remove_ids[r.definition_id] = int(remove_ids.get(r.definition_id, 0)) + 1

	## Exceptional / Myriad 副本上限（计入将移除的源）。
	## Signature / Bearer（ignore_deckbuilding）不占常规同名上限（Grimoire Signature）。
	if not new_card.ignore_deckbuilding:
		var title_key := new_card.title.to_lower()
		var existing := 0
		var rem_left := remove_ids.duplicate()
		for card in views:
			if card.ignore_deckbuilding:
				continue
			if card.title.to_lower() != title_key:
				continue
			var rem := int(rem_left.get(card.definition_id, 0))
			if rem > 0:
				rem_left[card.definition_id] = rem - 1
				continue
			existing += 1
		var max_copies := 1 if new_card.exceptional else (3 if new_card.myriad else 2)
		if existing + 1 > max_copies:
			return {"ok": false, "reason": "copy_limit"}

	if kind == CardAccessMatcher.KIND_LIMITED:
		var rule: DeckOptionRule = access.get("rule")
		var used := 0
		for card in views:
			if card.ignore_deckbuilding:
				continue
			var rem := int(remove_ids.get(card.definition_id, 0))
			if rem > 0:
				remove_ids[card.definition_id] = rem - 1
				continue
			var a2 := CardAccessMatcher.classify(card, profile)
			if a2.get("kind") == CardAccessMatcher.KIND_LIMITED and a2.get("rule") == rule:
				used += 1
		if rule != null and rule.limit >= 0 and used + 1 > rule.limit:
			return {"ok": false, "reason": "limit_exceeded"}

	return {"ok": true, "reason": "", "access": access}


static func _check_atleast(
	constraint: DeckOptionRule,
	_faction_counts: Dictionary,
	views: Array[DeckCardView],
	errors: Array[String]
) -> void:
	if constraint.atleast_factions <= 0 or constraint.atleast_min <= 0:
		return
	## 按约束 faction 列表计数；ignore_match 时仍计整副职阶分布。
	var want: Array[StringName] = constraint.factions
	if want.is_empty():
		want = [
			&"guardian", &"seeker", &"rogue", &"mystic", &"survivor"
		] as Array[StringName]
	var meeting := 0
	for f in want:
		var count := 0
		for card in views:
			if card.ignore_deckbuilding:
				continue
			if constraint.has_level and (card.level < constraint.level_min or card.level > constraint.level_max):
				continue
			if constraint.has_base_level and (card.level < constraint.base_level_min or card.level > constraint.base_level_max):
				## 5U-21：atleast 用各职阶卡，level 带另有 base_level；此处仅过滤参与计数的卡。
				pass
			if card.has_faction(f):
				count += 1
		if count >= constraint.atleast_min:
			meeting += 1
	if meeting < constraint.atleast_factions:
		var msg := constraint.error if constraint.error != "" else "atleast_failed"
		errors.append(msg)


static func _to_views(cards: Array) -> Array[DeckCardView]:
	var out: Array[DeckCardView] = []
	for c in cards:
		if c is DeckCardView:
			out.append(c as DeckCardView)
		elif c is Dictionary:
			out.append(DeckCardView.from_definition_dict(c as Dictionary))
		elif c is StringName or c is String:
			out.append(DeckCardView.from_registry(StringName(str(c))))
	return out


static func _rule_key(rule: DeckOptionRule) -> String:
	if rule == null:
		return "null"
	if rule.id != &"":
		return String(rule.id)
	if rule.error != "":
		return rule.error
	return "limit_%d_%s" % [rule.limit, ",".join(rule.factions)]
