# 24 — 实现类职责桶与命名（v1.1）

> **状态**：已落地一版（2026-11-09）；门面收口（2026-11-10）  
> **依赖**：[17-seq-runtime](17-seq-runtime.md) R4、effect-translation、六类职责讨论  
> **目的**：降低耦合、提高可读性——**看后缀知职责**；禁止再增平行业务 `*System`；**禁止为每条 `seq.*` 增殖薄 `*Service`**。

---

## 1. 六桶（唯一分类）

| # | 桶 | 英文 | 后缀 | 一句话 |
|---|---|---|---|---|
| 1 | **门面** | Facade | `*Service`（稀少） | **聚合**入口（组局/场景编排）；单条 seq **不**单独挂门面 |
| 2 | **流程体** | Flow | `*Flow` / `*FlowHandlers` | 某条/一组 `seq.*` 的 RESOLVE |
| 3 | **触发器** | Trigger | `*Trigger` | 到点判开火 → nest/run Flow |
| 4 | **查询** | Query | `*Query`（状态只读可用 `*Status`） | 只读；不压栈、不 CREATED |
| 5 | **管线** | Pipeline | `*Pipeline` / `*Engine` / `*Mount` | 跨 seq 工序、装载、编排、解释器 |
| 6 | **底座** | Infrastructure | 领域名（无业务后缀） | Catalog/栈/Gate/Store/局面/战役；**`GameContext.run_seq`** |

**不成桶**：Composition 静态树、Spec/DTO、nest vs 内联（Flow 内走法）。

```text
管线 / 测试 / Framework ──▶ GameContext.run_seq / catalog.nest ──▶ Catalog+栈(底座) ──▶ 流程体
场景门面（稀少） ──────────▶ run_seq / setup helpers                              ├─ Query
触发器 ──nest/run ─────────▲                                                    └─ Gate(底座)
```

### 1.1 门面收口（已裁决）

| 允许 | 禁止 |
|---|---|
| `GameContext.run_seq(flow_id, params)` / `sequence_catalog.nest` | 为 `seq.effect.gain_resource` / `seq.draw.*` / `seq.mythos.*` / `seq.enemy.*` / `seq.action.*` 各挂一个 `*Service` |
| `ScenarioService`：setup + 薄转发 `run_seq`（神话/遭遇抽/推进） | `ResourceGainService`、`DrawInvestigatorService`、`DrawEncounterService`、`MythosService`、`EnemyPhaseService`、`ActionSequenceService` |
| `ActionPipeline`：行动外壳内直接 `run_seq` | 再经一层 `ActionSequenceService` |

---

## 2. 命名硬规则

1. **多条相近 seq 合集** → 一律 `*FlowHandlers`（禁止裸 `*Handlers`）。  
2. **单条主手续** → `*Flow`。  
3. **`*Service` 仅聚合门面**；装载/开火管线用 `*Pipeline`/`*Mount`；**单条 seq 禁止新 `*Service`**。  
4. **选址/猎物/距离** → `*Query`；交战/冷漠等有效状态 → `*Status` 可保留。  
5. **开火** → `*Trigger`；禁止再用 `*Resolver` 表示开火或选址。  
6. **PI 选择** → 保留 `ChoiceResolver` 族（底座交互，≠ Query）。  
7. **禁止空 `*System` 挂点**；新代码不要加 `*System` 业务 API。  

8. **L0 写局面且仅被 Flow 调用** → 可留短名，但文档归 **流程体附属**；优先收进对应 `*Flow`。

---

## 3. 目录约定（本版）

| 目录 | 放什么 |
|---|---|
| `rules/facade/` | **稀少**聚合门面（现仅 `ScenarioService`） |
| `core/flow/` | 对局主路径 `*Flow` / `*FlowHandlers`（从 `core/timing` 迁出手续体） |
| `rules/trigger/` | `*Trigger` |
| `rules/query/` | `*Query` / 只读 `*Status` 与路径查询 |
| `rules/pipeline/` | `*Pipeline` / 行动·发起·Mount（渐进） |
| `core/timing/` | 栈、Catalog、TimingBus、RulesMemory 等 **底座运行时** |
| `rules/choices/` · `rules/interaction/` · `rules/registration/` | 底座（PI / Buff） |

一时迁不尽的类：以 **class 后缀** 为准，目录后续再收。

---

## 4. 本版已执行的重命名 / 收口（摘要）

| 旧 | 新 | 桶 |
|---|---|---|
| `BasicActionHandlers` | `BasicActionFlowHandlers` | Flow |
| `CardAbilityService` | `CardAbilityPipeline` | Pipeline |
| `TriggeredAbilityService` | `TriggeredAbilityPipeline` | Pipeline |
| `ScenarioCompositionAtoms` | `ScenarioCompositionFlowHandlers` | Flow |
| `ScenarioSetAsideService` | `ScenarioSetAside` | 场景域工具（≠ Catalog 门面） |
| `ImplicitActionTargets` | `ImplicitActionTargetQuery` | Query |
| `EnemyHunterTarget` | `HunterTargetQuery` | Query |
| `EnemyLocationTarget` | `EnemyLocationQuery` | Query |
| `EnemyPathfinding` | `EnemyPathQuery` | Query |
| `DrawSubflowHandlers` | `DrawSubflowFlowHandlers` | Flow |
| `DrawEncounterSubflowHandlers` | `DrawEncounterSubflowFlowHandlers` | Flow |
| （此前轮）开火/选址 `*Resolver`、`ActionSystem`、`ScenarioSystem` | `*Trigger` / `*Query` / `ActionPipeline` / `ScenarioService` | taxonomy-rename |
| `ResourceGainService` / `Draw*Service` / `MythosService` / `EnemyPhaseService` / `ActionSequenceService` | **删除** → `GameContext.run_seq` / `ActionPipeline` / `ScenarioService` | facade-collapse |
| `InterruptHandler` / `ReplacementHandler` | **并入** `InterruptFlowHandlers` / `ReplacementFlowHandlers` | impl-dedupe |
| `EffectOpExecutor` | **并入** `EffectResolutionGraph._execute_op` | impl-dedupe |
| `EncounterAgendaDoomPlacement` | **并入** `MythosFlow.place_on_current_agenda` | impl-dedupe |
| `MassiveKeywordFlow` | **并入** `MassiveEngagement.resolve_keyword` | impl-dedupe |
| `EnemySystem` | **删除**（空挂点） | impl-dedupe |

**目录迁移**：`rules/facade/` · `rules/trigger/` · `rules/query/` · `rules/pipeline/` · `core/flow/`；栈/Catalog 留在 `core/timing/`。

**保留**：`ScenarioService`（setup 聚合）、`ChoiceResolver*`、`EnemyMovement`（流程体附属 L0）、`*Status`、`*Engine`、`EffectResolutionGraph`（pending Cancel/Instead，待后续再收）。

---

## 5. 审查口诀

- 打开 `*Service`：超过聚合入口 / 薄 `run_seq` → **违规**；单条 seq 的转发类 → **应删**。  
- 打开 `*Trigger`：出现扣血/横置写入 → **违规**。  
- 打开 `*Query`：出现改局面 → **违规**。  
- 打开 `*Flow`：对外再暴露平行业务 API → **违规**。  
- 新增「只包一层 `catalog.run`」的类 → **违规**（用 `run_seq`）。  

---

## 6. 变更记录

| 日期 | 说明 |
|---|---|
| 2026-11-09 | v1：六桶 + 后缀硬规则 + 本版重命名/目录迁移 |
| 2026-11-10 | v1.1：收掉 per-seq 薄门面；统一 `GameContext.run_seq` |
| 2026-11-10 | v1.1+：合并重复薄层（Interrupt/Replace Handler、EffectOp、AgendaDoom 包装、MassiveKeywordFlow、EnemySystem stub）；砍 move/engage 真空旁路 |
