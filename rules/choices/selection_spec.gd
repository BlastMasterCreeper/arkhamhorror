class_name SelectionSpec
extends RefCounted

## 通用选择规格（静态）。见 docs/design/21-selection-spec.md


var choice_kind: AhcEnums.ChoiceKind = AhcEnums.ChoiceKind.PICK_TARGET
var filter: CandidateFilter = null
var min_picks: int = 1
var max_picks: int = 1
var prompt_id: StringName = &"pick:target"
var decider: StringName = &"controller"
var default_policy: StringName = &"first_option"
var deadline_ms: int = -1
## ChoiceBind
var bind_key: StringName = &"picked_enemy"
var bind_shape: StringName = &"entity"
## V 层：依赖所选目标的效果尾；null = 不做候选 dry-run（可由 SEQ 兄弟自动填）。
var viability_tail: CompositionNode = null
## true = 显式跳过 V（即使有后续 SEQ 兄弟 / 已标注 tail）。
var skip_viability: bool = false
## explicit_choose / implicit_attack / implicit_evade / implicit_investigate
var role: StringName = &"explicit_choose"


static func pick_entity(
	filter: CandidateFilter,
	prompt_id: StringName,
	bind_key: StringName = &"picked_enemy",
	min_picks: int = 1,
	max_picks: int = 1
) -> SelectionSpec:
	var s := SelectionSpec.new()
	s.choice_kind = (
		AhcEnums.ChoiceKind.PICK_MULTI if max_picks > 1 or min_picks != 1
		else AhcEnums.ChoiceKind.PICK_TARGET
	)
	s.filter = filter
	s.prompt_id = prompt_id
	s.bind_key = bind_key
	s.bind_shape = &"entity_list" if s.choice_kind == AhcEnums.ChoiceKind.PICK_MULTI else &"entity"
	s.min_picks = mini(min_picks, max_picks) if max_picks >= 0 else min_picks
	s.max_picks = maxi(max_picks, s.min_picks)
	## up to N（min=0）默认跳过；exactly/at-least 取前 N。
	s.default_policy = &"skip" if s.min_picks <= 0 else &"first_option"
	return s


## 糖：多选实体 → PICK_MULTI + entity_list（21 §4.1）。
static func pick_multi(
	filter: CandidateFilter,
	prompt_id: StringName,
	bind_key: StringName = &"picked_enemies",
	min_picks: int = 1,
	max_picks: int = 2
) -> SelectionSpec:
	var s := pick_entity(filter, prompt_id, bind_key, min_picks, maxi(max_picks, 1))
	s.choice_kind = AhcEnums.ChoiceKind.PICK_MULTI
	s.bind_shape = &"entity_list"
	return s


## 基础 Fight / Attack 隐式敌人目标（21 §3.2）。
static func implicit_attack(controller_id: StringName = &"") -> SelectionSpec:
	var s := pick_entity(
		CandidateFilter.from_preset(&"enemy_fight_target"),
		&"pick:fight_enemy",
		&"picked_enemy"
	)
	s.role = &"implicit_attack"
	s.viability_tail = CompositionNode.deal_damage_enemy(
		controller_id, &"memory:picked_enemy", 1
	)
	return s


## 基础 Evade 隐式敌人目标（21 §3.2）。
static func implicit_evade(controller_id: StringName = &"") -> SelectionSpec:
	var s := pick_entity(
		CandidateFilter.from_preset(&"enemy_evade_target"),
		&"pick:evade_enemy",
		&"picked_enemy"
	)
	s.role = &"implicit_evade"
	s.viability_tail = CompositionNode.seq([
		CompositionNode.exhaust_enemy(controller_id, &"memory:picked_enemy"),
		CompositionNode.disengage_enemy(controller_id, &"memory:picked_enemy"),
	])
	return s


## 基础 Investigate 隐式地点（所在地；非多选 Gate）。
static func implicit_investigate(controller_id: StringName = &"") -> SelectionSpec:
	var s := pick_entity(
		CandidateFilter.from_preset(&"location_investigate_target"),
		&"pick:investigate_location",
		&"picked_location"
	)
	s.role = &"implicit_investigate"
	## 0 clue 仍可调查；V 仅确认地点存在即可（skip：由 resolve_investigate 结构校验）。
	s.skip_viability = true
	return s


static func from_pick_target_params(params: Dictionary) -> SelectionSpec:
	var filter := CandidateFilter.from_variant(params.get("filter", "enemy_at_connecting"))
	var min_p := int(params.get("min", params.get("min_picks", 1)))
	var max_p := int(params.get("max", params.get("max_picks", 1)))
	var bind_key := StringName(str(params.get("memory_key", params.get("bind_key", "picked_enemy"))))
	var prompt := StringName(str(params.get("prompt_id", "pick:target")))
	var s := pick_entity(filter, prompt, bind_key, min_p, max_p)
	if params.has("bind") and typeof(params["bind"]) == TYPE_DICTIONARY:
		var b: Dictionary = params["bind"]
		if b.has("key"):
			s.bind_key = StringName(str(b["key"]))
		if b.has("shape"):
			s.bind_shape = StringName(str(b["shape"]))
	if params.has("decider"):
		s.decider = StringName(str(params["decider"]))
	if params.has("deadline_ms"):
		s.deadline_ms = int(params["deadline_ms"])
	return s


func to_choice_request(
	candidates: Array,
	decider_id: StringName
) -> ChoiceRequest:
	var req := ChoiceRequest.new()
	req.kind = choice_kind
	req.decider_id = decider_id
	req.prompt_id = prompt_id
	req.options = candidates.duplicate()
	req.min_picks = min_picks
	req.max_picks = max_picks
	req.default_index = 0
	req.default_policy = default_policy
	req.deadline_ms = deadline_ms
	req.context = {
		"bind_key": bind_key,
		"bind_shape": bind_shape,
		"default_policy": default_policy,
	}
	return req
