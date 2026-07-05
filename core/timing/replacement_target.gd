class_name ReplacementTarget
extends RefCounted

## Instead / Would 卡面效果的统一编译目标（07-effect-resolution §7.0）。
enum Kind {
	PENDING,
	SEQUENCE,
	WOULD_TRIGGER,
}


var kind: Kind = Kind.PENDING
var pending_id: StringName = &""
var flow_id: StringName = &""
var triggering_condition_id: StringName = &""
var bind: Dictionary = {}


static func pending(pending_id: StringName) -> ReplacementTarget:
	var t := ReplacementTarget.new()
	t.kind = Kind.PENDING
	t.pending_id = pending_id
	return t


static func sequence(flow_id: StringName, bind: Dictionary = {}) -> ReplacementTarget:
	var t := ReplacementTarget.new()
	t.kind = Kind.SEQUENCE
	t.flow_id = flow_id
	t.bind = bind.duplicate()
	return t


static func would_trigger(triggering_condition_id: StringName, bind: Dictionary = {}) -> ReplacementTarget:
	var t := ReplacementTarget.new()
	t.kind = Kind.WOULD_TRIGGER
	t.triggering_condition_id = triggering_condition_id
	t.bind = bind.duplicate()
	return t


static func from_params(params: Dictionary) -> ReplacementTarget:
	var t := ReplacementTarget.new()
	var kind_name: String = str(params.get("kind", "pending"))
	match kind_name:
		"pending", "PENDING":
			t.kind = Kind.PENDING
		"sequence", "SEQUENCE":
			t.kind = Kind.SEQUENCE
		"would", "would_trigger", "WOULD_TRIGGER":
			t.kind = Kind.WOULD_TRIGGER
		_:
			t.kind = Kind.PENDING
	t.pending_id = params.get("pending_id", &"") as StringName
	t.flow_id = params.get("flow_id", &"") as StringName
	t.triggering_condition_id = params.get("triggering_condition_id", &"") as StringName
	t.bind = (params.get("bind", {}) as Dictionary).duplicate()
	return t
