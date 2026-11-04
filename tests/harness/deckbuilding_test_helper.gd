class_name DeckbuildingTestHelper
extends RefCounted

## DB-* Deckbuilding Options 准入竖切。


static func _card(
	id: String,
	opts: Dictionary = {}
) -> DeckCardView:
	var data := {
		"definition_id": id,
		"title": opts.get("title", id),
		"level": opts.get("level", 0),
		"card_type": opts.get("card_type", "asset"),
		"factions": opts.get("factions", []),
		"faction_code": opts.get("faction_code", ""),
		"traits": opts.get("traits", []),
		"tags": opts.get("tags", []),
		"uses_types": opts.get("uses_types", []),
		"permanent": opts.get("permanent", false),
		"ignore_deckbuilding": opts.get("ignore_deckbuilding", false),
	}
	if data["factions"] is Array and (data["factions"] as Array).is_empty() and str(data["faction_code"]) != "":
		data["factions"] = [data["faction_code"]]
	return DeckCardView.from_definition_dict(data, StringName(id))


static func _roland() -> DeckbuildingProfile:
	return DeckbuildingProfile.from_options(
		[
			{"faction": ["guardian", "neutral"], "level": {"min": 0, "max": 5}},
			{"faction": ["seeker"], "level": {"min": 0, "max": 2}},
		],
		{},
		30,
		&"01001"
	)


static func _zoey() -> DeckbuildingProfile:
	return DeckbuildingProfile.from_options(
		[
			{"faction": ["guardian", "neutral"], "level": {"min": 0, "max": 5}},
			{
				"level": {"min": 0, "max": 0},
				"limit": 5,
				"error": "You cannot have more than 5 cards that are not Guardian or Neutral",
			},
		],
		{},
		30,
		&"02001"
	)


static func test_db01_roland_seeker_levels() -> bool:
	var profile := _roland()
	var seeker2 := _card("s2", {"faction_code": "seeker", "level": 2})
	var seeker3 := _card("s3", {"faction_code": "seeker", "level": 3})
	var guardian5 := _card("g5", {"faction_code": "guardian", "level": 5})
	return (
		CardAccessMatcher.can_access(seeker2, profile)
		and not CardAccessMatcher.can_access(seeker3, profile)
		and CardAccessMatcher.can_access(guardian5, profile)
	)


static func test_db02_zoey_offclass_limit_and_multiclass() -> bool:
	var profile := _zoey()
	## 本职不占越级坑。
	var g0 := _card("g0", {"faction_code": "guardian", "level": 0})
	if CardAccessMatcher.classify(g0, profile).get("kind") != CardAccessMatcher.KIND_UNLIMITED:
		return false
	## 多职阶含本职 → 无限带（FAQ 1.16 Dunwich）。
	var multi := _card(
		"gs0",
		{"factions": ["guardian", "seeker"], "level": 0, "title": "Multi"}
	)
	if CardAccessMatcher.classify(multi, profile).get("kind") != CardAccessMatcher.KIND_UNLIMITED:
		return false
	## 五张越级 L0 后第六张拒。
	var deck: Array = []
	for i in 5:
		deck.append(_card("sk%d" % i, {"faction_code": "seeker", "level": 0, "title": "Sk%d" % i}))
	var sixth := _card("sk5", {"faction_code": "seeker", "level": 0, "title": "Sk5"})
	var add5 := DeckLegality.can_add_card(deck.slice(0, 4), deck[4], profile)
	if not bool(add5.get("ok", false)):
		return false
	var add6 := DeckLegality.can_add_card(deck, sixth, profile)
	return not bool(add6.get("ok", false))


static func test_db03_carolyn_heal_tag_and_weapon_forbid() -> bool:
	var profile := DeckbuildingProfile.from_options(
		[
			{"not": true, "trait": ["weapon"], "level": {"min": 1, "max": 5}},
			{"faction": ["guardian"], "level": {"min": 0, "max": 3}},
			{"faction": ["neutral"], "level": {"min": 0, "max": 5}},
			{"tag": ["hh"], "level": {"min": 0, "max": 5}},
			{
				"faction": ["seeker", "mystic"],
				"level": {"min": 0, "max": 1},
				"limit": 15,
				"error": "You cannot have more than 15 level 0-1 Seeker and/or Mystic cards",
			},
		],
		{},
		30,
		&"05001"
	)
	var healer := _card(
		"heal",
		{"faction_code": "seeker", "level": 3, "tags": ["hh"], "title": "Healer"}
	)
	## Seeker L3 不在跨职 limit，但 hh 无限带可收。
	if CardAccessMatcher.classify(healer, profile).get("kind") != CardAccessMatcher.KIND_UNLIMITED:
		return false
	var weapon := _card(
		"gun",
		{"faction_code": "guardian", "level": 1, "traits": ["weapon"], "title": "Gun"}
	)
	return CardAccessMatcher.classify(weapon, profile).get("kind") == CardAccessMatcher.KIND_FORBIDDEN


static func test_db04_tony_secondary_class_choice() -> bool:
	var profile := DeckbuildingProfile.from_options(
		[
			{"faction": ["rogue", "neutral"], "level": {"min": 0, "max": 5}},
			{
				"name": "Secondary Class",
				"faction_select": ["guardian", "seeker", "survivor"],
				"level": {"min": 0, "max": 1},
				"type": ["event", "skill"],
				"limit": 10,
			},
		],
		{"Secondary Class": "survivor"},
		30,
		&"06003"
	)
	var surv_event := _card(
		"se",
		{
			"faction_code": "survivor",
			"level": 1,
			"card_type": "event",
			"title": "SurvEvent",
		}
	)
	var surv_asset := _card(
		"sa",
		{
			"faction_code": "survivor",
			"level": 0,
			"card_type": "asset",
			"title": "SurvAsset",
		}
	)
	return (
		CardAccessMatcher.can_access(surv_event, profile)
		and not CardAccessMatcher.can_access(surv_asset, profile)
	)


static func test_db06_lola_atleast() -> bool:
	var profile := DeckbuildingProfile.from_options(
		[
			{
				"faction": ["survivor", "guardian", "seeker", "rogue", "mystic"],
				"level": {"min": 0, "max": 3},
				"atleast": {"factions": 3, "min": 7},
				"error": "You must have at least 7 cards from 3 different factions",
			},
			{"faction": ["neutral"], "level": {"min": 0, "max": 5}},
		],
		{},
		30,
		&"03006"
	)
	## 仅 2 职阶各 7 + 16 neutral = 30 → atleast 失败。
	var deck: Array = []
	for i in 7:
		deck.append(_card("g%d" % i, {"faction_code": "guardian", "level": 0, "title": "G%d" % i}))
	for i in 7:
		deck.append(_card("s%d" % i, {"faction_code": "seeker", "level": 0, "title": "S%d" % i}))
	for i in 16:
		deck.append(_card("n%d" % i, {"faction_code": "neutral", "level": 0, "title": "N%d" % i}))
	var bad := DeckLegality.validate_deck(deck, profile)
	if bool(bad.get("ok", true)):
		return false
	## 7g + 7s + 7m + 9n = 30 → 3 职阶达标。
	var good_deck: Array = []
	for i in 7:
		good_deck.append(_card("g%d" % i, {"faction_code": "guardian", "level": 0, "title": "G%d" % i}))
	for i in 7:
		good_deck.append(_card("s%d" % i, {"faction_code": "seeker", "level": 0, "title": "S%d" % i}))
	for i in 7:
		good_deck.append(_card("m%d" % i, {"faction_code": "mystic", "level": 0, "title": "M%d" % i}))
	for i in 9:
		good_deck.append(_card("n%d" % i, {"faction_code": "neutral", "level": 0, "title": "N%d" % i}))
	var good := DeckLegality.validate_deck(good_deck, profile)
	return bool(good.get("ok", false))


static func test_db07_purchase_dry_run_limit_full() -> bool:
	var profile := _zoey()
	var deck: Array = []
	for i in 5:
		deck.append(_card("sk%d" % i, {"faction_code": "seeker", "level": 0, "title": "Sk%d" % i}))
	var next := _card("skx", {"faction_code": "seeker", "level": 0, "title": "SkX"})
	return not bool(DeckLegality.can_add_card(deck, next, profile).get("ok", true))
