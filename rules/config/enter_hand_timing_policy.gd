class_name EnterHandTimingPolicy
extends RefCounted

## `enter_hand` 时点下显现的 **同类内** 顺序占位（均属 FORCED 类别，见 06 §8）。
## 跨类优先级（Forced vs [reaction]）不由本类表达。
## 设计师尚未最终裁定；调整 `RulesConfig.enter_hand_timing` 即可切换。


enum CardRevelationOrder {
	## 保持来源传入顺序（如 draw_pending / card_ids 抽牌序）。**当前默认。**
	SOURCE_ORDER,
	## 控制者自行选择多张牌的显现顺序（待 ChoiceResolver / UI）。**同类内自排。**
	CONTROLLER_CHOICE,
	## 按卡定义上的 priority 字段排序（待 CardRegistry 扩展）。**同类内自排。**
	DEFINITION_PRIORITY,
}


## FORCED 类别在 `AbilityCategoryTier` 内的相对值（与 SequenceHandler.Tier.FORCED 对齐）。
## 显现 vs 其他 enter_hand 监听若属不同类别，走 06 §8.1 整批顺序，非本 enum。
enum ForcedSubTier {
	REVELATION_FORCED = 100,
	OTHER_ENTER_HAND_FORCED = 200,
}


## 多张牌同时入手时，**FORCED 类内** 显现 nest 的执行顺序。
var card_revelation_order: CardRevelationOrder = CardRevelationOrder.SOURCE_ORDER

## 预留：同属 FORCED 的子类之间若需再分层（尚未接入 ResponseWindow）。
var revelation_forced_sub_tier: int = ForcedSubTier.REVELATION_FORCED


func order_cards_for_revelation(
	game_ctx: GameContext,
	controller_id: StringName,
	card_ids: Array,
	params: Dictionary = {}
) -> Array:
	match card_revelation_order:
		CardRevelationOrder.SOURCE_ORDER:
			return card_ids.duplicate()
		CardRevelationOrder.CONTROLLER_CHOICE:
			push_warning(
				"EnterHandTimingPolicy: CONTROLLER_CHOICE not implemented; using SOURCE_ORDER"
			)
			return card_ids.duplicate()
		CardRevelationOrder.DEFINITION_PRIORITY:
			push_warning(
				"EnterHandTimingPolicy: DEFINITION_PRIORITY not implemented; using SOURCE_ORDER"
			)
			return card_ids.duplicate()
	return card_ids.duplicate()


## 单卡上多条 revelation 能力单元在 FORCED 类内的执行顺序（当前 = CardRegistry 登记序）。
func order_ability_units(units: Array) -> Array:
	return units.duplicate()
