class_name RulesMemory
extends RefCounted

var phase_trace: Array[String] = []
var _referents: Dictionary = {}


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
	return copy
