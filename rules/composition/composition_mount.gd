class_name CompositionMount
extends RefCounted

## 效果体装载：必须 nest 命名流程；禁止直 `composition.execute` / 直写 Store。
## 见 docs/design/19-core-2026-translation-roadmap.md §3.1 · 23-vacuum-audit.md


## 能力 / LISTENER / act-agenda 背文效果体 → nest `seq.ability.resolve`。
static func resolve_ability(
	game_ctx: GameContext,
	tree: CompositionNode,
	controller_id: StringName = &"",
	ability_id: StringName = &"",
	source_id: StringName = &""
) -> bool:
	if game_ctx == null or tree == null:
		return false
	if (
		game_ctx.sequence_catalog == null
		or not game_ctx.sequence_catalog.has_flow(&"seq.ability.resolve")
	):
		push_error("CompositionMount.resolve_ability: seq.ability.resolve missing; vacuum refused")
		return false
	var result: Dictionary = game_ctx.sequence_catalog.nest(
		game_ctx,
		&"seq.ability.resolve",
		{
			"composition": tree,
			"controller_id": controller_id,
			"ability_id": ability_id,
			"source_id": source_id,
		}
	)
	return bool(result.get("ok", false))


## Buff 创建（险境 / Hidden 等）→ nest `seq.effect.register`。
static func register_effect(
	game_ctx: GameContext,
	template: RegistrationTemplate,
	controller_id: StringName = &"",
	card_id: StringName = &""
) -> bool:
	if game_ctx == null or template == null:
		return false
	if (
		game_ctx.sequence_catalog == null
		or not game_ctx.sequence_catalog.has_flow(&"seq.effect.register")
	):
		push_error("CompositionMount.register_effect: seq.effect.register missing; vacuum refused")
		return false
	var result: Dictionary = game_ctx.sequence_catalog.nest(
		game_ctx,
		&"seq.effect.register",
		{
			"controller_id": controller_id,
			"card_id": card_id,
			"template": template,
		}
	)
	return bool(result.get("ok", false))
