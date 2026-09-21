class_name KeywordProfileTable
extends RefCounted

## 06 §3.2.6 · 关键词 Buff 的注册 / 注销场合。猎物 / 生成是指令，不进本表。
## LISTENER 延时竖切仍按 consume_slot 过滤；其它行只供 MountService / Store 钩查询。

const SLOT_AFTER_DRAWN_CARD: StringName = &"AFTER_DRAWN_CARD"

const OCC_SETUP: StringName = &"SETUP"
const OCC_AFTER_MULLIGAN: StringName = &"AFTER_MULLIGAN"
const OCC_CARD_DRAWN: StringName = &"CARD_DRAWN"
const OCC_PERIL_CHECK: StringName = &"PERIL_CHECK"
const OCC_REVELATION: StringName = &"REVELATION"
const OCC_ENTER_PLAY: StringName = &"ENTER_PLAY"
const OCC_LEAVE_PLAY: StringName = &"LEAVE_PLAY"
const OCC_ENTER_HAND: StringName = &"ENTER_HAND"
const OCC_LEAVE_HAND: StringName = &"LEAVE_HAND"
const OCC_GRANT: StringName = &"GRANT"
const OCC_DEFEAT: StringName = &"DEFEAT"
const OCC_FIRED: StringName = &"FIRED"
const OCC_DRAWN_CARD_FINALIZE: StringName = &"DRAWN_CARD_FINALIZE"
const OCC_LEAVE_SET_ASIDE: StringName = &"LEAVE_SET_ASIDE"

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


static func profiles_for_register_occasion(occasion: StringName) -> Array[KeywordProfile]:
	var matched: Array[KeywordProfile] = []
	for profile in _all():
		if profile.register_occasion == occasion:
			matched.append(profile)
	return matched


static func profiles_for_unregister_occasion(occasion: StringName) -> Array[KeywordProfile]:
	var matched: Array[KeywordProfile] = []
	for profile in _all():
		if profile.unregister_occasion == occasion:
			matched.append(profile)
	return matched


static func _all() -> Array[KeywordProfile]:
	var profiles: Array[KeywordProfile] = []
	## LISTENER · 不在场也可武装
	profiles.append(_row(
		&"surge", BUFF_LISTENER, OCC_CARD_DRAWN, OCC_FIRED, ZONE_LIMBO, LIFE_UNTIL_FIRED,
		SLOT_AFTER_DRAWN_CARD, &"seq.keyword.surge"
	))
	profiles.append(_row(
		&"starting", BUFF_LISTENER, OCC_SETUP, OCC_FIRED, ZONE_DECK, LIFE_IN_DECK
	))
	profiles.append(_row(
		&"swarming", BUFF_LISTENER, OCC_ENTER_PLAY, OCC_FIRED, ZONE_PLAY, LIFE_UNTIL_FIRED
	))
	## LISTENER · 在场
	profiles.append(_row(
		&"hunter", BUFF_LISTENER, OCC_ENTER_PLAY, OCC_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"patrol", BUFF_LISTENER, OCC_ENTER_PLAY, OCC_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"retaliate", BUFF_LISTENER, OCC_ENTER_PLAY, OCC_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"alert", BUFF_LISTENER, OCC_ENTER_PLAY, OCC_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"elusive", BUFF_LISTENER, OCC_ENTER_PLAY, OCC_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"doomed", BUFF_LISTENER, OCC_ENTER_PLAY, OCC_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	## RESTRICTION · 不在场也可武装
	profiles.append(_row(
		&"peril", BUFF_RESTRICTION, OCC_PERIL_CHECK, OCC_DRAWN_CARD_FINALIZE,
		ZONE_LIMBO, LIFE_DRAWN_RESOLVING
	))
	profiles.append(_row(
		&"hidden", BUFF_RESTRICTION, OCC_ENTER_HAND, OCC_LEAVE_HAND, ZONE_HAND, LIFE_HIDDEN_HAND
	))
	## RESTRICTION · 在场
	profiles.append(_row(
		&"aloof", BUFF_RESTRICTION, OCC_ENTER_PLAY, OCC_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"massive", BUFF_RESTRICTION, OCC_ENTER_PLAY, OCC_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"permanent", BUFF_RESTRICTION, OCC_SETUP, OCC_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	profiles.append(_row(
		&"unique", BUFF_RESTRICTION, OCC_ENTER_PLAY, OCC_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY
	))
	## MODIFIER · 不 Register LISTENER；Initiation 从手收集
	profiles.append(_row(&"fast", BUFF_MODIFIER, &"", &"", ZONE_HAND, &""))
	## L0 / Domain · 不走 LISTENER
	profiles.append(_row(&"uses", BUFF_DOMAIN, OCC_ENTER_PLAY, OCC_LEAVE_PLAY, ZONE_PLAY, &""))
	profiles.append(_row(&"victory", BUFF_DOMAIN, OCC_DEFEAT, &"", ZONE_PLAY, &""))
	profiles.append(_row(&"vengeance", BUFF_DOMAIN, OCC_DEFEAT, &"", ZONE_PLAY, &""))
	profiles.append(_row(&"seal", BUFF_DOMAIN, OCC_ENTER_PLAY, OCC_LEAVE_PLAY, ZONE_PLAY, &""))
	## 构筑；Bonded 对局另挂 WHILE_SET_ASIDE
	profiles.append(_row(
		&"bonded", BUFF_DECKBUILDING, OCC_SETUP, OCC_LEAVE_SET_ASIDE, ZONE_SET_ASIDE, LIFE_SET_ASIDE
	))
	profiles.append(_row(&"exceptional", BUFF_DECKBUILDING, &"", &"", &"", &""))
	profiles.append(_row(&"myriad", BUFF_DECKBUILDING, &"", &"", &"", &""))
	profiles.append(_row(&"reward", BUFF_DECKBUILDING, &"", &"", &"", &""))
	profiles.append(_row(&"researched", BUFF_DECKBUILDING, &"", &"", &"", &""))
	profiles.append(_row(&"customizable", BUFF_DECKBUILDING, &"", &"", &"", &""))
	return profiles


static func _row(
	keyword: StringName,
	buff_type: StringName,
	register_occasion: StringName,
	unregister_occasion: StringName,
	armed_zone: StringName,
	lifetime_kind: StringName,
	consume_slot: StringName = &"",
	consume_flow_id: StringName = &""
) -> KeywordProfile:
	var profile := KeywordProfile.new()
	profile.keyword = keyword
	profile.buff_type = buff_type
	profile.register_occasion = register_occasion
	profile.unregister_occasion = unregister_occasion
	profile.armed_zone = armed_zone
	profile.lifetime_kind = lifetime_kind
	profile.consume_slot = consume_slot
	profile.consume_flow_id = consume_flow_id
	return profile
