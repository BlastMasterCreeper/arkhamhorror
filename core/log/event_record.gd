class_name EventRecord
extends RefCounted

var seq: int = 0
var timestamp_ms: int = 0
var kind: AhcEnums.EventRecordKind = AhcEnums.EventRecordKind.SYSTEM
var framework_step: AhcEnums.FrameworkStep = AhcEnums.FrameworkStep.SETUP_01_CHOOSE_INVESTIGATORS
var skill_test_step: AhcEnums.SkillTestStep = AhcEnums.SkillTestStep.ST_1_BEGIN
var initiation_step: AhcEnums.InitiationStep = AhcEnums.InitiationStep.INIT_PRE_RESTRICTIONS
var payload: Dictionary = {}
var state_hash: String = ""
