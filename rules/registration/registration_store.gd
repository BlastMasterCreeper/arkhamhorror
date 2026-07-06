class_name RegistrationStore
extends RefCounted

var _entries: Array[Registration] = []
var _next_id: int = 0
var _stat_projections: StatProjectionStore = null


func bind_stat_projections(store: StatProjectionStore) -> void:
	_stat_projections = store


func register(template: RegistrationTemplate) -> StringName:
	_next_id += 1
	var reg_id := StringName("reg_%d" % _next_id)
	var reg := Registration.from_template(template, reg_id)
	_entries.append(reg)
	if _stat_projections != null:
		_stat_projections.attach(reg_id, template.stat_queries, template.controller_id)
	return reg_id


func unregister(id: StringName) -> void:
	if _stat_projections != null:
		_stat_projections.detach(id)
	for i in range(_entries.size() - 1, -1, -1):
		if _entries[i].id == id:
			_entries.remove_at(i)
			return


func unregister_by_drawn_card(card_id: StringName) -> void:
	if card_id == &"":
		return
	var to_remove: Array[StringName] = []
	for reg in _entries:
		if reg.lifetime_kind != AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING:
			continue
		if reg.drawn_card_id != card_id:
			continue
		var removes_peril := false
		for buff in reg.buffs:
			if buff.type == AhcEnums.BuffType.RESTRICTION:
				removes_peril = true
				break
		if removes_peril:
			to_remove.append(reg.id)
	for id in to_remove:
		unregister(id)


func has_keyword_buff(card_id: StringName, keyword: StringName) -> bool:
	if card_id == &"" or keyword == &"":
		return false
	for reg in _entries:
		if reg.lifetime_kind != AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING:
			continue
		if reg.drawn_card_id != card_id:
			continue
		for buff in reg.buffs:
			if buff.type == AhcEnums.BuffType.KEYWORD and buff.keyword == keyword:
				return true
	return false


func unregister_gained_keywords_for_drawn_card(card_id: StringName) -> void:
	if card_id == &"":
		return
	var to_remove: Array[StringName] = []
	for reg in _entries:
		if reg.lifetime_kind != AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING:
			continue
		if reg.drawn_card_id != card_id:
			continue
		var has_keyword := false
		for buff in reg.buffs:
			if buff.type == AhcEnums.BuffType.KEYWORD:
				has_keyword = true
				break
		if has_keyword:
			to_remove.append(reg.id)
	for id in to_remove:
		unregister(id)


func unregister_by_hidden_in_hand_card(card_id: StringName) -> void:
	if card_id == &"":
		return
	var to_remove: Array[StringName] = []
	for reg in _entries:
		if reg.lifetime_kind == AhcEnums.LifetimeKind.WHILE_HIDDEN_IN_HAND \
				and reg.drawn_card_id == card_id:
			to_remove.append(reg.id)
	for id in to_remove:
		unregister(id)


func has_hidden_leave_hand_restriction(card_id: StringName) -> bool:
	if card_id == &"":
		return false
	for reg in _entries:
		if reg.lifetime_kind != AhcEnums.LifetimeKind.WHILE_HIDDEN_IN_HAND:
			continue
		if reg.drawn_card_id != card_id:
			continue
		for buff in reg.buffs:
			if buff.type == AhcEnums.BuffType.RESTRICTION:
				return true
	return false


func has_peril_for_drawn_card(card_id: StringName) -> bool:
	if card_id == &"":
		return false
	for reg in _entries:
		if reg.lifetime_kind != AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING:
			continue
		if reg.drawn_card_id != card_id:
			continue
		for buff in reg.buffs:
			if buff.type == AhcEnums.BuffType.RESTRICTION:
				return true
	return false


func unregister_by_encounter_frame(frame_id: StringName) -> void:
	if frame_id == &"":
		return
	var to_remove: Array[StringName] = []
	for reg in _entries:
		if reg.lifetime_kind == AhcEnums.LifetimeKind.WHILE_ENCOUNTER_FRAME \
				and reg.encounter_frame_id == frame_id:
			to_remove.append(reg.id)
	for id in to_remove:
		unregister(id)


func count() -> int:
	return _entries.size()


func collect_modifiers(controller_id: StringName) -> Array[ModifierPayload]:
	var out: Array[ModifierPayload] = []
	for reg in _entries:
		if reg.controller_id != controller_id and reg.controller_id != &"":
			continue
		for buff in reg.buffs:
			if buff.type == AhcEnums.BuffType.MODIFIER and buff.modifier:
				out.append(buff.modifier)
	return out


func all_registrations() -> Array[Registration]:
	return _entries.duplicate()


func collect_listeners(timing_name: StringName) -> Array[ListenerEntry]:
	var out: Array[ListenerEntry] = []
	for reg in _entries:
		for buff in reg.buffs:
			if buff.type != AhcEnums.BuffType.LISTENER or buff.listener == null:
				continue
			if buff.listener.timing != timing_name:
				continue
			var entry := ListenerEntry.new()
			entry.reg_id = reg.id
			entry.lifetime_kind = reg.lifetime_kind
			entry.composition = buff.listener.composition
			out.append(entry)
	return out


func duplicate_store() -> RegistrationStore:
	var copy := RegistrationStore.new()
	copy._next_id = _next_id
	for reg in _entries:
		var r := Registration.new()
		r.id = reg.id
		r.controller_id = reg.controller_id
		r.lifetime_kind = reg.lifetime_kind
		r.duration = reg.duration
		r.encounter_frame_id = reg.encounter_frame_id
		r.drawn_card_id = reg.drawn_card_id
		r.buffs = reg.buffs.duplicate()
		copy._entries.append(r)
	return copy


func tick_duration(anchor: AhcEnums.DurationAnchorKind) -> void:
	var to_remove: Array[StringName] = []
	for reg in _entries:
		if reg.lifetime_kind == AhcEnums.LifetimeKind.DURATION and reg.duration == anchor:
			to_remove.append(reg.id)
	for id in to_remove:
		unregister(id)
