class_name RuleProfileTable
extends RefCounted

## 建局即挂载的固定规则。规格与关键词同一语言（KeywordProfile.effect_*）。
## 解释器是 KeywordEffects；本表不写流程体。


const SLOT_AOO: StringName = &"AOO"
const SLOT_FIGHT_FAIL: StringName = &"FIGHT_FAIL"

const RULE_OPPORTUNITY: StringName = &"opportunity_attack"
const RULE_FIGHT_FAIL: StringName = &"fight_fail_redirect"


static func all_profiles() -> Array[KeywordProfile]:
	return _all()


static func profile_for(rule_id: StringName) -> KeywordProfile:
	for profile in _all():
		if profile.keyword == rule_id:
			return profile
	return null


static func profiles_for_slot(slot: StringName) -> Array[KeywordProfile]:
	var matched: Array[KeywordProfile] = []
	for profile in _all():
		if profile.consume_slot == slot:
			matched.append(profile)
	matched.sort_custom(func(a: KeywordProfile, b: KeywordProfile) -> bool:
		return a.fire_priority < b.fire_priority
	)
	return matched


## 行动类型是否会借机。读规格上的 exempt_actions，不另写触发器。
static func provokes_for_types(action_types: Array) -> bool:
	var profile := profile_for(RULE_OPPORTUNITY)
	if profile == null:
		return true
	var exempt: Array = profile.effect_when.get("exempt_actions", [])
	if action_types.is_empty():
		return true
	for raw in action_types:
		var kind := int(raw)
		for item in exempt:
			if int(item) == kind:
				return false
	return true


static func _all() -> Array[KeywordProfile]:
	var profiles: Array[KeywordProfile] = []
	var opportunity := KeywordProfile.new()
	opportunity.keyword = RULE_OPPORTUNITY
	opportunity.buff_type = KeywordProfileTable.BUFF_LISTENER
	opportunity.consume_slot = SLOT_AOO
	opportunity.consume_flow_id = &"seq.rule.opportunity_attack"
	opportunity.effect_flow_id = &"seq.effect.opportunity_attacks"
	opportunity.effect_params = {"investigator_id": "$investigator_id"}
	opportunity.effect_when = {
		"exempt_actions": [
			AhcEnums.ActionType.FIGHT,
			AhcEnums.ActionType.EVADE,
			AhcEnums.ActionType.PARLEY,
			AhcEnums.ActionType.RESIGN,
		],
		"respect_skip_aoo": true,
	}
	opportunity.fire_priority = 10
	profiles.append(opportunity)
	var redirect := KeywordProfile.new()
	redirect.keyword = RULE_FIGHT_FAIL
	redirect.buff_type = KeywordProfileTable.BUFF_LISTENER
	redirect.consume_slot = SLOT_FIGHT_FAIL
	redirect.consume_flow_id = &"seq.rule.fight_fail_redirect"
	redirect.effect_flow_id = &"seq.effect.fight_fail_redirect"
	redirect.effect_params = {
		"attacker_id": "$investigator_id",
		"enemy_id": "$card_id",
		"investigator_id": "$investigator_id",
		"fight_damage": "$fight_damage",
	}
	redirect.effect_when = {
		"fight_damage_positive": true,
		"not_massive": true,
		"other_threat_holder": true,
	}
	redirect.fire_priority = 10
	profiles.append(redirect)
	return profiles
