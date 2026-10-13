class_name RulesConfig
extends RefCounted

## 默认 DISABLED：冲突须由完备规则栈 resolve；见 docs/00-architecture-overview.md §6。
var grim_rule_mode: AhcEnums.GrimRuleMode = AhcEnums.GrimRuleMode.DISABLED
var player_window_auto_close_ms: int = 0
## enter_hand 时点显现顺序；设计师裁定前保持默认 SOURCE_ORDER。
var enter_hand_timing: EnterHandTimingPolicy = EnterHandTimingPolicy.new()
## 非空时在 SETUP_11/12 从内置表安装 act/agenda；见 ScenarioSetupCatalog。
var setup_scenario_id: StringName = &""
## 显式 definition_id 列表（deck 自上而下顺序）；setup_scenario_id 非空时被忽略。
var setup_act_definition_ids: Array = []
var setup_agenda_definition_ids: Array = []
