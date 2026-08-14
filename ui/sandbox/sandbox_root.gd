extends Control

## 规则引擎测卡沙盒 · 主界面。

var _ctx: GameContext
var _choice_modal: ChoiceModal
var _choice_resolver: UiChoiceResolver
var _card_face: CardFaceView
var _state_text: RichTextLabel
var _log_text: RichTextLabel
var _board_list: ItemList
var _lab_option: OptionButton
var _encounter_pick: OptionButton
var _selected_definition: StringName = &""
var _board_rows: Array[Dictionary] = []
var _status_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	CardTextCatalog.ensure_loaded()
	_build_ui()
	_load_lab(0)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.09, 0.12)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 12)
	root.add_theme_constant_override("margin_right", 12)
	root.add_theme_constant_override("margin_top", 10)
	root.add_theme_constant_override("margin_bottom", 10)
	add_child(root)

	var main_v := VBoxContainer.new()
	main_v.add_theme_constant_override("separation", 8)
	root.add_child(main_v)

	var header := HBoxContainer.new()
	main_v.add_child(header)
	var title := Label.new()
	title.text = "阿卡姆恐怖 · 规则引擎测卡沙盒"
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(0.92, 0.82, 0.55)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_status_label = Label.new()
	_status_label.modulate = Color(0.6, 0.75, 0.65)
	header.add_child(_status_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	main_v.add_child(body)

	# —— 左：局面 ——
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(300, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	body.add_child(left)

	left.add_child(_section_label("局面一览（点击查看卡面）"))
	_board_list = ItemList.new()
	_board_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_list.item_selected.connect(_on_board_selected)
	left.add_child(_board_list)

	_state_text = RichTextLabel.new()
	_state_text.bbcode_enabled = true
	_state_text.fit_content = false
	_state_text.scroll_active = true
	_state_text.custom_minimum_size = Vector2(0, 160)
	_state_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_state_text)

	# —— 中：卡面 ——
	var mid := VBoxContainer.new()
	mid.custom_minimum_size = Vector2(340, 0)
	mid.add_theme_constant_override("separation", 6)
	body.add_child(mid)
	mid.add_child(_section_label("卡面模板"))
	_card_face = CardFaceView.new()
	mid.add_child(_card_face)
	var face_btns := HBoxContainer.new()
	mid.add_child(face_btns)
	var flip_btn := Button.new()
	flip_btn.text = "翻看 a/b 面"
	flip_btn.pressed.connect(func() -> void: _card_face.toggle_face())
	face_btns.add_child(flip_btn)

	# —— 右：操作 + 日志 ——
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	body.add_child(right)

	right.add_child(_section_label("Lab 预设"))
	var lab_row := HBoxContainer.new()
	right.add_child(lab_row)
	_lab_option = OptionButton.new()
	_lab_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for name in SandboxLabs.lab_names():
		_lab_option.add_item(name)
	lab_row.add_child(_lab_option)
	var load_lab := Button.new()
	load_lab.text = "加载 / 重置"
	load_lab.pressed.connect(func() -> void: _load_lab(_lab_option.selected))
	lab_row.add_child(load_lab)

	right.add_child(_section_label("引擎动作"))
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_theme_constant_override("v_separation", 6)
	right.add_child(actions)
	_add_action(actions, "放置毁灭", _act_place_doom)
	_add_action(actions, "推进密谋", _act_advance_agenda)
	_add_action(actions, "抽遭遇牌", _act_draw_encounter)
	_add_action(actions, "弃牌顶抽 Fire!", _act_draw_fire_discard)
	_add_action(actions, "推进场景(花线索)", _act_advance_act)
	_add_action(actions, "调查", _act_investigate)
	_add_action(actions, "接战", _act_engage)
	_add_action(actions, "攻击", _act_fight)
	_add_action(actions, "躲避", _act_evade)
	_add_action(actions, "到行动阶段", _act_to_action_phase)
	_add_action(actions, "刷新面板", _refresh_all)

	var enc_row := HBoxContainer.new()
	right.add_child(enc_row)
	enc_row.add_child(_section_label("遭遇牌库顶塞入"))
	_encounter_pick = OptionButton.new()
	for def_id in [&"12129", &"12124", &"12130", &"12126", &"12163"]:
		_encounter_pick.add_item("%s · %s" % [def_id, CardTextCatalog.display_title(def_id)])
		_encounter_pick.set_item_metadata(_encounter_pick.item_count - 1, def_id)
	enc_row.add_child(_encounter_pick)
	var push_enc := Button.new()
	push_enc.text = "放到牌库顶"
	push_enc.pressed.connect(_act_push_encounter_top)
	enc_row.add_child(push_enc)

	right.add_child(_section_label("日志（最近）"))
	_log_text = RichTextLabel.new()
	_log_text.bbcode_enabled = true
	_log_text.scroll_active = true
	_log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_text.custom_minimum_size = Vector2(0, 180)
	right.add_child(_log_text)

	_choice_modal = ChoiceModal.new()
	add_child(_choice_modal)
	_choice_resolver = UiChoiceResolver.new(_choice_modal)


func _section_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.modulate = Color(0.7, 0.75, 0.85)
	l.add_theme_font_size_override("font_size", 13)
	return l


func _add_action(grid: GridContainer, text: String, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(cb)
	grid.add_child(btn)


func _load_lab(index: int) -> void:
	_ctx = SandboxLabs.create_context(index)
	_ctx.interaction.resolver = _choice_resolver
	_choice_resolver.bind_modal(_choice_modal)
	_status_label.text = "Lab：%s" % SandboxLabs.lab_names()[index]
	_selected_definition = &""
	_card_face.clear_card()
	_refresh_all()


func _active_inv() -> StringName:
	if _ctx == null or _ctx.state == null:
		return &"inv_1"
	if _ctx.state.active_investigator_id != &"":
		return _ctx.state.active_investigator_id
	return &"inv_1"


func _run_safe(label: String, fn: Callable) -> void:
	if _ctx == null:
		return
	var err := ""
	# 捕获脚本错误以外的失败结果
	var result: Variant = fn.call()
	if result is Dictionary and (result as Dictionary).has("ok") \
			and not bool((result as Dictionary).get("ok", true)):
		err = str((result as Dictionary).get("error", (result as Dictionary).get("reason", "failed")))
	_status_label.text = (
		"%s · 完成" % label if err == "" else "%s · 失败：%s" % [label, err]
	)
	_refresh_all()


func _act_place_doom() -> void:
	_run_safe("放置毁灭", func() -> Dictionary:
		return _ctx.sequence_catalog.run(_ctx, &"seq.mythos.place_doom", {})
	)


func _act_advance_agenda() -> void:
	_run_safe("推进密谋", func() -> Dictionary:
		return _ctx.sequence_catalog.run(
			_ctx, &"seq.agenda.advance", {"source": &"sandbox", "explicit": true}
		)
	)


func _act_draw_encounter() -> void:
	_run_safe("抽遭遇牌", func() -> Dictionary:
		return _ctx.sequence_catalog.run(
			_ctx,
			&"seq.draw.encounter",
			{"drawer_id": _active_inv(), "amount": 1}
		)
	)


func _act_draw_fire_discard() -> void:
	_run_safe("弃牌顶抽 Fire!", func() -> Dictionary:
		var ok := ScenarioCompositionAtoms.lead_draw_topmost_encounter_discard_copy(
			_ctx, &"12129"
		)
		return {"ok": ok}
	)


func _act_advance_act() -> void:
	_run_safe("推进场景", func() -> Dictionary:
		var inv := _ctx.state.registry.get_investigator(_active_inv())
		if inv != null and inv.clues_on_card < 2:
			inv.clues_on_card = maxi(inv.clues_on_card, 2)
		return _ctx.sequence_catalog.run(_ctx, &"seq.act.advance", {})
	)


func _act_investigate() -> void:
	_run_safe("调查", func() -> Dictionary:
		return _ctx.actions.execute(AhcEnums.ActionType.INVESTIGATE, _active_inv())
	)


func _act_engage() -> void:
	_run_safe("接战", func() -> Dictionary:
		var enemy_id := _first_enemy_at_active()
		return _ctx.actions.execute(
			AhcEnums.ActionType.ENGAGE, _active_inv(), {"enemy_id": enemy_id}
		)
	)


func _act_fight() -> void:
	_run_safe("攻击", func() -> Dictionary:
		var enemy_id := _first_enemy_threat_or_location()
		return _ctx.actions.execute(
			AhcEnums.ActionType.FIGHT, _active_inv(), {"enemy_id": enemy_id}
		)
	)


func _act_evade() -> void:
	_run_safe("躲避", func() -> Dictionary:
		var enemy_id := _first_enemy_threat_or_location()
		return _ctx.actions.execute(
			AhcEnums.ActionType.EVADE, _active_inv(), {"enemy_id": enemy_id}
		)
	)


func _act_to_action_phase() -> void:
	_run_safe("到行动阶段", func() -> Dictionary:
		var hops := 0
		while hops < 64:
			if _ctx.framework.is_action_phase():
				return {"ok": true}
			if _ctx.framework.waiting_player_window:
				_ctx.framework.close_player_window_and_continue()
			else:
				_ctx.framework.advance()
			hops += 1
		return {"ok": false, "reason": &"timeout"}
	)


func _act_push_encounter_top() -> void:
	var idx := _encounter_pick.selected
	var def_id: StringName = _encounter_pick.get_item_metadata(idx)
	SandboxLabs.ensure_on_encounter_deck_top(_ctx, def_id)
	_status_label.text = "已将 %s 放到遭遇牌库顶" % def_id
	_refresh_all()


func _first_enemy_at_active() -> StringName:
	var inv := _ctx.state.registry.get_investigator(_active_inv())
	if inv == null:
		return &""
	for enemy_id in _ctx.state.registry.all_enemy_ids():
		var enemy := _ctx.state.registry.get_enemy(enemy_id)
		if enemy != null and enemy.location_tag == inv.location_tag:
			return enemy_id
	return &""


func _first_enemy_threat_or_location() -> StringName:
	var inv := _ctx.state.registry.get_investigator(_active_inv())
	if inv != null and not inv.threat_area.is_empty():
		return inv.threat_area[0]
	return _first_enemy_at_active()


func _on_board_selected(index: int) -> void:
	if index < 0 or index >= _board_rows.size():
		return
	var row: Dictionary = _board_rows[index]
	_selected_definition = row.get("definition_id", &"") as StringName
	_card_face.show_definition(_selected_definition, bool(row.get("face_b", false)))


func _refresh_all() -> void:
	_refresh_board_list()
	_refresh_state()
	_refresh_log()


func _refresh_board_list() -> void:
	_board_list.clear()
	_board_rows.clear()
	if _ctx == null or _ctx.state == null:
		return
	var st := _ctx.state
	_add_row("密谋", st.current_agenda_card_id, false)
	_add_row("场景", st.current_act_card_id, false)
	if st.scenario_reference_card_id != &"":
		_add_row("场景参考", st.scenario_reference_card_id, false)
	for loc_id in st.registry.all_location_ids():
		var card := st.registry.get_card(loc_id)
		if card != null and card.zone == AhcEnums.Zone.LOCATION_AREA:
			_add_row("地点", loc_id, false)
			for att in card.attachments:
				_add_row("  附着", att.instance_id, false)
	for inv_id in st.registry.all_investigator_ids():
		var inv := st.registry.get_investigator(inv_id)
		if inv == null:
			continue
		_board_list.add_item("调查员 %s @ %s" % [inv_id, inv.location_tag])
		_board_rows.append({"definition_id": &"", "face_b": false})
		for tid in inv.threat_area:
			_add_row("  威胁区", tid, false)
		for pid in inv.play_area:
			_add_row("  场上", pid, false)
	var fire_n := 0
	for cid in st.encounter_discard:
		var c := st.registry.get_card(cid)
		if c != null and c.id.definition_id == &"12129":
			fire_n += 1
	_board_list.add_item("遭遇弃牌堆 Fire! × %d（点此项看 12129）" % fire_n)
	_board_rows.append({"definition_id": &"12129", "face_b": false})
	for cid in st.set_aside:
		_add_row("一边", cid, false)


func _add_row(prefix: String, card_id: StringName, face_b: bool) -> void:
	if card_id == &"":
		return
	var card := _ctx.state.registry.get_card(card_id)
	var def_id := card_id
	var zone_s := "?"
	if card != null:
		def_id = card.id.definition_id
		zone_s = str(card.zone)
		face_b = card.face == AhcEnums.CardFace.B
	var title := CardTextCatalog.display_title(def_id)
	_board_list.add_item("%s · %s (%s) [%s]" % [prefix, title, def_id, zone_s])
	_board_rows.append({"definition_id": def_id, "face_b": face_b, "card_id": card_id})


func _refresh_state() -> void:
	if _ctx == null or _ctx.state == null:
		_state_text.text = ""
		return
	var st := _ctx.state
	var agenda_def := &""
	var act_def := &""
	var ac := st.registry.get_card(st.current_agenda_card_id)
	var actc := st.registry.get_card(st.current_act_card_id)
	if ac != null:
		agenda_def = ac.id.definition_id
	if actc != null:
		act_def = actc.id.definition_id
	var lines: PackedStringArray = []
	lines.append("[b]回合[/b] %d · 步骤 %s" % [st.round_number, str(_ctx.framework.current_step)])
	lines.append(
		"[b]密谋[/b] #%d %s · 毁灭 %d / 阈值 %d"
		% [
			st.current_agenda_number,
			CardTextCatalog.display_title(agenda_def),
			st.doom_on_agenda,
			st.agenda_threshold,
		]
	)
	lines.append(
		"[b]场景[/b] #%d %s · 线索阈值 %d"
		% [
			st.current_act_number,
			CardTextCatalog.display_title(act_def),
			st.act_clue_threshold,
		]
	)
	if st.scenario_resolution > 0:
		lines.append("[b]结局[/b] R%d" % st.scenario_resolution)
	for inv_id in st.registry.all_investigator_ids():
		var inv := st.registry.get_investigator(inv_id)
		if inv == null:
			continue
		lines.append(
			"[b]%s[/b] 地点=%s 线索=%d 伤害=%d 恐惧=%d 资源=%d 行动=%d%s%s"
			% [
				inv_id,
				inv.location_tag,
				inv.clues_on_card,
				inv.damage_taken,
				inv.horror_taken,
				inv.resource_pool,
				inv.actions_remaining,
				" [已击败]" if inv.eliminated else "",
				" 创伤体%d/精%d" % [inv.physical_trauma, inv.mental_trauma]
				if inv.physical_trauma + inv.mental_trauma > 0
				else "",
			]
		)
	_state_text.text = "\n".join(lines)


func _refresh_log() -> void:
	if _ctx == null or _ctx.log == null:
		_log_text.text = ""
		return
	var entries := _ctx.log.get_entries()
	var start := maxi(entries.size() - 40, 0)
	var parts: PackedStringArray = []
	for i in range(start, entries.size()):
		var e: Dictionary = entries[i]
		parts.append(
			"[color=#8899aa]%s[/color] %s"
			% [str(e.get("message", "")), _short_payload(e.get("payload", {}))]
		)
	_log_text.text = "\n".join(parts)


func _short_payload(payload: Variant) -> String:
	if payload is Dictionary:
		var d: Dictionary = payload
		if d.is_empty():
			return ""
		var keys: Array = d.keys()
		var bits: PackedStringArray = []
		for i in mini(keys.size(), 4):
			bits.append("%s=%s" % [str(keys[i]), str(d[keys[i]])])
		return "(%s)" % ", ".join(bits)
	return ""
