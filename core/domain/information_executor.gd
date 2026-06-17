class_name InformationExecutor
extends RefCounted

var _state: GameStateStore


func _init(state: GameStateStore) -> void:
	_state = state


func reveal_to_controller(card_id: StringName, controller_id: StringName) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null or controller_id == &"":
		return false
	card.controller_id = controller_id
	card.face_visibility.audience = AhcEnums.FaceAudience.CONTROLLER
	return true


func reveal_to_all(card_id: StringName) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	card.face_visibility.audience = AhcEnums.FaceAudience.ALL
	return true


func hide_from_all(card_id: StringName) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	card.face_visibility.audience = AhcEnums.FaceAudience.HIDDEN_ALL
	return true
