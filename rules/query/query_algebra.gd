class_name QueryAlgebra
extends RefCounted

## 查询算子。只读：不压栈，不改局面，不在并列里替玩家挑一个。
## 两种全集：board 是局面实体；catalog 是卡牌定义（构筑选项的行）。
## 具名 *Query、准入顺序、整副下限都是这些算子的模板，还没有改写成调用这里。
##
## scan → where → rank → aggregate
## project 读一列。board 与 CandidatePreds.field_value 共用；catalog 读印刷列。

const UNIVERSE_BOARD := &"board"
const UNIVERSE_CATALOG := &"catalog"

const MEASURE_DISTANCE := &"distance"
const MEASURE_FIELD := &"field"
const MEASURE_COUNT_AT := &"count_at"

const ORDER_MIN := &"min"
const ORDER_MAX := &"max"

const AGG_COUNT := &"count"
const AGG_EXISTS := &"exists"
const AGG_SUM := &"sum"
const AGG_MIN := &"min"
const AGG_MAX := &"max"
const AGG_GROUP_COUNT := &"group_count"

const SHAPE_SET := &"set"
const SHAPE_SCALAR := &"scalar"
const SHAPE_GROUP := &"group"


static func scan(
	state: GameStateStore,
	entity: StringName,
	universe: StringName = UNIVERSE_BOARD
) -> Array[StringName]:
	if universe == UNIVERSE_CATALOG:
		if entity != &"card" and entity != &"definition" and entity != &"":
			return []
		return CardRegistry.all_definition_ids()
	var out: Array[StringName] = []
	if state == null or state.registry == null:
		return out
	match entity:
		&"investigator":
			for inv_id in state.registry.all_investigator_ids():
				var inv := state.registry.get_investigator(inv_id)
				if inv == null or inv.eliminated:
					continue
				out.append(inv_id)
		&"enemy":
			for enemy_id in state.registry.all_enemy_ids():
				if state.registry.get_enemy(enemy_id) != null:
					out.append(enemy_id)
		&"location":
			for loc_id in state.registry.all_location_ids():
				if state.registry.get_location(loc_id) != null:
					out.append(loc_id)
		&"card":
			for card_id in state.registry.all_card_ids():
				if state.registry.get_card(card_id) != null:
					out.append(card_id)
	return out


static func where(
	game_ctx: GameContext,
	ids: Array[StringName],
	filter: Variant,
	controller_id: StringName = &"",
	source_id: StringName = &"",
	universe: StringName = UNIVERSE_BOARD
) -> Array[StringName]:
	if universe == UNIVERSE_CATALOG:
		return _where_catalog(ids, filter)
	if ids.is_empty() or game_ctx == null or game_ctx.state == null:
		return []
	if filter == null:
		return _copy_ids(ids)
	if typeof(filter) == TYPE_DICTIONARY and (filter as Dictionary).is_empty():
		return _copy_ids(ids)
	var spec := CandidateFilter.from_variant(filter)
	if spec.entity == &"location" and spec.at == &"":
		return _where_locations_open(game_ctx, ids, spec, controller_id)
	var matched := CandidateEnumerator.enumerate(spec, game_ctx, controller_id, source_id)
	return _intersect(ids, matched)


static func rank(
	state: GameStateStore,
	ids: Array[StringName],
	entity: StringName,
	measure: StringName,
	order: StringName = ORDER_MIN,
	anchor_id: StringName = &"",
	field: StringName = &"",
	count_kind: StringName = &"",
	universe: StringName = UNIVERSE_BOARD
) -> Array[StringName]:
	var best_set := false
	var best_n := 0
	var out: Array[StringName] = []
	for id in ids:
		var measured: Variant = _measure(
			state, id, entity, measure, anchor_id, field, count_kind, universe
		)
		if measured == null:
			continue
		var n := int(measured)
		if not best_set:
			best_set = true
			best_n = n
			out.append(id)
			continue
		var better := n > best_n if order == ORDER_MAX else n < best_n
		if better:
			best_n = n
			out.clear()
			out.append(id)
		elif n == best_n:
			out.append(id)
	return out


static func aggregate(
	state: GameStateStore,
	ids: Array[StringName],
	entity: StringName,
	op: StringName,
	field: StringName = &"",
	universe: StringName = UNIVERSE_BOARD
) -> Variant:
	match op:
		AGG_COUNT:
			return ids.size()
		AGG_EXISTS:
			return not ids.is_empty()
		AGG_GROUP_COUNT:
			if universe != UNIVERSE_CATALOG:
				return {}
			return _group_count(ids, field)
		AGG_SUM:
			return _fold_field(state, ids, entity, field, AGG_SUM, universe)
		AGG_MIN:
			return _fold_field(state, ids, entity, field, AGG_MIN, universe)
		AGG_MAX:
			return _fold_field(state, ids, entity, field, AGG_MAX, universe)
		_:
			return null


static func project(
	state: GameStateStore,
	entity_id: StringName,
	entity: StringName,
	field: StringName,
	universe: StringName = UNIVERSE_BOARD
) -> Variant:
	if universe == UNIVERSE_CATALOG:
		return _project_catalog(entity_id, field)
	return CandidatePreds.field_value(field, entity_id, entity, state)


## spec: universe（board / catalog）, from, ids, where, rank, aggregate
## catalog 的 where 是一条 deck_options 谓词。ids 给定时不再 scan，副本重复保留。
## bindings: controller_id, source_id, drawer_id（board 锚点）
## aggregate 为 group_count 时 shape 为分组；其它聚合是标量；否则是集合。
## ids 始终是聚合前的那一组。
static func eval(
	game_ctx: GameContext,
	spec: Dictionary,
	bindings: Dictionary = {}
) -> Dictionary:
	var universe := StringName(str(spec.get("universe", UNIVERSE_BOARD)))
	var entity := StringName(str(spec.get("from", "")))
	var ids: Array[StringName] = []
	if spec.has("ids") and spec["ids"] is Array:
		for raw_id in spec["ids"] as Array:
			ids.append(StringName(str(raw_id)))
	elif universe == UNIVERSE_CATALOG:
		var kind := entity if entity != &"" else &"card"
		ids = scan(null, kind, universe)
	elif game_ctx != null and game_ctx.state != null:
		ids = scan(game_ctx.state, entity, universe)
	if spec.has("where") and spec["where"] != null:
		if universe == UNIVERSE_CATALOG:
			ids = where(game_ctx, ids, spec["where"], &"", &"", universe)
		else:
			var raw: Variant = spec["where"]
			var filt: Dictionary = (raw as Dictionary).duplicate(true) if raw is Dictionary else {}
			filt["entity"] = String(entity)
			var controller_id := _binding_id(bindings, "controller_id")
			var source_id := _binding_id(bindings, "source_id")
			ids = where(game_ctx, ids, filt, controller_id, source_id, universe)
	if spec.has("rank") and spec["rank"] is Dictionary:
		var rank_spec: Dictionary = spec["rank"]
		var measure := StringName(str(rank_spec.get("measure", "")))
		if measure != &"":
			var order := StringName(str(rank_spec.get("order", ORDER_MIN)))
			var anchor := _resolve_anchor(
				game_ctx,
				str(rank_spec.get("anchor", "controller")),
				bindings
			)
			var field := StringName(str(rank_spec.get("field", "")))
			var count_kind := StringName(str(rank_spec.get("kind", "")))
			ids = rank(
				game_ctx.state if game_ctx != null else null,
				ids,
				entity,
				measure,
				order,
				anchor,
				field,
				count_kind,
				universe
			)
	var result := {"shape": SHAPE_SET, "ids": ids, "value": null}
	if spec.has("aggregate") and spec["aggregate"] is Dictionary:
		var agg: Dictionary = spec["aggregate"]
		var op := StringName(str(agg.get("op", "")))
		var field_name := StringName(str(agg.get("field", "")))
		result["shape"] = SHAPE_GROUP if op == AGG_GROUP_COUNT else SHAPE_SCALAR
		result["value"] = aggregate(
			game_ctx.state if game_ctx != null else null,
			ids,
			entity,
			op,
			field_name,
			universe
		)
	return result


static func _where_catalog(ids: Array[StringName], filter: Variant) -> Array[StringName]:
	if ids.is_empty():
		return []
	if filter == null:
		return _copy_ids(ids)
	if typeof(filter) == TYPE_DICTIONARY and (filter as Dictionary).is_empty():
		return _copy_ids(ids)
	if typeof(filter) != TYPE_DICTIONARY:
		return []
	var raw: Dictionary = (filter as Dictionary).duplicate(true)
	raw.erase("entity")
	var rule := DeckOptionRule.from_dict(raw)
	## 选型先解析成具体谓词。未解析的选型不是单卡测试。
	if rule.role == DeckOptionRule.Role.CHOICE:
		return []
	var invert := rule.is_not
	var out: Array[StringName] = []
	for id in ids:
		var view := DeckCardView.from_registry(id)
		var hit := rule.matches_card(view)
		if invert:
			hit = not hit
		if hit:
			out.append(id)
	return out


static func _project_catalog(definition_id: StringName, field: StringName) -> Variant:
	var view := DeckCardView.from_registry(definition_id)
	match field:
		&"level":
			return view.level
		&"permanent":
			return 1 if view.permanent else 0
		_:
			return null


## 一张多值列（职阶、特性）的牌计入它的每一项。副本按列表里出现的次数计。
static func _group_count(ids: Array[StringName], field: StringName) -> Dictionary:
	var counts := {}
	for id in ids:
		var view := DeckCardView.from_registry(id)
		var keys := _group_keys(view, field)
		for key in keys:
			var label := String(key).to_lower()
			if label == "":
				continue
			counts[label] = int(counts.get(label, 0)) + 1
	return counts


static func _group_keys(view: DeckCardView, field: StringName) -> Array[StringName]:
	var keys: Array[StringName] = []
	match field:
		&"faction":
			for item in view.factions:
				keys.append(item)
		&"trait":
			for item in view.traits:
				keys.append(item)
		&"type":
			if view.card_type != &"":
				keys.append(view.card_type)
		&"tag":
			for item in view.tags:
				keys.append(item)
		&"uses":
			for item in view.uses_types:
				keys.append(item)
	return keys


static func _where_locations_open(
	game_ctx: GameContext,
	ids: Array[StringName],
	spec: CandidateFilter,
	controller_id: StringName
) -> Array[StringName]:
	var structural: Array[StringName] = []
	for loc_id in ids:
		if game_ctx.state.registry.get_location(loc_id) == null:
			continue
		if not _location_traits_ok(loc_id, spec):
			continue
		structural.append(loc_id)
	if spec.preds.is_empty():
		return structural
	return CandidatePreds.filter_candidates(
		structural,
		spec.preds,
		game_ctx.state,
		controller_id,
		&"location",
		game_ctx,
		game_ctx.memory
	)


static func _location_traits_ok(location_id: StringName, spec: CandidateFilter) -> bool:
	if spec.traits.is_empty() and spec.trait_exclude.is_empty():
		return true
	for trait_name in spec.traits:
		if not CardRegistry.has_trait(location_id, trait_name):
			return false
	for trait_name in spec.trait_exclude:
		if CardRegistry.has_trait(location_id, trait_name):
			return false
	return true


static func _intersect(ids: Array[StringName], matched: Array[StringName]) -> Array[StringName]:
	var keep: Dictionary = {}
	for id in matched:
		keep[id] = true
	var out: Array[StringName] = []
	for id in ids:
		if keep.has(id):
			out.append(id)
	return out


static func _measure(
	state: GameStateStore,
	entity_id: StringName,
	entity: StringName,
	measure: StringName,
	anchor_id: StringName,
	field: StringName,
	count_kind: StringName,
	universe: StringName
) -> Variant:
	match measure:
		MEASURE_DISTANCE:
			if universe != UNIVERSE_BOARD:
				return null
			var origin := _entity_location(state, anchor_id)
			var dest := entity_id if entity == &"location" else _entity_location(state, entity_id)
			if origin == &"" or dest == &"":
				return null
			var dist := LocationGraph.distance(state, origin, dest)
			if dist < 0:
				return null
			return dist
		MEASURE_FIELD:
			return project(state, entity_id, entity, field, universe)
		MEASURE_COUNT_AT:
			if universe != UNIVERSE_BOARD:
				return null
			if count_kind != &"enemy" and count_kind != &"investigator":
				return null
			var at := entity_id if entity == &"location" else _entity_location(state, entity_id)
			if at == &"":
				return null
			var column := &"enemy_count" if count_kind == &"enemy" else &"investigator_count"
			return CandidatePreds.field_value(column, at, &"location", state)
		_:
			return null


static func _fold_field(
	state: GameStateStore,
	ids: Array[StringName],
	entity: StringName,
	field: StringName,
	op: StringName,
	universe: StringName
) -> Variant:
	var total := 0
	var best_set := false
	var best_n := 0
	var any := false
	for id in ids:
		var measured: Variant = project(state, id, entity, field, universe)
		if measured == null:
			continue
		var n := int(measured)
		any = true
		total += n
		if not best_set:
			best_set = true
			best_n = n
		elif op == AGG_MAX and n > best_n:
			best_n = n
		elif op == AGG_MIN and n < best_n:
			best_n = n
	if op == AGG_SUM:
		return total
	if not any:
		return null
	return best_n


static func _entity_location(state: GameStateStore, entity_id: StringName) -> StringName:
	if state == null or entity_id == &"":
		return &""
	if state.registry.get_location(entity_id) != null:
		return entity_id
	var inv := state.registry.get_investigator(entity_id)
	if inv != null:
		return inv.location_tag
	var enemy := state.registry.get_enemy(entity_id)
	if enemy != null:
		return enemy.location_tag
	return &""


static func _resolve_anchor(game_ctx: GameContext, token: String, bindings: Dictionary) -> StringName:
	match token:
		"controller":
			return _binding_id(bindings, "controller_id")
		"lead":
			if game_ctx != null and game_ctx.state != null:
				return game_ctx.state.lead_investigator_id
			return &""
		"source":
			return _binding_id(bindings, "source_id")
		"drawer":
			return _binding_id(bindings, "drawer_id")
		_:
			if token.begins_with("memory:"):
				return _memory_anchor(game_ctx, token, bindings)
			return StringName(token)


static func _memory_anchor(game_ctx: GameContext, token: String, bindings: Dictionary) -> StringName:
	if game_ctx == null or game_ctx.memory == null:
		return &""
	var key := StringName(token.substr(7))
	var controller_id := _binding_id(bindings, "controller_id")
	var ref: Variant = game_ctx.memory.get_referent(controller_id, key)
	if ref == null or str(ref) == "":
		return &""
	return StringName(str(ref))


static func _copy_ids(ids: Array[StringName]) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in ids:
		out.append(id)
	return out


static func _binding_id(bindings: Dictionary, key: String) -> StringName:
	var raw: Variant = bindings.get(key, &"")
	if raw == null:
		return &""
	return StringName(str(raw))
