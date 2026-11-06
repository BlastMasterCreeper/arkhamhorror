class_name UniqueTitle
extends RefCounted

## 独特（Unique）：**可挂载特征**（与 Victory 同属 CharacteristicMount），**不是关键词**。
## 本类：印刷/标题检测 + 同名查询；武装标记由 CharacteristicMount 挂载。
## Grimoire：同名（by title）至多一场一份；打出/进场前拒绝。
## 遭遇独特 vs 玩家同名冲突（进场同时弃玩家卡）另案，不在本查询。


static func is_unique(definition_id: StringName) -> bool:
	if definition_id == &"":
		return false
	var data: Dictionary = CardRegistry.definition_data(definition_id)
	if bool(data.get("is_unique", false)):
		return true
	var title := str(data.get("title", ""))
	return title_marks_unique(title)


static func title_marks_unique(title: String) -> bool:
	var t := title.strip_edges()
	if t.is_empty():
		return false
	var lower := t.to_lower()
	return lower.begins_with("[unique]") or lower.begins_with("★")


## 用于同名比较：去掉 `[unique]` / 星标前缀后的标题正文。
static func comparable_title(definition_id: StringName) -> String:
	var raw := CardRegistry.title(definition_id)
	return strip_unique_marker(raw)


static func strip_unique_marker(title: String) -> String:
	var t := title.strip_edges()
	var lower := t.to_lower()
	if lower.begins_with("[unique]"):
		return t.substr(8).strip_edges()
	if t.begins_with("★"):
		return _strip_star(t)
	return t


static func _strip_star(title: String) -> String:
	var i := 0
	while i < title.length() and str(title[i]) == "★":
		i += 1
	return title.substr(i).strip_edges()


## 场上是否已有同名独特卡（任意控制器）。印刷 ∪ 挂载独特特征。
static func unique_title_already_in_play(
	game_ctx: GameContext,
	definition_id: StringName,
	exclude_card_id: StringName = &""
) -> bool:
	if game_ctx == null or game_ctx.state == null or not is_unique(definition_id):
		return false
	var want := comparable_title(definition_id)
	if want.is_empty():
		return false
	for card_id in game_ctx.state.registry.all_card_ids():
		if card_id == exclude_card_id:
			continue
		var card := game_ctx.state.registry.get_card(card_id)
		if card == null or not ZoneMoveFlow.zone_is_in_play(card.zone):
			continue
		if not CharacteristicMount.has_effective_unique(game_ctx, card_id):
			continue
		if comparable_title(card.id.definition_id) == want:
			return true
	return false
