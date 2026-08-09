class_name BasicActionResolver
extends RefCounted

var _state: GameStateStore
var _skill_tests: SkillTestEngine


func _init(state: GameStateStore, skill_tests: SkillTestEngine) -> void:
	_state = state
	_skill_tests = skill_tests


func investigate(game_ctx: GameContext, inv_id: StringName, extra: Dictionary) -> Dictionary:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator"}
	var location_id: StringName = extra.get("location_id", inv.location_tag)
	var loc := _state.registry.get_location(location_id)
	if loc == null:
		return {"ok": false, "error": "unknown_location"}
	if inv.location_tag != loc.id:
		return {"ok": false, "error": "not_at_location"}
	var commits := _commits_from_extra(extra)
	var test := SkillTestContext.new()
	test.performing_investigator = inv_id
	test.skill = AhcEnums.SkillType.INTELLECT
	test.difficulty = loc.shroud
	var location_id_copy := location_id
	test.on_success = func(_ctx: SkillTestContext) -> void:
		_apply_discover_clue(location_id_copy, inv_id)
	var result := _skill_tests.run_full_test(test, game_ctx, commits)
	return {
		"ok": true,
		"success": result.success,
		"modified_value": result.modified_value,
		"skill_test_id": test.id,
	}


func engage(_game_ctx: GameContext, inv_id: StringName, extra: Dictionary) -> Dictionary:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator"}
	var enemy_id: StringName = extra.get("enemy_id", &"")
	var enemy := _state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "error": "unknown_enemy"}
	var target_err := _validate_engage_target(inv, enemy)
	if target_err != "":
		return {"ok": false, "error": target_err}
	_apply_engage(inv_id, enemy_id)
	return {"ok": true, "enemy_id": enemy_id}


func move(_game_ctx: GameContext, inv_id: StringName, extra: Dictionary) -> Dictionary:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator"}
	var dest_id: StringName = extra.get("destination_id", &"")
	var dest := _state.registry.get_location(dest_id)
	if dest == null:
		return {"ok": false, "error": "unknown_location"}
	var current := _state.registry.get_location(inv.location_tag)
	if current == null:
		return {"ok": false, "error": "not_at_location"}
	if not _is_connected(current, dest_id):
		return {"ok": false, "error": "not_connected"}
	inv.location_tag = dest_id
	if not dest.revealed:
		dest.revealed = true
		dest.clues = maxi(dest.clues, 1)
	return {"ok": true, "destination_id": dest_id}


func fight(game_ctx: GameContext, inv_id: StringName, extra: Dictionary) -> Dictionary:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator"}
	var enemy_id: StringName = extra.get("enemy_id", &"")
	var enemy := _state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "error": "unknown_enemy"}
	var target_err := _validate_fight_target(inv, enemy)
	if target_err != "":
		return {"ok": false, "error": target_err}
	var commits := _commits_from_extra(extra)
	var test := SkillTestContext.new()
	test.performing_investigator = inv_id
	test.target_enemy_id = enemy_id
	test.skill = AhcEnums.SkillType.COMBAT
	test.difficulty = enemy.fight
	var enemy_id_copy := enemy_id
	var inv_copy := inv_id
	test.on_success = func(_ctx: SkillTestContext) -> void:
		EnemyDefeatResolver.deal_damage(game_ctx, enemy_id_copy, 1)
	test.on_fail = func(_ctx: SkillTestContext) -> void:
		var fight_damage: int = int(extra.get("fight_damage", 1))
		FightFailRedirectResolver.try_redirect(game_ctx, inv_copy, enemy_id_copy, fight_damage)
	var result := _skill_tests.run_full_test(test, game_ctx, commits)
	return {
		"ok": true,
		"success": result.success,
		"modified_value": result.modified_value,
		"skill_test_id": test.id,
	}


func evade(game_ctx: GameContext, inv_id: StringName, extra: Dictionary) -> Dictionary:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator"}
	var enemy_id: StringName = extra.get("enemy_id", &"")
	var enemy := _state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "error": "unknown_enemy"}
	if not enemy.is_engaged_with(inv_id):
		return {"ok": false, "error": "not_engaged"}
	var commits := _commits_from_extra(extra)
	var test := SkillTestContext.new()
	test.performing_investigator = inv_id
	test.target_enemy_id = enemy_id
	test.skill = AhcEnums.SkillType.AGILITY
	test.difficulty = enemy.evade
	var enemy_id_copy := enemy_id
	test.on_success = func(_ctx: SkillTestContext) -> void:
		game_ctx.enemy.disengage(game_ctx, enemy_id_copy, true)
	var result := _skill_tests.run_full_test(test, game_ctx, commits)
	return {
		"ok": true,
		"success": result.success,
		"modified_value": result.modified_value,
		"skill_test_id": test.id,
	}


func _validate_fight_target(inv: InvestigatorState, enemy: EnemyState) -> String:
	if not enemy.is_at_location(inv.location_tag):
		return "wrong_location"
	if enemy.aloof and enemy.engaged_with == &"":
		return "aloof"
	return ""


func _is_connected(from_loc: LocationState, to_id: StringName) -> bool:
	if from_loc.id == to_id:
		return true
	return from_loc.connections.has(to_id)


func _validate_engage_target(inv: InvestigatorState, enemy: EnemyState) -> String:
	if not enemy.is_at_location(inv.location_tag):
		return "wrong_location"
	if enemy.massive:
		return "massive"
	if enemy.is_engaged_with(inv.id):
		return "already_engaged"
	return ""


func _apply_engage(inv_id: StringName, enemy_id: StringName) -> void:
	var enemy := _state.registry.get_enemy(enemy_id)
	var inv := _state.registry.get_investigator(inv_id)
	if enemy == null or inv == null:
		return
	if enemy.engaged_with != &"" and enemy.engaged_with != inv_id:
		var prev := _state.registry.get_investigator(enemy.engaged_with)
		if prev:
			prev.threat_area.erase(enemy_id)
	enemy.engaged_with = inv_id
	if not inv.threat_area.has(enemy_id):
		inv.threat_area.append(enemy_id)


func _commits_from_extra(extra: Dictionary) -> Array[CommittedCard]:
	var out: Array[CommittedCard] = []
	for item in extra.get("commits", []):
		if item is CommittedCard:
			out.append(item)
	return out


func _apply_discover_clue(location_id: StringName, inv_id: StringName) -> void:
	var loc := _state.registry.get_location(location_id)
	var inv := _state.registry.get_investigator(inv_id)
	if loc == null or inv == null:
		return
	if loc.clues <= 0:
		return
	loc.clues -= 1
	inv.clues_on_card += 1
