class_name ArkhamDbAbilityCompiler
extends RefCounted

static var _registered_definitions: Dictionary = {}


static func apply_to_registry(definition_id: StringName, src: Dictionary) -> Dictionary:
	var stats := {
		"segments": 0,
		"compiled": 0,
		"registered": 0,
	}
	var segments: Variant = src.get("ability_segments", [])
	if segments is Array:
		stats["segments"] = segments.size()
	var compiled: Variant = src.get("compiled_abilities", [])
	if not compiled is Array or compiled.is_empty():
		return stats
	stats["compiled"] = compiled.size()
	if _registered_definitions.has(definition_id):
		return stats
	for entry in compiled:
		if entry is Dictionary:
			if _register_entry(definition_id, entry as Dictionary):
				stats["registered"] += 1
	if int(stats["registered"]) > 0:
		_registered_definitions[definition_id] = true
	return stats


static func build_composition(
	template_id: String,
	params: Dictionary,
	bind: AbilityBindContext
) -> CompositionNode:
	match template_id:
		"take_horror":
			return CompositionNode.adjust_marker(
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.HORROR_TAKEN),
				int(params.get("amount", 1))
			)
		"take_damage":
			return CompositionNode.adjust_marker(
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.DAMAGE),
				int(params.get("amount", 1))
			)
		"lose_resources":
			return CompositionNode.adjust_marker(
				MarkerSlot.investigator(bind.controller_id, AhcEnums.MarkerKind.RESOURCE),
				-int(params.get("amount", 1))
			)
		"lose_all_resources":
			return CompositionNode.lose_all_resources(bind.controller_id)
		"enter_threat_area":
			return CompositionNode.enter_threat_area(bind.card_id, bind.controller_id)
		"grant_surge":
			return CompositionNode.grant_keyword(bind.card_id, &"surge")
	return null


static func _register_entry(definition_id: StringName, entry: Dictionary) -> bool:
	if str(entry.get("register_as", "")) != "revelation":
		return false
	var template_id := str(entry.get("template", ""))
	if template_id == "":
		return false
	var ability_id := StringName(str(entry.get("ability_id", "revelation:0")))
	var params := _params_from_entry(entry)
	CardRegistry.register_revelation(
		definition_id,
		ability_id,
		func(bind: AbilityBindContext) -> CompositionNode:
			return build_composition(template_id, params, bind)
	)
	return true


static func _params_from_entry(entry: Dictionary) -> Dictionary:
	var params := {}
	for key in ["amount", "direct", "trigger", "status"]:
		if entry.has(key):
			params[key] = entry[key]
	return params
