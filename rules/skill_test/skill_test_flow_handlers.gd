class_name SkillTestFlowHandlers
extends RefCounted

## seq.skill_test.* resolve · ST.1–ST.8 全窗口（04-skill-test-engine · 15 §17.5）。


static func run_revelation_test(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.skill_tests == null:
		return {"ok": false, "error": &"no_skill_test_engine"}
	var inv_id: StringName = params.get("inv_id", params.get("controller_id", &""))
	var skill: AhcEnums.SkillType = int(params.get("skill", AhcEnums.SkillType.WILLPOWER))
	var difficulty: int = int(params.get("difficulty", 0))
	var card_id: StringName = params.get("card_id", &"")
	var st7_body: Variant = params.get("st7_fail_by_composition")
	var st7_plan: Variant = params.get("st7_plan")
	var test := SkillTestContext.new()
	test.performing_investigator = inv_id
	test.skill = skill
	test.difficulty = maxi(difficulty, 0)
	if st7_plan is SkillTestSt7Plan:
		SkillTestSt7Composition.register_plan(test, game_ctx, st7_plan as SkillTestSt7Plan)
	elif st7_body is CompositionNode:
		SkillTestSt7Composition.register_fail_by_loop(
			test, game_ctx, st7_body as CompositionNode
		)
	if game_ctx.memory != null:
		EncounterPeril.sync_test_context_from_frame(test, game_ctx)
	var result := game_ctx.skill_tests.run_full_test(test, game_ctx)
	var fail_by := result.fail_by if result != null else 0
	var success := result.success if result != null else false
	var test_id: StringName = result.context.id if result != null and result.context != null else &""
	if game_ctx.memory != null and inv_id != &"":
		game_ctx.memory.set_referent(inv_id, &"last_skill_test_fail_by", fail_by)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.CARD,
			"skill_test:revelation_complete",
			{
				"inv": inv_id,
				"skill": skill,
				"difficulty": difficulty,
				"card": card_id,
				"success": success,
				"fail_by": fail_by,
				"test_id": test_id,
			}
		)
	return {
		"ok": true,
		"success": success,
		"fail_by": fail_by,
		"test_id": test_id,
	}


static func skill_type_for_flow(flow_id: StringName) -> AhcEnums.SkillType:
	match flow_id:
		&"seq.skill_test.intellect":
			return AhcEnums.SkillType.INTELLECT
		&"seq.skill_test.combat":
			return AhcEnums.SkillType.COMBAT
		&"seq.skill_test.agility":
			return AhcEnums.SkillType.AGILITY
		_:
			return AhcEnums.SkillType.WILLPOWER


static func flow_id_for_skill(skill: AhcEnums.SkillType) -> StringName:
	match skill:
		AhcEnums.SkillType.INTELLECT:
			return &"seq.skill_test.intellect"
		AhcEnums.SkillType.COMBAT:
			return &"seq.skill_test.combat"
		AhcEnums.SkillType.AGILITY:
			return &"seq.skill_test.agility"
		_:
			return &"seq.skill_test.willpower"
