class_name SequenceHandler
extends RefCounted

## 能力**类别**优先级（跨类整批；见 06 §8.1 / 14 §5.2）。
## 同类内选用、队长选序不由 tier 表达，见 ResponseWindow（待建）。
enum Tier { FORCED, FRAMEWORK, TRIGGERED, LISTENER }

var match_kind: StringName = &""
var phase: AhcEnums.SequencePhase = AhcEnums.SequencePhase.WHEN
var tier: Tier = Tier.FORCED
var callback: Callable
## 能力来源（卡实例 / ability id）；用于自身效果结算禁响应。
var source_id: StringName = &""
var controller_id: StringName = &""
var player_initiated: bool = false
var enabled: bool = true


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
	fn: Callable
) -> SequenceHandler:
	var h := SequenceHandler.new()
	h.match_kind = kind
	h.phase = AhcEnums.SequencePhase.AFTER
	h.tier = Tier.TRIGGERED
	h.source_id = source_id
	h.controller_id = controller_id
	h.player_initiated = true
	h.callback = fn
	return h


func matches(trigger: TriggeringCondition) -> bool:
	if match_kind == &"":
		return true
	return trigger.kind == match_kind
