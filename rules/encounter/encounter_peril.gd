class_name EncounterPeril
extends RefCounted

## seq.encounter.check_peril（E3）：险境 → Register RESTRICTION；与卡面 cannot 同路径（06 §7）。


static func apply_e3_check(
	game_ctx: GameContext,
	frame: EncounterResolutionFrame,
	has_peril_keyword: bool
) -> void:
	if frame == null:
		return
	if has_peril_keyword:
		frame.note_peril_keyword(true)
	if not frame.peril or frame.peril_restrictions_registered or game_ctx == null:
		return
	var template := RegistrationTemplate.peril_encounter_frame(frame.drawer_id, frame.id)
	var node := CompositionNode.register(template)
	node.provenance = AbilityUnitRef.from_framework(&"seq.encounter.check_peril")
	game_ctx.composition.execute(node)
	frame.peril_restrictions_registered = true


static func detach_frame(game_ctx: GameContext, frame: EncounterResolutionFrame) -> void:
	if game_ctx == null or frame == null:
		return
	game_ctx.registrations.unregister_by_encounter_frame(frame.id)


static func sync_test_context_from_frame(
	test_ctx: SkillTestContext,
	memory: RulesMemory
) -> void:
	if test_ctx == null or memory == null:
		return
	var frame := memory.peek_encounter_frame()
	if frame == null:
		return
	test_ctx.encounter_resolution_id = frame.id
	test_ctx.peril = frame.peril
