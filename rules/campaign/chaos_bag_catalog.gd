class_name ChaosBagCatalog
extends RefCounted

## 剧本/冒险混沌袋配方（Campaign Guide「Assemble the campaign chaos bag」）。
## 四档难度：easy / standard / hard / expert。
## 参考卡两面：easy_standard ← easy|standard；hard_expert ← hard|expert。

const BRETHREN_OF_ASH: StringName = &"brethren_of_ash"
const PATH_BRETHREN := "res://data/campaigns/brethren_of_ash/chaos_bag.json"

static var _cache: Dictionary = {} ## bag_id → parsed JSON


static func normalize_bag_difficulty(difficulty: StringName) -> StringName:
	var d := String(difficulty).to_lower()
	match d:
		"easy":
			return &"easy"
		"standard":
			return &"standard"
		"hard":
			return &"hard"
		"expert":
			return &"expert"
		"easy_standard":
			## 参考卡合并带：袋默认按 Standard（挑战档）。
			return &"standard"
		"hard_expert":
			return &"hard"
		_:
			return &"standard"


static func reference_band(difficulty: StringName) -> StringName:
	var bag_diff := normalize_bag_difficulty(difficulty)
	match bag_diff:
		&"easy", &"standard":
			return &"easy_standard"
		&"hard", &"expert":
			return &"hard_expert"
		_:
			return &"easy_standard"


static func bag_id_for_campaign(campaign_id: StringName) -> StringName:
	var c := String(campaign_id).to_lower()
	if c == "brethren_of_ash" or c == "core_2026" or c.begins_with("brethren"):
		return BRETHREN_OF_ASH
	return &""


static func bag_id_for_scenario(scenario_id: StringName) -> StringName:
	var data := _load(BRETHREN_OF_ASH)
	var scenarios: Array = data.get("scenarios", [])
	for s in scenarios:
		if StringName(str(s)) == scenario_id:
			return BRETHREN_OF_ASH
	return &""


static func resolve_bag_id(campaign_id: StringName, scenario_id: StringName) -> StringName:
	var from_camp := bag_id_for_campaign(campaign_id)
	if from_camp != &"":
		return from_camp
	return bag_id_for_scenario(scenario_id)


## 返回配方 token 列表（新实例，可直接装袋）。
static func build_tokens(
	bag_id: StringName,
	difficulty: StringName,
	id_prefix: StringName = &"bag"
) -> Array[ChaosToken]:
	var out: Array[ChaosToken] = []
	var data := _load(bag_id)
	if data.is_empty():
		return out
	var bag_diff := normalize_bag_difficulty(difficulty)
	var diffs: Dictionary = data.get("difficulties", {})
	var entry: Variant = diffs.get(String(bag_diff), {})
	if not entry is Dictionary:
		return out
	var nums: Array = (entry as Dictionary).get("numeric", [])
	var n := 0
	for v in nums:
		n += 1
		out.append(ChaosToken.numeric(int(v), StringName("%s_n%d" % [String(id_prefix), n])))
	var symbols: Array = data.get("symbol_tokens", [])
	## 单档可覆盖符号表；默认用顶层 symbol_tokens。
	if (entry as Dictionary).has("symbol_tokens"):
		symbols = (entry as Dictionary).get("symbol_tokens", symbols)
	var si := 0
	for raw in symbols:
		si += 1
		var kind := _parse_kind(str(raw))
		if kind < 0:
			continue
		var iid := StringName("%s_s%d" % [String(id_prefix), si])
		if kind == AhcEnums.ChaosTokenKind.AUTO_FAIL:
			out.append(ChaosToken.auto_fail(iid))
		elif kind == AhcEnums.ChaosTokenKind.NUMERIC:
			continue
		else:
			out.append(ChaosToken.symbol(kind as AhcEnums.ChaosTokenKind, 0, iid))
	return out


static func snapshot_tokens(tokens: Array) -> Array:
	var out: Array = []
	for t in tokens:
		if t is ChaosToken:
			var tok: ChaosToken = t
			out.append({"kind": _kind_key(tok.kind), "modifier": tok.modifier})
	return out


static func tokens_from_snapshot(snapshot: Array, id_prefix: StringName = &"snap") -> Array[ChaosToken]:
	var out: Array[ChaosToken] = []
	var i := 0
	for raw in snapshot:
		if not raw is Dictionary:
			continue
		i += 1
		var d: Dictionary = raw
		var kind := _parse_kind(str(d.get("kind", "")))
		if kind < 0:
			continue
		var iid := StringName("%s_%d" % [String(id_prefix), i])
		var mod := int(d.get("modifier", 0))
		if kind == AhcEnums.ChaosTokenKind.NUMERIC:
			out.append(ChaosToken.numeric(mod, iid))
		elif kind == AhcEnums.ChaosTokenKind.AUTO_FAIL:
			out.append(ChaosToken.auto_fail(iid))
		else:
			out.append(ChaosToken.symbol(kind as AhcEnums.ChaosTokenKind, mod, iid))
	return out


static func expected_size(bag_id: StringName, difficulty: StringName) -> int:
	return build_tokens(bag_id, difficulty).size()


static func _load(bag_id: StringName) -> Dictionary:
	if _cache.has(bag_id):
		return _cache[bag_id]
	var path := &""
	match bag_id:
		BRETHREN_OF_ASH:
			path = PATH_BRETHREN
		_:
			_cache[bag_id] = {}
			return {}
	if not FileAccess.file_exists(path):
		push_warning("ChaosBagCatalog: missing %s" % path)
		_cache[bag_id] = {}
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_cache[bag_id] = {}
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	var data: Dictionary = parsed if parsed is Dictionary else {}
	_cache[bag_id] = data
	return data


static func _parse_kind(key: String) -> int:
	match key.to_lower():
		"numeric", "+1", "-1":
			return AhcEnums.ChaosTokenKind.NUMERIC
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
		"bless":
			return AhcEnums.ChaosTokenKind.BLESS
		"curse":
			return AhcEnums.ChaosTokenKind.CURSE
		"frost":
			return AhcEnums.ChaosTokenKind.FROST
		_:
			return -1


static func _kind_key(kind: AhcEnums.ChaosTokenKind) -> String:
	match kind:
		AhcEnums.ChaosTokenKind.NUMERIC:
			return "numeric"
		AhcEnums.ChaosTokenKind.SKULL:
			return "skull"
		AhcEnums.ChaosTokenKind.CULTIST:
			return "cultist"
		AhcEnums.ChaosTokenKind.TABLET:
			return "tablet"
		AhcEnums.ChaosTokenKind.ELDER_THING:
			return "elder_thing"
		AhcEnums.ChaosTokenKind.ELDER_SIGN:
			return "elder_sign"
		AhcEnums.ChaosTokenKind.AUTO_FAIL:
			return "auto_fail"
		AhcEnums.ChaosTokenKind.BLESS:
			return "bless"
		AhcEnums.ChaosTokenKind.CURSE:
			return "curse"
		AhcEnums.ChaosTokenKind.FROST:
			return "frost"
		_:
			return "unknown"
