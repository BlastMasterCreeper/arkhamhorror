class_name ChaosSymbolFlow
extends RefCounted

## seq.chaos.symbol · ST.4：单枚 resolved token 的隐式符号能力。
## 父流程在 ST.3（seq.chaos.reveal）整帧结束后 nest；非 ST.3 内联 then。
## 「Reveal another」→ 本帧 RESOLVE 内再 nest ST.3，再对新增 resolved nest 本流。


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null:
		return {"ok": false, "error": "invalid_context"}
	var ctx: SkillTestContext = params.get("skill_test_ctx") as SkillTestContext
	if ctx == null and game_ctx.skill_tests != null:
		ctx = game_ctx.skill_tests.current_context()
	var token: ChaosToken = params.get("token") as ChaosToken
	if ctx == null or token == null:
		return {"ok": false, "error": "missing_token_or_test"}
	ctx.current_step = AhcEnums.SkillTestStep.ST_4_SYMBOL
	apply_symbol_ability(game_ctx, ctx, token)
	var nested_again := false
	if token.reveal_another:
		nested_again = _nest_reveal_another(game_ctx, ctx)
	return {
		"ok": true,
		"reveal_another": token.reveal_another,
		"nested_reveal": nested_again,
	}


## Bless/Curse 先于参考卡 / Elder Sign（与 SkillTestEngine 同序）。
static func apply_symbol_ability(
	game_ctx: GameContext,
	ctx: SkillTestContext,
	token: ChaosToken
) -> void:
	if BlessCurseRules.try_apply(ctx, token, game_ctx):
		return
	var state: GameStateStore = game_ctx.state if game_ctx != null else null
	ScenarioReferenceApplier.apply_token(game_ctx, ctx, token, state)


## Reveal another：nest 新一帧 ST.3，再对批内新 token nest ST.4（递归）。
static func _nest_reveal_another(game_ctx: GameContext, ctx: SkillTestContext) -> bool:
	if game_ctx == null or game_ctx.sequence_catalog == null:
		return false
	var batch_start := ctx.revealed_tokens.size()
	ctx.reveal_batch_start = batch_start
	ctx.current_step = AhcEnums.SkillTestStep.ST_3_REVEAL
	game_ctx.sequence_catalog.nest(
		game_ctx,
		&"seq.chaos.reveal",
		{
			"inv_id": ctx.performing_investigator,
			"test_id": ctx.id,
			"skill_test_ctx": ctx,
		}
	)
	var nested_any := false
	for i in range(batch_start, ctx.revealed_tokens.size()):
		var next_tok: ChaosToken = ctx.revealed_tokens[i]
		if next_tok == null:
			continue
		game_ctx.sequence_catalog.nest(
			game_ctx,
			&"seq.chaos.symbol",
			{
				"inv_id": ctx.performing_investigator,
				"test_id": ctx.id,
				"skill_test_ctx": ctx,
				"token": next_tok,
			}
		)
		nested_any = true
	return nested_any
