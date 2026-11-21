class_name SkillTestSt7Unit
extends RefCounted

## ST.7 同时结果单元：COLLECT 后经 ORDER_SIMULTANEOUS 排序，再内联执行。

var unit_id: StringName = &""
var source_id: StringName = &""
## on_success | on_fail | on_fail_by_each | symbol_fail_by
var slot: StringName = &""
var run: Callable = Callable()
## 非空则执行前须该卡仍 LIMBO/`COMMITTED`（投入技能支）。
var requires_committed_card: StringName = &""


static func create(
	unit_id: StringName,
	source_id: StringName,
	slot: StringName,
	run: Callable,
	requires_committed_card: StringName = &""
) -> SkillTestSt7Unit:
	var u := SkillTestSt7Unit.new()
	u.unit_id = unit_id
	u.source_id = source_id
	u.slot = slot
	u.run = run
	u.requires_committed_card = requires_committed_card
	return u


func applies(ctx: SkillTestContext, state: GameStateStore = null) -> bool:
	if ctx == null or not run.is_valid():
		return false
	if requires_committed_card != &"":
		if state == null:
			return false
		var card := state.registry.get_card(requires_committed_card)
		if card == null or not card.is_limbo_committed():
			return false
	match slot:
		&"on_success":
			return ctx.success
		&"on_fail":
			return not ctx.success
		&"on_fail_by_each":
			return not ctx.success and ctx.fail_by > 0
		&"symbol_fail_by":
			return not ctx.success
		_:
			return true
