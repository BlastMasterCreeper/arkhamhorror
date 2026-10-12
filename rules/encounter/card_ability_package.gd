class_name CardAbilityPackage
extends RefCounted

## 抽出/拿到一张牌后的结算包：按卡面能力处理。
## 不同类型自带默认能力体系（enemy/treachery ↔ 遭遇侧；asset/event/skill ↔ 调查员侧）。
## 不是按抽牌来源重定向，也不以 is_weakness 为第一键。
## 注意：勿用 CardRegistry.card_type 的缺省 treachery——未印刷类型视为调查员包。

enum Package { INVESTIGATOR, ENCOUNTER }


static func package_for_definition(definition_id: StringName) -> Package:
	var data := CardRegistry.definition_data(definition_id)
	## 只认定义里显式印刷的 card_type；缺省 ≠ treachery。
	var ctype: StringName = data.get("card_type", &"") as StringName
	if ctype == &"":
		ctype = data.get("type", &"") as StringName
	match ctype:
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
