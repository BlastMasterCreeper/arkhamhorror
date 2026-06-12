class_name EnemyAttack
extends RefCounted

var enemy_id: StringName = &""
var target_investigator: StringName = &""
var kind: AhcEnums.AttackKind = AhcEnums.AttackKind.OPPORTUNITY
var damage: int = 1
var horror: int = 0
var exhaust_after: bool = false


static func opportunity(enemy_id: StringName, target: StringName, damage: int = 1, horror: int = 0) -> EnemyAttack:
	var a := EnemyAttack.new()
	a.enemy_id = enemy_id
	a.target_investigator = target
	a.kind = AhcEnums.AttackKind.OPPORTUNITY
	a.damage = damage
	a.horror = horror
	a.exhaust_after = false
	return a
