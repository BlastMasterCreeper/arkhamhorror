class_name CandidatePreds
extends RefCounted

## 候选 N 层：数值谓词。见 docs/design/21-selection-spec.md §3.1.2


static func filter_candidates(
	candidates: Array[StringName],
	preds: Array,
	state: GameStateStore,
	controller_id: StringName,
	entity_kind: StringName,
	game_ctx: GameContext = null,
	memory: Variant = null
) -> Array[StringName]:
	var out: Array[StringName] = []
	if candidates.is_empty():
		return out
	if preds.is_empty():
		return candidates.duplicate()
	for cand in candidates:
		if passes_all(preds, cand, state, controller_id, entity_kind, game_ctx, memory):
			out.append(cand)
	return out


static func passes_all(
	preds: Array,
	candidate_id: StringName,
	state: GameStateStore,
	controller_id: StringName,
	entity_kind: StringName,
	game_ctx: GameContext = null,
	memory: Variant = null
) -> bool:
	for raw in preds:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		if not evaluate(raw, candidate_id, state, controller_id, entity_kind, game_ctx, memory):
			return false
	return true


static func evaluate(
	pred: Dictionary,
	candidate_id: StringName,
	state: GameStateStore,
	controller_id: StringName,
	entity_kind: StringName,
	game_ctx: GameContext = null,
	memory: Variant = null
) -> bool:
	if pred.has("stat_query") and str(pred.get("stat_query", "")) != "":
		return _eval_stat_query(pred, candidate_id, controller_id, entity_kind, state, game_ctx)
	var on := StringName(str(pred.get("on", "candidate")))
	var field := StringName(str(pred.get("field", "")))
	var op := StringName(str(pred.get("op", "eq")))
	var rhs := _resolve_value(pred.get("value", 0), controller_id, state, memory)
	var subject_id := _subject_id(on, candidate_id, controller_id, state, memory)
	if subject_id == &"" and on != &"candidate":
		return false
	var lhs: Variant = _field_value(
		field,
		subject_id if on != &"candidate" else candidate_id,
		entity_kind if on == &"candidate" else _infer_kind(on, subject_id, state),
		state
	)
	if lhs == null:
		return false
	return _compare(int(lhs), op, int(rhs))


static func _subject_id(
	on: StringName,
	candidate_id: StringName,
	controller_id: StringName,
	state: GameStateStore,
	memory: Variant
) -> StringName:
	match on:
		&"candidate":
			return candidate_id
		&"controller":
			return controller_id
		&"lead":
			return state.lead_investigator_id if state != null else &""
		_:
			var on_s := str(on)
			if on_s.begins_with("memory:"):
				var key := StringName(on_s.substr(7))
				var ref: Variant = _memory_get(memory, controller_id, key)
				if ref != null and str(ref) != "":
					return StringName(str(ref))
			return &""


static func _infer_kind(on: StringName, subject_id: StringName, state: GameStateStore) -> StringName:
	if on == &"controller" or on == &"lead":
		return &"investigator"
	if state == null:
		return &"enemy"
	if state.registry.get_enemy(subject_id) != null:
		return &"enemy"
	if state.registry.get_investigator(subject_id) != null:
		return &"investigator"
	if state.registry.get_location(subject_id) != null:
		return &"location"
	return &"enemy"


static func _field_value(
	field: StringName, entity_id: StringName, kind: StringName, state: GameStateStore
) -> Variant:
	if state == null or entity_id == &"" or field == &"":
		return null
	match kind:
		&"enemy":
			var enemy := state.registry.get_enemy(entity_id)
			if enemy == null:
				return null
			match field:
				&"fight":
					return enemy.fight
				&"evade":
					return enemy.evade
				&"health":
					return enemy.health
				&"health_remaining":
					return maxi(enemy.health - enemy.damage, 0)
				&"damage":
					return enemy.damage
				&"doom":
					return enemy.doom
				_:
					return null
		&"investigator":
			var inv := state.registry.get_investigator(entity_id)
			if inv == null:
				return null
			match field:
				&"resources", &"resource_pool":
					return inv.resource_pool
				&"clues", &"clues_on_card":
					return inv.clues_on_card
				&"actions_remaining", &"actions":
					return inv.actions_remaining
				&"damage_taken":
					return inv.damage_taken
				&"horror_taken":
					return inv.horror_taken
				&"willpower", &"skill_willpower":
					return inv.skill_willpower
				&"intellect", &"skill_intellect":
					return inv.skill_intellect
				&"combat", &"skill_combat":
					return inv.skill_combat
				&"agility", &"skill_agility":
					return inv.skill_agility
				## 无 max sanity 投影时：0 horror → 视为仍有 sanity 余量（≥1 用 horror_taken==0）。
				&"sanity_remaining":
					return 1 if inv.horror_taken <= 0 else 0
				_:
					return null
		&"location":
			var loc := state.registry.get_location(entity_id)
			if loc == null:
				return null
			match field:
				&"shroud":
					return loc.shroud
				&"clues":
					return loc.clues
				_:
					return null
		_:
			return null


static func _resolve_value(
	raw: Variant, controller_id: StringName, state: GameStateStore, memory: Variant
) -> int:
	if typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT:
		return int(raw)
	var s := str(raw)
	if s.begins_with("memory:"):
		var key := StringName(s.substr(7))
		var ref: Variant = _memory_get(memory, controller_id, key)
		if ref != null:
			return int(ref)
		return 0
	if s == "per_investigator":
		return maxi(state.per_investigator_count, 1) if state != null else 1
	return int(raw) if str(raw).is_valid_int() else 0


static func _memory_get(memory: Variant, controller_id: StringName, key: StringName) -> Variant:
	if memory == null:
		return null
	if memory is RulesMemory:
		return (memory as RulesMemory).get_referent(controller_id, key)
	if memory is GameSimulator:
		return (memory as GameSimulator).get_referent(controller_id, key)
	return null


static func _compare(lhs: int, op: StringName, rhs: int) -> bool:
	match op:
		&"eq":
			return lhs == rhs
		&"ne":
			return lhs != rhs
		&"lt":
			return lhs < rhs
		&"le":
			return lhs <= rhs
		&"gt":
			return lhs > rhs
		&"ge":
			return lhs >= rhs
		_:
			return false


static func _eval_stat_query(
	pred: Dictionary,
	candidate_id: StringName,
	controller_id: StringName,
	entity_kind: StringName,
	state: GameStateStore,
	game_ctx: GameContext
) -> bool:
	var name := str(pred.get("stat_query", ""))
	var value := int(pred.get("value", 0))
	if name == "clues_on_location_ge":
		var loc_id := _location_of(candidate_id, entity_kind, state)
		if loc_id == &"" or state == null:
			return false
		var loc: LocationState = state.registry.get_location(loc_id)
		return loc != null and loc.clues >= value
	if game_ctx == null or game_ctx.stat_projections == null:
		return true
	var q: StatQuery = null
	match name:
		"turn_action_spend_count_ge":
			q = StatQuery.turn_action_spend_count_ge(value)
		_:
			return true
	if q == null:
		return true
	var eval_ctx := EvaluationContext.new()
	eval_ctx.controller_id = controller_id
	var got: Variant = game_ctx.stat_projections.get_value(q, eval_ctx)
	return q.evaluate_value(got)


static func _location_of(
	entity_id: StringName, kind: StringName, state: GameStateStore
) -> StringName:
	if state == null:
		return &""
	match kind:
		&"location":
			return entity_id
		&"enemy":
			var enemy := state.registry.get_enemy(entity_id)
			return enemy.location_tag if enemy != null else &""
		&"investigator":
			var inv := state.registry.get_investigator(entity_id)
			return inv.location_tag if inv != null else &""
		_:
			return &""
