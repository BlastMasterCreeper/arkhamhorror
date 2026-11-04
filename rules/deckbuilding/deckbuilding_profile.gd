class_name DeckbuildingProfile
extends RefCounted

## 调查员 deck_options 经选型解析后的有效 Profile。

var investigator_id: StringName = &""
var deck_size: int = 30
var forbids: Array[DeckOptionRule] = []
var unlimited: Array[DeckOptionRule] = []
var limited: Array[DeckOptionRule] = []
var deck_constraints: Array[DeckOptionRule] = []
var choices_raw: Dictionary = {}
var unresolved_choices: Array[DeckOptionRule] = []


static func from_options(
	options: Array,
	choices: Dictionary = {},
	deck_size_default: int = 30,
	investigator_id: StringName = &""
) -> DeckbuildingProfile:
	var profile := DeckbuildingProfile.new()
	profile.investigator_id = investigator_id
	profile.deck_size = deck_size_default
	profile.choices_raw = choices.duplicate()
	var rules: Array[DeckOptionRule] = []
	for item in options:
		if item is DeckOptionRule:
			rules.append(item as DeckOptionRule)
		elif item is Dictionary:
			rules.append(DeckOptionRule.from_dict(item as Dictionary))
	for rule in rules:
		if rule.has_atleast():
			profile.deck_constraints.append(rule)
		match rule.role:
			DeckOptionRule.Role.FORBID:
				profile.forbids.append(rule)
			DeckOptionRule.Role.DECK_CONSTRAINT:
				## 已在 has_atleast 挂过；纯约束无准入谓词时到此。
				if not rule.has_atleast():
					profile.deck_constraints.append(rule)
			DeckOptionRule.Role.META:
				pass
			DeckOptionRule.Role.CHOICE:
				_apply_choice(profile, rule, choices)
			DeckOptionRule.Role.LIMIT:
				profile.limited.append(rule)
			DeckOptionRule.Role.ALLOW:
				profile.unlimited.append(rule)
	return profile


static func from_investigator_definition(data: Dictionary, choices: Dictionary = {}) -> DeckbuildingProfile:
	var opts: Array = []
	var raw_opts: Variant = data.get("deck_options", [])
	if raw_opts is Array:
		opts = raw_opts as Array
	var size := 30
	var req: Variant = data.get("deck_requirements", {})
	if req is Dictionary and (req as Dictionary).has("size"):
		size = int((req as Dictionary).get("size", 30))
	elif req is String:
		size = _parse_size_from_req_string(req as String, 30)
	if choices.has("deck_size"):
		size = int(choices.get("deck_size"))
	var iid := StringName(str(data.get("definition_id", data.get("code", ""))))
	return from_options(opts, choices, size, iid)


static func _apply_choice(profile: DeckbuildingProfile, rule: DeckOptionRule, choices: Dictionary) -> void:
	if not rule.deck_size_select.is_empty():
		var key := "deck_size"
		if choices.has(key):
			profile.deck_size = int(choices.get(key))
		elif choices.has(rule.name):
			profile.deck_size = int(choices.get(rule.name))
		return
	var choice_key := String(rule.id) if rule.id != &"" else rule.name
	if choice_key == "":
		choice_key = "choice"
	var value: Variant = null
	if choices.has(choice_key):
		value = choices.get(choice_key)
	elif choices.has(rule.name):
		value = choices.get(rule.name)
	elif choices.has(String(rule.id)):
		value = choices.get(String(rule.id))
	if value == null:
		profile.unresolved_choices.append(rule)
		return
	## 双 Class Choice：value 可以是 Array。
	var values: Array = value as Array if value is Array else [value]
	for v in values:
		for resolved in rule.resolve_choice(v):
			if resolved.role == DeckOptionRule.Role.LIMIT:
				profile.limited.append(resolved)
			else:
				profile.unlimited.append(resolved)


static func _parse_size_from_req_string(raw: String, fallback: int) -> int:
	for part in raw.split(","):
		var p := part.strip_edges()
		if p.begins_with("size:"):
			return int(p.substr(5))
	return fallback
