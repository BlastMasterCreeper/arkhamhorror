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


static func draw_collect_one(
	controller_id: StringName,
	after_timing: StringName = &"after_draw_collect_one"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("draw_collect_%s_%d" % [controller_id, Time.get_ticks_msec()])
	t.kind = &"draw_collect_one"
	t.controller_id = controller_id
	t.tags = [&"draw_investigator", &"draw_collect"]
	t.after_timing = after_timing
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
