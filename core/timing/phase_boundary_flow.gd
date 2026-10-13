class_name PhaseBoundaryFlow
extends RefCounted

## 阶段边界钩子 · `seq.framework.*_phase_{begins,ends}`。
## 仅提供 WHEN/AFTER 订点；框架步进本身仍在 FrameworkFlowEngine。

const FLOW_MYTHOS_BEGINS := &"seq.framework.mythos_phase_begins"
const FLOW_MYTHOS_ENDS := &"seq.framework.mythos_phase_ends"
const FLOW_INVESTIGATION_BEGINS := &"seq.framework.investigation_phase_begins"
const FLOW_INVESTIGATION_ENDS := &"seq.framework.investigation_phase_ends"
const FLOW_ENEMY_BEGINS := &"seq.framework.enemy_phase_begins"
const FLOW_ENEMY_ENDS := &"seq.framework.enemy_phase_ends"
const FLOW_UPKEEP_BEGINS := &"seq.framework.upkeep_phase_begins"
const FLOW_UPKEEP_ENDS := &"seq.framework.upkeep_phase_ends"

const ALL_FLOWS: Array[StringName] = [
	FLOW_MYTHOS_BEGINS,
	FLOW_MYTHOS_ENDS,
	FLOW_INVESTIGATION_BEGINS,
	FLOW_INVESTIGATION_ENDS,
	FLOW_ENEMY_BEGINS,
	FLOW_ENEMY_ENDS,
	FLOW_UPKEEP_BEGINS,
	FLOW_UPKEEP_ENDS,
]


static func flow_for_step(step: AhcEnums.FrameworkStep) -> StringName:
	match step:
		AhcEnums.FrameworkStep.MYTHOS_1_1_PHASE_BEGINS:
			return FLOW_MYTHOS_BEGINS
		AhcEnums.FrameworkStep.MYTHOS_1_5_PHASE_ENDS:
			return FLOW_MYTHOS_ENDS
		AhcEnums.FrameworkStep.INV_2_1_PHASE_BEGINS:
			return FLOW_INVESTIGATION_BEGINS
		AhcEnums.FrameworkStep.INV_2_3_PHASE_ENDS:
			return FLOW_INVESTIGATION_ENDS
		AhcEnums.FrameworkStep.ENEMY_3_1_PHASE_BEGINS:
			return FLOW_ENEMY_BEGINS
		AhcEnums.FrameworkStep.ENEMY_3_4_PHASE_ENDS:
			return FLOW_ENEMY_ENDS
		AhcEnums.FrameworkStep.UPKEEP_4_1_PHASE_BEGINS:
			return FLOW_UPKEEP_BEGINS
		AhcEnums.FrameworkStep.UPKEEP_4_6_PHASE_ENDS:
			return FLOW_UPKEEP_ENDS
	return &""


static func emit_for_step(game_ctx: GameContext, step: AhcEnums.FrameworkStep) -> Dictionary:
	var flow_id := flow_for_step(step)
	if flow_id == &"":
		return {"ok": false, "skipped": true}
	return emit(game_ctx, flow_id)


static func emit(game_ctx: GameContext, flow_id: StringName) -> Dictionary:
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(flow_id)
	):
		return game_ctx.sequence_catalog.run(game_ctx, flow_id, {})
	return {"ok": true, "flow_id": flow_id}


static func resolve(_game_ctx: GameContext, params: Dictionary) -> Dictionary:
	return {"ok": true, "flow_id": params.get("flow_id", &"")}
