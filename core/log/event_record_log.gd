class_name EventRecordLog
extends RefCounted

var _records: Array[EventRecord] = []
var _seq: int = 0
var event_index: EventIndex = EventIndex.new()


func append(
	p_kind: AhcEnums.EventRecordKind,
	p_payload: Dictionary = {},
	p_state_hash: String = ""
) -> EventRecord:
	var rec := EventRecord.new()
	rec.seq = _seq
	_seq += 1
	rec.timestamp_ms = Time.get_ticks_msec()
	rec.kind = p_kind
	rec.payload = p_payload
	rec.state_hash = p_state_hash
	_records.append(rec)
	return rec


func append_framework(step: AhcEnums.FrameworkStep, state_hash: String, extra: Dictionary = {}) -> void:
	var rec := append(AhcEnums.EventRecordKind.FRAMEWORK_STEP, extra, state_hash)
	rec.framework_step = step


func append_initiation(step: AhcEnums.InitiationStep, state_hash: String, extra: Dictionary = {}) -> void:
	var rec := append(AhcEnums.EventRecordKind.INITIATION_STEP, extra, state_hash)
	rec.initiation_step = step


func append_skill_test(step: AhcEnums.SkillTestStep, state_hash: String, extra: Dictionary = {}) -> void:
	var rec := append(AhcEnums.EventRecordKind.SKILL_TEST_STEP, extra, state_hash)
	rec.skill_test_step = step


func get_records() -> Array[EventRecord]:
	return _records


func last_seq() -> int:
	if _records.is_empty():
		return -1
	return _records[_records.size() - 1].seq


func record_count() -> int:
	return _records.size()
