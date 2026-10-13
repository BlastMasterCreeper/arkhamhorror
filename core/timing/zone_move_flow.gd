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
	return zone == AhcEnums.Zone.PLAY_AREA or zone == AhcEnums.Zone.THREAT_AREA


static func _apply_enter_play(game_ctx: GameContext, card_id: StringName) -> void:
	## 用卡上 controller；空则回退 card_id（敌人 spawn 等）。
	if game_ctx == null or game_ctx.triggered_abilities == null or card_id == &"":
		return
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return
	if not CardRegistry.has_triggered(card.id.definition_id):
		return
	var controller := card.controller_id
	if controller == &"":
		controller = card_id
	game_ctx.triggered_abilities.install_card(controller, card_id)


static func _apply_leave_play(game_ctx: GameContext, card_id: StringName) -> void:
	if game_ctx.triggered_abilities != null:
		game_ctx.triggered_abilities.uninstall_by_source(card_id)
	if game_ctx.registrations != null:
		game_ctx.registrations.on_card_leave_play(card_id)
