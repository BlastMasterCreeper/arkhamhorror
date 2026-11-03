class_name CommitPool
extends RefCounted

## ST.2 预投入池：入池仅校验、不生效；确认后整批同时投入（04 · Commit）。

var entries: Array[CommittedCard] = []


func clear() -> void:
	entries.clear()


func is_empty() -> bool:
	return entries.is_empty()


func size() -> int:
	return entries.size()


func has_card(card_id: StringName) -> bool:
	for e in entries:
		if e.card_id == card_id:
			return true
	return false


func count_for(investigator_id: StringName) -> int:
	var n := 0
	for e in entries:
		if e.from_investigator == investigator_id:
			n += 1
	return n


func count_by_definition(definition_id: StringName, state: GameStateStore) -> int:
	if state == null:
		return 0
	var n := 0
	for e in entries:
		var card := state.registry.get_card(e.card_id)
		if card != null and card.id.definition_id == definition_id:
			n += 1
	return n


func count_by_title(title: String, state: GameStateStore) -> int:
	if state == null or title == "":
		return 0
	var n := 0
	for e in entries:
		var card := state.registry.get_card(e.card_id)
		if card == null:
			continue
		if CardRegistry.title(card.id.definition_id) == title:
			n += 1
	return n


func add(entry: CommittedCard) -> void:
	if entry == null:
		return
	entries.append(entry)


func remove_card(card_id: StringName) -> bool:
	for i in range(entries.size()):
		if entries[i].card_id == card_id:
			entries.remove_at(i)
			return true
	return false


func snapshot() -> Array[CommittedCard]:
	var out: Array[CommittedCard] = []
	for e in entries:
		out.append(e)
	return out
