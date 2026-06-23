class_name StateMutator
extends RefCounted

var _state: GameStateStore
var _information: InformationExecutor


func _init(state: GameStateStore) -> void:
	_state = state
	_information = InformationExecutor.new(state)


func state() -> GameStateStore:
	return _state


func information() -> InformationExecutor:
	return _information


## L0 · AtomMoveCard
func move_card(card_id: StringName, to: CardSlot) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	var owner_inv := _state.registry.get_investigator(card.owner_id)
	if owner_inv != null:
		_remove_from_pile(card, owner_inv)
	elif card.zone == AhcEnums.Zone.LIMBO:
		pass
	if to.owner_id == &"encounter":
		return _insert_encounter_discard(card)
	var target_inv := _state.registry.get_investigator(to.owner_id)
	if target_inv == null:
		return false
	if not _insert_into_pile(card, target_inv, to):
		return false
	card.zone = _zone_for_pile(to.pile)
	if to.pile == AhcEnums.PileKind.INV_HAND:
		card.controller_id = to.owner_id
	return true


## L0 · AtomTransferMarker
func transfer_marker(kind: AhcEnums.MarkerKind, amount: int, from: MarkerSlot, to: MarkerSlot) -> bool:
	if amount <= 0:
		return false
	if not _take_marker(from, kind, amount):
		return false
	_give_marker(to, kind, amount)
	return true


## L0 · AtomAdjustMarker
func adjust_marker(at: MarkerSlot, delta: int, clamp_min: int = 0) -> bool:
	if delta == 0:
		return true
	if at.bearer_kind == AhcEnums.BearerKind.INVESTIGATOR:
		return _adjust_investigator_marker(at.bearer_id, at.kind, delta, clamp_min)
	if at.bearer_kind == AhcEnums.BearerKind.GLOBAL:
		return _adjust_pool_marker(at.kind, delta, clamp_min)
	return false


## L0 · AtomSetFlag
func set_flag(bearer_id: StringName, field: AhcEnums.FlagField, value: Variant) -> bool:
	match field:
		AhcEnums.FlagField.ELIMINATED:
			var inv := _state.registry.get_investigator(bearer_id)
			if inv == null:
				return false
			inv.eliminated = bool(value)
			return true
	return false


## L0 · AtomSetRef — 待扩展
func set_ref(_bearer_id: StringName, _field: StringName, _ref_id: StringName) -> bool:
	return false


func peek_deck_top(inv_id: StringName) -> StringName:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null or inv.deck.is_empty():
		return &""
	return inv.deck[0] as StringName


func bind_deck_top(inv_id: StringName) -> StringName:
	return peek_deck_top(inv_id)


func deck_is_empty(inv_id: StringName) -> bool:
	var inv := _state.registry.get_investigator(inv_id)
	return inv == null or inv.deck.is_empty()


func discard_is_empty(inv_id: StringName) -> bool:
	var inv := _state.registry.get_investigator(inv_id)
	return inv == null or inv.discard.is_empty()


## 从牌库顶取下 instance（脱离 deck pile；zone 暂留 DECK，待 reveal/入手）。
func pop_deck_top(inv_id: StringName) -> StringName:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null or inv.deck.is_empty():
		return &""
	var card_id := inv.deck[0] as StringName
	inv.deck.remove_at(0)
	return card_id


## Information brick · D2
func reveal_to_controller(card_id: StringName, controller_id: StringName) -> bool:
	return _information.reveal_to_controller(card_id, controller_id)


## D3：按卡定义进入 HAND 或 LIMBO。
func commit_enter_hand(card_id: StringName, inv_id: StringName) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	match CardRegistry.enter_hand_zone(card.id.definition_id):
		AhcEnums.Zone.LIMBO:
			return _enter_limbo(card_id, inv_id)
		_:
			return move_card(card_id, CardSlot.hand_bottom(inv_id))


func enter_hand_from_deck(card_id: StringName, inv_id: StringName) -> bool:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null or not inv.deck.has(card_id):
		return false
	inv.deck.erase(card_id)
	return commit_enter_hand(card_id, inv_id)


func reveal_drawn_card(card_id: StringName, controller_id: StringName) -> bool:
	return reveal_to_controller(card_id, controller_id)


func enter_hand_entry(card_id: StringName, inv_id: StringName) -> bool:
	return commit_enter_hand(card_id, inv_id)


func enter_limbo(card_id: StringName, controller_id: StringName) -> bool:
	return _enter_limbo(card_id, controller_id)


func finalize_limbo_discard(card_id: StringName, controller_id: StringName) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null or card.zone != AhcEnums.Zone.LIMBO:
		return false
	match CardRegistry.limbo_discard_pile(card.id.definition_id):
		&"encounter_discard":
			return move_card(card_id, CardSlot.encounter_discard_top())
		_:
			return move_card(card_id, CardSlot.discard_top(controller_id))


func execute_draw_instruction(inv_id: StringName, amount: int) -> Dictionary:
	return DrawInvestigatorFlow.run_mutator_only(self, inv_id, amount)


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


## Domain pile op（非 L0 效果原子；design 07a §6）。
func shuffle_discard_into_deck(inv_id: StringName) -> void:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return
	for card_id in inv.discard:
		var card := _state.registry.get_card(card_id)
		if card:
			card.zone = AhcEnums.Zone.DECK
	inv.deck = inv.discard.duplicate()
	inv.deck.shuffle()
	inv.discard.clear()


func add_resources(inv_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	adjust_marker(MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.RESOURCE), amount)


func take_horror(inv_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	adjust_marker(MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.HORROR_TAKEN), amount)


func discard_from_hand(card_id: StringName, inv_id: StringName) -> bool:
	return move_card(card_id, CardSlot.discard_top(inv_id))


func _enter_limbo(card_id: StringName, controller_id: StringName) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	var inv := _state.registry.get_investigator(card.owner_id)
	if inv != null:
		_remove_from_pile(card, inv)
	card.zone = AhcEnums.Zone.LIMBO
	card.controller_id = controller_id
	return true


func _insert_encounter_discard(card: CardInstance) -> bool:
	_state.encounter_discard.append(card.id.instance_id)
	card.zone = AhcEnums.Zone.DISCARD
	return true


func _adjust_investigator_marker(
	inv_id: StringName,
	kind: AhcEnums.MarkerKind,
	delta: int,
	clamp_min: int
) -> bool:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return false
	match kind:
		AhcEnums.MarkerKind.RESOURCE, AhcEnums.MarkerKind.POOL_RESOURCE:
			if delta < 0 and inv.resource_pool + delta < clamp_min:
				return false
			inv.resource_pool = maxi(inv.resource_pool + delta, clamp_min)
			return true
		AhcEnums.MarkerKind.HORROR_TAKEN:
			inv.horror_taken = maxi(inv.horror_taken + delta, clamp_min)
			return true
	return false


func _adjust_pool_marker(kind: AhcEnums.MarkerKind, delta: int, clamp_min: int) -> bool:
	var pool := _state.token_pool
	match kind:
		AhcEnums.MarkerKind.POOL_RESOURCE, AhcEnums.MarkerKind.RESOURCE:
			pool.resource_available = maxi(pool.resource_available + delta, clamp_min)
			return true
		AhcEnums.MarkerKind.POOL_DAMAGE:
			pool.damage_available = maxi(pool.damage_available + delta, clamp_min)
			return true
		AhcEnums.MarkerKind.POOL_HORROR:
			pool.horror_available = maxi(pool.horror_available + delta, clamp_min)
			return true
		AhcEnums.MarkerKind.POOL_CLUE:
			pool.clue_available = maxi(pool.clue_available + delta, clamp_min)
			return true
	return false


func _remove_from_pile(card: CardInstance, inv: InvestigatorState) -> void:
	match card.zone:
		AhcEnums.Zone.DECK:
			inv.deck.erase(card.id.instance_id)
		AhcEnums.Zone.HAND:
			inv.hand.erase(card.id.instance_id)
		AhcEnums.Zone.DISCARD:
			inv.discard.erase(card.id.instance_id)


func _insert_into_pile(card: CardInstance, inv: InvestigatorState, to: CardSlot) -> bool:
	var pile: Array = _pile_array(inv, to.pile)
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
	_adjust_pool_marker(kind, amount, 0)


func _take_from_investigator(inv_id: StringName, kind: AhcEnums.MarkerKind, amount: int) -> bool:
	if kind == AhcEnums.MarkerKind.RESOURCE or kind == AhcEnums.MarkerKind.POOL_RESOURCE:
		var inv := _state.registry.get_investigator(inv_id)
		if inv == null or inv.resource_pool < amount:
			return false
		inv.resource_pool -= amount
		return true
	return false


func _give_to_investigator(inv_id: StringName, kind: AhcEnums.MarkerKind, amount: int) -> void:
	_adjust_investigator_marker(inv_id, kind, amount, 0)
