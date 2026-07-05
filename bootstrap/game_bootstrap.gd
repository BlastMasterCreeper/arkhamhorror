class_name GameBootstrap
extends RefCounted


static func create(p_seed: int = 0, config: RulesConfig = null) -> GameContext:
	if p_seed != 0:
		seed(p_seed)
	var ctx := GameContext.new()
	ctx.config = config if config else RulesConfig.new()
	ctx.state = GameStateStore.new()
	ctx.log = GameLog.new()
	ctx.events = EventRecordLog.new()
	ctx.memory = RulesMemory.new()
	ctx.timing = TimingBus.new(ctx.log)
	ctx.sequences = ResolutionSequenceStack.new(ctx.log, ctx.events, ctx.memory)
	ctx.choices = DefaultChoiceResolver.new()
	ctx.interaction = PlayerInteractionGate.new()
	ctx.interaction.resolver = ctx.choices
	ctx.effects = EffectResolutionGraph.new(ctx.state, ctx.events, ctx.log)
	ctx.registrations = RegistrationStore.new()
	ctx.stat_projections = StatProjectionStore.new()
	ctx.stat_projections.bind(ctx.events, ctx.state)
	ctx.stat_emitter = GameStatEmitter.new(ctx.events, ctx.state, ctx.stat_projections)
	ctx.registrations.bind_stat_projections(ctx.stat_projections)
	ctx.mutator = StateMutator.new(ctx.state)
	ctx.mutator.bind_registration_store(ctx.registrations)
	ctx.card_abilities = CardAbilityService.new(ctx.mutator)
	ctx.sequence_catalog = SequenceCatalog.new()
	SequenceCatalogBootstrap.register_builtin(ctx.sequence_catalog, ctx.mutator, ctx.card_abilities)
	ctx.resource_gain = ResourceGainService.new(ctx.sequence_catalog)
	ctx.draw_investigator = DrawInvestigatorService.new(ctx.sequence_catalog)
	ctx.draw_encounter = DrawEncounterService.new(ctx.sequence_catalog)
	ctx.action_sequences = ActionSequenceService.new(ctx.sequence_catalog)
	ctx.modifiers = ModifierEngine.new(ctx.registrations)
	ctx.composition = CompositionExecutor.new(
		ctx.state, ctx.registrations, ctx.mutator, ctx.log
	)
	ctx.composition.bind_game_context(ctx)
	ctx.listeners = ListenerDispatcher.new(ctx.registrations, ctx.composition)
	ctx.timing.bind_listeners(ctx.listeners)
	ctx.legality = InitiationLegalityChecker.new()
	ctx.initiation = AbilityInitiationPipeline.new(
		ctx.state, ctx.events, ctx.effects, ctx.composition
	)
	ctx.triggered_abilities = TriggeredAbilityService.new()
	ctx.scenario = ScenarioSystem.new(ctx.state, ctx.log)
	ctx.scenario.bind_context(ctx)
	ctx.enemy = EnemySystem.new(ctx.state, ctx.log)
	ctx.skill_tests = SkillTestEngine.new(
		ctx.state, ctx.events, ctx.log, ctx.modifiers, ctx.mutator, ctx.timing
	)
	ctx.combat = CombatResolver.new(ctx.state, ctx.log, ctx.timing)
	ctx.framework = FrameworkFlowEngine.new(
		ctx.state, ctx.events, ctx.log, ctx.config, ctx.scenario, ctx.enemy, ctx.registrations
	)
	ctx.framework.bind_game_context(ctx)
	ctx.actions = ActionSystem.new(
		ctx.state,
		ctx.events,
		ctx.initiation,
		ctx.log,
		ctx.framework,
		ctx.skill_tests,
		ctx.combat,
		ctx.mutator
	)
	ctx.actions.bind_game_context(ctx)
	ctx.initiation.bind_game_context(ctx)
	ctx.triggered_abilities.bind_game_context(ctx)
	ctx.sequences.bind_game_context(ctx)
	ctx.effects.bind_game_context(ctx)
	return ctx


static func register_enter_hand_test_definitions() -> void:
	CardRegistry.register_definition(&"plain_weakness", {})
	CardRegistry.register_revelation(
		&"rev_take_horror",
		&"revelation:0",
		func(bind: AbilityBindContext) -> CompositionNode:
			return CompositionNode.adjust_marker(
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.HORROR_TAKEN),
				1
			)
	)
	CardRegistry.register_definition(
		&"rev_limbo_discard",
		{
			"enter_zone": AhcEnums.Zone.LIMBO,
			"limbo_discard_pile": &"owner_discard",
		}
	)
	CardRegistry.register_revelation(
		&"rev_limbo_discard",
		&"revelation:0",
		func(_bind: AbilityBindContext) -> CompositionNode:
			return CompositionNode.seq([])
	)


static func add_test_card_to_deck(ctx: GameContext, inv_id: StringName, definition_id: StringName = &"test_card") -> StringName:
	var instance_id := ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, instance_id, definition_id)
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = inv_id
	card.controller_id = inv_id
	card.zone = AhcEnums.Zone.DECK
	ctx.state.registry.register_card(card)
	var inv := ctx.state.registry.get_investigator(inv_id)
	if inv:
		inv.deck.append(instance_id)
	return instance_id


static func add_test_card_to_discard(
	ctx: GameContext,
	inv_id: StringName,
	definition_id: StringName = &"test_card"
) -> StringName:
	var instance_id := ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, instance_id, definition_id)
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = inv_id
	card.controller_id = inv_id
	card.zone = AhcEnums.Zone.DISCARD
	ctx.state.registry.register_card(card)
	var inv := ctx.state.registry.get_investigator(inv_id)
	if inv:
		inv.discard.append(instance_id)
	return instance_id


static func add_skill_card_to_hand(
	ctx: GameContext,
	inv_id: StringName,
	skill: AhcEnums.SkillType,
	definition_id: StringName = &"test_skill",
	max_committed: int = -1
) -> StringName:
	var instance_id := ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, instance_id, definition_id)
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = inv_id
	card.controller_id = inv_id
	card.zone = AhcEnums.Zone.HAND
	card.max_committed_per_test = max_committed
	card.skill_icons[_skill_icon_key(skill)] = 1
	ctx.state.registry.register_card(card)
	var inv := ctx.state.registry.get_investigator(inv_id)
	if inv:
		inv.hand.append(instance_id)
	return instance_id


static func setup_chaos_bag(ctx: GameContext, tokens: Array[ChaosToken]) -> void:
	ctx.state.chaos_bag.clear()
	for token in tokens:
		ctx.state.chaos_bag.add_token(token)


static func setup_investigator_at_location(
	ctx: GameContext,
	inv_id: StringName,
	location_tag: StringName = &"test_loc",
	skills: Dictionary = {}
) -> void:
	var inv := InvestigatorState.new()
	inv.id = inv_id
	inv.definition_id = StringName("def_%s" % inv_id)
	inv.location_tag = location_tag
	inv.skill_willpower = int(skills.get("willpower", 3))
	inv.skill_intellect = int(skills.get("intellect", 3))
	inv.skill_combat = int(skills.get("combat", 3))
	inv.skill_agility = int(skills.get("agility", 3))
	ctx.state.registry.register_investigator(inv)


static func setup_minimal_investigator(ctx: GameContext, inv_id: StringName) -> void:
	setup_investigator_at_location(ctx, inv_id, &"test_loc")
	setup_test_location(ctx, &"test_loc")
	var inv := ctx.state.registry.get_investigator(inv_id)
	if inv:
		inv.actions_remaining = 3
		inv.resource_pool = 5
	ctx.lead_investigator_id = inv_id
	ctx.active_investigator_id = inv_id
	ctx.state.lead_investigator_id = inv_id
	ctx.state.active_investigator_id = inv_id


static func _skill_icon_key(skill: AhcEnums.SkillType) -> StringName:
	match skill:
		AhcEnums.SkillType.WILLPOWER:
			return &"willpower"
		AhcEnums.SkillType.INTELLECT:
			return &"intellect"
		AhcEnums.SkillType.COMBAT:
			return &"combat"
		AhcEnums.SkillType.AGILITY:
			return &"agility"
	return &""


static func add_encounter_card_to_deck(
	ctx: GameContext,
	definition_id: StringName,
	keywords: Array = [],
	extra_def: Dictionary = {}
) -> StringName:
	var instance_id := ctx.state.registry.allocate_instance_id(&"enc_card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, instance_id, definition_id)
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"encounter"
	card.controller_id = &"encounter"
	card.zone = AhcEnums.Zone.DECK
	ctx.state.registry.register_card(card)
	ctx.state.encounter_deck.append(instance_id)
	var def_data: Dictionary = {
		"card_type": &"treachery",
		"limbo_discard_pile": &"encounter_discard",
	}
	def_data.merge(extra_def, true)
	if not keywords.is_empty():
		def_data["keywords"] = keywords
	CardRegistry.register_definition(definition_id, def_data)
	return instance_id


static func add_encounter_card_to_discard(
	ctx: GameContext,
	definition_id: StringName,
	keywords: Array = [],
	extra_def: Dictionary = {}
) -> StringName:
	var instance_id := ctx.state.registry.allocate_instance_id(&"enc_card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, instance_id, definition_id)
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"encounter"
	card.controller_id = &"encounter"
	card.zone = AhcEnums.Zone.DISCARD
	ctx.state.registry.register_card(card)
	ctx.state.encounter_discard.append(instance_id)
	var def_data: Dictionary = {
		"card_type": &"treachery",
		"limbo_discard_pile": &"encounter_discard",
	}
	def_data.merge(extra_def, true)
	if not keywords.is_empty():
		def_data["keywords"] = keywords
	CardRegistry.register_definition(definition_id, def_data)
	return instance_id


static func add_encounter_enemy_to_deck(
	ctx: GameContext,
	definition_id: StringName,
	opts: Dictionary = {}
) -> StringName:
	var keywords: Array = opts.get("keywords", [])
	var extra := {
		"card_type": &"enemy",
		"aloof": opts.get("aloof", false),
		"enemy": opts.get(
			"enemy",
			{"fight": opts.get("fight", 2), "evade": opts.get("evade", 2), "health": 1}
		),
	}
	var spawn_instruction = opts.get("spawn_instruction", null)
	if spawn_instruction is SpawnInstructionSpec:
		extra["spawn_instruction"] = spawn_instruction
	var prey_instruction = opts.get("prey_instruction", null)
	if prey_instruction is PreyInstructionSpec:
		extra["prey_instruction"] = prey_instruction
	if opts.get("prey", false):
		extra["keywords"] = keywords.duplicate()
		if not (extra["keywords"] as Array).has(&"prey"):
			(extra["keywords"] as Array).append(&"prey")
	return add_encounter_card_to_deck(ctx, definition_id, keywords, extra)


static func add_investigator_weakness_to_deck(
	ctx: GameContext,
	inv_id: StringName,
	definition_id: StringName,
	card_type: StringName = &"asset",
	extra_def: Dictionary = {}
) -> StringName:
	var instance_id := ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, instance_id, definition_id)
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = inv_id
	card.controller_id = inv_id
	card.zone = AhcEnums.Zone.DECK
	ctx.state.registry.register_card(card)
	var inv := ctx.state.registry.get_investigator(inv_id)
	if inv:
		inv.deck.append(instance_id)
	var def_data: Dictionary = {"card_type": card_type, "is_weakness": true}
	def_data.merge(extra_def, true)
	CardRegistry.register_definition(definition_id, def_data)
	return instance_id


static func setup_test_location(
	ctx: GameContext,
	location_id: StringName,
	shroud: int = 2,
	clues: int = 1
) -> void:
	var loc := LocationState.new()
	loc.id = location_id
	loc.shroud = shroud
	loc.clues = clues
	ctx.state.registry.register_location(loc)


static func connect_locations(
	ctx: GameContext,
	from_id: StringName,
	to_id: StringName,
	bidirectional: bool = true
) -> void:
	var from_loc := ctx.state.registry.get_location(from_id)
	var to_loc := ctx.state.registry.get_location(to_id)
	if from_loc and not from_loc.connections.has(to_id):
		from_loc.connections.append(to_id)
	if bidirectional and to_loc and not to_loc.connections.has(from_id):
		to_loc.connections.append(from_id)


static func setup_test_enemy(
	ctx: GameContext,
	enemy_id: StringName,
	location_tag: StringName = &"test_loc",
	fight: int = 2,
	evade: int = 2,
	engaged_with: StringName = &"",
	aloof: bool = false,
	massive: bool = false
) -> void:
	var enemy := EnemyState.new()
	enemy.id = enemy_id
	enemy.location_tag = location_tag
	enemy.fight = fight
	enemy.evade = evade
	enemy.engaged_with = engaged_with
	enemy.aloof = aloof
	enemy.massive = massive
	ctx.state.registry.register_enemy(enemy)


static func run_setup_through_game_begins(ctx: GameContext) -> void:
	ctx.framework.start_setup()
	var guard := 0
	while ctx.framework.current_step != AhcEnums.FrameworkStep.INV_2_1_PHASE_BEGINS:
		guard += 1
		if guard > 32:
			push_error("Setup loop guard tripped")
			break
		if ctx.framework.waiting_player_window:
			ctx.framework.close_player_window_and_continue()
		else:
			ctx.framework.advance()
