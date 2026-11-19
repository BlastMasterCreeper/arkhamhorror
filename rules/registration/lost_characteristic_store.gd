class_name LostCharacteristicStore
extends RefCounted

## 失去特征覆盖（不是 Registration）。与 GainStore 并列；effective 查询时互斥裁决。

class LoseEntry:
	extends RefCounted
	var id: StringName = &""
	var card_id: StringName = &""
	var lifetime_kind: AhcEnums.LifetimeKind = AhcEnums.LifetimeKind.WHILE_IN_PLAY
	var drawn_card_id: StringName = &""
	var losses: Array[GainedCharacteristicSpec] = []
	var source_kind: AhcEnums.CharacteristicSourceKind = AhcEnums.CharacteristicSourceKind.PLAYER


var _entries: Array = []
var _next_id: int = 0


func register(template: LoseTemplate) -> StringName:
	if template == null:
		return &""
	_next_id += 1
	var lid := StringName("lose_%d" % _next_id)
	var entry := LoseEntry.new()
	entry.id = lid
	entry.card_id = template.card_id
	entry.lifetime_kind = template.lifetime_kind
	entry.drawn_card_id = template.drawn_card_id
	entry.losses = template.losses.duplicate()
	entry.source_kind = template.source_kind
	_entries.append(entry)
	return lid


func unregister(id: StringName) -> void:
	for i in range(_entries.size() - 1, -1, -1):
		var entry: LoseEntry = _entries[i]
		if entry.id != id:
			continue
		_entries.remove_at(i)
		return


func has_lost_keyword(card_id: StringName, keyword: StringName) -> bool:
	return not keyword_entries(card_id, keyword).is_empty()


func keyword_entries(card_id: StringName, keyword: StringName) -> Array:
	var out: Array = []
	if card_id == &"" or keyword == &"":
		return out
	for entry in _entries:
		var e: LoseEntry = entry
		if e.card_id != card_id and e.drawn_card_id != card_id:
			continue
		for loss in e.losses:
			if (
				loss.kind == AhcEnums.GainedCharacteristicKind.KEYWORD
				and loss.id == keyword
			):
				out.append(e)
				break
	return out


func best_source_for_keyword(
	card_id: StringName, keyword: StringName
) -> AhcEnums.CharacteristicSourceKind:
	var best := AhcEnums.CharacteristicSourceKind.PRINTED
	var found := false
	for entry in keyword_entries(card_id, keyword):
		var e: LoseEntry = entry
		if not found or int(e.source_kind) > int(best):
			best = e.source_kind
			found = true
	return best


func unregister_for_drawn_card(card_id: StringName) -> void:
	if card_id == &"":
		return
	var to_remove: Array[StringName] = []
	for entry in _entries:
		var e: LoseEntry = entry
		if e.lifetime_kind != AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING:
			continue
		if e.drawn_card_id != card_id and e.card_id != card_id:
			continue
		to_remove.append(e.id)
	for id in to_remove:
		unregister(id)


func on_card_leave_play(card_id: StringName) -> void:
	if card_id == &"":
		return
	var to_remove: Array[StringName] = []
	for entry in _entries:
		var e: LoseEntry = entry
		if e.lifetime_kind != AhcEnums.LifetimeKind.WHILE_IN_PLAY:
			continue
		if e.card_id != card_id:
			continue
		to_remove.append(e.id)
	for id in to_remove:
		unregister(id)


func count() -> int:
	return _entries.size()
