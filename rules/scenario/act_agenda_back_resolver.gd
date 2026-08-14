class_name ActAgendaBackResolver
extends RefCounted

## Act/Agenda b 面 · 编译为 Composition 并在翻面时结算。


static func resolve(
	game_ctx: GameContext,
	definition_id: StringName,
	back_text: String,
	flipped_card_id: StringName = &"",
	is_agenda: bool = false
) -> Dictionary:
	if game_ctx == null:
		return {"ok": false}
	return ActAgendaBackFlow.resolve_back(
		game_ctx, definition_id, flipped_card_id, is_agenda, back_text
	)
