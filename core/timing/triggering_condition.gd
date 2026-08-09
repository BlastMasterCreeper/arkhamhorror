class_name TriggeringCondition
extends RefCounted

var id: StringName = &""
var kind: StringName = &""
var controller_id: StringName = &""
var tags: Array[StringName] = []
var after_timing: StringName = &""
var payload: Dictionary = {}


static func gain_resource(
	controller_id: StringName,
	source_tags: Array[StringName],
	after_timing: StringName = &"after_gain_resource"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("gain_%s_%d" % [controller_id, Time.get_ticks_msec()])
	t.kind = &"gain_resource"
	t.controller_id = controller_id
	t.tags = [&"gain_resource"]
	t.tags.append_array(source_tags)
	t.after_timing = after_timing
	return t


static func custom(
	kind: StringName,
	controller_id: StringName = &"",
	source_tags: Array[StringName] = [],
	after_timing: StringName = &""
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("%s_%d" % [kind, Time.get_ticks_msec()])
	t.kind = kind
	t.controller_id = controller_id
	t.tags = source_tags.duplicate()
	t.after_timing = after_timing
	return t


static func draw_investigator(
	controller_id: StringName,
	amount: int,
	source_tags: Array[StringName] = [],
	after_timing: StringName = &"after_draw_investigator"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("draw_%s_%d_%d" % [controller_id, amount, Time.get_ticks_msec()])
	t.kind = &"draw_investigator"
	t.controller_id = controller_id
	t.tags = [&"draw_investigator"]
	t.tags.append_array(source_tags)
	t.after_timing = after_timing
	t.payload = {"amount": amount}
	return t


static func draw_empty_piles_defeated(
	controller_id: StringName,
	after_timing: StringName = &"after_draw_empty_piles_defeated"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("draw_empty_%s_%d" % [controller_id, Time.get_ticks_msec()])
	t.kind = &"draw_empty_piles_defeated"
	t.controller_id = controller_id
	t.tags = [&"draw_investigator", &"draw_defeated"]
	t.after_timing = after_timing
	return t


static func enter_hand(
	controller_id: StringName,
	card_id: StringName,
	source_tags: Array[StringName] = [],
	after_timing: StringName = &"after_enter_hand"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enter_hand_%s_%d" % [card_id, Time.get_ticks_msec()])
	t.kind = &"enter_hand"
	t.controller_id = controller_id
	t.tags = [&"enter_hand", &"zone"]
	t.tags.append_array(source_tags)
	t.after_timing = after_timing
	t.payload = {"card_id": card_id}
	return t


static func draw_encounter(
	drawer_id: StringName,
	card_id: StringName = &"",
	source_tags: Array[StringName] = [],
	after_timing: StringName = &"after_draw_encounter"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("draw_enc_%s_%d" % [drawer_id, Time.get_ticks_msec()])
	t.kind = &"draw_encounter"
	t.controller_id = drawer_id
	t.tags = [&"draw_encounter", &"ENCOUNTER_CARD_DRAWN"]
	t.tags.append_array(source_tags)
	t.after_timing = after_timing
	t.payload = {"drawer_id": drawer_id, "card_id": card_id}
	return t


static func encounter_card_drawn(
	drawer_id: StringName,
	card_id: StringName,
	after_timing: StringName = &""
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enc_card_%s_%d" % [card_id, Time.get_ticks_msec()])
	t.kind = &"encounter_card_drawn"
	t.controller_id = drawer_id
	t.tags = [&"draw_encounter", &"ENCOUNTER_CARD_DRAWN"]
	t.payload = {"drawer_id": drawer_id, "card_id": card_id}
	t.after_timing = after_timing
	return t


static func encounter_revelation(
	drawer_id: StringName,
	card_id: StringName,
	after_timing: StringName = &"after_encounter_revelation"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enc_rev_%s_%d" % [card_id, Time.get_ticks_msec()])
	t.kind = &"encounter_revelation"
	t.controller_id = drawer_id
	t.payload = {"drawer_id": drawer_id, "card_id": card_id}
	return t


static func skill_test_revelation(
	inv_id: StringName,
	skill: AhcEnums.SkillType,
	difficulty: int,
	card_id: StringName = &"",
	after_timing: StringName = &"after_skill_test_revelation"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("skill_test_%s_%d" % [inv_id, Time.get_ticks_msec()])
	t.kind = &"skill_test"
	t.controller_id = inv_id
	t.tags = [&"skill_test", &"revelation"]
	t.after_timing = after_timing
	t.payload = {
		"inv_id": inv_id,
		"skill": skill,
		"difficulty": difficulty,
		"card_id": card_id,
	}
	return t


static func encounter_spawn(
	drawer_id: StringName,
	card_id: StringName,
	after_timing: StringName = &"after_encounter_spawn",
	from_hand: bool = false
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enc_spawn_%s_%d" % [card_id, Time.get_ticks_msec()])
	t.kind = &"encounter_spawn"
	t.controller_id = drawer_id
	if from_hand:
		t.tags = [&"spawn", &"encounter_spawn_from_hand"]
	else:
		t.tags = [&"draw_encounter", &"ENCOUNTER_CARD_DRAWN", &"spawn"]
	t.after_timing = after_timing
	t.payload = {
		"drawer_id": drawer_id,
		"card_id": card_id,
		"from_hand": from_hand,
	}
	return t


static func action_committed(
	action_kind: StringName,
	controller_id: StringName,
	source_tags: Array[StringName] = [],
	after_timing: StringName = &"",
	payload: Dictionary = {}
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("action_%s_%s_%d" % [action_kind, controller_id, Time.get_ticks_msec()])
	t.kind = StringName("action_%s" % action_kind)
	t.controller_id = controller_id
	t.tags = [&"action"]
	t.tags.append(action_kind)
	t.tags.append_array(source_tags)
	t.after_timing = after_timing if after_timing != &"" else StringName("after_action_%s" % action_kind)
	t.payload = payload.duplicate()
	return t


static func draw_encounter_resolve_bound(
	drawer_id: StringName,
	card_id: StringName,
	after_timing: StringName = &"after_draw_encounter_bound"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enc_bound_%s_%d" % [card_id, Time.get_ticks_msec()])
	t.kind = &"draw_encounter_resolve_bound"
	t.controller_id = drawer_id
	t.tags = [&"draw_encounter", &"weakness_encounter", &"ENCOUNTER_CARD_DRAWN"]
	t.after_timing = after_timing
	t.payload = {"drawer_id": drawer_id, "card_id": card_id}
	return t


static func mythos_place_doom(
	after_timing: StringName = &"after_mythos_place_doom"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("mythos_place_doom_%d" % Time.get_ticks_msec())
	t.kind = &"mythos_place_doom"
	t.tags = [&"mythos", &"framework"]
	t.after_timing = after_timing
	return t


static func mythos_check_doom_threshold(
	after_timing: StringName = &"after_mythos_check_doom_threshold"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("mythos_check_doom_%d" % Time.get_ticks_msec())
	t.kind = &"mythos_check_doom_threshold"
	t.tags = [&"mythos", &"framework", &"agenda"]
	t.after_timing = after_timing
	return t


static func agenda_advance(
	source: StringName = &"unknown",
	explicit: bool = false,
	after_timing: StringName = &"after_agenda_advance"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("agenda_advance_%s_%d" % [source, Time.get_ticks_msec()])
	t.kind = &"agenda_advance"
	t.tags = [&"agenda", &"scenario"]
	t.after_timing = after_timing
	t.payload = {"source": source, "explicit": explicit}
	return t


static func act_advance(
	after_timing: StringName = &"after_act_advance"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("act_advance_%d" % Time.get_ticks_msec())
	t.kind = &"act_advance"
	t.tags = [&"act", &"scenario"]
	t.after_timing = after_timing
	return t


static func act_agenda_back_resolve(
	definition_id: StringName,
	flipped_card_id: StringName,
	is_agenda: bool,
	after_timing: StringName = &"after_act_agenda_back"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName(
		"act_agenda_back_%s_%d" % [definition_id, Time.get_ticks_msec()]
	)
	t.kind = &"act_agenda_back_resolve"
	t.tags = [&"scenario", &"agenda" if is_agenda else &"act", &"act_agenda_back"]
	t.after_timing = after_timing
	t.payload = {
		"definition_id": definition_id,
		"flipped_card_id": flipped_card_id,
		"is_agenda": is_agenda,
	}
	return t


static func act_agenda_back_step(
	step_kind: StringName,
	definition_id: StringName,
	after_timing: StringName = &"after_act_agenda_back_step"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName(
		"act_agenda_back_step_%s_%s_%d" % [step_kind, definition_id, Time.get_ticks_msec()]
	)
	t.kind = StringName("act_agenda_back_%s" % step_kind)
	t.tags = [&"scenario", &"act_agenda_back", step_kind]
	t.after_timing = after_timing
	t.payload = {"definition_id": definition_id, "step_kind": step_kind}
	return t


static func scenario_trigger_resolution(
	resolution: int,
	source: StringName,
	after_timing: StringName = &"after_scenario_resolution"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("scenario_resolution_%d_%d" % [resolution, Time.get_ticks_msec()])
	t.kind = &"scenario_trigger_resolution"
	t.tags = [&"scenario", &"resolution"]
	t.after_timing = after_timing
	t.payload = {"resolution": resolution, "source": source}
	return t


static func enemy_3_2_hunter_patrol(
	after_timing: StringName = &"after_enemy_3_2_hunter_patrol"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enemy_3_2_hunter_%d" % Time.get_ticks_msec())
	t.kind = &"enemy_3_2_hunter_patrol"
	t.tags = [&"enemy", &"framework", &"move", &"hunter"]
	t.after_timing = after_timing
	return t


static func enemy_3_2_patrol(
	after_timing: StringName = &"after_enemy_3_2_patrol"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enemy_3_2_patrol_%d" % Time.get_ticks_msec())
	t.kind = &"enemy_3_2_patrol"
	t.tags = [&"enemy", &"framework", &"move", &"patrol"]
	t.after_timing = after_timing
	return t


static func enemy_phase_attacks(
	investigator_id: StringName,
	after_timing: StringName = &"after_enemy_phase_attacks"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enemy_phase_%s_%d" % [investigator_id, Time.get_ticks_msec()])
	t.kind = &"enemy_phase_attacks"
	t.controller_id = investigator_id
	t.tags = [&"enemy", &"framework", &"attack"]
	t.after_timing = after_timing
	t.payload = {"investigator_id": investigator_id}
	return t


static func enemy_massive_phase_attacks(
	after_timing: StringName = &"after_enemy_massive_phase_attacks"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enemy_massive_phase_%d" % Time.get_ticks_msec())
	t.kind = &"enemy_massive_phase_attacks"
	t.tags = [&"enemy", &"framework", &"attack", &"massive"]
	t.after_timing = after_timing
	return t


static func enemy_resolve_location(
	drawer_id: StringName = &"",
	after_timing: StringName = &"after_enemy_resolve_location"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enemy_resolve_loc_%d" % Time.get_ticks_msec())
	t.kind = &"enemy_resolve_location"
	t.controller_id = drawer_id
	t.tags = [&"enemy", &"location"]
	t.after_timing = after_timing
	return t


static func enemy_move(
	enemy_id: StringName,
	after_timing: StringName = &"after_enemy_move"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enemy_move_%s_%d" % [enemy_id, Time.get_ticks_msec()])
	t.kind = &"enemy_move"
	t.tags = [&"enemy", &"move"]
	t.after_timing = after_timing
	t.payload = {"enemy_id": enemy_id}
	return t


static func engage(
	params: Dictionary,
	after_timing: StringName = &"after_engage"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	var location_tag: StringName = params.get("location_tag", &"")
	var enemy_id: StringName = params.get("enemy_id", &"")
	t.id = StringName(
		"engage_%s_%s_%d" % [location_tag, enemy_id, Time.get_ticks_msec()]
	)
	t.kind = &"engage"
	t.tags = [&"engage"]
	t.after_timing = after_timing
	t.payload = params.duplicate()
	return t


static func enemy_attack(
	enemy_id: StringName,
	target_investigator: StringName,
	after_timing: StringName = &"after_enemy_attack"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enemy_attack_%s_%d" % [enemy_id, Time.get_ticks_msec()])
	t.kind = &"enemy_attack"
	t.controller_id = target_investigator
	t.tags = [&"enemy", &"attack"]
	t.after_timing = after_timing
	t.payload = {"enemy_id": enemy_id, "target_investigator": target_investigator}
	return t
