class_name InterruptTarget
extends RefCounted

## Cancel / Ignore 卡面效果的统一编译目标（07-effect-resolution §6.0）。
enum Kind {
	SEQUENCE,
	IMPACT,
	COST,
	KEYWORD,
	CHAOS_TOKEN,
}


var kind: Kind = Kind.SEQUENCE
var flow_id: StringName = &""
var pending_id: StringName = &""
var keyword: StringName = &""
var impact_op: AhcEnums.EffectOp = AhcEnums.EffectOp.DRAW_CARDS
var bind: Dictionary = {}
var scope: Dictionary = {}


static func sequence(flow_id: StringName, bind: Dictionary = {}) -> InterruptTarget:
	var t := InterruptTarget.new()
	t.kind = Kind.SEQUENCE
	t.flow_id = flow_id
	t.bind = bind.duplicate()
	return t


static func pending_impact(pending_id: StringName) -> InterruptTarget:
	var t := InterruptTarget.new()
	t.kind = Kind.IMPACT
	t.pending_id = pending_id
	return t


static func for_keyword(kw: StringName, scope: Dictionary = {}) -> InterruptTarget:
	var t := InterruptTarget.new()
	t.kind = Kind.KEYWORD
	t.keyword = kw
	t.scope = scope.duplicate()
	return t


static func cost(bind: Dictionary = {}) -> InterruptTarget:
	var t := InterruptTarget.new()
	t.kind = Kind.COST
	t.bind = bind.duplicate()
	return t


static func chaos_token(scope: Dictionary = {}) -> InterruptTarget:
	var t := InterruptTarget.new()
	t.kind = Kind.CHAOS_TOKEN
	t.scope = scope.duplicate()
	return t


static func from_params(params: Dictionary) -> InterruptTarget:
	var t := InterruptTarget.new()
	var kind_name: String = str(params.get("kind", "sequence"))
	match kind_name:
		"sequence", "SEQUENCE":
			t.kind = Kind.SEQUENCE
		"impact", "IMPACT", "pending":
			t.kind = Kind.IMPACT
		"cost", "COST":
			t.kind = Kind.COST
		"keyword", "KEYWORD":
			t.kind = Kind.KEYWORD
		"chaos_token", "CHAOS_TOKEN":
			t.kind = Kind.CHAOS_TOKEN
		_:
			t.kind = Kind.SEQUENCE
	t.flow_id = params.get("flow_id", &"") as StringName
	t.pending_id = params.get("pending_id", &"") as StringName
	t.keyword = params.get("keyword", &"") as StringName
	if params.has("impact_op"):
		t.impact_op = int(params.get("impact_op", AhcEnums.EffectOp.DRAW_CARDS))
	t.bind = (params.get("bind", {}) as Dictionary).duplicate()
	t.scope = (params.get("scope", {}) as Dictionary).duplicate()
	return t
