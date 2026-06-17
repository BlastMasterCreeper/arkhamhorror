# 03 — 行动系统 (ActionSystem)

> **依赖**：[02-framework-flow.md](02-framework-flow.md), [06-ability-initiation.md](06-ability-initiation.md)  
> **规则来源**：Grimoire Draw/Fight/... Action entries; Attack of Opportunity (p.38)

---

## 1. 目标

实现调查员在 Investigation Phase 的 **11 类行动**、Action Designator 语义、以及 **Attack of Opportunity (AOO)** 完整管线。

---

## 2. 行动类型枚举

```gdscript
enum ActionType {
    DRAW,
    RESOURCE,
    ACTIVATE,
    PLAY,
    MOVE,
    INVESTIGATE,
    ENGAGE,
    EVADE,
    FIGHT,
    PARLEY,      # 非独立 action token；通过 Play/Activate 带 designator
    RESIGN,
}
```

| 行动 | 基础/衍生 | 消耗 actions | 触发 AOO |
|---|---|---|---|
| Draw | 基础 | 1 | 是 |
| Resource | 基础 | 1 | 是 |
| Activate | 衍生 | 1×每个 [action] | 视 designator |
| Play | 衍生 | 1（Fast 除外） | Fast 否；否则是 |
| Move | 基础 | 1 | 是 |
| Investigate | 基础 | 1 | 是 |
| Engage | 基础 | 1 | 是 |
| Evade | 基础 | 1 | **否** |
| Fight | 基础 | 1 | **否** |
| Parley | designator | 见来源 | **否** |
| Resign | designator | 见来源 | **否** |

---

## 3. ActionRequest 与执行流程

```gdscript
class ActionRequest:
    var type: ActionType
    var investigator_id: StringName
    var targets: Array[EntityId]
    var source_card: EntityId          # Activate/Play 来源
    var ability_id: StringName         # 若 Activate
    var designators: Array[ActionType] # 如 [ACTIVATE, FIGHT]
```

### 3.1 执行管线

```
1. 校验 FrameworkStep == INV_2_2_1 且 investigator 有 actions
2. 校验行动合法性（目标、地点、engage 状态等）
3. AbilityInitiationPipeline.pre_check（若经能力）
4. 计算 action cost（[action] 个数 n = 该能力 **一次行动花费**）
5. Pay action cost（actions_remaining -= n，**一次付清**）
6. ──► Resolve AOO（若 applicable，**整次 initiating 最多 1 次**）
7. 执行行动主体（可能发起 SkillTest）
8. Framework 回到 PW_AFTER_ACTION
```

### 3.2 行动花费与借机攻击（已裁决 OQ-03-04）

多个 [action] 符号表示该能力的 **行动花费总量**（如 [action][action] = 花费 2 actions），**不是**分多次各走一遍行动框架。

| 规则 | 说明 |
|---|---|
| **一次花费** | `actions_remaining -= n` **一次扣完**；不循环 n 次 `INV_2_2_1` |
| **借机攻击** | 一次花费行动的能力 **最多 provoke AOO 一次**（付完 cost 后、主体效果前） |
| **Framework** | 仍占 **一个** `INV_2_2_1` 行动槽（只是该槽内消耗 n 点） |

```gdscript
func pay_action_cost(request: ActionRequest) -> void:
    var n := count_action_icons(request.ability)   # [action] 个数
    state.actions_remaining[request.investigator_id] -= n

func resolve_aoo_if_needed(request: ActionRequest) -> void:
    if provokes_aoo(request):
        aoo_resolver.resolve_once(request)   # 整次 initiate 仅一次
```

---

## 4. Activate 与 Action Designator

Grimoire：带 bold **Fight/Evade/Investigate/Move** 的能力视为对应行动类型。

```gdscript
func get_action_designators(ability: AbilityDef) -> Array[ActionType]:
    # 例：[action]: Fight ([combat] or [agility]) → [ACTIVATE, FIGHT]
    pass

func provokes_aoo(request: ActionRequest) -> bool:
    if request.type in [ActionType.EVADE, ActionType.FIGHT]:
        return false
    if ActionType.PARLEY in request.designators or ActionType.RESIGN in request.designators:
        return false
  # Activate 同时是 Fight → 不 provokes
    if ActionType.FIGHT in request.designators or ActionType.EVADE in request.designators:
        return false
    return has_ready_engaged_enemies(request.investigator_id)
```

**Activate 来源**（Grimoire Activate Action）：

- 控制者控制的 in-play 卡（含 investigator 卡）
- 同地点 scenario 卡（含 location、该地点 encounter、同地点 investigator threat area 卡）
- current act / current agenda

---

## 5. Attack of Opportunity

AOO 由 **触发条件 + 时点 + 攻击效果** 三部分组成；攻击效果经 `CombatAPI.enemy_attack()` 进入统一 `perform_attack()` 管线（见 [08-enemy-engagement.md §6](08-enemy-engagement.md)）。

| 层 | AOO 规则 |
|---|---|
| **触发** | 调查员 provoke action（付完 cost）；非 Fight/Evade/Parley/Resign；存在 ready engaged enemy |
| **时点** | cost 付完后、原 action 效果 resolve **之前** |
| **攻击效果** | 每位 ready engaged enemy 各攻击一次（顺序调查员选）；`AttackKind.OPPORTUNITY`；不 exhaust |

Grimoire p.38 顺序：

1. 调查员**付完** initiating action 的全部 cost
2. 每个 ready engaged enemy 攻击（顺序由调查员选）
3. AOO **不** exhaust enemy
4. 全部 AOO 完成后，才 resolve 原 action 效果

```gdscript
class AttackOfOpportunityResolver:
    func provokes(request: ActionRequest) -> bool: ...       # 触发条件
    func resolve(inv: StringName, provoking_request: ActionRequest) -> void:
        var enemies := state.get_ready_engaged_enemies(inv)
        var order := ui.choose_order(inv, enemies)
        for e in order:
            CombatAPI.enemy_attack(e, inv, AttackKind.OPPORTUNITY)  # 仅攻击效果层
        # 然后 return control to action body
```

AOO 的攻击效果计为 **enemy attack**（可触发「After enemy attacks you」等 [reaction]）。**Provoke 判定与插入时点保留在本 Resolver**，不得并入 `perform_attack()`。

---

## 6. 各行动规则摘要

### 6.1 Draw

- 从 deck 顶抽 1；deck 空 → shuffle discard + take 1 horror + draw（同时发生）
- discard 也空 → defeated + 1 mental trauma
- **规范抽牌序列**（信息 D2 可见、WHEN=D2–D3、Weakness 显现于入手）：见 **[15-timing-entry-catalog §16](15-timing-entry-catalog.md)**

### 6.2 Resource

- 从 global token pool → investigator resource pool +1

### 6.3 Play

- 选 hand 中 asset/event；付 resource cost → pool
- Event：resolve → discard
- Asset：进 play area；检查 slots，不足则 discard 已有 asset
- Skill **不可** Play
- Fast：不耗 action，走 Initiation Pipeline，任意指定 player window

### 6.4 Move

- 移到 connecting location；unrevealed → reveal + place clues
- 进入时若有 ready unengaged enemy → auto engage

### 6.5 Investigate

- Intellect test vs location shroud
- 成功：discover 1 clue（即使 location 0 clue 也可 investigate，Grimoire）

### 6.6 Engage

- 选同地点 enemy → threat area
- 可抢 engage 他人 engaged 的 enemy（原调查员 disengage）
- 不能 engage massive；不能 engage 已 engaged 自己的
- 可对 aloof / exhausted enemy engage

### 6.7 Evade

- 仅 engaged with self 的 enemy
- Agility vs evade；成功 → exhaust + disengage to location

### 6.8 Fight（已裁决 OQ-03-01）

**以 Grimoire（魔典书）为准**；Rulebook 入门描述仅为简化。

**默认合法目标**（基础 Fight 行动）：performing investigator **当前地点**上的敌人，包括：

| 子情况 | 说明 |
|---|---|
| 同地点 **unengaged** 敌人 | 在 location 上、不在任何人 threat area |
| **威胁区内**与自己交战的敌人 | engaged with self |
| 同地点、与他人交战的其他敌人 | 在队友 threat area，仍算同地点（Grimoire） |

**不合法**（除非卡牌能力另说）：

- 不同地点的敌人
- **Aloof** 且未与任何人交战（须先 Engage 或能力允许）

**卡牌能力扩展**：部分能力允许以**超出同地点**的敌人为 Fight 目标（如「Choose an enemy at a connecting location… Fight」）。由 `ActionRequest.source_card` / ability 文本覆盖默认 `is_valid_fight_target()`。

```gdscript
func is_valid_fight_target(inv: StringName, enemy: EntityId, ability: AbilityDef = null) -> bool:
    if ability and ability.extends_fight_range():
        return ability.validate_fight_target(inv, enemy)
    return location_graph.enemy_at_investigator_location(inv, enemy)
```

- Combat vs fight value
- 成功：deal 1 damage（可被武器修改）
- 失败且 enemy engaged 他人：damage → 该调查员

### 6.9 Parley / Resign

- 必须带 designator 的 [action] 或 Play
- Parley 通常要求 **enemy 在同地点**（除非文本另说）
- Resign：clues/tokens 留 location；investigator eliminated

### 6.10 Activate current agenda（已裁决 OQ-03-03）

**Agenda（密谋）没有「在地点上」的概念。** 调查员可以 **Activate** current agenda 上的 [action] 能力，但 **不** 视为 Parley「同地点」目标。

| 能力来源 | 地点语义 |
|---|---|
| Location / 同地点 encounter / 威胁区卡 | 按 Grimoire「同地点」规则 |
| **Current act / current agenda** | **无地点**；仅校验 Activate 来源合法 + ability 文本 |
| Parley designator 指向 agenda | **不** 因 Parley 而要求「同地点」— agenda 不参与地点 graph |

```gdscript
func is_valid_activate_source(inv: StringName, card: EntityId) -> bool:
    if card == scenario.current_agenda or card == scenario.current_act:
        return true   # 无 location 检查
    return location_graph.same_location(inv, card)
```

---

## 7. 额外行动 / 失去行动

- 回合外 gain action → 下回合 `actions_remaining` 增加
- 回合外 lose action → 下回合减少
- 在 investigation phase 外 gain/lose 在**该调查员 turn 开始**时应用（Grimoire Action）

---

## 8. ActionSystem API

```gdscript
class ActionSystem:
    func can_take_action(req: ActionRequest) -> Result
    func execute(req: ActionRequest) -> Result
    func get_available_actions(inv: StringName) -> Array[ActionType]
```

---

## 9. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| A-01 | engaged 时 Draw | AOO 先结算 |
| A-02 | [action] Fight 能力 | 无 AOO |
| A-03 | Fast event 在他人 turn window | 不耗 action |
| A-04 | Fight 打 aloof unengaged | 非法 |
| A-05 | Fight fail，enemy engaged 队友 | 队友受伤 |
| A-06 | [action][action] Activate | actions **一次 -2**；**至多 1 轮** AOO（非按 [action] 次数重复） |

---

## 10. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-03-05 | P2 | Elusive 在 AOO 后是否仍触发（AOO 算 attack）？ |
| OQ-03-06 | P1 | Play asset 时 slot 弃置：玩家选顺序还是引擎默认最旧 asset？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-03-01 | **以 Grimoire 为准。** 基础 Fight 目标 = 调查员**当前地点**上的敌人（含 unengaged、自己 threat 区、同地点他人 engaged 的敌人）。特殊卡牌能力可扩展目标范围至地点外。Aloof 未 engage 不可打。 | 2026-05-25 |
| OQ-03-02 | **攻击效果层**统一 `EnemyAttack` + `AttackKind`（PHASE / OPPORTUNITY / RETALIATE / ALERT），共用 `perform_attack()`，均属 enemy attack。**触发条件与时点**各 kind 独立（AOO→Action 管线、Retaliate/Alert→Skill Test、Phase→Enemy Phase）；不得把 provoke / ST.7 插入逻辑并入 `perform_attack()`。见 08 §6.1。 | 2026-05-25 |
| OQ-03-03 | **Agenda 无地点概念**；可 Activate agenda 能力，**不**视为 Parley 同地点。见 §6.10。 | 2026-05-25 |
| OQ-03-04 | [action]×n = **一次行动花费**，`actions_remaining -= n` **一次付清**；整次 initiating **至多 1 轮 AOO**。见 §3.2。 | 2026-05-25 |

---

## 11. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-03-01 裁决：Fight 目标以 Grimoire 同地点为准 |
| 2026-05-25 | v0.3 | OQ-03-02 裁决：EnemyAttack 统一攻击效果层 |
| 2026-05-25 | v0.4 | OQ-03-02 补充：触发 / 时点 / 攻击效果三层结构 |
| 2026-05-25 | v0.5 | OQ-03-03/04 裁决：Agenda 无地点；一次行动花费 + 一次 AOO |
