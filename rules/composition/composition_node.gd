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
var nest_flow_id: StringName = &""
var is_direct: bool = false
var place_doom_target: StringName = &""
## PI / 步间指称：RulesMemory key（如 picked_enemy）。
var memory_key: StringName = &""
## pick_target 候选过滤预设（如 enemy_at_connecting）；优先用 selection_spec。
var target_filter: StringName = &""
## 通用选择规格（21-selection-spec）；非空时覆盖 target_filter/memory_key。
var selection_spec: SelectionSpec = null
## nest_engage / nest_enemy_move_to 等模式或开关载荷。
var engage_mode: StringName = &"effect"
var auto_engage: bool = true


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
	return nest_lose_all_resources(inv_id)


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


## 卡面 gains keyword · nest `seq.effect.register`（不是真空 REGISTER）。
static func grant_keyword(card_id: StringName, keyword: StringName) -> CompositionNode:
	return nest_effect_register(
		RegistrationTemplate.gained_keyword_drawn_card_resolving(card_id, keyword)
	)


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


## L1 · Optional / may（16 §7.2 · 21 §4.1）：resolve 前 OPTIONAL_EFFECT；否 → 跳过子树。
## 默认跳过；body dry-run FIZZLE 时不 ask。memory_key 非空则 bind.shape=bool。
static func optional(
	body: CompositionNode,
	controller_id: StringName,
	prompt_id: StringName = &"composition:choice_optional",
	memory_key: StringName = &""
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.OPTIONAL
	n.inv_id = controller_id
	n.choice_must = false
	n.choice_prompt_id = prompt_id
	n.memory_key = memory_key
	if body != null:
		n.children.append(body)
	return n


## 编译糖 alias：template=`choice_optional`。
static func choice_optional(
	body: CompositionNode,
	controller_id: StringName,
	prompt_id: StringName = &"composition:choice_optional",
	memory_key: StringName = &""
) -> CompositionNode:
	return optional(body, controller_id, prompt_id, memory_key)


## 当前密谋放置 1 doom · nest `seq.mythos.place_doom`（议程信封，供 Forced AFTER 订阅）。
static func place_doom_on_current_agenda(may_advance_agenda: bool = false) -> CompositionNode:
	return nest_mythos_place_doom(may_advance_agenda)


## 调查员线索放到所在地点 · nest `seq.effect.place_clue`。
static func place_clue_on_investigator_location(controller_id: StringName) -> CompositionNode:
	return nest_place_clue(controller_id)


## L2 · nest `seq.skill_test`（revelation 内检定 · params.skill · 15 §17.5）。
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
	n.nest_flow_id = &"seq.enemy.attack"
	return n


static func nest_enemy_attack(enemy_id: StringName, target: StringName) -> CompositionNode:
	var n := nest_enemy_attack_last()
	n.enemy_ref_id = enemy_id
	n.target_investigator_id = target
	return n


## L0 · 横置来源卡（Free / Action 费用常用）。
static func exhaust_card(card_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"exhaust_card"
	n.card_id = card_id
	return n


## L0 · 横置敌人（choose and exhaust an enemy；支持 memory: 指称）。
static func exhaust_enemy(
	controller_id: StringName,
	enemy_spec: StringName = &"memory:picked_enemy",
	source_card_id: StringName = &""
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"exhaust_enemy"
	n.inv_id = controller_id
	n.card_id = source_card_id
	n.enemy_ref_id = enemy_spec
	return n


## L0 · 对敌人造成伤害（Fight V / 效果体；支持 memory: 指称）。
static func deal_damage_enemy(
	controller_id: StringName,
	enemy_spec: StringName = &"memory:picked_enemy",
	amount: int = 1,
	source_card_id: StringName = &""
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"deal_damage_enemy"
	n.inv_id = controller_id
	n.card_id = source_card_id
	n.enemy_ref_id = enemy_spec
	n.marker_delta = maxi(amount, 1)
	return n


## L0 · 敌人脱离交战（Evade 成功体之一；支持 memory: 指称）。
static func disengage_enemy(
	controller_id: StringName,
	enemy_spec: StringName = &"memory:picked_enemy",
	source_card_id: StringName = &""
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"disengage_enemy"
	n.inv_id = controller_id
	n.card_id = source_card_id
	n.enemy_ref_id = enemy_spec
	return n


## L1 · 调查员移动到指定地点（无 PI；destination 可为 memory:）。
static func nest_move_to(
	controller_id: StringName,
	location_spec: StringName = &"memory:picked_location",
	source_card_id: StringName = &""
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"nest_move_to"
	n.inv_id = controller_id
	n.card_id = source_card_id
	n.location_target = location_spec
	return n


## Move to a connecting location：PI select + nest_move_to（无内嵌 Gate）。
static func move_to_connecting(controller_id: StringName) -> CompositionNode:
	var spec := SelectionSpec.pick_entity(
		CandidateFilter.from_preset(&"location_connecting"),
		&"pick:move_connecting",
		&"picked_location"
	)
	return seq([
		select_entities(controller_id, spec),
		nest_move_to(controller_id, &"memory:picked_location"),
	])


## 兼容旧 template=`nest_move_connecting`：展开为 move_to_connecting。
static func nest_move_connecting(controller_id: StringName) -> CompositionNode:
	return move_to_connecting(controller_id)


## L1 · 获得资源（反应/效果；nest `seq.gain_resource`）。
static func nest_gain_resource(controller_id: StringName, amount: int = 1) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"nest_gain_resource"
	n.inv_id = controller_id
	n.marker_delta = maxi(amount, 1)
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


## 最近无 doom 敌人放置 1 doom · nest `seq.effect.place_doom`。
static func place_doom_nearest_enemy_without_doom(
	card_id: StringName,
	controller_id: StringName
) -> CompositionNode:
	return nest_place_doom(controller_id, card_id, &"nearest_enemy_without_doom")


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


## limbo treachery 附着 · nest `seq.effect.attach`。
static func attach_limbo_to_nearest_location_without(
	card_id: StringName,
	drawer_id: StringName,
	exclude_attachment_definition_id: StringName = &""
) -> CompositionNode:
	var n := nest_attach(card_id, drawer_id, &"nearest_without_same")
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


## 调查员受到 horror · nest `seq.effect.damage`（kind=horror）。
static func take_horror(inv_id: StringName, amount: int = 1, is_direct: bool = false) -> CompositionNode:
	return nest_take_horror(inv_id, amount, is_direct)


## 调查员受到 damage · nest `seq.effect.damage`（kind=damage）。
static func take_damage(inv_id: StringName, amount: int = 1, is_direct: bool = false) -> CompositionNode:
	return nest_take_damage(inv_id, amount, is_direct)


static func _nest_leaf(atom_name: StringName, flow_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = atom_name
	n.nest_flow_id = flow_id
	return n


## 造成伤害/恐惧（Dealing Damage/Horror）· take/deal 同 seq。
static func nest_damage(
	controller_id: StringName,
	kind: StringName = &"damage",
	amount: int = 1,
	is_direct: bool = false,
	target: StringName = &"controller",
	source_card_id: StringName = &""
) -> CompositionNode:
	var n := _nest_leaf(&"nest_damage", &"seq.effect.damage")
	n.inv_id = controller_id
	n.marker_delta = maxi(amount, 1)
	n.is_direct = is_direct
	n.location_target = target
	n.card_id = source_card_id
	n.definition_id = kind
	return n


static func nest_take_horror(
	inv_id: StringName,
	amount: int = 1,
	is_direct: bool = false,
	target: StringName = &"controller",
	source_card_id: StringName = &""
) -> CompositionNode:
	return nest_damage(inv_id, &"horror", amount, is_direct, target, source_card_id)


static func nest_take_damage(
	inv_id: StringName,
	amount: int = 1,
	is_direct: bool = false,
	target: StringName = &"controller",
	source_card_id: StringName = &""
) -> CompositionNode:
	return nest_damage(inv_id, &"damage", amount, is_direct, target, source_card_id)


static func nest_lose_resources(inv_id: StringName, amount: int = 1) -> CompositionNode:
	var n := _nest_leaf(&"nest_lose_resources", &"seq.effect.lose_resources")
	n.inv_id = inv_id
	n.marker_delta = maxi(amount, 1)
	return n


static func nest_lose_all_resources(inv_id: StringName) -> CompositionNode:
	var n := _nest_leaf(&"nest_lose_resources", &"seq.effect.lose_resources")
	n.inv_id = inv_id
	n.marker_delta = 0
	n.definition_id = &"all"
	return n


static func nest_heal(inv_id: StringName, kind: StringName, amount: int = 1) -> CompositionNode:
	var n := _nest_leaf(&"nest_heal", &"seq.effect.heal")
	n.inv_id = inv_id
	n.marker_delta = maxi(amount, 1)
	var marker := AhcEnums.MarkerKind.DAMAGE
	if kind == &"horror":
		marker = AhcEnums.MarkerKind.HORROR_TAKEN
	n.marker_slot = MarkerSlot.investigator(inv_id, marker)
	return n


static func nest_lose_action(inv_id: StringName, amount: int = 1) -> CompositionNode:
	var n := _nest_leaf(&"nest_lose_action", &"seq.effect.lose_action")
	n.inv_id = inv_id
	n.marker_delta = maxi(amount, 1)
	return n


static func nest_place_doom(
	controller_id: StringName,
	card_id: StringName,
	target: StringName,
	amount: int = 1
) -> CompositionNode:
	var n := _nest_leaf(&"nest_place_doom", &"seq.effect.place_doom")
	n.inv_id = controller_id
	n.card_id = card_id
	n.place_doom_target = target
	n.marker_delta = maxi(amount, 1)
	return n


static func nest_mythos_place_doom(may_advance_agenda: bool = false) -> CompositionNode:
	var n := _nest_leaf(&"nest_mythos_place_doom", &"seq.mythos.place_doom")
	n.may_advance_agenda = may_advance_agenda
	return n


static func nest_place_clue(controller_id: StringName) -> CompositionNode:
	var n := _nest_leaf(&"nest_place_clue", &"seq.effect.place_clue")
	n.inv_id = controller_id
	return n


static func nest_effect_register(template: RegistrationTemplate) -> CompositionNode:
	var n := _nest_leaf(&"nest_effect_register", &"seq.effect.register")
	n.register_template = template
	return n


static func nest_effect_unregister(reg_id: StringName) -> CompositionNode:
	var n := _nest_leaf(&"nest_effect_unregister", &"seq.effect.unregister")
	n.pending_id = reg_id
	return n


static func nest_discard_card(
	card_id: StringName,
	controller_id: StringName,
	trait_filter: StringName = &"",
	at_filter: StringName = &"",
	mode: StringName = &"choose"
) -> CompositionNode:
	var n := _nest_leaf(&"nest_discard_card", &"seq.effect.discard_card")
	n.card_id = card_id
	n.inv_id = controller_id
	n.definition_id = trait_filter
	n.location_target = at_filter
	n.place_doom_target = mode
	return n


## 调查员抽牌 · nest `seq.draw.investigator`。
static func nest_draw_investigator(
	controller_id: StringName,
	amount: int = 1
) -> CompositionNode:
	var n := _nest_leaf(&"nest_draw_investigator", &"seq.draw.investigator")
	n.inv_id = controller_id
	n.draw_amount = maxi(amount, 1)
	return n


static func nest_discard_from_hand(
	controller_id: StringName,
	amount: int = 1,
	mode: StringName = &"random"
) -> CompositionNode:
	var n := _nest_leaf(&"nest_discard_from_hand", &"seq.effect.discard_from_hand")
	n.inv_id = controller_id
	n.marker_delta = maxi(amount, 1)
	n.location_target = mode
	return n


static func nest_attach(
	card_id: StringName,
	controller_id: StringName,
	target: StringName = &"nearest_without_same"
) -> CompositionNode:
	var n := _nest_leaf(&"nest_attach", &"seq.effect.attach")
	n.card_id = card_id
	n.inv_id = controller_id
	n.location_target = target
	return n


static func nest_deal_damage(
	controller_id: StringName,
	amount: int = 1,
	target: StringName = &"controller",
	source_card_id: StringName = &"",
	per_investigator: bool = false
) -> CompositionNode:
	var n := nest_damage(controller_id, &"damage", amount, false, target, source_card_id)
	n.flag_value = per_investigator
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


## 卡面「does not provoke attacks of opportunity」：
## 译为行动开始 Register **限制类** SKIP_AOO；INIT_2B 由 AOO 原流程 **读取** 后分支。
## 不是 LISTENER，不是 Cancel/Ignore。节点留作 provenance；付费后挂载，resolve 不重复 Register。
static func no_provoke_aoo(controller_id: StringName = &"") -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"no_provoke_aoo"
	n.inv_id = controller_id
	return n


## 卡面「Resign」→ nest `seq.effect.resign` 信封（after_resign 可听）。
## 留置线索 / resigned / eliminate 在信封 handler 内。
static func resign(inv_id: StringName) -> CompositionNode:
	return nest_resign(inv_id)


## L0 · 调查员线索留在所在地点（Resign 第一步）。
static func leave_clues_at_location(inv_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"leave_clues_at_location"
	n.inv_id = inv_id
	return n


## L0 · 淘汰清理（威胁区/手牌隐私遭遇弃置 + ELIMINATED）。
static func eliminate(inv_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"eliminate"
	n.inv_id = inv_id
	return n


## 仅当 §4.0.5「是」时用：nest `seq.effect.resign`。
static func nest_resign(inv_id: StringName) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"nest_resign"
	n.nest_flow_id = &"seq.effect.resign"
	n.inv_id = inv_id
	return n


## PI：有限期确认目标 → 写入 RulesMemory（默认 = 合法集首项）。
## filter 可为预设 id 或 CandidateFilter / SelectionSpec（见 21）。
static func pick_target(
	controller_id: StringName,
	target_filter: Variant = &"enemy_at_connecting",
	prompt_id: StringName = &"pick:target",
	memory_key: StringName = &"picked_enemy",
	source_card_id: StringName = &""
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"pick_target"
	n.inv_id = controller_id
	n.card_id = source_card_id
	n.choice_prompt_id = prompt_id
	n.memory_key = memory_key
	if target_filter is SelectionSpec:
		n.selection_spec = target_filter as SelectionSpec
		n.target_filter = (n.selection_spec.filter.preset if n.selection_spec.filter != null else &"")
	else:
		n.selection_spec = SelectionSpec.pick_entity(
			CandidateFilter.from_variant(target_filter),
			prompt_id,
			memory_key
		)
		n.target_filter = StringName(str(target_filter)) if not (target_filter is Dictionary) else n.selection_spec.filter.preset
	return n


## 通用选择叶（实体多选 / 扩展约束）；编译 template=`select`。
static func select_entities(
	controller_id: StringName,
	spec: SelectionSpec,
	source_card_id: StringName = &""
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"select"
	n.inv_id = controller_id
	n.card_id = source_card_id
	n.selection_spec = spec
	if spec != null:
		n.choice_prompt_id = spec.prompt_id
		n.memory_key = spec.bind_key
		if spec.filter != null:
			n.target_filter = spec.filter.preset
	return n


## 同帧内联：把敌人放到目标地点（L0 改 location_tag；不 nest、不自动交战）。
static func move_enemy_to(
	controller_id: StringName,
	enemy_spec: StringName = &"memory:picked_enemy",
	location_spec: StringName = &"source_location",
	source_card_id: StringName = &""
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"move_enemy_to"
	n.inv_id = controller_id
	n.card_id = source_card_id
	n.enemy_ref_id = enemy_spec
	n.location_target = location_spec
	n.auto_engage = false
	return n


## 同帧内联：敌人与调查员交战（L0 apply_engage）。
static func engage_target(
	controller_id: StringName,
	enemy_spec: StringName = &"memory:picked_enemy",
	source_card_id: StringName = &""
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"engage_target"
	n.inv_id = controller_id
	n.card_id = source_card_id
	n.enemy_ref_id = enemy_spec
	n.engage_mode = &"effect"
	return n


## 限制类糖：解释时经 `seq.effect.register` 创建 SUPPRESS_AUTO_ENGAGE。
## 用于「移入后由卡面明示交战」——移入仍走正常自动交战入口，由限制分支。
## enemy_spec 可为 memory: 指称（解释期解析后再组 template）。
static func suppress_auto_engage(
	controller_id: StringName,
	enemy_spec: StringName = &"memory:picked_enemy",
	source_card_id: StringName = &""
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"suppress_auto_engage"
	n.inv_id = controller_id
	n.card_id = source_card_id
	n.enemy_ref_id = enemy_spec
	return n


## 卡面效果「移入地点」：nest `seq.enemy.move`（移入后仍走 auto-engage 入口）。
## 若需抑制自动交战、改由明示交战：先 `suppress_auto_engage`，再 nest `seq.engage`。
static func nest_enemy_move_to(
	controller_id: StringName,
	enemy_spec: StringName = &"memory:picked_enemy",
	location_spec: StringName = &"source_location",
	auto_engage_after: bool = true,
	source_card_id: StringName = &""
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"nest_enemy_move_to"
	n.nest_flow_id = &"seq.enemy.move"
	n.inv_id = controller_id
	n.card_id = source_card_id
	n.enemy_ref_id = enemy_spec
	n.location_target = location_spec
	n.auto_engage = auto_engage_after
	return n


## 仅当 §4.0.5「是」时用：nest `seq.engage`。
static func nest_engage(
	controller_id: StringName,
	enemy_spec: StringName = &"memory:picked_enemy",
	mode: StringName = &"effect",
	source_card_id: StringName = &""
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"nest_engage"
	n.nest_flow_id = &"seq.engage"
	n.inv_id = controller_id
	n.card_id = source_card_id
	n.enemy_ref_id = enemy_spec
	n.engage_mode = mode
	return n


## 12113：SKIP_AOO → PI → 抑制自动交战 → nest move → nest 明示交战。
static func engage_from_connecting(
	controller_id: StringName,
	source_card_id: StringName = &""
) -> CompositionNode:
	return seq([
		no_provoke_aoo(controller_id),
		pick_target(
			controller_id,
			&"enemy_at_connecting",
			&"pick:engage_connecting",
			&"picked_enemy",
			source_card_id
		),
		suppress_auto_engage(controller_id, &"memory:picked_enemy", source_card_id),
		nest_enemy_move_to(
			controller_id,
			&"memory:picked_enemy",
			&"source_location",
			true,
			source_card_id
		),
		nest_engage(controller_id, &"memory:picked_enemy", &"effect", source_card_id),
	])


## L0 · 群体花费线索（交互分配后补；现按玩家顺序各出 1 直至凑够）。
static func spend_clues_group(
	controller_id: StringName,
	amount: int = 1,
	per_investigator: bool = false
) -> CompositionNode:
	var n := CompositionNode.new()
	n.kind = AhcEnums.CompositionNodeKind.ATOM
	n.atom_name = &"spend_clues_group"
	n.inv_id = controller_id
	n.marker_delta = maxi(amount, 1)
	n.flag_value = per_investigator
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
