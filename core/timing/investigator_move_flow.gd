class_name InvestigatorMoveFlow
extends RefCounted

## 兼容薄封装 → `MoveFlow`（`seq.effect.move` 统一狭义移动核）。


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var p := params.duplicate()
	if not p.has("subject"):
		p["subject"] = MoveFlow.SUBJECT_INVESTIGATOR
	return MoveFlow.run(game_ctx, p)
