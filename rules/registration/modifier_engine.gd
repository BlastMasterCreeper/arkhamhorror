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
	if plan.effect_shape == AhcEnums.AmountEffectShape.ASSIGN:
		return _settle_attack_assignable(game_ctx, plan)
	return _settle_attack_determined(game_ctx, plan)


static func _settle_attack_assignable(game_ctx: GameContext, plan: AmountPlan) -> Dictionary:
	## 有分配：nest damage.assignable（内侧 Assign+Apply）。
	var amount := plan.amount
	var subjects: Array[StringName] = []
	if amount <= 0:
		return {
			"ok": false,
			"settled": 0,
			"dealt": 0,
			"subjects": subjects,
			"amount_remaining": plan.amount,
		}
	var settled := 0
	if game_ctx != null and game_ctx.sequence_catalog != null:
		var nest_res: Variant = game_ctx.sequence_catalog.nest(
			game_ctx,
			&"seq.effect.damage.assignable",
			{
				"controller_id": plan.primary_subject_id,
				"kind": &"damage",
				"target": &"enemy",
				"amount": amount,
				"primary_id": plan.primary_subject_id,
				"candidates": plan.candidate_ids,
			}
		)
		if nest_res is Dictionary:
			settled = int((nest_res as Dictionary).get("amount", 0))
			var legs_v: Variant = (nest_res as Dictionary).get("legs", [])
			if legs_v is Array:
				for entry in legs_v as Array:
					if entry is Dictionary:
						var sid: StringName = (entry as Dictionary).get("id", &"")
						if sid != &"":
							subjects.append(sid)
	else:
		plan.materialize_assign_default()
		return _settle_attack_determined(game_ctx, plan)
	plan.amount = 0
	return {
		"ok": settled > 0,
		"settled": settled,
		"dealt": settled,
		"subjects": subjects,
		"targets": subjects,
		"amount_remaining": plan.amount,
		"assignable": true,
	}


static func _settle_attack_determined(game_ctx: GameContext, plan: AmountPlan) -> Dictionary:
	var legs_payload: Array = []
	var subjects: Array[StringName] = []
	for i in plan.legs.size():
		var leg := plan.leg_at(i)
		if leg == null or leg.amount <= 0 or leg.subject_id == &"":
			continue
		legs_payload.append({"id": leg.subject_id, "amount": leg.amount})
		subjects.append(leg.subject_id)
	if legs_payload.is_empty():
		return {
			"ok": false,
			"settled": 0,
			"dealt": 0,
			"subjects": subjects,
			"amount_remaining": plan.amount,
		}
	var settled := 0
	## 无分配：一条 seq.effect.damage + legs。
	if game_ctx != null and game_ctx.sequence_catalog != null:
		var nest_res: Variant = game_ctx.sequence_catalog.nest(
			game_ctx,
			&"seq.effect.damage",
			{
				"controller_id": plan.primary_subject_id,
				"kind": &"damage",
				"target": &"enemy",
				"legs": legs_payload,
			}
		)
		if nest_res is Dictionary:
			settled = int((nest_res as Dictionary).get("amount", 0))
	else:
		for entry in legs_payload:
			var eid: StringName = entry.get("id", &"")
			var amt := int(entry.get("amount", 0))
			var result := EnemyDefeatResolver.deal_damage(game_ctx, eid, amt)
			if bool(result.get("ok", false)):
				settled += amt
	return {
		"ok": settled > 0,
		"settled": settled,
		"dealt": settled,
		"subjects": subjects,
		"targets": subjects,
		"amount_remaining": plan.amount,
		"multi": true,
	}


static func _settle_discover(
	game_ctx: GameContext,
	plan: AmountPlan,
	inv_id: StringName
) -> Dictionary:
	var subjects: Array[StringName] = []
	if inv_id == &"":
		return {"ok": false, "error": &"missing_inv_id", "settled": 0, "subjects": subjects}
	var legs_payload: Array = []
	for i in plan.legs.size():
		var leg := plan.leg_at(i)
		if leg == null or leg.amount <= 0 or leg.subject_id == &"":
			continue
		legs_payload.append({"location_id": leg.subject_id, "amount": leg.amount})
		subjects.append(leg.subject_id)
	if legs_payload.is_empty():
		return {"ok": false, "settled": 0, "subjects": subjects}
	var settled := 0
	## 一条 seq.effect.discover_clue + legs；原语仍逐地单目标。
	if game_ctx != null and game_ctx.sequence_catalog != null:
		var nest_res: Variant = game_ctx.sequence_catalog.nest(
			game_ctx,
			&"seq.effect.discover_clue",
			{"inv_id": inv_id, "legs": legs_payload}
		)
		if nest_res is Dictionary:
			settled = int((nest_res as Dictionary).get("amount", 0))
	else:
		var run_res := DiscoverClueFlow.run_params(
			game_ctx, {"inv_id": inv_id, "legs": legs_payload}
		)
		settled = int(run_res.get("amount", 0))
	return {
		"ok": settled > 0,
		"settled": settled,
		"discovered": settled,
		"subjects": subjects,
		"locations": subjects,
		"multi": true,
	}
