class_name CharacteristicPossessionResolver
extends RefCounted

## 同特征 Gain vs Lose 互斥裁决（07 §3.2 / Silver）。
## 电子版同级不用 Grim：走队长默认（PI）；无交互时用 same_priority_default。

## 同优先级默认：应用 lose（不拥有）。队长显式选用时可覆盖。
enum SamePriorityDefault { APPLY_LOSE, APPLY_GAIN }

static var same_priority_default: SamePriorityDefault = SamePriorityDefault.APPLY_LOSE


static func source_rank(kind: AhcEnums.CharacteristicSourceKind) -> int:
	match kind:
		AhcEnums.CharacteristicSourceKind.ENCOUNTER:
			return 2
		AhcEnums.CharacteristicSourceKind.PLAYER:
			return 1
		_:
			return 0


static func has_effective_keyword(
	game_ctx: GameContext,
	card_id: StringName,
	definition_id: StringName,
	keyword: StringName
) -> bool:
	if keyword == &"":
		return false
	var printed := CardRegistry.has_keyword(definition_id, keyword)
	var gain_best := AhcEnums.CharacteristicSourceKind.PRINTED
	var has_gain := false
	if game_ctx != null and game_ctx.gains != null and card_id != &"":
		has_gain = game_ctx.gains.has_gained_keyword(card_id, keyword)
		if has_gain:
			gain_best = game_ctx.gains.best_source_for_keyword(card_id, keyword)
	var has_lose := false
	var lose_best := AhcEnums.CharacteristicSourceKind.PRINTED
	if game_ctx != null and game_ctx.losts != null and card_id != &"":
		has_lose = game_ctx.losts.has_lost_keyword(card_id, keyword)
		if has_lose:
			lose_best = game_ctx.losts.best_source_for_keyword(card_id, keyword)

	## 无 lose：印刷 ∪ gained（keyword 不叠份，布尔有即可）。
	if not has_lose:
		return printed or has_gain

	## 有 lose、无 gain：lose 压印刷（有效不拥有）。
	if not has_gain:
		return false

	## Gain 与 Lose 并存：Silver 比来源优先级。
	var g_rank := source_rank(gain_best)
	var l_rank := source_rank(lose_best)
	if l_rank > g_rank:
		return false
	if g_rank > l_rank:
		return true
	## 同级：队长/PI 默认（非 Grim）。
	return same_priority_default == SamePriorityDefault.APPLY_GAIN
