class_name RulesMemory
extends RefCounted

var phase_trace: Array[String] = []
var _referents: Dictionary = {}
var _encounter_frame_stack: Array[EncounterResolutionFrame] = []


func push_encounter_frame(frame: EncounterResolutionFrame) -> void:
	if frame != null:
		_encounter_frame_stack.append(frame)


func pop_encounter_frame() -> EncounterResolutionFrame:
	if _encounter_frame_stack.is_empty():
		return null
	return _encounter_frame_stack.pop_back()


func peek_encounter_frame() -> EncounterResolutionFrame:
	if _encounter_frame_stack.is_empty():
		return null
	return _encounter_frame_stack[_encounter_frame_stack.size() - 1]


func top_encounter_frame_if_peril() -> EncounterResolutionFrame:
	var frame := peek_encounter_frame()
	if frame != null and frame.peril:
		return frame
	return null


func encounter_frame_depth() -> int:
	return _encounter_frame_stack.size()


func clear_trace() -> void:
	phase_trace.clear()


func record_phase(trigger: TriggeringCondition, phase: AhcEnums.SequencePhase, depth: int) -> void:
	var phase_name := phase_label(phase)
	phase_trace.append("%s:%s@%d" % [phase_name, trigger.kind, depth])


func set_referent(controller_id: StringName, key: StringName, value: Variant) -> void:
	var bucket: Dictionary = _referents.get(controller_id, {})
	bucket[key] = value
	_referents[controller_id] = bucket


func get_referent(controller_id: StringName, key: StringName) -> Variant:
	var bucket: Dictionary = _referents.get(controller_id, {})
	return bucket.get(key)


func get_referents(controller_id: StringName) -> Dictionary:
	var bucket: Dictionary = _referents.get(controller_id, {})
	return bucket.duplicate()


func phase_label(phase: AhcEnums.SequencePhase) -> String:
	match phase:
		AhcEnums.SequencePhase.WHEN:
			return "WHEN"
		AhcEnums.SequencePhase.RESOLVE:
			return "RESOLVE"
		AhcEnums.SequencePhase.AFTER:
			return "AFTER"
	return "?"


func duplicate_memory() -> RulesMemory:
	var copy := RulesMemory.new()
	copy.phase_trace = phase_trace.duplicate()
	copy._referents = _referents.duplicate(true)
	copy._encounter_frame_stack = _encounter_frame_stack.duplicate()
	return copy
