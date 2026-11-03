class_name GatePayload
extends RefCounted

## GATE：改 Intent 合法性（cannot / forbid）。

var kind: AhcEnums.GateKind = AhcEnums.GateKind.FORBID_DRAW
var drawer_id: StringName = &""
var drawn_card_id: StringName = &""
var encounter_frame_id: StringName = &""
var subject_id: StringName = &""
## FORBID_COMMIT_COUNT：禁止的投入张数（按控制者计）；例 [1, 2] = 03011。
var forbidden_commit_counts: Array[int] = []


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


## 03011 等：控制者不能正好投入 listed 张数（确认投入时检）。
static func forbid_commit_counts(
	controller_id: StringName,
	counts: Array[int],
	source_card_id: StringName = &""
) -> GatePayload:
	var p := GatePayload.new()
	p.kind = AhcEnums.GateKind.FORBID_COMMIT_COUNT
	p.drawer_id = controller_id
	p.drawn_card_id = source_card_id
	p.forbidden_commit_counts = counts.duplicate()
	return p


static func forbid_leave_hand(card_id: StringName, controller_id: StringName = &"") -> GatePayload:
	var p := GatePayload.new()
	p.kind = AhcEnums.GateKind.FORBID_LEAVE_HAND
	p.drawn_card_id = card_id
	p.drawer_id = controller_id
	return p
