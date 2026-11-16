class_name AgendaDoomQuery
extends RefCounted

## 密谋 doom 只读：场面总量 / 是否达阈值。


static func doom_in_play(state: GameStateStore) -> int:
	if state == null:
		return 0
	return state.doom_in_play()


static func meets_threshold(state: GameStateStore) -> bool:
	if state == null:
		return false
	return doom_in_play(state) >= state.agenda_threshold
