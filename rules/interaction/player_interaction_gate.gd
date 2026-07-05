class_name PlayerInteractionGate
extends RefCounted

## Rules 层唯一玩家决策入口（headless / UI 共用）。见 docs/design/16-player-interaction.md

var resolver: ChoiceResolver = DefaultChoiceResolver.new()


func ask(request: ChoiceRequest, ctx: GameContext) -> Variant:
	if request == null:
		return null
	var picked: Variant = resolver.resolve(request)
	if ctx != null and ctx.log != null:
		ctx.log.log(
			AhcEnums.LogCategory.SYSTEM,
			"interaction:choice",
			{
				"kind": request.kind,
				"prompt_id": request.prompt_id,
				"decider": request.decider_id,
				"picked": picked,
			}
		)
	return picked


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


func ask_pick_target(
	candidates: Array,
	controller_id: StringName,
	prompt_id: StringName,
	ctx: GameContext
) -> Variant:
	if candidates.is_empty():
		return null
	if candidates.size() == 1:
		return candidates[0]
	var req: ChoiceRequest = ChoiceRequest.new()
	req.kind = AhcEnums.ChoiceKind.PICK_TARGET
	req.decider_id = controller_id
	req.prompt_id = prompt_id
	req.options = candidates.duplicate()
	var pick: Variant = ask(req, ctx)
	return pick
