class_name EncounterResolutionFrame
extends RefCounted

## 单次 seq.draw.encounter run 的诊断帧；险境 RESTRICTION 按 card_id 生命周期，不挂本对象。

var id: StringName = &""
var drawer_id: StringName = &""
var current_card_id: StringName = &""
var cards_resolved: Array[StringName] = []
var surge_depth: int = 0
var shuffles: int = 0


static func create(drawer_id: StringName) -> EncounterResolutionFrame:
	var frame := EncounterResolutionFrame.new()
	frame.id = StringName("enc_frame_%d" % Time.get_ticks_msec())
	frame.drawer_id = drawer_id
	return frame


func append_resolved(card_id: StringName) -> void:
	if card_id != &"":
		cards_resolved.append(card_id)
