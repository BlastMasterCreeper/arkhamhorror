class_name GainedCharacteristicStore
extends RefCounted

## Gain 特征单独管理（不是 Registration / 不是 Buff）。
## 衍生Registration 载荷 写入 RegistrationStore，id 记在 derived_reg_ids。

class GainEntry:
	extends RefCounted
	var id: StringName = &""
	var card_id: StringName = &""
	var lifetime_kind: AhcEnums.LifetimeKind = AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING
	var drawn_card_id: StringName = &""
	var gains: Array[GainedCharacteristicSpec] = []
	var derived_reg_ids: Array[StringName] = []


var _entries: Array = []
var _next_id: int = 0
var _registrations: RegistrationStore = null


func bind_registrations(store: RegistrationStore) -> void:
	_registrations = store


func register(template: GainTemplate) -> StringName:
	if template == null:
		return &""
	_next_id += 1
	var gid := StringName("gain_%d" % _next_id)
	var entry := GainEntry.new()
	entry.id = gid
	entry.card_id = template.card_id
	entry.lifetime_kind = template.lifetime_kind
	entry.drawn_card_id = template.drawn_card_id
	entry.gains = template.gains.duplicate()
	if _registrations != null:
		for buff_t in template.derive_buff_templates:
			var rid := _registrations.register(buff_t)
			if rid != &"":
				entry.derived_reg_ids.append(rid)
	_entries.append(entry)
	return gid


func unregister(id: StringName) -> void:
	for i in range(_entries.size() - 1, -1, -1):
		var entry: GainEntry = _entries[i]
		if entry.id != id:
			continue
		if _registrations != null:
			for rid in entry.derived_reg_ids:
				_registrations.unregister(rid)
		_entries.remove_at(i)
		return


func has_gained_keyword(card_id: StringName, keyword: StringName) -> bool:
	if card_id == &"" or keyword == &"":
		return false
	for entry in _entries:
		var e: GainEntry = entry
		if e.card_id != card_id and e.drawn_card_id != card_id:
			continue
		for gain in e.gains:
			if (
				gain.kind == AhcEnums.GainedCharacteristicKind.KEYWORD
				and gain.id == keyword
			):
				return true
	return false


func unregister_keywords_for_drawn_card(card_id: StringName) -> void:
	if card_id == &"":
		return
	var to_remove: Array[StringName] = []
	for entry in _entries:
		var e: GainEntry = entry
		if e.lifetime_kind != AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING:
			continue
		if e.drawn_card_id != card_id and e.card_id != card_id:
			continue
		var has_kw := false
		for gain in e.gains:
			if gain.kind == AhcEnums.GainedCharacteristicKind.KEYWORD:
				has_kw = true
				break
		if has_kw:
			to_remove.append(e.id)
	for id in to_remove:
		unregister(id)


func count() -> int:
	return _entries.size()
