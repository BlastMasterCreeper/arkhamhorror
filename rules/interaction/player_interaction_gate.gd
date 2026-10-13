class_name PlayerInteractionGate
extends RefCounted

## Rules 层唯一玩家决策入口（headless / UI 共用）。见 docs/design/16-player-interaction.md
## 默认自动选用：未显式确认时一律 DefaultChoiceResolver.compute_default（无 deadline UI）。

var resolver: ChoiceResolver = DefaultChoiceResolver.new()
## 最近一次 ask 是否采用了默认（测试 / 日志可读）。
var last_used_default: bool = false


func ask(request: ChoiceRequest, ctx: GameContext) -> Variant:
	if request == null:
		return null
	var outcome: Dictionary = {}
	if resolver != null:
		outcome = resolver.resolve_choice(request)
	else:
		outcome = {
			"pick": DefaultChoiceResolver.compute_default(request),
			"used_default": true,
		}
	var picked: Variant = outcome.get("pick")
	var used_default := bool(outcome.get("used_default", true))
	## 显式应答为 null 且仍须有值 → 回落默认（流程不挂死）。
	if picked == null:
		var fallback: Variant = DefaultChoiceResolver.compute_default(request)
		if fallback != null or _null_is_valid_default(request):
			picked = fallback
			used_default = true
	last_used_default = used_default
	_record_choice(request, picked, used_default, ctx)
	return picked


func _null_is_valid_default(request: ChoiceRequest) -> bool:
	if request == null:
		return false
	return (
		request.kind == AhcEnums.ChoiceKind.PICK_MULTI and request.min_picks <= 0
	)


func _record_choice(
	request: ChoiceRequest,
	picked: Variant,
	used_default: bool,
	ctx: GameContext
) -> void:
	var payload := {
		"kind": request.kind,
		"prompt_id": request.prompt_id,
		"decider": request.decider_id,
		"picked": picked,
		"used_default": used_default,
		"default_policy": request.resolved_default_policy(),
		"default_index": request.default_index,
		"deadline_ms": request.deadline_ms,
	}
	if ctx != null and ctx.log != null:
		ctx.log.log(AhcEnums.LogCategory.SYSTEM, "interaction:choice", payload)
	if ctx != null and ctx.events != null:
		ctx.events.append(AhcEnums.EventRecordKind.INTERACTION_CHOICE, payload)


func ask_use_ability(
	handler: Variant,
	controller_id: StringName,
	ctx: GameContext,
	default_use: bool = false
) -> bool:
	var req: ChoiceRequest = ChoiceRequest.new()
	req.kind = AhcEnums.ChoiceKind.USE_ABILITY
	req.decider_id = controller_id
	req.prompt_id = &"reaction:use"
	req.options = [handler]
	req.context = {"handler": handler}
	req.default_index = 1 if default_use else 0
	req.default_policy = &"first_option" if default_use else &"skip"
	var pick: Variant = ask(req, ctx)
	if pick is bool:
		return pick
	return pick != null


func ask_optional_effect(
	controller_id: StringName,
	prompt_id: StringName,
	ctx: GameContext,
	default_use: bool = false
) -> bool:
	var req: ChoiceRequest = ChoiceRequest.new()
	req.kind = AhcEnums.ChoiceKind.OPTIONAL_EFFECT
	req.decider_id = controller_id
	req.prompt_id = prompt_id
	req.options = [false, true]
	req.default_index = 1 if default_use else 0
	req.default_policy = &"first_option" if default_use else &"skip"
	var pick: Variant = ask(req, ctx)
	if pick is bool:
		return pick
	return bool(pick)


func ask_order_simultaneous(
	items: Array,
	lead_id: StringName,
	prompt_id: StringName,
	ctx: GameContext
) -> Array:
	if items.size() <= 1:
		return items.duplicate()
	var req: ChoiceRequest = ChoiceRequest.new()
	req.kind = AhcEnums.ChoiceKind.ORDER_SIMULTANEOUS
	req.decider_id = lead_id
	req.prompt_id = prompt_id
	req.options = [items.duplicate()]
	req.context = {"count": items.size()}
	req.default_policy = &"first_option"
	var pick: Variant = ask(req, ctx)
	if pick is Array:
		return pick
	return items.duplicate()


func ask_pick_option(
	option_ids: Array,
	controller_id: StringName,
	prompt_id: StringName,
	ctx: GameContext
) -> Variant:
	if option_ids.is_empty():
		return null
	var req: ChoiceRequest = ChoiceRequest.new()
	req.kind = AhcEnums.ChoiceKind.PICK_OPTION
	req.decider_id = controller_id
	req.prompt_id = prompt_id
	req.options = option_ids.duplicate()
	req.default_index = 0
	req.default_policy = &"first_option"
	## 唯一选项也走 ask → 默认自动选用并记 used_default。
	return ask(req, ctx)


func ask_pick_target(
	candidates: Array,
	controller_id: StringName,
	prompt_id: StringName,
	ctx: GameContext
) -> Variant:
	if candidates.is_empty():
		return null
	var req: ChoiceRequest = ChoiceRequest.new()
	req.kind = AhcEnums.ChoiceKind.PICK_TARGET
	req.decider_id = controller_id
	req.prompt_id = prompt_id
	req.options = candidates.duplicate()
	req.default_index = 0
	req.default_policy = &"first_option"
	req.deadline_ms = -1
	var pick: Variant = ask(req, ctx)
	if pick == null:
		return DefaultChoiceResolver.compute_default(req)
	return pick


## 通用选择：按 SelectionSpec 建 ChoiceRequest，确认后由调用方 ChoiceBind。
func ask_selection(
	spec: SelectionSpec,
	candidates: Array,
	controller_id: StringName,
	ctx: GameContext
) -> Variant:
	if spec == null:
		return null
	## 不足 min_picks → 无法满足基数（min=0 时允许空候选 → 选无）。
	if candidates.size() < spec.min_picks:
		return null
	if candidates.is_empty():
		return [] if spec.min_picks <= 0 else null
	var decider := controller_id
	if spec.decider == &"lead" and ctx != null and ctx.state != null:
		var lead: StringName = ctx.state.lead_investigator_id
		if lead != &"":
			decider = lead
	var req := spec.to_choice_request(candidates, decider)
	var pick: Variant = ask(req, ctx)
	if pick == null:
		if spec.default_policy == &"skip":
			return [] if spec.min_picks <= 0 else null
		pick = DefaultChoiceResolver.compute_default(req)
		last_used_default = true
	if spec.choice_kind == AhcEnums.ChoiceKind.PICK_MULTI:
		return _normalize_multi_pick(pick, candidates, spec)
	return pick


func _normalize_multi_pick(pick: Variant, candidates: Array, spec: SelectionSpec) -> Variant:
	var list: Array = []
	if pick is Array:
		list = (pick as Array).duplicate()
	elif pick != null:
		list = [pick]
	if list.size() > spec.max_picks:
		list = list.slice(0, spec.max_picks)
	if list.size() < spec.min_picks:
		return null
	return list
