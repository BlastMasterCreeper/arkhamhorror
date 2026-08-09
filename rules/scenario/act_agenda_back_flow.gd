class_name ActAgendaBackFlow
extends RefCounted

## Act/Agenda b 面 · 编译 `back_effects` → Composition 并在翻面时结算。


static func resolve_back(
	game_ctx: GameContext,
	definition_id: StringName,
	flipped_card_id: StringName,
	is_agenda: bool,
	back_text: String = ""
) -> Dictionary:
	if game_ctx == null:
		return {"ok": false}
	if back_text.is_empty():
		back_text = CardRegistry.back_text(definition_id)
	if game_ctx.sequence_catalog != null and game_ctx.sequence_catalog.has_flow(
		&"seq.act_agenda.resolve_back"
	):
		return game_ctx.sequence_catalog.run(
			game_ctx,
			&"seq.act_agenda.resolve_back",
			{
				"definition_id": definition_id,
				"flipped_card_id": flipped_card_id,
				"is_agenda": is_agenda,
				"back_text": back_text,
			}
		)
	return _resolve_back_direct(
		game_ctx, definition_id, flipped_card_id, is_agenda, back_text
	)


static func run_resolve_back(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	return _resolve_back_direct(
		game_ctx,
		params.get("definition_id", &""),
		params.get("flipped_card_id", &""),
		bool(params.get("is_agenda", false)),
		str(params.get("back_text", ""))
	)


static func _resolve_back_direct(
	game_ctx: GameContext,
	definition_id: StringName,
	_flipped_card_id: StringName,
	_is_agenda: bool,
	back_text: String
) -> Dictionary:
	var tree := ActAgendaBackCompiler.compile(definition_id, back_text)
	var resolution_before := (
		game_ctx.state.scenario_resolution if game_ctx.state != null else -1
	)
	var executed := false
	if (
		game_ctx.composition != null
		and tree != null
		and not _seq_is_empty(tree)
	):
		game_ctx.composition.execute(tree)
		executed = true
	var resolution := resolution_before
	if game_ctx.state != null and game_ctx.state.scenario_resolution != resolution_before:
		resolution = game_ctx.state.scenario_resolution
	elif tree != null:
		resolution = _resolution_from_tree(tree, definition_id, back_text, resolution_before)
	if (
		game_ctx != null
		and game_ctx.log != null
		and not back_text.is_empty()
		and not executed
		and resolution < 0
	):
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"act_agenda:back_unhandled",
			{"definition_id": definition_id, "back_text": back_text}
		)
	return {
		"ok": true,
		"resolution": resolution,
		"executed": executed,
		"triggered_resolution": resolution > 0 and resolution != resolution_before,
	}


static func _seq_is_empty(node: CompositionNode) -> bool:
	if node == null:
		return true
	if node.kind != AhcEnums.CompositionNodeKind.SEQ:
		return false
	return node.children.is_empty()


static func _resolution_from_tree(
	tree: CompositionNode,
	definition_id: StringName,
	back_text: String,
	fallback: int
) -> int:
	if tree.kind != AhcEnums.CompositionNodeKind.SEQ:
		return fallback
	for child in tree.children:
		if child == null or child.atom_name != &"nest_scenario_resolution":
			continue
		if child.scenario_resolution > 0:
			return child.scenario_resolution
		return ScenarioResolutionParser.parse(
			CardRegistry.back_text(
				child.definition_id if child.definition_id != &"" else definition_id
			)
		)
	var parsed := ScenarioResolutionParser.parse(back_text)
	return parsed if parsed > 0 else fallback
