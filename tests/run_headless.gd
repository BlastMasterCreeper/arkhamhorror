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
	_run_test("F-05 mythos 1.3 agenda advance", _test_f05_mythos_agenda_advance)
	_run_test("SC-04 agenda doom advance clears doom", _test_sc04_agenda_advance_clears_doom)
	_run_test("C-01 dry-run register created", _test_dry_run_register_only)
	_run_test("C-02 dry-run draw empty deck illegal", _test_dry_run_draw_empty)
	_run_test("C-03 dry-run draw or register", _test_dry_run_draw_or_register)
	_run_test("C-04 register applies modifier", _test_register_modifier)
	_run_test("C-05 restriction blocks draw dry-run", _test_restriction_blocks_draw)
	_run_test("C-06 listener draws on timing", _test_listener_draw_on_timing)
	_run_test("C-07 until_fired listener removes self", _test_until_fired_listener)
	_run_test("C-08 initiation dry-run gate", _test_initiation_dry_run_gate)
	_run_test("C-09 choice dry-run OR branch", _test_dry_run_choice_or)
	_run_test("C-10 must choice auto-picks sole branch", _test_must_choice_auto_pick)
	_run_test("C-11 must choice skips all fizzle", _test_must_choice_skip_fizzle)
	_run_test("C-12 must choice asks when multiple", _test_must_choice_pick_option)
	_run_test("C-13 repeat fail-by must choice", _test_repeat_fail_by_must_choice)
	_run_test("ENC-ST-01 revelation skill test nests", _test_enc_skill_test_nest)
	_run_test("ENC-ST-02 fail-by resolves at ST.7", _test_enc_st7_fail_by_timing)
	_run_test("INIT-01 initiation records full sequence", _test_initiation_sequence_events)
	_run_test("INIT-02 play card aborts when cannot pay", _test_initiation_play_cost_abort)
	_run_test("INIT-03 play card runs initiation pipeline", _test_initiation_play_card_pipeline)
	_run_test("INIT-04 cost modifier reduces play cost", _test_initiation_cost_modifier)
	_run_test("INIT-05 action ability provokes AOO", _test_initiation_action_aoo)
	_run_test("INIT-06 on_play composition resolves", _test_initiation_on_play)
	_run_test("INIT-07 refunds costs after post-AOO abort", _test_initiation_post_aoo_refund)
	_run_test("TRIG-01 forced triggered bypasses initiation", _test_trig_forced_after_gain)
	_run_test("TRIG-02 reaction declined by default", _test_trig_reaction_declined)
	_run_test("TRIG-03 reaction accepted resolves", _test_trig_reaction_accepted)
	_run_test("TRIG-04 peril blocks teammate triggered", _test_trig_peril_blocks)
	_run_test("TRIG-05 install triggered on asset play", _test_trig_install_on_play)
	_run_test("ADB-01 import core 2026 packs", _test_adb_import_counts)
	_run_test("ADB-02 import asset cost and skills", _test_adb_asset_local_map)
	_run_test("ADB-03 import weakness subtype", _test_adb_weakness_in_harms_way)
	_run_test("ADB-04 import treachery keywords", _test_adb_treachery_surge)
	_run_test("ADB-05 import hidden enemy", _test_adb_hidden_elokoss)
	_run_test("ADB-06 import peril treachery", _test_adb_peril_cosmic_evils)
	_run_test("ADB-07 import keyword bool fields", _test_adb_keyword_bools)
	_run_test("ADB-08 compile prey lowest agility", _test_adb_prey_lowest_agility)
	_run_test("ADB-09 compile prey most resources", _test_adb_prey_most_resources)
	_run_test("ADB-10 compile prey investigator only", _test_adb_prey_investigator_only)
	_run_test("ADB-11 compile spawn farthest empty", _test_adb_spawn_farthest_empty)
	_run_test("ADB-12 spawn farthest empty resolves", _test_adb_spawn_farthest_empty_play)
	_run_test("ADB-13 prey lowest agility engages", _test_adb_prey_lowest_agility_play)
	_run_test("ADB-14 segment in harms way", _test_adb_segment_in_harms_way)
	_run_test("ADB-15 compile enter threat revelation", _test_adb_compile_enter_threat)
	_run_test("ADB-16 breaking point damage revelation", _test_adb_breaking_point_revelation)
	_run_test("ADB-17 compile forbidden secrets surge", _test_adb_compile_forbidden_secrets)
	_run_test("ADB-18 ability compile summary", _test_adb_ability_compile_summary)
	_run_test("EFF-01 effect draw blocked by forbid_draw", _test_eff_draw_blocked)
	_run_test("EFF-02 effect draw resolves when allowed", _test_eff_draw_ok)
	_run_test("CAN-01 cancel pending draw", _test_can_cancel_pending_draw)
	_run_test("CAN-02 cancel fails after resolve", _test_can_cancel_after_resolve)
	_run_test("CAN-03 replacement fails after cancel", _test_can_replacement_after_cancel)
	_run_test("IGN-01 ignore keeps pending but skips apply", _test_ign_ignore_skips_apply)
	_run_test("IGN-02 ignore blocks replacement", _test_ign_blocks_replacement)
	_run_test("INT-01 catalog interrupt cancel pending", _test_int_catalog_interrupt_cancel)
	_run_test("CAN-ENC-01 ward cancel revelation discards", _test_can_enc_ward_cancel_revelation)
	_run_test("REPL-01 most recent replacement wins", _test_repl_most_recent_wins)
	_run_test("REPL-02 composition cancel replace resolve", _test_repl_composition_pipeline)
	_run_test("REPL-03 catalog replace instead pending", _test_repl_catalog_instead)
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
	_run_test("ENC-SURGE-02 dynamic keyword surge chain", _test_enc_surge_dynamic_keyword)
	_run_test("ENC-SURGE-03 gained surge survives g4 peril unregister", _test_enc_surge_keyword_survives_g4)
	_run_test("ENC-SURGE-04 forbidden secrets no clues", _test_enc_surge_12126_no_clues)
	_run_test("ENC-SURGE-05 forbidden secrets with clues skips gained", _test_enc_surge_12126_with_clues)
	_run_test("ENC-SURGE-05b forbidden secrets fail-by horror", _test_enc_surge_12126_fail_by_horror)
	_run_test("ENC-12124 cosmic evils agenda doom", _test_enc_12124_choice_agenda)
	_run_test("ENC-12124 cosmic evils agenda advance", _test_enc_12124_choice_agenda_advance)
	_run_test("ENC-12124 cosmic evils punish branch", _test_enc_12124_choice_punish)
	_run_test("ADB-20 compile cosmic evils choice", _test_adb_compile_cosmic_evils)
	_run_test("ADB-21 compile forbidden secrets fail-by", _test_adb_compile_forbidden_secrets_fail_by)
	_run_test("ADB-19 compile raising suspicions", _test_adb_compile_raising_suspicions)
	_run_test("ENC-SURGE-06 raising suspicions places doom", _test_enc_surge_12160_places_doom)
	_run_test("ENC-SURGE-07 raising suspicions no target gains surge", _test_enc_surge_12160_no_target_gained)
	_run_test("GAIN-01 effective keyword query", _test_gain_effective_keyword)
	_run_test("ENC-11 encounter revelation nests catalog", _test_enc_revelation_nest)
	_run_test("ENC-21 encounter spawn nests catalog", _test_enc_spawn_nest)
	_run_test("ENC-22 hidden enemy secret hand no spawn", _test_enc_hidden_enemy_no_spawn)
	_run_test("ENC-23 hidden enemy hand ability spawns", _test_enc_hidden_enemy_hand_spawn)
	_run_test("ENC-12 hidden treachery secret hand", _test_enc_hidden_secret_hand)
	_run_test("ENC-24 hidden privacy forbid leave hand", _test_enc_hidden_forbid_leave_hand)
	_run_test("ENC-25 hidden treachery effective threat area", _test_enc_hidden_treachery_threat_area)
	_run_test("ENC-26 hidden treachery card discard from hand", _test_enc_hidden_treachery_discard_from_hand)
	_run_test("ENC-27 elimination discards hidden hand encounter", _test_enc_elimination_hidden_hand)
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
	_run_test("REST-01 draw action blocked by forbid_draw", _test_rest_draw_action_blocked)
	_run_test("PERIL-02 peril blocks teammate play", _test_peril_blocks_teammate_play)
	_run_test("PERIL-03 peril blocks teammate trigger", _test_peril_blocks_teammate_trigger)
	_run_test("PERIL-06 drawer play and trigger allowed", _test_peril_drawer_play_trigger_ok)
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
	_run_test("ACT-16 fight fail redirects to engaged holder", _test_act_fight_fail_redirect)
	_run_test("AOO-01 resource provokes damage", _test_aoo_resource)
	_run_test("AOO-02 fight skips aoo", _test_aoo_fight_skip)
	_run_test("AOO-03 exhausted enemy skips aoo", _test_aoo_exhausted_skip)
	_run_test("ACT-11 move to connected location", _test_act_move_success)
	_run_test("ACT-12 move rejects disconnected", _test_act_move_fail)
	_run_test("ACT-13 draw from deck", _test_act_draw_from_deck)
	_run_test("ACT-14 draw shuffles discard", _test_act_draw_shuffle)
	_run_test("ACT-15 draw empty piles defeated", _test_act_draw_defeated)
	_run_test("ACT-CAT-01 action seq catalog registered", _test_act_catalog_registered)
	_run_test("ACT-CAT-02 action gain fires after_gain_resource", _test_act_catalog_gain_after_listener)
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
	_run_test("EN-01 enemy 3.2 hunter patrol move", _test_en01_hunter_patrol_move)
	_run_test("EN-13 patrol move toward target", _test_en13_patrol_move)
	_run_test("EN-14 patrol skip at target location", _test_en14_patrol_skip_at_target)
	_run_test("EN-02 enemy 3.3 phase attack", _test_en02_phase_attack)
	_run_test("EN-03 move toward must shorten", _test_en03_move_must_shorten)
	_run_test("EN-04 move toward lateral when no shorten", _test_en04_move_lateral_no_shorten)
	_run_test("EN-05 move toward lead picks tie", _test_en05_move_lead_picks_tie)
	_run_test("EN-06b disengage reselects at same location", _test_en06_disengage_reselects)
	_run_test("EN-08 massive spawn not in threat area", _test_en08_massive_spawn_virtual)
	_run_test("EN-09 massive phase attacks both", _test_en09_massive_phase_both)
	_run_test("EN-10 massive batch interrupt on exhaust", _test_en10_massive_interrupt)
	_run_test("EN-11 ready triggers auto engage", _test_en11_ready_triggers_engage)
	_run_test("EN-12 evade then ready re-engages", _test_en12_evade_ready_reengage)
	_run_test("EN-15 fight fail triggers retaliate", _test_en15_fight_fail_retaliate)
	_run_test("EN-16 evade fail triggers alert", _test_en16_evade_fail_alert)
	_run_test("EN-17 exhausted skips retaliate and alert", _test_en17_exhausted_skips_keywords)
	_run_test("EN-18 massive fight fail no redirect", _test_en18_massive_fight_fail_no_redirect)
	_run_test("EN-06 elusive after AOO flees", _test_en06_elusive_after_aoo)
	_run_test("EN-19 fight elusive enemy flees", _test_en19_fight_elusive_flees)
	_run_test("ADB-22 compile aerial pursuit", _test_adb_compile_aerial_pursuit)
	_run_test("ENC-12163 move engage immediate attack", _test_enc_12163_move_attack)
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


func _test_f05_mythos_agenda_advance() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	if not h.run_full_round_one_investigator():
		return false
	h.ctx.state.agenda_threshold = 1
	h.ctx.state.current_agenda_number = 1
	h.ctx.framework.advance()
	h.close_windows()
	if h.framework_step() != AhcEnums.FrameworkStep.MYTHOS_1_2_PLACE_DOOM:
		return false
	if h.ctx.state.doom_on_agenda != 1:
		return false
	h.ctx.framework.advance()
	return (
		h.framework_step() == AhcEnums.FrameworkStep.MYTHOS_1_3_CHECK_DOOM_THRESHOLD
		and h.ctx.state.current_agenda_number == 2
		and h.ctx.state.doom_on_agenda == 0
		and AgendaDoomPolicy.doom_in_play(h.ctx.state) == 0
	)


func _test_sc04_agenda_advance_clears_doom() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	h.ctx.state.agenda_threshold = 5
	h.ctx.state.doom_on_agenda = 2
	h.ctx.state.current_agenda_number = 1
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_sc04")
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_sc04")
	enemy.doom = 3
	var result := h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"mythos_1_3"}
	)
	return (
		bool(result.get("advanced", false))
		and h.ctx.state.doom_on_agenda == 0
		and enemy.doom == 0
		and h.ctx.state.current_agenda_number == 2
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


func _must_choice_horror(amount: int = 1) -> CompositionNode:
	return CompositionNode.adjust_marker(
		MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.HORROR_TAKEN),
		amount
	)


func _make_fail_by_st7_plan() -> SkillTestSt7Plan:
	var plan := SkillTestSt7Plan.new()
	plan.on_fail_by_each = CompositionNode.must_choose(
		[
			CompositionNode.place_clue_on_investigator_location(&"inv_1"),
			_must_choice_horror(),
		],
		&"inv_1",
		[&"clue", &"horror"]
	)
	return plan


func _test_dry_run_choice_or() -> bool:
	var h := RuleTestHarness.new(42)
	var c := CompositionTestHelper.new(h.ctx)
	var node := CompositionNode.must_choose(
		[CompositionNode.draw(&"inv_1"), _must_choice_horror()],
		&"inv_1"
	)
	return c.dry_run(node)


func _test_must_choice_auto_pick() -> bool:
	var h := RuleTestHarness.new(42)
	var c := CompositionTestHelper.new(h.ctx)
	var node := CompositionNode.must_choose(
		[CompositionNode.draw(&"inv_1"), _must_choice_horror()],
		&"inv_1",
		[&"draw", &"horror"]
	)
	c.execute(node)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return inv.horror_taken == 1 and inv.hand.is_empty()


func _test_must_choice_skip_fizzle() -> bool:
	var h := RuleTestHarness.new(42)
	var c := CompositionTestHelper.new(h.ctx)
	var node := CompositionNode.must_choose(
		[CompositionNode.draw(&"inv_1"), CompositionNode.draw(&"inv_1")],
		&"inv_1"
	)
	c.execute(node)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return inv.hand.is_empty() and inv.deck.is_empty()


func _test_must_choice_pick_option() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"12126")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"encounter"
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.HAND
	h.ctx.state.registry.register_card(card)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.hand.append(card_id)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([{"pick": &"surge"}])
	var node := CompositionNode.must_choose(
		[_must_choice_horror(), CompositionNode.grant_keyword(card_id, &"surge")],
		&"inv_1",
		[&"horror", &"surge"],
		&"test:must_choice"
	)
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(node)
	inv = h.ctx.state.registry.get_investigator(&"inv_1")
	return inv.horror_taken == 0 and h.ctx.registrations.count() == 1


func _test_repeat_fail_by_must_choice() -> bool:
	var h := RuleTestHarness.new(42)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.clues_on_card = 2
	inv.skill_intellect = 2
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([{"pick": &"horror"}])
	var node := CompositionNode.nest_skill_test(
		&"inv_1",
		AhcEnums.SkillType.INTELLECT,
		3,
		&"",
		_make_fail_by_st7_plan()
	)
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(node)
	inv = h.ctx.state.registry.get_investigator(&"inv_1")
	return inv.horror_taken == 1 and inv.clues_on_card == 2


func _test_enc_skill_test_nest() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.memory.clear_trace()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.skill_intellect = 2
	inv.clues_on_card = 2
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(
		CompositionNode.nest_skill_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 3, &"card_12126")
	)
	var has_skill_test := false
	for entry in h.ctx.memory.phase_trace:
		if str(entry).contains("skill_test"):
			has_skill_test = true
			break
	return (
		has_skill_test
		and h.ctx.composition.last_skill_test_fail_by() == 1
		and h.ctx.skill_tests.skill_test_step_count(AhcEnums.SkillTestStep.ST_8_END) >= 1
	)


func _test_enc_st7_fail_by_timing() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.clues_on_card = 2
	inv.skill_intellect = 2
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([{"pick": &"horror"}])
	var card_id := _adb_add_encounter_treachery_to_deck(h, &"12126")
	h.ctx.mutator.enter_limbo(card_id, &"inv_1")
	if not h.ctx.card_abilities.resolve_revelations(h.ctx, &"inv_1", card_id):
		return false
	var st6_idx := -1
	var st7_idx := -1
	var st8_idx := -1
	var horror_idx := -1
	var records := h.ctx.events.get_records()
	for i in records.size():
		var rec: EventRecord = records[i]
		if rec.kind == AhcEnums.EventRecordKind.SKILL_TEST_STEP:
			match rec.skill_test_step:
				AhcEnums.SkillTestStep.ST_6_RESOLVE_RESULT:
					st6_idx = i
				AhcEnums.SkillTestStep.ST_7_APPLY:
					st7_idx = i
				AhcEnums.SkillTestStep.ST_8_END:
					st8_idx = i
		if rec.kind == AhcEnums.EventRecordKind.COMPOSITION_STEP:
			if str(rec.payload.get("atom", "")) == "adjust_marker":
				horror_idx = i
	inv = h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		inv.horror_taken == 1
		and st6_idx >= 0
		and st8_idx > st6_idx
		and horror_idx > st6_idx
		and horror_idx < st8_idx
	)


func _test_adb_compile_cosmic_evils() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12124")
	if compiled.size() != 1:
		return false
	var entry: Dictionary = compiled[0]
	var options: Variant = entry.get("options", [])
	if not options is Array or (options as Array).size() != 2:
		return false
	return (
		CardRegistry.has_revelation(&"12124")
		and entry.get("template", "") == "choice_must"
		and (options[0] as Dictionary).get("template", "") == "place_doom_on_current_agenda"
		and bool((options[0] as Dictionary).get("may_advance_agenda", false))
		and (options[1] as Dictionary).get("template", "") == "seq"
	)


func _test_adb_compile_forbidden_secrets_fail_by() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12126")
	if compiled.size() != 1:
		return false
	var else_entry: Variant = compiled[0].get("else", {})
	if not else_entry is Dictionary:
		return false
	var else_dict := else_entry as Dictionary
	var st7: Variant = else_dict.get("st7", {})
	if not st7 is Dictionary:
		return false
	var each: Variant = (st7 as Dictionary).get("on_fail_by_each", {})
	return (
		else_dict.get("template", "") == "skill_test"
		and else_dict.get("skill", "") == "intellect"
		and each is Dictionary
		and (each as Dictionary).get("template", "") == "choice_must"
	)


func _test_enc_12124_choice_agenda() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([{"pick": &"agenda"}])
	var card_id := _adb_add_encounter_treachery_to_deck(h, &"12124")
	h.ctx.mutator.enter_limbo(card_id, &"inv_1")
	if not h.ctx.card_abilities.resolve_revelations(h.ctx, &"inv_1", card_id):
		return false
	return h.ctx.state.doom_on_agenda == 1


func _test_enc_12124_choice_agenda_advance() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	h.ctx.state.agenda_threshold = 1
	h.ctx.state.current_agenda_number = 1
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([{"pick": &"agenda"}])
	var card_id := _adb_add_encounter_treachery_to_deck(h, &"12124")
	h.ctx.mutator.enter_limbo(card_id, &"inv_1")
	if not h.ctx.card_abilities.resolve_revelations(h.ctx, &"inv_1", card_id):
		return false
	return (
		h.ctx.state.current_agenda_number == 2
		and h.ctx.state.doom_on_agenda == 0
		and AgendaDoomPolicy.doom_in_play(h.ctx.state) == 0
	)


func _test_enc_12124_choice_punish() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([{"pick": &"punish"}])
	var card_id := _adb_add_encounter_treachery_to_deck(h, &"12124")
	h.ctx.mutator.enter_limbo(card_id, &"inv_1")
	if not h.ctx.card_abilities.resolve_revelations(h.ctx, &"inv_1", card_id):
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		inv.damage_taken == 1
		and inv.horror_taken == 1
		and h.ctx.registrations.has_keyword_buff(card_id, &"surge")
	)


func _test_enc_surge_12126_fail_by_horror() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.clues_on_card = 2
	inv.skill_intellect = 2
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([{"pick": &"horror"}])
	var card_id := _adb_add_encounter_treachery_to_deck(h, &"12126")
	h.ctx.mutator.enter_limbo(card_id, &"inv_1")
	if not h.ctx.card_abilities.resolve_revelations(h.ctx, &"inv_1", card_id):
		return false
	inv = h.ctx.state.registry.get_investigator(&"inv_1")
	return inv.horror_taken == 1 and inv.clues_on_card == 2 and not h.ctx.registrations.has_keyword_buff(card_id, &"surge")


func _collect_initiation_steps(h: RuleTestHarness) -> Array:
	var out: Array = []
	for rec in h.ctx.events.get_records():
		if rec.kind == AhcEnums.EventRecordKind.INITIATION_STEP:
			out.append(rec.initiation_step)
	return out


func _test_initiation_sequence_events() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var intent := InitiationIntent.create(&"inv_1", CompositionNode.draw(&"inv_1"))
	var res := h.ctx.initiation.initiate(intent, h.ctx)
	if not res.ok:
		return false
	var expected: Array = [
		AhcEnums.InitiationStep.INIT_PRE_RESTRICTIONS,
		AhcEnums.InitiationStep.INIT_1_APPLY_MODIFIERS,
		AhcEnums.InitiationStep.INIT_2_PAY_COSTS,
		AhcEnums.InitiationStep.INIT_2B_AOO,
		AhcEnums.InitiationStep.INIT_3_COMMENCE,
		AhcEnums.InitiationStep.INIT_4_RESOLVE,
	]
	return _collect_initiation_steps(h) == expected


func _test_initiation_play_cost_abort() -> bool:
	var h := RuleTestHarness.new(42)
	CardRegistry.register_definition(
		&"costly_asset",
		{"card_type": &"asset", "resource_cost": 2}
	)
	var card_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"costly_asset")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"inv_1"
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.HAND
	h.ctx.state.registry.register_card(card)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.hand.append(card_id)
	inv.resource_pool = 1
	var res := h.ctx.actions.play_card(&"inv_1", card_id)
	return (
		not res.ok
		and res.error == "cannot_pay"
		and inv.resource_pool == 1
		and inv.hand.has(card_id)
	)


func _test_initiation_play_card_pipeline() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_skill_card_to_hand(
		h.ctx, &"inv_1", AhcEnums.SkillType.WILLPOWER
	)
	var res := h.ctx.actions.play_card(&"inv_1", card_id)
	if not res.ok:
		return false
	var card := h.ctx.state.registry.get_card(card_id)
	if card.zone != AhcEnums.Zone.PLAY_AREA:
		return false
	var expected: Array = [
		AhcEnums.InitiationStep.INIT_PRE_RESTRICTIONS,
		AhcEnums.InitiationStep.INIT_1_APPLY_MODIFIERS,
		AhcEnums.InitiationStep.INIT_2_PAY_COSTS,
		AhcEnums.InitiationStep.INIT_2B_AOO,
		AhcEnums.InitiationStep.INIT_3_COMMENCE,
		AhcEnums.InitiationStep.INIT_4_RESOLVE,
	]
	return _collect_initiation_steps(h) == expected


func _test_initiation_cost_modifier() -> bool:
	var h := RuleTestHarness.new(42)
	CompositionTestHelper.new(h.ctx).execute(
		CompositionTestHelper.reduce_initiation_resource_cost_turn(&"inv_1", 1)
	)
	CardRegistry.register_definition(
		&"discounted_asset",
		{"card_type": &"asset", "resource_cost": 2}
	)
	var card_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"discounted_asset")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"inv_1"
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.HAND
	h.ctx.state.registry.register_card(card)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.hand.append(card_id)
	inv.resource_pool = 1
	var res := h.ctx.actions.play_card(&"inv_1", card_id)
	return res.ok and inv.resource_pool == 0 and card.zone == AhcEnums.Zone.PLAY_AREA


func _test_initiation_action_aoo() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2, &"inv_1")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.threat_area.append(&"enemy_1")
	inv.actions_remaining = 2
	var intent := InitiationIntent.action_ability(
		&"inv_1",
		CompositionNode.adjust_marker(
			MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE), 1
		)
	)
	var res := h.ctx.initiation.initiate(intent, h.ctx)
	return (
		res.ok
		and inv.damage_taken == 1
		and inv.resource_pool == 6
		and inv.actions_remaining == 1
		and int(res.get("aoo_attacks", 0)) == 1
	)


func _test_initiation_on_play() -> bool:
	var h := RuleTestHarness.new(42)
	CardRegistry.register_definition(&"ev_on_play", {"card_type": &"event"})
	CardRegistry.register_on_play(
		&"ev_on_play",
		&"on_play:0",
		func(bind: AbilityBindContext) -> CompositionNode:
			return CompositionNode.adjust_marker(
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.RESOURCE), 2
			)
	)
	var card_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"ev_on_play")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"inv_1"
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.HAND
	h.ctx.state.registry.register_card(card)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.hand.append(card_id)
	var pool_before := inv.resource_pool
	var res := h.ctx.actions.play_card(&"inv_1", card_id)
	return (
		res.ok
		and inv.resource_pool == pool_before + 2
		and not inv.hand.has(card_id)
		and inv.discard.has(card_id)
		and card.zone == AhcEnums.Zone.DISCARD
	)


func _test_initiation_post_aoo_refund() -> bool:
	var h := RuleTestHarness.new(42)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.resource_pool = 4
	var intent := InitiationIntent.ability(
		&"inv_1",
		CompositionNode.adjust_marker(
			MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE), -3
		)
	)
	intent.resource_cost = 2
	var res := h.ctx.initiation.initiate(intent, h.ctx)
	return not res.ok and res.error == "illegal" and inv.resource_pool == 4


func _test_trig_forced_after_gain() -> bool:
	var h := RuleTestHarness.new(42)
	var desc := TriggeredAbilityDescriptor.forced(
		&"gain_resource",
		AhcEnums.SequencePhase.AFTER,
		&"inv_1",
		CompositionNode.adjust_marker(
			MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE), 1
		)
	)
	h.ctx.triggered_abilities.register(desc)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var pool_before := inv.resource_pool
	h.ctx.resource_gain.gain(h.ctx, &"inv_1", 1, [&"resource_action"])
	if inv.resource_pool != pool_before + 2:
		return false
	return _collect_initiation_steps(h).is_empty()


func _test_trig_reaction_declined() -> bool:
	var h := RuleTestHarness.new(42)
	var desc := TriggeredAbilityDescriptor.reaction(
		&"gain_resource",
		AhcEnums.SequencePhase.AFTER,
		&"inv_1",
		CompositionNode.adjust_marker(
			MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE), 5
		)
	)
	h.ctx.triggered_abilities.register(desc)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var pool_before := inv.resource_pool
	h.ctx.resource_gain.gain(h.ctx, &"inv_1", 1, [&"resource_action"])
	return inv.resource_pool == pool_before + 1


func _test_trig_reaction_accepted() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"reaction:use", "pick": true},
	])
	var desc := TriggeredAbilityDescriptor.reaction(
		&"gain_resource",
		AhcEnums.SequencePhase.AFTER,
		&"inv_1",
		CompositionNode.adjust_marker(
			MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE), 2
		)
	)
	h.ctx.triggered_abilities.register(desc)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var pool_before := inv.resource_pool
	h.ctx.resource_gain.gain(h.ctx, &"inv_1", 1, [&"resource_action"])
	return inv.resource_pool == pool_before + 3


func _test_trig_peril_blocks() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	_setup_peril_for_drawer(h, &"inv_1", &"enc_peril_trig_asset")
	var desc := TriggeredAbilityDescriptor.reaction(
		&"gain_resource",
		AhcEnums.SequencePhase.AFTER,
		&"inv_2",
		CompositionNode.adjust_marker(
			MarkerSlot.investigator(&"inv_2", AhcEnums.MarkerKind.RESOURCE), 3
		)
	)
	h.ctx.triggered_abilities.register(desc)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"reaction:use", "pick": true},
	])
	var inv := h.ctx.state.registry.get_investigator(&"inv_2")
	var pool_before := inv.resource_pool
	h.ctx.resource_gain.gain(h.ctx, &"inv_2", 1, [&"resource_action"])
	return inv.resource_pool == pool_before + 1


func _test_trig_install_on_play() -> bool:
	var h := RuleTestHarness.new(42)
	CardRegistry.register_definition(&"trig_asset", {"card_type": &"asset"})
	CardRegistry.register_triggered(
		&"trig_asset",
		&"react:gain",
		&"gain_resource",
		AhcEnums.SequencePhase.AFTER,
		&"forced",
		func(bind: AbilityBindContext) -> CompositionNode:
			return CompositionNode.adjust_marker(
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.RESOURCE), 1
			)
	)
	var card_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"trig_asset")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"inv_1"
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.HAND
	h.ctx.state.registry.register_card(card)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.hand.append(card_id)
	if not h.ctx.actions.play_card(&"inv_1", card_id).ok:
		return false
	var pool_before := inv.resource_pool
	h.ctx.resource_gain.gain(h.ctx, &"inv_1", 1, [&"resource_action"])
	return inv.resource_pool == pool_before + 2


func _test_adb_import_counts() -> bool:
	var n := ArkhamDbCardLoader.load_core_2026()
	return n >= 166


func _test_adb_asset_local_map() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var def_id := &"12033"
	return (
		CardRegistry.title(def_id) == "Local Map"
		and CardRegistry.card_type(def_id) == &"asset"
		and CardRegistry.resource_cost(def_id) == 3
		and CardRegistry.has_keyword(def_id, &"surge") == false
	)


func _test_adb_weakness_in_harms_way() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var def_id := &"12003"
	return (
		CardRegistry.is_weakness(def_id)
		and CardRegistry.card_type(def_id) == &"treachery"
	)


func _test_adb_treachery_surge() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var def_id := &"12163"
	return (
		CardRegistry.card_type(def_id) == &"treachery"
		and CardRegistry.has_keyword(def_id, &"surge")
		and CardRegistry.ability_hints(def_id).has(&"revelation")
	)


func _test_adb_hidden_elokoss() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var def_id := &"12179b"
	var enemy := CardRegistry.enemy_stats(def_id)
	return (
		CardRegistry.is_hidden(def_id)
		and CardRegistry.has_keyword(def_id, &"hunter")
		and CardRegistry.has_keyword(def_id, &"massive")
		and CardRegistry.has_keyword(def_id, &"retaliate")
		and int(enemy.get("fight", 0)) == 5
	)


func _test_adb_peril_cosmic_evils() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var def_id := &"12124"
	return (
		CardRegistry.has_keyword(def_id, &"peril")
		and CardRegistry.ability_hints(def_id).has(&"revelation")
	)


func _adb_add_encounter_enemy_to_deck(h: RuleTestHarness, def_id: StringName) -> StringName:
	var instance_id := h.ctx.state.registry.allocate_instance_id(&"enc_card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, instance_id, def_id)
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"encounter"
	card.controller_id = &"encounter"
	card.zone = AhcEnums.Zone.DECK
	h.ctx.state.registry.register_card(card)
	h.ctx.state.encounter_deck.append(instance_id)
	return instance_id


func _adb_add_investigator_card_to_deck(
	h: RuleTestHarness,
	inv_id: StringName,
	def_id: StringName
) -> StringName:
	var instance_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, instance_id, def_id)
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = inv_id
	card.controller_id = inv_id
	card.zone = AhcEnums.Zone.DECK
	h.ctx.state.registry.register_card(card)
	var inv := h.ctx.state.registry.get_investigator(inv_id)
	if inv:
		inv.deck.append(instance_id)
	return instance_id


func _test_adb_keyword_bools() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var def_id := &"12114"
	return (
		CardRegistry.is_hunter(def_id)
		and CardRegistry.is_retaliate(def_id)
		and CardRegistry.has_keyword(def_id, &"hunter")
	)


func _test_adb_prey_lowest_agility() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var prey := CardRegistry.prey_spec(&"12114")
	return (
		prey != null
		and prey.compare_mode == PreyInstructionSpec.CompareMode.LOWEST
		and prey.skill == AhcEnums.SkillType.AGILITY
	)


func _test_adb_prey_most_resources() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var prey := CardRegistry.prey_spec(&"12164")
	return (
		prey != null
		and prey.value_kind == PreyInstructionSpec.ValueKind.RESOURCES
		and prey.compare_mode == PreyInstructionSpec.CompareMode.HIGHEST
	)


func _test_adb_prey_investigator_only() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var prey := CardRegistry.prey_spec(&"12009")
	return (
		prey != null
		and prey.investigator_title_only == "Trish Scarborough"
	)


func _test_adb_spawn_farthest_empty() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var spawn := CardRegistry.spawn_spec(&"12099")
	return (
		spawn.mode == SpawnInstructionSpec.Mode.INSTRUCTION
		and spawn.selector_kind == SpawnInstructionSpec.SelectorKind.FARTHEST_EMPTY
		and CardRegistry.is_aloof(&"12099")
	)


func _test_adb_spawn_farthest_empty_play() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	GameBootstrap.setup_test_location(h.ctx, &"loc_a")
	GameBootstrap.setup_test_location(h.ctx, &"loc_b")
	GameBootstrap.setup_test_location(h.ctx, &"loc_c")
	GameBootstrap.connect_locations(h.ctx, &"loc_a", &"loc_b")
	GameBootstrap.connect_locations(h.ctx, &"loc_b", &"loc_c")
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_1", &"loc_a")
	var card_id := _adb_add_encounter_enemy_to_deck(h, &"12099")
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	return enemy != null and enemy.location_tag == &"loc_c" and enemy.engaged_with == &""


func _test_adb_prey_lowest_agility_play() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	GameBootstrap.setup_investigator_at_location(
		h.ctx, &"inv_2", &"test_loc", {"agility": 1}
	)
	h.ctx.state.registry.get_investigator(&"inv_1").skill_agility = 4
	var def_data := CardRegistry.definition_data(&"12114")
	def_data["spawn_instruction"] = SpawnInstructionSpec.at_drawer_location()
	CardRegistry.register_definition(&"12114", def_data)
	var card_id := _adb_add_encounter_enemy_to_deck(h, &"12114")
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	return enemy != null and enemy.engaged_with == &"inv_2"


func _test_adb_segment_in_harms_way() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var segments := CardRegistry.ability_segments(&"12003")
	return segments.size() == 3 and CardRegistry.compiled_abilities(&"12003").size() >= 2


func _test_adb_compile_enter_threat() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	return (
		CardRegistry.has_revelation(&"12003")
		and CardRegistry.compiled_abilities(&"12003")[0].get("template", "") == "enter_threat_area"
	)


func _test_adb_breaking_point_revelation() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	if not CardRegistry.has_revelation(&"12015"):
		return false
	var card_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"12015")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"inv_1"
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.LIMBO
	h.ctx.state.registry.register_card(card)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	if not h.ctx.card_abilities.resolve_revelations(h.ctx, &"inv_1", card_id):
		return false
	return inv.damage_taken == 1


func _test_adb_ability_compile_summary() -> bool:
	ArkhamDbCardLoader.load_core_2026()
	var total_segments := 0
	var total_compiled := 0
	for def_id in [&"12003", &"12015", &"12126", &"12167"]:
		total_segments += CardRegistry.ability_segments(def_id).size()
		total_compiled += CardRegistry.compiled_abilities(def_id).size()
	return total_segments >= 4 and total_compiled >= 3


func _test_eff_draw_blocked() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionTestHelper.forbid_draw_turn(&"inv_1"))
	var res := h.ctx.effects.submit(EffectRequest.draw_cards(&"inv_1", 1))
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		not res.ok
		and res.error == "restriction_forbid_draw"
		and res.get("blocked_by_restriction", false)
		and inv.hand.is_empty()
	)


func _test_eff_draw_ok() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var res := h.ctx.effects.submit(EffectRequest.draw_cards(&"inv_1", 1))
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return res.ok and inv.hand.has(card_id) and inv.deck.is_empty()


func _test_can_cancel_pending_draw() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var begin := h.ctx.effects.begin_pending(EffectRequest.draw_cards(&"inv_1", 1))
	if not begin.get("ok", false):
		return false
	var pending_id: StringName = begin.get("pending_id", &"")
	if not h.ctx.effects.cancel_pending(pending_id).get("ok", false):
		return false
	var res := h.ctx.effects.resolve_pending(pending_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		not res.ok
		and res.error == "unknown_pending"
		and not h.ctx.effects.is_pending_registered(pending_id)
		and inv.hand.is_empty()
	)


func _test_can_cancel_after_resolve() -> bool:
	var h := RuleTestHarness.new(42)
	var begin := h.ctx.effects.begin_pending(EffectRequest.gain_resource(&"inv_1", 1))
	var pending_id: StringName = begin.get("pending_id", &"")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var pool_before := inv.resource_pool
	if not h.ctx.effects.resolve_pending(pending_id).get("ok", false):
		return false
	if inv.resource_pool != pool_before + 1:
		return false
	var cancel := h.ctx.effects.cancel_pending(pending_id)
	return not cancel.get("ok", false) and cancel.error == "already_resolved"


func _test_can_replacement_after_cancel() -> bool:
	var h := RuleTestHarness.new(42)
	var begin := h.ctx.effects.begin_pending(EffectRequest.gain_resource(&"inv_1", 3))
	var pending_id: StringName = begin.get("pending_id", &"")
	if not h.ctx.effects.cancel_pending(pending_id).get("ok", false):
		return false
	var repl := h.ctx.effects.register_replacement(
		pending_id,
		EffectRequest.gain_resource(&"inv_1", 1),
		&"ability_a"
	)
	return not repl.get("ok", false) and repl.error == "unknown_pending"


func _test_ign_ignore_skips_apply() -> bool:
	var h := RuleTestHarness.new(42)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var pool_before := inv.resource_pool
	var begin := h.ctx.effects.begin_pending(EffectRequest.gain_resource(&"inv_1", 3))
	var pending_id: StringName = begin.get("pending_id", &"")
	if not h.ctx.effects.ignore_pending(pending_id).get("ok", false):
		return false
	if not h.ctx.effects.is_pending_registered(pending_id):
		return false
	if inv.resource_pool != pool_before:
		return false
	var res := h.ctx.effects.resolve_pending(pending_id)
	return (
		res.ok
		and res.get("ignored", false)
		and not res.get("applied", true)
		and inv.resource_pool == pool_before
	)


func _test_ign_blocks_replacement() -> bool:
	var h := RuleTestHarness.new(42)
	var begin := h.ctx.effects.begin_pending(EffectRequest.gain_resource(&"inv_1", 3))
	var pending_id: StringName = begin.get("pending_id", &"")
	if not h.ctx.effects.ignore_pending(pending_id).get("ok", false):
		return false
	var repl := h.ctx.effects.register_replacement(
		pending_id,
		EffectRequest.gain_resource(&"inv_1", 1),
		&"ability_a"
	)
	return not repl.get("ok", false) and String(repl.get("error", &"")) == "pending_closed"


func _test_int_catalog_interrupt_cancel() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var begin := h.ctx.effects.begin_pending(EffectRequest.draw_cards(&"inv_1", 1))
	if not begin.get("ok", false):
		return false
	var pending_id: StringName = begin.get("pending_id", &"")
	var cancel := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.interrupt.cancel",
		{
			"controller_id": &"inv_1",
			"target": {"kind": "impact", "pending_id": pending_id},
		}
	)
	if not cancel.get("ok", false):
		return false
	var res := h.ctx.effects.resolve_pending(pending_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		not res.ok
		and res.error == "unknown_pending"
		and inv.hand.is_empty()
	)


func _test_can_enc_ward_cancel_revelation() -> bool:
	var h := RuleTestHarness.new(42)
	CardRegistry.register_definition(
		&"enc_ward_treach",
		{"card_type": &"treachery", "limbo_discard_pile": &"encounter_discard"}
	)
	CardRegistry.register_revelation(
		&"enc_ward_treach",
		&"rev",
		func(bind: AbilityBindContext) -> CompositionNode:
			return CompositionNode.adjust_marker(
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.HORROR_TAKEN),
				3
			)
	)
	var card_id := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_ward_treach")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	if h.ctx.mutator.pop_encounter_deck_top() != card_id:
		return false
	h.ctx.memory.push_encounter_frame(EncounterResolutionFrame.create(&"inv_1"))
	var cancel := h.ctx.effects.apply_interrupt_cancel(
		InterruptTarget.sequence(
			&"seq.encounter.revelation",
			{"card_id": card_id, "controller_id": &"inv_1"}
		)
	)
	if not cancel.get("ok", false):
		return false
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(
		CompositionNode.adjust_marker(
			MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.HORROR_TAKEN),
			1
		)
	)
	DrawEncounterFlow.resolve_encounter_card_tail(h.ctx, &"inv_1", card_id)
	h.ctx.memory.pop_encounter_frame()
	var card := h.ctx.state.registry.get_card(card_id)
	return (
		inv.horror_taken == 1
		and card != null
		and card.zone == AhcEnums.Zone.DISCARD
		and h.ctx.state.encounter_discard.has(card_id)
	)


func _test_repl_most_recent_wins() -> bool:
	var h := RuleTestHarness.new(42)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var pool_before := inv.resource_pool
	var begin := h.ctx.effects.begin_pending(
		EffectRequest.gain_resource(&"inv_1", 9),
		&"trigger_gain"
	)
	var pending_id: StringName = begin.get("pending_id", &"")
	if not h.ctx.effects.register_replacement(
		pending_id,
		EffectRequest.gain_resource(&"inv_1", 1),
		&"ability_first"
	).get("ok", false):
		return false
	if not h.ctx.effects.register_replacement(
		pending_id,
		EffectRequest.gain_resource(&"inv_1", 5),
		&"ability_second"
	).get("ok", false):
		return false
	var res := h.ctx.effects.resolve_pending(pending_id)
	return res.ok and res.get("replaced", false) and inv.resource_pool == pool_before + 5


func _test_repl_composition_pipeline() -> bool:
	var h := RuleTestHarness.new(42)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var pool_before := inv.resource_pool
	var begin := h.ctx.effects.begin_pending(EffectRequest.gain_resource(&"inv_1", 9))
	var pending_id: StringName = begin.get("pending_id", &"")
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(
		CompositionNode.seq([
			CompositionNode.replace_pending(
				pending_id,
				EffectRequest.gain_resource(&"inv_1", 2),
				&"card_instead"
			),
			CompositionNode.resolve_pending(pending_id),
		])
	)
	return inv.resource_pool == pool_before + 2


func _test_repl_catalog_instead() -> bool:
	var h := RuleTestHarness.new(42)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var pool_before := inv.resource_pool
	var begin := h.ctx.effects.begin_pending(EffectRequest.gain_resource(&"inv_1", 9))
	if not begin.get("ok", false):
		return false
	var pending_id: StringName = begin.get("pending_id", &"")
	var repl := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.replace.instead",
		{
			"controller_id": &"inv_1",
			"target": {"kind": "pending", "pending_id": pending_id},
			"replacement": {
				"op": AhcEnums.EffectOp.GAIN_RESOURCE,
				"controller_id": &"inv_1",
				"amount": 3,
			},
			"source_ability_id": &"card_instead",
		}
	)
	if not repl.get("ok", false):
		return false
	var res := h.ctx.effects.resolve_pending(pending_id)
	return res.ok and res.get("replaced", false) and inv.resource_pool == pool_before + 3


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


func _test_enc_surge_dynamic_keyword() -> bool:
	var h := RuleTestHarness.new(42)
	CardRegistry.register_definition(&"enc_dyn_surge", {"card_type": &"treachery"})
	CardRegistry.register_revelation(
		&"enc_dyn_surge",
		&"revelation:0",
		func(bind: AbilityBindContext) -> CompositionNode:
			return CompositionNode.grant_keyword(bind.card_id, &"surge")
	)
	var first := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_dyn_surge", [])
	var second := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_plain_b", [])
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var cards: Array = res.get("cards", [])
	return (
		cards.size() == 2
		and cards[0] == first
		and cards[1] == second
		and int(res.get("surge_depth", 0)) == 1
		and h.ctx.registrations.count() == 0
	)


func _test_enc_surge_keyword_survives_g4() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_plain_surge", [])
	h.ctx.mutator.enter_limbo(card_id, &"inv_1")
	EncounterGainedKeyword.register_surge(h.ctx, card_id)
	if not h.ctx.registrations.has_keyword_buff(card_id, &"surge"):
		return false
	EncounterPeril.unregister_for_card(h.ctx, card_id)
	if not h.ctx.registrations.has_keyword_buff(card_id, &"surge"):
		return false
	var tail := DrawEncounterFlow.resolve_encounter_card_tail(h.ctx, &"inv_1", card_id)
	return (
		bool(tail.get("should_surge", false))
		and not h.ctx.registrations.has_keyword_buff(card_id, &"surge")
	)


func _adb_add_encounter_treachery_to_deck(h: RuleTestHarness, def_id: StringName) -> StringName:
	return _adb_add_encounter_enemy_to_deck(h, def_id)


func _test_adb_compile_forbidden_secrets() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12126")
	var segments := CardRegistry.ability_segments(&"12126")
	var then_tpl := ""
	if compiled.size() == 1:
		var then_entry: Variant = compiled[0].get("then", {})
		if then_entry is Dictionary:
			then_tpl = str((then_entry as Dictionary).get("template", ""))
	return (
		CardRegistry.has_revelation(&"12126")
		and compiled.size() == 1
		and compiled[0].get("template", "") == "if_else"
		and compiled[0].get("if_kind", "") == "condition"
		and compiled[0].get("condition", "") == "investigator_has_no_clues"
		and then_tpl == "grant_surge"
		and compiled[0].get("status", "") == "partial"
		and segments.size() == 1
		and segments[0].get("if_kind", "") == "condition"
	)


func _test_enc_surge_12126_no_clues() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	if inv == null:
		return false
	inv.clues_on_card = 0
	var first := _adb_add_encounter_treachery_to_deck(h, &"12126")
	var second := _adb_add_encounter_treachery_to_deck(h, &"12127")
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var cards: Array = res.get("cards", [])
	return (
		cards.size() == 2
		and cards[0] == first
		and cards[1] == second
		and int(res.get("surge_depth", 0)) == 1
		and h.ctx.registrations.count() == 0
	)


func _test_enc_surge_12126_with_clues() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	if inv == null:
		return false
	inv.clues_on_card = 1
	var card_id := _adb_add_encounter_treachery_to_deck(h, &"12126")
	h.ctx.mutator.enter_limbo(card_id, &"inv_1")
	if not h.ctx.card_abilities.resolve_revelations(h.ctx, &"inv_1", card_id):
		return false
	return not h.ctx.registrations.has_keyword_buff(card_id, &"surge")


func _test_adb_compile_raising_suspicions() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12160")
	if compiled.size() != 1:
		return false
	var entry: Dictionary = compiled[0]
	var steps: Variant = entry.get("steps", [])
	if not steps is Array or (steps as Array).size() != 2:
		return false
	var step0: Dictionary = steps[0]
	var step1: Dictionary = steps[1]
	return (
		CardRegistry.has_revelation(&"12160")
		and entry.get("template", "") == "seq"
		and step0.get("template", "") == "place_doom_nearest_enemy_without_doom"
		and step1.get("template", "") == "if_else"
		and step1.get("evaluate", "") == "after_step"
		and step1.get("condition", "") == "previous_step_not_created"
		and (step1.get("then", {}) as Dictionary).get("template", "") == "grant_surge"
	)


func _test_enc_surge_12160_places_doom() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_a", &"test_loc")
	var first := _adb_add_encounter_treachery_to_deck(h, &"12160")
	var second := _adb_add_encounter_treachery_to_deck(h, &"12127")
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false):
		return false
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_a")
	var cards: Array = res.get("cards", [])
	return (
		enemy != null
		and enemy.doom == 1
		and cards.size() == 2
		and cards[0] == first
		and cards[1] == second
		and int(res.get("surge_depth", 0)) == 1
	)


func _test_enc_surge_12160_no_target_gained() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var card_id := _adb_add_encounter_treachery_to_deck(h, &"12160")
	h.ctx.mutator.enter_limbo(card_id, &"inv_1")
	if not h.ctx.card_abilities.resolve_revelations(h.ctx, &"inv_1", card_id):
		return false
	return h.ctx.registrations.has_keyword_buff(card_id, &"surge")


func _test_gain_effective_keyword() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_print_surge", [&"surge"])
	var card := h.ctx.state.registry.get_card(card_id)
	var def_id := card.id.definition_id
	if not EffectiveCharacteristicQuery.has_effective_keyword(h.ctx, card_id, def_id, &"surge"):
		return false
	EncounterGainedKeyword.register_surge(h.ctx, card_id)
	return EffectiveCharacteristicQuery.has_effective_keyword(h.ctx, card_id, def_id, &"surge")


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
		and card.owner_id == &"encounter"
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
		and card.owner_id == &"encounter"
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


func _test_enc_hidden_treachery_threat_area() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var treach_id := GameBootstrap.add_encounter_card_to_deck(
		h.ctx,
		&"enc_hidden_ta_t",
		[&"hidden"]
	)
	var enemy_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"enc_hidden_ta_e",
		{"keywords": [&"hidden"], "hidden": true}
	)
	var t_res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not t_res.get("ok", false):
		return false
	h.ctx.state.encounter_deck.clear()
	h.ctx.state.encounter_deck.append(enemy_id)
	var e_res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not e_res.get("ok", false):
		return false
	var state := h.ctx.state
	return (
		ThreatAreaQuery.counts_in_effective_threat_area(state, &"inv_1", treach_id)
		and not ThreatAreaQuery.counts_in_effective_threat_area(state, &"inv_1", enemy_id)
		and not h.ctx.state.registry.get_investigator(&"inv_1").threat_area.has(treach_id)
	)


func _test_enc_hidden_treachery_discard_from_hand() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var card_id := GameBootstrap.add_encounter_card_to_deck(
		h.ctx,
		&"enc_hidden_disc",
		[&"hidden"]
	)
	var draw_res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not draw_res.get("ok", false):
		return false
	if not h.ctx.registrations.has_hidden_leave_hand_restriction(card_id):
		return false
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionNode.discard_encounter_from_hand(card_id, &"inv_1"))
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		h.ctx.state.encounter_discard.has(card_id)
		and not inv1.hand.has(card_id)
		and not h.ctx.registrations.has_hidden_leave_hand_restriction(card_id)
	)


func _test_enc_elimination_hidden_hand() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var card_id := GameBootstrap.add_encounter_card_to_deck(
		h.ctx,
		&"enc_hidden_elim",
		[&"hidden"]
	)
	var draw_res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not draw_res.get("ok", false):
		return false
	var elim := InvestigatorElimination.eliminate(h.ctx, &"inv_1")
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		elim.get("eliminated", false)
		and inv1.eliminated
		and h.ctx.state.encounter_discard.has(card_id)
		and not inv1.hand.has(card_id)
		and not h.ctx.registrations.has_hidden_leave_hand_restriction(card_id)
	)


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


func _setup_peril_for_drawer(h: RuleTestHarness, drawer_id: StringName, enc_id: StringName) -> void:
	var frame := EncounterResolutionFrame.create(drawer_id)
	frame.current_card_id = enc_id
	h.ctx.memory.push_encounter_frame(frame)
	EncounterPeril.register_if_peril(h.ctx, drawer_id, enc_id, true)


func _test_rest_draw_action_blocked() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionTestHelper.forbid_draw_turn(&"inv_1"))
	if not h.prepare_action_phase():
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var actions_before := inv.actions_remaining
	var res := h.draw_action()
	return (
		not res.ok
		and res.error == "restriction_forbid_draw"
		and inv.actions_remaining == actions_before
		and inv.hand.is_empty()
	)


func _test_peril_blocks_teammate_play() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var card_id := GameBootstrap.add_skill_card_to_hand(
		h.ctx, &"inv_2", AhcEnums.SkillType.WILLPOWER
	)
	_setup_peril_for_drawer(h, &"inv_1", &"enc_peril_play")
	var res := h.ctx.actions.play_card(&"inv_2", card_id)
	return not res.ok and res.error == "restriction_forbid_play"


func _test_peril_blocks_teammate_trigger() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	_setup_peril_for_drawer(h, &"inv_1", &"enc_peril_trig")
	var intent := InitiationIntent.create(
		&"inv_2",
		CompositionNode.adjust_marker(
			MarkerSlot.investigator(&"inv_2", AhcEnums.MarkerKind.RESOURCE), 1
		)
	)
	if h.ctx.initiation.can_initiate(intent, h.ctx):
		return false
	var res := h.ctx.initiation.initiate(intent, h.ctx)
	return not res.ok and res.error == "restriction_forbid_trigger"


func _test_peril_drawer_play_trigger_ok() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_skill_card_to_hand(
		h.ctx, &"inv_1", AhcEnums.SkillType.WILLPOWER
	)
	_setup_peril_for_drawer(h, &"inv_1", &"enc_peril_drawer")
	var play_res := h.ctx.actions.play_card(&"inv_1", card_id)
	if not play_res.ok:
		return false
	var intent := InitiationIntent.create(
		&"inv_1",
		CompositionNode.adjust_marker(
			MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE), 1
		)
	)
	return h.ctx.initiation.can_initiate(intent, h.ctx) and h.ctx.initiation.initiate(intent, h.ctx).ok


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


func _test_act_catalog_registered() -> bool:
	var h := RuleTestHarness.new(42)
	var catalog := h.ctx.sequence_catalog
	var flows: Array[StringName] = [
		&"seq.interrupt.cancel",
		&"seq.interrupt.ignore",
		&"seq.replace.instead",
		&"seq.action.draw",
		&"seq.action.gain_resource",
		&"seq.action.move",
		&"seq.action.investigate",
		&"seq.action.fight",
		&"seq.action.engage",
		&"seq.action.evade",
	]
	for flow_id in flows:
		if not catalog.has_flow(flow_id):
			return false
	return h.ctx.action_sequences != null


func _test_act_catalog_gain_after_listener() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionTestHelper.after_gain_draw_listener(&"inv_1"))
	if not h.prepare_action_phase():
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	if inv.deck.size() != 1 or inv.hand.size() != 0:
		return false
	var res := h.take_resource_action()
	return res.ok and inv.deck.is_empty() and inv.hand.size() == 1


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


func _setup_move_test_graph(h: RuleTestHarness, inv_loc: StringName = &"loc_b") -> void:
	GameBootstrap.setup_test_location(h.ctx, &"loc_a")
	GameBootstrap.setup_test_location(h.ctx, &"loc_b")
	GameBootstrap.connect_locations(h.ctx, &"loc_a", &"loc_b")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = inv_loc


func _spawn_enemy_at(
	h: RuleTestHarness,
	definition_id: StringName,
	location_tag: StringName,
	opts: Dictionary = {}
) -> StringName:
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(h.ctx, definition_id, opts)
	var spawn := h.ctx.enemy.spawn_at_location(h.ctx, card_id, location_tag)
	if not spawn.get("ok", false):
		return &""
	return card_id


func _test_en01_hunter_patrol_move() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	_setup_move_test_graph(h)
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_hunter",
		&"loc_a",
		{"keywords": [&"hunter"], "enemy": {"damage": 1}}
	)
	if enemy_id == &"":
		return false
	if not h.advance_to_action_phase():
		return false
	h.end_turn()
	if not h.run_through_step(AhcEnums.FrameworkStep.ENEMY_3_2_HUNTER_PATROL_MOVE):
		return false
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	return enemy != null and enemy.location_tag == &"loc_b"


func _setup_patrol_test_graph(h: RuleTestHarness) -> void:
	for loc_id in [&"pat_a", &"pat_b", &"pat_goal"]:
		GameBootstrap.setup_test_location(h.ctx, loc_id)
	GameBootstrap.connect_locations(h.ctx, &"pat_a", &"pat_b")
	GameBootstrap.connect_locations(h.ctx, &"pat_b", &"pat_goal")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"pat_goal"


func _test_en13_patrol_move() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	_setup_patrol_test_graph(h)
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_patrol",
		&"pat_a",
		{
			"keywords": [&"patrol"],
			"patrol_instruction": PatrolTargetSpec.at_named_location(&"pat_goal"),
		}
	)
	if enemy_id == &"":
		return false
	var result := h.ctx.enemy_phase.run_patrol(h.ctx)
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	return (
		bool(result.get("ok", false))
		and enemy != null
		and enemy.location_tag == &"pat_b"
	)


func _test_en14_patrol_skip_at_target() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	_setup_patrol_test_graph(h)
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_patrol_skip",
		&"pat_goal",
		{
			"keywords": [&"patrol"],
			"patrol_instruction": PatrolTargetSpec.at_named_location(&"pat_goal"),
		}
	)
	if enemy_id == &"":
		return false
	var result := h.ctx.enemy_phase.run_patrol(h.ctx)
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	return (
		bool(result.get("ok", false))
		and (result.get("moved", []) as Array).is_empty()
		and enemy != null
		and enemy.location_tag == &"pat_goal"
	)


func _test_en02_phase_attack() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_phase",
		&"test_loc",
		{"enemy": {"damage": 2, "horror": 1}}
	)
	if enemy_id == &"":
		return false
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	enemy.engaged_with = &"inv_1"
	inv.threat_area.append(enemy_id)
	inv.damage_taken = 0
	inv.horror_taken = 0
	h.ctx.enemy_phase.run_phase_attacks(h.ctx, &"inv_1")
	return (
		inv.damage_taken == 2
		and inv.horror_taken == 1
		and enemy.exhausted
	)


func _test_en03_move_must_shorten() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	GameBootstrap.setup_test_location(h.ctx, &"mv_a")
	GameBootstrap.setup_test_location(h.ctx, &"mv_b")
	GameBootstrap.setup_test_location(h.ctx, &"mv_c")
	GameBootstrap.connect_locations(h.ctx, &"mv_a", &"mv_b")
	GameBootstrap.connect_locations(h.ctx, &"mv_b", &"mv_c")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"mv_c"
	var enemy_id := _spawn_enemy_at(h, &"en_mv_short", &"mv_a", {})
	if enemy_id == &"":
		return false
	var result := EnemyMovement.move_one_step_toward_location(h.ctx, enemy_id, &"mv_c")
	return (
		bool(result.get("moved", false))
		and result.get("to_location", &"") == &"mv_b"
	)


func _test_en04_move_lateral_no_shorten() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	for loc_id in [&"ring_0", &"ring_1", &"ring_2", &"ring_3"]:
		GameBootstrap.setup_test_location(h.ctx, loc_id)
	GameBootstrap.connect_locations(h.ctx, &"ring_0", &"ring_1")
	GameBootstrap.connect_locations(h.ctx, &"ring_1", &"ring_2")
	GameBootstrap.connect_locations(h.ctx, &"ring_2", &"ring_3")
	GameBootstrap.connect_locations(h.ctx, &"ring_3", &"ring_0")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"ring_0"
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([{"pick": &"ring_3"}])
	var enemy_id := _spawn_enemy_at(h, &"en_mv_lat", &"ring_2", {})
	if enemy_id == &"":
		return false
	var result := EnemyMovement.move_one_step_toward_location(h.ctx, enemy_id, &"ring_0")
	return bool(result.get("moved", false)) and result.get("to_location", &"") == &"ring_3"


func _test_en05_move_lead_picks_tie() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	for loc_id in [&"fork_goal", &"fork_left", &"fork_right", &"fork_enemy"]:
		GameBootstrap.setup_test_location(h.ctx, loc_id)
	GameBootstrap.connect_locations(h.ctx, &"fork_goal", &"fork_left")
	GameBootstrap.connect_locations(h.ctx, &"fork_goal", &"fork_right")
	GameBootstrap.connect_locations(h.ctx, &"fork_left", &"fork_enemy")
	GameBootstrap.connect_locations(h.ctx, &"fork_right", &"fork_enemy")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"fork_goal"
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([{"pick": &"fork_left"}])
	var enemy_id := _spawn_enemy_at(h, &"en_mv_tie", &"fork_enemy", {})
	if enemy_id == &"":
		return false
	var result := EnemyMovement.move_one_step_toward_location(h.ctx, enemy_id, &"fork_goal")
	return bool(result.get("moved", false)) and result.get("to_location", &"") == &"fork_left"


func _test_en06_disengage_reselects() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	GameBootstrap.setup_test_location(h.ctx, &"shared_loc")
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	inv1.location_tag = &"shared_loc"
	inv1.skill_willpower = 2
	GameBootstrap.setup_investigator_at_location(
		h.ctx, &"inv_2", &"shared_loc", {"willpower": 5}
	)
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_reselect",
		&"shared_loc",
		{
			"prey_instruction": PreyInstructionSpec.highest(
				AhcEnums.SkillType.WILLPOWER
			),
		}
	)
	if enemy_id == &"":
		return false
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	enemy.engaged_with = &"inv_1"
	inv1.threat_area.append(enemy_id)
	var result := h.ctx.enemy.disengage(h.ctx, enemy_id, false, true)
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	return (
		bool(result.get("ok", true))
		and enemy.engaged_with == &"inv_2"
		and inv2.threat_area.has(enemy_id)
		and not inv1.threat_area.has(enemy_id)
	)


func _test_en08_massive_spawn_virtual() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx, &"en_massive_spawn", {"keywords": [&"massive"]}
	)
	var spawn := h.ctx.enemy.spawn_default_from_draw(h.ctx, card_id, &"inv_1", false, &"en_massive_spawn")
	if not spawn.get("ok", false):
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var enemy := h.ctx.state.registry.get_enemy(card_id)
	return (
		enemy != null
		and enemy.massive
		and enemy.location_tag == inv.location_tag
		and enemy.engaged_with == &""
		and not inv.threat_area.has(card_id)
		and MassiveEngagement.is_virtually_engaged_with(enemy, &"inv_1", h.ctx)
	)


func _test_en09_massive_phase_both() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	GameBootstrap.setup_test_location(h.ctx, &"mass_loc")
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	inv1.location_tag = &"mass_loc"
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"mass_loc", {})
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_massive_phase",
		&"mass_loc",
		{"keywords": [&"massive"], "enemy": {"damage": 2, "horror": 0}}
	)
	if enemy_id == &"":
		return false
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	inv1.damage_taken = 0
	inv2.damage_taken = 0
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"order:massive_phase_attacks", "pick": [&"inv_1", &"inv_2"]},
	])
	var result := MassiveEngagement.resolve_phase_batch(h.ctx, enemy_id)
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	return (
		int(result.get("attacks", 0)) == 2
		and inv1.damage_taken == 2
		and inv2.damage_taken == 2
		and enemy.exhausted
	)


func _test_en10_massive_interrupt() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	GameBootstrap.setup_test_location(h.ctx, &"mass_loc")
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	inv1.location_tag = &"mass_loc"
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"mass_loc", {})
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_massive_int",
		&"mass_loc",
		{"keywords": [&"massive"], "enemy": {"damage": 3, "horror": 0}}
	)
	if enemy_id == &"":
		return false
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	inv1.damage_taken = 0
	inv2.damage_taken = 0
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"order:massive_phase_attacks", "pick": [&"inv_1", &"inv_2"]},
	])
	var after_first := func(eid: StringName, _target: StringName) -> void:
		var en := h.ctx.state.registry.get_enemy(eid)
		if en != null:
			en.exhausted = true
	var result := MassiveEngagement.resolve_phase_batch(h.ctx, enemy_id, after_first)
	return (
		int(result.get("attacks", 0)) == 1
		and bool(result.get("interrupted", false))
		and inv1.damage_taken == 3
		and inv2.damage_taken == 0
	)


func _test_en11_ready_triggers_engage() -> bool:
	var h := RuleTestHarness.new(42)
	h.run_setup()
	var enemy_id := _spawn_enemy_at(h, &"en_ready", &"test_loc", {})
	if enemy_id == &"":
		return false
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	enemy.exhausted = true
	enemy.engaged_with = &""
	inv.threat_area.erase(enemy_id)
	var result := h.ctx.enemy.set_enemy_exhausted(h.ctx, enemy_id, false, true)
	return (
		bool(result.get("ok", false))
		and not enemy.exhausted
		and enemy.engaged_with == &"inv_1"
		and inv.threat_area.has(enemy_id)
	)


func _test_en12_evade_ready_reengage() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(
		h.ctx, &"enemy_1", &"test_loc", 2, 2, &"inv_1"
	)
	var res := h.evade_action({"enemy_id": &"enemy_1"})
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	if not (res.ok and res.success and enemy.exhausted and enemy.engaged_with == &""):
		return false
	h.ctx.enemy.ready_all_exhausted_enemies(h.ctx)
	return enemy.engaged_with == &"inv_1" and inv.threat_area.has(&"enemy_1")


func _test_en15_fight_fail_retaliate() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase([ChaosToken.auto_fail()]):
		return false
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_retaliate",
		&"test_loc",
		{
			"keywords": [&"retaliate"],
			"enemy": {"fight": 2, "evade": 2, "health": 2, "damage": 2, "horror": 1},
		}
	)
	if enemy_id == &"":
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.damage_taken = 0
	inv.horror_taken = 0
	var res := h.fight_action({"enemy_id": enemy_id})
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	return (
		res.ok
		and not res.success
		and inv.damage_taken == 2
		and inv.horror_taken == 1
		and enemy != null
		and not enemy.exhausted
	)


func _test_en16_evade_fail_alert() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase([ChaosToken.auto_fail()]):
		return false
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_alert",
		&"test_loc",
		{
			"keywords": [&"alert"],
			"enemy": {"fight": 2, "evade": 2, "health": 2, "damage": 3, "horror": 0},
		}
	)
	if enemy_id == &"":
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	enemy.engaged_with = &"inv_1"
	inv.threat_area.append(enemy_id)
	inv.damage_taken = 0
	inv.horror_taken = 0
	var res := h.evade_action({"enemy_id": enemy_id})
	return (
		res.ok
		and not res.success
		and inv.damage_taken == 3
		and inv.horror_taken == 0
		and not enemy.exhausted
	)


func _test_en17_exhausted_skips_keywords() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase([ChaosToken.auto_fail()]):
		return false
	var retaliate_id := _spawn_enemy_at(
		h,
		&"en_ret_ex",
		&"test_loc",
		{
			"keywords": [&"retaliate"],
			"enemy": {"fight": 2, "evade": 2, "health": 2, "damage": 2, "horror": 0},
		}
	)
	var alert_id := _spawn_enemy_at(
		h,
		&"en_alert_ex",
		&"test_loc",
		{
			"keywords": [&"alert"],
			"enemy": {"fight": 2, "evade": 2, "health": 2, "damage": 3, "horror": 0},
		}
	)
	if retaliate_id == &"" or alert_id == &"":
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var alert_enemy := h.ctx.state.registry.get_enemy(alert_id)
	alert_enemy.engaged_with = &"inv_1"
	inv.threat_area.append(alert_id)
	var retaliate_enemy := h.ctx.state.registry.get_enemy(retaliate_id)
	retaliate_enemy.exhausted = true
	alert_enemy.exhausted = true
	inv.damage_taken = 0
	inv.horror_taken = 0
	var fight_res := h.fight_action({"enemy_id": retaliate_id})
	if not (fight_res.ok and not fight_res.success):
		return false
	if inv.damage_taken != 0 or inv.horror_taken != 0:
		return false
	inv.actions_remaining = 1
	var evade_res := h.evade_action({"enemy_id": alert_id})
	return fight_res.ok and not fight_res.success and inv.damage_taken == 0 and inv.horror_taken == 0


func _test_act_fight_fail_redirect() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase([ChaosToken.auto_fail()]):
		return false
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	GameBootstrap.setup_test_enemy(
		h.ctx, &"enemy_1", &"test_loc", 2, 2, &"inv_2"
	)
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	inv2.threat_area.append(&"enemy_1")
	inv1.damage_taken = 0
	inv2.damage_taken = 0
	var res := h.fight_action({"enemy_id": &"enemy_1"})
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	return (
		res.ok
		and not res.success
		and inv1.damage_taken == 0
		and inv2.damage_taken == 1
		and enemy != null
		and enemy.damage == 0
	)


func _test_en18_massive_fight_fail_no_redirect() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase([ChaosToken.auto_fail()]):
		return false
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_massive_fight",
		&"test_loc",
		{"keywords": [&"massive"], "enemy": {"fight": 2, "health": 3}}
	)
	if enemy_id == &"":
		return false
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	inv1.damage_taken = 0
	inv2.damage_taken = 0
	var res := h.fight_action({"enemy_id": enemy_id})
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	return (
		res.ok
		and not res.success
		and inv1.damage_taken == 0
		and inv2.damage_taken == 0
		and enemy != null
		and enemy.massive
		and not inv1.threat_area.has(enemy_id)
		and not inv2.threat_area.has(enemy_id)
	)


func _test_en06_elusive_after_aoo() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_location(h.ctx, &"flee_loc")
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"flee_loc")
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_elusive_aoo",
		&"test_loc",
		{
			"keywords": [&"elusive"],
			"enemy": {"fight": 2, "evade": 2, "health": 2, "damage": 1, "horror": 0},
		}
	)
	if enemy_id == &"":
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	enemy.engaged_with = &"inv_1"
	inv.threat_area.append(enemy_id)
	inv.damage_taken = 0
	var res := h.take_resource_action()
	return (
		res.ok
		and inv.damage_taken == 1
		and enemy.exhausted
		and enemy.engaged_with == &""
		and not inv.threat_area.has(enemy_id)
		and enemy.location_tag == &"flee_loc"
	)


func _test_en19_fight_elusive_flees() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase([ChaosToken.auto_fail()]):
		return false
	GameBootstrap.setup_test_location(h.ctx, &"flee_loc")
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"flee_loc")
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_elusive_fight",
		&"test_loc",
		{
			"keywords": [&"elusive"],
			"enemy": {"fight": 2, "evade": 2, "health": 2},
		}
	)
	if enemy_id == &"":
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	var res := h.fight_action({"enemy_id": enemy_id})
	return (
		res.ok
		and not res.success
		and enemy.exhausted
		and enemy.engaged_with == &""
		and not inv.threat_area.has(enemy_id)
		and enemy.location_tag == &"flee_loc"
	)


func _test_adb_compile_aerial_pursuit() -> bool:
	var compiled := CardRegistry.compiled_abilities(&"12163")
	if compiled.is_empty():
		return false
	var entry: Dictionary = compiled[0]
	var steps: Variant = entry.get("steps", [])
	if not steps is Array or (steps as Array).size() < 3:
		return false
	return (
		entry.get("template", "") == "seq"
		and steps.size() >= 3
		and (steps[0] as Dictionary).get("template", "") == "resolve_location"
		and (steps[1] as Dictionary).get("template", "") == "nest_enemy_move"
		and ((steps[1] as Dictionary).get("trait_exclude", []) as Array).has("Elite")
		and (steps[2] as Dictionary).get("template", "") == "if_else"
		and (steps[2] as Dictionary).get("condition", "") == "previous_step_engaged_investigator"
		and CardRegistry.has_revelation(&"12163")
	)


func _test_enc_12163_move_attack() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	_setup_move_test_graph(h)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.damage_taken = 0
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_aerial",
		&"loc_a",
		{"traits": ["Humanoid"], "enemy": {"damage": 1}}
	)
	if enemy_id == &"":
		return false
	var card_id := _adb_add_encounter_treachery_to_deck(h, &"12163")
	h.ctx.mutator.enter_limbo(card_id, &"inv_1")
	if not h.ctx.card_abilities.resolve_revelations(h.ctx, &"inv_1", card_id):
		return false
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	return (
		enemy != null
		and enemy.location_tag == &"loc_b"
		and enemy.engaged_with == &"inv_1"
		and inv.damage_taken == 1
		and inv.threat_area.has(enemy_id)
	)


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
