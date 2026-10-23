class_name PhysicalBinding
extends RefCounted

## 信息层地址（Zone / CardSlot / MarkerSlot）→ 物理区 / locus。
## 命名与建区在此；PhysicalOps 不认语义名。

const LIMBO := &"limbo"
const SET_ASIDE := &"set_aside"
const ENCOUNTER_DECK := &"encounter_deck"
const ENCOUNTER_DISCARD := &"encounter_discard"
const VICTORY_DISPLAY := &"victory_display"
const REMOVED := &"removed_from_game"
const LOCATION_AREA := &"location_area"
const CURRENT_ACT := &"current_act"
const CURRENT_AGENDA := &"current_agenda"
const SCENARIO_REFERENCE := &"scenario_reference"
const SUPPLY := &"supply"
const CHAOS_BAG := &"chaos_bag"
const AUGURY := &"augury"


var ops: PhysicalOps
## Domain 侧状态（密谋 doom locus 等）；由 GameStateStore 安装后绑定。
var domain: GameStateStore = null


func _init(physical_ops: PhysicalOps) -> void:
	ops = physical_ops


func bind_domain(state: GameStateStore) -> void:
	domain = state


func install_table() -> void:
	_ensure_card_region(LIMBO, CardRegion.Shape.FLAT)
	_ensure_card_region(SET_ASIDE, CardRegion.Shape.FLAT)
	_ensure_card_region(ENCOUNTER_DECK, CardRegion.Shape.DECK)
	_ensure_card_region(ENCOUNTER_DISCARD, CardRegion.Shape.FLAT)
	_ensure_card_region(VICTORY_DISPLAY, CardRegion.Shape.FLAT)
	_ensure_card_region(REMOVED, CardRegion.Shape.FLAT)
	_ensure_card_region(LOCATION_AREA, CardRegion.Shape.FLAT)
	_ensure_card_region(CURRENT_ACT, CardRegion.Shape.FLAT)
	_ensure_card_region(CURRENT_AGENDA, CardRegion.Shape.FLAT)
	_ensure_card_region(SCENARIO_REFERENCE, CardRegion.Shape.FLAT)
	_ensure_marker_region(SUPPLY)
	_ensure_marker_region(CHAOS_BAG)
	_ensure_marker_region(AUGURY)


func ensure_player(player_id: StringName, seat_index: int = 0) -> void:
	if ops.store.get_player(player_id) == null:
		ops.add_player(player_id, seat_index)
	_ensure_card_region(_deck(player_id), CardRegion.Shape.DECK, player_id)
	_ensure_card_region(_hand(player_id), CardRegion.Shape.FLAT, player_id)
	_ensure_card_region(_discard(player_id), CardRegion.Shape.FLAT, player_id)
	_ensure_card_region(_play(player_id), CardRegion.Shape.FLAT, player_id)
	_ensure_card_region(_threat(player_id), CardRegion.Shape.FLAT, player_id)
	_ensure_marker_region(_resource_pool(player_id))
	_ensure_marker_region(_inv_tokens(player_id))


func region_for_zone(zone: AhcEnums.Zone, owner_id: StringName = &"") -> StringName:
	match zone:
		AhcEnums.Zone.LIMBO:
			return LIMBO
		AhcEnums.Zone.SET_ASIDE:
			return SET_ASIDE
		AhcEnums.Zone.VICTORY_DISPLAY:
			return VICTORY_DISPLAY
		AhcEnums.Zone.REMOVED_FROM_GAME:
			return REMOVED
		AhcEnums.Zone.LOCATION_AREA:
			return LOCATION_AREA
		AhcEnums.Zone.CURRENT_ACT:
			return CURRENT_ACT
		AhcEnums.Zone.CURRENT_AGENDA:
			return CURRENT_AGENDA
		AhcEnums.Zone.SCENARIO_REFERENCE:
			return SCENARIO_REFERENCE
		AhcEnums.Zone.DECK:
			if owner_id == &"encounter":
				return ENCOUNTER_DECK
			ensure_player(owner_id)
			return _deck(owner_id)
		AhcEnums.Zone.HAND:
			ensure_player(owner_id)
			return _hand(owner_id)
		AhcEnums.Zone.DISCARD:
			if owner_id == &"encounter":
				return ENCOUNTER_DISCARD
			ensure_player(owner_id)
			return _discard(owner_id)
		AhcEnums.Zone.PLAY_AREA:
			ensure_player(owner_id)
			return _play(owner_id)
		AhcEnums.Zone.THREAT_AREA:
			ensure_player(owner_id)
			return _threat(owner_id)
		AhcEnums.Zone.ATTACHED:
			return LIMBO
	return LIMBO


func region_for_card_slot(slot: CardSlot) -> StringName:
	if slot == null:
		return LIMBO
	if slot.owner_id == &"victory_display":
		return VICTORY_DISPLAY
	if slot.owner_id == &"encounter":
		return ENCOUNTER_DISCARD
	match slot.pile:
		AhcEnums.PileKind.INV_DECK:
			ensure_player(slot.owner_id)
			return _deck(slot.owner_id)
		AhcEnums.PileKind.INV_HAND:
			ensure_player(slot.owner_id)
			return _hand(slot.owner_id)
		AhcEnums.PileKind.INV_DISCARD:
			ensure_player(slot.owner_id)
			return _discard(slot.owner_id)
	return LIMBO


func locus_for_marker_slot(slot: MarkerSlot) -> MarkerLocus:
	if slot == null:
		return MarkerLocus.region(SUPPLY)
	match slot.bearer_kind:
		AhcEnums.BearerKind.GLOBAL:
			return MarkerLocus.region(SUPPLY)
		AhcEnums.BearerKind.CARD:
			if domain != null:
				var card := domain.registry.get_card(slot.bearer_id)
				if card != null:
					ensure_physical_card(card)
			return MarkerLocus.card(slot.bearer_id)
		AhcEnums.BearerKind.INVESTIGATOR:
			ensure_player(slot.bearer_id)
			if (
				slot.kind == AhcEnums.MarkerKind.RESOURCE
				or slot.kind == AhcEnums.MarkerKind.POOL_RESOURCE
			):
				return MarkerLocus.region(_resource_pool(slot.bearer_id))
			return MarkerLocus.region(_inv_tokens(slot.bearer_id))
		AhcEnums.BearerKind.LOCATION:
			_ensure_marker_region(_loc_tokens(slot.bearer_id))
			return MarkerLocus.region(_loc_tokens(slot.bearer_id))
		AhcEnums.BearerKind.AGENDA:
			return agenda_doom_locus(domain)
	return MarkerLocus.region(SUPPLY)


func marker_key_for(kind: AhcEnums.MarkerKind) -> StringName:
	match kind:
		AhcEnums.MarkerKind.DAMAGE, AhcEnums.MarkerKind.POOL_DAMAGE:
			return MarkerKeys.DAMAGE
		AhcEnums.MarkerKind.HORROR, AhcEnums.MarkerKind.HORROR_TAKEN, AhcEnums.MarkerKind.POOL_HORROR:
			return MarkerKeys.HORROR
		AhcEnums.MarkerKind.CLUE, AhcEnums.MarkerKind.POOL_CLUE:
			return MarkerKeys.CLUE
		AhcEnums.MarkerKind.DOOM:
			return MarkerKeys.DOOM
		AhcEnums.MarkerKind.RESOURCE, AhcEnums.MarkerKind.POOL_RESOURCE:
			return MarkerKeys.RESOURCE
	return MarkerKeys.RESOURCE


func ensure_physical_card(card: CardInstance) -> StringName:
	if card == null or card.id == null:
		return &""
	var eid: StringName = card.id.instance_id
	if ops.store.get_card(eid) != null:
		return eid
	var owner := card.owner_id
	if owner == &"":
		owner = card.controller_id
	var region := region_for_zone(card.zone, owner)
	var shape := CardRegion.Shape.FLAT
	if region == ENCOUNTER_DECK or String(region).begins_with("deck_"):
		shape = CardRegion.Shape.DECK
	var owner_player := owner if owner != &"encounter" else &""
	_ensure_card_region(region, shape, owner_player)
	return ops.materialize_card(card.id.definition_id, region, eid)


func mirror_move_card(card: CardInstance, to_slot: CardSlot) -> bool:
	if card == null:
		return false
	var eid := ensure_physical_card(card)
	if eid == &"":
		return false
	var to_region := region_for_card_slot(to_slot)
	## encounter discard / victory already handled in region_for_card_slot
	if to_slot != null and to_slot.owner_id == &"encounter":
		to_region = ENCOUNTER_DISCARD
	var insert := AhcEnums.InsertMode.BOTTOM
	if to_slot != null:
		insert = to_slot.insert
	return ops.move_card(eid, to_region, insert)


func mirror_move_to_zone(card: CardInstance, zone: AhcEnums.Zone, owner_id: StringName) -> bool:
	if card == null:
		return false
	var eid := ensure_physical_card(card)
	if eid == &"":
		return false
	var region := region_for_zone(zone, owner_id)
	return ops.move_card(eid, region)


func mirror_transfer_marker(
	kind: AhcEnums.MarkerKind,
	amount: int,
	from: MarkerSlot,
	to: MarkerSlot
) -> bool:
	var key := marker_key_for(kind)
	return ops.transfer(key, amount, locus_for_marker_slot(from), locus_for_marker_slot(to))


## 物理状态原语 ③ · 翻面（CardFace）。信息层 Reveal（FaceAudience）另算，物理层不管可见性。
func mirror_flip(card_id: StringName, face: AhcEnums.CardFace) -> bool:
	if ops.store.get_card(card_id) == null:
		return true
	return ops.set_face(card_id, face)


func mirror_exhausted(card_id: StringName, exhausted: bool) -> bool:
	if ops.store.get_card(card_id) == null:
		return true
	return ops.set_exhausted(card_id, exhausted)


## 卡上 TokenBag → 物理 markers（全量同步）。
func sync_card_markers(card: CardInstance) -> void:
	if card == null:
		return
	var eid := ensure_physical_card(card)
	if eid == &"":
		return
	var phys := ops.store.get_card(eid)
	if phys == null:
		return
	phys.markers.clear()
	var bag: TokenBag = card.tokens
	if bag.damage > 0:
		phys.markers[MarkerKeys.DAMAGE] = bag.damage
	if bag.horror > 0:
		phys.markers[MarkerKeys.HORROR] = bag.horror
	if bag.doom > 0:
		phys.markers[MarkerKeys.DOOM] = bag.doom
	if bag.clue > 0:
		phys.markers[MarkerKeys.CLUE] = bag.clue
	for use_name in bag.uses.keys():
		var n := int(bag.uses[use_name])
		if n > 0:
			phys.markers[MarkerKeys.use_key(use_name as StringName)] = n


const AGENDA_DOOM_FALLBACK := &"agenda_doom"

func agenda_doom_locus(state: GameStateStore) -> MarkerLocus:
	if state != null and state.current_agenda_card_id != &"":
		var card := state.registry.get_card(state.current_agenda_card_id)
		if card != null:
			ensure_physical_card(card)
			return MarkerLocus.card(state.current_agenda_card_id)
	## 无当前密谋卡时暂记独立标记区
	_ensure_marker_region(AGENDA_DOOM_FALLBACK)
	return MarkerLocus.region(AGENDA_DOOM_FALLBACK)


func mirror_agenda_doom_set(state: GameStateStore, amount: int) -> void:
	var locus := agenda_doom_locus(state)
	var have := ops.get_count(locus, MarkerKeys.DOOM)
	var delta := amount - have
	if delta > 0:
		ops.add_markers(locus, MarkerKeys.DOOM, delta)
	elif delta < 0:
		ops.remove_markers(locus, MarkerKeys.DOOM, -delta)


func mirror_agenda_doom_delta(state: GameStateStore, delta: int) -> void:
	if delta == 0:
		return
	var locus := agenda_doom_locus(state)
	if delta > 0:
		ops.add_markers(locus, MarkerKeys.DOOM, delta)
	else:
		ops.remove_markers(locus, MarkerKeys.DOOM, -delta)


func mirror_chaos_draw(token: ChaosToken) -> void:
	var key := MarkerKeys.from_chaos_token(token)
	if key == &"":
		return
	_ensure_marker_region(CHAOS_BAG)
	_ensure_marker_region(AUGURY)
	## 袋侧可能尚未同步：先保证袋有至少 1，再 transfer
	if ops.get_count(MarkerLocus.region(CHAOS_BAG), key) < 1:
		ops.add_markers(MarkerLocus.region(CHAOS_BAG), key, 1)
	ops.transfer(key, 1, MarkerLocus.region(CHAOS_BAG), MarkerLocus.region(AUGURY))


func mirror_chaos_return(token: ChaosToken) -> void:
	var key := MarkerKeys.from_chaos_token(token)
	if key == &"":
		return
	_ensure_marker_region(CHAOS_BAG)
	_ensure_marker_region(AUGURY)
	if ops.get_count(MarkerLocus.region(AUGURY), key) < 1:
		ops.add_markers(MarkerLocus.region(AUGURY), key, 1)
	ops.transfer(key, 1, MarkerLocus.region(AUGURY), MarkerLocus.region(CHAOS_BAG))


func mirror_chaos_add_to_bag(token: ChaosToken) -> void:
	var key := MarkerKeys.from_chaos_token(token)
	if key == &"":
		return
	_ensure_marker_region(CHAOS_BAG)
	ops.add_markers(MarkerLocus.region(CHAOS_BAG), key, 1)


func resync_chaos_bag_from_tokens(tokens: Array) -> void:
	_ensure_marker_region(CHAOS_BAG)
	_ensure_marker_region(AUGURY)
	var bag := ops.store.get_marker_region(CHAOS_BAG)
	var aug := ops.store.get_marker_region(AUGURY)
	if bag != null:
		bag.counts.clear()
	if aug != null:
		aug.counts.clear()
	for raw in tokens:
		var tok := raw as ChaosToken
		if tok == null:
			continue
		mirror_chaos_add_to_bag(tok)


func mirror_rebuild_card_region_order(
	region_id: StringName,
	ordered_ids: Array,
	zone_hint: AhcEnums.Zone,
	owner_id: StringName
) -> void:
	var shape := CardRegion.Shape.DECK
	if zone_hint != AhcEnums.Zone.DECK:
		shape = CardRegion.Shape.FLAT
	_ensure_card_region(region_id, shape, owner_id if owner_id != &"encounter" else &"")
	var region := ops.store.get_card_region(region_id)
	if region == null:
		return
	region.card_ids.clear()
	for raw in ordered_ids:
		var cid := raw as StringName
		if cid == &"":
			continue
		## 仅调序：卡须已存在或由调用方 ensure
		var phys := ops.store.get_card(cid)
		if phys == null:
			continue
		if phys.region_id != &"" and phys.region_id != region_id:
			var old := ops.store.get_card_region(phys.region_id)
			if old != null:
				old.card_ids.erase(cid)
		phys.region_id = region_id
		region.card_ids.append(cid)


func _deck(player_id: StringName) -> StringName:
	return StringName("deck_%s" % String(player_id))


func _hand(player_id: StringName) -> StringName:
	return StringName("hand_%s" % String(player_id))


func _discard(player_id: StringName) -> StringName:
	return StringName("discard_%s" % String(player_id))


func _play(player_id: StringName) -> StringName:
	return StringName("play_%s" % String(player_id))


func _threat(player_id: StringName) -> StringName:
	return StringName("threat_%s" % String(player_id))


func _resource_pool(player_id: StringName) -> StringName:
	return StringName("resource_%s" % String(player_id))


func _inv_tokens(player_id: StringName) -> StringName:
	return StringName("inv_tokens_%s" % String(player_id))


func _loc_tokens(location_id: StringName) -> StringName:
	return StringName("loc_tokens_%s" % String(location_id))


func _ensure_card_region(
	region_id: StringName,
	shape: int,
	owner_player_id: StringName = &""
) -> void:
	if ops.store.get_card_region(region_id) != null:
		return
	ops.create_card_region(shape, owner_player_id, region_id)


func _ensure_marker_region(region_id: StringName) -> void:
	if ops.store.get_marker_region(region_id) != null:
		return
	## 桌面 supply = 无穷标记池；chaos_bag / augury 等有限区另建。
	var infinite := region_id == SUPPLY
	ops.create_marker_region(region_id, infinite)
