class_name CardRegistry
extends RefCounted

static var _definitions: Dictionary = {}
static var _revelations: Dictionary = {}
static var _on_play: Dictionary = {}
static var _triggered: Dictionary = {}


static func register_definition(definition_id: StringName, data: Dictionary = {}) -> void:
	_definitions[definition_id] = data


static func patch_definition(definition_id: StringName, data: Dictionary) -> void:
	var base: Dictionary = _definitions.get(definition_id, {})
	if base.is_empty():
		_definitions[definition_id] = data.duplicate()
	else:
		var merged := base.duplicate()
		merged.merge(data, true)
		_definitions[definition_id] = merged


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


## Uses (X type) · Domain 进场规格；空 = 无 Uses。
static func uses_spec(definition_id: StringName) -> Dictionary:
	var data := definition_data(definition_id)
	var raw: Variant = data.get("uses", {})
	if raw is Dictionary and not (raw as Dictionary).is_empty():
		var d: Dictionary = (raw as Dictionary).duplicate()
		if not d.has("type"):
			d["type"] = &"charges"
		if not d.has("count"):
			d["count"] = 0
		d["type"] = StringName(str(d.get("type", "charges")))
		d["count"] = int(d.get("count", 0))
		return d
	return parse_uses_from_text(str(data.get("text", "")))


## Seal 关键词规格；null = 无 Seal 打出额外费用。
## 来源：定义 `seal` 字段 · keywords 含 seal + 正文 `Seal (…)` · 或正文印刷 `Seal (…)`。
## 「seal a random…」效果句（无括号种类）不匹配，不走打出费用。
static func seal_spec(definition_id: StringName) -> SealSpec:
	var data := definition_data(definition_id)
	if data.has("seal"):
		var raw: Variant = data.get("seal")
		if raw is SealSpec:
			return raw as SealSpec
		if raw is Dictionary:
			return SealSpec.from_dictionary(raw as Dictionary)
		if raw is String or raw is StringName:
			var from_str := SealSpec.from_dictionary({"kind": str(raw)})
			if from_str != null:
				return from_str
	var from_text := SealSpec.parse_from_text(str(data.get("text", "")))
	if from_text != null:
		return from_text
	if has_keyword(definition_id, &"seal"):
		## 仅标 seal、无括号：视为随机封印（极少）。
		return SealSpec.random_any()
	return null


static func has_seal_play_cost(definition_id: StringName) -> bool:
	var spec := seal_spec(definition_id)
	return spec != null and spec.as_play_cost


## 调查员 `[elder_sign] effect` 规格字典；空 = 无印刷旧印能力。
static func elder_sign_effect(definition_id: StringName) -> Dictionary:
	var data := definition_data(definition_id)
	var raw: Variant = data.get("elder_sign", {})
	if raw is Dictionary and not (raw as Dictionary).is_empty():
		return (raw as Dictionary).duplicate(true)
	return parse_elder_sign_from_text(str(data.get("text", "")))


## 从正文解析常见 Core 旧印句（竖切够用；复杂句靠 JSON `elder_sign`）。
static func parse_elder_sign_from_text(text: String) -> Dictionary:
	if text.is_empty():
		return {}
	var re := RegEx.new()
	if re.compile("(?i)\\[elder_sign\\]\\s*effect:\\s*([^\\n]+)") != OK:
		return {}
	var m := re.search(text)
	if m == null:
		return {}
	var line := m.get_string(1).strip_edges()
	var out := {}
	var mod_re := RegEx.new()
	if mod_re.compile("^([+-]?\\d+)") == OK:
		var mm := mod_re.search(line)
		if mm != null:
			out["modifier"] = int(mm.get_string(1))
	## If you succeed, draw N card and gain M resource
	var succ_re := RegEx.new()
	if (
		succ_re.compile(
			"(?i)If you succeed,?\\s*draw\\s+(\\d+)\\s+cards?(?:\\s+and\\s+gain\\s+(\\d+)\\s+resources?)?"
		)
		== OK
	):
		var sm := succ_re.search(line)
		if sm != null:
			var steps: Array = [
				{"template": "draw", "amount": int(sm.get_string(1))}
			]
			if sm.get_string(2) != "":
				steps.append(
					{"template": "gain_resources", "amount": int(sm.get_string(2))}
				)
			out["on_success"] = {"template": "seq", "steps": steps}
			return out
	## If you succeed, heal N horror
	var heal_re := RegEx.new()
	if heal_re.compile("(?i)If you succeed,?\\s*heal\\s+(\\d+)\\s+horror") == OK:
		var hm := heal_re.search(line)
		if hm != null:
			out["on_success"] = {
				"template": "heal",
				"kind": "horror",
				"amount": int(hm.get_string(1)),
			}
			return out
	return out


static func parse_uses_from_text(text: String) -> Dictionary:
	if text.is_empty():
		return {}
	var re := RegEx.new()
	## Uses (3 charges) / Uses (4 ammo) …
	if re.compile("(?i)Uses\\s*\\((\\d+)\\s+([A-Za-z]+)\\)") != OK:
		return {}
	var m := re.search(text)
	if m == null:
		return {}
	var count := int(m.get_string(1))
	var raw_type := m.get_string(2).to_lower()
	var use_type := raw_type
	if raw_type.begins_with("charge"):
		use_type = "charges"
	elif raw_type.begins_with("ammo"):
		use_type = "ammo"
	elif raw_type.begins_with("secret"):
		use_type = "secrets"
	elif raw_type.begins_with("suppl"):
		use_type = "supplies"
	return {"count": count, "type": StringName(use_type)}


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
	optional: bool = false,
	window: StringName = &"",
	action_types: Array = [],
	provokes_aoo: Variant = null
) -> void:
	if not _triggered.has(definition_id):
		_triggered[definition_id] = []
	var unit := {
		"ability_id": ability_id,
		"match_kind": match_kind,
		"phase": phase,
		"ability_kind": ability_kind,
		"resource_cost": resource_cost,
		"action_cost": action_cost,
		"optional": optional,
		"window": window,
		"action_types": action_types.duplicate(),
		"builder": builder,
	}
	if provokes_aoo != null:
		unit["provokes_aoo"] = bool(provokes_aoo)
	(_triggered[definition_id] as Array).append(unit)


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
	if data.has("limbo_discard_pile"):
		return data.get("limbo_discard_pile") as StringName
	## 遭遇 treachery / enemy 默认进遭遇弃牌堆。
	var card_type: StringName = data.get("card_type", &"") as StringName
	if card_type == &"treachery" or card_type == &"enemy":
		return &"encounter_discard"
	return &"owner_discard"


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


static func is_patrol(definition_id: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("patrol", false):
		return true
	return has_keyword(definition_id, &"patrol")


static func patrol_spec(definition_id: StringName) -> PatrolTargetSpec:
	var data: Dictionary = _definitions.get(definition_id, {})
	var spec = data.get("patrol_instruction", null)
	if spec is PatrolTargetSpec:
		return spec
	return null


static func is_retaliate(definition_id: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("retaliate", false):
		return true
	return has_keyword(definition_id, &"retaliate")


static func is_alert(definition_id: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("alert", false):
		return true
	return has_keyword(definition_id, &"alert")


static func is_elusive(definition_id: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("elusive", false):
		return true
	return has_keyword(definition_id, &"elusive")


static func is_massive(definition_id: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("massive", false):
		return true
	return has_keyword(definition_id, &"massive")


static func is_doomed(definition_id: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("doomed", false):
		return true
	return has_keyword(definition_id, &"doomed")


static func victory_points(definition_id: StringName) -> int:
	var data: Dictionary = _definitions.get(definition_id, {})
	return int(data.get("victory", 0))


## 印刷生命（支援等）；0 = 无生命 / 不因伤害自动击败。
static func printed_health(definition_id: StringName) -> int:
	return int(definition_data(definition_id).get("health", 0))


## 印刷神智（支援等）；0 = 无神智 / 不因恐惧自动击败。
static func printed_sanity(definition_id: StringName) -> int:
	return int(definition_data(definition_id).get("sanity", 0))


static func is_act(definition_id: StringName) -> bool:
	return card_type(definition_id) == &"act"


static func is_agenda(definition_id: StringName) -> bool:
	return card_type(definition_id) == &"agenda"


static func back_text(definition_id: StringName) -> String:
	return str(definition_data(definition_id).get("back_text", ""))


static func back_name(definition_id: StringName) -> String:
	return str(definition_data(definition_id).get("back_name", ""))


static func back_effects(definition_id: StringName) -> Array:
	var raw: Variant = definition_data(definition_id).get("back_effects", [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


static func scenario_objective(definition_id: StringName) -> Dictionary:
	var raw: Variant = definition_data(definition_id).get("objective", {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return {}


static func scenario_doom_threshold(definition_id: StringName) -> int:
	var data := definition_data(definition_id)
	if not data.has("doom"):
		return 7
	var doom_val: Variant = data.get("doom")
	if doom_val == null:
		return -1
	return int(doom_val)


static func scenario_clue_threshold(definition_id: StringName) -> int:
	return location_printed_clues(definition_id)


static func all_definition_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for key in _definitions.keys():
		out.append(key as StringName)
	out.sort()
	return out


static func encounter_code(definition_id: StringName) -> StringName:
	return StringName(str(definition_data(definition_id).get("encounter_code", "")))


static func location_shroud(definition_id: StringName) -> int:
	var loc: Variant = definition_data(definition_id).get("location", {})
	if loc is Dictionary:
		return int((loc as Dictionary).get("shroud", 0))
	return 0


static func location_printed_clues(definition_id: StringName) -> int:
	var loc: Variant = definition_data(definition_id).get("location", {})
	if loc is Dictionary:
		var clues: Variant = (loc as Dictionary).get("clues")
		if clues == null or str(clues) == "dash":
			return -1
		return int(clues)
	return -1


static func goes_in_encounter_deck(definition_id: StringName) -> bool:
	var ctype := card_type(definition_id)
	return ctype == &"enemy" or ctype == &"treachery"


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


## 卡背类型：`player` | `encounter`。只描述无文本背面；与正面 cardtype / CardFace 正交。
static func card_back(definition_id: StringName) -> StringName:
	var data: Dictionary = _definitions.get(definition_id, {})
	var explicit: StringName = data.get("card_back", &"") as StringName
	if explicit == &"player" or explicit == &"encounter":
		return explicit
	return infer_card_back(data)


static func has_player_back(definition_id: StringName) -> bool:
	return card_back(definition_id) == &"player"


static func has_encounter_back(definition_id: StringName) -> bool:
	return card_back(definition_id) == &"encounter"


## 导入缺省推断（可被定义里显式 `card_back` 覆盖）。**不**用此结果代替正面能力包。
static func infer_card_back(data: Dictionary) -> StringName:
	if bool(data.get("is_weakness", false)):
		return &"player"
	var ctype: StringName = data.get("card_type", &"") as StringName
	match ctype:
		&"enemy", &"treachery", &"location", &"act", &"agenda", &"scenario":
			return &"encounter"
		_:
			pass
	## 剧情支援等：有遭遇组 + 玩家正面类型 → 常见遭遇卡背。
	if str(data.get("encounter_code", "")) != "":
		return &"encounter"
	return &"player"


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
