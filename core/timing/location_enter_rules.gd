class_name LocationEnterRules
extends RefCounted

## 规则自带：调查员进入地点。
## 未揭示 → 翻开 + 按印刷 clue value（× per investigator）从 token pool 放线索。
## 已揭示 → 不再放线索（首次进入已处理）。
## **不是**关键词；**不是**卡面 Forced。


## 调查员刚落到该地点后调用（Move / setup 放置等）。
static func on_investigator_enter(
	game_ctx: GameContext,
	location_id: StringName
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or location_id == &"":
		return {"ok": false, "error": "no_context"}
	var loc := game_ctx.state.registry.get_location(location_id)
	if loc == null:
		return {"ok": false, "error": "unknown_location"}
	if loc.revealed:
		return {
			"ok": true,
			"location_id": location_id,
			"revealed": false,
			"already_revealed": true,
			"clues_placed": 0,
		}
	return nest_or_run_reveal(game_ctx, {"location_id": location_id})


## Catalog nest；无 Catalog 时直跑。
static func nest_or_run_reveal(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(&"seq.effect.reveal_location")
	):
		return game_ctx.sequence_catalog.nest(
			game_ctx, &"seq.effect.reveal_location", params
		)
	return reveal_and_place_clues(game_ctx, params)


## 揭示地点并放置印刷线索（幂等：已揭示则跳过）。
static func reveal_and_place_clues(
	game_ctx: GameContext,
	params: Dictionary = {}
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	var location_id: StringName = params.get("location_id", &"") as StringName
	if location_id == &"":
		return {"ok": false, "error": "missing_location"}
	var loc := game_ctx.state.registry.get_location(location_id)
	if loc == null:
		return {"ok": false, "error": "unknown_location"}
	if loc.revealed:
		return {
			"ok": true,
			"location_id": location_id,
			"revealed": false,
			"already_revealed": true,
			"clues_placed": 0,
		}
	var printed := resolve_printed_clues(loc)
	var placed := PerInvestigatorScale.place_location_clues(game_ctx.state, printed)
	loc.revealed = true
	## 经 transfer_marker 从供给池落到地点（物理层镜像）；无 mutator 时回退逻辑计数。
	var need := maxi(placed - loc.clues, 0)
	if need > 0 and game_ctx.mutator != null:
		game_ctx.mutator.transfer_marker(
			AhcEnums.MarkerKind.CLUE,
			need,
			MarkerSlot.supply(AhcEnums.MarkerKind.CLUE),
			MarkerSlot.location(location_id, AhcEnums.MarkerKind.CLUE)
		)
	elif need > 0:
		loc.clues = placed
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"location:revealed",
			{
				"location_id": location_id,
				"printed_clues": printed,
				"clues_placed": placed,
			}
		)
	return {
		"ok": true,
		"location_id": location_id,
		"revealed": true,
		"already_revealed": false,
		"printed_clues": printed,
		"clues_placed": placed,
	}


## 印刷 clue value：实例 `printed_clues` ≥ 0 优先，否则查 CardRegistry（dash → -1）。
static func resolve_printed_clues(loc: LocationState) -> int:
	if loc == null:
		return -1
	if loc.printed_clues >= 0:
		return loc.printed_clues
	return CardRegistry.location_printed_clues(loc.id)
