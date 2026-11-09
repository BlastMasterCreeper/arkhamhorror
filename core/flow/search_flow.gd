class_name SearchFlow
extends RefCounted

## 搜寻内核 · `seq.effect.search`。
## 在指定区域翻找（对他人不揭示）；搜了牌库须洗（整库或顶 N 皆然）；弃牌堆不洗。
## 不含：look at / find（FAQ 互不计为 Search）；拿入手/抽/结算等后续 nest。

const AREA_INVESTIGATOR_DECK := &"investigator_deck"
const AREA_INVESTIGATOR_DISCARD := &"investigator_discard"
const AREA_ENCOUNTER_DECK := &"encounter_deck"
const AREA_ENCOUNTER_DISCARD := &"encounter_discard"

const SCOPE_ENTIRE := &"entire"
const SCOPE_TOP := &"top"


static func nest_or_run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(&"seq.effect.search")
	):
		return game_ctx.sequence_catalog.nest(game_ctx, &"seq.effect.search", params)
	return run(game_ctx, params)


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	var controller := _controller(params)
	var areas := resolve_areas(params)
	if areas.is_empty():
		return {"ok": false, "error": "missing_area"}
	var scope := resolve_scope(params)
	var top_n := maxi(int(params.get("amount", 0)), 0)
	if scope == SCOPE_TOP and top_n <= 0:
		return {"ok": false, "error": "missing_top_amount"}
	var viewed: Array[StringName] = []
	var found: Array[StringName] = []
	var taken: Array[StringName] = []
	var shuffled_areas: Array[StringName] = []
	for area in areas:
		var pile := _pile_ref(game_ctx, area, controller)
		var window := _window_ids(pile, scope, top_n)
		for card_id in window:
			viewed.append(card_id)
			if _matches_filter(game_ctx, card_id, params):
				found.append(card_id)
	## 搜寻期间对控制者临时揭示；结束后未取出的牌 hide（07-primitives · Search）。
	var prev_controllers: Dictionary = {}
	if game_ctx.mutator != null and controller != &"":
		for card_id in viewed:
			var card := game_ctx.state.registry.get_card(card_id)
			if card == null:
				continue
			prev_controllers[card_id] = card.controller_id
			game_ctx.mutator.reveal_to_controller(card_id, controller)
	## 有合格对象则必须找到（Grimoire）；take 时按 take_count 取出 → limbo。
	var take_count := int(params.get("take_count", 0))
	if take_count > 0 and not found.is_empty() and game_ctx.mutator != null:
		var n := mini(take_count, found.size())
		for i in n:
			var card_id: StringName = found[i]
			if game_ctx.mutator.enter_limbo(card_id, controller):
				taken.append(card_id)
	## 未取出：恢复未知 + 原 controller（搜寻不改库内牌归属）。
	if game_ctx.mutator != null:
		for card_id in viewed:
			if taken.has(card_id):
				continue
			game_ctx.mutator.hide_from_all(card_id)
			var rest := game_ctx.state.registry.get_card(card_id)
			if rest != null and prev_controllers.has(card_id):
				rest.controller_id = prev_controllers[card_id] as StringName
	## 搜了牌库 → 洗该库（整库 / 顶 N 皆然；弃牌堆不洗）。
	for area in areas:
		if area == AREA_INVESTIGATOR_DECK or area == AREA_ENCOUNTER_DECK:
			if _shuffle_deck_area(game_ctx, area, controller):
				shuffled_areas.append(area)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"effect:search",
			{
				"controller": controller,
				"areas": areas,
				"scope": scope,
				"viewed": viewed.size(),
				"found": found.size(),
				"taken": taken.size(),
				"shuffled": shuffled_areas,
			}
		)
	return {
		"ok": true,
		"controller_id": controller,
		"areas": areas,
		"scope": scope,
		"viewed": viewed,
		"found": found,
		"taken": taken,
		"shuffled": not shuffled_areas.is_empty(),
		"shuffled_areas": shuffled_areas,
		"changed": not taken.is_empty() or not shuffled_areas.is_empty() or not viewed.is_empty(),
	}


static func resolve_areas(params: Dictionary) -> Array[StringName]:
	var out: Array[StringName] = []
	var single: StringName = params.get("area", &"") as StringName
	## 便捷别名：遭遇库+弃牌堆。
	if (
		single == &"encounter_deck_and_discard"
		or bool(params.get("include_encounter_discard", false))
	):
		out.append(AREA_ENCOUNTER_DECK)
		out.append(AREA_ENCOUNTER_DISCARD)
		return out
	var raw: Variant = params.get("areas", null)
	if raw is Array:
		for a in raw as Array:
			var area := a as StringName
			if area != &"" and not out.has(area):
				out.append(area)
	if single != &"" and not out.has(single):
		out.append(single)
	return out


static func resolve_scope(params: Dictionary) -> StringName:
	var explicit: StringName = params.get("scope", &"") as StringName
	if explicit == SCOPE_ENTIRE or explicit == SCOPE_TOP:
		return explicit
	if int(params.get("amount", 0)) > 0:
		return SCOPE_TOP
	return SCOPE_ENTIRE


static func _controller(params: Dictionary) -> StringName:
	return params.get(
		"controller_id",
		params.get("investigator_id", params.get("inv_id", &""))
	) as StringName


static func _pile_ref(
	game_ctx: GameContext,
	area: StringName,
	controller: StringName
) -> Array:
	var missing: Array = []
	match area:
		AREA_ENCOUNTER_DECK:
			return game_ctx.state.encounter_deck
		AREA_ENCOUNTER_DISCARD:
			return game_ctx.state.encounter_discard
		AREA_INVESTIGATOR_DECK:
			var inv := game_ctx.state.registry.get_investigator(controller)
			return inv.deck if inv != null else missing
		AREA_INVESTIGATOR_DISCARD:
			var inv_d := game_ctx.state.registry.get_investigator(controller)
			return inv_d.discard if inv_d != null else missing
	return missing


static func _window_ids(pile: Array, scope: StringName, top_n: int) -> Array[StringName]:
	var out: Array[StringName] = []
	if pile.is_empty():
		return out
	if scope == SCOPE_TOP:
		var n := mini(top_n, pile.size())
		for i in n:
			out.append(pile[i] as StringName)
		return out
	for card_id in pile:
		out.append(card_id as StringName)
	return out


static func _matches_filter(
	game_ctx: GameContext,
	card_id: StringName,
	params: Dictionary
) -> bool:
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return false
	var def_id := card.id.definition_id
	var want_def: StringName = params.get("definition_id", &"") as StringName
	if want_def != &"" and def_id != want_def:
		return false
	var want_type: StringName = params.get("card_type", &"") as StringName
	if want_type != &"":
		var data := CardRegistry.definition_data(def_id)
		var ctype: StringName = data.get("card_type", &"") as StringName
		if ctype != want_type:
			return false
	var want_trait: StringName = params.get("trait", &"") as StringName
	if want_trait != &"":
		var traits: Array = CardRegistry.definition_data(def_id).get("traits", [])
		if not traits.has(want_trait) and not traits.has(str(want_trait)):
			return false
	## 无过滤条件时：整窗皆「合格」（供 take / 义务找到语义由调用方收窄）。
	return true


static func _shuffle_deck_area(
	game_ctx: GameContext,
	area: StringName,
	controller: StringName
) -> bool:
	var pile := _pile_ref(game_ctx, area, controller)
	if pile.is_empty():
		return false
	## 仅打乱当前库内剩余牌（已取出者不在库中）。
	pile.shuffle()
	return true
