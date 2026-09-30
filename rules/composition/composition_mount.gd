class_name CompositionMount
extends RefCounted

## 效果体装载：优先 nest 命名流程，禁止直 `composition.execute` 真空。
## 见 docs/design/19-core-2026-translation-roadmap.md §3.1


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
		game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(&"seq.ability.resolve")
	):
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
	if game_ctx.composition != null:
		game_ctx.composition.execute(tree)
		return true
	return false


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
		game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(&"seq.effect.register")
	):
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
	if game_ctx.registrations != null:
		game_ctx.registrations.register(template)
		return true
	return false
