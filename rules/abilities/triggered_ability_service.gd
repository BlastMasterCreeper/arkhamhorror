class_name TriggeredAbilityService
extends RefCounted

var _ctx: GameContext
var _descriptors: Array[TriggeredAbilityDescriptor] = []


func bind_game_context(ctx: GameContext) -> void:
	_ctx = ctx


func register(descriptor: TriggeredAbilityDescriptor) -> void:
	if descriptor == null or _ctx == null:
		return
	for existing in _descriptors:
		if existing != null and existing.source_id == descriptor.source_id and existing.id == descriptor.id:
			return
	_descriptors.append(descriptor)
	if descriptor.uses_timing_handler() and _ctx.sequences != null:
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


func uninstall_by_source(source_id: StringName) -> void:
	if source_id == &"" or _ctx == null:
		return
	if _ctx.sequences != null:
		_ctx.sequences.unregister_handlers_by_source(source_id)
	for i in range(_descriptors.size() - 1, -1, -1):
		if _descriptors[i].source_id == source_id:
			_descriptors.remove_at(i)


func list_free_abilities(controller_id: StringName) -> Array[TriggeredAbilityDescriptor]:
	var out: Array[TriggeredAbilityDescriptor] = []
	for desc in _descriptors:
		if desc == null:
			continue
		if desc.ability_kind != TriggeredAbilityDescriptor.AbilityKind.FREE_TRIGGERED:
			continue
		if desc.controller_id != controller_id:
			continue
		if not is_free_eligible(desc):
			continue
		out.append(desc)
	return out


func is_free_eligible(descriptor: TriggeredAbilityDescriptor) -> bool:
	if descriptor == null or _ctx == null or _ctx.framework == null or _ctx.state == null:
		return false
	if descriptor.ability_kind != TriggeredAbilityDescriptor.AbilityKind.FREE_TRIGGERED:
		return false
	if not _ctx.framework.waiting_player_window:
		return false
	var window: AhcEnums.PlayerWindow = _ctx.framework.pending_player_window
	if not _window_allows(descriptor, window):
		return false
	if descriptor.source_id != &"":
		var card := _ctx.state.registry.get_card(descriptor.source_id)
		if card == null:
			return false
		if card.zone != AhcEnums.Zone.PLAY_AREA and card.zone != AhcEnums.Zone.THREAT_AREA:
			return false
		if card.exhausted:
			return false
	return true


## Player Window 内已选定的免费触发能力；跳过二次 ask。
func activate_free(ability_id: StringName) -> Dictionary:
	var descriptor := _find_by_id(ability_id)
	if descriptor == null:
		return {"ok": false, "error": "unknown_ability"}
	if descriptor.ability_kind != TriggeredAbilityDescriptor.AbilityKind.FREE_TRIGGERED:
		return {"ok": false, "error": "not_free"}
	if not is_free_eligible(descriptor):
		return {"ok": false, "error": "not_eligible"}
	if descriptor.composition == null:
		return {"ok": false, "error": "invalid_intent"}
	return _resolve_via_initiation(descriptor)


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
		_:
			handler.tier = SequenceHandler.Tier.TRIGGERED
	var desc := descriptor
	handler.callback = func() -> void:
		resolve(desc)
	_ctx.sequences.register_handler(handler)


func _find_by_id(ability_id: StringName) -> TriggeredAbilityDescriptor:
	for desc in _descriptors:
		if desc != null and desc.id == ability_id:
			return desc
	return null


func _window_allows(
	descriptor: TriggeredAbilityDescriptor,
	window: AhcEnums.PlayerWindow
) -> bool:
	var constraint := descriptor.window
	if constraint == &"" or constraint == &"any_player_window":
		return true
	if constraint == &"during_your_turn":
		if not _is_investigation_player_window(window):
			return false
		return _ctx.state.active_investigator_id == descriptor.controller_id
	return true


func _is_investigation_player_window(window: AhcEnums.PlayerWindow) -> bool:
	match window:
		AhcEnums.PlayerWindow.PW_INV_AFTER_PHASE_BEGIN, \
		AhcEnums.PlayerWindow.PW_INV_BEFORE_ACTION, \
		AhcEnums.PlayerWindow.PW_INV_AFTER_ACTION, \
		AhcEnums.PlayerWindow.PW_INV_BEFORE_TURN_END:
			return true
		_:
			return false
