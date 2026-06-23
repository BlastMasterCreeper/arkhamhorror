class_name Registration
extends RefCounted

var id: StringName = &""
var controller_id: StringName = &""
var lifetime_kind: AhcEnums.LifetimeKind = AhcEnums.LifetimeKind.DURATION
var duration: AhcEnums.DurationAnchorKind = AhcEnums.DurationAnchorKind.THIS_TURN
var encounter_frame_id: StringName = &""
var buffs: Array[BuffSpec] = []


static func from_template(template: RegistrationTemplate, reg_id: StringName) -> Registration:
	var r := Registration.new()
	r.id = reg_id
	r.controller_id = template.controller_id
	r.lifetime_kind = template.lifetime_kind
	r.duration = template.duration
	r.encounter_frame_id = template.encounter_frame_id
	r.buffs = template.buffs.duplicate()
	return r
