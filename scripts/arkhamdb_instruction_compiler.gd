class_name ArkhamDbInstructionCompiler
extends RefCounted


static func apply_instructions(out: Dictionary, src: Dictionary) -> void:
	var spawn: Variant = src.get("spawn_instruction")
	if spawn is Dictionary:
		var spawn_spec := spawn_from_dict(spawn as Dictionary)
		if spawn_spec != null:
			out["spawn_instruction"] = spawn_spec
	var prey: Variant = src.get("prey_instruction")
	if prey is Dictionary:
		var prey_spec := prey_from_dict(prey as Dictionary)
		if prey_spec != null:
			out["prey_instruction"] = prey_spec


static func spawn_from_dict(data: Dictionary) -> SpawnInstructionSpec:
	var selector := str(data.get("selector", ""))
	match selector:
		"drawer_location", "your_location":
			return SpawnInstructionSpec.at_drawer_location()
		"named_location":
			var tag := StringName(str(data.get("location_tag", "")))
			if tag == &"":
				return null
			return SpawnInstructionSpec.at_named_location(tag)
		"nearest_empty":
			return SpawnInstructionSpec.nearest_empty()
		"farthest_empty":
			return SpawnInstructionSpec.farthest_empty()
	return null


static func prey_from_dict(data: Dictionary) -> PreyInstructionSpec:
	var kind := str(data.get("kind", "skill"))
	if kind == "investigator_only":
		var title := str(data.get("investigator_title", ""))
		if title == "":
			return null
		return PreyInstructionSpec.investigator_only(title)
	var compare := str(data.get("compare", "highest"))
	if str(data.get("metric", "skill")) == "resources":
		if compare == "lowest":
			return PreyInstructionSpec.fewest_resources()
		return PreyInstructionSpec.most_resources()
	var skill := _skill_from_name(str(data.get("skill", "willpower")))
	if compare == "lowest":
		return PreyInstructionSpec.lowest(skill)
	return PreyInstructionSpec.highest(skill)


static func _skill_from_name(name: String) -> AhcEnums.SkillType:
	match name.to_lower():
		"intellect":
			return AhcEnums.SkillType.INTELLECT
		"combat":
			return AhcEnums.SkillType.COMBAT
		"agility":
			return AhcEnums.SkillType.AGILITY
		_:
			return AhcEnums.SkillType.WILLPOWER
