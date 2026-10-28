class_name BlessCurseRules
extends RefCounted

## 规则自带祝福/诅咒符号能力（RR · TIC）。
## **不是**冒险参考卡能力，也 **不是**调查员印刷能力。
## 仅 ST.4 检定揭示路径调用；检定外揭示无效果。


## 若 token 为 bless/curse 则施加并返回 true；否则 false（留给其它 ST.4 路由）。
static func try_apply(
	ctx: SkillTestContext,
	token: ChaosToken,
	game_ctx: GameContext = null
) -> bool:
	if token == null:
		return false
	match token.kind:
		AhcEnums.ChaosTokenKind.BLESS:
			apply(ctx, token, 2, game_ctx)
			return true
		AhcEnums.ChaosTokenKind.CURSE:
			apply(ctx, token, -2, game_ctx)
			return true
		_:
			return false


## Bless +2 / Curse −2；Reveal another；ST.8 归 chaos_token_pool（非袋）。
## 能力揭示 curse 不走此路径 → finalize 仍回袋。
## 技能修正经 ChaosSkillModifier → MODIFIER Buff（THIS_SKILL_TEST）。
static func apply(
	ctx: SkillTestContext,
	token: ChaosToken,
	modifier: int,
	game_ctx: GameContext = null
) -> void:
	if ctx == null:
		return
	ChaosSkillModifier.apply(game_ctx, ctx, modifier)
	if token == null:
		return
	token.reveal_another = true
	token.return_to_pool = true
	## 与规则修饰对齐，便于审计；ST.4 以硬编码 modifier 为准。
	token.modifier = modifier
