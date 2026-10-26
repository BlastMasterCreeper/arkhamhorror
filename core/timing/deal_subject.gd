class_name DealSubject
extends RefCounted

## 造成伤害/恐惧的落点主体分类与统一 Apply。
## `seq.effect.deal` / `deal.assignable` 的 legs / candidates 不限单卡种：
## 敌人 · 场上有生命/神智（或 GRANT_CAPACITY）的卡 · 调查员。
## L0 仍单目标；本层只负责按 id 路由。


const KIND_ENEMY := &"enemy"
const KIND_CARD := &"card"
const KIND_INVESTIGATOR := &"investigator"


## 按运行时注册表归类主体；未知 → &""。
static func classify(game_ctx: GameContext, subject_id: StringName) -> StringName:
	if game_ctx == null or game_ctx.state == null or subject_id == &"":
		return &""
	if game_ctx.state.registry.get_enemy(subject_id) != null:
		return KIND_ENEMY
	if game_ctx.state.registry.get_investigator(subject_id) != null:
		return KIND_INVESTIGATOR
	var card := game_ctx.state.registry.get_card(subject_id)
	if card != null and _card_in_play(card):
		return KIND_CARD
	return &""


## 写入 amount 点（kind=damage|horror）；返回实际写入量。
static func apply(
	game_ctx: GameContext,
	kind: StringName,
	subject_id: StringName,
	amount: int
) -> int:
	if game_ctx == null or amount <= 0 or subject_id == &"":
		return 0
	var bearer := classify(game_ctx, subject_id)
	match bearer:
		KIND_ENEMY:
			if kind == &"horror":
				## 敌人通常无神智通道；明确 horror 腿跳过。
				return 0
			var er := EnemyDefeatResolver.deal_damage(game_ctx, subject_id, amount)
			return amount if bool(er.get("ok", false)) else 0
		KIND_CARD:
			var cr: Dictionary
			if kind == &"horror":
				cr = DefeatFlow.deal_horror_to_asset(game_ctx, subject_id, amount)
			else:
				cr = DefeatFlow.deal_damage_to_asset(game_ctx, subject_id, amount)
			return amount if bool(cr.get("ok", false)) else 0
		KIND_INVESTIGATOR:
			## 已定腿：直接 L0 写入（不再次 Assign / 不开嵌套 WOULD）。
			if game_ctx.mutator == null:
				return 0
			if game_ctx.state.registry.get_investigator(subject_id) == null:
				return 0
			var marker := (
				AhcEnums.MarkerKind.HORROR_TAKEN
				if kind == &"horror"
				else AhcEnums.MarkerKind.DAMAGE
			)
			if not game_ctx.mutator.transfer_marker(
				marker,
				amount,
				MarkerSlot.supply(marker),
				MarkerSlot.investigator(subject_id, marker)
			):
				return 0
			DefeatFlow.check_investigator_caps(game_ctx, subject_id)
			return amount
		_:
			return 0


## 分配快照容量：敌人 / 调查员 = -1（不设上限）；卡 = 印刷剩余或无印刷+GRANT 的 -1。
static func damage_capacity(
	game_ctx: GameContext,
	subject_id: StringName,
	dealt_inv_id: StringName = &""
) -> int:
	return _capacity(game_ctx, subject_id, &"damage", dealt_inv_id)


## 恐惧分配容量：调查员 = -1；卡同上；敌人通常 0（无神智通道）。
static func horror_capacity(
	game_ctx: GameContext,
	subject_id: StringName,
	dealt_inv_id: StringName = &""
) -> int:
	return _capacity(game_ctx, subject_id, &"horror", dealt_inv_id)


static func _capacity(
	game_ctx: GameContext,
	subject_id: StringName,
	kind: StringName,
	dealt_inv_id: StringName
) -> int:
	var bearer := classify(game_ctx, subject_id)
	match bearer:
		KIND_ENEMY:
			if kind == &"horror":
				return 0
			if game_ctx.state.registry.get_enemy(subject_id) == null:
				return 0
			return -1
		KIND_CARD:
			return DamageAssigner.card_remaining(
				game_ctx, subject_id, kind, dealt_inv_id, false
			)
		KIND_INVESTIGATOR:
			return -1
		_:
			return 0


static func _card_in_play(card: CardInstance) -> bool:
	if card == null:
		return false
	return (
		card.zone == AhcEnums.Zone.PLAY_AREA
		or card.zone == AhcEnums.Zone.THREAT_AREA
		or card.zone == AhcEnums.Zone.ATTACHED
	)
