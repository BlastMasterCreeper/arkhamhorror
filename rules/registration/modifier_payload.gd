class_name ModifierPayload
extends RefCounted

var stat: AhcEnums.StatRef = AhcEnums.StatRef.SKILL_WILLPOWER
var op: AhcEnums.ModOp = AhcEnums.ModOp.ADD
var value: int = 0
var condition: Condition = null
## NONE = 标量站点（compute）；ATTACK_DAMAGE / DISCOVER = Plan 消费式。
var plan_kind: AhcEnums.ModifierPlanKind = AhcEnums.ModifierPlanKind.NONE
var apply_mode: AhcEnums.ModifierApplyMode = AhcEnums.ModifierApplyMode.SCALAR


static func add_skill(stat: AhcEnums.StatRef, amount: int) -> ModifierPayload:
	var p := ModifierPayload.new()
	p.stat = stat
	p.op = AhcEnums.ModOp.ADD
	p.value = amount
	return p


## 无类型技能修正（任意检定 +N）。
static func add_skill_any(amount: int) -> ModifierPayload:
	return add_skill(AhcEnums.StatRef.SKILL_ANY, amount)


## 调查 shroud 修正（常为减：reduce_shroud；加算用 ADD）。
static func modify_shroud(amount: int, op: AhcEnums.ModOp = AhcEnums.ModOp.ADD) -> ModifierPayload:
	var p := ModifierPayload.new()
	p.stat = AhcEnums.StatRef.SHROUD
	p.op = op
	p.value = amount
	return p


static func reduce_shroud(amount: int) -> ModifierPayload:
	return modify_shroud(amount, AhcEnums.ModOp.SUB)


static func add_resource_gain(amount: int, apply_condition: Condition = null) -> ModifierPayload:
	var p := ModifierPayload.new()
	p.stat = AhcEnums.StatRef.RESOURCE_GAIN_AMOUNT
	p.op = AhcEnums.ModOp.ADD
	p.value = amount
	p.condition = apply_condition
	return p


static func reduce_initiation_resource_cost(
	amount: int,
	apply_condition: Condition = null
) -> ModifierPayload:
	var p := ModifierPayload.new()
	p.stat = AhcEnums.StatRef.INITIATION_RESOURCE_COST
	p.op = AhcEnums.ModOp.SUB
	p.value = amount
	p.condition = apply_condition
	return p


static func reduce_initiation_action_cost(
	amount: int,
	apply_condition: Condition = null
) -> ModifierPayload:
	var p := ModifierPayload.new()
	p.stat = AhcEnums.StatRef.INITIATION_ACTION_COST
	p.op = AhcEnums.ModOp.SUB
	p.value = amount
	p.condition = apply_condition
	return p


## 本次攻击伤害 +N（消费式选一 leg；多候选 PI）。
static func attack_damage_bonus(amount: int, apply_condition: Condition = null) -> ModifierPayload:
	var p := ModifierPayload.new()
	p.plan_kind = AhcEnums.ModifierPlanKind.ATTACK_DAMAGE
	p.apply_mode = AhcEnums.ModifierApplyMode.CONSUME_CHOOSE_ONE_LEG
	p.op = AhcEnums.ModOp.ADD
	p.value = amount
	p.condition = apply_condition
	return p


## 本次发现线索 +N（AmountPlan · DISCOVER）。
static func discover_bonus(amount: int, apply_condition: Condition = null) -> ModifierPayload:
	var p := ModifierPayload.new()
	p.plan_kind = AhcEnums.ModifierPlanKind.DISCOVER
	p.apply_mode = AhcEnums.ModifierApplyMode.CONSUME_CHOOSE_ONE_LEG
	p.op = AhcEnums.ModOp.ADD
	p.value = amount
	p.condition = apply_condition
	return p


## 本次造成恐惧 +N（AmountPlan · HORROR；settle 竖切待接）。
static func horror_bonus(amount: int, apply_condition: Condition = null) -> ModifierPayload:
	var p := ModifierPayload.new()
	p.plan_kind = AhcEnums.ModifierPlanKind.HORROR
	p.apply_mode = AhcEnums.ModifierApplyMode.CONSUME_CHOOSE_ONE_LEG
	p.op = AhcEnums.ModOp.ADD
	p.value = amount
	p.condition = apply_condition
	return p


func is_scalar() -> bool:
	return plan_kind == AhcEnums.ModifierPlanKind.NONE


func is_skill_stat() -> bool:
	return (
		stat == AhcEnums.StatRef.SKILL_WILLPOWER
		or stat == AhcEnums.StatRef.SKILL_INTELLECT
		or stat == AhcEnums.StatRef.SKILL_COMBAT
		or stat == AhcEnums.StatRef.SKILL_AGILITY
		or stat == AhcEnums.StatRef.SKILL_ANY
	)
