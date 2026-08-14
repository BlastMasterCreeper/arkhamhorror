class_name ScenarioDeckSetup
extends RefCounted

## Act/Agenda 牌库安装 · Setup 11–12 最小实现（10 §7）。


static func install_decks(
	game_ctx: GameContext,
	act_definition_ids: Array,
	agenda_definition_ids: Array
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	var installed := false
	var result := {"ok": true}
	if not act_definition_ids.is_empty():
		var act_ids := _materialize_deck(game_ctx, act_definition_ids, &"act")
		if act_ids.is_empty():
			return {"ok": false, "reason": &"empty_act_deck"}
		game_ctx.state.act_deck = act_ids.duplicate()
		var first_act: StringName = game_ctx.state.act_deck[0]
		game_ctx.state.act_deck.remove_at(0)
		_set_current(game_ctx, first_act, false)
		game_ctx.state.current_act_number = 1
		sync_act_clue_threshold(game_ctx.state, first_act)
		result["current_act"] = first_act
		result["act_remaining"] = game_ctx.state.act_deck.size()
		installed = true
	if not agenda_definition_ids.is_empty():
		var agenda_ids := _materialize_deck(game_ctx, agenda_definition_ids, &"agenda")
		if agenda_ids.is_empty():
			return {"ok": false, "reason": &"empty_agenda_deck"}
		game_ctx.state.agenda_deck = agenda_ids.duplicate()
		var first_agenda: StringName = game_ctx.state.agenda_deck[0]
		game_ctx.state.agenda_deck.remove_at(0)
		_set_current(game_ctx, first_agenda, true)
		game_ctx.state.current_agenda_number = 1
		game_ctx.state.doom_on_agenda = 0
		sync_agenda_threshold(game_ctx.state, first_agenda)
		result["current_agenda"] = first_agenda
		result["agenda_remaining"] = game_ctx.state.agenda_deck.size()
		installed = true
	if not installed:
		return {"ok": false, "reason": &"nothing_to_install"}
	return result


static func sync_agenda_threshold(state: GameStateStore, agenda_card_id: StringName) -> void:
	var card := state.registry.get_card(agenda_card_id)
	if card == null:
		state.agenda_threshold = 7
		return
	var doom := CardRegistry.scenario_doom_threshold(card.id.definition_id)
	state.agenda_threshold = doom if doom >= 0 else -1


static func sync_act_clue_threshold(state: GameStateStore, act_card_id: StringName) -> void:
	var card := state.registry.get_card(act_card_id)
	if card == null:
		state.act_clue_threshold = -1
		return
	state.act_clue_threshold = CardRegistry.scenario_clue_threshold(card.id.definition_id)


static func _materialize_deck(
	game_ctx: GameContext,
	definition_ids: Array,
	prefix: StringName
) -> Array[StringName]:
	var out: Array[StringName] = []
	var index := 0
	for raw in definition_ids:
		var def_id := StringName(str(raw))
		if def_id == &"":
			continue
		index += 1
		var instance_id := StringName("%s_%d_%s" % [prefix, index, def_id])
		if game_ctx.state.registry.get_card(instance_id) != null:
			out.append(instance_id)
			continue
		var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, instance_id, def_id)
		var card := CardInstance.new()
		card.id = eid
		card.owner_id = &"encounter"
		card.controller_id = &"encounter"
		card.zone = AhcEnums.Zone.SET_ASIDE
		game_ctx.state.registry.register_card(card)
		out.append(instance_id)
	return out


static func _set_current(game_ctx: GameContext, card_id: StringName, is_agenda: bool) -> void:
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return
	card.face = AhcEnums.CardFace.A
	if is_agenda:
		card.zone = AhcEnums.Zone.CURRENT_AGENDA
		game_ctx.state.current_agenda_card_id = card_id
	else:
		card.zone = AhcEnums.Zone.CURRENT_ACT
		game_ctx.state.current_act_card_id = card_id
	install_triggered_abilities(game_ctx, card_id)


static func install_triggered_abilities(game_ctx: GameContext, card_id: StringName) -> void:
	if game_ctx == null or game_ctx.triggered_abilities == null or card_id == &"":
		return
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return
	if not CardRegistry.has_triggered(card.id.definition_id):
		return
	game_ctx.triggered_abilities.install_card(card_id, card_id)


static func patch_spreading_flames_definitions() -> void:
	## 补充 imported JSON 未带的 doom / back_text（Spreading Flames）。
	var patches := {
		&"12106": {
			"card_type": &"agenda",
			"doom": 3,
			"back_text": "In player order, each investigator tests [willpower] (3). Each investigator who fails takes 1 horror.",
			"back_name": "Past Curfew",
			"back_effects": [
				{
					"kind": &"each_investigator_skill_test",
					"skill": &"willpower",
					"difficulty": 3,
					"on_fail": {"kind": &"horror", "amount": 1},
				},
			],
		},
		&"12107": {
			"card_type": &"agenda",
			"doom": 5,
			"back_text": "If they are still set aside, place 4 set-aside copies of Fire! in the encounter discard pile.\nIn player order, each investigator tests [agility] (3). Each investigator who fails takes 1 damage.",
			"back_name": "Lit Up",
			"back_effects": [
				{
					"kind": &"discard_set_aside_to_encounter_discard",
					"definition_id": &"12129",
					"count": 4,
				},
				{
					"kind": &"each_investigator_skill_test",
					"skill": &"agility",
					"difficulty": 3,
					"on_fail": {"kind": &"damage", "amount": 1},
				},
			],
		},
		&"12108": {
			"card_type": &"agenda",
			"doom": 10,
			"back_text": "Each surviving investigator who has not resigned is defeated and suffers 1 physical trauma.",
			"back_name": "Wild Flames",
			"back_effects": [
				{
					"kind": &"defeat_surviving_non_resigned",
					"physical_trauma": 1,
				},
			],
		},
		&"12109": {
			"card_type": &"act",
			"location": {"clues": 2},
			"objective": {"kind": &"may_spend_clues_end_of_round"},
			"back_text": "Discard each enemy in play.\nPut the set-aside Dormitories and Miskatonic Quad locations into play. Spawn the set-aside Servant of Flame enemy at the Dormitories.\nAttach 1 set-aside copy of Fire! to Your Friend's Room. Place each other set-aside copy of Fire! in the encounter discard pile.",
			"back_name": "Where There's Smoke...",
			"back_effects": [
				{"kind": &"discard_all_enemies"},
				{
					"kind": &"put_locations_into_play",
					"location_ids": [&"12117", &"12116"],
				},
				{
					"kind": &"spawn_set_aside_enemy",
					"enemy_id": &"12114",
					"location_id": &"12117",
				},
				{
					"kind": &"attach_set_aside_to_location",
					"definition_id": &"12129",
					"location_id": &"12113",
					"count": 1,
				},
				{
					"kind": &"discard_set_aside_to_encounter_discard",
					"definition_id": &"12129",
				},
			],
		},
		&"12110": {
			"card_type": &"act",
			"location": {"clues": "dash"},
			"objective": {
				"kind": &"all_undefeated_at_location",
				"location_id": &"12116",
			},
			"back_text": "Search all in-play and all out-of-play areas for the Servant of Flame, heal all damage from them, and set them aside, out of play.\nDiscard each enemy in play.\nDiscard all tokens and attachments from Your Friend's Room and remove it from the game. Put each remaining set-aside location (Orne Library, Science Hall, Warren Observatory) into play.",
			"back_name": "Escape the Dorms",
			"back_effects": [
				{"kind": &"heal_and_set_aside_enemy", "definition_id": &"12114"},
				{"kind": &"discard_all_enemies"},
				{"kind": &"remove_location_from_game", "location_id": &"12113"},
				{
					"kind": &"put_locations_into_play",
					"location_ids": [&"12120", &"12118", &"12119"],
				},
			],
		},
		&"12111": {
			"card_type": &"act",
			"location": {"clues": 3},
			"objective": {
				"kind": &"may_spend_clues_at_location",
				"location_id": &"12120",
			},
			"back_text": "Put the set-aside Dr. Henry Armitage story asset into play under any investigator's control. He does not take up an ally slot during this scenario.\nPut the set-aside Servant of Flame enemy into play at Miskatonic Quad. Place 3 [per_investigator] clues on Miskatonic Quad.\nThe lead investigator must search the encounter deck and discard pile for 1 [per_investigator] copies of Fire! and draw them.",
			"back_name": "Searching for Dr. Armitage",
			"back_effects": [
				{"kind": &"put_story_asset_from_set_aside", "definition_id": &"12115"},
				{
					"kind": &"spawn_set_aside_enemy",
					"enemy_id": &"12114",
					"location_id": &"12116",
				},
				{
					"kind": &"place_clues_on_location",
					"location_id": &"12116",
					"printed_clues": 3,
				},
				{
					"kind": &"lead_search_draw_encounter_copies",
					"definition_id": &"12129",
					"per_investigator": true,
				},
			],
		},
		&"12112": {
			"card_type": &"act",
			"location": {"clues": null},
			"objective": {
				"kind": &"enemy_defeated",
				"definition_id": &"12114",
			},
			"back_text": "<b>(→R1)</b> <i>(page 4)</i>",
			"back_name": "A Flame, Doused",
			"back_effects": [
				{"kind": &"trigger_scenario_resolution", "resolution": 1},
			],
		},
	}
	for def_id in patches.keys():
		CardRegistry.patch_definition(def_id, patches[def_id])
	_register_spreading_flames_triggered()
	_register_spreading_flames_revelations()


static func _register_spreading_flames_triggered() -> void:
	## 12108 a 面 Forced：密谋放置毁灭后，队长抽遭遇弃牌堆顶的 Fire!。
	if CardRegistry.has_triggered(&"12108"):
		return
	CardRegistry.register_triggered(
		&"12108",
		&"forced:after_doom_draw_fire",
		&"mythos_place_doom",
		AhcEnums.SequencePhase.AFTER,
		&"forced",
		func(_bind: AbilityBindContext) -> CompositionNode:
			return CompositionNode.lead_draw_topmost_encounter_discard_copy(&"12129")
	)


static func _register_spreading_flames_revelations() -> void:
	## 12129 Fire! 显现：附着到最近且未附着 Fire! 的地点。
	if CardRegistry.has_revelation(&"12129"):
		return
	CardRegistry.register_revelation(
		&"12129",
		&"revelation:0",
		func(bind: AbilityBindContext) -> CompositionNode:
			return CompositionNode.attach_limbo_to_nearest_location_without(
				bind.card_id, bind.controller_id, &"12129"
			)
	)
