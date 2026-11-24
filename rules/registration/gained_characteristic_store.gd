class_name GainedCharacteristicStore
extends RefCounted

## Gain 特征单独管理（不是 Registration / 不是 Buff）。
## 衍生Registration 载荷 写入 RegistrationStore，id 记在 derived_reg_ids。
## 同 keyword 多来源不叠份（Grimoire）；effective 侧布尔有即可。

class GainEntry:
	extends RefCounted
	var id: StringName = &""
	var card_id: StringName = &""
	var lifetime_kind: AhcEnums.LifetimeKind = AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING
	var drawn_card_id: StringName = &""
	var gains: Array[GainedCharacteristicSpec] = []
	var derived_reg_ids: Array[StringName] = []
	var source_kind: AhcEnums.CharacteristicSourceKind = AhcEnums.CharacteristicSourceKind.ENCOUNTER


var _entries: Array = []
var _next_id: int = 0
var _registrations: RegistrationStore = null


func bind_registrations(store: RegistrationStore) -> void:
	_registrations = store


func register(template: GainTemplate) -> StringName:
	if template == null:
		return &""
	## Grimoire：同一 keyword 不能 gain 超过一次——已有效拥有则拒绝新 Gain 条目。
	for gain in template.gains:
		if gain.kind != AhcEnums.GainedCharacteristicKind.KEYWORD:
			continue
		if has_gained_keyword(template.card_id, gain.id):
			return &""
	_next_id += 1
	var gid := StringName("gain_%d" % _next_id)
	var entry := GainEntry.new()
	entry.id = gid
	entry.card_id = template.card_id
	entry.lifetime_kind = template.lifetime_kind
	entry.drawn_card_id = template.drawn_card_id
	entry.gains = template.gains.duplicate()
	entry.source_kind = template.source_kind
	if _registrations != null:
		for reg_t in template.derive_registration_templates:
			var rid := _registrations.register(reg_t)
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
	return not keyword_entries(card_id, keyword).is_empty()


func keyword_entries(card_id: StringName, keyword: StringName) -> Array:
	var out: Array = []
	if card_id == &"" or keyword == &"":
		return out
	for entry in _entries:
		var e: GainEntry = entry
		if e.card_id != card_id and e.drawn_card_id != card_id:
			continue
		for gain in e.gains:
			if (
				gain.kind == AhcEnums.GainedCharacteristicKind.KEYWORD
				and gain.id == keyword
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
		var e: GainEntry = entry
		if not found or int(e.source_kind) > int(best):
			best = e.source_kind
			found = true
	return best


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
