class_name CampaignPurchaseTestHelper
extends RefCounted

## XP-01.. 购卡窗 / Exceptional / 修饰器 / 幕间竖切。


static func _clear_registry() -> void:
	## CardRegistry 无 clear API；用唯一 id 前缀避免撞车。
	pass


static func _reg(id: String, data: Dictionary) -> void:
	var d := data.duplicate()
	d["definition_id"] = id
	if not d.has("title"):
		d["title"] = id
	CardRegistry.register_definition(StringName(id), d)


static func _roland_record(deck_size: int = 30) -> CampaignInvestigatorRecord:
	_reg(
		"inv_roland_p6",
		{
			"card_type": "investigator",
			"title": "Roland",
			"deck_options": [
				{"faction": ["guardian", "neutral"], "level": {"min": 0, "max": 5}},
				{"faction": ["seeker"], "level": {"min": 0, "max": 2}},
			],
			"deck_requirements": {"size": deck_size, "card": {}, "random": []},
		}
	)
	var rec := CampaignInvestigatorRecord.new()
	rec.investigator_id = &"p1"
	rec.definition_id = &"inv_roland_p6"
	## 填满 size-1 张 filler，便于 NEW_CARD 时测移除。
	for i in deck_size - 1:
		var fid := "fill_%d" % i
		_reg(fid, {"card_type": "asset", "title": "Fill%d" % i, "level": 0, "faction_code": "guardian"})
		rec.deck.append(DeckCardView.from_registry(StringName(fid)))
	return rec


static func test_xp01_quote_new_and_upgrade() -> bool:
	var rec := _roland_record(5)
	_reg("gun0", {"card_type": "asset", "title": "Gun", "level": 0, "faction_code": "guardian"})
	_reg("gun2", {"card_type": "asset", "title": "Gun", "level": 2, "faction_code": "guardian"})
	rec.deck.append(DeckCardView.from_registry(&"gun0"))
	InvestigatorCampaignSystem.begin_experience_window(rec, 10)
	var offer := InvestigatorCampaignSystem.quote_purchase(rec, &"gun2")
	if not bool(offer.get("ok", false)):
		return false
	var kinds: Array = []
	var upgrade_xp := -1
	var new_xp := -1
	for opt in offer.get("options", []):
		kinds.append(opt.get("kind"))
		if opt.get("kind") == XpCostCalculator.KIND_UPGRADE:
			upgrade_xp = int(opt.get("xp"))
		if opt.get("kind") == XpCostCalculator.KIND_NEW_CARD:
			new_xp = int(opt.get("xp"))
	## 应同时有全价 NEW_CARD(2) 与 UPGRADE(2-0=2)。
	if not kinds.has(XpCostCalculator.KIND_NEW_CARD) or not kinds.has(XpCostCalculator.KIND_UPGRADE):
		return false
	if upgrade_xp != 2 or new_xp != 2:
		return false
	## 提交 upgrade：移除 gun0，加入 gun2，扣 2 XP。
	var up_opt: Dictionary = {}
	for opt in offer.get("options", []):
		if opt.get("kind") == XpCostCalculator.KIND_UPGRADE:
			up_opt = opt
			break
	var committed := InvestigatorCampaignSystem.commit_purchase(rec, up_opt)
	if not bool(committed.get("ok", false)):
		return false
	if rec.unspent_xp != 8:
		return false
	var has_gun2 := false
	var has_gun0 := false
	for c in rec.deck:
		if String(c.definition_id) == "gun2":
			has_gun2 = true
		if String(c.definition_id) == "gun0":
			has_gun0 = true
	return has_gun2 and not has_gun0


static func test_xp02_exceptional_cost_and_copy() -> bool:
	var rec := _roland_record(5)
	_reg(
		"obol",
		{
			"card_type": "asset",
			"title": "Obol",
			"level": 1,
			"faction_code": "neutral",
			"exceptional": true,
			"keywords": [&"exceptional"],
			"permanent": true,
		}
	)
	InvestigatorCampaignSystem.begin_experience_window(rec, 5)
	var offer := InvestigatorCampaignSystem.quote_purchase(rec, &"obol")
	if not bool(offer.get("ok", false)):
		return false
	var opt: Dictionary = offer["options"][0]
	## 2 * level 1 = 2；permanent 不占 size。
	if int(opt.get("xp")) != 2:
		return false
	var c1 := InvestigatorCampaignSystem.commit_purchase(rec, opt)
	if not bool(c1.get("ok", false)):
		return false
	## 第二份 Exceptional 同名应无选项 / 提交失败。
	var offer2 := InvestigatorCampaignSystem.quote_purchase(rec, &"obol")
	for o2 in offer2.get("options", []):
		if o2.get("kind") == XpCostCalculator.KIND_NEW_CARD:
			return false
	return true


static func test_xp03_dtrh_modifier() -> bool:
	var rec := _roland_record(5)
	_reg("sk0", {"card_type": "event", "title": "Search", "level": 0, "faction_code": "seeker"})
	_reg("sk1", {"card_type": "event", "title": "Search", "level": 1, "faction_code": "seeker"})
	rec.deck.append(DeckCardView.from_registry(&"sk0"))
	var mods: Array = [XpCostCalculator.modifier_dtrh(2)]
	InvestigatorCampaignSystem.begin_experience_window(rec, 10, mods)
	var offer := InvestigatorCampaignSystem.quote_purchase(rec, &"sk1")
	var new_xp := -1
	var up_xp := -1
	for opt in offer.get("options", []):
		if opt.get("kind") == XpCostCalculator.KIND_NEW_CARD:
			new_xp = int(opt.get("xp"))
		if opt.get("kind") == XpCostCalculator.KIND_UPGRADE:
			up_xp = int(opt.get("xp"))
	## 购新卡 base max(1,1)=1 + DtRH +1 → 2；升级 base 1 −1 → 0。
	return new_xp == 2 and up_xp == 0


static func test_xp04_list_accessible() -> bool:
	var rec := _roland_record(5)
	_reg("g5", {"card_type": "asset", "title": "G5", "level": 5, "faction_code": "guardian"})
	_reg("s3", {"card_type": "asset", "title": "S3", "level": 3, "faction_code": "seeker"})
	InvestigatorCampaignSystem.begin_experience_window(rec, 0)
	var pool: Array = [&"g5", &"s3"]
	var acc := InvestigatorCampaignSystem.list_accessible(rec, pool)
	return acc.has(&"g5") and not acc.has(&"s3")


static func test_xp05_interlude_shell() -> bool:
	var rec := _roland_record(5)
	InvestigatorCampaignSystem.begin_experience_window(rec, 3)
	if not rec.experience_window_open or rec.unspent_xp != 3:
		return false
	InvestigatorCampaignSystem.end_experience_window(rec)
	return (not rec.experience_window_open) and rec.unspent_xp == 3


static func test_xp06_myriad_copy_limit() -> bool:
	var profile := DeckbuildingProfile.from_options(
		[{"faction": ["guardian", "neutral"], "level": {"min": 0, "max": 5}}],
		{},
		3,
		&"inv"
	)
	var cards: Array = []
	for i in 3:
		cards.append(
			DeckCardView.from_definition_dict(
				{
					"definition_id": "m%d" % i,
					"title": "Swarm",
					"level": 0,
					"faction_code": "guardian",
					"myriad": true,
					"card_type": "asset",
				},
				StringName("m%d" % i)
			)
		)
	var ok3 := DeckLegality.validate_deck(cards, profile)
	if not bool(ok3.get("ok", false)):
		return false
	cards.append(
		DeckCardView.from_definition_dict(
			{
				"definition_id": "m3",
				"title": "Swarm",
				"level": 0,
				"faction_code": "guardian",
				"myriad": true,
				"card_type": "asset",
			},
			&"m3"
		)
	)
	## size 也会失败；至少 copy_limit 应出现。
	var bad := DeckLegality.validate_deck(cards, profile)
	var errs: Array = bad.get("errors", [])
	var has_copy := false
	for e in errs:
		if str(e).begins_with("copy_limit"):
			has_copy = true
	return has_copy
