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


## 域 B：匹配 plan_kind 的消费式修正应用一次。
## 无名 +N **不含目标**：只改已定效果的攻击伤害/发现量（plan.apply_amount_bonus）。
## 须先定效果（DETERMINED 腿 / ASSIGN 候选）；指名落点（09059 等）由效果步另写，不经此默认。
func apply_to_amount_plan(
	plan: AmountPlan,
	controller_id: StringName,
	game_ctx: GameContext = null,
	app_ctx: ApplicationContext = null
) -> AmountPlan:
	if plan == null or plan.kind == AhcEnums.ModifierPlanKind.NONE:
		return plan
	var mods := _store.collect_modifiers(controller_id)
	for mod in mods:
		if mod.plan_kind != plan.kind:
			continue
		if mod.apply_mode != AhcEnums.ModifierApplyMode.CONSUME_CHOOSE_ONE_LEG:
			continue
		if mod.condition != null and (app_ctx == null or not mod.condition.matches(app_ctx)):
			continue
		var bonus := _bonus_delta(mod)
		if bonus == 0:
			continue
		## 攻击与发现无名修正同构：改量，不选宿主。
		plan.apply_amount_bonus(bonus)
	return plan


func _bonus_delta(mod: ModifierPayload) -> int:
	match mod.op:
		AhcEnums.ModOp.ADD:
			return mod.value
		AhcEnums.ModOp.SUB:
			return -mod.value
		_:
			return 0


func _choose_leg_index(
	plan: AmountPlan,
	indices: Array[int],
	controller_id: StringName,
	game_ctx: GameContext
) -> int:
	if indices.size() == 1:
		return indices[0]
	## 多候选 → PI；primary_subject_id 仅作 default。
	var candidates: Array = []
	var default_index := 0
	for i in indices.size():
		var leg_i := plan.leg_at(indices[i])
		if leg_i == null:
			continue
		candidates.append(leg_i.subject_id)
		if plan.primary_subject_id != &"" and leg_i.subject_id == plan.primary_subject_id:
			default_index = candidates.size() - 1
	if candidates.is_empty():
		return -1
	if game_ctx != null and game_ctx.interaction != null:
		var pick: Variant = _ask_pick_leg_target(
			candidates, controller_id, default_index, plan.pi_prompt_id(), game_ctx
		)
		if pick != null:
			for i in indices.size():
				var leg := plan.leg_at(indices[i])
				if leg != null and leg.subject_id == pick:
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


## 落点：仅 amount>0 的 leg；按 plan.kind 分派。ctx 可带 inv_id（发现）等。
static func settle_amount_plan(
	game_ctx: GameContext,
	plan: AmountPlan,
	ctx: Dictionary = {}
) -> Dictionary:
	if plan == null:
		return {"ok": false, "settled": 0, "subjects": [] as Array[StringName]}
	match plan.kind:
		AhcEnums.ModifierPlanKind.ATTACK_DAMAGE:
			return _settle_attack_damage(game_ctx, plan)
		AhcEnums.ModifierPlanKind.DISCOVER:
			return _settle_discover(game_ctx, plan, ctx.get("inv_id", &"") as StringName)
		_:
			return {"ok": false, "error": &"unknown_plan_kind", "settled": 0, "subjects": [] as Array[StringName]}


static func _settle_attack_damage(game_ctx: GameContext, plan: AmountPlan) -> Dictionary:
	## ASSIGN：执行时物化（Gate 待接；headless 默认整量 → primary）。
	plan.materialize_assign_default()
	var settled := 0
	var subjects: Array[StringName] = []
	for i in plan.legs.size():
		var leg := plan.leg_at(i)
		if leg == null or leg.amount <= 0 or leg.subject_id == &"":
			continue
		var result := EnemyDefeatResolver.deal_damage(game_ctx, leg.subject_id, leg.amount)
		if bool(result.get("ok", false)):
			settled += leg.amount
			subjects.append(leg.subject_id)
	return {
		"ok": true,
		"settled": settled,
		"dealt": settled,
		"subjects": subjects,
		"targets": subjects,
		"amount_remaining": plan.amount,
	}


static func _settle_discover(
	game_ctx: GameContext,
	plan: AmountPlan,
	inv_id: StringName
) -> Dictionary:
	var settled := 0
	var subjects: Array[StringName] = []
	if inv_id == &"":
		return {"ok": false, "error": &"missing_inv_id", "settled": 0, "subjects": subjects}
	for i in plan.legs.size():
		var leg := plan.leg_at(i)
		if leg == null or leg.amount <= 0 or leg.subject_id == &"":
			continue
		var moved := 0
		if game_ctx != null and game_ctx.sequence_catalog != null:
			var nest_res: Variant = game_ctx.sequence_catalog.nest(
				game_ctx,
				&"seq.effect.discover_clue",
				{
					"inv_id": inv_id,
					"location_id": leg.subject_id,
					"amount": leg.amount,
				}
			)
			if nest_res is Dictionary:
				moved = int((nest_res as Dictionary).get("amount", 0))
		elif game_ctx != null:
			var run_res := DiscoverClueFlow.run(
				game_ctx, inv_id, leg.subject_id, leg.amount
			)
			moved = int(run_res.get("amount", 0))
		if moved > 0:
			settled += moved
			subjects.append(leg.subject_id)
	return {
		"ok": true,
		"settled": settled,
		"discovered": settled,
		"subjects": subjects,
		"locations": subjects,
	}
