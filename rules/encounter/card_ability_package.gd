class_name CardAbilityPackage
extends RefCounted

## 抽出/拿到一张牌后的结算包：按卡面能力处理。
## 不同类型自带默认能力体系（enemy/treachery ↔ 遭遇侧；asset/event/skill ↔ 调查员侧）。
## 不是按抽牌来源重定向，也不以 is_weakness 为第一键。

enum Package { INVESTIGATOR, ENCOUNTER }


static func package_for_definition(definition_id: StringName) -> Package:
	match CardRegistry.card_type(definition_id):
		&"enemy", &"treachery":
			return Package.ENCOUNTER
		_:
			return Package.INVESTIGATOR


static func package_for_card(game_ctx: GameContext, card_id: StringName) -> Package:
	if game_ctx == null or game_ctx.state == null:
		return Package.INVESTIGATOR
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return Package.INVESTIGATOR
	return package_for_definition(card.id.definition_id)


static func uses_encounter_package(game_ctx: GameContext, card_id: StringName) -> bool:
	return package_for_card(game_ctx, card_id) == Package.ENCOUNTER
