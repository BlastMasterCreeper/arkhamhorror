class_name CharacteristicMount
extends RefCounted

## 可挂载特征（非关键词）：独特 / 胜利 / 复仇。
## 印刷于 ENTER_PLAY 挂 CHARACTERISTIC；gains 经 mount_gained。
## 不进 KeywordProfileTable / KeywordMount。


const CHAR_UNIQUE: StringName = &"unique"
const CHAR_VICTORY: StringName = &"victory"
const CHAR_VENGEANCE: StringName = &"vengeance"
const META_VICTORY_EARNED: StringName = &"victory_points_earned"


## 进场别名：按定义挂印刷特征。
static func mount_at_enter_play(
	game_ctx: GameContext,
	card_id: StringName,
	def_id: StringName = &""
) -> void:
	if game_ctx == null or card_id == &"":
		return
	if def_id == &"":
		def_id = _definition_id(game_ctx, card_id)
	if UniqueTitle.is_unique(def_id):
		mount_gained(game_ctx, card_id, CHAR_UNIQUE, 0)
	var victory := CardRegistry.victory_points(def_id)
	if victory > 0:
		mount_gained(game_ctx, card_id, CHAR_VICTORY, victory)
	var vengeance := CardRegistry.vengeance_points(def_id)
	if vengeance > 0:
		mount_gained(game_ctx, card_id, CHAR_VENGEANCE, vengeance)


## gains Unique / Victory X / Vengeance X · 幂等。
static func mount_gained(
	game_ctx: GameContext,
	card_id: StringName,
	characteristic: StringName,
	scalar: int = 0
) -> void:
	if game_ctx == null or card_id == &"" or characteristic == &"":
		return
	if is_armed(game_ctx, card_id, characteristic):
		## Victory/复仇：已挂时抬升标量（再挂一条更大标量不叠同 id；先卸再挂）。
		if scalar > characteristic_scalar(game_ctx, card_id, characteristic):
			_unmount(game_ctx, card_id, characteristic)
		else:
			return
	var template := RegistrationTemplate.characteristic_while_in_play(
		card_id, characteristic, scalar
	)
	CompositionMount.register_effect(game_ctx, template, &"", card_id)


static func is_armed(
	game_ctx: GameContext,
	card_id: StringName,
	characteristic: StringName
) -> bool:
	if game_ctx == null or game_ctx.registrations == null:
		return false
	return game_ctx.registrations.has_characteristic_buff(card_id, characteristic)


static func characteristic_scalar(
	game_ctx: GameContext,
	card_id: StringName,
	characteristic: StringName
) -> int:
	if game_ctx == null or game_ctx.registrations == null:
		return 0
	return game_ctx.registrations.characteristic_scalar(card_id, characteristic)


static func has_effective_unique(game_ctx: GameContext, card_id: StringName) -> bool:
	if game_ctx == null or game_ctx.state == null or card_id == &"":
		return false
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return false
	if UniqueTitle.is_unique(card.id.definition_id):
		return true
	return is_armed(game_ctx, card_id, CHAR_UNIQUE)


static func routes_to_victory_display(game_ctx: GameContext, card_id: StringName) -> bool:
	return (
		effective_victory_points(game_ctx, card_id) > 0
		or effective_vengeance_points(game_ctx, card_id) > 0
	)


static func effective_victory_points(game_ctx: GameContext, card_id: StringName) -> int:
	var printed := 0
	var def_id := _definition_id(game_ctx, card_id)
	if def_id != &"":
		printed = CardRegistry.victory_points(def_id)
	var mounted := characteristic_scalar(game_ctx, card_id, CHAR_VICTORY)
	return maxi(printed, mounted)


static func effective_vengeance_points(game_ctx: GameContext, card_id: StringName) -> int:
	var printed := 0
	var def_id := _definition_id(game_ctx, card_id)
	if def_id != &"":
		printed = CardRegistry.vengeance_points(def_id)
	var mounted := characteristic_scalar(game_ctx, card_id, CHAR_VENGEANCE)
	return maxi(printed, mounted)


## 进胜利区前盖章：离场卸 CHARACTERISTIC 后仍可计分。
static func stamp_victory_earned(game_ctx: GameContext, card_id: StringName) -> void:
	if game_ctx == null or game_ctx.state == null or card_id == &"":
		return
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return
	var pts := effective_victory_points(game_ctx, card_id)
	if pts > 0:
		card.set_meta(META_VICTORY_EARNED, pts)


static func scored_victory_points(card: CardInstance) -> int:
	if card == null:
		return 0
	if card.has_meta(META_VICTORY_EARNED):
		return int(card.get_meta(META_VICTORY_EARNED))
	if card.id == null:
		return 0
	return CardRegistry.victory_points(card.id.definition_id)


static func _unmount(
	game_ctx: GameContext,
	card_id: StringName,
	characteristic: StringName
) -> void:
	if game_ctx == null or game_ctx.registrations == null:
		return
	var to_remove: Array[StringName] = []
	for reg in game_ctx.registrations.all_registrations():
		if reg.drawn_card_id != card_id:
			continue
		for buff in reg.buffs:
			if (
				buff.type == AhcEnums.BuffType.CHARACTERISTIC
				and buff.characteristic == characteristic
			):
				to_remove.append(reg.id)
				break
	for id in to_remove:
		game_ctx.registrations.unregister(id)


static func _definition_id(game_ctx: GameContext, card_id: StringName) -> StringName:
	if game_ctx == null or game_ctx.state == null:
		return &""
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null or card.id == null:
		return &""
	return card.id.definition_id
