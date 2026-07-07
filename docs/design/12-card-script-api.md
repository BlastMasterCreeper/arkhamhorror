# 12 — 卡牌脚本 API 规格 (CardScriptAPI)

> **依赖**：全部 design/01–11  
> **目标**：定义 Script Layer 唯一入口，使 Core 2026 卡牌可脚本化实现

---

## 1. 设计原则

1. **脚本不持有 State 裸引用** — 仅 `GameContext` + 门面 API
2. **声明 + 命令** — `register_abilities()` 声明；运行时通过 `EffectBuilder` 提交
3. **双轨** — 优先 `AbilityTemplate`；模板无法表达时用 `CardScript`。**不设固定比例**，按卡逐张选型（已裁决 OQ-12-01，见 §1.1）
4. **可测试** — 脚本可在 headless `GameContext` 下 unit test

### 1.1 Template vs Script 选型（已裁决 OQ-12-01）

**不设 70/30 等目标比例**；设计阶段无法预判。实现 Core 2026 卡牌时 **逐张裁决**，并在 `data/cards/` 或变更记录中注明选型理由。

| 优先 **AbilityTemplate** | 优先 **CardScript**（或 `on_custom_effect`） |
|---|---|
| 标准 EffectOp 链（draw / heal / discover / deal） | 多分支 player choice、复杂条件树 |
| 单 timing + 固定 cost | 动态 X、跨卡/跨区状态查询 |
| 关键词由引擎 handler 覆盖 | Scenario/Campaign 特化交互 |
| Committed skill「If successful…」 | Replacement / fail-by / 嵌套检定特规 |
| Constant modifier 注册 | Template 表达力不足或维护成本更高 |

**流程**：导入卡牌文本 → 尝试 `AbilityTemplate` → 无法无损表达或 dry-run 无法通过 → 补 `CardScript` / `ScenarioScript`。比例随卡池自然形成，**不作为 KPI**。

### 1.2 Core 2026 选型快照（ArkhamDB · Phase 4）

> **详表**：[`data/arkhamdb/reports/phase4_core_2026_backfill.md`](../../data/arkhamdb/reports/phase4_core_2026_backfill.md) §5

| 选型 | 张数 | 说明 |
|---|---:|---|
| Template 全匹配 | 0 | Phase 3 模板均为 `partial`（条件/检定后缀） |
| Template 部分 | 12 | 如 12003 enter_threat_area、12015 take_damage（首句） |
| Script 优先 | 113 | 含 `[reaction]`/`[action]`/检定类 revelation |

**记录约定**：逐卡选型写入 `data/packs/core_2026/cards/{code}.yaml`（OQ-12-06）；当前机器可读来源为 `imported/*.json` 的 `compiled_abilities` 字段。带 **If/Otherwise** 的 revelation 须含 `if_kind` 与 `template: if_else`（若适用）——见 [07-composition §3.3](07-composition.md#33-卡面-if-消歧timing--condition--both--已裁决-2026-07-07)。

---

## 2. 注册与加载

```gdscript
# boot
CardRegistry.load_pack("core_2026")

class CardRegistry:
    static func register(definition: CardDefinition, script: GDScript = null) -> void
    static func create_instance(def_id: StringName, owner: StringName) -> CardInstance
    static func get_script(def_id: StringName) -> CardScriptBase
```

```gdscript
class CardDefinition:
    var id: StringName
    var title: String
    var card_type: CardType
    var traits: Array[StringName]
    var cost: int
    var level: int
    var class: StringName
    var skills_icons: Dictionary
    var health: int
    var sanity: int
    var slots: Array[SlotType]
    var keywords: Array[StringName]
    var printed_abilities: Array[AbilityTemplate]
    # ① 规则参数（07 §0.1）— Spawn：② G4 读；Prey：② engage / ③ Hunter 等距读，不 nest
    var spawn_instruction: SpawnInstructionSpec | null
    var prey_instruction:  PreyInstructionSpec  | null
    # Patrol 括号 ①；Patrol 移动 ③ LISTENER @ 3.2（07 §0.1.3）
    var script_path: String                # optional
```

---

## 3. CardScriptBase

```gdscript
class_name CardScriptBase
extends RefCounted

var ctx: GameContext
var instance: CardInstance

func _init(context: GameContext, card: CardInstance) -> void:
    ctx = context
    instance = card

## 注册结构化能力（引擎解析 AbilityTemplate）
func register_abilities(reg: AbilityRegistrar) -> void:
    pass

## 生命周期
func on_enter_play(_payload: Dictionary = {}) -> void: pass
func on_leave_play(_payload: Dictionary = {}) -> void: pass
func on_exhaust() -> void: pass
func on_ready() -> void: pass

## 若 printed text 无法模板化，override 动态逻辑
func on_custom_effect(effect_id: StringName, payload: Dictionary) -> void: pass
```

---

## 4. AbilityRegistrar

```gdscript
class AbilityRegistrar:
    func add_constant(id: StringName, handler: Callable) -> void
    func add_forced(id: StringName, when: TimingPoint, handler: Callable) -> void
    func add_reaction(id: StringName, condition: TriggerCondition, handler: Callable) -> void
    func add_free(id: StringName, window: PlayerWindow, handler: Callable) -> void
    func add_action(id: StringName, cost_icons: int, designators: Array, handler: Callable) -> void
    func from_template(t: AbilityTemplate) -> void   # 数据驱动 fallback
```

Handler 签名：`func(ctx: GameContext, instance: CardInstance, payload: Dictionary) -> void`

---

## 5. 门面 API

### 5.1 GameContext

```gdscript
class GameContext:
    func for_investigator(id: StringName) -> InvestigatorAPI
    func for_active_investigator() -> InvestigatorAPI
    func for_performing_investigator() -> InvestigatorAPI
    func skill_test() -> SkillTestAPI
    func combat() -> CombatAPI
    func scenario() -> ScenarioAPI
    func effects() -> EffectBuilder
    func query() -> QueryAPI
    func log(message: String, category := "CARD") -> void
    func is_in_player_window(w: PlayerWindow) -> bool
    func request_player_choice(choice: ChoiceRequest) -> ChoiceResult
```

### 5.2 InvestigatorAPI

```gdscript
class InvestigatorAPI:
    func draw(n: int = 1) -> void
    func gain_resource(n: int = 1) -> void
    func spend_resource(n: int) -> bool
    func get_skill(s: SkillType) -> int
    func get_location() -> EntityId
    func get_hand() -> Array[EntityId]
    func get_play_area() -> Array[EntityId]
    func get_threat_area() -> Array[EntityId]
    func take_damage(n: int, opts: Dictionary = {}) -> void
    func take_horror(n: int, opts: Dictionary = {}) -> void
    func heal_damage(n: int, target: EntityId = self) -> void
    func discover_clue(n: int, from_location: EntityId) -> void
    func move_to(location: EntityId) -> void
```

### 5.3 SkillTestAPI

见 [04-skill-test-engine.md](04-skill-test-engine.md)。

### 5.4 CombatAPI

```gdscript
class CombatAPI:
    func fight(enemy: EntityId, base_damage: int = 1) -> SkillTestHandle
    func evade(enemy: EntityId) -> SkillTestHandle
    func enemy_attack(enemy: EntityId, target: StringName, kind: AttackKind) -> void
    func defeat_enemy(enemy: EntityId) -> void
```

### 5.5 ScenarioAPI

```gdscript
class ScenarioAPI:
    func get_current_act_number() -> int
    func get_doom_on_agenda() -> int
    func place_doom_on_agenda(n: int) -> void
    func advance_act() -> Result
    func search_encounter_deck(filter: Callable) -> Array[EntityId]
    func spawn_enemy(def_id: StringName, location: EntityId, drawer: StringName) -> EntityId
    func read_codex(entry: int) -> String              # narrative text
    func trigger_resolution(r: int) -> void
```

### 5.6 EffectBuilder（链式）

```gdscript
class EffectBuilder:
    func deal_damage(n: int) -> DamageBuilder
    func deal_horror(n: int) -> HorrorBuilder
    func transfer_damage(n: int) -> TransferAfflictionBuilder   # 不算 heal（07 §4.1）
    func transfer_horror(n: int) -> TransferAfflictionBuilder
    func cancel_revelation(treachery: EntityId) -> EffectBuilder
    func modify_skill_value(delta: int, source: EffectSource) -> EffectBuilder
    func submit() -> EffectResult

class DamageBuilder:
    func to(target: EntityId) -> DamageBuilder
    func direct() -> DamageBuilder
    func with_source(s: EffectSource) -> EffectBuilder
```

### 5.7 QueryAPI（只读）

```gdscript
class QueryAPI:
    func get_enemies_at_location(loc: EntityId) -> Array[EntityId]
    func get_investigators_at_location(loc: EntityId) -> Array[StringName]
    func count_clues_on_location(loc: EntityId) -> int
    func is_engaged(enemy: EntityId, inv: StringName) -> bool
    func get_card_in_play_by_title(title: String) -> EntityId
```

---

## 6. AbilityTemplate（数据驱动）

**存储**：纯 **`data/` 下 YAML**（Git diff 友好）；Godot 启动时加载解析（已裁决 OQ-12-06）。**不用** `.tres` 作为主格式。

```
data/
  packs/core_2026/
    cards/*.yaml          # CardDefinition + printed_abilities[]
    abilities/*.yaml      # 可复用 AbilityTemplate
```

覆盖常见模式，减少脚本量：

```yaml
# 示例：Logan Hastings reaction
id: logan_after_defeat_enemy
kind: TRIGGERED_REACTION
trigger: { after: enemy_defeated, controller: self }
cost: { exhaust: true }
effects:
  - gain_resource: { amount: 1, target: controller }
```

```yaml
# Deduction skill
id: deduction_extra_clue
kind: COMMITTED_SKILL
trigger: { on_skill_test_end, successful: true, action: investigate }
effects:
  - discover_clue: { amount: 1, at: test_location }
```

模板无法表达时 fallback 到 `CardScript.on_custom_effect`。

---

## 7. Core Set 示例实现

### 7.1 Ward of Protection（Fast Event Cancel）

> **规范译法**（Interrupt 族 · SEQUENCE）：见 [07-effect-resolution §6.0.1](07-effect-resolution.md#601-样例ward-of-protectioncancel--sequence)。  
> **FAQ**：Cancel revelation 后 treachery **仍进 encounter discard**；显现效果不结算。

**AbilityCompiler 产出（与脚本双轨对齐）**：

```gdscript
# compile 结果 ≈ 下列 composition（非 CardScript 手写 cancel_revelation Service）
CompositionNode.seq([
    CompositionNode.interrupt_cancel(
        InterruptTarget.sequence(
            &"seq.encounter.revelation",
            {"card_id": trigger_card_id, "controller_id": initiator_id}
        )
    ),
    # + deal 1 horror（nest seq.deal.horror 或 L0 Atom）
])
```

**Legacy CardScript 双轨**（复杂/过渡期 fallback；新卡优先 Compiler）：

```gdscript
extends CardScriptBase

func register_abilities(reg: AbilityRegistrar) -> void:
    reg.add_free("ward_cancel", PlayerWindow.PW_WHEN_DRAW_TREACHERY, _on_ward)

func _on_ward(_ctx, _inst, payload: Dictionary) -> void:
    var treachery = payload.get("card")
    if treachery == null or _is_weakness(treachery):
        return
    # 目标：与 Compiler 相同 — nest seq.interrupt.cancel + horror
    _ctx.sequence_catalog.run(_ctx, &"seq.interrupt.cancel", {
        "controller_id": _ctx.performing_investigator_id(),
        "target": {
            "kind": "sequence",
            "flow_id": &"seq.encounter.revelation",
            "bind": {"card_id": treachery.id.instance_id},
        },
    })
    _ctx.for_performing_investigator().take_horror(1)
```

### 7.2 Meat Cleaver（Action + Forced nested cost）

- Template：`[action] Fight + skill test modifiers`
- Script override：`on_custom_effect("meat_cleaver_optional_horror")` 处理 take 1 horror for +1 damage

### 7.3 Deduction（Committed Skill）

- 纯 `AbilityTemplate` COMMITTED_SKILL

### 7.4 Logan Hastings（Ally Reaction）

- Template：After defeat enemy, exhaust, gain 1 resource
- Constant：`You get +1 [willpower]` → modifier registration

### 7.5 Servant of Flame（Enemy）

- Keywords: Hunter, Prey, Retaliate — 引擎 keyword handler
- Spawn/engage 默认管线

### 7.6 Spreading Flames Scenario Reference

```gdscript
extends ScenarioScriptBase

func register_chaos_effects(reg: ChaosEffectRegistrar) -> void:
    reg.on_skull(func(ctx, st):
        var x = ctx.scenario().get_current_act_number()
        st.add_modifier(-x, source)
        st.on_fail_by(2, func():
            # ST.7：fail by 2+ → search Fire! from discard
            ctx.encounter().draw_from_discard_by_title("Fire!")
        )
    )
```

---

## 8. ScenarioScriptBase / CampaignScriptBase

```gdscript
class ScenarioScriptBase:
    func on_setup(ctx: GameContext, setup: ScenarioSetup) -> void
    func register_chaos_effects(reg: ChaosEffectRegistrar) -> void
    func on_act_advanced(act: EntityId) -> void
    func on_agenda_advanced(agenda: EntityId) -> void
```

```gdscript
class CampaignScriptBase:
    func on_scenario_complete(resolution: int, log: CampaignLog) -> void
    func modify_chaos_bag(bag: ChaosBag, log: CampaignLog) -> void
    func validate_deck(record: CampaignInvestigatorRecord) -> Result
```

---

## 9. 测试 harness

```gdscript
# tests/cards/test_ward_of_protection.gd
func test_cancel_non_weakness_treachery():
    var harness = RuleTestHarness.new("spreading_flames", ["joe_diamond"])
    harness.draw_treachery_for("player_1")
    harness.initiate_fast("ward_of_protection", "player_1")
    assert(harness.revelation_cancelled())
    assert(harness.horror_on("player_1") == 1)
```

---

## 10. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-12-02 | P1 | Codex 📖 交互：引擎 `read_codex(n)` 返回文本 + UI 展示，还是 ScenarioScript 完全控制 narrative？ |
| OQ-12-03 | P1 | CardScript 热重载（开发时）是否需求？ |
| OQ-12-04 | P2 | 非 GDScript 卡牌逻辑（Lua/DSL）是否在路线图中？ |
| OQ-12-05 | P1 | `request_player_choice` 同步阻塞 vs async signal — Godot 主线程模型选型？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-12-01 | **不设固定 Template/Script 比例**；实现阶段 **逐卡选型**，优先 Template，不足则 Script。选型准则见 §1.1。 | 2026-05-25 |
| OQ-12-06 | **纯 `data/*.yaml`**，启动时加载；不用 `.tres` 作主格式。见 §6。 | 2026-05-25 |

---

## 11. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-12-01 裁决：逐卡选型，无固定比例 |
| 2026-05-25 | v0.3 | OQ-12-06 裁决：YAML in data/ |
