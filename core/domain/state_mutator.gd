class_name StateMutator
extends RefCounted

var _state: GameStateStore
var _information: InformationExecutor
var _registrations: RegistrationStore = null
var _after_zone_move: Callable = Callable()
var _physical: PhysicalOps = null
var _binding: PhysicalBinding = null


func _init(state: GameStateStore) -> void:
	_state = state
	_information = InformationExecutor.new(state)
	if state != null:
		_physical = state.physical_ops
		_binding = state.physical_binding


func bind_registration_store(store: RegistrationStore) -> void:
	_registrations = store


func bind_after_zone_move(callback: Callable) -> void:
	_after_zone_move = callback


func state() -> GameStateStore:
	return _state


func information() -> InformationExecutor:
	return _information


func physical() -> PhysicalOps:
	return _physical


func physical_binding() -> PhysicalBinding:
	return _binding


## L0 · AtomMoveCard
func move_card(card_id: StringName, to: CardSlot) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	var from_zone := card.zone
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
		if not _insert_encounter_discard(card):
			return false
		_mirror_move_card(card, to)
		_emit_zone_move(card_id, from_zone, card.zone)
		return true
	if to.owner_id == &"victory_display":
		if not _insert_victory_display(card):
			return false
		_mirror_move_card(card, to)
		_emit_zone_move(card_id, from_zone, card.zone)
		return true
	var target_inv := _state.registry.get_investigator(to.owner_id)
	if target_inv == null:
		return false
	if not _insert_into_pile(card, target_inv, to):
		return false
	card.zone = _zone_for_pile(to.pile)
	if to.pile == AhcEnums.PileKind.INV_HAND:
		card.controller_id = to.owner_id
	_mirror_move_card(card, to)
	_emit_zone_move(card_id, from_zone, card.zone)
	return true


func _emit_zone_move(
	card_id: StringName,
	from_zone: AhcEnums.Zone,
	to_zone: AhcEnums.Zone
) -> void:
	if from_zone == to_zone:
		return
	if _after_zone_move.is_valid():
		_after_zone_move.call(card_id, from_zone, to_zone)


## L0 · AtomTransferMarker（桌面标记唯一变更原语；池为无穷供给）。
## 禁止虚无 Adjust：增减一律经池或承载者之间的 Transfer。
func transfer_marker(kind: AhcEnums.MarkerKind, amount: int, from: MarkerSlot, to: MarkerSlot) -> bool:
	if amount <= 0 or from == null or to == null:
		return false
	if not TokenPool.is_table_token_kind(kind):
		return false
	if not _take_marker(from, kind, amount):
		return false
	if not _give_marker(to, kind, amount):
		## 源已扣；回滚到源（池端 give 为空操作，仍可恢复承载者侧）。
		_give_marker(from, kind, amount)
		return false
	_mirror_transfer_marker(kind, amount, from, to)
	return true


## L0 · AtomSetFlag
func set_flag(bearer_id: StringName, field: AhcEnums.FlagField, value: Variant) -> bool:
	match field:
		AhcEnums.FlagField.ELIMINATED:
			var inv := _state.registry.get_investigator(bearer_id)
			if inv == null:
				return false
			inv.eliminated = bool(value)
			return true
		AhcEnums.FlagField.RESIGNED:
			var resigned_inv := _state.registry.get_investigator(bearer_id)
			if resigned_inv == null:
				return false
			resigned_inv.resigned = bool(value)
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
## 物理：各卡 move 进遭遇库 + shuffle（此处用重建序对齐洗后结果）。
func shuffle_encounter_discard_into_deck() -> void:
	for card_id in _state.encounter_discard:
		var card := _state.registry.get_card(card_id)
		if card != null:
			card.zone = AhcEnums.Zone.DECK
	_state.encounter_deck = _state.encounter_discard.duplicate()
	_state.encounter_deck.shuffle()
	_state.encounter_discard.clear()
	_mirror_rebuild_encounter_deck()


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


## 信息层 Reveal（FaceAudience）——不是物理状态原语。
## 惯例：Reveal 时常伴随物理 ③ 翻到 A（可见性与面向仍正交；hide 不翻面）。
func reveal_to_controller(card_id: StringName, controller_id: StringName) -> bool:
	if not _information.reveal_to_controller(card_id, controller_id):
		return false
	flip_card(card_id, AhcEnums.CardFace.A)
	return true


func reveal_to_all(card_id: StringName) -> bool:
	if not _information.reveal_to_all(card_id):
		return false
	flip_card(card_id, AhcEnums.CardFace.A)
	return true


func hide_from_all(card_id: StringName) -> bool:
	## 仅信息层可见性；不翻面。
	return _information.hide_from_all(card_id)


## 物理状态原语 ③ · 翻面（CardFace）。
func flip_card(card_id: StringName, face: AhcEnums.CardFace) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	card.face = face
	_mirror_flip(card_id, face)
	return true


## 物理状态原语 ③ · 横置 / 重整（orientation）。
func set_exhausted(card_id: StringName, exhausted: bool) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	card.exhausted = exhausted
	if _binding != null:
		_binding.ensure_physical_card(card)
		_binding.mirror_exhausted(card_id, exhausted)
	return true


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
	var from_zone := card.zone
	inv.hand.erase(card_id)
	inv.deck.erase(card_id)
	if not inv.threat_area.has(card_id):
		inv.threat_area.append(card_id)
	card.controller_id = inv_id
	card.zone = AhcEnums.Zone.PLAY_AREA
	_mirror_move_to_zone(card, AhcEnums.Zone.THREAT_AREA, inv_id)
	_emit_zone_move(card_id, from_zone, AhcEnums.Zone.PLAY_AREA)
	return true


func finalize_limbo_discard(card_id: StringName, controller_id: StringName) -> bool:
	## 效果结算后仍在 limbo → 按 CardDefinition.limbo_discard_pile 落堆（Grimoire Limbo）。
	var card := _state.registry.get_card(card_id)
	if card == null or card.zone != AhcEnums.Zone.LIMBO:
		return false
	match CardRegistry.limbo_discard_pile(card.id.definition_id, card.face):
		&"encounter_discard":
			return move_card(card_id, CardSlot.encounter_discard_top())
		_:
			return move_card(card_id, CardSlot.discard_top(controller_id))


## dry-run / 模拟器用。生产抽牌走 `DrawInvestigatorService`（seq.draw.investigator）。
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
## 物理：弃牌 move 进库 + 洗后序重建。
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
	_mirror_rebuild_player_deck(inv_id)


func discard_from_hand(card_id: StringName, inv_id: StringName) -> bool:
	return move_card(card_id, CardSlot.discard_top(inv_id))


func _enter_limbo(card_id: StringName, controller_id: StringName) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	var from_zone := card.zone
	var inv := _state.registry.get_investigator(card.owner_id)
	if inv != null:
		_remove_from_pile(card, inv)
	_state.encounter_deck.erase(card.id.instance_id)
	_state.encounter_discard.erase(card.id.instance_id)
	card.zone = AhcEnums.Zone.LIMBO
	card.controller_id = controller_id
	_mirror_move_to_zone(card, AhcEnums.Zone.LIMBO, controller_id)
	_emit_zone_move(card_id, from_zone, AhcEnums.Zone.LIMBO)
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


func _remove_from_pile(card: CardInstance, inv: InvestigatorState) -> void:
	match card.zone:
		AhcEnums.Zone.DECK:
			inv.deck.erase(card.id.instance_id)
		AhcEnums.Zone.HAND:
			inv.hand.erase(card.id.instance_id)
		AhcEnums.Zone.DISCARD:
			inv.discard.erase(card.id.instance_id)
		AhcEnums.Zone.PLAY_AREA, AhcEnums.Zone.THREAT_AREA:
			inv.threat_area.erase(card.id.instance_id)
			inv.play_area.erase(card.id.instance_id)


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
	match from.bearer_kind:
		AhcEnums.BearerKind.GLOBAL:
			return _take_from_pool(kind, amount)
		AhcEnums.BearerKind.INVESTIGATOR:
			return _take_from_investigator(from.bearer_id, kind, amount)
		AhcEnums.BearerKind.CARD:
			return _take_from_card(from.bearer_id, kind, amount)
		AhcEnums.BearerKind.LOCATION:
			return _take_from_location(from.bearer_id, kind, amount)
		AhcEnums.BearerKind.AGENDA:
			return _take_from_agenda(kind, amount)
	return false


func _give_marker(to: MarkerSlot, kind: AhcEnums.MarkerKind, amount: int) -> bool:
	match to.bearer_kind:
		AhcEnums.BearerKind.GLOBAL:
			_give_to_pool(kind, amount)
			return true
		AhcEnums.BearerKind.INVESTIGATOR:
			return _give_to_investigator(to.bearer_id, kind, amount)
		AhcEnums.BearerKind.CARD:
			return _give_to_card(to.bearer_id, kind, amount)
		AhcEnums.BearerKind.LOCATION:
			return _give_to_location(to.bearer_id, kind, amount)
		AhcEnums.BearerKind.AGENDA:
			return _give_to_agenda(kind, amount)
	return false


func _take_from_pool(kind: AhcEnums.MarkerKind, amount: int) -> bool:
	return _state.token_pool.take(kind, amount)


func _give_to_pool(kind: AhcEnums.MarkerKind, amount: int) -> void:
	_state.token_pool.give(kind, amount)


func _take_from_investigator(inv_id: StringName, kind: AhcEnums.MarkerKind, amount: int) -> bool:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null or amount <= 0:
		return false
	match kind:
		AhcEnums.MarkerKind.RESOURCE, AhcEnums.MarkerKind.POOL_RESOURCE:
			if inv.resource_pool < amount:
				return false
			inv.resource_pool -= amount
			return true
		AhcEnums.MarkerKind.DAMAGE:
			if inv.damage_taken < amount:
				return false
			inv.damage_taken -= amount
			return true
		AhcEnums.MarkerKind.HORROR_TAKEN, AhcEnums.MarkerKind.HORROR:
			if inv.horror_taken < amount:
				return false
			inv.horror_taken -= amount
			return true
		AhcEnums.MarkerKind.CLUE, AhcEnums.MarkerKind.POOL_CLUE:
			if inv.clues_on_card < amount:
				return false
			inv.clues_on_card -= amount
			return true
	return false


func _give_to_investigator(inv_id: StringName, kind: AhcEnums.MarkerKind, amount: int) -> bool:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null or amount <= 0:
		return false
	match kind:
		AhcEnums.MarkerKind.RESOURCE, AhcEnums.MarkerKind.POOL_RESOURCE:
			inv.resource_pool += amount
			return true
		AhcEnums.MarkerKind.DAMAGE:
			inv.damage_taken += amount
			return true
		AhcEnums.MarkerKind.HORROR_TAKEN, AhcEnums.MarkerKind.HORROR:
			inv.horror_taken += amount
			return true
		AhcEnums.MarkerKind.CLUE, AhcEnums.MarkerKind.POOL_CLUE:
			inv.clues_on_card += amount
			return true
	return false


func _take_from_card(card_id: StringName, kind: AhcEnums.MarkerKind, amount: int) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null or amount <= 0:
		return false
	match kind:
		AhcEnums.MarkerKind.DAMAGE, AhcEnums.MarkerKind.POOL_DAMAGE:
			if card.tokens.damage < amount:
				return false
			card.tokens.damage -= amount
			return true
		AhcEnums.MarkerKind.HORROR, AhcEnums.MarkerKind.HORROR_TAKEN, AhcEnums.MarkerKind.POOL_HORROR:
			if card.tokens.horror < amount:
				return false
			card.tokens.horror -= amount
			return true
		AhcEnums.MarkerKind.DOOM:
			if card.tokens.doom < amount:
				return false
			card.tokens.doom -= amount
			return true
		AhcEnums.MarkerKind.CLUE, AhcEnums.MarkerKind.POOL_CLUE:
			if card.tokens.clue < amount:
				return false
			card.tokens.clue -= amount
			return true
	return false


func _give_to_card(card_id: StringName, kind: AhcEnums.MarkerKind, amount: int) -> bool:
	var card := _state.registry.get_card(card_id)
	if card == null or amount <= 0:
		return false
	match kind:
		AhcEnums.MarkerKind.DAMAGE, AhcEnums.MarkerKind.POOL_DAMAGE:
			card.tokens.damage += amount
			return true
		AhcEnums.MarkerKind.HORROR, AhcEnums.MarkerKind.HORROR_TAKEN, AhcEnums.MarkerKind.POOL_HORROR:
			card.tokens.horror += amount
			return true
		AhcEnums.MarkerKind.DOOM:
			card.tokens.doom += amount
			return true
		AhcEnums.MarkerKind.CLUE, AhcEnums.MarkerKind.POOL_CLUE:
			card.tokens.clue += amount
			return true
	return false


func _take_from_location(location_id: StringName, kind: AhcEnums.MarkerKind, amount: int) -> bool:
	var loc := _state.registry.get_location(location_id)
	if loc == null or amount <= 0:
		return false
	match kind:
		AhcEnums.MarkerKind.CLUE, AhcEnums.MarkerKind.POOL_CLUE:
			if loc.clues < amount:
				return false
			loc.clues -= amount
			return true
	return false


func _give_to_location(location_id: StringName, kind: AhcEnums.MarkerKind, amount: int) -> bool:
	var loc := _state.registry.get_location(location_id)
	if loc == null or amount <= 0:
		return false
	match kind:
		AhcEnums.MarkerKind.CLUE, AhcEnums.MarkerKind.POOL_CLUE:
			loc.clues += amount
			return true
	return false


func _take_from_agenda(kind: AhcEnums.MarkerKind, amount: int) -> bool:
	if kind != AhcEnums.MarkerKind.DOOM or amount <= 0:
		return false
	if _state.doom_on_agenda < amount:
		return false
	_state.doom_on_agenda -= amount
	return true


func _give_to_agenda(kind: AhcEnums.MarkerKind, amount: int) -> bool:
	if kind != AhcEnums.MarkerKind.DOOM or amount <= 0:
		return false
	_state.doom_on_agenda += amount
	return true


func marker_count_at(at: MarkerSlot) -> int:
	if at == null:
		return 0
	match at.bearer_kind:
		AhcEnums.BearerKind.INVESTIGATOR:
			var inv := _state.registry.get_investigator(at.bearer_id)
			if inv == null:
				return 0
			match at.kind:
				AhcEnums.MarkerKind.RESOURCE, AhcEnums.MarkerKind.POOL_RESOURCE:
					return inv.resource_pool
				AhcEnums.MarkerKind.DAMAGE:
					return inv.damage_taken
				AhcEnums.MarkerKind.HORROR_TAKEN, AhcEnums.MarkerKind.HORROR:
					return inv.horror_taken
				AhcEnums.MarkerKind.CLUE, AhcEnums.MarkerKind.POOL_CLUE:
					return inv.clues_on_card
		AhcEnums.BearerKind.CARD:
			var card := _state.registry.get_card(at.bearer_id)
			if card == null:
				return 0
			match at.kind:
				AhcEnums.MarkerKind.DAMAGE, AhcEnums.MarkerKind.POOL_DAMAGE:
					return card.tokens.damage
				AhcEnums.MarkerKind.HORROR, AhcEnums.MarkerKind.HORROR_TAKEN, AhcEnums.MarkerKind.POOL_HORROR:
					return card.tokens.horror
				AhcEnums.MarkerKind.DOOM:
					return card.tokens.doom
				AhcEnums.MarkerKind.CLUE, AhcEnums.MarkerKind.POOL_CLUE:
					return card.tokens.clue
		AhcEnums.BearerKind.LOCATION:
			var loc := _state.registry.get_location(at.bearer_id)
			if loc == null:
				return 0
			match at.kind:
				AhcEnums.MarkerKind.CLUE, AhcEnums.MarkerKind.POOL_CLUE:
					return loc.clues
		AhcEnums.BearerKind.AGENDA:
			if at.kind == AhcEnums.MarkerKind.DOOM:
				return _state.doom_on_agenda
		AhcEnums.BearerKind.GLOBAL:
			return 0
	return 0


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


func _mirror_move_card(card: CardInstance, to: CardSlot) -> void:
	if _binding == null:
		return
	_binding.mirror_move_card(card, to)


func _mirror_move_to_zone(card: CardInstance, zone: AhcEnums.Zone, owner_id: StringName) -> void:
	if _binding == null:
		return
	_binding.mirror_move_to_zone(card, zone, owner_id)


func _mirror_transfer_marker(
	kind: AhcEnums.MarkerKind,
	amount: int,
	from: MarkerSlot,
	to: MarkerSlot
) -> void:
	if _binding == null:
		return
	_binding.mirror_transfer_marker(kind, amount, from, to)



func _mirror_flip(card_id: StringName, face: AhcEnums.CardFace) -> void:
	if _binding == null:
		return
	var card := _state.registry.get_card(card_id)
	if card != null:
		_binding.ensure_physical_card(card)
	_binding.mirror_flip(card_id, face)


func _mirror_rebuild_player_deck(inv_id: StringName) -> void:
	if _binding == null:
		return
	_binding.ensure_player(inv_id)
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return
	for card_id in inv.deck:
		var card := _state.registry.get_card(card_id)
		if card != null:
			_binding.ensure_physical_card(card)
	_binding.mirror_rebuild_card_region_order(
		StringName("deck_%s" % String(inv_id)),
		inv.deck,
		AhcEnums.Zone.DECK,
		inv_id
	)
	## 弃牌区清空
	_binding.mirror_rebuild_card_region_order(
		StringName("discard_%s" % String(inv_id)),
		[],
		AhcEnums.Zone.DISCARD,
		inv_id
	)


func _mirror_rebuild_encounter_deck() -> void:
	if _binding == null:
		return
	for card_id in _state.encounter_deck:
		var card := _state.registry.get_card(card_id)
		if card != null:
			_binding.ensure_physical_card(card)
	_binding.mirror_rebuild_card_region_order(
		PhysicalBinding.ENCOUNTER_DECK,
		_state.encounter_deck,
		AhcEnums.Zone.DECK,
		&"encounter"
	)
	_binding.mirror_rebuild_card_region_order(
		PhysicalBinding.ENCOUNTER_DISCARD,
		[],
		AhcEnums.Zone.DISCARD,
		&"encounter"
	)
