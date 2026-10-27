class_name RestrictionPayload
extends RefCounted

var kind: AhcEnums.RestrictionKind = AhcEnums.RestrictionKind.FORBID_DRAW
var drawer_id: StringName = &""
var drawn_card_id: StringName = &""
var encounter_frame_id: StringName = &""
## SUPPRESS_AUTO_ENGAGE 等：限制作用的敌人实例。
var subject_id: StringName = &""
## ASSIGN_CONSTRAINT：算子与过滤（伤/恐分摊；DamageAssigner 读）。
var assign_op: AhcEnums.AssignConstraintOp = AhcEnums.AssignConstraintOp.INCLUDE_CANDIDATE
## damage | horror | either
var assign_affliction: StringName = &"either"
var assign_direct_scope: AhcEnums.AssignDirectScope = AhcEnums.AssignDirectScope.NON_DIRECT
## INCLUDE：self_deals | other_at_location
var assign_expand_scope: StringName = &"self_deals"
## MAX_TO_MATCH：特质名（如 Miskatonic）；空=不按特质
var assign_trait: StringName = &""
var assign_amount: int = 1
var assign_if_able: bool = true


static func forbid_draw() -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.FORBID_DRAW
	return p


static func forbid_play_peril(drawer_id: StringName, drawn_card_id: StringName) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.FORBID_PLAY
	p.drawer_id = drawer_id
	p.drawn_card_id = drawn_card_id
	return p


static func forbid_trigger_peril(drawer_id: StringName, drawn_card_id: StringName) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.FORBID_TRIGGER
	p.drawer_id = drawer_id
	p.drawn_card_id = drawn_card_id
	return p


static func forbid_commit_peril(drawer_id: StringName, drawn_card_id: StringName) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.FORBID_COMMIT_TO_TEST
	p.drawer_id = drawer_id
	p.drawn_card_id = drawn_card_id
	return p


## 隐私（Hidden）· 除该卡牌面能力外不得离开手牌。
static func forbid_leave_hand(card_id: StringName, controller_id: StringName = &"") -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.FORBID_LEAVE_HAND
	p.drawn_card_id = card_id
	p.drawer_id = controller_id
	return p


## 限制类：本行动不引发借机。行动开始挂载；INIT_2B 由 AOO 原流程读取后分支。
static func skip_aoo(controller_id: StringName = &"") -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.SKIP_AOO
	p.drawer_id = controller_id
	return p


## 限制类：抑制该敌人的自动交战；auto-engage 入口读取后分支。
static func suppress_auto_engage(enemy_id: StringName) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.SUPPRESS_AUTO_ENGAGE
	p.subject_id = enemy_id
	return p


## 交战状态 Buff：敌人 subject ↔ 调查员 drawer 成对；与威胁区场面脱钩。
static func engagement(enemy_id: StringName, investigator_id: StringName) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.ENGAGEMENT
	p.subject_id = enemy_id
	p.drawer_id = investigator_id
	return p


## 与指定敌人交战时：禁止该调查员发现线索。
static func forbid_discover_clue(
	investigator_id: StringName,
	enemy_id: StringName
) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.FORBID_DISCOVER_CLUE
	p.drawer_id = investigator_id
	p.subject_id = enemy_id
	return p


## 与指定敌人交战时：禁止该调查员花费线索。
static func forbid_spend_clue(
	investigator_id: StringName,
	enemy_id: StringName
) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.FORBID_SPEND_CLUE
	p.drawer_id = investigator_id
	p.subject_id = enemy_id
	return p


## 冷漠：对该敌人的 Fight 在未交战时禁止（已交战则 Evaluator 放行）。
static func forbid_attack_aloof(enemy_id: StringName) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.FORBID_ATTACK
	p.subject_id = enemy_id
	return p


## 分摊约束工厂见 `assign_include_candidate` 等；WHILE_IN_PLAY 挂载用 RegistrationTemplate。


## 分摊：扩大候选（04015 allow direct；Bodyguard 他人）。
static func assign_include_candidate(
	subject_card_id: StringName,
	controller_id: StringName,
	affliction: StringName = &"either",
	direct_scope: AhcEnums.AssignDirectScope = AhcEnums.AssignDirectScope.BOTH,
	expand_scope: StringName = &"self_deals"
) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.ASSIGN_CONSTRAINT
	p.assign_op = AhcEnums.AssignConstraintOp.INCLUDE_CANDIDATE
	p.subject_id = subject_card_id
	p.drawer_id = controller_id
	p.drawn_card_id = subject_card_id
	p.assign_affliction = affliction
	p.assign_direct_scope = direct_scope
	p.assign_expand_scope = expand_scope
	return p


## 分摊：优先填满本卡再摊调查员卡（03109）。
static func assign_prior_fill(
	subject_card_id: StringName,
	controller_id: StringName,
	affliction: StringName = &"horror",
	direct_scope: AhcEnums.AssignDirectScope = AhcEnums.AssignDirectScope.NON_DIRECT
) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.ASSIGN_CONSTRAINT
	p.assign_op = AhcEnums.AssignConstraintOp.PRIOR_FILL
	p.subject_id = subject_card_id
	p.drawer_id = controller_id
	p.drawn_card_id = subject_card_id
	p.assign_affliction = affliction
	p.assign_direct_scope = direct_scope
	return p


## 分摊：至少 N 点到本卡（09007）。
static func assign_min_to_subject(
	subject_card_id: StringName,
	controller_id: StringName,
	amount: int = 1,
	affliction: StringName = &"damage",
	direct_scope: AhcEnums.AssignDirectScope = AhcEnums.AssignDirectScope.NON_DIRECT,
	if_able: bool = true
) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.ASSIGN_CONSTRAINT
	p.assign_op = AhcEnums.AssignConstraintOp.MIN_TO_SUBJECT
	p.subject_id = subject_card_id
	p.drawer_id = controller_id
	p.drawn_card_id = subject_card_id
	p.assign_affliction = affliction
	p.assign_direct_scope = direct_scope
	p.assign_amount = maxi(amount, 1)
	p.assign_if_able = if_able
	return p


## 分摊：匹配特质合计至多 N（60232）。
static func assign_max_to_match(
	controller_id: StringName,
	trait_name: StringName,
	amount: int = 1,
	affliction: StringName = &"either",
	direct_scope: AhcEnums.AssignDirectScope = AhcEnums.AssignDirectScope.BOTH
) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.ASSIGN_CONSTRAINT
	p.assign_op = AhcEnums.AssignConstraintOp.MAX_TO_MATCH
	p.drawer_id = controller_id
	p.assign_trait = trait_name
	p.assign_amount = maxi(amount, 0)
	p.assign_affliction = affliction
	p.assign_direct_scope = direct_scope
	return p


## 分摊：无印刷 health/sanity 时 GRANT 仅开候选（不设上限）；`amount` 保留兼容，不设 cap。
static func assign_grant_capacity(
	subject_card_id: StringName,
	controller_id: StringName,
	amount: int = 1,
	affliction: StringName = &"either",
	direct_scope: AhcEnums.AssignDirectScope = AhcEnums.AssignDirectScope.BOTH
) -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.ASSIGN_CONSTRAINT
	p.assign_op = AhcEnums.AssignConstraintOp.GRANT_CAPACITY
	p.subject_id = subject_card_id
	p.drawer_id = controller_id
	p.drawn_card_id = subject_card_id
	p.assign_amount = maxi(amount, 0)
	p.assign_affliction = affliction
	p.assign_direct_scope = direct_scope
	return p
