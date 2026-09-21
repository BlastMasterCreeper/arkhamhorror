class_name KeywordProfileTable
extends RefCounted

## 关键词模块表。新 keyword 加一行 + consume seq，禁止写进 seq.draw.encounter 优先队列。

const SLOT_AFTER_DRAWN_CARD: StringName = &"AFTER_DRAWN_CARD"


static func profiles_for_slot(slot: StringName) -> Array[KeywordProfile]:
	var matched: Array[KeywordProfile] = []
	for profile in _all():
		if profile.consume_slot == slot:
			matched.append(profile)
	return matched


static func _all() -> Array[KeywordProfile]:
	var surge := KeywordProfile.new()
	surge.keyword = &"surge"
	surge.consume_slot = SLOT_AFTER_DRAWN_CARD
	surge.consume_flow_id = &"seq.keyword.surge"
	var profiles: Array[KeywordProfile] = []
	profiles.append(surge)
	return profiles
