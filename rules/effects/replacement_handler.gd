class_name ReplacementHandler
extends RefCounted

## Instead 统一入口（07 §7.0）。替换载荷为 Dictionary（通常含 base_amount / amount），
## 挂在 RulesMemory 的命名流程身份上；不再使用 EffectRequest / PendingResolutionStore。


static func params_from_replacement(params: Dictionary) -> Dictionary:
	if params.is_empty():
		return {}
	## 兼容旧测例 op 枚举 → 效果手续参数。
	if params.has("base_amount") or params.has("amount") or params.has("flow_id"):
		return params.duplicate(true)
	var op: int = int(params.get("op", AhcEnums.EffectOp.CUSTOM))
	var out := params.duplicate(true)
	match op:
		AhcEnums.EffectOp.GAIN_RESOURCE:
			out["base_amount"] = int(params.get("amount", params.get("base_amount", 1)))
			out["flow_id"] = &"seq.effect.gain_resource"
		AhcEnums.EffectOp.DRAW_CARDS:
			out["amount"] = int(params.get("amount", 1))
			out["flow_id"] = &"seq.draw.investigator"
	return out


static func apply_instead(
	game_ctx: GameContext,
	target: ReplacementTarget,
	replacement_params: Dictionary,
	source_ability_id: StringName = &""
) -> Dictionary:
	if game_ctx == null or target == null:
		return {"ok": false, "error": "invalid_target"}
	if game_ctx.memory == null:
		return {"ok": false, "error": "missing_memory"}
	var params := params_from_replacement(replacement_params)
	if params.is_empty():
		return {"ok": false, "error": "invalid_replacement"}
	match target.kind:
		ReplacementTarget.Kind.SEQUENCE:
			if target.flow_id == &"":
				return {"ok": false, "error": "missing_replace_bind"}
			var res := game_ctx.memory.register_sequence_replacement(
				target.flow_id,
				target.bind,
				params,
				source_ability_id
			)
			if res.get("ok", false) and game_ctx.log != null:
				game_ctx.log.log(
					AhcEnums.LogCategory.ABILITY,
					"effect:sequence_replacement",
					{
						"flow_id": target.flow_id,
						"bind": target.bind,
						"initiation_seq": res.get("initiation_seq", 0),
						"source": source_ability_id,
					}
				)
			return res
		ReplacementTarget.Kind.PENDING:
			return {"ok": false, "error": "pending_replace_retired"}
		ReplacementTarget.Kind.WOULD_TRIGGER:
			return {"ok": false, "error": "would_replace_not_wired", "trigger": target.triggering_condition_id}
		_:
			return {"ok": false, "error": "replace_kind_mismatch", "kind": target.kind}
