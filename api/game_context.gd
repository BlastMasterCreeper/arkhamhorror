class_name GameContext
extends RefCounted

var state: GameStateStore
var framework: FrameworkFlowEngine
var timing: TimingBus
var log: GameLog
var events: EventRecordLog
var config: RulesConfig
var choices: ChoiceResolver

var actions: ActionSystem
var skill_tests: SkillTestEngine
var initiation: AbilityInitiationPipeline
var effects: EffectResolutionGraph
var scenario: ScenarioSystem
var enemy: EnemySystem

var registrations: RegistrationStore
var mutator: StateMutator
var modifiers: ModifierEngine
var composition: CompositionExecutor
var listeners: ListenerDispatcher
var legality: InitiationLegalityChecker
var combat: CombatResolver
var sequences: ResolutionSequenceStack
var memory: RulesMemory
var resource_gain: ResourceGainService
var draw_investigator: DrawInvestigatorService
var card_abilities: CardAbilityService
var enter_hand: EnterHandService

var active_investigator_id: StringName = &""
var performing_investigator_id: StringName = &""
var lead_investigator_id: StringName = &""
var skill_test_stack: Array[SkillTestContext] = []


func get_current_framework_step() -> AhcEnums.FrameworkStep:
	return framework.current_step
