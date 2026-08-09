class_name ScenarioCompositionAtoms
extends RefCounted

## 场景域通用 Composition 原子 · set-aside / 地点 / 清场 / R#（非 act_agenda 专用）。


static func discard_all_enemies_in_play(game_ctx: GameContext) -> bool:
	if game_ctx == null or game_ctx.state == null:
		return false
	var ids := game_ctx.state.registry.all_enemy_ids().duplicate()
	for enemy_id in ids:
		if game_ctx.enemy != null:
			game_ctx.enemy.discard_enemy_from_play(game_ctx, enemy_id)
		else:
			EnemyDefeatResolver.discard_from_play(game_ctx, enemy_id)
	if game_ctx.log != null and not ids.is_empty():
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"composition:discard_all_enemies",
			{"discarded": ids.size()}
		)
	return true


static func put_locations_into_play(
	game_ctx: GameContext,
	location_ids: Array[StringName]
) -> bool:
	var placed := false
	for loc_id in location_ids:
		if ScenarioSetAsideService.put_location_into_play(game_ctx, loc_id).get("ok", false):
			placed = true
	return placed


static func spawn_set_aside_enemy_at(
	game_ctx: GameContext,
	enemy_definition_id: StringName,
	location_id: StringName
) -> bool:
	return ScenarioSetAsideService.spawn_set_aside_enemy_at(
		game_ctx, enemy_definition_id, location_id
	).get("ok", false)


static func attach_set_aside_to_host(
	game_ctx: GameContext,
	definition_id: StringName,
	host_card_id: StringName,
	count: int = 1
) -> bool:
	return ScenarioSetAsideService.attach_set_aside_to_location(
		game_ctx, definition_id, host_card_id, count
	).get("ok", false)


static func discard_set_aside_to_encounter_discard(
	game_ctx: GameContext,
	definition_id: StringName,
	count: int = -1
) -> bool:
	return ScenarioSetAsideService.discard_set_aside_to_encounter_discard(
		game_ctx, definition_id, count
	).get("ok", false)


static func trigger_scenario_resolution(
	game_ctx: GameContext,
	resolution: int,
	source: StringName = &"unknown"
) -> bool:
	return ScenarioResolutionFlow.trigger(game_ctx, resolution, source).get("triggered", false)


static func dry_discard_all_enemies_in_play(sim: GameSimulator) -> bool:
	if sim == null or sim.state == null:
		return false
	return not sim.state.registry.all_enemy_ids().is_empty()


static func dry_put_locations_into_play(
	sim: GameSimulator,
	location_ids: Array[StringName]
) -> bool:
	if sim == null or sim.state == null:
		return false
	for loc_id in location_ids:
		if sim.state.registry.get_location(loc_id) != null:
			return true
	return false


static func dry_spawn_set_aside_enemy_at(
	sim: GameSimulator,
	enemy_definition_id: StringName,
	_location_id: StringName
) -> bool:
	if sim == null or sim.state == null:
		return false
	for card_id in sim.state.set_aside:
		var card := sim.state.registry.get_card(card_id)
		if card != null and card.id.definition_id == enemy_definition_id:
			return true
	return false


static func dry_attach_set_aside_to_host(
	sim: GameSimulator,
	definition_id: StringName,
	host_card_id: StringName,
	count: int = 1
) -> bool:
	if sim == null or sim.state == null:
		return false
	if sim.state.registry.get_card(host_card_id) == null:
		return false
	var found := 0
	for card_id in sim.state.set_aside:
		var card := sim.state.registry.get_card(card_id)
		if card != null and card.id.definition_id == definition_id:
			found += 1
	if found <= 0:
		return false
	if count < 0:
		return true
	return found >= count


static func dry_discard_set_aside_to_encounter_discard(
	sim: GameSimulator,
	definition_id: StringName,
	count: int = -1
) -> bool:
	if sim == null or sim.state == null:
		return false
	var found := 0
	for card_id in sim.state.set_aside:
		var card := sim.state.registry.get_card(card_id)
		if card != null and card.id.definition_id == definition_id:
			found += 1
	if found <= 0:
		return false
	if count < 0:
		return true
	return found >= count


static func dry_trigger_scenario_resolution(resolution: int) -> bool:
	return resolution > 0


static func defeat_surviving_non_resigned(
	game_ctx: GameContext,
	physical_trauma: int = 0,
	mental_trauma: int = 0
) -> bool:
	if game_ctx == null or game_ctx.state == null:
		return false
	var affected := false
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null or inv.eliminated or inv.resigned:
			continue
		if physical_trauma > 0:
			inv.physical_trauma += physical_trauma
		if mental_trauma > 0:
			inv.mental_trauma += mental_trauma
		InvestigatorElimination.eliminate(game_ctx, inv_id)
		affected = true
	if game_ctx.log != null and affected:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"composition:defeat_surviving",
			{"physical_trauma": physical_trauma, "mental_trauma": mental_trauma}
		)
	return affected


static func heal_and_set_aside_enemy(
	game_ctx: GameContext,
	definition_id: StringName
) -> bool:
	if game_ctx == null or game_ctx.state == null:
		return false
	var moved := false
	for enemy_id in game_ctx.state.registry.all_enemy_ids().duplicate():
		var card := game_ctx.state.registry.get_card(enemy_id)
		if card == null or card.id.definition_id != definition_id:
			continue
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy != null:
			enemy.damage = 0
			if enemy.engaged_with != &"":
				var prev := game_ctx.state.registry.get_investigator(enemy.engaged_with)
				if prev != null:
					prev.threat_area.erase(enemy_id)
				enemy.engaged_with = &""
			enemy.location_tag = &""
		card.zone = AhcEnums.Zone.SET_ASIDE
		ScenarioSetAsideService.remove_from_set_aside(game_ctx, enemy_id)
		if not game_ctx.state.set_aside.has(enemy_id):
			game_ctx.state.set_aside.append(enemy_id)
		moved = true
	return moved


static func remove_location_from_game(
	game_ctx: GameContext,
	location_id: StringName
) -> bool:
	if game_ctx == null or game_ctx.state == null or game_ctx.mutator == null:
		return false
	var card := game_ctx.state.registry.get_card(location_id)
	if card == null:
		return false
	for attached in card.attachments.duplicate():
		game_ctx.mutator.move_card(attached.instance_id, CardSlot.encounter_discard_top())
	card.attachments.clear()
	card.tokens.damage = 0
	card.tokens.horror = 0
	card.tokens.doom = 0
	card.tokens.clue = 0
	card.tokens.uses.clear()
	card.zone = AhcEnums.Zone.REMOVED_FROM_GAME
	if not game_ctx.state.removed_from_game.has(location_id):
		game_ctx.state.removed_from_game.append(location_id)
	return true


static func put_story_asset_from_set_aside(
	game_ctx: GameContext,
	definition_id: StringName,
	controller_id: StringName = &"lead_investigator"
) -> bool:
	if game_ctx == null or game_ctx.state == null:
		return false
	var owner := _resolve_controller(game_ctx, controller_id)
	if owner == &"":
		return false
	var cards := ScenarioSetAsideService.find_cards(game_ctx, definition_id)
	if cards.is_empty():
		return false
	var card_id: StringName = cards[0]
	ScenarioSetAsideService.remove_from_set_aside(game_ctx, card_id)
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return false
	card.zone = AhcEnums.Zone.PLAY_AREA
	card.controller_id = owner
	card.owner_id = owner
	var inv := game_ctx.state.registry.get_investigator(owner)
	if inv != null and not inv.play_area.has(card_id):
		inv.play_area.append(card_id)
	return true


static func place_clues_on_location(
	game_ctx: GameContext,
	location_id: StringName,
	printed_clues: int
) -> bool:
	if game_ctx == null or game_ctx.state == null:
		return false
	var loc := game_ctx.state.registry.get_location(location_id)
	if loc == null:
		return false
	loc.clues = PerInvestigatorScale.place_location_clues(
		game_ctx.state, printed_clues
	)
	return true


static func lead_search_draw_encounter_copies(
	game_ctx: GameContext,
	definition_id: StringName,
	per_investigator: bool = false
) -> bool:
	if game_ctx == null or game_ctx.state == null or game_ctx.mutator == null:
		return false
	var lead := game_ctx.state.lead_investigator_id
	if lead == &"":
		lead = game_ctx.state.registry.all_investigator_ids()[0]
	var count := (
		PerInvestigatorScale.scale(game_ctx.state, 1)
		if per_investigator
		else 1
	)
	var drawn := 0
	var searched_deck := false
	for _i in count:
		var card_id := _take_encounter_copy(game_ctx, definition_id, searched_deck)
		if card_id == &"":
			break
		searched_deck = true
		var card := game_ctx.state.registry.get_card(card_id)
		if card == null:
			continue
		card.controller_id = lead
		card.owner_id = &"encounter"
		game_ctx.mutator.commit_enter_threat_area(card_id, lead)
		drawn += 1
	return drawn > 0


## 队长抽遭遇弃牌堆顶（最近弃入）指定 definition 的副本；nest `seq.draw.encounter.resolve_bound`。
static func lead_draw_topmost_encounter_discard_copy(
	game_ctx: GameContext,
	definition_id: StringName
) -> bool:
	if game_ctx == null or game_ctx.state == null:
		return false
	var card_id := _take_topmost_encounter_discard_copy(game_ctx, definition_id)
	if card_id == &"":
		return false
	var lead := _resolve_controller(game_ctx, &"lead_investigator")
	if lead == &"":
		return false
	var card := game_ctx.state.registry.get_card(card_id)
	if card != null:
		card.controller_id = lead
		card.owner_id = &"encounter"
	if game_ctx.sequence_catalog != null:
		var result := game_ctx.sequence_catalog.nest(
			game_ctx,
			&"seq.draw.encounter.resolve_bound",
			{"drawer_id": lead, "card_id": card_id}
		)
		return bool(result.get("ok", false))
	return bool(DrawEncounterFlow.resolve_bound(game_ctx, lead, card_id).get("ok", false))


static func _take_topmost_encounter_discard_copy(
	game_ctx: GameContext,
	definition_id: StringName
) -> StringName:
	var discard := game_ctx.state.encounter_discard
	for i in range(discard.size() - 1, -1, -1):
		var card_id: StringName = discard[i]
		var card := game_ctx.state.registry.get_card(card_id)
		if card != null and card.id.definition_id == definition_id:
			discard.remove_at(i)
			return card_id
	return &""


static func _take_encounter_copy(
	game_ctx: GameContext,
	definition_id: StringName,
	allow_discard_search: bool
) -> StringName:
	for i in game_ctx.state.encounter_deck.size():
		var card_id: StringName = game_ctx.state.encounter_deck[i]
		var card := game_ctx.state.registry.get_card(card_id)
		if card != null and card.id.definition_id == definition_id:
			game_ctx.state.encounter_deck.remove_at(i)
			return card_id
	if allow_discard_search:
		for i in game_ctx.state.encounter_discard.size():
			var card_id: StringName = game_ctx.state.encounter_discard[i]
			var card := game_ctx.state.registry.get_card(card_id)
			if card != null and card.id.definition_id == definition_id:
				game_ctx.state.encounter_discard.remove_at(i)
				return card_id
	return &""


static func _resolve_controller(game_ctx: GameContext, controller_id: StringName) -> StringName:
	if controller_id == &"lead_investigator":
		if game_ctx.state.lead_investigator_id != &"":
			return game_ctx.state.lead_investigator_id
		var ids := game_ctx.state.registry.all_investigator_ids()
		return ids[0] if not ids.is_empty() else &""
	return controller_id


static func dry_defeat_surviving_non_resigned(sim: GameSimulator) -> bool:
	if sim == null or sim.state == null:
		return false
	for inv_id in sim.state.registry.all_investigator_ids():
		var inv := sim.state.registry.get_investigator(inv_id)
		if inv != null and not inv.eliminated and not inv.resigned:
			return true
	return false


static func dry_heal_and_set_aside_enemy(
	sim: GameSimulator,
	definition_id: StringName
) -> bool:
	if sim == null or sim.state == null:
		return false
	for enemy_id in sim.state.registry.all_enemy_ids():
		var card := sim.state.registry.get_card(enemy_id)
		if card != null and card.id.definition_id == definition_id:
			return true
	return false


static func dry_remove_location_from_game(sim: GameSimulator, location_id: StringName) -> bool:
	if sim == null or sim.state == null:
		return false
	return sim.state.registry.get_card(location_id) != null


static func dry_put_story_asset_from_set_aside(
	sim: GameSimulator,
	definition_id: StringName
) -> bool:
	return dry_spawn_set_aside_enemy_at(sim, definition_id, &"")


static func dry_place_clues_on_location(sim: GameSimulator, location_id: StringName) -> bool:
	if sim == null or sim.state == null:
		return false
	return sim.state.registry.get_location(location_id) != null


static func dry_lead_search_draw_encounter_copies(
	sim: GameSimulator,
	definition_id: StringName
) -> bool:
	if sim == null or sim.state == null:
		return false
	for card_id in sim.state.encounter_deck:
		var card := sim.state.registry.get_card(card_id)
		if card != null and card.id.definition_id == definition_id:
			return true
	for card_id in sim.state.encounter_discard:
		var card := sim.state.registry.get_card(card_id)
		if card != null and card.id.definition_id == definition_id:
			return true
	return false


static func dry_lead_draw_topmost_encounter_discard_copy(
	sim: GameSimulator,
	definition_id: StringName
) -> bool:
	if sim == null or sim.state == null:
		return false
	var discard := sim.state.encounter_discard
	for i in range(discard.size() - 1, -1, -1):
		var card := sim.state.registry.get_card(discard[i])
		if card != null and card.id.definition_id == definition_id:
			return true
	return false
