class_name DefaultChoiceResolver
extends ChoiceResolver

## Headless / AI 默认自动选用（16 §3.1–§3.2）。
## 不实现 UI 倒计时；deadline_ms 仅保留字段。
## mode=ASK 与 REGISTRATION_ORDER 在本 resolver 上算法相同（default_index / 原序）；
## RANDOM 在合法选项中抽选。FAVOR/DISFAVOR 后补。

var mode: AhcEnums.AutoChoiceMode = AhcEnums.AutoChoiceMode.ASK
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func resolve(request: ChoiceRequest) -> Variant:
	return compute_for_mode(request, mode, rng)


func resolve_choice(request: ChoiceRequest) -> Dictionary:
	return {"pick": compute_for_mode(request, mode, rng), "used_default": true}


## 规范默认（注册序 / default_index）：所有「未显式确认」回退路径必须落到此函数。
static func compute_default(request: ChoiceRequest) -> Variant:
	return compute_for_mode(
		request, AhcEnums.AutoChoiceMode.REGISTRATION_ORDER, null
	)


static func compute_for_mode(
	request: ChoiceRequest,
	p_mode: AhcEnums.AutoChoiceMode,
	p_rng: RandomNumberGenerator
) -> Variant:
	if request == null:
		return null
	if p_mode == AhcEnums.AutoChoiceMode.RANDOM:
		return _compute_random(request, p_rng)
	return _compute_registration_order(request)


static func _compute_registration_order(request: ChoiceRequest) -> Variant:
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
		AhcEnums.ChoiceKind.ASSIGN_DAMAGE, AhcEnums.ChoiceKind.ASSIGN_HORROR:
			## options = 默认腿表（已合法）；逾期 / headless 原样确认。
			return request.options.duplicate() if not request.options.is_empty() else []
		AhcEnums.ChoiceKind.ORDER_CARDS:
			if not request.options.is_empty() and request.options[0] is Array:
				return (request.options[0] as Array).duplicate()
			return request.options.duplicate()
		AhcEnums.ChoiceKind.CONFIRM_STEP:
			return true
		AhcEnums.ChoiceKind.PICK_MULTI, AhcEnums.ChoiceKind.CHAOS_PICK:
			return _pick_multi(request, policy)
		_:
			return _pick_single(request)


static func _compute_random(
	request: ChoiceRequest,
	p_rng: RandomNumberGenerator
) -> Variant:
	var r := p_rng
	if r == null:
		r = RandomNumberGenerator.new()
		r.randomize()
	var policy := request.resolved_default_policy()
	match request.kind:
		AhcEnums.ChoiceKind.USE_ABILITY:
			## 二值：发动 / 跳过。
			return r.randi_range(0, 1) == 1
		AhcEnums.ChoiceKind.OPTIONAL_EFFECT:
			if request.options.is_empty():
				return false
			return request.options[r.randi_range(0, request.options.size() - 1)]
		AhcEnums.ChoiceKind.ORDER_SIMULTANEOUS:
			var items: Array = []
			if not request.options.is_empty() and request.options[0] is Array:
				items = (request.options[0] as Array).duplicate()
			_shuffle_inplace(items, r)
			return items
		AhcEnums.ChoiceKind.ORDER_CARDS:
			var cards: Array = []
			if not request.options.is_empty() and request.options[0] is Array:
				cards = (request.options[0] as Array).duplicate()
			else:
				cards = request.options.duplicate()
			_shuffle_inplace(cards, r)
			return cards
		AhcEnums.ChoiceKind.ASSIGN_DAMAGE, AhcEnums.ChoiceKind.ASSIGN_HORROR:
			## RANDOM：打乱腿序仍保持各腿 amount（非重摊；真随机重摊后补）。
			var assigns: Array = request.options.duplicate()
			_shuffle_inplace(assigns, r)
			return assigns
		AhcEnums.ChoiceKind.CONFIRM_STEP:
			return true
		AhcEnums.ChoiceKind.PICK_MULTI:
			return _pick_multi_random(request, policy, r)
		_:
			if request.options.is_empty():
				return null
			return request.options[r.randi_range(0, request.options.size() - 1)]


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


static func _pick_multi_random(
	request: ChoiceRequest,
	policy: StringName,
	r: RandomNumberGenerator
) -> Variant:
	if request.options.is_empty():
		return []
	if policy == &"skip" and request.min_picks <= 0:
		return []
	var take := clampi(request.max_picks, 0, request.options.size())
	if take < request.min_picks:
		return []
	var shuffled: Array = request.options.duplicate()
	_shuffle_inplace(shuffled, r)
	var out: Array = []
	for i in take:
		out.append(shuffled[i])
	return out


static func _shuffle_inplace(arr: Array, r: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
