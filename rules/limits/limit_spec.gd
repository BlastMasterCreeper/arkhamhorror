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
## BY_CARD_TYPE 时用（asset / enemy / …）。
var card_type: StringName = &""
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


## Max N … per period · 同名 TITLE 合计（Dilemma 等）。
static func max_title_per_period(
	amount: int,
	period: AhcEnums.LimitPeriod,
	title_key: StringName = &"",
	limit_id: StringName = &"max_title"
) -> LimitSpec:
	var s := LimitSpec.new()
	s.id = limit_id
	s.kind = AhcEnums.LimitKind.INITIATE_QUOTA
	s.amount = amount
	s.period = period
	s.audience = AhcEnums.LimitAudience.TITLE
	s.title_key = title_key
	return s


## Limit once for each investigator per round（Minh 等）。
static func once_per_target_investigator(
	period: AhcEnums.LimitPeriod = AhcEnums.LimitPeriod.ROUND,
	limit_id: StringName = &"per_target_investigator"
) -> LimitSpec:
	var s := LimitSpec.new()
	s.id = limit_id
	s.kind = AhcEnums.LimitKind.INITIATE_QUOTA
	s.amount = 1
	s.period = period
	s.audience = AhcEnums.LimitAudience.PER_TARGET_INVESTIGATOR
	return s


## Limit once per game for each vehicle / asset instance。
static func once_per_asset_instance(
	period: AhcEnums.LimitPeriod = AhcEnums.LimitPeriod.GAME,
	limit_id: StringName = &"per_asset_instance"
) -> LimitSpec:
	var s := LimitSpec.new()
	s.id = limit_id
	s.kind = AhcEnums.LimitKind.INITIATE_QUOTA
	s.amount = 1
	s.period = period
	s.audience = AhcEnums.LimitAudience.PER_ASSET_INSTANCE
	return s


static func max_committed_per_test(amount: int = 1) -> LimitSpec:
	var s := LimitSpec.new()
	s.id = &"max_committed"
	s.kind = AhcEnums.LimitKind.COMMIT_MAX
	s.amount = amount
	s.period = AhcEnums.LimitPeriod.SKILL_TEST
	s.audience = AhcEnums.LimitAudience.TITLE
	return s


static func use_per_attack(amount: int = 3, limit_id: StringName = &"per_attack") -> LimitSpec:
	var s := LimitSpec.new()
	s.id = limit_id
	s.kind = AhcEnums.LimitKind.USE_QUOTA
	s.amount = amount
	s.period = AhcEnums.LimitPeriod.ATTACK
	s.audience = AhcEnums.LimitAudience.PLAYER
	return s


static func use_per_investigation(amount: int = 3, limit_id: StringName = &"per_investigation") -> LimitSpec:
	var s := LimitSpec.new()
	s.id = limit_id
	s.kind = AhcEnums.LimitKind.USE_QUOTA
	s.amount = amount
	s.period = AhcEnums.LimitPeriod.INVESTIGATION
	s.audience = AhcEnums.LimitAudience.PLAYER
	return s


static func resources_per_round(amount: int = 5, limit_id: StringName = &"resources_per_round") -> LimitSpec:
	var s := LimitSpec.new()
	s.id = limit_id
	s.kind = AhcEnums.LimitKind.EVENT_QUOTA
	s.amount = amount
	s.period = AhcEnums.LimitPeriod.ROUND
	s.audience = AhcEnums.LimitAudience.PLAYER
	s.event_key = &"resource_gain"
	return s


static func success_per_game(amount: int = 1, group: bool = false) -> LimitSpec:
	var s := LimitSpec.new()
	s.id = &"group_success_per_game" if group else &"success_per_game"
	s.kind = AhcEnums.LimitKind.EVENT_QUOTA
	s.amount = amount
	s.period = AhcEnums.LimitPeriod.GAME
	s.audience = (
		AhcEnums.LimitAudience.GROUP if group else AhcEnums.LimitAudience.PLAYER
	)
	s.event_key = &"success"
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


static func limit_in_play(amount: int = 1, by_trait: StringName = &"") -> LimitSpec:
	var s := LimitSpec.new()
	s.id = &"in_play"
	s.kind = AhcEnums.LimitKind.ZONE_OCCUPANCY
	s.amount = amount
	s.period = AhcEnums.LimitPeriod.NONE
	s.zone = AhcEnums.ZoneConstraint.IN_PLAY
	if by_trait != &"":
		s.match = AhcEnums.OccupancyMatch.BY_TRAIT
		s.trait_name = by_trait
	return s


static func limit_attached(
	amount: int = 1,
	by_card_type: StringName = &"asset",
	by_trait: StringName = &""
) -> LimitSpec:
	var s := LimitSpec.new()
	s.id = &"attached"
	s.kind = AhcEnums.LimitKind.ZONE_OCCUPANCY
	s.amount = amount
	s.period = AhcEnums.LimitPeriod.NONE
	s.zone = AhcEnums.ZoneConstraint.ATTACHED
	if by_trait != &"":
		s.match = AhcEnums.OccupancyMatch.BY_TRAIT
		s.trait_name = by_trait
	elif by_card_type != &"":
		s.match = AhcEnums.OccupancyMatch.BY_CARD_TYPE
		s.card_type = by_card_type
	else:
		s.match = AhcEnums.OccupancyMatch.ANY
	return s


static func limit_beneath(amount: int = 3) -> LimitSpec:
	var s := LimitSpec.new()
	s.id = &"beneath"
	s.kind = AhcEnums.LimitKind.ZONE_OCCUPANCY
	s.amount = amount
	s.period = AhcEnums.LimitPeriod.NONE
	s.zone = AhcEnums.ZoneConstraint.BENEATH
	s.match = AhcEnums.OccupancyMatch.ANY
	return s


static func limit_per_asset(amount: int = 1, by_trait: StringName = &"") -> LimitSpec:
	var s := LimitSpec.new()
	s.id = &"per_asset"
	s.kind = AhcEnums.LimitKind.ZONE_OCCUPANCY
	s.amount = amount
	s.period = AhcEnums.LimitPeriod.NONE
	s.zone = AhcEnums.ZoneConstraint.PER_ASSET
	if by_trait != &"":
		s.match = AhcEnums.OccupancyMatch.BY_TRAIT
		s.trait_name = by_trait
	return s


static func limit_per_enemy(amount: int = 1, by_trait: StringName = &"") -> LimitSpec:
	var s := LimitSpec.new()
	s.id = &"per_enemy"
	s.kind = AhcEnums.LimitKind.ZONE_OCCUPANCY
	s.amount = amount
	s.period = AhcEnums.LimitPeriod.NONE
	s.zone = AhcEnums.ZoneConstraint.PER_ENEMY
	if by_trait != &"":
		s.match = AhcEnums.OccupancyMatch.BY_TRAIT
		s.trait_name = by_trait
	return s


static func limit_per_agenda_act(amount: int = 1, by_trait: StringName = &"") -> LimitSpec:
	var s := LimitSpec.new()
	s.id = &"per_agenda_act"
	s.kind = AhcEnums.LimitKind.ZONE_OCCUPANCY
	s.amount = amount
	s.period = AhcEnums.LimitPeriod.NONE
	s.zone = AhcEnums.ZoneConstraint.PER_AGENDA_ACT
	if by_trait != &"":
		s.match = AhcEnums.OccupancyMatch.BY_TRAIT
		s.trait_name = by_trait
	return s


static func limit_per_deck(amount: int = 1, by_trait: StringName = &"") -> LimitSpec:
	var s := LimitSpec.new()
	s.id = &"per_deck"
	s.kind = AhcEnums.LimitKind.DECKBUILDING
	s.amount = amount
	s.period = AhcEnums.LimitPeriod.NONE
	s.zone = AhcEnums.ZoneConstraint.PER_DECK
	if by_trait != &"":
		s.match = AhcEnums.OccupancyMatch.BY_TRAIT
		s.trait_name = by_trait
	return s


## 从 imported JSON / 编译器 dict 水合（字段为枚举名字符串或已是枚举 int）。
static func from_dict(data: Dictionary) -> LimitSpec:
	var s := LimitSpec.new()
	if data.is_empty():
		return s
	s.id = StringName(str(data.get("id", "")))
	s.kind = _parse_limit_kind(data.get("kind", "INITIATE_QUOTA"))
	s.amount = int(data.get("amount", 1))
	s.period = _parse_limit_period(data.get("period", "NONE"))
	s.audience = _parse_limit_audience(data.get("audience", "PLAYER"))
	s.zone = _parse_zone_constraint(data.get("zone", "NONE"))
	s.match = _parse_occupancy_match(data.get("match", "BY_TITLE"))
	s.trait_name = StringName(str(data.get("trait_name", "")))
	s.card_type = StringName(str(data.get("card_type", "")))
	s.event_key = StringName(str(data.get("event_key", "")))
	s.anchor_key = StringName(str(data.get("anchor_key", "")))
	s.title_key = StringName(str(data.get("title_key", "")))
	return s


static func from_variant(item: Variant) -> LimitSpec:
	if item is LimitSpec:
		return item as LimitSpec
	if item is Dictionary:
		return from_dict(item as Dictionary)
	return null


static func _parse_limit_kind(raw: Variant) -> AhcEnums.LimitKind:
	if raw is int:
		return raw as AhcEnums.LimitKind
	match str(raw).to_upper():
		"USE_QUOTA":
			return AhcEnums.LimitKind.USE_QUOTA
		"EVENT_QUOTA":
			return AhcEnums.LimitKind.EVENT_QUOTA
		"COMMIT_MAX":
			return AhcEnums.LimitKind.COMMIT_MAX
		"ZONE_OCCUPANCY":
			return AhcEnums.LimitKind.ZONE_OCCUPANCY
		"DECKBUILDING":
			return AhcEnums.LimitKind.DECKBUILDING
		_:
			return AhcEnums.LimitKind.INITIATE_QUOTA


static func _parse_limit_period(raw: Variant) -> AhcEnums.LimitPeriod:
	if raw is int:
		return raw as AhcEnums.LimitPeriod
	match str(raw).to_upper():
		"TURN":
			return AhcEnums.LimitPeriod.TURN
		"ROUND":
			return AhcEnums.LimitPeriod.ROUND
		"PHASE":
			return AhcEnums.LimitPeriod.PHASE
		"GAME":
			return AhcEnums.LimitPeriod.GAME
		"CAMPAIGN":
			return AhcEnums.LimitPeriod.CAMPAIGN
		"SKILL_TEST":
			return AhcEnums.LimitPeriod.SKILL_TEST
		"ATTACK":
			return AhcEnums.LimitPeriod.ATTACK
		"INVESTIGATION":
			return AhcEnums.LimitPeriod.INVESTIGATION
		"ACT":
			return AhcEnums.LimitPeriod.ACT
		"LOCATION":
			return AhcEnums.LimitPeriod.LOCATION
		"CUSTOM_ANCHOR":
			return AhcEnums.LimitPeriod.CUSTOM_ANCHOR
		_:
			return AhcEnums.LimitPeriod.NONE


static func _parse_limit_audience(raw: Variant) -> AhcEnums.LimitAudience:
	if raw is int:
		return raw as AhcEnums.LimitAudience
	match str(raw).to_upper():
		"GROUP":
			return AhcEnums.LimitAudience.GROUP
		"TITLE":
			return AhcEnums.LimitAudience.TITLE
		"PER_TARGET_INVESTIGATOR":
			return AhcEnums.LimitAudience.PER_TARGET_INVESTIGATOR
		"PER_ASSET_INSTANCE":
			return AhcEnums.LimitAudience.PER_ASSET_INSTANCE
		"PER_ANCHOR":
			return AhcEnums.LimitAudience.PER_ANCHOR
		_:
			return AhcEnums.LimitAudience.PLAYER


static func _parse_zone_constraint(raw: Variant) -> AhcEnums.ZoneConstraint:
	if raw is int:
		return raw as AhcEnums.ZoneConstraint
	match str(raw).to_upper():
		"PER_INVESTIGATOR":
			return AhcEnums.ZoneConstraint.PER_INVESTIGATOR
		"PER_LOCATION":
			return AhcEnums.ZoneConstraint.PER_LOCATION
		"IN_PLAY":
			return AhcEnums.ZoneConstraint.IN_PLAY
		"PER_DECK":
			return AhcEnums.ZoneConstraint.PER_DECK
		"PER_ASSET":
			return AhcEnums.ZoneConstraint.PER_ASSET
		"PER_ENEMY":
			return AhcEnums.ZoneConstraint.PER_ENEMY
		"PER_AGENDA_ACT":
			return AhcEnums.ZoneConstraint.PER_AGENDA_ACT
		"ATTACHED":
			return AhcEnums.ZoneConstraint.ATTACHED
		"BENEATH":
			return AhcEnums.ZoneConstraint.BENEATH
		"VICTORY_DISPLAY":
			return AhcEnums.ZoneConstraint.VICTORY_DISPLAY
		_:
			return AhcEnums.ZoneConstraint.NONE


static func _parse_occupancy_match(raw: Variant) -> AhcEnums.OccupancyMatch:
	if raw is int:
		return raw as AhcEnums.OccupancyMatch
	match str(raw).to_upper():
		"BY_TRAIT":
			return AhcEnums.OccupancyMatch.BY_TRAIT
		"BY_CARD_TYPE":
			return AhcEnums.OccupancyMatch.BY_CARD_TYPE
		"ANY":
			return AhcEnums.OccupancyMatch.ANY
		_:
			return AhcEnums.OccupancyMatch.BY_TITLE


## 从卡面常见括号句 / 非括号 Limit 句编译（竖切）；未知句返回 null。
static func try_parse_paren_clause(text: String) -> LimitSpec:
	var t := text.strip_edges()
	## Max 1 committed per skill test
	var commit_re := RegEx.new()
	commit_re.compile("(?i)^Max\\s+(\\d+)\\s+committed\\s+per\\s+(?:skill\\s+)?test\\.?$")
	var commit_m := commit_re.search(t)
	if commit_m != null:
		return max_committed_per_test(int(commit_m.get_string(1)))
	## (Limit 5 resources per round.)
	var res_re := RegEx.new()
	res_re.compile("(?i)^\\(\\s*Limit\\s+(\\d+)\\s+resources\\s+per\\s+round\\s*\\.?\\)$")
	var res_m := res_re.search(t)
	if res_m != null:
		return resources_per_round(int(res_m.get_string(1)))
	## (Limit 1 success per game.)
	var success_re := RegEx.new()
	success_re.compile(
		"(?i)^\\(\\s*(Group\\s+)?[Ll]imit\\s+(\\d+|once)\\s+success(?:es)?\\s+per\\s+game\\s*\\.?\\)$"
	)
	var success_m := success_re.search(t)
	if success_m != null:
		var group_s := success_m.get_string(1).strip_edges() != ""
		var amt_s := success_m.get_string(2).to_lower()
		var amt := 1 if amt_s == "once" else int(amt_s)
		return success_per_game(amt, group_s)
	## (Limit three times per attack.) / (Limit 3 times per investigation.)
	var use_re := RegEx.new()
	use_re.compile(
		"(?i)^\\(\\s*Limit\\s+(once|twice|thrice|one|two|three|\\d+)\\s+(?:times\\s+)?per\\s+(attack|investigation)\\s*\\.?\\)$"
	)
	var use_m := use_re.search(t)
	if use_m != null:
		var amt := _parse_count_word(use_m.get_string(1))
		var scope := use_m.get_string(2).to_lower()
		if scope == "attack":
			return use_per_attack(amt)
		return use_per_investigation(amt)
	## (Limit once for each investigator per round.)
	var per_target_re := RegEx.new()
	per_target_re.compile(
		"(?i)^\\(\\s*Limit\\s+once\\s+for\\s+each\\s+investigator\\s+per\\s+(turn|round|phase|game)\\s*\\.?\\)$"
	)
	var per_target_m := per_target_re.search(t)
	if per_target_m != null:
		return once_per_target_investigator(_period_from_word(per_target_m.get_string(1)))
	## (Limit once per game for each vehicle.)
	var per_asset_re := RegEx.new()
	per_asset_re.compile(
		"(?i)^\\(\\s*Limit\\s+once\\s+per\\s+(turn|round|phase|game)\\s+for\\s+each\\s+(?:vehicle|asset)\\s*\\.?\\)$"
	)
	var per_asset_m := per_asset_re.search(t)
	if per_asset_m != null:
		return once_per_asset_instance(_period_from_word(per_asset_m.get_string(1)))
	## (Limit 1 attached asset.)
	var attached_re := RegEx.new()
	attached_re.compile(
		"(?i)^\\(\\s*Limit\\s+(\\d+)\\s+attached\\s+(asset|event|skill|enemy|treachery|cards?)\\s*\\.?\\)$"
	)
	var attached_m := attached_re.search(t)
	if attached_m != null:
		var n := int(attached_m.get_string(1))
		var ct := attached_m.get_string(2).to_lower()
		if ct.begins_with("card"):
			return limit_attached(n, &"")
		return limit_attached(n, StringName(ct))
	## (max 3 cards beneath her) / (max 3 cards beneath)
	var beneath_re := RegEx.new()
	beneath_re.compile("(?i)^\\(?\\s*max\\s+(\\d+)\\s+cards?\\s+beneath(?:\\s+\\w+)?\\s*\\.?\\)?$")
	var beneath_m := beneath_re.search(t)
	if beneath_m != null:
		return limit_beneath(int(beneath_m.get_string(1)))
	## Max 2 [[Dilemma]] per round
	var max_trait_re := RegEx.new()
	max_trait_re.compile(
		"(?i)^Max\\s+(\\d+)\\s+\\[\\[([^\\]]+)\\]\\]\\s+per\\s+(turn|round|phase|game)\\.?$"
	)
	var max_trait_m := max_trait_re.search(t)
	if max_trait_m != null:
		var s := max_title_per_period(
			int(max_trait_m.get_string(1)),
			_period_from_word(max_trait_m.get_string(3)),
			StringName(max_trait_m.get_string(2).strip_edges())
		)
		## 运行时 TITLE 键用 trait 名作 title_key；真正按 trait 过滤留给编译器。
		s.id = &"max_trait_period"
		return s
	## Max 1 per attack / Max 1 per game（TITLE）
	var max_per_re := RegEx.new()
	max_per_re.compile(
		"(?i)^Max\\s+(\\d+)\\s+per\\s+(turn|round|phase|game|attack|investigation)\\.?$"
	)
	var max_per_m := max_per_re.search(t)
	if max_per_m != null:
		var period := _period_from_word(max_per_m.get_string(2))
		return max_title_per_period(int(max_per_m.get_string(1)), period)
	## Limit 1 [[Trait]] in play / Limit 1 Title in play
	var in_play_re := RegEx.new()
	in_play_re.compile(
		"(?i)^Limit\\s+(\\d+)\\s+(?:\\[\\[([^\\]]+)\\]\\]|(.+?))\\s+in\\s+play\\.?$"
	)
	var in_play_m := in_play_re.search(t)
	if in_play_m != null:
		var trait_s := in_play_m.get_string(2).strip_edges()
		if trait_s != "":
			return limit_in_play(int(in_play_m.get_string(1)), StringName(trait_s))
		return limit_in_play(int(in_play_m.get_string(1)))
	## Limit 1 [[Trait]] per investigator / location / deck / asset / enemy
	var occ_re := RegEx.new()
	occ_re.compile(
		"(?i)^Limit\\s+(\\d+)\\s+(?:\\[\\[([^\\]]+)\\]\\]\\s+)?per\\s+(investigator|location|deck|asset|enemy|agenda\\/act)\\.?$"
	)
	var occ_m := occ_re.search(t)
	if occ_m != null:
		var n := int(occ_m.get_string(1))
		var trait_s := occ_m.get_string(2).strip_edges()
		var trait_n: StringName = StringName(trait_s) if trait_s != "" else &""
		match occ_m.get_string(3).to_lower():
			"investigator":
				return limit_per_investigator(n, trait_n)
			"location":
				return limit_per_location(n, trait_n)
			"deck":
				return limit_per_deck(n, trait_n)
			"asset":
				return limit_per_asset(n, trait_n)
			"enemy":
				return limit_per_enemy(n, trait_n)
			"agenda/act":
				return limit_per_agenda_act(n, trait_n)
			_:
				pass
	var m := RegEx.new()
	m.compile("(?i)^\\(\\s*(Group\\s+)?limit\\s+(once|\\d+)\\s+per\\s+(turn|round|phase|game)\\s*\\.?\\)$")
	var found := m.search(t)
	if found == null:
		return null
	var group := found.get_string(1).strip_edges() != ""
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
	s.period = _period_from_word(period_s)
	match period_s:
		"turn":
			s.id = &"per_turn"
		"round":
			s.id = &"per_round"
		"phase":
			s.id = &"per_phase"
		"game":
			s.id = &"per_game"
		_:
			return null
	if group:
		s.id = StringName("group_%s" % String(s.id))
	return s


static func _period_from_word(raw: String) -> AhcEnums.LimitPeriod:
	match raw.to_lower():
		"turn":
			return AhcEnums.LimitPeriod.TURN
		"round":
			return AhcEnums.LimitPeriod.ROUND
		"phase":
			return AhcEnums.LimitPeriod.PHASE
		"game":
			return AhcEnums.LimitPeriod.GAME
		"attack":
			return AhcEnums.LimitPeriod.ATTACK
		"investigation":
			return AhcEnums.LimitPeriod.INVESTIGATION
		_:
			return AhcEnums.LimitPeriod.NONE


static func _parse_count_word(raw: String) -> int:
	match raw.to_lower():
		"once", "one":
			return 1
		"twice", "two":
			return 2
		"thrice", "three":
			return 3
		_:
			return maxi(int(raw), 1)
