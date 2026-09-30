class_name CandidateFilter
extends RefCounted

## 实体候选过滤规格（静态）。见 docs/design/21-selection-spec.md


var entity: StringName = &"enemy"
var zones: Array[StringName] = []
var at: StringName = &""
var traits: Array[StringName] = []
var trait_exclude: Array[StringName] = []
var keywords: Array[StringName] = []
var keyword_exclude: Array[StringName] = []
var card_types: Array[StringName] = []
## null = 不限；true = 仅横置；false = 仅未横置。
var exhausted: Variant = null
## null = 不限；true/false = 是否与任何人交战；"controller"/"self" = 与控制者交战。
var engaged: Variant = null
## 非空时覆盖 engaged：&"controller" = 与 controller 交战；其它 = 指定调查员 id。
var engaged_with: StringName = &""
var exclude_massive: bool = true
var exclude_aloof: bool = false
## Fight：剔除 aloof 且未与任何人交战（engaged aloof 仍合法）。
var exclude_aloof_unengaged: bool = false
var owned_by: StringName = &"any"
var preset: StringName = &""
## N 层数值谓词（§3.1.2）；元素为 Dictionary：on/field/op/value 或 stat_query。
var preds: Array = []


static func from_preset(preset_id: StringName) -> CandidateFilter:
	var f := CandidateFilter.new()
	f.preset = preset_id
	match preset_id:
		&"enemy_at_connecting":
			f.entity = &"enemy"
			f.at = &"connecting"
			f.exclude_massive = true
		&"enemy_at_controller_location":
			f.entity = &"enemy"
			f.at = &"controller_location"
			f.exclude_massive = true
		&"enemy_fight_target":
			## 基础 Fight：同地点；含 massive；剔未交战 aloof。
			f.entity = &"enemy"
			f.at = &"controller_location"
			f.exclude_massive = false
			f.exclude_aloof_unengaged = true
		&"enemy_evade_target":
			## 基础 Evade：仅与自己交战（地点不限；通常同地）。
			f.entity = &"enemy"
			f.at = &""
			f.exclude_massive = false
			f.engaged_with = &"controller"
		&"location_investigate_target":
			f.entity = &"location"
			f.at = &"controller_location"
		&"location_connecting":
			f.entity = &"location"
			f.at = &"connecting"
		_:
			f.entity = &"enemy"
			f.at = preset_id
	return f


static func from_variant(raw: Variant) -> CandidateFilter:
	if raw is CandidateFilter:
		return raw as CandidateFilter
	if typeof(raw) == TYPE_STRING or typeof(raw) == TYPE_STRING_NAME:
		return from_preset(StringName(str(raw)))
	if typeof(raw) != TYPE_DICTIONARY:
		return from_preset(&"enemy_at_connecting")
	var d: Dictionary = raw
	if d.has("preset") and str(d.get("preset", "")) != "":
		var base := from_preset(StringName(str(d["preset"])))
		_merge_dict(base, d)
		return base
	var f := CandidateFilter.new()
	_merge_dict(f, d)
	return f


static func _merge_dict(f: CandidateFilter, d: Dictionary) -> void:
	if d.has("entity"):
		f.entity = StringName(str(d["entity"]))
	if d.has("at"):
		f.at = StringName(str(d["at"]))
	if d.has("owned_by"):
		f.owned_by = StringName(str(d["owned_by"]))
	if d.has("exclude_massive"):
		f.exclude_massive = bool(d["exclude_massive"])
	if d.has("exclude_aloof"):
		f.exclude_aloof = bool(d["exclude_aloof"])
	if d.has("exclude_aloof_unengaged"):
		f.exclude_aloof_unengaged = bool(d["exclude_aloof_unengaged"])
	if d.has("exhausted"):
		f.exhausted = d["exhausted"]
	if d.has("engaged"):
		f.engaged = d["engaged"]
	if d.has("engaged_with"):
		f.engaged_with = StringName(str(d["engaged_with"]))
	f.zones = _to_name_array(d.get("zones", f.zones))
	f.traits = _to_name_array(d.get("traits", f.traits))
	f.trait_exclude = _to_name_array(d.get("trait_exclude", f.trait_exclude))
	f.keywords = _to_name_array(d.get("keywords", f.keywords))
	f.keyword_exclude = _to_name_array(d.get("keyword_exclude", f.keyword_exclude))
	f.card_types = _to_name_array(d.get("card_types", f.card_types))
	if d.has("preds") and d["preds"] is Array:
		f.preds = (d["preds"] as Array).duplicate(true)


static func _to_name_array(raw: Variant) -> Array[StringName]:
	var out: Array[StringName] = []
	if raw is Array:
		for item in raw:
			out.append(StringName(str(item)))
	elif typeof(raw) == TYPE_STRING or typeof(raw) == TYPE_STRING_NAME:
		var s := str(raw)
		if s != "":
			out.append(StringName(s))
	return out
