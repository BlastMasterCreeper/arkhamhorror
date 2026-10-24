class_name AmountPlan
extends RefCounted

## 06 §6 / §16.3.2 · 域 B 效果量计划（伤 / 发现 / 恐惧… 同构）。
## 修正消费式选一 leg；多候选 PI。Plan 是应用宿主，不是 Buff 来源。


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


static func attack_damage_single(enemy_id: StringName, amount: int = 1) -> AmountPlan:
	return _single(AhcEnums.ModifierPlanKind.ATTACK_DAMAGE, enemy_id, amount)


static func discover_single(location_id: StringName, amount: int = 1) -> AmountPlan:
	return _single(AhcEnums.ModifierPlanKind.DISCOVER, location_id, amount)


static func horror_single(subject_id: StringName, amount: int = 1) -> AmountPlan:
	return _single(AhcEnums.ModifierPlanKind.HORROR, subject_id, amount)


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


func pi_prompt_id() -> StringName:
	match kind:
		AhcEnums.ModifierPlanKind.ATTACK_DAMAGE:
			return &"mod.attack_damage_leg"
		AhcEnums.ModifierPlanKind.DISCOVER:
			return &"mod.discover_leg"
		AhcEnums.ModifierPlanKind.HORROR:
			return &"mod.horror_leg"
		_:
			return &"mod.amount_plan_leg"
