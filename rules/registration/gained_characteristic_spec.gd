class_name GainedCharacteristicSpec
extends RefCounted

## Grimoire *gains a characteristic* · **不是** Buff。
## 拥有记录；行为侧由 profile **衍生** MODIFIER / GATE / DIRECTIVE / LISTENER / STATUS（或 AbilityLifecycle）。

var kind: AhcEnums.GainedCharacteristicKind = AhcEnums.GainedCharacteristicKind.KEYWORD
## KEYWORD / TRAIT / ICON 的标识；ABILITY 时可为能力名或空（载荷另挂）。
var id: StringName = &""
## 文本能力 gains 时的 AbilitySpec（P1+）；只读特征留空。
var ability_spec: Variant = null


static func keyword(keyword: StringName) -> GainedCharacteristicSpec:
	var g := GainedCharacteristicSpec.new()
	g.kind = AhcEnums.GainedCharacteristicKind.KEYWORD
	g.id = keyword
	return g


static func trait_gain(trait_id: StringName) -> GainedCharacteristicSpec:
	var g := GainedCharacteristicSpec.new()
	g.kind = AhcEnums.GainedCharacteristicKind.TRAIT
	g.id = trait_id
	return g


static func icon_gain(icon_id: StringName) -> GainedCharacteristicSpec:
	var g := GainedCharacteristicSpec.new()
	g.kind = AhcEnums.GainedCharacteristicKind.ICON
	g.id = icon_id
	return g


static func ability_gain(ability: Variant, ability_id: StringName = &"") -> GainedCharacteristicSpec:
	var g := GainedCharacteristicSpec.new()
	g.kind = AhcEnums.GainedCharacteristicKind.ABILITY
	g.id = ability_id
	g.ability_spec = ability
	return g
