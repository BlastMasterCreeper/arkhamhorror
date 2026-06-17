class_name DrawInvestigatorService
extends RefCounted

var _mutator: StateMutator
var _enter_hand: EnterHandService


func _init(mutator: StateMutator, enter_hand: EnterHandService = null) -> void:
	_mutator = mutator
	_enter_hand = enter_hand if enter_hand else EnterHandService.new(CardAbilityService.new())


## 一次「调查员抽牌」指令（amount=1 为 Draw 行动/抽 1 效果）。
func draw_cards(
	game_ctx: GameContext,
	inv_id: StringName,
	amount: int,
	source_tags: Array[StringName] = []
) -> Dictionary:
	if amount <= 0:
		return _empty_ok()
	var resolved: Array[Dictionary] = [{}]
	var resolve := func() -> void:
		resolved[0] = _mutator.execute_draw_instruction(inv_id, amount)
		var drawn: Array = resolved[0].get("drawn", [])
		if game_ctx != null and game_ctx.memory != null:
			game_ctx.memory.set_referent(inv_id, &"last_draw_count", drawn.size())
		var revelations: Array[StringName] = _enter_hand.nest_revelation_sequences(
			game_ctx, inv_id, drawn, source_tags, &"seq.draw.investigator"
		)
		resolved[0]["revelations"] = revelations
	if game_ctx != null and game_ctx.sequences != null:
		var tags: Array[StringName] = [&"draw_investigator"]
		tags.append_array(source_tags)
		var trigger := TriggeringCondition.draw_investigator(inv_id, amount, tags)
		game_ctx.sequences.run(trigger, resolve)
	else:
		resolve.call()
	return resolved[0]


func _empty_ok() -> Dictionary:
	return {
		"ok": true,
		"drew": false,
		"drawn": [],
		"shuffled": false,
		"shuffles": 0,
		"horror_taken": 0,
		"defeated": false,
		"revelations": [],
	}
