class_name ModifierEngine
extends RefCounted

var _store: RegistrationStore


func _init(store: RegistrationStore) -> void:
	_store = store


func compute(base: int, query: ModifierQuery, app_ctx: ApplicationContext = null) -> int:
	var mods := _store.collect_modifiers(query.controller_id)
	var add_total := 0
	var mul_factor := 1.0
	for mod in mods:
		if not mod.is_scalar():
			continue
		if not _matches_scalar_stat(mod.stat, query.stat):
			continue
		if mod.condition != null and (app_ctx == null or not mod.condition.matches(app_ctx)):
			continue
		match mod.op:
			AhcEnums.ModOp.ADD:
				add_total += mod.value
			AhcEnums.ModOp.SUB:
				add_total -= mod.value
			AhcEnums.ModOp.DOUBLE:
				mul_factor *= 2.0
			AhcEnums.ModOp.HALVE:
				mul_factor *= 0.5
	var result := int(ceil((base + add_total) * mul_factor))
	return maxi(result, 0)


## ST.5：有类型技能匹配自身；SKILL_ANY 匹配任意技能查询。
func _matches_scalar_stat(mod_stat: AhcEnums.StatRef, query_stat: AhcEnums.StatRef) -> bool:
	if mod_stat == query_stat:
		return true
	if mod_stat == AhcEnums.StatRef.SKILL_ANY and _is_typed_skill(query_stat):
		return true
	return false


func _is_typed_skill(stat: AhcEnums.StatRef) -> bool:
	return (
		stat == AhcEnums.StatRef.SKILL_WILLPOWER
		or stat == AhcEnums.StatRef.SKILL_INTELLECT
		or stat == AhcEnums.StatRef.SKILL_COMBAT
		or stat == AhcEnums.StatRef.SKILL_AGILITY
	)


## 消费式：每个 ATTACK_DAMAGE 修正选一条 amount>0 的 leg 加上；多候选 → PI。
func apply_attack_damage_plan(
	plan: AttackDamagePlan,
	controller_id: StringName,
	game_ctx: GameContext = null,
	app_ctx: ApplicationContext = null
) -> AttackDamagePlan:
	if plan == null:
		return plan
	var mods := _store.collect_modifiers(controller_id)
	for mod in mods:
		if mod.plan_kind != AhcEnums.ModifierPlanKind.ATTACK_DAMAGE:
			continue
		if mod.apply_mode != AhcEnums.ModifierApplyMode.CONSUME_CHOOSE_ONE_LEG:
			continue
		if mod.condition != null and (app_ctx == null or not mod.condition.matches(app_ctx)):
			continue
		var bonus := _bonus_delta(mod)
		if bonus == 0:
			continue
		var indices := plan.positive_leg_indices()
		if indices.is_empty():
			continue
		var chosen := _choose_attack_leg_index(plan, indices, controller_id, game_ctx)
		if chosen < 0:
			continue
		var leg := plan.leg_at(chosen)
		if leg != null:
			leg.amount += bonus
	return plan


func apply_discover_plan(
	plan: DiscoverPlan,
	controller_id: StringName,
	game_ctx: GameContext = null,
	app_ctx: ApplicationContext = null
) -> DiscoverPlan:
	if plan == null:
		return plan
	var mods := _store.collect_modifiers(controller_id)
	for mod in mods:
		if mod.plan_kind != AhcEnums.ModifierPlanKind.DISCOVER:
			continue
		if mod.apply_mode != AhcEnums.ModifierApplyMode.CONSUME_CHOOSE_ONE_LEG:
			continue
		if mod.condition != null and (app_ctx == null or not mod.condition.matches(app_ctx)):
			continue
		var bonus := _bonus_delta(mod)
		if bonus == 0:
			continue
		var indices := plan.positive_leg_indices()
		if indices.is_empty():
			continue
		var chosen := _choose_discover_leg_index(plan, indices, controller_id, game_ctx)
		if chosen < 0:
			continue
		var leg: DiscoverPlan.DiscoverLeg = plan.legs[chosen]
		if leg != null:
			leg.amount += bonus
	return plan


func _bonus_delta(mod: ModifierPayload) -> int:
	match mod.op:
		AhcEnums.ModOp.ADD:
			return mod.value
		AhcEnums.ModOp.SUB:
			return -mod.value
		_:
			return 0


func _choose_attack_leg_index(
	plan: AttackDamagePlan,
	indices: Array[int],
	controller_id: StringName,
	game_ctx: GameContext
) -> int:
	if indices.size() == 1:
		return indices[0]
	## 多候选 → PI；主目标仅作 default。
	var candidates: Array = []
	var default_index := 0
	for i in indices.size():
		var leg_i := plan.leg_at(indices[i])
		if leg_i == null:
			continue
		candidates.append(leg_i.target_id)
		if plan.primary_target_id != &"" and leg_i.target_id == plan.primary_target_id:
			default_index = candidates.size() - 1
	if candidates.is_empty():
		return -1
	if game_ctx != null and game_ctx.interaction != null:
		var pick: Variant = _ask_pick_leg_target(
			candidates, controller_id, default_index, &"mod.attack_damage_leg", game_ctx
		)
		if pick != null:
			for i in indices.size():
				var leg := plan.leg_at(indices[i])
				if leg != null and leg.target_id == pick:
					return indices[i]
	return indices[default_index] if default_index < indices.size() else indices[0]


func _choose_discover_leg_index(
	plan: DiscoverPlan,
	indices: Array[int],
	controller_id: StringName,
	game_ctx: GameContext
) -> int:
	if indices.size() == 1:
		return indices[0]
	var candidates: Array = []
	var default_index := 0
	for i in indices.size():
		var leg: DiscoverPlan.DiscoverLeg = plan.legs[indices[i]]
		if leg == null:
			continue
		candidates.append(leg.location_id)
		if plan.primary_location_id != &"" and leg.location_id == plan.primary_location_id:
			default_index = candidates.size() - 1
	if candidates.is_empty():
		return -1
	if game_ctx != null and game_ctx.interaction != null:
		var pick: Variant = _ask_pick_leg_target(
			candidates, controller_id, default_index, &"mod.discover_leg", game_ctx
		)
		if pick != null:
			for i in indices.size():
				var leg: DiscoverPlan.DiscoverLeg = plan.legs[indices[i]]
				if leg != null and leg.location_id == pick:
					return indices[i]
	return indices[default_index] if default_index < indices.size() else indices[0]


func _ask_pick_leg_target(
	candidates: Array,
	controller_id: StringName,
	default_index: int,
	prompt_id: StringName,
	game_ctx: GameContext
) -> Variant:
	var req := ChoiceRequest.new()
	req.kind = AhcEnums.ChoiceKind.PICK_TARGET
	req.decider_id = controller_id
	req.prompt_id = prompt_id
	req.options = candidates.duplicate()
	req.default_index = clampi(default_index, 0, maxi(candidates.size() - 1, 0))
	req.default_policy = &"first_option"
	req.deadline_ms = -1
	var pick: Variant = game_ctx.interaction.ask(req, game_ctx)
	if pick == null:
		return DefaultChoiceResolver.compute_default(req)
	return pick


## 落点：仅 amount>0 的 leg 结算伤害。
static func settle_attack_damage_plan(game_ctx: GameContext, plan: AttackDamagePlan) -> Dictionary:
	var dealt := 0
	var targets: Array[StringName] = []
	if plan == null:
		return {"ok": false, "dealt": 0, "targets": targets}
	for i in plan.legs.size():
		var leg: AttackDamagePlan.DamageLeg = plan.legs[i]
		if leg == null or leg.amount <= 0 or leg.target_id == &"":
			continue
		var result := EnemyDefeatResolver.deal_damage(game_ctx, leg.target_id, leg.amount)
		if bool(result.get("ok", false)):
			dealt += leg.amount
			targets.append(leg.target_id)
	return {"ok": true, "dealt": dealt, "targets": targets}
