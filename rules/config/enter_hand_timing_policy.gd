class_name EnterHandTimingPolicy
extends RefCounted

## `enter_hand` 时点下显现的 **REVELATION 类内** 顺序占位（独立类，**不是** FORCED 子类，见 06 §8.1.1）。
## When 打断槽（Fast / [reaction] When you draw）与显现 nest **不同档** FrameworkPriority；不由本类表达。
## 设计师尚未最终裁定；调整 `RulesConfig.enter_hand_timing` 即可切换。


enum CardRevelationOrder {
	## 保持来源传入顺序（如 draw_pending / card_ids 抽牌序）。**当前默认。**
	SOURCE_ORDER,
	## 控制者自行选择多张牌的显现顺序（待 ChoiceResolver / UI）。**同类内自排。**
	CONTROLLER_CHOICE,
	## 按卡定义上的 priority 字段排序（待 CardRegistry 扩展）。**同类内自排。**
	DEFINITION_PRIORITY,
}


## 多张牌同时入手时，**REVELATION 类内** 显现 nest 的执行顺序。
var card_revelation_order: CardRevelationOrder = CardRevelationOrder.SOURCE_ORDER


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


## 单卡上多条 revelation 能力单元在 REVELATION 类内的执行顺序（当前 = CardRegistry 登记序）。
func order_ability_units(units: Array) -> Array:
	return units.duplicate()
