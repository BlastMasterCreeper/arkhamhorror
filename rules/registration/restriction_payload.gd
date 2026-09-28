class_name RestrictionPayload
extends RefCounted

var kind: AhcEnums.RestrictionKind = AhcEnums.RestrictionKind.FORBID_DRAW
var drawer_id: StringName = &""
var drawn_card_id: StringName = &""
var encounter_frame_id: StringName = &""


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


## 本行动不引发借机：行动开始挂载，AOO 入口消费一次。
static func skip_aoo(controller_id: StringName = &"") -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.SKIP_AOO
	p.drawer_id = controller_id
	return p
