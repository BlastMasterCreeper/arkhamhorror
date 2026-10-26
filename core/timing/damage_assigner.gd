class_name DamageAssigner
extends RefCounted

## Assign（分摊）客观核（deal 内 PI）：候选 · 约束 · 默认表 · 校验。
## 约束来自 RestrictionKind.ASSIGN_CONSTRAINT（原流程读取，非 LISTENER）。
## 腿：`{ "bearer": &"investigator"|"card", "id": StringName, "amount": int }`


static func default_assignment(
	game_ctx: GameContext,
	inv_id: StringName,
	kind: StringName,
	amount: int,
	is_direct: bool
) -> Array[Dictionary]:
	var total := maxi(amount, 0)
	var empty: Array[Dictionary] = []
	if game_ctx == null or inv_id == &"" or total <= 0:
		return empty
	var caps := _capacity_map(game_ctx, inv_id, kind, is_direct)
	var constraints := _active_constraints(game_ctx, inv_id, kind, is_direct)
	var legs := _allocate_default(inv_id, total, caps, constraints)
	if not validate(game_ctx, inv_id, kind, is_direct, total, legs):
		return [{"bearer": &"investigator", "id": inv_id, "amount": total}]
	return legs


## 仅分配增量 K（07 §4）：在已确认腿占用容量之后，对合法全合格集摊 K。
## 不修改 reserved_legs；返回的是 **仅含 K** 的腿表。
static func assign_delta(
	game_ctx: GameContext,
	inv_id: StringName,
	kind: StringName,
	delta_amount: int,
	is_direct: bool,
	reserved_legs: Array = []
) -> Array[Dictionary]:
	var total := maxi(delta_amount, 0)
	var empty: Array[Dictionary] = []
	if game_ctx == null or inv_id == &"" or total <= 0:
		return empty
	var caps := _capacity_map(game_ctx, inv_id, kind, is_direct)
	_reserve_caps(caps, reserved_legs)
	var constraints := _active_constraints(game_ctx, inv_id, kind, is_direct)
	var legs := _allocate_default(inv_id, total, caps, constraints)
	## 增量腿自身须合法；与 reserved 合并后的总量校验由 pipeline 做。
	if not validate(game_ctx, inv_id, kind, is_direct, total, legs):
		return [{"bearer": &"investigator", "id": inv_id, "amount": total}]
	return legs


## 合并两套腿（同 bearer+id 加算）。
static func merge_legs(base_legs: Array, delta_legs: Array) -> Array[Dictionary]:
	var alloc: Dictionary = {}
	var inv_id: StringName = &""
	for leg in base_legs:
		if not (leg is Dictionary):
			continue
		var amt := int((leg as Dictionary).get("amount", 0))
		if amt <= 0:
			continue
		var bearer: StringName = (leg as Dictionary).get("bearer", &"")
		var id: StringName = (leg as Dictionary).get("id", &"")
		if bearer == &"investigator":
			inv_id = id
			_add(alloc, _inv_key(id), amt)
		else:
			_add(alloc, _card_key(id), amt)
	for leg2 in delta_legs:
		if not (leg2 is Dictionary):
			continue
		var amt2 := int((leg2 as Dictionary).get("amount", 0))
		if amt2 <= 0:
			continue
		var bearer2: StringName = (leg2 as Dictionary).get("bearer", &"")
		var id2: StringName = (leg2 as Dictionary).get("id", &"")
		if bearer2 == &"investigator":
			if inv_id == &"":
				inv_id = id2
			_add(alloc, _inv_key(id2 if id2 != &"" else inv_id), amt2)
		else:
			_add(alloc, _card_key(id2), amt2)
	return _alloc_to_legs(alloc, inv_id)


static func _allocate_default(
	inv_id: StringName,
	total: int,
	caps: Dictionary,
	constraints: Array[RestrictionPayload]
) -> Array[Dictionary]:
	var alloc: Dictionary = {}
	var rem := total
	var caps_work: Dictionary = caps.duplicate()
	## 1) PRIOR_FILL：先填满优先卡。
	for c in constraints:
		if c.assign_op != AhcEnums.AssignConstraintOp.PRIOR_FILL:
			continue
		var sid: StringName = c.subject_id
		var cap := int(caps_work.get(_card_key(sid), 0))
		var take := mini(cap, rem)
		if take > 0:
			_add(alloc, _card_key(sid), take)
			rem -= take
			caps_work[_card_key(sid)] = cap - take
	## 2) MIN_TO_SUBJECT。
	for c in constraints:
		if c.assign_op != AhcEnums.AssignConstraintOp.MIN_TO_SUBJECT:
			continue
		var sid2: StringName = c.subject_id
		var cap2 := int(caps_work.get(_card_key(sid2), 0))
		var need := mini(c.assign_amount, rem)
		if need > cap2:
			if c.assign_if_able:
				need = cap2
			else:
				need = 0
		if need > 0:
			_add(alloc, _card_key(sid2), need)
			rem -= need
			caps_work[_card_key(sid2)] = cap2 - need
	## 3) 剩余默认归调查员卡。
	if rem > 0:
		_add(alloc, _inv_key(inv_id), rem)
	return _alloc_to_legs(alloc, inv_id)


static func _reserve_caps(caps: Dictionary, reserved_legs: Array) -> void:
	for leg in reserved_legs:
		if not (leg is Dictionary):
			continue
		var amt := int((leg as Dictionary).get("amount", 0))
		if amt <= 0:
			continue
		var bearer: StringName = (leg as Dictionary).get("bearer", &"")
		if bearer != &"card":
			continue
		var id: StringName = (leg as Dictionary).get("id", &"")
		var key := _card_key(id)
		if caps.has(key):
			caps[key] = maxi(int(caps[key]) - amt, 0)


## Gate / UI 快照：调查员卡（无限）∪ 有剩余容量的场上卡。
static func candidate_entries(
	game_ctx: GameContext,
	inv_id: StringName,
	kind: StringName,
	is_direct: bool,
	reserved_legs: Array = []
) -> Array:
	var out: Array = []
	if game_ctx == null or inv_id == &"":
		return out
	out.append(
		{
			"bearer": &"investigator",
			"id": inv_id,
			"capacity": -1,
			"amount": 0,
		}
	)
	var caps := _capacity_map(game_ctx, inv_id, kind, is_direct)
	_reserve_caps(caps, reserved_legs)
	for key in caps.keys():
		var rem := int(caps[key])
		if rem <= 0:
			continue
		var cid := StringName(str(key).substr(5))
		out.append({"bearer": &"card", "id": cid, "capacity": rem, "amount": 0})
	return out


## Gate context：生效中 ASSIGN_CONSTRAINT 摘要。
static func constraint_summaries(
	game_ctx: GameContext,
	inv_id: StringName,
	kind: StringName,
	is_direct: bool
) -> Array:
	var out: Array = []
	for c in _active_constraints(game_ctx, inv_id, kind, is_direct):
		out.append(
			{
				"op": c.assign_op,
				"subject_id": c.subject_id,
				"affliction": c.assign_affliction,
				"direct_scope": c.assign_direct_scope,
				"expand_scope": c.assign_expand_scope,
				"trait": c.assign_trait,
				"amount": c.assign_amount,
				"if_able": c.assign_if_able,
			}
		)
	return out


## 外向 among：候选 id 列表上的默认全量归 primary；校验合计与集合。
static func default_among(subjects: Array, amount: int) -> Array:
	var total := maxi(amount, 0)
	var empty: Array = []
	if total <= 0 or subjects.is_empty():
		return empty
	var primary: StringName = subjects[0] as StringName
	return [{"id": primary, "amount": total}]


static func validate_among(subjects: Array, total: int, legs: Array) -> bool:
	if total < 0:
		return false
	var allowed: Dictionary = {}
	for s in subjects:
		allowed[s as StringName] = true
	var sum := 0
	for leg in legs:
		if not (leg is Dictionary):
			return false
		var amt := int((leg as Dictionary).get("amount", 0))
		if amt < 0:
			return false
		var sid: StringName = (leg as Dictionary).get("id", &"")
		if sid == &"" or not allowed.has(sid):
			return false
		sum += amt
	return sum == total


static func validate(
	game_ctx: GameContext,
	inv_id: StringName,
	kind: StringName,
	is_direct: bool,
	total: int,
	legs: Array,
	reserved_legs: Array = []
) -> bool:
	if total < 0:
		return false
	var sum := 0
	var by_key: Dictionary = {}
	for leg in legs:
		if not (leg is Dictionary):
			return false
		var amt := int((leg as Dictionary).get("amount", 0))
		if amt < 0:
			return false
		sum += amt
		var bearer: StringName = (leg as Dictionary).get("bearer", &"")
		var id: StringName = (leg as Dictionary).get("id", &"")
		var key := _inv_key(id) if bearer == &"investigator" else _card_key(id)
		_add(by_key, key, amt)
	if sum != total:
		return false
	var caps := _capacity_map(game_ctx, inv_id, kind, is_direct)
	_reserve_caps(caps, reserved_legs)
	## 每腿须在候选且不超过容量（调查员卡容量视为无限）。
	for key in by_key.keys():
		var amt2 := int(by_key[key])
		if str(key).begins_with("inv:"):
			continue
		if not caps.has(key):
			return false
		if amt2 > int(caps[key]):
			return false
	var constraints := _active_constraints(game_ctx, inv_id, kind, is_direct)
	for c in constraints:
		match c.assign_op:
			AhcEnums.AssignConstraintOp.PRIOR_FILL:
				var sk := _card_key(c.subject_id)
				var on_subj := int(by_key.get(sk, 0))
				var on_inv := int(by_key.get(_inv_key(inv_id), 0))
				var cap_left := int(caps.get(sk, 0)) - on_subj
				## 若本卡还能再吃且调查员卡上有量 → 违例。
				if cap_left > 0 and on_inv > 0:
					return false
			AhcEnums.AssignConstraintOp.MIN_TO_SUBJECT:
				var sk2 := _card_key(c.subject_id)
				var got := int(by_key.get(sk2, 0))
				var cap_av := int(caps.get(sk2, 0))
				var need2 := mini(c.assign_amount, cap_av) if c.assign_if_able else c.assign_amount
				if got < need2 and (not c.assign_if_able or cap_av > 0):
					if c.assign_if_able and cap_av == 0:
						pass
					elif got < need2:
						return false
			AhcEnums.AssignConstraintOp.MAX_TO_MATCH:
				var matched := 0
				for key2 in by_key.keys():
					if str(key2).begins_with("card:"):
						var cid := StringName(str(key2).substr(5))
						if _card_has_trait(game_ctx, cid, c.assign_trait):
							matched += int(by_key[key2])
				if matched > c.assign_amount:
					return false
			_:
				pass
	return true


static func _active_constraints(
	game_ctx: GameContext,
	inv_id: StringName,
	kind: StringName,
	is_direct: bool
) -> Array[RestrictionPayload]:
	var out: Array[RestrictionPayload] = []
	if game_ctx == null or game_ctx.registrations == null:
		return out
	for r in game_ctx.registrations.list_assign_constraints(inv_id):
		if not _affliction_matches(r.assign_affliction, kind):
			continue
		if not _direct_scope_matches(r.assign_direct_scope, is_direct):
			continue
		if r.assign_op == AhcEnums.AssignConstraintOp.INCLUDE_CANDIDATE:
			if r.assign_expand_scope == &"other_at_location":
				if not _same_location(game_ctx, r.drawer_id, inv_id):
					continue
		out.append(r)
	return out


static func _capacity_map(
	game_ctx: GameContext,
	inv_id: StringName,
	kind: StringName,
	is_direct: bool
) -> Dictionary:
	## key -> remaining capacity；不含调查员卡（无限）。
	## 候选不限卡种：凡 play 区有印刷 health/sanity，或 GRANT_CAPACITY Buff。
	var caps: Dictionary = {}
	var constraints := _active_constraints(game_ctx, inv_id, kind, is_direct)
	if is_direct:
		## direct：默认无卡；INCLUDE self_deals / GRANT 加入。
		for c in constraints:
			if c.assign_op == AhcEnums.AssignConstraintOp.INCLUDE_CANDIDATE:
				if c.assign_expand_scope == &"other_at_location":
					continue
				_put_cap(caps, game_ctx, c.subject_id, kind, constraints)
			elif c.assign_op == AhcEnums.AssignConstraintOp.GRANT_CAPACITY:
				_put_cap(caps, game_ctx, c.subject_id, kind, constraints)
		return caps
	## non-direct：己方 play 可承伤/恐卡 + INCLUDE + GRANT。
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv != null:
		for card_id in inv.play_area:
			_put_cap(caps, game_ctx, card_id, kind, constraints)
	for c in constraints:
		if c.assign_op == AhcEnums.AssignConstraintOp.INCLUDE_CANDIDATE:
			if c.assign_expand_scope == &"other_at_location":
				if not _same_location(game_ctx, c.drawer_id, inv_id):
					continue
				_put_cap(caps, game_ctx, c.subject_id, kind, constraints)
		elif c.assign_op == AhcEnums.AssignConstraintOp.GRANT_CAPACITY:
			## GRANT 可将无印刷生命/神智的卡纳入候选。
			_put_cap(caps, game_ctx, c.subject_id, kind, constraints)
	return caps


static func _put_cap(
	caps: Dictionary,
	game_ctx: GameContext,
	card_id: StringName,
	kind: StringName,
	constraints: Array[RestrictionPayload]
) -> void:
	var cap := card_remaining_with_grants(game_ctx, card_id, kind, constraints)
	if cap > 0:
		caps[_card_key(card_id)] = cap


## 场上卡剩余分摊容量 = 印刷 + 生效 GRANT − 已有标记。不限 cardtype。
static func card_remaining(
	game_ctx: GameContext,
	card_id: StringName,
	kind: StringName,
	dealt_inv_id: StringName = &"",
	is_direct: bool = false
) -> int:
	var constraints: Array[RestrictionPayload] = []
	if dealt_inv_id != &"":
		constraints = _active_constraints(game_ctx, dealt_inv_id, kind, is_direct)
	return card_remaining_with_grants(game_ctx, card_id, kind, constraints)


static func card_remaining_with_grants(
	game_ctx: GameContext,
	card_id: StringName,
	kind: StringName,
	constraints: Array[RestrictionPayload]
) -> int:
	var card := game_ctx.state.registry.get_card(card_id) if game_ctx != null else null
	if card == null:
		return 0
	if (
		card.zone != AhcEnums.Zone.PLAY_AREA
		and card.zone != AhcEnums.Zone.THREAT_AREA
		and card.zone != AhcEnums.Zone.ATTACHED
	):
		return 0
	var def := card.id.definition_id
	var printed := 0
	var tokens := 0
	if kind == &"horror":
		printed = CardRegistry.printed_sanity(def)
		tokens = card.tokens.horror
	else:
		printed = CardRegistry.printed_health(def)
		tokens = card.tokens.damage
	var grant := 0
	for c in constraints:
		if c.assign_op != AhcEnums.AssignConstraintOp.GRANT_CAPACITY:
			continue
		if c.subject_id != card_id:
			continue
		grant += maxi(c.assign_amount, 0)
	if printed <= 0 and grant <= 0:
		return 0
	return maxi(maxi(printed, 0) + grant - tokens, 0)


static func _asset_remaining(game_ctx: GameContext, card_id: StringName, kind: StringName) -> int:
	## 兼容旧名；新路径用 card_remaining。
	return card_remaining(game_ctx, card_id, kind, &"", false)


static func _affliction_matches(mask: StringName, kind: StringName) -> bool:
	if mask == &"either" or mask == &"":
		return true
	return mask == kind


static func _direct_scope_matches(scope: AhcEnums.AssignDirectScope, is_direct: bool) -> bool:
	match scope:
		AhcEnums.AssignDirectScope.BOTH:
			return true
		AhcEnums.AssignDirectScope.DIRECT:
			return is_direct
		AhcEnums.AssignDirectScope.NON_DIRECT:
			return not is_direct
	return false


static func _same_location(game_ctx: GameContext, a: StringName, b: StringName) -> bool:
	var ia := game_ctx.state.registry.get_investigator(a)
	var ib := game_ctx.state.registry.get_investigator(b)
	if ia == null or ib == null:
		return false
	return ia.location_tag != &"" and ia.location_tag == ib.location_tag


static func _card_has_trait(game_ctx: GameContext, card_id: StringName, trait_name: StringName) -> bool:
	if trait_name == &"":
		return false
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return false
	for t in CardRegistry.traits(card.id.definition_id):
		if StringName(str(t)) == trait_name or str(t) == str(trait_name):
			return true
	return false


static func _inv_key(inv_id: StringName) -> String:
	return "inv:%s" % String(inv_id)


static func _card_key(card_id: StringName) -> String:
	return "card:%s" % String(card_id)


static func _add(alloc: Dictionary, key: String, amount: int) -> void:
	alloc[key] = int(alloc.get(key, 0)) + amount


static func _alloc_to_legs(alloc: Dictionary, inv_id: StringName) -> Array[Dictionary]:
	var legs: Array[Dictionary] = []
	for key in alloc.keys():
		var amt := int(alloc[key])
		if amt <= 0:
			continue
		if str(key).begins_with("inv:"):
			legs.append({"bearer": &"investigator", "id": inv_id, "amount": amt})
		else:
			var cid := StringName(str(key).substr(5))
			legs.append({"bearer": &"card", "id": cid, "amount": amt})
	return legs
