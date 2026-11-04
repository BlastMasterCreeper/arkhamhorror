class_name XpCostCalculator
extends RefCounted

## 购卡 / 升级 XP 公式 + 可注入修饰器（DtRH 等）。

const KIND_NEW_CARD := &"NEW_CARD"
const KIND_UPGRADE := &"UPGRADE"


## modifiers: Array[Dictionary | Object]，实现 adjust_new_card / adjust_upgrade。
static func cost_new_card(card: DeckCardView, modifiers: Array = []) -> int:
	if card == null:
		return 0
	var printed := card.level
	var raw := printed * 2 if card.exceptional else printed
	## FAQ 1.8：购新卡至少 1。
	var base := maxi(1, raw)
	return _apply_new_mods(base, card, modifiers)


## OQ-11-10 暂定：Exceptional 换级按加倍后的印刷费用作差 ≡ 2*(new−old)。
static func cost_upgrade(target: DeckCardView, source: DeckCardView, modifiers: Array = []) -> int:
	if target == null or source == null:
		return 0
	var diff := target.level - source.level
	if diff < 0:
		diff = 0
	var base := diff * 2 if target.exceptional else diff
	return _apply_upgrade_mods(base, target, source, modifiers)


static func _apply_new_mods(base: int, card: DeckCardView, modifiers: Array) -> int:
	var xp := base
	for m in modifiers:
		if m is Dictionary and (m as Dictionary).has("adjust_new_card"):
			xp = int((m as Dictionary)["adjust_new_card"].call(xp, card))
		elif typeof(m) == TYPE_OBJECT and m.has_method("adjust_new_card"):
			xp = int(m.adjust_new_card(xp, card))
	return maxi(0, xp)


static func _apply_upgrade_mods(
	base: int, target: DeckCardView, source: DeckCardView, modifiers: Array
) -> int:
	var xp := base
	for m in modifiers:
		if m is Dictionary and (m as Dictionary).has("adjust_upgrade"):
			xp = int((m as Dictionary)["adjust_upgrade"].call(xp, target, source))
		elif typeof(m) == TYPE_OBJECT and m.has_method("adjust_upgrade"):
			xp = int(m.adjust_upgrade(xp, target, source))
	return maxi(0, xp)


## Down the Rabbit Hole 风格：购新卡 +1；升级 −1（次数由 upgrade_charges 控制）。
static func modifier_dtrh(upgrade_charges: int = 2) -> RefCounted:
	return _DtRhModifier.new(upgrade_charges)


## 内部修饰器对象（避免多行 lambda 解析坑）。
class _DtRhModifier extends RefCounted:
	var upgrade_left: int = 2

	func _init(charges: int = 2) -> void:
		upgrade_left = charges

	func adjust_new_card(xp: int, _card: DeckCardView) -> int:
		return xp + 1

	func adjust_upgrade(xp: int, _t: DeckCardView, _s: DeckCardView) -> int:
		if upgrade_left <= 0:
			return xp
		upgrade_left -= 1
		return maxi(0, xp - 1)
