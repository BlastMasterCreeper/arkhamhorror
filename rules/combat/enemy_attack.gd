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
