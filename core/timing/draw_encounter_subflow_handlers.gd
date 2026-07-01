class_name DrawEncounterSubflowHandlers
extends RefCounted

## E1 内联 collect：遭遇牌库 pop；空库洗弃（无 horror）；两堆皆空 RULES_GAP。


static func collect_one_step(
	game_ctx: GameContext,
	frame: EncounterResolutionFrame = null
) -> Dictionary:
	var mutator := game_ctx.mutator if game_ctx != null else null
	if mutator == null:
		return {"collected": false, "rules_gap": true}
	var shuffled := false
	if mutator.encounter_deck_is_empty():
		if mutator.encounter_discard_is_empty():
			return {"collected": false, "rules_gap": true}
		mutator.shuffle_encounter_discard_into_deck()
		if frame != null:
			frame.shuffles += 1
		shuffled = true
	var card_id := mutator.pop_encounter_deck_top()
	if card_id == &"":
		return {"collected": false, "rules_gap": true}
	return {"collected": true, "card_id": card_id, "shuffled": shuffled}
