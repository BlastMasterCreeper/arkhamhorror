class_name SealSpec
extends RefCounted

## 关键词 Seal 参数（06 Domain）：打出额外费用门槛 + 进场封印序列。
## 例：Seal (Elder Sign). · Seal (0). · Seal ([cultist] or [tablet]).

const MODE_KIND := &"kind" ## 搜指定 kind（可多枚并列 → 有限期选）
const MODE_NUMERIC := &"numeric" ## 搜指定面值数字标记
const MODE_RANDOM := &"random" ## 随机一枚（少见；多见于卡面效果而非关键词）
const MODE_CHOICE := &"choice" ## 袋内候选有限期确认（kinds 过滤；空=任意）

var mode: StringName = MODE_KIND
## 允许的符号/种类；空且 mode=choice/random → 任意袋内标记。
var kinds: Array = [] ## Array[AhcEnums.ChaosTokenKind] as int
var numeric_value: int = 0
var has_numeric_value: bool = false
## 关键词 Seal 为进场额外费用；false = 仅效果体用同一 Spec。
var as_play_cost: bool = true


static func kind(token_kind: AhcEnums.ChaosTokenKind) -> SealSpec:
	var s := SealSpec.new()
	s.mode = MODE_KIND
	s.kinds = [token_kind]
	return s


static func kinds_choice(token_kinds: Array) -> SealSpec:
	var s := SealSpec.new()
	s.mode = MODE_CHOICE if token_kinds.size() != 1 else MODE_KIND
	s.kinds = token_kinds.duplicate()
	return s


static func numeric(value: int) -> SealSpec:
	var s := SealSpec.new()
	s.mode = MODE_NUMERIC
	s.numeric_value = value
	s.has_numeric_value = true
	return s


static func random_any() -> SealSpec:
	var s := SealSpec.new()
	s.mode = MODE_RANDOM
	return s


static func from_dictionary(raw: Dictionary) -> SealSpec:
	if raw == null or raw.is_empty():
		return null
	var s := SealSpec.new()
	s.as_play_cost = bool(raw.get("as_play_cost", true))
	if raw.has("numeric") or raw.has("value"):
		s.mode = MODE_NUMERIC
		s.numeric_value = int(raw.get("numeric", raw.get("value", 0)))
		s.has_numeric_value = true
		return s
	var mode_raw: StringName = StringName(str(raw.get("mode", "")))
	if mode_raw == MODE_RANDOM:
		s.mode = MODE_RANDOM
		return s
	var kind_list: Array = []
	if raw.has("kinds") and raw.get("kinds") is Array:
		for item in raw.get("kinds") as Array:
			var k := parse_kind_name(str(item))
			if k >= 0:
				kind_list.append(k)
	elif raw.has("kind"):
		var k2 := parse_kind_name(str(raw.get("kind", "")))
		if k2 >= 0:
			kind_list.append(k2)
	s.kinds = kind_list
	if mode_raw == MODE_CHOICE or kind_list.size() > 1:
		s.mode = MODE_CHOICE
	elif mode_raw == MODE_KIND or kind_list.size() == 1:
		s.mode = MODE_KIND
	elif mode_raw != &"":
		s.mode = mode_raw
	else:
		s.mode = MODE_RANDOM
	return s


## 解析 "elder_sign" / "Elder Sign" / "skull" / "[skull]" 等。
static func parse_kind_name(name: String) -> int:
	var n := name.strip_edges().to_lower()
	n = n.replace("[", "").replace("]", "").replace("_", " ").strip_edges()
	n = n.replace(" ", "_")
	match n:
		"skull":
			return AhcEnums.ChaosTokenKind.SKULL
		"cultist":
			return AhcEnums.ChaosTokenKind.CULTIST
		"tablet":
			return AhcEnums.ChaosTokenKind.TABLET
		"elder_thing", "elderthing":
			return AhcEnums.ChaosTokenKind.ELDER_THING
		"elder_sign", "eldersign":
			return AhcEnums.ChaosTokenKind.ELDER_SIGN
		"auto_fail", "autofail", "auto-fail":
			return AhcEnums.ChaosTokenKind.AUTO_FAIL
		"auto_success", "autosuccess":
			return AhcEnums.ChaosTokenKind.AUTO_SUCCESS
		"bless":
			return AhcEnums.ChaosTokenKind.BLESS
		"curse":
			return AhcEnums.ChaosTokenKind.CURSE
		"frost":
			return AhcEnums.ChaosTokenKind.FROST
		_:
			return -1


## 从卡面 `Seal (…)` 括号解析。
static func parse_from_text(text: String) -> SealSpec:
	if text.is_empty():
		return null
	var re := RegEx.new()
	if re.compile("(?i)Seal\\s*\\(([^)]+)\\)") != OK:
		return null
	var m := re.search(text)
	if m == null:
		return null
	var inner := m.get_string(1).strip_edges()
	if inner.is_empty():
		return random_any()
	## 纯数字 / +N / -N → numeric
	var num_re := RegEx.new()
	if num_re.compile("^\\+?-?\\d+$") == OK:
		var nm := num_re.search(inner)
		if nm != null:
			return numeric(int(inner))
	## A or B or C
	var parts: PackedStringArray = inner.split(" or ")
	if parts.size() == 1:
		parts = inner.split("/")
	var kind_list: Array = []
	for part in parts:
		var k := parse_kind_name(str(part))
		if k >= 0:
			kind_list.append(k)
	if kind_list.is_empty():
		return null
	if kind_list.size() == 1:
		return kind(kind_list[0] as AhcEnums.ChaosTokenKind)
	return kinds_choice(kind_list)
