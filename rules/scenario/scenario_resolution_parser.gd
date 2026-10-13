class_name ScenarioResolutionParser
extends RefCounted

## 从 Act/Agenda b 面文本解析 `(→R#)` / `(->R#)`。


static func parse(text: String) -> int:
	if text.is_empty():
		return -1
	var re := RegEx.new()
	if re.compile("(?i)(→|->)R(\\d+)") != OK:
		return -1
	var m := re.search(text)
	if m == null:
		return -1
	return int(m.get_string(2))
