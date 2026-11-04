class_name DeckOptionRule
extends RefCounted

## 单条 ArkhamDB `deck_options[]` 条目的结构化规则。

enum Role {
	ALLOW,
	LIMIT,
	FORBID,
	CHOICE,
	DECK_CONSTRAINT,
	META,
}

var role: Role = Role.ALLOW
var level_min: int = 0
var level_max: int = 5
var has_level: bool = false
var factions: Array[StringName] = []
var traits: Array[StringName] = []
var types: Array[StringName] = []
var tags: Array[StringName] = []
var uses_types: Array[StringName] = []
var text_patterns: Array[String] = []
## null = 不限；true/false = 必须匹配 permanent 布尔。
var permanent_required: Variant = null
var limit: int = -1
var error: String = ""
var is_not: bool = false
var name: String = ""
var id: StringName = &""
var faction_select: Array[StringName] = []
var option_select: Array = []
var deck_size_select: Array[String] = []
var atleast_factions: int = 0
var atleast_min: int = 0
var ignore_match: bool = false
var base_level_min: int = 0
var base_level_max: int = 0
var has_base_level: bool = false


static func from_dict(raw: Dictionary) -> DeckOptionRule:
	var r := DeckOptionRule.new()
	r.is_not = bool(raw.get("not", false))
	r.error = str(raw.get("error", ""))
	r.name = str(raw.get("name", ""))
	r.id = StringName(str(raw.get("id", "")))
	r.ignore_match = bool(raw.get("ignore_match", false))
	if raw.has("limit"):
		r.limit = int(raw.get("limit"))
	if raw.has("level") and raw.get("level") is Dictionary:
		var lv: Dictionary = raw.get("level")
		r.has_level = true
		r.level_min = int(lv.get("min", 0))
		r.level_max = int(lv.get("max", 5))
	if raw.has("base_level") and raw.get("base_level") is Dictionary:
		var bl: Dictionary = raw.get("base_level")
		r.has_base_level = true
		r.base_level_min = int(bl.get("min", 0))
		r.base_level_max = int(bl.get("max", 0))
	r.factions = _names(raw.get("faction", []))
	r.traits = _names(raw.get("trait", []))
	r.types = _names(raw.get("type", []))
	r.tags = _names(raw.get("tag", []))
	r.uses_types = _names(raw.get("uses", []))
	r.faction_select = _names(raw.get("faction_select", []))
	if raw.has("text") and raw.get("text") is Array:
		for t in raw.get("text") as Array:
			r.text_patterns.append(str(t))
	if raw.has("permanent"):
		r.permanent_required = bool(raw.get("permanent"))
	if raw.has("option_select") and raw.get("option_select") is Array:
		r.option_select = (raw.get("option_select") as Array).duplicate(true)
	if raw.has("deck_size_select") and raw.get("deck_size_select") is Array:
		for s in raw.get("deck_size_select") as Array:
			r.deck_size_select.append(str(s))
	if raw.has("atleast") and raw.get("atleast") is Dictionary:
		var al: Dictionary = raw.get("atleast")
		r.atleast_factions = int(al.get("factions", 0))
		r.atleast_min = int(al.get("min", 0))
	r.role = _infer_role(r)
	return r


func has_access_predicate() -> bool:
	return (
		not factions.is_empty()
		or not traits.is_empty()
		or not types.is_empty()
		or not tags.is_empty()
		or not uses_types.is_empty()
		or not text_patterns.is_empty()
		or permanent_required != null
		or (has_level and limit >= 0 and factions.is_empty()) ## Dunwich 越级池：仅 level+limit
	)


func has_atleast() -> bool:
	return atleast_factions > 0 or atleast_min > 0


static func _infer_role(r: DeckOptionRule) -> Role:
	if not r.faction_select.is_empty() or not r.option_select.is_empty() or not r.deck_size_select.is_empty():
		return Role.CHOICE
	if r.is_not:
		return Role.FORBID
	## Lola 等：同条含 ALLOW 谓词 + atleast → 主角色仍按准入；atleast 在 Profile 侧另挂。
	if r.limit >= 0 and r.has_access_predicate():
		return Role.LIMIT
	if r.has_access_predicate():
		return Role.ALLOW
	if r.has_atleast():
		return Role.DECK_CONSTRAINT
	return Role.META


static func _names(raw: Variant) -> Array[StringName]:
	var out: Array[StringName] = []
	if raw is Array:
		for x in raw as Array:
			var s := String(x).strip_edges().to_lower()
			if s != "":
				out.append(StringName(s))
	return out


func matches_card(card: DeckCardView) -> bool:
	if card == null:
		return false
	if has_level:
		if card.level < level_min or card.level > level_max:
			return false
	if not factions.is_empty() and not card.has_any_faction(factions):
		return false
	if not traits.is_empty() and not card.has_any_trait(traits):
		return false
	if not types.is_empty():
		var ct := String(card.card_type).to_lower()
		var ok := false
		for t in types:
			if String(t) == ct:
				ok = true
				break
		if not ok:
			return false
	if not tags.is_empty() and not card.has_any_tag(tags):
		return false
	if not uses_types.is_empty() and not card.has_any_uses(uses_types):
		return false
	if permanent_required != null and card.permanent != bool(permanent_required):
		return false
	## `text` 正则只在导入期打 `tags`；运行时有 tag 谓词则已覆盖，裸 text 条目视为不可运行时匹配。
	if not text_patterns.is_empty() and tags.is_empty():
		return false
	return true


## 将 faction_select / option_select 解析为具体 ALLOW/LIMIT 规则。
func resolve_choice(choice_value: Variant) -> Array[DeckOptionRule]:
	var out: Array[DeckOptionRule] = []
	if not faction_select.is_empty():
		var chosen := String(choice_value).to_lower()
		if chosen == "":
			return out
		var allowed := false
		for f in faction_select:
			if String(f) == chosen:
				allowed = true
				break
		if not allowed:
			return out
		var resolved := _clone_as_access()
		resolved.factions = [StringName(chosen)] as Array[StringName]
		resolved.faction_select.clear()
		resolved.role = Role.LIMIT if limit >= 0 else Role.ALLOW
		out.append(resolved)
		return out
	if not option_select.is_empty():
		var cid := String(choice_value)
		for opt in option_select:
			if not opt is Dictionary:
				continue
			var d: Dictionary = opt
			if str(d.get("id", "")) != cid and str(d.get("name", "")) != cid:
				continue
			var resolved2 := DeckOptionRule.from_dict(d)
			## 选型子项继承父级 limit/type 若子项未写。
			if resolved2.limit < 0 and limit >= 0:
				resolved2.limit = limit
			if resolved2.types.is_empty() and not types.is_empty():
				resolved2.types = types.duplicate()
			if resolved2.role == Role.ALLOW and resolved2.limit >= 0:
				resolved2.role = Role.LIMIT
			out.append(resolved2)
			return out
	return out


func _clone_as_access() -> DeckOptionRule:
	var r := DeckOptionRule.new()
	r.role = role
	r.level_min = level_min
	r.level_max = level_max
	r.has_level = has_level
	r.factions = factions.duplicate()
	r.traits = traits.duplicate()
	r.types = types.duplicate()
	r.tags = tags.duplicate()
	r.uses_types = uses_types.duplicate()
	r.text_patterns = text_patterns.duplicate()
	r.permanent_required = permanent_required
	r.limit = limit
	r.error = error
	r.name = name
	r.id = id
	return r
