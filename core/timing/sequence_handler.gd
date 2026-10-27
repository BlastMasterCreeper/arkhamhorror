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


static func when_forced(kind: StringName, fn: Callable) -> SequenceHandler:
	var h := SequenceHandler.new()
	h.match_kind = kind
	h.phase = AhcEnums.SequencePhase.WHEN
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
	if match_kind == &"":
		return true
	return trigger.kind == match_kind
