class_name PhaseBoundaryFlow
extends RefCounted

## 阶段边界钩子 · 单条 `seq.framework.phase_boundary`。
## params：`phase` = mythos|investigation|enemy|upkeep；`boundary` = begins|ends。
## TC.kind 仍为 `{phase}_phase_{boundary}`，供 Forced match_kind 过滤（如 Fire!）。

const FLOW := &"seq.framework.phase_boundary"
## 旧 id 别名（调查结束）；仍转发到本条 + 固定 params。
const FLOW_INVESTIGATION_ENDS_ALIAS := &"seq.framework.investigation_phase_ends"

const PHASE_MYTHOS := &"mythos"
const PHASE_INVESTIGATION := &"investigation"
const PHASE_ENEMY := &"enemy"
const PHASE_UPKEEP := &"upkeep"
const BOUNDARY_BEGINS := &"begins"
const BOUNDARY_ENDS := &"ends"


static func params_for_step(step: AhcEnums.FrameworkStep) -> Dictionary:
	match step:
		AhcEnums.FrameworkStep.MYTHOS_1_1_PHASE_BEGINS:
			return {"phase": PHASE_MYTHOS, "boundary": BOUNDARY_BEGINS}
		AhcEnums.FrameworkStep.MYTHOS_1_5_PHASE_ENDS:
			return {"phase": PHASE_MYTHOS, "boundary": BOUNDARY_ENDS}
		AhcEnums.FrameworkStep.INV_2_1_PHASE_BEGINS:
			return {"phase": PHASE_INVESTIGATION, "boundary": BOUNDARY_BEGINS}
		AhcEnums.FrameworkStep.INV_2_3_PHASE_ENDS:
			return {"phase": PHASE_INVESTIGATION, "boundary": BOUNDARY_ENDS}
		AhcEnums.FrameworkStep.ENEMY_3_1_PHASE_BEGINS:
			return {"phase": PHASE_ENEMY, "boundary": BOUNDARY_BEGINS}
		AhcEnums.FrameworkStep.ENEMY_3_4_PHASE_ENDS:
			return {"phase": PHASE_ENEMY, "boundary": BOUNDARY_ENDS}
		AhcEnums.FrameworkStep.UPKEEP_4_1_PHASE_BEGINS:
			return {"phase": PHASE_UPKEEP, "boundary": BOUNDARY_BEGINS}
		AhcEnums.FrameworkStep.UPKEEP_4_6_PHASE_ENDS:
			return {"phase": PHASE_UPKEEP, "boundary": BOUNDARY_ENDS}
	return {}


static func emit_for_step(game_ctx: GameContext, step: AhcEnums.FrameworkStep) -> Dictionary:
	var params := params_for_step(step)
	if params.is_empty():
		return {"ok": false, "skipped": true}
	return emit(game_ctx, params)


static func emit(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(FLOW)
	):
		return game_ctx.sequence_catalog.run(game_ctx, FLOW, params)
	return resolve(game_ctx, params)


static func resolve(_game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var phase: StringName = params.get("phase", &"") as StringName
	var boundary: StringName = params.get("boundary", &"") as StringName
	return {
		"ok": phase != &"" and boundary != &"",
		"phase": phase,
		"boundary": boundary,
		"kind": TriggeringCondition.phase_boundary_kind(phase, boundary),
	}
