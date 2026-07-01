class_name ScriptingChoiceResolver
extends ChoiceResolver

## 测试脚本：按 prompt_id 或顺序队列应答。

var _queue: Array = []
var _by_prompt: Dictionary = {}
var _cursor: int = 0


func _init(script: Array = []) -> void:
	for entry in script:
		if entry is Dictionary:
			var pid: Variant = entry.get("prompt_id", &"")
			if pid != &"":
				_by_prompt[pid] = entry.get("pick")
			else:
				_queue.append(entry.get("pick"))


func resolve(request: ChoiceRequest) -> Variant:
	if request != null and _by_prompt.has(request.prompt_id):
		return _by_prompt[request.prompt_id]
	if _cursor < _queue.size():
		var pick: Variant = _queue[_cursor]
		_cursor += 1
		return pick
	return DefaultChoiceResolver.new().resolve(request)
