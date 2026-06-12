class_name EffectRequest
extends RefCounted

var op: AhcEnums.EffectOp = AhcEnums.EffectOp.CUSTOM
var source_id: StringName = &""
var controller_id: StringName = &""
var targets: Array = []
var amount: int = 0
var options: Dictionary = {}
