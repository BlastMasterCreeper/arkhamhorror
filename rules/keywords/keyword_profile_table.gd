class_name KeywordProfileTable
extends RefCounted

## 06 §3.2.6–§3.2.7 · 注册/注销绑已有流程砖或 zone 变迁。猎物 / 生成不进本表。
## LISTENER 开火：KeywordConsumer 按 (fire_flow_id, consume_slot) 收集，再按 fire_priority 排序。

const SLOT_AFTER_DRAWN_CARD: StringName = &"AFTER_DRAWN_CARD"

const FLOW_DRAW_ENCOUNTER: StringName = &"seq.draw.encounter"
const FLOW_DRAW_INVESTIGATOR: StringName = &"seq.draw.investigator"
const FLOW_ENCOUNTER_REVELATION: StringName = &"seq.encounter.revelation"
const FLOW_ENCOUNTER_SPAWN: StringName = &"seq.encounter.spawn"
const FLOW_ENTER_HAND: StringName = &"seq.enter_hand"
const FLOW_SETUP: StringName = &"seq.setup"
const FLOW_KEYWORD_SURGE: StringName = &"seq.keyword.surge"
const FLOW_KEYWORD_HUNTER: StringName = &"seq.keyword.hunter"
const FLOW_KEYWORD_PATROL: StringName = &"seq.keyword.patrol"
const FLOW_KEYWORD_MASSIVE: StringName = &"seq.keyword.massive"
const FLOW_ENEMY_3_2: StringName = &"seq.enemy.3_2"
const FLOW_ENEMY_ATTACK: StringName = &"seq.enemy.attack"
const FLOW_ENEMY_DEFEAT: StringName = &"seq.enemy.defeat"
const FLOW_PHASE_ATTACKS: StringName = &"seq.enemy.phase_attacks"
const FLOW_SKILL_TEST: StringName = &"seq.skill_test"

const SLOT_G2: StringName = &"G2"
const SLOT_G4: StringName = &"G4"
const SLOT_WHEN: StringName = &"WHEN"
const SLOT_AFTER: StringName = &"AFTER"
const SLOT_ENEMY_3_2: StringName = &"ENEMY_3_2"
const SLOT_ATTACK: StringName = &"ATTACK"
const SLOT_POST_ST7_FAIL: StringName = &"POST_ST7_FAIL"
const SLOT_AFTER_ATTACK: StringName = &"AFTER_ATTACK"
const SLOT_ON_DEFEAT: StringName = &"ON_DEFEAT"
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
const BUFF_INITIATION: StringName = &"INITIATION"

const TIER_FORCED: StringName = &"FORCED"
const TIER_FRAMEWORK: StringName = &"FRAMEWORK"
const TIER_TRIGGERED: StringName = &"TRIGGERED"
const TIER_DELAYED: StringName = &"DELAYED"
const TIER_LISTENER: StringName = &"LISTENER"
## 效果替换（Instead / Would）；庞大对阶段攻击走此档，非平行 framework seq。
const TIER_REPLACE: StringName = &"REPLACE"

const PLAY_ACTION: StringName = &"PLAY_ACTION"
const PLAY_FAST_WINDOW: StringName = &"PLAY_FAST_WINDOW"
const PLAY_FAST_TIMING: StringName = &"PLAY_FAST_TIMING"


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
	matched.sort_custom(func(a: KeywordProfile, b: KeywordProfile) -> bool:
		if a.fire_priority != b.fire_priority:
			return a.fire_priority < b.fire_priority
		return str(a.keyword) < str(b.keyword)
	)
	return matched


static func profiles_for_fire_anchor(
	fire_flow_id: StringName,
	fire_slot: StringName
) -> Array[KeywordProfile]:
	var matched: Array[KeywordProfile] = []
	for profile in _all():
		if profile.buff_type != BUFF_LISTENER:
			continue
		if profile.fire_flow_id != fire_flow_id:
			continue
		if profile.consume_slot != fire_slot:
			continue
		matched.append(profile)
	matched.sort_custom(func(a: KeywordProfile, b: KeywordProfile) -> bool:
		if a.fire_priority != b.fire_priority:
			return a.fire_priority < b.fire_priority
		return str(a.keyword) < str(b.keyword)
	)
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


static func play_form(has_fast: bool, has_timing_point: bool) -> StringName:
	## 打出仍是 PLAY_CARD。返回值只选窗口/是否耗 action，对齐免费/反应的对称，不是 AbilityKind。
	if not has_fast:
		return PLAY_ACTION
	if has_timing_point:
		return PLAY_FAST_TIMING
	return PLAY_FAST_WINDOW


static func _all() -> Array[KeywordProfile]:
	var profiles: Array[KeywordProfile] = []
	## LISTENER · 涌动：挂载抽牌 WHEN；开火 = 本条 AFTER 之后（DELAYED）
	profiles.append(_row(
		&"surge", BUFF_LISTENER,
		FLOW_DRAW_ENCOUNTER, SLOT_WHEN,
		FLOW_DRAW_ENCOUNTER, SLOT_AFTER,
		ZONE_LIMBO, LIFE_UNTIL_FIRED,
		SLOT_AFTER_DRAWN_CARD, FLOW_KEYWORD_SURGE,
		FLOW_DRAW_ENCOUNTER, 10, TIER_DELAYED
	))
	profiles.append(_row(
		&"starting", BUFF_LISTENER,
		FLOW_SETUP, SLOT_SETUP,
		FLOW_SETUP, SLOT_AFTER,
		ZONE_DECK, LIFE_IN_DECK,
		&"", &"",
		FLOW_SETUP, 10, TIER_DELAYED
	))
	profiles.append(_row(
		&"swarming", BUFF_LISTENER,
		&"", SLOT_ENTER_PLAY,
		&"", SLOT_FIRED,
		ZONE_PLAY, LIFE_UNTIL_FIRED,
		&"", &"",
		FLOW_ENCOUNTER_SPAWN, 10, TIER_DELAYED
	))
	## LISTENER · 进场挂载；开火锚在固定框架/攻击/检定流程（非流程内联管理体）
	profiles.append(_row(
		&"hunter", BUFF_LISTENER,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY,
		SLOT_ENEMY_3_2, FLOW_KEYWORD_HUNTER,
		FLOW_ENEMY_3_2, 10, TIER_LISTENER
	))
	profiles.append(_row(
		&"patrol", BUFF_LISTENER,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY,
		SLOT_ENEMY_3_2, FLOW_KEYWORD_PATROL,
		FLOW_ENEMY_3_2, 20, TIER_LISTENER
	))
	profiles.append(_row(
		&"retaliate", BUFF_LISTENER,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY,
		SLOT_POST_ST7_FAIL, &"",
		FLOW_SKILL_TEST, 10, TIER_LISTENER
	))
	profiles.append(_row(
		&"alert", BUFF_LISTENER,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY,
		SLOT_POST_ST7_FAIL, &"",
		FLOW_SKILL_TEST, 20, TIER_LISTENER
	))
	profiles.append(_row(
		&"elusive", BUFF_LISTENER,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY,
		SLOT_AFTER_ATTACK, &"",
		FLOW_ENEMY_ATTACK, 10, TIER_LISTENER
	))
	profiles.append(_row(
		&"doomed", BUFF_LISTENER,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY,
		SLOT_ON_DEFEAT, &"",
		FLOW_ENEMY_DEFEAT, 10, TIER_LISTENER
	))
	## RESTRICTION · 险境 = 遭遇抽牌 G2 / G4 已有砖（无 fire_priority；挂载即生效）
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
	## 庞大：RESTRICTION（交战）+ 对一般攻击效果 seq.enemy.attack 的 REPLACE（PHASE→batch）
	profiles.append(_row(
		&"massive", BUFF_RESTRICTION,
		&"", SLOT_ENTER_PLAY, &"", SLOT_LEAVE_PLAY, ZONE_PLAY, LIFE_IN_PLAY,
		SLOT_ATTACK, FLOW_KEYWORD_MASSIVE,
		FLOW_ENEMY_ATTACK, 10, TIER_REPLACE
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
	## 快速 · 打出 Initiation 档（非 LISTENER；勿与 ArkhamDB [fast]=免费触发符号合并）
	profiles.append(_row(&"fast", BUFF_INITIATION, &"", &"", &"", &"", ZONE_HAND, &""))
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
	consume_flow_id: StringName = &"",
	fire_flow_id: StringName = &"",
	fire_priority: int = 100,
	category_tier: StringName = TIER_LISTENER
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
	profile.fire_flow_id = fire_flow_id
	profile.fire_priority = fire_priority
	profile.category_tier = category_tier
	return profile
