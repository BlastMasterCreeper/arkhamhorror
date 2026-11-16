class_name ThreatAreaQuery
extends RefCounted

## 威胁区有效集合：物理 threat_area + 手牌中的隐私 treachery（视为威胁区）。


static func is_hidden_treachery_in_hand(
	state: GameStateStore,
	inv_id: StringName,
	card_id: StringName
) -> bool:
	if state == null or inv_id == &"" or card_id == &"":
		return false
	var inv := state.registry.get_investigator(inv_id)
	var card := state.registry.get_card(card_id)
	if inv == null or card == null:
		return false
	if not inv.hand.has(card_id):
		return false
	if card.zone != AhcEnums.Zone.HAND:
		return false
	var def_id := card.id.definition_id
	return (
		CardRegistry.is_hidden(def_id)
		and CardRegistry.card_type(def_id) == &"treachery"
	)


static func counts_in_effective_threat_area(
	state: GameStateStore,
	inv_id: StringName,
	card_id: StringName
) -> bool:
	if state == null or inv_id == &"" or card_id == &"":
		return false
	var inv := state.registry.get_investigator(inv_id)
	if inv == null:
		return false
	if inv.threat_area.has(card_id):
		return true
	return is_hidden_treachery_in_hand(state, inv_id, card_id)


## 敌人在攻击者以外的调查员威胁区内时，返回该调查员。否则空。
static func other_engaged_holder(
	game_ctx: GameContext,
	enemy_id: StringName,
	attacker_id: StringName
) -> StringName:
	if game_ctx == null or game_ctx.state == null or enemy_id == &"":
		return &""
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return &""
	var holder_id := enemy.engaged_with
	if holder_id == &"" or holder_id == attacker_id:
		return &""
	var holder := game_ctx.state.registry.get_investigator(holder_id)
	if holder == null or holder.eliminated or not holder.threat_area.has(enemy_id):
		return &""
	return holder_id


static func effective_threat_area_ids(
	state: GameStateStore,
	inv_id: StringName
) -> Array[StringName]:
	var out: Array[StringName] = []
	if state == null or inv_id == &"":
		return out
	var inv := state.registry.get_investigator(inv_id)
	if inv == null:
		return out
	for card_id in inv.threat_area:
		out.append(card_id)
	for card_id in inv.hand:
		if is_hidden_treachery_in_hand(state, inv_id, card_id):
			if not out.has(card_id):
				out.append(card_id)
	return out
