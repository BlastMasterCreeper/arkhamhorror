class_name InvestigatorSetupFlow
extends RefCounted

## Framework Setup 玩家侧步骤（02–04 / 07–08）。
## 由 `RulesConfig.setup_run_player_steps` 闸；`CampaignSetup.begin_scenario` 打开。


static func player_steps_enabled(game_ctx: GameContext) -> bool:
	return game_ctx != null and game_ctx.config != null and game_ctx.config.setup_run_player_steps


## SETUP_02 · Take trauma → 伤害/恐惧标记（不经 Defeat 检定；伤恐达上限由常态检测另处理）。
static func apply_trauma(game_ctx: GameContext) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	if game_ctx.state.setup_trauma_applied:
		return {"ok": true, "skipped": true, "reason": &"already_applied"}
	var applied: Array = []
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null:
			continue
		var phys := inv.physical_trauma
		var ment := inv.mental_trauma
		if phys > 0 and game_ctx.mutator != null:
			game_ctx.mutator.transfer_marker(
				AhcEnums.MarkerKind.DAMAGE,
				phys,
				MarkerSlot.supply(AhcEnums.MarkerKind.DAMAGE),
				MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.DAMAGE)
			)
		if ment > 0 and game_ctx.mutator != null:
			game_ctx.mutator.transfer_marker(
				AhcEnums.MarkerKind.HORROR,
				ment,
				MarkerSlot.supply(AhcEnums.MarkerKind.HORROR),
				MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.HORROR)
			)
		if phys > 0 or ment > 0:
			applied.append({"id": inv_id, "damage": phys, "horror": ment})
	game_ctx.state.setup_trauma_applied = true
	if game_ctx.log != null:
		game_ctx.log.log(AhcEnums.LogCategory.SCENARIO, "setup:apply_trauma", {"applied": applied})
	return {"ok": true, "applied": applied}


## SETUP_03 · Choose lead（已设则保留；否则取注册表首位）。
static func ensure_lead(game_ctx: GameContext, preferred: StringName = &"") -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	var ids := game_ctx.state.registry.all_investigator_ids()
	if ids.is_empty():
		return {"ok": false, "reason": &"no_investigators"}
	var lead := preferred
	if lead == &"":
		lead = game_ctx.state.lead_investigator_id
	if lead == &"" or not ids.has(lead):
		lead = ids[0]
	game_ctx.state.lead_investigator_id = lead
	game_ctx.lead_investigator_id = lead
	if game_ctx.state.active_investigator_id == &"":
		game_ctx.state.active_investigator_id = lead
		game_ctx.active_investigator_id = lead
	if game_ctx.framework != null:
		game_ctx.framework.refresh_player_order()
	if game_ctx.log != null:
		game_ctx.log.log(AhcEnums.LogCategory.SCENARIO, "setup:choose_lead", {"lead": lead})
	return {"ok": true, "lead": lead}


## SETUP_06 · Assemble chaos bag（快照优先；否则 Catalog 按难度）。
static func assemble_chaos_bag(game_ctx: GameContext) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	if game_ctx.state.setup_chaos_bag_assembled:
		return {"ok": true, "skipped": true, "reason": &"already_assembled"}
	## 已有袋内容（测试旁路 / begin_scenario 预装）→ 记组装完成。
	if game_ctx.state.chaos_bag != null and not game_ctx.state.chaos_bag.tokens.is_empty():
		game_ctx.state.setup_chaos_bag_assembled = true
		return {
			"ok": true,
			"skipped": true,
			"reason": &"bag_already_filled",
			"size": game_ctx.state.chaos_bag.tokens.size(),
		}
	var camp: CampaignState = game_ctx.state.campaign_state
	var tokens: Array[ChaosToken] = []
	var source := &"catalog"
	if camp != null and not camp.chaos_bag_snapshot.is_empty():
		tokens = ChaosBagCatalog.tokens_from_snapshot(camp.chaos_bag_snapshot, &"persist")
		source = &"snapshot"
	else:
		var bag_id: StringName = &""
		var difficulty: StringName = &"standard"
		if camp != null:
			bag_id = camp.chaos_bag_id
			difficulty = camp.difficulty
		if bag_id == &"" and game_ctx.config != null:
			bag_id = ChaosBagCatalog.bag_id_for_scenario(game_ctx.config.setup_scenario_id)
		if bag_id == &"" and camp != null:
			bag_id = ChaosBagCatalog.resolve_bag_id(camp.campaign_id, game_ctx.config.setup_scenario_id if game_ctx.config else &"")
		if game_ctx.config != null and camp == null:
			## 无剧本状态时：用参考卡带反推袋档（easy_standard→standard）。
			difficulty = ChaosBagCatalog.normalize_bag_difficulty(game_ctx.config.chaos_difficulty)
		tokens = ChaosBagCatalog.build_tokens(bag_id, difficulty, &"setup06")
	if tokens.is_empty():
		return {"ok": true, "skipped": true, "reason": &"no_bag_recipe"}
	GameBootstrap.setup_chaos_bag(game_ctx, tokens)
	game_ctx.state.setup_chaos_bag_assembled = true
	if camp != null:
		camp.chaos_bag_snapshot = ChaosBagCatalog.snapshot_tokens(tokens)
	if game_ctx.state.chaos_bag != null:
		game_ctx.state.chaos_bag.shuffle()
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"setup:assemble_chaos_bag",
			{"source": source, "size": tokens.size()}
		)
	return {"ok": true, "source": source, "size": tokens.size()}


## SETUP_04 · 永久进场 → 挂载起始 → Shuffle investigator decks。
static func shuffle_decks(game_ctx: GameContext) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	place_permanents(game_ctx)
	StartingKeyword.mount_printed_in_decks(game_ctx)
	var shuffled: Array[StringName] = []
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null or inv.deck.is_empty():
			continue
		inv.deck.shuffle()
		if game_ctx.mutator != null:
			game_ctx.mutator.sync_player_deck(inv_id)
		shuffled.append(inv_id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO, "setup:shuffle_decks", {"investigators": shuffled}
		)
	return {"ok": true, "shuffled": shuffled}


## 永久卡从牌库放入场（Grimoire Permanent · 开局进场，不计抽牌）。
static func place_permanents(game_ctx: GameContext) -> Dictionary:
	var placed: Array = []
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "placed": placed}
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null:
			continue
		var from_deck: Array[StringName] = inv.deck.duplicate()
		for card_id in from_deck:
			var card := game_ctx.state.registry.get_card(card_id)
			if card == null or card.id == null:
				continue
			if not CardRegistry.is_permanent(card.id.definition_id):
				continue
			inv.deck.erase(card_id)
			card.zone = AhcEnums.Zone.PLAY_AREA
			card.owner_id = inv_id
			card.controller_id = inv_id
			if not inv.play_area.has(card_id):
				inv.play_area.append(card_id)
			ZoneMoveFlow.notify_zone_set(
				game_ctx, card_id, AhcEnums.Zone.DECK, AhcEnums.Zone.PLAY_AREA
			)
			placed.append({"investigator_id": inv_id, "card_id": card_id})
	if game_ctx.log != null and not placed.is_empty():
		game_ctx.log.log(AhcEnums.LogCategory.SCENARIO, "setup:place_permanents", {"placed": placed})
	return {"ok": true, "placed": placed}


## SETUP_07 · Starting resources（各 5）。
static func starting_resources(game_ctx: GameContext, amount: int = 5) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	if game_ctx.state.setup_starting_resources_applied:
		return {"ok": true, "skipped": true, "reason": &"already_applied"}
	var gained: Array = []
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		if game_ctx.resource_gain != null:
			var n := game_ctx.resource_gain.gain(game_ctx, inv_id, amount, [&"setup_07"])
			gained.append({"id": inv_id, "amount": n})
		elif game_ctx.mutator != null:
			game_ctx.mutator.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				amount,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.RESOURCE)
			)
			gained.append({"id": inv_id, "amount": amount})
	game_ctx.state.setup_starting_resources_applied = true
	if game_ctx.log != null:
		game_ctx.log.log(AhcEnums.LogCategory.SCENARIO, "setup:starting_resources", {"gained": gained})
	return {"ok": true, "gained": gained}


## SETUP_08 · Opening hands：抽 5；弱点 set aside 并重抽；默认跳过 mulligan；弱点洗回牌库。
static func opening_hands(game_ctx: GameContext, opts: Dictionary = {}) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	if game_ctx.state.setup_opening_hands_applied:
		return {"ok": true, "skipped": true, "reason": &"already_applied"}
	var skip_mulligan := bool(opts.get("skip_mulligan", true))
	var results: Array = []
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null:
			continue
		var set_aside_weak: Array[StringName] = []
		var non_weak := 0
		var guard := 0
		while non_weak < 5 and guard < 64:
			guard += 1
			if inv.deck.is_empty() and game_ctx.mutator != null:
				## 空库：让抽牌手续处理（洗弃+horror）；若仍空则停。
				pass
			if game_ctx.draw_investigator == null:
				break
			var before_hand := inv.hand.duplicate()
			game_ctx.draw_investigator.draw_cards(game_ctx, inv_id, 1, [&"setup_08"])
			var added: Array[StringName] = []
			for cid in inv.hand:
				if not before_hand.has(cid):
					added.append(cid)
			if added.is_empty():
				break
			var card_id: StringName = added[0]
			if _is_weakness_card(game_ctx, card_id):
				if game_ctx.mutator != null:
					game_ctx.mutator.move_to_set_aside(card_id)
				elif inv.hand.has(card_id):
					inv.hand.erase(card_id)
					game_ctx.state.set_aside.append(card_id)
					var card := game_ctx.state.registry.get_card(card_id)
					if card:
						card.zone = AhcEnums.Zone.SET_ASIDE
				set_aside_weak.append(card_id)
			else:
				non_weak += 1
		## Headless：跳过 mulligan（有限期确认入口日后接 PI）。
		if not skip_mulligan and game_ctx.interaction != null:
			pass
		## 弱点洗回牌库。
		for wid in set_aside_weak:
			_return_set_aside_to_deck(game_ctx, inv_id, wid)
		if not set_aside_weak.is_empty() and game_ctx.mutator != null:
			inv.deck.shuffle()
			game_ctx.mutator.sync_player_deck(inv_id)
		results.append(
			{"id": inv_id, "hand_size": inv.hand.size(), "weaknesses_redrawn": set_aside_weak.size()}
		)
	## 起手+mulligan 之后：检索各 1 张 Starting。
	var starting := StartingKeyword.fire_after_opening_hands(game_ctx)
	game_ctx.state.setup_opening_hands_applied = true
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"setup:opening_hands",
			{"results": results, "starting": starting.get("pulled", [])}
		)
	return {"ok": true, "results": results, "starting": starting}


static func _is_weakness_card(game_ctx: GameContext, card_id: StringName) -> bool:
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null or card.id == null:
		return false
	var data := CardRegistry.definition_data(card.id.definition_id)
	if bool(data.get("is_weakness", false)):
		return true
	var sub := str(data.get("subtype_code", "")).to_lower()
	return sub == "weakness" or sub == "basicweakness"


static func _return_set_aside_to_deck(
	game_ctx: GameContext, inv_id: StringName, card_id: StringName
) -> void:
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	var card := game_ctx.state.registry.get_card(card_id)
	if inv == null or card == null:
		return
	if game_ctx.state.set_aside.has(card_id):
		game_ctx.state.set_aside.erase(card_id)
	card.zone = AhcEnums.Zone.DECK
	card.owner_id = inv_id
	card.controller_id = inv_id
	if not inv.deck.has(card_id):
		inv.deck.append(card_id)
	if game_ctx.mutator != null and game_ctx.state.physical_binding != null:
		game_ctx.state.physical_binding.mirror_move_to_zone(card, AhcEnums.Zone.DECK, inv_id)
