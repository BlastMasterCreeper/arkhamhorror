class_name SkillTestContext
extends RefCounted

var id: StringName = &""
var performing_investigator: StringName = &""
var skill: AhcEnums.SkillType = AhcEnums.SkillType.WILLPOWER
var difficulty: int = 0
var committed: Array[CommittedCard] = []
var revealed_tokens: Array[ChaosToken] = []
var chaos_modifier: int = 0
var modified_value: int = 0
var success: bool = false
var fail_by: int = 0
var peril: bool = false
var auto_fail: bool = false
var auto_success: bool = false
var nested_depth: int = 0
var encounter_resolution_id: StringName = &""
var pending_nested_tests: Array[SkillTestContext] = []
var target_enemy_id: StringName = &""
var on_success: Callable
var on_fail: Callable
var st7_fail_by_effects: Array[Callable] = []
var waiting_player_window: bool = false
var pending_player_window: AhcEnums.PlayerWindow = AhcEnums.PlayerWindow.PW_SKILL_TEST_AFTER_COMMIT
var current_step: AhcEnums.SkillTestStep = AhcEnums.SkillTestStep.ST_1_BEGIN
var ally_committed: bool = false
var success_applied: bool = false
var fail_applied: bool = false
