class_name SandboxLabs
extends RefCounted

## 沙盒预设局面 · 非完整战役流程。


static func lab_names() -> PackedStringArray:
	return PackedStringArray([
		"烈火渐起 · 开局",
		"Agenda3 + 弃牌堆 Fire!",
		"Act1 翻面后",
		"遭遇抽牌台",
	])


static func create_context(lab_index: int, seed: int = 42) -> GameContext:
	var ctx := GameBootstrap.create(seed, GameBootstrap.config_spreading_flames())
	GameBootstrap.setup_minimal_investigator(ctx, &"inv_1")
	# SF setup 会覆盖地点；先清掉测试地点依赖
	GameBootstrap.run_setup_through_game_begins(ctx)
	GameBootstrap.setup_chaos_bag(ctx, [ChaosToken.numeric(0)])
	var inv := ctx.state.registry.get_investigator(&"inv_1")
	if inv != null:
		inv.skill_willpower = 9
		inv.skill_intellect = 9
		inv.skill_combat = 9
		inv.skill_agility = 9
		inv.actions_remaining = 3
	match lab_index:
		1:
			_advance_to_agenda3(ctx)
		2:
			_flip_act1(ctx)
		3:
			_encounter_draw_lab(ctx)
		_:
			pass
	return ctx


static func _advance_to_agenda3(ctx: GameContext) -> void:
	ctx.state.doom_on_agenda = 3
	ctx.sequence_catalog.run(
		ctx, &"seq.agenda.advance", {"source": &"sandbox", "explicit": true}
	)
	ctx.state.doom_on_agenda = 5
	ctx.sequence_catalog.run(
		ctx, &"seq.agenda.advance", {"source": &"sandbox", "explicit": true}
	)


static func _flip_act1(ctx: GameContext) -> void:
	var inv := ctx.state.registry.get_investigator(&"inv_1")
	if inv != null:
		inv.clues_on_card = 2
	ctx.sequence_catalog.run(ctx, &"seq.act.advance", {})


static func _encounter_draw_lab(ctx: GameContext) -> void:
	## 牌库顶塞入若干可测遭遇牌（若尚无则从 set-aside / 新建）。
	for def_id in [&"12129", &"12124", &"12130"]:
		ensure_on_encounter_deck_top(ctx, def_id)


static func ensure_on_encounter_deck_top(ctx: GameContext, definition_id: StringName) -> void:
	# 已在牌库则移到顶
	for i in ctx.state.encounter_deck.size():
		var cid: StringName = ctx.state.encounter_deck[i]
		var card := ctx.state.registry.get_card(cid)
		if card != null and card.id.definition_id == definition_id:
			ctx.state.encounter_deck.remove_at(i)
			ctx.state.encounter_deck.insert(0, cid)
			return
	# set-aside
	var aside := ScenarioSetAsideService.find_cards(ctx, definition_id)
	if not aside.is_empty():
		var card_id: StringName = aside[0]
		ScenarioSetAsideService.remove_from_set_aside(ctx, card_id)
		var c := ctx.state.registry.get_card(card_id)
		if c != null:
			c.zone = AhcEnums.Zone.DECK
		ctx.state.encounter_deck.insert(0, card_id)
		return
	# 物化一张到牌库顶
	var instance_id := ctx.state.registry.allocate_instance_id(&"enc")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, instance_id, definition_id)
	var neu := CardInstance.new()
	neu.id = eid
	neu.owner_id = &"encounter"
	neu.controller_id = &"encounter"
	neu.zone = AhcEnums.Zone.DECK
	ctx.state.registry.register_card(neu)
	if CardRegistry.definition_data(definition_id).is_empty():
		CardRegistry.register_definition(definition_id, {"card_type": &"treachery"})
	ctx.state.encounter_deck.insert(0, instance_id)
