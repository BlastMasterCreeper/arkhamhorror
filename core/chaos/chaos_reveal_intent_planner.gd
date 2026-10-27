class_name ChaosRevealIntentPlanner
extends RefCounted

## 多能力作用于「将要揭示」时的意图规划（FAQ Olive + Grotesque Statue）：
## 1) 选能力生效次序  2) 每条能力选作用于哪一枚预期槽  3) 同时离袋  4) 按能力 CHAOS_PICK 结算子集
## 整批 = **一次**揭示手续；账本可有多行。


## 返回：
## {
##   "tokens": Array[ChaosToken],          # 本批全部物理揭示（同时）
##   "resolved": Array[ChaosToken],        # 计入 resolve / 未整枚 ignore
##   "ignored": Array[ChaosToken],         # 整枚 ignore（ignore_reveal；仍算揭示）
##   "order": Array[StringName],            # 能力生效序
##   "slot_targets": Dictionary,           # ability_id → 作用槽 id
##   "leaf_count": int,
## }
static func plan_and_reveal(
	bag: ChaosBag,
	base_expected: int,
	abilities: Array,
	gate: PlayerInteractionGate,
	game_ctx: GameContext,
	decider_id: StringName,
	source: StringName = &"skill_test"
) -> Dictionary:
	var empty := {
		"tokens": [] as Array[ChaosToken],
		"resolved": [] as Array[ChaosToken],
		"ignored": [] as Array[ChaosToken],
		"order": [],
		"slot_targets": {},
		"leaf_count": 0,
	}
	if bag == null:
		return empty
	var leaves: Array = []
	var next_id := 0
	for _i in range(maxi(base_expected, 1)):
		leaves.append(_new_leaf(next_id, &"", -1))
		next_id += 1
	var ordered: Array = []
	var slot_targets := {}
	if abilities != null and not abilities.is_empty():
		ordered = _normalize_order(
			_order_abilities(abilities, gate, game_ctx, decider_id),
			abilities
		)
		for raw in ordered:
			var ab: ChaosRevealReplaceAbility = raw as ChaosRevealReplaceAbility
			if ab == null:
				continue
			var target_id: int = _pick_target_slot(leaves, ab, gate, game_ctx)
			slot_targets[ab.ability_id] = target_id
			next_id = _expand_slot(leaves, target_id, ab, next_id)
	var tokens: Array[ChaosToken] = []
	for leaf in leaves:
		var tok: ChaosToken = null
		var by_ability: StringName = leaf.get("by_ability", &"") as StringName
		var sealed_host := _sealed_host_for(by_ability, ordered)
		if sealed_host != &"":
			tok = SealFlow.reveal_one_sealed(game_ctx, sealed_host, source)
		else:
			tok = bag.draw_random(source)
		if tok == null:
			break
		leaf["token"] = tok
		tokens.append(tok)
	var resolved: Array[ChaosToken] = []
	var ignored: Array[ChaosToken] = []
	_apply_resolve_picks(leaves, ordered, tokens, resolved, ignored, gate, game_ctx, bag)
	var order_ids: Array = []
	for raw2 in ordered:
		var ab2: ChaosRevealReplaceAbility = raw2 as ChaosRevealReplaceAbility
		if ab2 != null:
			order_ids.append(ab2.ability_id)
	return {
		"tokens": tokens,
		"resolved": resolved,
		"ignored": ignored,
		"order": order_ids,
		"slot_targets": slot_targets,
		"leaf_count": leaves.size(),
	}


static func _new_leaf(id: int, by_ability: StringName, from_slot: int) -> Dictionary:
	return {
		"id": id,
		"by_ability": by_ability,
		"from_slot": from_slot,
		"token": null,
	}


static func _sealed_host_for(ability_id: StringName, ordered: Array) -> StringName:
	if ability_id == &"":
		return &""
	for raw in ordered:
		var ab: ChaosRevealReplaceAbility = raw as ChaosRevealReplaceAbility
		if ab != null and ab.ability_id == ability_id:
			return ab.sealed_host_card_id
	return &""


static func _order_abilities(
	abilities: Array,
	gate: PlayerInteractionGate,
	game_ctx: GameContext,
	decider_id: StringName
) -> Array:
	if abilities.size() <= 1:
		return abilities.duplicate()
	if gate == null:
		return abilities.duplicate()
	var lead := decider_id
	if game_ctx != null and game_ctx.state != null and game_ctx.state.lead_investigator_id != &"":
		lead = game_ctx.state.lead_investigator_id
	return gate.ask_order_simultaneous(
		abilities.duplicate(),
		lead,
		&"chaos:reveal_replace_order",
		game_ctx
	)


## 脚本可按 ability_id（StringName）交序；对象引用亦接受。
static func _normalize_order(ordered: Array, abilities: Array) -> Array:
	if ordered == null or ordered.is_empty():
		return abilities.duplicate()
	var first: Variant = ordered[0]
	var by_id := false
	if first is StringName or first is String:
		by_id = true
	elif first is ChaosRevealReplaceAbility:
		by_id = false
	else:
		return abilities.duplicate()
	if not by_id:
		var objs: Array = []
		for raw in ordered:
			var ab: ChaosRevealReplaceAbility = raw as ChaosRevealReplaceAbility
			if ab != null:
				objs.append(ab)
		for raw2 in abilities:
			var ab2: ChaosRevealReplaceAbility = raw2 as ChaosRevealReplaceAbility
			if ab2 != null and not objs.has(ab2):
				objs.append(ab2)
		return objs
	var map := {}
	for raw3 in abilities:
		var ab3: ChaosRevealReplaceAbility = raw3 as ChaosRevealReplaceAbility
		if ab3 != null:
			map[ab3.ability_id] = ab3
	var out: Array = []
	for id_raw in ordered:
		var aid: StringName = &""
		if id_raw is StringName:
			aid = id_raw as StringName
		else:
			aid = StringName(str(id_raw))
		if map.has(aid):
			out.append(map[aid])
			map.erase(aid)
	for leftover in map.values():
		out.append(leftover)
	return out


static func _pick_target_slot(
	leaves: Array,
	ab: ChaosRevealReplaceAbility,
	gate: PlayerInteractionGate,
	game_ctx: GameContext
) -> int:
	var ids: Array = []
	for leaf in leaves:
		ids.append(int(leaf["id"]))
	if ids.is_empty():
		return -1
	if ids.size() == 1 or gate == null:
		return int(ids[0])
	var controller: StringName = ab.controller_id
	if controller == &"" and game_ctx != null and game_ctx.state != null:
		controller = game_ctx.state.lead_investigator_id
	var pick: Variant = gate.ask_pick_option(
		ids,
		controller,
		StringName("chaos:reveal_replace_target:%s" % String(ab.ability_id)),
		game_ctx
	)
	if pick == null:
		return int(ids[0])
	return int(pick)


static func _expand_slot(
	leaves: Array,
	target_id: int,
	ab: ChaosRevealReplaceAbility,
	next_id: int
) -> int:
	var idx := -1
	for i in leaves.size():
		if int(leaves[i]["id"]) == target_id:
			idx = i
			break
	if idx < 0:
		return next_id
	leaves.remove_at(idx)
	var n := maxi(ab.reveal_count, 1)
	for j in range(n):
		leaves.insert(idx + j, _new_leaf(next_id, ab.ability_id, target_id))
		next_id += 1
	return next_id


static func _apply_resolve_picks(
	leaves: Array,
	ordered: Array,
	all_tokens: Array[ChaosToken],
	resolved: Array[ChaosToken],
	ignored: Array[ChaosToken],
	gate: PlayerInteractionGate,
	game_ctx: GameContext,
	bag: ChaosBag
) -> void:
	var claimed: Dictionary = {} ## token instance → true if already decided
	for raw in ordered:
		var ab: ChaosRevealReplaceAbility = raw as ChaosRevealReplaceAbility
		if ab == null:
			continue
		if ab.resolve_count < 0 or ab.resolve_count >= ab.reveal_count:
			continue
		var group: Array[ChaosToken] = []
		for leaf in leaves:
			if leaf.get("by_ability", &"") != ab.ability_id:
				continue
			var t: ChaosToken = leaf.get("token")
			if t != null and not claimed.has(t):
				group.append(t)
		if group.is_empty():
			continue
		var keep_n := clampi(ab.resolve_count, 0, group.size())
		var keep: Array[ChaosToken] = _chaos_pick_keep(
			group, keep_n, ab.controller_id, ab.ability_id, gate, game_ctx
		)
		for t2 in group:
			claimed[t2] = true
			if keep.has(t2):
				resolved.append(t2)
			else:
				ignored.append(t2)
				if bag != null:
					bag.ignore_reveal(t2)
	## 未被任何「选 resolve」能力认领的叶：默认全部 resolve。
	for leaf2 in leaves:
		var t3: ChaosToken = leaf2.get("token")
		if t3 == null or claimed.has(t3):
			continue
		resolved.append(t3)
		claimed[t3] = true


static func _chaos_pick_keep(
	group: Array[ChaosToken],
	keep_n: int,
	controller_id: StringName,
	ability_id: StringName,
	gate: PlayerInteractionGate,
	game_ctx: GameContext
) -> Array[ChaosToken]:
	var out: Array[ChaosToken] = []
	if keep_n <= 0:
		return out
	if keep_n >= group.size():
		return group.duplicate()
	if gate == null:
		for i in keep_n:
			out.append(group[i])
		return out
	var pick: Variant = gate.ask_chaos_pick(
		group,
		keep_n,
		keep_n,
		controller_id,
		StringName("chaos:resolve_pick:%s" % String(ability_id)),
		game_ctx
	)
	if pick is Array:
		for item in pick as Array:
			if item is ChaosToken:
				out.append(item as ChaosToken)
	if out.size() < keep_n:
		out.clear()
		for i2 in keep_n:
			out.append(group[i2])
	return out
