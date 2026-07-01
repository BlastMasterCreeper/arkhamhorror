class_name ChoiceResolver
extends RefCounted

## Headless / UI 共用决策接口。子类：DefaultChoiceResolver、ScriptingChoiceResolver。


func resolve(request: ChoiceRequest) -> Variant:
	if request == null or request.options.is_empty():
		return null
	var idx := clampi(request.default_index, 0, request.options.size() - 1)
	return request.options[idx]
