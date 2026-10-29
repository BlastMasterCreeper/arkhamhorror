class_name GainTemplate
extends RefCounted

## Gain 特征授予模板（不是 Buff）。落地 `GainedCharacteristicStore`。

var card_id: StringName = &""
var lifetime_kind: AhcEnums.LifetimeKind = AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING
var drawn_card_id: StringName = &""
var gains: Array[GainedCharacteristicSpec] = []
## 衍生Registration 载荷 的 RegistrationTemplate（可选；Register 进 RegistrationStore 后绑 derived）。
var derive_buff_templates: Array[RegistrationTemplate] = []


static func keyword_drawn_card_resolving(
	card_id: StringName,
	keyword: StringName
) -> GainTemplate:
	var t := GainTemplate.new()
	t.card_id = card_id
	t.drawn_card_id = card_id
	t.lifetime_kind = AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING
	t.gains.append(GainedCharacteristicSpec.keyword(keyword))
	return t
