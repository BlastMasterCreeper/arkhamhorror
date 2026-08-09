class_name ScenarioLayoutSetup
extends RefCounted

## Setup 10 场景布局 · campaign guide + 10 §7。


static func install(game_ctx: GameContext, layout: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	if layout.is_empty():
		return {"ok": true, "skipped": true, "reason": &"no_layout"}
	if game_ctx.state.scenario_layout_installed:
		return {"ok": true, "skipped": true, "reason": &"already_installed"}
	_sync_per_investigator_count(game_ctx)
	var set_aside_counts: Dictionary = layout.get("set_aside", {})
	var set_aside_total := _install_set_aside(game_ctx, set_aside_counts)
	var location_result := _install_locations(game_ctx, layout)
	var deck_size := _build_encounter_deck(game_ctx, layout, set_aside_counts)
	_place_investigators(game_ctx, layout)
	game_ctx.state.scenario_layout_installed = true
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"setup:scenario_layout",
			{
				"starting_location": layout.get("starting_location", &""),
				"encounter_deck": deck_size,
				"set_aside": set_aside_total,
				"locations_in_play": location_result.get("in_play", 0),
				"locations_set_aside": location_result.get("set_aside", 0),
			}
		)
	return {
		"ok": true,
		"encounter_deck": deck_size,
		"set_aside": set_aside_total,
		"locations": location_result,
	}


static func install_reference_card(game_ctx: GameContext, definition_id: StringName) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	if definition_id == &"":
		return {"ok": true, "skipped": true, "reason": &"no_reference"}
	if game_ctx.state.scenario_reference_card_id != &"":
		return {"ok": true, "skipped": true, "reason": &"already_installed"}
	var card_id := materialize_card(
		game_ctx, definition_id, AhcEnums.Zone.PLAY_AREA, &"scenario_ref"
	)
	game_ctx.state.scenario_reference_card_id = card_id
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"setup:scenario_reference",
			{"definition_id": definition_id, "card_id": card_id}
		)
	return {"ok": true, "card_id": card_id, "definition_id": definition_id}


static func _sync_per_investigator_count(game_ctx: GameContext) -> void:
	var count := game_ctx.state.registry.all_investigator_ids().size()
	game_ctx.state.per_investigator_count = maxi(count, 1)


static func _install_set_aside(game_ctx: GameContext, counts: Dictionary) -> int:
	var total := 0
	for raw_def in counts.keys():
		var def_id := StringName(str(raw_def))
		var copies := int(counts[raw_def])
		for _i in copies:
			var card_id := materialize_card(
				game_ctx, def_id, AhcEnums.Zone.SET_ASIDE, &"set_aside"
			)
			game_ctx.state.set_aside.append(card_id)
			total += 1
	return total


static func _install_locations(game_ctx: GameContext, layout: Dictionary) -> Dictionary:
	var connections: Dictionary = layout.get("location_connections", {})
	var in_play: Array = layout.get("locations_in_play", [])
	var aside: Array = layout.get("locations_set_aside", [])
	var starting: StringName = layout.get("starting_location", &"")
	var in_play_count := 0
	var aside_count := 0
	for raw in in_play:
		var def_id := StringName(str(raw))
		var reveal := def_id == starting
		_register_location(game_ctx, def_id, true, reveal)
		in_play_count += 1
	for raw in aside:
		var def_id := StringName(str(raw))
		_register_location(game_ctx, def_id, false, false)
		aside_count += 1
	for raw in connections.keys():
		var from_id := StringName(str(raw))
		var from_loc := game_ctx.state.registry.get_location(from_id)
		if from_loc == null:
			continue
		for dest_raw in connections[raw]:
			var dest_id := StringName(str(dest_raw))
			if not from_loc.connections.has(dest_id):
				from_loc.connections.append(dest_id)
			var dest_loc := game_ctx.state.registry.get_location(dest_id)
			if dest_loc != null and not dest_loc.connections.has(from_id):
				dest_loc.connections.append(from_id)
	return {"in_play": in_play_count, "set_aside": aside_count}


static func _register_location(
	game_ctx: GameContext,
	definition_id: StringName,
	in_play: bool,
	reveal: bool
) -> void:
	if game_ctx.state.registry.get_location(definition_id) != null:
		return
	var loc := LocationState.new()
	loc.id = definition_id
	loc.shroud = CardRegistry.location_shroud(definition_id)
	loc.revealed = in_play and reveal
	if reveal:
		loc.clues = PerInvestigatorScale.place_location_clues(
			game_ctx.state,
			CardRegistry.location_printed_clues(definition_id)
		)
	else:
		loc.clues = 0
	game_ctx.state.registry.register_location(loc)
	if in_play:
		materialize_card(
			game_ctx,
			definition_id,
			AhcEnums.Zone.LOCATION_AREA,
			&"loc",
			definition_id
		)


static func _build_encounter_deck(
	game_ctx: GameContext,
	layout: Dictionary,
	set_aside_counts: Dictionary
) -> int:
	var encounter_sets: Array = layout.get("encounter_sets", [])
	if encounter_sets.is_empty():
		return 0
	var set_codes: Array[StringName] = []
	for raw in encounter_sets:
		set_codes.append(StringName(str(raw)))
	var deck_ids: Array[StringName] = []
	for def_id in CardRegistry.all_definition_ids():
		if not set_codes.has(CardRegistry.encounter_code(def_id)):
			continue
		if not CardRegistry.goes_in_encounter_deck(def_id):
			continue
		if set_aside_counts.has(def_id) or set_aside_counts.has(str(def_id)):
			continue
		deck_ids.append(def_id)
	deck_ids.sort()
	for def_id in deck_ids:
		var card_id := materialize_card(
			game_ctx, def_id, AhcEnums.Zone.DECK, &"enc"
		)
		game_ctx.state.encounter_deck.append(card_id)
	game_ctx.state.encounter_deck.shuffle()
	return game_ctx.state.encounter_deck.size()


static func _place_investigators(game_ctx: GameContext, layout: Dictionary) -> void:
	var starting: StringName = layout.get("starting_location", &"")
	if starting == &"":
		return
	if game_ctx.state.registry.get_location(starting) == null:
		return
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv != null:
			inv.location_tag = starting


static func materialize_card(
	game_ctx: GameContext,
	definition_id: StringName,
	zone: AhcEnums.Zone,
	prefix: StringName,
	instance_id: StringName = &""
) -> StringName:
	var card_instance_id := instance_id
	if card_instance_id == &"":
		card_instance_id = game_ctx.state.registry.allocate_instance_id(prefix)
	var eid := EntityId.create(
		AhcEnums.EntityKind.PLAYER_CARD, card_instance_id, definition_id
	)
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"encounter"
	card.controller_id = &"encounter"
	card.zone = zone
	card.face = AhcEnums.CardFace.A
	game_ctx.state.registry.register_card(card)
	return card_instance_id
