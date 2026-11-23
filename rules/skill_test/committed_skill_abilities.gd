class_name CommittedSkillAbilities
extends RefCounted

## 投入技能：commit 时装载除 ST.7 外的印刷能力。
## - commit_constant / constant+WHILE_COMMITTED
## - on_commit（When you commit → lasting Gain）
## - after_test_ends（延时 @ skill_test_ends；提前 uncommit 取消）
## - commit_only（投入限制；在 allow_commit 检查）
## ST.7 仍由 CommittedSkillSt7 负责。


static func allow_commit(
	test: SkillTestContext,
	game_ctx: GameContext,
	card_id: StringName
) -> Dictionary:
	if test == null or game_ctx == null or card_id == &"":
		return {"ok": true}
	var card := game_ctx.state.registry.get_card(card_id) if game_ctx.state != null else null
	if card == null:
		return {"ok": true}
	for raw in CardRegistry.compiled_abilities(card.id.definition_id):
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		var kinds := _commit_only_kinds(entry)
		if kinds.is_empty():
			continue
		var kind := test.test_kind
		if kind == &"":
			return {"ok": false, "error": "commit_only_kind_unknown"}
		var ok := false
		for k in kinds:
			if StringName(str(k)) == kind:
				ok = true
				break
		if not ok:
			return {"ok": false, "error": "commit_only_mismatch"}
	return {"ok": true}


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
	mounted += CommittedSkillSt7.mount_from_card(test, game_ctx, card_id)
	for raw in CardRegistry.compiled_abilities(card.id.definition_id):
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		if _mount_constant(entry, game_ctx, card_id):
			mounted += 1
		if _mount_on_commit(entry, test, game_ctx, card_id):
			mounted += 1
		if _mount_after_test_ends(entry, test, game_ctx, card_id):
			mounted += 1
	return mounted


static func unmount_early(
	test: SkillTestContext,
	game_ctx: GameContext,
	card_id: StringName
) -> void:
	## Silas 等提前收回：卸 ST.7 支 + after_test_ends 延时；WHILE_COMMITTED 由 leave limbo；
	## on_commit lasting（THIS_SKILL_TEST）保留至 ST.8 tick。
	CommittedSkillSt7.unmount_for_card(test, card_id)
	if game_ctx != null and game_ctx.registrations != null and test != null:
		game_ctx.registrations.unregister_after_test_ends_for_card(card_id, test.id)


static func _commit_only_kinds(entry: Dictionary) -> Array:
	var register_as := str(entry.get("register_as", "")).to_lower()
	var raw: Variant = entry.get("commit_only", null)
	if raw == null and register_as == "commit_restriction":
		raw = entry.get("kinds", [])
	if raw is Dictionary:
		var d: Dictionary = raw
		raw = d.get("kinds", d.get("during", []))
	if raw is Array:
		return raw as Array
	if raw is String and str(raw) != "":
		return [raw]
	return []


static func _mount_constant(
	entry: Dictionary,
	game_ctx: GameContext,
	card_id: StringName
) -> bool:
	var register_as := str(entry.get("register_as", "")).to_lower()
	var lifetime := str(entry.get("lifetime", "")).to_upper()
	var is_const := (
		register_as == "commit_constant"
		or (register_as == "constant" and lifetime == "WHILE_COMMITTED")
	)
	if not is_const:
		return false
	var mod_raw: Variant = entry.get("modifier", entry.get("params", {}))
	if not mod_raw is Dictionary:
		return false
	var mod: Dictionary = mod_raw
	var amount := int(mod.get("amount", 1))
	var stat_s := str(mod.get("stat", "skill_any"))
	var payload: ModifierPayload
	if stat_s == "skill_any" or stat_s == "any":
		payload = ModifierPayload.add_skill_any(amount)
	else:
		payload = ModifierPayload.add_skill(_stat_ref(stat_s), amount)
	return _run_register(
		game_ctx,
		RegistrationTemplate.while_committed_modifier(card_id, payload),
		card_id,
		card_id
	)


static func _mount_on_commit(
	entry: Dictionary,
	test: SkillTestContext,
	game_ctx: GameContext,
	card_id: StringName
) -> bool:
	var register_as := str(entry.get("register_as", "")).to_lower()
	if register_as != "on_commit" and register_as != "when_commit":
		return false
	var target := _resolve_on_commit_target(entry, test)
	if target == &"":
		return false
	var keywords: Array = []
	var kw_raw: Variant = entry.get("grant_keywords", entry.get("keywords", []))
	if kw_raw is Array:
		keywords = kw_raw as Array
	elif kw_raw is String and str(kw_raw) != "":
		keywords = [kw_raw]
	var n := 0
	for kw in keywords:
		var k := StringName(str(kw).to_lower())
		if k == &"":
			continue
		if _run_register(
			game_ctx,
			RegistrationTemplate.gained_keyword_this_skill_test(target, k),
			target,
			card_id
		):
			n += 1
	return n > 0


static func _mount_after_test_ends(
	entry: Dictionary,
	test: SkillTestContext,
	game_ctx: GameContext,
	card_id: StringName
) -> bool:
	var register_as := str(entry.get("register_as", "")).to_lower()
	if register_as != "after_test_ends" and register_as != "after_skill_test_ends":
		return false
	var body_raw: Variant = entry.get("body", entry.get("effect", {}))
	if not body_raw is Dictionary or (body_raw as Dictionary).is_empty():
		return false
	var body_d: Dictionary = body_raw
	var bind := AbilityBindContext.new()
	bind.card_id = card_id
	if game_ctx.state != null:
		var card := game_ctx.state.registry.get_card(card_id)
		if card != null:
			bind.controller_id = card.controller_id
			if bind.controller_id == &"":
				bind.controller_id = card.owner_id
	var node: CompositionNode = ArkhamDbAbilityCompiler.build_composition(
		str(body_d.get("template", "")),
		body_d,
		bind
	)
	if node == null:
		return false
	var ctrl := bind.controller_id
	if ctrl == &"":
		ctrl = test.performing_investigator
	return _run_register(
		game_ctx,
		RegistrationTemplate.after_skill_test_ends(ctrl, card_id, node, test.id),
		ctrl,
		card_id
	)


static func _resolve_on_commit_target(entry: Dictionary, test: SkillTestContext) -> StringName:
	var target := str(entry.get("target", "test_enemy")).to_lower()
	match target:
		"test_enemy", "enemy", "attacked_enemy":
			return test.target_enemy_id if test != null else &""
		"controller", "self", "committer":
			return test.performing_investigator if test != null else &""
		_:
			return StringName(target)


static func _run_register(
	game_ctx: GameContext,
	template: RegistrationTemplate,
	controller_id: StringName,
	card_id: StringName
) -> bool:
	if game_ctx == null or template == null:
		return false
	if game_ctx.sequence_catalog != null and game_ctx.sequence_catalog.has_flow(&"seq.effect.register"):
		var depth := 0
		if game_ctx.sequences != null and game_ctx.sequences.has_method("depth"):
			depth = int(game_ctx.sequences.depth())
		if depth > 0:
			return CompositionMount.register_effect(game_ctx, template, controller_id, card_id)
		var result: Dictionary = game_ctx.sequence_catalog.run(
			game_ctx,
			&"seq.effect.register",
			{
				"controller_id": controller_id,
				"card_id": card_id,
				"template": template,
			}
		)
		return bool(result.get("ok", false))
	## headless 无 Catalog 时回退（测）
	if game_ctx.registrations != null:
		return game_ctx.registrations.register(template) != &""
	return false


static func _stat_ref(stat_s: String) -> AhcEnums.StatRef:
	match stat_s.to_lower():
		"willpower", "will", "skill_willpower":
			return AhcEnums.StatRef.SKILL_WILLPOWER
		"intellect", "int", "skill_intellect":
			return AhcEnums.StatRef.SKILL_INTELLECT
		"combat", "fight", "skill_combat":
			return AhcEnums.StatRef.SKILL_COMBAT
		"agility", "agi", "skill_agility":
			return AhcEnums.StatRef.SKILL_AGILITY
		_:
			return AhcEnums.StatRef.SKILL_INTELLECT
