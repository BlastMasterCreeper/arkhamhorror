class_name SkillTestSt4Plan
extends RefCounted

## 检定 ST.4 卡面符号效果（04 §3.4）：on_symbols[kind_name] → 内联 Composition。


## StringName kind（cultist / skull / …）→ CompositionNode
var on_symbols: Dictionary = {}


static func from_compile_dict(
	entries: Dictionary,
	bind: AbilityBindContext,
	build_fn: Callable
) -> SkillTestSt4Plan:
	var plan := SkillTestSt4Plan.new()
	var symbols: Variant = entries.get("on_symbols", {})
	if not symbols is Dictionary:
		return plan
	for raw_key in (symbols as Dictionary).keys():
		var entry: Variant = (symbols as Dictionary)[raw_key]
		if entry is Dictionary and not (entry as Dictionary).is_empty():
			var entry_dict := entry as Dictionary
			var node: CompositionNode = build_fn.call(
				str(entry_dict.get("template", "")),
				entry_dict,
				bind
			)
			if node != null:
				plan.on_symbols[StringName(str(raw_key).to_lower())] = node
	return plan


func is_empty() -> bool:
	return on_symbols.is_empty()


func body_for_kind(kind: AhcEnums.ChaosTokenKind) -> CompositionNode:
	var key := kind_name(kind)
	if key == &"" or not on_symbols.has(key):
		return null
	return on_symbols[key] as CompositionNode


static func kind_name(kind: AhcEnums.ChaosTokenKind) -> StringName:
	match kind:
		AhcEnums.ChaosTokenKind.SKULL:
			return &"skull"
		AhcEnums.ChaosTokenKind.CULTIST:
			return &"cultist"
		AhcEnums.ChaosTokenKind.TABLET:
			return &"tablet"
		AhcEnums.ChaosTokenKind.ELDER_THING:
			return &"elder_thing"
		AhcEnums.ChaosTokenKind.ELDER_SIGN:
			return &"elder_sign"
		AhcEnums.ChaosTokenKind.BLESS:
			return &"bless"
		AhcEnums.ChaosTokenKind.CURSE:
			return &"curse"
		AhcEnums.ChaosTokenKind.FROST:
			return &"frost"
		_:
			return &""
