class_name EffectRestrictionGate
extends RefCounted

const NO_INTENT := -1


## EffectOp → RestrictionEvaluator.Intent（06 §16.4.3）。未映射 op 不查 Cannot。
static func block_reason(request: EffectRequest, store: RegistrationStore) -> StringName:
	if request == null or store == null:
		return &""
	var intent := intent_for_op(request.op)
	if intent == NO_INTENT:
		return &""
	return RestrictionEvaluator.block_reason(intent, request.controller_id, store)


static func intent_for_op(op: AhcEnums.EffectOp) -> int:
	match op:
		AhcEnums.EffectOp.DRAW_CARDS:
			return RestrictionEvaluator.Intent.DRAW
	return NO_INTENT
