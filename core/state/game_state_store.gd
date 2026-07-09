class_name GameStateStore
extends RefCounted

var registry: EntityRegistry = EntityRegistry.new()
var zones: ZoneManager
var encounter_deck: Array[StringName] = []
var encounter_discard: Array[StringName] = []
var token_pool: TokenPool = TokenPool.new()
var chaos_bag: ChaosBag = ChaosBag.new()
var current_act_number: int = 1
var current_agenda_number: int = 1
var round_number: int = 0
var turn_id: int = 0
var turn_owner_id: StringName = &""
var lead_investigator_id: StringName = &""
var active_investigator_id: StringName = &""
var doom_on_agenda: int = 0
var agenda_threshold: int = 7


func _init() -> void:
	zones = ZoneManager.new(registry)


func doom_in_play() -> int:
	var total := doom_on_agenda
	for enemy_id in registry.all_enemy_ids():
		var enemy := registry.get_enemy(enemy_id)
		if enemy != null:
			total += enemy.doom
	return total


func compute_state_hash() -> String:
	return str({
		"round": round_number,
		"step_doom": doom_on_agenda,
		"investigators": registry.all_investigator_ids(),
	})
