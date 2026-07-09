class_name Condition
extends RefCounted

enum DomainPredicate { NONE, INVESTIGATOR_CLUES_ON_CARD_EQ, PREVIOUS_STEP_NOT_CREATED, PREVIOUS_STEP_ENGAGED }

var tags_all: Array[StringName] = []
var _use_framework_step: bool = false
var _framework_step: AhcEnums.FrameworkStep = AhcEnums.FrameworkStep.SETUP_01_CHOOSE_INVESTIGATORS

var stat_queries: Array = []
var domain_predicate: DomainPredicate = DomainPredicate.NONE
var domain_inv_id: StringName = &""
var domain_card_id: StringName = &""
var domain_eq: int = 0


static func with_tags(required: Array[StringName]) -> Condition:
	var c := Condition.new()
	c.tags_all = required.duplicate()
	return c


static func with_framework_and_tags(
	step: AhcEnums.FrameworkStep,
	required: Array[StringName]
) -> Condition:
	var c := Condition.new()
	c._use_framework_step = true
	c._framework_step = step
	c.tags_all = required.duplicate()
	return c


static func with_min_action_spends(count: int, tags: Array[StringName] = []) -> Condition:
	var c := with_tags(tags)
	c.stat_queries.append(StatQuery.turn_action_spend_count_ge(count))
	return c


## L3 现态 · 调查员卡上 clue 数（12126 · at_entry · OQ-ADB-06 · Domain）。
static func investigator_has_no_clues(inv_id: StringName) -> Condition:
	var c := Condition.new()
	c.domain_predicate = DomainPredicate.INVESTIGATOR_CLUES_ON_CARD_EQ
	c.domain_inv_id = inv_id
	c.domain_eq = 0
	return c


## L3 · after_step · Seq 上一子步未 CREATED（12160 · 07 §3.3 / §4.4 · CompositionExecutor.last_step_created）。
static func previous_step_not_created(_inv_id: StringName, _card_id: StringName = &"") -> Condition:
	var c := Condition.new()
	c.domain_predicate = DomainPredicate.PREVIOUS_STEP_NOT_CREATED
	c.domain_inv_id = _inv_id
	c.domain_card_id = _card_id
	return c


## L3 · after_step · 上一子步移动后 engage 了调查员（12163）。
static func previous_step_engaged_investigator(_inv_id: StringName, _card_id: StringName = &"") -> Condition:
	var c := Condition.new()
	c.domain_predicate = DomainPredicate.PREVIOUS_STEP_ENGAGED
	c.domain_inv_id = _inv_id
	c.domain_card_id = _card_id
	return c


static func from_compile_id(
	condition_id: String,
	inv_id: StringName,
	card_id: StringName = &""
) -> Condition:
	match condition_id:
		"investigator_has_no_clues":
			return investigator_has_no_clues(inv_id)
		"previous_step_not_created":
			return previous_step_not_created(inv_id, card_id)
		"previous_step_engaged_investigator":
			return previous_step_engaged_investigator(inv_id, card_id)
	return null


func matches(ctx: ApplicationContext) -> bool:
	if ctx == null:
		return false
	if _use_framework_step and ctx.framework_step != _framework_step:
		return false
	for tag in tags_all:
		if tag not in ctx.tags:
			return false
	return true


func matches_with_snapshot(
	ctx: ApplicationContext,
	snapshot: Dictionary,
	eval_ctx: EvaluationContext
) -> bool:
	if not matches(ctx):
		return false
	if eval_ctx == null:
		return stat_queries.is_empty()
	for q in stat_queries:
		if q is not StatQuery:
			continue
		var pkey := (q as StatQuery).snapshot_key(eval_ctx.scope())
		if not (q as StatQuery).evaluate_value(snapshot.get(pkey, 0)):
			return false
	return true


func matches_domain(game_ctx: GameContext, fallback_inv_id: StringName) -> bool:
	if game_ctx == null or game_ctx.state == null:
		return false
	match domain_predicate:
		DomainPredicate.INVESTIGATOR_CLUES_ON_CARD_EQ:
			var inv_id := domain_inv_id if domain_inv_id != &"" else fallback_inv_id
			var inv := game_ctx.state.registry.get_investigator(inv_id)
			return inv != null and inv.clues_on_card == domain_eq
		DomainPredicate.PREVIOUS_STEP_NOT_CREATED:
			if game_ctx.composition != null:
				return not game_ctx.composition.last_step_created()
			return true
		DomainPredicate.PREVIOUS_STEP_ENGAGED:
			if game_ctx.composition != null:
				return game_ctx.composition.last_step_engaged_investigator() != &""
			return false
	return true


func matches_domain_sim(sim: GameSimulator, fallback_inv_id: StringName) -> bool:
	if sim == null or sim.state == null:
		return false
	match domain_predicate:
		DomainPredicate.INVESTIGATOR_CLUES_ON_CARD_EQ:
			var inv_id := domain_inv_id if domain_inv_id != &"" else fallback_inv_id
			var inv := sim.state.registry.get_investigator(inv_id)
			return inv != null and inv.clues_on_card == domain_eq
		DomainPredicate.PREVIOUS_STEP_NOT_CREATED:
			return not sim.last_step_created
		DomainPredicate.PREVIOUS_STEP_ENGAGED:
			return sim.last_step_engaged_investigator != &""
	return true
