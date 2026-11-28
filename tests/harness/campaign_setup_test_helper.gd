class_name CampaignSetupTestHelper
extends RefCounted

## CAMP-* 剧本开局竖切：选人 / 换人 / 初始牌库 / 冒险接线。


static func _reg_inv(id: String, opts: Dictionary = {}) -> void:
	var d := {
		"definition_id": id,
		"card_type": "investigator",
		"title": opts.get("title", id),
		"deck_options": opts.get(
			"deck_options",
			[{"faction": ["guardian", "neutral"], "level": {"min": 0, "max": 5}}]
		),
		"deck_requirements": opts.get(
			"deck_requirements",
			{"size": 5, "card": {}, "random": [{"target": "subtype", "value": "basicweakness"}]}
		),
	}
	CardRegistry.register_definition(StringName(id), d)


static func _reg_card(id: String, opts: Dictionary = {}) -> void:
	var d := {
		"definition_id": id,
		"card_type": opts.get("card_type", "asset"),
		"title": opts.get("title", id),
		"level": opts.get("level", 0),
		"faction_code": opts.get("faction_code", "guardian"),
		"is_weakness": opts.get("is_weakness", false),
		"subtype_code": opts.get("subtype_code", ""),
		"ignore_deckbuilding": opts.get("ignore_deckbuilding", false),
		"permanent": opts.get("permanent", false),
	}
	CardRegistry.register_definition(StringName(id), d)


static func test_camp01_select_and_opening_deck() -> bool:
	_reg_inv(
		"inv_camp_a",
		{
			"title": "CampA",
			"deck_requirements": {
				"size": 5,
				"card": {"sig_a": {"sig_a": "sig_a"}},
				"random": [{"target": "subtype", "value": "basicweakness"}],
			},
		}
	)
	_reg_card("sig_a", {"title": "SigA", "ignore_deckbuilding": true, "signature": true})
	_reg_card("bw_a", {"title": "BWa", "is_weakness": true, "subtype_code": "basicweakness"})
	_reg_card("bw_b", {"title": "BWb", "is_weakness": true, "subtype_code": "basicweakness"})
	var player_ids: Array = []
	for i in 5:
		var cid := "pc_a_%d" % i
		_reg_card(cid, {"title": "P%d" % i, "faction_code": "guardian"})
		player_ids.append(cid)
	var state := InvestigatorCampaignSystem.start_campaign(&"test_camp", &"easy_standard")
	var sel := InvestigatorCampaignSystem.select_investigator(state, &"inv_camp_a", {})
	if not bool(sel.get("ok", false)):
		return false
	var rec: CampaignInvestigatorRecord = sel["record"]
	## 署名已装。
	var has_sig := false
	for c in rec.deck:
		if String(c.definition_id) == "sig_a":
			has_sig = true
	if not has_sig:
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var built := InvestigatorCampaignSystem.set_opening_deck(
		state, rec, player_ids, {"rng": rng, "basic_weakness_pool": [&"bw_a", &"bw_b"]}
	)
	if not bool(built.get("ok", false)):
		return false
	if String(built.get("basic_weakness", "")) == "":
		return false
	if rec.counted_deck_size() != 5:
		return false
	## Starter 旗标跳过 BW。
	var state2 := InvestigatorCampaignSystem.start_campaign(
		&"starter", &"easy_standard", {"use_starter_deck_no_random_weakness": true}
	)
	var sel2 := InvestigatorCampaignSystem.select_investigator(state2, &"inv_camp_a", {})
	var rec2: CampaignInvestigatorRecord = sel2["record"]
	var built2 := InvestigatorCampaignSystem.set_opening_deck(state2, rec2, player_ids, {})
	return bool(built2.get("ok", false)) and String(built2.get("basic_weakness", "")) == ""


static func test_camp02_replace_investigator() -> bool:
	_reg_inv("inv_old", {"title": "Old"})
	_reg_inv("inv_new", {"title": "New", "deck_requirements": {"size": 5, "card": {}, "random": []}})
	for i in 5:
		_reg_card("rn_%d" % i, {"title": "R%d" % i})
	var state := InvestigatorCampaignSystem.start_campaign(&"rep")
	var sel := InvestigatorCampaignSystem.select_investigator(state, &"inv_old", {}, &"p1")
	if not bool(sel.get("ok", false)):
		return false
	var rep := InvestigatorCampaignSystem.replace_investigator(state, &"p1", &"inv_new", {})
	if not bool(rep.get("ok", false)):
		return false
	if state.investigators.size() != 1:
		return false
	var rec: CampaignInvestigatorRecord = state.investigators[0]
	if rec.definition_id != &"inv_new":
		return false
	if rec.investigator_id != &"p1":
		return false
	## 旧牌组不继承。
	return rec.deck.is_empty() or rec.counted_deck_size() == 0


static func test_camp03_prepare_scenario() -> bool:
	var state := InvestigatorCampaignSystem.start_campaign(&"sf", &"hard_expert")
	var prep := InvestigatorCampaignSystem.prepare_scenario(
		state, ScenarioSetupCatalog.SPREADING_FLAMES
	)
	if not bool(prep.get("ok", false)):
		return false
	var cfg: RulesConfig = prep["config"]
	if cfg.setup_scenario_id != ScenarioSetupCatalog.SPREADING_FLAMES:
		return false
	if cfg.chaos_difficulty != &"hard_expert":
		return false
	var layout: Dictionary = prep["layout"]
	if str(layout.get("starting_location", "")) == "":
		return false
	if state.current_scenario_id != ScenarioSetupCatalog.SPREADING_FLAMES:
		return false
	return state.log.has_note("prepare_scenario:spreading_flames")


static func test_camp04_unresolved_choice_blocks() -> bool:
	_reg_inv(
		"inv_choice",
		{
			"title": "Chooser",
			"deck_options": [
				{"faction": ["rogue", "neutral"], "level": {"min": 0, "max": 5}},
				{
					"name": "Secondary Class",
					"faction_select": ["guardian", "seeker", "survivor"],
					"level": {"min": 0, "max": 1},
					"type": ["event", "skill"],
					"limit": 10,
				},
			],
			"deck_requirements": {"size": 5, "card": {}, "random": []},
		}
	)
	var state := InvestigatorCampaignSystem.start_campaign(&"ch")
	var bad := InvestigatorCampaignSystem.select_investigator(state, &"inv_choice", {})
	if bool(bad.get("ok", true)):
		return false
	var good := InvestigatorCampaignSystem.select_investigator(
		state, &"inv_choice", {"Secondary Class": "survivor"}, &"p2"
	)
	return bool(good.get("ok", false)) and state.investigators.size() == 1


static func test_camp05_begin_scenario_e2e() -> bool:
	_reg_inv(
		"inv_camp_e2e",
		{
			"title": "E2E",
			"deck_requirements": {
				"size": 8,
				"card": {"sig_e2e": {"sig_e2e": "sig_e2e"}},
				"random": [],
			},
		}
	)
	_reg_card("sig_e2e", {"title": "SigE2E", "ignore_deckbuilding": true})
	var player_ids: Array = []
	for i in 8:
		var cid := "pc_e2e_%d" % i
		_reg_card(cid, {"title": "E%d" % i, "faction_code": "guardian"})
		player_ids.append(cid)
	var state := InvestigatorCampaignSystem.start_campaign(&"e2e", &"easy_standard")
	var sel := InvestigatorCampaignSystem.select_investigator(state, &"inv_camp_e2e", {}, &"p1")
	if not bool(sel.get("ok", false)):
		return false
	var rec: CampaignInvestigatorRecord = sel["record"]
	rec.physical_trauma = 1
	rec.mental_trauma = 0
	var built := InvestigatorCampaignSystem.set_opening_deck(
		state, rec, player_ids, {"skip_basic_weakness": true}
	)
	if not bool(built.get("ok", false)):
		return false
	var begun := InvestigatorCampaignSystem.begin_scenario(
		state,
		ScenarioSetupCatalog.SPREADING_FLAMES,
		{"seed": 7, "skip_mulligan": true}
	)
	if not bool(begun.get("ok", false)):
		return false
	var ctx: GameContext = begun["ctx"]
	if ctx == null or ctx.state == null:
		return false
	if not ctx.state.scenario_layout_installed:
		return false
	if ctx.state.current_agenda_card_id == &"" or ctx.state.current_act_card_id == &"":
		return false
	if ctx.state.scenario_reference_card_id == &"":
		return false
	if not ctx.state.setup_game_begins_resolved:
		return false
	## SETUP_06：easy_standard → standard 袋 = 10 数字 + 7 符号。
	if not ctx.state.setup_chaos_bag_assembled:
		return false
	if ctx.state.chaos_bag.tokens.size() != 17:
		return false
	if state.chaos_bag_snapshot.size() != 17:
		return false
	var inv := ctx.state.registry.get_investigator(&"p1")
	if inv == null:
		return false
	## SETUP_07 起始 5 资源；SETUP_08 起手 5；SETUP_02 创伤 1 伤。
	if inv.resource_pool < 5:
		return false
	if inv.hand.size() != 5:
		return false
	if inv.damage_taken != 1:
		return false
	if inv.location_tag == &"":
		return false
	return state.log.has_note("begin_scenario:spreading_flames")


static func test_bag01_brethren_sizes() -> bool:
	var easy := ChaosBagCatalog.build_tokens(ChaosBagCatalog.BRETHREN_OF_ASH, &"easy")
	var std := ChaosBagCatalog.build_tokens(ChaosBagCatalog.BRETHREN_OF_ASH, &"standard")
	var hard := ChaosBagCatalog.build_tokens(ChaosBagCatalog.BRETHREN_OF_ASH, &"hard")
	var expert := ChaosBagCatalog.build_tokens(ChaosBagCatalog.BRETHREN_OF_ASH, &"expert")
	if easy.size() != 17 or std.size() != 17:
		return false
	if hard.size() != 18 or expert.size() != 19:
		return false
	## 符号：skull×2 + cultist + tablet + elder_thing + autofail + eldersign。
	var skulls := 0
	for t in std:
		if t.kind == AhcEnums.ChaosTokenKind.SKULL:
			skulls += 1
	if skulls != 2:
		return false
	if ChaosBagCatalog.reference_band(&"easy") != &"easy_standard":
		return false
	if ChaosBagCatalog.reference_band(&"expert") != &"hard_expert":
		return false
	if ChaosBagCatalog.normalize_bag_difficulty(&"easy_standard") != &"standard":
		return false
	return ChaosBagCatalog.bag_id_for_scenario(ScenarioSetupCatalog.SPREADING_FLAMES) == ChaosBagCatalog.BRETHREN_OF_ASH


static func test_bag02_snapshot_persists_across_scenarios() -> bool:
	_reg_inv(
		"inv_bag_persist",
		{"title": "BagP", "deck_requirements": {"size": 8, "card": {}, "random": []}}
	)
	var player_ids: Array = []
	for i in 8:
		var cid := "pc_bag_%d" % i
		_reg_card(cid, {"faction_code": "guardian"})
		player_ids.append(cid)
	var state := InvestigatorCampaignSystem.start_campaign(
		&"brethren_of_ash", &"hard", {}
	)
	var sel := InvestigatorCampaignSystem.select_investigator(state, &"inv_bag_persist", {}, &"p1")
	if not bool(sel.get("ok", false)):
		return false
	var built := InvestigatorCampaignSystem.set_opening_deck(
		state, sel["record"], player_ids, {"skip_basic_weakness": true}
	)
	if not bool(built.get("ok", false)):
		return false
	var first := InvestigatorCampaignSystem.begin_scenario(
		state, ScenarioSetupCatalog.SPREADING_FLAMES, {"seed": 3, "skip_mulligan": true}
	)
	if not bool(first.get("ok", false)):
		return false
	if state.chaos_bag_snapshot.size() != 18:
		return false
	## 模拟下场：清空装配旗，恢复快照而非重算。
	var ctx2 := GameBootstrap.create(9, first["config"])
	ctx2.state.campaign_state = state
	ctx2.config.setup_run_player_steps = false
	var assembled := InvestigatorSetupFlow.assemble_chaos_bag(ctx2)
	return (
		bool(assembled.get("ok", false))
		and String(assembled.get("source", "")) == "snapshot"
		and int(assembled.get("size", 0)) == 18
	)
