class_name SoakAssigner
extends RefCounted

## 承伤/承恐分摊（deal 内 PI 的客观核）：候选 · 约束 · 默认表 · 校验。
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
	var alloc: Dictionary = {} ## id -> amount；调查员用 inv_id 键，前缀区分
	var rem := total
	## 1) PRIOR_FILL：先填满优先卡。
	for c in constraints:
		if c.assign_op != AhcEnums.AssignConstraintOp.PRIOR_FILL:
			continue
		var sid: StringName = c.subject_id
		var cap := int(caps.get(_card_key(sid), 0))
		var take := mini(cap, rem)
		if take > 0:
			_add(alloc, _card_key(sid), take)
			rem -= take
			caps[_card_key(sid)] = cap - take
	## 2) MIN_TO_SUBJECT。
	for c in constraints:
		if c.assign_op != AhcEnums.AssignConstraintOp.MIN_TO_SUBJECT:
			continue
		var sid2: StringName = c.subject_id
		var cap2 := int(caps.get(_card_key(sid2), 0))
		var need := mini(c.assign_amount, rem)
		if need > cap2:
			if c.assign_if_able:
				need = cap2
			else:
				need = 0
		if need > 0:
			_add(alloc, _card_key(sid2), need)
			rem -= need
			caps[_card_key(sid2)] = cap2 - need
	## 3) 剩余默认归调查员卡（受 MAX_TO_MATCH 限制的不能往匹配资产乱塞——默认本来就不塞）。
	if rem > 0:
		_add(alloc, _inv_key(inv_id), rem)
		rem = 0
	## 4) 若默认把点分到匹配资产会破 MAX——默认算法不主动分给资产，仅 PRIOR/MIN 会；
	##    再跑一遍校验，失败则整表打回调查员（防御）。
	var legs := _alloc_to_legs(alloc, inv_id)
	if not validate(game_ctx, inv_id, kind, is_direct, total, legs):
		return [{"bearer": &"investigator", "id": inv_id, "amount": total}]
	return legs


static func validate(
	game_ctx: GameContext,
	inv_id: StringName,
	kind: StringName,
	is_direct: bool,
	total: int,
	legs: Array
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
	var caps: Dictionary = {}
	var constraints := _active_constraints(game_ctx, inv_id, kind, is_direct)
	if is_direct:
		## direct：默认无资产；ALLOW_DIRECT / INCLUDE self_deals+DIRECT|BOTH 加入。
		for c in constraints:
			if c.assign_op != AhcEnums.AssignConstraintOp.INCLUDE_CANDIDATE:
				continue
			if c.assign_expand_scope == &"other_at_location":
				continue
			var cap := _asset_remaining(game_ctx, c.subject_id, kind)
			if cap > 0:
				caps[_card_key(c.subject_id)] = cap
		return caps
	## non-direct：己方可承伤/恐资产 + INCLUDE。
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv != null:
		for card_id in inv.play_area:
			var cap2 := _asset_remaining(game_ctx, card_id, kind)
			if cap2 > 0:
				caps[_card_key(card_id)] = cap2
	for c in constraints:
		if c.assign_op != AhcEnums.AssignConstraintOp.INCLUDE_CANDIDATE:
			continue
		if c.assign_expand_scope == &"other_at_location":
			if not _same_location(game_ctx, c.drawer_id, inv_id):
				continue
			var cap3 := _asset_remaining(game_ctx, c.subject_id, kind)
			if cap3 > 0:
				caps[_card_key(c.subject_id)] = cap3
	return caps


static func _asset_remaining(game_ctx: GameContext, card_id: StringName, kind: StringName) -> int:
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null or card.zone != AhcEnums.Zone.PLAY_AREA:
		return 0
	var def := card.id.definition_id
	if kind == &"horror":
		var sanity := CardRegistry.printed_sanity(def)
		if sanity <= 0:
			return 0
		return maxi(sanity - card.tokens.horror, 0)
	var health := CardRegistry.printed_health(def)
	if health <= 0:
		return 0
	return maxi(health - card.tokens.damage, 0)


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
