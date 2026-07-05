class_name TriggeredAbilityService
extends RefCounted

var _ctx: GameContext
var _descriptors: Array[TriggeredAbilityDescriptor] = []


func bind_game_context(ctx: GameContext) -> void:
	_ctx = ctx


func register(descriptor: TriggeredAbilityDescriptor) -> void:
	if descriptor == null or _ctx == null or _ctx.sequences == null:
		return
	_descriptors.append(descriptor)
	_install_handler(descriptor)


func install_card(controller_id: StringName, card_id: StringName) -> void:
	if _ctx == null or _ctx.state == null:
		return
	var card := _ctx.state.registry.get_card(card_id)
	if card == null:
		return
	var definition_id := card.id.definition_id
	var bind := AbilityBindContext.new()
	bind.controller_id = controller_id
	bind.card_id = card_id
	for unit in CardRegistry.triggered_units_at(definition_id):
		register(
			TriggeredAbilityDescriptor.from_registry_unit(
				unit, controller_id, card_id, definition_id, bind
			)
		)


func resolve(descriptor: TriggeredAbilityDescriptor) -> Dictionary:
	if descriptor == null or _ctx == null:
		return {"ok": false, "error": "no_context"}
	if not _should_use(descriptor):
		return {"ok": false, "error": "declined"}
	if descriptor.composition == null:
		return {"ok": false, "error": "invalid_intent"}
	if descriptor.ability_kind == TriggeredAbilityDescriptor.AbilityKind.FORCED:
		return _resolve_forced(descriptor)
	return _resolve_via_initiation(descriptor)


func _resolve_forced(descriptor: TriggeredAbilityDescriptor) -> Dictionary:
	var source_id := descriptor.source_id
	if source_id != &"" and _ctx.sequences != null:
		_ctx.sequences.begin_ability_resolution(source_id)
	if _ctx.composition != null:
		_ctx.composition.execute(descriptor.composition)
	if source_id != &"" and _ctx.sequences != null:
		_ctx.sequences.end_ability_resolution()
	return {"ok": true}


func _resolve_via_initiation(descriptor: TriggeredAbilityDescriptor) -> Dictionary:
	if _ctx.initiation == null:
		return {"ok": false, "error": "no_initiation"}
	var intent := _build_intent(descriptor)
	var source_id := descriptor.source_id
	if source_id != &"" and _ctx.sequences != null:
		_ctx.sequences.begin_ability_resolution(source_id)
	var result := _ctx.initiation.initiate(intent, _ctx)
	if source_id != &"" and _ctx.sequences != null:
		_ctx.sequences.end_ability_resolution()
	return result


func _should_use(descriptor: TriggeredAbilityDescriptor) -> bool:
	if _ctx == null or _ctx.interaction == null:
		return true
	if descriptor.is_player_initiated():
		return _ctx.interaction.ask_use_ability(
			descriptor, descriptor.controller_id, _ctx
		)
	if descriptor.optional:
		return _ctx.interaction.ask_optional_effect(
			descriptor.controller_id, descriptor.id, _ctx
		)
	return true


func _build_intent(descriptor: TriggeredAbilityDescriptor) -> InitiationIntent:
	var intent: InitiationIntent
	if descriptor.provokes_aoo():
		intent = InitiationIntent.action_ability(
			descriptor.controller_id,
			descriptor.composition,
			descriptor.action_cost
		)
	else:
		intent = InitiationIntent.ability(descriptor.controller_id, descriptor.composition)
		intent.resource_cost = descriptor.resource_cost
		intent.action_cost = descriptor.action_cost
	intent.source_id = descriptor.source_id
	intent.ability_id = descriptor.id
	return intent


func _install_handler(descriptor: TriggeredAbilityDescriptor) -> void:
	var handler := SequenceHandler.new()
	handler.match_kind = descriptor.match_kind
	handler.phase = descriptor.phase
	handler.source_id = descriptor.source_id
	handler.controller_id = descriptor.controller_id
	handler.player_initiated = descriptor.is_player_initiated()
	match descriptor.ability_kind:
		TriggeredAbilityDescriptor.AbilityKind.FORCED:
			handler.tier = SequenceHandler.Tier.FORCED
		TriggeredAbilityDescriptor.AbilityKind.FREE:
			handler.tier = SequenceHandler.Tier.TRIGGERED
		_:
			handler.tier = SequenceHandler.Tier.TRIGGERED
	var desc := descriptor
	handler.callback = func() -> void:
		resolve(desc)
	_ctx.sequences.register_handler(handler)
