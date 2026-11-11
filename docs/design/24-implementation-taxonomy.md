# 24 — 实现类职责桶与命名（v2 · 五桶）

> **状态**：v2（2026-11-10）— **取消门面为一等桶**  
> **依赖**：[17-seq-runtime](17-seq-runtime.md) R4、effect-translation  
> **目的**：看后缀知职责；禁止平行业务 `*System`；禁止为单条 `seq.*` 增殖 `*Service`。

---

## 1. 五桶（唯一职责分类）

| # | 桶 | 英文 | 后缀 | 一句话 |
|---|---|---|---|---|
| 1 | **流程体** | Flow | `*Flow` / `*FlowHandlers` | 某条/一组 `seq.*` 的 RESOLVE |
| 2 | **触发器** | Trigger | `*Trigger` | 到点判开火 → nest/run Flow |
| 3 | **查询** | Query | `*Query`（状态只读可用 `*Status`） | 只读；不压栈、不 CREATED |
| 4 | **管线** | Pipeline | `*Pipeline` / `*Engine` / `*Mount` | 跨 seq 工序、装载、编排、解释器；**含稀少聚合入口** |
| 5 | **底座** | Infrastructure | 领域名（无业务后缀） | Catalog/栈/Gate/Store/局面；**`GameContext.run_seq`** |

```text
管线 / Framework / 测试 ──▶ GameContext.run_seq / catalog.nest ──▶ Catalog+栈(底座) ──▶ 流程体
触发器 ──nest/run ─────────▲                                                    ├─ Query
                                                                               └─ Gate(底座)
```

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
5. **开火** → `*Trigger`；禁止再用 `*Resolver` 表示开火或选址。  
6. **PI 选择** → 保留 `ChoiceResolver` 族（底座交互，≠ Query）。  
7. **禁止空 `*System` 挂点**；新代码不要加 `*System` 业务 API。  
8. **L0 写局面且仅被 Flow 调用** → 可留短名；文档归 **不成桶 · L0 附属**（或收进对应 `*Flow`）。

---

## 3. 不成桶 — **不必再开职责桶**

不成桶不是第六职责，只是 **不进五桶的东西**。再拆成一等桶会重蹈「空分类」：它们不压栈、不发起、不查询局面规则语义。

可读性上允许 **标签**（文档/盘点用，非后缀硬规则）：

| 标签 | 放什么 | 例子 |
|---|---|---|
| **DTO / Spec** | 参数、意图、能力描述、选择规格 | `EffectRequest`、`InitiationIntent`、`SelectionSpec`、`EnemyAttack` |
| **静态树** | Composition / ST.7 计划树 | `CompositionNode`、`SkillTestSt7Plan` |
| **局面形** | 实体状态、物理槽、枚举 | `CardInstance`、`InvestigatorState`、`AhcEnums` |
| **L0 附属** | 仅被 Flow 调用的写局面/域辅助（优先收进对应 `*Flow`，勿增殖） | `EncounterDoomPlacement`、`RevealLocationFlow` |
| **Policy / 表** | 阈值、挂载表、配置谓词 | `AgendaDoomQuery`、`KeywordProfileTable`、`EnterHandTimingPolicy` |

**禁止**：为上述标签新建 `*DtoBucket` / `*SpecService` 等职责层；标签只服务阅读。

---

## 4. 目录约定

| 目录 | 放什么 |
|---|---|
| `core/flow/` | 对局主路径 `*Flow` / `*FlowHandlers` |
| `rules/pipeline/` | 稀少聚合入口 `*Pipeline`（行动 / 场景 / 能力装载） |
| `rules/trigger/` | `*Trigger` |
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
| `*Resolver`（开火/选址） | `*Trigger` / `*Query` | Trigger / Query |
| `ActionSystem` | `ActionPipeline` | Pipeline |
| `ScenarioSystem` → `ScenarioPipeline` | **`ScenarioPipeline`** | Pipeline |
| per-seq 薄 `*Service` | **删除** → `run_seq` | — |
| `InterruptHandler` / `ReplacementHandler` / `EffectOpExecutor` / `MassiveKeywordFlow` / `EnemySystem` | 并入 FlowHandlers / ERG / MassiveEngagement / 删除 | — |

**保留边界**：`ChoiceResolver*`（底座）、`*Status`、`*Engine`、`EffectResolutionGraph`（管线 · pending Cancel/Instead，待再收）。

---

## 6. 审查口诀

- 打开新类：先问落在五桶哪一格；答不上来 → 多半是 **不成桶**（DTO/树/局面形），不是缺第六桶。  
- 新增「只包一层 `catalog.run`」的类 → **违规**（用 `run_seq`）。  
- 打开 `*Trigger`：出现扣血/横置写入 → **违规**。  
- 打开 `*Query`：出现改局面 → **违规**。  
- 打开 `*Flow`：对外再暴露平行业务 API → **违规**。  
- 打开 `*Pipeline`：超过跨 seq 编排 / 装载 / 聚合入口 → 考虑拆 Flow。  

---

## 7. 变更记录

| 日期 | 说明 |
|---|---|
| 2026-11-09 | v1：六桶 + 后缀硬规则 + 重命名/目录迁移 |
| 2026-11-10 | v1.1：收掉 per-seq 薄门面；统一 `run_seq`；合并重复薄层 |
| 2026-11-10 | **v2**：取消门面桶 → 五桶；`ScenarioService` → `ScenarioPipeline`；不成桶只保留标签、不开新职责 |
| 2026-11-10 | 删除 `EnemyMovement`：并入 `MoveFlow._hop_enemy_one_step_toward`（禁 L0 类膨胀） |
| 2026-11-11 | 关键词开火体改静态 nest 规格：`KeywordProfile.effect_*` + `KeywordEffects`；猎手/巡逻/涌动/反击/警戒/毁灭/逃逸不再各写实现类；蜂拥垫牌为 `SwarmPadFlow`，庞大阶段攻击批留在交战域 |
| 2026-11-10 | 删除 `KeywordMovementFlowHandlers`：猎手/巡逻只填 `toward`，地点变更统一 `MoveFlow` / `seq.effect.move` |
| 2026-11-10 | 深合并：`SwarmDamage`→`DefeatFlow`；`EncounterGainedKeyword`/`AloofStatus`/`EncounterPeril`/`EncounterPrivacy`→`KeywordMount`；`Hunter`/`Patrol` 目标并入 `MoveFlow.toward`；`DrawEncounterSubflow`→`DrawEncounterFlow`；`DrawSubflow`→`DrawInvestigatorFlow`；`LocationEnterRules`→`RevealLocationFlow`；`InvestigatorCampaignSystem`→`InvestigatorCampaignPipeline`；`DamagePipeline`→`DealInvestigatorPipeline`；`DealPreImpact`→`DealOutboundPipeline`；`AgendaDoomPolicy`→`AgendaDoomQuery`+写入并入 `AgendaAdvanceFlow`；`EncounterCardDiscard`→`ZoneMoveFlow`；`InvestigatorElimination`→`DefeatFlow` |
