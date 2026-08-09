class_name PerInvestigatorScale
extends RefCounted

## [per_investigator] 缩放 · 09 §5 / Grimoire。


static func count(state: GameStateStore) -> int:
	if state == null or state.per_investigator_count <= 0:
		return 1
	return state.per_investigator_count


static func scale(state: GameStateStore, base: int) -> int:
	return base * count(state)


static func place_location_clues(state: GameStateStore, printed_clues: int) -> int:
	if printed_clues < 0:
		return 0
	return scale(state, printed_clues)
