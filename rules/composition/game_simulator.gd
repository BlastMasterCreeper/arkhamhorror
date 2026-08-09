class_name GameSimulator
extends RefCounted

var state: GameStateStore
var registrations: RegistrationStore
var mutator: StateMutator
var last_step_created: bool = false
var last_step_engaged_investigator: StringName = &""
var last_resolved_location: StringName = &""
var last_skill_test_fail_by: int = 0
var for_each_inv_override: StringName = &""


static func from_context(ctx: GameContext) -> GameSimulator:
	var sim := GameSimulator.new()
	sim.state = _duplicate_state(ctx.state)
	sim.registrations = ctx.registrations.duplicate_store()
	sim._bind_mutator()
	return sim


func fork() -> GameSimulator:
	var copy := GameSimulator.new()
	copy.state = _duplicate_state(state)
	copy.registrations = registrations.duplicate_store()
	copy.last_skill_test_fail_by = last_skill_test_fail_by
	copy.for_each_inv_override = for_each_inv_override
	copy._bind_mutator()
	return copy


func _bind_mutator() -> void:
	mutator = StateMutator.new(state)
	mutator.bind_registration_store(registrations)


static func _duplicate_state(src: GameStateStore) -> GameStateStore:
	var copy := GameStateStore.new()
	copy.round_number = src.round_number
	copy.lead_investigator_id = src.lead_investigator_id
	copy.active_investigator_id = src.active_investigator_id
	copy.doom_on_agenda = src.doom_on_agenda
	copy.agenda_threshold = src.agenda_threshold
	copy.current_agenda_number = src.current_agenda_number
	copy.current_act_number = src.current_act_number
	copy.act_clue_threshold = src.act_clue_threshold
	copy.victory_display = src.victory_display.duplicate()
	copy.current_act_card_id = src.current_act_card_id
	copy.current_agenda_card_id = src.current_agenda_card_id
	copy.act_deck = src.act_deck.duplicate()
	copy.agenda_deck = src.agenda_deck.duplicate()
	copy.removed_from_game = src.removed_from_game.duplicate()
	copy.scenario_resolution = src.scenario_resolution
	copy.per_investigator_count = src.per_investigator_count
	copy.set_aside = src.set_aside.duplicate()
	copy.scenario_reference_card_id = src.scenario_reference_card_id
	copy.scenario_layout_installed = src.scenario_layout_installed
	copy.setup_game_begins_resolved = src.setup_game_begins_resolved
	copy.deferred_setup_revelations = src.deferred_setup_revelations.duplicate()
	copy.encounter_deck = src.encounter_deck.duplicate()
	copy.encounter_discard = src.encounter_discard.duplicate()
	copy.token_pool = TokenPool.new()
	copy.token_pool.damage_available = src.token_pool.damage_available
	copy.token_pool.horror_available = src.token_pool.horror_available
	copy.token_pool.clue_available = src.token_pool.clue_available
	copy.token_pool.resource_available = src.token_pool.resource_available
	for inv_id in src.registry.all_investigator_ids():
		var inv_src := src.registry.get_investigator(inv_id)
		var inv := InvestigatorState.new()
		inv.id = inv_src.id
		inv.definition_id = inv_src.definition_id
		inv.resource_pool = inv_src.resource_pool
		inv.actions_remaining = inv_src.actions_remaining
		inv.skill_willpower = inv_src.skill_willpower
		inv.skill_intellect = inv_src.skill_intellect
		inv.skill_combat = inv_src.skill_combat
		inv.skill_agility = inv_src.skill_agility
		inv.location_tag = inv_src.location_tag
		inv.damage_taken = inv_src.damage_taken
		inv.horror_taken = inv_src.horror_taken
		inv.clues_on_card = inv_src.clues_on_card
		inv.eliminated = inv_src.eliminated
		inv.resigned = inv_src.resigned
		inv.physical_trauma = inv_src.physical_trauma
		inv.mental_trauma = inv_src.mental_trauma
		inv.deck = inv_src.deck.duplicate()
		inv.hand = inv_src.hand.duplicate()
		inv.discard = inv_src.discard.duplicate()
		copy.registry.register_investigator(inv)
	for card_id in src.registry.all_card_ids():
		var card_src: CardInstance = src.registry.get_card(card_id)
		var card := CardInstance.new()
		card.id = card_src.id
		card.owner_id = card_src.owner_id
		card.controller_id = card_src.controller_id
		card.zone = card_src.zone
		card.zone_index = card_src.zone_index
		copy.registry.register_card(card)
	for loc_id in src.registry.all_location_ids():
		var loc_src := src.registry.get_location(loc_id)
		var loc := LocationState.new()
		loc.id = loc_src.id
		loc.shroud = loc_src.shroud
		loc.clues = loc_src.clues
		loc.revealed = loc_src.revealed
		loc.connections = loc_src.connections.duplicate()
		copy.registry.register_location(loc)
	return copy
