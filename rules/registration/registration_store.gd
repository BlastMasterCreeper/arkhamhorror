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


func unregister_by_controller(controller_id: StringName) -> void:
	on_card_leave_play(controller_id)


func on_card_leave_play(card_id: StringName) -> void:
	## 06 §3.2.6 · 只卸 WHILE_IN_PLAY。不碰涌动 / 险境 / 隐私 / 起始 / 绑定 / 延时。
	_unregister_matching(card_id, [
		AhcEnums.LifetimeKind.WHILE_IN_PLAY,
	])


func on_leave_hand(card_id: StringName) -> void:
	_unregister_matching(card_id, [
		AhcEnums.LifetimeKind.WHILE_HIDDEN_IN_HAND,
		AhcEnums.LifetimeKind.WHILE_IN_HAND,
	])


func on_leave_deck(card_id: StringName) -> void:
	_unregister_matching(card_id, [
		AhcEnums.LifetimeKind.WHILE_IN_DECK,
	])


func on_leave_set_aside(card_id: StringName) -> void:
	_unregister_matching(card_id, [
		AhcEnums.LifetimeKind.WHILE_SET_ASIDE,
	])


func on_drawn_card_finalize(card_id: StringName) -> void:
	unregister_by_drawn_card(card_id)


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


## 读取：是否存在 SKIP_AOO 限制类 Buff（不卸）。
func has_skip_aoo(controller_id: StringName) -> bool:
	return _find_skip_aoo_reg_id(controller_id) != &""


## 入口读完后卸掉本行动的 SKIP_AOO（lifetime）；不是 Cancel/Ignore。
func clear_skip_aoo(controller_id: StringName) -> void:
	var reg_id := _find_skip_aoo_reg_id(controller_id)
	if reg_id != &"":
		unregister(reg_id)


## INIT_2B：读取 SKIP_AOO → 供原流程分支；读后 clear lifetime。
## 返回 true = 原流程应跳过借机攻击（限制生效），不是 interrupt。
func read_skip_aoo(controller_id: StringName) -> bool:
	if not has_skip_aoo(controller_id):
		return false
	clear_skip_aoo(controller_id)
	return true


func _find_skip_aoo_reg_id(controller_id: StringName) -> StringName:
	if controller_id == &"":
		return &""
	for reg in _entries:
		if reg.controller_id != controller_id:
			continue
		for buff in reg.buffs:
			if buff.type != AhcEnums.BuffType.RESTRICTION or buff.restriction == null:
				continue
			if buff.restriction.kind == AhcEnums.RestrictionKind.SKIP_AOO:
				return reg.id
	return &""


## 读取：该敌人是否有 SUPPRESS_AUTO_ENGAGE（不卸）。
func has_suppress_auto_engage(enemy_id: StringName) -> bool:
	return _find_suppress_auto_engage_reg_id(enemy_id) != &""


## auto-engage 入口：读取限制 → 原流程跳过自动交战；读后 clear。
func read_suppress_auto_engage(enemy_id: StringName) -> bool:
	var reg_id := _find_suppress_auto_engage_reg_id(enemy_id)
	if reg_id == &"":
		return false
	unregister(reg_id)
	return true


## 明示交战后清掉残留（若移入未触发 auto-engage 入口）。
func clear_suppress_auto_engage(enemy_id: StringName) -> void:
	var reg_id := _find_suppress_auto_engage_reg_id(enemy_id)
	if reg_id != &"":
		unregister(reg_id)


func _find_suppress_auto_engage_reg_id(enemy_id: StringName) -> StringName:
	if enemy_id == &"":
		return &""
	for reg in _entries:
		for buff in reg.buffs:
			if buff.type != AhcEnums.BuffType.RESTRICTION or buff.restriction == null:
				continue
			if buff.restriction.kind != AhcEnums.RestrictionKind.SUPPRESS_AUTO_ENGAGE:
				continue
			if buff.restriction.subject_id == enemy_id or reg.drawn_card_id == enemy_id:
				return reg.id
	return &""


## 交战状态 Buff：敌人是否与该调查员成对交战（与威胁区脱钩）。
func has_engagement(enemy_id: StringName, investigator_id: StringName) -> bool:
	return _find_engagement_reg_id(enemy_id, investigator_id) != &""


## 该敌人当前交战的调查员（无则 &""）；一对一。
func engagement_partner(enemy_id: StringName) -> StringName:
	if enemy_id == &"":
		return &""
	for reg in _entries:
		for buff in reg.buffs:
			if buff.type != AhcEnums.BuffType.RESTRICTION or buff.restriction == null:
				continue
			if buff.restriction.kind != AhcEnums.RestrictionKind.ENGAGEMENT:
				continue
			if buff.restriction.subject_id == enemy_id or reg.drawn_card_id == enemy_id:
				var inv: StringName = buff.restriction.drawer_id
				if inv == &"":
					inv = reg.controller_id
				return inv
	return &""


## 与该调查员成对交战的敌人列表。
func engaged_enemies_for(investigator_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	if investigator_id == &"":
		return out
	var seen: Dictionary = {}
	for reg in _entries:
		for buff in reg.buffs:
			if buff.type != AhcEnums.BuffType.RESTRICTION or buff.restriction == null:
				continue
			if buff.restriction.kind != AhcEnums.RestrictionKind.ENGAGEMENT:
				continue
			var inv: StringName = buff.restriction.drawer_id
			if inv == &"":
				inv = reg.controller_id
			if inv != investigator_id:
				continue
			var enemy_id: StringName = buff.restriction.subject_id
			if enemy_id == &"":
				enemy_id = reg.drawn_card_id
			if enemy_id == &"" or seen.has(enemy_id):
				continue
			seen[enemy_id] = true
			out.append(enemy_id)
	return out


## 卸掉该敌人全部交战状态 Buff（脱离 / 抢怪前）。
func clear_engagement(enemy_id: StringName) -> void:
	if enemy_id == &"":
		return
	var to_remove: Array[StringName] = []
	for reg in _entries:
		for buff in reg.buffs:
			if buff.type != AhcEnums.BuffType.RESTRICTION or buff.restriction == null:
				continue
			if buff.restriction.kind != AhcEnums.RestrictionKind.ENGAGEMENT:
				continue
			if buff.restriction.subject_id == enemy_id or reg.drawn_card_id == enemy_id:
				to_remove.append(reg.id)
				break
	for id in to_remove:
		unregister(id)


func _find_engagement_reg_id(enemy_id: StringName, investigator_id: StringName) -> StringName:
	if enemy_id == &"" or investigator_id == &"":
		return &""
	for reg in _entries:
		for buff in reg.buffs:
			if buff.type != AhcEnums.BuffType.RESTRICTION or buff.restriction == null:
				continue
			if buff.restriction.kind != AhcEnums.RestrictionKind.ENGAGEMENT:
				continue
			var subject: StringName = buff.restriction.subject_id
			if subject == &"":
				subject = reg.drawn_card_id
			var inv: StringName = buff.restriction.drawer_id
			if inv == &"":
				inv = reg.controller_id
			if subject == enemy_id and inv == investigator_id:
				return reg.id
	return &""


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
	on_leave_hand(card_id)


func _unregister_matching(card_id: StringName, kinds: Array) -> void:
	if card_id == &"":
		return
	var to_remove: Array[StringName] = []
	for reg in _entries:
		if not kinds.has(reg.lifetime_kind):
			continue
		if reg.drawn_card_id != card_id and reg.controller_id != card_id:
			continue
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
			entry.controller_id = reg.controller_id
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
