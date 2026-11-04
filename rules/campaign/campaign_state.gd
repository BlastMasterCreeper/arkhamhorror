class_name CampaignState
extends RefCounted

## 一场剧本的持久状态（调查员记录 / Log / 难度 / 当前冒险）。

const MODE_CAMPAIGN := &"campaign"
const MODE_STANDALONE := &"standalone"
const MODE_EPIC := &"epic"

var campaign_id: StringName = &""
var mode: StringName = MODE_CAMPAIGN
var difficulty: StringName = &"easy_standard"
var log: CampaignLog = CampaignLog.new()
var investigators: Array[CampaignInvestigatorRecord] = []
## Starter Deck 2026：不抽 random basic weakness。
var use_starter_deck_no_random_weakness: bool = false
## 当前/下一场冒险 id（ScenarioSetupCatalog 键，如 spreading_flames）。
var current_scenario_id: StringName = &""
var scenarios_completed: Array[StringName] = []
## 已抽走的 basic weakness definition_id（全局池去重）。
var claimed_basic_weaknesses: Array[StringName] = []


func find_record(investigator_id: StringName) -> CampaignInvestigatorRecord:
	for r in investigators:
		if r.investigator_id == investigator_id:
			return r
	return null


func remove_record(investigator_id: StringName) -> bool:
	for i in investigators.size():
		if investigators[i].investigator_id == investigator_id:
			investigators.remove_at(i)
			return true
	return false
