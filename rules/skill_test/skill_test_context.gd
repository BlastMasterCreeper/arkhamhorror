class_name SkillTestContext
extends RefCounted

var id: StringName = &""
var performing_investigator: StringName = &""
var skill: AhcEnums.SkillType = AhcEnums.SkillType.WILLPOWER
var difficulty: int = 0
var committed: Array[CommittedCard] = []
var revealed_tokens: Array[ChaosToken] = []
## 审计镜像：ST.4 写入的混乱技能修正累计；真相在 Registration MODIFIER（THIS_SKILL_TEST）。
var chaos_modifier: int = 0
var chaos_modifier_reg_ids: Array[StringName] = []
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
## *If … is revealed*：紧贴 resolved 揭示触发。
## 项：{ "kind"|"kinds", "mode": &"any"|"each", "on_match": Callable, "fired": bool }
## any（默认）= 自肃本检定至多一次；each = for-each，每枚一次、不自肃。
var if_revealed_watchers: Array[Dictionary] = []
## 最近一次揭示结算快照（测试 / 审计）。
var if_revealed_snapshot: Dictionary = {}
## ST.3「将要揭示」替换体（Olive / Grotesque Statue 等）；进入 ST.3 时消费。
var pending_reveal_replace: Array = []
## 本轮 ST.3 批在 `revealed_tokens` 中的起始下标（供 ST.4 扫本批）。
var reveal_batch_start: int = 0
## 最近一次 `ChaosRevealIntentPlanner.plan_and_reveal` 结果（测试 / 审计）。
var last_reveal_intent: Dictionary = {}
## ST.3 批 resolve 后一次性钩：{ "require_symbol": bool, "composition": CompositionNode }
var after_reveal_hooks: Array = []
