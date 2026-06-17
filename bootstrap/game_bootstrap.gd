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
	ctx.choices = ChoiceResolver.new()
	ctx.effects = EffectResolutionGraph.new(ctx.state, ctx.events, ctx.log)
	ctx.registrations = RegistrationStore.new()
	ctx.mutator = StateMutator.new(ctx.state)
	ctx.resource_gain = ResourceGainService.new(ctx.mutator)
	ctx.card_abilities = CardAbilityService.new(ctx.mutator)
	ctx.enter_hand = EnterHandService.new(ctx.card_abilities)
	ctx.draw_investigator = DrawInvestigatorService.new(ctx.mutator, ctx.enter_hand)
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
	ctx.scenario = ScenarioSystem.new(ctx.state, ctx.log)
	ctx.enemy = EnemySystem.new(ctx.state, ctx.log)
	ctx.skill_tests = SkillTestEngine.new(
		ctx.state, ctx.events, ctx.log, ctx.modifiers, ctx.mutator, ctx.timing
	)
	ctx.combat = CombatResolver.new(ctx.state, ctx.log, ctx.timing)
	ctx.framework = FrameworkFlowEngine.new(
		ctx.state, ctx.events, ctx.log, ctx.config, ctx.scenario, ctx.enemy, ctx.registrations
	)
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
	ctx.sequences.bind_game_context(ctx)
	return ctx


static func register_enter_hand_test_definitions() -> void:
	CardRegistry.register_definition(&"plain_weakness", {})
	CardRegistry.register_revelation(
		&"rev_take_horror",
		&"revelation:0",
		func(bind: AbilityBindContext) -> CompositionNode:
			return CompositionNode.take_horror(bind.controller_id, 1)
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
