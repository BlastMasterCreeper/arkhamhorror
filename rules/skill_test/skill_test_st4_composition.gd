class_name SkillTestSt4Composition
extends RefCounted

## ST.4 Apply symbol effects · 卡面 on_symbols 内联 Composition（与场景袋修正并列）。


static func register_plan(
	test: SkillTestContext,
	game_ctx: GameContext,
	plan: SkillTestSt4Plan
) -> void:
	if test == null or plan == null or game_ctx == null or plan.is_empty():
		return
	for raw_key in plan.on_symbols.keys():
		var body: CompositionNode = plan.on_symbols[raw_key] as CompositionNode
		if body == null:
			continue
		var kind := _kind_from_name(StringName(str(raw_key)))
		if kind < 0:
			continue
		var captured := body
		test.st4_on_symbol[kind] = func(_ctx: SkillTestContext) -> void:
			game_ctx.composition.execute(captured)


static func _kind_from_name(name: StringName) -> int:
	match str(name).to_lower():
		"skull":
			return AhcEnums.ChaosTokenKind.SKULL
		"cultist":
			return AhcEnums.ChaosTokenKind.CULTIST
		"tablet":
			return AhcEnums.ChaosTokenKind.TABLET
		"elder_thing":
			return AhcEnums.ChaosTokenKind.ELDER_THING
		"elder_sign":
			return AhcEnums.ChaosTokenKind.ELDER_SIGN
		"bless":
			return AhcEnums.ChaosTokenKind.BLESS
		"curse":
			return AhcEnums.ChaosTokenKind.CURSE
		"frost":
			return AhcEnums.ChaosTokenKind.FROST
		_:
			return -1
