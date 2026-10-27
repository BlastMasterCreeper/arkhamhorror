class_name AloofStatus
extends RefCounted

## 冷漠（Aloof）限制类门面。
## 拥有：Domain `enemy.aloof` / `CardRegistry.is_aloof`（spawn / auto-engage 读）。
## Fight 拦截：WHILE_IN_PLAY 的 `FORBID_ATTACK`（未交战时 Evaluator 拦；已交战放行）。


static func ensure_forbid_attack(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	if game_ctx == null or game_ctx.registrations == null or enemy_id == &"":
		return &""
	if game_ctx.registrations.has_forbid_attack(enemy_id):
		return &""
	var template := RegistrationTemplate.aloof_forbid_attack(enemy_id)
	if (
		game_ctx.sequence_catalog == null
		or not game_ctx.sequence_catalog.has_flow(&"seq.effect.register")
	):
		push_error("AloofStatus.ensure_forbid_attack: seq.effect.register missing; vacuum refused")
		return &""
	var result := game_ctx.sequence_catalog.nest(
		game_ctx,
		&"seq.effect.register",
		{"template": template}
	)
	return result.get("reg_id", &"") as StringName
