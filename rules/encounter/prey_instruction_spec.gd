class_name PreyInstructionSpec
extends RefCounted

enum CompareMode { HIGHEST, LOWEST }
enum ValueKind { SKILL, RESOURCES, CLUES }

var compare_mode: CompareMode = CompareMode.HIGHEST
var value_kind: ValueKind = ValueKind.SKILL
var skill: AhcEnums.SkillType = AhcEnums.SkillType.WILLPOWER
var investigator_title_only: String = ""
## Prey – Nearest to another [[Trait]] enemy：按与该特性敌人的路径距离取最近调查员。
var nearest_enemy_trait: StringName = &""
## 「another」：评分时排除该敌人实例（spawn 时尚无实例则传 &""）。
var exclude_self: bool = true


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


static func most_clues() -> PreyInstructionSpec:
	var spec := PreyInstructionSpec.new()
	spec.compare_mode = CompareMode.HIGHEST
	spec.value_kind = ValueKind.CLUES
	return spec


static func fewest_clues() -> PreyInstructionSpec:
	var spec := PreyInstructionSpec.new()
	spec.compare_mode = CompareMode.LOWEST
	spec.value_kind = ValueKind.CLUES
	return spec


static func investigator_only(title: String) -> PreyInstructionSpec:
	var spec := PreyInstructionSpec.new()
	spec.investigator_title_only = title
	return spec


## 在候选调查员中选「距另一带该特性的敌人」路径最近者（RR Nearest）。
static func nearest_to_enemy_trait(
	trait_name: StringName,
	exclude_self_enemy: bool = true
) -> PreyInstructionSpec:
	var spec := PreyInstructionSpec.new()
	spec.nearest_enemy_trait = trait_name
	spec.exclude_self = exclude_self_enemy
	spec.compare_mode = CompareMode.LOWEST
	return spec


func is_nearest_to_enemy_trait() -> bool:
	return nearest_enemy_trait != &""
