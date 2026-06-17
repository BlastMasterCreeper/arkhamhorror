class_name ApplicationContext
extends RefCounted

var timing: StringName = &""
var framework_step: AhcEnums.FrameworkStep = AhcEnums.FrameworkStep.SETUP_01_CHOOSE_INVESTIGATORS
var controller_id: StringName = &""
var tags: Array[StringName] = []
var trigger: TriggeringCondition = null
var referents: Dictionary = {}
var payload: Dictionary = {}


static func from_sequence(
	game_ctx: GameContext,
	trigger: TriggeringCondition,
	phase: AhcEnums.SequencePhase
) -> ApplicationContext:
	var ctx := ApplicationContext.new()
	ctx.trigger = trigger
	ctx.controller_id = trigger.controller_id
	ctx.tags = trigger.tags.duplicate()
	ctx.payload = trigger.payload.duplicate()
	if game_ctx.framework:
		ctx.framework_step = game_ctx.framework.current_step
	if game_ctx.memory:
		ctx.referents = game_ctx.memory.get_referents(trigger.controller_id)
	match phase:
		AhcEnums.SequencePhase.WHEN:
			ctx.timing = StringName("when_%s" % trigger.kind)
		AhcEnums.SequencePhase.AFTER:
			ctx.timing = trigger.after_timing if trigger.after_timing != &"" else StringName("after_%s" % trigger.kind)
		_:
			ctx.timing = StringName("resolve_%s" % trigger.kind)
	return ctx
