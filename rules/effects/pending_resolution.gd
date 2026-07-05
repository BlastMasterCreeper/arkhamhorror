class_name PendingResolution
extends RefCounted

enum State { OPEN, IGNORED, RESOLVED }

var id: StringName = &""
var triggering_condition_id: StringName = &""
var request: EffectRequest = null
var state: State = State.OPEN
var replacements: Array[ReplacementCandidate] = []
var resolved_request: EffectRequest = null
var was_replaced: bool = false
var was_ignored: bool = false


func is_registered() -> bool:
	return state == State.OPEN or state == State.IGNORED


func blocks_replacement() -> bool:
	return state != State.OPEN
