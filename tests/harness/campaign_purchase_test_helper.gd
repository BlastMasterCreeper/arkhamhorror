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
	InvestigatorCampaignSystem.begin_experience_window(rec, 10, {"dtrh": 2})
	var offer := InvestigatorCampaignSystem.quote_purchase(rec, &"sk1")
	var new_xp := -1
	var up_xp := -1
	for opt in offer.get("options", []):
		if opt.get("kind") == XpCostCalculator.KIND_NEW_CARD:
			new_xp = int(opt.get("xp"))
		if opt.get("kind") == XpCostCalculator.KIND_UPGRADE:
			up_xp = int(opt.get("xp"))
	## 购新卡 base max(1,1)=1 + DtRH +1 → 2；升级 base 1 −1 → 0。
	## 再 quote 一次：预览不吞次数，升级仍为 0。
	var offer2 := InvestigatorCampaignSystem.quote_purchase(rec, &"sk1")
	var up2 := -1
	for opt in offer2.get("options", []):
		if opt.get("kind") == XpCostCalculator.KIND_UPGRADE:
			up2 = int(opt.get("xp"))
	return new_xp == 2 and up_xp == 0 and up2 == 0


static func test_xp09_arcane_research_spell_only() -> bool:
	## Arcane Research：仅源卡带 Spell 的升级 −1；购新 Spell 不减。
	var rec := _roland_record(5)
	_reg(
		"sp0g",
		{
			"card_type": "event",
			"title": "Shrivelling",
			"level": 0,
			"faction_code": "guardian",
			"traits": ["spell"],
		}
	)
	_reg(
		"sp2g",
		{
			"card_type": "event",
			"title": "Shrivelling",
			"level": 2,
			"faction_code": "guardian",
			"traits": ["spell"],
		}
	)
	_reg("gun0", {"card_type": "asset", "title": "Gun", "level": 0, "faction_code": "guardian"})
	_reg("gun2", {"card_type": "asset", "title": "Gun", "level": 2, "faction_code": "guardian"})
	rec.deck.append(DeckCardView.from_registry(&"sp0g"))
	rec.deck.append(DeckCardView.from_registry(&"gun0"))
	InvestigatorCampaignSystem.begin_experience_window(rec, 10, {"arcane_research": true})
	var spell_offer := InvestigatorCampaignSystem.quote_purchase(rec, &"sp2g")
	var gun_offer := InvestigatorCampaignSystem.quote_purchase(rec, &"gun2")
	var spell_up := -1
	var spell_new := -1
	for opt in spell_offer.get("options", []):
		if opt.get("kind") == XpCostCalculator.KIND_UPGRADE:
			spell_up = int(opt.get("xp"))
		if opt.get("kind") == XpCostCalculator.KIND_NEW_CARD:
			spell_new = int(opt.get("xp"))
	var gun_up := -1
	for opt in gun_offer.get("options", []):
		if opt.get("kind") == XpCostCalculator.KIND_UPGRADE:
			gun_up = int(opt.get("xp"))
	## Spell 升级 2−0=2 −1 AR → 1；购新 Spell 不减 → 2；Gun 升级无 AR → 2。
	return spell_up == 1 and spell_new == 2 and gun_up == 2


static func test_xp10_pelt_and_size_refill() -> bool:
	## Pelt：下一次购新 −1；SIZE_REFILL：undersize L0 = 0 且 DtRH 不加价。
	var rec := _roland_record(5)
	## 人为缩到 3 张（exile 后 undersize）。
	while rec.deck.size() > 3:
		rec.deck.pop_back()
	_reg("l0", {"card_type": "asset", "title": "L0", "level": 0, "faction_code": "guardian"})
	_reg("l1", {"card_type": "asset", "title": "L1Card", "level": 1, "faction_code": "guardian"})
	InvestigatorCampaignSystem.begin_experience_window(
		rec, 5, {"dtrh": 2, "pelt": 1}
	)
	var refill_offer := InvestigatorCampaignSystem.quote_purchase(rec, &"l0")
	var has_refill := false
	for opt in refill_offer.get("options", []):
		if opt.get("kind") == XpCostCalculator.KIND_SIZE_REFILL and int(opt.get("xp")) == 0:
			has_refill = true
			var c := InvestigatorCampaignSystem.commit_purchase(rec, opt)
			if not bool(c.get("ok", false)):
				return false
	if not has_refill:
		return false
	## 仍可能 undersize；再补到满后再测 Pelt。
	while _count_size(rec) < 5:
		var o2 := InvestigatorCampaignSystem.quote_purchase(rec, &"l0")
		var done := false
		for opt in o2.get("options", []):
			if opt.get("kind") == XpCostCalculator.KIND_SIZE_REFILL:
				InvestigatorCampaignSystem.commit_purchase(rec, opt)
				done = true
				break
		if not done:
			break
	## 满尺寸后购 L1：base 1 + DtRH 1 − Pelt 1 → 1。
	var offer_l1 := InvestigatorCampaignSystem.quote_purchase(rec, &"l1")
	var xp_l1 := -1
	for opt in offer_l1.get("options", []):
		if opt.get("kind") == XpCostCalculator.KIND_NEW_CARD:
			xp_l1 = int(opt.get("xp"))
	return xp_l1 == 1


static func _count_size(rec: CampaignInvestigatorRecord) -> int:
	return rec.counted_deck_size()


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


static func test_xp08_count_vd_and_personal_bonus() -> bool:
	## 02111 式：Victory 进共享池；06160 式：个人 When earning +；Dead Ends 式：fewer −。
	var rec_a := _roland_record(5)
	var rec_b := _roland_record(5)
	rec_a.unspent_xp = 2
	rec_b.unspent_xp = 0
	rec_a.queue_resolution_xp_bonus(1, &"06160")
	var tall_a := InvestigatorCampaignSystem.count_and_begin_experience_window(rec_a, 3, 0)
	var tall_b := InvestigatorCampaignSystem.count_and_begin_experience_window(rec_b, 3, 0)
	if int(tall_a.get("personal_delta", -1)) != 1:
		return false
	if int(tall_a.get("earned_this_scenario", -1)) != 4:
		return false
	if int(tall_b.get("earned_this_scenario", -1)) != 3:
		return false
	if rec_a.unspent_xp != 6 or rec_b.unspent_xp != 3:
		return false
	## Dead Ends：VD 1 − 2 fewer → raw −1 → earned 0；prior 5 不动。
	var rec_d := _roland_record(5)
	rec_d.unspent_xp = 5
	rec_d.queue_resolution_xp_penalty(2, &"12006")
	var tall_d := InvestigatorCampaignSystem.count_and_begin_experience_window(rec_d, 1, 0)
	if int(tall_d.get("personal_delta", 0)) != -2:
		return false
	if int(tall_d.get("raw_earned_this_scenario", 0)) != -1:
		return false
	if int(tall_d.get("earned_this_scenario", -1)) != 0:
		return false
	if rec_d.unspent_xp != 5:
		return false
	## Obol +2。
	var rec_c := _roland_record(5)
	rec_c.unspent_xp = 0
	var tall_c := InvestigatorCampaignSystem.count_and_begin_experience_window(
		rec_c, 1, 0, [], [ExperienceCount.delta(2, &"03308")]
	)
	return int(tall_c.get("earned_this_scenario", -1)) == 3 and rec_c.unspent_xp == 3


static func test_xp07_size_exempt_purchase_no_remove() -> bool:
	## Permanent / Signature 购入不要求 −1；Myriad 计入 size 须 −1。
	var rec := _roland_record(5)
	## deck 已满 size（4 filler + 1 gun 稍后）；先清到 5 张 filler。
	rec.deck.clear()
	for i in 5:
		var fid := "sz_%d" % i
		_reg(fid, {"card_type": "asset", "title": "Sz%d" % i, "level": 0, "faction_code": "guardian"})
		rec.deck.append(DeckCardView.from_registry(StringName(fid)))
	_reg("perm_p", {
		"card_type": "asset", "title": "PermP", "level": 0, "faction_code": "guardian",
		"permanent": true,
	})
	_reg("sig_p", {
		"card_type": "asset", "title": "SigP", "level": 0, "faction_code": "guardian",
		"ignore_deckbuilding": true, "signature": true,
	})
	_reg("myr_p", {
		"card_type": "asset", "title": "MyrP", "level": 0, "faction_code": "guardian",
		"myriad": true,
	})
	InvestigatorCampaignSystem.begin_experience_window(rec, 10)
	var perm_offer := InvestigatorCampaignSystem.quote_purchase(rec, &"perm_p")
	var perm_opt: Dictionary = perm_offer["options"][0]
	var c_perm := InvestigatorCampaignSystem.commit_purchase(rec, perm_opt)
	if not bool(c_perm.get("ok", false)):
		return false
	if rec.counted_deck_size() != 5:
		return false
	var sig_view := DeckCardView.from_registry(&"sig_p")
	rec.add_bearer_card(sig_view)  ## 或 Signature：不计 size
	if rec.counted_deck_size() != 5:
		return false
	## Myriad 计入 → 满 size 时无 remove 应失败。
	var myr_offer := InvestigatorCampaignSystem.quote_purchase(rec, &"myr_p")
	if not bool(myr_offer.get("ok", false)):
		return false
	var myr_opt: Dictionary = myr_offer["options"][0]
	var c_myr := InvestigatorCampaignSystem.commit_purchase(rec, myr_opt)
	return not bool(c_myr.get("ok", true))


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
