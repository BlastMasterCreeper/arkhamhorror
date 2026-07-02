class_name TriggeringCondition
extends RefCounted

var id: StringName = &""
var kind: StringName = &""
var controller_id: StringName = &""
var tags: Array[StringName] = []
var after_timing: StringName = &""
var payload: Dictionary = {}


static func gain_resource(
	controller_id: StringName,
	source_tags: Array[StringName],
	after_timing: StringName = &"after_gain_resource"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("gain_%s_%d" % [controller_id, Time.get_ticks_msec()])
	t.kind = &"gain_resource"
	t.controller_id = controller_id
	t.tags = [&"gain_resource"]
	t.tags.append_array(source_tags)
	t.after_timing = after_timing
	return t


static func custom(
	kind: StringName,
	controller_id: StringName = &"",
	source_tags: Array[StringName] = [],
	after_timing: StringName = &""
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("%s_%d" % [kind, Time.get_ticks_msec()])
	t.kind = kind
	t.controller_id = controller_id
	t.tags = source_tags.duplicate()
	t.after_timing = after_timing
	return t


static func draw_investigator(
	controller_id: StringName,
	amount: int,
	source_tags: Array[StringName] = [],
	after_timing: StringName = &"after_draw_investigator"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("draw_%s_%d_%d" % [controller_id, amount, Time.get_ticks_msec()])
	t.kind = &"draw_investigator"
	t.controller_id = controller_id
	t.tags = [&"draw_investigator"]
	t.tags.append_array(source_tags)
	t.after_timing = after_timing
	t.payload = {"amount": amount}
	return t


static func draw_empty_piles_defeated(
	controller_id: StringName,
	after_timing: StringName = &"after_draw_empty_piles_defeated"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("draw_empty_%s_%d" % [controller_id, Time.get_ticks_msec()])
	t.kind = &"draw_empty_piles_defeated"
	t.controller_id = controller_id
	t.tags = [&"draw_investigator", &"draw_defeated"]
	t.after_timing = after_timing
	return t


static func enter_hand(
	controller_id: StringName,
	card_id: StringName,
	source_tags: Array[StringName] = [],
	after_timing: StringName = &"after_enter_hand"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enter_hand_%s_%d" % [card_id, Time.get_ticks_msec()])
	t.kind = &"enter_hand"
	t.controller_id = controller_id
	t.tags = [&"enter_hand", &"zone"]
	t.tags.append_array(source_tags)
	t.after_timing = after_timing
	t.payload = {"card_id": card_id}
	return t


static func draw_encounter(
	drawer_id: StringName,
	card_id: StringName = &"",
	source_tags: Array[StringName] = [],
	after_timing: StringName = &"after_draw_encounter"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("draw_enc_%s_%d" % [drawer_id, Time.get_ticks_msec()])
	t.kind = &"draw_encounter"
	t.controller_id = drawer_id
	t.tags = [&"draw_encounter", &"ENCOUNTER_CARD_DRAWN"]
	t.tags.append_array(source_tags)
	t.after_timing = after_timing
	t.payload = {"drawer_id": drawer_id, "card_id": card_id}
	return t


static func encounter_card_drawn(
	drawer_id: StringName,
	card_id: StringName,
	after_timing: StringName = &""
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enc_card_%s_%d" % [card_id, Time.get_ticks_msec()])
	t.kind = &"encounter_card_drawn"
	t.controller_id = drawer_id
	t.tags = [&"draw_encounter", &"ENCOUNTER_CARD_DRAWN"]
	t.payload = {"drawer_id": drawer_id, "card_id": card_id}
	t.after_timing = after_timing
	return t


static func encounter_revelation(
	drawer_id: StringName,
	card_id: StringName,
	after_timing: StringName = &"after_encounter_revelation"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enc_rev_%s_%d" % [card_id, Time.get_ticks_msec()])
	t.kind = &"encounter_revelation"
	t.controller_id = drawer_id
	t.payload = {"drawer_id": drawer_id, "card_id": card_id}
	return t


static func encounter_spawn(
	drawer_id: StringName,
	card_id: StringName,
	after_timing: StringName = &"after_encounter_spawn",
	from_hand: bool = false
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enc_spawn_%s_%d" % [card_id, Time.get_ticks_msec()])
	t.kind = &"encounter_spawn"
	t.controller_id = drawer_id
	if from_hand:
		t.tags = [&"spawn", &"encounter_spawn_from_hand"]
	else:
		t.tags = [&"draw_encounter", &"ENCOUNTER_CARD_DRAWN", &"spawn"]
	t.after_timing = after_timing
	t.payload = {
		"drawer_id": drawer_id,
		"card_id": card_id,
		"from_hand": from_hand,
	}
	return t


static func action_committed(
	action_kind: StringName,
	controller_id: StringName,
	source_tags: Array[StringName] = [],
	after_timing: StringName = &"",
	payload: Dictionary = {}
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("action_%s_%s_%d" % [action_kind, controller_id, Time.get_ticks_msec()])
	t.kind = StringName("action_%s" % action_kind)
	t.controller_id = controller_id
	t.tags = [&"action"]
	t.tags.append(action_kind)
	t.tags.append_array(source_tags)
	t.after_timing = after_timing if after_timing != &"" else StringName("after_action_%s" % action_kind)
	t.payload = payload.duplicate()
	return t


static func draw_encounter_resolve_bound(
	drawer_id: StringName,
	card_id: StringName,
	after_timing: StringName = &"after_draw_encounter_bound"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enc_bound_%s_%d" % [card_id, Time.get_ticks_msec()])
	t.kind = &"draw_encounter_resolve_bound"
	t.controller_id = drawer_id
	t.tags = [&"draw_encounter", &"weakness_encounter", &"ENCOUNTER_CARD_DRAWN"]
	t.after_timing = after_timing
	t.payload = {"drawer_id": drawer_id, "card_id": card_id}
	return t
