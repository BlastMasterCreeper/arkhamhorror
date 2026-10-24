class_name AttackDamagePlan
extends RefCounted

## 06 §16.3.2 · 攻击成功后的伤害落点计划（可多 leg；修正消费式选一）。


class DamageLeg extends RefCounted:
	var target_id: StringName = &""
	var amount: int = 0

	static func make(target_id: StringName, amount: int) -> DamageLeg:
		var leg := DamageLeg.new()
		leg.target_id = target_id
		leg.amount = amount
		return leg


var legs: Array = [] ## Array[DamageLeg]
var tags: Array[StringName] = []
var primary_target_id: StringName = &""


static func single_enemy(enemy_id: StringName, amount: int = 1) -> AttackDamagePlan:
	var plan := AttackDamagePlan.new()
	plan.primary_target_id = enemy_id
	plan.legs.append(DamageLeg.make(enemy_id, amount))
	return plan


func positive_leg_indices() -> Array[int]:
	var out: Array[int] = []
	for i in legs.size():
		var leg: DamageLeg = legs[i]
		if leg != null and leg.amount > 0 and leg.target_id != &"":
			out.append(i)
	return out


func leg_at(index: int) -> DamageLeg:
	if index < 0 or index >= legs.size():
		return null
	return legs[index] as DamageLeg
