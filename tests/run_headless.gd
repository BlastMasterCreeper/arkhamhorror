extends SceneTree

## CI entry: godot --headless --path . -s res://tests/run_headless.gd

const PASS := 0
const FAIL := 1

var _failed := 0


func _initialize() -> void:
	print("=== AHC LCG headless tests ===")
	_run_test("A-01 setup reaches investigation phase", _test_setup_to_inv_phase)
	_run_test("A-02 resource action", _test_resource_action)
	_run_test("A-03 event records written", _test_event_records)
	_run_test("F-01 round 1 skips mythos", _test_round1_skips_mythos)
	_run_test("F-02 full round to round 2 mythos", _test_full_round_to_mythos)
	_run_test("F-03 action phase gate", _test_action_phase_gate)
	_run_test("C-01 dry-run register created", _test_dry_run_register_only)
	_run_test("C-02 dry-run draw empty deck illegal", _test_dry_run_draw_empty)
	_run_test("C-03 dry-run draw or register", _test_dry_run_draw_or_register)
	_run_test("C-04 register applies modifier", _test_register_modifier)
	_run_test("C-05 restriction blocks draw dry-run", _test_restriction_blocks_draw)
	_run_test("C-06 listener draws on timing", _test_listener_draw_on_timing)
	_run_test("C-07 until_fired listener removes self", _test_until_fired_listener)
	_run_test("C-08 initiation dry-run gate", _test_initiation_dry_run_gate)
	_run_test("ENC-01 seq.draw.encounter catalog", _test_enc_draw_catalog)
	_run_test("ENC-02 default spawn engaged", _test_enc_spawn_default_engaged)
	_run_test("ENC-17 default spawn drawer not prey auto engage", _test_enc_default_spawn_drawer_not_prey)
	_run_test("ENC-03 spawn instruction at location", _test_enc_spawn_instruction_at_location)
	_run_test("ENC-04 spawn failed discard", _test_enc_spawn_failed_discard)
	_run_test("ENC-19 spawn failed reports in draw result", _test_enc_spawn_failed_in_result)
	_run_test("ENC-20 weakness enemy spawn failed bearer discard", _test_enc_weakness_spawn_failed)
	_run_test("ENC-05 aloof spawn not engaged", _test_enc_spawn_aloof)
	_run_test("ENC-18 aloof spawn instruction at location", _test_enc_spawn_aloof_with_instruction)
	_run_test("ENC-06 prey highest willpower", _test_enc_prey_highest_willpower)
	_run_test("ENC-07 no prey lead engages", _test_enc_no_prey_lead_engages)
	_run_test("ENC-08 prey lowest agility", _test_enc_prey_lowest_agility)
	_run_test("ENC-09 surge chain two treacheries", _test_enc_surge_chain)
	_run_test("ENC-10 peril surge clears before second card", _test_enc_peril_surge_not_sticky)
	_run_test("ENC-11 encounter revelation nests catalog", _test_enc_revelation_nest)
	_run_test("ENC-21 encounter spawn nests catalog", _test_enc_spawn_nest)
	_run_test("ENC-22 hidden enemy secret hand no spawn", _test_enc_hidden_enemy_no_spawn)
	_run_test("ENC-23 hidden enemy hand ability spawns", _test_enc_hidden_enemy_hand_spawn)
	_run_test("ENC-12 hidden treachery secret hand", _test_enc_hidden_secret_hand)
	_run_test("ENC-24 hidden privacy forbid leave hand", _test_enc_hidden_forbid_leave_hand)
	_run_test("ENC-13 default treachery reveal all", _test_enc_default_reveal_all)
	_run_test("ENC-14 empty deck shuffles discard", _test_enc_shuffle_discard)
	_run_test("ENC-15 both piles empty rules gap", _test_enc_both_piles_empty)
	_run_test("ENC-16 surge chain shuffles discard", _test_enc_surge_shuffles_discard)
	_run_test("WKN-01 asset weakness uses investigator draw", _test_wkn_asset_weakness_investigator_draw)
	_run_test("WKN-03 enemy weakness redirects resolve_bound", _test_wkn_enemy_weakness_resolve_bound)
	_run_test("STAT-01 cold fold action spend count", _test_stat_cold_fold_action_count)
	_run_test("STAT-02 hot projection increments", _test_stat_hot_projection_increments)
	_run_test("STAT-03 unregister drops hot projection", _test_stat_unregister_drops_hot)
	_run_test("STAT-04 condition min action spends", _test_stat_condition_min_action_spends)
	_run_test("ST-01 begin pushes stack", _test_st_begin)
	_run_test("ST-02 commit adds icon bonus", _test_st_commit_bonus)
	_run_test("ST-03 successful intellect test", _test_st_success)
	_run_test("ST-04 auto-fail token", _test_st_auto_fail)
	_run_test("ST-05 ally commit helps", _test_st_ally_commit)
	_run_test("ST-06 peril blocks ally", _test_st_peril_blocks_ally)
	_run_test("PERIL-01 encounter frame blocks ally commit", _test_peril_frame_blocks_ally)
	_run_test("PERIL-04 peril not sticky across cards", _test_peril_not_sticky_across_cards)
	_run_test("PERIL-05 peril unregister allows ally", _test_peril_unregister_allows_ally)
	_run_test("ST-07 apply success callback", _test_st_apply_success)
	_run_test("ST-08 end discards committed", _test_st_end_cleanup)
	_run_test("ACT-01 investigate discovers clue", _test_act_investigate_success)
	_run_test("ACT-02 investigate fail no clue", _test_act_investigate_fail)
	_run_test("ACT-03 fight deals damage", _test_act_fight_success)
	_run_test("ACT-04 evade disengages enemy", _test_act_evade_success)
	_run_test("ACT-05 evade requires engagement", _test_act_evade_not_engaged)
	_run_test("ACT-06 fight rejects aloof", _test_act_fight_aloof)
	_run_test("ACT-07 engage adds to threat area", _test_act_engage_success)
	_run_test("ACT-08 engage steals enemy", _test_act_engage_steal)
	_run_test("ACT-09 engage rejects massive", _test_act_engage_massive)
	_run_test("ACT-10 engage then fight aloof", _test_act_engage_then_fight)
	_run_test("AOO-01 resource provokes damage", _test_aoo_resource)
	_run_test("AOO-02 fight skips aoo", _test_aoo_fight_skip)
	_run_test("AOO-03 exhausted enemy skips aoo", _test_aoo_exhausted_skip)
	_run_test("ACT-11 move to connected location", _test_act_move_success)
	_run_test("ACT-12 move rejects disconnected", _test_act_move_fail)
	_run_test("ACT-13 draw from deck", _test_act_draw_from_deck)
	_run_test("ACT-14 draw shuffles discard", _test_act_draw_shuffle)
	_run_test("ACT-15 draw empty piles defeated", _test_act_draw_defeated)
	_run_test("VIS-01 draw reveal before hand", _test_vis_draw_reveal_before_hand)
	_run_test("VIS-02 draw face known to controller only", _test_vis_draw_controller_only)
	_run_test("DRAW-02 draw two simultaneous", _test_draw_two_simultaneous)
	_run_test("DRAW-03 draw two mid-deck shuffle", _test_draw_two_mid_shuffle)
	GameBootstrap.register_enter_hand_test_definitions()
	_run_test("ENT-01 enter_hand revelation take horror", _test_ent_revelation_take_horror)
	_run_test("ENT-02 enter_hand no revelation", _test_ent_no_revelation)
	_run_test("ENT-03 enter_hand revelation order and limbo discard", _test_ent_revelation_order)
	_run_test("REG-01 turn end ticks duration", _test_reg_turn_end_tick)
	_run_test("NS-01 nested sequence LIFO", _test_ns_lifo_nest)
	_run_test("NS-02 after waits for nested child", _test_ns_after_order)
	_run_test("NS-03 upkeep framework resource modifier", _test_ns_upkeep_resource_modifier)
	_run_test("NS-04 gain sequence fires after listener", _test_ns_gain_after_listener)
	_run_test("NS-05 response window refresh after nest", _test_ns_refresh_after_nest)
	_run_test("NS-06 reaction blocked on own resolution", _test_ns_self_response_blocked)
	_run_test("PI-01 default optional declines", _test_pi_default_optional_decline)
	_run_test("PI-02 scripting resolver by prompt_id", _test_pi_scripting_resolver)
	_run_test("FWK-01 upkeep 4.4 draw and gain via catalog", _test_fwk_upkeep_44_catalog)
	_run_test("FWK-02 mythos 1.4 encounter draw", _test_fwk_mythos_14_encounter_draw)
	_run_test("FWK-03 mythos 1.4 two investigators", _test_fwk_mythos_14_two_investigators)
	_run_test("FWK-04 mythos 1.4 enemy spawn engaged", _test_fwk_mythos_14_enemy_spawn)
	_run_test("FWK-05 mythos 1.4 spawn instruction named", _test_fwk_mythos_14_spawn_instruction_named)
	_run_test("FWK-06 mythos 1.4 spawn instruction auto engage", _test_fwk_mythos_14_spawn_instruction_auto_engage)
	if _failed > 0:
		print("FAILED: %d test(s)" % _failed)
		quit(FAIL)
	else:
		print("All tests passed.")
		quit(PASS)


func _run_test(name: String, fn: Callable) -> void:
	if fn.call():
		print("  OK  %s" % name)
	else:
		print("  FAIL %s" % name)
		_failed += 1


func _test_setup_to_inv_phase() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	return h.framework_step() == AhcEnums.FrameworkStep.INV_2_1_PHASE_BEGINS


func _test_resource_action() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	if not h.advance_to_action_phase():
		return false
	h.ctx.state.registry.get_investigator(&"inv_1").actions_remaining = 1
	var res := h.take_resource_action()
	h.close_windows()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return res.ok and inv.resource_pool == 6 and inv.actions_remaining == 0


func _test_round1_skips_mythos() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	return (
		h.ctx.framework.round_number == 1
		and h.ctx.framework.skip_mythos
		and h.framework_step() == AhcEnums.FrameworkStep.INV_2_1_PHASE_BEGINS
	)


func _test_full_round_to_mythos() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	if not h.run_full_round_one_investigator():
		return false
	h.ctx.framework.advance()
	return (
		h.ctx.framework.round_number == 2
		and h.framework_step() == AhcEnums.FrameworkStep.MYTHOS_1_1_PHASE_BEGINS
	)


func _test_action_phase_gate() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	var blocked := h.take_resource_action()
	return not blocked.ok and blocked.error == "not_action_phase"


func _test_event_records() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	return h.event_count(AhcEnums.EventRecordKind.FRAMEWORK_STEP) >= 14


func _test_dry_run_register_only() -> bool:
	var h := RuleTestHarness.new(42)
	var c := CompositionTestHelper.new(h.ctx)
	var node := CompositionTestHelper.lasting_willpower_turn(&"inv_1", 1)
	return c.dry_run(node)


func _test_dry_run_draw_empty() -> bool:
	var h := RuleTestHarness.new(42)
	var c := CompositionTestHelper.new(h.ctx)
	var draw := CompositionNode.draw(&"inv_1")
	return not c.dry_run(draw)


func _test_dry_run_draw_or_register() -> bool:
	var h := RuleTestHarness.new(42)
	var c := CompositionTestHelper.new(h.ctx)
	var node := CompositionNode.seq([
		CompositionNode.draw(&"inv_1"),
		CompositionTestHelper.lasting_willpower_turn(&"inv_1", 1),
	])
	return c.dry_run(node)


func _test_register_modifier() -> bool:
	var h := RuleTestHarness.new(42)
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionTestHelper.lasting_willpower_turn(&"inv_1", 1))
	return c.modifier_willpower(3, &"inv_1") == 4


func _test_restriction_blocks_draw() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionTestHelper.forbid_draw_turn(&"inv_1"))
	return not c.dry_run(CompositionNode.draw(&"inv_1"))


func _test_listener_draw_on_timing() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionTestHelper.delayed_draw_listener(&"inv_1", &"after_fight"))
	var inv_before := h.ctx.state.registry.get_investigator(&"inv_1")
	if inv_before.deck.size() != 1 or inv_before.hand.size() != 0:
		return false
	h.ctx.timing.emit_timing(&"after_fight")
	var inv_after := h.ctx.state.registry.get_investigator(&"inv_1")
	return inv_after.deck.is_empty() and inv_after.hand.size() == 1


func _test_until_fired_listener() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionTestHelper.delayed_draw_listener(&"inv_1", &"after_fight"))
	if h.ctx.registrations.count() != 1:
		return false
	h.ctx.timing.emit_timing(&"after_fight")
	if h.ctx.registrations.count() != 0:
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return inv.hand.size() == 1 and inv.deck.size() == 1


func _test_initiation_dry_run_gate() -> bool:
	var h := RuleTestHarness.new(42)
	var draw_intent := InitiationIntent.create(&"inv_1", CompositionNode.draw(&"inv_1"))
	if h.ctx.initiation.can_initiate(draw_intent, h.ctx):
		return false
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	if not h.ctx.initiation.can_initiate(draw_intent, h.ctx):
		return false
	var res := h.ctx.initiation.initiate(draw_intent, h.ctx)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return res.ok and inv.hand.size() == 1


func _test_st_begin() -> bool:
	var h := RuleTestHarness.new(42)
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 2)
	st.begin(test)
	return (
		h.ctx.skill_test_stack.size() == 1
		and h.ctx.skill_tests.skill_test_step_count(AhcEnums.SkillTestStep.ST_1_BEGIN) >= 1
	)


func _test_st_commit_bonus() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	var card_id := GameBootstrap.add_skill_card_to_hand(
		h.ctx, &"inv_1", AhcEnums.SkillType.INTELLECT
	)
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 5)
	var commits: Array[CommittedCard] = [CommittedCard.create(card_id, &"inv_1")]
	var result := st.run(test, commits)
	return result.modified_value == 4


func _test_st_success() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 3)
	return st.run(test).success


func _test_st_auto_fail() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.auto_fail()])
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 0)
	var result := st.run(test)
	return not result.success and result.modified_value == 0


func _test_st_ally_commit() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc", {"intellect": 2})
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	inv1.skill_intellect = 2
	var card_id := GameBootstrap.add_skill_card_to_hand(
		h.ctx, &"inv_2", AhcEnums.SkillType.INTELLECT
	)
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 3)
	var commits: Array[CommittedCard] = [CommittedCard.create(card_id, &"inv_2")]
	return st.run(test, commits).success


func _test_enc_draw_catalog() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_minimal_investigator(h.ctx, &"inv_1")
	CardRegistry.register_definition(
		&"plain_treachery",
		{"card_type": &"treachery", "keywords": []}
	)
	GameBootstrap.add_encounter_card_to_deck(h.ctx, &"plain_treachery")
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var cards: Array = res.get("cards", [])
	return cards.size() == 1 and h.ctx.state.encounter_deck.is_empty()


func _test_enc_spawn_default_engaged() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(h.ctx, &"enc_enemy_default")
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var card := h.ctx.state.registry.get_card(card_id)
	return (
		enemy != null
		and enemy.engaged_with == &"inv_1"
		and enemy.location_tag == &"test_loc"
		and inv.threat_area.has(card_id)
		and card.zone == AhcEnums.Zone.PLAY_AREA
	)


func _test_enc_default_spawn_drawer_not_prey() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(
		h.ctx, &"inv_2", &"test_loc", {"willpower": 5}
	)
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"enc_default_drawer",
		{"prey_instruction": PreyInstructionSpec.highest(AhcEnums.SkillType.WILLPOWER)}
	)
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	return (
		enemy != null
		and enemy.engaged_with == &"inv_1"
		and inv1.threat_area.has(card_id)
		and not inv2.threat_area.has(card_id)
	)


func _test_enc_spawn_instruction_at_location() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"loc_b")
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"enc_enemy_instr",
		{"spawn_instruction": SpawnInstructionSpec.at_named_location(&"loc_b")}
	)
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		enemy != null
		and enemy.location_tag == &"loc_b"
		and enemy.engaged_with == &""
		and not inv.threat_area.has(card_id)
	)


func _test_enc_spawn_failed_discard() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"enc_enemy_fail",
		{"spawn_instruction": SpawnInstructionSpec.at_named_location(&"missing_loc")}
	)
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	var card := h.ctx.state.registry.get_card(card_id)
	return (
		enemy == null
		and card.zone == AhcEnums.Zone.DISCARD
		and h.ctx.state.encounter_discard.has(card_id)
	)


func _test_enc_spawn_failed_in_result() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.ctx.sequence_catalog.has_flow(&"seq.encounter.spawn"):
		return false
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"enc_spawn_fail_result",
		{"spawn_instruction": SpawnInstructionSpec.at_named_location(&"missing_loc")}
	)
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	var failed: Array = res.get("spawn_failed_discards", [])
	return (
		res.get("ok", false)
		and failed.size() == 1
		and failed[0] == card_id
	)


func _test_enc_weakness_spawn_failed() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_investigator_weakness_to_deck(
		h.ctx,
		&"inv_1",
		&"wkn_enc_spawn_fail",
		&"enemy",
		{
			"spawn_instruction": SpawnInstructionSpec.at_named_location(&"missing_loc"),
			"enemy": {"fight": 2, "evade": 2, "health": 1},
		}
	)
	var res := h.ctx.draw_investigator.draw_cards(h.ctx, &"inv_1", 1, [&"test"])
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var card := h.ctx.state.registry.get_card(card_id)
	var failed: Array = res.get("spawn_failed_discards", [])
	return (
		res.get("drew", false)
		and h.ctx.state.registry.get_enemy(card_id) == null
		and card.zone == AhcEnums.Zone.DISCARD
		and inv.discard.has(card_id)
		and failed.size() == 1
		and failed[0] == card_id
	)


func _test_enc_spawn_aloof() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"enc_enemy_aloof",
		{"aloof": true}
	)
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		enemy != null
		and enemy.aloof
		and enemy.location_tag == &"test_loc"
		and enemy.engaged_with == &""
		and not inv.threat_area.has(card_id)
	)


func _test_enc_spawn_aloof_with_instruction() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"loc_b")
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"enc_aloof_spawn",
		{
			"aloof": true,
			"spawn_instruction": SpawnInstructionSpec.at_named_location(&"loc_b"),
		}
	)
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		enemy != null
		and enemy.aloof
		and enemy.location_tag == &"loc_b"
		and enemy.engaged_with == &""
		and not inv.threat_area.has(card_id)
	)


func _test_enc_prey_highest_willpower() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(
		h.ctx, &"inv_2", &"test_loc", {"willpower": 5}
	)
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"enc_prey_will",
		{
			"spawn_instruction": SpawnInstructionSpec.at_drawer_location(),
			"prey_instruction": PreyInstructionSpec.highest(AhcEnums.SkillType.WILLPOWER),
		}
	)
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	return (
		enemy != null
		and enemy.engaged_with == &"inv_2"
		and inv2.threat_area.has(card_id)
	)


func _test_enc_no_prey_lead_engages() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"enc_no_prey",
		{"spawn_instruction": SpawnInstructionSpec.at_drawer_location()}
	)
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		enemy != null
		and enemy.engaged_with == &"inv_1"
		and inv1.threat_area.has(card_id)
	)


func _test_enc_prey_lowest_agility() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(
		h.ctx, &"inv_2", &"test_loc", {"agility": 1}
	)
	h.ctx.state.registry.get_investigator(&"inv_1").skill_agility = 4
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"enc_prey_agi",
		{
			"spawn_instruction": SpawnInstructionSpec.at_drawer_location(),
			"prey_instruction": PreyInstructionSpec.lowest(AhcEnums.SkillType.AGILITY),
		}
	)
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	return enemy != null and enemy.engaged_with == &"inv_2"


func _test_enc_surge_chain() -> bool:
	var h := RuleTestHarness.new(42)
	var first := GameBootstrap.add_encounter_card_to_deck(
		h.ctx, &"enc_surge_a", [&"surge"]
	)
	var second := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_plain_b", [])
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var cards: Array = res.get("cards", [])
	if cards.size() != 2:
		return false
	if cards[0] != first or cards[1] != second:
		return false
	if int(res.get("surge_depth", 0)) != 1:
		return false
	var card_a := h.ctx.state.registry.get_card(first)
	var card_b := h.ctx.state.registry.get_card(second)
	return (
		h.ctx.state.encounter_deck.is_empty()
		and card_a.zone == AhcEnums.Zone.DISCARD
		and card_b.zone == AhcEnums.Zone.DISCARD
		and h.ctx.state.encounter_discard.has(first)
		and h.ctx.state.encounter_discard.has(second)
	)


func _test_enc_peril_surge_not_sticky() -> bool:
	var h := RuleTestHarness.new(42)
	var first := GameBootstrap.add_encounter_card_to_deck(
		h.ctx, &"enc_peril_surge", [&"peril", &"surge"]
	)
	var second := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_plain_b", [])
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var cards: Array = res.get("cards", [])
	return (
		cards.size() == 2
		and int(res.get("surge_depth", 0)) == 1
		and h.ctx.registrations.count() == 0
		and not h.ctx.registrations.has_peril_for_drawn_card(first)
		and not h.ctx.registrations.has_peril_for_drawn_card(second)
	)


func _test_enc_revelation_nest() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.memory.clear_trace()
	CardRegistry.register_definition(&"enc_rev_horror", {"card_type": &"treachery"})
	CardRegistry.register_revelation(
		&"enc_rev_horror",
		&"revelation:0",
		func(bind: AbilityBindContext) -> CompositionNode:
			return CompositionNode.adjust_marker(
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.HORROR_TAKEN),
				1
			)
	)
	GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_rev_horror", [])
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	var revelations: Array = res.get("revelations", [])
	var trace := h.ctx.memory.phase_trace
	var has_card_drawn := false
	var has_revelation := false
	for entry in trace:
		var line := str(entry)
		if line.begins_with("RESOLVE:encounter_card_drawn@"):
			has_card_drawn = true
		if line.begins_with("RESOLVE:encounter_revelation@"):
			has_revelation = true
	return (
		res.get("ok", false)
		and inv.horror_taken == 1
		and revelations.size() == 1
		and has_card_drawn
		and has_revelation
	)


func _test_enc_spawn_nest() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.memory.clear_trace()
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(h.ctx, &"enc_spawn_nest")
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var trace := h.ctx.memory.phase_trace
	var has_card_drawn := false
	var has_spawn := false
	for entry in trace:
		var line := str(entry)
		if line.begins_with("RESOLVE:encounter_card_drawn@"):
			has_card_drawn = true
		if line.begins_with("RESOLVE:encounter_spawn@"):
			has_spawn = true
	return (
		res.get("ok", false)
		and enemy != null
		and enemy.engaged_with == &"inv_1"
		and inv.threat_area.has(card_id)
		and has_card_drawn
		and has_spawn
	)


func _test_enc_hidden_enemy_no_spawn() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.memory.clear_trace()
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"enc_hidden_enemy",
		{"keywords": [&"hidden"], "hidden": true}
	)
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var card := h.ctx.state.registry.get_card(card_id)
	var has_spawn := false
	for entry in h.ctx.memory.phase_trace:
		if str(entry).begins_with("RESOLVE:encounter_spawn@"):
			has_spawn = true
	return (
		inv1.hand.has(card_id)
		and card.is_hidden
		and card.zone == AhcEnums.Zone.HAND
		and card.face_known_to(&"inv_1")
		and not card.face_known_to(&"inv_2")
		and h.ctx.state.registry.get_enemy(card_id) == null
		and not inv1.threat_area.has(card_id)
		and not has_spawn
		and h.ctx.registrations.has_hidden_leave_hand_restriction(card_id)
	)


func _test_enc_hidden_enemy_hand_spawn() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.memory.clear_trace()
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"enc_hidden_spawn",
		{"keywords": [&"hidden"], "hidden": true}
	)
	var draw_res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not draw_res.get("ok", false):
		return false
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	if not inv1.hand.has(card_id):
		return false
	h.ctx.memory.clear_trace()
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(
		CompositionNode.seq([
			CompositionNode.expose_hidden(card_id),
			CompositionNode.spawn_encounter_enemy(card_id, &"inv_1"),
		])
	)
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	var card := h.ctx.state.registry.get_card(card_id)
	var has_spawn := false
	for entry in h.ctx.memory.phase_trace:
		if str(entry).begins_with("RESOLVE:encounter_spawn@"):
			has_spawn = true
	return (
		enemy != null
		and enemy.engaged_with == &"inv_1"
		and inv1.threat_area.has(card_id)
		and not inv1.hand.has(card_id)
		and not card.is_hidden
		and card.face_known_to(&"inv_2")
		and card.zone == AhcEnums.Zone.PLAY_AREA
		and has_spawn
		and not h.ctx.registrations.has_hidden_leave_hand_restriction(card_id)
	)


func _test_enc_hidden_secret_hand() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	CardRegistry.register_definition(&"enc_hidden_t", {"card_type": &"treachery"})
	CardRegistry.register_revelation(
		&"enc_hidden_t",
		&"revelation:0",
		func(bind: AbilityBindContext) -> CompositionNode:
			return CompositionNode.commit_hidden_enter_hand(bind.card_id, bind.controller_id)
	)
	var card_id := GameBootstrap.add_encounter_card_to_deck(
		h.ctx, &"enc_hidden_t", [&"hidden"]
	)
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var card := h.ctx.state.registry.get_card(card_id)
	return (
		inv1.hand.has(card_id)
		and card.is_hidden
		and card.zone == AhcEnums.Zone.HAND
		and card.face_known_to(&"inv_1")
		and not card.face_known_to(&"inv_2")
		and h.ctx.state.encounter_discard.is_empty()
		and h.ctx.registrations.has_hidden_leave_hand_restriction(card_id)
	)


func _test_enc_hidden_forbid_leave_hand() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var card_id := GameBootstrap.add_encounter_card_to_deck(
		h.ctx,
		&"enc_hidden_no_leave",
		[&"hidden"]
	)
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	if not h.ctx.registrations.has_hidden_leave_hand_restriction(card_id):
		return false
	var blocked_enc := not h.ctx.mutator.move_card(
		card_id, CardSlot.encounter_discard_top()
	)
	var blocked_inv := not h.ctx.mutator.move_card(
		card_id, CardSlot.discard_top(&"inv_1")
	)
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	return blocked_enc and blocked_inv and inv1.hand.has(card_id)


func _test_enc_default_reveal_all() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var card_id := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_plain_e2", [])
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var card := h.ctx.state.registry.get_card(card_id)
	return (
		card.face_known_to(&"inv_1")
		and card.face_known_to(&"inv_2")
		and card.zone == AhcEnums.Zone.DISCARD
		and h.ctx.state.encounter_discard.has(card_id)
	)


func _test_enc_shuffle_discard() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_encounter_card_to_discard(h.ctx, &"enc_from_disc")
	h.ctx.state.encounter_deck.clear()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var horror_before := inv.horror_taken
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var cards: Array = res.get("cards", [])
	var card := h.ctx.state.registry.get_card(card_id)
	return (
		cards.size() == 1
		and cards[0] == card_id
		and res.get("shuffled", false)
		and int(res.get("shuffles", 0)) == 1
		and inv.horror_taken == horror_before
		and card.zone == AhcEnums.Zone.DISCARD
		and h.ctx.state.encounter_deck.is_empty()
		and h.ctx.state.encounter_discard.has(card_id)
	)


func _test_enc_surge_shuffles_discard() -> bool:
	var h := RuleTestHarness.new(42)
	var plain := GameBootstrap.add_encounter_card_to_discard(h.ctx, &"enc_plain_mid")
	var surge := GameBootstrap.add_encounter_card_to_deck(
		h.ctx, &"enc_surge_mid", [&"surge"]
	)
	h.ctx.state.encounter_deck = [surge] as Array[StringName]
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var cards: Array = res.get("cards", [])
	var plain_card := h.ctx.state.registry.get_card(plain)
	return (
		cards.size() == 2
		and cards[0] == surge
		and cards[1] == plain
		and int(res.get("surge_depth", 0)) == 1
		and res.get("shuffled", false)
		and int(res.get("shuffles", 0)) == 1
		and plain_card.zone == AhcEnums.Zone.DISCARD
		and h.ctx.state.encounter_discard.has(plain)
		and h.ctx.state.encounter_deck.has(surge)
	)


func _test_enc_both_piles_empty() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.state.encounter_deck.clear()
	h.ctx.state.encounter_discard.clear()
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	return not res.get("ok", false) and res.get("error", &"") == &"encounter_piles_empty"


func _test_wkn_asset_weakness_investigator_draw() -> bool:
	var h := RuleTestHarness.new(42)
	CardRegistry.register_definition(&"wkn_asset_rev", {"card_type": &"asset", "is_weakness": true})
	CardRegistry.register_revelation(
		&"wkn_asset_rev",
		&"revelation:0",
		func(bind: AbilityBindContext) -> CompositionNode:
			return CompositionNode.adjust_marker(
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.HORROR_TAKEN),
				1
			)
	)
	var card_id := GameBootstrap.add_investigator_weakness_to_deck(
		h.ctx, &"inv_1", &"wkn_asset_rev", &"asset"
	)
	var res := h.ctx.draw_investigator.draw_cards(h.ctx, &"inv_1", 1, [&"test"])
	if not res.get("ok", false):
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var card := h.ctx.state.registry.get_card(card_id)
	var revelations: Array = res.get("revelations", [])
	return (
		inv.hand.has(card_id)
		and inv.horror_taken == 1
		and card.zone == AhcEnums.Zone.HAND
		and revelations.size() == 1
		and h.ctx.state.registry.get_enemy(card_id) == null
	)


func _test_wkn_enemy_weakness_resolve_bound() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var card_id := GameBootstrap.add_investigator_weakness_to_deck(
		h.ctx,
		&"inv_1",
		&"wkn_enemy",
		&"enemy",
		{"enemy": {"fight": 2, "evade": 2, "health": 1}},
	)
	var res := h.ctx.draw_investigator.draw_cards(h.ctx, &"inv_1", 1, [&"test"])
	if not res.get("ok", false):
		return false
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	var card := h.ctx.state.registry.get_card(card_id)
	return (
		res.get("drew", false)
		and not inv1.hand.has(card_id)
		and not inv1.deck.has(card_id)
		and enemy != null
		and enemy.engaged_with == &"inv_1"
		and inv1.threat_area.has(card_id)
		and card.zone == AhcEnums.Zone.PLAY_AREA
		and card.face_known_to(&"inv_1")
		and card.face_known_to(&"inv_2")
	)


func _test_stat_cold_fold_action_count() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var template := RegistrationTemplate.new()
	template.controller_id = &"inv_1"
	template.stat_queries = [StatQuery.turn_action_spend_count_ge(3)]
	h.ctx.registrations.register(template)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.actions_remaining = 3
	for _i in 3:
		if not h.take_resource_action().ok:
			return false
	var eval_ctx := EvaluationContext.from_game(null, h.ctx.state, h.ctx.events)
	var count := int(
		h.ctx.stat_projections.get_value(StatQuery.turn_action_spend_count_ge(3), eval_ctx)
	)
	return count >= 3


func _test_stat_hot_projection_increments() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var template := RegistrationTemplate.new()
	template.controller_id = &"inv_1"
	template.stat_queries = [StatQuery.turn_action_spend_count_ge(1)]
	h.ctx.registrations.register(template)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.actions_remaining = 4
	for _i in 3:
		if not h.take_resource_action().ok:
			return false
	var eval_ctx := EvaluationContext.from_game(null, h.ctx.state, h.ctx.events)
	var q := StatQuery.turn_action_spend_count_ge(1)
	if int(h.ctx.stat_projections.get_value(q, eval_ctx)) != 3:
		return false
	if h.ctx.stat_projections.hot_count() < 1:
		return false
	if not h.take_resource_action().ok:
		return false
	return int(h.ctx.stat_projections.get_value(q, eval_ctx)) == 4


func _test_stat_unregister_drops_hot() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var template := RegistrationTemplate.new()
	template.controller_id = &"inv_1"
	template.stat_queries = [StatQuery.turn_action_spend_count_ge(1)]
	var reg_id := h.ctx.registrations.register(template)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.actions_remaining = 2
	if not h.take_resource_action().ok:
		return false
	var eval_ctx := EvaluationContext.from_game(null, h.ctx.state, h.ctx.events)
	h.ctx.stat_projections.get_value(StatQuery.turn_action_spend_count_ge(1), eval_ctx)
	if h.ctx.stat_projections.hot_count() < 1:
		return false
	h.ctx.registrations.unregister(reg_id)
	if h.ctx.stat_projections.hot_count() != 0:
		return false
	inv.actions_remaining = 1
	if not h.take_resource_action().ok:
		return false
	return h.ctx.stat_projections.hot_count() == 0


func _test_stat_condition_min_action_spends() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var template := RegistrationTemplate.new()
	template.controller_id = &"inv_1"
	template.stat_queries = [StatQuery.turn_action_spend_count_ge(2)]
	h.ctx.registrations.register(template)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.actions_remaining = 2
	var cond := Condition.with_min_action_spends(2)
	var app_ctx := ApplicationContext.new()
	var eval_ctx := EvaluationContext.from_game(app_ctx, h.ctx.state, h.ctx.events)
	var snap := h.ctx.stat_projections.ensure_hot_for_registrations(eval_ctx)
	if cond.matches_with_snapshot(app_ctx, snap, eval_ctx):
		return false
	if not h.take_resource_action().ok:
		return false
	snap = h.ctx.stat_projections.ensure_hot_for_registrations(eval_ctx)
	if cond.matches_with_snapshot(app_ctx, snap, eval_ctx):
		return false
	if not h.take_resource_action().ok:
		return false
	snap = h.ctx.stat_projections.ensure_hot_for_registrations(eval_ctx)
	return cond.matches_with_snapshot(app_ctx, snap, eval_ctx)


func _test_st_peril_blocks_ally() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var card_id := GameBootstrap.add_skill_card_to_hand(
		h.ctx, &"inv_2", AhcEnums.SkillType.INTELLECT
	)
	var enc_id := &"enc_peril_1"
	var frame := EncounterResolutionFrame.create(&"inv_1")
	frame.current_card_id = enc_id
	h.ctx.memory.push_encounter_frame(frame)
	EncounterPeril.register_if_peril(h.ctx, &"inv_1", enc_id, true)
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 2)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	var res := h.ctx.skill_tests.commit_card(test, &"inv_2", card_id)
	return not res.ok and res.error == "peril_no_assist"


func _test_peril_frame_blocks_ally() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var card_id := GameBootstrap.add_skill_card_to_hand(
		h.ctx, &"inv_2", AhcEnums.SkillType.INTELLECT
	)
	var enc_id := &"enc_peril_1"
	var frame := EncounterResolutionFrame.create(&"inv_1")
	frame.current_card_id = enc_id
	h.ctx.memory.push_encounter_frame(frame)
	EncounterPeril.register_if_peril(h.ctx, &"inv_1", enc_id, true)
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 2)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	var res := h.ctx.skill_tests.commit_card(test, &"inv_2", card_id)
	return not res.ok and res.error == "peril_no_assist" and test.peril


func _test_peril_not_sticky_across_cards() -> bool:
	var h := RuleTestHarness.new(42)
	var card_a := &"enc_a"
	var card_b := &"enc_b"
	EncounterPeril.register_if_peril(h.ctx, &"inv_1", card_a, true)
	if h.ctx.registrations.count() != 1:
		return false
	EncounterPeril.unregister_for_card(h.ctx, card_a)
	return h.ctx.registrations.count() == 0


func _test_peril_unregister_allows_ally() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var card_id := GameBootstrap.add_skill_card_to_hand(
		h.ctx, &"inv_2", AhcEnums.SkillType.INTELLECT
	)
	var enc_id := &"enc_peril_1"
	var frame := EncounterResolutionFrame.create(&"inv_1")
	frame.current_card_id = enc_id
	h.ctx.memory.push_encounter_frame(frame)
	EncounterPeril.register_if_peril(h.ctx, &"inv_1", enc_id, true)
	EncounterPeril.unregister_for_card(h.ctx, enc_id)
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 2)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	var res := h.ctx.skill_tests.commit_card(test, &"inv_2", card_id)
	return res.ok


func _test_st_apply_success() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 2)
	var flags := {"applied": false}
	test.on_success = func(_ctx: SkillTestContext) -> void:
		flags.applied = true
	st.run(test)
	return flags.applied


func _test_st_end_cleanup() -> bool:
	var h := RuleTestHarness.new(42)
	var token := ChaosToken.numeric(0, &"tok_1")
	GameBootstrap.setup_chaos_bag(h.ctx, [token])
	var card_id := GameBootstrap.add_skill_card_to_hand(
		h.ctx, &"inv_1", AhcEnums.SkillType.INTELLECT
	)
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 2)
	var commits: Array[CommittedCard] = [CommittedCard.create(card_id, &"inv_1")]
	st.run(test, commits)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var card := h.ctx.state.registry.get_card(card_id)
	return (
		h.ctx.skill_test_stack.is_empty()
		and inv.hand.is_empty()
		and inv.discard.has(card_id)
		and card.zone == AhcEnums.Zone.DISCARD
		and h.ctx.state.chaos_bag.tokens.size() == 1
		and h.ctx.state.chaos_bag.revealed_this_test.is_empty()
	)


func _test_act_investigate_success() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var loc := h.ctx.state.registry.get_location(&"test_loc")
	loc.clues = 2
	var res := h.investigate_action()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return res.ok and res.success and loc.clues == 1 and inv.clues_on_card == 1


func _test_act_investigate_fail() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var loc := h.ctx.state.registry.get_location(&"test_loc")
	loc.shroud = 9
	loc.clues = 2
	var inv_before := h.ctx.state.registry.get_investigator(&"inv_1")
	var res := h.investigate_action()
	return res.ok and not res.success and loc.clues == 2 and inv_before.clues_on_card == 0


func _test_act_fight_success() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	var res := h.fight_action({"enemy_id": &"enemy_1"})
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	return res.ok and res.success and enemy.damage == 1


func _test_act_evade_success() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(
		h.ctx, &"enemy_1", &"test_loc", 2, 2, &"inv_1"
	)
	var res := h.evade_action({"enemy_id": &"enemy_1"})
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	return res.ok and res.success and enemy.exhausted and enemy.engaged_with == &""


func _test_act_evade_not_engaged() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	var res := h.evade_action({"enemy_id": &"enemy_1"})
	return not res.ok and res.error == "not_engaged"


func _test_act_fight_aloof() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2, &"", true)
	var res := h.fight_action({"enemy_id": &"enemy_1"})
	return not res.ok and res.error == "aloof"


func _test_act_engage_success() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	var res := h.engage_action({"enemy_id": &"enemy_1"})
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	return res.ok and inv.threat_area.has(&"enemy_1") and enemy.is_engaged_with(&"inv_1")


func _test_act_engage_steal() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	GameBootstrap.setup_test_enemy(
		h.ctx, &"enemy_1", &"test_loc", 2, 2, &"inv_2"
	)
	var inv2_before := h.ctx.state.registry.get_investigator(&"inv_2")
	inv2_before.threat_area.append(&"enemy_1")
	var res := h.engage_action({"enemy_id": &"enemy_1"})
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	return (
		res.ok
		and enemy.is_engaged_with(&"inv_1")
		and inv1.threat_area.has(&"enemy_1")
		and not inv2.threat_area.has(&"enemy_1")
	)


func _test_act_engage_massive() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(
		h.ctx, &"enemy_1", &"test_loc", 2, 2, &"", false, true
	)
	var res := h.engage_action({"enemy_id": &"enemy_1"})
	return not res.ok and res.error == "massive"


func _test_act_engage_then_fight() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(
		h.ctx, &"enemy_1", &"test_loc", 2, 2, &"", true
	)
	if not h.engage_action({"enemy_id": &"enemy_1"}).ok:
		return false
	h.ctx.state.registry.get_investigator(&"inv_1").actions_remaining = 1
	var fight_res := h.fight_action({"enemy_id": &"enemy_1"})
	return fight_res.ok and fight_res.success


func _test_aoo_resource() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2, &"inv_1")
	h.ctx.state.registry.get_investigator(&"inv_1").threat_area.append(&"enemy_1")
	var pool_before := h.ctx.state.registry.get_investigator(&"inv_1").resource_pool
	var res := h.take_resource_action()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return res.ok and inv.damage_taken == 1 and inv.resource_pool == pool_before + 1 and int(res.aoo_attacks) == 1


func _test_aoo_fight_skip() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2, &"inv_1")
	h.ctx.state.registry.get_investigator(&"inv_1").threat_area.append(&"enemy_1")
	var res := h.fight_action({"enemy_id": &"enemy_1"})
	return res.ok and int(res.aoo_attacks) == 0 and h.ctx.state.registry.get_investigator(&"inv_1").damage_taken == 0


func _test_aoo_exhausted_skip() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2, &"inv_1")
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	enemy.exhausted = true
	h.ctx.state.registry.get_investigator(&"inv_1").threat_area.append(&"enemy_1")
	var res := h.take_resource_action()
	return res.ok and int(res.aoo_attacks) == 0 and h.ctx.state.registry.get_investigator(&"inv_1").damage_taken == 0


func _test_act_move_success() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_location(h.ctx, &"loc_b", 1, 0)
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"loc_b")
	var res := h.move_action({"destination_id": &"loc_b"})
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return res.ok and inv.location_tag == &"loc_b" and int(res.aoo_attacks) == 0


func _test_act_move_fail() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_location(h.ctx, &"loc_far", 1, 0)
	var res := h.move_action({"destination_id": &"loc_far"})
	return not res.ok and res.error == "not_connected"


func _test_act_draw_from_deck() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var card_id := GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var res := h.draw_action()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return res.ok and res.drew and inv.hand.has(card_id) and inv.deck.is_empty()


func _test_act_draw_shuffle() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var card_id := GameBootstrap.add_test_card_to_discard(h.ctx, &"inv_1")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.deck.clear()
	var res := h.draw_action()
	return (
		res.ok
		and res.drew
		and res.shuffled
		and res.horror_taken == 1
		and inv.hand.has(card_id)
		and inv.discard.is_empty()
		and not inv.deck.has(card_id)
	)


func _test_act_draw_defeated() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.deck.clear()
	inv.discard.clear()
	var res := h.draw_action()
	return res.ok and res.defeated and inv.eliminated


func _test_vis_draw_reveal_before_hand() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var card := h.ctx.state.registry.get_card(card_id)
	if card == null:
		return false
	if card.face_known_to(&"inv_1"):
		return false
	var bound := h.ctx.mutator.bind_deck_top(&"inv_1")
	if bound != card_id:
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	if not inv.deck.has(card_id):
		return false
	if not h.ctx.mutator.reveal_drawn_card(card_id, &"inv_1"):
		return false
	if not card.face_known_to(&"inv_1"):
		return false
	if card.zone != AhcEnums.Zone.DECK:
		return false
	return h.ctx.mutator.enter_hand_from_deck(card_id, &"inv_1") and inv.hand.has(card_id)


func _test_vis_draw_controller_only() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var card_id := GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var res := h.draw_action()
	if not res.ok or not res.drew:
		return false
	var card := h.ctx.state.registry.get_card(card_id)
	return card.face_known_to(&"inv_1") and not card.face_known_to(&"inv_2")


func _test_draw_two_simultaneous() -> bool:
	var h := RuleTestHarness.new(42)
	var a := GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1", &"card_a")
	var b := GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1", &"card_b")
	var res := h.ctx.draw_investigator.draw_cards(h.ctx, &"inv_1", 2, [&"test"])
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var drawn: Array = res.get("drawn", [])
	return (
		res.ok
		and res.drew
		and drawn.size() == 2
		and inv.hand.has(a)
		and inv.hand.has(b)
		and inv.deck.is_empty()
		and not res.defeated
	)


func _test_draw_two_mid_shuffle() -> bool:
	var h := RuleTestHarness.new(42)
	var top := GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1", &"top")
	var from_disc := GameBootstrap.add_test_card_to_discard(h.ctx, &"inv_1", &"from_disc")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.deck = [top] as Array[StringName]
	var res := h.ctx.draw_investigator.draw_cards(h.ctx, &"inv_1", 2, [&"test"])
	return (
		res.ok
		and res.drew
		and res.shuffled
		and res.horror_taken == 1
		and inv.hand.size() == 2
		and inv.hand.has(top)
		and inv.hand.has(from_disc)
		and inv.discard.is_empty()
	)


func _test_ent_revelation_take_horror() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1", &"rev_take_horror")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var res := h.ctx.draw_investigator.draw_cards(h.ctx, &"inv_1", 1, [&"test"])
	var revelations: Array = res.get("revelations", [])
	return (
		res.ok
		and res.drew
		and inv.hand.has(card_id)
		and inv.horror_taken == 1
		and revelations.size() == 1
		and revelations[0] == card_id
	)


func _test_ent_no_revelation() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1", &"plain_weakness")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var res := h.ctx.draw_investigator.draw_cards(h.ctx, &"inv_1", 1, [&"test"])
	var revelations: Array = res.get("revelations", [])
	return (
		res.ok
		and res.drew
		and inv.hand.has(card_id)
		and inv.horror_taken == 0
		and revelations.is_empty()
	)


func _test_ent_revelation_order() -> bool:
	var h := RuleTestHarness.new(42)
	var first := GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1", &"rev_take_horror")
	var second := GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1", &"rev_limbo_discard")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var res := h.ctx.draw_investigator.draw_cards(h.ctx, &"inv_1", 2, [&"test"])
	var revelations: Array = res.get("revelations", [])
	var second_card := h.ctx.state.registry.get_card(second)
	return (
		res.ok
		and res.drew
		and inv.hand.has(first)
		and not inv.hand.has(second)
		and inv.discard.has(second)
		and second_card.zone == AhcEnums.Zone.DISCARD
		and inv.horror_taken == 1
		and revelations.size() == 2
		and revelations[0] == first
		and revelations[1] == second
	)


func _test_reg_turn_end_tick() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionTestHelper.lasting_willpower_turn(&"inv_1", 1))
	if c.modifier_willpower(3, &"inv_1") != 4:
		return false
	if h.ctx.registrations.count() != 1:
		return false
	h.end_turn()
	return h.ctx.registrations.count() == 0 and c.modifier_willpower(3, &"inv_1") == 3


func _test_ns_lifo_nest() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.memory.clear_trace()
	var parent := TriggeringCondition.custom(&"parent_effect", &"inv_1")
	var child := TriggeringCondition.custom(&"child_effect", &"inv_1")
	h.ctx.sequences.run(
		parent,
		func() -> void:
			h.ctx.sequences.nest(child, func() -> void: pass)
	)
	var expected := [
		"WHEN:parent_effect@0",
		"RESOLVE:parent_effect@0",
		"WHEN:child_effect@1",
		"RESOLVE:child_effect@1",
		"AFTER:child_effect@1",
		"AFTER:parent_effect@0",
	]
	return h.ctx.memory.phase_trace == expected


func _test_ns_after_order() -> bool:
	var h := RuleTestHarness.new(42)
	var order: Array[String] = []
	h.ctx.sequences.register_handler(
		SequenceHandler.after_forced(&"parent_effect", func() -> void: order.append("parent_after"))
	)
	h.ctx.sequences.register_handler(
		SequenceHandler.after_forced(&"child_effect", func() -> void: order.append("child_after"))
	)
	var parent := TriggeringCondition.custom(&"parent_effect", &"inv_1")
	var child := TriggeringCondition.custom(&"child_effect", &"inv_1")
	h.ctx.sequences.run(
		parent,
		func() -> void:
			h.ctx.sequences.nest(child, func() -> void: pass)
	)
	return order == ["child_after", "parent_after"]


func _test_ns_upkeep_resource_modifier() -> bool:
	var h := RuleTestHarness.new(42)
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionTestHelper.upkeep_framework_resource_bonus(&"inv_1", 1))
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var pool_before := inv.resource_pool
	h.ctx.resource_gain.gain(h.ctx, &"inv_1", 1, [&"resource_action"])
	if inv.resource_pool != pool_before + 1:
		return false
	h.ctx.framework.current_step = AhcEnums.FrameworkStep.UPKEEP_4_4_DRAW_AND_RESOURCE
	h.ctx.resource_gain.gain(h.ctx, &"inv_1", 1, [&"framework", &"upkeep_4_4"])
	return inv.resource_pool == pool_before + 1 + 2


func _test_ns_gain_after_listener() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionTestHelper.after_gain_draw_listener(&"inv_1"))
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	if inv.deck.size() != 1 or inv.hand.size() != 0:
		return false
	h.ctx.resource_gain.gain(h.ctx, &"inv_1", 1, [&"resource_action"])
	return inv.deck.is_empty() and inv.hand.size() == 1


func _test_ns_refresh_after_nest() -> bool:
	var h := RuleTestHarness.new(42)
	var score := [0]
	var outer := SequenceHandler.when_forced(
		&"player_window",
		func() -> void:
			score[0] += 1
			if score[0] == 1:
				var inner := SequenceHandler.when_forced(
					&"player_window",
					func() -> void: score[0] += 10
				)
				h.ctx.sequences.register_handler(inner)
	)
	h.ctx.sequences.register_handler(outer)
	h.ctx.sequences.run(TriggeringCondition.custom(&"player_window", &"inv_1"), func() -> void: pass)
	return score[0] == 11 and h.ctx.sequences.response_round() == 0


func _test_ns_self_response_blocked() -> bool:
	var h := RuleTestHarness.new(42)
	var reaction_fired := [false]
	var reaction := SequenceHandler.after_reaction(
		&"draw_cards",
		&"card_a",
		&"inv_1",
		func() -> void: reaction_fired[0] = true
	)
	h.ctx.sequences.register_handler(reaction)
	var parent := TriggeringCondition.custom(&"play_card", &"inv_1")
	parent.after_timing = &""
	var draw := TriggeringCondition.custom(&"draw_cards", &"inv_1")
	h.ctx.sequences.run(
		parent,
		func() -> void:
			h.ctx.sequences.begin_ability_resolution(&"card_a")
			h.ctx.sequences.nest(draw, func() -> void: pass)
			h.ctx.sequences.end_ability_resolution()
	)
	return not reaction_fired[0]


func _test_pi_default_optional_decline() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.ctx.interaction.ask_optional_effect(&"inv_1", &"may:heal", h.ctx, false):
		return true
	return false


func _test_pi_scripting_resolver() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"pick:enemy", "pick": &"enemy_1"},
	])
	var pick: Variant = h.ctx.interaction.ask_pick_target([&"enemy_0", &"enemy_1"], &"inv_1", &"pick:enemy", h.ctx)
	return pick == &"enemy_1"


func _test_fwk_upkeep_44_catalog() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	h.ctx.framework.refresh_player_order()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	if inv == null or inv.deck.size() != 1:
		return false
	var pool_before := inv.resource_pool
	var hand_before := inv.hand.size()
	h.ctx.framework.current_step = AhcEnums.FrameworkStep.UPKEEP_4_4_DRAW_AND_RESOURCE
	h.ctx.framework._on_enter_step(AhcEnums.FrameworkStep.UPKEEP_4_4_DRAW_AND_RESOURCE)
	if inv.hand.size() != hand_before + 1 or not inv.deck.is_empty():
		return false
	if inv.resource_pool != pool_before + 1:
		return false
	return true


func _test_fwk_mythos_14_encounter_draw() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	if not h.run_full_round_one_investigator():
		return false
	h.ctx.framework.advance()
	if h.ctx.framework.round_number != 2:
		return false
	if not h.run_through_step(AhcEnums.FrameworkStep.MYTHOS_1_4_DRAW_ENCOUNTER_EACH):
		return false
	var card_id := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"fwk_mythos_enc")
	h.ctx.framework.advance()
	var card := h.ctx.state.registry.get_card(card_id)
	var step_ok := (
		h.framework_step() == AhcEnums.FrameworkStep.MYTHOS_1_5_PHASE_ENDS
		and h.ctx.framework.waiting_player_window
	)
	var card_ok := (
		card != null
		and card.zone == AhcEnums.Zone.DISCARD
		and h.ctx.state.encounter_deck.is_empty()
		and h.ctx.state.encounter_discard.has(card_id)
	)
	h.close_windows()
	return step_ok and card_ok


func _test_fwk_mythos_14_two_investigators() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	h.run_setup()
	h.ctx.framework.refresh_player_order()
	if h.ctx.framework.player_order.size() != 2:
		return false
	if not h.run_full_round_investigators(2):
		return false
	h.ctx.framework.advance()
	if h.ctx.framework.round_number != 2:
		return false
	if not h.run_through_step(AhcEnums.FrameworkStep.MYTHOS_1_4_DRAW_ENCOUNTER_EACH):
		return false
	var card_1 := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"fwk_mythos_enc_a")
	var card_2 := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"fwk_mythos_enc_b")
	h.ctx.framework.advance()
	var after_first := (
		h.framework_step() == AhcEnums.FrameworkStep.MYTHOS_1_4_DRAW_ENCOUNTER_EACH
		and h.ctx.framework.waiting_player_window
		and h.ctx.framework.pending_player_window == AhcEnums.PlayerWindow.PW_MYTHOS_AFTER_ENCOUNTER_DRAW
		and h.ctx.framework.investigators_remaining_this_phase == [&"inv_2"]
	)
	var c1 := h.ctx.state.registry.get_card(card_1)
	var after_first_cards := (
		c1 != null
		and c1.zone == AhcEnums.Zone.DISCARD
		and h.ctx.state.encounter_deck.size() == 1
	)
	h.ctx.framework.close_player_window_and_continue()
	var c2 := h.ctx.state.registry.get_card(card_2)
	var after_second := (
		h.framework_step() == AhcEnums.FrameworkStep.MYTHOS_1_5_PHASE_ENDS
		and h.ctx.framework.waiting_player_window
		and c2 != null
		and c2.zone == AhcEnums.Zone.DISCARD
		and h.ctx.state.encounter_deck.is_empty()
		and h.ctx.state.encounter_discard.has(card_1)
		and h.ctx.state.encounter_discard.has(card_2)
	)
	h.close_windows()
	return after_first and after_first_cards and after_second


func _test_fwk_mythos_14_enemy_spawn() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	if not h.run_full_round_one_investigator():
		return false
	h.ctx.framework.advance()
	if h.ctx.framework.round_number != 2:
		return false
	if not h.run_through_step(AhcEnums.FrameworkStep.MYTHOS_1_4_DRAW_ENCOUNTER_EACH):
		return false
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(h.ctx, &"fwk_mythos_enemy")
	h.ctx.framework.advance()
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var card := h.ctx.state.registry.get_card(card_id)
	var step_ok := (
		h.framework_step() == AhcEnums.FrameworkStep.MYTHOS_1_5_PHASE_ENDS
		and h.ctx.framework.waiting_player_window
	)
	var spawn_ok := (
		enemy != null
		and enemy.engaged_with == &"inv_1"
		and enemy.location_tag == &"test_loc"
		and inv.threat_area.has(card_id)
		and card.zone == AhcEnums.Zone.PLAY_AREA
		and not h.ctx.state.encounter_discard.has(card_id)
	)
	h.close_windows()
	return step_ok and spawn_ok


func _test_fwk_mythos_14_spawn_instruction_named() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	if not h.run_full_round_one_investigator():
		return false
	h.ctx.framework.advance()
	if not h.run_through_step(AhcEnums.FrameworkStep.MYTHOS_1_4_DRAW_ENCOUNTER_EACH):
		return false
	GameBootstrap.setup_test_location(h.ctx, &"loc_b")
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"fwk_spawn_named",
		{"spawn_instruction": SpawnInstructionSpec.at_named_location(&"loc_b")}
	)
	h.ctx.framework.advance()
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var card := h.ctx.state.registry.get_card(card_id)
	var step_ok := (
		h.framework_step() == AhcEnums.FrameworkStep.MYTHOS_1_5_PHASE_ENDS
		and h.ctx.framework.waiting_player_window
	)
	var spawn_ok := (
		enemy != null
		and enemy.location_tag == &"loc_b"
		and enemy.engaged_with == &""
		and not inv.threat_area.has(card_id)
		and card.zone == AhcEnums.Zone.PLAY_AREA
	)
	h.close_windows()
	return step_ok and spawn_ok


func _test_fwk_mythos_14_spawn_instruction_auto_engage() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(
		h.ctx, &"inv_2", &"test_loc", {"willpower": 5}
	)
	h.run_setup()
	h.ctx.framework.refresh_player_order()
	if not h.run_full_round_investigators(2):
		return false
	h.ctx.framework.advance()
	if h.ctx.framework.round_number != 2:
		return false
	if not h.run_through_step(AhcEnums.FrameworkStep.MYTHOS_1_4_DRAW_ENCOUNTER_EACH):
		return false
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"fwk_spawn_drawer_prey",
		{
			"spawn_instruction": SpawnInstructionSpec.at_drawer_location(),
			"prey_instruction": PreyInstructionSpec.highest(AhcEnums.SkillType.WILLPOWER),
		}
	)
	var filler_id := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"fwk_spawn_fill")
	h.ctx.framework.advance()
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	var card := h.ctx.state.registry.get_card(card_id)
	var after_first := (
		h.framework_step() == AhcEnums.FrameworkStep.MYTHOS_1_4_DRAW_ENCOUNTER_EACH
		and h.ctx.framework.waiting_player_window
		and h.ctx.framework.pending_player_window == AhcEnums.PlayerWindow.PW_MYTHOS_AFTER_ENCOUNTER_DRAW
		and enemy != null
		and enemy.location_tag == &"test_loc"
		and enemy.engaged_with == &"inv_2"
		and inv2.threat_area.has(card_id)
		and not inv1.threat_area.has(card_id)
		and card.zone == AhcEnums.Zone.PLAY_AREA
	)
	h.ctx.framework.close_player_window_and_continue()
	var filler := h.ctx.state.registry.get_card(filler_id)
	var after_second := (
		h.framework_step() == AhcEnums.FrameworkStep.MYTHOS_1_5_PHASE_ENDS
		and h.ctx.framework.waiting_player_window
		and filler != null
		and filler.zone == AhcEnums.Zone.DISCARD
		and h.ctx.state.encounter_deck.is_empty()
	)
	h.close_windows()
	return after_first and after_second
