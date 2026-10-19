class_name InvestigatorState
extends RefCounted

var id: StringName = &""
var definition_id: StringName = &""
## 调查员卡面名；Prey (Name only) 等指令过滤用。
var display_name: String = ""
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
## 印刷生命 / 神智（伤恐常态击败检测）；0 = 未设置（不因伤恐自动击败）。
var health: int = 0
var sanity: int = 0
var clues_on_card: int = 0
var actions_remaining: int = 0
var actions_bonus_next_turn: int = 0
var actions_penalty_next_turn: int = 0
var eliminated: bool = false
var resigned: bool = false
var physical_trauma: int = 0
var mental_trauma: int = 0
var is_active_turn: bool = false
## 印刷文本框视为空白（Grimoire Blank）；印刷 Elder Sign 等不发起。
var text_box_blank: bool = false
## 隐式符号能力（主要是 Elder Sign）；ST.4 由 ScenarioReferenceApplier 发起。
var symbol_abilities: Array = []


## 当前可发起的符号能力（空白时跳过 printed）。
func active_symbol_ability(kind: AhcEnums.ChaosTokenKind) -> ChaosSymbolAbility:
	for raw in symbol_abilities:
		var ab: ChaosSymbolAbility = raw as ChaosSymbolAbility
		if ab == null or ab.symbol_kind != kind:
			continue
		if ab.printed and text_box_blank:
			continue
		return ab
	return null


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
