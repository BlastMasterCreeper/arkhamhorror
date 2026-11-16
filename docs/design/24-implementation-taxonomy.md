# 24 — 实现类职责桶与命名（v2 · 四桶）

> **状态**：v2（2026-11-11）— **取消门面与触发器为一等桶**  
> **依赖**：[17-seq-runtime](17-seq-runtime.md) R4、effect-translation  
> **目的**：看后缀知职责；禁止平行业务 `*System`；禁止为单条 `seq.*` 增殖 `*Service`。

---

## 1. 四桶（唯一职责分类）

| # | 桶 | 英文 | 后缀 | 一句话 |
|---|---|---|---|---|
| 1 | **流程体** | Flow | `*Flow` / `*FlowHandlers` | 某条/一组 `seq.*` 的 RESOLVE |
| 2 | **查询** | Query | `*Query`（状态只读可用 `*Status`） | 只读；不压栈、不 CREATED |
| 3 | **管线** | Pipeline | `*Pipeline` / `*Engine` / `*Mount` | 跨 seq 工序、装载、编排、解释器；**含稀少聚合入口** |
| 4 | **底座** | Infrastructure | 领域名（无业务后缀） | Catalog/栈/Gate/Store/局面；**`GameContext.run_seq`** |

```text
管线 / Framework / 测试 ──▶ GameContext.run_seq / catalog.nest ──▶ Catalog+栈(底座) ──▶ 流程体
KeywordEffects / RuleMount（已挂载的静态规格）─────────────────▲              ├─ Query
                                                                               └─ Gate(底座)
```

关键词在进场挂载；固定规则在 **游戏创建** 时 `RuleMount.mount_builtin`。两者的开火体都是 `KeywordProfile.effect_*`，由 `KeywordEffects` 解释。没有单独的触发器职责。

### 1.1 为何取消「门面」桶（已裁决）

薄 `*Service`（只包 `catalog.run`）已被收掉；只剩的「聚合入口」本质是 **管线编排**，不是独立职责。空桶会诱导向回增殖 per-seq 门面。

| 旧说法 | 现归宿 |
|---|---|
| per-seq `ResourceGainService` / `Draw*Service` / … | **删除** → `GameContext.run_seq` |
| `ScenarioService`（setup + 薄转发） | **`ScenarioPipeline`**（管线） |
| 「门面」作为六桶之一 | **废除** |

---

## 2. 命名硬规则

1. **多条相近 seq 合集** → 一律 `*FlowHandlers`（禁止裸 `*Handlers`）。  
2. **单条主手续** → `*Flow`。  
3. **禁止为单条 `seq.*` 新增 `*Service`**；稀少聚合入口用 **`*Pipeline`**（或场景域短名，仍归管线桶）。  
4. **选址/猎物/距离** → `*Query`；交战/冷漠等有效状态 → `*Status` 可保留。  
5. **开火**写在静态规格（`KeywordProfile.effect_*`）上，由 `KeywordEffects` 解释。禁止 `*Trigger` / 用 `*Resolver` 表示开火或选址。  
6. **PI 选择** → 保留 `ChoiceResolver` 族（底座交互，≠ Query）。  
7. **禁止空 `*System` 挂点**；新代码不要加 `*System` 业务 API。  
8. **L0 写局面且仅被 Flow 调用** → 可留短名；文档归 **不成桶 · L0 附属**（或收进对应 `*Flow`）。

---

## 3. 不成桶 — **不必再开职责桶**

不成桶不是第五职责，只是 **不进四桶的东西**。再拆成一等桶会重蹈「空分类」：它们不压栈、不发起、不查询局面规则语义。

可读性上允许 **标签**（文档/盘点用，非后缀硬规则）：

| 标签 | 放什么 | 例子 |
|---|---|---|
| **DTO / Spec** | 参数、意图、能力描述、选择规格 | `EffectRequest`、`InitiationIntent`、`SelectionSpec`、`EnemyAttack` |
| **静态树** | Composition / ST.7 计划树 | `CompositionNode`、`SkillTestSt7Plan` |
| **局面形** | 实体状态、物理槽、枚举 | `CardInstance`、`InvestigatorState`、`AhcEnums` |
| **L0 附属** | 仅被 Flow 调用的写局面/域辅助（优先收进对应 `*Flow`，勿增殖） | 分摊在 `DealAssignableFlow`；蜂拥包在 `VirtualCard` + 移动/接战/横置；set-aside 在 `ScenarioCompositionFlowHandlers` |
| **Policy / 表** | 阈值、挂载表、配置谓词 | `KeywordProfileTable`、`RuleProfileTable`、`EnterHandTimingPolicy` |

**禁止**：为上述标签新建 `*DtoBucket` / `*SpecService` 等职责层；标签只服务阅读。

---

## 4. 目录约定

| 目录 | 放什么 |
|---|---|
| `core/flow/` | 对局主路径 `*Flow` / `*FlowHandlers` |
| `rules/pipeline/` | 稀少聚合入口 `*Pipeline`（行动 / 场景 / 能力装载） |
| `rules/framework/` | 建局挂载的规则规格（`RuleProfileTable` / `RuleMount`） |
| `rules/query/` | `*Query` / `*Status` |
| `core/timing/` | 栈、Catalog、TimingBus、RulesMemory、承伤管线等 **底座 / 管线运行时** |
| `rules/choices/` · `rules/interaction/` · `rules/registration/` | 底座（PI / Buff） |

一时迁不尽的类：以 **class 后缀 / 本表归属** 为准，目录后续再收。

---

## 5. 已执行的重命名 / 收口（摘要）

| 旧 | 新 | 桶 |
|---|---|---|
| `BasicActionHandlers` | `BasicActionFlowHandlers` | Flow |
| `CardAbilityService` / `TriggeredAbilityService` | `*Pipeline` | Pipeline |
| `ScenarioCompositionAtoms` | `ScenarioCompositionFlowHandlers` | Flow |
| `ScenarioSetAsideService` | `ScenarioSetAside` | 不成桶 · L0/域工具 |
| `*Resolver`（开火/选址） | 静态规格 / `*Query` | 规格 / Query |
| `ActionSystem` | `ActionPipeline` | Pipeline |
| `ScenarioSystem` → `ScenarioPipeline` | **`ScenarioPipeline`** | Pipeline |
| per-seq 薄 `*Service` | **删除** → `run_seq` | — |
| `InterruptHandler` / `ReplacementHandler` / `EffectOpExecutor` / `MassiveKeywordFlow` / `EnemySystem` | 并入 FlowHandlers / ERG / MassiveEngagement / 删除 | — |

**保留边界**：`ChoiceResolver*`（底座）、`*Status`、`*Engine`、`EffectResolutionGraph`（管线 · pending Cancel/Instead，待再收）。

---

## 6. 审查口诀

- 打开新类：先问落在四桶哪一格；答不上来 → 多半是 **不成桶**（DTO/树/局面形），不是缺新桶。  
- 新增「只包一层 `catalog.run`」的类 → **违规**（用 `run_seq`）。  
- 新增 `*Trigger` → **违规**（开火写规格，建局或进场挂载）。  
- 打开 `*Query`：出现改局面 → **违规**。  
- 打开 `*Flow`：对外再暴露平行业务 API → **违规**。  
- 打开 `*Pipeline`：超过跨 seq 编排 / 装载 / 聚合入口 → 考虑拆 Flow。  

---

## 7. 全库普查（2026-11-16）

范围：生产 `class_name` **228**。不含 `tests/` 7 个测试辅助、`ui/` 5 个沙盒类。无重名 `class_name`。下表按类逐条重数。

| 桶 | 数量 |
|---|---|
| 流程体 | 37 |
| 查询 | 28 |
| 管线 | 36 |
| 底座 | 30 |
| 不成桶 | 97 |

不成桶标签：DTO / Spec 54、局面形 20、Policy / 表 9、编译器 6、L0 附属 5、静态树 3。

`*Trigger` / `*Service` / `*System` 均为 0。`TriggeringCondition`、`TriggeredAbilityDescriptor`、`TriggeredAbilityPipeline` 是时点信封与发起管线。

后缀与职责不一致，不因此新开桶：`StatQuery` / `ModifierQuery`（比较或取数的规格，不读局面）、`SequenceHandler`（堆栈订阅记录）。另有 14 个类在查询桶里，但没有 `*Query` / `*Status` 后缀：`CandidateEnumerator`、`CandidatePreds`、`CandidateViability`、`CardAccessMatcher`、`DeckLegality`、`EffectRestrictionGate`、`ExperienceCount`、`InitiationLegalityChecker`、`PerInvestigatorScale`、`QueryAlgebra`、`RestrictionEvaluator`、`TextBoxBlank`、`UniqueTitle`、`XpCostCalculator`。

没有其它文件引用的三个类：`AbilityRegistry`、`CardScriptBase`、`ResponsePrompt`。

`TextBoxBlank` 目前把印刷文本框写成布尔。Mind Wipe（核心第 68 张，`01068`）要的是注册上的 `BLANK`：特性除外，本阶段结束注销。

### 7.1 流程体

| 类 | 文件 | 功能 |
|---|---|---|
| `ActAdvanceFlow` | `rules/scenario/act_advance_flow.gd` | 场景推进：可选花费线索，再翻当前场景。 |
| `ActAgendaBackFlow` | `rules/scenario/act_agenda_back_flow.gd` | 结算场景或密谋的 b 面：普通指令走效果树，遭遇卡背走抽取进场。 |
| `ActAgendaFlipFlow` | `rules/scenario/act_agenda_flip_flow.gd` | 翻面推进内核：清标记、卸 a 面、翻面、结算 b 面、推进牌移出游戏。 |
| `ActionFlowHandlers` | `core/flow/action_flow_handlers.gd` | 行动手续的 RESOLVE：抽牌、获得资源，以及转交基础行动。 |
| `AgendaAdvanceFlow` | `core/flow/agenda_advance_flow.gd` | 密谋推进：清毁灭，再翻当前密谋。 |
| `BasicActionFlowHandlers` | `core/flow/basic_action_flow_handlers.gd` | 基础调查、攻击、躲避行动的 RESOLVE，检定参数在这里组装。 |
| `ChaosRevealFlow` | `core/flow/chaos_reveal_flow.gd` | 检定 ST.3 揭示混乱标记：先收替换，再同时离袋。 |
| `DealAssignableFlow` | `core/flow/deal_assignable_flow.gd` | 待分配的造成伤害/恐惧，含候选、约束、默认腿和校验。 |
| `DeckbuildingChoiceFlow` | `rules/deckbuilding/deckbuilding_choice_flow.gd` | 选定调查员后的附带选择：副职阶、特性、牌组尺寸。 |
| `DefeatFlow` | `core/flow/defeat_flow.gd` | 击败：成功后 nest 退场。取消则不退场。 |
| `DiscoverClueFlow` | `core/flow/discover_clue_flow.gd` | 发现线索。调查成功会 nest 到这里。 |
| `DrawEncounterFlow` | `core/flow/draw_encounter_flow.gd` | 遭遇抽牌：离库进悬置，再按队列结算；默认不入手。 |
| `DrawInvestigatorFlow` | `core/flow/draw_investigator_flow.gd` | 调查员抽牌：先收齐张数，再批量揭示和入手。 |
| `EffectFlowHandlers` | `core/flow/effect_flow_handlers.gd` | 纸面没有章节名的效果句：抽牌、伤恐、横置、移动等 seq.effect。 |
| `EnemyAttackFlow` | `core/flow/enemy_attack_flow.gd` | 敌人攻击核，以及借机攻击这一批。 |
| `EnemyPhaseFlow` | `core/flow/enemy_phase_flow.gd` | 敌军阶段：合格敌人、猎手式移动，以及庞大的阶段攻击批。 |
| `EngageFlow` | `core/flow/engage_flow.gd` | 交战：自动或效果两条路径，授予交战状态，需要时再进入威胁区。 |
| `EnterThreatAreaFlow` | `core/flow/enter_threat_area_flow.gd` | 把敌人放进调查员威胁区。庞大在这一步被拒绝。 |
| `EvadeFlow` | `core/flow/evade_flow.gd` | 躲避效果核：同时横置并解除交战。自动躲避走这里，不另开检定。 |
| `ExhaustReadyFlow` | `core/flow/exhaust_ready_flow.gd` | 横置和重整。费用里的横置不走这里。 |
| `InterruptFlowHandlers` | `core/flow/interrupt_flow_handlers.gd` | 取消和忽略的 RESOLVE，直接交给效果图派发。 |
| `InvestigatorSetupFlow` | `rules/campaign/investigator_setup_flow.gd` | 开局玩家侧：洗牌、起手、再触发仍在牌库里的起始牌。 |
| `MoveFlow` | `core/flow/move_flow.gd` | 沿连接移动，或无视连接移动到地点。蜂拥整包跟着对齐地点。 |
| `MythosFlow` | `core/flow/mythos_flow.gd` | 神话阶段 1.2 到 1.3：放置毁灭、抽遭遇牌。 |
| `PhaseBoundaryFlow` | `core/flow/phase_boundary_flow.gd` | 阶段开始和结束的那一个钩子，强制能力订在这里。 |
| `ReplacementFlowHandlers` | `core/flow/replacement_flow_handlers.gd` | 代替的 RESOLVE，直接交给效果图派发。 |
| `RevealLocationFlow` | `core/flow/reveal_location_flow.gd` | 调查员进入未揭示地点时翻开，并放上印刷线索。 |
| `ScenarioCompositionFlowHandlers` | `core/flow/scenario_composition_flow_handlers.gd` | 冒险正文里的地点、清场、结算编号，以及 set-aside 的放入和取出。 |
| `ScenarioObjectiveFlow` | `rules/scenario/scenario_objective_flow.gd` | 检查场景目标，满足时推进场景。 |
| `ScenarioResolutionFlow` | `rules/scenario/scenario_resolution_flow.gd` | 冒险结算编号 R# 的结算。 |
| `ScenarioSetupFlow` | `rules/scenario/scenario_setup_flow.gd` | 开局「当游戏开始时」那一步。 |
| `SealFlow` | `core/flow/seal_flow.gd` | 把混乱标记封印到卡上，或释放回袋。离场会立刻释放。 |
| `SearchFlow` | `core/flow/search_flow.gd` | 搜寻指定区域。搜了牌库就要洗，弃牌堆不洗。 |
| `SkillTestFlowHandlers` | `core/flow/skill_test_flow_handlers.gd` | 技能检定命名流程的 RESOLVE，覆盖 ST.1 到 ST.8。 |
| `SpawnFlow` | `core/flow/spawn_flow.gd` | 敌人生成：放到地点，或生成即进入威胁区。冷漠不自动交战。 |
| `SwarmPadFlow` | `core/flow/swarm_pad_flow.gd` | 蜂拥进场后垫指定张数的集群卡。 |
| `ZoneMoveFlow` | `core/flow/zone_move_flow.gd` | 广义换区。进场和退场是对这次换区的过滤，不另开流程。 |

### 7.2 查询

| 类 | 文件 | 功能 |
|---|---|---|
| `AgendaDoomQuery` | `rules/query/agenda_doom_query.gd` | 只读场面毁灭总量，以及是否达到密谋阈值。 |
| `CandidateEnumerator` | `rules/choices/candidate_enumerator.gd` | 按候选过滤规格列出合法实体。 |
| `CandidatePreds` | `rules/choices/candidate_preds.gd` | 候选上的数值谓词，例如技能、资源、线索高低。 |
| `CandidateViability` | `rules/choices/candidate_viability.gd` | 把候选临时绑上后做 dry-run，没有结算的剔掉。 |
| `CardAccessMatcher` | `rules/deckbuilding/card_access_matcher.gd` | 构筑准入：先禁止，再无限允许，再占有限名额。 |
| `DeckLegality` | `rules/deckbuilding/deck_legality.gd` | 整副牌是否合法，以及单卡能不能买。 |
| `EffectRestrictionGate` | `rules/effects/effect_restriction_gate.gd` | 效果操作要不要查 Cannot。目前只把抽牌映到限制意图。 |
| `EffectiveCharacteristicQuery` | `rules/query/effective_characteristic_query.gd` | 有效特征：印刷减去空白，再并上获得的。 |
| `EnemyLocationQuery` | `rules/query/enemy_location_query.gd` | 把「向某敌人/调查员」收成一个地点，移动的目标始终是地点。 |
| `EnemyPathQuery` | `rules/query/enemy_path_query.gd` | 朝目标地点走一步：优先缩短距离，走不动也得走，并列给队长选。 |
| `EngagementStatus` | `rules/query/engagement_status.gd` | 谁与谁交战。庞大且未横置、同地点时算虚拟交战。 |
| `ExperienceCount` | `rules/campaign/experience_count.gd` | 幕间结算经验：共享胜利点、剧本增减、个人加减。 |
| `FleeDestinationQuery` | `rules/query/flee_destination_query.gd` | 逃逸落点：连接地点里优先没有调查员的。 |
| `HunterTargetQuery` | `rules/query/hunter_target_query.gd` | 猎手要靠近的调查员。等距先看猎物，再看队长。 |
| `ImplicitActionTargetQuery` | `rules/query/implicit_action_target_query.gd` | 基础攻击、躲避、调查没写目标时，推出那个隐式目标。 |
| `InitiationLegalityChecker` | `rules/abilities/initiation_legality_checker.gd` | 发起前用复制局面走一遍效果树，看会不会产生结算。 |
| `NearestEnemyQuery` | `rules/query/nearest_enemy_query.gd` | 最近的敌人。等距时由当前交互的玩家选。 |
| `NearestLocationQuery` | `rules/query/nearest_location_query.gd` | 最近的地点。等距时由抽牌者选。 |
| `PatrolTargetQuery` | `rules/query/patrol_target_query.gd` | 把巡逻括号里的目标解析成地点。这一步不压栈。 |
| `PerInvestigatorScale` | `rules/scenario/per_investigator_scale.gd` | 按调查员人数放大线索、生命等印刷值。 |
| `PreyQuery` | `rules/query/prey_query.gd` | 在候选人里按猎物指令挑出调查员。 |
| `QueryAlgebra` | `rules/query/query_algebra.gd` | 局面查询算子：全集、筛选、取最值、聚合、读一列。具名查询是它的模板。 |
| `RestrictionEvaluator` | `rules/registration/restriction_evaluator.gd` | 问某项意图是否被 Cannot 挡住，例如抽牌、打出、攻击、发现线索。 |
| `SpawnLocationQuery` | `rules/query/spawn_location_query.gd` | 按生成指令算出落点地点。 |
| `TextBoxBlank` | `rules/cards/text_box_blank.gd` | 把一张卡的印刷文本框标成空白或恢复。现在是布尔，特性除外和阶段结束还没写进注册。 |
| `ThreatAreaQuery` | `rules/query/threat_area_query.gd` | 威胁区里有什么，手牌中的隐私诡计也算在里面。 |
| `UniqueTitle` | `rules/cards/unique_title.gd` | 同名独特是否已经在场。独特本身由特征挂载武装。 |
| `XpCostCalculator` | `rules/campaign/xp_cost_calculator.gd` | 买一张牌或升级要花多少经验，含可插入的折扣。 |

### 7.3 管线

| 类 | 文件 | 功能 |
|---|---|---|
| `AbilityInitiationPipeline` | `rules/abilities/ability_initiation_pipeline.gd` | 发起一条能力或打出：限制、费用、dry-run，通过后在栈上解释效果树。 |
| `ActionPipeline` | `rules/pipeline/action_pipeline.gd` | 玩家行动入口：打出、借机攻击、再跑已解析的行动。 |
| `CampaignSetup` | `rules/campaign/campaign_setup.gd` | 剧本开局：开剧本、选调查员、初始牌库，再交给冒险设置。 |
| `CardAbilityPipeline` | `rules/pipeline/card_ability_pipeline.gd` | 装载并结算卡上的显现能力。 |
| `ChaosRevealIntentPlanner` | `core/chaos/chaos_reveal_intent_planner.gd` | 多条「将要揭示」能力同时在场时，排次序、分槽、再同时离袋。 |
| `CharacteristicMount` | `rules/cards/characteristic_mount.gd` | 进场挂上独特、胜利、复仇这类非关键词特征。 |
| `CompositionDryRunner` | `rules/composition/composition_dry_runner.gd` | 在复制的局面上走效果树，不写入真局面。 |
| `CompositionExecutor` | `rules/composition/composition_executor.gd` | 在已压栈的命名流程里解释效果组合树。 |
| `CompositionMount` | `rules/composition/composition_mount.gd` | 把能力效果体装进 seq.ability.resolve，禁止绕过堆栈直接执行。 |
| `DealInvestigatorPipeline` | `core/timing/deal_investigator_pipeline.gd` | 调查员承伤：分配、When、再同时施加。 |
| `DealOutboundPipeline` | `core/timing/deal_outbound_pipeline.gd` | 已定主体的外向伤恐：分配之后 When，再施加。 |
| `EffectResolutionGraph` | `rules/effects/effect_resolution_graph.gd` | 取消、忽略和代替的挂起与派发。 |
| `ElderSignBinder` | `rules/scenario/elder_sign_binder.gd` | 把调查员卡上的古印效果装成印刷符号能力。 |
| `EligibilityCollector` | `rules/eligibility/eligibility_collector.gd` | 给资格管线拍一份当前属性快照。 |
| `EligibilityPipeline` | `rules/eligibility/eligibility_pipeline.gd` | 资格收集：从订阅匹配到次数，不含费用和 dry-run。 |
| `FrameworkFlowEngine` | `rules/framework/framework_flow_engine.gd` | 驱动一轮的框架步和玩家窗：神话、调查、敌军、维持。 |
| `GameBootstrap` | `bootstrap/game_bootstrap.gd` | 创建一局：接上各库，并在创建时挂上固定规则。 |
| `GameSimulator` | `rules/composition/game_simulator.gd` | 复制局面和注册，供 dry-run 试走。 |
| `InitiationCostPipeline` | `rules/abilities/initiation_cost_pipeline.gd` | 算并支付发起费用：资源、行动，以及修正后的费用。 |
| `InvestigatorCampaignPipeline` | `rules/campaign/investigator_campaign_pipeline.gd` | 幕间购卡：报价、候选和提交。 |
| `KeywordConsumer` | `rules/keywords/keyword_consumer.gd` | 在某个槽收集已挂载的关键词监听，按优先级开火。 |
| `KeywordEffects` | `rules/keywords/keyword_effects.gd` | 解释关键词和固定规则规格里的 nest，规格不成立就不压栈。 |
| `KeywordMount` | `rules/keywords/keyword_mount.gd` | 进场时按关键词表登记关键词，并挂上它的行为。 |
| `ListenerDispatcher` | `rules/registration/listener_dispatcher.gd` | 时点到了就执行注册里的监听效果，一次性的随后注销。 |
| `ModifierEngine` | `rules/registration/modifier_engine.gd` | 按注册收集数值修正，加到基础值上。 |
| `RuleMount` | `rules/framework/rule_mount.gd` | 游戏创建时挂上固定规则。之后按槽消费，开火仍由规格解释。 |
| `ScenarioDeckSetup` | `rules/scenario/scenario_deck_setup.gd` | 开局安装场景牌库和密谋牌库。 |
| `ScenarioLayoutSetup` | `rules/scenario/scenario_layout_setup.gd` | 开局摆地点，并在只有地点状态时物化地点卡。 |
| `ScenarioPipeline` | `rules/pipeline/scenario_pipeline.gd` | 一场冒险的编排入口：组局和往下推进。 |
| `ScenarioReferenceApplier` | `rules/scenario/scenario_reference_applier.gd` | ST.4 发起参考卡或规则自带的符号能力：修正、再揭示、失败句。 |
| `ScenarioReferenceBinder` | `rules/scenario/scenario_reference_binder.gd` | 把参考卡 JSON 上的符号条装到那张卡的实例上。 |
| `SequenceCatalogBootstrap` | `bootstrap/sequence_catalog_bootstrap.gd` | 把内置的 seq.* 登记进目录。 |
| `SkillTestEngine` | `rules/skill_test/skill_test_engine.gd` | 检定步骤机：投入、揭示、符号、计算、判定、施加结果。 |
| `SkillTestIfRevealed` | `rules/skill_test/skill_test_if_revealed.gd` | 把「若本次揭示了某符号」挂到这次检定上。 |
| `SkillTestSt7Composition` | `rules/skill_test/skill_test_st7_composition.gd` | 在 ST.7 里解释成功、失败和每点失败的效果树。 |
| `TriggeredAbilityPipeline` | `rules/pipeline/triggered_ability_pipeline.gd` | 安装、卸下，并在玩家窗里列出能发的免费和激活能力。 |

### 7.4 底座

| 类 | 文件 | 功能 |
|---|---|---|
| `AbilityRegistry` | `rules/abilities/ability_registry.gd` | 按时点登记 Forced 回调。没有其它文件引用。 |
| `AbilityResponsePreferences` | `rules/interaction/ability_response_preferences.gd` | 记住本局玩家对可选响应的偏好，按卡定义和能力 id 索引。 |
| `CardRegistry` | `scripts/card_registry.gd` | 牌面目录：标题、特性、能力段、封印和次数规格。 |
| `ChaosBag` | `core/chaos/chaos_bag.gd` | 混乱袋：洗袋、离袋、能力揭示、封印和揭示账本。 |
| `ChoiceResolver` | `rules/choices/choice_resolver.gd` | 玩家决策接口。headless、脚本和界面各有一个实现。 |
| `DefaultChoiceResolver` | `rules/choices/default_choice_resolver.gd` | 无人确认时按默认选项继续，流程不挂死。 |
| `EntityRegistry` | `core/state/entity_registry.gd` | 调查员、卡、地点、敌人的实例表。 |
| `EventIndex` | `core/stats/event_index.gd` | 按回合给事件划窗口，回合开始开、回合结束关。 |
| `EventRecordLog` | `core/log/event_record_log.gd` | 追加并保存事件行，供时点和属性投影读取。 |
| `GameContext` | `api/game_context.gd` | 一局的总入口。run_seq 从这里进目录和堆栈。 |
| `GameLog` | `core/log/game_log.gd` | 给人和测试看的分类日志。 |
| `GameStatEmitter` | `core/stats/game_stat_emitter.gd` | 把回合开始等事实写进事件日志，并推进回合号。 |
| `GameStateStore` | `core/state/game_state_store.gd` | 这一局的局面：牌区、当前场景密谋、混乱袋、标记池、设置连接法则。 |
| `LocationGraph` | `rules/subsystems/location_graph.gd` | 地点拓扑：符号边并上设置连接法则，供移动和各查询问邻接、距离、路径。 |
| `PendingResolutionStore` | `rules/effects/pending_resolution_store.gd` | 保存这些挂起的结算。 |
| `PhysicalBinding` | `core/physical/physical_binding.gd` | 信息层的区划地址对应到哪一个物理区。 |
| `PhysicalOps` | `core/physical/physical_ops.gd` | 物理层的原子操作：移牌、改标记、翻面。不解释规则含义。 |
| `PhysicalStore` | `core/physical/physical_store.gd` | 物理桌面：玩家、牌、牌区、标记区。不记交战和当前密谋。 |
| `PlayerInteractionGate` | `rules/interaction/player_interaction_gate.gd` | 唯一的玩家确认入口。期内没人答就用默认。 |
| `PlayerWindowIntentPool` | `rules/interaction/player_window_intent_pool.gd` | 玩家时间段的意图池，以及超时节拍。 |
| `RegistrationStore` | `rules/registration/registration_store.gd` | 注册的存放和注销。离场、离手、离开牌库时按寿命卸。 |
| `ResolutionSequenceStack` | `core/timing/resolution_sequence_stack.gd` | 命名流程的压栈和弹出，以及 When / After 响应窗。 |
| `RulesMemory` | `core/timing/rules_memory.gd` | 一步到下一步之间记住的指称，以及遭遇帧和已取消的流程。 |
| `ScriptingChoiceResolver` | `rules/choices/scripting_choice_resolver.gd` | 测试里按脚本回答玩家确认，没写到的用默认。 |
| `SequenceCatalog` | `core/timing/sequence_catalog.gd` | 命名流程目录：登记、运行、嵌套。 |
| `StatProjectionStore` | `core/stats/stat_projection_store.gd` | 按注册维持这些投影，事件来了就更新。 |
| `StateMutator` | `core/domain/state_mutator.gd` | 信息层写入局面的咽喉：移牌、转移标记、改旗、揭示牌面。 |
| `TimingBus` | `core/timing/timing_bus.gd` | 发出一个时点，让监听调度去开火。 |
| `TokenPool` | `core/tokens/token_pool.gd` | 桌面标记的无穷供给。取出和放回都不记库存。 |
| `ZoneManager` | `core/state/zone_manager.gd` | 在局面的各个牌区数组之间移动卡。 |

### 7.5 不成桶

| 类 | 标签 | 文件 | 功能 |
|---|---|---|---|
| `AbilityBindContext` | DTO / Spec | `core/timing/ability_bind_context.gd` | 挂载能力时带上的流程、控制者、卡实例三件套。 |
| `AbilityUnitRef` | DTO / Spec | `core/timing/ability_unit_ref.gd` | 效果结算回溯到哪张卡的哪条能力，不存放效果正文。 |
| `AmountPlan` | DTO / Spec | `rules/registration/amount_plan.gd` | 效果量计划：先定目标和基准量，修正只改量，再物化分摊。 |
| `ApplicationContext` | DTO / Spec | `core/timing/application_context.gd` | 当前时点、框架步、控制者和载荷，供条件和修正匹配。 |
| `BuffSpec` | DTO / Spec | `rules/registration/buff_spec.gd` | 一条 Buff 载荷：修正、限制、监听、关键词或特征。 |
| `CandidateFilter` | DTO / Spec | `rules/choices/candidate_filter.gd` | 选目标时的静态过滤条件。 |
| `CardAbilityPackage` | DTO / Spec | `rules/encounter/card_ability_package.gd` | 按正面类型决定抽出后走调查员包还是遭遇包。 |
| `ChaosRevealRecord` | DTO / Spec | `core/chaos/chaos_reveal_record.gd` | 一次揭示的账本行。取消视为没抽到，忽略仍算揭示但不结算。 |
| `ChaosRevealReplaceAbility` | DTO / Spec | `core/chaos/chaos_reveal_replace_ability.gd` | 揭多枚再选若干结算的替换体，例如 Olive。 |
| `ChaosSymbolAbility` | DTO / Spec | `core/chaos/chaos_symbol_ability.gd` | 隐式符号能力：修正值加上效果，ST.4 发起。 |
| `ChoiceRequest` | DTO / Spec | `rules/choices/choice_request.gd` | 一次玩家确认请求：选项、默认和时限。 |
| `CommittedCard` | DTO / Spec | `rules/skill_test/committed_card.gd` | 投入检定的一张牌，以及它提供的图标。 |
| `Condition` | DTO / Spec | `core/timing/condition.gd` | 时点匹配条件：标签、框架步、属性比较、领域谓词。 |
| `DealAfflictionReport` | DTO / Spec | `core/timing/deal_affliction_report.gd` | 把实际造成的伤和恐写回当前帧，供「受到伤害后」匹配。 |
| `DeckCardView` | DTO / Spec | `rules/deckbuilding/deck_card_view.gd` | 构筑和购卡用的牌面快照，不是场上的卡实例。 |
| `DeckbuildingProfile` | DTO / Spec | `rules/deckbuilding/deckbuilding_profile.gd` | 选型之后冻结下来的有效构筑档案。 |
| `DryRunResult` | DTO / Spec | `rules/composition/dry_run_result.gd` | dry-run 是否产生过结算。 |
| `EffectRequest` | DTO / Spec | `rules/effects/effect_request.gd` | 一次效果请求：操作、来源、控制者、目标和数量。 |
| `EncounterResolutionFrame` | DTO / Spec | `core/timing/encounter_resolution_frame.gd` | 一次遭遇抽牌的诊断帧。险境限制按卡的寿命走，不挂在这上面。 |
| `EnemyAttack` | DTO / Spec | `rules/combat/enemy_attack.gd` | 一次敌人打击的参数：目标、种类、伤恐、打完是否横置。 |
| `EvaluationContext` | DTO / Spec | `core/stats/evaluation_context.gd` | 算属性投影时的调查员、回合和事件序号。 |
| `EventRecord` | DTO / Spec | `core/log/event_record.gd` | 记事里的一行：序号、种类、框架步和载荷。 |
| `InitiationIntent` | DTO / Spec | `rules/abilities/initiation_intent.gd` | 一次发起：能力或打出，带费用、行动类型和效果树。 |
| `InterruptTarget` | DTO / Spec | `core/timing/interrupt_target.gd` | 卡面「取消/忽略」要打断的那一次结算。 |
| `KeywordProfile` | DTO / Spec | `rules/keywords/keyword_profile.gd` | 一条关键词或规则的静态规格：何时挂、何时开火、nest 什么。 |
| `ListenerEntry` | DTO / Spec | `rules/registration/listener_entry.gd` | 一条监听：谁的、什么寿命、要解释的效果树。 |
| `ListenerPayload` | DTO / Spec | `rules/registration/listener_payload.gd` | 监听 Buff 的载荷：订哪个时点、带哪棵效果树。 |
| `ModifierPayload` | DTO / Spec | `rules/registration/modifier_payload.gd` | 一条数值修正：哪项、加减、多少、有没有条件。 |
| `ModifierQuery` | DTO / Spec | `rules/registration/modifier_query.gd` | 向修正引擎要哪名控制者的哪项数值。名字带 Query，本身不读局面。 |
| `PatrolTargetSpec` | DTO / Spec | `rules/encounter/patrol_target_spec.gd` | 巡逻括号里写的那个指定目标。 |
| `PendingResolution` | DTO / Spec | `rules/effects/pending_resolution.gd` | 一次还没落地的结算，取消、忽略或代替都挂在它上面。 |
| `PlayerWindowIntentEntry` | DTO / Spec | `rules/interaction/player_window_intent_entry.gd` | 玩家时间段里一条待发起的意图。 |
| `PreyInstructionSpec` | DTO / Spec | `rules/encounter/prey_instruction_spec.gd` | 猎物括号里的比较：最高或最低的技能、资源或线索。 |
| `Registration` | DTO / Spec | `rules/registration/registration.gd` | 登记库里的一条记录：寿命、控制者、上面的 Buff。 |
| `RegistrationTemplate` | DTO / Spec | `rules/registration/registration_template.gd` | 创建一条注册的模板，含常见的持续修正和限制糖。 |
| `ReplacementCandidate` | DTO / Spec | `rules/effects/replacement_candidate.gd` | 一个「改为」候选：哪条能力、换成哪次效果请求。 |
| `ReplacementTarget` | DTO / Spec | `core/timing/replacement_target.gd` | 卡面「改为」要换掉的那一次结算，以及替换载荷。 |
| `ResolutionSequenceFrame` | DTO / Spec | `core/timing/resolution_sequence_frame.gd` | 堆栈上的一帧：触发、相位、深度。 |
| `ResponsePrompt` | DTO / Spec | `core/timing/response_prompt.gd` | 一次反应选用的轻量结果。没有其它文件引用，正式确认走玩家交互门。 |
| `RestrictionPayload` | DTO / Spec | `rules/registration/restriction_payload.gd` | 一条限制的种类和参数：禁止、跳过借机、交战、分摊约束。 |
| `ScenarioReferenceDefinition` | DTO / Spec | `core/chaos/scenario_reference_definition.gd` | 一张冒险参考卡：按难度挂各符号的效果。 |
| `SealSpec` | DTO / Spec | `core/chaos/seal_spec.gd` | 封印关键词的参数：要封哪一种标记。 |
| `SelectionSpec` | DTO / Spec | `rules/choices/selection_spec.gd` | 一次选择的静态规格：选几个、过滤、结果绑到哪。 |
| `SequenceHandler` | DTO / Spec | `core/timing/sequence_handler.gd` | 堆栈上的一条订阅：匹配哪种时点、哪一档、回调是什么。 |
| `SkillTestContext` | DTO / Spec | `rules/skill_test/skill_test_context.gd` | 一次检定的现场：技能、难度、投入的牌、揭示的标记和修正后的值。 |
| `SkillTestResult` | DTO / Spec | `rules/skill_test/skill_test_result.gd` | 检定结果：成功与否、修正后的值、失败几点。 |
| `SpawnInstructionSpec` | DTO / Spec | `rules/encounter/spawn_instruction_spec.gd` | 生成指令：抽取者所在、指定地点、最近空地点，或与猎物交战。 |
| `StatFolder` | DTO / Spec | `core/stats/stat_folder.gd` | 把事件折成一个属性值，例如本回合花了几次行动。 |
| `StatProjection` | DTO / Spec | `core/stats/stat_projection.gd` | 一份算好的属性投影：查询、范围、当前值。 |
| `StatQuery` | DTO / Spec | `core/stats/stat_query.gd` | 一条属性比较：哪项、大于还是小于、和几比。名字带 Query，本身不读局面。 |
| `StatScope` | DTO / Spec | `core/stats/stat_scope.gd` | 属性投影的范围：哪名调查员、哪个回合。 |
| `TimingWindow` | DTO / Spec | `core/timing/timing_window.gd` | 一个打开的响应窗：哪次触发、When 还是 After、第几轮。 |
| `TriggeredAbilityDescriptor` | DTO / Spec | `rules/abilities/triggered_ability_descriptor.gd` | 一条已装载能力：强制、反应、免费或激活，以及它的效果树。 |
| `TriggeringCondition` | DTO / Spec | `core/timing/triggering_condition.gd` | 一次时点触发：种类、控制者、标签和载荷。 |
| `AhcEnums` | 局面形 | `core/types/ahc_enums.gd` | 领域和规则共用的枚举。 |
| `CampaignInvestigatorRecord` | 局面形 | `rules/campaign/campaign_investigator_record.gd` | 剧本里一名调查员的经验、创伤和购卡记录。 |
| `CampaignLog` | 局面形 | `rules/campaign/campaign_log.gd` | 剧本日志：记下短语，划掉的条目不再算数。 |
| `CampaignState` | 局面形 | `rules/campaign/campaign_state.gd` | 一场剧本的难度、日志和当前冒险。 |
| `CardFaceVisibility` | 局面形 | `core/domain/card_face_visibility.gd` | 谁看得到这张牌的牌面。 |
| `CardInstance` | 局面形 | `core/state/card_instance.gd` | 一张运行时卡：区域、横置、标记、印刷能力和空白旗。 |
| `CardRegion` | 局面形 | `core/physical/card_region.gd` | 物理卡区，牌库有序，其它区平铺。 |
| `CardSlot` | 局面形 | `core/domain/card_slot.gd` | 信息层的牌堆地址：哪一叠、属谁、从顶还是从底插入。 |
| `ChaosToken` | 局面形 | `core/chaos/chaos_token.gd` | 一枚混乱标记：种类、修正、是否再揭示、是否回池、封印在哪。 |
| `EnemyState` | 局面形 | `core/state/enemy_state.gd` | 场上敌人的地点、战斗、躲避、生命、伤害和关键词旗。 |
| `EntityId` | 局面形 | `core/state/entity_id.gd` | 实体身份：种类、实例 id、定义 id。 |
| `InvestigatorState` | 局面形 | `core/state/investigator_state.gd` | 一名调查员的地点、手牌、牌库、威胁区、伤恐和技能。 |
| `LocationState` | 局面形 | `core/state/location_state.gd` | 一个地点的隐藏值、线索、是否已揭示、符号连接。 |
| `MarkerKeys` | 局面形 | `core/physical/marker_keys.gd` | 物理层可数标记的键名。 |
| `MarkerLocus` | 局面形 | `core/physical/marker_locus.gd` | 标记放在独立区，还是放在某张卡上。 |
| `MarkerRegion` | 局面形 | `core/physical/marker_region.gd` | 独立标记区的数量表。供给池是无穷的。 |
| `MarkerSlot` | 局面形 | `core/domain/marker_slot.gd` | 一次标记转移的一端：种类、承载者、是池还是卡上。 |
| `PhysicalCard` | 局面形 | `core/physical/physical_card.gd` | 物理层的一张牌：所在区、正反面、上面的标记。 |
| `PhysicalPlayer` | 局面形 | `core/physical/physical_player.gd` | 座位上的玩家。规则上的调查员是另一层。 |
| `TokenBag` | 局面形 | `core/tokens/token_bag.gd` | 一张卡上的伤害、恐惧、毁灭、线索、次数和封印的标记。 |
| `ChaosBagCatalog` | Policy / 表 | `rules/campaign/chaos_bag_catalog.gd` | 剧本各难度的混乱袋配方。 |
| `DeckOptionRule` | Policy / 表 | `rules/deckbuilding/deck_option_rule.gd` | 一条 deck_options 构筑规则。 |
| `EncounterDrawPriority` | Policy / 表 | `core/timing/encounter_draw_priority.gd` | 遭遇牌抽出后的队列顺序：揭示、险境、显现、弃置。 |
| `EnterHandTimingPolicy` | Policy / 表 | `rules/config/enter_hand_timing_policy.gd` | 玩家卡入手显现在显现类内部的先后。遭遇显现不走这里。 |
| `KeywordProfileTable` | Policy / 表 | `rules/keywords/keyword_profile_table.gd` | 关键词规格表。猎物和生成指令不在这张表里。 |
| `RuleProfileTable` | Policy / 表 | `rules/framework/rule_profile_table.gd` | 建局就挂的固定规则，写法和关键词规格相同。 |
| `RulesConfig` | Policy / 表 | `rules/config/rules_config.gd` | 这一局的开关：自动选择、开局步骤、入手显现顺序。 |
| `ScenarioReferenceCatalog` | Policy / 表 | `rules/scenario/scenario_reference_catalog.gd` | 读取并缓存冒险参考卡定义。 |
| `ScenarioSetupCatalog` | Policy / 表 | `rules/scenario/scenario_setup_catalog.gd` | 开局要用的冒险数据：地点、牌库、阈值。 |
| `ActAgendaBackCompiler` | 编译器 | `rules/scenario/act_agenda_back_compiler.gd` | 把场景/密谋背面的 back_effects 编成效果组合树。 |
| `ArkhamDbAbilityCompiler` | 编译器 | `scripts/arkhamdb_ability_compiler.gd` | 把导入的卡面能力编成效果组合树。 |
| `ArkhamDbCardLoader` | 编译器 | `scripts/arkhamdb_card_loader.gd` | 把 ArkhamDB JSON 装进 CardRegistry。 |
| `ArkhamDbInstructionCompiler` | 编译器 | `scripts/arkhamdb_instruction_compiler.gd` | 把生成、猎物、巡逻指令编成对应规格。 |
| `CardScriptBase` | 编译器 | `scripts/card_script_base.gd` | 单卡脚本基类。没有子类，也没有其它文件引用。 |
| `ScenarioResolutionParser` | 编译器 | `rules/scenario/scenario_resolution_parser.gd` | 从场景或密谋背面读出指向哪个 R#。 |
| `DealSubject` | L0 附属 | `core/timing/deal_subject.gd` | 按 id 把伤害或恐惧落到敌人、场上卡或调查员。 |
| `EncounterAttachment` | L0 附属 | `rules/encounter/encounter_attachment.gd` | 显现时把悬置中的诡计附到地点；地点还没物化就先补一张地点卡。 |
| `InformationExecutor` | L0 附属 | `core/domain/information_executor.gd` | 改谁看得到牌面。这是权限，不算结算。 |
| `MarkerTransferBatch` | L0 附属 | `core/domain/marker_transfer_batch.gd` | 把多来源多目标的标记转移拆成若干次单腿转移。 |
| `VirtualCard` | L0 附属 | `rules/cards/virtual_card.gd` | 虚拟身份和蜂拥包：宿主、成员，以及整包对齐时的深度。 |
| `CompositionNode` | 静态树 | `rules/composition/composition_node.gd` | 效果组合的一个节点：顺序、分支、叶子或循环。 |
| `DrawInvestigatorComposition` | 静态树 | `core/timing/draw_investigator_composition.gd` | 调查员抽牌的中间树和记忆键：待揭示、已绑定、洗牌和恐惧。 |
| `SkillTestSt7Plan` | 静态树 | `rules/skill_test/skill_test_st7_plan.gd` | ST.7 待执行的那几支效果：成功、失败、每点失败。 |

## 8. 变更记录

| 日期 | 说明 |
|---|---|
| 2026-11-09 | v1：六桶 + 后缀硬规则 + 重命名/目录迁移 |
| 2026-11-10 | v1.1：收掉 per-seq 薄门面；统一 `run_seq`；合并重复薄层 |
| 2026-11-10 | **v2**：取消门面桶 → 五桶；`ScenarioService` → `ScenarioPipeline`；不成桶只保留标签、不开新职责 |
| 2026-11-10 | 删除 `EnemyMovement`：并入 `MoveFlow._hop_enemy_one_step_toward`（禁 L0 类膨胀） |
| 2026-11-11 | 取消触发器桶：固定规则与关键词同一套 `effect_*` 规格；规则在 `GameBootstrap.create` 由 `RuleMount` 挂载。借机攻击、Fight 失败转嫁不再是 `*Trigger` |
| 2026-11-11 | 关键词开火体改静态 nest 规格：`KeywordProfile.effect_*` + `KeywordEffects`；猎手/巡逻/涌动/反击/警戒/毁灭/逃逸不再各写实现类；蜂拥垫牌为 `SwarmPadFlow`，庞大阶段攻击批留在交战域 |
| 2026-11-10 | 删除 `KeywordMovementFlowHandlers`：猎手/巡逻只填 `toward`，地点变更统一 `MoveFlow` / `seq.effect.move` |
| 2026-11-10 | 深合并：`SwarmDamage`→`DefeatFlow`；`EncounterGainedKeyword`/`AloofStatus`/`EncounterPeril`/`EncounterPrivacy`→`KeywordMount`；`Hunter`/`Patrol` 目标并入 `MoveFlow.toward`；`DrawEncounterSubflow`→`DrawEncounterFlow`；`DrawSubflow`→`DrawInvestigatorFlow`；`LocationEnterRules`→`RevealLocationFlow`；`InvestigatorCampaignSystem`→`InvestigatorCampaignPipeline`；`DamagePipeline`→`DealInvestigatorPipeline`；`DealPreImpact`→`DealOutboundPipeline`；`AgendaDoomPolicy`→`AgendaDoomQuery`+写入并入 `AgendaAdvanceFlow`；`EncounterCardDiscard`→`ZoneMoveFlow`；`InvestigatorElimination`→`DefeatFlow` |
| 2026-11-11 | 全库普查：生产 `class_name` 233（不含 tests 7、ui 5）。流程体 38、查询 27、管线 38、底座 31、不成桶 99。`*Trigger` / `*Service` / `*System` 均为 0。仍是专用实现类、未收成规格：`StartingKeyword`、`BlessCurseRules` |
| 2026-11-13 | 祝福/诅咒改为规则自带符号能力：效果字典与参考卡同形，ST.4 走 `ScenarioReferenceApplier`。删除 `BlessCurseRules`。生产类 232，管线 37 |
| 2026-11-13 | 起始：用卡的 `owner_id` nest `seq.effect.search` 再入手。删除 `StartingKeyword`。生产类 231，管线 36 |
| 2026-11-13 | 删除 `MassiveEngagement`。虚拟交战归 `EngagementStatus`；阶段攻击批归 `EnemyPhaseFlow`；进场/移动/接战不再清威胁区。生产类 230，流程体 37 |
| 2026-11-16 | 删除 `SwarmPack`、`DamageAssigner`、`ScenarioSetAside`。蜂拥绑定在 `VirtualCard`，整包对齐在移动/接战/横置；分摊在 `DealAssignableFlow`；set-aside 在 `ScenarioCompositionFlowHandlers`。生产类 227，不成桶 96 |
| 2026-11-16 | 普查为每个生产类写下职责。逐类重数后：底座 30、不成桶 97、局面形 20（含 `TokenBag`）。无其它引用：`AbilityRegistry`、`CardScriptBase`、`LocationGraph`、`ResponsePrompt` |
| 2026-11-16 | `LocationGraph` 提供拓扑查询：地点符号边与设置连接法则分开。移动、寻路、生成、逃逸、连接候选改走这里 |
| 2026-11-16 | 查询算子 `QueryAlgebra`：scan / where / rank / aggregate / project。生产类 228，查询 28。具名 `*Query` 尚未改成模板调用 |
