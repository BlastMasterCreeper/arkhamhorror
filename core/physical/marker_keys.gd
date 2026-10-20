class_name MarkerKeys
extends RefCounted

## 物理层可数标记键（StringName）。信息层可再贴语义名。

const DAMAGE := &"DAMAGE"
const HORROR := &"HORROR"
const CLUE := &"CLUE"
const DOOM := &"DOOM"
const RESOURCE := &"RESOURCE"

const CHAOS_PREFIX := "CHAOS:"
const USE_PREFIX := "USE:"


static func use_key(use_name: StringName) -> StringName:
	return StringName("%s%s" % [USE_PREFIX, String(use_name)])


static func chaos_numeric(value: int) -> StringName:
	if value > 0:
		return StringName("%s+%d" % [CHAOS_PREFIX, value])
	return StringName("%s%d" % [CHAOS_PREFIX, value])


static func chaos_symbol(symbol: StringName) -> StringName:
	return StringName("%s%s" % [CHAOS_PREFIX, String(symbol)])


static func is_chaos(key: StringName) -> bool:
	return String(key).begins_with(CHAOS_PREFIX)


static func is_use(key: StringName) -> bool:
	return String(key).begins_with(USE_PREFIX)


static func from_chaos_token(token: ChaosToken) -> StringName:
	if token == null:
		return &""
	match token.kind:
		AhcEnums.ChaosTokenKind.NUMERIC:
			return chaos_numeric(token.modifier)
		AhcEnums.ChaosTokenKind.SKULL:
			return chaos_symbol(&"SKULL")
		AhcEnums.ChaosTokenKind.CULTIST:
			return chaos_symbol(&"CULTIST")
		AhcEnums.ChaosTokenKind.TABLET:
			return chaos_symbol(&"TABLET")
		AhcEnums.ChaosTokenKind.ELDER_THING:
			return chaos_symbol(&"ELDER_THING")
		AhcEnums.ChaosTokenKind.ELDER_SIGN:
			return chaos_symbol(&"ELDER_SIGN")
		AhcEnums.ChaosTokenKind.AUTO_FAIL:
			return chaos_symbol(&"AUTO_FAIL")
		AhcEnums.ChaosTokenKind.AUTO_SUCCESS:
			return chaos_symbol(&"AUTO_SUCCESS")
		AhcEnums.ChaosTokenKind.BLESS:
			return chaos_symbol(&"BLESS")
		AhcEnums.ChaosTokenKind.CURSE:
			return chaos_symbol(&"CURSE")
		AhcEnums.ChaosTokenKind.FROST:
			return chaos_symbol(&"FROST")
		AhcEnums.ChaosTokenKind.CAMPAIGN_CUSTOM:
			return chaos_symbol(&"CAMPAIGN_CUSTOM")
	return &""
