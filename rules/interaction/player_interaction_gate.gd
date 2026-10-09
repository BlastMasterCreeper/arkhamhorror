class_name PlayerInteractionGate
extends RefCounted

## Rules 层唯一玩家决策入口（headless / UI 共用）。见 docs/design/16-player-interaction.md

var resolver: ChoiceResolver = DefaultChoiceResolver.new()


func ask(request: ChoiceRequest, ctx: GameContext) -> Variant:
	if request == null:
		return null
	var picked: Variant = resolver.resolve(request)
	var used_default := _looks_like_default(request, picked)
	if ctx != null and ctx.log != null:
		ctx.log.log(
			AhcEnums.LogCategory.SYSTEM,
			"interaction:choice",
			{
				"kind": request.kind,
				"prompt_id": request.prompt_id,
				"decider": request.decider_id,
				"picked": picked,
				"used_default": used_default,
				"deadline_ms": request.deadline_ms,
			}
		)
	return picked


func _looks_like_default(request: ChoiceRequest, picked: Variant) -> bool:
	if request.options.is_empty() or picked == null:
		return true
	## USE_ABILITY 等返回 bool，options 里是 handler——不能 bool == Object。
	if typeof(picked) == TYPE_BOOL:
		return (picked == true) == (request.default_index > 0)
	var idx := clampi(request.default_index, 0, request.options.size() - 1)
	var opt: Variant = request.options[idx]
	if typeof(picked) != typeof(opt):
		return false
	return is_same(picked, opt) or str(picked) == str(opt)


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
	if option_ids.size() == 1:
		return option_ids[0]
	var req: ChoiceRequest = ChoiceRequest.new()
	req.kind = AhcEnums.ChoiceKind.PICK_OPTION
	req.decider_id = controller_id
	req.prompt_id = prompt_id
	req.options = option_ids.duplicate()
	var pick: Variant = ask(req, ctx)
	return pick


func ask_pick_target(
	candidates: Array,
	controller_id: StringName,
	prompt_id: StringName,
	ctx: GameContext
) -> Variant:
	if candidates.is_empty():
		return null
	## 唯一候选 = 默认确认；多候选走有限期确认（逾期/headless → default_index）。
	var req: ChoiceRequest = ChoiceRequest.new()
	req.kind = AhcEnums.ChoiceKind.PICK_TARGET
	req.decider_id = controller_id
	req.prompt_id = prompt_id
	req.options = candidates.duplicate()
	req.default_index = 0
	req.deadline_ms = -1
	if candidates.size() == 1:
		return candidates[0]
	var pick: Variant = ask(req, ctx)
	if pick == null:
		return candidates[0]
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
	## 单选且唯一候选 → 默认确认（仍返回值供 bind）。
	if spec.max_picks <= 1 and candidates.size() == 1:
		return candidates[0]
	## exactly N 且候选恰为 N → 默认确认全集。
	if (
		spec.choice_kind == AhcEnums.ChoiceKind.PICK_MULTI
		and spec.min_picks == spec.max_picks
		and candidates.size() == spec.min_picks
	):
		return candidates.duplicate()
	var req := spec.to_choice_request(candidates, decider)
	var pick: Variant = ask(req, ctx)
	if pick == null:
		if spec.default_policy == &"skip":
			return [] if spec.min_picks <= 0 else null
		if spec.max_picks <= 1:
			return candidates[0]
		return _default_multi_slice(candidates, spec)
	if spec.choice_kind == AhcEnums.ChoiceKind.PICK_MULTI:
		return _normalize_multi_pick(pick, candidates, spec)
	return pick


func _default_multi_slice(candidates: Array, spec: SelectionSpec) -> Array:
	var take := clampi(spec.max_picks, 0, candidates.size())
	if take < spec.min_picks:
		return []
	var out: Array = []
	for i in take:
		out.append(candidates[i])
	return out


func _normalize_multi_pick(pick: Variant, candidates: Array, spec: SelectionSpec) -> Variant:
	var list: Array = []
	if pick is Array:
		list = (pick as Array).duplicate()
	elif pick != null:
		list = [pick]
	## 截断至 max_picks；不足 min → 视为无效。
	if list.size() > spec.max_picks:
		list = list.slice(0, spec.max_picks)
	if list.size() < spec.min_picks:
		return null
	return list
