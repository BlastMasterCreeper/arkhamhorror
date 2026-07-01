class_name Condition
extends RefCounted

var tags_all: Array[StringName] = []
var _use_framework_step: bool = false
var _framework_step: AhcEnums.FrameworkStep = AhcEnums.FrameworkStep.SETUP_01_CHOOSE_INVESTIGATORS


var stat_queries: Array = []


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


static func with_min_action_spends(count: int, tags: Array[StringName] = []) -> Condition:
	var c := with_tags(tags)
	c.stat_queries.append(StatQuery.turn_action_spend_count_ge(count))
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


func matches_with_snapshot(
	ctx: ApplicationContext,
	snapshot: Dictionary,
	eval_ctx: EvaluationContext
) -> bool:
	if not matches(ctx):
		return false
	if eval_ctx == null:
		return stat_queries.is_empty()
	for q in stat_queries:
		if q is not StatQuery:
			continue
		var pkey := (q as StatQuery).snapshot_key(eval_ctx.scope())
		if not (q as StatQuery).evaluate_value(snapshot.get(pkey, 0)):
			return false
	return true
