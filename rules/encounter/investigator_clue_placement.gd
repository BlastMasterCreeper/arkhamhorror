class_name InvestigatorCluePlacement
extends RefCounted

## 12126 fail-by · 调查员卡上 1 clue 放到所在地点（Domain · clues_on_card → location.clues）。


static func place_one_on_investigator_location(game_ctx: GameContext, inv_id: StringName) -> bool:
	if game_ctx == null or game_ctx.state == null:
		return false
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null or inv.clues_on_card <= 0 or inv.location_tag == &"":
		return false
	var loc := game_ctx.state.registry.get_location(inv.location_tag)
	if loc == null:
		return false
	inv.clues_on_card -= 1
	loc.clues += 1
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.CARD,
			"encounter:place_clue_on_location",
			{"inv": inv_id, "location": inv.location_tag, "clues_on_card": inv.clues_on_card}
		)
	return true
