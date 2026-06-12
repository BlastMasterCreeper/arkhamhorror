class_name StateMutator
extends RefCounted

var _state: GameStateStore


func _init(state: GameStateStore) -> void:
	_state = state


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


func draw_from_deck_to_hand(inv_id: StringName) -> bool:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null or inv.deck.is_empty():
		return false
	var card_id: StringName = inv.deck[0]
	inv.deck.remove_at(0)
	var card := _state.registry.get_card(card_id)
	if card:
		card.zone = AhcEnums.Zone.HAND
	inv.hand.append(card_id)
	return true


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
