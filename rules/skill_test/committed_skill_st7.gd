class_name CommittedSkillSt7
extends RefCounted

## 投入技能：从印刷 `compiled_abilities` 装载 ST.7 支并挂入本次检定。
## 仅 `register_as == commit`（或显式 skill-commit）且含 `st7`；跳过 nest `skill_test` 条目
##（那些 ST.7 属于被 nest 的检定，由 nest 路径挂载）。


static func mount_from_card(
	test: SkillTestContext,
	game_ctx: GameContext,
	card_id: StringName
) -> int:
	if test == null or game_ctx == null or card_id == &"":
		return 0
	var card := game_ctx.state.registry.get_card(card_id) if game_ctx.state != null else null
	if card == null:
		return 0
	var mounted := 0
	for raw in CardRegistry.compiled_abilities(card.id.definition_id):
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		if not _is_commit_st7_entry(entry):
			continue
		var plan := _plan_from_entry(entry, game_ctx, card_id)
		if plan == null or plan.is_empty():
			continue
		var ability_id := StringName(
			str(entry.get("ability_id", "commit:%s" % String(card_id)))
		)
		plan.source_id = ability_id
		plan.requires_committed_card = card_id
		SkillTestSt7Composition.register_plan(
			test, game_ctx, plan, ability_id, card_id
		)
		mounted += 1
	return mounted


static func unmount_for_card(test: SkillTestContext, card_id: StringName) -> void:
	if test == null or card_id == &"":
		return
	var kept: Array = []
	for raw in test.st7_units:
		var unit: SkillTestSt7Unit = raw as SkillTestSt7Unit
		if unit == null:
			continue
		if unit.requires_committed_card == card_id:
			continue
		kept.append(unit)
	test.st7_units = kept


static func _is_commit_st7_entry(entry: Dictionary) -> bool:
	var st7: Variant = entry.get("st7", {})
	if not st7 is Dictionary or (st7 as Dictionary).is_empty():
		## 兼容旧键
		var legacy: Variant = entry.get("st7_fail_by", {})
		if not legacy is Dictionary or (legacy as Dictionary).is_empty():
			return false
	var template := str(entry.get("template", ""))
	if template == "skill_test" or template == "nest_skill_test":
		## ST.7 属于该 nest 检定，不在宿主 commit 时装载。
		return false
	var register_as := str(entry.get("register_as", "commit")).to_lower()
	return register_as == "commit" or register_as == "skill_commit"


static func _plan_from_entry(
	entry: Dictionary,
	game_ctx: GameContext,
	card_id: StringName
) -> SkillTestSt7Plan:
	var bind := AbilityBindContext.new()
	bind.card_id = card_id
	if game_ctx.state != null:
		var card := game_ctx.state.registry.get_card(card_id)
		if card != null:
			bind.controller_id = card.controller_id
			if bind.controller_id == &"":
				bind.controller_id = card.owner_id
	var st7: Variant = entry.get("st7", {})
	if st7 is Dictionary and not (st7 as Dictionary).is_empty():
		return SkillTestSt7Plan.from_compile_dict(
			st7 as Dictionary,
			bind,
			Callable(ArkhamDbAbilityCompiler, "build_composition")
		)
	var legacy: Variant = entry.get("st7_fail_by", {})
	if legacy is Dictionary and not (legacy as Dictionary).is_empty():
		var plan := SkillTestSt7Plan.new()
		plan.on_fail_by_each = ArkhamDbAbilityCompiler.build_composition(
			str((legacy as Dictionary).get("template", "")),
			legacy as Dictionary,
			bind
		)
		return plan
	return null
