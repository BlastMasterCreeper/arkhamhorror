class_name StateMutator
extends RefCounted

var _state: GameStateStore
var _information: InformationExecutor


func _init(state: GameStateStore) -> void:
	_state = state
	_information = InformationExecutor.new(state)


func information() -> InformationExecutor:
	return _information


func move_card(card_id: StringName, to: CardSlot) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	var owner_inv := _state.registry.get_investigator(card.owner_id)
	if owner_inv == null:
		return false
	_remove_from_pile(card, owner_inv)
	var target_inv := _state.registry.get_investigator(to.owner_id)
	if target_inv == null:
		return false
	if not _insert_into_pile(card, target_inv, to):
		return false
	card.zone = _zone_for_pile(to.pile)
	return true


func transfer_marker(kind: AhcEnums.MarkerKind, amount: int, from: MarkerSlot, to: MarkerSlot) -> bool:
	if amount <= 0:
		return false
	if not _take_marker(from, kind, amount):
		return false
	_give_marker(to, kind, amount)
	return true


func peek_deck_top(inv_id: StringName) -> StringName:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null or inv.deck.is_empty():
		return &""
	return inv.deck[0] as StringName


## D1 bind：返回将抽的 instance，牌仍在 deck。
func bind_deck_top(inv_id: StringName) -> StringName:
	return peek_deck_top(inv_id)


## D2：仅改牌面可见性，不改 zone。
func reveal_drawn_card(card_id: StringName, controller_id: StringName) -> bool:
	return _information.reveal_to_controller(card_id, controller_id)


## D3：deck → hand（牌须仍在 deck 堆列表中）。
func enter_hand_from_deck(card_id: StringName, inv_id: StringName) -> bool:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null or not inv.deck.has(card_id):
		return false
	inv.deck.erase(card_id)
	return _enter_hand(card_id, inv_id)


func _enter_hand(card_id: StringName, inv_id: StringName) -> bool:
	var inv := _state.registry.get_investigator(inv_id)
	var card := _state.registry.get_card(card_id)
	if inv == null or card == null:
		return false
	card.zone = AhcEnums.Zone.HAND
	card.controller_id = inv_id
	inv.hand.append(card_id)
	return true


## 从牌库顶取下 instance（仍保持 zone=DECK，待 reveal/入手）。
func take_top_from_deck(inv_id: StringName) -> StringName:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null or inv.deck.is_empty():
		return &""
	var card_id := inv.deck[0] as StringName
	inv.deck.remove_at(0)
	return card_id


## Grimoire Drawing Cards：一次指令抽 amount 张；≥2 同时 reveal+入手；空库 mid-draw 洗弃牌堆并完成。
func execute_draw_instruction(inv_id: StringName, amount: int) -> Dictionary:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator", "drawn": [], "drew": false, "shuffled": false, "shuffles": 0, "horror_taken": 0, "defeated": false}
	if amount <= 0:
		return {"ok": true, "drawn": [], "drew": false, "shuffled": false, "shuffles": 0, "horror_taken": 0, "defeated": false}
	var pending: Array[StringName] = []
	var shuffles := 0
	var horror_taken := 0
	while pending.size() < amount:
		if inv.deck.is_empty():
			if inv.discard.is_empty():
				inv.eliminated = true
				return _draw_instruction_result(pending, shuffles, horror_taken, true)
			_shuffle_discard_into_deck(inv)
			shuffles += 1
			horror_taken += 1
			inv.horror_taken += 1
		var card_id := take_top_from_deck(inv_id)
		if card_id == &"":
			if inv.discard.is_empty():
				return _draw_instruction_result(pending, shuffles, horror_taken, true)
			continue
		pending.append(card_id)
	for card_id in pending:
		if not reveal_drawn_card(card_id, inv_id):
			push_warning("StateMutator: reveal failed for %s" % card_id)
	for card_id in pending:
		if not enter_hand_entry(card_id, inv_id):
			push_warning("StateMutator: enter_hand_entry failed for %s" % card_id)
	return _draw_instruction_result(pending, shuffles, horror_taken, false)


## enter_hand 入口：按卡定义进入 HAND 或 LIMBO（显现唯一 timing 的物理落点）。
func enter_hand_entry(card_id: StringName, inv_id: StringName) -> bool:
	var inv := _state.registry.get_investigator(inv_id)
	var card := _state.registry.get_card(card_id)
	if inv == null or card == null:
		return false
	if inv.deck.has(card_id):
		inv.deck.erase(card_id)
	match CardRegistry.enter_hand_zone(card.id.definition_id):
		AhcEnums.Zone.LIMBO:
			return enter_limbo(card_id, inv_id)
		_:
			return _enter_hand(card_id, inv_id)


func enter_limbo(card_id: StringName, controller_id: StringName) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	var inv := _state.registry.get_investigator(card.owner_id)
	if inv != null:
		_remove_from_pile(card, inv)
	card.zone = AhcEnums.Zone.LIMBO
	card.controller_id = controller_id
	return true


## 显现后仍在 limbo → 弃入 CardRegistry 指定的牌堆。
func finalize_limbo_discard(card_id: StringName, controller_id: StringName) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null or card.zone != AhcEnums.Zone.LIMBO:
		return false
	match CardRegistry.limbo_discard_pile(card.id.definition_id):
		&"encounter_discard":
			return _discard_to_encounter_discard(card_id)
		_:
			return _discard_to_owner_discard(card_id, controller_id)


func _discard_to_owner_discard(card_id: StringName, owner_id: StringName) -> bool:
	var inv := _state.registry.get_investigator(owner_id)
	var card := _state.registry.get_card(card_id)
	if inv == null or card == null:
		return false
	inv.discard.append(card_id)
	card.zone = AhcEnums.Zone.DISCARD
	card.owner_id = owner_id
	return true


func _discard_to_encounter_discard(card_id: StringName) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	_state.encounter_discard.append(card_id)
	card.zone = AhcEnums.Zone.DISCARD
	return true


func _draw_instruction_result(
	drawn: Array[StringName],
	shuffles: int,
	horror_taken: int,
	defeated: bool
) -> Dictionary:
	return {
		"ok": true,
		"drawn": drawn.duplicate(),
		"drew": not drawn.is_empty(),
		"shuffled": shuffles > 0,
		"shuffles": shuffles,
		"horror_taken": horror_taken,
		"defeated": defeated,
	}


## D1→D2→D3 抽 1 张（测试/组合原子）。
func draw_one_card_to_hand(inv_id: StringName) -> StringName:
	var result := execute_draw_instruction(inv_id, 1)
	var drawn: Array = result.get("drawn", [])
	if drawn.is_empty():
		return &""
	return drawn[0] as StringName


func draw_from_deck_to_hand(inv_id: StringName) -> bool:
	return draw_one_card_to_hand(inv_id) != &""


func perform_draw_action(inv_id: StringName) -> Dictionary:
	return execute_draw_instruction(inv_id, 1)


func _shuffle_discard_into_deck(inv: InvestigatorState) -> void:
	for card_id in inv.discard:
		var card := _state.registry.get_card(card_id)
		if card:
			card.zone = AhcEnums.Zone.DECK
	inv.deck = inv.discard.duplicate()
	inv.deck.shuffle()
	inv.discard.clear()


func _remove_from_pile(card: CardInstance, inv: InvestigatorState) -> void:
	match card.zone:
		AhcEnums.Zone.DECK:
			inv.deck.erase(card.id.instance_id)
		AhcEnums.Zone.HAND:
			inv.hand.erase(card.id.instance_id)
		AhcEnums.Zone.DISCARD:
			inv.discard.erase(card.id.instance_id)


func _insert_into_pile(card: CardInstance, inv: InvestigatorState, to: CardSlot) -> bool:
	var target_inv := _state.registry.get_investigator(to.owner_id)
	if target_inv == null:
		return false
	var pile: Array = _pile_array(target_inv, to.pile)
	if pile == null:
		return false
	card.owner_id = to.owner_id
	if to.insert == AhcEnums.InsertMode.TOP:
		pile.insert(0, card.id.instance_id)
	else:
		pile.append(card.id.instance_id)
	return true


func _pile_array(inv: InvestigatorState, pile: AhcEnums.PileKind) -> Array:
	match pile:
		AhcEnums.PileKind.INV_DECK:
			return inv.deck
		AhcEnums.PileKind.INV_HAND:
			return inv.hand
		AhcEnums.PileKind.INV_DISCARD:
			return inv.discard
	return []


func _zone_for_pile(pile: AhcEnums.PileKind) -> AhcEnums.Zone:
	match pile:
		AhcEnums.PileKind.INV_DECK:
			return AhcEnums.Zone.DECK
		AhcEnums.PileKind.INV_HAND:
			return AhcEnums.Zone.HAND
		AhcEnums.PileKind.INV_DISCARD:
			return AhcEnums.Zone.DISCARD
	return AhcEnums.Zone.DECK


func _take_marker(from: MarkerSlot, kind: AhcEnums.MarkerKind, amount: int) -> bool:
	if from.bearer_kind == AhcEnums.BearerKind.GLOBAL:
		return _take_from_pool(kind, amount)
	if from.bearer_kind == AhcEnums.BearerKind.INVESTIGATOR:
		return _take_from_investigator(from.bearer_id, kind, amount)
	return false


func _give_marker(to: MarkerSlot, kind: AhcEnums.MarkerKind, amount: int) -> void:
	if to.bearer_kind == AhcEnums.BearerKind.GLOBAL:
		_give_to_pool(kind, amount)
	elif to.bearer_kind == AhcEnums.BearerKind.INVESTIGATOR:
		_give_to_investigator(to.bearer_id, kind, amount)


func _take_from_pool(kind: AhcEnums.MarkerKind, amount: int) -> bool:
	match kind:
		AhcEnums.MarkerKind.POOL_RESOURCE, AhcEnums.MarkerKind.RESOURCE:
			return true
		AhcEnums.MarkerKind.POOL_DAMAGE, AhcEnums.MarkerKind.POOL_HORROR, AhcEnums.MarkerKind.POOL_CLUE:
			return true
	return false


func _give_to_pool(kind: AhcEnums.MarkerKind, amount: int) -> void:
	var pool := _state.token_pool
	match kind:
		AhcEnums.MarkerKind.POOL_RESOURCE, AhcEnums.MarkerKind.RESOURCE:
			pool.resource_available += amount
		AhcEnums.MarkerKind.POOL_DAMAGE:
			pool.damage_available += amount
		AhcEnums.MarkerKind.POOL_HORROR:
			pool.horror_available += amount
		AhcEnums.MarkerKind.POOL_CLUE:
			pool.clue_available += amount


func _take_from_investigator(inv_id: StringName, kind: AhcEnums.MarkerKind, amount: int) -> bool:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return false
	if kind == AhcEnums.MarkerKind.RESOURCE or kind == AhcEnums.MarkerKind.POOL_RESOURCE:
		if inv.resource_pool < amount:
			return false
		inv.resource_pool -= amount
		return true
	return false


func _give_to_investigator(inv_id: StringName, kind: AhcEnums.MarkerKind, amount: int) -> void:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return
	if kind == AhcEnums.MarkerKind.RESOURCE or kind == AhcEnums.MarkerKind.POOL_RESOURCE:
		inv.resource_pool += amount


func add_resources(inv_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	_give_to_investigator(inv_id, AhcEnums.MarkerKind.RESOURCE, amount)


func take_horror(inv_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return
	inv.horror_taken += amount


func discard_from_hand(card_id: StringName, inv_id: StringName) -> bool:
	var inv := _state.registry.get_investigator(inv_id)
	var card := _state.registry.get_card(card_id)
	if inv == null or card == null or card.zone != AhcEnums.Zone.HAND:
		return false
	if not inv.hand.has(card_id):
		return false
	inv.hand.erase(card_id)
	inv.discard.append(card_id)
	card.zone = AhcEnums.Zone.DISCARD
	return true
