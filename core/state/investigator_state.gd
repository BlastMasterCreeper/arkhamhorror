class_name InvestigatorState
extends RefCounted

var id: StringName = &""
var definition_id: StringName = &""
var location_id: EntityId = null
var location_tag: StringName = &""
var play_area: Array[StringName] = []
var threat_area: Array[StringName] = []
var hand: Array[StringName] = []
var deck: Array[StringName] = []
var discard: Array[StringName] = []
var skill_willpower: int = 0
var skill_intellect: int = 0
var skill_combat: int = 0
var skill_agility: int = 0
var resource_pool: int = 0
var damage_taken: int = 0
var horror_taken: int = 0
var clues_on_card: int = 0
var actions_remaining: int = 0
var actions_bonus_next_turn: int = 0
var actions_penalty_next_turn: int = 0
var eliminated: bool = false
var resigned: bool = false
var is_active_turn: bool = false


func get_skill(skill: AhcEnums.SkillType) -> int:
	match skill:
		AhcEnums.SkillType.WILLPOWER:
			return skill_willpower
		AhcEnums.SkillType.INTELLECT:
			return skill_intellect
		AhcEnums.SkillType.COMBAT:
			return skill_combat
		AhcEnums.SkillType.AGILITY:
			return skill_agility
	return 0


func shares_location_with(other: InvestigatorState) -> bool:
	if other == null:
		return false
	if location_tag != &"" and other.location_tag != &"":
		return location_tag == other.location_tag
	return (
		location_id != null
		and other.location_id != null
		and location_id.instance_id == other.location_id.instance_id
	)
