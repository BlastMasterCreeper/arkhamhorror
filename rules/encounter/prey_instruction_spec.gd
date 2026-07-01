class_name PreyInstructionSpec
extends RefCounted

enum CompareMode { HIGHEST, LOWEST }

var compare_mode: CompareMode = CompareMode.HIGHEST
var skill: AhcEnums.SkillType = AhcEnums.SkillType.WILLPOWER
var only: bool = false


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
