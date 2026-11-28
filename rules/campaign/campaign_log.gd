class_name CampaignLog
extends RefCounted

## 剧本日志：精确短语记录；crossed-out 忽略。

var notes: Array[String] = []
var crossed_out: Dictionary = {} ## phrase → true
## 键值型条目（创伤以外的结构化记录，如 earned story assets）。
var entries: Dictionary = {}


func record(phrase: String) -> void:
	var p := phrase.strip_edges()
	if p == "" or crossed_out.get(p, false):
		return
	if not notes.has(p):
		notes.append(p)


func cross_out(phrase: String) -> void:
	var p := phrase.strip_edges()
	if p == "":
		return
	crossed_out[p] = true


func has_note(phrase: String) -> bool:
	var p := phrase.strip_edges()
	return notes.has(p) and not crossed_out.get(p, false)


func set_entry(key: StringName, value: Variant) -> void:
	entries[key] = value


func get_entry(key: StringName, default: Variant = null) -> Variant:
	return entries.get(key, default)
