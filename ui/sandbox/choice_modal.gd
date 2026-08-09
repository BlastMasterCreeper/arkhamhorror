class_name ChoiceModal
extends CanvasLayer

## 沙盒选择浮层 · 阻塞 UiChoiceResolver 直到玩家点选。

signal choice_picked(value: Variant)

var _panel: PanelContainer
var _title: Label
var _prompt: Label
var _buttons: VBoxContainer
var _waiting: bool = false
var _result: Variant = null


func _ready() -> void:
	layer = 100
	visible = false
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(420, 200)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.14, 0.18)
	style.border_color = Color(0.7, 0.55, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_panel.add_child(v)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 18)
	_title.modulate = Color(0.95, 0.85, 0.55)
	v.add_child(_title)

	_prompt = Label.new()
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.modulate = Color(0.85, 0.85, 0.9)
	v.add_child(_prompt)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 6)
	v.add_child(_buttons)


func is_waiting() -> bool:
	return _waiting


func pick_result() -> Variant:
	return _result


func present(request: ChoiceRequest) -> void:
	_waiting = true
	_result = null
	visible = true
	_clear_buttons()
	_title.text = _kind_title(request.kind)
	_prompt.text = (
		request.prompt
		if request.prompt != ""
		else "提示：%s · 决定者 %s" % [str(request.prompt_id), str(request.decider_id)]
	)
	match request.kind:
		AhcEnums.ChoiceKind.USE_ABILITY, AhcEnums.ChoiceKind.OPTIONAL_EFFECT:
			_add_bool_buttons(request)
		AhcEnums.ChoiceKind.CONFIRM_STEP:
			_add_button("确认", true)
		AhcEnums.ChoiceKind.ORDER_SIMULTANEOUS, AhcEnums.ChoiceKind.ORDER_CARDS:
			_add_order_keep(request)
		_:
			_add_option_buttons(request)


func dismiss_with(value: Variant) -> void:
	_result = value
	_waiting = false
	visible = false
	choice_picked.emit(value)


func _add_bool_buttons(request: ChoiceRequest) -> void:
	var use_label := "使用 / 是"
	var skip_label := "跳过 / 否"
	_add_button(use_label, true)
	_add_button(skip_label, false)
	# 若 options 为 [false, true]，对齐 DefaultChoiceResolver
	if request.options.size() >= 2:
		pass


func _add_order_keep(request: ChoiceRequest) -> void:
	var arr: Array = []
	if not request.options.is_empty() and request.options[0] is Array:
		arr = (request.options[0] as Array).duplicate()
	else:
		arr = request.options.duplicate()
	_add_button("保持当前顺序", arr)


func _add_option_buttons(request: ChoiceRequest) -> void:
	if request.options.is_empty():
		_add_button("（无选项 · 取消）", null)
		return
	for i in request.options.size():
		var opt: Variant = request.options[i]
		var label := _option_label(opt, i)
		_add_button(label, opt)


func _add_button(text: String, value: Variant) -> void:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var captured: Variant = value
	btn.pressed.connect(func() -> void: dismiss_with(captured))
	_buttons.add_child(btn)


func _clear_buttons() -> void:
	for c in _buttons.get_children():
		c.queue_free()


func _option_label(opt: Variant, index: int) -> String:
	if opt is StringName or opt is String:
		return "%d. %s" % [index + 1, str(opt)]
	if opt is Dictionary:
		return "%d. %s" % [index + 1, str((opt as Dictionary).get("id", opt))]
	return "%d. %s" % [index + 1, str(opt)]


func _kind_title(kind: AhcEnums.ChoiceKind) -> String:
	match kind:
		AhcEnums.ChoiceKind.USE_ABILITY:
			return "是否发动能力"
		AhcEnums.ChoiceKind.OPTIONAL_EFFECT:
			return "可选效果"
		AhcEnums.ChoiceKind.PICK_TARGET:
			return "选择目标"
		AhcEnums.ChoiceKind.PICK_OPTION:
			return "选择一项"
		AhcEnums.ChoiceKind.PICK_MULTI:
			return "多选"
		AhcEnums.ChoiceKind.TIE_BREAK:
			return "并列裁决"
		AhcEnums.ChoiceKind.ORDER_SIMULTANEOUS:
			return "同时能力排序"
		AhcEnums.ChoiceKind.CONFIRM_STEP:
			return "确认"
		_:
			return "玩家选择 · %s" % str(kind)
