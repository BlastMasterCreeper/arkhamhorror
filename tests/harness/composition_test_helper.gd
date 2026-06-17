class_name CompositionTestHelper
extends RefCounted

var _ctx: GameContext
var _dry_runner: CompositionDryRunner = CompositionDryRunner.new()


func _init(ctx: GameContext) -> void:
	_ctx = ctx


func dry_run(node: CompositionNode) -> bool:
	var sim := GameSimulator.from_context(_ctx)
	return _dry_runner.simulate(node, sim).has_any_created


func execute(node: CompositionNode) -> void:
	_ctx.composition.execute(node)


func modifier_willpower(base: int, controller_id: StringName) -> int:
	var q := ModifierQuery.new()
	q.controller_id = controller_id
	q.stat = AhcEnums.StatRef.SKILL_WILLPOWER
	return _ctx.modifiers.compute(base, q)


static func lasting_willpower_turn(inv_id: StringName, amount: int) -> CompositionNode:
	var payload := ModifierPayload.add_skill(AhcEnums.StatRef.SKILL_WILLPOWER, amount)
	var template := RegistrationTemplate.lasting_modifier(
		inv_id, AhcEnums.DurationAnchorKind.THIS_TURN, payload
	)
	return CompositionNode.register(template)


static func forbid_draw_turn(inv_id: StringName) -> CompositionNode:
	var template := RegistrationTemplate.lasting_restriction(
		inv_id, AhcEnums.DurationAnchorKind.THIS_TURN, RestrictionPayload.forbid_draw()
	)
	return CompositionNode.register(template)


static func delayed_draw_listener(inv_id: StringName, timing: StringName) -> CompositionNode:
	var listener := ListenerPayload.at_timing(timing, CompositionNode.draw(inv_id))
	var template := RegistrationTemplate.delayed_listener(inv_id, listener)
	return CompositionNode.register(template)


static func after_gain_draw_listener(inv_id: StringName) -> CompositionNode:
	return delayed_draw_listener(inv_id, &"after_gain_resource")


static func upkeep_framework_resource_bonus(inv_id: StringName, amount: int) -> CompositionNode:
	var cond := Condition.with_framework_and_tags(
		AhcEnums.FrameworkStep.UPKEEP_4_4_DRAW_AND_RESOURCE,
		[&"gain_resource", &"framework"]
	)
	var payload := ModifierPayload.add_resource_gain(amount, cond)
	var template := RegistrationTemplate.lasting_modifier(
		inv_id, AhcEnums.DurationAnchorKind.THIS_TURN, payload
	)
	return CompositionNode.register(template)
