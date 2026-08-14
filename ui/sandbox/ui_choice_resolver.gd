class_name UiChoiceResolver
extends ChoiceResolver

## 沙盒专用 · 同步阻塞等待 ChoiceModal（泵事件循环，不改引擎 await 栈）。

var _modal: ChoiceModal
var _fallback: DefaultChoiceResolver = DefaultChoiceResolver.new()


func _init(modal: ChoiceModal = null) -> void:
	_modal = modal


func bind_modal(modal: ChoiceModal) -> void:
	_modal = modal


func resolve(request: ChoiceRequest) -> Variant:
	if request == null:
		return null
	if _modal == null or not is_instance_valid(_modal):
		return _fallback.resolve(request)
	_modal.present(request)
	while _modal.is_waiting():
		DisplayServer.process_events()
		OS.delay_msec(16)
	return _modal.pick_result()
