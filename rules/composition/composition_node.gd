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
var pending_id: StringName = &""
var effect_request: EffectRequest = null
var source_ability_id: StringName = &""
var interrupt_mode: StringName = &""
var interrupt_target: InterruptTarget = null
var replace_target: ReplacementTarget = null


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


## L0 · treachery/asset 弱点进入威胁区（从 limbo / hand）。
static func enter_threat_area(card_id: StringName, inv_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"enter_threat_area"
	n.card_id = card_id
	n.inv_id = inv_id
	return n


static func lose_all_resources(inv_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"lose_all_resources"
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


## L2 · 统一打断节点（07 §6.0：Cancel / Ignore 均 nest seq.interrupt.* 或本节点）。
static func interrupt(mode: StringName, target: InterruptTarget) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"interrupt"
	n.interrupt_mode = mode
	n.interrupt_target = target
	if target != null and target.pending_id != &"":
		n.pending_id = target.pending_id
	return n


static func interrupt_cancel(target: InterruptTarget) -> CompositionNode:
	return interrupt(&"cancel", target)


static func interrupt_ignore(target: InterruptTarget) -> CompositionNode:
	return interrupt(&"ignore", target)


## 竖切占位：等价 interrupt_cancel(InterruptTarget.pending_impact(...))。
static func cancel_pending(pending_id: StringName) -> CompositionNode:
	return interrupt_cancel(InterruptTarget.pending_impact(pending_id))


## 竖切占位：等价 interrupt_ignore(InterruptTarget.pending_impact(...))。
static func ignore_pending(pending_id: StringName) -> CompositionNode:
	return interrupt_ignore(InterruptTarget.pending_impact(pending_id))


## L2 · 统一 Instead 节点（07 §7.0：nest seq.replace.instead 或本节点）。
static func replace_instead(
	target: ReplacementTarget,
	replacement: EffectRequest,
	source_ability_id: StringName = &""
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"replace_instead"
	n.replace_target = target
	n.effect_request = replacement
	n.source_ability_id = source_ability_id
	if target != null and target.pending_id != &"":
		n.pending_id = target.pending_id
	return n


## 竖切占位：等价 replace_instead(ReplacementTarget.pending(...), ...)。
static func replace_pending(
	pending_id: StringName,
	replacement: EffectRequest,
	source_ability_id: StringName = &""
) -> CompositionNode:
	return replace_instead(
		ReplacementTarget.pending(pending_id), replacement, source_ability_id
	)


## L2 · Resolve pending（Cancel / Replacement 窗口结束后执行）。
static func resolve_pending(pending_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"resolve_pending"
	n.pending_id = pending_id
	return n
