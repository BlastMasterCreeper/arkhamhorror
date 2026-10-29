class_name GatePayload
extends RefCounted

## GATE Buff：改 Intent 合法性（cannot / forbid）。

var kind: AhcEnums.GateKind = AhcEnums.GateKind.FORBID_DRAW
var drawer_id: StringName = &""
var drawn_card_id: StringName = &""
var encounter_frame_id: StringName = &""
var subject_id: StringName = &""


static func forbid_draw() -> GatePayload:
	var p := GatePayload.new()
	p.kind = AhcEnums.GateKind.FORBID_DRAW
	return p


static func forbid_play_peril(drawer_id: StringName, drawn_card_id: StringName) -> GatePayload:
	var p := GatePayload.new()
	p.kind = AhcEnums.GateKind.FORBID_PLAY
	p.drawer_id = drawer_id
	p.drawn_card_id = drawn_card_id
	return p


static func forbid_trigger_peril(drawer_id: StringName, drawn_card_id: StringName) -> GatePayload:
	var p := GatePayload.new()
	p.kind = AhcEnums.GateKind.FORBID_TRIGGER
	p.drawer_id = drawer_id
	p.drawn_card_id = drawn_card_id
	return p


static func forbid_commit_peril(drawer_id: StringName, drawn_card_id: StringName) -> GatePayload:
	var p := GatePayload.new()
	p.kind = AhcEnums.GateKind.FORBID_COMMIT_TO_TEST
	p.drawer_id = drawer_id
	p.drawn_card_id = drawn_card_id
	return p


static func forbid_leave_hand(card_id: StringName, controller_id: StringName = &"") -> GatePayload:
	var p := GatePayload.new()
	p.kind = AhcEnums.GateKind.FORBID_LEAVE_HAND
	p.drawn_card_id = card_id
	p.drawer_id = controller_id
	return p
