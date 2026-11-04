class_name ExperienceCount
extends RefCounted

## 幕间步骤 1「Count experience」汇总。
## 共享池（胜利展示 Victory X）+ 剧本 guide ± + 个人「结算时额外经验」bonus。


## personal_bonuses: Array[Dictionary] { amount: int, source: StringName, ... }
## 或 Array[int]；亦接受已登记在 record.pending_resolution_xp_bonuses 上的条目。
static func tally(
	victory_points: int,
	guide_delta: int = 0,
	personal_bonuses: Array = [],
	prior_unspent: int = 0
) -> Dictionary:
	var personal := 0
	var sources: Array = []
	for b in personal_bonuses:
		var amt := 0
		var src: StringName = &""
		if b is Dictionary:
			amt = int((b as Dictionary).get("amount", 0))
			src = StringName(str((b as Dictionary).get("source", "")))
		elif typeof(b) == TYPE_INT:
			amt = int(b)
		else:
			continue
		personal += amt
		sources.append({"amount": amt, "source": src})
	var earned := maxi(0, victory_points) + guide_delta + personal
	## guide_delta 可为负（剧本惩罚）；earned 本场可为负再与 prior 相加时由调用方决定是否 clamp。
	## Grimoire：本场合计加入 prior unspent；此处不强制 earned≥0，但 begin 窗常用 maxi(0, earned)。
	return {
		"victory_points": victory_points,
		"guide_delta": guide_delta,
		"personal_bonus": personal,
		"personal_sources": sources,
		"earned_this_scenario": earned,
		"prior_unspent": prior_unspent,
		"unspent_after_count": prior_unspent + earned,
	}


## 从 GameStateStore 胜利展示求和（遇敌/地点/玩家牌 Victory X，如 02111 Delve）。
static func victory_points_from_state(state: GameStateStore) -> int:
	if state == null:
		return 0
	return state.total_victory_points()


## 个人 bonus 条目（06160 / Charon's Obol 等「When earning experience…」）。
static func bonus(amount: int, source: StringName = &"") -> Dictionary:
	return {"amount": amount, "source": source}
