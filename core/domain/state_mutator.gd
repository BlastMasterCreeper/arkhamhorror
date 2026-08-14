class_name StateMutator
extends RefCounted

var _state: GameStateStore
var _information: InformationExecutor
var _registrations: RegistrationStore = null


func _init(state: GameStateStore) -> void:
	_state = state
	_information = InformationExecutor.new(state)


func bind_registration_store(store: RegistrationStore) -> void:
	_registrations = store


func state() -> GameStateStore:
	return _state


func information() -> InformationExecutor:
	return _information


## L0 · AtomMoveCard
func move_card(card_id: StringName, to: CardSlot) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	if _would_leave_hand(card, to) and _blocks_leave_hand(card_id):
		return false
	if _would_leave_hand(card, to):
		var holder_id := card.controller_id
		if holder_id == &"":
			holder_id = card.owner_id
		var holder := _state.registry.get_investigator(holder_id)
		if holder != null:
			_remove_from_pile(card, holder)
	else:
		var owner_inv := _state.registry.get_investigator(card.owner_id)
		if owner_inv != null:
			_remove_from_pile(card, owner_inv)
		elif card.zone == AhcEnums.Zone.LIMBO:
			pass
		elif card.zone == AhcEnums.Zone.VICTORY_DISPLAY:
			_state.victory_display.erase(card.id.instance_id)
		elif card.zone == AhcEnums.Zone.PLAY_AREA and card.owner_id == &"encounter":
			_state.encounter_deck.erase(card.id.instance_id)
			_state.encounter_discard.erase(card.id.instance_id)
			for inv_id in _state.registry.all_investigator_ids():
				var inv := _state.registry.get_investigator(inv_id)
				if inv != null:
					inv.threat_area.erase(card.id.instance_id)
	if to.owner_id == &"encounter":
		return _insert_encounter_discard(card)
	if to.owner_id == &"victory_display":
		return _insert_victory_display(card)
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


func pop_encounter_deck_top() -> StringName:
	if _state.encounter_deck.is_empty():
		return &""
	var card_id := _state.encounter_deck[0] as StringName
	_state.encounter_deck.remove_at(0)
	var card := _state.registry.get_card(card_id)
	if card != null:
		card.zone = AhcEnums.Zone.LIMBO
	return card_id


func encounter_deck_is_empty() -> bool:
	return _state.encounter_deck.is_empty()


func encounter_discard_is_empty() -> bool:
	return _state.encounter_discard.is_empty()


## Domain pile op · 遭遇弃牌堆洗回遭遇牌库（无 horror）。
func shuffle_encounter_discard_into_deck() -> void:
	for card_id in _state.encounter_discard:
		var card := _state.registry.get_card(card_id)
		if card != null:
			card.zone = AhcEnums.Zone.DECK
	_state.encounter_deck = _state.encounter_discard.duplicate()
	_state.encounter_deck.shuffle()
	_state.encounter_discard.clear()


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


## L0 · AtomRevealCard（Grimoire Reveal；D2 等）
func reveal_to_controller(card_id: StringName, controller_id: StringName) -> bool:
	return _information.reveal_to_controller(card_id, controller_id)


func reveal_to_all(card_id: StringName) -> bool:
	return _information.reveal_to_all(card_id)


func hide_from_all(card_id: StringName) -> bool:
	return _information.hide_from_all(card_id)


## 隐私（Hidden）遭遇 · E4 秘密入手显现（drawer CONTROLLER + is_hidden）。
func commit_hidden_enter_hand(card_id: StringName, inv_id: StringName) -> bool:
	if not commit_enter_hand(card_id, inv_id):
		return false
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	card.is_hidden = true
	card.controller_id = inv_id
	return reveal_to_controller(card_id, inv_id)


## 隐私 enemy · spawn 前域转换（hand→LIMBO）。公开/清 is_hidden 由先行显现 composition 负责。
func prepare_hand_card_for_encounter_spawn(card_id: StringName, bearer_id: StringName) -> bool:
	var card := _state.registry.get_card(card_id)
	var inv := _state.registry.get_investigator(bearer_id)
	if card == null or inv == null:
		return false
	if card.zone != AhcEnums.Zone.HAND:
		return false
	if card.controller_id != bearer_id and not inv.hand.has(card_id):
		return false
	_remove_from_pile(card, inv)
	card.controller_id = bearer_id
	card.zone = AhcEnums.Zone.LIMBO
	return true


## 隐私卡面暴露显现：结束 secret hand 并公开牌面（须先于 spawn_encounter_enemy）。
func expose_hidden_card(card_id: StringName) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	card.is_hidden = false
	return reveal_to_all(card_id)


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


func commit_enter_threat_area(card_id: StringName, inv_id: StringName) -> bool:
	var card := _state.registry.get_card(card_id)
	var inv := _state.registry.get_investigator(inv_id)
	if card == null or inv == null:
		return false
	inv.hand.erase(card_id)
	inv.deck.erase(card_id)
	if not inv.threat_area.has(card_id):
		inv.threat_area.append(card_id)
	card.controller_id = inv_id
	card.zone = AhcEnums.Zone.PLAY_AREA
	return true


func finalize_limbo_discard(card_id: StringName, controller_id: StringName) -> bool:
	## 效果结算后仍在 limbo → 按 CardDefinition.limbo_discard_pile 落堆（Grimoire Limbo）。
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
	_state.encounter_deck.erase(card.id.instance_id)
	_state.encounter_discard.erase(card.id.instance_id)
	card.zone = AhcEnums.Zone.LIMBO
	card.controller_id = controller_id
	return true


func _insert_encounter_discard(card: CardInstance) -> bool:
	_state.encounter_discard.append(card.id.instance_id)
	card.zone = AhcEnums.Zone.DISCARD
	return true


func _insert_victory_display(card: CardInstance) -> bool:
	_state.encounter_deck.erase(card.id.instance_id)
	_state.encounter_discard.erase(card.id.instance_id)
	_state.victory_display.erase(card.id.instance_id)
	_state.victory_display.append(card.id.instance_id)
	card.zone = AhcEnums.Zone.VICTORY_DISPLAY
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
		AhcEnums.MarkerKind.DAMAGE:
			inv.damage_taken = maxi(inv.damage_taken + delta, clamp_min)
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
	# 遭遇牌 owner 恒为 encounter；进调查员 pile 只改 controller（见 move_card HAND 分支）。
	if card.owner_id != &"encounter":
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


func _would_leave_hand(card: CardInstance, to: CardSlot) -> bool:
	if card.zone != AhcEnums.Zone.HAND:
		return false
	if to.pile == AhcEnums.PileKind.INV_HAND:
		return false
	return true


func _blocks_leave_hand(card_id: StringName) -> bool:
	if _registrations == null:
		return false
	return RestrictionEvaluator.blocks_leave_hand(card_id, _registrations)
