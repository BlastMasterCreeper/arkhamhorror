class_name DefeatFlow
extends RefCounted

## 击败内核 · `seq.effect.defeat`（敌人别名 `seq.enemy.defeat`）。
## 大信封：退场（nest `seq.defeat.leave_play`）是击败效果体的一部分，不是信封外另起后续。
## Cancel 整封击败 → 退场不跑。伤/恐达上限 = 常态检测；卡面击败 = cause=effect。
## 支援：退场经 L0 `move_card` → 拥有者弃牌堆；**不**走 `seq.effect.discard_card`。

const SUBJECT_ENEMY := &"enemy"
const SUBJECT_INVESTIGATOR := &"investigator"
const SUBJECT_ASSET := &"asset"

const CAUSE_DAMAGE_CAP := &"damage_cap"
const CAUSE_HORROR_CAP := &"horror_cap"
const CAUSE_EFFECT := &"effect"

const FLOW_DEFEAT := &"seq.effect.defeat"
const FLOW_ENEMY_DEFEAT := &"seq.enemy.defeat"
const FLOW_LEAVE := &"seq.defeat.leave_play"


static func nest_or_run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var p := _normalize_params(game_ctx, params)
	if p.is_empty():
		return {"ok": false, "defeated": false, "error": "invalid_params"}
	if not _eligible(game_ctx, p):
		return {"ok": true, "defeated": false, "subject": p.get("subject", &"")}
	var flow_id := _entry_flow_id(game_ctx, p)
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and flow_id != &""
		and game_ctx.sequence_catalog.has_flow(flow_id)
	):
		return game_ctx.sequence_catalog.nest(game_ctx, flow_id, p)
	return resolve(game_ctx, p)


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var p := _normalize_params(game_ctx, params)
	if p.is_empty():
		return {"ok": false, "defeated": false, "error": "invalid_params"}
	if not _eligible(game_ctx, p):
		return {"ok": true, "defeated": false, "subject": p.get("subject", &"")}
	var flow_id := _entry_flow_id(game_ctx, p)
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and flow_id != &""
		and game_ctx.sequence_catalog.has_flow(flow_id)
	):
		return game_ctx.sequence_catalog.run(game_ctx, flow_id, p)
	return resolve(game_ctx, p)


## 伤害后常态检测：damage ≥ health → 击败（cause=damage_cap）。
static func check_enemy_damage_cap(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	return nest_or_run(
		game_ctx,
		{
			"subject": SUBJECT_ENEMY,
			"enemy_id": enemy_id,
			"cause": CAUSE_DAMAGE_CAP,
		}
	)


## 调查员伤/恐常态检测。
static func check_investigator_caps(game_ctx: GameContext, inv_id: StringName) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or inv_id == &"":
		return {"ok": false, "defeated": false}
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null or inv.eliminated:
		return {"ok": false, "defeated": false}
	var cause := &""
	if inv.health > 0 and inv.damage_taken >= inv.health:
		cause = CAUSE_DAMAGE_CAP
	elif inv.sanity > 0 and inv.horror_taken >= inv.sanity:
		cause = CAUSE_HORROR_CAP
	if cause == &"":
		return {"ok": true, "defeated": false}
	return nest_or_run(
		game_ctx,
		{
			"subject": SUBJECT_INVESTIGATOR,
			"investigator_id": inv_id,
			"cause": cause,
		}
	)


## 支援资产伤/恐常态检测（tokens vs 印刷 health/sanity）。
static func check_asset_caps(game_ctx: GameContext, card_id: StringName) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or card_id == &"":
		return {"ok": false, "defeated": false}
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null or not _asset_in_play(card):
		return {"ok": false, "defeated": false}
	var health := CardRegistry.printed_health(card.id.definition_id)
	var sanity := CardRegistry.printed_sanity(card.id.definition_id)
	var cause := &""
	if health > 0 and card.tokens.damage >= health:
		cause = CAUSE_DAMAGE_CAP
	elif sanity > 0 and card.tokens.horror >= sanity:
		cause = CAUSE_HORROR_CAP
	if cause == &"":
		return {"ok": true, "defeated": false}
	return nest_or_run(
		game_ctx,
		{
			"subject": SUBJECT_ASSET,
			"card_id": card_id,
			"cause": cause,
		}
	)


## 对场上支援造成伤害并常态检测击败。
static func deal_damage_to_asset(
	game_ctx: GameContext,
	card_id: StringName,
	amount: int
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or card_id == &"" or amount <= 0:
		return {"ok": false, "defeated": false}
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null or not _asset_in_play(card):
		return {"ok": false, "defeated": false}
	card.tokens.damage += amount
	var check := check_asset_caps(game_ctx, card_id)
	check["ok"] = true
	check["damage"] = card.tokens.damage
	return check


## 对场上支援造成恐惧并常态检测击败。
static func deal_horror_to_asset(
	game_ctx: GameContext,
	card_id: StringName,
	amount: int
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or card_id == &"" or amount <= 0:
		return {"ok": false, "defeated": false}
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null or not _asset_in_play(card):
		return {"ok": false, "defeated": false}
	card.tokens.horror += amount
	var check := check_asset_caps(game_ctx, card_id)
	check["ok"] = true
	check["horror"] = card.tokens.horror
	return check


static func defeat_enemy_effect(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	return nest_or_run(
		game_ctx,
		{
			"subject": SUBJECT_ENEMY,
			"enemy_id": enemy_id,
			"cause": CAUSE_EFFECT,
		}
	)


static func defeat_investigator_effect(game_ctx: GameContext, inv_id: StringName) -> Dictionary:
	return nest_or_run(
		game_ctx,
		{
			"subject": SUBJECT_INVESTIGATOR,
			"investigator_id": inv_id,
			"cause": CAUSE_EFFECT,
		}
	)


static func defeat_asset_effect(game_ctx: GameContext, card_id: StringName) -> Dictionary:
	return nest_or_run(
		game_ctx,
		{
			"subject": SUBJECT_ASSET,
			"card_id": card_id,
			"cause": CAUSE_EFFECT,
		}
	)


## Catalog handler（`seq.effect.defeat` / `seq.enemy.defeat`）：Cancel 则停；否则 nest 退场。
static func resolve(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var p := _normalize_params(game_ctx, params)
	if p.is_empty():
		return {"ok": false, "defeated": false, "error": "invalid_params"}
	var subject: StringName = p.get("subject", &"") as StringName
	var bind := _cancel_bind(p, subject)
	if (
		game_ctx != null
		and game_ctx.memory != null
		and (
			game_ctx.memory.is_sequence_cancelled(FLOW_DEFEAT, bind)
			or game_ctx.memory.is_sequence_cancelled(FLOW_ENEMY_DEFEAT, bind)
		)
	):
		## 消费本次 Cancel：伤/恐常态检测之后仍可再触发。
		game_ctx.memory.clear_sequence_cancel(FLOW_DEFEAT, bind)
		game_ctx.memory.clear_sequence_cancel(FLOW_ENEMY_DEFEAT, bind)
		return {
			"ok": false,
			"defeated": false,
			"cancelled": true,
			"subject": subject,
		}
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(FLOW_LEAVE)
	):
		return game_ctx.sequence_catalog.nest(game_ctx, FLOW_LEAVE, p)
	return leave_play(game_ctx, p)


static func leave_play(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var p := _normalize_params(game_ctx, params)
	var subject: StringName = p.get("subject", &"") as StringName
	match subject:
		SUBJECT_ENEMY:
			return _leave_enemy(game_ctx, p)
		SUBJECT_INVESTIGATOR:
			return _leave_investigator(game_ctx, p)
		SUBJECT_ASSET:
			return _leave_asset(game_ctx, p)
	return {"ok": false, "defeated": false, "error": "unknown_subject"}


static func _entry_flow_id(game_ctx: GameContext, params: Dictionary) -> StringName:
	var subject: StringName = params.get("subject", &"") as StringName
	if (
		subject == SUBJECT_ENEMY
		and game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(FLOW_ENEMY_DEFEAT)
	):
		return FLOW_ENEMY_DEFEAT
	return FLOW_DEFEAT


static func _eligible(game_ctx: GameContext, params: Dictionary) -> bool:
	if game_ctx == null or game_ctx.state == null:
		return false
	var subject: StringName = params.get("subject", &"") as StringName
	var cause: StringName = params.get("cause", CAUSE_EFFECT) as StringName
	match subject:
		SUBJECT_ENEMY:
			var enemy_id: StringName = params.get("enemy_id", &"") as StringName
			var enemy := game_ctx.state.registry.get_enemy(enemy_id)
			if enemy == null:
				return false
			if cause == CAUSE_DAMAGE_CAP:
				return enemy.damage >= enemy.health
			return true
		SUBJECT_INVESTIGATOR:
			var inv_id: StringName = params.get("investigator_id", &"") as StringName
			var inv := game_ctx.state.registry.get_investigator(inv_id)
			if inv == null or inv.eliminated:
				return false
			if cause == CAUSE_DAMAGE_CAP:
				return inv.health > 0 and inv.damage_taken >= inv.health
			if cause == CAUSE_HORROR_CAP:
				return inv.sanity > 0 and inv.horror_taken >= inv.sanity
			return true
		SUBJECT_ASSET:
			var card_id: StringName = params.get("card_id", &"") as StringName
			var card := game_ctx.state.registry.get_card(card_id)
			if card == null or not _asset_in_play(card):
				return false
			var health := CardRegistry.printed_health(card.id.definition_id)
			var sanity := CardRegistry.printed_sanity(card.id.definition_id)
			if cause == CAUSE_DAMAGE_CAP:
				return health > 0 and card.tokens.damage >= health
			if cause == CAUSE_HORROR_CAP:
				return sanity > 0 and card.tokens.horror >= sanity
			return true
	return false


static func _normalize_params(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if params == null or params.is_empty():
		return {}
	var p := params.duplicate()
	var subject := _subject(p)
	if subject == &"":
		return {}
	p["subject"] = subject
	if subject == SUBJECT_ENEMY:
		var enemy_id: StringName = p.get("enemy_id", &"") as StringName
		if enemy_id == &"" or game_ctx == null or game_ctx.state == null:
			return {}
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy == null:
			return {}
		p["location_id"] = p.get("location_id", enemy.location_tag)
		p["definition_id"] = p.get("definition_id", _enemy_definition_id(game_ctx, enemy_id))
		if not p.has("cause"):
			p["cause"] = CAUSE_DAMAGE_CAP
	elif subject == SUBJECT_INVESTIGATOR:
		var inv_id: StringName = p.get(
			"investigator_id", p.get("inv_id", &"")
		) as StringName
		if inv_id == &"":
			return {}
		p["investigator_id"] = inv_id
		if not p.has("cause"):
			p["cause"] = CAUSE_EFFECT
	elif subject == SUBJECT_ASSET:
		var card_id: StringName = p.get("card_id", &"") as StringName
		if card_id == &"" or game_ctx == null or game_ctx.state == null:
			return {}
		var card := game_ctx.state.registry.get_card(card_id)
		if card == null:
			return {}
		p["card_id"] = card_id
		p["definition_id"] = p.get("definition_id", card.id.definition_id)
		p["owner_id"] = p.get("owner_id", card.owner_id)
		if not p.has("cause"):
			p["cause"] = CAUSE_DAMAGE_CAP
	return p


static func _leave_enemy(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var enemy_id: StringName = params.get("enemy_id", &"") as StringName
	var definition_id: StringName = params.get("definition_id", &"") as StringName
	return EnemyDefeatResolver.finalize_leave_play(game_ctx, enemy_id, definition_id)


static func _leave_investigator(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var inv_id: StringName = params.get("investigator_id", &"") as StringName
	var elim := InvestigatorElimination.eliminate(game_ctx, inv_id)
	return {
		"ok": bool(elim.get("eliminated", false)),
		"defeated": bool(elim.get("defeated", false)),
		"eliminated": bool(elim.get("eliminated", false)),
		"investigator_id": inv_id,
		"discarded": elim.get("discarded", []),
		"subject": SUBJECT_INVESTIGATOR,
	}


## 支援退场（≠ discard 效果包装）：
## Victory/复仇 → 胜利区；有玩家所有者 → 其弃牌堆；否则（无主剧情支援）→ 置一边。
static func _leave_asset(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var card_id: StringName = params.get("card_id", &"") as StringName
	if game_ctx == null or game_ctx.state == null or card_id == &"":
		return {"ok": false, "defeated": false}
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null or game_ctx.mutator == null:
		return {"ok": false, "defeated": false}
	var owner_id: StringName = card.owner_id
	var dest := &""
	var moved := false
	var def_id := card.id.definition_id if card.id != null else &""
	if CardRegistry.routes_to_victory_display(def_id):
		moved = game_ctx.mutator.move_card(card_id, CardSlot.victory_display())
		dest = &"victory_display"
	elif game_ctx.state.registry.get_investigator(owner_id) != null:
		moved = game_ctx.mutator.move_card(card_id, CardSlot.discard_top(owner_id))
		dest = &"owner_discard"
	else:
		## 未被玩家拥有的剧情支援 → 置一边（非 REMOVED）。
		moved = game_ctx.mutator.move_to_set_aside(card_id)
		dest = &"set_aside"
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"asset:defeated",
			{"card_id": card_id, "owner": owner_id, "dest": dest, "ok": moved}
		)
	return {
		"ok": moved,
		"defeated": moved,
		"card_id": card_id,
		"subject": SUBJECT_ASSET,
		"dest": dest,
		"via_discard_effect": false,
	}


static func _asset_in_play(card: CardInstance) -> bool:
	if card == null:
		return false
	return (
		card.zone == AhcEnums.Zone.PLAY_AREA
		or card.zone == AhcEnums.Zone.THREAT_AREA
		or card.zone == AhcEnums.Zone.ATTACHED
	)


static func _subject(params: Dictionary) -> StringName:
	var s: StringName = params.get("subject", &"") as StringName
	if s != &"":
		return s
	if params.get("enemy_id", &"") as StringName != &"":
		return SUBJECT_ENEMY
	if (
		params.get("investigator_id", &"") as StringName != &""
		or params.get("inv_id", &"") as StringName != &""
	):
		return SUBJECT_INVESTIGATOR
	if params.get("card_id", &"") as StringName != &"":
		return SUBJECT_ASSET
	return &""


static func _cancel_bind(params: Dictionary, subject: StringName) -> Dictionary:
	match subject:
		SUBJECT_ENEMY:
			return {"card_id": params.get("enemy_id", &"")}
		SUBJECT_INVESTIGATOR:
			return {"card_id": params.get("investigator_id", &"")}
		SUBJECT_ASSET:
			return {"card_id": params.get("card_id", &"")}
	return {}


static func _enemy_definition_id(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card != null:
		return card.id.definition_id
	return enemy_id
