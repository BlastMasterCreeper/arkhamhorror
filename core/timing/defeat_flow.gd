class_name DefeatFlow
extends RefCounted

## 击败内核 · `seq.effect.defeat`（敌人别名 `seq.enemy.defeat`）。
## 成功后 nest `seq.defeat.leave_play`（退场）；Cancel → 无退场。
## 伤/恐达上限 = 常态检测（cause=damage_cap|horror_cap）；卡面击败 = cause=effect。

const SUBJECT_ENEMY := &"enemy"
const SUBJECT_INVESTIGATOR := &"investigator"

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
	return &""


static func _cancel_bind(params: Dictionary, subject: StringName) -> Dictionary:
	match subject:
		SUBJECT_ENEMY:
			return {"card_id": params.get("enemy_id", &"")}
		SUBJECT_INVESTIGATOR:
			return {"card_id": params.get("investigator_id", &"")}
	return {}


static func _enemy_definition_id(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card != null:
		return card.id.definition_id
	return enemy_id
