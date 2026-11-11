class_name RuleMount
extends RefCounted

## 固定规则在游戏创建时挂上。之后按槽消费，开火体由 KeywordEffects 解释。


const SUBJECT: StringName = &"rules"


static func mount_builtin(game_ctx: GameContext) -> void:
	if game_ctx == null:
		return
	var armed := {}
	for profile in RuleProfileTable.all_profiles():
		armed[profile.keyword] = true
	game_ctx.mounted_rules = armed


static func is_armed(game_ctx: GameContext, rule_id: StringName) -> bool:
	if game_ctx == null or rule_id == &"":
		return false
	return bool(game_ctx.mounted_rules.get(rule_id, false))


static func consume_at(
	game_ctx: GameContext,
	slot: StringName,
	facts: Dictionary = {}
) -> Dictionary:
	var merged := {"ok": true, "attacks": 0, "redirected": false}
	if game_ctx == null:
		return merged
	var catalog := game_ctx.sequence_catalog
	for profile in RuleProfileTable.profiles_for_slot(slot):
		if not is_armed(game_ctx, profile.keyword):
			continue
		var payload := facts.duplicate()
		if not payload.has("card_id"):
			payload["card_id"] = payload.get("enemy_id", &"")
		if not KeywordEffects.matches(game_ctx, profile.keyword, payload):
			continue
		if catalog == null or profile.consume_flow_id == &"" or not catalog.has_flow(profile.consume_flow_id):
			continue
		var nested: Dictionary = catalog.nest(game_ctx, profile.consume_flow_id, payload)
		merged["ok"] = bool(nested.get("ok", true)) and bool(merged["ok"])
		merged["attacks"] = int(merged["attacks"]) + int(nested.get("attacks", 0))
		if bool(nested.get("redirected", false)):
			merged["redirected"] = true
			merged["target"] = nested.get("target", &"")
			merged["damage"] = int(nested.get("damage", 0))
	return merged
