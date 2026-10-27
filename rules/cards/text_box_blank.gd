class_name TextBoxBlank
extends RefCounted

## 印刷文本框视为空白（Grimoire Blank）：印刷内容不生效；他源获得的不空白。


static func set_blank(card: CardInstance, blank: bool) -> void:
	if card == null:
		return
	card.text_box_blank = blank


static func set_blank_by_id(game_ctx: GameContext, card_id: StringName, blank: bool) -> bool:
	if game_ctx == null or game_ctx.state == null:
		return false
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return false
	set_blank(card, blank)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.CARD,
			"keyword:text_box_blank",
			{"card": card_id, "blank": blank}
		)
	return true


static func is_blank(card: CardInstance) -> bool:
	return card != null and card.text_box_blank
