class_name SkillTestIfRevealed
extends RefCounted

## 将编译期 if_revealed 规格挂到 SkillTestContext（紧贴揭示 + any 自肃 / each 不自肃）。


static func register_specs(
	test: SkillTestContext,
	game_ctx: GameContext,
	specs: Array
) -> void:
	if test == null or specs.is_empty():
		return
	for raw in specs:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var spec: Dictionary = raw
		var body: CompositionNode = spec.get("body") as CompositionNode
		if body == null:
			continue
		var kinds: Array = []
		var kinds_raw: Variant = spec.get("kinds", [])
		if kinds_raw is Array:
			for k in kinds_raw as Array:
				kinds.append(int(k))
		elif spec.has("kind"):
			kinds.append(int(spec.get("kind", -1)))
		if kinds.is_empty():
			continue
		var mode: StringName = spec.get("mode", &"any")
		var entry := {
			"kinds": kinds,
			"mode": mode,
			"fired": false,
			"on_match": _make_callback(game_ctx, body),
		}
		test.if_revealed_watchers.append(entry)


static func _make_callback(game_ctx: GameContext, body: CompositionNode) -> Callable:
	return func(ctx: SkillTestContext, _kind: int, _n: int) -> void:
		if game_ctx == null or body == null:
			return
		var inv := ctx.performing_investigator if ctx != null else &""
		CompositionMount.resolve_ability(game_ctx, body, inv)


static func kind_from_token_key(key: String) -> int:
	match key.strip_edges().to_lower().replace("[", "").replace("]", ""):
		"skull":
			return int(AhcEnums.ChaosTokenKind.SKULL)
		"cultist":
			return int(AhcEnums.ChaosTokenKind.CULTIST)
		"tablet":
			return int(AhcEnums.ChaosTokenKind.TABLET)
		"elder_thing", "elderthing":
			return int(AhcEnums.ChaosTokenKind.ELDER_THING)
		"elder_sign", "eldersign":
			return int(AhcEnums.ChaosTokenKind.ELDER_SIGN)
		"auto_fail", "autofail", "auto-fail":
			return int(AhcEnums.ChaosTokenKind.AUTO_FAIL)
		"auto_success", "autosuccess":
			return int(AhcEnums.ChaosTokenKind.AUTO_SUCCESS)
		"curse":
			return int(AhcEnums.ChaosTokenKind.CURSE)
		"bless":
			return int(AhcEnums.ChaosTokenKind.BLESS)
		"frost":
			return int(AhcEnums.ChaosTokenKind.FROST)
		_:
			return -1


## 皱缩术符号表：skull / cultist / tablet / elder_thing / auto_fail。
static func shrivelling_kinds() -> Array:
	return [
		int(AhcEnums.ChaosTokenKind.SKULL),
		int(AhcEnums.ChaosTokenKind.CULTIST),
		int(AhcEnums.ChaosTokenKind.TABLET),
		int(AhcEnums.ChaosTokenKind.ELDER_THING),
		int(AhcEnums.ChaosTokenKind.AUTO_FAIL),
	]


static func specs_from_compile(
	params: Dictionary,
	bind: AbilityBindContext,
	build_composition: Callable
) -> Array:
	var out: Array = []
	var raw: Variant = params.get("if_revealed", null)
	if raw == null:
		return out
	var entries: Array = []
	if raw is Array:
		entries = raw as Array
	elif raw is Dictionary:
		entries = [raw]
	else:
		return out
	for entry_raw in entries:
		if not entry_raw is Dictionary:
			continue
		var entry: Dictionary = entry_raw
		var kinds: Array = []
		var kinds_src: Variant = entry.get("kinds", null)
		if kinds_src is Array:
			for k in kinds_src as Array:
				var ki := kind_from_token_key(str(k)) if typeof(k) == TYPE_STRING else int(k)
				if ki >= 0:
					kinds.append(ki)
		elif entry.has("kind"):
			var one: Variant = entry.get("kind")
			var ki2 := kind_from_token_key(str(one)) if typeof(one) == TYPE_STRING else int(one)
			if ki2 >= 0:
				kinds.append(ki2)
		if kinds.is_empty():
			continue
		var body_raw: Variant = entry.get("then", entry.get("body", {}))
		if not body_raw is Dictionary:
			continue
		var body_dict: Dictionary = body_raw
		var body: CompositionNode = build_composition.call(
			str(body_dict.get("template", "")),
			body_dict,
			bind
		)
		if body == null:
			continue
		var mode := StringName(str(entry.get("mode", "any")))
		if mode != &"each":
			mode = &"any"
		out.append({"kinds": kinds, "mode": mode, "body": body})
	return out
