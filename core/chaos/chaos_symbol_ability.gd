class_name ChaosSymbolAbility
extends RefCounted

## 隐式符号能力（OQ-04-07）：ST.3 揭示后 ST.4 发起；载荷 = modifier + 效果。


var ability_id: StringName = &""
var symbol_kind: AhcEnums.ChaosTokenKind = AhcEnums.ChaosTokenKind.SKULL
var source_card_id: StringName = &""
## 印刷能力；文本框空白时不发起。
var printed: bool = true
## int 或 { "expr": "neg_act" | "neg_act_plus_1" | ... }
var modifier: Variant = 0
var reveal_another: bool = false
## ST.4 立即效果体（无 succeed/fail 条件；如 Daniela 造成伤害）。
var immediate: Dictionary = {}
## ST.7：*If you succeed* / *If this test is successful*。
var on_success: Dictionary = {}
var on_fail: Dictionary = {}
var on_fail_by: Dictionary = {}


static func from_effect_dict(
	kind: AhcEnums.ChaosTokenKind,
	effect: Dictionary,
	source_card_id: StringName,
	ability_id: StringName
) -> ChaosSymbolAbility:
	var ab := ChaosSymbolAbility.new()
	ab.symbol_kind = kind
	ab.source_card_id = source_card_id
	ab.ability_id = ability_id
	ab.printed = true
	ab.modifier = effect.get("modifier", 0)
	ab.reveal_another = bool(effect.get("reveal_another", false))
	var imm_raw: Variant = effect.get("immediate", effect.get("body", {}))
	if imm_raw is Dictionary:
		ab.immediate = (imm_raw as Dictionary).duplicate(true)
	var ok_raw: Variant = effect.get("on_success", {})
	if ok_raw is Dictionary:
		ab.on_success = (ok_raw as Dictionary).duplicate(true)
	var fail_raw: Variant = effect.get("on_fail", {})
	if fail_raw is Dictionary:
		ab.on_fail = (fail_raw as Dictionary).duplicate(true)
	var fail_by_raw: Variant = effect.get("on_fail_by", {})
	if fail_by_raw is Dictionary:
		ab.on_fail_by = (fail_by_raw as Dictionary).duplicate(true)
	return ab


## 还原为 Applier / ST.7 注册用的效果字典。
func to_effect_dict() -> Dictionary:
	var d := {
		"modifier": modifier,
		"reveal_another": reveal_another,
	}
	if not immediate.is_empty():
		d["immediate"] = immediate.duplicate(true)
	if not on_success.is_empty():
		d["on_success"] = on_success.duplicate(true)
	if not on_fail.is_empty():
		d["on_fail"] = on_fail.duplicate(true)
	if not on_fail_by.is_empty():
		d["on_fail_by"] = on_fail_by.duplicate(true)
	return d
