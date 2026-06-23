class_name EncounterResolutionFrame
extends RefCounted

## 单次 seq.draw.encounter run 的结算帧；险境（peril）粘性挂在本对象上。

var id: StringName = &""
var drawer_id: StringName = &""
var peril: bool = false
var peril_restrictions_registered: bool = false
var cards_resolved: Array[StringName] = []
var surge_depth: int = 0


static func create(drawer_id: StringName) -> EncounterResolutionFrame:
	var frame := EncounterResolutionFrame.new()
	frame.id = StringName("enc_frame_%d" % Time.get_ticks_msec())
	frame.drawer_id = drawer_id
	return frame


func note_peril_keyword(has_peril: bool) -> void:
	if has_peril:
		peril = true


func append_resolved(card_id: StringName) -> void:
	if card_id != &"":
		cards_resolved.append(card_id)
