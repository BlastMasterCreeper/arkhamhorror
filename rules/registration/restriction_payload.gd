class_name RestrictionPayload
extends RefCounted

var kind: AhcEnums.RestrictionKind = AhcEnums.RestrictionKind.FORBID_DRAW
var drawer_id: StringName = &""
var encounter_frame_id: StringName = &""


static func forbid_draw() -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.FORBID_DRAW
	return p


static func forbid_play_peril(drawer_id: StringName, frame_id: StringName) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.FORBID_PLAY
	p.drawer_id = drawer_id
	p.encounter_frame_id = frame_id
	return p


static func forbid_trigger_peril(drawer_id: StringName, frame_id: StringName) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.FORBID_TRIGGER
	p.drawer_id = drawer_id
	p.encounter_frame_id = frame_id
	return p


static func forbid_commit_peril(drawer_id: StringName, frame_id: StringName) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.FORBID_COMMIT_TO_TEST
	p.drawer_id = drawer_id
	p.encounter_frame_id = frame_id
	return p
