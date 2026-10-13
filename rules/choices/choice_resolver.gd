class_name ChoiceResolver
extends RefCounted

## Headless / UI 共用决策接口。子类：DefaultChoiceResolver、ScriptingChoiceResolver、UiChoiceResolver。
## 默认自动选用见 DefaultChoiceResolver.compute_default（16 §3.1；无 deadline UI）。


func resolve(request: ChoiceRequest) -> Variant:
	return DefaultChoiceResolver.compute_default(request)


## 统一出口：pick + used_default（显式应答 false；自动默认 true）。
func resolve_choice(request: ChoiceRequest) -> Dictionary:
	var pick: Variant = resolve(request)
	if pick == null and request != null:
		pick = DefaultChoiceResolver.compute_default(request)
		return {"pick": pick, "used_default": true}
	## 基类 / Default：整次 resolve 即默认路径。
	return {"pick": pick, "used_default": true}
