class_name GameSimulator
extends RefCounted

var state: GameStateStore
var registrations: RegistrationStore
var mutator: StateMutator
var last_step_created: bool = false


static func from_context(ctx: GameContext) -> GameSimulator:
	var sim := GameSimulator.new()
	sim.state = _duplicate_state(ctx.state)
	sim.registrations = ctx.registrations.duplicate_store()
	sim.mutator = StateMutator.new(sim.state)
	sim.mutator.bind_registration_store(sim.registrations)
	return sim


static func _duplicate_state(src: GameStateStore) -> GameStateStore:
	var copy := GameStateStore.new()
	copy.round_number = src.round_number
	copy.lead_investigator_id = src.lead_investigator_id
	copy.active_investigator_id = src.active_investigator_id
	copy.doom_on_agenda = src.doom_on_agenda
	copy.agenda_threshold = src.agenda_threshold
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
	return copy
