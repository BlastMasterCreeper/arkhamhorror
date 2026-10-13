class_name DoomedResolver
extends RefCounted

## 厄运降临（Doomed）· Grimoire / 08 §8
##
## 敌人 **被击败**（defeat）时在 **当前密谋** 上放置 1 毁灭；可推进密谋。
## 「弃置」敌人不算 defeat，不触发。


static func try_on_defeat(game_ctx: GameContext, enemy_id: StringName) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or enemy_id == &"":
		return {"ok": true, "triggered": false}
	var def_id := _definition_id(game_ctx, enemy_id)
	if not CardRegistry.is_doomed(def_id):
		return {"ok": true, "triggered": false}
	var placed := EncounterAgendaDoomPlacement.place_on_current_agenda(game_ctx, true)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:doomed",
			{
				"enemy_id": enemy_id,
				"definition_id": def_id,
				"placed": placed,
				"doom_on_agenda": game_ctx.state.doom_on_agenda,
			}
		)
	return {"ok": true, "triggered": true, "placed": placed}


static func _definition_id(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null:
		return enemy_id
	return card.id.definition_id
