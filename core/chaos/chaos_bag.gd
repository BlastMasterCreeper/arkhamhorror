class_name ChaosBag
extends RefCounted

var tokens: Array[ChaosToken] = []
## 本检定仍留置工作区、待 ST.8 归袋的标记（物理堆）。
var revealed_this_test: Array[ChaosToken] = []
## 封印中的标记：不在袋内，不可 `draw_random`。
var sealed_tokens: Array[ChaosToken] = []
## 本作用域揭示账本：含已归袋的能力揭示；审计 / Cancel·Ignore 查询。
var reveal_ledger: Array[ChaosRevealRecord] = []
var reveal_scope_id: StringName = &""
## disposition 定案且 was_resolved 时回调 `(token: ChaosToken, rec: ChaosRevealRecord)`。
## 由 SkillTestEngine 在 begin_test 挂上，驱动 if_revealed_watchers。
var on_resolved_reveal: Callable


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
## 仍 resolved 的枚在此刻通知 `on_resolved_reveal`（紧贴揭示结算）。
func finalize_ability_reveal(revealed: Array[ChaosToken]) -> void:
	for token in revealed:
		if token == null:
			continue
		var rec := _find_record(token)
		if rec != null and rec.was_resolved():
			_emit_resolved_reveal(token, rec)
		_return_physical(token)
		if rec != null:
			rec.physically_returned = true


## ST.3 批：意图规划忽略已应用后，对每枚 resolved 通知观察者。
func notify_resolved_tokens(resolved: Array) -> void:
	for item in resolved:
		var token: ChaosToken = item as ChaosToken
		if token == null:
			continue
		var rec := _find_record(token)
		if rec != null and rec.was_resolved():
			_emit_resolved_reveal(token, rec)
		elif rec == null and on_resolved_reveal.is_valid():
			## 无账本行时仍通知（无 scope 旁路）。
			on_resolved_reveal.call(token, null)


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


## 整枚 Ignore：仍算抽到/揭示，但不 resolve（无修饰/符号；if_revealed 不触发）。
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


## 从袋封印到 host 卡；成功则标记离袋。
func seal(token: ChaosToken, host_card_id: StringName) -> bool:
	if token == null or host_card_id == &"":
		return false
	if token.sealed:
		return token.sealed_on == host_card_id
	if not tokens.has(token):
		return false
	tokens.erase(token)
	token.sealed = true
	token.sealed_on = host_card_id
	if not sealed_tokens.has(token):
		sealed_tokens.append(token)
	return true


func seal_random(host_card_id: StringName) -> ChaosToken:
	if tokens.is_empty() or host_card_id == &"":
		return null
	var idx := randi() % tokens.size()
	var token: ChaosToken = tokens[idx]
	if seal(token, host_card_id):
		return token
	return null


func seal_kind(kind: AhcEnums.ChaosTokenKind, host_card_id: StringName) -> ChaosToken:
	if host_card_id == &"":
		return null
	for t in tokens:
		var tok: ChaosToken = t as ChaosToken
		if tok != null and tok.kind == kind and not tok.sealed:
			if seal(tok, host_card_id):
				return tok
	return null


func sealed_on(host_card_id: StringName) -> Array[ChaosToken]:
	var out: Array[ChaosToken] = []
	if host_card_id == &"":
		return out
	for t in sealed_tokens:
		var tok: ChaosToken = t as ChaosToken
		if tok != null and tok.sealed and tok.sealed_on == host_card_id:
			out.append(tok)
	return out


## 释放回袋；若仍在揭示工作区则保留在工作区（ST.8 再归袋）。
func release(token: ChaosToken) -> bool:
	if token == null:
		return false
	var was_sealed := token.sealed or sealed_tokens.has(token)
	if not was_sealed:
		return false
	token.sealed = false
	token.sealed_on = &""
	sealed_tokens.erase(token)
	if not revealed_this_test.has(token) and not tokens.has(token):
		tokens.append(token)
	return true


func release_all_on(host_card_id: StringName) -> Array[ChaosToken]:
	var out: Array[ChaosToken] = sealed_on(host_card_id)
	for tok in out.duplicate():
		release(tok)
	return out


## 作刚揭示：从封印移入揭示工作区并记账；不再挂卡、不回袋。
func reveal_one_sealed(host_card_id: StringName, source: StringName = &"skill_test") -> ChaosToken:
	var candidates := sealed_on(host_card_id)
	if candidates.is_empty():
		return null
	var token: ChaosToken = candidates[0]
	token.sealed = false
	token.sealed_on = &""
	sealed_tokens.erase(token)
	if not revealed_this_test.has(token):
		revealed_this_test.append(token)
	_record_reveal(token, source)
	return token


func clear() -> void:
	tokens.clear()
	revealed_this_test.clear()
	sealed_tokens.clear()
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


func _emit_resolved_reveal(token: ChaosToken, rec: ChaosRevealRecord) -> void:
	if on_resolved_reveal.is_valid():
		on_resolved_reveal.call(token, rec)
