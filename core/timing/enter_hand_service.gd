class_name EnterHandService
extends RefCounted

## 显现唯一入口 timing（与来源、方式、入手前 zone 无关）。
const TIMING := &"enter_hand"

var _abilities: CardAbilityService


func _init(abilities: CardAbilityService) -> void:
	_abilities = abilities


## 按 enter_hand 顺序 nest 各张牌的显现序列。
func nest_revelation_sequences(
	game_ctx: GameContext,
	controller_id: StringName,
	card_ids: Array,
	source_tags: Array[StringName] = [],
	flow_id: StringName = &"seq.enter_hand"
) -> Array[StringName]:
	var resolved: Array[StringName] = []
	if game_ctx == null or game_ctx.sequences == null:
		for card_id in card_ids:
			var cid := card_id as StringName
			if _abilities.resolve_revelations(game_ctx, controller_id, cid, flow_id):
				resolved.append(cid)
		return resolved
	for card_id in card_ids:
		var cid := card_id as StringName
		if not _abilities.has_revelation(game_ctx, cid):
			continue
		var trigger := TriggeringCondition.enter_hand(controller_id, cid, source_tags)
		game_ctx.sequences.nest(
			trigger,
			func() -> void:
				_abilities.resolve_revelations(game_ctx, controller_id, cid, flow_id)
		)
		resolved.append(cid)
	return resolved
