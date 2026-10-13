class_name SkillTestSt7Plan
extends RefCounted

## 检定 ST.7 待执行内联 Composition（04 §3.7 · FAQ delayed effects @ ST.7）。

var on_success: CompositionNode = null
var on_fail: CompositionNode = null
var on_fail_by_each: CompositionNode = null


static func from_compile_dict(
	entries: Dictionary,
	bind: AbilityBindContext,
	build_fn: Callable
) -> SkillTestSt7Plan:
	var plan := SkillTestSt7Plan.new()
	for key in ["on_success", "on_fail", "on_fail_by_each"]:
		var entry: Variant = entries.get(key)
		if entry is Dictionary and not (entry as Dictionary).is_empty():
			var node: CompositionNode = build_fn.call(
				str((entry as Dictionary).get("template", "")),
				entry as Dictionary,
				bind
			)
			if node != null:
				plan.assign_branch(key, node)
	# 兼容旧键 st7_fail_by
	if plan.on_fail_by_each == null:
		var legacy: Variant = entries.get("fail_by_each")
		if legacy is Dictionary and not (legacy as Dictionary).is_empty():
			plan.on_fail_by_each = build_fn.call(
				str((legacy as Dictionary).get("template", "")),
				legacy as Dictionary,
				bind
			)
	return plan


func assign_branch(key: String, node: CompositionNode) -> void:
	match key:
		"on_success":
			on_success = node
		"on_fail":
			on_fail = node
		"on_fail_by_each":
			on_fail_by_each = node


func is_empty() -> bool:
	return on_success == null and on_fail == null and on_fail_by_each == null


func has_any_for_outcome(success: bool, fail_by: int) -> bool:
	if success:
		return on_success != null
	if on_fail != null:
		return true
	return on_fail_by_each != null and fail_by > 0
