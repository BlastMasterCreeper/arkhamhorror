class_name KeywordProfileTable
extends RefCounted

## 06 §3.2.6 · 注册/注销绑已有流程砖或 zone 变迁。猎物 / 生成不进本表。
## LISTENER 延时竖切仍按 consume_slot 过滤。

const SLOT_AFTER_DRAWN_CARD: StringName = &"AFTER_DRAWN_CARD"

const FLOW_DRAW_ENCOUNTER: StringName = &"seq.draw.encounter"
const FLOW_DRAW_INVESTIGATOR: StringName = &"seq.draw.investigator"
const FLOW_ENCOUNTER_REVELATION: StringName = &"seq.encounter.revelation"
const FLOW_ENCOUNTER_SPAWN: StringName = &"seq.encounter.spawn"
const FLOW_ENTER_HAND: StringName = &"seq.enter_hand"
const FLOW_SETUP: StringName = &"seq.setup"
const FLOW_KEYWORD_SURGE: StringName = &"seq.keyword.surge"

const SLOT_G2: StringName = &"G2"
const SLOT_G4: StringName = &"G4"
const SLOT_WHEN: StringName = &"WHEN"
const SLOT_AFTER: StringName = &"AFTER"
const SLOT_ENTER_PLAY: StringName = &"ENTER_PLAY"
const SLOT_LEAVE_PLAY: StringName = &"LEAVE_PLAY"
const SLOT_ENTER_HAND: StringName = &"ENTER_HAND"
const SLOT_LEAVE_HAND: StringName = &"LEAVE_HAND"
const SLOT_ENTER_SET_ASIDE: StringName = &"ENTER_SET_ASIDE"
const SLOT_LEAVE_SET_ASIDE: StringName = &"LEAVE_SET_ASIDE"
const SLOT_GRANT: StringName = &"GRANT"
const SLOT_DEFEAT: StringName = &"DEFEAT"
const SLOT_FIRED: StringName = &"FIRED"
const SLOT_SETUP: StringName = &"SETUP"

const ZONE_PLAY: StringName = &"PLAY"
const ZONE_LIMBO: StringName = &"LIMBO"
const ZONE_HAND: StringName = &"HAND"
const ZONE_DECK: StringName = &"DECK"
const ZONE_SET_ASIDE: StringName = &"SET_ASIDE"

const LIFE_IN_PLAY: StringName = &"WHILE_IN_PLAY"
const LIFE_DRAWN_RESOLVING: StringName = &"WHILE_DRAWN_CARD_RESOLVING"
const LIFE_HIDDEN_HAND: StringName = &"WHILE_HIDDEN_IN_HAND"
const LIFE_IN_HAND: StringName = &"WHILE_IN_HAND"
const LIFE_IN_DECK: StringName = &"WHILE_IN_DECK"
const LIFE_SET_ASIDE: StringName = &"WHILE_SET_ASIDE"
const LIFE_UNTIL_FIRED: StringName = &"UNTIL_FIRED"

const BUFF_LISTENER: StringName = &"LISTENER"
const BUFF_RESTRICTION: StringName = &"RESTRICTION"
const BUFF_MODIFIER: StringName = &"MODIFIER"
const BUFF_DOMAIN: StringName = &"DOMAIN"
const BUFF_DECKBUILDING: StringName = &"DECKBUILDING"


static func all_profiles() -> Array[KeywordProfile]:
	return _all()


static func profile_for(keyword: StringName) -> KeywordProfile:
	for profile in _all():
		if profile.keyword == keyword:
			return profile
	return null


static func profiles_for_slot(slot: StringName) -> Array[KeywordProfile]:
	var matched: Array[KeywordProfile] = []
	for profile in _all():
		if profile.consume_slot == slot:
			matched.append(profile)
	return matched


static func profiles_for_register(flow_id: StringName, slot: StringName) -> Array[KeywordProfile]:
	var matched: Array[KeywordProfile] = []
	for profile in _all():
		if profile.register_flow_id == flow_id and profile.register_slot == slot:
			matched.append(profile)
	return matched


static func profiles_for_unregister(flow_id: StringName, slot: StringName) -> Array[KeywordProfile]:
	var matched: Array[KeywordProfile] = []
	for profile in _all():
		if profile.unregister_flow_id == flow_id and profile.unregister_slot == slot:
			matched.append(profile)
	return matched


static func _all() -> Array[KeywordProfile]:
	var profiles: Array[KeywordProfile] = []
	## LISTENER · 绑 seq.draw.encounter 已有砖（不另开 PERIL_CHECK / CARD_DRAWN 节点）
	profiles.append(_row(
		&"surge", BUFF_LISTENER,
		FLOW_DRAW_ENCOUNTER, SLOT_WHEN,
		FLOW_DRAW_ENCOUNTER, SLOT_AFTER,
		ZONE_LIMBO, LIFE_UNTIL_FIRED,
		SLOT_AFTER_DRAWN_CARD, FLOW_KEYWORD_SURGE
	))
	profiles.append(_row(
		&"starting", BUFF_LISTENER,
		FLOW_SETUP, SLOT_SETUP,
		FLOW_SETUP, SLOT_AFTER,
		ZONE_DECK, LIFE_IN_DECK
	))
	profiles.append(_row(
		&"swarming", BUFF_LISTENER,
		&"", SLOT_ENTER_PLAY,
		&"", SLOT_FIRED,
		ZONE_PLAY, LIFE_UNTIL_FIRED
	))
	## LISTENER · zone 变迁（spawn / 打出等已有流程里的 L0）
	profiles.append(_row(
		&"hunter", BUFF_LISTENER,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"patrol", BUFF_LISTENER,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"retaliate", BUFF_LISTENER,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"alert", BUFF_LISTENER,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"elusive", BUFF_LISTENER,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"doomed", BUFF_LISTENER,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	## RESTRICTION · 险境 = 遭遇抽牌 G2 / G4 已有砖
	profiles.append(_row(
		&"peril", BUFF_RESTRICTION,
		FLOW_DRAW_ENCOUNTER, SLOT_G2,
		FLOW_DRAW_ENCOUNTER, SLOT_G4,
		ZONE_LIMBO, LIFE_DRAWN_RESOLVING
	))
	profiles.append(_row(
		&"hidden", BUFF_RESTRICTION,
		FLOW_ENCOUNTER_REVELATION, SLOT_ENTER_HAND,
		&"", SLOT_LEAVE_HAND,
		ZONE_HAND, LIFE_HIDDEN_HAND
	))
	profiles.append(_row(
		&"aloof", BUFF_RESTRICTION,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"massive", BUFF_RESTRICTION,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"permanent", BUFF_RESTRICTION,
		FLOW_SETUP, SLOT_ENTER_PLAY,
		&"", SLOT_LEAVE_PLAY,
		ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"unique", BUFF_RESTRICTION,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	## MODIFIER · 不 Register LISTENER；Initiation 从手收集
	profiles.append(_row(&"fast", BUFF_MODIFIER, &"", &"", &"", &"", ZONE_HAND, &""))
	## L0 / Domain
	profiles.append(_row(
		&"uses", BUFF_DOMAIN, &"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, &""
	))
	profiles.append(_row(&"victory", BUFF_DOMAIN, &"", SLOT_DEFEAT, &"", &"", ZONE_PLAY, &""))
	profiles.append(_row(&"vengeance", BUFF_DOMAIN, &"", SLOT_DEFEAT, &"", &"", ZONE_PLAY, &""))
	profiles.append(_row(
		&"seal", BUFF_DOMAIN, &"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, &""
	))
	## 构筑；绑定对局挂 WHILE_SET_ASIDE（setup 已有 set-aside 步）
	profiles.append(_row(
		&"bonded", BUFF_DECKBUILDING,
		FLOW_SETUP, SLOT_ENTER_SET_ASIDE,
		&"", SLOT_LEAVE_SET_ASIDE,
		ZONE_SET_ASIDE, LIFE_SET_ASIDE
	))
	profiles.append(_row(&"exceptional", BUFF_DECKBUILDING, &"", &"", &"", &"", &"", &""))
	profiles.append(_row(&"myriad", BUFF_DECKBUILDING, &"", &"", &"", &"", &"", &""))
	profiles.append(_row(&"reward", BUFF_DECKBUILDING, &"", &"", &"", &"", &"", &""))
	profiles.append(_row(&"researched", BUFF_DECKBUILDING, &"", &"", &"", &"", &"", &""))
	profiles.append(_row(&"customizable", BUFF_DECKBUILDING, &"", &"", &"", &"", &"", &""))
	return profiles


static func _row(
	keyword: StringName,
	buff_type: StringName,
	register_flow_id: StringName,
	register_slot: StringName,
	unregister_flow_id: StringName,
	unregister_slot: StringName,
	armed_zone: StringName,
	lifetime_kind: StringName,
	consume_slot: StringName = &"",
	consume_flow_id: StringName = &""
) -> KeywordProfile:
	var profile := KeywordProfile.new()
	profile.keyword = keyword
	profile.buff_type = buff_type
	profile.register_flow_id = register_flow_id
	profile.register_slot = register_slot
	profile.unregister_flow_id = unregister_flow_id
	profile.unregister_slot = unregister_slot
	profile.armed_zone = armed_zone
	profile.lifetime_kind = lifetime_kind
	profile.consume_slot = consume_slot
	profile.consume_flow_id = consume_flow_id
	return profile
