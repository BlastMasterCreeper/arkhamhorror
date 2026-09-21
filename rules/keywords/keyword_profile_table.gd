class_name KeywordProfileTable
extends RefCounted

## 仅登记 consume_shape = NEST_SEQ 的关键词。其它形状见 06 §3.2.5，禁止写进抽牌优先队列。

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
	surge.consume_shape = &"NEST_SEQ"
	surge.consume_slot = SLOT_AFTER_DRAWN_CARD
	surge.consume_flow_id = &"seq.keyword.surge"
	var profiles: Array[KeywordProfile] = []
	profiles.append(surge)
	return profiles
