class_name XpCostCalculator
extends RefCounted

## 购卡 / 升级 XP 公式 + 可注入修饰器（DtRH / Arcane Research / Pelt…）。

const KIND_NEW_CARD := &"NEW_CARD"
const KIND_UPGRADE := &"UPGRADE"
## FAQ 1.18：Exile 等导致 undersize 时，L0 补牌至合法尺寸，0 XP（DtRH 不加价）。
const KIND_SIZE_REFILL := &"SIZE_REFILL"


## consume=false：报价预览不扣次数；commit 时 consume=true。
static func cost_new_card(card: DeckCardView, modifiers: Array = [], consume: bool = true) -> int:
	if card == null:
		return 0
	var printed := card.level
	var raw := printed * 2 if card.exceptional else printed
	## FAQ 1.8：购新卡至少 1。
	var base := maxi(1, raw)
	return _apply_new_mods(base, card, modifiers, consume)


## OQ-11-10 暂定：Exceptional 换级按加倍后的印刷费用作差 ≡ 2*(new−old)。
static func cost_upgrade(
	target: DeckCardView, source: DeckCardView, modifiers: Array = [], consume: bool = true
) -> int:
	if target == null or source == null:
		return 0
	var diff := target.level - source.level
	if diff < 0:
		diff = 0
	var base := diff * 2 if target.exceptional else diff
	return _apply_upgrade_mods(base, target, source, modifiers, consume)


## FAQ 1.18 size refill：L0 补牌固定 0；不跑购新卡修饰器（含 DtRH +1）。
static func cost_size_refill(card: DeckCardView) -> int:
	if card == null or card.level != 0:
		return -1
	return 0


static func _apply_new_mods(base: int, card: DeckCardView, modifiers: Array, consume: bool) -> int:
	var xp := base
	for m in modifiers:
		if typeof(m) == TYPE_OBJECT and m.has_method("adjust_new_card"):
			xp = int(m.adjust_new_card(xp, card, consume))
		elif m is Dictionary and (m as Dictionary).has("adjust_new_card"):
			xp = int((m as Dictionary)["adjust_new_card"].call(xp, card, consume))
	return maxi(0, xp)


static func _apply_upgrade_mods(
	base: int,
	target: DeckCardView,
	source: DeckCardView,
	modifiers: Array,
	consume: bool
) -> int:
	var xp := base
	for m in modifiers:
		if typeof(m) == TYPE_OBJECT and m.has_method("adjust_upgrade"):
			xp = int(m.adjust_upgrade(xp, target, source, consume))
		elif m is Dictionary and (m as Dictionary).has("adjust_upgrade"):
			xp = int((m as Dictionary)["adjust_upgrade"].call(xp, target, source, consume))
	return maxi(0, xp)


## 从窗规格组装修饰器列表（顺序：DtRH → Arcane Research → Pelt）。
## spec: { dtrh?: int charges, arcane_research?: bool|int, pelt?: int }
static func build_modifiers(spec: Dictionary) -> Array:
	var out: Array = []
	if spec.has("dtrh"):
		out.append(modifier_dtrh(int(spec.get("dtrh", 2))))
	var ar: Variant = spec.get("arcane_research", false)
	if typeof(ar) == TYPE_BOOL and bool(ar):
		out.append(modifier_arcane_research(1))
	elif typeof(ar) == TYPE_INT and int(ar) > 0:
		out.append(modifier_arcane_research(int(ar)))
	if spec.has("pelt") and int(spec.get("pelt", 0)) > 0:
		out.append(modifier_pelt(int(spec.get("pelt", 1))))
	return out


static func modifier_dtrh(upgrade_charges: int = 2) -> RefCounted:
	return _DtRhModifier.new(upgrade_charges)


static func modifier_arcane_research(charges: int = 1) -> RefCounted:
	return _ArcaneResearchModifier.new(charges)


static func modifier_pelt(charges: int = 1) -> RefCounted:
	return _PeltModifier.new(charges)


class _DtRhModifier extends RefCounted:
	var upgrade_left: int = 2

	func _init(charges: int = 2) -> void:
		upgrade_left = charges

	func adjust_new_card(xp: int, _card: DeckCardView, _consume: bool = true) -> int:
		return xp + 1

	func adjust_upgrade(xp: int, _t: DeckCardView, _s: DeckCardView, consume: bool = true) -> int:
		if upgrade_left <= 0:
			return xp
		if consume:
			upgrade_left -= 1
		return maxi(0, xp - 1)


class _ArcaneResearchModifier extends RefCounted:
	var charges_left: int = 1

	func _init(charges: int = 1) -> void:
		charges_left = charges

	func adjust_new_card(xp: int, _card: DeckCardView, _consume: bool = true) -> int:
		return xp

	func adjust_upgrade(
		xp: int, _target: DeckCardView, source: DeckCardView, consume: bool = true
	) -> int:
		if charges_left <= 0 or source == null:
			return xp
		if not source.has_any_trait([&"spell"] as Array[StringName]):
			return xp
		if consume:
			charges_left -= 1
		return maxi(0, xp - 1)


class _PeltModifier extends RefCounted:
	var charges_left: int = 1

	func _init(charges: int = 1) -> void:
		charges_left = charges

	func adjust_new_card(xp: int, _card: DeckCardView, consume: bool = true) -> int:
		if charges_left <= 0:
			return xp
		if consume:
			charges_left -= 1
		return maxi(0, xp - 1)

	func adjust_upgrade(
		xp: int, _t: DeckCardView, _s: DeckCardView, _consume: bool = true
	) -> int:
		return xp
