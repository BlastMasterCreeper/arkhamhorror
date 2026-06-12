class_name CardScriptBase
extends RefCounted

var ctx: GameContext
var instance: CardInstance


func _init(context: GameContext, card: CardInstance) -> void:
	ctx = context
	instance = card
