class_name CardTextCatalog
extends RefCounted

## 简中译文字段查找 · 缺译回退 CardRegistry / 英文 imported JSON。

static var _zh: Dictionary = {}
static var _loaded: bool = false


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_load_zh("res://data/arkhamdb/translations/zh-cn/pack/core/core_2026_encounter.json")
	_load_zh("res://data/arkhamdb/translations/zh-cn/pack/core/core_2026.json")


static func _load_zh(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		for item in parsed as Array:
			if item is Dictionary:
				var code := int((item as Dictionary).get("code", 0))
				if code > 0:
					_zh[str(code)] = (item as Dictionary).duplicate(true)


static func zh_entry(definition_id: StringName) -> Dictionary:
	ensure_loaded()
	var key := str(definition_id)
	# 去掉前导零以外的纯数字 code
	var raw: Variant = _zh.get(key, {})
	if raw is Dictionary:
		return raw as Dictionary
	return {}


static func display_title(definition_id: StringName) -> String:
	var zh := zh_entry(definition_id)
	var name_zh := str(zh.get("name", ""))
	if name_zh != "":
		return name_zh
	var t := CardRegistry.title(definition_id)
	return t if t != "" else str(definition_id)


static func display_text(definition_id: StringName, face_b: bool = false) -> String:
	var zh := zh_entry(definition_id)
	if face_b:
		var back_zh := str(zh.get("back_text", ""))
		if back_zh != "":
			return back_zh
		return CardRegistry.back_text(definition_id)
	var text_zh := str(zh.get("text", ""))
	if text_zh != "":
		return text_zh
	return str(CardRegistry.definition_data(definition_id).get("text", ""))


static func display_flavor(definition_id: StringName, face_b: bool = false) -> String:
	var zh := zh_entry(definition_id)
	if face_b:
		return str(zh.get("back_flavor", ""))
	return str(zh.get("flavor", ""))


static func display_back_name(definition_id: StringName) -> String:
	var zh := zh_entry(definition_id)
	var bn := str(zh.get("back_name", ""))
	if bn != "":
		return bn
	return CardRegistry.back_name(definition_id)


static func to_bbcode(raw: String) -> String:
	## 轻度清洗 ArkhamDB 标记 → RichTextLabel BBCode。
	var s := raw
	s = s.replace("[action]", "[b]行动[/b] ")
	s = s.replace("[fast]", "[b]快速[/b] ")
	s = s.replace("[reaction]", "[b]反应[/b] ")
	s = s.replace("[willpower]", "意志")
	s = s.replace("[intellect]", "智力")
	s = s.replace("[combat]", "战力")
	s = s.replace("[agility]", "敏捷")
	s = s.replace("[skull]", "骷髅")
	s = s.replace("[cultist]", "邪教徒")
	s = s.replace("[tablet]", "石板")
	s = s.replace("[elder_thing]", "古神")
	s = s.replace("[per_investigator]", "每位调查员")
	s = s.replace("<b>", "[b]").replace("</b>", "[/b]")
	s = s.replace("<i>", "[i]").replace("</i>", "[/i]")
	s = s.replace("\n", "\n")
	return s
