class_name PhysicalTestHelper
extends RefCounted

## PHYS-* 物理层基础竖切。


static func make_ops() -> PhysicalOps:
	return PhysicalOps.new(PhysicalStore.new())


static func test_set_aside_to_deck_shuffle() -> bool:
	var ops := make_ops()
	var set_aside := ops.create_card_region(CardRegion.Shape.FLAT, &"", &"set_aside")
	var deck := ops.create_card_region(CardRegion.Shape.DECK, &"", &"encounter_deck")
	var ids: Array[StringName] = []
	for i in 3:
		var eid := ops.materialize_card(StringName("def_%d" % i), set_aside)
		if eid == &"":
			return false
		ids.append(eid)
	for eid in ids:
		if not ops.move_card(eid, deck, AhcEnums.InsertMode.BOTTOM):
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
	var first: StringName = ids[0]
	return d.size() == 3 and ops.store.get_card(first).region_id == deck


static func test_marker_transfer_pool_to_card() -> bool:
	var ops := make_ops()
	var supply := ops.create_marker_region(&"supply")
	var set_aside := ops.create_card_region(CardRegion.Shape.FLAT, &"", &"set_aside")
	var enemy_id := ops.materialize_card(&"e1", set_aside)
	if enemy_id == &"":
		return false
	ops.add_markers(MarkerLocus.region(supply), MarkerKeys.DAMAGE, 5)
	var ok := ops.transfer(
		MarkerKeys.DAMAGE,
		2,
		MarkerLocus.region(supply),
		MarkerLocus.card(enemy_id)
	)
	if not ok:
		return false
	return (
		ops.get_count(MarkerLocus.region(supply), MarkerKeys.DAMAGE) == 3
		and ops.get_count(MarkerLocus.card(enemy_id), MarkerKeys.DAMAGE) == 2
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
	var cid := ops.materialize_card(&"def", flat)
	if cid == &"":
		return false
	if not ops.set_face(cid, AhcEnums.CardFace.B):
		return false
	if not ops.set_exhausted(cid, true):
		return false
	var card := ops.store.get_card(cid)
	return card != null and card.face == AhcEnums.CardFace.B and card.exhausted


static func test_destroy_requires_empty() -> bool:
	var ops := make_ops()
	var region := ops.create_card_region(CardRegion.Shape.FLAT, &"", &"box")
	var cid := ops.materialize_card(&"d", region)
	if ops.destroy_card_region(region):
		return false
	var other := ops.create_card_region(CardRegion.Shape.FLAT, &"", &"other")
	ops.move_card(cid, other)
	return ops.destroy_card_region(region)


static func test_player_resource_pool() -> bool:
	var ops := make_ops()
	var player := ops.add_player()
	if player == null:
		return false
	var supply := ops.create_marker_region(&"supply")
	var pool := ops.create_marker_region(StringName("resource_%s" % String(player.id)))
	ops.add_markers(MarkerLocus.region(supply), MarkerKeys.RESOURCE, 30)
	if not ops.transfer(
		MarkerKeys.RESOURCE,
		5,
		MarkerLocus.region(supply),
		MarkerLocus.region(pool)
	):
		return false
	return ops.get_count(MarkerLocus.region(pool), MarkerKeys.RESOURCE) == 5


static func test_entity_id_alloc_not_definition() -> bool:
	var ops := make_ops()
	var a := ops.materialize_card(&"12106")
	var b := ops.materialize_card(&"12106")
	if a == &"" or b == &"" or a == b:
		return false
	var ca := ops.store.get_card(a)
	var cb := ops.store.get_card(b)
	if ca == null or cb == null:
		return false
	if ca.definition_id != &"12106" or cb.definition_id != &"12106":
		return false
	if not ops.dematerialize_card(a):
		return false
	var c := ops.materialize_card(&"12107")
	## 不复用已回收的 a
	return c != &"" and c != a and ops.store.get_card(a) == null


static func test_bridge_move_mirrors() -> bool:
	var h := RuleTestHarness.new(91)
	var ctx := h.ctx
	var inv := ctx.state.registry.get_investigator(&"inv_1")
	if inv == null or inv.deck.is_empty():
		GameBootstrap.setup_minimal_investigator(ctx, &"inv_1")
		inv = ctx.state.registry.get_investigator(&"inv_1")
	if inv == null or inv.deck.is_empty():
		## 造一张库顶卡
		var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, &"bridge_c1", &"bridge_def")
		var card := CardInstance.new()
		card.id = eid
		card.owner_id = &"inv_1"
		card.controller_id = &"inv_1"
		card.zone = AhcEnums.Zone.DECK
		ctx.state.registry.register_card(card)
		inv.deck.append(&"bridge_c1")
	var card_id: StringName = inv.deck[0]
	if not ctx.mutator.move_card(card_id, CardSlot.hand_bottom(&"inv_1")):
		return false
	var phys := ctx.state.physical.get_card(card_id)
	if phys == null:
		return false
	return phys.region_id == StringName("hand_inv_1")


static func test_bridge_resource_adjust_mirrors() -> bool:
	var h := RuleTestHarness.new(92)
	var ctx := h.ctx
	if ctx.state.registry.get_investigator(&"inv_1") == null:
		GameBootstrap.setup_minimal_investigator(ctx, &"inv_1")
	if not ctx.mutator.adjust_marker(
		MarkerSlot.investigator(&"inv_1", AhcEnums.MarkerKind.RESOURCE), 3
	):
		return false
	var locus := MarkerLocus.region(StringName("resource_inv_1"))
	return ctx.state.physical_ops.get_count(locus, MarkerKeys.RESOURCE) == 3


static func test_bridge_reveal_mirrors_flip() -> bool:
	var h := RuleTestHarness.new(93)
	var ctx := h.ctx
	if ctx.state.registry.get_investigator(&"inv_1") == null:
		GameBootstrap.setup_minimal_investigator(ctx, &"inv_1")
	var eid := EntityId.create(AhcEnums.EntityKind.PLAYER_CARD, &"bridge_rev", &"bridge_def")
	var card := CardInstance.new()
	card.id = eid
	card.owner_id = &"inv_1"
	card.controller_id = &"inv_1"
	card.zone = AhcEnums.Zone.HAND
	card.face = AhcEnums.CardFace.B
	ctx.state.registry.register_card(card)
	ctx.state.registry.get_investigator(&"inv_1").hand.append(&"bridge_rev")
	## 物理先落 B，揭示应翻到 A
	ctx.state.physical_binding.ensure_physical_card(card)
	ctx.state.physical_ops.set_face(&"bridge_rev", AhcEnums.CardFace.B)
	if not ctx.mutator.reveal_to_controller(&"bridge_rev", &"inv_1"):
		return false
	var phys := ctx.state.physical.get_card(&"bridge_rev")
	return (
		phys != null
		and phys.face == AhcEnums.CardFace.A
		and card.face_visibility.audience == AhcEnums.FaceAudience.CONTROLLER
	)
