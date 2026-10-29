class_name LimitSpec
extends RefCounted

## 卡面 Limit / Max 声明（06d）。不是 Registration payload。

var id: StringName = &""
var kind: AhcEnums.LimitKind = AhcEnums.LimitKind.INITIATE_QUOTA
var amount: int = 1
var period: AhcEnums.LimitPeriod = AhcEnums.LimitPeriod.ROUND
var audience: AhcEnums.LimitAudience = AhcEnums.LimitAudience.PLAYER
var zone: AhcEnums.ZoneConstraint = AhcEnums.ZoneConstraint.NONE
var match: AhcEnums.OccupancyMatch = AhcEnums.OccupancyMatch.BY_TITLE
var trait_name: StringName = &""
var event_key: StringName = &""
var anchor_key: StringName = &""
## TITLE / 同名合计时用；空则运行时从 source 卡取 title。
var title_key: StringName = &""


static func once_per_round(limit_id: StringName = &"once_per_round") -> LimitSpec:
	var s := LimitSpec.new()
	s.id = limit_id
	s.kind = AhcEnums.LimitKind.INITIATE_QUOTA
	s.amount = 1
	s.period = AhcEnums.LimitPeriod.ROUND
	s.audience = AhcEnums.LimitAudience.PLAYER
	return s


static func once_per_game(limit_id: StringName = &"once_per_game") -> LimitSpec:
	var s := LimitSpec.new()
	s.id = limit_id
	s.kind = AhcEnums.LimitKind.INITIATE_QUOTA
	s.amount = 1
	s.period = AhcEnums.LimitPeriod.GAME
	s.audience = AhcEnums.LimitAudience.PLAYER
	return s


static func once_per_turn(limit_id: StringName = &"once_per_turn") -> LimitSpec:
	var s := LimitSpec.new()
	s.id = limit_id
	s.kind = AhcEnums.LimitKind.INITIATE_QUOTA
	s.amount = 1
	s.period = AhcEnums.LimitPeriod.TURN
	s.audience = AhcEnums.LimitAudience.PLAYER
	return s


static func group_once_per_round(limit_id: StringName = &"group_once_per_round") -> LimitSpec:
	var s := once_per_round(limit_id)
	s.audience = AhcEnums.LimitAudience.GROUP
	return s


static func group_once_per_game(limit_id: StringName = &"group_once_per_game") -> LimitSpec:
	var s := once_per_game(limit_id)
	s.audience = AhcEnums.LimitAudience.GROUP
	return s


static func max_committed_per_test(amount: int = 1) -> LimitSpec:
	var s := LimitSpec.new()
	s.id = &"max_committed"
	s.kind = AhcEnums.LimitKind.COMMIT_MAX
	s.amount = amount
	s.period = AhcEnums.LimitPeriod.SKILL_TEST
	s.audience = AhcEnums.LimitAudience.TITLE
	return s


static func limit_per_investigator(amount: int = 1, by_trait: StringName = &"") -> LimitSpec:
	var s := LimitSpec.new()
	s.id = &"per_investigator"
	s.kind = AhcEnums.LimitKind.ZONE_OCCUPANCY
	s.amount = amount
	s.period = AhcEnums.LimitPeriod.NONE
	s.audience = AhcEnums.LimitAudience.PLAYER
	s.zone = AhcEnums.ZoneConstraint.PER_INVESTIGATOR
	if by_trait != &"":
		s.match = AhcEnums.OccupancyMatch.BY_TRAIT
		s.trait_name = by_trait
	return s


static func limit_per_location(amount: int = 1, by_trait: StringName = &"") -> LimitSpec:
	var s := LimitSpec.new()
	s.id = &"per_location"
	s.kind = AhcEnums.LimitKind.ZONE_OCCUPANCY
	s.amount = amount
	s.period = AhcEnums.LimitPeriod.NONE
	s.zone = AhcEnums.ZoneConstraint.PER_LOCATION
	if by_trait != &"":
		s.match = AhcEnums.OccupancyMatch.BY_TRAIT
		s.trait_name = by_trait
	return s


## 从卡面常见括号句编译（竖切）；未知句返回 null。
static func try_parse_paren_clause(text: String) -> LimitSpec:
	var t := text.strip_edges()
	var group := false
	var m := RegEx.new()
	m.compile("(?i)^\\(\\s*(Group\\s+)?limit\\s+(once|\\d+)\\s+per\\s+(turn|round|phase|game)\\s*\\.?\\)$")
	var found := m.search(t)
	if found == null:
		return null
	group = found.get_string(1).strip_edges() != ""
	var once_or_n := found.get_string(2).to_lower()
	var period_s := found.get_string(3).to_lower()
	var amount := 1
	if once_or_n != "once":
		amount = int(once_or_n)
	var s := LimitSpec.new()
	s.kind = AhcEnums.LimitKind.INITIATE_QUOTA
	s.amount = amount
	s.audience = (
		AhcEnums.LimitAudience.GROUP if group else AhcEnums.LimitAudience.PLAYER
	)
	match period_s:
		"turn":
			s.period = AhcEnums.LimitPeriod.TURN
			s.id = &"per_turn"
		"round":
			s.period = AhcEnums.LimitPeriod.ROUND
			s.id = &"per_round"
		"phase":
			s.period = AhcEnums.LimitPeriod.PHASE
			s.id = &"per_phase"
		"game":
			s.period = AhcEnums.LimitPeriod.GAME
			s.id = &"per_game"
		_:
			return null
	if group:
		s.id = StringName("group_%s" % String(s.id))
	return s
