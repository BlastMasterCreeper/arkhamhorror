class_name InitiationLegalityChecker
extends RefCounted

var _dry_runner: CompositionDryRunner = CompositionDryRunner.new()


func dry_run(intent: InitiationIntent, ctx: GameContext) -> DryRunResult:
	var result := DryRunResult.new()
	if intent == null or intent.composition == null:
		return result
	var sim := GameSimulator.from_context(ctx)
	return _dry_runner.simulate(intent.composition, sim)
