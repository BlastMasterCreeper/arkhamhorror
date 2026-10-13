class_name ScenarioResolutionFlow
extends RefCounted

## 场景结算 `(→R#)` · 02 §8。


static func trigger(game_ctx: GameContext, resolution: int, source: StringName = &"unknown") -> Dictionary:
	if game_ctx == null or game_ctx.state == null or resolution <= 0:
		return {"ok": false, "triggered": false}
	game_ctx.state.scenario_resolution = resolution
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"scenario:resolution",
			{"resolution": resolution, "source": source}
		)
	if game_ctx.framework != null:
		game_ctx.framework.trigger_scenario_resolution(resolution)
	return {"ok": true, "triggered": true, "resolution": resolution}
