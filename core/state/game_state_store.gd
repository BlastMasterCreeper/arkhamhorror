class_name GameStateStore
extends RefCounted

var registry: EntityRegistry = EntityRegistry.new()
var zones: ZoneManager
var token_pool: TokenPool = TokenPool.new()
var chaos_bag: ChaosBag = ChaosBag.new()
var current_act_number: int = 1
var round_number: int = 0
var lead_investigator_id: StringName = &""
var active_investigator_id: StringName = &""
var doom_on_agenda: int = 0
var agenda_threshold: int = 7


func _init() -> void:
	zones = ZoneManager.new(registry)


func doom_in_play() -> int:
	return doom_on_agenda


func compute_state_hash() -> String:
	return str({
		"round": round_number,
		"step_doom": doom_on_agenda,
		"investigators": registry.all_investigator_ids(),
	})
