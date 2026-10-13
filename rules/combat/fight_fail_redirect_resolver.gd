class_name FightFailRedirectResolver
extends RefCounted

## Fight 失败转嫁 · Grimoire *Fight Action* / 08 §6.6。
##
## 攻击检定失败时，若目标位于 **另一名且仅一名** 调查员威胁区，则本攻击本应造成的
## 伤害改由该调查员承受（默认 1，可由武器等修改后传入 `fight_damage`）。
## 庞大敌人不进威胁区 → 不转嫁。


static func try_redirect(
	game_ctx: GameContext,
	attacker_id: StringName,
	enemy_id: StringName,
	fight_damage: int = 1
) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or enemy_id == &"" or attacker_id == &"":
		return {"ok": true, "redirected": false}
	if fight_damage <= 0:
		return {"ok": true, "redirected": false}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null or enemy.massive:
		return {"ok": true, "redirected": false}
	var holder_id := _threat_area_holder(game_ctx, enemy_id, attacker_id)
	if holder_id == &"":
		return {"ok": true, "redirected": false}
	var holder := game_ctx.state.registry.get_investigator(holder_id)
	if holder == null or holder.eliminated:
		return {"ok": true, "redirected": false}
	holder.damage_taken += fight_damage
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.DAMAGE,
			"fight_fail_redirect",
			{
				"attacker": attacker_id,
				"enemy_id": enemy_id,
				"target": holder_id,
				"damage": fight_damage,
			}
		)
	return {"ok": true, "redirected": true, "target": holder_id, "damage": fight_damage}


static func _threat_area_holder(
	game_ctx: GameContext,
	enemy_id: StringName,
	attacker_id: StringName
) -> StringName:
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return &""
	var holder_id := enemy.engaged_with
	if holder_id == &"" or holder_id == attacker_id:
		return &""
	var holder := game_ctx.state.registry.get_investigator(holder_id)
	if holder == null or not holder.threat_area.has(enemy_id):
		return &""
	return holder_id
