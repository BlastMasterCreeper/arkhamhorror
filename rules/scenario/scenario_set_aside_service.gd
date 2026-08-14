class_name ScenarioSetAsideService
extends RefCounted

## Set-aside 区操作 · act/agenda b 面与 setup 共用。


static func find_cards(game_ctx: GameContext, definition_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	if game_ctx == null or game_ctx.state == null:
		return out
	for card_id in game_ctx.state.set_aside:
		var card := game_ctx.state.registry.get_card(card_id)
		if card != null and card.id.definition_id == definition_id:
			out.append(card_id)
	return out


static func remove_from_set_aside(game_ctx: GameContext, card_id: StringName) -> void:
	if game_ctx == null or game_ctx.state == null:
		return
	game_ctx.state.set_aside.erase(card_id)


static func put_location_into_play(
	game_ctx: GameContext,
	location_id: StringName,
	reveal: bool = true
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	var loc := game_ctx.state.registry.get_location(location_id)
	if loc == null:
		return {"ok": false, "reason": &"unknown_location"}
	if reveal and not loc.revealed:
		loc.revealed = true
		var printed := CardRegistry.location_printed_clues(location_id)
		if printed >= 0:
			loc.clues = PerInvestigatorScale.place_location_clues(game_ctx.state, printed)
	var card := game_ctx.state.registry.get_card(location_id)
	if card == null:
		ScenarioLayoutSetup.materialize_card(
			game_ctx, location_id, AhcEnums.Zone.LOCATION_AREA, &"loc", location_id
		)
	else:
		card.zone = AhcEnums.Zone.LOCATION_AREA
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"location:into_play",
			{"location_id": location_id, "revealed": loc.revealed, "clues": loc.clues}
		)
	return {"ok": true, "location_id": location_id}


static func spawn_set_aside_enemy_at(
	game_ctx: GameContext,
	enemy_definition_id: StringName,
	location_id: StringName
) -> Dictionary:
	if game_ctx == null or game_ctx.enemy == null:
		return {"ok": false}
	var cards := find_cards(game_ctx, enemy_definition_id)
	if cards.is_empty():
		return {"ok": false, "reason": &"missing_set_aside_enemy"}
	var card_id: StringName = cards[0]
	remove_from_set_aside(game_ctx, card_id)
	var spawn := game_ctx.enemy.spawn_at_location(
		game_ctx, card_id, location_id, enemy_definition_id
	)
	if spawn.get("ok", false):
		_apply_enemy_health_per_investigator(game_ctx, card_id, enemy_definition_id)
	return spawn


static func attach_set_aside_to_location(
	game_ctx: GameContext,
	definition_id: StringName,
	location_id: StringName,
	count: int = 1
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or count <= 0:
		return {"ok": false}
	var host := game_ctx.state.registry.get_card(location_id)
	if host == null:
		return {"ok": false, "reason": &"missing_location_card"}
	var attached: Array[StringName] = []
	var cards := find_cards(game_ctx, definition_id)
	for i in mini(count, cards.size()):
		var card_id: StringName = cards[i]
		var treachery := game_ctx.state.registry.get_card(card_id)
		if treachery == null:
			continue
		remove_from_set_aside(game_ctx, card_id)
		treachery.zone = AhcEnums.Zone.ATTACHED
		treachery.attached_to = host.id
		if not host.attachments.has(treachery.id):
			host.attachments.append(treachery.id)
		attached.append(card_id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"attach:set_aside",
			{
				"definition_id": definition_id,
				"location_id": location_id,
				"attached": attached,
			}
		)
	return {"ok": not attached.is_empty(), "attached": attached}


static func discard_set_aside_to_encounter_discard(
	game_ctx: GameContext,
	definition_id: StringName,
	count: int = -1
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or game_ctx.mutator == null:
		return {"ok": false}
	var discarded: Array[StringName] = []
	var cards := find_cards(game_ctx, definition_id)
	var limit := cards.size()
	if count >= 0:
		limit = mini(count, cards.size())
	for i in limit:
		var card_id: StringName = cards[i]
		remove_from_set_aside(game_ctx, card_id)
		game_ctx.mutator.move_card(card_id, CardSlot.encounter_discard_top())
		discarded.append(card_id)
	return {"ok": true, "discarded": discarded}


static func _apply_enemy_health_per_investigator(
	game_ctx: GameContext,
	enemy_id: StringName,
	definition_id: StringName
) -> void:
	var stats := CardRegistry.enemy_stats(definition_id)
	if not bool(stats.get("health_per_investigator", false)):
		return
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return
	var base := int(stats.get("health", 1))
	enemy.health = PerInvestigatorScale.scale(game_ctx.state, base)
