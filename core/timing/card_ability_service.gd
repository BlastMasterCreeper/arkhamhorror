class_name CardAbilityService
extends RefCounted

var _mutator: StateMutator


func _init(mutator: StateMutator = null) -> void:
	_mutator = mutator


func bind_mutator(mutator: StateMutator) -> void:
	_mutator = mutator


func has_revelation(game_ctx: GameContext, card_id: StringName) -> bool:
	var card := _get_card(game_ctx, card_id)
	if card == null:
		return false
	return CardRegistry.has_revelation(card.id.definition_id)


func resolve_revelations(
	game_ctx: GameContext,
	controller_id: StringName,
	card_id: StringName,
	flow_id: StringName = &"",
	defer_limbo_finalize: bool = false
) -> bool:
	if game_ctx == null or game_ctx.composition == null:
		return false
	var depth := game_ctx.sequences.depth() if game_ctx.sequences != null else -1
	var trigger_kind := &""
	if game_ctx.sequences != null and game_ctx.sequences.current_trigger() != null:
		trigger_kind = game_ctx.sequences.current_trigger().kind
	## I2：显现体只在已压栈入口 seq（enter_hand / encounter.revelation）内解释。
	if game_ctx.sequences == null or depth <= 0:
		# #region agent log
		_agent_dbg("A", "card_ability_service.gd:resolve_revelations", "vacuum_refused", {"card": str(card_id), "controller": str(controller_id), "flow_id": str(flow_id), "depth": depth, "trigger": str(trigger_kind)})
		# #endregion
		push_error("CardAbilityService.resolve_revelations: no sequence frame; vacuum refused")
		return false
	# #region agent log
	_agent_dbg("B", "card_ability_service.gd:resolve_revelations", "on_stack", {"card": str(card_id), "controller": str(controller_id), "flow_id": str(flow_id), "depth": depth, "trigger": str(trigger_kind), "defer": defer_limbo_finalize})
	# #endregion
	var card := _get_card(game_ctx, card_id)
	if card == null:
		return false
	var units := CardRegistry.revelation_units_at(card.id.definition_id)
	if game_ctx.config != null and game_ctx.config.enter_hand_timing != null:
		units = game_ctx.config.enter_hand_timing.order_ability_units(units)
	if units.is_empty():
		return false
	var bind_dict := {"card_id": card_id}
	if (
		game_ctx.memory != null
		and game_ctx.memory.is_sequence_cancelled(flow_id, bind_dict)
	):
		return true
	var bind := AbilityBindContext.new()
	bind.flow_id = flow_id
	bind.controller_id = controller_id
	bind.card_id = card_id
	for unit in units:
		var builder: Callable = unit.get("builder", Callable())
		if not builder.is_valid():
			continue
		var node: CompositionNode = builder.call(bind)
		if node == null:
			continue
		node.provenance = AbilityUnitRef.from_card_ability(
			flow_id,
			card.id.definition_id,
			unit.get("ability_id", &"") as StringName,
			card_id
		)
		game_ctx.composition.execute(node)
	if not defer_limbo_finalize and _mutator != null:
		_mutator.finalize_limbo_discard(card_id, controller_id)
	return true


# #region agent log
func _agent_dbg(hyp: String, loc: String, msg: String, data: Dictionary) -> void:
	var path := "/opt/cursor/logs/debug.log"
	var f := FileAccess.open(path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify({
		"hypothesisId": hyp,
		"location": loc,
		"message": msg,
		"data": data,
		"timestamp": Time.get_ticks_msec(),
	}))
	f.close()
# #endregion


func _get_card(game_ctx: GameContext, card_id: StringName) -> CardInstance:
	if game_ctx == null or game_ctx.state == null:
		return null
	return game_ctx.state.registry.get_card(card_id)
