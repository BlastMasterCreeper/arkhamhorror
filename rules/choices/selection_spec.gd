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
	s.min_picks = mini(min_picks, max_picks)
	s.max_picks = maxi(max_picks, s.min_picks)
	s.default_policy = &"first_option"
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
	req.deadline_ms = deadline_ms
	req.context = {
		"bind_key": bind_key,
		"bind_shape": bind_shape,
		"default_policy": default_policy,
	}
	return req
