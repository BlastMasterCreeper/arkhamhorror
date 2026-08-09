class_name CompositionNode
extends RefCounted

## 占位：for_each 循环内绑定当前调查员 id。
const INV_EACH: StringName = &"each_investigator"

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
var branch_condition: Condition = null
var then_branch: CompositionNode = null
var else_branch: CompositionNode = null
var choice_must: bool = false
var choice_prompt_id: StringName = &""
var choice_option_ids: Array[StringName] = []
var test_skill: AhcEnums.SkillType = AhcEnums.SkillType.WILLPOWER
var test_difficulty: int = 0
var st7_plan: SkillTestSt7Plan = null
var repeat_count_source: StringName = &""
var repeat_count_fixed: int = 0
var may_advance_agenda: bool = false
var trait_exclude: Array[StringName] = []
var location_target: StringName = &""
var enemy_ref_id: StringName = &""
var target_investigator_id: StringName = &""
var definition_id: StringName = &""
var location_ids: Array[StringName] = []
var atom_count: int = -1
var scenario_resolution: int = -1
var for_each_source: StringName = &"player_order"


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


## L0 · 动态 keyword（06 §3.2 · G3 gains surge 等）。
static func grant_keyword(card_id: StringName, keyword: StringName) -> CompositionNode:
	return register(RegistrationTemplate.gained_keyword_drawn_card_resolving(card_id, keyword))


## L1 · must choose（07 §3.3 · 16 §7.2.1）：resolve 前 dry-run 过滤 FIZZLE 分支。
static func must_choose(
	branches: Array,
	controller_id: StringName,
	option_ids: Array = [],
	prompt_id: StringName = &"composition:choice_must"
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.CHOICE
	n.inv_id = controller_id
	n.choice_must = true
	n.choice_prompt_id = prompt_id
	for branch in branches:
		if branch is CompositionNode:
			n.children.append(branch as CompositionNode)
	for oid in option_ids:
		n.choice_option_ids.append(oid as StringName)
	var idx := 0
	while n.choice_option_ids.size() < n.children.size():
		n.choice_option_ids.append(StringName("opt_%d" % idx))
		idx += 1
	return n


## L0 · 12124 等：当前密谋放置 1 doom。
static func place_doom_on_current_agenda(may_advance_agenda: bool = false) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"place_doom_on_current_agenda"
	n.may_advance_agenda = may_advance_agenda
	return n


## L0 · 12126 fail-by：卡上 1 clue 放到调查员所在地点。
static func place_clue_on_investigator_location(controller_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"place_clue_on_investigator_location"
	n.inv_id = controller_id
	return n


## L2 · nest `seq.skill_test.*`（revelation 内检定 · 15 §17.5）。
static func nest_skill_test(
	controller_id: StringName,
	skill: AhcEnums.SkillType,
	difficulty: int,
	card_id: StringName = &"",
	st7_plan: SkillTestSt7Plan = null
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"nest_skill_test"
	n.inv_id = controller_id
	n.card_id = card_id
	n.test_skill = skill
	n.test_difficulty = maxi(difficulty, 0)
	n.st7_plan = st7_plan
	return n


static func nest_enemy_resolve_location(
	controller_id: StringName,
	location_target: StringName = &"drawer_location"
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"nest_enemy_resolve_location"
	n.inv_id = controller_id
	n.location_target = location_target
	return n


static func nest_enemy_move(
	controller_id: StringName,
	trait_exclude: Array[StringName] = []
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"nest_enemy_move"
	n.inv_id = controller_id
	n.trait_exclude = trait_exclude.duplicate()
	return n


static func nest_enemy_attack_last() -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"nest_enemy_attack"
	return n


## L1 · 按最近一次检定 fail_by 重复执行 body（12126 · 16 §7.2.1 must 在 body 内）。
static func repeat_fail_by(body: CompositionNode) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.REPEAT
	n.repeat_count_source = &"last_skill_test_fail_by"
	if body != null:
		n.children.append(body)
	return n


## L1 · 情景条件分支（If = L3 条件，非 timing；见 07-composition §3.3）。
static func if_else(
	condition: Condition,
	then_node: CompositionNode,
	else_node: CompositionNode,
	controller_id: StringName
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.IF
	n.branch_condition = condition
	n.then_branch = then_node
	n.else_branch = else_node
	n.inv_id = controller_id
	return n


## L0 · 12160 等：最近无 doom 敌人放置 1 doom（CREATED → CompositionExecutor · 07 §4.4）。
static func place_doom_nearest_enemy_without_doom(
	card_id: StringName,
	controller_id: StringName
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"place_doom_nearest_enemy_without_doom"
	n.card_id = card_id
	n.inv_id = controller_id
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


## L0 · 弃置场上所有敌人（场景指令 / b 面）。
static func discard_all_enemies_in_play() -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"discard_all_enemies_in_play"
	return n


## L0 · 地点进场（可从未揭示 set-aside 状态注册）。
static func put_locations_into_play(ids: Array) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"put_locations_into_play"
	for raw in ids:
		n.location_ids.append(raw as StringName)
	return n


## L0 · 从 set-aside 生成敌人到指定地点。
static func spawn_set_aside_enemy_at(
	enemy_definition_id: StringName,
	location_id: StringName
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"spawn_set_aside_enemy_at"
	n.definition_id = enemy_definition_id
	n.location_target = location_id
	return n


## L0 · 将 set-aside 牌附着到 host 卡（常为地点）。
static func attach_set_aside_to_host(
	definition_id: StringName,
	host_card_id: StringName,
	count: int = 1
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"attach_set_aside_to_host"
	n.definition_id = definition_id
	n.card_id = host_card_id
	n.atom_count = maxi(count, 1)
	return n


## L0 · limbo treachery 附着到最近且无该 definition 附着的地点（Fire! 显现）。
static func attach_limbo_to_nearest_location_without(
	card_id: StringName,
	drawer_id: StringName,
	exclude_attachment_definition_id: StringName = &""
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"attach_limbo_to_nearest_location_without"
	n.card_id = card_id
	n.inv_id = drawer_id
	n.definition_id = exclude_attachment_definition_id
	return n


## L0 · set-aside 复制进遭遇弃牌堆；atom_count < 0 表示全部。
static func discard_set_aside_to_encounter_discard(
	definition_id: StringName,
	count: int = -1
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"discard_set_aside_to_encounter_discard"
	n.definition_id = definition_id
	n.atom_count = count
	return n


## L1 · 按 player order 依次执行 body（跳过 eliminated / resigned）。
static func for_each_player_order(body: CompositionNode) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.FOR_EACH
	n.for_each_source = &"player_order"
	if body != null:
		n.children.append(body)
	return n


## L0 · 调查员受到 horror（场景 b 面 fail 等）。
static func take_horror(inv_id: StringName, amount: int = 1) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"take_horror"
	n.inv_id = inv_id
	n.marker_delta = maxi(amount, 1)
	return n


## L0 · 调查员受到 damage。
static func take_damage(inv_id: StringName, amount: int = 1) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"take_damage"
	n.inv_id = inv_id
	n.marker_delta = maxi(amount, 1)
	return n


## L2 · nest 场景结算 `(→R#)`。
static func nest_scenario_resolution(
	resolution: int,
	source_definition_id: StringName = &""
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"nest_scenario_resolution"
	n.scenario_resolution = resolution
	n.definition_id = source_definition_id
	return n


## L0 · 未 resign 存活调查员 defeated + 可选 trauma。
static func defeat_surviving_non_resigned(
	physical_trauma: int = 0,
	mental_trauma: int = 0
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"defeat_surviving_non_resigned"
	n.marker_delta = physical_trauma
	n.draw_amount = mental_trauma
	return n


static func heal_and_set_aside_enemy(definition_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"heal_and_set_aside_enemy"
	n.definition_id = definition_id
	return n


static func remove_location_from_game(location_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"remove_location_from_game"
	n.card_id = location_id
	return n


static func put_story_asset_from_set_aside(
	definition_id: StringName,
	controller_id: StringName = &"lead_investigator"
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"put_story_asset_from_set_aside"
	n.definition_id = definition_id
	n.location_target = controller_id
	return n


static func place_clues_on_location(location_id: StringName, printed_clues: int) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"place_clues_on_location"
	n.location_target = location_id
	n.atom_count = printed_clues
	return n


static func lead_search_draw_encounter_copies(
	definition_id: StringName,
	per_investigator: bool = false
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"lead_search_draw_encounter_copies"
	n.definition_id = definition_id
	n.flag_value = per_investigator
	return n


static func lead_draw_topmost_encounter_discard_copy(
	definition_id: StringName
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"lead_draw_topmost_encounter_discard_copy"
	n.definition_id = definition_id
	return n
