class_name DrawInvestigatorComposition
extends RefCounted

const PENDING_KEY := &"draw_pending"
const SHUFFLES_KEY := &"draw_shuffles"
const HORROR_KEY := &"draw_horror_taken"


## mid-draw：洗弃牌堆 + 1 horror（L1 Seq of L0 atoms）。
static func shuffle_and_horror(inv_id: StringName) -> CompositionNode:
	return CompositionNode.seq(
		[
			CompositionNode.shuffle_discard_into_deck(inv_id),
			CompositionNode.adjust_marker(
				MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.HORROR_TAKEN),
				1
			),
		]
	)


## D2：批量 reveal（L1 Seq of Information bricks）。
static func reveal_batch(inv_id: StringName, card_ids: Array) -> CompositionNode:
	var steps: Array = []
	for card_id in card_ids:
		steps.append(CompositionNode.reveal_to_controller(card_id as StringName, inv_id))
	return CompositionNode.seq(steps)


## D3：批量 enter_hand（L1 Seq of L0 move / limbo commits）。
static func enter_hand_batch(inv_id: StringName, card_ids: Array) -> CompositionNode:
	var steps: Array = []
	for card_id in card_ids:
		steps.append(CompositionNode.commit_enter_hand(card_id as StringName, inv_id))
	return CompositionNode.seq(steps)


static func init_draw_state(memory: RulesMemory, inv_id: StringName) -> void:
	if memory == null:
		return
	memory.set_referent(inv_id, PENDING_KEY, [] as Array[StringName])
	memory.set_referent(inv_id, SHUFFLES_KEY, 0)
	memory.set_referent(inv_id, HORROR_KEY, 0)


static func pending_cards(memory: RulesMemory, inv_id: StringName) -> Array[StringName]:
	if memory == null:
		return []
	var bucket: Array = memory.get_referent(inv_id, PENDING_KEY) as Array
	if bucket == null:
		return []
	var out: Array[StringName] = []
	for card_id in bucket:
		out.append(card_id as StringName)
	return out


static func pending_count(memory: RulesMemory, inv_id: StringName) -> int:
	return pending_cards(memory, inv_id).size()


static func append_pending(memory: RulesMemory, inv_id: StringName, card_id: StringName) -> void:
	if memory == null or card_id == &"":
		return
	var bucket: Array = memory.get_referent(inv_id, PENDING_KEY) as Array
	if bucket == null:
		bucket = []
	bucket.append(card_id)
	memory.set_referent(inv_id, PENDING_KEY, bucket)


static func increment_shuffle_horror(memory: RulesMemory, inv_id: StringName) -> void:
	if memory == null:
		return
	var shuffles := int(memory.get_referent(inv_id, SHUFFLES_KEY))
	var horror := int(memory.get_referent(inv_id, HORROR_KEY))
	memory.set_referent(inv_id, SHUFFLES_KEY, shuffles + 1)
	memory.set_referent(inv_id, HORROR_KEY, horror + 1)
