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
	if game_ctx.triggered_abilities != null:
		game_ctx.triggered_abilities.uninstall_by_source(card_id)
	if game_ctx.registrations != null:
		game_ctx.registrations.unregister_by_controller(card_id)
	card.face = AhcEnums.CardFace.B
	var back := CardRegistry.back_text(def_id)
	var back_result := ActAgendaBackResolver.resolve(game_ctx, def_id, back, card_id, is_agenda)
	var resolution: int = int(back_result.get("resolution", -1))
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
	if is_agenda:
		game_ctx.state.current_agenda_card_id = &""
	else:
		game_ctx.state.current_act_card_id = &""
	if not game_ctx.state.removed_from_game.has(card_id):
		game_ctx.state.removed_from_game.append(card_id)


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
	else:
		card.zone = AhcEnums.Zone.CURRENT_ACT
		game_ctx.state.current_act_card_id = next_id
		ScenarioDeckSetup.sync_act_clue_threshold(game_ctx.state, next_id)
	ScenarioDeckSetup.install_triggered_abilities(game_ctx, next_id)
	return {"ok": true, "promoted": true, "card_id": next_id}
