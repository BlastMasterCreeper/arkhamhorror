class_name ChaosBag
extends RefCounted

var tokens: Array[ChaosToken] = []
## 本检定仍留置工作区、待 ST.8 归袋的标记（物理堆）。
var revealed_this_test: Array[ChaosToken] = []
## 本作用域揭示账本：含已归袋的能力揭示；供 ST.4 后 *If … is revealed* 门槛查阅。
var reveal_ledger: Array[ChaosRevealRecord] = []
var reveal_scope_id: StringName = &""


func shuffle() -> void:
	tokens.shuffle()


func begin_reveal_scope(scope_id: StringName) -> void:
	reveal_scope_id = scope_id
	reveal_ledger.clear()


func end_reveal_scope() -> void:
	reveal_scope_id = &""
	reveal_ledger.clear()


func draw_random(source: StringName = &"skill_test") -> ChaosToken:
	if tokens.is_empty():
		return null
	var idx := randi() % tokens.size()
	var token := tokens[idx]
	tokens.remove_at(idx)
	revealed_this_test.append(token)
	_record_reveal(token, source)
	return token


## 能力揭示（Rod 等）：离袋并记账；帧末须 `finalize_ability_reveal` 归袋（账本保留）。
func reveal_for_ability(amount: int = 1) -> Array[ChaosToken]:
	var out: Array[ChaosToken] = []
	for _i in range(maxi(amount, 0)):
		var token := draw_random(&"ability")
		if token == null:
			break
		out.append(token)
	return out


## 能力帧末 disposition：物理回袋，账本行保留（除非已 Cancel）。
func finalize_ability_reveal(revealed: Array[ChaosToken]) -> void:
	for token in revealed:
		if token == null:
			continue
		_return_physical(token)
		var rec := _find_record(token)
		if rec != null:
			rec.physically_returned = true


func return_token(token: ChaosToken) -> void:
	if token == null:
		return
	_return_physical(token)


func return_all_revealed() -> void:
	while not revealed_this_test.is_empty():
		_return_physical(revealed_this_test[0])


## 整枚 Cancel：视为从未抽到（Grimoire）；一切「曾揭示」查询排除。
func cancel_reveal(token: ChaosToken) -> void:
	var rec := _find_record(token)
	if rec != null:
		rec.canceled = true
		rec.ignored = false


## 整枚 Ignore：仍算抽到/揭示，但不 resolve（无修饰/符号；Recall/Eye 门槛不算）。
func ignore_reveal(token: ChaosToken) -> void:
	var rec := _find_record(token)
	if rec == null or rec.canceled:
		return
	rec.ignored = true


## 未 Cancel（含 Ignore）—「曾揭示 / 曾抽到」。
func has_uncanceled_kind(kind: AhcEnums.ChaosTokenKind) -> bool:
	return has_revealed_kind(kind)


func count_uncanceled_kind(kind: AhcEnums.ChaosTokenKind) -> int:
	return count_revealed_kind(kind)


func uncanceled_records() -> Array[ChaosRevealRecord]:
	return revealed_records()


func has_revealed_kind(kind: AhcEnums.ChaosTokenKind) -> bool:
	for rec in reveal_ledger:
		if not rec.was_revealed():
			continue
		if rec.kind == kind:
			return true
	return false


func count_revealed_kind(kind: AhcEnums.ChaosTokenKind) -> int:
	var n := 0
	for rec in reveal_ledger:
		if not rec.was_revealed():
			continue
		if rec.kind == kind:
			n += 1
	return n


func revealed_records() -> Array[ChaosRevealRecord]:
	var out: Array[ChaosRevealRecord] = []
	for rec in reveal_ledger:
		if rec.was_revealed():
			out.append(rec)
	return out


## 未 Cancel 且未 Ignore — ST.4/5 与 FAQ 2.5「resolved」门槛。
func has_resolved_kind(kind: AhcEnums.ChaosTokenKind) -> bool:
	for rec in reveal_ledger:
		if not rec.was_resolved():
			continue
		if rec.kind == kind:
			return true
	return false


func count_resolved_kind(kind: AhcEnums.ChaosTokenKind) -> int:
	var n := 0
	for rec in reveal_ledger:
		if not rec.was_resolved():
			continue
		if rec.kind == kind:
			n += 1
	return n


func resolved_records() -> Array[ChaosRevealRecord]:
	var out: Array[ChaosRevealRecord] = []
	for rec in reveal_ledger:
		if rec.was_resolved():
			out.append(rec)
	return out


func add_token(token: ChaosToken) -> void:
	tokens.append(token)


func clear() -> void:
	tokens.clear()
	revealed_this_test.clear()
	reveal_ledger.clear()
	reveal_scope_id = &""


func _record_reveal(token: ChaosToken, source: StringName) -> void:
	if token == null:
		return
	## 无作用域时仍允许物理揭示（非检定能力）；账本仅在有 scope 时写入。
	if reveal_scope_id == &"":
		return
	reveal_ledger.append(ChaosRevealRecord.from_token(token, source, reveal_scope_id))


func _return_physical(token: ChaosToken) -> void:
	revealed_this_test.erase(token)
	if not tokens.has(token):
		tokens.append(token)


func _find_record(token: ChaosToken) -> ChaosRevealRecord:
	for i in range(reveal_ledger.size() - 1, -1, -1):
		var rec: ChaosRevealRecord = reveal_ledger[i]
		if rec.token == token:
			return rec
	return null
