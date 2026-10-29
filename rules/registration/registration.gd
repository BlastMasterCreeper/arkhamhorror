class_name Registration
extends RefCounted

var id: StringName = &""
var controller_id: StringName = &""
var lifetime_kind: AhcEnums.LifetimeKind = AhcEnums.LifetimeKind.DURATION
var duration: AhcEnums.DurationAnchorKind = AhcEnums.DurationAnchorKind.THIS_TURN
var encounter_frame_id: StringName = &""
var drawn_card_id: StringName = &""
## 行为 Buff（MODIFIER / RESTRICTION / LISTENER）。
var buffs: Array[BuffSpec] = []
## Gain 特征（拥有）；**不是** Buff。卸本条时级联卸 `derived_reg_ids`。
var gains: Array[GainedCharacteristicSpec] = []
## Gain 衍生出的行为 Registration id（同 Store）；Unregister Gain 壳时一并卸。
var derived_reg_ids: Array[StringName] = []


static func from_template(template: RegistrationTemplate, reg_id: StringName) -> Registration:
	var r := Registration.new()
	r.id = reg_id
	r.controller_id = template.controller_id
	r.lifetime_kind = template.lifetime_kind
	r.duration = template.duration
	r.encounter_frame_id = template.encounter_frame_id
	r.drawn_card_id = template.drawn_card_id
	r.buffs = template.buffs.duplicate()
	r.gains = template.gains.duplicate()
	return r
