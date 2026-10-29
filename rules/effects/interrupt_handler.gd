class_name InterruptHandler
extends RefCounted

## Cancel / Ignore 统一入口（07 §6.0）。身份 = 命名流程 / keyword / chaos；不再经 PendingResolutionStore。


static func apply_cancel(game_ctx: GameContext, target: InterruptTarget) -> Dictionary:
	if game_ctx == null or target == null:
		return {"ok": false, "error": "invalid_target"}
	match target.kind:
		InterruptTarget.Kind.SEQUENCE:
			if target.flow_id == &"":
				return {"ok": false, "error": "missing_cancel_bind"}
			if game_ctx.memory == null:
				return {"ok": false, "error": "missing_memory"}
			game_ctx.memory.cancel_sequence(target.flow_id, target.bind)
			if game_ctx.log != null:
				game_ctx.log.log(
					AhcEnums.LogCategory.ABILITY,
					"effect:sequence_cancelled",
					{"flow_id": target.flow_id, "bind": target.bind}
				)
			return {"ok": true, "flow_id": target.flow_id, "cancelled": true}
		InterruptTarget.Kind.IMPACT:
			## 旧 EffectOp pending 已退役；IMPACT 须改订 SEQUENCE。
			return {"ok": false, "error": "impact_pending_retired"}
		InterruptTarget.Kind.COST, InterruptTarget.Kind.KEYWORD:
			return {"ok": false, "error": "influence_ignore_not_wired", "kind": target.kind}
		InterruptTarget.Kind.CHAOS_TOKEN:
			return {"ok": false, "error": "chaos_cancel_not_wired"}
		_:
			return {"ok": false, "error": "cancel_kind_mismatch", "kind": target.kind}


static func apply_ignore(game_ctx: GameContext, target: InterruptTarget) -> Dictionary:
	if game_ctx == null or target == null:
		return {"ok": false, "error": "invalid_target"}
	match target.kind:
		InterruptTarget.Kind.SEQUENCE:
			if target.flow_id == &"":
				return {"ok": false, "error": "missing_ignore_bind"}
			if game_ctx.memory == null:
				return {"ok": false, "error": "missing_memory"}
			var res := game_ctx.memory.ignore_sequence(target.flow_id, target.bind)
			if res.get("ok", false) and game_ctx.log != null:
				game_ctx.log.log(
					AhcEnums.LogCategory.ABILITY,
					"effect:sequence_ignored",
					{"flow_id": target.flow_id, "bind": target.bind}
				)
			return res
		InterruptTarget.Kind.IMPACT:
			return {"ok": false, "error": "impact_pending_retired"}
		InterruptTarget.Kind.COST, InterruptTarget.Kind.KEYWORD:
			## ② 影响忽略：豁免 Buff 路径（待接 RestrictionKind）。
			return {"ok": false, "error": "influence_ignore_not_wired", "kind": target.kind}
		InterruptTarget.Kind.CHAOS_TOKEN:
			return {"ok": false, "error": "chaos_ignore_not_wired"}
		_:
			return {"ok": false, "error": "ignore_kind_mismatch", "kind": target.kind}
