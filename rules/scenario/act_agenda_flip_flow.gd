class_name ActAgendaFlipFlow
extends RefCounted

## Act/Agenda 翻面推进内核 · 02 §7 / 10 §3–4。
##
## 1. 清 advancing 卡 token
## 2. a 面 unregister（OQ-02-02）
## 3. 翻面 → 结算 b 面
## 4. advancing 卡 removed from game；sequential next 成为 current


static func flip_agenda(game_ctx: GameContext) -> Dictionary:
	return _flip(game_ctx, true)


static func flip_act(game_ctx: GameContext) -> Dictionary:
	return _flip(game_ctx, false)


static func _flip(game_ctx: GameContext, is_agenda: bool) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "flipped": false}
	var card_id := (
		game_ctx.state.current_agenda_card_id
		if is_agenda
		else game_ctx.state.current_act_card_id
	)
	if card_id == &"":
		return {"ok": false, "flipped": false, "reason": &"no_current_card"}
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return {"ok": false, "flipped": false, "reason": &"missing_card"}
	var def_id := card.id.definition_id
	_clear_tokens(card)
	_mirror_tokens(game_ctx, card)
	if game_ctx.triggered_abilities != null:
		game_ctx.triggered_abilities.uninstall_by_source(card_id)
	if game_ctx.registrations != null:
		game_ctx.registrations.on_card_leave_play(card_id)
	card.face = AhcEnums.CardFace.B
	_mirror_flip(game_ctx, card, AhcEnums.CardFace.B)
	var encounter_back := CardRegistry.has_encounter_cardtype_back(def_id)
	var back := CardRegistry.back_text(def_id)
	var back_result := ActAgendaBackResolver.resolve(game_ctx, def_id, back, card_id, is_agenda)
	var resolution: int = int(back_result.get("resolution", -1))
	## 遭遇类型背面：按抽取规则进场/显现/弃置，**不** RFG（仍晋升下一张）。
	## 普通指令背面：结算后 advancing 卡 removed from game。
	if encounter_back or bool(back_result.get("encounter_back", false)):
		_clear_current_pointer(game_ctx, card_id, is_agenda)
	else:
		_remove_from_game(game_ctx, card_id, is_agenda)
	var promoted := _promote_next(game_ctx, is_agenda)
	if is_agenda:
		game_ctx.state.current_agenda_number += 1
	else:
		game_ctx.state.current_act_number += 1
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"act_agenda:flipped",
			{
				"kind": &"agenda" if is_agenda else &"act",
				"from_card": card_id,
				"definition_id": def_id,
				"back_name": CardRegistry.back_name(def_id),
				"promoted": promoted.get("card_id", &""),
				"resolution": resolution,
			}
		)
	return {
		"ok": true,
		"flipped": true,
		"flipped_card_id": card_id,
		"definition_id": def_id,
		"promoted": promoted,
		"resolution": resolution,
		"encounter_back": encounter_back,
		"back": back_result,
	}


static func _clear_tokens(card: CardInstance) -> void:
	card.tokens.damage = 0
	card.tokens.horror = 0
	card.tokens.doom = 0
	card.tokens.clue = 0
	card.tokens.uses.clear()


static func _remove_from_game(game_ctx: GameContext, card_id: StringName, is_agenda: bool) -> void:
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return
	card.zone = AhcEnums.Zone.REMOVED_FROM_GAME
	_clear_current_pointer(game_ctx, card_id, is_agenda)
	if not game_ctx.state.removed_from_game.has(card_id):
		game_ctx.state.removed_from_game.append(card_id)
	_mirror_move_zone(game_ctx, card, AhcEnums.Zone.REMOVED_FROM_GAME, &"")


## 遭遇类型背面结算后：卸下 current 指针；卡本身已由 spawn/discard/进场安置。
static func _clear_current_pointer(
	game_ctx: GameContext,
	card_id: StringName,
	is_agenda: bool
) -> void:
	if is_agenda:
		if game_ctx.state.current_agenda_card_id == card_id:
			game_ctx.state.current_agenda_card_id = &""
	else:
		if game_ctx.state.current_act_card_id == card_id:
			game_ctx.state.current_act_card_id = &""


static func _promote_next(game_ctx: GameContext, is_agenda: bool) -> Dictionary:
	var deck: Array[StringName] = (
		game_ctx.state.agenda_deck if is_agenda else game_ctx.state.act_deck
	)
	if deck.is_empty():
		if is_agenda:
			game_ctx.state.agenda_threshold = -1
		else:
			game_ctx.state.act_clue_threshold = -1
		return {"ok": true, "promoted": false}
	var next_id: StringName = deck[0]
	deck.remove_at(0)
	var card := game_ctx.state.registry.get_card(next_id)
	if card == null:
		return {"ok": false, "promoted": false}
	card.face = AhcEnums.CardFace.A
	if is_agenda:
		card.zone = AhcEnums.Zone.CURRENT_AGENDA
		game_ctx.state.current_agenda_card_id = next_id
		ScenarioDeckSetup.sync_agenda_threshold(game_ctx.state, next_id)
		_mirror_flip(game_ctx, card, AhcEnums.CardFace.A)
		_mirror_move_zone(game_ctx, card, AhcEnums.Zone.CURRENT_AGENDA, &"")
	else:
		card.zone = AhcEnums.Zone.CURRENT_ACT
		game_ctx.state.current_act_card_id = next_id
		ScenarioDeckSetup.sync_act_clue_threshold(game_ctx.state, next_id)
		_mirror_flip(game_ctx, card, AhcEnums.CardFace.A)
		_mirror_move_zone(game_ctx, card, AhcEnums.Zone.CURRENT_ACT, &"")
	ScenarioDeckSetup.install_triggered_abilities(game_ctx, next_id)
	return {"ok": true, "promoted": true, "card_id": next_id}


static func _mirror_flip(
	game_ctx: GameContext,
	card: CardInstance,
	face: AhcEnums.CardFace
) -> void:
	if game_ctx.state == null or game_ctx.state.physical_binding == null:
		return
	game_ctx.state.physical_binding.ensure_physical_card(card)
	game_ctx.state.physical_binding.mirror_flip(card.id.instance_id, face)


static func _mirror_tokens(game_ctx: GameContext, card: CardInstance) -> void:
	if game_ctx.state == null or game_ctx.state.physical_binding == null:
		return
	game_ctx.state.physical_binding.sync_card_markers(card)


static func _mirror_move_zone(
	game_ctx: GameContext,
	card: CardInstance,
	zone: AhcEnums.Zone,
	owner_id: StringName
) -> void:
	if game_ctx.state == null or game_ctx.state.physical_binding == null:
		return
	game_ctx.state.physical_binding.mirror_move_to_zone(card, zone, owner_id)
