class_name ChaosSymbolFlow
extends RefCounted

## seq.chaos.symbol · ST.4 名义：单枚 resolved 的隐式符号能力。
## 挂在 `seq.chaos.reveal` 的 **After** 上，**Forced 同档**（与其它 Forced After 同窗）。
## 不是「After 窗关完后父流程再 nest」。
## 「Reveal another」→ nest 新的 reveal；新批符号仍由该帧 After Forced 发起。


const HANDLER_SOURCE: StringName = &"rules.chaos_symbol"


## Bootstrap：订 reveal After · Forced（幂等）。
static func bind_rules_handler(game_ctx: GameContext) -> void:
	if game_ctx == null or game_ctx.sequences == null:
		return
	game_ctx.sequences.unregister_handlers_by_source(HANDLER_SOURCE)
	var handler := SequenceHandler.after_forced(
		&"reveal_chaos_token",
		func() -> void:
			on_reveal_after_forced(game_ctx)
	)
	handler.source_id = HANDLER_SOURCE
	game_ctx.sequences.register_handler(handler)


## reveal After · Forced：对本批 resolved 逐枚 nest `seq.chaos.symbol`。
static func on_reveal_after_forced(game_ctx: GameContext) -> void:
	if game_ctx == null or game_ctx.sequence_catalog == null:
		return
	var trigger := game_ctx.sequences.current_trigger() if game_ctx.sequences != null else null
	var ctx: SkillTestContext = null
	var batch_start := 0
	if trigger != null:
		ctx = trigger.payload.get("skill_test_ctx") as SkillTestContext
		batch_start = int(trigger.payload.get("symbol_batch_start", 0))
	if ctx == null and game_ctx.skill_tests != null:
		ctx = game_ctx.skill_tests.current_context()
	if ctx == null:
		return
	batch_start = clampi(batch_start, 0, ctx.revealed_tokens.size())
	ctx.current_step = AhcEnums.SkillTestStep.ST_4_SYMBOL
	for i in range(batch_start, ctx.revealed_tokens.size()):
		var token: ChaosToken = ctx.revealed_tokens[i]
		if token == null:
			continue
		nest_for_token(game_ctx, ctx, token)


static func nest_for_token(
	game_ctx: GameContext,
	ctx: SkillTestContext,
	token: ChaosToken
) -> Dictionary:
	if game_ctx == null or game_ctx.sequence_catalog == null or token == null:
		return {"ok": false}
	return game_ctx.sequence_catalog.nest(
		game_ctx,
		&"seq.chaos.symbol",
		{
			"inv_id": ctx.performing_investigator if ctx != null else &"",
			"test_id": ctx.id if ctx != null else &"",
			"skill_test_ctx": ctx,
			"token": token,
		}
	)


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
		## 再 nest 揭示；新批符号由新帧 After · Forced 发起。
		nested_again = _nest_reveal_another(game_ctx, ctx)
	return {
		"ok": true,
		"reveal_another": token.reveal_another,
		"nested_reveal": nested_again,
	}


## Bless/Curse 先于参考卡 / Elder Sign。
static func apply_symbol_ability(
	game_ctx: GameContext,
	ctx: SkillTestContext,
	token: ChaosToken
) -> void:
	if BlessCurseRules.try_apply(ctx, token, game_ctx):
		return
	var state: GameStateStore = game_ctx.state if game_ctx != null else null
	ScenarioReferenceApplier.apply_token(game_ctx, ctx, token, state)


static func _nest_reveal_another(game_ctx: GameContext, ctx: SkillTestContext) -> bool:
	if game_ctx == null or game_ctx.sequence_catalog == null:
		return false
	ctx.reveal_batch_start = ctx.revealed_tokens.size()
	ctx.current_step = AhcEnums.SkillTestStep.ST_3_REVEAL
	var res: Dictionary = game_ctx.sequence_catalog.nest(
		game_ctx,
		&"seq.chaos.reveal",
		{
			"inv_id": ctx.performing_investigator,
			"test_id": ctx.id,
			"skill_test_ctx": ctx,
		}
	)
	return bool(res.get("ok", false))
