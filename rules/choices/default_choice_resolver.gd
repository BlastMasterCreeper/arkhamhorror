class_name DefaultChoiceResolver
extends ChoiceResolver

## Headless / AI 默认自动选用（16 §3.1）。
## 不实现 UI 倒计时；deadline_ms 仅保留字段。唯一默认算法见 compute_default。


func resolve(request: ChoiceRequest) -> Variant:
	return compute_default(request)


func resolve_choice(request: ChoiceRequest) -> Dictionary:
	return {"pick": compute_default(request), "used_default": true}


## 规范默认：所有「未显式确认」路径必须落到此函数（Gate / Scripting 回退 / UI 取消）。
static func compute_default(request: ChoiceRequest) -> Variant:
	if request == null:
		return null
	var policy := request.resolved_default_policy()
	match request.kind:
		AhcEnums.ChoiceKind.USE_ABILITY:
			if policy == &"skip":
				return false
			return request.default_index > 0
		AhcEnums.ChoiceKind.OPTIONAL_EFFECT:
			if policy == &"skip":
				return false if request.options.is_empty() else request.options[0]
			if request.options.size() >= 2:
				return request.options[1] if request.default_index > 0 else request.options[0]
			return request.default_index > 0
		AhcEnums.ChoiceKind.ORDER_SIMULTANEOUS:
			if not request.options.is_empty() and request.options[0] is Array:
				return (request.options[0] as Array).duplicate()
			return []
		AhcEnums.ChoiceKind.PICK_TARGET, AhcEnums.ChoiceKind.PICK_OPTION:
			return _pick_single(request)
		AhcEnums.ChoiceKind.TIE_BREAK, AhcEnums.ChoiceKind.SILVER_RULE:
			return _pick_single(request)
		AhcEnums.ChoiceKind.ASSIGN_DAMAGE:
			return request.options.duplicate() if not request.options.is_empty() else []
		AhcEnums.ChoiceKind.ORDER_CARDS:
			if not request.options.is_empty() and request.options[0] is Array:
				return (request.options[0] as Array).duplicate()
			return request.options.duplicate()
		AhcEnums.ChoiceKind.CONFIRM_STEP:
			return true
		AhcEnums.ChoiceKind.PICK_MULTI:
			return _pick_multi(request, policy)
		_:
			return _pick_single(request)


static func _pick_single(request: ChoiceRequest) -> Variant:
	if request.options.is_empty():
		return null
	var idx: int = clampi(request.default_index, 0, request.options.size() - 1)
	return request.options[idx]


## 多选：skip+min0 → []；否则取前 min(max_picks, options)（须 ≥ min_picks）。
static func _pick_multi(request: ChoiceRequest, policy: StringName) -> Variant:
	if request.options.is_empty():
		return []
	if policy == &"skip" and request.min_picks <= 0:
		return []
	var take := clampi(request.max_picks, 0, request.options.size())
	if take < request.min_picks:
		return []
	var out: Array = []
	for i in take:
		out.append(request.options[i])
	return out
