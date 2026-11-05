class_name CampaignSetup
extends RefCounted

## 剧本开局手续：开剧本 → 选/换调查员（附带 CHOICE）→ 初始牌库 → 接线冒险设置。


static func start_campaign(
	campaign_id: StringName = &"campaign",
	difficulty: StringName = &"standard",
	flags: Dictionary = {}
) -> CampaignState:
	var state := CampaignState.new()
	state.campaign_id = campaign_id
	state.difficulty = ChaosBagCatalog.normalize_bag_difficulty(difficulty)
	state.mode = StringName(str(flags.get("mode", CampaignState.MODE_CAMPAIGN)))
	state.use_starter_deck_no_random_weakness = bool(
		flags.get("use_starter_deck_no_random_weakness", false)
	)
	var bag_id := ChaosBagCatalog.bag_id_for_campaign(campaign_id)
	if bag_id == &"" and flags.has("chaos_bag_id"):
		bag_id = StringName(str(flags.get("chaos_bag_id")))
	state.chaos_bag_id = bag_id
	state.log.record("campaign_started:%s" % String(campaign_id))
	return state


## 选定调查员并应用附带构筑选择；写入 CampaignState。
static func select_investigator(
	state: CampaignState,
	definition_id: StringName,
	choices: Dictionary = {},
	player_slot: StringName = &""
) -> Dictionary:
	if state == null:
		return {"ok": false, "reason": "missing_state"}
	var data := CardRegistry.definition_data(definition_id)
	if data.is_empty():
		return {"ok": false, "reason": "unknown_investigator"}
	if str(data.get("card_type", "")) != "investigator":
		return {"ok": false, "reason": "not_investigator"}
	var rec := CampaignInvestigatorRecord.new()
	rec.investigator_id = player_slot if player_slot != &"" else definition_id
	rec.definition_id = definition_id
	var bound := DeckbuildingChoiceFlow.bind_investigator(rec, data, choices)
	if not bool(bound.get("ok", false)):
		return {
			"ok": false,
			"reason": "unresolved_choices",
			"unresolved": bound.get("unresolved", []),
			"record": rec,
		}
	## 必带署名 / 署名弱点。
	var req_res := install_required_cards(rec)
	state.investigators.append(rec)
	state.log.record("selected_investigator:%s" % String(definition_id))
	return {
		"ok": true,
		"record": rec,
		"profile": bound.get("profile"),
		"required": req_res,
	}


## 更换调查员：移除旧记录，选新人（牌组不继承）。
static func replace_investigator(
	state: CampaignState,
	old_investigator_id: StringName,
	new_definition_id: StringName,
	choices: Dictionary = {}
) -> Dictionary:
	if state == null:
		return {"ok": false, "reason": "missing_state"}
	if not state.remove_record(old_investigator_id):
		return {"ok": false, "reason": "unknown_record"}
	state.log.record(
		"replaced_investigator:%s->%s" % [String(old_investigator_id), String(new_definition_id)]
	)
	return select_investigator(state, new_definition_id, choices, old_investigator_id)


## 从 deck_requirements.card 安装 Signature（含署名弱点）。
static func install_required_cards(record: CampaignInvestigatorRecord) -> Dictionary:
	if record == null:
		return {"ok": false, "added": []}
	var data := CardRegistry.definition_data(record.definition_id)
	var req: Variant = data.get("deck_requirements", {})
	var added: Array[StringName] = []
	if req is Dictionary:
		var cards_req: Variant = (req as Dictionary).get("card", {})
		if cards_req is Dictionary:
			for code in (cards_req as Dictionary).keys():
				var sid := StringName(str(code))
				var view := DeckCardView.from_registry(sid)
				if view.definition_id == &"":
					continue
				view.ignore_deckbuilding = true
				record.deck.append(view)
				added.append(sid)
	return {"ok": true, "added": added}


## 组装开局牌组：player_card_ids 为计入 size 的构筑卡；自动处理 random basic weakness。
## opts: { skip_basic_weakness?: bool, rng?: RandomNumberGenerator, basic_weakness_pool?: Array }
static func set_opening_deck(
	state: CampaignState,
	record: CampaignInvestigatorRecord,
	player_card_ids: Array,
	opts: Dictionary = {}
) -> Dictionary:
	if state == null or record == null:
		return {"ok": false, "reason": "missing"}
	## 保留已安装的 required（ignore / weakness）；清掉其它后重装玩家卡。
	var kept: Array[DeckCardView] = []
	for c in record.deck:
		if c.ignore_deckbuilding or c.is_weakness:
			kept.append(c)
	record.deck = kept
	for id_v in player_card_ids:
		var id := StringName(str(id_v))
		var view := DeckCardView.from_registry(id)
		if view.definition_id == &"":
			return {"ok": false, "reason": "unknown_card:%s" % String(id)}
		record.deck.append(view)

	var skip_bw := bool(opts.get("skip_basic_weakness", state.use_starter_deck_no_random_weakness))
	var bw_id: StringName = &""
	if not skip_bw and _requires_random_basic_weakness(record):
		var pool: Array = opts.get("basic_weakness_pool", [])
		if pool.is_empty():
			pool = list_basic_weakness_pool(state)
		var rng: RandomNumberGenerator = opts.get("rng")
		if rng == null:
			rng = RandomNumberGenerator.new()
			rng.randomize()
		bw_id = _draw_basic_weakness(state, pool, rng)
		if bw_id == &"":
			return {"ok": false, "reason": "no_basic_weakness_available"}
		var bw := DeckCardView.from_registry(bw_id)
		bw.is_weakness = true
		bw.ignore_deckbuilding = true
		record.deck.append(bw)

	var validation := validate_opening_deck(record)
	validation["basic_weakness"] = bw_id
	return validation


static func validate_opening_deck(record: CampaignInvestigatorRecord) -> Dictionary:
	if record == null:
		return {"ok": false, "reason": "missing_record", "errors": ["missing_record"]}
	var profile := record.profile()
	if not profile.unresolved_choices.is_empty():
		return {"ok": false, "reason": "unresolved_choices", "errors": ["unresolved_choices"]}
	var result := DeckLegality.validate_deck(record.deck_as_array(), profile)
	## 必带署名是否在组。
	var data := CardRegistry.definition_data(record.definition_id)
	var req: Variant = data.get("deck_requirements", {})
	var missing: Array[StringName] = []
	if req is Dictionary:
		var cards_req: Variant = (req as Dictionary).get("card", {})
		if cards_req is Dictionary:
			for code in (cards_req as Dictionary).keys():
				var sid := StringName(str(code))
				var found := false
				for c in record.deck:
					if c.definition_id == sid:
						found = true
						break
				if not found:
					missing.append(sid)
	if not missing.is_empty():
		var errs: Array = result.get("errors", [])
		for m in missing:
			errs.append("missing_required:%s" % String(m))
		return {"ok": false, "reason": "missing_required", "errors": errs, "missing_required": missing}
	result["reason"] = "" if bool(result.get("ok", false)) else "illegal_deck"
	return result


## 列出可选 basic weakness（扣掉本剧本已 claimed）。
static func list_basic_weakness_pool(state: CampaignState) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in CardRegistry.all_definition_ids():
		var data := CardRegistry.definition_data(id)
		var sub := str(data.get("subtype_code", "")).to_lower()
		if sub != "basicweakness":
			continue
		if state != null and state.claimed_basic_weaknesses.has(id):
			continue
		out.append(id)
	return out


## 接线冒险：写入 current_scenario_id，返回已设 setup_scenario_id 的 RulesConfig。
static func prepare_scenario(
	state: CampaignState,
	scenario_id: StringName,
	base_config: RulesConfig = null
) -> Dictionary:
	if state == null:
		return {"ok": false, "reason": "missing_state"}
	if scenario_id == &"":
		return {"ok": false, "reason": "missing_scenario"}
	state.current_scenario_id = scenario_id
	var cfg := base_config if base_config != null else RulesConfig.new()
	cfg.setup_scenario_id = scenario_id
	## 参考卡两面带（≠ 四档袋难度）。
	cfg.chaos_difficulty = ChaosBagCatalog.reference_band(state.difficulty)
	if state.chaos_bag_id == &"":
		state.chaos_bag_id = ChaosBagCatalog.resolve_bag_id(state.campaign_id, scenario_id)
	ScenarioSetupCatalog.prepare_definitions(scenario_id)
	var layout := ScenarioSetupCatalog.resolve_layout(cfg)
	var decks := ScenarioSetupCatalog.resolve(cfg)
	state.log.record("prepare_scenario:%s" % String(scenario_id))
	return {
		"ok": not layout.is_empty() or not (decks.get("act", []) as Array).is_empty(),
		"config": cfg,
		"layout": layout,
		"act_agenda": decks,
	}


## 将开局牌组装入运行时调查员（测试/竖切用薄桥）。
## 创伤只写入 InvestigatorState 计数；标记由 SETUP_02 / apply_trauma 落地。
static func materialize_deck_into_context(
	ctx: GameContext,
	record: CampaignInvestigatorRecord,
	inv_id: StringName = &"",
	location_tag: StringName = &"test_loc"
) -> Dictionary:
	if ctx == null or record == null:
		return {"ok": false, "reason": "missing"}
	var iid := inv_id if inv_id != &"" else record.investigator_id
	if ctx.state.registry.get_investigator(iid) == null:
		GameBootstrap.setup_investigator_at_location(
			ctx, iid, location_tag, {"definition_id": record.definition_id}
		)
		if ctx.state.registry.get_location(location_tag) == null:
			GameBootstrap.setup_test_location(ctx, location_tag)
		if ctx.state.lead_investigator_id == &"":
			ctx.lead_investigator_id = iid
			ctx.active_investigator_id = iid
			ctx.state.lead_investigator_id = iid
			ctx.state.active_investigator_id = iid
	var inv := ctx.state.registry.get_investigator(iid)
	if inv:
		inv.physical_trauma = record.physical_trauma
		inv.mental_trauma = record.mental_trauma
		if ctx.state.physical_binding != null:
			ctx.state.physical_binding.ensure_player(iid)
	var placed: Array[StringName] = []
	for view in record.deck:
		var instance_id := ctx.state.registry.allocate_instance_id(&"card")
		var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, instance_id, view.definition_id)
		var card := CardInstance.new()
		card.id = eid
		card.owner_id = iid
		card.controller_id = iid
		card.zone = AhcEnums.Zone.DECK
		ctx.state.registry.register_card(card)
		if inv:
			inv.deck.append(instance_id)
		if ctx.state.physical_binding != null:
			ctx.state.physical_binding.ensure_physical_card(card)
		placed.append(instance_id)
	if inv and ctx.mutator != null:
		ctx.mutator.sync_player_deck(iid)
	return {"ok": true, "investigator_id": iid, "cards": placed}


## 剧本 → 对局：prepare + 装库 + Framework Setup 走到 game begins（含冒险布局 10–14）。
## opts: { seed?, skip_mulligan?, lead_id?, chaos_tokens?: Array, run_player_steps?: bool }
static func begin_scenario(
	state: CampaignState,
	scenario_id: StringName,
	opts: Dictionary = {}
) -> Dictionary:
	if state == null:
		return {"ok": false, "reason": "missing_state"}
	if state.investigators.is_empty():
		return {"ok": false, "reason": "no_investigators"}
	for rec in state.investigators:
		var v := validate_opening_deck(rec)
		if not bool(v.get("ok", false)):
			return {
				"ok": false,
				"reason": "illegal_deck",
				"investigator_id": rec.investigator_id,
				"errors": v.get("errors", []),
			}
	var prep := prepare_scenario(state, scenario_id)
	if not bool(prep.get("ok", false)):
		return {"ok": false, "reason": "prepare_failed", "prep": prep}
	var cfg: RulesConfig = prep["config"]
	cfg.setup_run_player_steps = bool(opts.get("run_player_steps", true))
	var p_seed := int(opts.get("seed", 42))
	var ctx := GameBootstrap.create(p_seed, cfg)
	ctx.state.campaign_state = state
	for rec in state.investigators:
		var mat := materialize_deck_into_context(ctx, rec)
		if not bool(mat.get("ok", false)):
			return {"ok": false, "reason": "materialize_failed", "detail": mat}
	var lead: StringName = opts.get("lead_id", &"")
	InvestigatorSetupFlow.ensure_lead(ctx, lead)
	## 可选强制袋内容；否则 SETUP_06 从快照/Catalog 组装。
	var tokens_raw: Variant = opts.get("chaos_tokens", [])
	if tokens_raw is Array and not (tokens_raw as Array).is_empty():
		var typed_tokens: Array[ChaosToken] = []
		for t in tokens_raw as Array:
			if t is ChaosToken:
				typed_tokens.append(t as ChaosToken)
		if not typed_tokens.is_empty():
			GameBootstrap.setup_chaos_bag(ctx, typed_tokens)
			state.chaos_bag_snapshot = ChaosBagCatalog.snapshot_tokens(typed_tokens)
			ctx.state.setup_chaos_bag_assembled = true
	## 起手 mulligan 策略写入 state 备忘，供 SETUP_08 读（目前仅 skip）。
	ctx.state.set_meta("setup_skip_mulligan", bool(opts.get("skip_mulligan", true)))
	GameBootstrap.run_setup_through_game_begins(ctx)
	## 开局后把袋写回剧本快照，供下场延续。
	if ctx.state != null and ctx.state.chaos_bag != null:
		state.chaos_bag_snapshot = ChaosBagCatalog.snapshot_tokens(ctx.state.chaos_bag.tokens)
	state.log.record("begin_scenario:%s" % String(scenario_id))
	return {
		"ok": true,
		"ctx": ctx,
		"config": cfg,
		"layout": prep.get("layout", {}),
		"act_agenda": prep.get("act_agenda", {}),
		"chaos_bag_size": ctx.state.chaos_bag.tokens.size() if ctx.state.chaos_bag else 0,
	}


static func _requires_random_basic_weakness(record: CampaignInvestigatorRecord) -> bool:
	var data := CardRegistry.definition_data(record.definition_id)
	var req: Variant = data.get("deck_requirements", {})
	if not req is Dictionary:
		return false
	var randoms: Variant = (req as Dictionary).get("random", [])
	if not randoms is Array:
		return false
	for r in randoms as Array:
		if r is Dictionary:
			var d: Dictionary = r
			if str(d.get("target", "")) == "subtype" and str(d.get("value", "")) == "basicweakness":
				return true
			## ArkhamDB 偶见 value 直接写 basicweakness
			if str(d.get("value", "")) == "basicweakness":
				return true
	return false


static func _draw_basic_weakness(
	state: CampaignState, pool: Array, rng: RandomNumberGenerator
) -> StringName:
	var candidates: Array[StringName] = []
	for id_v in pool:
		var id := StringName(str(id_v))
		if state.claimed_basic_weaknesses.has(id):
			continue
		candidates.append(id)
	if candidates.is_empty():
		return &""
	var pick: StringName = candidates[rng.randi_range(0, candidates.size() - 1)]
	state.claimed_basic_weaknesses.append(pick)
	return pick
