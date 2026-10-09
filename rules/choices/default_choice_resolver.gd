class_name DefaultChoiceResolver
extends ChoiceResolver

## Headless / AI 默认：ORDER 保持原序；其余取 default_index 或首项。


func resolve(request: ChoiceRequest) -> Variant:
	if request == null:
		return null
	match request.kind:
		AhcEnums.ChoiceKind.USE_ABILITY:
			return request.default_index > 0
		AhcEnums.ChoiceKind.OPTIONAL_EFFECT:
			if request.options.size() >= 2:
				return request.options[1] if request.default_index > 0 else request.options[0]
			return request.default_index > 0
		AhcEnums.ChoiceKind.ORDER_SIMULTANEOUS:
			if not request.options.is_empty() and request.options[0] is Array:
				return (request.options[0] as Array).duplicate()
			return []
		AhcEnums.ChoiceKind.PICK_TARGET, AhcEnums.ChoiceKind.PICK_OPTION:
			return _pick_single(request)
		AhcEnums.ChoiceKind.TIE_BREAK:
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
			return _pick_multi(request)
		AhcEnums.ChoiceKind.SILVER_RULE:
			if request.options.is_empty():
				return null
			return request.options[0]
		_:
			return _pick_single(request)


func _pick_single(request: ChoiceRequest) -> Variant:
	if request.options.is_empty():
		return null
	var idx: int = clampi(request.default_index, 0, request.options.size() - 1)
	return request.options[idx]


## 多选默认：skip+min0 → []；否则取前 min(max_picks, options) 项（须 ≥ min_picks）。
func _pick_multi(request: ChoiceRequest) -> Variant:
	if request.options.is_empty():
		return []
	var policy: StringName = &"first_option"
	if typeof(request.context) == TYPE_DICTIONARY and request.context.has("default_policy"):
		policy = StringName(str(request.context["default_policy"]))
	if policy == &"skip" and request.min_picks <= 0:
		return []
	var take := clampi(request.max_picks, 0, request.options.size())
	if take < request.min_picks:
		return []
	var out: Array = []
	for i in take:
		out.append(request.options[i])
	return out
