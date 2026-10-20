class_name PhysicalTestHelper
extends RefCounted

## PHYS-* 物理层基础竖切。


static func make_ops() -> PhysicalOps:
	return PhysicalOps.new(PhysicalStore.new())


static func test_set_aside_to_deck_shuffle() -> bool:
	var ops := make_ops()
	var set_aside := ops.create_card_region(CardRegion.Shape.FLAT, &"", &"set_aside")
	var deck := ops.create_card_region(CardRegion.Shape.DECK, &"", &"encounter_deck")
	for i in 3:
		var cid := StringName("scen_%d" % i)
		if not ops.materialize_card(cid, cid, set_aside):
			return false
	for i in 3:
		var cid := StringName("scen_%d" % i)
		if not ops.move_card(cid, deck, AhcEnums.InsertMode.BOTTOM):
			return false
	var aside := ops.store.get_card_region(set_aside)
	var d := ops.store.get_card_region(deck)
	if aside == null or d == null:
		return false
	if not aside.is_empty() or d.size() != 3:
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	if not ops.shuffle(deck, rng):
		return false
	return d.size() == 3 and ops.store.get_card(&"scen_0").region_id == deck


static func test_marker_transfer_pool_to_card() -> bool:
	var ops := make_ops()
	var supply := ops.create_marker_region(&"supply")
	var set_aside := ops.create_card_region(CardRegion.Shape.FLAT, &"", &"set_aside")
	if not ops.materialize_card(&"enemy_1", &"e1", set_aside):
		return false
	ops.add_markers(MarkerLocus.region(supply), MarkerKeys.DAMAGE, 5)
	var ok := ops.transfer(
		MarkerKeys.DAMAGE,
		2,
		MarkerLocus.region(supply),
		MarkerLocus.card(&"enemy_1")
	)
	if not ok:
		return false
	return (
		ops.get_count(MarkerLocus.region(supply), MarkerKeys.DAMAGE) == 3
		and ops.get_count(MarkerLocus.card(&"enemy_1"), MarkerKeys.DAMAGE) == 2
	)


static func test_augury_reveal_and_return() -> bool:
	var ops := make_ops()
	var bag := ops.create_marker_region(&"chaos_bag")
	var augury := ops.create_marker_region(&"augury")
	var key := MarkerKeys.chaos_numeric(-2)
	ops.add_markers(MarkerLocus.region(bag), key, 2)
	ops.add_markers(MarkerLocus.region(bag), MarkerKeys.chaos_symbol(&"SKULL"), 1)
	if not ops.transfer(key, 1, MarkerLocus.region(bag), MarkerLocus.region(augury)):
		return false
	if ops.get_count(MarkerLocus.region(bag), key) != 1:
		return false
	if ops.get_count(MarkerLocus.region(augury), key) != 1:
		return false
	if not ops.transfer(key, 1, MarkerLocus.region(augury), MarkerLocus.region(bag)):
		return false
	return (
		ops.get_count(MarkerLocus.region(bag), key) == 2
		and ops.get_count(MarkerLocus.region(augury), key) == 0
		and ops.store.get_marker_region(augury).is_empty()
	)


static func test_card_face_exhaust() -> bool:
	var ops := make_ops()
	var flat := ops.create_card_region(CardRegion.Shape.FLAT)
	if not ops.materialize_card(&"c1", &"def", flat):
		return false
	if not ops.set_face(&"c1", AhcEnums.CardFace.B):
		return false
	if not ops.set_exhausted(&"c1", true):
		return false
	var card := ops.store.get_card(&"c1")
	return card != null and card.face == AhcEnums.CardFace.B and card.exhausted


static func test_destroy_requires_empty() -> bool:
	var ops := make_ops()
	var region := ops.create_card_region(CardRegion.Shape.FLAT, &"", &"box")
	ops.materialize_card(&"c1", &"d", region)
	if ops.destroy_card_region(region):
		return false
	ops.move_card(&"c1", ops.create_card_region(CardRegion.Shape.FLAT, &"", &"other"))
	return ops.destroy_card_region(region)


static func test_player_resource_pool() -> bool:
	var ops := make_ops()
	ops.add_player(&"p1", 0)
	var supply := ops.create_marker_region(&"supply")
	var pool := ops.create_marker_region(&"resource_p1")
	ops.add_markers(MarkerLocus.region(supply), MarkerKeys.RESOURCE, 30)
	if not ops.transfer(
		MarkerKeys.RESOURCE,
		5,
		MarkerLocus.region(supply),
		MarkerLocus.region(pool)
	):
		return false
	return ops.get_count(MarkerLocus.region(pool), MarkerKeys.RESOURCE) == 5
