class_name ZoneMoveFlow
extends RefCounted

## 广义区划迁移 · `seq.zone.move`。
## 进场 / 离场 = 对本流程的过滤别名（场外↔场上）；不是效果 seq。
## 调用点直接 L0 `move_card` / 写 zone + `notify_zone_set`；本类不做去向薄包装。
## 翻译卡面时：从「弃置 / 放入场 / 从游戏中移除 / 入手…」等措辞分辨区划转移序列，
## 经 L0 写入即可被时点听到；勿另铸 `seq.effect.enter_play` / 去向 facade。

const FLOW := &"seq.zone.move"

const ALIAS_ENTER_PLAY := &"ENTER_PLAY"
const ALIAS_LEAVE_PLAY := &"LEAVE_PLAY"
const ALIAS_LEAVE_HAND := &"LEAVE_HAND"


static func bind_mutator(game_ctx: GameContext) -> void:
	if game_ctx == null or game_ctx.mutator == null:
		return
	game_ctx.mutator.bind_after_zone_move(
		func(card_id: StringName, from_zone: AhcEnums.Zone, to_zone: AhcEnums.Zone) -> void:
			after_l0_move(game_ctx, card_id, from_zone, to_zone)
	)


static func after_l0_move(
	game_ctx: GameContext,
	card_id: StringName,
	from_zone: AhcEnums.Zone,
	to_zone: AhcEnums.Zone
) -> void:
	if card_id == &"" or from_zone == to_zone:
		return
	nest_or_run(
		game_ctx,
		{
			"card_id": card_id,
			"from_zone": from_zone,
			"to_zone": to_zone,
		}
	)


static func notify_zone_set(
	game_ctx: GameContext,
	card_id: StringName,
	from_zone: AhcEnums.Zone,
	to_zone: AhcEnums.Zone
) -> void:
	## L0 直接写 zone（未走 move_card）时补发同一通道。
	after_l0_move(game_ctx, card_id, from_zone, to_zone)


static func nest_or_run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(FLOW)
	):
		return game_ctx.sequence_catalog.run(game_ctx, FLOW, params)
	return run(game_ctx, params)


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	var card_id: StringName = params.get("card_id", &"") as StringName
	if card_id == &"":
		return {"ok": false, "error": "missing_card_id"}
	var from_zone: int = int(params.get("from_zone", -1))
	var to_zone: int = int(params.get("to_zone", -1))
	if from_zone < 0 or to_zone < 0:
		var card := game_ctx.state.registry.get_card(card_id)
		if card == null:
			return {"ok": false, "error": "missing_card"}
		if to_zone < 0:
			to_zone = card.zone
		if from_zone < 0:
			from_zone = to_zone
	var was_in_play := zone_is_in_play(from_zone as AhcEnums.Zone)
	var now_in_play := zone_is_in_play(to_zone as AhcEnums.Zone)
	var was_in_hand := (from_zone as AhcEnums.Zone) == AhcEnums.Zone.HAND
	var now_in_hand := (to_zone as AhcEnums.Zone) == AhcEnums.Zone.HAND
	var out := {
		"ok": true,
		"card_id": card_id,
		"from_zone": from_zone,
		"to_zone": to_zone,
	}
	if not was_in_play and now_in_play:
		out[ALIAS_ENTER_PLAY] = true
		_apply_enter_play(game_ctx, card_id)
	elif was_in_play and not now_in_play:
		out[ALIAS_LEAVE_PLAY] = true
		_apply_leave_play(game_ctx, card_id)
	if was_in_hand and not now_in_hand:
		out[ALIAS_LEAVE_HAND] = true
		if game_ctx.registrations != null:
			game_ctx.registrations.on_leave_hand(card_id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.CARD,
			"zone:move",
			{
				"card_id": card_id,
				"from": from_zone,
				"to": to_zone,
				"enter_play": out.get(ALIAS_ENTER_PLAY, false),
				"leave_play": out.get(ALIAS_LEAVE_PLAY, false),
			}
		)
	return out


static func zone_is_in_play(zone: AhcEnums.Zone) -> bool:
	## ATTACHED 亦 in-play（Grimoire Attachment）；离场时须走 leave 捆绑以便级联清附属。
	return (
		zone == AhcEnums.Zone.PLAY_AREA
		or zone == AhcEnums.Zone.THREAT_AREA
		or zone == AhcEnums.Zone.ATTACHED
	)


static func _apply_enter_play(game_ctx: GameContext, card_id: StringName) -> void:
	## Domain：Uses 进场放 typed token；Seal 关键词进场封印；再装触发能力。
	if game_ctx == null or card_id == &"":
		return
	var card := game_ctx.state.registry.get_card(card_id) if game_ctx.state != null else null
	if card == null:
		return
	_apply_uses_on_enter(game_ctx, card)
	_apply_seal_on_enter(game_ctx, card_id)
	if game_ctx.triggered_abilities == null:
		return
	if not CardRegistry.has_triggered(card.id.definition_id):
		return
	var controller := card.controller_id
	if controller == &"":
		controller = card_id
	game_ctx.triggered_abilities.install_card(controller, card_id)


static func _apply_seal_on_enter(game_ctx: GameContext, card_id: StringName) -> void:
	if game_ctx == null or game_ctx.state == null or card_id == &"":
		return
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null or not CardRegistry.has_seal_play_cost(card.id.definition_id):
		return
	SealFlow.pay_keyword_on_enter(game_ctx, card_id)


static func _apply_uses_on_enter(game_ctx: GameContext, card: CardInstance) -> void:
	if card == null:
		return
	var uses: Dictionary = CardRegistry.uses_spec(card.id.definition_id)
	if uses.is_empty():
		return
	var use_type: StringName = uses.get("type", &"charges") as StringName
	var count := maxi(int(uses.get("count", 0)), 0)
	if use_type == &"" or count <= 0:
		return
	card.tokens.uses[use_type] = count
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.CARD,
			"keyword:uses_enter",
			{"card": card.id.instance_id, "type": use_type, "count": count}
		)


static func _apply_leave_play(game_ctx: GameContext, card_id: StringName) -> void:
	## 时点=场上→场外区划移动；条件=LEAVE_PLAY；同时组：token→pool、弃附属、lasting 过期。
	## 「同时」= 与该次移动同一时间；全部完毕才轮到 After（01 §5.2/§5.3）；≠ 内联 then。
	if game_ctx.triggered_abilities != null:
		game_ctx.triggered_abilities.uninstall_by_source(card_id)
	if game_ctx.registrations != null:
		game_ctx.registrations.on_card_leave_play(card_id)
	## Seal：离场立即释放封印标记回袋（Grimoire）。
	SealFlow.release_on_leave_play(game_ctx, card_id)
	if game_ctx.state == null:
		return
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return
	_return_tokens_to_pool(game_ctx, card)
	_discard_attachments_on_leave(game_ctx, card)


## 卡上 damage/horror/clue → global TokenPool；doom/uses 清零（池无 doom/uses 槽）。
static func _return_tokens_to_pool(game_ctx: GameContext, card: CardInstance) -> void:
	if card == null:
		return
	var pool: TokenPool = game_ctx.state.token_pool if game_ctx != null and game_ctx.state != null else null
	var damage := maxi(card.tokens.damage, 0)
	var horror := maxi(card.tokens.horror, 0)
	var clue := maxi(card.tokens.clue, 0)
	if pool != null:
		pool.damage_available += damage
		pool.horror_available += horror
		pool.clue_available += clue
	card.tokens.damage = 0
	card.tokens.horror = 0
	card.tokens.clue = 0
	card.tokens.doom = 0
	card.tokens.uses.clear()
	card.tokens.sealed.clear()
	if game_ctx != null and game_ctx.log != null and (damage + horror + clue) > 0:
		game_ctx.log.log(
			AhcEnums.LogCategory.CARD,
			"leave_play:tokens_to_pool",
			{
				"card": card.id.instance_id if card.id != null else &"",
				"damage": damage,
				"horror": horror,
				"clue": clue,
			}
		)


## 宿主离场 → 弃置全部附属（各进 owner discard）；嵌套附属由 ATTACHED leave 级联。
static func _discard_attachments_on_leave(game_ctx: GameContext, host: CardInstance) -> void:
	if game_ctx == null or host == null or host.attachments.is_empty():
		return
	var pending: Array = host.attachments.duplicate()
	host.attachments.clear()
	var discarded: Array[StringName] = []
	for raw in pending:
		var eid: EntityId = raw as EntityId
		if eid == null:
			continue
		var att_id := eid.instance_id
		var att := game_ctx.state.registry.get_card(att_id) if game_ctx.state != null else null
		if att == null:
			continue
		att.attached_to = null
		if _discard_attachment_instance(game_ctx, att):
			discarded.append(att_id)
	if game_ctx.log != null and not discarded.is_empty():
		game_ctx.log.log(
			AhcEnums.LogCategory.CARD,
			"leave_play:attachments_discarded",
			{
				"host": host.id.instance_id if host.id != null else &"",
				"attachments": discarded,
			}
		)


static func _discard_attachment_instance(game_ctx: GameContext, card: CardInstance) -> bool:
	## L0 弃置去向（非 nest seq.effect.discard_card）：与 EffectFlowHandlers 统一路由。
	if card == null or game_ctx == null:
		return false
	var card_id := card.id.instance_id if card.id != null else &""
	if card_id == &"":
		return false
	var inv_id := card.controller_id
	if inv_id == &"":
		inv_id = card.owner_id
	if game_ctx.state != null and game_ctx.state.registry.get_enemy(card_id) != null:
		var routed := EnemyDefeatResolver.discard_from_play(game_ctx, card_id)
		return bool(routed.get("ok", false))
	if card.owner_id == &"encounter":
		return EncounterCardDiscard.discard_from_investigator_to_encounter_pile(
			game_ctx, card_id, inv_id
		)
	if game_ctx.state != null and game_ctx.state.registry.get_investigator(card.owner_id) != null:
		if game_ctx.mutator == null:
			return false
		return game_ctx.mutator.move_card(card_id, CardSlot.discard_top(card.owner_id))
	card.zone = AhcEnums.Zone.REMOVED_FROM_GAME
	if game_ctx.state != null and not game_ctx.state.removed_from_game.has(card_id):
		game_ctx.state.removed_from_game.append(card_id)
	ZoneMoveFlow.notify_zone_set(
		game_ctx, card_id, AhcEnums.Zone.ATTACHED, AhcEnums.Zone.REMOVED_FROM_GAME
	)
	return true
