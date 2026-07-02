class_name CompositionNode
extends RefCounted

var kind: AhcEnums.CompositionNodeKind = AhcEnums.CompositionNodeKind.SEQ
var children: Array[CompositionNode] = []
var inv_id: StringName = &""
var card_id: StringName = &""
var atom_op: AhcEnums.AtomOp = AhcEnums.AtomOp.MOVE_CARD
var atom_name: StringName = &""
var draw_amount: int = 1
var marker_delta: int = 0
var flag_field: AhcEnums.FlagField = AhcEnums.FlagField.ELIMINATED
var flag_value: Variant = true
var to_slot: CardSlot = null
var marker_slot: MarkerSlot = null
var register_template: RegistrationTemplate = null
var provenance: AbilityUnitRef = null


static func seq(nodes: Array) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.SEQ
	for child in nodes:
		n.children.append(child as CompositionNode)
	return n


## L2 宏 · 调查员抽牌指令（展开为 DrawInvestigatorFlow 原子链）。
static func draw(inv_id: StringName, amount: int = 1) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.inv_id = inv_id
	n.atom_name = &"draw"
	n.draw_amount = maxi(amount, 1)
	return n


## L0 · AtomMoveCard
static func move_card(card_id: StringName, to: CardSlot) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_op = AhcEnums.AtomOp.MOVE_CARD
	n.atom_name = &"move_card"
	n.card_id = card_id
	n.to_slot = to
	return n


## L0 · AtomAdjustMarker
static func adjust_marker(at: MarkerSlot, delta: int) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_op = AhcEnums.AtomOp.ADJUST_MARKER
	n.atom_name = &"adjust_marker"
	n.marker_slot = at
	n.marker_delta = delta
	return n


## L0 · AtomSetFlag
static func set_flag(bearer_id: StringName, field: AhcEnums.FlagField, value: Variant) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_op = AhcEnums.AtomOp.SET_FLAG
	n.atom_name = &"set_flag"
	n.inv_id = bearer_id
	n.flag_field = field
	n.flag_value = value
	return n


## L0 · AtomRevealCard（Grimoire Reveal 揭示卡牌；写 FaceAudience）
static func reveal_to_controller(card_id: StringName, controller_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_op = AhcEnums.AtomOp.REVEAL_CARD
	n.atom_name = &"reveal_to_controller"
	n.card_id = card_id
	n.inv_id = controller_id
	return n


static func reveal_to_all(card_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_op = AhcEnums.AtomOp.REVEAL_CARD
	n.atom_name = &"reveal_to_all"
	n.card_id = card_id
	return n


static func commit_hidden_enter_hand(card_id: StringName, inv_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"commit_hidden_enter_hand"
	n.card_id = card_id
	n.inv_id = inv_id
	return n


## L0 · pop deck top（结果写入 RulesMemory draw_pending）。
static func pop_deck_top(inv_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"pop_deck_top"
	n.inv_id = inv_id
	return n


## Domain pile op · 洗弃牌堆进牌库（非 L0 效果原子）。
static func shuffle_discard_into_deck(inv_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"shuffle_discard_into_deck"
	n.inv_id = inv_id
	return n


## D3 · enter_hand（HAND 或 LIMBO，按卡定义）。
static func commit_enter_hand(card_id: StringName, inv_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"commit_enter_hand"
	n.card_id = card_id
	n.inv_id = inv_id
	return n


## L0 · 隐私（Hidden）暴露显现（清 is_hidden + ALL；须先于 spawn_encounter_enemy）。
static func expose_hidden(card_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"expose_hidden"
	n.card_id = card_id
	return n


## L2 · nest `seq.encounter.spawn`（须 preceded by expose_hidden / reveal 等显现步骤）。
static func spawn_encounter_enemy(card_id: StringName, inv_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"spawn_encounter_enemy"
	n.card_id = card_id
	n.inv_id = inv_id
	return n


## L0 · 隐私/遭遇 treachery 卡面弃置（unregister 离手限制 → 遭遇弃牌堆）。
static func discard_encounter_from_hand(card_id: StringName, inv_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"discard_encounter_from_hand"
	n.card_id = card_id
	n.inv_id = inv_id
	return n


static func register(template: RegistrationTemplate) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.REGISTER
	n.register_template = template
	return n
