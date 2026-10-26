class_name AmountPlan
extends RefCounted

## 06 §6 / §16.3.2 · 域 B 效果量计划（伤 / 发现 同构）。
## 攻击伤：bonus_routing 决定修正如何进 Plan；发现：消费式选一腿。


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
## 攻击伤专用；发现忽略（仍走选腿）。
var bonus_routing: AhcEnums.AmountBonusRouting = AhcEnums.AmountBonusRouting.PIN_PRIMARY
## ADD_TO_POOL：尚未 Assign 进腿的可分配总量（基础 + 已应用修正）。
var pool_amount: int = 0
## ADD_TO_POOL Assign 候选（敌 id）；空则默认仅 primary。
var candidate_ids: Array[StringName] = []


static func attack_damage_single(enemy_id: StringName, amount: int = 1) -> AmountPlan:
	var plan := _single(AhcEnums.ModifierPlanKind.ATTACK_DAMAGE, enemy_id, amount)
	plan.bonus_routing = AhcEnums.AmountBonusRouting.PIN_PRIMARY
	return plan


## 多敌落点、未写分配（03153）：修正钉主目标。
static func attack_damage_pin_primary(
	primary_id: StringName,
	leg_amounts: Dictionary
) -> AmountPlan:
	var plan := AmountPlan.new()
	plan.kind = AhcEnums.ModifierPlanKind.ATTACK_DAMAGE
	plan.bonus_routing = AhcEnums.AmountBonusRouting.PIN_PRIMARY
	plan.primary_subject_id = primary_id
	for sid in leg_amounts.keys():
		plan.legs.append(AmountLeg.make(sid as StringName, int(leg_amounts[sid])))
	if plan.find_leg_index(primary_id) < 0 and primary_id != &"":
		plan.legs.append(AmountLeg.make(primary_id, 0))
	return plan


## 写明分配（04305）：总量进 pool，修正先加 pool，再 Assign。
static func attack_damage_assign_pool(
	total: int,
	primary_id: StringName,
	candidates: Array[StringName] = []
) -> AmountPlan:
	var plan := AmountPlan.new()
	plan.kind = AhcEnums.ModifierPlanKind.ATTACK_DAMAGE
	plan.bonus_routing = AhcEnums.AmountBonusRouting.ADD_TO_POOL
	plan.primary_subject_id = primary_id
	plan.pool_amount = maxi(total, 0)
	plan.candidate_ids = candidates.duplicate()
	if plan.candidate_ids.is_empty() and primary_id != &"":
		plan.candidate_ids.append(primary_id)
	return plan


static func discover_single(location_id: StringName, amount: int = 1) -> AmountPlan:
	return _single(AhcEnums.ModifierPlanKind.DISCOVER, location_id, amount)


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


## 把 amount 加到指定 subject 腿；无则新建。
func add_to_subject(subject_id: StringName, amount: int) -> void:
	if subject_id == &"" or amount == 0:
		return
	var idx := find_leg_index(subject_id)
	if idx < 0:
		legs.append(AmountLeg.make(subject_id, amount))
		return
	var leg := leg_at(idx)
	if leg != null:
		leg.amount += amount


## Headless / 逾期默认：整池摊到 primary（Gate Assign 后补）。
func assign_pool_default() -> void:
	if bonus_routing != AhcEnums.AmountBonusRouting.ADD_TO_POOL:
		return
	var rem := pool_amount
	if rem <= 0:
		return
	var target := primary_subject_id
	if target == &"" and not candidate_ids.is_empty():
		target = candidate_ids[0]
	if target == &"":
		return
	add_to_subject(target, rem)
	pool_amount = 0


func pi_prompt_id() -> StringName:
	match kind:
		AhcEnums.ModifierPlanKind.ATTACK_DAMAGE:
			return &"mod.attack_damage_leg"
		AhcEnums.ModifierPlanKind.DISCOVER:
			return &"mod.discover_leg"
		_:
			return &"mod.amount_plan_leg"
