class_name DiscoverPlan
extends RefCounted

## 06 §16.3.2 · 调查成功后的发现线索计划（与 AttackDamagePlan 同构；落地竖切后接）。


class DiscoverLeg extends RefCounted:
	var location_id: StringName = &""
	var amount: int = 0

	static func make(location_id: StringName, amount: int) -> DiscoverLeg:
		var leg := DiscoverLeg.new()
		leg.location_id = location_id
		leg.amount = amount
		return leg


var legs: Array = [] ## Array[DiscoverLeg]
var tags: Array[StringName] = []
var primary_location_id: StringName = &""


static func single_location(location_id: StringName, amount: int = 1) -> DiscoverPlan:
	var plan := DiscoverPlan.new()
	plan.primary_location_id = location_id
	plan.legs.append(DiscoverLeg.make(location_id, amount))
	return plan


func positive_leg_indices() -> Array[int]:
	var out: Array[int] = []
	for i in legs.size():
		var leg: DiscoverLeg = legs[i]
		if leg != null and leg.amount > 0 and leg.location_id != &"":
			out.append(i)
	return out
