class_name CardRegistry
extends RefCounted

static var _definitions: Dictionary = {}
static var _revelations: Dictionary = {}
static var _on_play: Dictionary = {}
static var _triggered: Dictionary = {}


static func register_definition(definition_id: StringName, data: Dictionary = {}) -> void:
	_definitions[definition_id] = data


static func definition_data(definition_id: StringName) -> Dictionary:
	var data: Variant = _definitions.get(definition_id, {})
	if data is Dictionary:
		return (data as Dictionary).duplicate()
	return {}


static func title(definition_id: StringName) -> String:
	return str(definition_data(definition_id).get("title", ""))


static func ability_hints(definition_id: StringName) -> Array:
	var data := definition_data(definition_id)
	var hints: Variant = data.get("ability_hints", [])
	if hints is Array:
		return hints.duplicate()
	return []


static func traits(definition_id: StringName) -> Array:
	var data := definition_data(definition_id)
	var tr: Variant = data.get("traits", [])
	if tr is Array:
		return tr.duplicate()
	return []


static func ability_segments(definition_id: StringName) -> Array:
	var data := definition_data(definition_id)
	var segments: Variant = data.get("ability_segments", [])
	if segments is Array:
		return segments.duplicate(true)
	return []


static func compiled_abilities(definition_id: StringName) -> Array:
	var data := definition_data(definition_id)
	var compiled: Variant = data.get("compiled_abilities", [])
	if compiled is Array:
		return compiled.duplicate(true)
	return []


## builder: Callable(AbilityBindContext) -> CompositionNode
static func register_revelation(
	definition_id: StringName,
	ability_id: StringName,
	builder: Callable
) -> void:
	if not _revelations.has(definition_id):
		_revelations[definition_id] = []
	(_revelations[definition_id] as Array).append(
		{
			"ability_id": ability_id,
			"builder": builder,
		}
	)


static func revelation_units_at(definition_id: StringName) -> Array:
	return (_revelations.get(definition_id, []) as Array).duplicate()


static func has_revelation(definition_id: StringName) -> bool:
	return not revelation_units_at(definition_id).is_empty()


## builder: Callable(AbilityBindContext) -> CompositionNode
static func register_on_play(
	definition_id: StringName,
	ability_id: StringName,
	builder: Callable
) -> void:
	if not _on_play.has(definition_id):
		_on_play[definition_id] = []
	(_on_play[definition_id] as Array).append(
		{
			"ability_id": ability_id,
			"builder": builder,
		}
	)


static func on_play_units_at(definition_id: StringName) -> Array:
	return (_on_play.get(definition_id, []) as Array).duplicate()


static func has_on_play(definition_id: StringName) -> bool:
	return not on_play_units_at(definition_id).is_empty()


static func build_on_play_composition(
	game_ctx: GameContext,
	controller_id: StringName,
	card_id: StringName
) -> CompositionNode:
	if game_ctx == null or game_ctx.state == null:
		return null
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return null
	var units := on_play_units_at(card.id.definition_id)
	if units.is_empty():
		return null
	var bind := AbilityBindContext.new()
	bind.controller_id = controller_id
	bind.card_id = card_id
	var children: Array[CompositionNode] = []
	for unit in units:
		var builder: Callable = unit.get("builder", Callable())
		if not builder.is_valid():
			continue
		var node: CompositionNode = builder.call(bind)
		if node != null:
			children.append(node)
	if children.is_empty():
		return null
	if children.size() == 1:
		return children[0]
	return CompositionNode.seq(children)


## builder: Callable(AbilityBindContext) -> CompositionNode
static func register_triggered(
	definition_id: StringName,
	ability_id: StringName,
	match_kind: StringName,
	phase: AhcEnums.SequencePhase,
	ability_kind: StringName,
	builder: Callable,
	resource_cost: int = 0,
	action_cost: int = 0,
	optional: bool = false
) -> void:
	if not _triggered.has(definition_id):
		_triggered[definition_id] = []
	(_triggered[definition_id] as Array).append(
		{
			"ability_id": ability_id,
			"match_kind": match_kind,
			"phase": phase,
			"ability_kind": ability_kind,
			"resource_cost": resource_cost,
			"action_cost": action_cost,
			"optional": optional,
			"builder": builder,
		}
	)


static func triggered_units_at(definition_id: StringName) -> Array:
	return (_triggered.get(definition_id, []) as Array).duplicate()


static func has_triggered(definition_id: StringName) -> bool:
	return not triggered_units_at(definition_id).is_empty()


## enter_hand 时点的物理 zone（显现唯一入口；与来源/方式无关）。
static func enter_hand_zone(definition_id: StringName) -> AhcEnums.Zone:
	var data: Dictionary = _definitions.get(definition_id, {})
	return data.get("enter_zone", AhcEnums.Zone.HAND) as AhcEnums.Zone


## 显现后仍在 limbo 时弃入的牌堆：`owner_discard` | `encounter_discard`。
static func limbo_discard_pile(definition_id: StringName) -> StringName:
	var data: Dictionary = _definitions.get(definition_id, {})
	return data.get("limbo_discard_pile", &"owner_discard") as StringName


static func has_keyword(definition_id: StringName, keyword: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	var keywords: Array = data.get("keywords", [])
	for kw in keywords:
		if kw == keyword:
			return true
	return false


static func is_hunter(definition_id: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("hunter", false):
		return true
	return has_keyword(definition_id, &"hunter")


static func is_retaliate(definition_id: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("retaliate", false):
		return true
	return has_keyword(definition_id, &"retaliate")


static func is_massive(definition_id: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("massive", false):
		return true
	return has_keyword(definition_id, &"massive")


static func has_surge(definition_id: StringName) -> bool:
	return has_keyword(definition_id, &"surge")


static func has_peril(definition_id: StringName) -> bool:
	return has_keyword(definition_id, &"peril")


static func is_permanent(definition_id: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("permanent", false):
		return true
	return has_keyword(definition_id, &"permanent")


static func card_type(definition_id: StringName) -> StringName:
	var data: Dictionary = _definitions.get(definition_id, {})
	return data.get("card_type", &"treachery") as StringName


static func resource_cost(definition_id: StringName) -> int:
	var data: Dictionary = _definitions.get(definition_id, {})
	return int(data.get("resource_cost", 0))


static func action_cost(definition_id: StringName) -> int:
	var data: Dictionary = _definitions.get(definition_id, {})
	return int(data.get("action_cost", 0))


static func spawn_spec(definition_id: StringName) -> SpawnInstructionSpec:
	var data: Dictionary = _definitions.get(definition_id, {})
	var spec = data.get("spawn_instruction", null)
	if spec is SpawnInstructionSpec:
		return spec
	return SpawnInstructionSpec.framework_default()


static func is_aloof(definition_id: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("aloof", false):
		return true
	return has_keyword(definition_id, &"aloof")


static func is_hidden(definition_id: StringName) -> bool:
	## 卡牌是否带 **隐私（Hidden）** 关键词。见 docs/design/15-timing-entry-catalog.md §17.4.3。
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("hidden", false):
		return true
	return has_keyword(definition_id, &"hidden")


static func is_weakness(definition_id: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("is_weakness", false):
		return true
	return has_keyword(definition_id, &"weakness")


static func enemy_stats(definition_id: StringName) -> Dictionary:
	var data: Dictionary = _definitions.get(definition_id, {})
	var stats: Variant = data.get("enemy", {})
	if stats is Dictionary:
		return stats
	return {}


static func prey_spec(definition_id: StringName) -> PreyInstructionSpec:
	var data: Dictionary = _definitions.get(definition_id, {})
	var spec = data.get("prey_instruction", null)
	if spec is PreyInstructionSpec:
		return spec
	return null
