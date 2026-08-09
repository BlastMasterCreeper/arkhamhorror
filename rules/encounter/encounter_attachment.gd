class_name EncounterAttachment
extends RefCounted

## 遭遇 treachery limbo → 附着地点 · 显现（Revelation）共用。


static func attach_limbo_to_location(
	game_ctx: GameContext,
	card_id: StringName,
	location_id: StringName
) -> bool:
	if game_ctx == null or game_ctx.state == null:
		return false
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return false
	var host := game_ctx.state.registry.get_card(location_id)
	if host == null:
		## 仅有 LocationState 时物化地点卡，供 attachments 挂载。
		ScenarioLayoutSetup.materialize_card(
			game_ctx, location_id, AhcEnums.Zone.LOCATION_AREA, &"loc", location_id
		)
		host = game_ctx.state.registry.get_card(location_id)
	if host == null:
		return false
	game_ctx.state.encounter_deck.erase(card_id)
	game_ctx.state.encounter_discard.erase(card_id)
	game_ctx.state.set_aside.erase(card_id)
	card.zone = AhcEnums.Zone.ATTACHED
	card.attached_to = host.id
	if not host.attachments.has(card.id):
		host.attachments.append(card.id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"attach:limbo_to_location",
			{"card_id": card_id, "location_id": location_id}
		)
	return true


static func attach_limbo_to_nearest_location_without(
	game_ctx: GameContext,
	card_id: StringName,
	drawer_id: StringName,
	exclude_attachment_definition_id: StringName = &""
) -> bool:
	if game_ctx == null or card_id == &"":
		return false
	var exclude := exclude_attachment_definition_id
	if exclude == &"":
		var card := game_ctx.state.registry.get_card(card_id)
		if card != null:
			exclude = card.id.definition_id
	var location_id := NearestLocationResolver.pick_nearest_without_attachment(
		game_ctx, drawer_id, exclude
	)
	if location_id == &"":
		return false
	return attach_limbo_to_location(game_ctx, card_id, location_id)


static func dry_attach_limbo_to_nearest_location_without(
	sim: GameSimulator,
	drawer_id: StringName,
	exclude_attachment_definition_id: StringName
) -> bool:
	if sim == null or sim.state == null:
		return false
	var from_inv := sim.state.registry.get_investigator(drawer_id)
	if from_inv == null or from_inv.location_tag == &"":
		return false
	for loc_id in sim.state.registry.all_location_ids():
		var host := sim.state.registry.get_card(loc_id)
		if host == null or host.zone != AhcEnums.Zone.LOCATION_AREA:
			continue
		if _sim_location_has_attachment(sim, loc_id, exclude_attachment_definition_id):
			continue
		return true
	return false


static func _sim_location_has_attachment(
	sim: GameSimulator,
	location_id: StringName,
	definition_id: StringName
) -> bool:
	if definition_id == &"":
		return false
	var host := sim.state.registry.get_card(location_id)
	if host == null:
		return false
	for attached_eid in host.attachments:
		var attached := sim.state.registry.get_card(attached_eid.instance_id)
		if attached != null and attached.id.definition_id == definition_id:
			return true
	return false
