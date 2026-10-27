class_name PhysicalOps
extends RefCounted

## 物理层原子行为。由信息层组合调用；不解释规则含义。

var store: PhysicalStore


func _init(physical_store: PhysicalStore) -> void:
	store = physical_store


# --- 玩家 ---

## player_id 为空则 store 分配实体 id（如 player_1）。
func add_player(player_id: StringName = &"", seat_index: int = 0) -> PhysicalPlayer:
	var id := player_id
	if id == &"":
		id = store.alloc_entity_id(&"player")
	elif store.get_player(id) != null:
		return null
	var p := PhysicalPlayer.new()
	p.id = id
	p.seat_index = seat_index
	store.players[id] = p
	return p


# --- 卡区 ---

func create_card_region(
	shape: int,
	owner_player_id: StringName = &"",
	region_id: StringName = &""
) -> StringName:
	var id := region_id
	if id == &"":
		id = store.alloc_region_id(&"card_region")
	var region := CardRegion.new()
	region.id = id
	region.shape = shape
	region.owner_player_id = owner_player_id
	store.card_regions[id] = region
	return id


func destroy_card_region(region_id: StringName) -> bool:
	var region := store.get_card_region(region_id)
	if region == null or not region.is_empty():
		return false
	store.card_regions.erase(region_id)
	return true


# --- 标记区 ---

func create_marker_region(region_id: StringName = &"", infinite: bool = false) -> StringName:
	var id := region_id
	if id == &"":
		id = store.alloc_region_id(&"marker_region")
	var region := MarkerRegion.new()
	region.id = id
	region.infinite = infinite
	store.marker_regions[id] = region
	return id


func destroy_marker_region(region_id: StringName) -> bool:
	var region := store.get_marker_region(region_id)
	if region == null or not region.is_empty():
		return false
	store.marker_regions.erase(region_id)
	return true


# --- 卡牌实体 ---

## 物化一张卡。card_id 为空则分配实体 id；definition_id 为牌面/目录编号。
## 返回实体 id；失败返回 &""。
func materialize_card(
	definition_id: StringName,
	into_region_id: StringName = &"",
	card_id: StringName = &""
) -> StringName:
	var id := card_id
	if id == &"":
		id = store.alloc_entity_id(&"card")
	elif store.get_card(id) != null:
		return &""
	var card := PhysicalCard.new()
	card.id = id
	card.definition_id = definition_id
	store.cards[id] = card
	if into_region_id != &"":
		if not move_card(id, into_region_id):
			store.cards.erase(id)
			return &""
	return id


## 从物理层移除卡实体（须先不在任何区，或一并从当前区摘掉）。
func dematerialize_card(card_id: StringName) -> bool:
	var card := store.get_card(card_id)
	if card == null:
		return false
	if card.region_id != &"":
		var region := store.get_card_region(card.region_id)
		if region != null:
			region.card_ids.erase(card_id)
		card.region_id = &""
	store.cards.erase(card_id)
	return true


func move_card(
	card_id: StringName,
	to_region_id: StringName,
	insert: AhcEnums.InsertMode = AhcEnums.InsertMode.BOTTOM
) -> bool:
	var card := store.get_card(card_id)
	var to_region := store.get_card_region(to_region_id)
	if card == null or to_region == null:
		return false
	if card.region_id != &"":
		var from_region := store.get_card_region(card.region_id)
		if from_region == null:
			return false
		from_region.card_ids.erase(card_id)
	_insert_card(to_region, card_id, insert)
	card.region_id = to_region_id
	if to_region.shape == CardRegion.Shape.FLAT:
		card.display_order = to_region.card_ids.find(card_id)
	return true


func shuffle(region_id: StringName, rng: RandomNumberGenerator = null) -> bool:
	var region := store.get_card_region(region_id)
	if region == null or region.shape != CardRegion.Shape.DECK:
		return false
	if region.card_ids.size() <= 1:
		return true
	var r := rng
	if r == null:
		r = RandomNumberGenerator.new()
		r.randomize()
	for i in range(region.card_ids.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var tmp: StringName = region.card_ids[i]
		region.card_ids[i] = region.card_ids[j]
		region.card_ids[j] = tmp
	return true


func set_face(card_id: StringName, face: AhcEnums.CardFace) -> bool:
	var card := store.get_card(card_id)
	if card == null:
		return false
	card.face = face
	return true


func set_exhausted(card_id: StringName, exhausted: bool) -> bool:
	var card := store.get_card(card_id)
	if card == null:
		return false
	card.exhausted = exhausted
	return true


func set_display_order(card_id: StringName, order: int) -> bool:
	var card := store.get_card(card_id)
	if card == null:
		return false
	card.display_order = order
	return true


# --- 标记 ---

func transfer(
	key: StringName,
	amount: int,
	from_locus: MarkerLocus,
	to_locus: MarkerLocus
) -> bool:
	if amount <= 0 or key == &"":
		return false
	if not _take(from_locus, key, amount):
		return false
	_give(to_locus, key, amount)
	return true


func add_markers(locus: MarkerLocus, key: StringName, amount: int) -> bool:
	if amount <= 0 or key == &"":
		return false
	_give(locus, key, amount)
	return true


func remove_markers(locus: MarkerLocus, key: StringName, amount: int) -> bool:
	if amount <= 0 or key == &"":
		return false
	return _take(locus, key, amount)


func clear_key(locus: MarkerLocus, key: StringName) -> bool:
	if not _has_locus(locus):
		return false
	var counts: Dictionary = _counts_of(locus)
	counts.erase(key)
	return true


func get_count(locus: MarkerLocus, key: StringName) -> int:
	if not _has_locus(locus):
		return 0
	var counts: Dictionary = _counts_of(locus)
	return int(counts.get(key, 0))


# --- 内部 ---

func _insert_card(
	region: CardRegion,
	card_id: StringName,
	insert: AhcEnums.InsertMode
) -> void:
	if region.shape == CardRegion.Shape.DECK and insert == AhcEnums.InsertMode.TOP:
		region.card_ids.insert(0, card_id)
	else:
		region.card_ids.append(card_id)


func _has_locus(locus: MarkerLocus) -> bool:
	if locus == null:
		return false
	if locus.kind == MarkerLocus.Kind.REGION:
		return store.get_marker_region(locus.id) != null
	return store.get_card(locus.id) != null


func _counts_of(locus: MarkerLocus) -> Dictionary:
	if locus.kind == MarkerLocus.Kind.REGION:
		return store.get_marker_region(locus.id).counts
	return store.get_card(locus.id).markers


func _take(locus: MarkerLocus, key: StringName, amount: int) -> bool:
	if not _has_locus(locus):
		return false
	if locus.kind == MarkerLocus.Kind.REGION:
		var region := store.get_marker_region(locus.id)
		if region != null and region.infinite:
			return amount > 0
	var counts: Dictionary = _counts_of(locus)
	var have := int(counts.get(key, 0))
	if have < amount:
		return false
	var left := have - amount
	if left <= 0:
		counts.erase(key)
	else:
		counts[key] = left
	return true


func _give(locus: MarkerLocus, key: StringName, amount: int) -> void:
	if not _has_locus(locus):
		return
	if locus.kind == MarkerLocus.Kind.REGION:
		var region := store.get_marker_region(locus.id)
		if region != null and region.infinite:
			return
	var counts: Dictionary = _counts_of(locus)
	counts[key] = int(counts.get(key, 0)) + amount
