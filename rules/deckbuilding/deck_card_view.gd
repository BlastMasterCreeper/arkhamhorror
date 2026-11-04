class_name DeckCardView
extends RefCounted

## 构筑/购卡准入用的卡面快照（非运行时 CardInstance）。

var definition_id: StringName = &""
var title: String = ""
var level: int = 0
var card_type: StringName = &""
var factions: Array[StringName] = []
var traits: Array[StringName] = []
var tags: Array[StringName] = []
var uses_types: Array[StringName] = []
var permanent: bool = false
## Signature / bearer / 显式忽略 options 的卡。
var ignore_deckbuilding: bool = false


static func from_definition_dict(data: Dictionary, definition_id: StringName = &"") -> DeckCardView:
	var v := DeckCardView.new()
	v.definition_id = definition_id if definition_id != &"" else StringName(str(data.get("definition_id", "")))
	v.title = str(data.get("title", ""))
	v.level = int(data.get("level", data.get("xp", 0)))
	v.card_type = StringName(str(data.get("card_type", "")))
	v.permanent = bool(data.get("permanent", false))
	v.ignore_deckbuilding = bool(data.get("ignore_deckbuilding", false))
	v.factions = _string_names(data.get("factions", []))
	if v.factions.is_empty():
		var fc := str(data.get("faction_code", ""))
		if fc != "":
			v.factions.append(StringName(fc))
		for key in ["faction2_code", "faction3_code"]:
			var extra := str(data.get(key, ""))
			if extra != "":
				v.factions.append(StringName(extra))
	v.traits = _lower_names(data.get("traits", []))
	v.tags = _lower_names(data.get("tags", []))
	var uses: Variant = data.get("uses", {})
	if uses is Dictionary and not (uses as Dictionary).is_empty():
		v.uses_types.append(StringName(str((uses as Dictionary).get("type", "charges")).to_lower()))
	var uses_list: Variant = data.get("uses_types", [])
	if uses_list is Array:
		for u in uses_list as Array:
			var un := StringName(str(u).to_lower())
			if un != &"" and not v.uses_types.has(un):
				v.uses_types.append(un)
	return v


static func from_registry(definition_id: StringName) -> DeckCardView:
	return from_definition_dict(CardRegistry.definition_data(definition_id), definition_id)


static func _string_names(raw: Variant) -> Array[StringName]:
	var out: Array[StringName] = []
	if raw is Array:
		for x in raw as Array:
			var s := StringName(str(x))
			if s != &"":
				out.append(s)
	return out


static func _lower_names(raw: Variant) -> Array[StringName]:
	var out: Array[StringName] = []
	if raw is Array:
		for x in raw as Array:
			var s := String(x).strip_edges().to_lower()
			if s != "":
				out.append(StringName(s))
	elif raw is String:
		for part in (raw as String).split("."):
			var s := part.strip_edges().to_lower()
			if s != "":
				out.append(StringName(s))
	return out


func has_faction(faction: StringName) -> bool:
	var want := String(faction).to_lower()
	for f in factions:
		if String(f).to_lower() == want:
			return true
	return false


func has_any_faction(want: Array[StringName]) -> bool:
	for f in want:
		if has_faction(f):
			return true
	return false


func has_any_trait(want: Array[StringName]) -> bool:
	for t in want:
		var w := String(t).to_lower()
		for have in traits:
			if String(have) == w:
				return true
	return false


func has_any_tag(want: Array[StringName]) -> bool:
	for t in want:
		var w := String(t).to_lower()
		for have in tags:
			if String(have) == w:
				return true
	return false


func has_any_uses(want: Array[StringName]) -> bool:
	for t in want:
		var w := String(t).to_lower()
		for have in uses_types:
			if String(have) == w:
				return true
	return false
