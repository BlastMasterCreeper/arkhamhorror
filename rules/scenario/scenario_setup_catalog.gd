class_name ScenarioSetupCatalog
extends RefCounted

## Setup 10–12 场景数据 · campaign guide / 10 §7 / 02 §6。

const SPREADING_FLAMES: StringName = &"spreading_flames"


static func resolve(config: RulesConfig) -> Dictionary:
	if config == null:
		return {"act": [], "agenda": []}
	if config.setup_scenario_id != &"":
		return _builtin(config.setup_scenario_id)
	return {
		"act": config.setup_act_definition_ids.duplicate(),
		"agenda": config.setup_agenda_definition_ids.duplicate(),
	}


static func resolve_layout(config: RulesConfig) -> Dictionary:
	if config == null or config.setup_scenario_id == &"":
		return {}
	return _builtin_layout(config.setup_scenario_id)


static func prepare_definitions(scenario_id: StringName) -> void:
	match scenario_id:
		SPREADING_FLAMES:
			ArkhamDbCardLoader.load_imported_file(
				"res://data/arkhamdb/imported/core_2026_encounter.json"
			)
			ScenarioDeckSetup.patch_spreading_flames_definitions()
		_:
			pass


static func _builtin(scenario_id: StringName) -> Dictionary:
	match scenario_id:
		SPREADING_FLAMES:
			return {
				"act": [&"12109", &"12110", &"12111", &"12112"],
				"agenda": [&"12106", &"12107", &"12108"],
			}
		_:
			push_warning("ScenarioSetupCatalog: unknown scenario_id %s" % scenario_id)
			return {"act": [], "agenda": []}


static func _builtin_layout(scenario_id: StringName) -> Dictionary:
	match scenario_id:
		SPREADING_FLAMES:
			return {
				"encounter_sets": [
					&"spreading_flames",
					&"ashen_pilgrims",
					&"bystanders",
					&"cosmic_evils",
					&"eldritch_lore",
					&"fire_ch2",
					&"hallucinations",
					&"mad_science",
					&"miskatonic_university",
				],
				"locations_in_play": [&"12113"],
				"locations_set_aside": [
					&"12116",
					&"12117",
					&"12118",
					&"12119",
					&"12120",
				],
				"starting_location": &"12113",
				"reference_card": &"12105",
				"set_aside": {
					&"12129": 5,
					&"12114": 1,
					&"12115": 1,
				},
				"location_connections": {
					&"12113": [&"12117"],
					&"12117": [&"12113", &"12116"],
					&"12116": [&"12117", &"12118", &"12120"],
					&"12118": [&"12116", &"12119"],
					&"12119": [&"12118", &"12120"],
					&"12120": [&"12116", &"12119"],
				},
			}
		_:
			push_warning("ScenarioSetupCatalog: unknown layout %s" % scenario_id)
			return {}
