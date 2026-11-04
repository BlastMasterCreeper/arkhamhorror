class_name InvestigatorCampaignSystem
extends RefCounted

## Experience 购卡窗：报价 / 提交 / 候选目录 / 幕间入口。
## Customizable sheet 延后（P6c）。
## 选定调查员后的附带构筑选型见 `DeckbuildingChoiceFlow` / `bind_investigator_choices`。


## 选定调查员后列出附带玩家选择（副职阶 / 特性 / 尺寸…）。
static func list_investigator_choices(
	investigator_def: Dictionary,
	answered: Dictionary = {}
) -> Array:
	return DeckbuildingChoiceFlow.list_choices(investigator_def, answered)


## 绑定调查员定义 + 应用附带选择 → 冻结 Profile。
static func bind_investigator_choices(
	record: CampaignInvestigatorRecord,
	investigator_def: Dictionary,
	answers: Dictionary = {}
) -> Dictionary:
	return DeckbuildingChoiceFlow.bind_investigator(record, investigator_def, answers)


## —— 剧本开局（见 CampaignSetup）——

static func start_campaign(
	campaign_id: StringName = &"campaign",
	difficulty: StringName = &"easy_standard",
	flags: Dictionary = {}
) -> CampaignState:
	return CampaignSetup.start_campaign(campaign_id, difficulty, flags)


static func select_investigator(
	state: CampaignState,
	definition_id: StringName,
	choices: Dictionary = {},
	player_slot: StringName = &""
) -> Dictionary:
	return CampaignSetup.select_investigator(state, definition_id, choices, player_slot)


static func replace_investigator(
	state: CampaignState,
	old_investigator_id: StringName,
	new_definition_id: StringName,
	choices: Dictionary = {}
) -> Dictionary:
	return CampaignSetup.replace_investigator(
		state, old_investigator_id, new_definition_id, choices
	)


static func set_opening_deck(
	state: CampaignState,
	record: CampaignInvestigatorRecord,
	player_card_ids: Array,
	opts: Dictionary = {}
) -> Dictionary:
	return CampaignSetup.set_opening_deck(state, record, player_card_ids, opts)


static func validate_deck(record: CampaignInvestigatorRecord) -> Dictionary:
	return CampaignSetup.validate_opening_deck(record)


static func prepare_scenario(
	state: CampaignState,
	scenario_id: StringName,
	base_config: RulesConfig = null
) -> Dictionary:
	return CampaignSetup.prepare_scenario(state, scenario_id, base_config)


static func materialize_deck_into_context(
	ctx: GameContext,
	record: CampaignInvestigatorRecord,
	inv_id: StringName = &"",
	location_tag: StringName = &"test_loc"
) -> Dictionary:
	return CampaignSetup.materialize_deck_into_context(ctx, record, inv_id, location_tag)


static func begin_scenario(
	state: CampaignState,
	scenario_id: StringName,
	opts: Dictionary = {}
) -> Dictionary:
	return CampaignSetup.begin_scenario(state, scenario_id, opts)


## 幕间步骤 1：Count XP 后打开购卡窗。
## 可直接传 earned_xp；或传 victory_points + guide_delta，并消费 record 上排队的个人 bonus。
## modifiers 可为已构建 Array，或 build_modifiers 规格 Dictionary（dtrh/arcane_research/pelt）。
static func begin_experience_window(
	record: CampaignInvestigatorRecord,
	earned_xp: int,
	modifiers: Variant = []
) -> void:
	if record == null:
		return
	record.unspent_xp += maxi(0, earned_xp)
	if modifiers is Dictionary:
		record.xp_modifiers = XpCostCalculator.build_modifiers(modifiers as Dictionary)
	elif modifiers is Array:
		record.xp_modifiers = (modifiers as Array).duplicate()
	else:
		record.xp_modifiers = []
	record.experience_window_open = true


## Count → begin：VD（含 02111 等 Victory 牌）+ guide ± + 个人 bonus（06160 / Obol…）。
static func count_and_begin_experience_window(
	record: CampaignInvestigatorRecord,
	victory_points: int,
	guide_delta: int = 0,
	modifiers: Array = [],
	extra_personal_bonuses: Array = []
) -> Dictionary:
	if record == null:
		return {"ok": false, "reason": "missing_record"}
	var personal: Array = record.take_resolution_xp_bonuses()
	for b in extra_personal_bonuses:
		personal.append(b)
	var tallied := ExperienceCount.tally(
		victory_points, guide_delta, personal, record.unspent_xp
	)
	var earned := int(tallied.get("earned_this_scenario", 0))
	begin_experience_window(record, earned, modifiers)
	tallied["ok"] = true
	tallied["unspent_xp"] = record.unspent_xp
	return tallied


static func end_experience_window(record: CampaignInvestigatorRecord) -> void:
	if record == null:
		return
	record.experience_window_open = false
	record.xp_modifiers.clear()


## 返回可购印刷品 definition_id 列表（player cardtype；已过 Profile 准入 dry-run）。
static func list_accessible(
	record: CampaignInvestigatorRecord,
	pool: Array = []
) -> Array[StringName]:
	var out: Array[StringName] = []
	if record == null:
		return out
	var profile := record.profile()
	var ids: Array = pool
	if ids.is_empty():
		ids = CardRegistry.all_definition_ids()
	for id_v in ids:
		var id := StringName(str(id_v))
		var view := DeckCardView.from_registry(id)
		if view.definition_id == &"":
			continue
		if not _is_purchase_cardtype(view.card_type):
			continue
		var check := DeckLegality.can_add_card(record.deck_as_array(), view, profile)
		if bool(check.get("ok", false)):
			out.append(id)
	return out


## 选定目标印刷品 → Offer：{ ok, options: [{ kind, xp, target, source?, remove_ids }] }
static func quote_purchase(
	record: CampaignInvestigatorRecord,
	target_def_id: StringName
) -> Dictionary:
	if record == null:
		return {"ok": false, "reason": "missing_record", "options": []}
	if not record.experience_window_open:
		return {"ok": false, "reason": "window_closed", "options": []}
	var target := DeckCardView.from_registry(target_def_id)
	if target.definition_id == &"":
		## 允许测试直接用已注册数据；若空则失败。
		return {"ok": false, "reason": "unknown_card", "options": []}
	var profile := record.profile()
	var options: Array = []
	var mods: Array = record.xp_modifiers

	var undersized := _count_for_size(record) < profile.deck_size

	## FAQ 1.18 SIZE_REFILL：undersize 时 L0 补牌 0 XP（DtRH 不加价）。
	if (
		undersized
		and target.level == 0
		and target.counts_toward_deck_size()
		and not (target.exceptional and _title_count(record, target.title) >= 1)
	):
		var refill_check := DeckLegality.can_add_card(record.deck_as_array(), target, profile)
		if bool(refill_check.get("ok", false)):
			options.append(
				{
					"kind": XpCostCalculator.KIND_SIZE_REFILL,
					"xp": 0,
					"target": target,
					"source": null,
					"remove_ids": [],
					"affordable": true,
					"size_refill": true,
				}
			)

	## NEW_CARD（满尺寸或非 L0 refill 路径；报价不消耗修饰器次数）。
	var new_check := DeckLegality.can_add_card(record.deck_as_array(), target, profile)
	if bool(new_check.get("ok", false)):
		if target.exceptional and _title_count(record, target.title) >= 1:
			pass
		elif undersized and target.level == 0 and target.counts_toward_deck_size():
			## 与 SIZE_REFILL 重复时不另报全价 NEW_CARD。
			pass
		else:
			var xp_new := XpCostCalculator.cost_new_card(target, mods, false)
			options.append(
				{
					"kind": XpCostCalculator.KIND_NEW_CARD,
					"xp": xp_new,
					"target": target,
					"source": null,
					"remove_ids": [],
					"affordable": xp_new <= record.unspent_xp,
				}
			)

	## UPGRADE：同 title、更低 level 源。
	var seen_levels: Dictionary = {}
	for src in record.deck:
		if src.title.to_lower() != target.title.to_lower():
			continue
		if src.level >= target.level:
			continue
		var lk := src.level
		if seen_levels.has(lk):
			continue
		seen_levels[lk] = true
		var remove: Array = [src]
		var up_check := DeckLegality.can_add_card(
			record.deck_as_array(), target, profile, remove
		)
		if not bool(up_check.get("ok", false)):
			continue
		var xp_up := XpCostCalculator.cost_upgrade(target, src, mods, false)
		options.append(
			{
				"kind": XpCostCalculator.KIND_UPGRADE,
				"xp": xp_up,
				"target": target,
				"source": src,
				"remove_ids": [src.definition_id],
				"affordable": xp_up <= record.unspent_xp,
			}
		)

	return {"ok": not options.is_empty(), "reason": "" if not options.is_empty() else "no_options", "options": options}


## choice: Offer 中的一条（或 { kind, target_def, source_def?, xp }）。
static func commit_purchase(record: CampaignInvestigatorRecord, choice: Dictionary) -> Dictionary:
	if record == null or not record.experience_window_open:
		return {"ok": false, "reason": "window_closed"}
	var kind: StringName = choice.get("kind", &"")
	var target: DeckCardView = choice.get("target")
	if target == null and choice.has("target_def"):
		target = DeckCardView.from_registry(StringName(str(choice.get("target_def"))))
	if target == null:
		return {"ok": false, "reason": "missing_target"}
	var source: DeckCardView = choice.get("source")
	var mods: Array = record.xp_modifiers
	## 提交时重算并消耗修饰器次数（不以报价快照为准，防重复报价吞次数）。
	var xp := 0
	if kind == XpCostCalculator.KIND_SIZE_REFILL or bool(choice.get("size_refill", false)):
		kind = XpCostCalculator.KIND_SIZE_REFILL
		xp = XpCostCalculator.cost_size_refill(target)
		if xp < 0:
			return {"ok": false, "reason": "refill_requires_level_0"}
		if _count_for_size(record) >= record.profile().deck_size:
			return {"ok": false, "reason": "deck_not_undersized"}
	elif kind == XpCostCalculator.KIND_UPGRADE and source != null:
		xp = XpCostCalculator.cost_upgrade(target, source, mods, true)
	else:
		xp = XpCostCalculator.cost_new_card(target, mods, true)
		kind = XpCostCalculator.KIND_NEW_CARD
	if xp > record.unspent_xp:
		return {"ok": false, "reason": "insufficient_xp"}

	var profile := record.profile()
	var remove: Array = []
	if kind == XpCostCalculator.KIND_UPGRADE and source != null:
		remove.append(source)
	var check := DeckLegality.can_add_card(record.deck_as_array(), target, profile, remove)
	if not bool(check.get("ok", false)):
		return {"ok": false, "reason": str(check.get("reason", "illegal"))}

	if kind == XpCostCalculator.KIND_UPGRADE and source != null:
		_remove_one(record, source.definition_id)
	elif kind == XpCostCalculator.KIND_NEW_CARD and target.counts_toward_deck_size():
		## 维持尺寸：仅对计入 size 的卡要求 +1/−1；Permanent / Signature / 弱点 / Bearer 免。
		var remove_ids: Array = choice.get("remove_ids", [])
		if remove_ids.is_empty():
			var counted := _count_for_size(record)
			if counted + 1 > profile.deck_size:
				return {"ok": false, "reason": "need_remove_for_size"}
		else:
			for rid in remove_ids:
				_remove_one(record, StringName(str(rid)))
	## SIZE_REFILL：undersize 补入，不移除。

	record.deck.append(target)
	## Myriad：购一张可再 +≤2 同 level 0 XP 副本；**仍计入 size**，每张额外副本也须维持尺寸。
	if target.myriad and bool(choice.get("myriad_extra", false)):
		var extras := mini(2, int(choice.get("myriad_extra_count", 2)))
		var extra_removes: Array = choice.get("myriad_extra_remove_ids", [])
		var extra_ri := 0
		for _i in extras:
			if _title_count(record, target.title) >= 3:
				break
			if target.counts_toward_deck_size():
				if extra_ri < extra_removes.size():
					_remove_one(record, StringName(str(extra_removes[extra_ri])))
					extra_ri += 1
				elif _count_for_size(record) + 1 > profile.deck_size:
					return {"ok": false, "reason": "need_remove_for_myriad_extra"}
			record.deck.append(DeckCardView.from_definition_dict({
				"definition_id": String(target.definition_id),
				"title": target.title,
				"level": target.level,
				"card_type": String(target.card_type),
				"factions": target.factions.duplicate(),
				"traits": target.traits.duplicate(),
				"myriad": true,
			}, target.definition_id))

	record.unspent_xp -= xp
	return {"ok": true, "kind": kind, "xp_spent": xp, "unspent_xp": record.unspent_xp}


static func _is_purchase_cardtype(card_type: StringName) -> bool:
	var t := String(card_type)
	return t in ["asset", "event", "skill"]


static func _title_count(record: CampaignInvestigatorRecord, title: String) -> int:
	var n := 0
	var key := title.to_lower()
	for c in record.deck:
		if c.title.to_lower() == key:
			n += 1
	return n


static func _count_for_size(record: CampaignInvestigatorRecord) -> int:
	var n := 0
	for c in record.deck:
		if c.counts_toward_deck_size():
			n += 1
	return n


static func _remove_one(record: CampaignInvestigatorRecord, def_id: StringName) -> bool:
	for i in record.deck.size():
		if record.deck[i].definition_id == def_id:
			record.deck.remove_at(i)
			return true
	return false
