class_name EnemyAttack
extends RefCounted

var enemy_id: StringName = &""
var target_investigator: StringName = &""
var kind: AhcEnums.AttackKind = AhcEnums.AttackKind.OPPORTUNITY
var damage: int = 1
var horror: int = 0
var exhaust_after: bool = false


static func opportunity(enemy_id: StringName, target: StringName, damage: int = 1, horror: int = 0) -> EnemyAttack:
	return enemy_strike(enemy_id, target, damage, horror, false, AhcEnums.AttackKind.OPPORTUNITY)


static func phase(enemy_id: StringName, target: StringName, damage: int = 1, horror: int = 0) -> EnemyAttack:
	return enemy_strike(enemy_id, target, damage, horror, true, AhcEnums.AttackKind.PHASE)


static func retaliate(enemy_id: StringName, target: StringName, damage: int = 1, horror: int = 0) -> EnemyAttack:
	return enemy_strike(enemy_id, target, damage, horror, false, AhcEnums.AttackKind.RETALIATE)


static func alert(enemy_id: StringName, target: StringName, damage: int = 1, horror: int = 0) -> EnemyAttack:
	return enemy_strike(enemy_id, target, damage, horror, false, AhcEnums.AttackKind.ALERT)


## 统一攻击效果：对目标造成敌人伤害/恐惧值；exhaust 由调用方（阶段 vs 卡面）决定。
static func enemy_strike(
	enemy_id: StringName,
	target: StringName,
	damage: int = 1,
	horror: int = 0,
	exhaust_after: bool = false,
	kind: AhcEnums.AttackKind = AhcEnums.AttackKind.OPPORTUNITY
) -> EnemyAttack:
	var a := EnemyAttack.new()
	a.enemy_id = enemy_id
	a.target_investigator = target
	a.kind = kind
	a.damage = damage
	a.horror = horror
	a.exhaust_after = exhaust_after
	return a


## 先定攻击效果（敌+目标）→ 无名修正敌人伤害/恐惧印刷量 → 建 strike。
static func build_from_enemy(
	game_ctx: GameContext,
	enemy_id: StringName,
	target: StringName,
	exhaust_after: bool = false,
	kind: AhcEnums.AttackKind = AhcEnums.AttackKind.OPPORTUNITY
) -> EnemyAttack:
	var damage := 1
	var horror := 0
	if game_ctx != null and game_ctx.state != null:
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy != null:
			damage = enemy.attack_damage
			horror = enemy.attack_horror
	var amounts := modified_strike_amounts(game_ctx, target, damage, horror)
	return enemy_strike(
		enemy_id,
		target,
		int(amounts.get("damage", damage)),
		int(amounts.get("horror", horror)),
		exhaust_after,
		kind
	)


## 对已定「敌人攻击」效果：先修攻击伤害/恐惧数值（修正不含目标）。
static func modified_strike_amounts(
	game_ctx: GameContext,
	target_investigator: StringName,
	base_damage: int,
	base_horror: int
) -> Dictionary:
	var damage := maxi(base_damage, 0)
	var horror := maxi(base_horror, 0)
	if game_ctx == null or game_ctx.modifiers == null or target_investigator == &"":
		return {"damage": damage, "horror": horror}
	var qd := ModifierQuery.new()
	qd.controller_id = target_investigator
	qd.stat = AhcEnums.StatRef.ENEMY_DAMAGE
	damage = game_ctx.modifiers.compute(damage, qd)
	var qh := ModifierQuery.new()
	qh.controller_id = target_investigator
	qh.stat = AhcEnums.StatRef.ENEMY_HORROR
	horror = game_ctx.modifiers.compute(horror, qh)
	return {"damage": maxi(damage, 0), "horror": maxi(horror, 0)}
