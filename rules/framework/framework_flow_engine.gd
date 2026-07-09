class_name FrameworkFlowEngine
extends RefCounted

signal step_entered(step: AhcEnums.FrameworkStep)
signal player_window_opened(window: AhcEnums.PlayerWindow)
signal round_began(round_number: int)

var _state: GameStateStore
var _events: EventRecordLog
var _log: GameLog
var _scenario: ScenarioSystem
var _enemy: EnemySystem
var _registrations: RegistrationStore
var _game_ctx: GameContext = null

var current_step: AhcEnums.FrameworkStep = AhcEnums.FrameworkStep.SETUP_01_CHOOSE_INVESTIGATORS
var round_number: int = 0
var skip_mythos: bool = false
var waiting_player_window: bool = false
var pending_player_window: AhcEnums.PlayerWindow = AhcEnums.PlayerWindow.PW_INV_BEFORE_ACTION

var player_order: Array[StringName] = []
var investigators_remaining_this_phase: Array[StringName] = []
var pending_action_loop: bool = false
var _setup_complete: bool = false


func _init(
	state: GameStateStore,
	events: EventRecordLog,
	log: GameLog,
	_config: RulesConfig,
	scenario: ScenarioSystem = null,
	enemy: EnemySystem = null,
	registrations: RegistrationStore = null
) -> void:
	_state = state
	_events = events
	_log = log
	_scenario = scenario
	_enemy = enemy
	_registrations = registrations


func bind_game_context(ctx: GameContext) -> void:
	_game_ctx = ctx


func start_setup() -> void:
	_setup_complete = false
	current_step = AhcEnums.FrameworkStep.SETUP_01_CHOOSE_INVESTIGATORS
	_enter_step(current_step)


func advance() -> void:
	if waiting_player_window:
		return
	if not _setup_complete:
		_advance_setup()
		return
	_advance_round_step()


func close_player_window_and_continue() -> void:
	var after_action := pending_player_window == AhcEnums.PlayerWindow.PW_INV_AFTER_ACTION
	waiting_player_window = false
	if after_action and current_step == AhcEnums.FrameworkStep.INV_2_2_1_TAKE_ACTION and not pending_action_loop:
		_goto(AhcEnums.FrameworkStep.INV_2_2_2_TURN_ENDS)
	advance()


func begin_round() -> void:
	round_number += 1
	_state.round_number = round_number
	skip_mythos = round_number == 1
	refresh_player_order()
	round_began.emit(round_number)
	if skip_mythos:
		_goto(AhcEnums.FrameworkStep.INV_2_1_PHASE_BEGINS)
	else:
		_goto(AhcEnums.FrameworkStep.MYTHOS_1_1_PHASE_BEGINS)


func refresh_player_order() -> void:
	player_order = _state.registry.all_investigator_ids()
	if _state.lead_investigator_id != &"" and player_order.has(_state.lead_investigator_id):
		player_order.erase(_state.lead_investigator_id)
		player_order.insert(0, _state.lead_investigator_id)


func is_action_phase() -> bool:
	return current_step == AhcEnums.FrameworkStep.INV_2_2_1_TAKE_ACTION


func on_action_completed(investigator_id: StringName) -> void:
	if not is_action_phase():
		return
	var inv := _state.registry.get_investigator(investigator_id)
	pending_action_loop = inv != null and inv.actions_remaining > 0
	_open_player_window(AhcEnums.PlayerWindow.PW_INV_AFTER_ACTION)


func end_investigator_turn() -> void:
	if not is_action_phase():
		return
	pending_action_loop = false
	_goto(AhcEnums.FrameworkStep.INV_2_2_2_TURN_ENDS)


func advance_until(step: AhcEnums.FrameworkStep, max_hops: int = 256) -> bool:
	var hops := 0
	while current_step != step and hops < max_hops:
		if waiting_player_window:
			close_player_window_and_continue()
		elif is_action_phase():
			return false
		else:
			advance()
		hops += 1
	return current_step == step


func _advance_setup() -> void:
	var next := _next_setup_step(current_step)
	if next == current_step:
		return
	if next == AhcEnums.FrameworkStep.INV_2_1_PHASE_BEGINS:
		_setup_complete = true
		begin_round()
		return
	_goto(next)


func _advance_round_step() -> void:
	if current_step == AhcEnums.FrameworkStep.MYTHOS_1_4_DRAW_ENCOUNTER_EACH:
		_advance_mythos_encounter_draw()
		return
	if current_step == AhcEnums.FrameworkStep.INV_2_2_1_TAKE_ACTION:
		return
	if current_step == AhcEnums.FrameworkStep.ENEMY_3_3_ENGAGED_ATTACKS:
		_advance_enemy_attacks()
		return
	if current_step == AhcEnums.FrameworkStep.UPKEEP_4_5_CHECK_HAND_SIZE:
		_advance_upkeep_hand_check()
		return
	var next := _next_round_step(current_step)
	if next == current_step:
		return
	if current_step == AhcEnums.FrameworkStep.UPKEEP_4_6_PHASE_ENDS:
		begin_round()
		return
	_goto(next)


func _advance_mythos_encounter_draw() -> void:
	if investigators_remaining_this_phase.is_empty():
		_goto(AhcEnums.FrameworkStep.MYTHOS_1_5_PHASE_ENDS)
		return
	var drawer: StringName = investigators_remaining_this_phase[0]
	investigators_remaining_this_phase.remove_at(0)
	if _scenario:
		_scenario.resolve_encounter_draw(drawer)
	if investigators_remaining_this_phase.is_empty():
		_goto(AhcEnums.FrameworkStep.MYTHOS_1_5_PHASE_ENDS)
	else:
		_open_player_window(AhcEnums.PlayerWindow.PW_MYTHOS_AFTER_ENCOUNTER_DRAW)


func _advance_enemy_attacks() -> void:
	if investigators_remaining_this_phase.is_empty():
		_goto(AhcEnums.FrameworkStep.ENEMY_3_4_PHASE_ENDS)
		return
	var inv: StringName = investigators_remaining_this_phase[0]
	investigators_remaining_this_phase.remove_at(0)
	if _enemy:
		_enemy.resolve_phase_attacks_for(inv)
	if investigators_remaining_this_phase.is_empty():
		_goto(AhcEnums.FrameworkStep.ENEMY_3_4_PHASE_ENDS)
	else:
		_open_player_window(AhcEnums.PlayerWindow.PW_ENEMY_BETWEEN_ATTACKS)


func _advance_upkeep_hand_check() -> void:
	if investigators_remaining_this_phase.is_empty():
		_goto(AhcEnums.FrameworkStep.UPKEEP_4_6_PHASE_ENDS)
		return
	var inv_id: StringName = investigators_remaining_this_phase[0]
	investigators_remaining_this_phase.remove_at(0)
	var inv := _state.registry.get_investigator(inv_id)
	if inv and inv.hand.size() > 8:
		inv.hand.resize(8)
	if investigators_remaining_this_phase.is_empty():
		_goto(AhcEnums.FrameworkStep.UPKEEP_4_6_PHASE_ENDS)


func _goto(step: AhcEnums.FrameworkStep) -> void:
	current_step = step
	_enter_step(step)


func _enter_step(step: AhcEnums.FrameworkStep) -> void:
	_on_enter_step(step)
	_record_step()
	step_entered.emit(step)
	_maybe_open_window_for(step)


func _record_step() -> void:
	_events.append_framework(current_step, _state.compute_state_hash())
	_log.log(AhcEnums.LogCategory.FRAMEWORK, "step:%s" % current_step, {"round": round_number})


func _maybe_open_window_for(step: AhcEnums.FrameworkStep) -> void:
	var w = _player_window_for(step)
	if w != null:
		_open_player_window(w)


func _open_player_window(w: AhcEnums.PlayerWindow) -> void:
	pending_player_window = w
	waiting_player_window = true
	player_window_opened.emit(w)


func _on_enter_step(step: AhcEnums.FrameworkStep) -> void:
	if step == AhcEnums.FrameworkStep.MYTHOS_1_2_PLACE_DOOM:
		if _scenario:
			_scenario.place_mythos_doom()
	elif step == AhcEnums.FrameworkStep.MYTHOS_1_3_CHECK_DOOM_THRESHOLD:
		if _scenario:
			_scenario.check_agenda_doom_threshold()
	elif step == AhcEnums.FrameworkStep.MYTHOS_1_4_DRAW_ENCOUNTER_EACH:
		investigators_remaining_this_phase = player_order.duplicate()
	elif step == AhcEnums.FrameworkStep.INV_2_1_PHASE_BEGINS:
		investigators_remaining_this_phase = player_order.duplicate()
	elif step == AhcEnums.FrameworkStep.INV_2_2_TURN_BEGINS:
		_start_next_investigator_turn()
	elif step == AhcEnums.FrameworkStep.INV_2_2_1_TAKE_ACTION:
		pending_action_loop = true
	elif step == AhcEnums.FrameworkStep.INV_2_2_2_TURN_ENDS:
		var inv := _state.registry.get_investigator(_state.active_investigator_id)
		if inv:
			if _game_ctx != null and _game_ctx.stat_emitter != null:
				_game_ctx.stat_emitter.record_turn_end(inv.id)
			inv.is_active_turn = false
		_tick_duration(AhcEnums.DurationAnchorKind.THIS_TURN)
	elif step == AhcEnums.FrameworkStep.INV_2_3_PHASE_ENDS:
		_tick_duration(AhcEnums.DurationAnchorKind.THIS_PHASE)
	elif step == AhcEnums.FrameworkStep.UPKEEP_4_6_PHASE_ENDS:
		_tick_duration(AhcEnums.DurationAnchorKind.THIS_ROUND)
	elif step == AhcEnums.FrameworkStep.ENEMY_3_2_HUNTER_PATROL_MOVE:
		if _enemy:
			_enemy.enemy_phase_3_2_moves()
	elif step == AhcEnums.FrameworkStep.ENEMY_3_3_ENGAGED_ATTACKS:
		if _enemy:
			_enemy.resolve_massive_phase_attacks()
		investigators_remaining_this_phase = player_order.duplicate()
	elif step == AhcEnums.FrameworkStep.UPKEEP_4_3_READY_EXHAUSTED:
		if _enemy and _game_ctx != null:
			_enemy.ready_all_exhausted_enemies(_game_ctx)
	elif step == AhcEnums.FrameworkStep.UPKEEP_4_4_DRAW_AND_RESOURCE:
		_resolve_upkeep_draw_and_resource()
	elif step == AhcEnums.FrameworkStep.UPKEEP_4_5_CHECK_HAND_SIZE:
		investigators_remaining_this_phase = player_order.duplicate()


func _resolve_upkeep_draw_and_resource() -> void:
	var tags: Array[StringName] = [&"framework", &"upkeep_4_4"]
	if _game_ctx != null and _game_ctx.draw_investigator != null and _game_ctx.resource_gain != null:
		for inv_id in player_order:
			_game_ctx.draw_investigator.draw_cards(_game_ctx, inv_id, 1, tags)
			_game_ctx.resource_gain.gain(_game_ctx, inv_id, 1, tags)
		return
	for inv_id in player_order:
		var up_inv := _state.registry.get_investigator(inv_id)
		if up_inv:
			up_inv.resource_pool += 1


func _tick_duration(anchor: AhcEnums.DurationAnchorKind) -> void:
	if _registrations == null:
		return
	var before := _registrations.count()
	_registrations.tick_duration(anchor)
	var removed := before - _registrations.count()
	if removed > 0:
		_log.log(AhcEnums.LogCategory.SYSTEM, "duration_tick", {"anchor": anchor, "removed": removed})


func _start_next_investigator_turn() -> void:
	if investigators_remaining_this_phase.is_empty():
		return
	var inv_id: StringName = investigators_remaining_this_phase[0]
	investigators_remaining_this_phase.remove_at(0)
	_state.active_investigator_id = inv_id
	var inv := _state.registry.get_investigator(inv_id)
	if inv:
		inv.is_active_turn = true
		inv.actions_remaining = 3 + inv.actions_bonus_next_turn - inv.actions_penalty_next_turn
		inv.actions_bonus_next_turn = 0
		inv.actions_penalty_next_turn = 0
	if _game_ctx != null and _game_ctx.stat_emitter != null:
		_game_ctx.stat_emitter.record_turn_begin(inv_id)


func _next_setup_step(step: AhcEnums.FrameworkStep) -> AhcEnums.FrameworkStep:
	match step:
		AhcEnums.FrameworkStep.SETUP_01_CHOOSE_INVESTIGATORS:
			return AhcEnums.FrameworkStep.SETUP_02_APPLY_TRAUMA
		AhcEnums.FrameworkStep.SETUP_02_APPLY_TRAUMA:
			return AhcEnums.FrameworkStep.SETUP_03_CHOOSE_LEAD_INVESTIGATOR
		AhcEnums.FrameworkStep.SETUP_03_CHOOSE_LEAD_INVESTIGATOR:
			return AhcEnums.FrameworkStep.SETUP_04_SHUFFLE_INVESTIGATOR_DECKS
		AhcEnums.FrameworkStep.SETUP_04_SHUFFLE_INVESTIGATOR_DECKS:
			return AhcEnums.FrameworkStep.SETUP_05_ASSEMBLE_TOKEN_POOL
		AhcEnums.FrameworkStep.SETUP_05_ASSEMBLE_TOKEN_POOL:
			return AhcEnums.FrameworkStep.SETUP_06_ASSEMBLE_CHAOS_BAG
		AhcEnums.FrameworkStep.SETUP_06_ASSEMBLE_CHAOS_BAG:
			return AhcEnums.FrameworkStep.SETUP_07_STARTING_RESOURCES
		AhcEnums.FrameworkStep.SETUP_07_STARTING_RESOURCES:
			return AhcEnums.FrameworkStep.SETUP_08_OPENING_HANDS_MULLIGAN
		AhcEnums.FrameworkStep.SETUP_08_OPENING_HANDS_MULLIGAN:
			return AhcEnums.FrameworkStep.SETUP_09_READ_SCENARIO_INTRO
		AhcEnums.FrameworkStep.SETUP_09_READ_SCENARIO_INTRO:
			return AhcEnums.FrameworkStep.SETUP_10_SCENARIO_SETUP
		AhcEnums.FrameworkStep.SETUP_10_SCENARIO_SETUP:
			return AhcEnums.FrameworkStep.SETUP_11_SET_AGENDA_DECK
		AhcEnums.FrameworkStep.SETUP_11_SET_AGENDA_DECK:
			return AhcEnums.FrameworkStep.SETUP_12_SET_ACT_DECK
		AhcEnums.FrameworkStep.SETUP_12_SET_ACT_DECK:
			return AhcEnums.FrameworkStep.SETUP_13_PLACE_SCENARIO_REFERENCE
		AhcEnums.FrameworkStep.SETUP_13_PLACE_SCENARIO_REFERENCE:
			return AhcEnums.FrameworkStep.SETUP_14_GAME_BEGINS_ABOUT
		AhcEnums.FrameworkStep.SETUP_14_GAME_BEGINS_ABOUT:
			return AhcEnums.FrameworkStep.INV_2_1_PHASE_BEGINS
		_:
			return step


func _next_round_step(step: AhcEnums.FrameworkStep) -> AhcEnums.FrameworkStep:
	match step:
		AhcEnums.FrameworkStep.MYTHOS_1_1_PHASE_BEGINS:
			return AhcEnums.FrameworkStep.MYTHOS_1_2_PLACE_DOOM
		AhcEnums.FrameworkStep.MYTHOS_1_2_PLACE_DOOM:
			return AhcEnums.FrameworkStep.MYTHOS_1_3_CHECK_DOOM_THRESHOLD
		AhcEnums.FrameworkStep.MYTHOS_1_3_CHECK_DOOM_THRESHOLD:
			return AhcEnums.FrameworkStep.MYTHOS_1_4_DRAW_ENCOUNTER_EACH
		AhcEnums.FrameworkStep.MYTHOS_1_5_PHASE_ENDS:
			return AhcEnums.FrameworkStep.INV_2_1_PHASE_BEGINS
		AhcEnums.FrameworkStep.INV_2_1_PHASE_BEGINS:
			if investigators_remaining_this_phase.is_empty():
				return AhcEnums.FrameworkStep.INV_2_3_PHASE_ENDS
			return AhcEnums.FrameworkStep.INV_2_2_TURN_BEGINS
		AhcEnums.FrameworkStep.INV_2_2_TURN_BEGINS:
			return AhcEnums.FrameworkStep.INV_2_2_1_TAKE_ACTION
		AhcEnums.FrameworkStep.INV_2_2_2_TURN_ENDS:
			if investigators_remaining_this_phase.is_empty():
				return AhcEnums.FrameworkStep.INV_2_3_PHASE_ENDS
			return AhcEnums.FrameworkStep.INV_2_2_TURN_BEGINS
		AhcEnums.FrameworkStep.INV_2_3_PHASE_ENDS:
			return AhcEnums.FrameworkStep.ENEMY_3_1_PHASE_BEGINS
		AhcEnums.FrameworkStep.ENEMY_3_1_PHASE_BEGINS:
			return AhcEnums.FrameworkStep.ENEMY_3_2_HUNTER_PATROL_MOVE
		AhcEnums.FrameworkStep.ENEMY_3_2_HUNTER_PATROL_MOVE:
			return AhcEnums.FrameworkStep.ENEMY_3_3_ENGAGED_ATTACKS
		AhcEnums.FrameworkStep.ENEMY_3_4_PHASE_ENDS:
			return AhcEnums.FrameworkStep.UPKEEP_4_1_PHASE_BEGINS
		AhcEnums.FrameworkStep.UPKEEP_4_1_PHASE_BEGINS:
			return AhcEnums.FrameworkStep.UPKEEP_4_2_FLIP_MINI_CARDS
		AhcEnums.FrameworkStep.UPKEEP_4_2_FLIP_MINI_CARDS:
			return AhcEnums.FrameworkStep.UPKEEP_4_3_READY_EXHAUSTED
		AhcEnums.FrameworkStep.UPKEEP_4_3_READY_EXHAUSTED:
			return AhcEnums.FrameworkStep.UPKEEP_4_4_DRAW_AND_RESOURCE
		AhcEnums.FrameworkStep.UPKEEP_4_4_DRAW_AND_RESOURCE:
			return AhcEnums.FrameworkStep.UPKEEP_4_5_CHECK_HAND_SIZE
		AhcEnums.FrameworkStep.UPKEEP_4_6_PHASE_ENDS:
			return AhcEnums.FrameworkStep.MYTHOS_1_1_PHASE_BEGINS
		_:
			return step


func _player_window_for(step: AhcEnums.FrameworkStep) -> Variant:
	match step:
		AhcEnums.FrameworkStep.MYTHOS_1_1_PHASE_BEGINS:
			return AhcEnums.PlayerWindow.PW_MYTHOS_AFTER_BEGIN
		AhcEnums.FrameworkStep.MYTHOS_1_5_PHASE_ENDS:
			return AhcEnums.PlayerWindow.PW_MYTHOS_BEFORE_END
		AhcEnums.FrameworkStep.INV_2_1_PHASE_BEGINS:
			return AhcEnums.PlayerWindow.PW_INV_AFTER_PHASE_BEGIN
		AhcEnums.FrameworkStep.INV_2_2_1_TAKE_ACTION:
			return AhcEnums.PlayerWindow.PW_INV_BEFORE_ACTION
		AhcEnums.FrameworkStep.INV_2_2_2_TURN_ENDS:
			return AhcEnums.PlayerWindow.PW_INV_BEFORE_TURN_END
		AhcEnums.FrameworkStep.ENEMY_3_2_HUNTER_PATROL_MOVE:
			return AhcEnums.PlayerWindow.PW_ENEMY_AFTER_MOVE
		AhcEnums.FrameworkStep.UPKEEP_4_3_READY_EXHAUSTED:
			return AhcEnums.PlayerWindow.PW_UPKEEP_AFTER_READY
		_:
			return null
