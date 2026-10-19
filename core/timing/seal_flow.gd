class_name SealFlow
extends RefCounted

## 封印 / 释放内核 · `seq.effect.seal` / `seq.effect.release_seal`。
## Domain：标记离袋挂到卡上；离场立即释放回袋。不作 Buff。

const MODE_RANDOM := &"random"
const MODE_KIND := &"kind"
const MODE_TOKEN := &"token"
const MODE_CHOICE := &"choice"


static func nest_or_run_seal(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	return _nest_or_run(game_ctx, &"seq.effect.seal", params)


static func nest_or_run_release(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	return _nest_or_run(game_ctx, &"seq.effect.release_seal", params)


static func _nest_or_run(
	game_ctx: GameContext,
	flow_id: StringName,
	params: Dictionary
) -> Dictionary:
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(flow_id)
	):
		return game_ctx.sequence_catalog.nest(game_ctx, flow_id, params)
	if flow_id == &"seq.effect.seal":
		return seal(game_ctx, params)
	return release(game_ctx, params)


static func seal(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	var bag: ChaosBag = game_ctx.state.chaos_bag
	if bag == null:
		return {"ok": false, "error": "no_bag"}
	var host: StringName = params.get("host_card_id", params.get("card_id", &"")) as StringName
	if host == &"":
		return {"ok": false, "error": "no_host"}
	var card := game_ctx.state.registry.get_card(host)
	if card == null:
		return {"ok": false, "error": "host_missing"}
	var mode: StringName = params.get("mode", MODE_RANDOM) as StringName
	var sealed_tok: ChaosToken = null
	match mode:
		MODE_RANDOM:
			sealed_tok = bag.seal_random(host)
		MODE_KIND:
			var kind: int = int(params.get("kind", AhcEnums.ChaosTokenKind.NUMERIC))
			sealed_tok = bag.seal_kind(kind as AhcEnums.ChaosTokenKind, host)
		MODE_TOKEN:
			sealed_tok = params.get("token") as ChaosToken
			if sealed_tok == null or not bag.seal(sealed_tok, host):
				sealed_tok = null
		MODE_CHOICE:
			sealed_tok = _seal_choice(game_ctx, bag, host, params)
		_:
			return {"ok": false, "error": "bad_mode"}
	if sealed_tok == null:
		return {"ok": false, "error": "seal_failed", "host": host, "mode": mode}
	_sync_card_sealed(card, bag, host)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.CARD,
			"seal:seal",
			{"host": host, "kind": sealed_tok.kind, "mode": mode}
		)
	return {"ok": true, "host": host, "token": sealed_tok, "kind": sealed_tok.kind}


static func release(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	var bag: ChaosBag = game_ctx.state.chaos_bag
	if bag == null:
		return {"ok": false, "error": "no_bag"}
	var host: StringName = params.get("host_card_id", params.get("card_id", &"")) as StringName
	var token: ChaosToken = params.get("token") as ChaosToken
	var released: Array[ChaosToken] = []
	if token != null:
		if bag.release(token):
			released.append(token)
	elif host != &"":
		released = bag.release_all_on(host)
	else:
		return {"ok": false, "error": "no_target"}
	if host != &"":
		var card := game_ctx.state.registry.get_card(host)
		if card != null:
			_sync_card_sealed(card, bag, host)
	elif token != null and token.sealed_on == &"":
		## 单枚已释放：清所有卡镜像里对该 token 的引用。
		_erase_token_from_all_cards(game_ctx, token)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.CARD,
			"seal:release",
			{"host": host, "count": released.size()}
		)
	return {"ok": not released.is_empty() or token == null, "released": released, "host": host}


## 离场：释放该卡上全部封印（Grimoire Domain 清理；同 Uses 清 token，不 nest）。
static func release_on_leave_play(game_ctx: GameContext, card_id: StringName) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or card_id == &"":
		return {"ok": false}
	var bag: ChaosBag = game_ctx.state.chaos_bag
	if bag == null:
		return {"ok": false}
	var released := bag.release_all_on(card_id)
	var card := game_ctx.state.registry.get_card(card_id)
	if card != null:
		card.tokens.sealed.clear()
	if game_ctx.log != null and not released.is_empty():
		game_ctx.log.log(
			AhcEnums.LogCategory.CARD,
			"seal:release_leave_play",
			{"host": card_id, "count": released.size()}
		)
	return {"ok": true, "released": released, "host": card_id}


## 将封印标记移入揭示工作区并记账（作刚揭示）；不再挂在卡上，也不回袋。
static func reveal_one_sealed(
	game_ctx: GameContext,
	host_card_id: StringName,
	source: StringName = &"skill_test"
) -> ChaosToken:
	if game_ctx == null or game_ctx.state == null or host_card_id == &"":
		return null
	var bag: ChaosBag = game_ctx.state.chaos_bag
	if bag == null:
		return null
	var tok := bag.reveal_one_sealed(host_card_id, source)
	if tok == null:
		return null
	var card := game_ctx.state.registry.get_card(host_card_id)
	if card != null:
		_sync_card_sealed(card, bag, host_card_id)
	return tok


static func sealed_count(game_ctx: GameContext, host_card_id: StringName) -> int:
	if game_ctx == null or game_ctx.state == null:
		return 0
	var bag: ChaosBag = game_ctx.state.chaos_bag
	if bag == null:
		return 0
	return bag.sealed_on(host_card_id).size()


static func can_seal_kind(bag: ChaosBag, kind: AhcEnums.ChaosTokenKind) -> bool:
	if bag == null:
		return false
	for t in bag.tokens:
		var tok: ChaosToken = t as ChaosToken
		if tok != null and tok.kind == kind and not tok.sealed:
			return true
	return false


static func _seal_choice(
	game_ctx: GameContext,
	bag: ChaosBag,
	host: StringName,
	params: Dictionary
) -> ChaosToken:
	var candidates: Array[ChaosToken] = []
	var filter_kind: int = int(params.get("kind", -1))
	for t in bag.tokens:
		var tok: ChaosToken = t as ChaosToken
		if tok == null or tok.sealed:
			continue
		if filter_kind >= 0 and int(tok.kind) != filter_kind:
			continue
		candidates.append(tok)
	if candidates.is_empty():
		return null
	var controller: StringName = params.get(
		"controller_id", params.get("inv_id", &"")
	) as StringName
	if controller == &"" and game_ctx.state != null:
		controller = game_ctx.state.lead_investigator_id
	var gate: PlayerInteractionGate = game_ctx.interaction
	var pick: ChaosToken = candidates[0]
	if gate != null and candidates.size() > 1:
		var chosen: Variant = gate.ask_chaos_pick(
			candidates,
			1,
			1,
			controller,
			&"chaos:seal_pick",
			game_ctx
		)
		if chosen is Array and not (chosen as Array).is_empty():
			var first: Variant = (chosen as Array)[0]
			if first is ChaosToken:
				pick = first as ChaosToken
		elif chosen is ChaosToken:
			pick = chosen as ChaosToken
	if bag.seal(pick, host):
		return pick
	return null


static func _sync_card_sealed(card: CardInstance, bag: ChaosBag, host: StringName) -> void:
	if card == null or bag == null:
		return
	card.tokens.sealed.clear()
	for t in bag.sealed_on(host):
		card.tokens.sealed.append(t)


static func _erase_token_from_all_cards(game_ctx: GameContext, token: ChaosToken) -> void:
	if game_ctx == null or game_ctx.state == null or token == null:
		return
	for card_id in game_ctx.state.registry.all_card_ids():
		var card := game_ctx.state.registry.get_card(card_id)
		if card == null:
			continue
		card.tokens.sealed.erase(token)
