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
		var peril_frame := game_ctx.memory.peek_encounter_frame()
		if peril_frame != null and game_ctx.registrations != null \
				and game_ctx.registrations.has_peril_for_drawn_card(peril_frame.current_card_id):
			if not ctx.tags.has(&"peril_active"):
				ctx.tags.append(&"peril_active")
			ctx.referents["encounter_drawer_id"] = peril_frame.drawer_id
			ctx.referents["drawn_card_id"] = peril_frame.current_card_id
	match phase:
		AhcEnums.SequencePhase.WHEN:
			ctx.timing = StringName("when_%s" % trigger.kind)
		AhcEnums.SequencePhase.AFTER:
			ctx.timing = trigger.after_timing if trigger.after_timing != &"" else StringName("after_%s" % trigger.kind)
		_:
			ctx.timing = StringName("resolve_%s" % trigger.kind)
	return ctx
