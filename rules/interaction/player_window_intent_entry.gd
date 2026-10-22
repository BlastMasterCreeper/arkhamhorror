class_name PlayerWindowIntentEntry
extends RefCounted

## 玩家时间段窗意图池条目（16 §7.3）。

var entry_id: StringName = &""
var ability_id: StringName = &""
var controller_id: StringName = &""
var source_id: StringName = &""
var repeat_count: int = 1


static func free_ability(
	ability_id: StringName,
	controller_id: StringName,
	source_id: StringName = &"",
	repeat_count: int = 1
) -> PlayerWindowIntentEntry:
	var e := PlayerWindowIntentEntry.new()
	e.entry_id = StringName("pw_%s_%d" % [ability_id, Time.get_ticks_msec()])
	e.ability_id = ability_id
	e.controller_id = controller_id
	e.source_id = source_id
	e.repeat_count = maxi(repeat_count, 1)
	return e
