class_name CandidateEnumerator
extends RefCounted

## 按 CandidateFilter 客观枚举合法候选。见 docs/design/21-selection-spec.md


static func enumerate(
	filter: CandidateFilter,
	game_ctx: GameContext,
	controller_id: StringName,
	source_card_id: StringName = &""
) -> Array[StringName]:
	var out: Array[StringName] = []
	if filter == null or game_ctx == null or game_ctx.state == null:
		return out
	match filter.entity:
		&"enemy":
			_enum_enemies(filter, game_ctx, controller_id, source_card_id, out)
		&"location":
			_enum_locations(filter, game_ctx, controller_id, source_card_id, out)
		&"investigator":
			_enum_investigators(filter, game_ctx, controller_id, out)
		&"card":
			_enum_cards(filter, game_ctx, controller_id, out)
		_:
			pass
	if not filter.preds.is_empty() and not out.is_empty():
		out = CandidatePreds.filter_candidates(
			out,
			filter.preds,
			game_ctx.state,
			controller_id,
			filter.entity,
			game_ctx,
			game_ctx.memory
		)
	return out


## V / L7 dry-run：仅有 GameSimulator 时枚举（state + memory_referents）。
static func enumerate_on_sim(
	filter: CandidateFilter,
	sim: GameSimulator,
	controller_id: StringName,
	source_card_id: StringName = &""
) -> Array[StringName]:
	var out: Array[StringName] = []
	if filter == null or sim == null or sim.state == null:
		return out
	match filter.entity:
		&"enemy":
			_enum_enemies_sim(filter, sim, controller_id, source_card_id, out)
		&"location":
			for loc_id in _location_universe_sim(filter, sim, controller_id, source_card_id):
				if sim.state.registry.get_location(loc_id) != null:
					out.append(loc_id)
		&"investigator":
			for inv_id in sim.state.registry.all_investigator_ids():
				var inv := sim.state.registry.get_investigator(inv_id)
				if inv == null or inv.eliminated:
					continue
				if filter.owned_by == &"controller" and inv_id != controller_id:
					continue
				out.append(inv_id)
		_:
			pass
	if not filter.preds.is_empty() and not out.is_empty():
		out = CandidatePreds.filter_candidates(
			out, filter.preds, sim.state, controller_id, filter.entity, null, sim
		)
	return out


static func _enum_enemies_sim(
	filter: CandidateFilter,
	sim: GameSimulator,
	controller_id: StringName,
	source_card_id: StringName,
	out: Array[StringName]
) -> void:
	var locs := _location_universe_sim(filter, sim, controller_id, source_card_id)
	for enemy_id in sim.state.registry.all_enemy_ids():
		var enemy := sim.state.registry.get_enemy(enemy_id)
		if enemy == null:
			continue
		if not _enemy_structure_ok(filter, enemy, controller_id):
			continue
		if not locs.is_empty() and not locs.has(enemy.location_tag):
			continue
		out.append(enemy_id)


static func _location_universe_sim(
	filter: CandidateFilter,
	sim: GameSimulator,
	controller_id: StringName,
	source_card_id: StringName
) -> Array[StringName]:
	var out: Array[StringName] = []
	var at := filter.at
	if at == &"":
		return out
	var inv := sim.state.registry.get_investigator(controller_id)
	var here := &""
	if source_card_id != &"" and sim.state.registry.get_location(source_card_id) != null:
		here = source_card_id
	elif inv != null:
		here = inv.location_tag
	match at:
		&"connecting":
			var loc := sim.state.registry.get_location(here) if here != &"" else null
			if loc != null:
				for conn in loc.connections:
					out.append(conn)
		&"controller_location", &"source_location":
			if here != &"":
				out.append(here)
		_:
			if str(at).begins_with("memory:"):
				var key := StringName(str(at).substr(7))
				var ref: Variant = sim.get_referent(controller_id, key)
				if ref != null and str(ref) != "":
					out.append(StringName(str(ref)))
			elif sim.state.registry.get_location(at) != null:
				out.append(at)
	return out


static func _enum_enemies(
	filter: CandidateFilter,
	game_ctx: GameContext,
	controller_id: StringName,
	source_card_id: StringName,
	out: Array[StringName]
) -> void:
	var locs := _location_universe(filter, game_ctx, controller_id, source_card_id)
	for enemy_id in game_ctx.state.registry.all_enemy_ids():
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy == null:
			continue
		if not _enemy_structure_ok(filter, enemy, controller_id):
			continue
		if not locs.is_empty() and not locs.has(enemy.location_tag):
			continue
		if not _traits_ok(game_ctx, enemy_id, filter):
			continue
		if not _keywords_ok(game_ctx, enemy_id, filter):
			continue
		out.append(enemy_id)


static func _enemy_structure_ok(
	filter: CandidateFilter, enemy: EnemyState, controller_id: StringName
) -> bool:
	if filter.exclude_massive and enemy.massive:
		return false
	if filter.exclude_aloof and enemy.aloof:
		return false
	if filter.exclude_aloof_unengaged and enemy.aloof and enemy.engaged_with == &"":
		return false
	if filter.exhausted != null and bool(enemy.exhausted) != bool(filter.exhausted):
		return false
	var want_with := filter.engaged_with
	if want_with == &"" and filter.engaged != null:
		var eng_raw := str(filter.engaged)
		if eng_raw == "controller" or eng_raw == "self":
			want_with = &"controller"
		elif eng_raw == "true" or eng_raw == "false":
			var is_eng := enemy.engaged_with != &""
			if is_eng != bool(filter.engaged):
				return false
		else:
			want_with = StringName(eng_raw)
	if want_with != &"":
		var target_inv := controller_id if want_with == &"controller" or want_with == &"self" else want_with
		if enemy.engaged_with != target_inv:
			return false
	return true


static func _enum_locations(
	filter: CandidateFilter,
	game_ctx: GameContext,
	controller_id: StringName,
	source_card_id: StringName,
	out: Array[StringName]
) -> void:
	var locs := _location_universe(filter, game_ctx, controller_id, source_card_id)
	for loc_id in locs:
		if game_ctx.state.registry.get_location(loc_id) != null:
			out.append(loc_id)


static func _enum_investigators(
	filter: CandidateFilter,
	game_ctx: GameContext,
	controller_id: StringName,
	out: Array[StringName]
) -> void:
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null or inv.eliminated:
			continue
		if filter.owned_by == &"controller" and inv_id != controller_id:
			continue
		out.append(inv_id)


static func _enum_cards(
	filter: CandidateFilter,
	game_ctx: GameContext,
	controller_id: StringName,
	out: Array[StringName]
) -> void:
	## v0.1：仅手牌（后续按 zones 扩展）。
	var want_hand := filter.zones.is_empty() or filter.zones.has(&"hand")
	if not want_hand:
		return
	for card_id in game_ctx.state.registry.all_card_ids():
		var card := game_ctx.state.registry.get_card(card_id)
		if card == null:
			continue
		if filter.owned_by == &"controller" or filter.owned_by == &"any":
			if card.owner_id != controller_id and filter.owned_by == &"controller":
				continue
		if not _card_in_hand(game_ctx, card_id, controller_id):
			continue
		if filter.exhausted != null and bool(card.exhausted) != bool(filter.exhausted):
			continue
		if not _traits_ok(game_ctx, card_id, filter):
			continue
		if not _keywords_ok(game_ctx, card_id, filter):
			continue
		if not filter.card_types.is_empty():
			var def_id := card.id.definition_id if card.id != null else &""
			var ctype := _card_type_of(def_id)
			if ctype != &"" and not filter.card_types.has(ctype):
				continue
		out.append(card_id)


static func _location_universe(
	filter: CandidateFilter,
	game_ctx: GameContext,
	controller_id: StringName,
	source_card_id: StringName
) -> Array[StringName]:
	var out: Array[StringName] = []
	var at := filter.at
	if at == &"":
		return out
	var inv := game_ctx.state.registry.get_investigator(controller_id)
	var here := &""
	if source_card_id != &"" and game_ctx.state.registry.get_location(source_card_id) != null:
		here = source_card_id
	elif inv != null:
		here = inv.location_tag
	match at:
		&"connecting":
			var loc := game_ctx.state.registry.get_location(here) if here != &"" else null
			if loc != null:
				for conn in loc.connections:
					out.append(conn)
		&"controller_location", &"source_location":
			if here != &"":
				out.append(here)
		_:
			if str(at).begins_with("memory:"):
				var key := StringName(str(at).substr(7))
				if game_ctx.memory != null:
					var ref: Variant = game_ctx.memory.get_referent(controller_id, key)
					if ref != null and str(ref) != "":
						out.append(StringName(str(ref)))
			elif game_ctx.state.registry.get_location(at) != null:
				out.append(at)
	return out


static func _traits_ok(
	game_ctx: GameContext, entity_id: StringName, filter: CandidateFilter
) -> bool:
	if filter.traits.is_empty() and filter.trait_exclude.is_empty():
		return true
	var have := _traits_of(game_ctx, entity_id)
	for t in filter.traits:
		if not have.has(t):
			return false
	for t in filter.trait_exclude:
		if have.has(t):
			return false
	return true


static func _keywords_ok(
	game_ctx: GameContext, entity_id: StringName, filter: CandidateFilter
) -> bool:
	if filter.keywords.is_empty() and filter.keyword_exclude.is_empty():
		return true
	var have := _keywords_of(game_ctx, entity_id)
	for k in filter.keywords:
		if not have.has(k):
			return false
	for k in filter.keyword_exclude:
		if have.has(k):
			return false
	return true


static func _traits_of(game_ctx: GameContext, entity_id: StringName) -> Array[StringName]:
	var card := game_ctx.state.registry.get_card(entity_id)
	if card == null or card.id == null:
		return []
	return CandidateFilter._to_name_array(CardRegistry.traits(card.id.definition_id))


static func _keywords_of(game_ctx: GameContext, entity_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var enemy := game_ctx.state.registry.get_enemy(entity_id)
	if enemy != null:
		if enemy.aloof:
			out.append(&"aloof")
		if enemy.massive:
			out.append(&"massive")
	if game_ctx.registrations != null and game_ctx.registrations.has_method("has_keyword_buff"):
		for kw in [&"surge", &"peril", &"hunter", &"alert", &"retaliate", &"elusive"]:
			if game_ctx.registrations.has_keyword_buff(entity_id, kw):
				out.append(kw)
	return out


static func _card_in_hand(
	game_ctx: GameContext, card_id: StringName, controller_id: StringName
) -> bool:
	var inv := game_ctx.state.registry.get_investigator(controller_id)
	if inv == null:
		return false
	return inv.hand.has(card_id)


static func _card_type_of(definition_id: StringName) -> StringName:
	if definition_id == &"":
		return &""
	return CardRegistry.card_type(definition_id)
