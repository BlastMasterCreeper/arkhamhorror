class_name CardFaceView
extends PanelContainer

## 文字卡面模板 · 无官方插画。

var _stripe: ColorRect
var _type_label: Label
var _title_label: Label
var _meta_label: Label
var _body: RichTextLabel
var _flavor: RichTextLabel
var _id_label: Label
var _face_b: bool = false
var _definition_id: StringName = &""


func _ready() -> void:
	_build()


func _build() -> void:
	custom_minimum_size = Vector2(320, 440)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.93, 0.89, 0.78)
	style.border_color = Color(0.25, 0.18, 0.12)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(v)

	_stripe = ColorRect.new()
	_stripe.custom_minimum_size = Vector2(0, 8)
	_stripe.color = Color(0.35, 0.28, 0.22)
	v.add_child(_stripe)

	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 12)
	_type_label.modulate = Color(0.25, 0.2, 0.15)
	v.add_child(_type_label)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.modulate = Color(0.12, 0.08, 0.05)
	v.add_child(_title_label)

	_meta_label = Label.new()
	_meta_label.add_theme_font_size_override("font_size", 13)
	_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_meta_label.modulate = Color(0.3, 0.22, 0.15)
	v.add_child(_meta_label)

	var sep := HSeparator.new()
	v.add_child(sep)

	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = false
	_body.scroll_active = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.custom_minimum_size = Vector2(0, 180)
	_body.add_theme_color_override("default_color", Color(0.1, 0.08, 0.05))
	v.add_child(_body)

	_flavor = RichTextLabel.new()
	_flavor.bbcode_enabled = true
	_flavor.fit_content = true
	_flavor.scroll_active = false
	_flavor.custom_minimum_size = Vector2(0, 48)
	_flavor.add_theme_color_override("default_color", Color(0.35, 0.28, 0.2))
	v.add_child(_flavor)

	_id_label = Label.new()
	_id_label.add_theme_font_size_override("font_size", 11)
	_id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_id_label.modulate = Color(0.4, 0.35, 0.3)
	v.add_child(_id_label)

	clear_card()


func clear_card() -> void:
	_definition_id = &""
	_type_label.text = "未选中卡牌"
	_title_label.text = "—"
	_meta_label.text = ""
	_body.text = "在左侧局面列表中点击卡牌查看。"
	_flavor.text = ""
	_id_label.text = ""
	_stripe.color = Color(0.45, 0.4, 0.35)


func show_definition(definition_id: StringName, face_b: bool = false) -> void:
	CardTextCatalog.ensure_loaded()
	_definition_id = definition_id
	_face_b = face_b
	if definition_id == &"":
		clear_card()
		return
	var ctype := CardRegistry.card_type(definition_id)
	_stripe.color = _stripe_for_type(ctype)
	_type_label.text = _type_label_zh(ctype) + (" · b 面" if face_b else " · a 面")
	if face_b:
		var bn := CardTextCatalog.display_back_name(definition_id)
		_title_label.text = bn if bn != "" else CardTextCatalog.display_title(definition_id)
	else:
		_title_label.text = CardTextCatalog.display_title(definition_id)
	_meta_label.text = _meta_line(definition_id, ctype)
	_body.text = CardTextCatalog.to_bbcode(
		CardTextCatalog.display_text(definition_id, face_b)
	)
	var fl := CardTextCatalog.display_flavor(definition_id, face_b)
	_flavor.text = "[i]%s[/i]" % CardTextCatalog.to_bbcode(fl) if fl != "" else ""
	_id_label.text = str(definition_id)


func toggle_face() -> void:
	if _definition_id == &"":
		return
	show_definition(_definition_id, not _face_b)


func _meta_line(definition_id: StringName, ctype: StringName) -> String:
	var parts: PackedStringArray = []
	var traits_arr := CardRegistry.traits(definition_id)
	if not traits_arr.is_empty():
		var tnames: PackedStringArray = []
		for t in traits_arr:
			tnames.append(str(t))
		parts.append(" · ".join(tnames))
	match ctype:
		&"enemy":
			var data := CardRegistry.definition_data(definition_id)
			var enemy: Dictionary = data.get("enemy", {})
			parts.append(
				"战 %s / 躲 %s / 血 %s"
				% [
					str(enemy.get("fight", "?")),
					str(enemy.get("evade", "?")),
					str(enemy.get("health", "?")),
				]
			)
		&"location":
			parts.append(
				"隐蔽 %d · 线索印刷 %d"
				% [
					CardRegistry.location_shroud(definition_id),
					CardRegistry.location_printed_clues(definition_id),
				]
			)
		&"agenda":
			var doom := CardRegistry.scenario_doom_threshold(definition_id)
			if doom >= 0:
				parts.append("毁灭阈值 %d" % doom)
		&"act":
			var clues := CardRegistry.scenario_clue_threshold(definition_id)
			if clues >= 0:
				parts.append("线索阈值 %d" % clues)
	return "  |  ".join(parts)


func _stripe_for_type(ctype: StringName) -> Color:
	match ctype:
		&"treachery":
			return Color(0.45, 0.12, 0.12)
		&"enemy":
			return Color(0.55, 0.2, 0.15)
		&"location":
			return Color(0.2, 0.4, 0.25)
		&"agenda":
			return Color(0.35, 0.15, 0.4)
		&"act":
			return Color(0.15, 0.3, 0.5)
		&"asset":
			return Color(0.55, 0.45, 0.15)
		_:
			return Color(0.35, 0.28, 0.22)


func _type_label_zh(ctype: StringName) -> String:
	match ctype:
		&"treachery":
			return "诡计"
		&"enemy":
			return "敌人"
		&"location":
			return "地点"
		&"agenda":
			return "密谋"
		&"act":
			return "场景"
		&"asset":
			return "支援"
		&"event":
			return "事件"
		&"skill":
			return "技能"
		&"scenario":
			return "场景参考"
		_:
			return str(ctype)
