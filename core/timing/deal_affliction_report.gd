class_name DealAfflictionReport
extends RefCounted

## 将实发伤/恐写回当前 deal 帧 TC.payload，供 AFTER 条件（受到伤害后 / 恐惧后 / 和或）匹配。


static func patch_current(game_ctx: GameContext, damage: int, horror: int) -> void:
	if game_ctx == null or game_ctx.sequences == null:
		return
	game_ctx.sequences.patch_trigger_payload(
		{
			"damage": maxi(damage, 0),
			"horror": maxi(horror, 0),
			"amount": maxi(damage, 0) + maxi(horror, 0),
		}
	)
