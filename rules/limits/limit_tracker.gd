class_name LimitTracker
extends RefCounted

## Limit / Max 配额门槛（06d）。权威计数可重建自 EventRecord；本竖切用增量计数。

var _counts: Dictionary = {}  # counter_key -> int
var _ignores: Dictionary = {}  # ignore_key -> true


func clear() -> void:
	_counts.clear()
	_ignores.clear()


func can_initiate(
	spec: LimitSpec,
	ability_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	title_key: StringName = &""
) -> bool:
	if spec == null or spec.kind != AhcEnums.LimitKind.INITIATE_QUOTA:
		return true
	if _is_ignored(spec, ability_id, controller_id, title_key):
		return true
	var key := _counter_key(spec, ability_id, controller_id, game_ctx, title_key)
	return int(_counts.get(key, 0)) < spec.amount


func record_commence(
	spec: LimitSpec,
	ability_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	title_key: StringName = &""
) -> void:
	if spec == null or spec.kind != AhcEnums.LimitKind.INITIATE_QUOTA:
		return
	var key := _counter_key(spec, ability_id, controller_id, game_ctx, title_key)
	_counts[key] = int(_counts.get(key, 0)) + 1


func record_commence_all(
	specs: Array,
	ability_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	title_key: StringName = &""
) -> void:
	for s in specs:
		if s is LimitSpec:
			record_commence(s as LimitSpec, ability_id, controller_id, game_ctx, title_key)


func can_initiate_all(
	specs: Array,
	ability_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	title_key: StringName = &""
) -> bool:
	for s in specs:
		if s is LimitSpec and not can_initiate(
			s as LimitSpec, ability_id, controller_id, game_ctx, title_key
		):
			return false
	return true


## Ignore the limit：按 LimitSpec 身份跳过后续检查（直至 clear_ignore）。
func ignore_limit(
	spec: LimitSpec,
	ability_id: StringName = &"",
	controller_id: StringName = &"",
	title_key: StringName = &""
) -> void:
	if spec == null:
		return
	_ignores[_ignore_key(spec, ability_id, controller_id, title_key)] = true


func clear_ignore(
	spec: LimitSpec,
	ability_id: StringName = &"",
	controller_id: StringName = &"",
	title_key: StringName = &""
) -> void:
	if spec == null:
		return
	_ignores.erase(_ignore_key(spec, ability_id, controller_id, title_key))


func count_in_play_for_occupancy(
	spec: LimitSpec,
	game_ctx: GameContext,
	controller_id: StringName,
	definition_id: StringName,
	location_id: StringName = &""
) -> int:
	if (
		spec == null
		or spec.kind != AhcEnums.LimitKind.ZONE_OCCUPANCY
		or game_ctx == null
		or game_ctx.state == null
	):
		return 0
	var n := 0
	for card_id in game_ctx.state.registry.all_card_ids():
		var card = game_ctx.state.registry.get_card(card_id)
		if card == null:
			continue
		if not _card_in_occupancy_zone(card, spec, controller_id, location_id):
			continue
		if not _occupancy_matches(card.id.definition_id, definition_id, spec):
			continue
		n += 1
	return n


func can_enter_zone(
	spec: LimitSpec,
	game_ctx: GameContext,
	controller_id: StringName,
	definition_id: StringName,
	location_id: StringName = &""
) -> bool:
	if spec == null or spec.kind != AhcEnums.LimitKind.ZONE_OCCUPANCY:
		return true
	if _is_ignored(spec, definition_id, controller_id, &""):
		return true
	return (
		count_in_play_for_occupancy(spec, game_ctx, controller_id, definition_id, location_id)
		< spec.amount
	)


func can_enter_zone_all(
	specs: Array,
	game_ctx: GameContext,
	controller_id: StringName,
	definition_id: StringName,
	location_id: StringName = &""
) -> bool:
	for s in specs:
		if s is LimitSpec and not can_enter_zone(
			s as LimitSpec, game_ctx, controller_id, definition_id, location_id
		):
			return false
	return true


func _is_ignored(
	spec: LimitSpec,
	ability_id: StringName,
	controller_id: StringName,
	title_key: StringName
) -> bool:
	return _ignores.has(_ignore_key(spec, ability_id, controller_id, title_key))


func _ignore_key(
	spec: LimitSpec,
	ability_id: StringName,
	controller_id: StringName,
	title_key: StringName
) -> String:
	return "%s|%s|%s|%s|%s" % [
		String(spec.id),
		str(spec.kind),
		String(ability_id),
		String(title_key),
		String(controller_id) if spec.audience == AhcEnums.LimitAudience.PLAYER else "*",
	]


func _counter_key(
	spec: LimitSpec,
	ability_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	title_key: StringName
) -> String:
	var unit := String(ability_id)
	if spec.audience == AhcEnums.LimitAudience.TITLE:
		unit = String(title_key) if title_key != &"" else unit
	var who := "*"
	match spec.audience:
		AhcEnums.LimitAudience.PLAYER, AhcEnums.LimitAudience.PER_TARGET_INVESTIGATOR:
			who = String(controller_id)
		AhcEnums.LimitAudience.GROUP:
			who = "group"
		AhcEnums.LimitAudience.TITLE:
			who = "title"
		_:
			who = String(controller_id)
	return "%s|%s|%s|%s|%s|%s" % [
		str(spec.kind),
		String(spec.id),
		unit,
		who,
		str(spec.period),
		_epoch(spec.period, game_ctx),
	]


func _epoch(period: AhcEnums.LimitPeriod, game_ctx: GameContext) -> String:
	var state: GameStateStore = game_ctx.state if game_ctx != null else null
	match period:
		AhcEnums.LimitPeriod.TURN:
			return "t:%d" % (state.turn_id if state else 0)
		AhcEnums.LimitPeriod.ROUND:
			return "r:%d" % (state.round_number if state else 0)
		AhcEnums.LimitPeriod.PHASE:
			return "p:%d:%d" % [
				state.round_number if state else 0,
				int(game_ctx.get_current_framework_step()) if game_ctx else 0,
			]
		AhcEnums.LimitPeriod.GAME, AhcEnums.LimitPeriod.NONE:
			return "g"
		AhcEnums.LimitPeriod.CAMPAIGN:
			return "c"
		_:
			return "x:%d" % int(period)


func _card_in_occupancy_zone(
	card,
	spec: LimitSpec,
	controller_id: StringName,
	location_id: StringName
) -> bool:
	match spec.zone:
		AhcEnums.ZoneConstraint.PER_INVESTIGATOR:
			if (
				card.zone != AhcEnums.Zone.PLAY_AREA
				and card.zone != AhcEnums.Zone.THREAT_AREA
				and card.zone != AhcEnums.Zone.ATTACHED
			):
				return false
			return card.controller_id == controller_id or card.owner_id == controller_id
		AhcEnums.ZoneConstraint.IN_PLAY:
			return (
				card.zone == AhcEnums.Zone.PLAY_AREA
				or card.zone == AhcEnums.Zone.THREAT_AREA
				or card.zone == AhcEnums.Zone.LOCATION_AREA
				or card.zone == AhcEnums.Zone.ATTACHED
			)
		AhcEnums.ZoneConstraint.PER_LOCATION:
			if location_id == &"":
				return false
			if card.zone == AhcEnums.Zone.ATTACHED and card.attached_to != null:
				return (
					card.attached_to.instance_id == location_id
					or card.attached_to.definition_id == location_id
				)
			return false
		_:
			return false


func _occupancy_matches(
	card_def: StringName,
	incoming_def: StringName,
	spec: LimitSpec
) -> bool:
	if spec.match == AhcEnums.OccupancyMatch.BY_TRAIT:
		if spec.trait_name == &"":
			return false
		for t in CardRegistry.traits(card_def):
			if StringName(str(t).to_lower()) == StringName(String(spec.trait_name).to_lower()):
				return true
			## ArkhamDB traits 常带空格/大小写
			if str(t).to_lower() == String(spec.trait_name).to_lower():
				return true
		return false
	## BY_TITLE：同 definition 或同 title 字符串
	if card_def == incoming_def:
		return true
	var a := CardRegistry.title(card_def)
	var b := CardRegistry.title(incoming_def)
	return a != "" and a == b
