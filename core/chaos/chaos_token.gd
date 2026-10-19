class_name ChaosToken
extends RefCounted

var kind: AhcEnums.ChaosTokenKind = AhcEnums.ChaosTokenKind.NUMERIC
var modifier: int = 0
var reveal_another: bool = false
var instance_id: StringName = &""


static func numeric(value: int, instance_id: StringName = &"") -> ChaosToken:
	var t := ChaosToken.new()
	t.kind = AhcEnums.ChaosTokenKind.NUMERIC
	t.modifier = value
	t.instance_id = instance_id
	return t


static func auto_fail(instance_id: StringName = &"") -> ChaosToken:
	var t := ChaosToken.new()
	t.kind = AhcEnums.ChaosTokenKind.AUTO_FAIL
	t.instance_id = instance_id
	return t


static func with_reveal_another(kind: AhcEnums.ChaosTokenKind, modifier: int = 0) -> ChaosToken:
	var t := ChaosToken.new()
	t.kind = kind
	t.modifier = modifier
	t.reveal_another = true
	return t


static func symbol(
	kind: AhcEnums.ChaosTokenKind,
	modifier: int = 0,
	instance_id: StringName = &""
) -> ChaosToken:
	var t := ChaosToken.new()
	t.kind = kind
	t.modifier = modifier
	t.instance_id = instance_id
	return t


## 卡面「token with a symbol」= 非数字标记（含 auto-fail / elder sign / curse…）。
func is_symbol_token() -> bool:
	return kind != AhcEnums.ChaosTokenKind.NUMERIC
