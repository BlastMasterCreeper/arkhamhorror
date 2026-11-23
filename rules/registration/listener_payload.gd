class_name ListenerPayload
extends RefCounted

var timing: StringName = &""
var composition: CompositionNode = null
## 非空 = 仅该次检定的 ST.7 可开火；空 = 任意检定 ST.7（下一次匹配槽即开火）。
var scope_test_id: StringName = &""


static func at_timing(
	timing_name: StringName,
	node: CompositionNode,
	scope_test_id: StringName = &""
) -> ListenerPayload:
	var p := ListenerPayload.new()
	p.timing = timing_name
	p.composition = node
	p.scope_test_id = scope_test_id
	return p


## 延时：到某次检定 ST.7 按成败槽结算（与 register_plan 同批 ORDER）。
static func at_st7_slot(
	slot: StringName,
	node: CompositionNode,
	scope_test_id: StringName = &""
) -> ListenerPayload:
	return at_timing(SkillTestSt7Composition.timing_for_slot(slot), node, scope_test_id)
