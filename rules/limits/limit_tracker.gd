class_name LimitTracker
extends RefCounted

## Limit / Max 配额门槛（06d）。
## 运行时 HOT = 增量计数；权威 = EventRecord（LIMIT_CONSUME / LIMIT_IGNORE）可 fold 重建。
## 禁止单独持久化本表——存档应落 EventRecord（或含其的战役快照）。

var _counts: Dictionary = {}  # counter_key -> int
var _ignores: Dictionary = {}  # ignore_key -> true
## 作用域 token：ATTACK / INVESTIGATION / SKILL_TEST / CUSTOM → 当前打开的 id。
var _scopes: Dictionary = {}
var _events: EventRecordLog = null


func bind_events(events: EventRecordLog) -> void:
	_events = events


func clear() -> void:
	_counts.clear()
	_ignores.clear()
	_scopes.clear()


## 自 EventRecord fold 重建计数与 ignore；不清/不重建 ephemeral scopes。
func rebuild_from_events(events: EventRecordLog = null) -> int:
	var log: EventRecordLog = events if events != null else _events
	_counts.clear()
	_ignores.clear()
	if log == null:
		return 0
	var applied := 0
	for rec in log.get_records():
		if rec is not EventRecord:
			continue
		var er := rec as EventRecord
		match er.kind:
			AhcEnums.EventRecordKind.LIMIT_CONSUME:
				var key := str(er.payload.get("counter_key", ""))
				var amt := int(er.payload.get("amount", 0))
				if key == "" or amt <= 0:
					continue
				_counts[key] = int(_counts.get(key, 0)) + amt
				applied += 1
			AhcEnums.EventRecordKind.LIMIT_IGNORE:
				var ik := str(er.payload.get("ignore_key", ""))
				if ik == "":
					continue
				_ignores[ik] = true
				applied += 1
			_:
				pass
	return applied


## 打开作用域（如一次 Fight / Investigate / Skill Test）。
func begin_scope(period: AhcEnums.LimitPeriod, scope_id: StringName) -> void:
	if scope_id == &"":
		return
	_scopes[period] = scope_id


func end_scope(period: AhcEnums.LimitPeriod, scope_id: StringName = &"") -> void:
	if scope_id != &"" and _scopes.get(period, &"") != scope_id:
		return
	_scopes.erase(period)


func current_scope(period: AhcEnums.LimitPeriod) -> StringName:
	return _scopes.get(period, &"") as StringName


## 卡离场：清掉绑该实例的配额（再进场视为新能力实例）。
func reset_for_instance(instance_id: StringName) -> void:
	if instance_id == &"":
		return
	var needle := "|i:%s|" % String(instance_id)
	var drop: Array = []
	for key in _counts.keys():
		if String(key).find(needle) >= 0:
			drop.append(key)
	for key in drop:
		_counts.erase(key)
	var drop_ig: Array = []
	for key in _ignores.keys():
		if String(key).find(String(instance_id)) >= 0:
			drop_ig.append(key)
	for key in drop_ig:
		_ignores.erase(key)


func remaining(
	spec: LimitSpec,
	unit_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	title_key: StringName = &"",
	instance_id: StringName = &"",
	audience_id: StringName = &""
) -> int:
	if spec == null:
		return 0
	if _is_ignored(spec, unit_id, controller_id, title_key, instance_id, audience_id):
		return spec.amount
	var key := _counter_key(
		spec, unit_id, controller_id, game_ctx, title_key, instance_id, audience_id
	)
	return maxi(spec.amount - int(_counts.get(key, 0)), 0)


func can_consume(
	spec: LimitSpec,
	unit_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	amount: int = 1,
	title_key: StringName = &"",
	instance_id: StringName = &"",
	audience_id: StringName = &""
) -> bool:
	if spec == null or amount <= 0:
		return true
	return remaining(
		spec, unit_id, controller_id, game_ctx, title_key, instance_id, audience_id
	) >= amount


## 消费配额；返回实际计入数量（可能被剩余量截断）。
func consume(
	spec: LimitSpec,
	unit_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	amount: int = 1,
	title_key: StringName = &"",
	instance_id: StringName = &"",
	clamp: bool = false,
	audience_id: StringName = &""
) -> int:
	if spec == null or amount <= 0:
		return 0
	if _is_ignored(spec, unit_id, controller_id, title_key, instance_id, audience_id):
		return amount
	var left := remaining(
		spec, unit_id, controller_id, game_ctx, title_key, instance_id, audience_id
	)
	var take := amount
	if clamp:
		take = mini(amount, left)
	elif take > left:
		return 0
	if take <= 0:
		return 0
	var key := _counter_key(
		spec, unit_id, controller_id, game_ctx, title_key, instance_id, audience_id
	)
	_counts[key] = int(_counts.get(key, 0)) + take
	_emit_consume(
		spec, key, take, unit_id, controller_id, title_key, instance_id, audience_id, game_ctx
	)
	return take


func can_initiate(
	spec: LimitSpec,
	ability_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	title_key: StringName = &"",
	instance_id: StringName = &"",
	audience_id: StringName = &""
) -> bool:
	if spec == null:
		return true
	if spec.kind != AhcEnums.LimitKind.INITIATE_QUOTA:
		return true
	return can_consume(
		spec, ability_id, controller_id, game_ctx, 1, title_key, instance_id, audience_id
	)


func record_commence(
	spec: LimitSpec,
	ability_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	title_key: StringName = &"",
	instance_id: StringName = &"",
	audience_id: StringName = &""
) -> void:
	if spec == null or spec.kind != AhcEnums.LimitKind.INITIATE_QUOTA:
		return
	consume(
		spec, ability_id, controller_id, game_ctx, 1, title_key, instance_id, false, audience_id
	)


func can_initiate_all(
	specs: Array,
	ability_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	title_key: StringName = &"",
	instance_id: StringName = &"",
	audience_id: StringName = &""
) -> bool:
	for s in specs:
		if s is LimitSpec and not can_initiate(
			s as LimitSpec, ability_id, controller_id, game_ctx, title_key, instance_id, audience_id
		):
			return false
	return true


func record_commence_all(
	specs: Array,
	ability_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	title_key: StringName = &"",
	instance_id: StringName = &"",
	audience_id: StringName = &""
) -> void:
	for s in specs:
		if s is LimitSpec:
			record_commence(
				s as LimitSpec, ability_id, controller_id, game_ctx, title_key, instance_id, audience_id
			)


## USE_QUOTA：同作用域内多次触发（Fire Axe per attack 等）。
func can_use(
	spec: LimitSpec,
	unit_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	title_key: StringName = &"",
	instance_id: StringName = &"",
	audience_id: StringName = &""
) -> bool:
	if spec == null or spec.kind != AhcEnums.LimitKind.USE_QUOTA:
		return true
	return can_consume(
		spec, unit_id, controller_id, game_ctx, 1, title_key, instance_id, audience_id
	)


func record_use(
	spec: LimitSpec,
	unit_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	title_key: StringName = &"",
	instance_id: StringName = &"",
	audience_id: StringName = &""
) -> bool:
	if spec == null or spec.kind != AhcEnums.LimitKind.USE_QUOTA:
		return true
	return consume(
		spec, unit_id, controller_id, game_ctx, 1, title_key, instance_id, false, audience_id
	) > 0


## EVENT_QUOTA：按事件计量（资源获得量、成功次数…）；clamp 时截断到剩余。
func clamp_event_amount(
	spec: LimitSpec,
	unit_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	amount: int,
	title_key: StringName = &"",
	instance_id: StringName = &"",
	audience_id: StringName = &""
) -> int:
	if spec == null or spec.kind != AhcEnums.LimitKind.EVENT_QUOTA:
		return amount
	return consume(
		spec, unit_id, controller_id, game_ctx, amount, title_key, instance_id, true, audience_id
	)


func can_event(
	spec: LimitSpec,
	unit_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	amount: int = 1,
	title_key: StringName = &"",
	instance_id: StringName = &"",
	audience_id: StringName = &""
) -> bool:
	if spec == null or spec.kind != AhcEnums.LimitKind.EVENT_QUOTA:
		return true
	return can_consume(
		spec, unit_id, controller_id, game_ctx, amount, title_key, instance_id, audience_id
	)


func record_event(
	spec: LimitSpec,
	unit_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	amount: int = 1,
	title_key: StringName = &"",
	instance_id: StringName = &"",
	audience_id: StringName = &""
) -> int:
	if spec == null or spec.kind != AhcEnums.LimitKind.EVENT_QUOTA:
		return 0
	return consume(
		spec, unit_id, controller_id, game_ctx, amount, title_key, instance_id, false, audience_id
	)


## COMMIT_MAX：同名投入本检定上限（预投入读池；确认后读 committed）。
func can_commit_title(
	spec: LimitSpec,
	skill_ctx: SkillTestContext,
	game_ctx: GameContext,
	definition_id: StringName,
	title: String = ""
) -> bool:
	if spec == null or spec.kind != AhcEnums.LimitKind.COMMIT_MAX:
		return true
	if skill_ctx == null or game_ctx == null or game_ctx.state == null:
		return true
	var n := 0
	var want_title := title
	if want_title == "":
		want_title = CardRegistry.title(definition_id)
	var source: Array = []
	if not skill_ctx.commits_confirmed and skill_ctx.commit_pool != null:
		source = skill_ctx.commit_pool.snapshot()
	else:
		source = skill_ctx.committed
	for commit in source:
		var card: CardInstance = game_ctx.state.registry.get_card(commit.card_id)
		if card == null:
			continue
		if card.id.definition_id == definition_id:
			n += 1
			continue
		if want_title != "" and CardRegistry.title(card.id.definition_id) == want_title:
			n += 1
	return n < spec.amount


func ignore_limit(
	spec: LimitSpec,
	ability_id: StringName = &"",
	controller_id: StringName = &"",
	title_key: StringName = &"",
	instance_id: StringName = &"",
	audience_id: StringName = &""
) -> void:
	if spec == null:
		return
	var ik := _ignore_key(spec, ability_id, controller_id, title_key, instance_id, audience_id)
	_ignores[ik] = true
	_emit_ignore(spec, ik, ability_id, controller_id, title_key, instance_id, audience_id)


func clear_ignore(
	spec: LimitSpec,
	ability_id: StringName = &"",
	controller_id: StringName = &"",
	title_key: StringName = &"",
	instance_id: StringName = &"",
	audience_id: StringName = &""
) -> void:
	if spec == null:
		return
	_ignores.erase(
		_ignore_key(spec, ability_id, controller_id, title_key, instance_id, audience_id)
	)


func _emit_consume(
	spec: LimitSpec,
	counter_key: String,
	amount: int,
	unit_id: StringName,
	controller_id: StringName,
	title_key: StringName,
	instance_id: StringName,
	audience_id: StringName,
	game_ctx: GameContext
) -> void:
	if _events == null or amount <= 0:
		return
	_events.append(
		AhcEnums.EventRecordKind.LIMIT_CONSUME,
		{
			"counter_key": counter_key,
			"amount": amount,
			"limit_id": String(spec.id),
			"kind": int(spec.kind),
			"period": int(spec.period),
			"audience": int(spec.audience),
			"unit_id": String(unit_id),
			"controller_id": String(controller_id),
			"title_key": String(title_key),
			"instance_id": String(instance_id),
			"audience_id": String(audience_id),
			"epoch": _epoch(spec.period, game_ctx),
			"event_key": String(spec.event_key),
		}
	)


func _emit_ignore(
	spec: LimitSpec,
	ignore_key: String,
	ability_id: StringName,
	controller_id: StringName,
	title_key: StringName,
	instance_id: StringName,
	audience_id: StringName
) -> void:
	if _events == null:
		return
	_events.append(
		AhcEnums.EventRecordKind.LIMIT_IGNORE,
		{
			"ignore_key": ignore_key,
			"limit_id": String(spec.id),
			"kind": int(spec.kind),
			"ability_id": String(ability_id),
			"controller_id": String(controller_id),
			"title_key": String(title_key),
			"instance_id": String(instance_id),
			"audience_id": String(audience_id),
		}
	)


func count_in_play_for_occupancy(
	spec: LimitSpec,
	game_ctx: GameContext,
	controller_id: StringName,
	definition_id: StringName,
	location_id: StringName = &"",
	host_id: StringName = &""
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
		if not _card_in_occupancy_zone(card, spec, controller_id, location_id, host_id):
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
	location_id: StringName = &"",
	host_id: StringName = &""
) -> bool:
	if spec == null or spec.kind != AhcEnums.LimitKind.ZONE_OCCUPANCY:
		return true
	if _is_ignored(spec, definition_id, controller_id, &"", &"", &""):
		return true
	return (
		count_in_play_for_occupancy(
			spec, game_ctx, controller_id, definition_id, location_id, host_id
		)
		< spec.amount
	)


func can_enter_zone_all(
	specs: Array,
	game_ctx: GameContext,
	controller_id: StringName,
	definition_id: StringName,
	location_id: StringName = &"",
	host_id: StringName = &""
) -> bool:
	for s in specs:
		if s is LimitSpec and not can_enter_zone(
			s as LimitSpec, game_ctx, controller_id, definition_id, location_id, host_id
		):
			return false
	return true


## DECKBUILDING：牌组列表现读（非 scenario 运行时）。
func count_in_deck_for_limit(
	spec: LimitSpec,
	deck_definition_ids: Array,
	incoming_definition_id: StringName
) -> int:
	if spec == null or spec.kind != AhcEnums.LimitKind.DECKBUILDING:
		return 0
	var n := 0
	for item in deck_definition_ids:
		var def_id: StringName = item as StringName
		if def_id == &"":
			continue
		if not _occupancy_matches(def_id, incoming_definition_id, spec):
			continue
		n += 1
	return n


func can_include_in_deck(
	spec: LimitSpec,
	deck_definition_ids: Array,
	incoming_definition_id: StringName
) -> bool:
	if spec == null or spec.kind != AhcEnums.LimitKind.DECKBUILDING:
		return true
	return count_in_deck_for_limit(spec, deck_definition_ids, incoming_definition_id) < spec.amount


func can_include_in_deck_all(
	specs: Array,
	deck_definition_ids: Array,
	incoming_definition_id: StringName
) -> bool:
	for s in specs:
		if s is LimitSpec and not can_include_in_deck(
			s as LimitSpec, deck_definition_ids, incoming_definition_id
		):
			return false
	return true


func _is_ignored(
	spec: LimitSpec,
	ability_id: StringName,
	controller_id: StringName,
	title_key: StringName,
	instance_id: StringName,
	audience_id: StringName = &""
) -> bool:
	return _ignores.has(
		_ignore_key(spec, ability_id, controller_id, title_key, instance_id, audience_id)
	)


func _ignore_key(
	spec: LimitSpec,
	ability_id: StringName,
	controller_id: StringName,
	title_key: StringName,
	instance_id: StringName,
	audience_id: StringName = &""
) -> String:
	return "%s|%s|%s|%s|%s|%s|%s" % [
		String(spec.id),
		str(spec.kind),
		String(ability_id),
		String(title_key),
		String(controller_id) if spec.audience == AhcEnums.LimitAudience.PLAYER else "*",
		String(instance_id),
		String(audience_id),
	]


func _counter_key(
	spec: LimitSpec,
	unit_id: StringName,
	controller_id: StringName,
	game_ctx: GameContext,
	title_key: StringName,
	instance_id: StringName,
	audience_id: StringName = &""
) -> String:
	var unit := String(unit_id)
	var effective_title := title_key
	if effective_title == &"" and spec.title_key != &"":
		effective_title = spec.title_key
	if spec.audience == AhcEnums.LimitAudience.TITLE:
		unit = String(effective_title) if effective_title != &"" else unit
	var who := "*"
	match spec.audience:
		AhcEnums.LimitAudience.PLAYER:
			who = String(controller_id)
		AhcEnums.LimitAudience.GROUP:
			who = "group"
		AhcEnums.LimitAudience.TITLE:
			who = "title"
		AhcEnums.LimitAudience.PER_TARGET_INVESTIGATOR, AhcEnums.LimitAudience.PER_ASSET_INSTANCE, AhcEnums.LimitAudience.PER_ANCHOR:
			who = String(audience_id) if audience_id != &"" else String(controller_id)
		_:
			who = String(controller_id)
	var inst := String(instance_id) if instance_id != &"" else "-"
	return "%s|%s|%s|%s|%s|%s|i:%s|" % [
		str(spec.kind),
		String(spec.id),
		unit,
		who,
		str(spec.period),
		_epoch(spec.period, game_ctx),
		inst,
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
		AhcEnums.LimitPeriod.ATTACK, AhcEnums.LimitPeriod.INVESTIGATION, AhcEnums.LimitPeriod.SKILL_TEST, AhcEnums.LimitPeriod.ACT, AhcEnums.LimitPeriod.LOCATION, AhcEnums.LimitPeriod.CUSTOM_ANCHOR:
			var sid := current_scope(period)
			return "s:%s" % (String(sid) if sid != &"" else "none")
		_:
			return "x:%d" % int(period)


func _card_in_occupancy_zone(
	card,
	spec: LimitSpec,
	controller_id: StringName,
	location_id: StringName,
	host_id: StringName = &""
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
			if card.zone == AhcEnums.Zone.LOCATION_AREA and card.id != null:
				## 地点区牌：attached_to / owner 指向地点实例时计入。
				if card.attached_to != null and card.attached_to.instance_id == location_id:
					return true
				return card.owner_id == location_id or card.controller_id == location_id
			return false
		AhcEnums.ZoneConstraint.ATTACHED, AhcEnums.ZoneConstraint.PER_ASSET, AhcEnums.ZoneConstraint.PER_ENEMY, AhcEnums.ZoneConstraint.PER_AGENDA_ACT:
			if card.zone != AhcEnums.Zone.ATTACHED or card.attached_to == null:
				return false
			if host_id == &"":
				return true
			if card.attached_to.instance_id != host_id and card.attached_to.definition_id != host_id:
				return false
			if spec.zone == AhcEnums.ZoneConstraint.ATTACHED:
				return true
			var host_def: StringName = card.attached_to.definition_id
			var host_type: StringName = CardRegistry.card_type(host_def)
			match spec.zone:
				AhcEnums.ZoneConstraint.PER_ASSET:
					return host_type == &"asset"
				AhcEnums.ZoneConstraint.PER_ENEMY:
					return host_type == &"enemy"
				AhcEnums.ZoneConstraint.PER_AGENDA_ACT:
					return host_type == &"agenda" or host_type == &"act"
				_:
					return true
		AhcEnums.ZoneConstraint.BENEATH:
			if card.zone != AhcEnums.Zone.BENEATH or card.attached_to == null:
				return false
			if host_id == &"":
				return true
			return (
				card.attached_to.instance_id == host_id
				or card.attached_to.definition_id == host_id
			)
		AhcEnums.ZoneConstraint.VICTORY_DISPLAY:
			return card.zone == AhcEnums.Zone.VICTORY_DISPLAY
		_:
			return false


func _occupancy_matches(
	card_def: StringName,
	incoming_def: StringName,
	spec: LimitSpec
) -> bool:
	match spec.match:
		AhcEnums.OccupancyMatch.ANY:
			return true
		AhcEnums.OccupancyMatch.BY_TRAIT:
			if spec.trait_name == &"":
				return false
			for t in CardRegistry.traits(card_def):
				if str(t).to_lower() == String(spec.trait_name).to_lower():
					return true
			return false
		AhcEnums.OccupancyMatch.BY_CARD_TYPE:
			if spec.card_type == &"":
				return false
			return CardRegistry.card_type(card_def) == spec.card_type
		_:
			if card_def == incoming_def:
				return true
			var a := CardRegistry.title(card_def)
			var b := CardRegistry.title(incoming_def)
			return a != "" and a == b
