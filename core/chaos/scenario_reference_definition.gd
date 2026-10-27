class_name ScenarioReferenceDefinition
extends RefCounted

## 冒险参考卡（Scenario Reference Card）· 按难度挂符号效果。
## 数据：`data/scenarios/<id>/reference.json`。

var scenario_id: StringName = &""
var reference_card: StringName = &""
var title: String = ""
## difficulty_key → { ChaosTokenKind-name → effect Dictionary }
var difficulties: Dictionary = {}


static func from_dict(raw: Dictionary) -> ScenarioReferenceDefinition:
	var d := ScenarioReferenceDefinition.new()
	d.scenario_id = StringName(str(raw.get("scenario_id", "")))
	d.reference_card = StringName(str(raw.get("reference_card", "")))
	d.title = str(raw.get("title", ""))
	var diffs: Variant = raw.get("difficulties", {})
	if diffs is Dictionary:
		d.difficulties = (diffs as Dictionary).duplicate(true)
	return d


func effect_for(difficulty_key: StringName, kind: AhcEnums.ChaosTokenKind) -> Dictionary:
	var band: Variant = difficulties.get(String(difficulty_key), {})
	if not band is Dictionary:
		band = difficulties.get("easy_standard", {})
	if not band is Dictionary:
		return {}
	var key := _kind_key(kind)
	if key.is_empty():
		return {}
	var effect: Variant = (band as Dictionary).get(key, {})
	if effect is Dictionary:
		return (effect as Dictionary).duplicate(true)
	return {}


static func _kind_key(kind: AhcEnums.ChaosTokenKind) -> String:
	match kind:
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
		_:
			return ""
