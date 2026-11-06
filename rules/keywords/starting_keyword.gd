class_name StartingKeyword
extends RefCounted

## 起始（Starting）· 玩家轴 LISTENER（DELAYED）。
## 挂载：牌库内 KEYWORD 标记；开火：起手+mulligan 之后各检索 1 张入手。


## 对每位调查员牌库内印刷 Starting 挂武装。
static func mount_printed_in_decks(game_ctx: GameContext) -> void:
	if game_ctx == null or game_ctx.state == null:
		return
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null:
			continue
		for card_id in inv.deck:
			var card := game_ctx.state.registry.get_card(card_id)
			if card == null or card.id == null:
				continue
			KeywordMount.mount_starting_if_absent(game_ctx, card_id, card.id.definition_id)


## SETUP_08 之后：每位调查员从牌库检索 1 张已武装 Starting 入手。
static func fire_after_opening_hands(game_ctx: GameContext) -> Dictionary:
	var pulled: Array = []
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "pulled": pulled}
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var card_id := _first_armed_in_deck(game_ctx, inv_id)
		if card_id == &"":
			continue
		if game_ctx.mutator == null:
			continue
		if not game_ctx.mutator.enter_hand_from_deck(card_id, inv_id):
			continue
		if game_ctx.registrations != null:
			game_ctx.registrations.on_leave_deck(card_id)
		pulled.append({"investigator_id": inv_id, "card_id": card_id})
	if game_ctx.log != null and not pulled.is_empty():
		game_ctx.log.log(AhcEnums.LogCategory.SCENARIO, "setup:starting_search", {"pulled": pulled})
	return {"ok": true, "pulled": pulled}


static func _first_armed_in_deck(game_ctx: GameContext, inv_id: StringName) -> StringName:
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null:
		return &""
	for card_id in inv.deck:
		if KeywordMount.is_keyword_armed(game_ctx, card_id, &"starting"):
			return card_id
	return &""
