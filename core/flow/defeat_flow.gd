class_name DefeatFlow
extends RefCounted

## 击败内核 · `seq.effect.defeat`（敌人别名 `seq.enemy.defeat`）。
## 大信封：退场（nest `seq.defeat.leave_play`）是击败效果体的一部分，不是信封外另起后续。
## Cancel 整封击败 → 退场不跑。伤/恐达上限 = 常态检测；卡面击败 = cause=effect。
## 支援：退场经 L0 `move_card` → 拥有者弃牌堆；**不**走 `seq.effect.discard_card`。
## 敌人伤/弃置/退场去向（原 EnemyDefeatResolver）并入本类，不再平行门面。

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


## 对场上支援造成伤害并常态检测击败（POOL → 卡 Transfer）。
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
	if game_ctx.mutator == null:
		return {"ok": false, "defeated": false}
	if not game_ctx.mutator.transfer_marker(
		AhcEnums.MarkerKind.DAMAGE,
		amount,
		MarkerSlot.supply(AhcEnums.MarkerKind.DAMAGE),
		MarkerSlot.card(card_id, AhcEnums.MarkerKind.DAMAGE)
	):
		return {"ok": false, "defeated": false}
	var check := check_asset_caps(game_ctx, card_id)
	check["ok"] = true
	check["damage"] = card.tokens.damage
	return check


## 对场上支援造成恐惧并常态检测击败（POOL → 卡 Transfer）。
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
	if game_ctx.mutator == null:
		return {"ok": false, "defeated": false}
	if not game_ctx.mutator.transfer_marker(
		AhcEnums.MarkerKind.HORROR,
		amount,
		MarkerSlot.supply(AhcEnums.MarkerKind.HORROR),
		MarkerSlot.card(card_id, AhcEnums.MarkerKind.HORROR)
	):
		return {"ok": false, "defeated": false}
	var check := check_asset_caps(game_ctx, card_id)
	check["ok"] = true
	check["horror"] = card.tokens.horror
	return check


static func deal_damage(
	game_ctx: GameContext,
	enemy_id: StringName,
	amount: int
) -> Dictionary:
	## 蜂拥包：主体超限不击败；集群卡牌击败后超额可溢出（PI/自动）。
	if SwarmPack.pack_ids(game_ctx, enemy_id).size() > 1 or SwarmPack.is_swarm_card(game_ctx, enemy_id):
		return _swarm_deal_damage(game_ctx, enemy_id, amount)
	if game_ctx == null or game_ctx.state == null or enemy_id == &"" or amount <= 0:
		return {"ok": false, "defeated": false}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "defeated": false}
	enemy.damage += amount
	if enemy.damage < enemy.health:
		return {"ok": true, "defeated": false, "damage": enemy.damage}
	return check_enemy_damage_cap(game_ctx, enemy_id)


## 默认按伤害上限检测；卡面击败传 `CAUSE_EFFECT`。
static func defeat(
	game_ctx: GameContext,
	enemy_id: StringName,
	cause: StringName = CAUSE_DAMAGE_CAP
) -> Dictionary:
	if cause == CAUSE_EFFECT:
		return defeat_enemy_effect(game_ctx, enemy_id)
	return nest_or_run(
		game_ctx,
		{
			"subject": SUBJECT_ENEMY,
			"enemy_id": enemy_id,
			"cause": cause,
		}
	)


## 击败成功后的退场（由 `seq.defeat.leave_play` nest 调用）。
static func finalize_leave_play(
	game_ctx: GameContext,
	enemy_id: StringName,
	definition_id: StringName = &""
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or enemy_id == &"":
		return {"ok": false, "defeated": false}
	if game_ctx.state.registry.get_enemy(enemy_id) == null:
		return {"ok": false, "defeated": false}
	## 集群卡牌离场：不再按一般敌人击败去向；牌库底规则覆盖。
	if SwarmPack.is_swarm_card(game_ctx, enemy_id):
		return _finalize_swarm_leave(game_ctx, enemy_id)
	_clear_enemy_engagement(game_ctx, enemy_id)
	DoomedTrigger.try_on_defeat(game_ctx, enemy_id)
	var routed := _route_enemy_after_defeat(game_ctx, enemy_id)
	game_ctx.state.registry.unregister_enemy(enemy_id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:defeated",
			{"enemy_id": enemy_id, "victory_display": routed.get("victory_display", false)}
		)
	var card := game_ctx.state.registry.get_card(enemy_id)
	var def_id := definition_id
	if def_id == &"" and card != null:
		def_id = card.id.definition_id
	if card != null and bool(routed.get("victory_display", false)):
		ScenarioObjectiveFlow.check_enemy_defeated(game_ctx, def_id)
	return {
		"ok": true,
		"defeated": true,
		"enemy_id": enemy_id,
		"victory_display": routed.get("victory_display", false),
		"subject": SUBJECT_ENEMY,
	}


static func discard_from_play(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or enemy_id == &"":
		return {"ok": false, "discarded": false}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "discarded": false}
	_clear_enemy_engagement(game_ctx, enemy_id)
	_route_enemy_to_discard(game_ctx, enemy_id)
	game_ctx.state.registry.unregister_enemy(enemy_id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:discarded_from_play",
			{"enemy_id": enemy_id}
		)
	return {"ok": true, "discarded": true, "enemy_id": enemy_id}


static func defeat_enemy_effect(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	return nest_or_run(
		game_ctx,
		{
			"subject": SUBJECT_ENEMY,
			"enemy_id": enemy_id,
			"cause": CAUSE_EFFECT,
		}
	)


static func _finalize_swarm_leave(game_ctx: GameContext, swarm_id: StringName) -> Dictionary:
	_clear_enemy_engagement(game_ctx, swarm_id)
	SwarmPack.unbind_swarm(game_ctx, swarm_id)
	var card := game_ctx.state.registry.get_card(swarm_id)
	var owner_id: StringName = &""
	if card != null:
		owner_id = card.owner_id
		## 保持不可见进所有者牌库底。
		if card.face_visibility != null:
			card.face_visibility.audience = AhcEnums.FaceAudience.HIDDEN_ALL
		if game_ctx.mutator != null and owner_id != &"" and game_ctx.state.registry.get_investigator(owner_id) != null:
			game_ctx.mutator.move_card(swarm_id, CardSlot.deck_bottom(owner_id))
	game_ctx.state.registry.unregister_enemy(swarm_id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"swarm:leave_to_deck_bottom",
			{"swarm_id": swarm_id, "owner_id": owner_id}
		)
	return {
		"ok": true,
		"defeated": true,
		"enemy_id": swarm_id,
		"swarm_card": true,
		"dest": &"owner_deck_bottom",
		"subject": SUBJECT_ENEMY,
	}


static func _clear_enemy_engagement(game_ctx: GameContext, enemy_id: StringName) -> void:
	EngageFlow.disengage(game_ctx, enemy_id, false, false)


static func _route_enemy_after_defeat(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	## 去向：胜利/复仇特征（印刷∪挂载）→ 胜利区；否则按所有者（遭遇弃牌 / 玩家弃牌 / 无主→置一边）。
	if CharacteristicMount.routes_to_victory_display(game_ctx, enemy_id):
		CharacteristicMount.stamp_victory_earned(game_ctx, enemy_id)
		var moved := _route_enemy_to_victory_display(game_ctx, enemy_id)
		return {"victory_display": moved, "dest": &"victory_display"}
	return _route_enemy_to_discard(game_ctx, enemy_id)


static func _route_enemy_to_victory_display(game_ctx: GameContext, enemy_id: StringName) -> bool:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null or game_ctx.mutator == null:
		return false
	return game_ctx.mutator.move_card(enemy_id, CardSlot.victory_display())


static func _route_enemy_to_discard(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null or game_ctx.mutator == null:
		return {"victory_display": false, "dest": &""}
	## 弱点敌人 → 所有者弃牌堆。
	if game_ctx.state.registry.get_investigator(card.owner_id) != null:
		game_ctx.mutator.move_card(enemy_id, CardSlot.discard_top(card.owner_id))
		return {"victory_display": false, "dest": &"owner_discard"}
	## 遭遇敌人 → 遭遇弃牌堆。
	if card.owner_id == &"encounter":
		game_ctx.mutator.move_card(enemy_id, CardSlot.encounter_discard_top())
		return {"victory_display": false, "dest": &"encounter_discard"}
	## 无玩家/遭遇所有者 → 置一边（少见；剧情体主要走支援路径）。
	game_ctx.mutator.move_to_set_aside(enemy_id)
	return {"victory_display": false, "dest": &"set_aside"}


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
			## 主体仍有集群卡牌：不可击败（可超生命承伤）。
			if _swarm_host_blocks(game_ctx, enemy_id):
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
	return finalize_leave_play(game_ctx, enemy_id, definition_id)


static func _leave_investigator(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var inv_id: StringName = params.get("investigator_id", &"") as StringName
	var elim := eliminate_investigator(game_ctx, inv_id)
	return {
		"ok": bool(elim.get("eliminated", false)),
		"defeated": bool(elim.get("defeated", false)),
		"eliminated": bool(elim.get("eliminated", false)),
		"investigator_id": inv_id,
		"discarded": elim.get("discarded", []),
		"subject": SUBJECT_INVESTIGATOR,
	}


## 支援退场（≠ discard 效果包装）：
## Victory/复仇 → 胜利区；有玩家所有者 → 其弃牌堆；否则（无主剧情支援）→ REMOVED。
## 依据：FAQ · Lita Chantler（01117）— 临时控制、非牌组成员时离场 → remove from the game。
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
	if CharacteristicMount.routes_to_victory_display(game_ctx, card_id):
		CharacteristicMount.stamp_victory_earned(game_ctx, card_id)
		moved = game_ctx.mutator.move_card(card_id, CardSlot.victory_display())
		dest = &"victory_display"
	elif game_ctx.state.registry.get_investigator(owner_id) != null:
		moved = game_ctx.mutator.move_card(card_id, CardSlot.discard_top(owner_id))
		dest = &"owner_discard"
	else:
		## 无玩家所有者（临时控制的剧情支援等）→ 从游戏中移除。
		moved = game_ctx.mutator.remove_from_game(card_id)
		dest = &"removed_from_game"
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

## --- 调查员淘汰 / 撤退（原 InvestigatorElimination） ---

## Resign（撤退）：线索留地点 → resigned → eliminate。
## 卡面编译应展为三步 Composition；本函数供 `seq.effect.resign` / 旧单 Atom 兼容。
static func resign_investigator(game_ctx: GameContext, inv_id: StringName) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "resigned": false}
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null or inv.eliminated:
		return {"ok": false, "resigned": false}
	var clues_left := inv.clues_on_card
	if clues_left > 0 and inv.location_tag != &"":
		var loc := game_ctx.state.registry.get_location(inv.location_tag)
		if loc != null:
			loc.clues += clues_left
		inv.clues_on_card = 0
	if game_ctx.mutator != null:
		game_ctx.mutator.set_flag(inv_id, AhcEnums.FlagField.RESIGNED, true)
	else:
		inv.resigned = true
	var elim := eliminate_investigator(game_ctx, inv_id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.ACTION,
			"investigator:resigned",
			{"inv": inv_id, "clues_left_on_location": clues_left}
		)
	return {
		"ok": bool(elim.get("eliminated", false)),
		"resigned": true,
		"eliminated": bool(elim.get("eliminated", false)),
		"clues_left_on_location": clues_left,
		"discarded": elim.get("discarded", []),
	}


static func eliminate_investigator(game_ctx: GameContext, inv_id: StringName) -> Dictionary:
	var discarded: Array[StringName] = []
	if game_ctx == null or game_ctx.mutator == null:
		return {"eliminated": false, "defeated": false, "discarded": discarded}
	if game_ctx.state == null:
		game_ctx.mutator.set_flag(inv_id, AhcEnums.FlagField.ELIMINATED, true)
		return {"eliminated": true, "defeated": true, "discarded": discarded}
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null:
		return {"eliminated": false, "defeated": false, "discarded": discarded}
	for card_id in inv.threat_area.duplicate():
		if _is_encounter_card(game_ctx, card_id):
			if ZoneMoveFlow.discard_encounter_from_investigator(game_ctx, card_id, inv_id):
				discarded.append(card_id)
	for card_id in inv.hand.duplicate():
		if _is_hidden_encounter_in_hand(game_ctx, inv_id, card_id):
			if ZoneMoveFlow.discard_encounter_from_investigator(game_ctx, card_id, inv_id):
				discarded.append(card_id)
	game_ctx.mutator.set_flag(inv_id, AhcEnums.FlagField.ELIMINATED, true)
	return {"eliminated": true, "defeated": true, "discarded": discarded}


static func _is_encounter_card(game_ctx: GameContext, card_id: StringName) -> bool:
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return false
	if card.owner_id == &"encounter":
		return true
	return game_ctx.state.registry.get_enemy(card_id) != null


static func _is_hidden_encounter_in_hand(
	game_ctx: GameContext,
	inv_id: StringName,
	card_id: StringName
) -> bool:
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return false
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null or not inv.hand.has(card_id):
		return false
	if not CardRegistry.is_hidden(card.id.definition_id):
		return false
	return card.owner_id == &"encounter"


## --- 蜂拥伤害（原 SwarmDamage） ---

## 蜂拥伤害：主体可超生命且不可击败；集群卡牌击败后超额伤害经 PI 选目标传递。
## 自动模式只是 Gate/DefaultResolver 的可选路径，不是强制自动。


static func _swarm_host_blocks(game_ctx: GameContext, enemy_id: StringName) -> bool:
	if game_ctx == null or enemy_id == &"":
		return false
	if SwarmPack.is_swarm_card(game_ctx, enemy_id):
		return false
	return SwarmPack.has_swarm_cards(game_ctx, enemy_id)


## 对敌人造成伤害；处理主体超限与集群溢出。
static func _swarm_deal_damage(game_ctx: GameContext, enemy_id: StringName, amount: int) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or enemy_id == &"" or amount <= 0:
		return {"ok": false, "defeated": false}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "defeated": false}
	enemy.damage += amount
	if SwarmPack.is_swarm_card(game_ctx, enemy_id):
		if enemy.damage < enemy.health:
			return {"ok": true, "defeated": false, "damage": enemy.damage}
		var excess := enemy.damage - enemy.health
		enemy.damage = enemy.health
		## 退场会解绑；溢出候选须在 leave 前快照。
		var host_id := SwarmPack.host_of(game_ctx, enemy_id)
		var spill_candidates := _spill_candidates(game_ctx, host_id, enemy_id)
		var defeated := check_enemy_damage_cap(game_ctx, enemy_id)
		var spill := {"ok": true, "spilled": 0}
		if excess > 0 and bool(defeated.get("defeated", false)):
			spill = spill_excess(game_ctx, excess, spill_candidates)
		defeated["excess"] = excess
		defeated["spill"] = spill
		return defeated
	## 主体：可超生命；仍有集群卡牌则不击败。
	if _swarm_host_blocks(game_ctx, enemy_id):
		return {
			"ok": true,
			"defeated": false,
			"damage": enemy.damage,
			"over_health": enemy.damage >= enemy.health,
			"host_blocked": true,
		}
	if enemy.damage < enemy.health:
		return {"ok": true, "defeated": false, "damage": enemy.damage}
	return check_enemy_damage_cap(game_ctx, enemy_id)


static func _spill_candidates(
	game_ctx: GameContext,
	host_id: StringName,
	from_swarm_id: StringName
) -> Array:
	var candidates: Array = []
	if game_ctx == null or host_id == &"":
		return candidates
	for sid in SwarmPack.swarm_ids(game_ctx, host_id):
		if sid != from_swarm_id and game_ctx.state.registry.get_enemy(sid) != null:
			candidates.append(sid)
	if game_ctx.state.registry.get_enemy(host_id) != null:
		candidates.append(host_id)
	return candidates


## `candidates` 为 leave 前快照。经 PI 选目标；支持自动默认，但不强制自动。
static func spill_excess(game_ctx: GameContext, excess: int, candidates: Array) -> Dictionary:
	if game_ctx == null or excess <= 0:
		return {"ok": true, "spilled": 0}
	## 过滤 leave 后仍在场的目标。
	var alive: Array = []
	for raw in candidates:
		var cid: StringName = raw as StringName
		if cid != &"" and game_ctx.state.registry.get_enemy(cid) != null:
			alive.append(cid)
	if alive.is_empty():
		return {"ok": true, "spilled": 0, "remaining": excess}
	## PI 有限期确认；未确认 / 无 Gate 时才用默认（自动模式可走这条）。
	var pick: Variant = null
	if game_ctx.interaction != null:
		var decider := game_ctx.lead_investigator_id
		if decider == &"":
			for inv_id in game_ctx.state.registry.all_investigator_ids():
				decider = inv_id
				break
		pick = game_ctx.interaction.ask_pick_target(
			alive,
			decider,
			&"swarm:spill_excess",
			game_ctx
		)
	if pick == null:
		pick = alive[0]
	var target_id: StringName = pick as StringName
	if target_id == &"":
		return {"ok": true, "spilled": 0, "remaining": excess}
	var nested := _swarm_deal_damage(game_ctx, target_id, excess)
	return {
		"ok": true,
		"spilled": excess,
		"to": target_id,
		"result": nested,
	}
