# 00 — 架构总览

> **版本**：设计草案 v0.3  
> **规则基准**：2026 Core Set Rulebook + Arkham Grimoire v1.0  
> **范围**：规则引擎抽象层；不含 UI、不含完整卡牌数据库

---

## 1. 目标

将《诡镇奇谈：卡牌版》（Arkham Horror: The Card Game, AHC LCG）的 2026 Core Set 规则抽象为**严谨、可运行、解耦**的电子系统，满足：

1. **Framework Event** 与 **Player Window** 严格分离，对齐 Grimoire 时点图。
2. **规则完备性**：电子版 **引擎即规则**；时点、冲突、Cannot/Replacement/tier 等须 **可判定、可重放**（见 [07 §3.2](design/07-effect-resolution.md)）。**Grim Rule 不是** 主路径（§6）。
2. 所有卡牌逻辑通过 **数据定义 + 可选脚本** 实现，引擎只提供通用原语。
3. 子系统边界清晰，可独立测试与迭代。
4. 扩展包通过 `CardPack` / `ScenarioPack` 插件化接入，无需修改核心引擎。

---

## 2. 四层架构

```
┌─────────────────────────────────────────────────────────┐
│  Presentation Layer（后续）                              │
│  UI · 输入 · Hidden/Peril 信息隔离 · 多人同步（可选）     │
└───────────────────────────┬─────────────────────────────┘
                            │ Request / Event
┌───────────────────────────▼─────────────────────────────┐
│  Script Layer                                            │
│  CardScript · ScenarioScript · CampaignScript            │
└───────────────────────────┬─────────────────────────────┘
                            │ 门面 API（禁止直接改 State）
┌───────────────────────────▼─────────────────────────────┐
│  Rules Layer                                             │
│  FrameworkFlowEngine · ActionSystem · SkillTestEngine    │
│  AbilityInitiationPipeline · EffectResolutionGraph       │
└───────────────────────────┬─────────────────────────────┘
                            │ 读写 Domain
┌───────────────────────────▼─────────────────────────────┐
│  Domain Layer                                            │
│  GameStateStore · EntityRegistry · ZoneManager             │
│  TokenPool · TimingBus · GameLog · EventRecord           │
└─────────────────────────────────────────────────────────┘
```

| 层 | 职责 | 禁止 |
|---|---|---|
| **Domain** | 实体、区域、标记、查询；纯数据与不变量 | 回合逻辑、卡牌文本、随机裁定 |
| **Rules** | 框架步骤推进、检定、能力 initiation、效果 DAG | 硬编码单卡逻辑 |
| **Script** | 卡牌/场景/战役特有行为 | 绕过 API 直接修改底层状态 |
| **Presentation** | 渲染、玩家输入、信息可见性 | 在 UI 层做规则裁定 |

**依赖规则（单向）**：Presentation → Rules → Domain；Script → Rules（经 API）。Domain 不依赖 Rules。

---

## 3. Godot 模块划分（建议）

```
res://
├── core/                    # Domain Layer
│   ├── state/
│   │   ├── game_state.gd
│   │   ├── entity_registry.gd
│   │   └── zone_manager.gd
│   ├── tokens/
│   │   └── token_pool.gd
│   ├── timing/
│   │   └── timing_bus.gd
│   └── log/
│       ├── game_log.gd
│       └── event_record.gd
├── rules/                   # Rules Layer
│   ├── framework/
│   │   └── framework_flow_engine.gd
│   ├── actions/
│   │   └── action_system.gd
│   ├── skill_test/
│   │   └── skill_test_engine.gd
│   ├── abilities/
│   │   ├── ability_initiation_pipeline.gd
│   │   └── ability_registry.gd
│   ├── effects/
│   │   └── effect_resolution_graph.gd
│   └── subsystems/            # 领域规则协调器
│       ├── enemy_system.gd
│       ├── location_graph.gd
│       └── scenario_system.gd
├── scripts/                 # Script Layer 基类与注册
│   ├── card_script_base.gd
│   ├── scenario_script_base.gd
│   ├── ability_registrar.gd
│   └── card_registry.gd
├── api/                     # 脚本门面（Script 唯一入口）
│   ├── game_context.gd
│   ├── investigator_api.gd
│   ├── skill_test_api.gd
│   ├── combat_api.gd
│   └── scenario_api.gd
└── data/                    # 静态定义（Resource / JSON）
    └── packs/
        └── core_2026/
```

---

## 4. 全局 GameContext

`GameContext` 是 Rules 层与 Script 层之间的**唯一会话上下文**，在单局游戏生命周期内存在。

### 4.1 职责

- 持有对 `GameStateStore`、`FrameworkFlowEngine`、`TimingBus` 的只读或受控引用。
- 提供 **Investigator-scoped** 与 **Global** 两种 API 作用域。
- 追踪当前 `FrameworkStep`、主动调查员、Lead Investigator、嵌套深度（检定/能力栈）。

### 4.2 作用域模型

| 作用域 | 含义 | 示例 API |
|---|---|---|
| `Global` | 与特定调查员无关 | `get_doom_in_play()`, `get_current_act()` |
| `Investigator(id)` | 绑定单一调查员 | `draw_card()`, `gain_resource()`, `get_hand()` |
| `ActiveInvestigator` | 当前回合调查员 | `take_action(ActionType.FIGHT, target)` |
| `PerformingInvestigator` | 当前检定/能力发起者 | `commit_to_test(card)` |

```gdscript
# 概念形状
class GameContext:
    var state: GameStateStore
    var framework: FrameworkFlowEngine
    var timing: TimingBus
    var log: GameLog

    var active_investigator_id: StringName
    var performing_investigator_id: StringName
    var lead_investigator_id: StringName
    var current_step: FrameworkStep
    var skill_test_stack: Array[SkillTestContext]
    var initiation_stack: Array[InitiationContext]

    func for_investigator(id: StringName) -> InvestigatorAPI
    func skill_test() -> SkillTestAPI
    func combat() -> CombatAPI
    func scenario() -> ScenarioAPI
```

### 4.3 脚本访问约束

- `CardScript` 通过构造函数注入 `GameContext` + `CardInstance`。
- Script **不得** 持有 `GameStateStore` 裸引用；所有变更经 `EffectBuilder.submit()` 或 `ActionSystem.request()`。
- 嵌套检定时，`GameContext.skill_test_stack` 栈顶为当前检定上下文。

---

## 5. 核心设计决策摘要

### 5.1 Framework Event 状态机

- 用显式 `FrameworkStep` 枚举驱动回合，**禁止**自由 `trigger_timing()` 推进框架。
- `FrameworkFlowEngine` 是唯一推进框架的组件。
- 第 1 回合跳过 Mythos Phase（Grimoire p.27）。

详见 [design/02-framework-flow.md](design/02-framework-flow.md) 与 [design/00-framework-step-index.md](design/00-framework-step-index.md)（Grimoire 逐步 ID 对照表）。

### 5.2 Timing Bus 三层模型

| 类型 | 规则对应 | 顺序 |
|---|---|---|
| **Forced** | Forced – when/after/at/if | 同 timing point 全部 forced 先完 |
| **Framework** | 框架步骤内嵌 | 不可跳过 |
| **Triggered** | Free / Reaction / Action | Forced 之后 |

Initiation Sequence 独立为 `AbilityInitiationPipeline`（Grimoire p.31）。

详见 [design/06-ability-initiation.md](design/06-ability-initiation.md)。

### 5.3 Effect Graph

- 统一处理 Target、Cancel、Ignore、Instead、Then、Lasting、Delayed、Modifiers。
- 卡牌脚本提交 `EffectRequest`，由 `EffectResolutionGraph` 顺序/并行解析。

详见 [design/07-effect-resolution.md](design/07-effect-resolution.md)。

### 5.4 卡牌双轨制

| 轨道 | 适用 |
|---|---|
| **Data-driven** | 关键词、常量加成、模板化触发（逐卡优先尝试，见 12 §1.1） |
| **Script-driven** | Template 无法表达时的复杂分支、场景交互 |

组合：`CardDefinition` + `AbilityDefinitions[]` + 可选 `CardScript`。

详见 [design/12-card-script-api.md](design/12-card-script-api.md)。

### 5.5 Headless 规则运行（已裁决 OQ-00-06）

**裁决**：需要。v1 即支持**单进程 headless** 无 UI 规则运行，用于自动化测试与批量回归。

架构采用**同一套 Domain + Rules 层，两种入口**：

```
┌─────────────────────┐     ┌─────────────────────┐
│  Headless 入口       │     │  游戏客户端入口      │
│  tests/runner.gd    │     │  Main.tscn + UI      │
│  godot --headless   │     │  玩家输入 → Request  │
└──────────┬──────────┘     └──────────┬──────────┘
           │                           │
           └───────────┬───────────────┘
                       ▼
           GameContext + Rules Layer
           （Framework / Action / SkillTest / Effect）
                       ▼
                  Domain Layer
```

**Headless 入口职责**：

- 通过脚本/API 提交动作（非鼠标点击），例如 `harness.take_action(ActionType.INVESTIGATE)`
- 玩家选择由 `ChoiceResolver` 处理：测试脚本注入确定性选择，或 AI 默认策略
- 固定 RNG seed，输出 `EventRecord` + `state_hash`，供 CI 断言

**约束**：

- Rules / Domain 层**不得**依赖 `Node`、场景树、纹理、输入事件
- 需玩家裁决时（伤害分配、Lead Investigator 多选一），经 `ChoiceRequest` 抽象，headless 与 UI 共用接口
- Presentation 层不参与 headless 路径

**建议目录**：

```
res://tests/
├── harness/rule_test_harness.gd    # setup + action + assert
├── scenarios/                      # 按场景/卡牌分组的回归用例
└── run_headless.gd                 # CI 入口
```

**CI 示例**：`godot --headless --path . -s res://tests/run_headless.gd`

---

## 6. 规则优先级与 Grim Rule（实体 vs 电子版）

| 规则 | 行为 |
|---|---|
| **Golden Rule** | 卡牌文本 > 规则书 |
| **Cannot** | 卡面 / RESTRICTION 的 **cannot** **绝对**；其他能力 **不得** countermand（Grimoire *Cannot*）。见 [07 §3.2](design/07-effect-resolution.md) |
| **Silver Rule** | 两卡文本 **直接矛盾且无法调和** 时：遭遇 > 玩家；双遭遇/双玩家 → 队长。**不**适用于 Cannot；**不**适用于 Replacement 栈（见 [07 §3.2–§3.4](design/07-effect-resolution.md)） |
| **Grim Rule**（Grimoire） | 玩家 **查不到规则 / 无法共识 / 局进行不下去** 时，选当时认为 **对通关最不利** 的方式继续。**含** 时点冲突——但前提是 **人肉查书失败**，不是规则体系的正式答案 |

### 6.1 实体桌游：Grim 的真实角色

Grimoire 明确：Grim Rule **is not an exhaustive answer**；目的是 **lookup 太费时** 时 **让实体局继续**，障碍主要来自 **玩家对规则不熟 + 无法快速查到**，而非规则书「缺了一条」。

时点冲突、Replacement 争用等，在桌游里 **本应有 Grimoire 答案**；落到 Grim 说明 **桌上没能及时找到那条答案**。

### 6.2 电子版：完备规则，Grim 非主路径

本项目的 **产品目标** 是 **数字化 Grimoire + 引擎内建完备裁定**：

| 实体桌游 | 电子版引擎 |
|---|---|
| 玩家查 PDF / 讨论 | **TimingCatalog、SequenceCatalog、07 §3.2 冲突栈** 直接给出结果 |
| 不熟规则 → 可能 Grim | **不应** 因「不熟悉」触发 Grim |
| Grim 含 timing 冲突 | timing 冲突应在 **层 0–4 + 队长合法多选** 内 **确定性 resolve** |
| 落到 Grim = 继续游戏 | 落到 Grim = **`RulesEngineGap`**（实现漏洞 / 设计师未决 OQ），应 **assert / 日志 / 修引擎**，而非 silent 猜最糟 |

```text
正常对局路径：
  Cannot → Replacement → Cancel → tier → Silver → Lead 合法多选
  （永不进入 Grim）

仅以下情况可配置 Grim / AUTO_WORST：
  · headless 回归探测未覆盖分支（显式 seed config）
  · 故意模拟实体桌「查书失败」（house / 教学模式，可选）
  · 设计师 OQ 尚未关闭且允许临时继续（应标记 TECH_DEBT）
```

### 6.3 `RulesConfig.grim_rule_mode`

| 模式 | 用途 |
|---|---|
| **`DISABLED`**（**引擎默认**） | 冲突栈无法 resolve → **push_error / EventRecord `RULES_GAP`**；测试 fail fast |
| `AUTO_WORST` | headless / 探索性回归；**非** 正式对局默认 |
| `PAUSE_FOR_RULING` | 带 UI 时人工裁定（极少） |

```gdscript
# rules/config/rules_config.gd — 默认 DISABLED；GameBootstrap.create(..., config) 可覆盖
var grim_rule_mode: GrimRuleMode = GrimRuleMode.DISABLED
```

**Invariant（目标）**：任意合法游戏状态转移，引擎 **不依赖** Grim Rule 即可推进。Grimoire 的 Grim 条文保留为 **对照说明**，解释实体桌为何存在该兜底，**不**作为电子版冲突解析的主算法。

---

## 7. 日志与可重放

### 7.1 GameLog

分类：`SYSTEM` | `FRAMEWORK` | `ACTION` | `ABILITY` | `SKILL_TEST` | `DAMAGE` | `CARD` | `SCENARIO`

### 7.2 EventRecord

每条框架步骤、**Initiation 各步**、Skill Test 步骤、效果提交写入 append-only `EventRecord`（Initiation 与 Framework **同级**完整记录，已裁决 OQ-IDX-02）：

```gdscript
class EventRecord:
    var seq: int
    var timestamp_ms: int
    var kind: StringName          # "framework_step", "initiation_step", "skill_test_step", "effect_applied", ...
    var framework_step: FrameworkStep      # kind == framework_step 时
    var skill_test_step: SkillTestStep     # kind == skill_test_step 时（独立枚举，见 IDX）
    var initiation_step: InitiationStep    # kind == initiation_step 时
    var payload: Dictionary
    var state_hash: String        # 可选，用于回归测试
```

用途：调试、回放、AI 训练、规则回归测试。

---

## 8. 与现有 addon 的差异对照

同盘原型位于 `Godot Dice Roller/godot-dice-roller/addons/arkham_horror_lcg/`（Godot 4.3，约 15–20% 逻辑层）。

| addon 现有 | 本设计处置 |
|---|---|
| `TimingSystem` 30+ 粗粒度 `TimingWindow` | 替换为 `FrameworkStep` + `TimingBus` 三层模型；Window 与 Step 一一映射 |
| `ArkhamGameManager` 阶段枚举不完整 | 由 `FrameworkFlowEngine` 独占流程；Manager 降为门面或废弃 |
| `CardInstance.Zone` 缺 Limbo/Victory/ThreatArea | 扩展见 [design/01-game-state-zones.md](design/01-game-state-zones.md) |
| `InspectorSystem` 未集成 | 合并为 `Investigator` 实体 + `PlayerArea` |
| 无 SkillTest / ChaosBag | [design/04](design/04-skill-test-engine.md) / [design/05](design/05-chaos-bag.md) 从零定义 |
| `CardScriptBase` 钩子过少 | 扩展为 `AbilityRegistrar` 模式，见 [design/12](design/12-card-script-api.md) |
| `create_card_instance` 未挂载脚本 | `CardRegistry` 在实例化时绑定 Script + Abilities |
| `ally_script.gd` 调用不存在的 `get_inspector()` | 统一经 `GameContext.for_investigator()` |

**本阶段不迁移 addon 代码**；实现阶段可择其 `GameLog`、部分 `CardData` 结构复用。

---

## 9. 子系统文档索引

| 文档 | 子系统 |
|---|---|
| [00-framework-step-index.md](design/00-framework-step-index.md) | FrameworkStep / ST / Initiation 完整索引 |
| [01-game-state-zones.md](design/01-game-state-zones.md) | GameStateStore、区域、实体 |
| [02-framework-flow.md](design/02-framework-flow.md) | FrameworkFlowEngine |
| [03-action-system.md](design/03-action-system.md) | ActionSystem、AOO |
| [04-skill-test-engine.md](design/04-skill-test-engine.md) | SkillTestEngine |
| [05-chaos-bag.md](design/05-chaos-bag.md) | ChaosBagSystem |
| [06-ability-initiation.md](design/06-ability-initiation.md) | AbilitySystem、Initiation |
| [07-effect-resolution.md](design/07-effect-resolution.md) | EffectResolutionGraph |
| [08-enemy-engagement.md](design/08-enemy-engagement.md) | EnemySystem |
| [09-location-graph.md](design/09-location-graph.md) | LocationGraph |
| [10-scenario-encounter.md](design/10-scenario-encounter.md) | ScenarioSystem |
| [11-investigator-campaign.md](design/11-investigator-campaign.md) | Investigator、Campaign |
| [12-card-script-api.md](design/12-card-script-api.md) | CardScript API |
| [open-questions-master.md](open-questions-master.md) | 规则疑点汇总 |

---

## 10. 测试场景（架构级）

| ID | 场景 | 验证点 |
|---|---|---|
| A-01 | 空局初始化 → Setup 14 步 → 进入 Round 1 Investigation | 跳过 Mythos |
| A-02 | Round 2 完整四阶段 | FrameworkStep 顺序 |
| A-03 | 嵌套检定中 Script 调用 API | Context 栈不泄漏 |
| A-04 | EventRecord 回放 | 同 seed 同终态 |
| A-05 | Grim Rule AUTO_WORST | 日志记录裁定 |

---

## 11. Open Questions（本模块）

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-00-02 | P1 | 多人 hot-seat vs 网络：Lead Investigator 裁定权是否仅本地主机持有？ |
| OQ-00-03 | P2 | `EventRecord` 是否需持久化到磁盘以支持战役中断恢复？ |
| OQ-00-04 | P1 | 实现阶段是否迁移 addon，还是在 `arkhamhorror` 全新实现并仅参考 API 形状？ |
| OQ-00-05 | P2 | AI 控制同伴调查员时，Hidden/Peril 信息隔离是否在 Presentation 层模拟「不读牌名」？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-00-06 | **需要 headless**。v1 支持单进程 `godot --headless` 无 UI 规则运行；Domain/Rules 与 UI 解耦，共用 `GameContext`；测试经 `RuleTestHarness` + 固定 seed + `EventRecord`/`state_hash` 回归。详见 §5.5。 | 2026-05-25 |
| OQ-00-01 | 电子版默认 `grim_rule_mode`？ | **`DISABLED`**；冲突由 07 §3.2 完备栈 resolve；`AUTO_WORST` 仅 headless 显式开启。Grim = 实体查书受阻兜底，非引擎主路径。见 §6。 | 2026-06-18 |

---

## 12. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | 增加 Framework Step 索引引用 |
| 2026-05-25 | v0.3 | OQ-00-06 裁决：v1 支持 headless 规则运行（§5.5） |
| 2026-05-25 | v0.4 | OQ-00-01 默认 AUTO_WORST；OQ-IDX-02 EventRecord 扩展 |
| 2026-06-18 | v0.5 | **§6** Grim Rule 实体 vs 电子版；默认 `DISABLED`；完备规则 invariant |
