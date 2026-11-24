class_name GainTemplate
extends RefCounted

## Gain 特征授予模板（不是 Registration 载荷）。落地 `GainedCharacteristicStore`。

var card_id: StringName = &""
var lifetime_kind: AhcEnums.LifetimeKind = AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING
var drawn_card_id: StringName = &""
var gains: Array[GainedCharacteristicSpec] = []
## Silver 冲突用：遭遇载荷 > 玩家载荷。
var source_kind: AhcEnums.CharacteristicSourceKind = AhcEnums.CharacteristicSourceKind.ENCOUNTER
## 衍生Registration 载荷 的 RegistrationTemplate（可选；Register 进 RegistrationStore 后绑 derived）。
var derive_registration_templates: Array[RegistrationTemplate] = []


static func keyword_drawn_card_resolving(
	card_id: StringName,
	keyword: StringName,
	source_kind: AhcEnums.CharacteristicSourceKind = AhcEnums.CharacteristicSourceKind.ENCOUNTER
) -> GainTemplate:
	var t := GainTemplate.new()
	t.card_id = card_id
	t.drawn_card_id = card_id
	t.lifetime_kind = AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING
	t.source_kind = source_kind
	t.gains.append(GainedCharacteristicSpec.keyword(keyword))
	return t


static func keyword_while_in_play(
	card_id: StringName,
	keyword: StringName,
	source_kind: AhcEnums.CharacteristicSourceKind = AhcEnums.CharacteristicSourceKind.PLAYER
) -> GainTemplate:
	var t := GainTemplate.new()
	t.card_id = card_id
	t.lifetime_kind = AhcEnums.LifetimeKind.WHILE_IN_PLAY
	t.source_kind = source_kind
	t.gains.append(GainedCharacteristicSpec.keyword(keyword))
	return t
