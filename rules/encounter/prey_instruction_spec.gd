class_name PreyInstructionSpec
extends RefCounted

enum CompareMode { HIGHEST, LOWEST }
enum ValueKind { SKILL, RESOURCES }

var compare_mode: CompareMode = CompareMode.HIGHEST
var value_kind: ValueKind = ValueKind.SKILL
var skill: AhcEnums.SkillType = AhcEnums.SkillType.WILLPOWER
var investigator_title_only: String = ""


static func highest(skill: AhcEnums.SkillType) -> PreyInstructionSpec:
	var spec := PreyInstructionSpec.new()
	spec.compare_mode = CompareMode.HIGHEST
	spec.skill = skill
	return spec


static func lowest(skill: AhcEnums.SkillType) -> PreyInstructionSpec:
	var spec := PreyInstructionSpec.new()
	spec.compare_mode = CompareMode.LOWEST
	spec.skill = skill
	return spec


static func most_resources() -> PreyInstructionSpec:
	var spec := PreyInstructionSpec.new()
	spec.compare_mode = CompareMode.HIGHEST
	spec.value_kind = ValueKind.RESOURCES
	return spec


static func fewest_resources() -> PreyInstructionSpec:
	var spec := PreyInstructionSpec.new()
	spec.compare_mode = CompareMode.LOWEST
	spec.value_kind = ValueKind.RESOURCES
	return spec


static func investigator_only(title: String) -> PreyInstructionSpec:
	var spec := PreyInstructionSpec.new()
	spec.investigator_title_only = title
	return spec
