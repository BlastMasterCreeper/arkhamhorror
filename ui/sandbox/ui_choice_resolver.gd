class_name UiChoiceResolver
extends ChoiceResolver

## 沙盒专用 · 同步阻塞等待 ChoiceModal（泵事件循环，不改引擎 await 栈）。
## auto_choice_mode ≠ ASK 时跳过模态，走 DefaultChoiceResolver.compute_for_mode。

var _modal: ChoiceModal
var _fallback: DefaultChoiceResolver = DefaultChoiceResolver.new()
var auto_choice_mode: AhcEnums.AutoChoiceMode = AhcEnums.AutoChoiceMode.ASK


func _init(modal: ChoiceModal = null) -> void:
	_modal = modal


func bind_modal(modal: ChoiceModal) -> void:
	_modal = modal


func configure_from_context(ctx: GameContext) -> void:
	if ctx == null or ctx.config == null:
		auto_choice_mode = AhcEnums.AutoChoiceMode.ASK
		return
	auto_choice_mode = ctx.config.auto_choice_mode
	_fallback.mode = auto_choice_mode
	if ctx.choices is DefaultChoiceResolver:
		_fallback.rng = (ctx.choices as DefaultChoiceResolver).rng


func resolve(request: ChoiceRequest) -> Variant:
	return resolve_choice(request).get("pick")


func resolve_choice(request: ChoiceRequest) -> Dictionary:
	if request == null:
		return {"pick": null, "used_default": true}
	if auto_choice_mode != AhcEnums.AutoChoiceMode.ASK:
		return {
			"pick": DefaultChoiceResolver.compute_for_mode(
				request, auto_choice_mode, _fallback.rng
			),
			"used_default": true,
		}
	if _modal == null or not is_instance_valid(_modal):
		return {"pick": _fallback.resolve(request), "used_default": true}
	_modal.present(request)
	while _modal.is_waiting():
		DisplayServer.process_events()
		OS.delay_msec(16)
	var pick: Variant = _modal.pick_result()
	## 取消 / 未确认 → 默认自动选用（倒计时 UI 后补；此处同等价于逾期）。
	if pick == null:
		return {
			"pick": DefaultChoiceResolver.compute_default(request),
			"used_default": true,
		}
	return {"pick": pick, "used_default": false}
