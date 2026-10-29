class_name RulesMemory
extends RefCounted

## 步间指称 + 命名流程打断/替换账本（Cancel / Ignore① / Instead）。
## 取代旧 PendingResolutionStore：身份是 seq.* + bind，不是 EffectOp pending。

var phase_trace: Array[String] = []
var _referents: Dictionary = {}
var _encounter_frame_stack: Array[EncounterResolutionFrame] = []
var _cancelled_sequence_keys: Dictionary = {}
var _ignored_sequence_keys: Dictionary = {}
## key → Array[{ "params": Dictionary, "source_ability_id": StringName, "initiation_seq": int }]
var _sequence_replacements: Dictionary = {}
var _next_replacement_seq: int = 0


static func sequence_bind_key(flow_id: StringName, bind: Dictionary = {}) -> StringName:
	## 身份轴：card_id（含 source/enemy 别名）或 effect_instance；ability_id 仅审计，不进 key。
	var card_id: StringName = bind.get("card_id", &"") as StringName
	if card_id != &"":
		return StringName("%s:%s" % [flow_id, card_id])
	var effect_instance: StringName = bind.get("effect_instance", &"") as StringName
	if effect_instance != &"":
		return StringName("%s:%s" % [flow_id, effect_instance])
	return flow_id


## Catalog / handler 共用：从手续 params 抽出打断身份 bind。
static func effect_bind_from_params(params: Dictionary) -> Dictionary:
	var bind := {}
	var card_id: StringName = params.get("card_id", &"") as StringName
	if card_id == &"":
		card_id = params.get("source_id", &"") as StringName
	if card_id == &"":
		card_id = params.get("enemy_id", &"") as StringName
	if card_id == &"":
		card_id = params.get("investigator_id", &"") as StringName
	if card_id != &"":
		bind["card_id"] = card_id
	var effect_instance: StringName = params.get("effect_instance", &"") as StringName
	if effect_instance != &"":
		bind["effect_instance"] = effect_instance
	var ability_id: StringName = params.get("ability_id", &"") as StringName
	if ability_id != &"":
		bind["ability_id"] = ability_id
	var controller_id: StringName = params.get("controller_id", &"") as StringName
	if controller_id == &"":
		controller_id = params.get("inv_id", &"") as StringName
	if controller_id != &"":
		bind["controller_id"] = controller_id
	return bind


func cancel_sequence(flow_id: StringName, bind: Dictionary = {}) -> void:
	var key := sequence_bind_key(flow_id, bind)
	_cancelled_sequence_keys[key] = true
	## Cancel 关闭该身份上的替换窗。
	_sequence_replacements.erase(key)
	_ignored_sequence_keys.erase(key)


func is_sequence_cancelled(flow_id: StringName, bind: Dictionary = {}) -> bool:
	return bool(_cancelled_sequence_keys.get(sequence_bind_key(flow_id, bind), false))


func clear_sequence_cancel(flow_id: StringName, bind: Dictionary = {}) -> void:
	_cancelled_sequence_keys.erase(sequence_bind_key(flow_id, bind))


## Ignore①：保留发起身份，结算时跳过施加（与 Cancel 注销不同）。
func ignore_sequence(flow_id: StringName, bind: Dictionary = {}) -> Dictionary:
	var key := sequence_bind_key(flow_id, bind)
	if bool(_cancelled_sequence_keys.get(key, false)):
		return {"ok": false, "error": "sequence_cancelled"}
	if bool(_ignored_sequence_keys.get(key, false)):
		return {"ok": true, "already_ignored": true}
	_ignored_sequence_keys[key] = true
	## Ignore 后不可再挂 Instead。
	_sequence_replacements.erase(key)
	return {"ok": true}


func is_sequence_ignored(flow_id: StringName, bind: Dictionary = {}) -> bool:
	return bool(_ignored_sequence_keys.get(sequence_bind_key(flow_id, bind), false))


func clear_sequence_ignore(flow_id: StringName, bind: Dictionary = {}) -> void:
	_ignored_sequence_keys.erase(sequence_bind_key(flow_id, bind))


## Instead：对尚未结算的命名流程身份登记替换载荷（最近 initiation_seq 胜）。
func register_sequence_replacement(
	flow_id: StringName,
	bind: Dictionary,
	replacement_params: Dictionary,
	source_ability_id: StringName = &""
) -> Dictionary:
	var key := sequence_bind_key(flow_id, bind)
	if bool(_cancelled_sequence_keys.get(key, false)):
		return {"ok": false, "error": "sequence_cancelled"}
	if bool(_ignored_sequence_keys.get(key, false)):
		return {"ok": false, "error": "sequence_ignored"}
	_next_replacement_seq += 1
	var entry := {
		"params": replacement_params.duplicate(true),
		"source_ability_id": source_ability_id,
		"initiation_seq": _next_replacement_seq,
	}
	var bucket: Array = _sequence_replacements.get(key, [])
	bucket.append(entry)
	_sequence_replacements[key] = bucket
	return {"ok": true, "initiation_seq": _next_replacement_seq}


func winning_sequence_replacement(flow_id: StringName, bind: Dictionary = {}) -> Dictionary:
	var key := sequence_bind_key(flow_id, bind)
	var bucket: Array = _sequence_replacements.get(key, [])
	if bucket.is_empty():
		return {}
	var winner: Dictionary = bucket[0]
	for item in bucket:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if int(item.get("initiation_seq", 0)) > int(winner.get("initiation_seq", 0)):
			winner = item
	return winner


func clear_sequence_replacements(flow_id: StringName, bind: Dictionary = {}) -> void:
	_sequence_replacements.erase(sequence_bind_key(flow_id, bind))


## 效果手续开跑前：读 Cancel / Ignore / Instead，并消费打断账本。
func consume_effect_gate(flow_id: StringName, bind: Dictionary = {}) -> Dictionary:
	if is_sequence_cancelled(flow_id, bind):
		clear_sequence_cancel(flow_id, bind)
		clear_sequence_ignore(flow_id, bind)
		clear_sequence_replacements(flow_id, bind)
		return {"ok": false, "cancelled": true, "error": "sequence_cancelled"}
	if is_sequence_ignored(flow_id, bind):
		clear_sequence_ignore(flow_id, bind)
		clear_sequence_replacements(flow_id, bind)
		return {"ok": true, "ignored": true, "applied": false}
	var winner := winning_sequence_replacement(flow_id, bind)
	clear_sequence_replacements(flow_id, bind)
	if not winner.is_empty():
		return {
			"ok": true,
			"replaced": true,
			"replacement_params": winner.get("params", {}),
			"source_ability_id": winner.get("source_ability_id", &""),
		}
	return {"ok": true}


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
	## @deprecated 使用 RegistrationStore.has_peril_for_drawn_card + current_card_id
	var frame := peek_encounter_frame()
	if frame == null:
		return null
	return frame


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


func duplicate_referents() -> Dictionary:
	return _referents.duplicate(true)


func phase_label(phase: AhcEnums.SequencePhase) -> String:
	match phase:
		AhcEnums.SequencePhase.WOULD:
			return "WOULD"
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
	copy._cancelled_sequence_keys = _cancelled_sequence_keys.duplicate()
	copy._ignored_sequence_keys = _ignored_sequence_keys.duplicate()
	copy._sequence_replacements = _sequence_replacements.duplicate(true)
	copy._next_replacement_seq = _next_replacement_seq
	return copy
