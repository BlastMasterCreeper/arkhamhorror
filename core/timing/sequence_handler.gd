class_name SequenceHandler
extends RefCounted

## 能力**类别**优先级（跨类整批；见 06 §8.1 / 14 §5.2）。
## 显现（Revelation）是独立类，**不是** FORCED；不进同窗口 Forced 批（06 §8.1.1）。
## 同类内：Forced 自动批；player_initiated TRIGGERED → 意愿池（16 §7.1）。
enum Tier { FORCED, FRAMEWORK, TRIGGERED, REVELATION, LISTENER }

var match_kind: StringName = &""
var phase: AhcEnums.SequencePhase = AhcEnums.SequencePhase.WHEN
var tier: Tier = Tier.FORCED
var callback: Callable
## 能力来源（卡实例 / ability id）；用于自身效果结算禁响应。
var source_id: StringName = &""
var controller_id: StringName = &""
## 响应模式查找键（16 §7.1.3）；可空。
var definition_id: StringName = &""
var ability_id: StringName = &""
var player_initiated: bool = false
var enabled: bool = true
## COLLECT L3 情景（可空 = 无条件）。
var collect_condition: Condition = null
## COLLECT L5：剩余次数；`< 0` = 无限；`0` = 耗尽不出候选。
var limit_remaining: int = -1
## deal / 受到伤恐：同一时点的条件过滤。`damage` | `horror` | `either`（空=either）。
var affliction_filter: StringName = &"either"


static func when_forced(kind: StringName, fn: Callable) -> SequenceHandler:
	var h := SequenceHandler.new()
	h.match_kind = kind
	h.phase = AhcEnums.SequencePhase.WHEN
	h.tier = Tier.FORCED
	h.callback = fn
	return h


static func would_forced(kind: StringName, fn: Callable) -> SequenceHandler:
	var h := SequenceHandler.new()
	h.match_kind = kind
	h.phase = AhcEnums.SequencePhase.WOULD
	h.tier = Tier.FORCED
	h.callback = fn
	return h


static func after_forced(kind: StringName, fn: Callable) -> SequenceHandler:
	var h := SequenceHandler.new()
	h.match_kind = kind
	h.phase = AhcEnums.SequencePhase.AFTER
	h.tier = Tier.FORCED
	h.callback = fn
	return h


## 受到伤害后（须 damage>0）。
static func after_take_damage(fn: Callable) -> SequenceHandler:
	var h := after_forced(&"damage", fn)
	h.affliction_filter = &"damage"
	return h


## 受到恐惧后（须 horror>0）。
static func after_take_horror(fn: Callable) -> SequenceHandler:
	var h := after_forced(&"damage", fn)
	h.affliction_filter = &"horror"
	return h


## 受到伤害和/或恐惧后（至少一种 >0）。
static func after_take_damage_or_horror(fn: Callable) -> SequenceHandler:
	var h := after_forced(&"damage", fn)
	h.affliction_filter = &"either"
	return h


static func after_reaction(
	kind: StringName,
	source_id: StringName,
	controller_id: StringName,
	fn: Callable,
	ability_id: StringName = &"",
	definition_id: StringName = &""
) -> SequenceHandler:
	var h := SequenceHandler.new()
	h.match_kind = kind
	h.phase = AhcEnums.SequencePhase.AFTER
	h.tier = Tier.TRIGGERED
	h.source_id = source_id
	h.controller_id = controller_id
	h.ability_id = ability_id if ability_id != &"" else source_id
	h.definition_id = definition_id
	h.player_initiated = true
	h.callback = fn
	return h


static func when_revelation(kind: StringName, fn: Callable) -> SequenceHandler:
	var h := SequenceHandler.new()
	h.match_kind = kind
	h.phase = AhcEnums.SequencePhase.WHEN
	h.tier = Tier.REVELATION
	h.callback = fn
	return h


func matches(trigger: TriggeringCondition) -> bool:
	if match_kind != &"" and (trigger == null or trigger.kind != match_kind):
		return false
	if match_kind == &"damage" and not _affliction_filter_ok(trigger):
		return false
	return true


func _affliction_filter_ok(trigger: TriggeringCondition) -> bool:
	var filt := affliction_filter if affliction_filter != &"" else &"either"
	var amounts := TriggeringCondition.affliction_amounts(trigger)
	var dmg := int(amounts.get("damage", 0))
	var hor := int(amounts.get("horror", 0))
	match filt:
		&"damage":
			return dmg > 0
		&"horror":
			return hor > 0
		_:
			return dmg > 0 or hor > 0
