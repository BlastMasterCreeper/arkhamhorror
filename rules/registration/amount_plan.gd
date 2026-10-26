class_name AmountPlan
extends RefCounted

## 06 §6 / §16.3.2 · 域 B 效果量计划。
## 序：先定效果/目标 → 无名修正只改量（不含目标）→ 物化（ASSIGN）→ settle。


class AmountLeg extends RefCounted:
	## 宿主：敌人 / 地点 / 调查员…（由 plan.kind 解释）
	var subject_id: StringName = &""
	var amount: int = 0

	static func make(subject_id: StringName, amount: int) -> AmountLeg:
		var leg := AmountLeg.new()
		leg.subject_id = subject_id
		leg.amount = amount
		return leg


## 与 AhcEnums.ModifierPlanKind 效果量成员对齐（不含 NONE）。
var kind: AhcEnums.ModifierPlanKind = AhcEnums.ModifierPlanKind.ATTACK_DAMAGE
var legs: Array = [] ## Array[AmountLeg]
var tags: Array[StringName] = []
var primary_subject_id: StringName = &""
## 物化形态；默认目标已定。
var effect_shape: AhcEnums.AmountEffectShape = AhcEnums.AmountEffectShape.DETERMINED
## ASSIGN：本次攻击伤害数值（修正加在这里；执行时再 Assign → legs）。
## DETERMINED：可与 primary 腿同步；修正直接加 primary 腿。
var amount: int = 0
## ASSIGN 候选（敌 id）；空则默认仅 primary。
var candidate_ids: Array[StringName] = []


static func attack_damage_single(enemy_id: StringName, amount: int = 1) -> AmountPlan:
	var plan := _single(AhcEnums.ModifierPlanKind.ATTACK_DAMAGE, enemy_id, amount)
	plan.effect_shape = AhcEnums.AmountEffectShape.DETERMINED
	plan.amount = maxi(amount, 0)
	return plan


## 目标已定多腿（03153）：无名修正加在攻击目标（primary）的伤害量上。
static func attack_damage_determined(
	primary_id: StringName,
	leg_amounts: Dictionary
) -> AmountPlan:
	var plan := AmountPlan.new()
	plan.kind = AhcEnums.ModifierPlanKind.ATTACK_DAMAGE
	plan.effect_shape = AhcEnums.AmountEffectShape.DETERMINED
	plan.primary_subject_id = primary_id
	for sid in leg_amounts.keys():
		plan.legs.append(AmountLeg.make(sid as StringName, int(leg_amounts[sid])))
	if plan.find_leg_index(primary_id) < 0 and primary_id != &"":
		plan.legs.append(AmountLeg.make(primary_id, 0))
	var primary_leg := plan.leg_at(plan.find_leg_index(primary_id))
	plan.amount = primary_leg.amount if primary_leg != null else 0
	return plan


## 04305：先定效果（候选集）；amount = 攻击伤害；修正改 amount；执行再 Assign。
static func attack_damage_assign(
	attack_damage: int,
	primary_id: StringName,
	candidates: Array[StringName] = []
) -> AmountPlan:
	var plan := AmountPlan.new()
	plan.kind = AhcEnums.ModifierPlanKind.ATTACK_DAMAGE
	plan.effect_shape = AhcEnums.AmountEffectShape.ASSIGN
	plan.primary_subject_id = primary_id
	plan.amount = maxi(attack_damage, 0)
	plan.candidate_ids = candidates.duplicate()
	if plan.candidate_ids.is_empty() and primary_id != &"":
		plan.candidate_ids.append(primary_id)
	return plan


static func discover_single(location_id: StringName, amount: int = 1) -> AmountPlan:
	var plan := _single(AhcEnums.ModifierPlanKind.DISCOVER, location_id, amount)
	plan.effect_shape = AhcEnums.AmountEffectShape.DETERMINED
	plan.amount = maxi(amount, 0)
	return plan


static func _single(
	kind: AhcEnums.ModifierPlanKind,
	subject_id: StringName,
	amount: int
) -> AmountPlan:
	var plan := AmountPlan.new()
	plan.kind = kind
	plan.primary_subject_id = subject_id
	plan.legs.append(AmountLeg.make(subject_id, amount))
	return plan


func positive_leg_indices() -> Array[int]:
	var out: Array[int] = []
	for i in legs.size():
		var leg: AmountLeg = legs[i]
		if leg != null and leg.amount > 0 and leg.subject_id != &"":
			out.append(i)
	return out


func leg_at(index: int) -> AmountLeg:
	if index < 0 or index >= legs.size():
		return null
	return legs[index] as AmountLeg


func find_leg_index(subject_id: StringName) -> int:
	if subject_id == &"":
		return -1
	for i in legs.size():
		var leg: AmountLeg = legs[i]
		if leg != null and leg.subject_id == subject_id:
			return i
	return -1


## 把 delta 加到指定 subject 腿；无则新建。
func add_to_subject(subject_id: StringName, delta: int) -> void:
	if subject_id == &"" or delta == 0:
		return
	var idx := find_leg_index(subject_id)
	if idx < 0:
		legs.append(AmountLeg.make(subject_id, delta))
		return
	var leg := leg_at(idx)
	if leg != null:
		leg.amount += delta


## 无名修正：只改本次攻击伤害（或发现）数值；不含目标。
func apply_amount_bonus(delta: int) -> void:
	if delta == 0:
		return
	match effect_shape:
		AhcEnums.AmountEffectShape.ASSIGN:
			amount = maxi(amount + delta, 0)
		_:
			## DETERMINED：攻击伤害量 = primary 腿。
			var primary := primary_subject_id
			if primary == &"":
				return
			add_to_subject(primary, delta)
			var leg := leg_at(find_leg_index(primary))
			amount = leg.amount if leg != null else maxi(amount + delta, 0)


## ASSIGN 物化：Gate 待接；headless 默认整量 → primary。
func materialize_assign_default() -> void:
	if effect_shape != AhcEnums.AmountEffectShape.ASSIGN:
		return
	var rem := amount
	if rem <= 0:
		return
	var target := primary_subject_id
	if target == &"" and not candidate_ids.is_empty():
		target = candidate_ids[0]
	if target == &"":
		return
	add_to_subject(target, rem)
	amount = 0


func pi_prompt_id() -> StringName:
	match kind:
		AhcEnums.ModifierPlanKind.ATTACK_DAMAGE:
			return &"mod.attack_damage_leg"
		AhcEnums.ModifierPlanKind.DISCOVER:
			return &"mod.discover_leg"
		_:
			return &"mod.amount_plan_leg"
