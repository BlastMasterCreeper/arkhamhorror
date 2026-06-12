class_name SkillTestHelper
extends RefCounted

var _ctx: GameContext


func _init(ctx: GameContext) -> void:
	_ctx = ctx


func make_test(
	performing: StringName,
	skill: AhcEnums.SkillType,
	difficulty: int,
	peril: bool = false
) -> SkillTestContext:
	var test := SkillTestContext.new()
	test.performing_investigator = performing
	test.skill = skill
	test.difficulty = difficulty
	test.peril = peril
	return test


func run(test: SkillTestContext, commits: Array[CommittedCard] = []) -> SkillTestResult:
	return _ctx.skill_tests.run_full_test(test, _ctx, commits)


func begin(test: SkillTestContext) -> SkillTestContext:
	return _ctx.skill_tests.begin_test(test, _ctx)
