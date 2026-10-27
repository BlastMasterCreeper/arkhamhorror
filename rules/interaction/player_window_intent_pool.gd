class_name PlayerWindowIntentPool
extends RefCounted

## 玩家时间段窗意图池 + 倒计时节拍（16 §7.3）。
## headless：`pulse()` = 当前运行中的计时器到期（main 或 contention）。

var _ctx: GameContext = null
var _entries: Array[PlayerWindowIntentEntry] = []
var _locked: bool = false
var _active: bool = false


func bind_game_context(ctx: GameContext) -> void:
	_ctx = ctx


func clear() -> void:
	_entries.clear()
	_locked = false


func begin_window() -> void:
	clear()
	_active = true


func end_window() -> void:
	clear()
	_active = false


func is_active() -> bool:
	return _active


func is_locked() -> bool:
	return _locked


func size() -> int:
	return _entries.size()


func entries() -> Array[PlayerWindowIntentEntry]:
	return _entries.duplicate()


## 入池：每控制器上限 1；锁池期间拒绝。
func enqueue(entry: PlayerWindowIntentEntry) -> Dictionary:
	if not _active:
		return {"ok": false, "error": "window_closed"}
	if _locked:
		return {"ok": false, "error": "locked"}
	if entry == null or entry.ability_id == &"":
		return {"ok": false, "error": "invalid_entry"}
	if _controller_has_entry(entry.controller_id):
		return {"ok": false, "error": "controller_limit"}
	if not _still_eligible(entry):
		return {"ok": false, "error": "not_eligible"}
	_entries.append(entry)
	return {"ok": true, "entry_id": entry.entry_id, "pool_size": _entries.size()}


func withdraw(entry_id: StringName, controller_id: StringName) -> Dictionary:
	if not _active:
		return {"ok": false, "error": "window_closed"}
	if _locked:
		return {"ok": false, "error": "locked"}
	for i in range(_entries.size()):
		var e := _entries[i]
		if e.entry_id != entry_id:
			continue
		if e.controller_id != controller_id:
			return {"ok": false, "error": "not_controller"}
		_entries.remove_at(i)
		return {"ok": true, "pool_size": _entries.size()}
	return {"ok": false, "error": "not_found"}


## 计时器到期一步：≥2 争议裁决；=1 结算；=0 关窗。
func pulse() -> Dictionary:
	if not _active:
		return {"ok": false, "error": "window_closed"}
	if _locked:
		return {"ok": false, "error": "locked"}
	if _entries.size() >= 2:
		return _resolve_contention()
	if _entries.size() == 1:
		return _resolve_entry(_entries[0])
	_close_framework_window()
	return {"ok": true, "closed": true, "pool_size": 0}


func enqueue_free(
	ability_id: StringName,
	controller_id: StringName,
	repeat_count: int = 1
) -> Dictionary:
	if _ctx == null or _ctx.triggered_abilities == null:
		return {"ok": false, "error": "no_context"}
	var desc := _find_free(ability_id)
	if desc == null:
		return {"ok": false, "error": "unknown_ability"}
	var n := _clamp_repeat(desc, repeat_count)
	var entry := PlayerWindowIntentEntry.free_ability(
		ability_id, controller_id, desc.source_id, n
	)
	return enqueue(entry)


func _clamp_repeat(desc: TriggeredAbilityDescriptor, requested: int) -> int:
	var n := maxi(requested, 1)
	if desc == null or not desc.pw_intent_batch:
		return 1
	var cap := desc.max_batch if desc.max_batch > 0 else n
	return mini(n, cap)


func _resolve_contention() -> Dictionary:
	if _ctx == null or _ctx.interaction == null:
		return _resolve_entry(_entries[0])
	var lead := _lead_id()
	var option_ids: Array = []
	var by_id: Dictionary = {}
	for e in _entries:
		option_ids.append(e.entry_id)
		by_id[e.entry_id] = e
	var pick: Variant = _ctx.interaction.ask_pick_option(
		option_ids, lead, &"pw_intent:pick", _ctx
	)
	var chosen: PlayerWindowIntentEntry = null
	if pick != null and by_id.has(pick):
		chosen = by_id[pick] as PlayerWindowIntentEntry
	else:
		chosen = _entries[0]
	return _resolve_entry(chosen)


func _resolve_entry(entry: PlayerWindowIntentEntry) -> Dictionary:
	if entry == null:
		return {"ok": false, "error": "null_entry"}
	_locked = true
	_remove_entry(entry.entry_id)
	var resolved := 0
	var last: Dictionary = {}
	for _i in entry.repeat_count:
		if not _still_eligible(entry):
			break
		last = _activate_free(entry)
		if not bool(last.get("ok", false)):
			break
		resolved += 1
	_locked = false
	return {
		"ok": true,
		"closed": false,
		"resolved": resolved,
		"entry_id": entry.entry_id,
		"pool_size": _entries.size(),
		"last": last,
	}


func _activate_free(entry: PlayerWindowIntentEntry) -> Dictionary:
	if _ctx == null or _ctx.triggered_abilities == null:
		return {"ok": false, "error": "no_context"}
	return _ctx.triggered_abilities.activate_free(entry.ability_id)


func _still_eligible(entry: PlayerWindowIntentEntry) -> bool:
	if _ctx == null or _ctx.triggered_abilities == null or entry == null:
		return false
	var desc := _find_free(entry.ability_id)
	if desc == null:
		return false
	return _ctx.triggered_abilities.is_free_eligible(desc)


func _find_free(ability_id: StringName) -> TriggeredAbilityDescriptor:
	if _ctx == null or _ctx.triggered_abilities == null:
		return null
	var desc := _ctx.triggered_abilities.find_by_id(ability_id)
	if desc == null:
		return null
	if desc.ability_kind != TriggeredAbilityDescriptor.AbilityKind.FREE_TRIGGERED:
		return null
	return desc


func _controller_has_entry(controller_id: StringName) -> bool:
	for e in _entries:
		if e.controller_id == controller_id:
			return true
	return false


func _remove_entry(entry_id: StringName) -> void:
	for i in range(_entries.size() - 1, -1, -1):
		if _entries[i].entry_id == entry_id:
			_entries.remove_at(i)


func _close_framework_window() -> void:
	end_window()
	if _ctx != null and _ctx.framework != null and _ctx.framework.waiting_player_window:
		_ctx.framework.close_player_window_and_continue()


func _lead_id() -> StringName:
	if _ctx == null:
		return &""
	if _ctx.lead_investigator_id != &"":
		return _ctx.lead_investigator_id
	if _ctx.state != null:
		return _ctx.state.lead_investigator_id
	return &""
