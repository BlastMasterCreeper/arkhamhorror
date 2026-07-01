class_name StatScope
extends RefCounted

var inv_id: StringName = &""
var turn_id: int = 0


static func for_inv_turn(inv_id: StringName, turn_id: int) -> StatScope:
	var s := StatScope.new()
	s.inv_id = inv_id
	s.turn_id = turn_id
	return s


static func from_state(state: GameStateStore, inv_id: StringName = &"") -> StatScope:
	var s := StatScope.new()
	if inv_id == &"" and state != null:
		inv_id = state.turn_owner_id if state.turn_owner_id != &"" else state.active_investigator_id
	s.inv_id = inv_id
	s.turn_id = state.turn_id if state != null else 0
	return s


func projection_key(stat_key: AhcEnums.StatKey) -> StringName:
	return StringName("%d:%s:%d" % [stat_key, inv_id, turn_id])


func interest_token(stat_key: AhcEnums.StatKey) -> StringName:
	return StringName("%d:%s" % [stat_key, inv_id])
