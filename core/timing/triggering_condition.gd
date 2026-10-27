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


## ST.3「将要揭示混沌标记」：WHEN 窗挂 Olive / Mask of Silenus 等替换体。
static func reveal_chaos_token(
	inv_id: StringName,
	test_id: StringName = &"",
	after_timing: StringName = &"after_reveal_chaos_token"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("reveal_chaos_%s_%d" % [inv_id, Time.get_ticks_msec()])
	t.kind = &"reveal_chaos_token"
	t.controller_id = inv_id
	t.tags = [&"chaos", &"reveal", &"skill_test"]
	t.after_timing = after_timing
	t.payload = {"inv_id": inv_id, "test_id": test_id}
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


## 已持有实例 → 走遭遇侧能力体系结算（非「来源重定向」）。
static func encounter_resolve_card(
	drawer_id: StringName,
	card_id: StringName,
	after_timing: StringName = &"after_encounter_resolve_card"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enc_resolve_%s_%d" % [card_id, Time.get_ticks_msec()])
	t.kind = &"encounter_resolve_card"
	t.controller_id = drawer_id
	t.tags = [&"encounter", &"resolve_card", &"ENCOUNTER_CARD_DRAWN"]
	t.after_timing = after_timing
	t.payload = {"drawer_id": drawer_id, "card_id": card_id}
	return t


static func keyword_surge(
	drawer_id: StringName,
	card_id: StringName,
	after_timing: StringName = &"after_keyword_surge"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("keyword_surge_%s_%d" % [card_id, Time.get_ticks_msec()])
	t.kind = &"keyword_surge"
	t.controller_id = drawer_id
	t.tags = [&"keyword", &"surge"]
	t.after_timing = after_timing
	t.payload = {"drawer_id": drawer_id, "card_id": card_id}
	return t


static func keyword_hunter(
	enemy_id: StringName,
	after_timing: StringName = &"after_keyword_hunter"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("keyword_hunter_%s_%d" % [enemy_id, Time.get_ticks_msec()])
	t.kind = &"keyword_hunter"
	t.tags = [&"keyword", &"hunter", &"move"]
	t.after_timing = after_timing
	t.payload = {"card_id": enemy_id, "enemy_id": enemy_id}
	return t


static func keyword_patrol(
	enemy_id: StringName,
	after_timing: StringName = &"after_keyword_patrol"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("keyword_patrol_%s_%d" % [enemy_id, Time.get_ticks_msec()])
	t.kind = &"keyword_patrol"
	t.tags = [&"keyword", &"patrol", &"move"]
	t.after_timing = after_timing
	t.payload = {"card_id": enemy_id, "enemy_id": enemy_id}
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


static func investigation_phase_ends(
	after_timing: StringName = &"after_investigation_phase_ends"
) -> TriggeringCondition:
	return phase_boundary(&"investigation", &"ends", after_timing)


static func phase_boundary_kind(phase: StringName, boundary: StringName) -> StringName:
	return StringName("%s_phase_%s" % [phase, boundary])


## 阶段边界（G6 · 单条 seq）：phase / boundary → params；kind 仍细分供 match_kind。
static func phase_boundary(
	phase: StringName,
	boundary: StringName,
	after_timing: StringName = &""
) -> TriggeringCondition:
	var kind := phase_boundary_kind(phase, boundary)
	var t := TriggeringCondition.new()
	t.id = StringName("%s_%d" % [kind, Time.get_ticks_msec()])
	t.kind = kind
	t.tags = [&"framework", &"phase_boundary", phase, boundary]
	if after_timing == &"":
		t.after_timing = StringName("after_%s" % kind)
	else:
		t.after_timing = after_timing
	t.payload = {"phase": phase, "boundary": boundary}
	return t


static func phase_boundary_from_params(
	params: Dictionary,
	after_timing: StringName = &""
) -> TriggeringCondition:
	var phase: StringName = params.get("phase", &"") as StringName
	var boundary: StringName = params.get("boundary", &"") as StringName
	return phase_boundary(phase, boundary, after_timing)


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


static func enemy_3_2(
	after_timing: StringName = &"after_enemy_3_2"
) -> TriggeringCondition:
	## Framework 3.2 基础手续（Hunter/Patrol 关键词 resolve）；非关键词平行流程。
	var t := TriggeringCondition.new()
	t.id = StringName("enemy_3_2_%d" % Time.get_ticks_msec())
	t.kind = &"enemy_3_2"
	t.tags = [&"enemy", &"framework", &"move", &"hunter", &"patrol"]
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


static func keyword_massive(
	enemy_id: StringName,
	after_timing: StringName = &"after_keyword_massive"
) -> TriggeringCondition:
	## 庞大对阶段攻击的效果替换体（非平行 framework 流程）。
	var t := TriggeringCondition.new()
	t.id = StringName("keyword_massive_%s_%d" % [enemy_id, Time.get_ticks_msec()])
	t.kind = &"keyword_massive"
	t.tags = [&"keyword", &"massive", &"attack", &"replace"]
	t.after_timing = after_timing
	t.payload = {"card_id": enemy_id, "enemy_id": enemy_id}
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


## 搜寻（seq.effect.search）。
## 广义区划迁移（seq.zone.move · 进场/离场信息别名）。
static func zone_move(
	params: Dictionary,
	after_timing: StringName = &"after_zone_move"
) -> TriggeringCondition:
	var card_id: StringName = params.get("card_id", &"") as StringName
	var t := TriggeringCondition.new()
	t.id = StringName("zone_move_%s_%d" % [card_id, Time.get_ticks_msec()])
	t.kind = &"zone_move"
	t.tags = [&"zone_move"]
	t.after_timing = after_timing
	t.payload = params.duplicate()
	return t


static func search(
	params: Dictionary,
	after_timing: StringName = &"after_search"
) -> TriggeringCondition:
	var controller: StringName = params.get(
		"controller_id",
		params.get("investigator_id", params.get("inv_id", &""))
	) as StringName
	var t := TriggeringCondition.new()
	t.id = StringName("search_%s_%d" % [controller, Time.get_ticks_msec()])
	t.kind = &"search"
	t.controller_id = controller
	t.tags = [&"search", &"effect"]
	t.after_timing = after_timing
	t.payload = params.duplicate()
	return t


## 躲避效果（seq.effect.evade · 横置+解除交战；含自动躲避入口）。
static func evade_effect(
	params: Dictionary,
	after_timing: StringName = &"after_evade_effect"
) -> TriggeringCondition:
	var enemy_id: StringName = params.get("enemy_id", &"") as StringName
	var inv_id: StringName = params.get(
		"investigator_id", params.get("inv_id", &"")
	) as StringName
	var mode: StringName = params.get("mode", &"") as StringName
	var t := TriggeringCondition.new()
	t.id = StringName("evade_effect_%s_%d" % [enemy_id, Time.get_ticks_msec()])
	t.kind = &"evade_effect"
	t.controller_id = inv_id
	t.tags = [&"evade", &"effect", mode]
	t.after_timing = after_timing
	t.payload = params.duplicate()
	return t


## 横置（seq.effect.exhaust）。
static func exhaust(
	params: Dictionary,
	after_timing: StringName = &"after_exhaust"
) -> TriggeringCondition:
	var kind := ExhaustReadyFlow.resolve_target_kind(params)
	var target: StringName = params.get(
		"enemy_id", params.get("card_id", &"")
	) as StringName
	var t := TriggeringCondition.new()
	t.id = StringName("exhaust_%s_%s_%d" % [kind, target, Time.get_ticks_msec()])
	t.kind = &"exhaust"
	t.tags = [&"exhaust", kind]
	t.after_timing = after_timing
	t.payload = params.duplicate()
	return t


## 重整（seq.effect.ready）。
static func ready(
	params: Dictionary,
	after_timing: StringName = &"after_ready"
) -> TriggeringCondition:
	var kind := ExhaustReadyFlow.resolve_target_kind(params)
	var target: StringName = params.get(
		"enemy_id", params.get("card_id", &"")
	) as StringName
	var t := TriggeringCondition.new()
	t.id = StringName("ready_%s_%s_%d" % [kind, target, Time.get_ticks_msec()])
	t.kind = &"ready"
	t.tags = [&"ready", kind]
	t.after_timing = after_timing
	t.payload = params.duplicate()
	return t


static func seal(
	params: Dictionary,
	after_timing: StringName = &"after_seal"
) -> TriggeringCondition:
	var host: StringName = params.get(
		"host_card_id", params.get("card_id", &"")
	) as StringName
	var t := TriggeringCondition.new()
	t.id = StringName("seal_%s_%d" % [host, Time.get_ticks_msec()])
	t.kind = &"seal"
	t.tags = [&"seal", &"chaos", &"effect"]
	t.after_timing = after_timing
	t.payload = params.duplicate()
	return t


static func release_seal(
	params: Dictionary,
	after_timing: StringName = &"after_release_seal"
) -> TriggeringCondition:
	var host: StringName = params.get(
		"host_card_id", params.get("card_id", &"")
	) as StringName
	var t := TriggeringCondition.new()
	t.id = StringName("release_seal_%s_%d" % [host, Time.get_ticks_msec()])
	t.kind = &"release_seal"
	t.tags = [&"seal", &"release", &"chaos", &"effect"]
	t.after_timing = after_timing
	t.payload = params.duplicate()
	return t


## 狭义移动（seq.effect.move）：调查员 / 敌人 / 附属 / 标记。
## 订阅用 tags（subject）二次过滤；勿再按主体拆 flow_id。
static func move(
	params: Dictionary,
	after_timing: StringName = &"after_move"
) -> TriggeringCondition:
	var subject := MoveFlow.resolve_subject(params)
	var dest: StringName = params.get(
		"destination_id",
		params.get("to", params.get("target_location", &""))
	) as StringName
	var entity: StringName = params.get(
		"enemy_id",
		params.get(
			"investigator_id",
			params.get(
				"inv_id",
				params.get("attachment_id", params.get("card_id", &""))
			)
		)
	) as StringName
	var move_kind := MoveFlow.resolve_move_kind(params)
	var t := TriggeringCondition.new()
	t.id = StringName(
		"move_%s_%s_%s_%s_%d" % [move_kind, subject, entity, dest, Time.get_ticks_msec()]
	)
	t.kind = &"move"
	t.tags = [&"move", subject, move_kind]
	t.after_timing = after_timing
	t.payload = params.duplicate()
	t.payload["move_kind"] = move_kind
	if subject == MoveFlow.SUBJECT_INVESTIGATOR and entity != &"":
		t.controller_id = entity
	return t


static func enemy_move(
	enemy_id: StringName,
	after_timing: StringName = &"after_move"
) -> TriggeringCondition:
	return move({"subject": MoveFlow.SUBJECT_ENEMY, "enemy_id": enemy_id}, after_timing)


static func investigator_move(
	investigator_id: StringName,
	destination_id: StringName = &"",
	after_timing: StringName = &"after_move"
) -> TriggeringCondition:
	return move(
		{
			"subject": MoveFlow.SUBJECT_INVESTIGATOR,
			"investigator_id": investigator_id,
			"destination_id": destination_id,
		},
		after_timing
	)


static func engage(
	params: Dictionary,
	after_timing: StringName = &"after_engage"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	var location_tag: StringName = params.get("location_tag", &"")
	var enemy_id: StringName = params.get("enemy_id", &"")
	var mode: StringName = params.get("mode", &"auto") as StringName
	t.id = StringName(
		"engage_%s_%s_%d" % [location_tag, enemy_id, Time.get_ticks_msec()]
	)
	t.kind = &"engage"
	t.tags = [&"engage", mode]
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


## 敌人被击败（defeat）· WHEN/AFTER 在离场前收集（06 §3.2.4）。
static func enemy_defeated(
	enemy_id: StringName,
	location_id: StringName = &"",
	definition_id: StringName = &"",
	after_timing: StringName = &"after_enemy_defeated"
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("enemy_defeated_%s_%d" % [enemy_id, Time.get_ticks_msec()])
	t.kind = &"enemy_defeated"
	t.tags = [&"enemy", &"defeat"]
	t.after_timing = after_timing
	t.payload = {
		"enemy_id": enemy_id,
		"location_id": location_id,
		"definition_id": definition_id,
	}
	return t


## 击败效果（seq.effect.defeat · 敌人/调查员）。
static func defeat(
	params: Dictionary,
	after_timing: StringName = &"after_defeat"
) -> TriggeringCondition:
	var subject: StringName = params.get("subject", &"") as StringName
	var enemy_id: StringName = params.get("enemy_id", &"") as StringName
	if subject == &"" and enemy_id != &"":
		return enemy_defeated(
			enemy_id,
			params.get("location_id", &"") as StringName,
			params.get("definition_id", &"") as StringName,
			after_timing
		)
	var inv_id: StringName = params.get(
		"investigator_id", params.get("inv_id", &"")
	) as StringName
	var t := TriggeringCondition.new()
	t.id = StringName(
		"defeat_%s_%s_%d"
		% [subject, enemy_id if enemy_id != &"" else inv_id, Time.get_ticks_msec()]
	)
	t.kind = &"defeat"
	t.tags = [&"defeat", &"effect", subject]
	t.controller_id = inv_id
	t.after_timing = after_timing
	t.payload = params.duplicate()
	return t


## 击败成功后的退场 nest（seq.defeat.leave_play）。
static func defeat_leave_play(
	params: Dictionary,
	after_timing: StringName = &"after_defeat_leave_play"
) -> TriggeringCondition:
	var subject: StringName = params.get("subject", &"") as StringName
	var t := TriggeringCondition.new()
	t.id = StringName("defeat_leave_%s_%d" % [subject, Time.get_ticks_msec()])
	t.kind = &"defeat_leave_play"
	t.tags = [&"defeat", &"leave_play", subject]
	t.after_timing = after_timing
	t.payload = params.duplicate()
	return t


static func discover_clue(
	inv_id: StringName,
	location_id: StringName,
	amount: int = 1,
	after_timing: StringName = &"after_discover_clue"
) -> TriggeringCondition:
	return discover_clue_from_params(
		{"inv_id": inv_id, "location_id": location_id, "amount": amount},
		after_timing
	)


## 单地或 legs 多地；多目标仍一条 discover_clue 帧（AFTER 一次）。
static func discover_clue_from_params(
	params: Dictionary,
	after_timing: StringName = &"after_discover_clue"
) -> TriggeringCondition:
	var inv_id: StringName = params.get("inv_id", &"")
	var t := TriggeringCondition.new()
	t.id = StringName("discover_clue_%s_%d" % [inv_id, Time.get_ticks_msec()])
	t.kind = &"discover_clue"
	t.controller_id = inv_id
	t.tags = [&"discover_clue"]
	t.after_timing = after_timing
	t.payload = params.duplicate(true)
	return t


static func take_horror(
	controller_id: StringName,
	amount: int = 1,
	is_direct: bool = false,
	after_timing: StringName = &"after_damage"
) -> TriggeringCondition:
	return damage(controller_id, &"horror", amount, is_direct, &"controller", &"", after_timing)


static func take_damage(
	controller_id: StringName,
	amount: int = 1,
	is_direct: bool = false,
	after_timing: StringName = &"after_damage"
) -> TriggeringCondition:
	return damage(controller_id, &"damage", amount, is_direct, &"controller", &"", after_timing)


static func damage(
	controller_id: StringName,
	kind: StringName = &"damage",
	amount: int = 1,
	is_direct: bool = false,
	target: StringName = &"controller",
	source: StringName = &"",
	after_timing: StringName = &"after_damage"
) -> TriggeringCondition:
	return damage_from_params(
		{
			"controller_id": controller_id,
			"kind": kind,
			"amount": amount,
			"direct": is_direct,
			"target": target,
			"source": source,
		},
		after_timing
	)


## 单目标或 legs 多目标；多目标仍一条 damage 帧。
## payload 恒带 `damage` / `horror`（可一侧为 0）；同一时点、条件看这两量。
static func damage_from_params(
	params: Dictionary,
	after_timing: StringName = &"after_damage"
) -> TriggeringCondition:
	var controller_id: StringName = params.get(
		"controller_id", params.get("inv_id", &"")
	)
	var payload := params.duplicate(true)
	var amounts := normalize_affliction_amounts(params)
	var dmg := int(amounts.get("damage", 0))
	var hor := int(amounts.get("horror", 0))
	payload["damage"] = dmg
	payload["horror"] = hor
	var kind := StringName(str(params.get("kind", "")))
	if kind == &"":
		if dmg > 0 and hor <= 0:
			kind = &"damage"
		elif hor > 0 and dmg <= 0:
			kind = &"horror"
		else:
			kind = &"damage"
	payload["kind"] = kind
	if not payload.has("amount"):
		payload["amount"] = dmg + hor
	return _effect(
		&"damage",
		controller_id,
		[&"effect", &"damage", kind],
		after_timing,
		payload
	)


## 从 params / payload 规范化伤恐量（兼容旧 kind+amount；legs 合计）。
static func normalize_affliction_amounts(params: Dictionary) -> Dictionary:
	var dmg := maxi(int(params.get("damage", params.get("damage_amount", 0))), 0)
	var hor := maxi(int(params.get("horror", params.get("horror_amount", 0))), 0)
	dmg += _sum_leg_amounts(params.get("legs_damage", null))
	hor += _sum_leg_amounts(params.get("legs_horror", null))
	if dmg <= 0 and hor <= 0:
		var kind := StringName(str(params.get("kind", "damage")))
		var amount := maxi(int(params.get("amount", 0)), 0)
		var legs_sum := _sum_leg_amounts(params.get("legs", null))
		if legs_sum > 0:
			amount = legs_sum
		if kind == &"horror":
			hor = amount
		else:
			dmg = amount
	return {"damage": dmg, "horror": hor}


static func affliction_amounts(trigger: TriggeringCondition) -> Dictionary:
	if trigger == null:
		return {"damage": 0, "horror": 0}
	return normalize_affliction_amounts(trigger.payload)


static func _sum_leg_amounts(raw: Variant) -> int:
	if not (raw is Array):
		return 0
	var total := 0
	for leg in raw as Array:
		if leg is Dictionary:
			total += maxi(int((leg as Dictionary).get("amount", 0)), 0)
	return total


static func lose_resources(
	controller_id: StringName,
	amount: int = 1,
	all_mode: bool = false,
	after_timing: StringName = &"after_lose_resources"
) -> TriggeringCondition:
	return _effect(
		&"lose_resources",
		controller_id,
		[&"effect", &"lose_resources"],
		after_timing,
		{"amount": amount, "all": all_mode}
	)


static func lose_all_resources(
	controller_id: StringName,
	after_timing: StringName = &"after_lose_resources"
) -> TriggeringCondition:
	return lose_resources(controller_id, 0, true, after_timing)


static func heal(
	controller_id: StringName,
	kind: StringName,
	amount: int = 1,
	after_timing: StringName = &"after_heal"
) -> TriggeringCondition:
	return _effect(
		&"heal",
		controller_id,
		[&"effect", &"heal", kind],
		after_timing,
		{"kind": kind, "amount": amount}
	)


static func lose_action(
	controller_id: StringName,
	amount: int = 1,
	after_timing: StringName = &"after_lose_action"
) -> TriggeringCondition:
	return _effect(
		&"lose_action",
		controller_id,
		[&"effect", &"lose_action"],
		after_timing,
		{"amount": amount}
	)


static func place_doom(
	controller_id: StringName,
	target: StringName,
	amount: int = 1,
	card_id: StringName = &"",
	after_timing: StringName = &"after_place_doom"
) -> TriggeringCondition:
	return _effect(
		&"place_doom",
		controller_id,
		[&"effect", &"place_doom", target],
		after_timing,
		{"target": target, "amount": amount, "card_id": card_id}
	)


static func place_clue(
	controller_id: StringName,
	after_timing: StringName = &"after_place_clue"
) -> TriggeringCondition:
	return _effect(
		&"place_clue",
		controller_id,
		[&"effect", &"place_clue"],
		after_timing,
		{}
	)


static func reveal_location(
	params: Dictionary,
	after_timing: StringName = &"after_reveal_location"
) -> TriggeringCondition:
	var location_id: StringName = params.get("location_id", &"") as StringName
	var t := TriggeringCondition.new()
	t.id = StringName("reveal_location_%s_%d" % [location_id, Time.get_ticks_msec()])
	t.kind = &"reveal_location"
	t.tags = [&"effect", &"location", &"reveal"]
	t.after_timing = after_timing
	t.payload = params.duplicate()
	return t


static func effect_register(
	controller_id: StringName,
	card_id: StringName = &"",
	after_timing: StringName = &"after_effect_register"
) -> TriggeringCondition:
	return _effect(
		&"effect_register",
		controller_id,
		[&"effect", &"register"],
		after_timing,
		{"card_id": card_id}
	)


static func effect_unregister(
	controller_id: StringName,
	reg_id: StringName = &"",
	after_timing: StringName = &"after_effect_unregister"
) -> TriggeringCondition:
	return _effect(
		&"effect_unregister",
		controller_id,
		[&"effect", &"unregister"],
		after_timing,
		{"reg_id": reg_id}
	)


static func discard_card(
	controller_id: StringName,
	card_id: StringName = &"",
	after_timing: StringName = &"after_discard_card",
	from_zone: StringName = &"",
	amount: int = 1,
	mode: StringName = &"choose"
) -> TriggeringCondition:
	var tags: Array[StringName] = [&"effect", &"discard_card"]
	if from_zone == &"hand":
		tags.append(&"from_hand")
	return _effect(
		&"discard_card",
		controller_id,
		tags,
		after_timing,
		{"card_id": card_id, "from": from_zone, "amount": amount, "mode": mode}
	)


## 兼容旧工厂：统一为 discard_card + from=hand。
static func discard_from_hand(
	controller_id: StringName,
	amount: int = 1,
	mode: StringName = &"random",
	after_timing: StringName = &"after_discard_card"
) -> TriggeringCondition:
	return discard_card(controller_id, &"", after_timing, &"hand", amount, mode)


static func attach_card(
	controller_id: StringName,
	card_id: StringName = &"",
	target: StringName = &"nearest_without_same",
	after_timing: StringName = &"after_attach"
) -> TriggeringCondition:
	return _effect(
		&"attach",
		controller_id,
		[&"effect", &"attach", target],
		after_timing,
		{"card_id": card_id, "target": target}
	)


static func deal_damage(
	controller_id: StringName,
	amount: int = 1,
	target: StringName = &"controller",
	after_timing: StringName = &"after_damage"
) -> TriggeringCondition:
	return damage(controller_id, &"damage", amount, false, target, &"", after_timing)


static func resign(
	investigator_id: StringName,
	after_timing: StringName = &"after_resign"
) -> TriggeringCondition:
	return _effect(
		&"resign",
		investigator_id,
		[&"effect", &"resign"],
		after_timing,
		{"investigator_id": investigator_id}
	)


## Initiation / Forced 效果体装载帧（禁止真空 execute）。
static func ability_resolve(
	controller_id: StringName,
	ability_id: StringName = &"",
	source_id: StringName = &"",
	after_timing: StringName = &"after_ability_resolve"
) -> TriggeringCondition:
	return _effect(
		&"ability_resolve",
		controller_id,
		[&"ability", &"resolve"],
		after_timing,
		{"ability_id": ability_id, "source_id": source_id}
	)


static func _effect(
	kind: StringName,
	controller_id: StringName,
	tags: Array[StringName],
	after_timing: StringName,
	payload: Dictionary
) -> TriggeringCondition:
	var t := TriggeringCondition.new()
	t.id = StringName("%s_%s_%d" % [kind, controller_id, Time.get_ticks_msec()])
	t.kind = kind
	t.controller_id = controller_id
	t.tags = tags.duplicate()
	t.after_timing = after_timing
	t.payload = payload.duplicate()
	return t
