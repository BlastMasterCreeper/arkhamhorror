extends SceneTree

## CI entry: godot --headless --path . -s res://tests/run_headless.gd

const PASS := 0
const FAIL := 1

var _failed := 0


func _initialize() -> void:
	print("=== AHC LCG headless tests ===")
	_run_test("PHYS-01 set-aside to deck shuffle", PhysicalTestHelper.test_set_aside_to_deck_shuffle)
	_run_test("PHYS-02 marker transfer pool to card", PhysicalTestHelper.test_marker_transfer_pool_to_card)
	_run_test("PHYS-03 augury reveal and return", PhysicalTestHelper.test_augury_reveal_and_return)
	_run_test("PHYS-04 card face exhaust", PhysicalTestHelper.test_card_face_exhaust)
	_run_test("PHYS-05 destroy requires empty", PhysicalTestHelper.test_destroy_requires_empty)
	_run_test("PHYS-06 player resource pool", PhysicalTestHelper.test_player_resource_pool)
	_run_test("PHYS-07 entity id alloc not definition", PhysicalTestHelper.test_entity_id_alloc_not_definition)
	_run_test("MTB-01 expand multi source to multi target", _test_mtb_expand_legs)
	_run_test("MTB-02 execute batch via atomic transfer_marker", _test_mtb_execute_resources)
	_run_test("MTB-03 sum mismatch rejects", _test_mtb_sum_mismatch)
	_run_test("PHYS-BRIDGE-01 move mirrors physical", PhysicalTestHelper.test_bridge_move_mirrors)
	_run_test("PHYS-BRIDGE-02 resource adjust mirrors", PhysicalTestHelper.test_bridge_resource_adjust_mirrors)
	_run_test("PHYS-BRIDGE-03 reveal mirrors flip", PhysicalTestHelper.test_bridge_reveal_mirrors_flip)
	_run_test("PHYS-BRIDGE-04 exhaust mirrors physical", PhysicalTestHelper.test_bridge_exhaust_mirrors)
	_run_test("PHYS-BRIDGE-05 chaos bag to augury", PhysicalTestHelper.test_bridge_chaos_augury)
	_run_test("PHYS-BRIDGE-06 card tokens sync", PhysicalTestHelper.test_bridge_card_tokens)
	_run_test("PHYS-BRIDGE-07 agenda doom mirrors", PhysicalTestHelper.test_bridge_agenda_doom)
	_run_test("PHYS-BRIDGE-08 shuffle rebuilds deck", PhysicalTestHelper.test_bridge_shuffle_rebuild)
	_run_test("A-01 setup reaches investigation phase", _test_setup_to_inv_phase)
	_run_test("A-02 resource action", _test_resource_action)
	_run_test("A-03 event records written", _test_event_records)
	_run_test("F-01 round 1 skips mythos", _test_round1_skips_mythos)
	_run_test("F-02 full round to round 2 mythos", _test_full_round_to_mythos)
	_run_test("F-05 mythos 1.3 agenda advance", _test_f05_mythos_agenda_advance)
	_run_test("SC-04 agenda doom advance clears doom", _test_sc04_agenda_advance_clears_doom)
	_run_test("SC-05 agenda flip promotes next card", _test_sc05_agenda_flip_promotes)
	_run_test("SC-06 act flip triggers resolution", _test_sc06_act_flip_resolution)
	_run_test("SC-07 act advance spends clues", _test_sc07_act_advance_spends_clues)
	_run_test("SC-08 setup wires act agenda decks", _test_sc08_setup_wires_act_agenda_decks)
	_run_test("SC-09 setup scenario layout", _test_sc09_setup_scenario_layout)
	_run_test("SC-10 setup scenario reference", _test_sc10_setup_scenario_reference)
	_run_test("REF-01 SF loads reference JSON", _test_ref01_sf_loads_reference_json)
	_run_test("REF-02 SF skull modifier neg act", _test_ref02_sf_skull_neg_act)
	_run_test("REF-03 SF tablet reveal another + fail damage", _test_ref03_sf_tablet_fail_damage)
	_run_test("REF-04 SF elder_thing fail-by draws Fire", _test_ref04_sf_elder_thing_fail_by_fire)
	_run_test("REF-05 SF hard skull neg act+1", _test_ref05_sf_hard_skull)
	_run_test("REF-06 blank skips printed symbol ability", _test_ref06_blank_skips_printed_symbol)
	_run_test("REF-07 blank skips tablet ST.7", _test_ref07_blank_skips_tablet_st7)
	_run_test("ES-01 Joe elder_sign spec loads", _test_es01_joe_elder_sign_spec)
	_run_test("ES-02 elder_sign +1 modifier at ST.4", _test_es02_modifier)
	_run_test("ES-03 Joe succeed draws and gains resource", _test_es03_joe_succeed)
	_run_test("ES-04 blank skips elder_sign", _test_es04_blank_skips)
	_run_test("ES-05 Joe fail skips on_success", _test_es05_joe_fail_no_success)
	_run_test("BC-01 bless +2 reveal_another return_to_pool", _test_bc01_bless_st4)
	_run_test("BC-02 curse -2 reveal_another return_to_pool", _test_bc02_curse_st4)
	_run_test("BC-02b chaos mod is THIS_SKILL_TEST Buff", _test_bc02b_chaos_mod_buff)
	_run_test("BC-02c symbol nests after reveal", _test_bc02c_symbol_nests_after_reveal)
	_run_test("BC-03 bless chain then ST.8 to pool", _test_bc03_bless_chain_pool)
	_run_test("BC-04 ability curse finalize returns to bag", _test_bc04_ability_curse_bag)
	_run_test("BC-05 ignored bless returns to bag", _test_bc05_ignored_bless_bag)
	_run_test("SHRIV-01 compile if_revealed on skill_test", _test_shriv01_compile_if_revealed)
	_run_test("SHRIV-02 skull take horror at ST.3 before ST.4", _test_shriv02_horror_before_symbol)
	_run_test("SHRIV-03 self-limit one horror despite two skulls", _test_shriv03_self_limit)
	_run_test("CF-01 compile 12059 if_revealed skull", _test_cf01_compile_12059)
	_run_test("CF-02 12059 skull removes charge", _test_cf02_skull_removes_charge)
	_run_test("CF-03 12059 skull no charge damage discard", _test_cf03_skull_no_charge_discard)
	_run_test("SC-11 investigate after sf setup", _test_sc11_investigate_after_sf_setup)
	_run_test("SC-12 setup game begins timing", _test_sc12_setup_game_begins_timing)
	_run_test("SC-13 act1 flip spawns layout", _test_sc13_act1_flip_spawns_layout)
	_run_test("SC-14 agenda2 flip discards fire", _test_sc14_agenda2_flip_discards_fire)
	_run_test("SC-15 act agenda back composition atoms", _test_sc15_act_agenda_back_composition_atoms)
	_run_test("SC-16 agenda1 flip skill horror", _test_sc16_agenda1_flip_skill_horror)
	_run_test("SC-17 agenda2 flip skill damage", _test_sc17_agenda2_flip_skill_damage)
	_run_test("SC-18 agenda3 flip defeat trauma", _test_sc18_agenda3_flip_defeat_trauma)
	_run_test("SC-19 objective all at quad advance", _test_sc19_objective_all_at_quad_advance)
	_run_test("SC-20 objective servant defeated advance", _test_sc20_objective_servant_defeated_advance)
	_run_test("SC-21 act2 flip layout", _test_sc21_act2_flip_layout)
	_run_test("SC-22 act3 flip armitage", _test_sc22_act3_flip_armitage)
	_run_test("SC-23 agenda3 forced draws fire", _test_sc23_agenda3_forced_draws_fire)
	_run_test("SC-24 fire revelation attaches", _test_sc24_fire_revelation_attaches)
	_run_test("SC-25 fire revelation no target discards", _test_sc25_fire_revelation_no_target_discards)
	_run_test("SC-26 agenda enemy-back settles as spawn not drawn", _test_sc26_agenda_enemy_back_not_drawn)
	_run_test("SC-27 agenda treachery-back revelation not drawn", _test_sc27_agenda_treachery_back_not_drawn)
	_run_test("SC-28 01121a flip → Masked Hunter not drawn", _test_sc28_01121_masked_hunter_flip)
	_run_test("SC-29 Masked Hunter blocks discover while engaged", _test_sc29_masked_hunter_forbid_discover)
	_run_test("SC-30 Masked Hunter blocks spend while engaged", _test_sc30_masked_hunter_forbid_spend)
	_run_test("SC-31 Masked Hunter clue forbid clears on disengage", _test_sc31_masked_hunter_forbid_clears)
	_run_test("SC-32 50026a flip → Narôgath not drawn", _test_sc32_50026_narogath_flip)
	_run_test("SC-33 aloof FORBID_ATTACK blocks fight until engaged", _test_sc33_aloof_forbid_attack)
	_run_test("SC-34 Narôgath Prey nearest Cultist engages closer inv", _test_sc34_narogath_prey_nearest_cultist)
	_run_test("PREY-01 nearest_to_enemy_trait distance filter", _test_prey_nearest_to_enemy_trait)
	_run_test("PREY-02 prey tie opens Lead pick window", _test_prey_tie_opens_lead_pick)
	_run_test("C-01 dry-run register created", _test_dry_run_register_only)
	_run_test("C-02 dry-run draw empty deck illegal", _test_dry_run_draw_empty)
	_run_test("C-03 dry-run draw or register", _test_dry_run_draw_or_register)
	_run_test("C-04 register applies modifier", _test_register_modifier)
	_run_test("MOD-01 SKILL_ANY matches any skill query", _test_mod_skill_any)
	_run_test("MOD-02 attack damage bonus single leg", _test_mod_attack_damage_single_leg)
	_run_test("MOD-03 DETERMINED bonus bumps attack damage on primary", _test_mod_attack_damage_determined)
	_run_test("MOD-04 DETERMINED bumps zero primary attack damage", _test_mod_attack_damage_determined_from_zero)
	_run_test("MOD-05 ASSIGN mods attack amount then materialize", _test_mod_attack_damage_assign)
	_run_test("MOD-06 discover bonus single leg investigate", _test_mod_discover_bonus_single_leg)
	_run_test("MOD-07 discover anon bonus pins primary location", _test_mod_discover_determined_multi)
	_run_test("MOD-08 zero-amount discover primary still gets anon bonus", _test_mod_discover_zero_primary_bonus)
	_run_test("MOD-09 shroud modifier lowers investigate difficulty", _test_mod_shroud_investigate)
	_run_test("MOD-10 enemy ENEMY_DAMAGE then DamagePipeline", _test_mod_enemy_damage_then_pipeline)
	_run_test("MOD-11 enemy attack WHEN increase_pending", _test_mod_enemy_attack_increase_pending)
	_run_test("MOD-12 discover named bonus other location", _test_mod_discover_named_bonus)
	_run_test("MOD-13 attack multi-leg settle one seq", _test_mod_attack_multi_leg_settle_one_seq)
	_run_test("MOD-14 discover multi-leg settle one seq", _test_mod_discover_multi_leg_settle_one_seq)
	_run_test("MOD-15 multi-leg damage AFTER fires once", _test_mod_multi_leg_damage_after_once)
	_run_test("MOD-16 deal.assignable damage+horror one seq", _test_mod_deal_assignable_bundle_one_seq)
	_run_test("MOD-17 deal mixed enemy+card legs", _test_mod_deal_mixed_subject_legs)
	_run_test("MOD-18 deal.assignable among card subject", _test_mod_deal_assignable_card_subject)
	_run_test("MOD-19 deal legs_damage/legs_horror empty side", _test_mod_deal_dual_legs_empty_side)
	_run_test("C-05 restriction blocks draw dry-run", _test_restriction_blocks_draw)
	_run_test("C-06 listener draws on timing", _test_listener_draw_on_timing)
	_run_test("C-07 until_fired listener removes self", _test_until_fired_listener)
	_run_test("C-08 listener fires via seq.ability.resolve", _test_listener_no_vacuum)
	_run_test("C-09 initiation dry-run gate", _test_initiation_dry_run_gate)
	_run_test("C-10 choice dry-run OR branch", _test_dry_run_choice_or)
	_run_test("C-11 must choice auto-picks sole branch", _test_must_choice_auto_pick)
	_run_test("C-12 must choice skips all fizzle", _test_must_choice_skip_fizzle)
	_run_test("C-13 must choice asks when multiple", _test_must_choice_pick_option)
	_run_test("C-14 repeat fail-by must choice", _test_repeat_fail_by_must_choice)
	_run_test("C-15 choice_optional default declines", _test_choice_optional_default_decline)
	_run_test("C-16 choice_optional accept runs body", _test_choice_optional_accept)
	_run_test("C-17 choice_optional dry-run OR body", _test_choice_optional_dry_run)
	_run_test("C-18 choice_optional compiler sugar", _test_choice_optional_compiler)
	_run_test("C-19 choice_optional fizzle skips ask", _test_choice_optional_fizzle_skip)
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
	_run_test("RW-01 willingness pool lead picks one at a time", _test_rw_willingness_pool_order)
	_run_test("RW-02 forced before willingness reactions", _test_rw_forced_before_reactions)
	_run_test("RW-03 reaction eligible after nest joins later", _test_rw_reaction_after_nest)
	_run_test("RW-MODE-01 AUTO_JOIN skips ask", _test_rw_mode_auto_join)
	_run_test("RW-MODE-02 AUTO_DECLINE skips pool", _test_rw_mode_auto_decline)
	_run_test("ELIG-L3-01 condition fail skips pool", _test_elig_l3_condition_fail)
	_run_test("ELIG-L3-02 condition pass joins pool", _test_elig_l3_condition_pass)
	_run_test("ELIG-L4-01 peril blocks reaction at collect", _test_elig_l4_peril_collect)
	_run_test("ELIG-L5-01 limit exhausted skips", _test_elig_l5_limit)
	_run_test("ELIG-01 collect has no dry_run", _test_elig_collect_no_dry_run)
	_run_test("PW-01 intent pool sole resolves on pulse", _test_pw_intent_sole_pulse)
	_run_test("PW-02 intent pool contention lead pick", _test_pw_intent_contention)
	_run_test("PW-03 empty pulse closes window", _test_pw_intent_empty_closes)
	_run_test("PW-BATCH-01 01017 physical training x3", _test_pw_batch_01017)
	_run_test("TRIG-05 install triggered on asset play", _test_trig_install_on_play)
	_run_test("TRIG-06 free listed in player window", _test_trig_free_listed_in_window)
	_run_test("TRIG-07 free activate exhausts and moves", _test_trig_free_activate_move)
	_run_test("ADB-25 compile olivier free move", _test_adb_compile_olivier_free)
	_run_test("ADB-26 olivier free activate vertical", _test_adb_olivier_free_activate)
	_run_test("ADB-27 compile 12125 forced discover horror", _test_adb_compile_12125_forced)
	_run_test("ADB-28 12125 forced after discover", _test_adb_12125_forced_discover)
	_run_test("ADB-29 compile 12108 forced place doom", _test_adb_compile_12108_forced)
	_run_test("ADB-30 compile 12145 reaction discover resource", _test_adb_compile_12145_reaction)
	_run_test("ADB-31 12145 reaction after discover", _test_adb_12145_reaction_discover)
	_run_test("ADB-32 12145 reaction declined", _test_adb_12145_reaction_declined)
	_run_test("ADB-73 compile 12060 Jim after take", _test_adb_compile_12060_jim_take)
	_run_test("ADB-74 12060 Jim after take draws", _test_adb_12060_jim_after_take)
	_run_test("SEQ-EFF-01 nest take_horror", _test_seq_eff_nest_take_horror)
	_run_test("SEQ-EFF-02 nest register unregister", _test_seq_eff_register_unregister)
	_run_test("SEQ-EFF-03 lose resources fizzle", _test_seq_eff_lose_resources_fizzle)
	_run_test("SEQ-EFF-04 nest heal", _test_seq_eff_heal)
	_run_test("SEQ-EFF-05 nest place doom source", _test_seq_eff_place_doom_source)
	_run_test("SEQ-EFF-06 nest discard from hand", _test_seq_eff_discard_from_hand)
	_run_test("SEQ-EFF-07 nest attach controller location", _test_seq_eff_attach_controller_location)
	_run_test("SEQ-EFF-08 nest deal damage at location", _test_seq_eff_deal_damage_at_location)
	_run_test("SEQ-EFF-09 nest deal damage attached fire", _test_seq_eff_deal_damage_attached)
	_run_test("ADB-33 compile 12130 skill choice", _test_adb_compile_12130_skill_choice)
	_run_test("ADB-72 compile 12127 hand-count difficulty", _test_adb_compile_12127)
	_run_test("ENC-12127 extraplanar visions fail path", _test_enc_12127_fail)
	_run_test("ADB-34 compile 12164 lose or attack", _test_adb_compile_12164_lose_or_attack)
	_run_test("ADB-35 compile 12188 place doom source", _test_adb_compile_12188_place_doom)
	_run_test("ADB-36 compile 12184 lose action", _test_adb_compile_12184_lose_action)
	_run_test("ADB-37 compile 12128 fail-by discard or resource", _test_adb_compile_12128_fail_by)
	_run_test("ADB-38 compile 12159 flash flood attach", _test_adb_compile_12159_attach)
	_run_test("ADB-39 compile 12117 heal damage and horror", _test_adb_compile_12117_heal)
	_run_test("ADB-40 compile 12102 weakness discard action", _test_adb_compile_12102_discard_action)
	_run_test("ADB-41 compile 12129 fire forced phase ends", _test_adb_compile_12129_fire_forced)
	_run_test("ADB-42 12102 activate_action discard", _test_adb_12102_activate_action_discard)
	_run_test("ADB-43 12129 fire forced on phase ends", _test_adb_12129_fire_forced_phase_ends)
	_run_test("ADB-44 compile 12106 parley action types", _test_adb_compile_12106_parley)
	_run_test("ADB-45 parley action skips AOO", _test_adb_parley_skips_aoo)
	_run_test("SEQ-EFF-10 discard_card bystander at location", _test_seq_eff_discard_bystander)
	_run_test("ADB-46 compile 12112 resign and group clues", _test_adb_compile_12112)
	_run_test("ADB-47 resign inline via initiation on stack", _test_adb_resign_inline_initiation)
	_run_test("ADB-48 compile 12113 engage connecting no AOO", _test_adb_compile_12113)
	_run_test("ADB-49 engage types provoke AOO by default", _test_adb_engage_types_provoke_aoo)
	_run_test("ADB-50 12113 engage connecting skips AOO", _test_adb_12113_engage_connecting)
	_run_test("ADB-51 compile 12118 discard hand after discover", _test_adb_compile_12118)
	_run_test("ADB-52 compile 12119 reaction draw", _test_adb_compile_12119)
	_run_test("ADB-53 compile 12120 draw three", _test_adb_compile_12120)
	_run_test("ADB-54 12120 activate draws three", _test_adb_12120_draw_three)
	_run_test("ADB-55 compile 12116 fast move inv count", _test_adb_compile_12116)
	_run_test("ADB-56 compile 12132 enemy defeated forced", _test_adb_compile_12132)
	_run_test("ADB-57 12132 defeat deals location horror", _test_adb_12132_defeat_horror)
	_run_test("ADB-58 compile 12122 after attack discard asset", _test_adb_compile_12122)
	_run_test("ADB-59 12122 phase attack discards asset", _test_adb_12122_discard_asset)
	_run_test("ADB-60 SKIP_AOO restriction read branches AOO", _test_adb_skip_aoo_buff_consume)
	_run_test("ADB-61 SUPPRESS_AUTO_ENGAGE after move keeps explicit engage", _test_adb_suppress_auto_engage_explicit)
	_run_test("ADB-62 SelectionSpec filter ready enemy at connecting", _test_adb_selection_filter_ready)
	_run_test("ADB-63 V dry-run drops already-exhausted for choose exhaust", _test_adb_viability_exhaust_enemy)
	_run_test("ADB-64 V empty set fizzles choose exhaust when all exhausted", _test_adb_viability_exhaust_all_exhausted)
	_run_test("ADB-65 N preds fight le filters weak enemy", _test_adb_preds_fight_le)
	_run_test("ADB-66 N preds controller resources gate", _test_adb_preds_controller_resources)
	_run_test("ADB-67 pick_multi default takes first max", _test_adb_pick_multi_default)
	_run_test("ADB-68 pick_multi scripting subset", _test_adb_pick_multi_scripting)
	_run_test("ADB-69 pick_multi for_each exhausts list", _test_adb_pick_multi_for_each)
	_run_test("ADB-70 pick_multi min unsatisfied fizzles", _test_adb_pick_multi_min_fizzle)
	_run_test("ADB-71 pick_multi compiler sugar", _test_adb_pick_multi_compiler)
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
	_run_test("ADB-10b compile prey nearest Cultist enemy", _test_adb_prey_nearest_cultist)
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
	_run_test("ENC-SURGE-01 keyword seq nest", _test_enc_surge_nests_keyword_seq)
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
	_run_test("KW-OCC-01 keyword listener occasions table", _test_kw_occ_profile_table)
	_run_test("KW-OCC-02 leave play unregisters only in-play", _test_kw_occ_leave_play_scoped)
	_run_test("KW-OCC-03 leave hand unregisters hidden not in-play", _test_kw_occ_leave_hand_scoped)
	_run_test("KW-OCC-04 peril finalize is not leave play", _test_kw_occ_peril_finalize)
	_run_test("KW-FAST-01 play forms stay PLAY_CARD", _test_kw_fast_play_form)
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
	_run_test("WKN-03 enemy weakness uses encounter ability package", _test_wkn_enemy_weakness_encounter_package)
	_run_test("ENC-28 drawn location uses encounter package into play", _test_enc_drawn_location_into_play)
	_run_test("CARD-BACK-01 player vs encounter back axis", _test_card_back_axis)
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
	_run_test("PERIL-07 peril registers via seq.effect.register", _test_peril_register_no_vacuum)
	_run_test("ST-07 apply success callback", _test_st_apply_success)
	_run_test("ST-08 end discards committed", _test_st_end_cleanup)
	_run_test("BAG-LEDGER-01 skill reveal ledger clears at ST.8", _test_bag_ledger_skill_reveal)
	_run_test("BAG-LEDGER-02 ability curse if-revealed binary eager", _test_bag_ledger_ability_curse_gate)
	_run_test("BAG-LEDGER-03 cancel excludes from if-revealed", _test_bag_ledger_cancel_excludes)
	_run_test("BAG-LEDGER-04 if-revealed self-limits once per test", _test_bag_ledger_self_limit)
	_run_test("BAG-LEDGER-04b for-each fires per curse no self-limit", _test_bag_ledger_each_mode)
	_run_test("BAG-LEDGER-05 ST.3 eager before ST.4 no double", _test_bag_ledger_st3_eager_before_st4)
	_run_test("BAG-INTENT-01 no replace equals single draw", _test_bag_intent_no_replace)
	_run_test("BAG-INTENT-02 Olive reveal3 resolve2", _test_bag_intent_olive_alone)
	_run_test("BAG-INTENT-03 Olive then Statue order+slot", _test_bag_intent_olive_then_statue)
	_run_test("BAG-INTENT-04 Statue then Olive order", _test_bag_intent_statue_then_olive)
	_run_test("BAG-INTENT-05 ST.3 multi resolved modifiers", _test_bag_intent_st3_multi_modifiers)
	_run_test("BAG-IGNORE-01 olive ignore still revealed not resolved", _test_bag_ignore_olive_revealed)
	_run_test("BAG-IGNORE-02 cancel excludes revealed and resolved", _test_bag_ignore_cancel_excludes_both)
	_run_test("BAG-IGNORE-03 if-revealed uses resolved not ignored", _test_bag_ignore_gate_skips_ignored)
	_run_test("BAG-WIRE-01 compile 12068 mask silenus", _test_bag_wire_compile_12068)
	_run_test("BAG-WIRE-02 12068 would-reveal queues replace", _test_bag_wire_12068_vertical)
	_run_test("BAG-WIRE-03 12068 resolved symbol takes horror", _test_bag_wire_12068_symbol_horror)
	_run_test("BAG-USES-01 enter play places Uses charges", _test_bag_uses_enter_play)
	_run_test("BAG-SEAL-01 seal_random leaves bag", _test_bag_seal_random)
	_run_test("BAG-SEAL-02 seal_kind missing fails", _test_bag_seal_kind_missing)
	_run_test("BAG-SEAL-03 leave play releases", _test_bag_seal_leave_play_release)
	_run_test("BAG-SEAL-04 seq.effect.seal nest", _test_bag_seal_catalog_nest)
	_run_test("BAG-SEAL-05 sealed reveal instead", _test_bag_seal_reveal_instead)
	_run_test("BAG-SEAL-06 keyword cost gate blocks play", _test_bag_seal_keyword_cost_gate)
	_run_test("BAG-SEAL-07 keyword play seals on enter", _test_bag_seal_keyword_play_enter)
	_run_test("BAG-SEAL-08 keyword choice seals one", _test_bag_seal_keyword_choice)
	_run_test("BAG-SEAL-09 put into play seals via zone", _test_bag_seal_keyword_zone_enter)
	_run_test("ACT-01 investigate discovers clue", _test_act_investigate_success)
	_run_test("ACT-02 investigate fail no clue", _test_act_investigate_fail)
	_run_test("ACT-03 fight deals damage", _test_act_fight_success)
	_run_test("ACT-04 evade disengages enemy", _test_act_evade_success)
	_run_test("ACT-05 evade requires engagement", _test_act_evade_not_engaged)
	_run_test("ACT-06 fight rejects aloof", _test_act_fight_aloof)
	_run_test("ACT-IMP-01 fight auto-binds sole enemy", _test_act_imp_fight_auto_bind)
	_run_test("ACT-IMP-02 fight empty legal set fails pre-spend", _test_act_imp_fight_no_target)
	_run_test("ACT-IMP-03 evade auto-binds engaged enemy", _test_act_imp_evade_auto_bind)
	_run_test("ACT-IMP-04 fight picks among two enemies", _test_act_imp_fight_two_enemies)
	_run_test("ACT-IMP-05 investigate wrong location fails pre-spend", _test_act_imp_investigate_wrong_loc)
	_run_test("ACT-07 engage adds to threat area", _test_act_engage_success)
	_run_test("ACT-08 engage steals enemy", _test_act_engage_steal)
	_run_test("ACT-09 engage rejects massive", _test_act_engage_massive)
	_run_test("ACT-09b action engage nests seq.engage effect", _test_act_engage_nests_kernel)
	_run_test("ACT-10 engage then fight aloof", _test_act_engage_then_fight)
	_run_test("ENGAGE-01 grant buff without moving into threat area", _test_engage_grant_cross_location)
	_run_test("ENGAGE-02 enter_threat moves into threat area and buff", _test_engage_enter_threat_buff)
	_run_test("ENGAGE-03 disengage clears engagement buff", _test_engage_disengage_clears_buff)
	_run_test("M4-01 effect.gain_resource registered with alias", _test_m4_gain_resource_rename)
	_run_test("ACT-16 fight fail redirects to engaged holder", _test_act_fight_fail_redirect)
	_run_test("AOO-01 resource provokes damage", _test_aoo_resource)
	_run_test("AOO-02 fight skips aoo", _test_aoo_fight_skip)
	_run_test("AOO-03 exhausted enemy skips aoo", _test_aoo_exhausted_skip)
	_run_test("ACT-11 move to connected location", _test_act_move_success)
	_run_test("ACT-11b action move nests seq.effect.move", _test_act_move_nests_effect_move)
	_run_test("ACT-12 move rejects disconnected", _test_act_move_fail)
	_run_test("G1-01 seq.effect.move registered", _test_g1_effect_move_registered)
	_run_test("G1-02 seq.effect.move enemy subject", _test_g1_effect_move_enemy)
	_run_test("G1-03 seq.effect.move attachment", _test_g1_effect_move_attachment)
	_run_test("G1-04 seq.effect.move marker clue", _test_g1_effect_move_marker)
	_run_test("G1-05 seq.effect.move enemy move_to", _test_g1_effect_move_enemy_move_to)
	_run_test("G1-06 elusive flee nests move", _test_g1_elusive_flee_nests_move)
	_run_test("G1-07 move rejects disconnected", _test_g1_move_rejects_disconnected)
	_run_test("G1-08 move_to ignores connections", _test_g1_move_to_ignores_connections)
	_run_test("L-01 per_investigator clues on reveal", _test_l01_per_investigator_clues)
	_run_test("L-02 move to unrevealed reveals and places clues", _test_l02_move_unrevealed)
	_run_test("L-02b re-enter revealed does not place clues again", _test_l02b_reenter_no_reclues)
	_run_test("L-02c enemy move does not reveal location", _test_l02c_enemy_move_no_reveal)
	_run_test("G2-01 seq.effect.exhaust enemy", _test_g2_exhaust_enemy)
	_run_test("EVADE-01 seq.effect.evade attempt success", _test_evade_effect_attempt)
	_run_test("EVADE-02 automatically evade unengaged", _test_evade_automatic_unengaged)
	_run_test("EVADE-03 composition automatically_evade", _test_evade_composition_auto)
	_run_test("G2-02 seq.effect.ready enemy engages", _test_g2_ready_enemy_engages)
	_run_test("G2-03 seq.effect.exhaust card in play", _test_g2_exhaust_card_in_play)
	_run_test("G2-04 exhaust rejects hand card", _test_g2_exhaust_rejects_hand)
	_run_test("G2-05 upkeep 4.3 readies flat cards", _test_g2_upkeep_ready_flat_cards)
	_run_test("G3-01 seq.effect.search entire deck take shuffle", _test_g3_search_entire_take_shuffle)
	_run_test("G3-02 seq.effect.search top N still shuffles deck", _test_g3_search_top_shuffles)
	_run_test("G3-03 search catalog registered", _test_g3_search_catalog)
	_run_test("G5-01 defeat cancel skips leave-play", _test_g5_defeat_cancel_no_leave)
	_run_test("G5-02 damage cap standing re-triggers after cancel", _test_g5_damage_cap_retriggers)
	_run_test("G5-03 effect defeat ignores health", _test_g5_effect_defeat)
	_run_test("G5-04 investigator horror cap defeat", _test_g5_investigator_horror_cap)
	_run_test("G5-05 defeat catalog registered", _test_g5_defeat_catalog)
	_run_test("G5-06 enemy attack damage cap defeats investigator", _test_g5_enemy_attack_damage_cap)
	_run_test("G5-07 asset damage cap leave to discard not discard effect", _test_g5_asset_damage_cap)
	_run_test("G5-08 asset effect defeat to discard", _test_g5_asset_effect_defeat)
	_run_test("G5-09 asset defeat cancel skips leave", _test_g5_asset_cancel_no_leave)
	_run_test("G5-10 unowned story asset defeat to REMOVED", _test_g5_unowned_story_asset_removed)
	_run_test("G5-11 weakness enemy defeat to owner discard", _test_g5_weakness_enemy_owner_discard)
	_run_test("G5-12 vengeance enemy defeat to victory display", _test_g5_vengeance_to_victory_display)
	_run_test("ZM-01 seq.zone.move catalog", _test_zm_catalog)
	_run_test("ZM-02 leave play on discard from play", _test_zm_leave_play_discard_asset)
	_run_test("ZM-03 enemy discard-from-play leave play", _test_zm_enemy_discard_leave_play)
	_run_test("ZM-04 leave play returns tokens to pool", _test_zm_leave_play_tokens_to_pool)
	_run_test("ZM-05 leave play discards attachments", _test_zm_leave_play_discards_attachments)
	_run_test("ZM-06 defeat asset leave cleans tokens+attachments", _test_zm_defeat_asset_leave_cleanup)
	_run_test("G6-01 phase boundary catalog", _test_g6_phase_boundary_catalog)
	_run_test("G6-02 framework emits phase boundary seq", _test_g6_framework_emits)
	_run_test("EV-01 seq.effect.evade catalog", _test_ev_catalog)
	_run_test("EV-02 action success nests evade effect", _test_ev_action_nests_effect)
	_run_test("EV-03 automatically evade no skill test", _test_ev_automatically_evade)
	_run_test("EV-04 legacy mode=effect → automatic", _test_ev_mode_effect_normalizes)
	_run_test("I2-01 vacuum execute refused", _test_i2_vacuum_execute_refused)
	_run_test("I2-02 mount nests ability.resolve", _test_i2_mount_nests_frame)
	_run_test("ACT-13 draw from deck", _test_act_draw_from_deck)
	_run_test("ACT-14 draw shuffles discard", _test_act_draw_shuffle)
	_run_test("ACT-15 draw empty piles defeated", _test_act_draw_defeated)
	_run_test("ACT-CAT-01 action seq catalog registered", _test_act_catalog_registered)
	_run_test("ACT-CAT-02 action gain fires after_gain_resource", _test_act_catalog_gain_after_listener)
	_run_test("SEQ-AUDIT-01 full catalog inventory", _test_seq_audit_catalog_inventory)
	_run_test("VIS-01 draw reveal before hand", _test_vis_draw_reveal_before_hand)
	_run_test("VIS-02 draw face known to controller only", _test_vis_draw_controller_only)
	_run_test("DRAW-02 draw two simultaneous", _test_draw_two_simultaneous)
	_run_test("DRAW-03 draw two mid-deck shuffle", _test_draw_two_mid_shuffle)
	GameBootstrap.register_enter_hand_test_definitions()
	_run_test("ENT-01 enter_hand revelation take horror", _test_ent_revelation_take_horror)
	_run_test("ENT-02 enter_hand no revelation", _test_ent_no_revelation)
	_run_test("ENT-03 enter_hand revelation order and limbo discard", _test_ent_revelation_order)
	_run_test("TIMING-ZONE-01 would-deck when-hand-or-limbo", _test_draw_when_zones)
	_run_test("TIM-01 draw investigator SPLIT zones", _test_tim_draw_investigator_split)
	_run_test("TIM-02 draw encounter SPLIT zones", _test_tim_draw_encounter_split)
	_run_test("TIM-DMG-01 WOULD then WHEN before Apply", _test_tim_dmg_apply_slots)
	_run_test("TIM-DMG-02 WOULD reduce_pending before Apply", _test_tim_dmg_prevent)
	_run_test("TIM-DMG-03 WHEN increase_pending adds delta K", _test_tim_dmg_increase_pending)
	_run_test("TIM-DMG-04 increase_pending keeps reserved legs", _test_tim_dmg_increase_keeps_legs)
	_run_test("TIM-DMG-05 outbound WOULD before Apply", _test_tim_dmg_outbound_preimpact)
	_run_test("TIM-DMG-06 outbound reduce_pending", _test_tim_dmg_outbound_reduce)
	_run_test("ASN-01 PRIOR_FILL horror to asset first", _test_asn_prior_fill)
	_run_test("ASN-02 MIN_TO_SUBJECT damage if able", _test_asn_min_to_subject)
	_run_test("ASN-03 MAX_TO_MATCH trait cap", _test_asn_max_to_match)
	_run_test("ASN-04 INCLUDE direct allows asset assign", _test_asn_include_direct)
	_run_test("ASN-05 INCLUDE Bodyguard other at location", _test_asn_include_bodyguard)
	_run_test("ASN-06 pipeline apply PRIOR_FILL legs", _test_asn_pipeline_prior_fill)
	_run_test("ASN-07 GRANT_CAPACITY without printed health", _test_asn_grant_capacity)
	_run_test("ASN-08 Assign Gate scripted legs", _test_asn_gate_scripted)
	_run_test("ASN-09 Assign Gate among subjects", _test_asn_gate_among)
	_run_test("TIM-DMG-07 AFTER affliction filters", _test_tim_dmg_after_affliction_filters)
	_run_test("TIM-DMG-08 AFTER take after nested defeat", _test_tim_dmg_after_take_after_defeat)
	_run_test("TIMING-REV-01 revelation own priority class", _test_revelation_own_priority_class)
	_run_test("REG-01 turn end ticks duration", _test_reg_turn_end_tick)
	_run_test("NS-01 nested sequence LIFO", _test_ns_lifo_nest)
	_run_test("NS-02 after waits for nested child", _test_ns_after_order)
	_run_test("NS-03 upkeep framework resource modifier", _test_ns_upkeep_resource_modifier)
	_run_test("NS-04 gain sequence fires after listener", _test_ns_gain_after_listener)
	_run_test("NS-05 response window refresh after nest", _test_ns_refresh_after_nest)
	_run_test("NS-06 reaction blocked on own resolution", _test_ns_self_response_blocked)
	_run_test("PI-01 default optional declines", _test_pi_default_optional_decline)
	_run_test("PI-02 scripting resolver by prompt_id", _test_pi_scripting_resolver)
	_run_test("PI-03 default pick_target used_default", _test_pi_default_pick_used_default)
	_run_test("PI-04 scripting explicit not used_default", _test_pi_scripting_not_default)
	_run_test("PI-05 scripting miss falls to default", _test_pi_scripting_miss_default)
	_run_test("PI-06 INTERACTION_CHOICE event record", _test_pi_interaction_event_record)
	_run_test("PI-07 compute_default pick_multi first N", _test_pi_compute_default_multi)
	_run_test("PI-AUTO-01 registration order pick", _test_pi_auto_registration_order)
	_run_test("PI-AUTO-02 random pick deterministic seed", _test_pi_auto_random_seed)
	_run_test("PI-AUTO-03 random order shuffles", _test_pi_auto_random_order)
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
	_run_test("EN-20 fight fail redirect and retaliate", _test_en20_fight_fail_redirect_and_retaliate)
	_run_test("EN-21 alert on aloof unengaged evade fail", _test_en21_alert_aloof_unengaged)
	_run_test("EN-22 fight success elusive enemy flees", _test_en22_fight_success_elusive_flees)
	_run_test("EN-23 defeat doomed places agenda doom", _test_en23_defeat_doomed_places_doom)
	_run_test("EN-24 discard enemy skips doomed", _test_en24_discard_enemy_skips_doomed)
	_run_test("EN-25 defeat non-doomed no agenda doom", _test_en25_defeat_non_doomed_no_doom)
	_run_test("EN-26 defeat victory enemy to display", _test_en26_defeat_victory_to_display)
	_run_test("EN-27 discard victory enemy not to display", _test_en27_discard_victory_not_to_display)
	_run_test("ADB-23 import bystander doomed text", _test_adb_import_bystander_doomed)
	_run_test("ADB-24 import elite servant victory points", _test_adb_import_elite_servant_victory)
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


func _test_mtb_expand_legs() -> bool:
	## 2+1 → 2+1：展开为三条原子腿（非单次 L0）。
	var a := MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE)
	var b := MarkerSlot.investigator(&"inv_2", AhcEnums.MarkerKind.RESOURCE)
	var c := MarkerSlot.investigator(&"inv_3", AhcEnums.MarkerKind.RESOURCE)
	var d := MarkerSlot.investigator(&"inv_4", AhcEnums.MarkerKind.RESOURCE)
	var legs := MarkerTransferBatch.expand(
		[{"slot": a, "amount": 2}, {"slot": b, "amount": 1}],
		[{"slot": c, "amount": 2}, {"slot": d, "amount": 1}]
	)
	if legs.size() != 2:
		return false
	return (
		int(legs[0].get("amount", 0)) == 2
		and (legs[0].get("from") as MarkerSlot).bearer_id == &"inv_1"
		and (legs[0].get("to") as MarkerSlot).bearer_id == &"inv_3"
		and int(legs[1].get("amount", 0)) == 1
		and (legs[1].get("from") as MarkerSlot).bearer_id == &"inv_2"
		and (legs[1].get("to") as MarkerSlot).bearer_id == &"inv_4"
	)


func _test_mtb_execute_resources() -> bool:
	## 1→2：包装展开为两条原子 transfer_marker（2+1）。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_minimal_investigator(h.ctx, &"inv_2")
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	inv1.resource_pool = 5
	inv2.resource_pool = 0
	var ok := MarkerTransferBatch.execute(
		h.ctx.mutator,
		AhcEnums.MarkerKind.RESOURCE,
		[{"slot": MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE), "amount": 3}],
		[
			{"slot": MarkerSlot.investigator(&"inv_2", AhcEnums.MarkerKind.RESOURCE), "amount": 2},
			{"slot": MarkerSlot.investigator(&"inv_2", AhcEnums.MarkerKind.RESOURCE), "amount": 1},
		]
	)
	return ok and inv1.resource_pool == 2 and inv2.resource_pool == 3


func _test_mtb_sum_mismatch() -> bool:
	var legs := MarkerTransferBatch.expand(
		[{"slot": MarkerSlot.investigator(&"a", AhcEnums.MarkerKind.RESOURCE), "amount": 2}],
		[{"slot": MarkerSlot.investigator(&"b", AhcEnums.MarkerKind.RESOURCE), "amount": 1}]
	)
	return legs.is_empty()


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


func _prepare_sf_act_agenda_defs() -> void:
	ScenarioSetupCatalog.prepare_definitions(ScenarioSetupCatalog.SPREADING_FLAMES)


func _test_sc05_agenda_flip_promotes() -> bool:
	var h := RuleTestHarness.new(42)
	_prepare_sf_act_agenda_defs()
	var setup := h.ctx.scenario.setup_act_agenda_decks([], [&"12106", &"12107", &"12108"])
	if not setup.get("ok", false):
		return false
	var first_id := h.ctx.state.current_agenda_card_id
	h.ctx.state.doom_on_agenda = 3
	var advance := h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"mythos_1_3", "explicit": true}
	)
	var flipped := h.ctx.state.registry.get_card(first_id)
	var current := h.ctx.state.registry.get_card(h.ctx.state.current_agenda_card_id)
	return (
		advance.get("advanced", false)
		and h.ctx.state.current_agenda_number == 2
		and h.ctx.state.agenda_threshold == 5
		and h.ctx.state.doom_on_agenda == 0
		and h.ctx.state.removed_from_game.has(first_id)
		and flipped != null
		and flipped.face == AhcEnums.CardFace.B
		and flipped.zone == AhcEnums.Zone.REMOVED_FROM_GAME
		and current != null
		and current.face == AhcEnums.CardFace.A
		and current.zone == AhcEnums.Zone.CURRENT_AGENDA
		and h.ctx.state.current_agenda_card_id != first_id
	)


func _test_sc06_act_flip_resolution() -> bool:
	var h := RuleTestHarness.new(42)
	_prepare_sf_act_agenda_defs()
	var setup := h.ctx.scenario.setup_act_agenda_decks([&"12112"], [])
	if not setup.get("ok", false):
		return false
	var act_id := h.ctx.state.current_act_card_id
	var advance := h.ctx.sequence_catalog.run(
		h.ctx, &"seq.act.advance", {"skip_clue_spend": true}
	)
	var flipped := h.ctx.state.registry.get_card(act_id)
	return (
		advance.get("advanced", false)
		and h.ctx.state.scenario_resolution == 1
		and h.ctx.framework.current_step == AhcEnums.FrameworkStep.SCENARIO_RESOLUTION
		and flipped != null
		and flipped.face == AhcEnums.CardFace.B
		and h.ctx.state.removed_from_game.has(act_id)
		and h.ctx.state.current_act_card_id == &""
	)


func _test_sc07_act_advance_spends_clues() -> bool:
	var h := RuleTestHarness.new(42)
	_prepare_sf_act_agenda_defs()
	var setup := h.ctx.scenario.setup_act_agenda_decks([&"12109", &"12110"], [])
	if not setup.get("ok", false):
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.clues_on_card = 1
	var blocked := h.ctx.sequence_catalog.run(h.ctx, &"seq.act.advance", {})
	if blocked.get("advanced", true):
		return false
	inv.clues_on_card = 2
	var advance := h.ctx.sequence_catalog.run(h.ctx, &"seq.act.advance", {})
	var current := h.ctx.state.registry.get_card(h.ctx.state.current_act_card_id)
	return (
		advance.get("advanced", false)
		and inv.clues_on_card == 0
		and h.ctx.state.current_act_number == 2
		and current != null
		and current.id.definition_id == &"12110"
	)


func _test_sc08_setup_wires_act_agenda_decks() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	var agenda := h.ctx.state.registry.get_card(h.ctx.state.current_agenda_card_id)
	var act := h.ctx.state.registry.get_card(h.ctx.state.current_act_card_id)
	return (
		agenda != null
		and agenda.id.definition_id == &"12106"
		and agenda.zone == AhcEnums.Zone.CURRENT_AGENDA
		and h.ctx.state.agenda_threshold == 3
		and h.ctx.state.current_agenda_number == 1
		and h.ctx.state.agenda_deck.size() == 2
		and act != null
		and act.id.definition_id == &"12109"
		and act.zone == AhcEnums.Zone.CURRENT_ACT
		and h.ctx.state.act_clue_threshold == 2
		and h.ctx.state.current_act_number == 1
		and h.ctx.state.act_deck.size() == 3
		and h.framework_step() == AhcEnums.FrameworkStep.INV_2_1_PHASE_BEGINS
	)


func _sf_set_aside_count(h: RuleTestHarness, definition_id: StringName) -> int:
	var count := 0
	for card_id in h.ctx.state.set_aside:
		var card := h.ctx.state.registry.get_card(card_id)
		if card != null and card.id.definition_id == definition_id:
			count += 1
	return count


func _test_sc09_setup_scenario_layout() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	var loc := h.ctx.state.registry.get_location(&"12113")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var dorm := h.ctx.state.registry.get_location(&"12117")
	return (
		h.ctx.state.scenario_layout_installed
		and loc != null
		and loc.revealed
		and loc.shroud == 2
		and loc.clues == 2
		and inv != null
		and inv.location_tag == &"12113"
		and dorm != null
		and not dorm.revealed
		and _sf_set_aside_count(h, &"12129") == 5
		and _sf_set_aside_count(h, &"12114") == 1
		and _sf_set_aside_count(h, &"12115") == 1
		and h.ctx.state.encounter_deck.size() >= 10
		and h.ctx.state.per_investigator_count == 1
	)


func _test_sc10_setup_scenario_reference() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	var ref := h.ctx.state.registry.get_card(h.ctx.state.scenario_reference_card_id)
	return (
		ref != null
		and ref.id.definition_id == &"12105"
		and ref.zone == AhcEnums.Zone.PLAY_AREA
		and h.ctx.state.scenario_reference != null
		and ref.symbol_abilities.size() == 3
		and not ref.text_box_blank
	)


func _test_ref01_sf_loads_reference_json() -> bool:
	ScenarioReferenceCatalog.clear_cache()
	var def := ScenarioReferenceCatalog.load_for_scenario(&"spreading_flames")
	if def == null or def.reference_card != &"12105":
		return false
	var easy_skull := def.effect_for(&"easy_standard", AhcEnums.ChaosTokenKind.SKULL)
	var hard_skull := def.effect_for(&"hard_expert", AhcEnums.ChaosTokenKind.SKULL)
	var tablet := def.effect_for(&"easy_standard", AhcEnums.ChaosTokenKind.TABLET)
	return (
		not easy_skull.is_empty()
		and not hard_skull.is_empty()
		and bool(tablet.get("reveal_another", false))
		and str((easy_skull.get("modifier", {}) as Dictionary).get("expr", "")) == "neg_act"
		and str((hard_skull.get("modifier", {}) as Dictionary).get("expr", "")) == "neg_act_plus_1"
	)


func _test_ref02_sf_skull_neg_act() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	h.ctx.state.current_act_number = 2
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.symbol(AhcEnums.ChaosTokenKind.SKULL, 0, &"sk_ref"),
	])
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 0)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.resolve_reveal_chain(test)
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.continue_after_reveal_window(test)
	var ok := test.chaos_modifier == -2
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return ok


func _test_ref03_sf_tablet_fail_damage() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var dmg_before := inv.damage_taken
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 9)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	## 直接注入 tablet，避免 draw_random 次序抖动。
	var tab := ChaosToken.symbol(AhcEnums.ChaosTokenKind.TABLET, 0, &"tab_ref")
	test.revealed_tokens.append(tab)
	test.reveal_batch_start = 0
	h.ctx.skill_tests.step_apply_symbol_effects(test)
	test.success = false
	test.fail_by = 5
	h.ctx.skill_tests.step_apply_results(test)
	var ok := (
		test.chaos_modifier == -1
		and tab.reveal_another
		and inv.damage_taken == dmg_before + 1
	)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return ok


func _test_ref04_sf_elder_thing_fail_by_fire() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	## 从 set-aside 挪一张 Fire! 进遭遇弃牌堆供参考卡抽取。
	var fire_id := &""
	for cid in h.ctx.state.set_aside:
		var c := h.ctx.state.registry.get_card(cid)
		if c != null and c.id.definition_id == &"12129":
			fire_id = cid
			break
	if fire_id == &"":
		return false
	h.ctx.state.set_aside.erase(fire_id)
	h.ctx.state.encounter_discard.append(fire_id)
	var fire_card := h.ctx.state.registry.get_card(fire_id)
	fire_card.zone = AhcEnums.Zone.DISCARD
	var discard_before := _encounter_discard_count(h, &"12129")
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 9)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	var et := ChaosToken.symbol(AhcEnums.ChaosTokenKind.ELDER_THING, 0, &"et_ref")
	test.revealed_tokens.append(et)
	test.reveal_batch_start = 0
	h.ctx.skill_tests.step_apply_symbol_effects(test)
	test.success = false
	test.fail_by = 3
	h.ctx.skill_tests.step_apply_results(test)
	var discard_after := _encounter_discard_count(h, &"12129")
	var ok := (
		test.chaos_modifier == -3
		and discard_before >= 1
		and discard_after == discard_before - 1
	)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return ok


func _test_ref05_sf_hard_skull() -> bool:
	var cfg := GameBootstrap.config_spreading_flames()
	cfg.chaos_difficulty = &"hard_expert"
	var h := RuleTestHarness.new(42, cfg)
	h.run_setup()
	h.ctx.state.current_act_number = 2
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.symbol(AhcEnums.ChaosTokenKind.SKULL, 0, &"sk_hard"),
	])
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 0)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.resolve_reveal_chain(test)
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.continue_after_reveal_window(test)
	## Hard：-(act+1) = -3。
	var ok := test.chaos_modifier == -3
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return ok


func _test_ref06_blank_skips_printed_symbol() -> bool:
	## 文本框空白：印刷符号能力不发起；不清零回退 –act。
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	h.ctx.state.current_act_number = 2
	var ref_id := h.ctx.state.scenario_reference_card_id
	var ref := h.ctx.state.registry.get_card(ref_id)
	if ref == null or ref.symbol_abilities.is_empty():
		return false
	TextBoxBlank.set_blank_by_id(h.ctx, ref_id, true)
	if ref.active_symbol_ability(AhcEnums.ChaosTokenKind.SKULL) != null:
		return false
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.symbol(AhcEnums.ChaosTokenKind.SKULL, 0, &"sk_blank"),
	])
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 0)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.resolve_reveal_chain(test)
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.continue_after_reveal_window(test)
	var ok_blank := test.chaos_modifier == 0
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	## 解除空白后应恢复印刷能力。
	TextBoxBlank.set_blank_by_id(h.ctx, ref_id, false)
	if ref.active_symbol_ability(AhcEnums.ChaosTokenKind.SKULL) == null:
		return false
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.symbol(AhcEnums.ChaosTokenKind.SKULL, 0, &"sk_unblank"),
	])
	var test2 := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 0)
	h.ctx.skill_tests.begin_test(test2, h.ctx)
	h.ctx.skill_tests.step_commit(test2, [])
	h.ctx.skill_tests.close_player_window(test2)
	h.ctx.skill_tests.resolve_reveal_chain(test2)
	h.ctx.skill_tests.close_player_window(test2)
	h.ctx.skill_tests.continue_after_reveal_window(test2)
	var ok_restore := test2.chaos_modifier == -2
	h.ctx.skill_tests.step_apply_results(test2)
	h.ctx.skill_tests.step_end(test2, h.ctx)
	return ok_blank and ok_restore


func _test_ref07_blank_skips_tablet_st7() -> bool:
	## 空白时 tablet 不施加 reveal_another / on_fail 伤害。
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var dmg_before := inv.damage_taken
	TextBoxBlank.set_blank_by_id(h.ctx, h.ctx.state.scenario_reference_card_id, true)
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 9)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	var tab := ChaosToken.symbol(AhcEnums.ChaosTokenKind.TABLET, 0, &"tab_blank")
	test.revealed_tokens.append(tab)
	test.reveal_batch_start = 0
	h.ctx.skill_tests.step_apply_symbol_effects(test)
	test.success = false
	test.fail_by = 5
	h.ctx.skill_tests.step_apply_results(test)
	var ok := (
		test.chaos_modifier == 0
		and not tab.reveal_another
		and inv.damage_taken == dmg_before
	)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return ok


func _es_bind_joe(h: RuleTestHarness) -> InvestigatorState:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.definition_id = &"12004"
	inv.display_name = "Joe Diamond"
	ElderSignBinder.bind_investigator(h.ctx, &"inv_1")
	return inv


func _test_es01_joe_elder_sign_spec() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var effect: Dictionary = CardRegistry.elder_sign_effect(&"12004")
	var on_ok: Dictionary = effect.get("on_success", {})
	var steps: Array = on_ok.get("steps", [])
	return (
		int(effect.get("modifier", -99)) == 1
		and str(on_ok.get("template", "")) == "seq"
		and steps.size() == 2
		and str((steps[0] as Dictionary).get("template", "")) == "draw"
		and str((steps[1] as Dictionary).get("template", "")) == "gain_resources"
	)


func _test_es02_modifier() -> bool:
	var h := RuleTestHarness.new(42)
	var inv := _es_bind_joe(h)
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 0)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	var es := ChaosToken.symbol(AhcEnums.ChaosTokenKind.ELDER_SIGN, 0, &"es_mod")
	test.revealed_tokens.append(es)
	test.reveal_batch_start = 0
	h.ctx.skill_tests.step_apply_symbol_effects(test)
	var ok := test.chaos_modifier == 1 and inv.active_symbol_ability(
		AhcEnums.ChaosTokenKind.ELDER_SIGN
	) != null
	h.ctx.skill_tests.step_end(test, h.ctx)
	return ok


func _test_es03_joe_succeed() -> bool:
	var h := RuleTestHarness.new(42)
	var inv := _es_bind_joe(h)
	## 抽牌需要牌库有牌。
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1", &"es_deck_card")
	var hand_before := inv.hand.size()
	var res_before := inv.resource_pool
	var st := SkillTestHelper.new(h.ctx)
	## 难度 0 + elder_sign +1 → 成功。
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 0)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	var es := ChaosToken.symbol(AhcEnums.ChaosTokenKind.ELDER_SIGN, 0, &"es_ok")
	test.revealed_tokens.append(es)
	test.reveal_batch_start = 0
	h.ctx.skill_tests.step_apply_symbol_effects(test)
	h.ctx.skill_tests.step_calculate_modified_value(test)
	h.ctx.skill_tests.step_determine_success(test)
	h.ctx.skill_tests.step_apply_results(test)
	var ok := (
		test.success
		and test.chaos_modifier == 1
		and inv.hand.size() == hand_before + 1
		and inv.resource_pool == res_before + 1
	)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return ok


func _test_es04_blank_skips() -> bool:
	var h := RuleTestHarness.new(42)
	var inv := _es_bind_joe(h)
	inv.text_box_blank = true
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 0)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	var es := ChaosToken.symbol(AhcEnums.ChaosTokenKind.ELDER_SIGN, 0, &"es_blank")
	test.revealed_tokens.append(es)
	test.reveal_batch_start = 0
	h.ctx.skill_tests.step_apply_symbol_effects(test)
	var ok := test.chaos_modifier == 0
	h.ctx.skill_tests.step_end(test, h.ctx)
	return ok


func _test_es05_joe_fail_no_success() -> bool:
	var h := RuleTestHarness.new(42)
	var inv := _es_bind_joe(h)
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1", &"es_deck_fail")
	var hand_before := inv.hand.size()
	var res_before := inv.resource_pool
	var st := SkillTestHelper.new(h.ctx)
	## 难度很高 → 失败；on_success 不应开火。
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 99)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	var es := ChaosToken.symbol(AhcEnums.ChaosTokenKind.ELDER_SIGN, 0, &"es_fail")
	test.revealed_tokens.append(es)
	test.reveal_batch_start = 0
	h.ctx.skill_tests.step_apply_symbol_effects(test)
	h.ctx.skill_tests.step_calculate_modified_value(test)
	h.ctx.skill_tests.step_determine_success(test)
	h.ctx.skill_tests.step_apply_results(test)
	var ok := (
		not test.success
		and test.chaos_modifier == 1
		and inv.hand.size() == hand_before
		and inv.resource_pool == res_before
	)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return ok


func _test_bc01_bless_st4() -> bool:
	var h := RuleTestHarness.new(42)
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 0)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	var bless := ChaosToken.symbol(AhcEnums.ChaosTokenKind.BLESS, 0, &"bc_bless")
	test.revealed_tokens.append(bless)
	test.reveal_batch_start = 0
	var again := h.ctx.skill_tests.step_apply_symbol_effects(test)
	var ok := (
		again
		and test.chaos_modifier == 2
		and bless.reveal_another
		and bless.return_to_pool
		and bless.modifier == 2
	)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return ok


func _test_bc02_curse_st4() -> bool:
	var h := RuleTestHarness.new(42)
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 0)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	var curse := ChaosToken.symbol(AhcEnums.ChaosTokenKind.CURSE, 0, &"bc_curse")
	test.revealed_tokens.append(curse)
	test.reveal_batch_start = 0
	var again := h.ctx.skill_tests.step_apply_symbol_effects(test)
	var ok := (
		again
		and test.chaos_modifier == -2
		and curse.reveal_another
		and curse.return_to_pool
		and curse.modifier == -2
	)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return ok


func _test_bc02b_chaos_mod_buff() -> bool:
	## ST.4 创建 THIS_SKILL_TEST MODIFIER；ST.5 经 ModifierEngine（负修正压低）；ST.8 tick 卸。
	var h := RuleTestHarness.new(42)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.skill_willpower = 4
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 0)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	var curse := ChaosToken.symbol(AhcEnums.ChaosTokenKind.CURSE, 0, &"bc_buff")
	test.revealed_tokens.append(curse)
	test.reveal_batch_start = 0
	h.ctx.skill_tests.step_apply_symbol_effects(test)
	var regs_after_st4 := 0
	for reg in h.ctx.registrations.all_registrations():
		if (
			reg.lifetime_kind == AhcEnums.LifetimeKind.DURATION
			and reg.duration == AhcEnums.DurationAnchorKind.THIS_SKILL_TEST
		):
			regs_after_st4 += 1
	var mv := h.ctx.skill_tests.step_calculate_modified_value(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	var regs_after_st8 := 0
	for reg2 in h.ctx.registrations.all_registrations():
		if (
			reg2.lifetime_kind == AhcEnums.LifetimeKind.DURATION
			and reg2.duration == AhcEnums.DurationAnchorKind.THIS_SKILL_TEST
		):
			regs_after_st8 += 1
	return (
		test.chaos_modifier == -2
		and not test.chaos_modifier_reg_ids.is_empty()
		and regs_after_st4 >= 1
		and mv == 2
		and regs_after_st8 == 0
	)


func _test_bc02c_symbol_nests_after_reveal() -> bool:
	## ST.3 = reveal；ST.4 = reveal After · Forced 上 nest seq.chaos.symbol。
	var h := RuleTestHarness.new(42)
	if not h.ctx.sequence_catalog.has_flow(&"seq.chaos.symbol"):
		return false
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.numeric(-1, &"nest_num"),
	])
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 0)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	var reveal_before := _sequence_kind_count(h, &"reveal_chaos_token")
	var symbol_before := _sequence_kind_count(h, &"chaos_symbol_ability")
	h.ctx.skill_tests.resolve_reveal_chain(test)
	var reveal_after := _sequence_kind_count(h, &"reveal_chaos_token")
	var symbol_after := _sequence_kind_count(h, &"chaos_symbol_ability")
	h.ctx.skill_tests.step_end(test, h.ctx)
	return (
		reveal_after > reveal_before
		and symbol_after > symbol_before
		and test.chaos_modifier == -1
		and not test.chaos_modifier_reg_ids.is_empty()
	)


func _test_bc03_bless_chain_pool() -> bool:
	## bless → ST.4 帧内 nest 再揭 numeric +1 → ST.8：bless 进 pool，numeric 回袋。
	var h := RuleTestHarness.new(42)
	var bless := ChaosToken.symbol(AhcEnums.ChaosTokenKind.BLESS, 0, &"bc_chain_b")
	var num := ChaosToken.numeric(1, &"bc_chain_n")
	GameBootstrap.setup_chaos_bag(h.ctx, [bless, num])
	var bag := h.ctx.state.chaos_bag
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 0)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	## 注入 bless；ST.4 nest 符号能力内自动再 nest ST.3→ST.4。
	bag.tokens.erase(bless)
	if not bag.revealed_this_test.has(bless):
		bag.revealed_this_test.append(bless)
	test.revealed_tokens.append(bless)
	test.reveal_batch_start = 0
	var again := h.ctx.skill_tests.step_apply_symbol_effects(test)
	if not again:
		h.ctx.skill_tests.step_end(test, h.ctx)
		return false
	h.ctx.skill_tests.step_calculate_modified_value(test)
	h.ctx.skill_tests.step_determine_success(test)
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	var pool_has_bless := false
	for t in bag.chaos_token_pool:
		var tok: ChaosToken = t as ChaosToken
		if tok != null and tok.kind == AhcEnums.ChaosTokenKind.BLESS:
			pool_has_bless = true
			break
	var bag_has_bless := false
	var bag_has_num := false
	for t2 in bag.tokens:
		var tok2: ChaosToken = t2 as ChaosToken
		if tok2 == null:
			continue
		if tok2.kind == AhcEnums.ChaosTokenKind.BLESS:
			bag_has_bless = true
		if tok2.kind == AhcEnums.ChaosTokenKind.NUMERIC and tok2.modifier == 1:
			bag_has_num = true
	return (
		test.chaos_modifier == 3
		and pool_has_bless
		and not bag_has_bless
		and bag_has_num
		and bag.revealed_this_test.is_empty()
	)


func _test_bc04_ability_curse_bag() -> bool:
	## 能力揭示 curse：finalize 回袋，不进 pool（无 ST.4 符号能力）。
	var h := RuleTestHarness.new(42)
	var curse := ChaosToken.symbol(AhcEnums.ChaosTokenKind.CURSE, -2, &"bc_abil_c")
	GameBootstrap.setup_chaos_bag(h.ctx, [curse])
	var bag := h.ctx.state.chaos_bag
	bag.begin_reveal_scope(&"bc_abil")
	var pulled := bag.reveal_for_ability(1)
	bag.finalize_ability_reveal(pulled)
	bag.end_reveal_scope()
	return (
		pulled.size() == 1
		and bag.tokens.has(curse)
		and bag.chaos_token_pool.is_empty()
		and not curse.return_to_pool
		and bag.revealed_this_test.is_empty()
	)


func _test_bc05_ignored_bless_bag() -> bool:
	## Ignore 后不发起 ST.4 → 无 return_to_pool → ST.8 回袋。
	var h := RuleTestHarness.new(42)
	var bless := ChaosToken.symbol(AhcEnums.ChaosTokenKind.BLESS, 0, &"bc_ign_b")
	GameBootstrap.setup_chaos_bag(h.ctx, [bless])
	var bag := h.ctx.state.chaos_bag
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 0)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	var drawn := bag.draw_random(&"skill_test")
	bag.ignore_reveal(drawn)
	## 被 Ignore：不入 resolved / 不跑 ST.4。
	h.ctx.skill_tests.step_calculate_modified_value(test)
	h.ctx.skill_tests.step_determine_success(test)
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return (
		drawn == bless
		and test.chaos_modifier == 0
		and not bless.return_to_pool
		and bag.tokens.has(bless)
		and bag.chaos_token_pool.is_empty()
	)


func _test_shriv01_compile_if_revealed() -> bool:
	## 皱缩术式：skill_test.if_revealed kinds + take_horror。
	var bind := AbilityBindContext.new()
	bind.controller_id = &"inv_1"
	bind.card_id = &"shriv_test"
	var node := ArkhamDbAbilityCompiler.build_composition(
		"skill_test",
		{
			"skill": "willpower",
			"difficulty": 0,
			"if_revealed": {
				"kinds": ["skull", "cultist", "tablet", "elder_thing", "auto_fail"],
				"mode": "any",
				"then": {"template": "take_horror", "amount": 2},
			},
		},
		bind
	)
	return (
		node != null
		and node.atom_name == &"nest_skill_test"
		and node.if_revealed_specs.size() == 1
		and (node.if_revealed_specs[0] as Dictionary).get("kinds", []).size() == 5
		and (node.if_revealed_specs[0] as Dictionary).get("mode", &"") == &"any"
		and (node.if_revealed_specs[0] as Dictionary).get("body") is CompositionNode
	)


func _test_shriv02_horror_before_symbol() -> bool:
	## FAQ：揭示 skull 当下 take horror（ST.3），早于参考卡符号能力（ST.4）。
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	h.ctx.state.current_act_number = 2
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.symbol(AhcEnums.ChaosTokenKind.SKULL, 0, &"sk_shriv"),
	])
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var horror_before := inv.horror_taken
	var body := CompositionNode.take_horror(&"inv_1", 2)
	var specs: Array = [{
		"kinds": SkillTestIfRevealed.shrivelling_kinds(),
		"mode": &"any",
		"body": body,
	}]
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 0)
	SkillTestIfRevealed.register_specs(test, h.ctx, specs)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.step_reveal_token(test)
	var horror_after_reveal := inv.horror_taken
	var mod_before_symbol := test.chaos_modifier
	h.ctx.skill_tests.step_apply_symbol_effects(test)
	var mod_after_symbol := test.chaos_modifier
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.continue_after_reveal_window(test)
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return (
		horror_after_reveal == horror_before + 2
		and mod_before_symbol == 0
		and mod_after_symbol == -2
		and inv.horror_taken == horror_before + 2
	)


func _test_shriv03_self_limit() -> bool:
	## 自肃：同检定两枚 skull resolved → take horror 仍只一次。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.symbol(AhcEnums.ChaosTokenKind.SKULL, 0, &"sk_a"),
		ChaosToken.symbol(AhcEnums.ChaosTokenKind.SKULL, 0, &"sk_b"),
	])
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var horror_before := inv.horror_taken
	var body := CompositionNode.take_horror(&"inv_1", 2)
	var specs: Array = [{
		"kinds": SkillTestIfRevealed.shrivelling_kinds(),
		"mode": &"any",
		"body": body,
	}]
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 9)
	SkillTestIfRevealed.register_specs(test, h.ctx, specs)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	## 能力揭示两枚 skull（均 resolved）→ 自肃只伤一次。
	var pulled: Array[ChaosToken] = h.ctx.state.chaos_bag.reveal_for_ability(2)
	h.ctx.state.chaos_bag.finalize_ability_reveal(pulled)
	h.ctx.state.chaos_bag.add_token(ChaosToken.numeric(0, &"n_shriv"))
	h.ctx.skill_tests.resolve_reveal_chain(test)
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.continue_after_reveal_window(test)
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return (
		pulled.size() == 2
		and inv.horror_taken == horror_before + 2
	)


func _test_cf01_compile_12059() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var compiled := CardRegistry.compiled_abilities(&"12059")
	if compiled.is_empty():
		return false
	var entry: Dictionary = compiled[0]
	var if_rev: Variant = entry.get("if_revealed", {})
	if not if_rev is Dictionary:
		return false
	var types: Variant = entry.get("action_types", [])
	var then_body: Dictionary = (if_rev as Dictionary).get("then", {})
	return (
		CardRegistry.has_triggered(&"12059")
		and str(entry.get("register_as", "")) == "action"
		and str(entry.get("template", "")) == "skill_test"
		and str(entry.get("skill", "")) == "willpower"
		and str((if_rev as Dictionary).get("kind", "")) == "skull"
		and str(then_body.get("template", "")) == "if_else"
		and str(then_body.get("condition", "")) == "source_has_use"
		and types is Array
		and (types as Array).has("activate")
		and (types as Array).has("fight")
		and CardRegistry.compiled_abilities(&"12071").size() == 1
	)


func _test_cf02_skull_removes_charge() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.symbol(AhcEnums.ChaosTokenKind.SKULL, 0, &"cf_sk"),
	])
	var card_id := GameBootstrap.add_asset_to_play(h.ctx, &"inv_1", &"12059")
	ScenarioDeckSetup.install_triggered_abilities(h.ctx, card_id)
	var card := h.ctx.state.registry.get_card(card_id)
	var charges_enter := int(card.tokens.uses.get(&"charges", -1))
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.actions_remaining = 1
	if not h.ctx.framework.waiting_player_window:
		h.ctx.framework.open_player_window(AhcEnums.PlayerWindow.PW_INV_BEFORE_ACTION)
	var listed := h.ctx.triggered_abilities.list_action_abilities(&"inv_1")
	if listed.is_empty():
		return false
	var result := h.ctx.triggered_abilities.activate_action(listed[0].id)
	var charges_left := int(card.tokens.uses.get(&"charges", -1))
	return (
		charges_enter == 3
		and bool(result.get("ok", false))
		and charges_left == 2
		and card.zone == AhcEnums.Zone.PLAY_AREA
		and inv.damage_taken == 0
	)


func _test_cf03_skull_no_charge_discard() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.symbol(AhcEnums.ChaosTokenKind.SKULL, 0, &"cf_sk0"),
	])
	var card_id := GameBootstrap.add_asset_to_play(h.ctx, &"inv_1", &"12059")
	ScenarioDeckSetup.install_triggered_abilities(h.ctx, card_id)
	var card := h.ctx.state.registry.get_card(card_id)
	card.tokens.uses[&"charges"] = 0
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var dmg_before := inv.damage_taken
	inv.actions_remaining = 1
	if not h.ctx.framework.waiting_player_window:
		h.ctx.framework.open_player_window(AhcEnums.PlayerWindow.PW_INV_BEFORE_ACTION)
	var listed := h.ctx.triggered_abilities.list_action_abilities(&"inv_1")
	if listed.is_empty():
		return false
	var result := h.ctx.triggered_abilities.activate_action(listed[0].id)
	return (
		bool(result.get("ok", false))
		and inv.damage_taken == dmg_before + 1
		and card.zone == AhcEnums.Zone.DISCARD
		and inv.discard.has(card_id)
	)


func _test_sc11_investigate_after_sf_setup() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	if not h.advance_to_action_phase():
		return false
	h.ctx.state.registry.get_investigator(&"inv_1").actions_remaining = 1
	var loc := h.ctx.state.registry.get_location(&"12113")
	var before_clues := loc.clues
	var res := h.investigate_action()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		res.ok
		and res.success
		and loc.clues == before_clues - 1
		and inv.clues_on_card == 1
	)


func _log_has_message(h: RuleTestHarness, message: String) -> bool:
	for entry in h.ctx.log.get_entries():
		if str(entry.get("message", "")) == message:
			return true
	return false


func _encounter_discard_count(h: RuleTestHarness, definition_id: StringName) -> int:
	var count := 0
	for card_id in h.ctx.state.encounter_discard:
		var card := h.ctx.state.registry.get_card(card_id)
		if card != null and card.id.definition_id == definition_id:
			count += 1
	return count


func _enemy_at_location(
	h: RuleTestHarness,
	definition_id: StringName,
	location_id: StringName
) -> EnemyState:
	for enemy_id in h.ctx.state.registry.all_enemy_ids():
		var enemy := h.ctx.state.registry.get_enemy(enemy_id)
		if enemy == null or enemy.location_tag != location_id:
			continue
		var card := h.ctx.state.registry.get_card(enemy_id)
		if card != null and card.id.definition_id == definition_id:
			return enemy
	return null


func _test_sc12_setup_game_begins_timing() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	return (
		h.ctx.state.setup_game_begins_resolved
		and _log_has_message(h, "setup:game_begins")
		and _log_has_message(h, "timing:when_the_game_begins")
	)


func _test_sc13_act1_flip_spawns_layout() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.clues_on_card = 2
	var advance := h.ctx.sequence_catalog.run(h.ctx, &"seq.act.advance", {})
	var dorm := h.ctx.state.registry.get_location(&"12117")
	var quad := h.ctx.state.registry.get_location(&"12116")
	var room_card := h.ctx.state.registry.get_card(&"12113")
	var servant := _enemy_at_location(h, &"12114", &"12117")
	var current := h.ctx.state.registry.get_card(h.ctx.state.current_act_card_id)
	return (
		advance.get("advanced", false)
		and h.ctx.state.current_act_number == 2
		and current != null
		and current.id.definition_id == &"12110"
		and dorm != null
		and dorm.revealed
		and quad != null
		and quad.revealed
		and servant != null
		and room_card != null
		and room_card.attachments.size() == 1
		and _encounter_discard_count(h, &"12129") == 4
		and _sf_set_aside_count(h, &"12129") == 0
		and _sf_set_aside_count(h, &"12114") == 0
		and _sf_set_aside_count(h, &"12115") == 1
		and inv.clues_on_card == 0
	)


func _test_sc14_agenda2_flip_discards_fire() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	h.ctx.state.doom_on_agenda = 3
	var adv1 := h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	if not adv1.get("advanced", false):
		return false
	h.ctx.state.doom_on_agenda = 5
	var adv2 := h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	return (
		adv2.get("advanced", false)
		and h.ctx.state.current_agenda_number == 3
		and _encounter_discard_count(h, &"12129") == 4
		and _sf_set_aside_count(h, &"12129") == 1
	)


func _test_sc15_act_agenda_back_composition_atoms() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.ctx.sequence_catalog.has_flow(&"seq.act_agenda.resolve_back"):
		return false
	_prepare_sf_act_agenda_defs()
	var tree12107 := ActAgendaBackCompiler.compile(&"12107", CardRegistry.back_text(&"12107"))
	if tree12107.kind != AhcEnums.CompositionNodeKind.SEQ or tree12107.children.size() != 2:
		return false
	var discard_atom: CompositionNode = tree12107.children[0]
	var tree12109 := ActAgendaBackCompiler.compile(&"12109", CardRegistry.back_text(&"12109"))
	return (
		discard_atom.atom_name == &"discard_set_aside_to_encounter_discard"
		and discard_atom.definition_id == &"12129"
		and discard_atom.atom_count == 4
		and tree12107.children[1].kind == AhcEnums.CompositionNodeKind.FOR_EACH
		and tree12109.kind == AhcEnums.CompositionNodeKind.SEQ
		and tree12109.children.size() == 5
		and tree12109.children[0].atom_name == &"discard_all_enemies_in_play"
		and tree12109.children[1].atom_name == &"put_locations_into_play"
		and tree12109.children[2].atom_name == &"spawn_set_aside_enemy_at"
		and tree12109.children[3].atom_name == &"attach_set_aside_to_host"
		and tree12109.children[4].atom_name == &"discard_set_aside_to_encounter_discard"
	)


func _test_sc16_agenda1_flip_skill_horror() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.skill_willpower = 0
	h.ctx.state.doom_on_agenda = 3
	var before_resolve := _sequence_kind_count(h, &"ability_resolve")
	var adv := h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	return (
		adv.get("advanced", false)
		and inv.horror_taken == 1
		and _sequence_kind_count(h, &"ability_resolve") > before_resolve
	)


func _test_sc17_agenda2_flip_skill_damage() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.skill_agility = 0
	inv.skill_willpower = 9
	h.ctx.state.doom_on_agenda = 3
	h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	h.ctx.state.doom_on_agenda = 5
	var adv2 := h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	return adv2.get("advanced", false) and inv.damage_taken == 1


func _test_sc18_agenda3_flip_defeat_trauma() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.skill_willpower = 9
	inv.skill_agility = 9
	h.ctx.state.doom_on_agenda = 3
	h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	h.ctx.state.doom_on_agenda = 5
	h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	h.ctx.state.doom_on_agenda = 10
	var adv3 := h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	return (
		adv3.get("advanced", false)
		and inv.eliminated
		and inv.physical_trauma == 1
		and h.ctx.state.current_agenda_number == 4
	)


func _test_sc19_objective_all_at_quad_advance() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.clues_on_card = 2
	h.ctx.sequence_catalog.run(h.ctx, &"seq.act.advance", {})
	if h.ctx.state.current_act_number != 2:
		return false
	inv.location_tag = &"12116"
	var result := ScenarioObjectiveFlow.check_end_of_round(h.ctx)
	return result.get("advanced", false) and h.ctx.state.current_act_number == 3


func _test_sc20_objective_servant_defeated_advance() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.clues_on_card = 2
	h.ctx.sequence_catalog.run(h.ctx, &"seq.act.advance", {})
	inv.location_tag = &"12116"
	ScenarioObjectiveFlow.check_end_of_round(h.ctx)
	inv.clues_on_card = 3
	inv.location_tag = &"12120"
	ScenarioObjectiveFlow.check_end_of_round(h.ctx)
	if h.ctx.state.current_act_number != 4:
		return false
	var servant_id := &""
	for enemy_id in h.ctx.state.registry.all_enemy_ids():
		var card := h.ctx.state.registry.get_card(enemy_id)
		if card != null and card.id.definition_id == &"12114":
			servant_id = enemy_id
			break
	if servant_id == &"":
		return false
	var enemy := h.ctx.state.registry.get_enemy(servant_id)
	if enemy == null:
		return false
	enemy.damage = enemy.health
	var defeat := EnemyDefeatResolver.defeat(h.ctx, servant_id)
	return (
		defeat.get("defeated", false)
		and h.ctx.state.current_act_number == 5
		and h.ctx.state.scenario_resolution == 1
	)


func _test_sc21_act2_flip_layout() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.clues_on_card = 2
	h.ctx.sequence_catalog.run(h.ctx, &"seq.act.advance", {})
	inv.location_tag = &"12116"
	ScenarioObjectiveFlow.check_end_of_round(h.ctx)
	var orne := h.ctx.state.registry.get_location(&"12120")
	var room_removed := h.ctx.state.removed_from_game.has(&"12113")
	return (
		h.ctx.state.current_act_number == 3
		and orne != null
		and orne.revealed
		and room_removed
		and _sf_set_aside_count(h, &"12114") >= 1
	)


func _test_sc22_act3_flip_armitage() -> bool:
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.clues_on_card = 2
	h.ctx.sequence_catalog.run(h.ctx, &"seq.act.advance", {})
	inv.location_tag = &"12116"
	ScenarioObjectiveFlow.check_end_of_round(h.ctx)
	inv.clues_on_card = 3
	inv.location_tag = &"12120"
	ScenarioObjectiveFlow.check_end_of_round(h.ctx)
	var armitage_in_play := false
	for card_id in inv.play_area:
		var card := h.ctx.state.registry.get_card(card_id)
		if card != null and card.id.definition_id == &"12115":
			armitage_in_play = true
			break
	var quad := h.ctx.state.registry.get_location(&"12116")
	var servant := _enemy_at_location(h, &"12114", &"12116")
	return (
		h.ctx.state.current_act_number == 4
		and armitage_in_play
		and quad != null
		and quad.clues == 3
		and servant != null
	)


func _test_sc23_agenda3_forced_draws_fire() -> bool:
	## 12108 a 面 Forced：放置 doom 后 lead 抽遭遇弃牌堆顶 Fire!；翻面后不再触发。
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.skill_willpower = 9
	inv.skill_agility = 9
	h.ctx.state.doom_on_agenda = 3
	h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	h.ctx.state.doom_on_agenda = 5
	h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	if h.ctx.state.current_agenda_number != 3:
		return false
	if not CardRegistry.has_triggered(&"12108"):
		return false
	if _encounter_discard_count(h, &"12129") < 1:
		return false
	var settle_before := _sequence_kind_count(h, &"encounter_resolve_card")
	h.ctx.sequence_catalog.run(h.ctx, &"seq.mythos.place_doom", {})
	var settle_after := _sequence_kind_count(h, &"encounter_resolve_card")
	if settle_after <= settle_before:
		return false
	## 翻面卸下 Forced 后，再放置 doom 不应再 nest resolve_card
	h.ctx.state.doom_on_agenda = 10
	var settle_mid := _sequence_kind_count(h, &"encounter_resolve_card")
	h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	h.ctx.sequence_catalog.run(h.ctx, &"seq.mythos.place_doom", {})
	return _sequence_kind_count(h, &"encounter_resolve_card") == settle_mid


func _sequence_kind_count(h: RuleTestHarness, kind: StringName) -> int:
	var n := 0
	for rec in h.ctx.events.get_records():
		if rec.kind != AhcEnums.EventRecordKind.SEQUENCE_STEP:
			continue
		if rec.payload.get("kind", &"") == kind:
			n += 1
	return n


func _test_sc24_fire_revelation_attaches() -> bool:
	## 12129 显现：抽 Fire! 后附着到最近无 Fire! 的地点（setup 仅 12113）。
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	if not CardRegistry.has_revelation(&"12129"):
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.skill_willpower = 9
	inv.skill_agility = 9
	h.ctx.state.doom_on_agenda = 3
	h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	h.ctx.state.doom_on_agenda = 5
	h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	if _encounter_discard_count(h, &"12129") < 1:
		return false
	h.ctx.sequence_catalog.run(h.ctx, &"seq.mythos.place_doom", {})
	var room := h.ctx.state.registry.get_card(&"12113")
	if room == null or room.attachments.is_empty():
		return false
	var attached_id: StringName = room.attachments[0].instance_id
	var fire := h.ctx.state.registry.get_card(attached_id)
	return (
		fire != null
		and fire.id.definition_id == &"12129"
		and fire.zone == AhcEnums.Zone.ATTACHED
		and not h.ctx.state.encounter_discard.has(attached_id)
	)


func _test_sc25_fire_revelation_no_target_discards() -> bool:
	## 全部在场地点已有 Fire! → 显现失败 → G4 弃入遭遇弃牌堆。
	var h := RuleTestHarness.new(42, GameBootstrap.config_spreading_flames())
	h.run_setup()
	if not CardRegistry.has_revelation(&"12129"):
		return false
	var aside := ScenarioSetAsideService.find_cards(h.ctx, &"12129")
	if aside.is_empty():
		return false
	var first: StringName = aside[0]
	ScenarioSetAsideService.remove_from_set_aside(h.ctx, first)
	if not EncounterAttachment.attach_limbo_to_location(h.ctx, first, &"12113"):
		return false
	var second: StringName = aside[1] if aside.size() > 1 else &""
	if second == &"":
		return false
	ScenarioSetAsideService.remove_from_set_aside(h.ctx, second)
	h.ctx.state.encounter_discard.append(second)
	var card := h.ctx.state.registry.get_card(second)
	if card != null:
		card.zone = AhcEnums.Zone.DISCARD
	var lead := h.ctx.state.lead_investigator_id
	if lead == &"":
		lead = &"inv_1"
	var result := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.encounter.resolve_card",
		{"drawer_id": lead, "card_id": second}
	)
	return (
		result.get("ok", false)
		and h.ctx.state.encounter_discard.has(second)
		and card != null
		and card.zone == AhcEnums.Zone.DISCARD
	)


func _test_sc26_agenda_enemy_back_not_drawn() -> bool:
	## FAQ：密谋 b 面为 enemy → 按抽取规则 spawn；不 RFG；不触发 when-drawn。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"test_loc")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	CardRegistry.register_definition(
		&"agenda_enemy_back",
		{
			"card_type": &"agenda",
			"doom": 1,
			"back_card_type": &"enemy",
			"enemy": {"fight": 2, "evade": 2, "health": 3, "damage": 1, "horror": 0},
		}
	)
	CardRegistry.register_definition(
		&"agenda_next_plain",
		{"card_type": &"agenda", "doom": 7, "back_text": "Nothing happens."}
	)
	var setup := h.ctx.scenario.setup_act_agenda_decks(
		[], [&"agenda_enemy_back", &"agenda_next_plain"]
	)
	if not setup.get("ok", false):
		return false
	var first_id := h.ctx.state.current_agenda_card_id
	var drawn_when := {"n": 0}
	var when_draw := SequenceHandler.new()
	when_draw.match_kind = &"encounter_card_drawn"
	when_draw.phase = AhcEnums.SequencePhase.WHEN
	when_draw.tier = SequenceHandler.Tier.TRIGGERED
	when_draw.callback = func() -> void: drawn_when["n"] = int(drawn_when["n"]) + 1
	h.ctx.sequences.register_handler(when_draw)
	h.ctx.state.doom_on_agenda = 1
	var advance := h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	var flipped := h.ctx.state.registry.get_card(first_id)
	var enemy := h.ctx.state.registry.get_enemy(first_id)
	var settle_n := _sequence_kind_count(h, &"encounter_resolve_card")
	return (
		advance.get("advanced", false)
		and bool(advance.get("flip", {}).get("encounter_back", false))
		and settle_n >= 1
		and int(drawn_when["n"]) == 0
		and not h.ctx.state.removed_from_game.has(first_id)
		and flipped != null
		and flipped.face == AhcEnums.CardFace.B
		and CardRegistry.card_type_of(flipped) == &"enemy"
		and flipped.zone == AhcEnums.Zone.PLAY_AREA
		and enemy != null
		and inv.threat_area.has(first_id)
		and h.ctx.state.current_agenda_card_id != first_id
		and h.ctx.state.current_agenda_number == 2
	)


func _test_sc27_agenda_treachery_back_not_drawn() -> bool:
	## FAQ：密谋 b 面为 treachery → 显现 + G4 弃置；不触发 when-drawn。
	var h := RuleTestHarness.new(42)
	CardRegistry.register_definition(
		&"agenda_treach_back",
		{
			"card_type": &"agenda",
			"doom": 1,
			"back_card_type": &"treachery",
			"limbo_discard_pile": &"encounter_discard",
		}
	)
	CardRegistry.register_revelation(
		&"agenda_treach_back",
		&"rev",
		func(bind: AbilityBindContext) -> CompositionNode:
			return CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.HORROR_TAKEN,
				2,
				MarkerSlot.supply(AhcEnums.MarkerKind.HORROR_TAKEN),
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.HORROR_TAKEN)
			)
	)
	CardRegistry.register_definition(
		&"agenda_after_treach",
		{"card_type": &"agenda", "doom": 7, "back_text": "Nothing happens."}
	)
	var setup := h.ctx.scenario.setup_act_agenda_decks(
		[], [&"agenda_treach_back", &"agenda_after_treach"]
	)
	if not setup.get("ok", false):
		return false
	var first_id := h.ctx.state.current_agenda_card_id
	var drawn_when := {"n": 0}
	var when_draw := SequenceHandler.new()
	when_draw.match_kind = &"encounter_card_drawn"
	when_draw.phase = AhcEnums.SequencePhase.WHEN
	when_draw.tier = SequenceHandler.Tier.TRIGGERED
	when_draw.callback = func() -> void: drawn_when["n"] = int(drawn_when["n"]) + 1
	h.ctx.sequences.register_handler(when_draw)
	h.ctx.state.doom_on_agenda = 1
	var advance := h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	var flipped := h.ctx.state.registry.get_card(first_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		advance.get("advanced", false)
		and bool(advance.get("flip", {}).get("encounter_back", false))
		and int(drawn_when["n"]) == 0
		and not h.ctx.state.removed_from_game.has(first_id)
		and flipped != null
		and flipped.face == AhcEnums.CardFace.B
		and flipped.zone == AhcEnums.Zone.DISCARD
		and h.ctx.state.encounter_discard.has(first_id)
		and inv.horror_taken == 2
		and h.ctx.state.current_agenda_number == 2
	)


func _test_sc28_01121_masked_hunter_flip() -> bool:
	## 01121a Predator or Prey? → 01121b The Masked Hunter（遭遇类型背面）。
	## Spawn Engaged with Prey · Prey Most clues · +2 health/investigator · 非 when-drawn。
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file(
		"res://data/arkhamdb/imported/core_classic_slice.json"
	)
	if not CardRegistry.has_encounter_cardtype_back(&"01121a"):
		return false
	if CardRegistry.is_hidden(&"01121b"):
		return false  ## ArkhamDB JSON hidden ≠ 隐私
	GameBootstrap.setup_test_location(h.ctx, &"test_loc")
	GameBootstrap.setup_minimal_investigator(h.ctx, &"inv_2")
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	inv1.location_tag = &"test_loc"
	inv2.location_tag = &"test_loc"
	inv1.clues_on_card = 0
	inv2.clues_on_card = 3
	h.ctx.state.per_investigator_count = 2
	h.ctx.state.lead_investigator_id = &"inv_1"
	h.ctx.lead_investigator_id = &"inv_1"
	CardRegistry.register_definition(
		&"agenda_after_01121",
		{"card_type": &"agenda", "doom": 7, "back_text": "Nothing happens."}
	)
	var setup := h.ctx.scenario.setup_act_agenda_decks(
		[], [&"01121a", &"agenda_after_01121"]
	)
	if not setup.get("ok", false):
		return false
	var first_id := h.ctx.state.current_agenda_card_id
	var drawn_when := {"n": 0}
	var when_draw := SequenceHandler.new()
	when_draw.match_kind = &"encounter_card_drawn"
	when_draw.phase = AhcEnums.SequencePhase.WHEN
	when_draw.tier = SequenceHandler.Tier.TRIGGERED
	when_draw.callback = func() -> void: drawn_when["n"] = int(drawn_when["n"]) + 1
	h.ctx.sequences.register_handler(when_draw)
	h.ctx.state.doom_on_agenda = 6
	var advance := h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	var flipped := h.ctx.state.registry.get_card(first_id)
	var enemy := h.ctx.state.registry.get_enemy(first_id)
	var spawn := CardRegistry.spawn_spec(&"01121a")
	var prey := CardRegistry.prey_spec(&"01121a")
	return (
		advance.get("advanced", false)
		and bool(advance.get("flip", {}).get("encounter_back", false))
		and int(drawn_when["n"]) == 0
		and not h.ctx.state.removed_from_game.has(first_id)
		and flipped != null
		and flipped.face == AhcEnums.CardFace.B
		and CardRegistry.card_type_of(flipped) == &"enemy"
		and CardRegistry.is_hunter(&"01121a")
		and spawn.selector_kind == SpawnInstructionSpec.SelectorKind.ENGAGED_WITH_PREY
		and prey != null
		and prey.value_kind == PreyInstructionSpec.ValueKind.CLUES
		and enemy != null
		and enemy.health == 8
		and enemy.fight == 4
		and inv2.threat_area.has(first_id)
		and not inv1.threat_area.has(first_id)
		and EngagementStatus.is_engaged_with(h.ctx, first_id, &"inv_2")
		and CardRegistry.forbids_clues_while_engaged(&"01121a")
		and RestrictionEvaluator.blocks_discover_clue(&"inv_2", h.ctx.registrations)
		and RestrictionEvaluator.blocks_spend_clue(&"inv_2", h.ctx.registrations)
		and not RestrictionEvaluator.blocks_discover_clue(&"inv_1", h.ctx.registrations)
		and h.ctx.state.current_agenda_number == 2
	)


func _test_sc29_masked_hunter_forbid_discover() -> bool:
	## 与 Masked Hunter 交战的调查员不能发现线索；非交战者可以。
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file(
		"res://data/arkhamdb/imported/core_classic_slice.json"
	)
	GameBootstrap.setup_test_location(h.ctx, &"test_loc", 2, 3)
	GameBootstrap.setup_minimal_investigator(h.ctx, &"inv_2")
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	inv1.location_tag = &"test_loc"
	inv2.location_tag = &"test_loc"
	inv1.clues_on_card = 0
	inv2.clues_on_card = 5
	h.ctx.state.per_investigator_count = 2
	h.ctx.state.lead_investigator_id = &"inv_1"
	CardRegistry.register_definition(
		&"agenda_after_01121b",
		{"card_type": &"agenda", "doom": 7, "back_text": "Nothing happens."}
	)
	h.ctx.scenario.setup_act_agenda_decks([], [&"01121a", &"agenda_after_01121b"])
	h.ctx.state.doom_on_agenda = 6
	h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	var hunter_id := &""
	for eid in h.ctx.state.registry.all_card_ids():
		var c := h.ctx.state.registry.get_card(eid)
		if c != null and c.id.definition_id == &"01121a" and c.face == AhcEnums.CardFace.B:
			hunter_id = eid
			break
	if hunter_id == &"" or not EngagementStatus.is_engaged_with(h.ctx, hunter_id, &"inv_2"):
		return false
	var loc := h.ctx.state.registry.get_location(&"test_loc")
	var clues_before := loc.clues
	var blocked := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.discover_clue",
		{"inv_id": &"inv_2", "location_id": &"test_loc", "amount": 1}
	)
	var ok_other := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.discover_clue",
		{"inv_id": &"inv_1", "location_id": &"test_loc", "amount": 1}
	)
	return (
		not blocked.get("ok", false)
		and str(blocked.get("error", "")) == "restriction_forbid_discover_clue"
		and inv2.clues_on_card == 5
		and ok_other.get("ok", false)
		and inv1.clues_on_card == 1
		and loc.clues == clues_before - 1
	)


func _test_sc30_masked_hunter_forbid_spend() -> bool:
	## 交战者线索不能用于推进场景；只靠非交战者的线索仍可凑够。
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file(
		"res://data/arkhamdb/imported/core_classic_slice.json"
	)
	GameBootstrap.setup_test_location(h.ctx, &"test_loc")
	GameBootstrap.setup_minimal_investigator(h.ctx, &"inv_2")
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	inv1.location_tag = &"test_loc"
	inv2.location_tag = &"test_loc"
	## Prey most clues → inv_2；仅 inv_2 有线索时推进应失败。
	inv1.clues_on_card = 0
	inv2.clues_on_card = 4
	h.ctx.state.per_investigator_count = 2
	h.ctx.state.lead_investigator_id = &"inv_1"
	CardRegistry.register_definition(
		&"agenda_pad_01121",
		{"card_type": &"agenda", "doom": 7, "back_text": "Nothing happens."}
	)
	CardRegistry.register_definition(
		&"act_need_2",
		{"card_type": &"act", "location": {"clues": 2}, "back_text": "(→R1)"}
	)
	CardRegistry.register_definition(
		&"act_need_2b",
		{"card_type": &"act", "location": {"clues": 99}, "back_text": "Nothing happens."}
	)
	h.ctx.scenario.setup_act_agenda_decks(
		[&"act_need_2", &"act_need_2b"], [&"01121a", &"agenda_pad_01121"]
	)
	h.ctx.state.doom_on_agenda = 6
	h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	if not RestrictionEvaluator.blocks_spend_clue(&"inv_2", h.ctx.registrations):
		return false
	var fail := h.ctx.sequence_catalog.run(h.ctx, &"seq.act.advance", {})
	## 再给 inv_1 线索 → 可推进；inv_2 线索不动。
	inv1.clues_on_card = 2
	var inv2_before := inv2.clues_on_card
	var ok := h.ctx.sequence_catalog.run(h.ctx, &"seq.act.advance", {})
	return (
		not fail.get("advanced", false)
		and str(fail.get("reason", "")) == "insufficient_clues"
		and ok.get("advanced", false)
		and inv1.clues_on_card == 0
		and inv2.clues_on_card == inv2_before
	)


func _test_sc32_50026_narogath_flip() -> bool:
	## 50026a Predator or Prey? → 50026b Narôgath（Return to Midnight Masks）。
	## Spawn Engaged with Prey · Hunter · +3 health/investigator · 非 when-drawn。
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file(
		"res://data/arkhamdb/imported/core_classic_slice.json"
	)
	if not CardRegistry.has_encounter_cardtype_back(&"50026a"):
		return false
	GameBootstrap.setup_test_location(h.ctx, &"test_loc")
	GameBootstrap.setup_minimal_investigator(h.ctx, &"inv_2")
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	inv1.location_tag = &"test_loc"
	inv2.location_tag = &"test_loc"
	h.ctx.state.per_investigator_count = 2
	h.ctx.state.lead_investigator_id = &"inv_1"
	h.ctx.lead_investigator_id = &"inv_1"
	CardRegistry.register_definition(
		&"agenda_after_50026",
		{"card_type": &"agenda", "doom": 7, "back_text": "Nothing happens."}
	)
	var setup := h.ctx.scenario.setup_act_agenda_decks(
		[], [&"50026a", &"agenda_after_50026"]
	)
	if not setup.get("ok", false):
		return false
	var first_id := h.ctx.state.current_agenda_card_id
	var drawn_when := {"n": 0}
	var when_draw := SequenceHandler.new()
	when_draw.match_kind = &"encounter_card_drawn"
	when_draw.phase = AhcEnums.SequencePhase.WHEN
	when_draw.tier = SequenceHandler.Tier.TRIGGERED
	when_draw.callback = func() -> void: drawn_when["n"] = int(drawn_when["n"]) + 1
	h.ctx.sequences.register_handler(when_draw)
	h.ctx.state.doom_on_agenda = 6
	var advance := h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	var flipped := h.ctx.state.registry.get_card(first_id)
	var enemy := h.ctx.state.registry.get_enemy(first_id)
	var spawn := CardRegistry.spawn_spec(&"50026a")
	var prey := CardRegistry.prey_spec(&"50026a")
	return (
		advance.get("advanced", false)
		and bool(advance.get("flip", {}).get("encounter_back", false))
		and int(drawn_when["n"]) == 0
		and not h.ctx.state.removed_from_game.has(first_id)
		and flipped != null
		and flipped.face == AhcEnums.CardFace.B
		and CardRegistry.card_type_of(flipped) == &"enemy"
		and CardRegistry.is_hunter(&"50026a")
		and spawn.selector_kind == SpawnInstructionSpec.SelectorKind.ENGAGED_WITH_PREY
		and prey != null
		and prey.is_nearest_to_enemy_trait()
		and prey.nearest_enemy_trait == &"Cultist"
		and enemy != null
		and enemy.health == 10
		and enemy.fight == 3
		and EngagementStatus.is_engaged(h.ctx, first_id)
		and h.ctx.state.current_agenda_number == 2
	)


func _test_sc33_aloof_forbid_attack() -> bool:
	## 冷漠：进场挂 FORBID_ATTACK；未交战 Fight 被拦；交战后可 Fight。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2, &"", true)
	if not h.ctx.registrations.has_forbid_attack(&"enemy_1"):
		return false
	if not RestrictionEvaluator.blocks_fight(&"inv_1", &"enemy_1", h.ctx.registrations):
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var before := inv.actions_remaining
	var blocked := h.fight_action({"enemy_id": &"enemy_1"})
	if blocked.ok or blocked.error != "aloof" or inv.actions_remaining != before:
		return false
	if not h.engage_action({"enemy_id": &"enemy_1"}).ok:
		return false
	if RestrictionEvaluator.blocks_fight(&"inv_1", &"enemy_1", h.ctx.registrations):
		return false
	inv.actions_remaining = 1
	var ok := h.fight_action({"enemy_id": &"enemy_1"})
	return ok.ok and ok.success


func _test_prey_nearest_to_enemy_trait() -> bool:
	## loc_a—loc_b：Cultist @ a；inv1@a 距 0，inv2@b 距 1 → 选 inv1。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"loc_a")
	GameBootstrap.setup_test_location(h.ctx, &"loc_b")
	GameBootstrap.connect_locations(h.ctx, &"loc_a", &"loc_b")
	GameBootstrap.setup_minimal_investigator(h.ctx, &"inv_2")
	h.ctx.state.registry.get_investigator(&"inv_1").location_tag = &"loc_a"
	h.ctx.state.registry.get_investigator(&"inv_2").location_tag = &"loc_b"
	h.ctx.state.lead_investigator_id = &"inv_2"
	h.ctx.lead_investigator_id = &"inv_2"
	var cult_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"cult_anchor",
		{"traits": [&"Humanoid", &"Cultist"]}
	)
	var spawned := h.ctx.enemy.spawn_at_location(h.ctx, cult_id, &"loc_a", &"cult_anchor")
	if not spawned.get("ok", false):
		return false
	if not CardRegistry.card_has_trait(h.ctx.state.registry.get_card(cult_id), &"Cultist"):
		return false
	var spec := PreyInstructionSpec.nearest_to_enemy_trait(&"Cultist")
	var pick := PreyResolver.best_match(
		spec, h.ctx, [&"inv_1", &"inv_2"], &"hunter_self"
	)
	return pick == &"inv_1"


func _test_prey_tie_opens_lead_pick() -> bool:
	## 两调查员同地、同距 Cultist → 过滤并列；Lead 开窗显式选 inv_2（非静默 Lead=inv_1）。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"loc_a")
	GameBootstrap.setup_minimal_investigator(h.ctx, &"inv_2")
	h.ctx.state.registry.get_investigator(&"inv_1").location_tag = &"loc_a"
	h.ctx.state.registry.get_investigator(&"inv_2").location_tag = &"loc_a"
	h.ctx.state.lead_investigator_id = &"inv_1"
	h.ctx.lead_investigator_id = &"inv_1"
	var cult_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"cult_tie",
		{"traits": [&"Cultist"]}
	)
	if not h.ctx.enemy.spawn_at_location(h.ctx, cult_id, &"loc_a", &"cult_tie").get("ok", false):
		return false
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"pick:prey_tie", "pick": &"inv_2"},
	])
	var before_events := h.ctx.events.get_records().size() if h.ctx.events != null else 0
	var spec := PreyInstructionSpec.nearest_to_enemy_trait(&"Cultist")
	var pick := PreyResolver.best_match(spec, h.ctx, [&"inv_1", &"inv_2"], &"src")
	var saw_pi := false
	if h.ctx.events != null:
		var records := h.ctx.events.get_records()
		for i in range(before_events, records.size()):
			var rec: EventRecord = records[i]
			if rec.kind != AhcEnums.EventRecordKind.INTERACTION_CHOICE:
				continue
			if str(rec.payload.get("prompt_id", "")) == "pick:prey_tie":
				saw_pi = true
				break
	return (
		pick == &"inv_2"
		and saw_pi
		and not h.ctx.interaction.last_used_default
	)


func _test_sc34_narogath_prey_nearest_cultist() -> bool:
	## 场上已有 Cultist @ loc_a；inv1@a、inv2@b → 50026 翻面交战 inv1（非 Lead inv2）。
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file(
		"res://data/arkhamdb/imported/core_classic_slice.json"
	)
	GameBootstrap.setup_test_location(h.ctx, &"loc_a")
	GameBootstrap.setup_test_location(h.ctx, &"loc_b")
	GameBootstrap.connect_locations(h.ctx, &"loc_a", &"loc_b")
	GameBootstrap.setup_minimal_investigator(h.ctx, &"inv_2")
	h.ctx.state.registry.get_investigator(&"inv_1").location_tag = &"loc_a"
	h.ctx.state.registry.get_investigator(&"inv_2").location_tag = &"loc_b"
	h.ctx.state.per_investigator_count = 2
	h.ctx.state.lead_investigator_id = &"inv_2"
	h.ctx.lead_investigator_id = &"inv_2"
	var cult_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"cult_for_narogath",
		{"traits": [&"Humanoid", &"Cultist"]}
	)
	if not h.ctx.enemy.spawn_at_location(h.ctx, cult_id, &"loc_a", &"cult_for_narogath").get(
		"ok", false
	):
		return false
	CardRegistry.register_definition(
		&"agenda_after_50026_prey",
		{"card_type": &"agenda", "doom": 7, "back_text": "Nothing happens."}
	)
	h.ctx.scenario.setup_act_agenda_decks(
		[], [&"50026a", &"agenda_after_50026_prey"]
	)
	var first_id := h.ctx.state.current_agenda_card_id
	h.ctx.state.doom_on_agenda = 6
	h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	return (
		EngagementStatus.is_engaged_with(h.ctx, first_id, &"inv_1")
		and not EngagementStatus.is_engaged_with(h.ctx, first_id, &"inv_2")
		and h.ctx.state.registry.get_investigator(&"inv_1").threat_area.has(first_id)
	)


func _test_sc31_masked_hunter_forbid_clears() -> bool:
	## 脱离后发现/花费限制卸除。
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file(
		"res://data/arkhamdb/imported/core_classic_slice.json"
	)
	GameBootstrap.setup_test_location(h.ctx, &"test_loc", 2, 2)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	inv.clues_on_card = 0
	h.ctx.state.per_investigator_count = 1
	CardRegistry.register_definition(
		&"agenda_pad_clear",
		{"card_type": &"agenda", "doom": 7, "back_text": "Nothing happens."}
	)
	h.ctx.scenario.setup_act_agenda_decks([], [&"01121a", &"agenda_pad_clear"])
	h.ctx.state.doom_on_agenda = 6
	h.ctx.sequence_catalog.run(
		h.ctx, &"seq.agenda.advance", {"source": &"test", "explicit": true}
	)
	var hunter_id := h.ctx.state.registry.all_card_ids()[0]
	for eid in h.ctx.state.registry.all_card_ids():
		var c := h.ctx.state.registry.get_card(eid)
		if c != null and c.id.definition_id == &"01121a" and c.face == AhcEnums.CardFace.B:
			hunter_id = eid
			break
	if not EngagementStatus.is_engaged_with(h.ctx, hunter_id, &"inv_1"):
		return false
	if not RestrictionEvaluator.blocks_discover_clue(&"inv_1", h.ctx.registrations):
		return false
	## 横置脱离：避免同地点 auto-engage 立刻再挂上限制。
	h.ctx.enemy.disengage(h.ctx, hunter_id, true, false)
	var after := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.discover_clue",
		{"inv_id": &"inv_1", "location_id": &"test_loc", "amount": 1}
	)
	return (
		not EngagementStatus.is_engaged(h.ctx, hunter_id)
		and not RestrictionEvaluator.blocks_discover_clue(&"inv_1", h.ctx.registrations)
		and after.get("ok", false)
		and inv.clues_on_card == 1
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


func _test_mod_skill_any() -> bool:
	var h := RuleTestHarness.new(42)
	var c := CompositionTestHelper.new(h.ctx)
	var payload := ModifierPayload.add_skill_any(2)
	c.execute(CompositionNode.register(RegistrationTemplate.lasting_modifier(
		&"inv_1", AhcEnums.DurationAnchorKind.THIS_TURN, payload
	)))
	var q_will := ModifierQuery.new()
	q_will.controller_id = &"inv_1"
	q_will.stat = AhcEnums.StatRef.SKILL_WILLPOWER
	var q_combat := ModifierQuery.new()
	q_combat.controller_id = &"inv_1"
	q_combat.stat = AhcEnums.StatRef.SKILL_COMBAT
	var q_res := ModifierQuery.new()
	q_res.controller_id = &"inv_1"
	q_res.stat = AhcEnums.StatRef.RESOURCE_GAIN_AMOUNT
	return (
		h.ctx.modifiers.compute(3, q_will) == 5
		and h.ctx.modifiers.compute(1, q_combat) == 3
		and h.ctx.modifiers.compute(1, q_res) == 1
	)


func _test_mod_attack_damage_single_leg() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	enemy.health = 5
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionNode.register(
		RegistrationTemplate.attack_damage_bonus_this_test(&"inv_1", 1)
	))
	var res := h.fight_action({"enemy_id": &"enemy_1"})
	enemy = h.ctx.state.registry.get_enemy(&"enemy_1")
	return res.ok and res.success and enemy != null and enemy.damage == 2


func _test_mod_attack_damage_determined() -> bool:
	## MOD-03 · 03153：效果/目标已定；无名 +N 改攻击伤害（primary），旁路不变。
	var h := RuleTestHarness.new(42)
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionNode.register(
		RegistrationTemplate.attack_damage_bonus_this_test(&"inv_1", 1)
	))
	var plan := AmountPlan.attack_damage_determined(
		&"enemy_a", {&"enemy_a": 1, &"enemy_b": 1}
	)
	plan = h.ctx.modifiers.apply_to_amount_plan(plan, &"inv_1", h.ctx)
	return (
		plan.effect_shape == AhcEnums.AmountEffectShape.DETERMINED
		and plan.leg_at(plan.find_leg_index(&"enemy_a")).amount == 2
		and plan.leg_at(plan.find_leg_index(&"enemy_b")).amount == 1
		and plan.amount == 2
	)


func _test_mod_attack_damage_determined_from_zero() -> bool:
	## MOD-04：primary 攻击伤害为 0 仍可被无名修正；旁路仍为 0。
	var h := RuleTestHarness.new(42)
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionNode.register(
		RegistrationTemplate.attack_damage_bonus_this_test(&"inv_1", 1)
	))
	var plan := AmountPlan.attack_damage_determined(
		&"enemy_a", {&"enemy_a": 0, &"enemy_b": 0}
	)
	plan = h.ctx.modifiers.apply_to_amount_plan(plan, &"inv_1", h.ctx)
	return (
		plan.leg_at(plan.find_leg_index(&"enemy_a")).amount == 1
		and plan.leg_at(plan.find_leg_index(&"enemy_b")).amount == 0
	)


func _test_mod_attack_damage_assign() -> bool:
	## MOD-05 · 04305：先定效果；+N 改攻击伤害 amount；settle 再 Assign（默认→primary）。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_a", &"test_loc", 2, 2)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_b", &"test_loc", 2, 2)
	var ea := h.ctx.state.registry.get_enemy(&"enemy_a")
	var eb := h.ctx.state.registry.get_enemy(&"enemy_b")
	ea.health = 10
	eb.health = 10
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionNode.register(
		RegistrationTemplate.attack_damage_bonus_this_test(&"inv_1", 1)
	))
	var plan := AmountPlan.attack_damage_assign(
		4, &"enemy_a", [&"enemy_a", &"enemy_b"] as Array[StringName]
	)
	plan = h.ctx.modifiers.apply_to_amount_plan(plan, &"inv_1", h.ctx)
	if plan.amount != 5 or not plan.legs.is_empty():
		return false
	var settled := ModifierEngine.settle_amount_plan(h.ctx, plan)
	ea = h.ctx.state.registry.get_enemy(&"enemy_a")
	eb = h.ctx.state.registry.get_enemy(&"enemy_b")
	return (
		int(settled.get("settled", 0)) == 5
		and plan.amount == 0
		and ea.damage == 5
		and eb.damage == 0
	)


func _test_mod_discover_bonus_single_leg() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var loc := h.ctx.state.registry.get_location(&"test_loc")
	loc.clues = 3
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionNode.register(
		RegistrationTemplate.discover_bonus_this_test(&"inv_1", 1)
	))
	var res := h.investigate_action()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		res.ok
		and res.success
		and loc.clues == 1
		and inv.clues_on_card == 2
	)


func _test_mod_discover_determined_multi() -> bool:
	## MOD-07：多地已定；无名发现修正不含目标 → 只加 primary（调查地）。
	var h := RuleTestHarness.new(42)
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionNode.register(
		RegistrationTemplate.discover_bonus_this_test(&"inv_1", 1)
	))
	var plan := AmountPlan.new()
	plan.kind = AhcEnums.ModifierPlanKind.DISCOVER
	plan.effect_shape = AhcEnums.AmountEffectShape.DETERMINED
	plan.primary_subject_id = &"loc_a"
	plan.legs.append(AmountPlan.AmountLeg.make(&"loc_a", 1))
	plan.legs.append(AmountPlan.AmountLeg.make(&"loc_b", 1))
	plan.amount = 1
	plan = h.ctx.modifiers.apply_to_amount_plan(plan, &"inv_1", h.ctx)
	return (
		plan.leg_at(plan.find_leg_index(&"loc_a")).amount == 2
		and plan.leg_at(plan.find_leg_index(&"loc_b")).amount == 1
	)


func _test_mod_discover_zero_primary_bonus() -> bool:
	## MOD-08：primary 发现量为 0 时无名修正仍加在 primary。
	var h := RuleTestHarness.new(42)
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionNode.register(
		RegistrationTemplate.discover_bonus_this_test(&"inv_1", 1)
	))
	var plan := AmountPlan.new()
	plan.kind = AhcEnums.ModifierPlanKind.DISCOVER
	plan.effect_shape = AhcEnums.AmountEffectShape.DETERMINED
	plan.primary_subject_id = &"loc_a"
	plan.legs.append(AmountPlan.AmountLeg.make(&"loc_a", 0))
	plan.legs.append(AmountPlan.AmountLeg.make(&"loc_b", 0))
	plan = h.ctx.modifiers.apply_to_amount_plan(plan, &"inv_1", h.ctx)
	return (
		plan.leg_at(plan.find_leg_index(&"loc_a")).amount == 1
		and plan.leg_at(plan.find_leg_index(&"loc_b")).amount == 0
	)


func _test_mod_shroud_investigate() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var loc := h.ctx.state.registry.get_location(&"test_loc")
	loc.shroud = 4
	loc.clues = 2
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionNode.register(
		RegistrationTemplate.reduce_shroud_this_turn(&"inv_1", 3)
	))
	var q := ModifierQuery.new()
	q.controller_id = &"inv_1"
	q.stat = AhcEnums.StatRef.SHROUD
	if h.ctx.modifiers.compute(4, q) != 1:
		return false
	## 印刷 shroud 4、−3 → 难度 1；默认混沌袋易成功并发现线索。
	var res := h.investigate_action()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return res.ok and res.success and loc.clues == 1 and inv.clues_on_card == 1


func _test_mod_enemy_damage_then_pipeline() -> bool:
	## MOD-10：先修敌人攻击伤害量 → DamagePipeline 承伤。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_ed", &"test_loc", 2, 2)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_ed")
	enemy.attack_damage = 3
	enemy.attack_horror = 0
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionNode.register(
		RegistrationTemplate.reduce_enemy_damage_this_turn(&"inv_1", 1)
	))
	var strike := EnemyAttack.build_from_enemy(
		h.ctx, &"enemy_ed", &"inv_1", false, AhcEnums.AttackKind.PHASE
	)
	if strike.damage != 2:
		return false
	h.ctx.combat.perform_attack(strike)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return inv.damage_taken == 2


func _test_mod_enemy_attack_increase_pending() -> bool:
	## MOD-11：敌人攻击进 DamagePipeline；WHEN 可 increase_pending（02221 同路）。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_ip", &"test_loc", 2, 2)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_ip")
	enemy.attack_damage = 2
	enemy.attack_horror = 0
	var when_n := {"n": -1}
	var when_h := SequenceHandler.when_forced(&"damage", func() -> void: pass)
	when_h.callback = func() -> void:
		DamagePipeline.increase_pending(h.ctx, &"inv_1", 2)
		when_n["n"] = DamagePipeline.pending_amount(h.ctx, &"inv_1")
	h.ctx.sequences.register_handler(when_h)
	var strike := EnemyAttack.build_from_enemy(
		h.ctx, &"enemy_ip", &"inv_1", false, AhcEnums.AttackKind.PHASE
	)
	h.ctx.combat.perform_attack(strike)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return when_n["n"] == 4 and inv.damage_taken == 4


func _test_mod_discover_named_bonus() -> bool:
	## MOD-12 · 09059 形：效果步指名在另一地点加发现（非无名 Buff 选腿）。
	var h := RuleTestHarness.new(42)
	var plan := AmountPlan.discover_single(&"loc_a", 1)
	plan.add_named_bonus(&"loc_enemy", 1)
	return (
		plan.leg_at(plan.find_leg_index(&"loc_a")).amount == 1
		and plan.leg_at(plan.find_leg_index(&"loc_enemy")).amount == 1
	)


func _test_mod_attack_multi_leg_settle_one_seq() -> bool:
	## MOD-13 · 03153 形：多敌 DETERMINED settle → 一条 seq.effect.deal + legs；L0 仍单目标。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_a", &"test_loc", 2, 2)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_b", &"test_loc", 2, 2)
	var ea := h.ctx.state.registry.get_enemy(&"enemy_a")
	var eb := h.ctx.state.registry.get_enemy(&"enemy_b")
	ea.health = 10
	eb.health = 10
	var plan := AmountPlan.attack_damage_determined(
		&"enemy_a", {&"enemy_a": 2, &"enemy_b": 1}
	)
	var settled := ModifierEngine.settle_amount_plan(h.ctx, plan)
	ea = h.ctx.state.registry.get_enemy(&"enemy_a")
	eb = h.ctx.state.registry.get_enemy(&"enemy_b")
	return (
		bool(settled.get("multi", false))
		and int(settled.get("settled", 0)) == 3
		and ea.damage == 2
		and eb.damage == 1
	)


func _test_mod_discover_multi_leg_settle_one_seq() -> bool:
	## MOD-14：多地 DISCOVER settle → 一条 seq.effect.discover_clue + legs；原语逐地。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_location(h.ctx, &"loc_a", 2, 3)
	GameBootstrap.setup_test_location(h.ctx, &"loc_b", 2, 3)
	var plan := AmountPlan.new()
	plan.kind = AhcEnums.ModifierPlanKind.DISCOVER
	plan.effect_shape = AhcEnums.AmountEffectShape.DETERMINED
	plan.primary_subject_id = &"loc_a"
	plan.legs.append(AmountPlan.AmountLeg.make(&"loc_a", 2))
	plan.legs.append(AmountPlan.AmountLeg.make(&"loc_b", 1))
	plan.amount = 2
	var settled := ModifierEngine.settle_amount_plan(
		h.ctx, plan, {"inv_id": &"inv_1"}
	)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var la := h.ctx.state.registry.get_location(&"loc_a")
	var lb := h.ctx.state.registry.get_location(&"loc_b")
	return (
		bool(settled.get("multi", false))
		and int(settled.get("settled", 0)) == 3
		and inv.clues_on_card == 3
		and la.clues == 1
		and lb.clues == 2
	)


func _test_mod_multi_leg_damage_after_once() -> bool:
	## MOD-15：legs 多目标仍一条 damage 帧 → AFTER 只响一次。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_a", &"test_loc", 2, 2)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_b", &"test_loc", 2, 2)
	h.ctx.state.registry.get_enemy(&"enemy_a").health = 10
	h.ctx.state.registry.get_enemy(&"enemy_b").health = 10
	var after_n := {"n": 0}
	var after_h := SequenceHandler.after_forced(&"damage", func() -> void: pass)
	after_h.callback = func() -> void:
		after_n["n"] = int(after_n["n"]) + 1
	h.ctx.sequences.register_handler(after_h)
	var nest_res: Variant = h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.deal",
		{
			"controller_id": &"inv_1",
			"kind": &"damage",
			"target": &"enemy",
			"legs": [
				{"id": &"enemy_a", "amount": 1},
				{"id": &"enemy_b", "amount": 1},
			],
		}
	)
	var ea := h.ctx.state.registry.get_enemy(&"enemy_a")
	var eb := h.ctx.state.registry.get_enemy(&"enemy_b")
	return (
		nest_res is Dictionary
		and bool((nest_res as Dictionary).get("multi", false))
		and int((nest_res as Dictionary).get("amount", 0)) == 2
		and after_n["n"] == 1
		and ea.damage == 1
		and eb.damage == 1
	)


func _test_mod_deal_assignable_bundle_one_seq() -> bool:
	## 伤+恐同条 deal.assignable；AFTER(damage) 只一次（非各开一条）。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var after_n := {"n": 0}
	var after_h := SequenceHandler.after_forced(&"damage", func() -> void: pass)
	after_h.callback = func() -> void:
		after_n["n"] = int(after_n["n"]) + 1
	h.ctx.sequences.register_handler(after_h)
	var res: Variant = h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.deal.assignable",
		{
			"controller_id": &"inv_1",
			"damage": 2,
			"horror": 1,
			"target": &"controller",
		}
	)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		res is Dictionary
		and bool((res as Dictionary).get("simultaneous", false))
		and int((res as Dictionary).get("damage", 0)) == 2
		and int((res as Dictionary).get("horror", 0)) == 1
		and after_n["n"] == 1
		and inv.damage_taken == 2
		and inv.horror_taken == 1
	)


func _test_mod_deal_mixed_subject_legs() -> bool:
	## MOD-17：已定 deal legs 混装敌人 + 有生命场上卡；一条 seq，L0 分路由。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_mix", &"test_loc", 2, 2)
	h.ctx.state.registry.get_enemy(&"enemy_mix").health = 10
	var card_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_deal_mix", {"health": 3, "sanity": 0}
	)
	var nest_res: Variant = h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.deal",
		{
			"controller_id": &"inv_1",
			"kind": &"damage",
			"target": &"subjects",
			"legs": [
				{"id": &"enemy_mix", "amount": 2},
				{"id": card_id, "amount": 1},
			],
		}
	)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_mix")
	var card := h.ctx.state.registry.get_card(card_id)
	return (
		nest_res is Dictionary
		and bool((nest_res as Dictionary).get("multi", false))
		and int((nest_res as Dictionary).get("amount", 0)) == 3
		and enemy.damage == 2
		and card != null
		and card.tokens.damage == 1
	)


func _test_mod_deal_assignable_card_subject() -> bool:
	## MOD-18：assignable among 场上卡（非仅敌人）。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var card_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_deal_asn_card", {"health": 4, "sanity": 0}
	)
	var res: Variant = h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.deal.assignable",
		{
			"controller_id": &"inv_1",
			"target": &"subjects",
			"damage": 2,
			"primary_id": card_id,
			"candidates": [card_id],
		}
	)
	var card := h.ctx.state.registry.get_card(card_id)
	return (
		res is Dictionary
		and bool((res as Dictionary).get("ok", false))
		and int((res as Dictionary).get("damage", 0)) == 2
		and card != null
		and card.tokens.damage == 2
	)


func _test_mod_deal_dual_legs_empty_side() -> bool:
	## MOD-19：seq.effect.deal 支持 legs_damage/legs_horror；单边空载兼容单类型。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_dual", &"test_loc", 2, 2)
	h.ctx.state.registry.get_enemy(&"enemy_dual").health = 10
	var only_dmg: Variant = h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.deal",
		{
			"controller_id": &"inv_1",
			"target": &"subjects",
			"legs_damage": [{"id": &"enemy_dual", "amount": 2}],
			"legs_horror": [],
		}
	)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_dual")
	if (
		not (only_dmg is Dictionary)
		or int((only_dmg as Dictionary).get("damage", 0)) != 2
		or int((only_dmg as Dictionary).get("horror", 0)) != 0
		or enemy.damage != 2
	):
		return false
	var only_hor: Variant = h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.deal",
		{
			"controller_id": &"inv_1",
			"target": &"controller",
			"assign_format": &"pipeline",
			"legs_damage": [],
			"legs_horror": [{"bearer": &"investigator", "id": &"inv_1", "amount": 1}],
		}
	)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var both: Variant = h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.deal",
		{
			"controller_id": &"inv_1",
			"target": &"controller",
			"assign_format": &"pipeline",
			"legs_damage": [{"bearer": &"investigator", "id": &"inv_1", "amount": 1}],
			"legs_horror": [{"bearer": &"investigator", "id": &"inv_1", "amount": 1}],
		}
	)
	return (
		only_hor is Dictionary
		and int((only_hor as Dictionary).get("horror", 0)) == 1
		and int((only_hor as Dictionary).get("damage", 0)) == 0
		and both is Dictionary
		and bool((both as Dictionary).get("simultaneous", false))
		and int((both as Dictionary).get("damage", 0)) == 1
		and int((both as Dictionary).get("horror", 0)) == 1
		and inv.damage_taken == 1
		and inv.horror_taken == 2
	)


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


func _test_listener_no_vacuum() -> bool:
	## LISTENER 开火经 seq.ability.resolve 装载（禁直 execute）。
	var h := RuleTestHarness.new(42)
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionTestHelper.delayed_draw_listener(&"inv_1", &"after_fight"))
	var before := _sequence_kind_count(h, &"ability_resolve")
	h.ctx.timing.emit_timing(&"after_fight")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		inv.hand.size() == 1
		and _sequence_kind_count(h, &"ability_resolve") > before
	)


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
	return CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.HORROR_TAKEN,
				amount,
				MarkerSlot.supply(AhcEnums.MarkerKind.HORROR_TAKEN),
				MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.HORROR_TAKEN)
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


func _test_choice_optional_default_decline() -> bool:
	var h := RuleTestHarness.new(42)
	var c := CompositionTestHelper.new(h.ctx)
	var node := CompositionNode.choice_optional(
		_must_choice_horror(),
		&"inv_1",
		&"may:horror",
		&"optional_chose"
	)
	c.execute(node)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var chose: Variant = h.ctx.memory.get_referent(&"inv_1", &"optional_chose")
	return inv.horror_taken == 0 and chose == false


func _test_choice_optional_accept() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"may:horror", "pick": true},
	])
	var c := CompositionTestHelper.new(h.ctx)
	var node := CompositionNode.choice_optional(
		_must_choice_horror(2),
		&"inv_1",
		&"may:horror",
		&"optional_chose"
	)
	c.execute(node)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var chose: Variant = h.ctx.memory.get_referent(&"inv_1", &"optional_chose")
	return inv.horror_taken == 2 and chose == true


func _test_choice_optional_dry_run() -> bool:
	var h := RuleTestHarness.new(42)
	var c := CompositionTestHelper.new(h.ctx)
	var node := CompositionNode.choice_optional(
		_must_choice_horror(),
		&"inv_1",
		&"may:horror"
	)
	var fizzle := CompositionNode.choice_optional(
		CompositionNode.draw(&"inv_1"),
		&"inv_1",
		&"may:draw"
	)
	return c.dry_run(node) and not c.dry_run(fizzle)


func _test_choice_optional_compiler() -> bool:
	var bind := AbilityBindContext.new()
	bind.controller_id = &"inv_1"
	var node := ArkhamDbAbilityCompiler.build_composition(
		"choice_optional",
		{
			"prompt_id": "may:horror",
			"memory_key": "optional_chose",
			"body": {"template": "take_horror", "amount": 1},
		},
		bind
	)
	return (
		node != null
		and node.kind == AhcEnums.CompositionNodeKind.OPTIONAL
		and node.choice_prompt_id == &"may:horror"
		and node.memory_key == &"optional_chose"
		and node.children.size() == 1
	)


func _test_choice_optional_fizzle_skip() -> bool:
	var h := RuleTestHarness.new(42)
	## Scripting 若被调用会返回 true；fizzle 路径不得 ask。
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"may:draw", "pick": true},
	])
	var c := CompositionTestHelper.new(h.ctx)
	var node := CompositionNode.choice_optional(
		CompositionNode.draw(&"inv_1"),
		&"inv_1",
		&"may:draw",
		&"optional_chose"
	)
	c.execute(node)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var chose: Variant = h.ctx.memory.get_referent(&"inv_1", &"optional_chose")
	return inv.hand.is_empty() and chose == null


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
	if not h.resolve_encounter_revelation(card_id):
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
			var atom := str(rec.payload.get("atom", ""))
			if (
				atom == "transfer_marker"
				or atom == "nest_damage"
				or atom == "nest_take_horror"
				or atom == "take_horror"
			):
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
	if not h.resolve_encounter_revelation(card_id):
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
	if not h.resolve_encounter_revelation(card_id):
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
	if not h.resolve_encounter_revelation(card_id):
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
	if not h.resolve_encounter_revelation(card_id):
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
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				1,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE)
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
			return CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				2,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.RESOURCE)
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
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				3,
				MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE)
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
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				1,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE)
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
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				5,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE)
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
		{"prompt_id": &"willingness:join", "pick": true},
	])
	var desc := TriggeredAbilityDescriptor.reaction(
		&"gain_resource",
		AhcEnums.SequencePhase.AFTER,
		&"inv_1",
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				2,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE)
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
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				3,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(&"inv_2", AhcEnums.MarkerKind.RESOURCE)
			)
	)
	h.ctx.triggered_abilities.register(desc)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"willingness:join", "pick": true},
	])
	var inv := h.ctx.state.registry.get_investigator(&"inv_2")
	var pool_before := inv.resource_pool
	h.ctx.resource_gain.gain(h.ctx, &"inv_2", 1, [&"resource_action"])
	return inv.resource_pool == pool_before + 1


func _test_rw_willingness_pool_order() -> bool:
	## 两条 [reaction] 同窗：均入池 → 队长先放行 B → 再放行 A。
	var h := RuleTestHarness.new(42)
	var order: Array[String] = []
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"willingness:join", "pick": true},
		{"prompt_id": &"willingness:pick", "pick": &"react_b"},
	])
	var react_a := SequenceHandler.after_reaction(
		&"gain_resource",
		&"react_a",
		&"inv_1",
		func() -> void: order.append("a")
	)
	var react_b := SequenceHandler.after_reaction(
		&"gain_resource",
		&"react_b",
		&"inv_1",
		func() -> void: order.append("b")
	)
	h.ctx.sequences.register_handler(react_a)
	h.ctx.sequences.register_handler(react_b)
	h.ctx.resource_gain.gain(h.ctx, &"inv_1", 1, [&"resource_action"])
	return order == ["b", "a"]


func _test_rw_forced_before_reactions() -> bool:
	## Forced 自动批先于意愿池；两条反应随后按 pick 序。
	var h := RuleTestHarness.new(42)
	var order: Array[String] = []
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"willingness:join", "pick": true},
		{"prompt_id": &"willingness:pick", "pick": &"react_1"},
	])
	h.ctx.sequences.register_handler(
		SequenceHandler.after_forced(
			&"gain_resource",
			func() -> void: order.append("forced")
		)
	)
	h.ctx.sequences.register_handler(
		SequenceHandler.after_reaction(
			&"gain_resource",
			&"react_1",
			&"inv_1",
			func() -> void: order.append("r1")
		)
	)
	h.ctx.sequences.register_handler(
		SequenceHandler.after_reaction(
			&"gain_resource",
			&"react_2",
			&"inv_1",
			func() -> void: order.append("r2")
		)
	)
	h.ctx.resource_gain.gain(h.ctx, &"inv_1", 1, [&"resource_action"])
	return order == ["forced", "r1", "r2"]


func _test_rw_reaction_after_nest() -> bool:
	## 第一条反应 nest 后才登记第二条 → 下一轮 COLLECT 再入池。
	var h := RuleTestHarness.new(42)
	var order: Array[String] = []
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"willingness:join", "pick": true},
	])
	var react_outer := SequenceHandler.after_reaction(
		&"gain_resource",
		&"react_outer",
		&"inv_1",
		func() -> void:
			order.append("outer")
			var react_inner := SequenceHandler.after_reaction(
				&"gain_resource",
				&"react_inner",
				&"inv_1",
				func() -> void: order.append("inner")
			)
			h.ctx.sequences.register_handler(react_inner)
	)
	h.ctx.sequences.register_handler(react_outer)
	h.ctx.resource_gain.gain(h.ctx, &"inv_1", 1, [&"resource_action"])
	return order == ["outer", "inner"]


func _test_rw_mode_auto_join() -> bool:
	## AUTO_JOIN：不经 willingness:join ask；默认 resolver 亦会结算。
	var h := RuleTestHarness.new(42)
	h.ctx.ability_response_prefs.set_mode(
		AhcEnums.AbilityResponseMode.AUTO_JOIN, &"", &"", &"react_auto"
	)
	var fired := [false]
	h.ctx.sequences.register_handler(
		SequenceHandler.after_reaction(
			&"gain_resource",
			&"react_auto",
			&"inv_1",
			func() -> void: fired[0] = true
		)
	)
	h.ctx.resource_gain.gain(h.ctx, &"inv_1", 1, [&"resource_action"])
	return fired[0]


func _test_rw_mode_auto_decline() -> bool:
	## AUTO_DECLINE：即使脚本愿 join 也不入池。
	var h := RuleTestHarness.new(42)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"willingness:join", "pick": true},
	])
	h.ctx.ability_response_prefs.set_mode(
		AhcEnums.AbilityResponseMode.AUTO_DECLINE, &"", &"", &"react_no"
	)
	var fired := [false]
	h.ctx.sequences.register_handler(
		SequenceHandler.after_reaction(
			&"gain_resource",
			&"react_no",
			&"inv_1",
			func() -> void: fired[0] = true
		)
	)
	h.ctx.resource_gain.gain(h.ctx, &"inv_1", 1, [&"resource_action"])
	return not fired[0]


func _test_elig_l3_condition_fail() -> bool:
	## L3：collect_condition 不满足 → 不进响应池。
	var h := RuleTestHarness.new(42)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"willingness:join", "pick": true},
	])
	var fired := [false]
	var react := SequenceHandler.after_reaction(
		&"gain_resource",
		&"react_cond_fail",
		&"inv_1",
		func() -> void: fired[0] = true
	)
	react.collect_condition = Condition.with_tags([&"needs_missing_tag"])
	h.ctx.sequences.register_handler(react)
	h.ctx.resource_gain.gain(h.ctx, &"inv_1", 1, [&"resource_action"])
	return not fired[0]


func _test_elig_l3_condition_pass() -> bool:
	## L3：标签匹配 → 可入池结算。
	var h := RuleTestHarness.new(42)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"willingness:join", "pick": true},
	])
	var fired := [false]
	var react := SequenceHandler.after_reaction(
		&"gain_resource",
		&"react_cond_ok",
		&"inv_1",
		func() -> void: fired[0] = true
	)
	react.collect_condition = Condition.with_tags([&"resource_action"])
	h.ctx.sequences.register_handler(react)
	h.ctx.resource_gain.gain(h.ctx, &"inv_1", 1, [&"resource_action"])
	return fired[0]


func _test_elig_l4_peril_collect() -> bool:
	## L4：险境 FORBID_TRIGGER 在 COLLECT 筛掉队友反应（不入池）。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	_setup_peril_for_drawer(h, &"inv_1", &"enc_peril_elig_l4")
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"willingness:join", "pick": true},
	])
	var fired := [false]
	h.ctx.sequences.register_handler(
		SequenceHandler.after_reaction(
			&"gain_resource",
			&"react_peril_blocked",
			&"inv_2",
			func() -> void: fired[0] = true
		)
	)
	h.ctx.resource_gain.gain(h.ctx, &"inv_2", 1, [&"resource_action"])
	return not fired[0]


func _test_elig_l5_limit() -> bool:
	## L5：次数耗尽不出候选。
	var h := RuleTestHarness.new(42)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"willingness:join", "pick": true},
	])
	var fired := [false]
	var react := SequenceHandler.after_reaction(
		&"gain_resource",
		&"react_limit",
		&"inv_1",
		func() -> void: fired[0] = true
	)
	react.limit_remaining = 0
	h.ctx.sequences.register_handler(react)
	h.ctx.resource_gain.gain(h.ctx, &"inv_1", 1, [&"resource_action"])
	return not fired[0]


func _test_elig_collect_no_dry_run() -> bool:
	## COLLECT 只跑 L1–L5；无 composition 时仍可判定，不依赖 dry_run。
	var h := RuleTestHarness.new(42)
	var react := SequenceHandler.after_reaction(
		&"gain_resource",
		&"react_dry",
		&"inv_1",
		func() -> void: pass
	)
	react.collect_condition = Condition.with_tags([&"resource_action"])
	var app_ctx := ApplicationContext.new()
	app_ctx.tags = [&"gain_resource", &"resource_action"]
	var reports: Array = EligibilityPipeline.run_collect(react, h.ctx, app_ctx, false)
	if reports.size() != 5:
		return false
	for r in reports:
		if r == null or not (r as EligibilityPipeline.GateReport).passed:
			return false
		## 关卡号须在 1–5；无 L6/L7。
		var level: int = (r as EligibilityPipeline.GateReport).level
		if level < 1 or level > 5:
			return false
	return EligibilityPipeline.passes_collect(react, h.ctx, app_ctx, false)


func _pw_register_free_resource(h: RuleTestHarness, ability_id: StringName, amount: int = 1) -> StringName:
	var card_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"pw_free_asset")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"inv_1"
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.PLAY_AREA
	h.ctx.state.registry.register_card(card)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.play_area.append(card_id)
	var desc := TriggeredAbilityDescriptor.free_triggered(
		&"inv_1",
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				amount,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE)
			),
		&"during_your_turn",
		card_id,
		&"pw_free_asset"
	)
	desc.id = ability_id
	h.ctx.triggered_abilities.register(desc)
	return ability_id


func _test_pw_intent_sole_pulse() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	if not h.ctx.framework.waiting_player_window:
		h.ctx.framework.open_player_window(AhcEnums.PlayerWindow.PW_INV_BEFORE_ACTION)
	_pw_register_free_resource(h, &"free_res_1", 2)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var before := inv.resource_pool
	var enq := h.ctx.player_window_intents.enqueue_free(&"free_res_1", &"inv_1")
	if not bool(enq.get("ok", false)):
		return false
	var pulse := h.ctx.player_window_intents.pulse()
	return (
		bool(pulse.get("ok", false))
		and int(pulse.get("resolved", 0)) == 1
		and inv.resource_pool == before + 2
		and h.ctx.framework.waiting_player_window
		and h.ctx.player_window_intents.size() == 0
	)


func _test_pw_intent_contention() -> bool:
	## 两名调查员各挂一条 → pulse 争议由队长挑 inv_2 的意图。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	h.ctx.state.lead_investigator_id = &"inv_1"
	h.ctx.lead_investigator_id = &"inv_1"
	if not h.prepare_action_phase():
		return false
	if not h.ctx.framework.waiting_player_window:
		h.ctx.framework.open_player_window(AhcEnums.PlayerWindow.PW_INV_BEFORE_ACTION)
	## inv_1 free
	var card_a := h.ctx.state.registry.allocate_instance_id(&"card")
	var ea := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_a, &"pw_a")
	var ca := CardInstance.new()
	ca.id = ea
	ca.owner_id = &"inv_1"
	ca.controller_id = &"inv_1"
	ca.zone = AhcEnums.Zone.PLAY_AREA
	h.ctx.state.registry.register_card(ca)
	h.ctx.state.registry.get_investigator(&"inv_1").play_area.append(card_a)
	var desc_a := TriggeredAbilityDescriptor.free_triggered(
		&"inv_1",
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				1,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE)
			),
		&"any_player_window",
		card_a,
		&"pw_a"
	)
	desc_a.id = &"free_a"
	h.ctx.triggered_abilities.register(desc_a)
	## inv_2 free
	var card_b := h.ctx.state.registry.allocate_instance_id(&"card")
	var eb := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_b, &"pw_b")
	var cb := CardInstance.new()
	cb.id = eb
	cb.owner_id = &"inv_2"
	cb.controller_id = &"inv_2"
	cb.zone = AhcEnums.Zone.PLAY_AREA
	h.ctx.state.registry.register_card(cb)
	h.ctx.state.registry.get_investigator(&"inv_2").play_area.append(card_b)
	var desc_b := TriggeredAbilityDescriptor.free_triggered(
		&"inv_2",
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				3,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(&"inv_2", AhcEnums.MarkerKind.RESOURCE)
			),
		&"any_player_window",
		card_b,
		&"pw_b"
	)
	desc_b.id = &"free_b"
	h.ctx.triggered_abilities.register(desc_b)
	var enq_a := h.ctx.player_window_intents.enqueue_free(&"free_a", &"inv_1")
	var enq_b := h.ctx.player_window_intents.enqueue_free(&"free_b", &"inv_2")
	if not bool(enq_a.get("ok", false)) or not bool(enq_b.get("ok", false)):
		return false
	var pick_id: StringName = enq_b.get("entry_id", &"") as StringName
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"pw_intent:pick", "pick": pick_id},
	])
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	var before2 := inv2.resource_pool
	var pulse := h.ctx.player_window_intents.pulse()
	return (
		bool(pulse.get("ok", false))
		and int(pulse.get("resolved", 0)) == 1
		and inv2.resource_pool == before2 + 3
		and h.ctx.player_window_intents.size() == 1
	)


func _test_pw_intent_empty_closes() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	if not h.ctx.framework.waiting_player_window:
		h.ctx.framework.open_player_window(AhcEnums.PlayerWindow.PW_INV_BEFORE_ACTION)
	var pulse := h.ctx.player_window_intents.pulse()
	return bool(pulse.get("ok", false)) and bool(pulse.get("closed", false))


func _test_pw_batch_01017() -> bool:
	## 01017 白名单 ×3：检定窗入池一次 pulse 连花 3 资源并叠 +3 战。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	GameBootstrap.install_physical_training_01017(h.ctx, &"inv_1")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.resource_pool = 5
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.COMBAT, 2)
	st.begin(test)
	var commit_res := h.ctx.skill_tests.step_commit(test, [])
	if not bool(commit_res.get("ok", false)):
		return false
	if not test.waiting_player_window:
		return false
	var enq := h.ctx.player_window_intents.enqueue_free(
		&"01017:physical_training", &"inv_1", 3
	)
	if not bool(enq.get("ok", false)):
		return false
	if int(enq.get("pool_size", 0)) != 1:
		return false
	var before := inv.resource_pool
	var pulse := h.ctx.player_window_intents.pulse()
	if not bool(pulse.get("ok", false)) or int(pulse.get("resolved", 0)) != 3:
		return false
	if inv.resource_pool != before - 3:
		return false
	var q := ModifierQuery.new()
	q.controller_id = &"inv_1"
	q.stat = AhcEnums.StatRef.SKILL_COMBAT
	return h.ctx.modifiers.compute(0, q) == 3


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
			return CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				1,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.RESOURCE)
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


func _test_trig_free_listed_in_window() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	if not h.ctx.framework.waiting_player_window:
		return false
	var card_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"free_asset")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"inv_1"
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.PLAY_AREA
	h.ctx.state.registry.register_card(card)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.play_area.append(card_id)
	var desc := TriggeredAbilityDescriptor.free_triggered(
		&"inv_1",
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				1,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE)
			),
		&"during_your_turn",
		card_id,
		&"free_asset"
	)
	h.ctx.triggered_abilities.register(desc)
	var listed := h.ctx.triggered_abilities.list_free_abilities(&"inv_1")
	if listed.size() != 1:
		return false
	h.ctx.framework.close_player_window_and_continue()
	while h.ctx.framework.waiting_player_window:
		h.ctx.framework.close_player_window_and_continue()
	return h.ctx.triggered_abilities.list_free_abilities(&"inv_1").is_empty()


func _test_trig_free_activate_move() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_location(h.ctx, &"loc_b")
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"loc_b")
	var card_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"move_free_asset")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"inv_1"
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.PLAY_AREA
	h.ctx.state.registry.register_card(card)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.play_area.append(card_id)
	var desc := TriggeredAbilityDescriptor.free_triggered(
		&"inv_1",
		CompositionNode.seq([
			CompositionNode.exhaust_card(card_id),
			CompositionNode.nest_move_connecting(&"inv_1"),
		]),
		&"during_your_turn",
		card_id,
		&"move_free_asset"
	)
	h.ctx.triggered_abilities.register(desc)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"pick:move_connecting", "pick": &"loc_b"},
	])
	var actions_before := inv.actions_remaining
	var result := h.ctx.triggered_abilities.activate_free(desc.id)
	return (
		bool(result.get("ok", false))
		and card.exhausted
		and inv.location_tag == &"loc_b"
		and inv.actions_remaining == actions_before
	)


func _test_adb_compile_olivier_free() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var compiled := CardRegistry.compiled_abilities(&"12046")
	if compiled.size() != 1:
		return false
	var entry: Dictionary = compiled[0]
	var steps: Variant = entry.get("steps", [])
	if not steps is Array or (steps as Array).size() != 3:
		return false
	var step0: Dictionary = steps[0]
	var step1: Dictionary = steps[1]
	var step2: Dictionary = steps[2]
	return (
		entry.get("register_as", "") == "free"
		and entry.get("window", "") == "during_your_turn"
		and entry.get("template", "") == "seq"
		and step0.get("template", "") == "exhaust_source"
		and step1.get("template", "") == "pick_target"
		and step1.get("filter", "") == "location_connecting"
		and step2.get("template", "") == "nest_move_to"
		and CardRegistry.has_triggered(&"12046")
	)


func _test_adb_olivier_free_activate() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_location(h.ctx, &"loc_b")
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"loc_b")
	var card_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"12046")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"inv_1"
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.HAND
	h.ctx.state.registry.register_card(card)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.hand.append(card_id)
	inv.resource_pool = 5
	if not h.ctx.actions.play_card(&"inv_1", card_id).ok:
		return false
	# play_card may close/advance windows; re-open investigation player window if needed
	if not h.ctx.framework.waiting_player_window:
		h.ctx.framework.open_player_window(AhcEnums.PlayerWindow.PW_INV_BEFORE_ACTION)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"pick:move_connecting", "pick": &"loc_b"},
	])
	var free_list := h.ctx.triggered_abilities.list_free_abilities(&"inv_1")
	if free_list.is_empty():
		return false
	var result := h.ctx.triggered_abilities.activate_free(free_list[0].id)
	return (
		bool(result.get("ok", false))
		and card.exhausted
		and inv.location_tag == &"loc_b"
	)


func _test_adb_compile_12125_forced() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12125")
	var forced: Dictionary = {}
	for entry in compiled:
		if entry is Dictionary and str((entry as Dictionary).get("register_as", "")) == "forced":
			forced = entry as Dictionary
			break
	return (
		CardRegistry.has_revelation(&"12125")
		and CardRegistry.has_triggered(&"12125")
		and forced.get("template", "") == "take_horror"
		and forced.get("match_kind", "") == "discover_clue"
		and str(forced.get("phase", "")).to_upper() == "AFTER"
		and int(forced.get("amount", 0)) == 1
	)


func _test_adb_12125_forced_discover() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	if not h.prepare_action_phase():
		return false
	var loc := h.ctx.state.registry.get_location(&"test_loc")
	loc.clues = 1
	var card_id := _adb_add_encounter_treachery_to_deck(h, &"12125")
	var draw_res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not bool(draw_res.get("ok", false)):
		return false
	var card := h.ctx.state.registry.get_card(card_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	if card == null or inv == null:
		return false
	if card.zone != AhcEnums.Zone.PLAY_AREA:
		return false
	if not inv.threat_area.has(card_id):
		return false
	var horror_before := inv.horror_taken
	var res := h.investigate_action()
	return (
		res.ok
		and res.success
		and loc.clues == 0
		and inv.clues_on_card == 1
		and inv.horror_taken == horror_before + 1
	)


func _test_adb_compile_12108_forced() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12108")
	var forced: Dictionary = {}
	for entry in compiled:
		if entry is Dictionary and str((entry as Dictionary).get("register_as", "")) == "forced":
			forced = entry as Dictionary
			break
	return (
		CardRegistry.has_triggered(&"12108")
		and forced.get("template", "") == "lead_draw_topmost_encounter_discard_copy"
		and forced.get("match_kind", "") == "mythos_place_doom"
		and str(forced.get("phase", "")).to_upper() == "AFTER"
		and str(forced.get("definition_id", "")) == "12129"
	)


func _test_adb_compile_12145_reaction() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12145")
	if compiled.size() != 1:
		return false
	var entry: Dictionary = compiled[0]
	return (
		CardRegistry.has_triggered(&"12145")
		and entry.get("register_as", "") == "reaction"
		and entry.get("template", "") == "gain_resources"
		and entry.get("match_kind", "") == "discover_clue"
		and str(entry.get("phase", "")).to_upper() == "AFTER"
		and int(entry.get("amount", 0)) == 1
	)


func _adb_setup_downtown_location(h: RuleTestHarness) -> StringName:
	GameBootstrap.setup_test_location(h.ctx, &"12145", 2, 1)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"12145"
	var card_id := ScenarioLayoutSetup.materialize_card(
		h.ctx, &"12145", AhcEnums.Zone.LOCATION_AREA, &"loc", &"12145"
	)
	ScenarioDeckSetup.install_triggered_abilities(h.ctx, card_id)
	return card_id


func _test_adb_12145_reaction_discover() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	if not h.prepare_action_phase():
		return false
	_adb_setup_downtown_location(h)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"willingness:join", "pick": true},
	])
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var pool_before := inv.resource_pool
	var loc := h.ctx.state.registry.get_location(&"12145")
	var res := h.investigate_action()
	return (
		res.ok
		and res.success
		and loc.clues == 0
		and inv.clues_on_card == 1
		and inv.resource_pool == pool_before + 1
	)


func _test_adb_12145_reaction_declined() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	if not h.prepare_action_phase():
		return false
	_adb_setup_downtown_location(h)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var pool_before := inv.resource_pool
	var res := h.investigate_action()
	return res.ok and res.success and inv.resource_pool == pool_before


func _test_adb_compile_12060_jim_take() -> bool:
	## ADB-73：Jim Culver after take damage and/or horror → damage + either + take_self。
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var compiled := CardRegistry.compiled_abilities(&"12060")
	if compiled.size() != 1:
		return false
	var entry: Dictionary = compiled[0]
	var steps: Variant = entry.get("steps", [])
	if not steps is Array or (steps as Array).size() != 2:
		return false
	var step0: Dictionary = steps[0]
	var step1: Dictionary = steps[1]
	return (
		CardRegistry.has_triggered(&"12060")
		and entry.get("register_as", "") == "reaction"
		and entry.get("status", "") == "full"
		and entry.get("match_kind", "") == "damage"
		and str(entry.get("phase", "")).to_upper() == "AFTER"
		and entry.get("affliction_filter", "") == "either"
		and bool(entry.get("take_self", false))
		and step0.get("template", "") == "exhaust_source"
		and step1.get("template", "") == "draw"
		and int(step1.get("amount", 0)) == 1
	)


func _test_adb_12060_jim_after_take() -> bool:
	## ADB-74：承伤 AFTER → exhaust Jim + draw（经注册路径，非手写 handler）。
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	if not h.prepare_action_phase():
		return false
	var card_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"12060", {"health": 2, "sanity": 2}
	)
	h.ctx.triggered_abilities.install_card(&"inv_1", card_id)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new(
		[{"prompt_id": &"willingness:join", "pick": true}]
	)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var hand_before := inv.hand.size()
	## 保证有牌可抽。
	var deck_card := GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1", &"filler_jim_draw")
	if deck_card == &"":
		return false
	var res: Variant = h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.deal.assignable",
		{"controller_id": &"inv_1", "damage": 1, "horror": 0}
	)
	var card := h.ctx.state.registry.get_card(card_id)
	return (
		res is Dictionary
		and bool((res as Dictionary).get("ok", false))
		and card != null
		and card.exhausted
		and inv.hand.size() == hand_before + 1
		and inv.damage_taken == 1
	)


func _test_seq_eff_nest_take_horror() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.ctx.sequence_catalog.has_flow(&"seq.effect.deal.assignable"):
		return false
	var node := CompositionNode.nest_take_horror(&"inv_1", 2)
	if node.nest_flow_id != &"seq.effect.deal.assignable":
		return false
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(node)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return inv.horror_taken == 2 and _sequence_kind_count(h, &"damage") > 0


func _test_seq_eff_register_unregister() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.ctx.sequence_catalog.has_flow(&"seq.effect.register"):
		return false
	if not h.ctx.sequence_catalog.has_flow(&"seq.effect.unregister"):
		return false
	var card_id := &"surge_card"
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionNode.grant_keyword(card_id, &"surge"))
	if not h.ctx.registrations.has_keyword_buff(card_id, &"surge"):
		return false
	if _sequence_kind_count(h, &"effect_register") == 0:
		return false
	var regs: Array = h.ctx.registrations.all_registrations()
	if regs.is_empty():
		return false
	c.execute(CompositionNode.nest_effect_unregister((regs[0] as Registration).id))
	return (
		h.ctx.registrations.count() == 0
		and _sequence_kind_count(h, &"effect_unregister") > 0
	)


func _test_seq_eff_lose_resources_fizzle() -> bool:
	var h := RuleTestHarness.new(42)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.resource_pool = 0
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionNode.nest_lose_resources(&"inv_1", 1))
	return inv.resource_pool == 0 and not h.ctx.composition.last_step_created()


func _test_seq_eff_heal() -> bool:
	var h := RuleTestHarness.new(42)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.damage_taken = 2
	inv.horror_taken = 1
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(
		CompositionNode.seq(
			[
				CompositionNode.nest_heal(&"inv_1", &"damage", 1),
				CompositionNode.nest_heal(&"inv_1", &"horror", 1),
			]
		)
	)
	return (
		inv.damage_taken == 1
		and inv.horror_taken == 0
		and _sequence_kind_count(h, &"heal") >= 2
	)


func _test_seq_eff_place_doom_source() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_a", &"test_loc")
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(
		CompositionNode.nest_place_doom(&"inv_1", &"enemy_a", &"source")
	)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_a")
	return (
		enemy != null
		and enemy.doom == 1
		and _sequence_kind_count(h, &"place_doom") > 0
	)


func _test_seq_eff_discard_from_hand() -> bool:
	## from=hand 走统一 seq.effect.discard_card（不再有平行 discard_from_hand flow）。
	var h := RuleTestHarness.new(42)
	if not h.ctx.sequence_catalog.has_flow(&"seq.effect.discard_card"):
		return false
	if h.ctx.sequence_catalog.has_flow(&"seq.effect.discard_from_hand"):
		return false
	GameBootstrap.add_skill_card_to_hand(h.ctx, &"inv_1", AhcEnums.SkillType.WILLPOWER)
	GameBootstrap.add_skill_card_to_hand(h.ctx, &"inv_1", AhcEnums.SkillType.INTELLECT)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	if inv == null or inv.hand.size() != 2:
		return false
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionNode.nest_discard_from_hand(&"inv_1", 1, &"random"))
	return inv.hand.size() == 1 and _sequence_kind_count(h, &"discard_card") > 0


func _test_seq_eff_attach_controller_location() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.ctx.sequence_catalog.has_flow(&"seq.effect.attach"):
		return false
	GameBootstrap.setup_test_location(h.ctx, &"test_loc")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	var card_id := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_attach_flood", [])
	var card := h.ctx.state.registry.get_card(card_id)
	if card == null:
		return false
	card.zone = AhcEnums.Zone.LIMBO
	card.controller_id = &"inv_1"
	h.ctx.state.encounter_deck.erase(card_id)
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(
		CompositionNode.nest_attach(card_id, &"inv_1", &"controller_location")
	)
	var host := h.ctx.state.registry.get_card(&"test_loc")
	return (
		card.zone == AhcEnums.Zone.ATTACHED
		and host != null
		and not host.attachments.is_empty()
		and card.attached_to == host.id
		and _sequence_kind_count(h, &"attach") > 0
	)


func _test_seq_eff_deal_damage_at_location() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.ctx.sequence_catalog.has_flow(&"seq.effect.deal"):
		return false
	GameBootstrap.setup_test_location(h.ctx, &"test_loc")
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	inv1.location_tag = &"test_loc"
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	if inv2 == null:
		return false
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(
		CompositionNode.nest_deal_damage(
			&"inv_1", 1, &"each_at_controller_location"
		)
	)
	return (
		inv1.damage_taken == 1
		and inv2.damage_taken == 1
		and _sequence_kind_count(h, &"damage") > 0
	)


func _test_adb_compile_12130_skill_choice() -> bool:
	## 应展尽展：pick_option → nest_skill_test(flow_id) + 单次 st7。
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12130")
	if compiled.size() != 1:
		return false
	var entry: Dictionary = compiled[0]
	var steps: Variant = entry.get("steps", [])
	if not steps is Array or (steps as Array).size() != 2:
		return false
	var pick: Dictionary = steps[0] as Dictionary
	var test: Dictionary = steps[1] as Dictionary
	var st7: Dictionary = test.get("st7", {})
	var each: Dictionary = st7.get("on_fail_by_each", {})
	return (
		CardRegistry.has_revelation(&"12130")
		and entry.get("template", "") == "seq"
		and entry.get("translation", "") == "full_expand"
		and pick.get("template", "") == "pick_option"
		and (pick.get("options", []) as Array) == ["willpower", "agility"]
		and test.get("template", "") == "nest_skill_test"
		and test.get("flow_id", "") == "seq.skill_test"
		and test.get("skill", "") == "memory:picked_skill"
		and int(test.get("difficulty", 0)) == 3
		and each.get("template", "") == "take_damage"
		and each.get("flow_id", "") == "seq.effect.deal.assignable"
		and each.get("kind", "") == "damage"
		and each.get("target", "") == "controller"
		and test.get("investigator", "") == "controller"
	)


func _test_adb_compile_12127() -> bool:
	## 应展尽展：PI 只选技能；nest seq.skill_test；fail 叶带 flow_id。
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12127")
	if compiled.size() != 1:
		return false
	var entry: Dictionary = compiled[0]
	var steps: Variant = entry.get("steps", [])
	if not steps is Array or (steps as Array).size() != 2:
		return false
	var pick: Dictionary = steps[0] as Dictionary
	var test: Dictionary = steps[1] as Dictionary
	var st7: Dictionary = test.get("st7", {})
	var on_fail: Dictionary = st7.get("on_fail", {})
	var fail_steps: Variant = on_fail.get("steps", [])
	return (
		CardRegistry.has_revelation(&"12127")
		and entry.get("template", "") == "seq"
		and entry.get("translation", "") == "full_expand"
		and pick.get("template", "") == "pick_option"
		and pick.get("prompt_id", "") == "skill_test:willpower_or_intellect"
		and (pick.get("options", []) as Array) == ["willpower", "intellect"]
		and test.get("template", "") == "nest_skill_test"
		and test.get("flow_id", "") == "seq.skill_test"
		and test.get("skill", "") == "memory:picked_skill"
		and test.get("difficulty_source", "") == "hand_count"
		and test.get("investigator", "") == "controller"
		and fail_steps is Array
		and (fail_steps as Array).size() == 2
		and ((fail_steps as Array)[0] as Dictionary).get("flow_id", "")
			== "seq.effect.deal.assignable"
		and ((fail_steps as Array)[0] as Dictionary).get("kind", "") == "damage"
		and ((fail_steps as Array)[0] as Dictionary).get("target", "") == "controller"
		and ((fail_steps as Array)[1] as Dictionary).get("flow_id", "")
			== "seq.effect.discard_card"
		and ((fail_steps as Array)[1] as Dictionary).get("from", "") == "hand"
		and ((fail_steps as Array)[1] as Dictionary).get("investigator", "") == "controller"
	)


func _test_enc_12127_fail() -> bool:
	## 手牌 2 → 难度 2；willpower 低 + 0 token → 失败：1 伤 + 随机弃 1。
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.skill_willpower = 1
	inv.skill_intellect = 5
	inv.damage_taken = 0
	GameBootstrap.add_skill_card_to_hand(h.ctx, &"inv_1", AhcEnums.SkillType.COMBAT)
	GameBootstrap.add_skill_card_to_hand(h.ctx, &"inv_1", AhcEnums.SkillType.AGILITY)
	var hand_before := inv.hand.size()
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0)])
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([{"pick": &"willpower"}])
	var card_id := _adb_add_encounter_treachery_to_deck(h, &"12127")
	h.ctx.mutator.enter_limbo(card_id, &"inv_1")
	if not h.resolve_encounter_revelation(card_id):
		return false
	inv = h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		inv.damage_taken == 1
		and inv.hand.size() == hand_before - 1
		and h.ctx.composition.last_skill_test_fail_by() >= 1
	)


func _test_adb_compile_12164_lose_or_attack() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12164")
	if compiled.size() != 1:
		return false
	var entry: Dictionary = compiled[0]
	var steps: Variant = entry.get("steps", [])
	if not steps is Array or (steps as Array).size() != 2:
		return false
	var then_entry: Dictionary = (steps[1] as Dictionary).get("then", {})
	return (
		entry.get("template", "") == "seq"
		and (steps[0] as Dictionary).get("template", "") == "lose_resources"
		and then_entry.get("template", "") == "nest_enemy_attack"
		and then_entry.get("enemy", "") == "source"
	)


func _test_adb_compile_12188_place_doom() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12188")
	if compiled.is_empty():
		return false
	return (compiled[0] as Dictionary).get("template", "") == "place_doom_on_source"


func _test_adb_compile_12184_lose_action() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12184")
	if compiled.is_empty():
		return false
	var entry: Dictionary = compiled[0]
	return (
		entry.get("template", "") == "lose_action"
		and int(entry.get("amount", 0)) == 1
	)


func _test_adb_compile_12128_fail_by() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12128")
	if compiled.is_empty():
		return false
	var entry: Dictionary = compiled[0]
	var st7: Dictionary = entry.get("st7", {})
	var choice: Dictionary = st7.get("on_fail_by_each", {})
	var options: Variant = choice.get("options", [])
	return (
		entry.get("template", "") == "skill_test"
		and choice.get("template", "") == "choice_must"
		and options is Array
		and (options as Array).size() == 2
		and ((options as Array)[0] as Dictionary).get("template", "") == "discard_card"
		and ((options as Array)[0] as Dictionary).get("from", "") == "hand"
	)


func _test_adb_compile_12159_attach() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12159")
	if compiled.is_empty():
		return false
	var rev: Dictionary = compiled[0]
	return (
		CardRegistry.has_revelation(&"12159")
		and rev.get("register_as", "") == "revelation"
		and rev.get("template", "") == "attach_controller_location"
	)


func _test_adb_compile_12117_heal() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12117")
	if compiled.is_empty():
		return false
	var entry: Dictionary = compiled[0]
	var steps: Variant = entry.get("steps", [])
	return (
		entry.get("register_as", "") == "action"
		and entry.get("template", "") == "seq"
		and steps is Array
		and (steps as Array).size() == 2
		and ((steps as Array)[0] as Dictionary).get("template", "") == "heal"
		and ((steps as Array)[1] as Dictionary).get("kind", "") == "horror"
	)


func _test_adb_compile_12102_discard_action() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var compiled := CardRegistry.compiled_abilities(&"12102")
	var discard_action: Dictionary = {}
	for entry in compiled:
		if entry is Dictionary and (entry as Dictionary).get("template", "") == "discard_source":
			discard_action = entry as Dictionary
			break
	return (
		not discard_action.is_empty()
		and discard_action.get("register_as", "") == "action"
		and int(discard_action.get("action_cost", 0)) == 2
	)


func _test_adb_compile_12129_fire_forced() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12129")
	var forced: Dictionary = {}
	for entry in compiled:
		if entry is Dictionary and str((entry as Dictionary).get("register_as", "")) == "forced":
			forced = entry as Dictionary
			break
	return (
		CardRegistry.has_triggered(&"12129")
		and forced.get("template", "") == "deal_damage"
		and forced.get("match_kind", "") == "investigation_phase_ends"
		and str(forced.get("phase", "")).to_upper() == "WHEN"
		and forced.get("target", "") == "non_elite_with_health_at_attached_location"
	)


func _test_adb_compile_12106_parley() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12106")
	if compiled.is_empty():
		return false
	var entry: Dictionary = compiled[0]
	var types: Variant = entry.get("action_types", [])
	var st7: Dictionary = entry.get("st7", {})
	var on_ok: Dictionary = st7.get("on_success", {})
	return (
		entry.get("register_as", "") == "action"
		and entry.get("template", "") == "skill_test"
		and entry.get("skill", "") == "intellect"
		and int(entry.get("difficulty", 0)) == 2
		and int(entry.get("action_cost", 0)) == 1
		and types is Array
		and (types as Array).has("activate")
		and (types as Array).has("parley")
		and on_ok.get("template", "") == "discard_card"
		and on_ok.get("trait", "") == "Bystander"
		and on_ok.get("at", "") == "controller_location"
		and CardRegistry.compiled_abilities(&"12107").size() == 1
		and CardRegistry.compiled_abilities(&"12108").size() >= 1
	)


func _test_adb_parley_skips_aoo() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2, &"inv_1")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.threat_area.append(&"enemy_1")
	inv.actions_remaining = 2
	inv.damage_taken = 0
	var intent := InitiationIntent.action_ability(
		&"inv_1",
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				1,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE)
			),
		1,
		AhcEnums.ActionType.ACTIVATE,
		[AhcEnums.ActionType.ACTIVATE, AhcEnums.ActionType.PARLEY]
	)
	var res := h.ctx.initiation.initiate(intent, h.ctx)
	return (
		res.ok
		and inv.damage_taken == 0
		and int(res.get("aoo_attacks", 0)) == 0
		and inv.actions_remaining == 1
		and not intent.provokes_aoo
	)


func _test_adb_compile_12112() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12112")
	if compiled.size() < 2:
		return false
	var free_entry: Dictionary = {}
	var resign_entry: Dictionary = {}
	for entry in compiled:
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry
		match str(e.get("register_as", "")):
			"free":
				free_entry = e
			"action":
				resign_entry = e
	var types: Variant = resign_entry.get("action_types", [])
	var steps: Variant = free_entry.get("steps", [])
	var resign_steps: Variant = resign_entry.get("steps", [])
	if not resign_steps is Array or (resign_steps as Array).size() != 1:
		return false
	if not steps is Array or (steps as Array).size() != 2:
		return false
	if not types is Array:
		return false
	var r0: Dictionary = (resign_steps as Array)[0]
	return (
		str(resign_entry.get("template", "")) == "seq"
		and str(resign_entry.get("translation", "")) == "full_expand"
		and not resign_entry.has("provokes_aoo")
		and str(r0.get("template", "")) == "nest_resign"
		and str(r0.get("flow_id", "")) == "seq.effect.resign"
		and (types as Array).has("activate")
		and (types as Array).has("resign")
		and str(free_entry.get("template", "")) == "seq"
		and str(((steps as Array)[0] as Dictionary).get("template", "")) == "spend_clues_group"
		and str(((steps as Array)[1] as Dictionary).get("template", "")) == "deal_damage"
	)


func _test_adb_resign_inline_initiation() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_location(h.ctx, &"test_loc")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	inv.clues_on_card = 2
	inv.actions_remaining = 1
	var loc := h.ctx.state.registry.get_location(&"test_loc")
	var clues_before := loc.clues
	## nest seq.effect.resign 信封；经 seq.ability.resolve 装载（禁真空）。
	var body := CompositionNode.nest_resign(&"inv_1")
	if str(body.atom_name) != "nest_resign":
		return false
	if body.nest_flow_id != &"seq.effect.resign":
		return false
	var intent := InitiationIntent.action_ability(
		&"inv_1",
		body,
		1,
		AhcEnums.ActionType.ACTIVATE,
		[AhcEnums.ActionType.ACTIVATE, AhcEnums.ActionType.RESIGN]
	)
	var res := h.ctx.initiation.initiate(intent, h.ctx)
	return (
		res.ok
		and not intent.provokes_aoo
		and inv.resigned
		and inv.eliminated
		and inv.clues_on_card == 0
		and loc.clues == clues_before + 2
		and inv.actions_remaining == 0
		and h.ctx.sequence_catalog.has_flow(&"seq.ability.resolve")
		and h.ctx.sequence_catalog.has_flow(&"seq.effect.resign")
	)


func _test_adb_compile_12113() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12113")
	if compiled.is_empty():
		return false
	var entry: Dictionary = compiled[0]
	var types: Variant = entry.get("action_types", [])
	var steps: Variant = entry.get("steps", [])
	if not steps is Array or (steps as Array).size() != 5:
		return false
	var s0: Dictionary = (steps as Array)[0]
	var s1: Dictionary = (steps as Array)[1]
	var s2: Dictionary = (steps as Array)[2]
	var s3: Dictionary = (steps as Array)[3]
	var s4: Dictionary = (steps as Array)[4]
	if not types is Array:
		return false
	return (
		str(entry.get("register_as", "")) == "action"
		and str(entry.get("template", "")) == "seq"
		and str(entry.get("translation", "")) == "full_expand"
		and str(entry.get("status", "")) == "full"
		and int(entry.get("action_cost", 0)) == 1
		and (types as Array).has("activate")
		and (types as Array).has("engage")
		and not entry.has("provokes_aoo")
		and str(s0.get("template", "")) == "no_provoke_aoo"
		and str(s1.get("template", "")) == "pick_target"
		and str(s1.get("filter", "")) == "enemy_at_connecting"
		and str(s2.get("template", "")) == "suppress_auto_engage"
		and str(s3.get("template", "")) == "nest_enemy_move_to"
		and str(s3.get("flow_id", "")) == "seq.effect.move"
		and str(s4.get("template", "")) == "nest_engage"
		and str(s4.get("flow_id", "")) == "seq.engage"
		and CardRegistry.has_triggered(&"12113")
	)


func _test_adb_engage_types_provoke_aoo() -> bool:
	## Engage 不在借机豁免类型内（仅 Fight/Evade/Parley/Resign）。
	if not AttackOfOpportunityResolver.provokes_for_types(
		[AhcEnums.ActionType.ACTIVATE, AhcEnums.ActionType.ENGAGE]
	):
		return false
	if AttackOfOpportunityResolver.provokes_for_types(
		[AhcEnums.ActionType.ACTIVATE, AhcEnums.ActionType.FIGHT]
	):
		return false
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2, &"inv_1")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.threat_area.append(&"enemy_1")
	inv.actions_remaining = 2
	inv.damage_taken = 0
	var intent := InitiationIntent.action_ability(
		&"inv_1",
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				1,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE)
			),
		1,
		AhcEnums.ActionType.ACTIVATE,
		[AhcEnums.ActionType.ACTIVATE, AhcEnums.ActionType.ENGAGE]
	)
	var res := h.ctx.initiation.initiate(intent, h.ctx)
	return (
		res.ok
		and intent.provokes_aoo
		and inv.damage_taken == 1
		and int(res.get("aoo_attacks", 0)) == 1
		and inv.actions_remaining == 1
	)


func _test_adb_12113_engage_connecting() -> bool:
	## 12113：Engage 类型会借机；限制类 SKIP_AOO 在 INIT_2B 被原流程读取后分支。
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_location(h.ctx, &"loc_b")
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"loc_b")
	## 本地点已交战敌人：无限制时应受伤；读取到 SKIP_AOO 则原流程不跑借机。
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_here", &"test_loc", 2, 2, &"inv_1")
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_conn", &"loc_b", 2, 2)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	inv.threat_area.append(&"enemy_here")
	inv.actions_remaining = 2
	inv.damage_taken = 0
	var loc_card_id := ScenarioLayoutSetup.materialize_card(
		h.ctx, &"12113", AhcEnums.Zone.LOCATION_AREA, &"loc", &"test_loc"
	)
	h.ctx.triggered_abilities.install_card(loc_card_id, loc_card_id)
	if not h.ctx.framework.waiting_player_window:
		h.ctx.framework.open_player_window(AhcEnums.PlayerWindow.PW_INV_BEFORE_ACTION)
	var listed := h.ctx.triggered_abilities.list_action_abilities(&"inv_1")
	if listed.is_empty():
		return false
	var desc: TriggeredAbilityDescriptor = listed[0]
	## 类型层仍会借机；豁免靠限制类读取分支，不是 provokes_aoo override / Cancel。
	if not desc.provokes_aoo():
		return false
	var result := h.ctx.triggered_abilities.activate_action(desc.id)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_conn")
	return (
		bool(result.get("ok", false))
		and inv.damage_taken == 0
		and int(result.get("aoo_attacks", 0)) == 0
		and not h.ctx.registrations.has_skip_aoo(&"inv_1")
		and enemy != null
		and enemy.location_tag == &"test_loc"
		and enemy.engaged_with == &"inv_1"
		and inv.threat_area.has(&"enemy_conn")
		and inv.actions_remaining == 1
	)


func _test_adb_suppress_auto_engage_explicit() -> bool:
	## 移入仍走 auto-engage 入口；SUPPRESS_AUTO_ENGAGE 读取后跳过；明示交战绑定 controller。
	## 创建须经 seq.effect.register（非真空 Store）。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_location(h.ctx, &"loc_b")
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"loc_b")
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_conn", &"loc_b", 2, 2)
	## 第二调查员同地点：若走 Prey/Lead 自动交战可能交战到他人。
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	inv.actions_remaining = 2
	var body := CompositionNode.seq([
		CompositionNode.suppress_auto_engage(&"inv_1", &"enemy_conn"),
		CompositionNode.nest_enemy_move_to(
			&"inv_1", &"enemy_conn", &"test_loc", true
		),
		CompositionNode.nest_engage(&"inv_1", &"enemy_conn", &"effect"),
	])
	var intent := InitiationIntent.action_ability(
		&"inv_1", body, 1, AhcEnums.ActionType.ACTIVATE,
		[AhcEnums.ActionType.ACTIVATE, AhcEnums.ActionType.ENGAGE]
	)
	var res := h.ctx.initiation.initiate(intent, h.ctx)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_conn")
	return (
		res.ok
		and enemy != null
		and enemy.location_tag == &"test_loc"
		and enemy.engaged_with == &"inv_1"
		and inv.threat_area.has(&"enemy_conn")
		and not h.ctx.registrations.has_suppress_auto_engage(&"enemy_conn")
		and _sequence_kind_count(h, &"effect_register") > 0
	)


func _test_adb_selection_filter_ready() -> bool:
	## CandidateFilter：connecting + exhausted=false；横置敌不入选；bind → Memory。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_location(h.ctx, &"loc_b")
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"loc_b")
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_ready", &"loc_b", 2, 2)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_exh", &"loc_b", 2, 2)
	var exh := h.ctx.state.registry.get_enemy(&"enemy_exh")
	exh.exhausted = true
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	var filter := CandidateFilter.from_variant({
		"preset": "enemy_at_connecting",
		"exhausted": false,
	})
	var candidates := CandidateEnumerator.enumerate(filter, h.ctx, &"inv_1")
	if candidates.size() != 1 or candidates[0] != &"enemy_ready":
		return false
	var spec := SelectionSpec.pick_entity(filter, &"pick:ready_conn", &"picked_enemy")
	var body := CompositionNode.seq([
		CompositionNode.select_entities(&"inv_1", spec),
	])
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(body)
	var mem: Variant = h.ctx.memory.get_referent(&"inv_1", &"picked_enemy")
	return mem != null and StringName(str(mem)) == &"enemy_ready"


func _test_adb_viability_exhaust_enemy() -> bool:
	## V：不靠 filter.exhausted；已横置敌 dry-run 无 CREATED → 不入合法集；ready 被横置。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_ready", &"test_loc", 2, 2)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_exh", &"test_loc", 2, 2)
	var exh := h.ctx.state.registry.get_enemy(&"enemy_exh")
	exh.exhausted = true
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	var filter := CandidateFilter.from_variant({
		"preset": "enemy_at_controller_location",
	})
	var spec := SelectionSpec.pick_entity(filter, &"pick:exhaust", &"picked_enemy")
	var body := CompositionNode.seq([
		CompositionNode.select_entities(&"inv_1", spec),
		CompositionNode.exhaust_enemy(&"inv_1", &"memory:picked_enemy"),
	])
	var helper := CompositionTestHelper.new(h.ctx)
	if not helper.dry_run(body):
		return false
	helper.execute(body)
	var mem: Variant = h.ctx.memory.get_referent(&"inv_1", &"picked_enemy")
	var ready := h.ctx.state.registry.get_enemy(&"enemy_ready")
	return (
		mem != null
		and StringName(str(mem)) == &"enemy_ready"
		and ready != null
		and ready.exhausted
		and exh.exhausted
	)


func _test_adb_viability_exhaust_all_exhausted() -> bool:
	## 全部已横置 → V 后空集 → select fizzle；L7 无 CREATED。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_a", &"test_loc", 2, 2)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_b", &"test_loc", 2, 2)
	h.ctx.state.registry.get_enemy(&"enemy_a").exhausted = true
	h.ctx.state.registry.get_enemy(&"enemy_b").exhausted = true
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	var filter := CandidateFilter.from_variant({
		"preset": "enemy_at_controller_location",
	})
	var spec := SelectionSpec.pick_entity(filter, &"pick:exhaust", &"picked_enemy")
	var body := CompositionNode.seq([
		CompositionNode.select_entities(&"inv_1", spec),
		CompositionNode.exhaust_enemy(&"inv_1", &"memory:picked_enemy"),
	])
	var helper := CompositionTestHelper.new(h.ctx)
	if helper.dry_run(body):
		return false
	helper.execute(body)
	var mem: Variant = h.ctx.memory.get_referent(&"inv_1", &"picked_enemy")
	return mem == null


func _test_adb_preds_fight_le() -> bool:
	## N：fight ≤ 2 只保留弱敌。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_weak", &"test_loc", 2, 2)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_strong", &"test_loc", 4, 2)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	var filter := CandidateFilter.from_variant({
		"preset": "enemy_at_controller_location",
		"preds": [
			{"on": "candidate", "field": "fight", "op": "le", "value": 2},
		],
	})
	var candidates := CandidateEnumerator.enumerate(filter, h.ctx, &"inv_1")
	return candidates.size() == 1 and candidates[0] == &"enemy_weak"


func _test_adb_preds_controller_resources() -> bool:
	## N：controller.resources ≥ 1 才过；0 资源时全集剔除。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	inv.resource_pool = 0
	var filter := CandidateFilter.from_variant({
		"preset": "enemy_at_controller_location",
		"preds": [
			{"on": "controller", "field": "resources", "op": "ge", "value": 1},
		],
	})
	var empty := CandidateEnumerator.enumerate(filter, h.ctx, &"inv_1")
	if not empty.is_empty():
		return false
	inv.resource_pool = 2
	var ok := CandidateEnumerator.enumerate(filter, h.ctx, &"inv_1")
	return ok.size() == 1 and ok[0] == &"enemy_1"


func _test_adb_pick_multi_default() -> bool:
	## pick_multi max=2：headless 默认取前 2；bind entity_list。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_a", &"test_loc", 2, 2)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_b", &"test_loc", 2, 2)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_c", &"test_loc", 2, 2)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	var body := CompositionNode.pick_multi(
		&"inv_1",
		&"enemy_at_controller_location",
		1,
		2,
		&"pick:multi",
		&"picked_enemies"
	)
	CompositionTestHelper.new(h.ctx).execute(body)
	var mem: Variant = h.ctx.memory.get_referent(&"inv_1", &"picked_enemies")
	if not mem is Array:
		return false
	var list := mem as Array
	return list.size() == 2 and list.has(&"enemy_a") and list.has(&"enemy_b")


func _test_adb_pick_multi_scripting() -> bool:
	## Scripting 指定子集；截断遵守 max_picks。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_a", &"test_loc", 2, 2)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_b", &"test_loc", 2, 2)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_c", &"test_loc", 2, 2)
	h.ctx.state.registry.get_investigator(&"inv_1").location_tag = &"test_loc"
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"pick:multi", "pick": [&"enemy_c", &"enemy_a"]},
	])
	var body := CompositionNode.pick_multi(
		&"inv_1", &"enemy_at_controller_location", 1, 2, &"pick:multi", &"picked_enemies"
	)
	CompositionTestHelper.new(h.ctx).execute(body)
	var mem: Variant = h.ctx.memory.get_referent(&"inv_1", &"picked_enemies")
	if not mem is Array:
		return false
	var list := mem as Array
	return list.size() == 2 and list[0] == &"enemy_c" and list[1] == &"enemy_a"


func _test_adb_pick_multi_for_each() -> bool:
	## pick_multi → for_each_memory → exhaust：两敌均横置；V 剔除已横置。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_ready_a", &"test_loc", 2, 2)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_ready_b", &"test_loc", 2, 2)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_exh", &"test_loc", 2, 2)
	h.ctx.state.registry.get_enemy(&"enemy_exh").exhausted = true
	h.ctx.state.registry.get_investigator(&"inv_1").location_tag = &"test_loc"
	var pick := CompositionNode.pick_multi(
		&"inv_1", &"enemy_at_controller_location", 1, 2, &"pick:multi", &"picked_enemies"
	)
	var body := CompositionNode.seq([
		pick,
		CompositionNode.for_each_memory(
			&"inv_1",
			&"picked_enemies",
			CompositionNode.exhaust_enemy(&"inv_1", &"memory:picked_enemy"),
			&"picked_enemy"
		),
	])
	var helper := CompositionTestHelper.new(h.ctx)
	if not helper.dry_run(body):
		return false
	helper.execute(body)
	var a := h.ctx.state.registry.get_enemy(&"enemy_ready_a")
	var b := h.ctx.state.registry.get_enemy(&"enemy_ready_b")
	var exh := h.ctx.state.registry.get_enemy(&"enemy_exh")
	var mem: Variant = h.ctx.memory.get_referent(&"inv_1", &"picked_enemies")
	return (
		a != null and a.exhausted
		and b != null and b.exhausted
		and exh != null and exh.exhausted
		and mem is Array
		and (mem as Array).size() == 2
		and not (mem as Array).has(&"enemy_exh")
	)


func _test_adb_pick_multi_min_fizzle() -> bool:
	## exactly 2 但仅 1 合法候选 → fizzle，不写 Memory。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_only", &"test_loc", 2, 2)
	h.ctx.state.registry.get_investigator(&"inv_1").location_tag = &"test_loc"
	var body := CompositionNode.pick_multi(
		&"inv_1", &"enemy_at_controller_location", 2, 2, &"pick:multi", &"picked_enemies"
	)
	var helper := CompositionTestHelper.new(h.ctx)
	if helper.dry_run(body):
		return false
	helper.execute(body)
	return h.ctx.memory.get_referent(&"inv_1", &"picked_enemies") == null


func _test_adb_pick_multi_compiler() -> bool:
	var bind := AbilityBindContext.new()
	bind.controller_id = &"inv_1"
	var node := ArkhamDbAbilityCompiler.build_composition(
		"pick_multi",
		{
			"filter": "enemy_at_controller_location",
			"min": 1,
			"max": 3,
			"prompt_id": "pick:multi",
			"memory_key": "picked_enemies",
		},
		bind
	)
	if node == null or node.selection_spec == null:
		return false
	var spec: SelectionSpec = node.selection_spec
	var each := ArkhamDbAbilityCompiler.build_composition(
		"for_each_memory",
		{
			"memory_key": "picked_enemies",
			"each_key": "picked_enemy",
			"body": {"template": "exhaust_enemy", "enemy": "memory:picked_enemy"},
		},
		bind
	)
	return (
		node.atom_name == &"select"
		and spec.choice_kind == AhcEnums.ChoiceKind.PICK_MULTI
		and spec.bind_shape == &"entity_list"
		and spec.min_picks == 1
		and spec.max_picks == 3
		and each != null
		and each.kind == AhcEnums.CompositionNodeKind.FOR_EACH
		and each.for_each_source == &"memory_list"
	)


func _test_adb_skip_aoo_buff_consume() -> bool:
	## 限制类 SKIP_AOO：行动开始经 seq.effect.register；INIT_2B 原流程读取后分支。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2, &"inv_1")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.threat_area.append(&"enemy_1")
	inv.actions_remaining = 2
	inv.damage_taken = 0
	var body := CompositionNode.seq([
		CompositionNode.no_provoke_aoo(&"inv_1"),
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				1,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE)
			),
	])
	var intent := InitiationIntent.action_ability(
		&"inv_1",
		body,
		1,
		AhcEnums.ActionType.ACTIVATE,
		[AhcEnums.ActionType.ACTIVATE, AhcEnums.ActionType.ENGAGE]
	)
	if not intent.provokes_aoo:
		return false
	var res := h.ctx.initiation.initiate(intent, h.ctx)
	return (
		res.ok
		and inv.damage_taken == 0
		and int(res.get("aoo_attacks", 0)) == 0
		and not h.ctx.registrations.has_skip_aoo(&"inv_1")
		and inv.actions_remaining == 1
		and _sequence_kind_count(h, &"effect_register") > 0
	)


func _test_adb_compile_12118() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12118")
	if compiled.is_empty():
		return false
	var entry: Dictionary = compiled[0]
	return (
		entry.get("register_as", "") == "forced"
		and entry.get("template", "") == "discard_card"
		and entry.get("from", "") == "hand"
		and entry.get("flow_id", "") == "seq.effect.discard_card"
		and entry.get("mode", "") == "choose"
		and int(entry.get("amount", 0)) == 1
		and entry.get("investigator", "") == "controller"
		and entry.get("match_kind", "") == "discover_clue"
		and str(entry.get("phase", "")).to_upper() == "AFTER"
		and entry.get("status", "") == "full"
		and CardRegistry.has_triggered(&"12118")
	)


func _test_adb_compile_12119() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12119")
	if compiled.is_empty():
		return false
	var entry: Dictionary = compiled[0]
	return (
		entry.get("register_as", "") == "reaction"
		and entry.get("template", "") == "draw"
		and int(entry.get("amount", 0)) == 1
		and entry.get("match_kind", "") == "discover_clue"
		and str(entry.get("phase", "")).to_upper() == "AFTER"
		and CardRegistry.has_triggered(&"12119")
	)


func _test_adb_compile_12120() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12120")
	if compiled.is_empty():
		return false
	var entry: Dictionary = compiled[0]
	var types: Variant = entry.get("action_types", [])
	return (
		entry.get("register_as", "") == "action"
		and entry.get("template", "") == "draw"
		and int(entry.get("amount", 0)) == 3
		and int(entry.get("action_cost", 0)) == 2
		and types is Array
		and (types as Array).has("activate")
		and CardRegistry.has_triggered(&"12120")
	)


func _test_adb_12120_draw_three() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	if not h.prepare_action_phase():
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	inv.actions_remaining = 3
	for _i in 5:
		GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var hand_before := inv.hand.size()
	var loc_card_id := ScenarioLayoutSetup.materialize_card(
		h.ctx, &"12120", AhcEnums.Zone.LOCATION_AREA, &"loc", &"test_loc"
	)
	h.ctx.triggered_abilities.install_card(loc_card_id, loc_card_id)
	if not h.ctx.framework.waiting_player_window:
		h.ctx.framework.open_player_window(AhcEnums.PlayerWindow.PW_INV_BEFORE_ACTION)
	var listed := h.ctx.triggered_abilities.list_action_abilities(&"inv_1")
	if listed.is_empty():
		return false
	var result := h.ctx.triggered_abilities.activate_action(listed[0].id)
	return (
		bool(result.get("ok", false))
		and inv.hand.size() == hand_before + 3
		and inv.actions_remaining == 1
	)


func _test_adb_compile_12116() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12116")
	if compiled.is_empty():
		return false
	var entry: Dictionary = compiled[0]
	var steps: Variant = entry.get("steps", [])
	if not steps is Array or (steps as Array).size() != 2:
		return false
	var step0: Dictionary = steps[0]
	var step1: Dictionary = steps[1]
	return (
		entry.get("register_as", "") == "free"
		and entry.get("template", "") == "seq"
		and entry.get("condition", "") == "investigators_in_game_1_or_2"
		and entry.get("window", "") == "during_your_turn"
		and step0.get("template", "") == "pick_target"
		and step0.get("filter", "") == "location_connecting"
		and step1.get("template", "") == "nest_move_to"
		and CardRegistry.has_triggered(&"12116")
	)


func _test_adb_compile_12132() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12132")
	if compiled.is_empty():
		return false
	var entry: Dictionary = compiled[0]
	return (
		entry.get("register_as", "") == "forced"
		and entry.get("template", "") == "take_horror"
		and entry.get("target", "") == "each_at_source_location"
		and entry.get("match_kind", "") == "enemy_defeated"
		and str(entry.get("phase", "")).to_upper() == "WHEN"
		and entry.get("status", "") == "full"
		and CardRegistry.has_triggered(&"12132")
	)


func _test_adb_12132_defeat_horror() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	if not h.prepare_action_phase():
		return false
	if not h.ctx.sequence_catalog.has_flow(&"seq.effect.defeat"):
		return false
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	inv1.location_tag = &"test_loc"
	inv1.horror_taken = 0
	inv2.horror_taken = 0
	var enemy_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"12132",
		{"enemy": {"fight": 1, "evade": 1, "health": 1, "damage": 1, "horror": 0}}
	)
	var spawn := h.ctx.enemy.spawn_at_location(h.ctx, enemy_id, &"test_loc")
	if not spawn.get("ok", false):
		return false
	## 致死伤 → defeat → Forced WHEN 同地点各 1 恐惧。
	var defeat := EnemyDefeatResolver.deal_damage(h.ctx, enemy_id, 1)
	return (
		bool(defeat.get("defeated", false))
		and inv1.horror_taken == 1
		and inv2.horror_taken == 1
		and h.ctx.state.registry.get_enemy(enemy_id) == null
	)


func _test_adb_compile_12122() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var compiled := CardRegistry.compiled_abilities(&"12122")
	if compiled.is_empty():
		return false
	var entry: Dictionary = compiled[0]
	return (
		entry.get("register_as", "") == "forced"
		and entry.get("template", "") == "discard_card"
		and entry.get("at", "") == "controlled_assets"
		and entry.get("match_kind", "") == "enemy_attack"
		and str(entry.get("phase", "")).to_upper() == "AFTER"
		and entry.get("status", "") == "full"
		and CardRegistry.has_triggered(&"12122")
	)


func _test_adb_12122_discard_asset() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	if not h.prepare_action_phase():
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	inv.damage_taken = 0
	## 控制区放一张 asset。
	var asset_id := h.ctx.state.registry.allocate_instance_id(&"card")
	CardRegistry.register_definition(&"test_asset_122", {"card_type": &"asset"})
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, asset_id, &"test_asset_122")
	var asset := CardInstance.new()
	asset.id = eid
	asset.owner_id = &"inv_1"
	asset.controller_id = &"inv_1"
	asset.zone = AhcEnums.Zone.PLAY_AREA
	h.ctx.state.registry.register_card(asset)
	inv.play_area.append(asset_id)
	var enemy_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"12122",
		{"enemy": {"fight": 2, "evade": 2, "health": 2, "damage": 1, "horror": 0}}
	)
	var spawn := h.ctx.enemy.spawn_engaged(h.ctx, enemy_id, &"inv_1")
	if not spawn.get("ok", false):
		return false
	h.ctx.enemy_phase.run_phase_attacks(h.ctx, &"inv_1")
	var asset_card := h.ctx.state.registry.get_card(asset_id)
	return (
		inv.damage_taken == 1
		and not inv.play_area.has(asset_id)
		and asset_card != null
		and asset_card.zone == AhcEnums.Zone.DISCARD
		and inv.discard.has(asset_id)
	)


func _test_seq_eff_discard_bystander() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	if CardRegistry.title(&"12123") != "Bystander":
		return false
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_location(h.ctx, &"test_loc")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	var enemy_id := _spawn_enemy_at(
		h,
		&"12123",
		&"test_loc",
		{"enemy": {"fight": 1, "evade": 1, "health": 1}}
	)
	if enemy_id == &"" or CardRegistry.title(&"12123") != "Bystander":
		return false
	var result := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.discard_card",
		{
			"controller_id": &"inv_1",
			"trait": &"Bystander",
			"at": &"controller_location",
			"mode": &"choose",
		}
	)
	return (
		bool(result.get("ok", false))
		and h.ctx.state.registry.get_enemy(enemy_id) == null
		and h.ctx.state.encounter_discard.has(enemy_id)
	)


func _test_adb_12102_activate_action_discard() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	if not h.prepare_action_phase():
		return false
	var card_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"12102")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"inv_1"
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.HAND
	h.ctx.state.registry.register_card(card)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.hand.append(card_id)
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionNode.enter_threat_area(card_id, &"inv_1"))
	if not inv.threat_area.has(card_id):
		return false
	if not h.ctx.framework.waiting_player_window:
		h.ctx.framework.open_player_window(AhcEnums.PlayerWindow.PW_INV_BEFORE_ACTION)
	inv.actions_remaining = 3
	var listed := h.ctx.triggered_abilities.list_action_abilities(&"inv_1")
	if listed.is_empty():
		return false
	var result := h.ctx.triggered_abilities.activate_action(listed[0].id)
	return (
		bool(result.get("ok", false))
		and not inv.threat_area.has(card_id)
		and inv.discard.has(card_id)
		and card.zone == AhcEnums.Zone.DISCARD
		and inv.actions_remaining == 1
		and h.ctx.triggered_abilities.list_action_abilities(&"inv_1").is_empty()
	)


func _test_adb_12129_fire_forced_phase_ends() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	if not h.ctx.sequence_catalog.has_flow(PhaseBoundaryFlow.FLOW):
		return false
	GameBootstrap.setup_test_location(h.ctx, &"test_loc")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	var fire_id := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"12129", [])
	h.ctx.state.encounter_deck.erase(fire_id)
	var fire := h.ctx.state.registry.get_card(fire_id)
	fire.zone = AhcEnums.Zone.LIMBO
	fire.controller_id = &"inv_1"
	if not EncounterAttachment.attach_limbo_to_location(h.ctx, fire_id, &"test_loc"):
		return false
	h.ctx.triggered_abilities.install_card(&"inv_1", fire_id)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_fire_tgt", &"test_loc", 2, 2)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_fire_tgt")
	if enemy == null:
		return false
	enemy.health = 3
	var horror_before := inv.horror_taken
	var dmg_before := inv.damage_taken
	var result := h.ctx.sequence_catalog.run(
		h.ctx,
		PhaseBoundaryFlow.FLOW,
		{
			"phase": PhaseBoundaryFlow.PHASE_INVESTIGATION,
			"boundary": PhaseBoundaryFlow.BOUNDARY_ENDS,
		}
	)
	return (
		bool(result.get("ok", false))
		and inv.damage_taken == dmg_before + 1
		and inv.horror_taken == horror_before
		and enemy.damage == 1
		and h.ctx.state.registry.get_enemy(&"enemy_fire_tgt") != null
	)


func _test_seq_eff_deal_damage_attached() -> bool:
	var h := RuleTestHarness.new(42)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.location_tag = &"test_loc"
	var fire_id := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_fire_attach", [])
	h.ctx.state.encounter_deck.erase(fire_id)
	var fire := h.ctx.state.registry.get_card(fire_id)
	fire.zone = AhcEnums.Zone.LIMBO
	if not EncounterAttachment.attach_limbo_to_location(h.ctx, fire_id, &"test_loc"):
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_a", &"test_loc")
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_a")
	if enemy == null:
		return false
	enemy.health = 3
	var result := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.deal",
		{
			"controller_id": &"inv_1",
			"source": fire_id,
			"card_id": fire_id,
			"kind": &"damage",
			"amount": 1,
			"target": &"non_elite_with_health_at_attached_location",
		}
	)
	return (
		bool(result.get("ok", false))
		and inv.damage_taken == 1
		and enemy.damage == 1
		and h.ctx.state.registry.get_enemy(&"enemy_a") != null
	)


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
	## 12179b：ArkhamDB JSON `hidden` 仅表示 b 面不进遭遇库列表，≠ 隐私（Hidden）关键词。
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	var def_id := &"12179b"
	var enemy := CardRegistry.enemy_stats(def_id)
	return (
		not CardRegistry.is_hidden(def_id)
		and not CardRegistry.has_keyword(def_id, &"hidden")
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


func _test_adb_prey_nearest_cultist() -> bool:
	ArkhamDbCardLoader.load_imported_file(
		"res://data/arkhamdb/imported/core_classic_slice.json"
	)
	var prey := CardRegistry.prey_spec(&"50026b")
	return (
		prey != null
		and prey.is_nearest_to_enemy_trait()
		and prey.nearest_enemy_trait == &"Cultist"
		and prey.exclude_self
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
	if not h.resolve_encounter_revelation(card_id):
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
			return CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.HORROR_TAKEN,
				3,
				MarkerSlot.supply(AhcEnums.MarkerKind.HORROR_TAKEN),
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.HORROR_TAKEN)
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
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.HORROR_TAKEN,
				1,
				MarkerSlot.supply(AhcEnums.MarkerKind.HORROR_TAKEN),
				MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.HORROR_TAKEN)
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


func _test_enc_surge_nests_keyword_seq() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.memory.clear_trace()
	GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_surge_a", [&"surge"])
	GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_plain_b", [])
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	if not res.get("ok", false) or int(res.get("surge_depth", 0)) != 1:
		return false
	var has_surge_seq := false
	for entry in h.ctx.memory.phase_trace:
		if str(entry).begins_with("RESOLVE:keyword_surge@"):
			has_surge_seq = true
			break
	return has_surge_seq


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
	DrawEncounterFlow.resolve_encounter_card_tail(h.ctx, &"inv_1", card_id)
	if not h.ctx.registrations.has_keyword_buff(card_id, &"surge"):
		return false
	var consumed := KeywordConsumer.evaluate_keyword(h.ctx, card_id, &"surge")
	return consumed and not h.ctx.registrations.has_keyword_buff(card_id, &"surge")


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
	if not h.resolve_encounter_revelation(card_id):
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
	if not h.resolve_encounter_revelation(card_id):
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


func _test_kw_occ_profile_table() -> bool:
	if KeywordProfileTable.profile_for(&"prey") != null:
		return false
	if KeywordProfileTable.profile_for(&"spawn") != null:
		return false
	var surge := KeywordProfileTable.profile_for(&"surge")
	if surge == null:
		return false
	if surge.buff_type != &"LISTENER":
		return false
	if surge.register_flow_id != KeywordProfileTable.FLOW_DRAW_ENCOUNTER:
		return false
	if surge.register_slot != KeywordProfileTable.SLOT_WHEN:
		return false
	if surge.unregister_flow_id != KeywordProfileTable.FLOW_DRAW_ENCOUNTER:
		return false
	if surge.unregister_slot != KeywordProfileTable.SLOT_AFTER:
		return false
	if surge.armed_zone != KeywordProfileTable.ZONE_LIMBO:
		return false
	var hunter := KeywordProfileTable.profile_for(&"hunter")
	if hunter == null or hunter.register_slot != KeywordProfileTable.SLOT_ENTER_PLAY:
		return false
	if hunter.unregister_slot != KeywordProfileTable.SLOT_LEAVE_PLAY:
		return false
	if hunter.armed_zone != KeywordProfileTable.ZONE_PLAY:
		return false
	if hunter.fire_flow_id != KeywordProfileTable.FLOW_ENEMY_3_2:
		return false
	if hunter.consume_slot != KeywordProfileTable.SLOT_ENEMY_3_2:
		return false
	if hunter.consume_flow_id != KeywordProfileTable.FLOW_KEYWORD_HUNTER:
		return false
	if hunter.fire_priority != 10 or hunter.category_tier != KeywordProfileTable.TIER_LISTENER:
		return false
	var patrol := KeywordProfileTable.profile_for(&"patrol")
	if patrol == null or patrol.fire_flow_id != KeywordProfileTable.FLOW_ENEMY_3_2:
		return false
	if patrol.fire_priority != 20:
		return false
	var enemy_3_2 := KeywordProfileTable.profiles_for_fire_anchor(
		KeywordProfileTable.FLOW_ENEMY_3_2, KeywordProfileTable.SLOT_ENEMY_3_2
	)
	if enemy_3_2.size() < 2:
		return false
	if enemy_3_2[0].keyword != &"hunter" or enemy_3_2[1].keyword != &"patrol":
		return false
	if KeywordProfileTable.profile_for(&"surge").category_tier != KeywordProfileTable.TIER_DELAYED:
		return false
	var massive := KeywordProfileTable.profile_for(&"massive")
	if massive == null or massive.fire_flow_id != KeywordProfileTable.FLOW_ENEMY_ATTACK:
		return false
	if massive.consume_slot != KeywordProfileTable.SLOT_ATTACK:
		return false
	if massive.consume_flow_id != KeywordProfileTable.FLOW_KEYWORD_MASSIVE:
		return false
	if massive.category_tier != KeywordProfileTable.TIER_REPLACE:
		return false
	var starting := KeywordProfileTable.profile_for(&"starting")
	if starting == null or starting.register_flow_id != KeywordProfileTable.FLOW_SETUP:
		return false
	if starting.armed_zone != KeywordProfileTable.ZONE_DECK:
		return false
	if starting.unregister_slot != KeywordProfileTable.SLOT_AFTER:
		return false
	var peril := KeywordProfileTable.profile_for(&"peril")
	if peril == null or peril.register_flow_id != KeywordProfileTable.FLOW_DRAW_ENCOUNTER:
		return false
	if peril.register_slot != KeywordProfileTable.SLOT_G2:
		return false
	if peril.unregister_slot != KeywordProfileTable.SLOT_G4:
		return false
	if peril.armed_zone != KeywordProfileTable.ZONE_LIMBO:
		return false
	var hidden := KeywordProfileTable.profile_for(&"hidden")
	if hidden == null or hidden.register_flow_id != KeywordProfileTable.FLOW_ENCOUNTER_REVELATION:
		return false
	if hidden.register_slot != KeywordProfileTable.SLOT_ENTER_HAND:
		return false
	if hidden.unregister_slot != KeywordProfileTable.SLOT_LEAVE_HAND:
		return false
	var bonded := KeywordProfileTable.profile_for(&"bonded")
	if bonded == null or bonded.armed_zone != KeywordProfileTable.ZONE_SET_ASIDE:
		return false
	var fast := KeywordProfileTable.profile_for(&"fast")
	if fast == null or fast.buff_type != KeywordProfileTable.BUFF_INITIATION:
		return false
	if fast.register_slot != &"":
		return false
	if fast.armed_zone != KeywordProfileTable.ZONE_HAND:
		return false
	for profile in KeywordProfileTable.all_profiles():
		if profile.buff_type != KeywordProfileTable.BUFF_LISTENER:
			continue
		if profile.register_slot == &"" or profile.unregister_slot == &"":
			return false
		if profile.armed_zone == &"":
			return false
	var enter_play := KeywordProfileTable.profiles_for_register(
		&"", KeywordProfileTable.SLOT_ENTER_PLAY
	)
	var hunter_in_enter := false
	var surge_in_enter := false
	var peril_in_enter := false
	for profile in enter_play:
		if profile.keyword == &"hunter":
			hunter_in_enter = true
		if profile.keyword == &"surge":
			surge_in_enter = true
		if profile.keyword == &"peril":
			peril_in_enter = true
	var peril_g2 := KeywordProfileTable.profiles_for_register(
		KeywordProfileTable.FLOW_DRAW_ENCOUNTER, KeywordProfileTable.SLOT_G2
	)
	var peril_on_g2 := false
	for profile in peril_g2:
		if profile.keyword == &"peril":
			peril_on_g2 = true
	return hunter_in_enter and not surge_in_enter and not peril_in_enter and peril_on_g2


func _kw_occ_bind(
	store: RegistrationStore,
	lifetime: AhcEnums.LifetimeKind,
	card_id: StringName
) -> StringName:
	var template := RegistrationTemplate.new()
	template.lifetime_kind = lifetime
	template.drawn_card_id = card_id
	template.buffs.append(
		BuffSpec.listener_buff(ListenerPayload.at_timing(&"kw_occ_dummy", null))
	)
	return store.register(template)


func _test_kw_occ_leave_play_scoped() -> bool:
	var h := RuleTestHarness.new(42)
	var store := h.ctx.registrations
	_kw_occ_bind(store, AhcEnums.LifetimeKind.WHILE_IN_PLAY, &"hunter_card")
	_kw_occ_bind(store, AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING, &"limbo_card")
	_kw_occ_bind(store, AhcEnums.LifetimeKind.WHILE_HIDDEN_IN_HAND, &"hand_card")
	_kw_occ_bind(store, AhcEnums.LifetimeKind.UNTIL_FIRED, &"delayed_card")
	_kw_occ_bind(store, AhcEnums.LifetimeKind.WHILE_IN_DECK, &"starting_card")
	_kw_occ_bind(store, AhcEnums.LifetimeKind.WHILE_SET_ASIDE, &"bonded_card")
	_kw_occ_bind(store, AhcEnums.LifetimeKind.DURATION, &"lasting_card")
	if store.count() != 7:
		return false
	store.on_card_leave_play(&"hunter_card")
	if store.count() != 6:
		return false
	store.on_card_leave_play(&"limbo_card")
	store.on_card_leave_play(&"hand_card")
	store.on_card_leave_play(&"starting_card")
	store.on_card_leave_play(&"bonded_card")
	return store.count() == 6


func _test_kw_occ_leave_hand_scoped() -> bool:
	var h := RuleTestHarness.new(42)
	var store := h.ctx.registrations
	_kw_occ_bind(store, AhcEnums.LifetimeKind.WHILE_IN_PLAY, &"asset_card")
	_kw_occ_bind(store, AhcEnums.LifetimeKind.WHILE_HIDDEN_IN_HAND, &"hidden_card")
	_kw_occ_bind(store, AhcEnums.LifetimeKind.WHILE_IN_HAND, &"hand_card")
	store.on_leave_hand(&"hidden_card")
	if store.count() != 2:
		return false
	store.on_leave_hand(&"hand_card")
	if store.count() != 1:
		return false
	store.on_leave_hand(&"asset_card")
	return store.count() == 1


func _test_kw_occ_peril_finalize() -> bool:
	var h := RuleTestHarness.new(42)
	var store := h.ctx.registrations
	store.register(RegistrationTemplate.peril_drawn_card_resolving(&"inv_1", &"treachery"))
	EncounterGainedKeyword.register_surge(h.ctx, &"treachery")
	_kw_occ_bind(store, AhcEnums.LifetimeKind.WHILE_IN_PLAY, &"hunter_card")
	if store.count() != 3:
		return false
	if not store.has_peril_for_drawn_card(&"treachery"):
		return false
	if not store.has_keyword_buff(&"treachery", &"surge"):
		return false
	store.on_card_leave_play(&"treachery")
	if store.count() != 3:
		return false
	store.on_drawn_card_finalize(&"treachery")
	if store.has_peril_for_drawn_card(&"treachery"):
		return false
	if not store.has_keyword_buff(&"treachery", &"surge"):
		return false
	store.on_leave_deck(&"starting_missing")
	store.on_leave_set_aside(&"bonded_missing")
	return store.count() == 2 and store.has_keyword_buff(&"treachery", &"surge")


func _test_kw_fast_play_form() -> bool:
	if KeywordProfileTable.play_form(false, false) != KeywordProfileTable.PLAY_ACTION:
		return false
	if KeywordProfileTable.play_form(false, true) != KeywordProfileTable.PLAY_ACTION:
		return false
	if KeywordProfileTable.play_form(true, false) != KeywordProfileTable.PLAY_FAST_WINDOW:
		return false
	if KeywordProfileTable.play_form(true, true) != KeywordProfileTable.PLAY_FAST_TIMING:
		return false
	var fast := KeywordProfileTable.profile_for(&"fast")
	return (
		fast != null
		and fast.buff_type == KeywordProfileTable.BUFF_INITIATION
		and fast.armed_zone == KeywordProfileTable.ZONE_HAND
	)


func _test_enc_revelation_nest() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.memory.clear_trace()
	CardRegistry.register_definition(&"enc_rev_horror", {"card_type": &"treachery"})
	CardRegistry.register_revelation(
		&"enc_rev_horror",
		&"revelation:0",
		func(bind: AbilityBindContext) -> CompositionNode:
			return CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.HORROR_TAKEN,
				1,
				MarkerSlot.supply(AhcEnums.MarkerKind.HORROR_TAKEN),
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.HORROR_TAKEN)
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
			return CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.HORROR_TAKEN,
				1,
				MarkerSlot.supply(AhcEnums.MarkerKind.HORROR_TAKEN),
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.HORROR_TAKEN)
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


func _test_wkn_enemy_weakness_encounter_package() -> bool:
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


func _test_enc_drawn_location_into_play() -> bool:
	## 遭遇库抽出地点 → ENCOUNTER 包；无显现时 G4 默认进场（非弃牌）。
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_encounter_card_to_deck(
		h.ctx,
		&"enc_loc_drawn",
		[],
		{
			"card_type": &"location",
			"location": {"shroud": 2, "clues": 1},
		}
	)
	if not CardAbilityPackage.uses_encounter_package(h.ctx, card_id):
		return false
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	var card := h.ctx.state.registry.get_card(card_id)
	var loc := h.ctx.state.registry.get_location(&"enc_loc_drawn")
	return (
		bool(res.get("ok", false))
		and card != null
		and card.zone == AhcEnums.Zone.LOCATION_AREA
		and loc != null
		and loc.revealed
		and not h.ctx.state.encounter_discard.has(card_id)
	)


func _test_card_back_axis() -> bool:
	## 卡背类型与正面 cardtype 正交：弱点 = 遭遇类型 + 玩家卡背；显式可覆盖推断。
	CardRegistry.register_definition(
		&"cb_wkn_enemy",
		{"card_type": &"enemy", "is_weakness": true}
	)
	CardRegistry.register_definition(
		&"cb_story_asset",
		{"card_type": &"asset", "encounter_code": &"test_set"}
	)
	CardRegistry.register_definition(
		&"cb_player_asset",
		{"card_type": &"asset"}
	)
	CardRegistry.register_definition(
		&"cb_explicit_player_enemy",
		{"card_type": &"enemy", "card_back": &"player"}
	)
	return (
		CardRegistry.has_player_back(&"cb_wkn_enemy")
		and CardRegistry.has_encounter_back(&"cb_story_asset")
		and CardRegistry.has_player_back(&"cb_player_asset")
		and CardRegistry.has_player_back(&"cb_explicit_player_enemy")
		and CardRegistry.card_type(&"cb_wkn_enemy") == &"enemy"
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


func _test_peril_register_no_vacuum() -> bool:
	## 险境挂载经 seq.effect.register（对齐 gained keyword）。
	var h := RuleTestHarness.new(42)
	var before := _sequence_kind_count(h, &"effect_register")
	_setup_peril_for_drawer(h, &"inv_1", &"enc_peril_vac")
	return (
		h.ctx.registrations.has_peril_for_drawn_card(&"enc_peril_vac")
		and _sequence_kind_count(h, &"effect_register") > before
	)


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
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				1,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(&"inv_2", AhcEnums.MarkerKind.RESOURCE)
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
		CompositionNode.transfer_marker(
				AhcEnums.MarkerKind.RESOURCE,
				1,
				MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
				MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE)
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
		and h.ctx.state.chaos_bag.reveal_ledger.is_empty()
		and h.ctx.state.chaos_bag.reveal_scope_id == &""
	)


func _test_bag_ledger_skill_reveal() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0, &"n0")])
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 0)
	st.run(test)
	return (
		h.ctx.state.chaos_bag.tokens.size() == 1
		and h.ctx.state.chaos_bag.revealed_this_test.is_empty()
		and h.ctx.state.chaos_bag.reveal_ledger.is_empty()
	)


func _test_bag_ledger_ability_curse_gate() -> bool:
	var h := RuleTestHarness.new(42)
	var curse := ChaosToken.symbol(AhcEnums.ChaosTokenKind.CURSE, -2, &"curse_1")
	## 先只放 curse，保证能力揭示确定性；ST.3 前再补 numeric。
	GameBootstrap.setup_chaos_bag(h.ctx, [curse])
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 0)
	var flags := {"fires": 0}
	var on_match := func(_ctx: SkillTestContext, _kind: int, _n: int) -> void:
		flags.fires += 1
	test.if_revealed_watchers = [
		{"kind": AhcEnums.ChaosTokenKind.CURSE, "on_match": on_match}
	]
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	## Rod 式：finalize 定案即 eager 触发（不必等 ST.4 后门槛）。
	var pulled: Array[ChaosToken] = h.ctx.state.chaos_bag.reveal_for_ability(1)
	h.ctx.state.chaos_bag.finalize_ability_reveal(pulled)
	var fires_after_rod: int = int(flags.fires)
	## 能力揭示 curse 须回袋（非 pool）；ST.3 改用 numeric，避免检定再揭 curse 走符号能力。
	var bag_after_rod: bool = (
		h.ctx.state.chaos_bag.tokens.has(curse)
		and h.ctx.state.chaos_bag.chaos_token_pool.is_empty()
	)
	h.ctx.state.chaos_bag.tokens.clear()
	h.ctx.state.chaos_bag.add_token(ChaosToken.numeric(0, &"n0"))
	h.ctx.skill_tests.resolve_reveal_chain(test)
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.continue_after_reveal_window(test)
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return (
		fires_after_rod == 1
		and flags.fires == 1
		and bag_after_rod
		and pulled.size() == 1
		and pulled[0].kind == AhcEnums.ChaosTokenKind.CURSE
		and h.ctx.state.chaos_bag.tokens.size() == 1
		and h.ctx.state.chaos_bag.revealed_this_test.is_empty()
		and h.ctx.state.chaos_bag.reveal_ledger.is_empty()
	)


func _test_bag_ledger_cancel_excludes() -> bool:
	var h := RuleTestHarness.new(42)
	var curse := ChaosToken.symbol(AhcEnums.ChaosTokenKind.CURSE, -2, &"curse_x")
	GameBootstrap.setup_chaos_bag(h.ctx, [curse])
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 0)
	var flags := {"fires": 0}
	var on_match := func(_ctx: SkillTestContext, _kind: int, _n: int) -> void:
		flags.fires += 1
	test.if_revealed_watchers = [
		{"kind": AhcEnums.ChaosTokenKind.CURSE, "on_match": on_match}
	]
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	var pulled: Array[ChaosToken] = h.ctx.state.chaos_bag.reveal_for_ability(1)
	h.ctx.state.chaos_bag.cancel_reveal(pulled[0])
	h.ctx.state.chaos_bag.finalize_ability_reveal(pulled)
	## 撤出袋外，避免 ST.3 再次抽到同一枚形成「新揭示」账本行。
	h.ctx.state.chaos_bag.tokens.clear()
	h.ctx.state.chaos_bag.add_token(ChaosToken.numeric(1, &"n1"))
	var saw_curse_before_gate := h.ctx.state.chaos_bag.has_uncanceled_kind(
		AhcEnums.ChaosTokenKind.CURSE
	)
	h.ctx.skill_tests.resolve_reveal_chain(test)
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.continue_after_reveal_window(test)
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return (
		not saw_curse_before_gate
		and flags.fires == 0
		and h.ctx.state.chaos_bag.tokens.size() == 1
	)


func _test_bag_ledger_self_limit() -> bool:
	## any 自肃：Rod 揭 2 枚 curse → 只触发一次；后续 ST.3 再揭同 kind 也不再发。
	var h := RuleTestHarness.new(42)
	var c1 := ChaosToken.symbol(AhcEnums.ChaosTokenKind.CURSE, -2, &"c1")
	var c2 := ChaosToken.symbol(AhcEnums.ChaosTokenKind.CURSE, -2, &"c2")
	var c3 := ChaosToken.symbol(AhcEnums.ChaosTokenKind.CURSE, -2, &"c3")
	GameBootstrap.setup_chaos_bag(h.ctx, [c1, c2])
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.COMBAT, 0)
	var flags := {"fires": 0}
	var on_match := func(_ctx: SkillTestContext, _kind: int, _n: int) -> void:
		flags.fires += 1
	test.if_revealed_watchers = [
		{"kind": AhcEnums.ChaosTokenKind.CURSE, "mode": &"any", "on_match": on_match}
	]
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	var pulled: Array[ChaosToken] = h.ctx.state.chaos_bag.reveal_for_ability(2)
	h.ctx.state.chaos_bag.finalize_ability_reveal(pulled)
	var fires_after_rod: int = int(flags.fires)
	h.ctx.state.chaos_bag.add_token(c3)
	h.ctx.skill_tests.resolve_reveal_chain(test)
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.continue_after_reveal_window(test)
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return (
		fires_after_rod == 1
		and flags.fires == 1
		and pulled.size() == 2
		and bool(test.if_revealed_watchers[0].get("fired", false))
	)


func _test_bag_ledger_each_mode() -> bool:
	## each：Rod 揭 2 枚 curse → 触发两次；不自肃。
	var h := RuleTestHarness.new(42)
	var c1 := ChaosToken.symbol(AhcEnums.ChaosTokenKind.CURSE, -2, &"ce1")
	var c2 := ChaosToken.symbol(AhcEnums.ChaosTokenKind.CURSE, -2, &"ce2")
	GameBootstrap.setup_chaos_bag(h.ctx, [c1, c2])
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.COMBAT, 0)
	var flags := {"fires": 0}
	var on_match := func(_ctx: SkillTestContext, _kind: int, _n: int) -> void:
		flags.fires += 1
	test.if_revealed_watchers = [
		{"kind": AhcEnums.ChaosTokenKind.CURSE, "mode": &"each", "on_match": on_match}
	]
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	var pulled: Array[ChaosToken] = h.ctx.state.chaos_bag.reveal_for_ability(2)
	h.ctx.state.chaos_bag.finalize_ability_reveal(pulled)
	h.ctx.state.chaos_bag.add_token(ChaosToken.numeric(0, &"n_each"))
	h.ctx.skill_tests.resolve_reveal_chain(test)
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.continue_after_reveal_window(test)
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return flags.fires == 2 and pulled.size() == 2


func _test_bag_ledger_st3_eager_before_st4() -> bool:
	## ST.3 resolved curse → if_revealed 在符号能力前触发；窗后不再连发。
	var h := RuleTestHarness.new(42)
	var curse := ChaosToken.symbol(AhcEnums.ChaosTokenKind.CURSE, -2, &"c_st3")
	GameBootstrap.setup_chaos_bag(h.ctx, [curse])
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 0)
	var flags := {"fires": 0, "at_step": -1}
	var on_match := func(ctx: SkillTestContext, _kind: int, _n: int) -> void:
		flags.fires += 1
		flags.at_step = int(ctx.current_step)
	test.if_revealed_watchers = [
		{"kind": AhcEnums.ChaosTokenKind.CURSE, "on_match": on_match}
	]
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.resolve_reveal_chain(test)
	var fires_after_chain: int = int(flags.fires)
	var step_at_fire: int = int(flags.at_step)
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.continue_after_reveal_window(test)
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return (
		fires_after_chain == 1
		and flags.fires == 1
		and step_at_fire == int(AhcEnums.SkillTestStep.ST_3_REVEAL)
		and test.chaos_modifier == -2
	)


func _test_bag_intent_no_replace() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.numeric(0, &"n0"),
		ChaosToken.numeric(1, &"n1"),
	])
	h.ctx.state.chaos_bag.begin_reveal_scope(&"intent_none")
	var plan: Dictionary = ChaosRevealIntentPlanner.plan_and_reveal(
		h.ctx.state.chaos_bag, 1, [], h.ctx.interaction, h.ctx, &"inv_1"
	)
	return (
		int(plan.get("leaf_count", 0)) == 1
		and (plan.get("resolved") as Array).size() == 1
		and (plan.get("ignored") as Array).is_empty()
		and (plan.get("tokens") as Array).size() == 1
	)


func _test_bag_intent_olive_alone() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.numeric(0, &"a"),
		ChaosToken.numeric(1, &"b"),
		ChaosToken.numeric(2, &"c"),
		ChaosToken.numeric(3, &"d"),
	])
	h.ctx.state.chaos_bag.begin_reveal_scope(&"intent_olive")
	var olive := ChaosRevealReplaceAbility.create(&"olive", &"inv_1", 3, 2)
	var plan: Dictionary = ChaosRevealIntentPlanner.plan_and_reveal(
		h.ctx.state.chaos_bag, 1, [olive], h.ctx.interaction, h.ctx, &"inv_1"
	)
	return (
		int(plan.get("leaf_count", 0)) == 3
		and (plan.get("tokens") as Array).size() == 3
		and (plan.get("resolved") as Array).size() == 2
		and (plan.get("ignored") as Array).size() == 1
		and h.ctx.state.chaos_bag.revealed_this_test.size() == 3
		and h.ctx.state.chaos_bag.count_revealed_kind(AhcEnums.ChaosTokenKind.NUMERIC) == 3
		and h.ctx.state.chaos_bag.count_resolved_kind(AhcEnums.ChaosTokenKind.NUMERIC) == 2
	)


func _test_bag_intent_olive_then_statue() -> bool:
	var h := RuleTestHarness.new(7)
	h.ctx.state.lead_investigator_id = &"inv_1"
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.numeric(0, &"t0"),
		ChaosToken.numeric(1, &"t1"),
		ChaosToken.numeric(2, &"t2"),
		ChaosToken.numeric(3, &"t3"),
		ChaosToken.numeric(4, &"t4"),
	])
	h.ctx.state.chaos_bag.begin_reveal_scope(&"intent_olive_statue")
	var olive := ChaosRevealReplaceAbility.create(&"olive", &"inv_1", 3, 2)
	var statue := ChaosRevealReplaceAbility.create(&"statue", &"inv_1", 2, 1)
	## Olive 先 → 3 叶；Statue 作用 Olive 的第一叶（默认 id 序列展开后的首叶）→ 总叶 4。
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"chaos:reveal_replace_order", "pick": [&"olive", &"statue"]},
		{"prompt_id": &"chaos:reveal_replace_target:statue", "pick": 1},
	])
	var plan: Dictionary = ChaosRevealIntentPlanner.plan_and_reveal(
		h.ctx.state.chaos_bag, 1, [olive, statue], h.ctx.interaction, h.ctx, &"inv_1"
	)
	var order: Array = plan.get("order", [])
	var slots: Dictionary = plan.get("slot_targets", {})
	return (
		order.size() == 2
		and order[0] == &"olive"
		and order[1] == &"statue"
		and int(slots.get(&"statue", -1)) == 1
		and int(plan.get("leaf_count", 0)) == 4
		and (plan.get("tokens") as Array).size() == 4
		and (plan.get("resolved") as Array).size() == 3
		and (plan.get("ignored") as Array).size() == 1
	)


func _test_bag_intent_statue_then_olive() -> bool:
	var h := RuleTestHarness.new(11)
	h.ctx.state.lead_investigator_id = &"inv_1"
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.numeric(0, &"s0"),
		ChaosToken.numeric(1, &"s1"),
		ChaosToken.numeric(2, &"s2"),
		ChaosToken.numeric(3, &"s3"),
		ChaosToken.numeric(4, &"s4"),
	])
	h.ctx.state.chaos_bag.begin_reveal_scope(&"intent_statue_olive")
	var olive := ChaosRevealReplaceAbility.create(&"olive", &"inv_1", 3, 2)
	var statue := ChaosRevealReplaceAbility.create(&"statue", &"inv_1", 2, 1)
	## Statue 先：1→2；Olive 作用 Statue 的一叶（默认取头叶 id）→ 该叶再变 3 → 总叶 4。
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"chaos:reveal_replace_order", "pick": [&"statue", &"olive"]},
	])
	var plan: Dictionary = ChaosRevealIntentPlanner.plan_and_reveal(
		h.ctx.state.chaos_bag, 1, [olive, statue], h.ctx.interaction, h.ctx, &"inv_1"
	)
	var order: Array = plan.get("order", [])
	return (
		order.size() == 2
		and order[0] == &"statue"
		and order[1] == &"olive"
		and int(plan.get("leaf_count", 0)) == 4
		and (plan.get("tokens") as Array).size() == 4
	)


func _test_bag_intent_st3_multi_modifiers() -> bool:
	var h := RuleTestHarness.new(42)
	## 固定两枚 +1，Olive 揭 2 解 2 → chaos_modifier 累加为 2。
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.numeric(1, &"m1"),
		ChaosToken.numeric(1, &"m2"),
	])
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 0)
	test.pending_reveal_replace = [
		ChaosRevealReplaceAbility.create(&"double", &"inv_1", 2, 2)
	]
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.resolve_reveal_chain(test)
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.continue_after_reveal_window(test)
	var intent: Dictionary = test.last_reveal_intent
	var ok := (
		test.revealed_tokens.size() == 2
		and test.chaos_modifier == 2
		and int(intent.get("leaf_count", 0)) == 2
		and (intent.get("resolved") as Array).size() == 2
		and test.pending_reveal_replace.is_empty()
	)
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return ok


func _test_bag_ignore_olive_revealed() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.numeric(0, &"n0"),
		ChaosToken.numeric(1, &"n1"),
		ChaosToken.numeric(2, &"n2"),
		ChaosToken.numeric(3, &"n3"),
	])
	h.ctx.state.chaos_bag.begin_reveal_scope(&"ignore_olive")
	var olive := ChaosRevealReplaceAbility.create(&"olive", &"inv_1", 3, 2)
	var plan: Dictionary = ChaosRevealIntentPlanner.plan_and_reveal(
		h.ctx.state.chaos_bag, 1, [olive], h.ctx.interaction, h.ctx, &"inv_1"
	)
	var ignored: Array = plan.get("ignored", [])
	if ignored.is_empty():
		return false
	var ig: ChaosToken = ignored[0] as ChaosToken
	var ig_row_ok := false
	for r in h.ctx.state.chaos_bag.reveal_ledger:
		if r.token != ig:
			continue
		ig_row_ok = r.ignored and r.was_revealed() and not r.was_resolved()
		break
	return (
		ig_row_ok
		and h.ctx.state.chaos_bag.revealed_records().size() == 3
		and h.ctx.state.chaos_bag.resolved_records().size() == 2
	)


func _test_bag_ignore_cancel_excludes_both() -> bool:
	var h := RuleTestHarness.new(42)
	var curse := ChaosToken.symbol(AhcEnums.ChaosTokenKind.CURSE, -2, &"c_cancel")
	GameBootstrap.setup_chaos_bag(h.ctx, [curse])
	h.ctx.state.chaos_bag.begin_reveal_scope(&"cancel_scope")
	var pulled: Array[ChaosToken] = h.ctx.state.chaos_bag.reveal_for_ability(1)
	h.ctx.state.chaos_bag.cancel_reveal(pulled[0])
	return (
		not h.ctx.state.chaos_bag.has_revealed_kind(AhcEnums.ChaosTokenKind.CURSE)
		and not h.ctx.state.chaos_bag.has_resolved_kind(AhcEnums.ChaosTokenKind.CURSE)
		and h.ctx.state.chaos_bag.revealed_records().is_empty()
		and h.ctx.state.chaos_bag.resolved_records().is_empty()
	)


func _test_bag_ignore_gate_skips_ignored() -> bool:
	## 能力揭示 curse 后 Ignore → finalize 时非 resolved，if_revealed 不开火；revealed 仍可见。
	var h := RuleTestHarness.new(42)
	var curse := ChaosToken.symbol(AhcEnums.ChaosTokenKind.CURSE, -2, &"c_gate")
	GameBootstrap.setup_chaos_bag(h.ctx, [curse])
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 0)
	var flags := {"fires": 0}
	var on_match := func(_ctx: SkillTestContext, _kind: int, _n: int) -> void:
		flags.fires += 1
	test.if_revealed_watchers = [
		{"kind": AhcEnums.ChaosTokenKind.CURSE, "on_match": on_match}
	]
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	var pulled: Array[ChaosToken] = h.ctx.state.chaos_bag.reveal_for_ability(1)
	h.ctx.state.chaos_bag.ignore_reveal(pulled[0])
	h.ctx.state.chaos_bag.finalize_ability_reveal(pulled)
	h.ctx.state.chaos_bag.tokens.clear()
	h.ctx.state.chaos_bag.add_token(ChaosToken.numeric(0, &"n_gate"))
	var saw_revealed := h.ctx.state.chaos_bag.has_revealed_kind(AhcEnums.ChaosTokenKind.CURSE)
	var saw_resolved := h.ctx.state.chaos_bag.has_resolved_kind(AhcEnums.ChaosTokenKind.CURSE)
	h.ctx.skill_tests.resolve_reveal_chain(test)
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.continue_after_reveal_window(test)
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return saw_revealed and not saw_resolved and flags.fires == 0


func _test_bag_wire_compile_12068() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var compiled := CardRegistry.compiled_abilities(&"12068")
	if compiled.size() != 1:
		return false
	var entry: Dictionary = compiled[0]
	if str(entry.get("match_kind", "")) != "reveal_chaos_token":
		return false
	if str(entry.get("phase", "")).to_upper() != "WHEN":
		return false
	if str(entry.get("template", "")) != "seq":
		return false
	if str(entry.get("status", "")) != "full":
		return false
	var steps: Array = entry.get("steps", [])
	if steps.size() != 3:
		return false
	var spend: Dictionary = steps[0]
	var replace: Dictionary = steps[1]
	var symbol_hook: Dictionary = steps[2]
	var uses := CardRegistry.uses_spec(&"12068")
	return (
		CardRegistry.has_triggered(&"12068")
		and str(spend.get("template", "")) == "spend_use"
		and str(replace.get("template", "")) == "chaos_reveal_replace"
		and int(replace.get("reveal_count", 0)) == 2
		and int(replace.get("resolve_count", 0)) == 1
		and str(symbol_hook.get("template", "")) == "after_reveal_if_resolved_symbol"
		and int(uses.get("count", 0)) == 3
		and String(uses.get("type", &"")) == "charges"
		and h.ctx.sequence_catalog.has_flow(&"seq.chaos.reveal")
	)


func _test_bag_wire_12068_vertical() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	if not h.ctx.sequence_catalog.has_flow(&"seq.chaos.reveal"):
		return false
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.numeric(1, &"w0"),
		ChaosToken.numeric(1, &"w1"),
		ChaosToken.numeric(0, &"w2"),
	])
	var card_id := GameBootstrap.add_asset_to_play(h.ctx, &"inv_1", &"12068")
	var card := h.ctx.state.registry.get_card(card_id)
	## Uses Domain：进场即 3 charges；勿手写。
	var charges_enter := int(card.tokens.uses.get(&"charges", -1))
	## 意愿池 join（16 §7.1）；非二次 reaction:use。
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"willingness:join", "pick": true},
	])
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var horror_before := inv.horror_taken
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 0)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.resolve_reveal_chain(test)
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.continue_after_reveal_window(test)
	var intent: Dictionary = test.last_reveal_intent
	var charges_left := int(card.tokens.uses.get(&"charges", -1))
	var resolved_arr: Array = intent.get("resolved", [])
	var expected_mod := 0
	if resolved_arr.size() == 1 and resolved_arr[0] is ChaosToken:
		expected_mod = (resolved_arr[0] as ChaosToken).modifier
	var ok := (
		charges_enter == 3
		and int(intent.get("leaf_count", 0)) == 2
		and resolved_arr.size() == 1
		and (intent.get("ignored") as Array).size() == 1
		and test.revealed_tokens.size() == 1
		and test.chaos_modifier == expected_mod
		and charges_left == 2
		and inv.horror_taken == horror_before
	)
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return ok


func _test_bag_wire_12068_symbol_horror() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	## 两枚符号：揭 2 解 1 → 必有 resolved 符号 → take 1 horror。
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.symbol(AhcEnums.ChaosTokenKind.SKULL, -1, &"sk0"),
		ChaosToken.symbol(AhcEnums.ChaosTokenKind.CULTIST, -1, &"cu0"),
	])
	var card_id := GameBootstrap.add_asset_to_play(h.ctx, &"inv_1", &"12068")
	var card := h.ctx.state.registry.get_card(card_id)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"willingness:join", "pick": true},
	])
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var horror_before := inv.horror_taken
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.INTELLECT, 0)
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.resolve_reveal_chain(test)
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.continue_after_reveal_window(test)
	var intent: Dictionary = test.last_reveal_intent
	var resolved_arr: Array = intent.get("resolved", [])
	var resolved_is_symbol := false
	if resolved_arr.size() == 1 and resolved_arr[0] is ChaosToken:
		resolved_is_symbol = (resolved_arr[0] as ChaosToken).is_symbol_token()
	var ok := (
		int(card.tokens.uses.get(&"charges", -1)) == 2
		and resolved_arr.size() == 1
		and resolved_is_symbol
		and inv.horror_taken == horror_before + 1
	)
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	return ok


func _test_bag_uses_enter_play() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var card_id := GameBootstrap.add_asset_to_play(h.ctx, &"inv_1", &"12068")
	var card := h.ctx.state.registry.get_card(card_id)
	if card == null or int(card.tokens.uses.get(&"charges", -1)) != 3:
		return false
	## 离场清 Uses token。
	h.ctx.mutator.move_card(card_id, CardSlot.discard_top(&"inv_1"))
	return card.tokens.uses.is_empty()


func _test_bag_seal_random() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var skull := ChaosToken.symbol(AhcEnums.ChaosTokenKind.SKULL, -1, &"sk1")
	var plus := ChaosToken.numeric(1, &"n1")
	GameBootstrap.setup_chaos_bag(h.ctx, [skull, plus])
	var host := GameBootstrap.add_asset_to_play(h.ctx, &"inv_1", &"12068")
	var bag_before := h.ctx.state.chaos_bag.tokens.size()
	var res: Dictionary = SealFlow.seal(
		h.ctx, {"host_card_id": host, "mode": SealFlow.MODE_RANDOM}
	)
	if not bool(res.get("ok", false)):
		return false
	var card := h.ctx.state.registry.get_card(host)
	var sealed_tok: ChaosToken = res.get("token") as ChaosToken
	return (
		h.ctx.state.chaos_bag.tokens.size() == bag_before - 1
		and h.ctx.state.chaos_bag.sealed_tokens.size() == 1
		and sealed_tok != null
		and sealed_tok.sealed
		and sealed_tok.sealed_on == host
		and card != null
		and card.tokens.sealed.size() == 1
		and not h.ctx.state.chaos_bag.tokens.has(sealed_tok)
	)


func _test_bag_seal_kind_missing() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0, &"n0")])
	var host := GameBootstrap.add_asset_to_play(h.ctx, &"inv_1", &"12068")
	var bag_n := h.ctx.state.chaos_bag.tokens.size()
	var res: Dictionary = SealFlow.seal(
		h.ctx,
		{
			"host_card_id": host,
			"mode": SealFlow.MODE_KIND,
			"kind": AhcEnums.ChaosTokenKind.SKULL,
		}
	)
	return (
		not bool(res.get("ok", false))
		and h.ctx.state.chaos_bag.tokens.size() == bag_n
		and h.ctx.state.chaos_bag.sealed_tokens.is_empty()
	)


func _test_bag_seal_leave_play_release() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var skull := ChaosToken.symbol(AhcEnums.ChaosTokenKind.SKULL, -2, &"sk_leave")
	GameBootstrap.setup_chaos_bag(h.ctx, [skull, ChaosToken.numeric(1, &"n_leave")])
	var host := GameBootstrap.add_asset_to_play(h.ctx, &"inv_1", &"12068")
	var seal_res: Dictionary = SealFlow.seal(
		h.ctx,
		{
			"host_card_id": host,
			"mode": SealFlow.MODE_KIND,
			"kind": AhcEnums.ChaosTokenKind.SKULL,
		}
	)
	if not bool(seal_res.get("ok", false)):
		return false
	var bag_mid := h.ctx.state.chaos_bag.tokens.size()
	h.ctx.mutator.move_card(host, CardSlot.discard_top(&"inv_1"))
	var card := h.ctx.state.registry.get_card(host)
	return (
		h.ctx.state.chaos_bag.sealed_tokens.is_empty()
		and h.ctx.state.chaos_bag.tokens.size() == bag_mid + 1
		and h.ctx.state.chaos_bag.tokens.has(skull)
		and not skull.sealed
		and skull.sealed_on == &""
		and (card == null or card.tokens.sealed.is_empty())
	)


func _test_bag_seal_catalog_nest() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	if not h.ctx.sequence_catalog.has_flow(&"seq.effect.seal"):
		return false
	if not h.ctx.sequence_catalog.has_flow(&"seq.effect.release_seal"):
		return false
	GameBootstrap.setup_chaos_bag(h.ctx, [
		ChaosToken.symbol(AhcEnums.ChaosTokenKind.CULTIST, -1, &"cu1"),
		ChaosToken.numeric(0, &"n_nest"),
	])
	var host := GameBootstrap.add_asset_to_play(h.ctx, &"inv_1", &"12068")
	var seal_res: Dictionary = h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.seal",
		{
			"host_card_id": host,
			"mode": SealFlow.MODE_KIND,
			"kind": AhcEnums.ChaosTokenKind.CULTIST,
		}
	)
	if not bool(seal_res.get("ok", false)):
		return false
	var rel: Dictionary = h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.release_seal",
		{"host_card_id": host}
	)
	return (
		bool(rel.get("ok", false))
		and h.ctx.state.chaos_bag.sealed_tokens.is_empty()
		and h.ctx.state.chaos_bag.tokens.size() == 2
	)


func _test_bag_seal_reveal_instead() -> bool:
	var h := RuleTestHarness.new(42)
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var sealed_num := ChaosToken.numeric(-3, &"sealed_m3")
	var bag_only := ChaosToken.numeric(9, &"bag_9")
	GameBootstrap.setup_chaos_bag(h.ctx, [sealed_num, bag_only])
	var host := GameBootstrap.add_asset_to_play(h.ctx, &"inv_1", &"12068")
	var seal_res: Dictionary = SealFlow.seal(
		h.ctx,
		{"host_card_id": host, "mode": SealFlow.MODE_TOKEN, "token": sealed_num}
	)
	if not bool(seal_res.get("ok", false)):
		return false
	var bag_n := h.ctx.state.chaos_bag.tokens.size()
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.WILLPOWER, 0)
	test.pending_reveal_replace = [
		ChaosRevealReplaceAbility.create_sealed_instead(
			&"premonition", &"inv_1", host, 1
		)
	]
	h.ctx.skill_tests.begin_test(test, h.ctx)
	h.ctx.skill_tests.step_commit(test, [])
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.resolve_reveal_chain(test)
	var intent: Dictionary = test.last_reveal_intent
	var resolved: Array = intent.get("resolved", [])
	var ok: bool = (
		resolved.size() == 1
		and resolved[0] == sealed_num
		and test.chaos_modifier == -3
		and h.ctx.state.chaos_bag.tokens.size() == bag_n
		and h.ctx.state.chaos_bag.tokens.has(bag_only)
		and not h.ctx.state.chaos_bag.tokens.has(sealed_num)
		and h.ctx.state.chaos_bag.sealed_tokens.is_empty()
		and h.ctx.state.chaos_bag.revealed_this_test.has(sealed_num)
	)
	h.ctx.skill_tests.close_player_window(test)
	h.ctx.skill_tests.continue_after_reveal_window(test)
	h.ctx.skill_tests.step_apply_results(test)
	h.ctx.skill_tests.step_end(test, h.ctx)
	## ST.8 归袋后 sealed 标记应回袋（曾作揭示）。
	ok = ok and h.ctx.state.chaos_bag.tokens.has(sealed_num)
	return ok


func _test_bag_seal_keyword_cost_gate() -> bool:
	var h := RuleTestHarness.new(42)
	CardRegistry.register_definition(
		&"seal_skull_asset",
		{
			"card_type": &"asset",
			"resource_cost": 0,
			"keywords": [&"seal"],
			"seal": {"kind": "skull"},
			"text": "Seal (Skull).",
		}
	)
	GameBootstrap.setup_chaos_bag(h.ctx, [ChaosToken.numeric(0, &"n0")])
	var card_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"seal_skull_asset")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"inv_1"
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.HAND
	h.ctx.state.registry.register_card(card)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.hand.append(card_id)
	inv.resource_pool = 5
	var res := h.ctx.actions.play_card(&"inv_1", card_id)
	return (
		not res.ok
		and res.error == "cannot_pay"
		and inv.hand.has(card_id)
		and card.zone == AhcEnums.Zone.HAND
		and h.ctx.state.chaos_bag.sealed_tokens.is_empty()
	)


func _test_bag_seal_keyword_play_enter() -> bool:
	var h := RuleTestHarness.new(42)
	CardRegistry.register_definition(
		&"seal_elder_asset",
		{
			"card_type": &"asset",
			"resource_cost": 0,
			"keywords": [&"seal"],
			"seal": {"kind": "elder_sign"},
			"text": "Seal (Elder Sign).",
		}
	)
	var elder := ChaosToken.symbol(AhcEnums.ChaosTokenKind.ELDER_SIGN, 0, &"es1")
	GameBootstrap.setup_chaos_bag(h.ctx, [elder, ChaosToken.numeric(1, &"n1")])
	var card_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"seal_elder_asset")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"inv_1"
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.HAND
	h.ctx.state.registry.register_card(card)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.hand.append(card_id)
	var res := h.ctx.actions.play_card(&"inv_1", card_id)
	card = h.ctx.state.registry.get_card(card_id)
	return (
		res.ok
		and card != null
		and card.zone == AhcEnums.Zone.PLAY_AREA
		and elder.sealed
		and elder.sealed_on == card_id
		and card.tokens.sealed.size() == 1
		and not h.ctx.state.chaos_bag.tokens.has(elder)
	)


func _test_bag_seal_keyword_choice() -> bool:
	var h := RuleTestHarness.new(42)
	CardRegistry.register_definition(
		&"seal_choice_asset",
		{
			"card_type": &"asset",
			"resource_cost": 0,
			"keywords": [&"seal"],
			"seal": {"kinds": ["cultist", "tablet"]},
			"text": "Seal ([cultist] or [tablet]).",
		}
	)
	var cultist := ChaosToken.symbol(AhcEnums.ChaosTokenKind.CULTIST, -1, &"cu_s")
	var tablet := ChaosToken.symbol(AhcEnums.ChaosTokenKind.TABLET, -1, &"tab_s")
	GameBootstrap.setup_chaos_bag(h.ctx, [cultist, tablet, ChaosToken.numeric(0, &"n_c")])
	## 默认 Gate 取候选 head → cultist。
	var card_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"seal_choice_asset")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"inv_1"
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.HAND
	h.ctx.state.registry.register_card(card)
	h.ctx.state.registry.get_investigator(&"inv_1").hand.append(card_id)
	var res := h.ctx.actions.play_card(&"inv_1", card_id)
	card = h.ctx.state.registry.get_card(card_id)
	var sealed_ok := cultist.sealed or tablet.sealed
	var one_sealed := int(cultist.sealed) + int(tablet.sealed) == 1
	return (
		res.ok
		and sealed_ok
		and one_sealed
		and card != null
		and card.tokens.sealed.size() == 1
	)


func _test_bag_seal_keyword_zone_enter() -> bool:
	var h := RuleTestHarness.new(42)
	CardRegistry.register_definition(
		&"seal_zone_asset",
		{
			"card_type": &"asset",
			"keywords": [&"seal"],
			"seal": {"kind": "skull"},
			"text": "Seal (Skull).",
		}
	)
	var skull := ChaosToken.symbol(AhcEnums.ChaosTokenKind.SKULL, -1, &"sk_z")
	GameBootstrap.setup_chaos_bag(h.ctx, [skull])
	## put into play（非打出 Initiation）仍走进场 Domain。
	var host := GameBootstrap.add_asset_to_play(h.ctx, &"inv_1", &"seal_zone_asset")
	var card := h.ctx.state.registry.get_card(host)
	return (
		skull.sealed
		and skull.sealed_on == host
		and card != null
		and card.tokens.sealed.size() == 1
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
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	enemy.health = 2
	var res := h.fight_action({"enemy_id": &"enemy_1"})
	enemy = h.ctx.state.registry.get_enemy(&"enemy_1")
	return res.ok and res.success and enemy != null and enemy.damage == 1


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
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var before := inv.actions_remaining
	var res := h.evade_action({"enemy_id": &"enemy_1"})
	return (
		not res.ok
		and res.error == "not_engaged"
		and inv.actions_remaining == before
	)


func _test_act_fight_aloof() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2, &"", true)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var before := inv.actions_remaining
	var res := h.fight_action({"enemy_id": &"enemy_1"})
	return not res.ok and res.error == "aloof" and inv.actions_remaining == before


func _test_act_imp_fight_auto_bind() -> bool:
	## 未传 enemy_id：唯一合法敌人自动绑定。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	enemy.health = 2
	var res := h.fight_action({})
	enemy = h.ctx.state.registry.get_enemy(&"enemy_1")
	return res.ok and res.success and enemy != null and enemy.damage == 1


func _test_act_imp_fight_no_target() -> bool:
	## 无合法敌人 → 付费前失败。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var before := inv.actions_remaining
	var res := h.fight_action({})
	return (
		not res.ok
		and res.error == "no_legal_target"
		and inv.actions_remaining == before
	)


func _test_act_imp_evade_auto_bind() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(
		h.ctx, &"enemy_1", &"test_loc", 2, 2, &"inv_1"
	)
	var res := h.evade_action({})
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	return res.ok and res.success and enemy.exhausted and enemy.engaged_with == &""


func _test_act_imp_fight_two_enemies() -> bool:
	## 两敌同地：Gate 默认 first_option；攻击成功。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_a", &"test_loc", 2, 2)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_b", &"test_loc", 2, 2)
	h.ctx.state.registry.get_enemy(&"enemy_a").health = 3
	h.ctx.state.registry.get_enemy(&"enemy_b").health = 3
	var res := h.fight_action({})
	var a := h.ctx.state.registry.get_enemy(&"enemy_a")
	var b := h.ctx.state.registry.get_enemy(&"enemy_b")
	var damaged := (a != null and a.damage == 1) or (b != null and b.damage == 1)
	var other_ok := (
		(a != null and a.damage == 1 and b != null and b.damage == 0)
		or (b != null and b.damage == 1 and a != null and a.damage == 0)
	)
	return res.ok and res.success and damaged and other_ok


func _test_act_imp_investigate_wrong_loc() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_location(h.ctx, &"loc_b")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var before := inv.actions_remaining
	var res := h.investigate_action({"location_id": &"loc_b"})
	return (
		not res.ok
		and res.error == "not_at_location"
		and inv.actions_remaining == before
	)


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


func _test_act_engage_nests_kernel() -> bool:
	## 基础行动 = 效果交战：外壳 nest seq.engage mode=effect。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	var res := h.engage_action({"enemy_id": &"enemy_1"})
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	return (
		res.ok
		and res.get("mode", &"") == EngageFlow.MODE_EFFECT
		and res.get("placement", &"") == EngageFlow.PLACEMENT_ENTER_THREAT
		and enemy != null
		and enemy.is_engaged_with(&"inv_1")
	)


func _test_engage_grant_cross_location() -> bool:
	## grant：Register 交战 Buff；不移入威胁区（检测威胁区仍为假）。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"loc_far")
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_1", &"test_loc")
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_far", &"loc_far", 2, 2)
	var res := h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.engage",
		{
			"mode": EngageFlow.MODE_EFFECT,
			"placement": EngageFlow.PLACEMENT_GRANT,
			"require_same_location": false,
			"enemy_id": &"enemy_far",
			"investigator_id": &"inv_1",
		}
	)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_far")
	return (
		res.ok
		and res.get("placement", &"") == EngageFlow.PLACEMENT_GRANT
		and bool(res.get("engagement_buff", false))
		and not bool(res.get("moved_into_threat_area", true))
		and EngagementStatus.is_engaged_with(h.ctx, &"enemy_far", &"inv_1")
		and enemy != null
		and enemy.engaged_with == &""
		and not inv.threat_area.has(&"enemy_far")
	)


func _test_engage_enter_threat_buff() -> bool:
	## 真实交战：Register Buff，并移入威胁区（检测在威胁区为真）。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	var res := h.engage_action({"enemy_id": &"enemy_1"})
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		res.ok
		and inv.threat_area.has(&"enemy_1")
		and EngagementStatus.is_engaged_with(h.ctx, &"enemy_1", &"inv_1")
		and h.ctx.registrations.has_engagement(&"enemy_1", &"inv_1")
	)


func _test_engage_disengage_clears_buff() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	if not h.engage_action({"enemy_id": &"enemy_1"}).ok:
		return false
	h.ctx.enemy.disengage(h.ctx, &"enemy_1", false, false)
	return (
		not EngagementStatus.is_engaged_with(h.ctx, &"enemy_1", &"inv_1")
		and not h.ctx.registrations.has_engagement(&"enemy_1", &"inv_1")
	)


func _test_m4_gain_resource_rename() -> bool:
	var h := RuleTestHarness.new(42)
	var catalog := h.ctx.sequence_catalog
	if catalog == null:
		return false
	if not catalog.has_flow(&"seq.effect.gain_resource"):
		return false
	## 旧根 id 已废。
	if catalog.has_flow(&"seq.gain_resource"):
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var before := inv.resource_pool
	var result := catalog.run(
		h.ctx,
		&"seq.effect.gain_resource",
		{"controller_id": &"inv_1", "base_amount": 2, "source_tags": []}
	)
	return int(result.get("amount", 0)) == 2 and inv.resource_pool == before + 2


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


func _test_act_move_nests_effect_move() -> bool:
	## 行动外壳 nest 狭义移动内核 seq.effect.move。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_location(h.ctx, &"loc_b", 1, 0)
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"loc_b")
	var res := h.move_action({"destination_id": &"loc_b"})
	return (
		res.ok
		and res.get("from", &"") == &"test_loc"
		and res.get("to", &"") == &"loc_b"
		and h.ctx.sequence_catalog.has_flow(&"seq.effect.move")
	)


func _test_g1_effect_move_registered() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.ctx.sequence_catalog.has_flow(&"seq.effect.move"):
		return false
	GameBootstrap.setup_test_location(h.ctx, &"loc_b", 1, 0)
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"loc_b")
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_1", &"test_loc")
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.move",
		{
			"subject": MoveFlow.SUBJECT_INVESTIGATOR,
			"investigator_id": &"inv_1",
			"destination_id": &"loc_b",
			"move_kind": MoveFlow.KIND_MOVE,
			"auto_engage_after": false,
		}
	)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		res.ok
		and inv.location_tag == &"loc_b"
		and res.get("from", &"") == &"test_loc"
		and res.get("subject", &"") == MoveFlow.SUBJECT_INVESTIGATOR
		and res.get("move_kind", &"") == MoveFlow.KIND_MOVE
	)


func _test_g1_effect_move_enemy() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"loc_b", 1, 0)
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"loc_b")
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.move",
		{
			"subject": MoveFlow.SUBJECT_ENEMY,
			"enemy_id": &"enemy_1",
			"destination_id": &"loc_b",
			"move_kind": MoveFlow.KIND_MOVE,
			"steps": 1,
			"auto_engage": false,
		}
	)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	return (
		res.ok
		and bool(res.get("moved", false))
		and enemy.location_tag == &"loc_b"
		and res.get("move_kind", &"") == MoveFlow.KIND_MOVE
		and h.ctx.sequence_catalog.has_flow(&"seq.effect.move")
		and not h.ctx.sequence_catalog.has_flow(&"seq.enemy.move")
	)


func _test_g1_effect_move_attachment() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"test_loc", 1, 0)
	GameBootstrap.setup_test_location(h.ctx, &"loc_b", 1, 0)
	var card_id := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_attach_move", [])
	h.ctx.state.encounter_deck.erase(card_id)
	var card := h.ctx.state.registry.get_card(card_id)
	card.zone = AhcEnums.Zone.LIMBO
	if not EncounterAttachment.attach_limbo_to_location(h.ctx, card_id, &"test_loc"):
		return false
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.move",
		{
			"subject": MoveFlow.SUBJECT_ATTACHMENT,
			"attachment_id": card_id,
			"destination_id": &"loc_b",
			"move_kind": MoveFlow.KIND_MOVE_TO,
		}
	)
	card = h.ctx.state.registry.get_card(card_id)
	var host_b := h.ctx.state.registry.get_card(&"loc_b")
	return (
		res.ok
		and card.zone == AhcEnums.Zone.ATTACHED
		and card.attached_to != null
		and card.attached_to.instance_id == &"loc_b"
		and host_b != null
		and host_b.attachments.has(card.id)
		and res.get("from", &"") == &"test_loc"
		and res.get("to", &"") == &"loc_b"
	)


func _test_g1_effect_move_marker() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"loc_a", 1, 3)
	GameBootstrap.setup_test_location(h.ctx, &"loc_b", 1, 0)
	var loc_a := h.ctx.state.registry.get_location(&"loc_a")
	var loc_b := h.ctx.state.registry.get_location(&"loc_b")
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.move",
		{
			"subject": MoveFlow.SUBJECT_MARKER,
			"from_location": &"loc_a",
			"destination_id": &"loc_b",
			"amount": 2,
			"marker_kind": AhcEnums.MarkerKind.CLUE,
			"move_kind": MoveFlow.KIND_MOVE_TO,
		}
	)
	return (
		res.ok
		and loc_a.clues == 1
		and loc_b.clues == 2
		and int(res.get("amount", 0)) == 2
		and res.get("subject", &"") == MoveFlow.SUBJECT_MARKER
		and res.get("move_kind", &"") == MoveFlow.KIND_MOVE_TO
	)


func _test_g1_effect_move_enemy_move_to() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"loc_b", 1, 0)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	var res := MoveFlow.nest_or_run(
		h.ctx,
		{
			"subject": MoveFlow.SUBJECT_ENEMY,
			"enemy_id": &"enemy_1",
			"destination_id": &"loc_b",
			"move_kind": MoveFlow.KIND_MOVE_TO,
			"auto_engage": false,
		}
	)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	return (
		res.ok
		and bool(res.get("moved", false))
		and res.get("move_kind", &"") == MoveFlow.KIND_MOVE_TO
		and enemy.location_tag == &"loc_b"
	)


func _test_g1_elusive_flee_nests_move() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_location(h.ctx, &"flee_loc")
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"flee_loc")
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_elusive_wire",
		&"test_loc",
		{
			"keywords": [&"elusive"],
			"enemy": {"fight": 2, "evade": 2, "health": 2, "damage": 1, "horror": 0},
		}
	)
	if enemy_id == &"":
		return false
	var flee := ElusiveResolver.try_flee_was_attacked(h.ctx, enemy_id)
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	return (
		bool(flee.get("ok", false))
		and bool(flee.get("fled", false))
		and bool(flee.get("moved", false))
		and enemy != null
		and enemy.location_tag == &"flee_loc"
		and enemy.exhausted
	)


func _test_g1_move_rejects_disconnected() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"loc_far", 1, 0)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_1", &"test_loc")
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.move",
		{
			"subject": MoveFlow.SUBJECT_INVESTIGATOR,
			"investigator_id": &"inv_1",
			"destination_id": &"loc_far",
			"move_kind": MoveFlow.KIND_MOVE,
			"auto_engage_after": false,
		}
	)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		not bool(res.get("ok", false))
		and str(res.get("error", "")) == "not_connected"
		and inv.location_tag == &"test_loc"
	)


func _test_g1_move_to_ignores_connections() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"loc_far", 1, 0)
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_1", &"test_loc")
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.move",
		{
			"subject": MoveFlow.SUBJECT_INVESTIGATOR,
			"investigator_id": &"inv_1",
			"destination_id": &"loc_far",
			"move_kind": MoveFlow.KIND_MOVE_TO,
			"auto_engage_after": false,
		}
	)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		bool(res.get("ok", false))
		and res.get("move_kind", &"") == MoveFlow.KIND_MOVE_TO
		and inv.location_tag == &"loc_far"
	)


func _test_l01_per_investigator_clues() -> bool:
	## 印刷 2 × 开局调查员数 2 → 放 4 线索。
	var h := RuleTestHarness.new(42)
	h.ctx.state.per_investigator_count = 2
	GameBootstrap.setup_test_location(
		h.ctx, &"loc_pi", 3, 2, false, 2
	)
	var reveal := LocationEnterRules.reveal_and_place_clues(
		h.ctx, {"location_id": &"loc_pi"}
	)
	var loc := h.ctx.state.registry.get_location(&"loc_pi")
	return (
		bool(reveal.get("ok", false))
		and bool(reveal.get("revealed", false))
		and int(reveal.get("clues_placed", 0)) == 4
		and loc.revealed
		and loc.clues == 4
	)


func _test_l02_move_unrevealed() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.state.per_investigator_count = 1
	GameBootstrap.setup_test_location(h.ctx, &"test_loc", 2, 0)
	GameBootstrap.setup_test_location(
		h.ctx, &"loc_dark", 4, 3, false, 3
	)
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"loc_dark")
	h.ctx.state.registry.get_investigator(&"inv_1").location_tag = &"test_loc"
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.move",
		{
			"subject": MoveFlow.SUBJECT_INVESTIGATOR,
			"investigator_id": &"inv_1",
			"destination_id": &"loc_dark",
			"move_kind": MoveFlow.KIND_MOVE,
			"auto_engage_after": false,
		}
	)
	var loc := h.ctx.state.registry.get_location(&"loc_dark")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		bool(res.get("ok", false))
		and inv.location_tag == &"loc_dark"
		and loc.revealed
		and loc.clues == 3
		and bool(res.get("location_revealed", false))
		and int(res.get("clues_placed", 0)) == 3
		and h.ctx.sequence_catalog.has_flow(&"seq.effect.reveal_location")
	)


func _test_l02b_reenter_no_reclues() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"test_loc", 2, 0)
	GameBootstrap.setup_test_location(
		h.ctx, &"loc_once", 2, 2, false, 2
	)
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"loc_once")
	h.ctx.state.registry.get_investigator(&"inv_1").location_tag = &"test_loc"
	h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.move",
		{
			"subject": MoveFlow.SUBJECT_INVESTIGATOR,
			"investigator_id": &"inv_1",
			"destination_id": &"loc_once",
			"move_kind": MoveFlow.KIND_MOVE,
			"auto_engage_after": false,
		}
	)
	var loc := h.ctx.state.registry.get_location(&"loc_once")
	loc.clues = 1
	## 走回再进：已揭示，线索保持 1。
	h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.move",
		{
			"subject": MoveFlow.SUBJECT_INVESTIGATOR,
			"investigator_id": &"inv_1",
			"destination_id": &"test_loc",
			"move_kind": MoveFlow.KIND_MOVE,
			"auto_engage_after": false,
		}
	)
	var res2 := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.move",
		{
			"subject": MoveFlow.SUBJECT_INVESTIGATOR,
			"investigator_id": &"inv_1",
			"destination_id": &"loc_once",
			"move_kind": MoveFlow.KIND_MOVE,
			"auto_engage_after": false,
		}
	)
	return (
		loc.revealed
		and loc.clues == 1
		and not bool(res2.get("location_revealed", false))
		and int(res2.get("clues_placed", 0)) == 0
	)


func _test_l02c_enemy_move_no_reveal() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"test_loc", 2, 0)
	GameBootstrap.setup_test_location(
		h.ctx, &"loc_enemy", 2, 2, false, 2
	)
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"loc_enemy")
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.move",
		{
			"subject": MoveFlow.SUBJECT_ENEMY,
			"enemy_id": &"enemy_1",
			"destination_id": &"loc_enemy",
			"move_kind": MoveFlow.KIND_MOVE,
			"steps": 1,
			"auto_engage": false,
		}
	)
	var loc := h.ctx.state.registry.get_location(&"loc_enemy")
	return not loc.revealed and loc.clues == 0


func _test_g2_exhaust_enemy() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.exhaust",
		{"target_kind": ExhaustReadyFlow.TARGET_ENEMY, "enemy_id": &"enemy_1"}
	)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	return (
		bool(res.get("ok", false))
		and bool(res.get("changed", false))
		and enemy.exhausted
		and h.ctx.sequence_catalog.has_flow(&"seq.effect.ready")
	)


func _test_evade_effect_attempt() -> bool:
	## 躲避效果核：交战敌 → 横置 + 脱离（mode=attempt）。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_enemy(
		h.ctx, &"enemy_1", &"test_loc", 2, 2, &"inv_1"
	)
	var res := EvadeFlow.after_attempt_success(h.ctx, &"enemy_1", &"inv_1")
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	return (
		bool(res.get("ok", false))
		and bool(res.get("created", false))
		and bool(res.get("exhaust_changed", false))
		and bool(res.get("disengaged", false))
		and enemy.exhausted
		and enemy.engaged_with == &""
		and h.ctx.sequence_catalog.has_flow(&"seq.effect.evade")
	)


func _test_evade_automatic_unengaged() -> bool:
	## 自动躲避未交战敌：只横置，不算 attempt。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	enemy.engaged_with = &""
	var res := EvadeFlow.automatically_evade(h.ctx, &"enemy_1", &"inv_1")
	return (
		bool(res.get("ok", false))
		and bool(res.get("created", false))
		and bool(res.get("exhaust_changed", false))
		and not bool(res.get("disengaged", false))
		and res.get("mode", &"") == EvadeFlow.MODE_AUTOMATIC
		and enemy.exhausted
		and enemy.engaged_with == &""
	)


func _test_evade_composition_auto() -> bool:
	## Composition automatically_evade → nest 同核。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_enemy(
		h.ctx, &"enemy_1", &"test_loc", 2, 2, &"inv_1"
	)
	var c := CompositionTestHelper.new(h.ctx)
	c.execute(CompositionNode.automatically_evade(&"inv_1", &"enemy_1"))
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	return enemy.exhausted and enemy.engaged_with == &""


func _test_g2_ready_enemy_engages() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	enemy.exhausted = true
	enemy.engaged_with = &""
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.threat_area.erase(&"enemy_1")
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.ready",
		{
			"target_kind": ExhaustReadyFlow.TARGET_ENEMY,
			"enemy_id": &"enemy_1",
			"trigger_area_change": true,
		}
	)
	return (
		bool(res.get("ok", false))
		and bool(res.get("changed", false))
		and not enemy.exhausted
		and enemy.engaged_with == &"inv_1"
	)


func _test_g2_exhaust_card_in_play() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := h.ctx.state.registry.allocate_instance_id(&"asset")
	var card := CardInstance.new()
	card.id = EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"test_asset")
	card.zone = AhcEnums.Zone.PLAY_AREA
	card.controller_id = &"inv_1"
	h.ctx.state.registry.register_card(card)
	var res := ExhaustReadyFlow.nest_or_run_exhaust(
		h.ctx,
		{"target_kind": ExhaustReadyFlow.TARGET_CARD, "card_id": card_id}
	)
	return bool(res.get("ok", false)) and bool(res.get("changed", false)) and card.exhausted


func _test_g2_exhaust_rejects_hand() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	## 入手到手牌区（非平放）。
	inv.deck.erase(card_id)
	inv.hand.append(card_id)
	var card := h.ctx.state.registry.get_card(card_id)
	card.zone = AhcEnums.Zone.HAND
	var res := ExhaustReadyFlow.exhaust(
		h.ctx,
		{"target_kind": ExhaustReadyFlow.TARGET_CARD, "card_id": card_id}
	)
	return (
		not bool(res.get("ok", false))
		and str(res.get("error", "")) == "not_flat_zone"
		and not card.exhausted
	)


func _test_g2_upkeep_ready_flat_cards() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := h.ctx.state.registry.allocate_instance_id(&"asset")
	var card := CardInstance.new()
	card.id = EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"test_asset")
	card.zone = AhcEnums.Zone.PLAY_AREA
	card.exhausted = true
	h.ctx.state.registry.register_card(card)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_1", &"test_loc", 2, 2)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_1")
	enemy.exhausted = true
	var res := ExhaustReadyFlow.ready_all_in_play(h.ctx)
	return (
		bool(res.get("ok", false))
		and not card.exhausted
		and not enemy.exhausted
		and (res.get("readied", []) as Array).has(card_id)
		and (res.get("readied", []) as Array).has(&"enemy_1")
	)


func _test_g3_search_entire_take_shuffle() -> bool:
	var h := RuleTestHarness.new(42)
	var decoy := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_decoy_a")
	var target := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_search_hit")
	var decoy2 := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_decoy_b")
	var before := h.ctx.state.encounter_deck.duplicate()
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.search",
		{
			"controller_id": &"inv_1",
			"area": SearchFlow.AREA_ENCOUNTER_DECK,
			"scope": SearchFlow.SCOPE_ENTIRE,
			"definition_id": &"enc_search_hit",
			"take_count": 1,
		}
	)
	var taken: Array = res.get("taken", [])
	var decoy_card := h.ctx.state.registry.get_card(decoy)
	var target_card := h.ctx.state.registry.get_card(target)
	return (
		bool(res.get("ok", false))
		and bool(res.get("shuffled", false))
		and taken.has(target)
		and not h.ctx.state.encounter_deck.has(target)
		and h.ctx.state.encounter_deck.has(decoy)
		and h.ctx.state.encounter_deck.has(decoy2)
		and h.ctx.state.encounter_deck != before
		and target_card != null
		and target_card.zone == AhcEnums.Zone.LIMBO
		and decoy_card != null
		and decoy_card.controller_id != &"inv_1"
		and decoy_card.face_visibility.audience == AhcEnums.FaceAudience.HIDDEN_ALL
	)


func _test_g3_search_top_shuffles() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_top_a")
	var hit := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_top_hit")
	GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_top_c")
	## 顶 1 张不含 hit（hit 在第 2 张）→ found 空；搜牌库仍须洗。
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.search",
		{
			"controller_id": &"inv_1",
			"area": SearchFlow.AREA_ENCOUNTER_DECK,
			"scope": SearchFlow.SCOPE_TOP,
			"amount": 1,
			"definition_id": &"enc_top_hit",
			"take_count": 1,
		}
	)
	return (
		bool(res.get("ok", false))
		and bool(res.get("shuffled", false))
		and (res.get("found", []) as Array).is_empty()
		and h.ctx.state.encounter_deck.has(hit)
		and h.ctx.state.encounter_deck.size() == 3
	)


func _test_g3_search_catalog() -> bool:
	var h := RuleTestHarness.new(42)
	return h.ctx.sequence_catalog.has_flow(&"seq.effect.search")


func _test_g5_defeat_cancel_no_leave() -> bool:
	var h := RuleTestHarness.new(42)
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_g5_cancel",
		&"test_loc",
		{"enemy": {"fight": 1, "evade": 1, "health": 3}}
	)
	if enemy_id == &"":
		return false
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	enemy.damage = enemy.health
	h.ctx.memory.cancel_sequence(
		&"seq.effect.defeat",
		{"card_id": enemy_id}
	)
	var res := EnemyDefeatResolver.defeat(h.ctx, enemy_id, DefeatFlow.CAUSE_DAMAGE_CAP)
	return (
		bool(res.get("cancelled", false))
		and not bool(res.get("defeated", false))
		and h.ctx.state.registry.get_enemy(enemy_id) != null
	)


func _test_g5_damage_cap_retriggers() -> bool:
	var h := RuleTestHarness.new(42)
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_g5_re",
		&"test_loc",
		{"enemy": {"fight": 1, "evade": 1, "health": 2}}
	)
	if enemy_id == &"":
		return false
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	enemy.damage = enemy.health
	h.ctx.memory.cancel_sequence(
		&"seq.effect.defeat",
		{"card_id": enemy_id}
	)
	var cancelled := EnemyDefeatResolver.defeat(h.ctx, enemy_id, DefeatFlow.CAUSE_DAMAGE_CAP)
	if not bool(cancelled.get("cancelled", false)):
		return false
	if h.ctx.state.registry.get_enemy(enemy_id) == null:
		return false
	## Cancel 已消费；伤仍满血 → 常态检测再次击败并 nest 退场。
	var again := DefeatFlow.check_enemy_damage_cap(h.ctx, enemy_id)
	return (
		bool(again.get("defeated", false))
		and h.ctx.state.registry.get_enemy(enemy_id) == null
	)


func _test_g5_effect_defeat() -> bool:
	var h := RuleTestHarness.new(42)
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_g5_fx",
		&"test_loc",
		{"enemy": {"fight": 1, "evade": 1, "health": 5}}
	)
	if enemy_id == &"":
		return false
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	## 伤未满血仍可被卡面击败。
	enemy.damage = 0
	var res := EnemyDefeatResolver.defeat(h.ctx, enemy_id, DefeatFlow.CAUSE_EFFECT)
	return (
		bool(res.get("defeated", false))
		and h.ctx.state.registry.get_enemy(enemy_id) == null
	)


func _test_g5_investigator_horror_cap() -> bool:
	var h := RuleTestHarness.new(42)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.sanity = 2
	inv.horror_taken = 0
	var applied := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.deal.assignable",
		{
			"controller_id": &"inv_1",
			"kind": &"horror",
			"amount": 2,
			"target": &"controller",
		}
	)
	return (
		bool(applied.get("ok", false))
		and inv.eliminated
		and inv.horror_taken >= inv.sanity
	)


func _test_g5_defeat_catalog() -> bool:
	var h := RuleTestHarness.new(42)
	return (
		h.ctx.sequence_catalog.has_flow(&"seq.effect.defeat")
		and not h.ctx.sequence_catalog.has_flow(&"seq.enemy.defeat")
		and h.ctx.sequence_catalog.has_flow(&"seq.defeat.leave_play")
	)


func _test_g5_enemy_attack_damage_cap() -> bool:
	var h := RuleTestHarness.new(42)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.health = 2
	inv.damage_taken = 0
	var attack := EnemyAttack.enemy_strike(
		&"enemy_atk", &"inv_1", 2, 0, false, AhcEnums.AttackKind.PHASE
	)
	h.ctx.combat.perform_attack(attack)
	return inv.eliminated and inv.damage_taken >= inv.health


func _test_g5_asset_damage_cap() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.memory.clear_trace()
	var card_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_g5_hp", {"health": 2, "sanity": 0}
	)
	var res := DefeatFlow.deal_damage_to_asset(h.ctx, card_id, 2)
	var card := h.ctx.state.registry.get_card(card_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var saw_discard_effect := false
	for entry in h.ctx.memory.phase_trace:
		if str(entry).contains("discard_card"):
			saw_discard_effect = true
			break
	return (
		bool(res.get("defeated", false))
		and card != null
		and card.zone == AhcEnums.Zone.DISCARD
		and inv.discard.has(card_id)
		and not inv.play_area.has(card_id)
		and not bool(res.get("via_discard_effect", true))
		and not saw_discard_effect
	)


func _test_g5_asset_effect_defeat() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_g5_fx", {"health": 5}
	)
	var card := h.ctx.state.registry.get_card(card_id)
	card.tokens.damage = 0
	var res := DefeatFlow.defeat_asset_effect(h.ctx, card_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		bool(res.get("defeated", false))
		and card.zone == AhcEnums.Zone.DISCARD
		and inv.discard.has(card_id)
		and not bool(res.get("via_discard_effect", true))
	)


func _test_g5_asset_cancel_no_leave() -> bool:
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_g5_cancel", {"health": 1}
	)
	var card := h.ctx.state.registry.get_card(card_id)
	card.tokens.damage = 1
	h.ctx.memory.cancel_sequence(&"seq.effect.defeat", {"card_id": card_id})
	var res := DefeatFlow.check_asset_caps(h.ctx, card_id)
	return (
		bool(res.get("cancelled", false))
		and not bool(res.get("defeated", false))
		and card.zone == AhcEnums.Zone.PLAY_AREA
	)


func _test_g5_unowned_story_asset_removed() -> bool:
	## 无玩家所有者的剧情支援击败 → 从游戏中移除（FAQ · Lita Chantler 01117）。
	var h := RuleTestHarness.new(42)
	CardRegistry.register_definition(
		&"story_asset_g5",
		{"card_type": &"asset", "health": 1, "encounter_code": &"story"}
	)
	var card_id := h.ctx.state.registry.allocate_instance_id(&"card")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, card_id, &"story_asset_g5")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &""
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.PLAY_AREA
	h.ctx.state.registry.register_card(card)
	var res := DefeatFlow.defeat_asset_effect(h.ctx, card_id)
	return (
		bool(res.get("defeated", false))
		and res.get("dest", &"") == &"removed_from_game"
		and card.zone == AhcEnums.Zone.REMOVED_FROM_GAME
		and h.ctx.state.removed_from_game.has(card_id)
		and not h.ctx.state.set_aside.has(card_id)
	)


func _test_g5_weakness_enemy_owner_discard() -> bool:
	## 弱点敌人击败 → 所有者弃牌堆（非遭遇弃牌）。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"test_loc", 0, 0)
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx, &"weak_enemy_g5", {"health": 1}
	)
	var card := h.ctx.state.registry.get_card(card_id)
	card.owner_id = &"inv_1"
	var spawn := h.ctx.enemy.spawn_at_location(h.ctx, card_id, &"test_loc")
	if not spawn.get("ok", false):
		return false
	var res := DefeatFlow.defeat_enemy_effect(h.ctx, card_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		bool(res.get("defeated", false))
		and not bool(res.get("victory_display", false))
		and inv.discard.has(card_id)
		and not h.ctx.state.encounter_discard.has(card_id)
	)


func _test_g5_vengeance_to_victory_display() -> bool:
	## 复仇指示 → 胜利区（同 Victory）。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"test_loc", 0, 0)
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx,
		&"en_vengeance_g5",
		{"health": 1, "vengeance": 2}
	)
	CardRegistry.patch_definition(&"en_vengeance_g5", {"vengeance": 2, "health": 1})
	var spawn := h.ctx.enemy.spawn_at_location(h.ctx, card_id, &"test_loc")
	if not spawn.get("ok", false):
		return false
	var res := DefeatFlow.defeat_enemy_effect(h.ctx, card_id)
	var card := h.ctx.state.registry.get_card(card_id)
	return (
		bool(res.get("defeated", false))
		and bool(res.get("victory_display", false))
		and h.ctx.state.victory_display.has(card_id)
		and card != null
		and card.zone == AhcEnums.Zone.VICTORY_DISPLAY
	)


func _test_zm_catalog() -> bool:
	var h := RuleTestHarness.new(42)
	return h.ctx.sequence_catalog.has_flow(&"seq.zone.move")


func _test_zm_leave_play_discard_asset() -> bool:
	var h := RuleTestHarness.new(42)
	var store := h.ctx.registrations
	var card_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_zm_leave", {"health": 1}
	)
	_kw_occ_bind(store, AhcEnums.LifetimeKind.WHILE_IN_PLAY, card_id)
	if store.count() != 1:
		return false
	var moved := h.ctx.mutator.move_card(card_id, CardSlot.discard_top(&"inv_1"))
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		moved
		and store.count() == 0
		and inv.discard.has(card_id)
		and not inv.play_area.has(card_id)
	)


func _test_zm_enemy_discard_leave_play() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"test_loc", 0, 0)
	var card_id := GameBootstrap.add_encounter_enemy_to_deck(
		h.ctx, &"enc_zm_discard", {"health": 1}
	)
	var spawn := h.ctx.enemy.spawn_at_location(h.ctx, card_id, &"test_loc")
	if not spawn.get("ok", false):
		return false
	var store := h.ctx.registrations
	_kw_occ_bind(store, AhcEnums.LifetimeKind.WHILE_IN_PLAY, card_id)
	if store.count() != 1:
		return false
	var res := EnemyDefeatResolver.discard_from_play(h.ctx, card_id)
	return (
		bool(res.get("ok", false))
		and store.count() == 0
		and h.ctx.state.registry.get_enemy(card_id) == null
	)


func _test_zm_leave_play_tokens_to_pool() -> bool:
	## 01 §5.2 / Grimoire Leaves Play：离场卡上标记经 transfer_marker 归还无穷池（卡面剥光）。
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_zm_tokens", {"health": 3, "sanity": 3}
	)
	var card := h.ctx.state.registry.get_card(card_id)
	if card == null:
		return false
	card.tokens.damage = 2
	card.tokens.horror = 1
	card.tokens.clue = 3
	card.tokens.doom = 1
	card.tokens.uses[&"ammo"] = 4
	var moved := h.ctx.mutator.move_card(card_id, CardSlot.discard_top(&"inv_1"))
	return (
		moved
		and card.tokens.damage == 0
		and card.tokens.horror == 0
		and card.tokens.clue == 0
		and card.tokens.doom == 0
		and card.tokens.uses.is_empty()
	)


func _test_zm_leave_play_discards_attachments() -> bool:
	## 宿主离场 → 附属同时弃置（遭遇附属进遭遇弃牌堆）。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_location(h.ctx, &"test_loc", 2, 1)
	var host_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"asset_zm_host", {"health": 1}
	)
	var host := h.ctx.state.registry.get_card(host_id)
	if host == null:
		return false
	var fire_id := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_zm_attach_fire", [])
	## 直接挂到支援上（跳过 limbo→地点路径）。
	var fire := h.ctx.state.registry.get_card(fire_id)
	if fire == null:
		return false
	h.ctx.state.encounter_deck.erase(fire_id)
	fire.zone = AhcEnums.Zone.ATTACHED
	fire.attached_to = host.id
	host.attachments.append(fire.id)
	## 附属上亦有标记，弃置（ATTACHED leave）时应剥光。
	fire.tokens.damage = 1
	var moved := h.ctx.mutator.move_card(host_id, CardSlot.discard_top(&"inv_1"))
	var fire_after := h.ctx.state.registry.get_card(fire_id)
	return (
		moved
		and host.attachments.is_empty()
		and fire_after != null
		and fire_after.attached_to == null
		and fire_after.zone == AhcEnums.Zone.DISCARD
		and h.ctx.state.encounter_discard.has(fire_id)
		and fire_after.tokens.damage == 0
	)


func _test_zm_defeat_asset_leave_cleanup() -> bool:
	## 击败 nest 退场：宿主标记剥光 + 附属弃置（同 LEAVE_PLAY 捆绑）。
	var h := RuleTestHarness.new(42)
	var host_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"asset_zm_defeat_host", {"health": 2}
	)
	var host := h.ctx.state.registry.get_card(host_id)
	if host == null:
		return false
	host.tokens.damage = 2
	host.tokens.clue = 1
	host.tokens.uses[&"ammo"] = 2
	var fire_id := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"enc_zm_defeat_attach", [])
	var fire := h.ctx.state.registry.get_card(fire_id)
	if fire == null:
		return false
	h.ctx.state.encounter_deck.erase(fire_id)
	fire.zone = AhcEnums.Zone.ATTACHED
	fire.attached_to = host.id
	host.attachments.append(fire.id)
	fire.tokens.horror = 1
	var res := DefeatFlow.check_asset_caps(h.ctx, host_id)
	var fire_after := h.ctx.state.registry.get_card(fire_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		bool(res.get("defeated", false))
		and host.zone == AhcEnums.Zone.DISCARD
		and inv.discard.has(host_id)
		and host.tokens.damage == 0
		and host.tokens.clue == 0
		and host.tokens.uses.is_empty()
		and host.attachments.is_empty()
		and fire_after != null
		and fire_after.zone == AhcEnums.Zone.DISCARD
		and h.ctx.state.encounter_discard.has(fire_id)
		and fire_after.tokens.horror == 0
	)


func _test_g6_phase_boundary_catalog() -> bool:
	var h := RuleTestHarness.new(42)
	var mythos_begins := PhaseBoundaryFlow.params_for_step(
		AhcEnums.FrameworkStep.MYTHOS_1_1_PHASE_BEGINS
	)
	var inv_ends := PhaseBoundaryFlow.params_for_step(
		AhcEnums.FrameworkStep.INV_2_3_PHASE_ENDS
	)
	return (
		h.ctx.sequence_catalog.has_flow(PhaseBoundaryFlow.FLOW)
		and not h.ctx.sequence_catalog.has_flow(
			&"seq.framework.investigation_phase_ends"
		)
		and mythos_begins.get("phase", &"") == PhaseBoundaryFlow.PHASE_MYTHOS
		and mythos_begins.get("boundary", &"") == PhaseBoundaryFlow.BOUNDARY_BEGINS
		and inv_ends.get("phase", &"") == PhaseBoundaryFlow.PHASE_INVESTIGATION
		and inv_ends.get("boundary", &"") == PhaseBoundaryFlow.BOUNDARY_ENDS
	)


func _test_g6_framework_emits() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.memory.clear_trace()
	h.ctx.framework._on_enter_step(AhcEnums.FrameworkStep.MYTHOS_1_1_PHASE_BEGINS)
	h.ctx.framework._on_enter_step(AhcEnums.FrameworkStep.ENEMY_3_1_PHASE_BEGINS)
	h.ctx.framework._on_enter_step(AhcEnums.FrameworkStep.UPKEEP_4_6_PHASE_ENDS)
	var saw_mythos := false
	var saw_enemy := false
	var saw_upkeep := false
	for entry in h.ctx.memory.phase_trace:
		var s := str(entry)
		if s.contains("mythos_phase_begins"):
			saw_mythos = true
		if s.contains("enemy_phase_begins"):
			saw_enemy = true
		if s.contains("upkeep_phase_ends"):
			saw_upkeep = true
	return saw_mythos and saw_enemy and saw_upkeep


func _test_ev_catalog() -> bool:
	var h := RuleTestHarness.new(42)
	return h.ctx.sequence_catalog.has_flow(&"seq.effect.evade")


func _test_ev_action_nests_effect() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(
		h.ctx, &"enemy_ev", &"test_loc", 2, 1, &"inv_1"
	)
	h.ctx.memory.clear_trace()
	var res := h.evade_action({"enemy_id": &"enemy_ev"})
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_ev")
	var saw_evade := false
	for entry in h.ctx.memory.phase_trace:
		if str(entry).contains("evade_effect"):
			saw_evade = true
			break
	return (
		res.ok
		and res.success
		and enemy != null
		and enemy.exhausted
		and enemy.engaged_with == &""
		and saw_evade
	)


func _test_ev_automatically_evade() -> bool:
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_enemy(
		h.ctx, &"enemy_auto_ev", &"test_loc", 2, 99, &"inv_1"
	)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_auto_ev")
	## 难度极高：若走检定几乎必失败；自动躲避不检定。
	var res := EvadeFlow.automatically_evade(h.ctx, &"enemy_auto_ev", &"inv_1")
	return (
		bool(res.get("ok", false))
		and bool(res.get("automatic", false))
		and enemy.exhausted
		and enemy.engaged_with == &""
	)


func _test_ev_mode_effect_normalizes() -> bool:
	## 卡面「evade」不作独立执行 mode；历史 mode=effect → automatic。
	if EvadeFlow.normalize_mode(&"effect") != EvadeFlow.MODE_AUTOMATIC:
		return false
	if EvadeFlow.normalize_mode(&"") != EvadeFlow.MODE_AUTOMATIC:
		return false
	if EvadeFlow.normalize_mode(EvadeFlow.MODE_ATTEMPT) != EvadeFlow.MODE_ATTEMPT:
		return false
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_test_enemy(
		h.ctx, &"enemy_legacy_ev", &"test_loc", 2, 99, &"inv_1"
	)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_legacy_ev")
	var res := EvadeFlow.nest_or_run(
		h.ctx,
		{
			"enemy_id": &"enemy_legacy_ev",
			"controller_id": &"inv_1",
			"mode": &"effect",
		}
	)
	return (
		bool(res.get("ok", false))
		and bool(res.get("automatic", false))
		and str(res.get("mode", &"")) == str(EvadeFlow.MODE_AUTOMATIC)
		and enemy.exhausted
		and enemy.engaged_with == &""
	)


func _test_i2_vacuum_execute_refused() -> bool:
	## 栈空时裸 execute 不得改局面。
	var h := RuleTestHarness.new(42)
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	if h.ctx.sequences.depth() != 0:
		return false
	var ok := h.ctx.composition.execute(CompositionNode.nest_draw_investigator(&"inv_1"))
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return not ok and inv.hand.is_empty() and inv.deck.size() == 1


func _test_i2_mount_nests_frame() -> bool:
	## Mount → seq.ability.resolve → 栈上 execute 可落地。
	var h := RuleTestHarness.new(42)
	GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1")
	var before := _sequence_kind_count(h, &"ability_resolve")
	var mounted := CompositionMount.resolve_ability(
		h.ctx, CompositionNode.nest_draw_investigator(&"inv_1"), &"inv_1"
	)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		mounted
		and inv.hand.size() == 1
		and _sequence_kind_count(h, &"ability_resolve") > before
	)


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
	var trauma_before := inv.mental_trauma
	var res := h.draw_action()
	return (
		res.ok
		and res.defeated
		and inv.eliminated
		and inv.mental_trauma == trauma_before + 1
	)


func _test_act_catalog_registered() -> bool:
	var h := RuleTestHarness.new(42)
	var catalog := h.ctx.sequence_catalog
	var flows: Array[StringName] = [
		&"seq.interrupt.cancel",
		&"seq.interrupt.ignore",
		&"seq.replace.instead",
		&"seq.action.draw",
		&"seq.action.gain_resource",
		&"seq.effect.gain_resource",
		&"seq.action.move",
		&"seq.effect.move",
		&"seq.effect.exhaust",
		&"seq.effect.ready",
		&"seq.effect.search",
		&"seq.effect.defeat",
		&"seq.defeat.leave_play",
		&"seq.zone.move",
		&"seq.action.investigate",
		&"seq.action.fight",
		&"seq.action.engage",
		&"seq.engage",
		&"seq.action.evade",
		&"seq.effect.evade",
		&"seq.effect.discover_clue",
	]
	for flow_id in flows:
		if not catalog.has_flow(flow_id):
			return false
	return h.ctx.action_sequences != null


## 22 / bootstrap 全量对照：必有正式 id；别名 / 已废 / 刻意不铸不得注册。
func _test_seq_audit_catalog_inventory() -> bool:
	var h := RuleTestHarness.new(42)
	var catalog := h.ctx.sequence_catalog
	var required: Array[StringName] = [
		&"seq.ability.resolve",
		&"seq.act.advance",
		&"seq.act_agenda.resolve_back",
		&"seq.action.draw",
		&"seq.action.engage",
		&"seq.action.evade",
		&"seq.action.fight",
		&"seq.action.gain_resource",
		&"seq.action.investigate",
		&"seq.action.move",
		&"seq.agenda.advance",
		&"seq.chaos.reveal",
		&"seq.chaos.symbol",
		&"seq.defeat.leave_play",
		&"seq.draw.empty_piles_defeated",
		&"seq.draw.encounter",
		&"seq.draw.investigator",
		&"seq.effect.attach",
		&"seq.effect.deal",
		&"seq.effect.deal.assignable",
		&"seq.effect.defeat",
		&"seq.effect.discard_card",
		&"seq.effect.discover_clue",
		&"seq.effect.evade",
		&"seq.effect.exhaust",
		&"seq.effect.gain_resource",
		&"seq.effect.heal",
		&"seq.effect.lose_action",
		&"seq.effect.lose_resources",
		&"seq.effect.move",
		&"seq.effect.place_clue",
		&"seq.effect.place_doom",
		&"seq.effect.ready",
		&"seq.effect.register",
		&"seq.effect.release_seal",
		&"seq.effect.resign",
		&"seq.effect.reveal_location",
		&"seq.effect.seal",
		&"seq.effect.search",
		&"seq.effect.unregister",
		&"seq.encounter.resolve_card",
		&"seq.encounter.revelation",
		&"seq.encounter.spawn",
		&"seq.enemy.3_2",
		&"seq.enemy.attack",
		&"seq.enemy.phase_attacks",
		&"seq.enemy.resolve_location",
		&"seq.engage",
		&"seq.enter_hand",
		&"seq.framework.phase_boundary",
		&"seq.interrupt.cancel",
		&"seq.interrupt.ignore",
		&"seq.keyword.hunter",
		&"seq.keyword.massive",
		&"seq.keyword.patrol",
		&"seq.keyword.surge",
		&"seq.mythos.check_doom_threshold",
		&"seq.mythos.place_doom",
		&"seq.replace.instead",
		&"seq.skill_test",
		&"seq.zone.move",
	]
	var forbidden: Array[StringName] = [
		&"seq.effect.discard_from_hand",
		&"seq.effect.damage",
		&"seq.effect.damage.assignable",
		&"seq.enemy.defeat",
		&"seq.enemy.move",
		&"seq.enemy.massive_phase_attacks",
		&"seq.enemy.3_2_hunter_patrol",
		&"seq.enemy.3_2_patrol",
		&"seq.draw.encounter.resolve_bound",
		&"seq.effect.enter_play",
		&"seq.effect.spend_token",
		&"seq.framework.investigation_phase_ends",
		&"seq.gain_resource",
		&"seq.aoo",
		&"seq.play",
		&"seq.commit",
		&"seq.spend",
		&"seq.peril.check",
		&"seq.skill_test.intellect",
		&"seq.skill_test.combat",
		&"seq.skill_test.agility",
		&"seq.setup",
	]
	if required.size() != 61:
		return false
	for flow_id in required:
		if not catalog.has_flow(flow_id):
			return false
	for flow_id in forbidden:
		if catalog.has_flow(flow_id):
			return false
	var registered := catalog.registered_flow_ids()
	if registered.size() != required.size():
		return false
	return true


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
	var before := h.ctx.state.registry.get_card(card_id)
	if before == null or before.zone != AhcEnums.Zone.DECK:
		return false
	var res := h.ctx.draw_investigator.draw_cards(h.ctx, &"inv_1", 1, [&"test"])
	var revelations: Array = res.get("revelations", [])
	var after := h.ctx.state.registry.get_card(card_id)
	return (
		res.ok
		and res.drew
		and inv.hand.has(card_id)
		and after != null
		and after.zone == AhcEnums.Zone.HAND
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


func _test_draw_when_zones() -> bool:
	var h := RuleTestHarness.new(42)
	var player_id := GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1", &"plain_weakness")
	var player_card := h.ctx.state.registry.get_card(player_id)
	if player_card == null or player_card.zone != AhcEnums.Zone.DECK:
		return false
	var player_res := h.ctx.draw_investigator.draw_cards(h.ctx, &"inv_1", 1, [&"test"])
	if not player_res.ok or player_card.zone != AhcEnums.Zone.HAND:
		return false
	var enc_id := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"zone_treachery")
	var enc_card := h.ctx.state.registry.get_card(enc_id)
	if enc_card == null or enc_card.zone != AhcEnums.Zone.DECK:
		return false
	if h.ctx.mutator.pop_encounter_deck_top() != enc_id:
		return false
	return enc_card.zone == AhcEnums.Zone.LIMBO


func _test_tim_draw_investigator_split() -> bool:
	## TIM-01：信封 WOULD 时仍在 DECK；中段 WHEN 时已在 HAND；显现在 WHEN 之后。
	var h := RuleTestHarness.new(42)
	h.ctx.memory.clear_trace()
	var card_id := GameBootstrap.add_test_card_to_deck(h.ctx, &"inv_1", &"tim_plain")
	var card := h.ctx.state.registry.get_card(card_id)
	var zones := {"would": AhcEnums.Zone.REMOVED_FROM_GAME, "when": AhcEnums.Zone.REMOVED_FROM_GAME}
	h.ctx.sequences.register_handler(
		SequenceHandler.would_forced(
			&"draw_investigator",
			func() -> void: zones["would"] = card.zone
		)
	)
	h.ctx.sequences.register_handler(
		SequenceHandler.when_forced(
			&"draw_investigator",
			func() -> void: zones["when"] = card.zone
		)
	)
	var res := h.ctx.draw_investigator.draw_cards(h.ctx, &"inv_1", 1, [&"test"])
	var trace := h.ctx.memory.phase_trace
	var would_i := -1
	var when_i := -1
	var resolve_i := -1
	var after_i := -1
	for i in range(trace.size()):
		var line := str(trace[i])
		if line.begins_with("WOULD:draw_investigator@"):
			would_i = i
		elif line.begins_with("WHEN:draw_investigator@"):
			when_i = i
		elif line.begins_with("RESOLVE:draw_investigator@") and resolve_i < 0:
			resolve_i = i
		elif line.begins_with("AFTER:draw_investigator@"):
			after_i = i
	return (
		res.get("ok", false)
		and zones["would"] == AhcEnums.Zone.DECK
		and zones["when"] == AhcEnums.Zone.HAND
		and card.zone == AhcEnums.Zone.HAND
		and would_i >= 0
		and when_i >= 0
		and resolve_i >= 0
		and after_i >= 0
		## 信封 WOULD → RESOLVE → 砖块 WHEN → AFTER
		and would_i < resolve_i
		and resolve_i < when_i
		and when_i < after_i
	)


func _test_tim_draw_encounter_split() -> bool:
	## TIM-02：WOULD 时仍在 DECK；WHEN 时已在 LIMBO；显现尚未开始。
	var h := RuleTestHarness.new(42)
	h.ctx.memory.clear_trace()
	var card_id := GameBootstrap.add_encounter_card_to_deck(h.ctx, &"tim_enc_plain")
	var card := h.ctx.state.registry.get_card(card_id)
	var zones := {"would": AhcEnums.Zone.REMOVED_FROM_GAME, "when": AhcEnums.Zone.REMOVED_FROM_GAME}
	var revelation_started := [false]
	var when_before_rev := [true]
	CardRegistry.register_revelation(
		&"tim_enc_plain",
		&"revelation:0",
		func(_bind: AbilityBindContext) -> CompositionNode:
			revelation_started[0] = true
			return CompositionNode.seq([])
	)
	var would_enc := SequenceHandler.would_forced(
		&"draw_encounter",
		func() -> void: zones["would"] = card.zone
	)
	var when_enc := SequenceHandler.when_forced(
		&"draw_encounter",
		func() -> void: pass
	)
	when_enc.callback = func() -> void:
		zones["when"] = card.zone
		when_before_rev[0] = not revelation_started[0]
	h.ctx.sequences.register_handler(would_enc)
	h.ctx.sequences.register_handler(when_enc)
	var res := h.ctx.draw_encounter.draw_one(h.ctx, &"inv_1")
	var trace := h.ctx.memory.phase_trace
	var would_i := -1
	var when_i := -1
	var resolve_i := -1
	for i in range(trace.size()):
		var line := str(trace[i])
		if line.begins_with("WOULD:draw_encounter@"):
			would_i = i
		elif line.begins_with("WHEN:draw_encounter@"):
			when_i = i
		elif line.begins_with("RESOLVE:draw_encounter@") and resolve_i < 0:
			resolve_i = i
	return (
		res.get("ok", false)
		and zones["would"] == AhcEnums.Zone.DECK
		and zones["when"] == AhcEnums.Zone.LIMBO
		and when_before_rev[0]
		and would_i >= 0
		and when_i >= 0
		and resolve_i >= 0
		and would_i < resolve_i
		and resolve_i < when_i
		and revelation_started[0]
	)


func _test_tim_dmg_apply_slots() -> bool:
	## TIM-DMG-01：Assign 非时点；WOULD→WHEN 均在 Apply 前（pending、未写入）；AFTER 时已写入。
	var h := RuleTestHarness.new(42)
	h.ctx.memory.clear_trace()
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var snap := {
		"would_dmg": -1,
		"would_pending": -1,
		"when_dmg": -1,
		"when_pending": -1,
		"after_dmg": -1,
	}
	var would_h := SequenceHandler.would_forced(&"damage", func() -> void: pass)
	would_h.callback = func() -> void:
		snap["would_dmg"] = inv.damage_taken
		snap["would_pending"] = DamagePipeline.pending_amount(h.ctx, &"inv_1")
	h.ctx.sequences.register_handler(would_h)
	var when_h := SequenceHandler.when_forced(&"damage", func() -> void: pass)
	when_h.callback = func() -> void:
		snap["when_dmg"] = inv.damage_taken
		snap["when_pending"] = DamagePipeline.pending_amount(h.ctx, &"inv_1")
	h.ctx.sequences.register_handler(when_h)
	h.ctx.sequences.register_handler(
		SequenceHandler.after_forced(
			&"damage",
			func() -> void: snap["after_dmg"] = inv.damage_taken
		)
	)
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.deal.assignable",
		{"controller_id": &"inv_1", "kind": &"damage", "amount": 2}
	)
	var trace := h.ctx.memory.phase_trace
	var would_i := -1
	var when_i := -1
	var resolve_i := -1
	var after_i := -1
	for i in range(trace.size()):
		var line := str(trace[i])
		if line.begins_with("WOULD:damage@"):
			would_i = i
		elif line.begins_with("WHEN:damage@"):
			when_i = i
		elif line.begins_with("RESOLVE:damage@") and resolve_i < 0:
			resolve_i = i
		elif line.begins_with("AFTER:damage@"):
			after_i = i
	return (
		bool(res.get("ok", false))
		and int(res.get("amount", 0)) == 2
		and snap["would_dmg"] == 0
		and snap["would_pending"] == 2
		and snap["when_dmg"] == 0
		and snap["when_pending"] == 2
		and snap["after_dmg"] == 2
		and inv.damage_taken == 2
		and would_i >= 0
		and when_i >= 0
		and resolve_i >= 0
		and after_i >= 0
		and resolve_i < would_i
		and would_i < when_i
		and when_i < after_i
	)


func _test_tim_dmg_prevent() -> bool:
	## TIM-DMG-02：WOULD 内 reduce_pending → Apply 写入量减少；WHEN 仍见已降低的 pending。
	var h := RuleTestHarness.new(42)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var when_pending := {"n": -1}
	h.ctx.sequences.register_handler(
		SequenceHandler.would_forced(
			&"damage",
			func() -> void: DamagePipeline.reduce_pending(h.ctx, &"inv_1", 1)
		)
	)
	var when_h := SequenceHandler.when_forced(&"damage", func() -> void: pass)
	when_h.callback = func() -> void:
		when_pending["n"] = DamagePipeline.pending_amount(h.ctx, &"inv_1")
	h.ctx.sequences.register_handler(when_h)
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.deal.assignable",
		{"controller_id": &"inv_1", "kind": &"horror", "amount": 2}
	)
	return (
		bool(res.get("ok", false))
		and int(res.get("amount", 0)) == 1
		and when_pending["n"] == 1
		and inv.horror_taken == 1
	)


func _test_tim_dmg_increase_pending() -> bool:
	## TIM-DMG-03：WHEN 内 increase_pending(+2)（02221）；同实例量 2→4，Apply 写入 4。
	var h := RuleTestHarness.new(42)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var when_pending := {"n": -1}
	var when_h := SequenceHandler.when_forced(&"damage", func() -> void: pass)
	when_h.callback = func() -> void:
		DamagePipeline.increase_pending(h.ctx, &"inv_1", 2)
		when_pending["n"] = DamagePipeline.pending_amount(h.ctx, &"inv_1")
	h.ctx.sequences.register_handler(when_h)
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.deal.assignable",
		{"controller_id": &"inv_1", "kind": &"damage", "amount": 2}
	)
	return (
		bool(res.get("ok", false))
		and int(res.get("amount", 0)) == 4
		and when_pending["n"] == 4
		and inv.damage_taken == 4
	)


func _test_tim_dmg_increase_keeps_legs() -> bool:
	## TIM-DMG-04：已确认 N 腿（资产+调查员）保留；K 默认进调查员；不推翻资产腿。
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_inc_dmg", {"health": 3, "sanity": 0}
	)
	var snap := {"asset_n": -1, "inv_n": -1, "pending": -1}
	var would_h := SequenceHandler.would_forced(&"damage", func() -> void: pass)
	would_h.callback = func() -> void:
		## 模拟已确认 Assign：1 资产 + 1 调查员。
		DamagePipeline.reassign_pending_legs(
			h.ctx,
			&"inv_1",
			[
				{"bearer": &"card", "id": card_id, "amount": 1},
				{"bearer": &"investigator", "id": &"inv_1", "amount": 1},
			]
		)
	h.ctx.sequences.register_handler(would_h)
	var when_h := SequenceHandler.when_forced(&"damage", func() -> void: pass)
	when_h.callback = func() -> void:
		DamagePipeline.increase_pending(h.ctx, &"inv_1", 2)
		var legs := DamagePipeline.pending_legs(h.ctx, &"inv_1")
		snap["asset_n"] = _asn_leg_amount(legs, &"card", card_id)
		snap["inv_n"] = _asn_leg_amount(legs, &"investigator", &"inv_1")
		snap["pending"] = DamagePipeline.pending_amount(h.ctx, &"inv_1")
	h.ctx.sequences.register_handler(when_h)
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.deal.assignable",
		{"controller_id": &"inv_1", "kind": &"damage", "amount": 2}
	)
	var card := h.ctx.state.registry.get_card(card_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		bool(res.get("ok", false))
		and int(res.get("amount", 0)) == 4
		and snap["pending"] == 4
		and snap["asset_n"] == 1
		and snap["inv_n"] == 3
		and card != null
		and card.tokens.damage == 1
		and inv.damage_taken == 3
	)


func _asn_leg_amount(legs: Array, bearer: StringName, id: StringName) -> int:
	var total := 0
	for leg in legs:
		if not (leg is Dictionary):
			continue
		if (leg as Dictionary).get("bearer", &"") != bearer:
			continue
		if (leg as Dictionary).get("id", &"") != id:
			continue
		total += int((leg as Dictionary).get("amount", 0))
	return total


func _test_tim_dmg_outbound_preimpact() -> bool:
	## TIM-DMG-05：已定敌腿 WOULD→WHEN 在 Apply 前（pending 未写入）。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_pre", &"test_loc", 2, 2)
	h.ctx.state.registry.get_enemy(&"enemy_pre").health = 10
	h.ctx.memory.clear_trace()
	var snap := {"would_dmg": -1, "would_pending": -1, "when_dmg": -1, "after_dmg": -1}
	var would_h := SequenceHandler.would_forced(&"damage", func() -> void: pass)
	would_h.callback = func() -> void:
		snap["would_dmg"] = h.ctx.state.registry.get_enemy(&"enemy_pre").damage
		snap["would_pending"] = DealPreImpact.pending_amount(h.ctx, &"inv_1")
	h.ctx.sequences.register_handler(would_h)
	var when_h := SequenceHandler.when_forced(&"damage", func() -> void: pass)
	when_h.callback = func() -> void:
		snap["when_dmg"] = h.ctx.state.registry.get_enemy(&"enemy_pre").damage
	h.ctx.sequences.register_handler(when_h)
	h.ctx.sequences.register_handler(
		SequenceHandler.after_forced(
			&"damage",
			func() -> void: snap["after_dmg"] = h.ctx.state.registry.get_enemy(&"enemy_pre").damage
		)
	)
	var nest_res: Variant = h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.deal",
		{
			"controller_id": &"inv_1",
			"kind": &"damage",
			"target": &"subjects",
			"legs": [{"id": &"enemy_pre", "amount": 2}],
		}
	)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_pre")
	return (
		nest_res is Dictionary
		and int((nest_res as Dictionary).get("amount", 0)) == 2
		and snap["would_dmg"] == 0
		and snap["would_pending"] == 2
		and snap["when_dmg"] == 0
		and snap["after_dmg"] == 2
		and enemy.damage == 2
	)


func _test_tim_dmg_outbound_reduce() -> bool:
	## TIM-DMG-06：外向 WOULD reduce_pending → Apply 量减少。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_red", &"test_loc", 2, 2)
	h.ctx.state.registry.get_enemy(&"enemy_red").health = 10
	h.ctx.sequences.register_handler(
		SequenceHandler.would_forced(
			&"damage",
			func() -> void: DealPreImpact.reduce_pending(h.ctx, &"inv_1", 1)
		)
	)
	var nest_res: Variant = h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.deal",
		{
			"controller_id": &"inv_1",
			"kind": &"damage",
			"target": &"subjects",
			"legs": [{"id": &"enemy_red", "amount": 3}],
		}
	)
	var enemy := h.ctx.state.registry.get_enemy(&"enemy_red")
	return (
		nest_res is Dictionary
		and int((nest_res as Dictionary).get("amount", 0)) == 2
		and enemy.damage == 2
	)


func _test_tim_dmg_after_affliction_filters() -> bool:
	## TIM-DMG-07：受到伤害后 / 恐惧后 / 伤害和或恐惧后 = 同一 AFTER 时点、不同条件。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var counts := {"dmg": 0, "hor": 0, "either": 0}
	h.ctx.sequences.register_handler(
		SequenceHandler.after_take_damage(
			func() -> void: counts["dmg"] = int(counts["dmg"]) + 1
		)
	)
	h.ctx.sequences.register_handler(
		SequenceHandler.after_take_horror(
			func() -> void: counts["hor"] = int(counts["hor"]) + 1
		)
	)
	h.ctx.sequences.register_handler(
		SequenceHandler.after_take_damage_or_horror(
			func() -> void: counts["either"] = int(counts["either"]) + 1
		)
	)
	## 仅伤害 → dmg+either；恐不触发。
	h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.deal.assignable",
		{"controller_id": &"inv_1", "damage": 1, "horror": 0}
	)
	if counts["dmg"] != 1 or counts["hor"] != 0 or counts["either"] != 1:
		return false
	## 仅恐惧 → hor+either；伤条件不触发。
	h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.deal.assignable",
		{"controller_id": &"inv_1", "damage": 0, "horror": 1}
	)
	if counts["dmg"] != 1 or counts["hor"] != 1 or counts["either"] != 2:
		return false
	## 伤+恐同帧 → 三者各 +1（仍一条 AFTER）。
	h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.deal.assignable",
		{"controller_id": &"inv_1", "damage": 1, "horror": 1}
	)
	return counts["dmg"] == 2 and counts["hor"] == 2 and counts["either"] == 3


func _test_tim_dmg_after_take_after_defeat() -> bool:
	## TIM-DMG-08：致命承伤 → 击败 nest AFTER 先于父 deal AFTER take。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	inv.health = 2
	inv.damage_taken = 0
	var order: Array = []
	h.ctx.sequences.register_handler(
		SequenceHandler.after_forced(
			&"defeat",
			func() -> void: order.append(&"defeat")
		)
	)
	h.ctx.sequences.register_handler(
		SequenceHandler.after_take_damage(
			func() -> void: order.append(&"take")
		)
	)
	h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.deal.assignable",
		{"controller_id": &"inv_1", "damage": 2, "horror": 0}
	)
	return (
		order.size() >= 2
		and order[0] == &"defeat"
		and order[order.size() - 1] == &"take"
		and inv.eliminated
	)


func _test_asn_prior_fill() -> bool:
	## ASN-01 · 03109：PRIOR_FILL horror → 先填满资产神智，剩余归调查员。
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_asn_prior", {"health": 0, "sanity": 2}
	)
	h.ctx.registrations.register(
		RegistrationTemplate.assign_constraint_while_in_play(
			RestrictionPayload.assign_prior_fill(card_id, &"inv_1", &"horror")
		)
	)
	var legs := DamageAssigner.default_assignment(h.ctx, &"inv_1", &"horror", 3, false)
	return (
		_asn_leg_amount(legs, &"card", card_id) == 2
		and _asn_leg_amount(legs, &"investigator", &"inv_1") == 1
		and DamageAssigner.validate(h.ctx, &"inv_1", &"horror", false, 3, legs)
	)


func _test_asn_min_to_subject() -> bool:
	## ASN-02 · 09007：MIN_TO_SUBJECT damage 1 if_able。
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_asn_min", {"health": 2, "sanity": 0}
	)
	h.ctx.registrations.register(
		RegistrationTemplate.assign_constraint_while_in_play(
			RestrictionPayload.assign_min_to_subject(card_id, &"inv_1", 1, &"damage")
		)
	)
	var legs := DamageAssigner.default_assignment(h.ctx, &"inv_1", &"damage", 3, false)
	var bad_all_inv := [{"bearer": &"investigator", "id": &"inv_1", "amount": 3}]
	return (
		_asn_leg_amount(legs, &"card", card_id) == 1
		and _asn_leg_amount(legs, &"investigator", &"inv_1") == 2
		and DamageAssigner.validate(h.ctx, &"inv_1", &"damage", false, 3, legs)
		and not DamageAssigner.validate(h.ctx, &"inv_1", &"damage", false, 3, bad_all_inv)
	)


func _test_asn_max_to_match() -> bool:
	## ASN-03 · 60232：MAX_TO_MATCH trait Miskatonic ≤ 1。
	var h := RuleTestHarness.new(42)
	var a := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_asn_misk_a",
		{"health": 3, "sanity": 0, "traits": [&"Miskatonic"]}
	)
	var b := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_asn_misk_b",
		{"health": 3, "sanity": 0, "traits": [&"Miskatonic"]}
	)
	h.ctx.registrations.register(
		RegistrationTemplate.assign_constraint_while_in_play(
			RestrictionPayload.assign_max_to_match(&"inv_1", &"Miskatonic", 1, &"either")
		)
	)
	var ok_one := [
		{"bearer": &"card", "id": a, "amount": 1},
		{"bearer": &"investigator", "id": &"inv_1", "amount": 2},
	]
	var bad_two := [
		{"bearer": &"card", "id": a, "amount": 1},
		{"bearer": &"card", "id": b, "amount": 1},
		{"bearer": &"investigator", "id": &"inv_1", "amount": 1},
	]
	var default_legs := DamageAssigner.default_assignment(h.ctx, &"inv_1", &"damage", 3, false)
	return (
		DamageAssigner.validate(h.ctx, &"inv_1", &"damage", false, 3, ok_one)
		and not DamageAssigner.validate(h.ctx, &"inv_1", &"damage", false, 3, bad_two)
		and _asn_leg_amount(default_legs, &"investigator", &"inv_1") == 3
	)


func _test_asn_include_direct() -> bool:
	## ASN-04 · 04015：INCLUDE + DIRECT 才允许 direct 摊资产；无 INCLUDE 则拒。
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_asn_direct", {"health": 2, "sanity": 2}
	)
	var assign_only := [{"bearer": &"card", "id": card_id, "amount": 1}]
	if DamageAssigner.validate(h.ctx, &"inv_1", &"damage", true, 1, assign_only):
		return false
	h.ctx.registrations.register(
		RegistrationTemplate.assign_constraint_while_in_play(
			RestrictionPayload.assign_include_candidate(
				card_id,
				&"inv_1",
				&"either",
				AhcEnums.AssignDirectScope.DIRECT,
				&"self_deals"
			)
		)
	)
	return DamageAssigner.validate(h.ctx, &"inv_1", &"damage", true, 1, assign_only)


func _test_asn_include_bodyguard() -> bool:
	## ASN-05 · Bodyguard：other_at_location 扩他人伤害候选。
	var h := RuleTestHarness.new(42)
	GameBootstrap.setup_minimal_investigator(h.ctx, &"inv_2")
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	inv1.location_tag = &"sa_loc"
	inv2.location_tag = &"sa_loc"
	var guard_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_asn_guard", {"health": 2, "sanity": 0}
	)
	h.ctx.registrations.register(
		RegistrationTemplate.assign_constraint_while_in_play(
			RestrictionPayload.assign_include_candidate(
				guard_id,
				&"inv_1",
				&"damage",
				AhcEnums.AssignDirectScope.NON_DIRECT,
				&"other_at_location"
			)
		)
	)
	var assign_guard := [{"bearer": &"card", "id": guard_id, "amount": 1}]
	var far := false
	inv2.location_tag = &"elsewhere"
	far = DamageAssigner.validate(h.ctx, &"inv_2", &"damage", false, 1, assign_guard)
	inv2.location_tag = &"sa_loc"
	var near := DamageAssigner.validate(h.ctx, &"inv_2", &"damage", false, 1, assign_guard)
	return near and not far


func _test_asn_pipeline_prior_fill() -> bool:
	## ASN-06：pipeline Apply 按 PRIOR_FILL 腿写入；达神智上限则击败退场清标记。
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_asn_pipe", {"health": 0, "sanity": 2}
	)
	h.ctx.registrations.register(
		RegistrationTemplate.assign_constraint_while_in_play(
			RestrictionPayload.assign_prior_fill(card_id, &"inv_1", &"horror")
		)
	)
	var res := DamagePipeline.deal_investigator(h.ctx, &"inv_1", &"horror", 3, false)
	var card := h.ctx.state.registry.get_card(card_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var horror_legs: Array = res.get("legs_horror", [])
	return (
		bool(res.get("ok", false))
		and int(res.get("amount", 0)) == 3
		and _asn_leg_amount(horror_legs, &"card", card_id) == 2
		and _asn_leg_amount(horror_legs, &"investigator", &"inv_1") == 1
		and inv.horror_taken == 1
		and card != null
		and card.zone == AhcEnums.Zone.DISCARD
		and card.tokens.horror == 0
	)


func _test_asn_grant_capacity() -> bool:
	## ASN-07：无印刷 + GRANT → 开候选且不设上限；无 GRANT 拒；落任意量后仍 -1。
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_asn_grant", {"health": 0, "sanity": 0}
	)
	var bare := [{"bearer": &"card", "id": card_id, "amount": 1}]
	if DamageAssigner.validate(h.ctx, &"inv_1", &"damage", false, 1, bare):
		return false
	h.ctx.registrations.register(
		RegistrationTemplate.assign_constraint_while_in_play(
			RestrictionPayload.assign_grant_capacity(card_id, &"inv_1", 2, &"damage")
		)
	)
	if not DamageAssigner.validate(h.ctx, &"inv_1", &"damage", false, 1, bare):
		return false
	## 无印刷不设上限：超量（相对 GRANT amount 参数）仍合法。
	var over := [{"bearer": &"card", "id": card_id, "amount": 3}]
	if not DamageAssigner.validate(h.ctx, &"inv_1", &"damage", false, 3, over):
		return false
	if DamageAssigner.card_remaining(h.ctx, card_id, &"damage", &"inv_1", false) != -1:
		return false
	var applied := DamagePipeline.apply_investigator_legs(
		h.ctx,
		&"inv_1",
		&"damage",
		2,
		false,
		[{"bearer": &"card", "id": card_id, "amount": 2}]
	)
	var card := h.ctx.state.registry.get_card(card_id)
	return (
		bool(applied.get("ok", false))
		and int(applied.get("amount", 0)) == 2
		and card != null
		and card.tokens.damage == 2
		and DamageAssigner.card_remaining(h.ctx, card_id, &"damage", &"inv_1", false) == -1
		and DealSubject.damage_capacity(h.ctx, &"inv_1") == -1
	)


func _test_asn_gate_scripted() -> bool:
	## ASN-08：Assign Gate 显式确认腿表（非默认全归调查员）。
	var h := RuleTestHarness.new(42)
	var card_id := GameBootstrap.add_asset_to_play(
		h.ctx, &"inv_1", &"ally_asn_gate", {"health": 3, "sanity": 0}
	)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new(
		[
			{
				"prompt_id": &"assign:damage",
				"pick": [{"bearer": &"card", "id": card_id, "amount": 2}],
			}
		]
	)
	var res := h.ctx.sequence_catalog.run(
		h.ctx,
		&"seq.effect.deal.assignable",
		{"controller_id": &"inv_1", "kind": &"damage", "amount": 2}
	)
	var card := h.ctx.state.registry.get_card(card_id)
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	return (
		bool(res.get("ok", false))
		and not h.ctx.interaction.last_used_default
		and card != null
		and card.tokens.damage == 2
		and inv.damage_taken == 0
	)


func _test_asn_gate_among() -> bool:
	## ASN-09：外向 among 经 Gate 拆到两敌。
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_g0", &"test_loc", 2, 2)
	GameBootstrap.setup_test_enemy(h.ctx, &"enemy_g1", &"test_loc", 2, 2)
	h.ctx.state.registry.get_enemy(&"enemy_g0").health = 10
	h.ctx.state.registry.get_enemy(&"enemy_g1").health = 10
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new(
		[
			{
				"prompt_id": &"assign:among:damage",
				"pick": [
					{"id": &"enemy_g0", "amount": 1},
					{"id": &"enemy_g1", "amount": 1},
				],
			}
		]
	)
	var res: Variant = h.ctx.sequence_catalog.nest(
		h.ctx,
		&"seq.effect.deal.assignable",
		{
			"controller_id": &"inv_1",
			"target": &"subjects",
			"damage": 2,
			"primary_id": &"enemy_g0",
			"candidates": [&"enemy_g0", &"enemy_g1"],
		}
	)
	var e0 := h.ctx.state.registry.get_enemy(&"enemy_g0")
	var e1 := h.ctx.state.registry.get_enemy(&"enemy_g1")
	return (
		res is Dictionary
		and bool((res as Dictionary).get("ok", false))
		and not h.ctx.interaction.last_used_default
		and e0.damage == 1
		and e1.damage == 1
	)


func _test_revelation_own_priority_class() -> bool:
	## 抽取步骤：When 95 在 Forced 之后、显现后续步骤 90 之前。
	if EncounterDrawPriority.PLAYER_WHEN_DRAW != 95:
		return false
	if EncounterDrawPriority.REVELATION != 90:
		return false
	if EncounterDrawPriority.PLAYER_WHEN_DRAW <= EncounterDrawPriority.REVELATION:
		return false
	if SequenceHandler.Tier.REVELATION == SequenceHandler.Tier.FORCED:
		return false
	if int(SequenceHandler.Tier.REVELATION) <= int(SequenceHandler.Tier.TRIGGERED):
		return false
	var h := RuleTestHarness.new(42)
	var order: Array[String] = []
	h.ctx.sequences.register_handler(
		SequenceHandler.when_revelation(&"draw_timing", func() -> void: order.append("revelation"))
	)
	var when_draw := SequenceHandler.new()
	when_draw.match_kind = &"draw_timing"
	when_draw.phase = AhcEnums.SequencePhase.WHEN
	when_draw.tier = SequenceHandler.Tier.TRIGGERED
	when_draw.callback = func() -> void: order.append("when_draw")
	h.ctx.sequences.register_handler(when_draw)
	h.ctx.sequences.register_handler(
		SequenceHandler.when_forced(&"draw_timing", func() -> void: order.append("forced"))
	)
	h.ctx.sequences.run(TriggeringCondition.custom(&"draw_timing", &"inv_1"), func() -> void: pass)
	var policy := EnterHandTimingPolicy.new()
	var ordered := policy.order_cards_for_revelation(h.ctx, &"inv_1", [&"a", &"b"])
	return order == ["forced", "when_draw", "revelation"] and ordered == [&"a", &"b"]


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
		return h.ctx.interaction.last_used_default
	return false


func _test_pi_scripting_resolver() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"pick:enemy", "pick": &"enemy_1"},
	])
	var pick: Variant = h.ctx.interaction.ask_pick_target([&"enemy_0", &"enemy_1"], &"inv_1", &"pick:enemy", h.ctx)
	return pick == &"enemy_1" and not h.ctx.interaction.last_used_default


func _test_pi_default_pick_used_default() -> bool:
	var h := RuleTestHarness.new(42)
	var pick: Variant = h.ctx.interaction.ask_pick_target(
		[&"enemy_0", &"enemy_1"], &"inv_1", &"pick:enemy", h.ctx
	)
	return pick == &"enemy_0" and h.ctx.interaction.last_used_default


func _test_pi_scripting_not_default() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"pick:enemy", "pick": &"enemy_1"},
	])
	var pick: Variant = h.ctx.interaction.ask_pick_target(
		[&"enemy_0", &"enemy_1"], &"inv_1", &"pick:enemy", h.ctx
	)
	## 显式脚本应答即使等于「非默认项」也 used_default=false。
	return pick == &"enemy_1" and not h.ctx.interaction.last_used_default


func _test_pi_scripting_miss_default() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.interaction.resolver = ScriptingChoiceResolver.new([
		{"prompt_id": &"other:prompt", "pick": &"enemy_1"},
	])
	var pick: Variant = h.ctx.interaction.ask_pick_target(
		[&"enemy_0", &"enemy_1"], &"inv_1", &"pick:enemy", h.ctx
	)
	return pick == &"enemy_0" and h.ctx.interaction.last_used_default


func _test_pi_interaction_event_record() -> bool:
	var h := RuleTestHarness.new(42)
	h.ctx.interaction.ask_pick_target([&"a", &"b"], &"inv_1", &"pick:ev", h.ctx)
	var found := false
	for rec in h.ctx.events.get_records():
		if rec.kind != AhcEnums.EventRecordKind.INTERACTION_CHOICE:
			continue
		found = true
		if not bool(rec.payload.get("used_default", false)):
			return false
		if str(rec.payload.get("picked", "")) != "a":
			return false
	return found


func _test_pi_compute_default_multi() -> bool:
	var req := ChoiceRequest.new()
	req.kind = AhcEnums.ChoiceKind.PICK_MULTI
	req.options = [&"e1", &"e2", &"e3"]
	req.min_picks = 1
	req.max_picks = 2
	req.default_policy = &"first_option"
	var pick: Variant = DefaultChoiceResolver.compute_default(req)
	if not pick is Array or (pick as Array).size() != 2:
		return false
	req.min_picks = 0
	req.default_policy = &"skip"
	var skip: Variant = DefaultChoiceResolver.compute_default(req)
	return skip is Array and (skip as Array).is_empty()


func _test_pi_auto_registration_order() -> bool:
	var cfg := RulesConfig.new()
	cfg.auto_choice_mode = AhcEnums.AutoChoiceMode.REGISTRATION_ORDER
	var h := RuleTestHarness.new(42, cfg)
	var pick: Variant = h.ctx.interaction.ask_pick_target(
		[&"a", &"b", &"c"], &"inv_1", &"pick:auto_reg", h.ctx
	)
	if pick != &"a" or not h.ctx.interaction.last_used_default:
		return false
	var ordered: Array = h.ctx.interaction.ask_order_simultaneous(
		[&"x", &"y", &"z"], &"inv_1", &"order:auto_reg", h.ctx
	)
	return ordered == [&"x", &"y", &"z"]


func _test_pi_auto_random_seed() -> bool:
	var cfg := RulesConfig.new()
	cfg.auto_choice_mode = AhcEnums.AutoChoiceMode.RANDOM
	var h1 := RuleTestHarness.new(99, cfg)
	var h2 := RuleTestHarness.new(99, cfg)
	var opts: Array = [&"a", &"b", &"c", &"d", &"e"]
	var p1: Variant = h1.ctx.interaction.ask_pick_target(opts, &"inv_1", &"pick:rnd", h1.ctx)
	var p2: Variant = h2.ctx.interaction.ask_pick_target(opts, &"inv_1", &"pick:rnd", h2.ctx)
	if p1 != p2:
		return false
	## 同 seed 可复现；且须落在候选内。
	if not opts.has(p1):
		return false
	## 换 seed 通常得不同结果（极小概率碰撞则再抽一次对照）。
	var h3 := RuleTestHarness.new(100, cfg)
	var p3: Variant = h3.ctx.interaction.ask_pick_target(opts, &"inv_1", &"pick:rnd", h3.ctx)
	if p3 == p1:
		var h4 := RuleTestHarness.new(101, cfg)
		var p4: Variant = h4.ctx.interaction.ask_pick_target(opts, &"inv_1", &"pick:rnd", h4.ctx)
		if p4 == p1:
			## 仍相同则至少确认 used_default 与候选合法。
			return h1.ctx.interaction.last_used_default and opts.has(p4)
	return h1.ctx.interaction.last_used_default


func _test_pi_auto_random_order() -> bool:
	var cfg := RulesConfig.new()
	cfg.auto_choice_mode = AhcEnums.AutoChoiceMode.RANDOM
	var h := RuleTestHarness.new(7, cfg)
	var items: Array = [&"i0", &"i1", &"i2", &"i3", &"i4", &"i5"]
	var ordered: Array = h.ctx.interaction.ask_order_simultaneous(
		items, &"inv_1", &"order:rnd", h.ctx
	)
	if ordered.size() != items.size():
		return false
	## 须为同一多重集。
	var sorted_in := items.duplicate()
	var sorted_out := ordered.duplicate()
	sorted_in.sort()
	sorted_out.sort()
	if sorted_in != sorted_out:
		return false
	## 固定 seed=7 下应打乱（若偶然未打乱则用静态 compute_for_mode 再验一次）。
	if ordered == items:
		var req := ChoiceRequest.new()
		req.kind = AhcEnums.ChoiceKind.ORDER_SIMULTANEOUS
		req.options = [items.duplicate()]
		var rng := RandomNumberGenerator.new()
		rng.seed = 12345
		var alt: Variant = DefaultChoiceResolver.compute_for_mode(
			req, AhcEnums.AutoChoiceMode.RANDOM, rng
		)
		if not alt is Array or (alt as Array) == items:
			return false
	return h.ctx.interaction.last_used_default


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
	var result := h.ctx.enemy_phase.run_3_2(h.ctx)
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
	var result := h.ctx.enemy_phase.run_3_2(h.ctx)
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
	## 经 3.3 基础手续；庞大 REPLACE → seq.keyword.massive（非平行 massive 流程）。
	var result := h.ctx.enemy_phase.run_phase_attacks(h.ctx, &"inv_1")
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	return (
		int(result.get("attacks", 0)) == 2
		and inv1.damage_taken == 2
		and inv2.damage_taken == 2
		and enemy.exhausted
		and h.ctx.sequence_catalog.has_flow(&"seq.keyword.massive")
		and not h.ctx.sequence_catalog.has_flow(&"seq.enemy.massive_phase_attacks")
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


func _test_en20_fight_fail_redirect_and_retaliate() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase([ChaosToken.auto_fail()]):
		return false
	GameBootstrap.setup_investigator_at_location(h.ctx, &"inv_2", &"test_loc")
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_ret_redirect",
		&"test_loc",
		{
			"keywords": [&"retaliate"],
			"enemy": {"fight": 2, "evade": 2, "health": 2, "damage": 2, "horror": 1},
		}
	)
	if enemy_id == &"":
		return false
	var inv1 := h.ctx.state.registry.get_investigator(&"inv_1")
	var inv2 := h.ctx.state.registry.get_investigator(&"inv_2")
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	enemy.engaged_with = &"inv_2"
	inv2.threat_area.append(enemy_id)
	inv1.damage_taken = 0
	inv1.horror_taken = 0
	inv2.damage_taken = 0
	inv2.horror_taken = 0
	var res := h.fight_action({"enemy_id": enemy_id})
	return (
		res.ok
		and not res.success
		and inv1.damage_taken == 2
		and inv1.horror_taken == 1
		and inv2.damage_taken == 1
		and inv2.horror_taken == 0
		and enemy != null
		and not enemy.exhausted
	)


func _test_en21_alert_aloof_unengaged() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase([ChaosToken.auto_fail()]):
		return false
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_alert_aloof",
		&"test_loc",
		{
			"keywords": [&"alert", &"aloof"],
			"enemy": {"fight": 2, "evade": 2, "health": 2, "damage": 3, "horror": 0},
		}
	)
	if enemy_id == &"":
		return false
	var inv := h.ctx.state.registry.get_investigator(&"inv_1")
	var enemy := h.ctx.state.registry.get_enemy(enemy_id)
	if enemy.engaged_with != &"" or inv.threat_area.has(enemy_id):
		return false
	inv.damage_taken = 0
	inv.horror_taken = 0
	var st := SkillTestHelper.new(h.ctx)
	var test := st.make_test(&"inv_1", AhcEnums.SkillType.AGILITY, 2)
	test.target_enemy_id = enemy_id
	var result := st.run(test)
	return (
		not result.success
		and inv.damage_taken == 3
		and inv.horror_taken == 0
		and not enemy.exhausted
	)


func _test_en22_fight_success_elusive_flees() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	GameBootstrap.setup_test_location(h.ctx, &"flee_loc")
	GameBootstrap.connect_locations(h.ctx, &"test_loc", &"flee_loc")
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_elusive_win",
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
		and res.success
		and enemy.damage == 1
		and enemy.exhausted
		and enemy.engaged_with == &""
		and not inv.threat_area.has(enemy_id)
		and enemy.location_tag == &"flee_loc"
	)


func _test_en23_defeat_doomed_places_doom() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	h.ctx.state.agenda_threshold = 7
	h.ctx.state.doom_on_agenda = 0
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_doomed",
		&"test_loc",
		{
			"keywords": [&"doomed"],
			"enemy": {"fight": 1, "evade": 1, "health": 1},
		}
	)
	if enemy_id == &"":
		return false
	var res := h.fight_action({"enemy_id": enemy_id})
	return (
		res.ok
		and res.success
		and h.ctx.state.doom_on_agenda == 1
		and h.ctx.state.registry.get_enemy(enemy_id) == null
		and h.ctx.state.encounter_discard.has(enemy_id)
	)


func _test_en24_discard_enemy_skips_doomed() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	h.ctx.state.doom_on_agenda = 0
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_doomed_disc",
		&"test_loc",
		{
			"keywords": [&"doomed"],
			"enemy": {"fight": 1, "evade": 1, "health": 1},
		}
	)
	if enemy_id == &"":
		return false
	var discard := h.ctx.enemy.discard_enemy_from_play(h.ctx, enemy_id)
	return (
		discard.get("discarded", false)
		and h.ctx.state.doom_on_agenda == 0
		and h.ctx.state.registry.get_enemy(enemy_id) == null
		and h.ctx.state.encounter_discard.has(enemy_id)
	)


func _test_en25_defeat_non_doomed_no_doom() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	h.ctx.state.doom_on_agenda = 0
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_plain",
		&"test_loc",
		{"enemy": {"fight": 1, "evade": 1, "health": 1}}
	)
	if enemy_id == &"":
		return false
	var res := h.fight_action({"enemy_id": enemy_id})
	return (
		res.ok
		and res.success
		and h.ctx.state.doom_on_agenda == 0
		and h.ctx.state.registry.get_enemy(enemy_id) == null
	)


func _test_adb_import_bystander_doomed() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	return CardRegistry.is_doomed(&"12123")


func _test_en26_defeat_victory_to_display() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_victory",
		&"test_loc",
		{
			"victory": 2,
			"enemy": {"fight": 1, "evade": 1, "health": 1},
		}
	)
	if enemy_id == &"":
		return false
	var res := h.fight_action({"enemy_id": enemy_id})
	var card := h.ctx.state.registry.get_card(enemy_id)
	return (
		res.ok
		and res.success
		and h.ctx.state.registry.get_enemy(enemy_id) == null
		and h.ctx.state.victory_display.has(enemy_id)
		and not h.ctx.state.encounter_discard.has(enemy_id)
		and card != null
		and card.zone == AhcEnums.Zone.VICTORY_DISPLAY
		and h.ctx.state.total_victory_points() == 2
	)


func _test_en27_discard_victory_not_to_display() -> bool:
	var h := RuleTestHarness.new(42)
	if not h.prepare_action_phase():
		return false
	var enemy_id := _spawn_enemy_at(
		h,
		&"en_victory_disc",
		&"test_loc",
		{
			"victory": 1,
			"enemy": {"fight": 1, "evade": 1, "health": 1},
		}
	)
	if enemy_id == &"":
		return false
	var discard := h.ctx.enemy.discard_enemy_from_play(h.ctx, enemy_id)
	return (
		discard.get("discarded", false)
		and h.ctx.state.registry.get_enemy(enemy_id) == null
		and not h.ctx.state.victory_display.has(enemy_id)
		and h.ctx.state.encounter_discard.has(enemy_id)
		and h.ctx.state.total_victory_points() == 0
	)


func _test_adb_import_elite_servant_victory() -> bool:
	ArkhamDbCardLoader.load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	return CardRegistry.victory_points(&"12114") == 2


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
	if not h.resolve_encounter_revelation(card_id):
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
