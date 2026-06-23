# 08 — 敌人、交战与移动 (EnemySystem)

> **依赖**：[01-game-state-zones.md](01-game-state-zones.md), [03-action-system.md](03-action-system.md), [09-location-graph.md](09-location-graph.md)  
> **规则来源**：Grimoire Enemy Cards, Hunter, Massive, Engagement, Enemy Phase

---

## 1. 目标

管理敌人 **Spawn、Engagement、移动、攻击** 及关键词：Aloof、Hunter、Patrol、Prey、Massive、Retaliate、Alert、Elusive、Doomed。

---

## 2. 敌人状态

```gdscript
class EnemyState:
    var card: EntityId
    var location: EntityId
    var engaged_with: StringName          # "" if unengaged
    var in_threat_area: bool
    var ready: bool                       # !exhausted
```

---

## 3. Engagement 规则

| 事件 | 行为 |
|---|---|
| **Encounter draw，无 Spawn 文本**（非 Aloof） | **`spawn_engaged(drawer)`** — 原子进场 engaged + threat area；**无** auto engage 过程 |
| Spawn at location **有** Spawn 文本（或效果指定 location） | 先进 location → **`auto_engage_at_location`**（除非 Aloof） |
| Investigator enters location with ready unengaged enemy | auto engage |
| Enemy moves into location with investigator | auto engage |
| Exhausted enemy readies at location with investigator (Upkeep 4.3) | auto engage |
| **Engage action** | 手动 engage（与 spawn 无关的 **[action]**） |
| Evade success | disengage → enemy at location |
| **Aloof spawn**（含无 Spawn 的 encounter draw） | at drawer location，**unengaged**，**不**进 threat area |
| Massive | ready: engaged with **all** at location; exhausted: none; **never** in threat area |

**术语**：**`spawn_engaged`** = 进场时已是 engaged 状态（L0 一次提交）；**`auto_engage_at_location`** = 已在 location 的 unengaged 敌人按 Engagement 规则选目标；**`Engage action`** = 调查员行动。三者 **不可** 混用。

**多调查员同地点**：Lead Investigator 选 engage 目标（Prey 优先）。

---

## 4. Prey 与 Hunter 目标（已裁决 OQ-08-01）

Hunter 移动 / 选最近调查员时：

1. 计算每位调查员的 **最短路径步数**，取 **等距（equidistant）** 子集
2. **在等距子集内** 按 **Prey** 过滤 / 比较（Prey 不可选非等距调查员）
3. Prey 仍有多选或等距内无 Prey 匹配 → **Lead Investigator** 在等距子集中选择

```gdscript
func choose_hunter_target(enemy: EntityId) -> EntityId:
    var equidistant := investigators_at_minimum_path_distance(enemy)
    var prey_matches := filter_by_prey(enemy, equidistant)
    if prey_matches.size() == 1:
        return prey_matches[0]
    if prey_matches.size() > 1:
        return resolve_prey_tie(prey_matches)   # 或 Lead 选
    return ui.lead_investigator_choose(equidistant)
```

Prey 示例：`Prey (lowest [agility])` — 在等距子集内比较 agility 值。

---

## 5. Hunter / Patrol 移动（Enemy 3.2）

| 关键词 | 移动 |
|---|---|
| Hunter | ready, unengaged, 不在有 investigator 的地点 → 沿最短路径向 nearest investigator 移动 1 步 |
| Patrol | 向括号内目标移动 1 步（方向/地点/卡） |
| 阻挡 | card ability 阻止移动 → 不移动 |
| 移动后遇 investigator | auto engage |

**不移动**：exhausted、已 engaged、hunter 已在有 investigator 地点。

---

## 6. 敌人攻击（已裁决 OQ-03-02）

### 6.1 三层结构：触发 → 时点 → 攻击效果

AOO、Retaliate、Alert、敌人阶段攻击 **不是**「只有攻击」——每条都由三部分组成；**仅第三部分**统一为 `EnemyAttack` 原语。

| 层 | 职责 | 是否按 `AttackKind` 分化 |
|---|---|---|
| **触发条件** | 何种游戏事件使该攻击**有资格**发生 | 是（各 kind 独立规则） |
| **时点** | 在 Framework / Skill Test 的**哪一步**插入 | 是 |
| **攻击效果** | deal damage/horror、exhaust、Elusive 等 | **否** — 统一 `perform_attack()` |

```gdscript
# ── 攻击效果层（统一）──
enum AttackKind { PHASE, OPPORTUNITY, RETALIATE, ALERT }

class EnemyAttack:
    var enemy: EntityId
    var target_investigator: StringName
    var kind: AttackKind          # 供 [reaction] 过滤与日志；不改变结算逻辑
    var damage: int
    var horror: int
    var exhaust_after: bool

func perform_attack(attack: EnemyAttack) -> void:
    damage_pipeline.deal(attack.damage, attack.horror, attack.target)
    timing_bus.emit("enemy_attack_completed", attack)   # 可触发 After enemy attacks you 等
    if attack.exhaust_after:
        exhaust(attack.enemy)
    check_elusive_after_attack(attack.enemy)
```

```gdscript
# ── 触发 + 时点层（分化）──
# 各 Resolver 只负责「是否触发、何时触发」，满足后构造 EnemyAttack 并调用 perform_attack()

class AttackOfOpportunityResolver:   # 见 03-action-system §5
    func check_trigger(action: ActionRequest) -> bool: ...
    func resolve_timing(action: ActionRequest) -> void: ...  # cost 付完后、action 效果前

class RetaliateTrigger:
    func check_trigger(test: SkillTestContext) -> bool: ...  # fail fight vs ready + Retaliate
    func resolve_timing(test: SkillTestContext) -> void: ... # ST.7 内 / fight fail 后果链

class AlertTrigger:
    func check_trigger(test: SkillTestContext) -> bool: ...  # fail evade vs ready + Alert
    func resolve_timing(test: SkillTestContext) -> void: ... # ST.7 之后

class EnemyPhaseAttackResolver:
    func check_trigger(enemy: EntityId) -> bool: ...         # Enemy Phase 3.3, engaged
    func resolve_timing() -> void: ...                        # 按 player order batch
```

### 6.2 各 AttackKind 的三层对照

| AttackKind | 触发条件 | 时点 | 攻击效果 (`perform_attack`) |
|---|---|---|---|
| **OPPORTUNITY** | 调查员 provoke：付完 action cost；非 Fight/Evade/Parley/Resign；ready engaged enemy | Action 管线内，**全部 AOO 完成后**才 resolve 原 action | `exhaust_after = false` |
| **RETALIATE** | Fail **fight** test vs **ready** enemy（带 Retaliate） | Fight test **ST.7** 后果链 | `exhaust_after = false` |
| **ALERT** | Fail **evade** test vs **ready** enemy（带 Alert） | Evade test **ST.7 之后** | `exhaust_after = false`；可不 engaged |
| **PHASE** | Enemy Phase 3.3；enemy engaged（Massive 见 §6.3） | `ENEMY_PHASE_ATTACK` FrameworkStep | `exhaust_after = true`（Massive batch 例外） |

**统一边界**：上述四种在 **攻击效果层** 均属 **enemy attack**，共用 `perform_attack()`，可触发「After enemy attacks you / After enemy attacks」等 [reaction]。**触发与时点逻辑不得并入 `perform_attack()`**，须保留在各 Resolver / Trigger 中。

| 来源 | exhaust_after |
|---|---|
| Enemy Phase 3.3 | true |
| AOO | false |
| Retaliate | false |
| Alert | false |

### 6.3 Enemy Phase 攻击顺序

- Player order
- 每位调查员 resolve **全部** engaged enemies 攻击（顺序由被攻击调查员选）
- **Massive**（已裁决 OQ-08-02）：
  - **发起攻击时**确定本 batch 的 **攻击效果序列**（对该 enemy engaged 的每位调查员各 1 次；顺序 Lead 选）
  - 序列 **尽量全部结算**；**batch 开始时锁定**，中途 **横置（exhaust）不影响** 后续每次攻击
  - **全部**攻击完成后才 exhaust Massive enemy

```gdscript
func resolve_massive_phase_attacks(enemy: EntityId) -> void:
    var targets := get_engaged_investigators(enemy)
    var order := ui.lead_investigator_choose_order(targets)
    var sequence := order.map(inv -> EnemyAttack.new(enemy, inv, AttackKind.PHASE, ..., exhaust_after=false))
    for attack in sequence:
        perform_attack(attack)   # 中途 enemy 被 exhaust 仍继续
    exhaust(enemy)               # batch 结束后统一 exhaust
```

### 6.4 Retaliate / Alert（触发 + 时点摘要）

- **Retaliate**：触发 = fail fight vs ready enemy；时点 = ST.7；效果 → `perform_attack(RETALIATE)`
- **Alert**：触发 = fail evade vs ready enemy；时点 = ST.7 之后；效果 → `perform_attack(ALERT)`；**不要求 engaged**，enemy 不在 threat area 仍 **deal damage**（已裁决 OQ-08-03）

### 6.5 Elusive

Ready elusive 在 **attack resolves 后**（含 fail）：disengage all → move to connecting（优先无 investigator）→ exhaust。

---

## 7. Spawn

> **规则来源**：Grimoire *Spawn*；FAQ *Spawning an Enemy*（draw vs location spawn）。

### 7.1 三种进场模式（术语）

| 模式 | 何时 | 行为 | 是否调用 `engage()` / auto engage |
|---|---|---|---|
| **`spawn_engaged(drawer)`** | Encounter draw，**无** `Spawn –` 文本，**非 Aloof** | `location := drawer.location`；`engaged_with := drawer`；进 **threat area** | **否** — 单 L0 原子 |
| **`spawn_at_location` + `auto_engage_at_location`** | 有 `Spawn –` 文本，或效果 spawn 到 location | 先进合法 location；若非 Aloof → 按 §3 Engagement 选调查员 engage | **是** — auto engage 子流程 |
| **`spawn_at_location`（Aloof）** | Aloof，任意 spawn 路径 | 进 location，**unengaged**，不进 threat area | **否** |

**Engage action**（[03 §6](03-action-system.md)）与上表 **无关** — 仅调查员花费 action 手动 engage。

### 7.2 算法（`EnemySystem.spawn_from_encounter_draw`）

```
1. Parse spawn instruction（或 ability override）
2. 若 instruction 为空（Framework 1.4 默认 draw）:
     if aloof:
       spawn_at_location(drawer.location)   # unengaged
     else:
       spawn_engaged(drawer)                # 原子；≠ auto engage
   else:
     loc := 选合法 location（drawer 选若多选）
     if 无法 spawn → discard_to_owner_pile(enemy)   # 不 enter play；见 §7.4
     spawn_at_location(loc)
     if not aloof:
       auto_engage_at_location(loc)         # Lead / Prey，见 §3
3. Massive / 其他关键词在 spawn 提交后由 register 同步
```

```gdscript
## L0 原子：无 Spawn 文本的 encounter draw（非 Aloof）
func spawn_engaged(enemy_id: StringName, drawer_id: StringName) -> void:
    var loc := drawer_location(drawer_id)
    place_in_play(enemy_id, loc)
    enemy.engaged_with = drawer_id
    add_to_threat_area(drawer_id, enemy_id)
    # 禁止 nest ActionSystem.engage 或 auto_engage_at_location
```

### 7.3 与 E5 的对应

遭遇抽牌 E5 → `seq.encounter.spawn` → 上表分支；见 [15 §17.4.1](15-timing-entry-catalog.md)。

### 7.4 Spawn 失败：弃置到 **对应弃牌堆**

Grimoire *Spawn*：若无合法 location spawn，**does not spawn, and is discarded instead**。

| Owner | 弃置目标 | 典型 |
|---|---|---|
| **encounter deck**（`owner_id = encounter`） | **encounter discard pile** | 遭遇牌库抽出的 enemy |
| **调查员 bearer**（weakness enemy） | 该调查员 **discard pile** | encounter cardtype weakness 等 |

```gdscript
## L0：按 CardInstance.owner_id 路由；不 enter play
func discard_spawn_failed(enemy_id: StringName) -> void:
    var owner := state.get_owner(enemy_id)
    if owner == &"encounter":
        mutator.discard_to_encounter_pile(enemy_id)
    else:
        mutator.discard_to_investigator_pile(enemy_id, owner)
    # 视为「已 draw / 已结算 spawn 尝试」；Surge、AFTER 等仍按 E5 完成后的规则继续
```

**要点**：

- **不是** removed from game；是 **owner 对应 discard pile**（与 defeat 路由一致，见 §8）。
- Revelation（E4）**已结算** 后若 spawn 失败，仍 discard — spawn 失败 **不** 回溯显现。
- `spawn_engaged` 路径下 drawer **无 location**（极端/setup 边界）→ v0 同 **`discard_spawn_failed`**（OQ-ENC-02）。

## 8. Defeat / Victory / Doomed

- Damage >= health → defeated → encounter discard（或 weakness owner discard）
- Victory X → victory display
- Doomed：defeat 时 place 1 doom on agenda（discard 不算 defeat）

---

## 9. EnemySystem API

```gdscript
class EnemySystem:
    func spawn_from_encounter_draw(enemy: EntityId, drawer: StringName) -> Result
    func spawn_engaged(enemy: EntityId, drawer: StringName) -> Result   # L0；无 auto engage
    func spawn_at_location(enemy: EntityId, location: EntityId) -> Result
    func auto_engage_at_location(enemy: EntityId, location: EntityId) -> Result
    func discard_spawn_failed(enemy: EntityId) -> Result   # §7.4；owner 路由 discard
    func spawn(enemy: EntityId, drawer: StringName, instruction: SpawnInstruction) -> Result  # 委托 §7.2
    func engage(enemy: EntityId, inv: StringName) -> Result             # Engage **action** 专用
    func disengage(enemy: EntityId) -> Result
    func hunter_patrol_move() -> void
    func resolve_phase_attacks() -> void
    func perform_attack(attack: EnemyAttack) -> void
    func check_retaliate(test: SkillTestContext) -> void   # 触发 + 时点；满足时调用 perform_attack
    func check_alert(test: SkillTestContext) -> void       # 触发 + 时点；满足时调用 perform_attack
    func check_elusive_after_attack(enemy: EntityId) -> void
```

---

## 10. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| EN-01 | Draw Servant of Flame | spawn engaged hunter |
| EN-02 | Aloof Abigail spawn | unengaged at location |
| EN-03 | Hunter move toward nearest | 1 step |
| EN-04 | Retaliate on fight fail | attack, no exhaust |
| EN-05 | Massive 2 investigators | 2 attacks then exhaust |
| EN-07 | Massive batch 第 1 击后 card exhaust enemy | 第 2 击仍 resolve |
| EN-06 | Elusive after AOO | flee + exhaust |
| EN-08 | Spawn 指向未进场 location | **encounter discard**；不 enter play |
| EN-09 | Weakness enemy spawn 失败 | **bearer discard pile** |

---

## 11. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-08-04 | P2 | Patrol 目标 location 不在 play — 不移动还是 discard？ |
| OQ-08-05 | P1 | Engage 抢怪：同时 disengage 原调查员是否触发「leaves engagement」类能力？ |
| OQ-08-06 | P2 | Enemy 与 investigator 同地点但 aloof + ready：Investigate 合法，Fight 不合法 — 确认？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-03-02 | **攻击效果层**统一 `EnemyAttack` + `AttackKind`；**触发条件与时点**各 kind 独立 Resolver。均属 enemy attack，共用 `perform_attack()`。见 §6.1。 | 2026-05-25 |
| OQ-08-02 | Massive 多次攻击 **batch 发起时锁定序列**，尽量全部结算；**中途横置不取消**后续攻击。见 §6.3。 | 2026-05-25 |
| OQ-08-03 | Alert 攻击 **不要求 engaged**；enemy 不在 threat area 仍 **deal damage**。见 §6.4。 | 2026-05-25 |
| OQ-08-01 | Hunter：**等距子集 → Prey 过滤 → Lead 选**。Prey 必须在等距内。见 §4。 | 2026-05-25 |

---

## 12. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-03-02 补充：触发 / 时点 / 攻击效果三层结构 |
| 2026-05-25 | v0.3 | OQ-08-02 裁决：Massive batch 锁定序列，中途 exhaust 不取消 |
| 2026-06-18 | v0.4 | §3/§7 **`spawn_engaged` vs `auto_engage_at_location` vs Engage action**；对齐 15 §17 E5 |
| 2026-06-18 | v0.4.1 | §7.4 spawn 失败 → **owner 对应 discard pile**；EN-08/09 |
