class_name ExperienceCount
extends RefCounted

## 幕间步骤 1「Count experience」汇总。
## 共享池（胜利展示 Victory X）+ 剧本 guide ± + 个人结算调整（可加可减）。


## personal_deltas: Array[Dictionary] { amount: int, source: StringName }
## amount > 0 = 额外获得（06160 / Obol）；amount < 0 = 减少获得（12006 Dead Ends / Hospital Debts）。
## 亦接受 Array[int]。
static func tally(
	victory_points: int,
	guide_delta: int = 0,
	personal_deltas: Array = [],
	prior_unspent: int = 0
) -> Dictionary:
	var personal := 0
	var sources: Array = []
	for b in personal_deltas:
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
	## 本场 raw 可为负（惩罚大于 VD）；加入 unspent 时本场贡献 floor 0，不掏已积未花 XP。
	var raw_earned := maxi(0, victory_points) + guide_delta + personal
	var earned := maxi(0, raw_earned)
	return {
		"victory_points": victory_points,
		"guide_delta": guide_delta,
		"personal_delta": personal,
		"personal_bonus": personal, ## 兼容旧键
		"personal_sources": sources,
		"raw_earned_this_scenario": raw_earned,
		"earned_this_scenario": earned,
		"prior_unspent": prior_unspent,
		"unspent_after_count": prior_unspent + earned,
	}


static func victory_points_from_state(state: GameStateStore) -> int:
	if state == null:
		return 0
	return state.total_victory_points()


## 个人结算调整：正=额外获得，负=减少获得（earn N fewer）。
static func delta(amount: int, source: StringName = &"") -> Dictionary:
	return {"amount": amount, "source": source}


## 兼容旧名。
static func bonus(amount: int, source: StringName = &"") -> Dictionary:
	return delta(amount, source)


static func penalty(amount: int, source: StringName = &"") -> Dictionary:
	## amount 传正数表示「少得 N」；内部存负。
	return delta(-maxi(0, amount), source)
