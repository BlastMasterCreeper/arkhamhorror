class_name LoseTemplate
extends RefCounted

## 失去特征（Gain 对偶）。落地 `LostCharacteristicStore`；禁与 lose_resources 混名。

var card_id: StringName = &""
var lifetime_kind: AhcEnums.LifetimeKind = AhcEnums.LifetimeKind.WHILE_IN_PLAY
var drawn_card_id: StringName = &""
var losses: Array[GainedCharacteristicSpec] = []
## Silver 冲突用：遭遇载荷 > 玩家载荷。
var source_kind: AhcEnums.CharacteristicSourceKind = AhcEnums.CharacteristicSourceKind.PLAYER


static func keyword_while_in_play(
	card_id: StringName,
	keyword: StringName,
	source_kind: AhcEnums.CharacteristicSourceKind = AhcEnums.CharacteristicSourceKind.PLAYER
) -> LoseTemplate:
	var t := LoseTemplate.new()
	t.card_id = card_id
	t.lifetime_kind = AhcEnums.LifetimeKind.WHILE_IN_PLAY
	t.source_kind = source_kind
	t.losses.append(GainedCharacteristicSpec.keyword(keyword))
	return t


static func keyword_drawn_card_resolving(
	card_id: StringName,
	keyword: StringName,
	source_kind: AhcEnums.CharacteristicSourceKind = AhcEnums.CharacteristicSourceKind.ENCOUNTER
) -> LoseTemplate:
	var t := LoseTemplate.new()
	t.card_id = card_id
	t.drawn_card_id = card_id
	t.lifetime_kind = AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING
	t.source_kind = source_kind
	t.losses.append(GainedCharacteristicSpec.keyword(keyword))
	return t
