class_name ImplicitActionTargets
extends RefCounted

## 基础 Fight / Evade / Investigate 隐式目标：U–S → V → Gate。
## 见 docs/design/21-selection-spec.md §3.2 / §3.2.2


static func resolve(
	action_type: AhcEnums.ActionType,
	game_ctx: GameContext,
	investigator_id: StringName,
	extra: Dictionary
) -> Dictionary:
	match action_type:
		AhcEnums.ActionType.FIGHT:
			return resolve_fight(game_ctx, investigator_id, extra)
		AhcEnums.ActionType.EVADE:
			return resolve_evade(game_ctx, investigator_id, extra)
		AhcEnums.ActionType.INVESTIGATE:
			return resolve_investigate(game_ctx, investigator_id, extra)
		_:
			return {"ok": true, "extra": extra}


static func resolve_fight(
	game_ctx: GameContext,
	investigator_id: StringName,
	extra: Dictionary
) -> Dictionary:
	var spec := SelectionSpec.implicit_attack(investigator_id)
	var legal := _legal_candidates(spec, game_ctx, investigator_id)
	var provided: StringName = extra.get("enemy_id", &"")
	if provided != &"":
		if legal.has(provided):
			return _ok_enemy(extra, provided)
		return {"ok": false, "error": _diagnose_fight(game_ctx, investigator_id, provided)}
	if legal.is_empty():
		return {"ok": false, "error": "no_legal_target"}
	var picked := _pick(spec, legal, investigator_id, game_ctx)
	if picked == &"":
		return {"ok": false, "error": "no_legal_target"}
	return _ok_enemy(extra, picked)


static func resolve_evade(
	game_ctx: GameContext,
	investigator_id: StringName,
	extra: Dictionary
) -> Dictionary:
	var spec := SelectionSpec.implicit_evade(investigator_id)
	var legal := _legal_candidates(spec, game_ctx, investigator_id)
	var provided: StringName = extra.get("enemy_id", &"")
	if provided != &"":
		if legal.has(provided):
			return _ok_enemy(extra, provided)
		return {"ok": false, "error": _diagnose_evade(game_ctx, investigator_id, provided)}
	if legal.is_empty():
		return {"ok": false, "error": "no_legal_target"}
	var picked := _pick(spec, legal, investigator_id, game_ctx)
	if picked == &"":
		return {"ok": false, "error": "no_legal_target"}
	return _ok_enemy(extra, picked)


## 基础 Investigate：隐式地点 = 所在地（非多选）；非法则发起失败。
static func resolve_investigate(
	game_ctx: GameContext,
	investigator_id: StringName,
	extra: Dictionary
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	var inv := game_ctx.state.registry.get_investigator(investigator_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator"}
	var provided: StringName = extra.get("location_id", &"")
	var location_id := provided if provided != &"" else inv.location_tag
	if location_id == &"":
		return {"ok": false, "error": "no_legal_target"}
	var loc := game_ctx.state.registry.get_location(location_id)
	if loc == null:
		return {"ok": false, "error": "unknown_location"}
	if inv.location_tag != loc.id:
		return {"ok": false, "error": "not_at_location"}
	var out := extra.duplicate(true)
	out["location_id"] = location_id
	return {"ok": true, "extra": out, "location_id": location_id}


static func _legal_candidates(
	spec: SelectionSpec,
	game_ctx: GameContext,
	investigator_id: StringName
) -> Array[StringName]:
	if spec == null or spec.filter == null or game_ctx == null:
		return []
	var candidates := CandidateEnumerator.enumerate(
		spec.filter, game_ctx, investigator_id
	)
	if (
		not spec.skip_viability
		and spec.viability_tail != null
		and not candidates.is_empty()
	):
		candidates = CandidateViability.filter_viable(
			candidates, game_ctx, investigator_id, spec.bind_key, spec.viability_tail
		)
	return candidates


static func _pick(
	spec: SelectionSpec,
	legal: Array[StringName],
	investigator_id: StringName,
	game_ctx: GameContext
) -> StringName:
	if legal.is_empty():
		return &""
	var picked: Variant = legal[0]
	if game_ctx != null and game_ctx.interaction != null:
		picked = game_ctx.interaction.ask_selection(spec, legal, investigator_id, game_ctx)
	if picked == null:
		return &""
	if picked is Array:
		var arr: Array = picked
		return StringName(str(arr[0])) if not arr.is_empty() else &""
	return StringName(str(picked))


static func _ok_enemy(extra: Dictionary, enemy_id: StringName) -> Dictionary:
	var out := extra.duplicate(true)
	out["enemy_id"] = enemy_id
	return {"ok": true, "extra": out, "enemy_id": enemy_id}


static func _diagnose_fight(
	game_ctx: GameContext, investigator_id: StringName, enemy_id: StringName
) -> String:
	if game_ctx == null or game_ctx.state == null:
		return "no_legal_target"
	var inv := game_ctx.state.registry.get_investigator(investigator_id)
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if inv == null or enemy == null:
		return "unknown_enemy"
	if not enemy.is_at_location(inv.location_tag):
		return "wrong_location"
	if enemy.aloof and enemy.engaged_with == &"":
		return "aloof"
	return "no_legal_target"


static func _diagnose_evade(
	game_ctx: GameContext, investigator_id: StringName, enemy_id: StringName
) -> String:
	if game_ctx == null or game_ctx.state == null:
		return "no_legal_target"
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return "unknown_enemy"
	if not enemy.is_engaged_with(investigator_id):
		return "not_engaged"
	return "no_legal_target"
