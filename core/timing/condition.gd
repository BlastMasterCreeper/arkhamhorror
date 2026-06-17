class_name Condition
extends RefCounted

var tags_all: Array[StringName] = []
var _use_framework_step: bool = false
var _framework_step: AhcEnums.FrameworkStep = AhcEnums.FrameworkStep.SETUP_01_CHOOSE_INVESTIGATORS


static func with_tags(required: Array[StringName]) -> Condition:
	var c := Condition.new()
	c.tags_all = required.duplicate()
	return c


static func with_framework_and_tags(
	step: AhcEnums.FrameworkStep,
	required: Array[StringName]
) -> Condition:
	var c := Condition.new()
	c._use_framework_step = true
	c._framework_step = step
	c.tags_all = required.duplicate()
	return c


func matches(ctx: ApplicationContext) -> bool:
	if ctx == null:
		return false
	if _use_framework_step and ctx.framework_step != _framework_step:
		return false
	for tag in tags_all:
		if tag not in ctx.tags:
			return false
	return true
