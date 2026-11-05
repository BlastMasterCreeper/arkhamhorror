class_name DeckbuildingChoiceFlow
extends RefCounted

## 选定调查员后的附带玩家选择（副职阶 / 特性 / 牌组尺寸等）。
## 统一消费 `deck_options` 里 Role.CHOICE 条目；答案写入 `deckbuilding_choices`，
## 再冻结为 `DeckbuildingProfile`。≠ 对局内 seq 时点的 PlayerInteractionGate。

const KIND_FACTION := &"faction_select"
const KIND_OPTION := &"option_select"
const KIND_DECK_SIZE := &"deck_size_select"


## 列出该调查员尚未/需要完成的构筑选型提示。
## 返回 Array[Dictionary]：{ key, kind, label, options, multi, answered, value? }
static func list_choices(
	investigator_def: Dictionary,
	answered: Dictionary = {}
) -> Array:
	var out: Array = []
	var opts: Array = investigator_def.get("deck_options", []) if investigator_def.has("deck_options") else []
	for item in opts:
		var rule: DeckOptionRule = (
			item if item is DeckOptionRule else DeckOptionRule.from_dict(item as Dictionary)
		)
		if rule.role != DeckOptionRule.Role.CHOICE:
			continue
		var entry := _choice_entry(rule, answered)
		if not entry.is_empty():
			out.append(entry)
	return out


## 将玩家答案合并进 choices；校验选项合法。返回 { ok, choices, errors }。
static func apply_answers(
	investigator_def: Dictionary,
	prior: Dictionary,
	answers: Dictionary
) -> Dictionary:
	var merged: Dictionary = prior.duplicate(true)
	var errors: Array[String] = []
	var pending := list_choices(investigator_def, {})
	var by_key: Dictionary = {}
	for p in pending:
		by_key[str(p.get("key", ""))] = p
	for ak in answers.keys():
		var key := str(ak)
		if not by_key.has(key):
			## 允许用 label/name 别名；否则记错。
			var matched := ""
			for p in pending:
				if str(p.get("label", "")) == key:
					matched = str(p.get("key", ""))
					break
			if matched == "":
				errors.append("unknown_choice:%s" % key)
				continue
			key = matched
		var spec: Dictionary = by_key[key]
		var value: Variant = answers[ak]
		if not _value_allowed(spec, value):
			errors.append("illegal_value:%s=%s" % [key, str(value)])
			continue
		merged[key] = _normalize_value(spec, value)
	return {"ok": errors.is_empty(), "choices": merged, "errors": errors}


## 选定调查员：写入 record.definition_id + 应用附带选择；未完成则 unresolved。
static func bind_investigator(
	record: CampaignInvestigatorRecord,
	investigator_def: Dictionary,
	answers: Dictionary = {}
) -> Dictionary:
	if record == null:
		return {"ok": false, "reason": "missing_record"}
	var def_id := StringName(
		str(investigator_def.get("definition_id", investigator_def.get("code", "")))
	)
	if def_id != &"":
		record.definition_id = def_id
		## 确保注册，便于后续 profile()。
		if CardRegistry.definition_data(def_id).is_empty():
			var copy := investigator_def.duplicate(true)
			copy["definition_id"] = String(def_id)
			CardRegistry.register_definition(def_id, copy)
	var applied := apply_answers(investigator_def, record.deckbuilding_choices, answers)
	if not bool(applied.get("ok", false)):
		return {"ok": false, "reason": "illegal_answers", "errors": applied.get("errors", [])}
	record.deckbuilding_choices = applied["choices"]
	var profile := DeckbuildingProfile.from_investigator_definition(
		investigator_def, record.deckbuilding_choices
	)
	var still := list_choices(investigator_def, record.deckbuilding_choices)
	var unresolved: Array = []
	for c in still:
		if not bool(c.get("answered", false)):
			unresolved.append(c)
	return {
		"ok": unresolved.is_empty() and profile.unresolved_choices.is_empty(),
		"profile": profile,
		"unresolved": unresolved,
		"choices": record.deckbuilding_choices,
	}


static func _choice_entry(rule: DeckOptionRule, answered: Dictionary) -> Dictionary:
	var key := _choice_key(rule)
	var kind: StringName = &""
	var options: Array = []
	var multi := false
	if not rule.deck_size_select.is_empty():
		kind = KIND_DECK_SIZE
		key = "deck_size" if key == "choice" or key == "" else key
		for s in rule.deck_size_select:
			options.append({"id": str(s), "label": str(s)})
	elif not rule.faction_select.is_empty():
		kind = KIND_FACTION
		for f in rule.faction_select:
			options.append({"id": String(f), "label": String(f)})
	elif not rule.option_select.is_empty():
		kind = KIND_OPTION
		for opt in rule.option_select:
			if opt is Dictionary:
				var d: Dictionary = opt
				var oid := str(d.get("id", d.get("name", "")))
				options.append({"id": oid, "label": str(d.get("name", oid)), "raw": d})
	else:
		return {}
	var has := answered.has(key) or answered.has(rule.name) or (
		rule.id != &"" and answered.has(String(rule.id))
	)
	var value: Variant = null
	if answered.has(key):
		value = answered.get(key)
	elif answered.has(rule.name):
		value = answered.get(rule.name)
	elif rule.id != &"" and answered.has(String(rule.id)):
		value = answered.get(String(rule.id))
	return {
		"key": key,
		"kind": kind,
		"label": rule.name if rule.name != "" else key,
		"id": rule.id,
		"options": options,
		"multi": multi,
		"answered": has and value != null,
		"value": value,
		"limit": rule.limit,
		"level_min": rule.level_min if rule.has_level else 0,
		"level_max": rule.level_max if rule.has_level else 5,
		"types": rule.types.duplicate(),
	}


static func _choice_key(rule: DeckOptionRule) -> String:
	if not rule.deck_size_select.is_empty():
		return "deck_size"
	if rule.id != &"":
		return String(rule.id)
	if rule.name != "":
		return rule.name
	return "choice"


static func _value_allowed(spec: Dictionary, value: Variant) -> bool:
	var ids: Array = []
	for o in spec.get("options", []):
		ids.append(str((o as Dictionary).get("id", "")))
	if value is Array:
		for v in value as Array:
			if not ids.has(str(v).to_lower()) and not ids.has(str(v)):
				## faction ids 已 lower；尺寸是数字字符串。
				var ok := false
				for idv in ids:
					if str(idv).to_lower() == str(v).to_lower():
						ok = true
						break
				if not ok:
					return false
		return true
	var s := str(value)
	for idv in ids:
		if str(idv) == s or str(idv).to_lower() == s.to_lower():
			return true
	return false


static func _normalize_value(spec: Dictionary, value: Variant) -> Variant:
	if spec.get("kind") == KIND_DECK_SIZE:
		return int(value)
	if value is Array:
		var out: Array = []
		for v in value as Array:
			out.append(str(v).to_lower() if spec.get("kind") == KIND_FACTION else str(v))
		return out
	if spec.get("kind") == KIND_FACTION:
		return str(value).to_lower()
	return str(value)
