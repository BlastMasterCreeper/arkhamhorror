class_name DealAssignableFlow
extends RefCounted

## seq.effect.deal.assignable · 待分配「造成伤害/恐惧」一条手续。
## 伤与恐可同时入参；同帧 Assign（可分步 PI）后 **同时** Apply。
## 禁止伤、恐各 nest 一条 assignable。
## 无分配已定 → seq.effect.deal。
## 多目标候选不限卡种：敌人 / 有生命·神智（或 GRANT_CAPACITY）的场上卡 / 调查员。


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.mutator == null:
		return {"ok": false, "amount": 0}
	var dmg := _amount_of(params, &"damage")
	var hor := _amount_of(params, &"horror")
	## 兼容旧单 kind+amount。
	if dmg <= 0 and hor <= 0:
		var kind := StringName(str(params.get("kind", "damage")))
		var amount := maxi(int(params.get("amount", 0)), 0)
		if kind == &"horror":
			hor = amount
		else:
			dmg = amount
	if dmg <= 0 and hor <= 0:
		return {"ok": false, "amount": 0, "error": "zero_amount"}
	var target := StringName(str(params.get("target", "controller")))
	var inv_id: StringName = params.get(
		"controller_id", params.get("inv_id", &"")
	)
	var is_direct := bool(params.get("direct", false))
	var direct_dmg := bool(params.get("direct_damage", is_direct))
	var direct_hor := bool(params.get("direct_horror", is_direct))
	match target:
		&"enemy", &"enemies", &"subjects", &"among_candidates":
			return _among_subjects(game_ctx, params, dmg, hor, inv_id)
		&"each_at_controller_location", &"each_at_source_location":
			return _each_at_location(
				game_ctx, params, dmg, hor, direct_dmg, direct_hor, target
			)
		_:
			return _investigator_take(
				game_ctx, params, dmg, hor, inv_id, direct_dmg, direct_hor
			)


static func _amount_of(params: Dictionary, kind: StringName) -> int:
	if kind == &"horror":
		return maxi(
			int(params.get("horror", params.get("horror_amount", 0))),
			0
		)
	return maxi(
		int(params.get("damage", params.get("damage_amount", 0))),
		0
	)


static func _investigator_take(
	game_ctx: GameContext,
	params: Dictionary,
	damage_amt: int,
	horror_amt: int,
	inv_id: StringName,
	direct_dmg: bool,
	direct_hor: bool
) -> Dictionary:
	if inv_id == &"" or game_ctx.state.registry.get_investigator(inv_id) == null:
		return {"ok": false, "amount": 0, "error": "unknown_investigator"}
	var result := DealInvestigatorPipeline.deal_investigator_bundle(
		game_ctx,
		inv_id,
		damage_amt,
		horror_amt,
		direct_dmg,
		direct_hor
	)
	DealAfflictionReport.patch_current(
		game_ctx, int(result.get("damage", 0)), int(result.get("horror", 0))
	)
	_log(game_ctx, result, params)
	result["assignable"] = true
	result["target"] = &"controller"
	result["simultaneous"] = damage_amt > 0 and horror_amt > 0
	return result


## 在候选主体间分配 damage（默认全量归 primary）；horror 仅落可承恐主体。
## candidates / primary 可为敌人、场上卡、调查员混装。
static func _among_subjects(
	game_ctx: GameContext,
	params: Dictionary,
	damage_amt: int,
	horror_amt: int,
	controller_id: StringName
) -> Dictionary:
	var primary: StringName = params.get(
		"primary_id", params.get("enemy_id", params.get("card_id", &""))
	)
	var candidates: Array = params.get("candidates", [])
	var subject_ids: Array[StringName] = _normalize_subjects(primary, candidates)
	if subject_ids.is_empty():
		return {"ok": false, "amount": 0, "error": "missing_primary"}
	var d_legs: Array = []
	if damage_amt > 0:
		d_legs = _assign_among(
			game_ctx, controller_id, &"damage", damage_amt, subject_ids, &"assign:among:damage"
		)
	var h_legs: Array = []
	if horror_amt > 0:
		## 恐惧：仅落到可承恐的卡/调查员（敌人跳过）。
		var horror_subjects: Array[StringName] = []
		for sid in subject_ids:
			var kind := DealSubject.classify(game_ctx, sid)
			if kind == DealSubject.KIND_CARD or kind == DealSubject.KIND_INVESTIGATOR:
				horror_subjects.append(sid)
		if not horror_subjects.is_empty():
			h_legs = _assign_among(
				game_ctx,
				controller_id,
				&"horror",
				horror_amt,
				horror_subjects,
				&"assign:among:horror"
			)
	## Assign 后 PreImpact（与承伤对称），再 Apply。
	var scope: StringName = controller_id if controller_id != &"" else &"deal_out"
	var pre := DealOutboundPipeline.apply_bundle(game_ctx, d_legs, h_legs, scope)
	var applied_d := int(pre.get("damage", 0))
	var applied_h := int(pre.get("horror", 0))
	var result := {
		"ok": applied_d > 0 or applied_h > 0,
		"amount": applied_d + applied_h,
		"damage": applied_d,
		"horror": applied_h,
		"kind": &"damage" if applied_d > 0 else &"horror",
		"target": &"subjects",
		"legs": pre.get("legs", d_legs),
		"legs_horror": pre.get("legs_horror", h_legs),
		"assignable": true,
		"controller_id": controller_id,
		"simultaneous": damage_amt > 0 and horror_amt > 0,
		"prevented": bool(pre.get("prevented", false)),
	}
	DealAfflictionReport.patch_current(game_ctx, applied_d, applied_h)
	_log(game_ctx, result, params)
	return result


static func _normalize_subjects(
	primary: StringName, candidates: Array
) -> Array[StringName]:
	var out: Array[StringName] = []
	var seen: Dictionary = {}
	if primary != &"":
		out.append(primary)
		seen[primary] = true
	for raw in candidates:
		var sid: StringName = &""
		if raw is StringName or raw is String:
			sid = StringName(str(raw))
		elif raw is Dictionary:
			sid = (raw as Dictionary).get(
				"id", (raw as Dictionary).get("enemy_id", (raw as Dictionary).get("card_id", &""))
			)
		if sid == &"" or seen.has(sid):
			continue
		seen[sid] = true
		out.append(sid)
	return out


## Assign among：有 Gate 则 ask；否则全量归 primary。
static func _assign_among(
	game_ctx: GameContext,
	controller_id: StringName,
	kind: StringName,
	amount: int,
	subjects: Array[StringName],
	prompt_id: StringName
) -> Array:
	var subj: Array = []
	for s in subjects:
		subj.append(s)
	if game_ctx != null and game_ctx.interaction != null:
		return game_ctx.interaction.ask_assign_among(
			game_ctx, controller_id, kind, amount, subj, prompt_id
		)
	return DealAssignableFlow.default_among(subj, amount)


static func _each_at_location(
	game_ctx: GameContext,
	params: Dictionary,
	damage_amt: int,
	horror_amt: int,
	direct_dmg: bool,
	direct_hor: bool,
	target: StringName
) -> Dictionary:
	var loc_id := _location_for_target(game_ctx, params, target)
	if loc_id == &"":
		return {"ok": false, "amount": 0}
	var applied_d := 0
	var applied_h := 0
	for other_id in game_ctx.state.registry.all_investigator_ids():
		var other := game_ctx.state.registry.get_investigator(other_id)
		if other == null or other.eliminated or other.resigned:
			continue
		if other.location_tag != loc_id:
			continue
		var one := DealInvestigatorPipeline.deal_investigator_bundle(
			game_ctx, other_id, damage_amt, horror_amt, direct_dmg, direct_hor
		)
		applied_d += int(one.get("damage", 0))
		applied_h += int(one.get("horror", 0))
	var result := {
		"ok": applied_d > 0 or applied_h > 0,
		"amount": applied_d + applied_h,
		"damage": applied_d,
		"horror": applied_h,
		"target": target,
		"assignable": true,
		"simultaneous": damage_amt > 0 and horror_amt > 0,
	}
	_log(game_ctx, result, params)
	return result


static func _location_for_target(
	game_ctx: GameContext, params: Dictionary, target: StringName
) -> StringName:
	if target == &"each_at_source_location":
		var source_id: StringName = params.get(
			"source", params.get("card_id", params.get("enemy_id", &""))
		)
		var enemy := game_ctx.state.registry.get_enemy(source_id)
		if enemy != null:
			return enemy.location_tag
		var card := game_ctx.state.registry.get_card(source_id)
		if card != null and card.attached_to != null:
			var host_id := card.attached_to.instance_id
			if game_ctx.state.registry.get_location(host_id) != null:
				return host_id
			if game_ctx.state.registry.get_location(card.attached_to.definition_id) != null:
				return card.attached_to.definition_id
			return host_id
	var inv_id: StringName = params.get(
		"controller_id", params.get("inv_id", &"")
	)
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	return inv.location_tag if inv != null else &""


static func _log(game_ctx: GameContext, result: Dictionary, params: Dictionary) -> void:
	if game_ctx == null or game_ctx.log == null:
		return
	game_ctx.log.log(
		AhcEnums.LogCategory.CARD,
		"effect:deal.assignable",
		{
			"damage": int(result.get("damage", 0)),
			"horror": int(result.get("horror", 0)),
			"amount": int(result.get("amount", 0)),
			"simultaneous": bool(result.get("simultaneous", false)),
			"source": params.get("source", params.get("card_id", &"")),
		}
	)

## 分摊核：候选、约束、默认腿、校验。原 DamageAssigner。
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
	## 1) PRIOR_FILL：先填满优先卡（无限容量不自动吃光）。
	for c in constraints:
		if c.assign_op != AhcEnums.AssignConstraintOp.PRIOR_FILL:
			continue
		var sid: StringName = c.subject_id
		var cap := int(caps_work.get(_card_key(sid), 0))
		if cap < 0:
			continue
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
		if cap2 >= 0 and need > cap2:
			if c.assign_if_able:
				need = cap2
			else:
				need = 0
		if need > 0:
			_add(alloc, _card_key(sid2), need)
			rem -= need
			if cap2 >= 0:
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
		if not caps.has(key):
			continue
		var cur := int(caps[key])
		if cur < 0:
			## 无限：占用不减 cap。
			continue
		caps[key] = maxi(cur - amt, 0)


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
		## 0 = 无余量；>0 有限；<0 无限（无印刷+GRANT）。
		if rem == 0:
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
	## 每腿须在候选且不超过容量（调查员无限；卡 cap<0 = 无印刷不设上限）。
	for key in by_key.keys():
		var amt2 := int(by_key[key])
		if str(key).begins_with("inv:"):
			continue
		if not caps.has(key):
			return false
		var cap_v := int(caps[key])
		if cap_v >= 0 and amt2 > cap_v:
			return false
	var constraints := _active_constraints(game_ctx, inv_id, kind, is_direct)
	for c in constraints:
		match c.assign_op:
			AhcEnums.AssignConstraintOp.PRIOR_FILL:
				var sk := _card_key(c.subject_id)
				var on_subj := int(by_key.get(sk, 0))
				var on_inv := int(by_key.get(_inv_key(inv_id), 0))
				var cap_raw := int(caps.get(sk, 0))
				if cap_raw < 0:
					## 无限容量：不强制先填满。
					pass
				else:
					var cap_left := cap_raw - on_subj
					## 若本卡还能再吃且调查员卡上有量 → 违例。
					if cap_left > 0 and on_inv > 0:
						return false
			AhcEnums.AssignConstraintOp.MIN_TO_SUBJECT:
				var sk2 := _card_key(c.subject_id)
				var got := int(by_key.get(sk2, 0))
				var cap_av := int(caps.get(sk2, 0))
				var need2 := c.assign_amount
				if cap_av >= 0 and c.assign_if_able:
					need2 = mini(c.assign_amount, cap_av)
				if got < need2 and (not c.assign_if_able or cap_av != 0):
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
	## >0 有限容量；-1 无限（无印刷+GRANT）。
	if cap > 0 or cap < 0:
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


## 剩余容量：有印刷 → 印刷−标记；无印刷 + GRANT → **-1（不设上限）**；否则 0（非候选）。
## 调查员 / 敌人外向分配上限不经此函数（各自无限）。
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
	var has_grant := false
	for c in constraints:
		if c.assign_op != AhcEnums.AssignConstraintOp.GRANT_CAPACITY:
			continue
		if c.subject_id != card_id:
			continue
		has_grant = true
		break
	if printed > 0:
		return maxi(printed - tokens, 0)
	## 无印刷：GRANT 仅打开候选，不设可分配上限。
	if has_grant:
		return -1
	return 0


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
