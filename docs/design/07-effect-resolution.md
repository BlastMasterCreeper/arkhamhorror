# 07 — 效果解析与修饰 (EffectResolutionGraph)

> **依赖**：[01-game-state-zones.md](01-game-state-zones.md), [06-ability-initiation.md](06-ability-initiation.md), **[07-effect-primitives.md](07-effect-primitives.md)（L0 原子）**, **[07-composition.md](07-composition.md)（效果组合）**  
> **规则来源**：Grimoire Dealing Damage/Horror, Effects, Target, Instead, Cancel, Modifiers

---

## 0. 与原子层 / 效果组合的关系

- **L0 原子**：`MoveCard` / `TransferMarker` / … — 见 [07-effect-primitives.md](07-effect-primitives.md)
- **效果组合 Composition**：L0/L1/L2 组合树 + dry-run — 见 [07-composition.md](07-composition.md)
- **Registration / Buff**：规则表 — 见 [06-registration-buff-model.md](06-registration-buff-model.md)

下文 `EffectOp`、`EffectRequest` 在实现上应 **编译为 CompositionTree**，而非与原子并列的第三套执行分支。

---

## 1. 目标

将所有游戏效果统一为 **EffectRequest DAG**，处理 Target、Cancel/Ignore/Instead、Then、For each、Damage 两步、Modifiers 重算。

---

## 2. EffectRequest 原语

```gdscript
enum EffectOp {
    DEAL_DAMAGE,
    DEAL_HORROR,
    DEAL_DIRECT_DAMAGE,
    DEAL_DIRECT_HORROR,
    HEAL,
    TRANSFER_AFFLICTION,       # Moving damage/horror；不算 heal（OQ-07-02）
    DISCOVER_CLUE,
    PLACE_CLUE,
    SPEND_CLUE,
    GAIN_RESOURCE,
    SPEND_RESOURCE,
    DRAW_CARDS,
    DISCARD_CARDS,
    MOVE_INVESTIGATOR,
    MOVE_ENEMY,
    SPAWN_ENEMY,
    ENGAGE,
    DISENGAGE,
    EVADE_AUTO,
    DEFEAT,
    EXHAUST,
    READY,
    ATTACH,
    ADVANCE_ACT,
    ADVANCE_AGENDA,
    PLACE_DOOM,
    REMOVE_DOOM,
    SEARCH_DECK,
    SHUFFLE,
    EXILE,
    CUSTOM,                    # CardScript 扩展
}

class EffectRequest:
    var op: EffectOp
    var source: EffectSource
    var controller: StringName
    var targets: Array[EntityId]
    var amount: int
    var options: Dictionary      # skill, location, filters, ...
    var then_chain: Array[EffectRequest]
    var is_optional: bool
    var replacement_id: StringName
```

卡牌脚本通过 `EffectBuilder` 构建，**禁止**直接改 `GameStateStore`。

```gdscript
EffectBuilder.deal_horror(1).to_investigator(id).from_source(src).submit(ctx)
EffectBuilder.discover_clue(1).at_location(loc).submit(ctx)
```

---

## 3. 解析管线

```gdscript
class EffectResolutionGraph:
    func submit(request: EffectRequest) -> EffectResult
    func submit_batch(requests: Array[EffectRequest], simultaneous: bool) -> Array[EffectResult]
```

### 3.1 单请求流程

```
1. Validate targets（Silver Rule 冲突标记）
2. 若本请求已被 Cancel（见 §6.1）→ abort（视为未发生）
3. 若 Replacement 已生效（见 §7.1）→ 执行替换后效果，跳过原 op
4. Check Cannot — 绝对拦截
5. Pay embedded costs（若有）
6. Execute op
7. Emit timing events（after/when）
8. Process then_chain（then 优先于 step 7 产生的 after）
```

**Cancel 与 Replacement 的先后**不在此线性步骤内硬编码，而在 **TimingBus 触发顺序** 中裁决（§6.1、§7.1）。

---

## 4. Deal Damage / Horror（两步）

Grimoire p.8：

### Step 1 Assign

- 确定 amount
- Investigator 可分配到 eligible assets（有 health/sanity）
- 不超过 asset 将 defeat 的量
- 剩余 → investigator 卡
- Direct：必须 investigator 卡

**Between 1 and 2**：prevent / reduce / reassign 能力

### Step 2 Apply

- 同时放置 tokens
- 若未 apply 任何 → 未 successfully dealt
- 检查 defeat：investigator / enemy / asset

```gdscript
class DamagePipeline:
    func deal(dealt: DamageDealt) -> void:
        var assignment := assign(dealt)      # 可插入 prevent
        apply(assignment)                     # 同时 apply
        check_defeat(assignment.affected)
```

### 4.1 Moving damage / horror（已裁决 OQ-07-02）

卡牌文本 **Move / Move 1 damage / Move 1 horror**（从 A 转移到 B）使用独立原语 **`EffectOp.TRANSFER_AFFLICTION`**，**不算 heal**。

| | `HEAL` | `TRANSFER_AFFLICTION` |
|---|---|---|
| 语义 | 移除 affliction（治疗） | 在实体间 **移动** 已有 token |
| 触发「After heal」等 | 是 | **否** |
| 走 DamagePipeline assign | 否 | 否（源减、目标加，原子操作） |
| defeat 检查 | 视 heal 规则 | 转移后双方检查 |

```gdscript
enum AfflictionKind { DAMAGE, HORROR }

class TransferAfflictionRequest:
    var from: EntityId
    var to: EntityId
    var kind: AfflictionKind
    var amount: int

func execute_transfer(req: TransferAfflictionRequest) -> void:
    remove_tokens(req.from, req.kind, req.amount)
    add_tokens(req.to, req.kind, req.amount)
    check_defeat([req.from, req.to])
    timing_bus.emit("affliction_transferred", req)   # 非 "healed"
```

```gdscript
EffectBuilder.transfer_damage(1).from(asset_a).to(asset_b).submit(ctx)
EffectBuilder.transfer_horror(1).from(inv).to(enemy).submit(ctx)
```

---

## 5. Target 规则

- 无 valid target → 效果 **fail to initiate**（整个 ability 不可启动）
- 多 target 同时选
- 「Any number」不可选 0
- 多效果 on 一 target：至少一个可改变 state 则 valid
- 「Each enemy」：至少一个 valid 即可 initiate，invalid 跳过

---

## 6. Cancel vs Ignore

| | Cancel | Ignore |
|---|---|---|
| Initiation | 打断，未发生 | 已 initiate |
| 后续反应 | 不可 react | 可 react to initiate |
| Chaos token | 视为未 draw | 已 draw，modifier/effect 不应用 |

Exile/remove from game **不可** ignore。

### 6.1 Cancel 与 Replacement 交互（已裁决 OQ-07-06）

**看两者触发先后**；Replacement 效果一般为 **Delayed 延时效果**，与 **Forced** 同优先级 tier（见 §10、`06 §5.1`）。

| 谁先触发 / 结算 | 结果 |
|---|---|
| **Replacement 先** | 原「可结算效果」已被替换；针对原效果的 **Cancel 无法发动**（无可取消的 pending resolution） |
| **Cancel 先** | 原效果视为未发生；**Replacement 不结算** — Replacement 替换的是「即将可结算的效果」，已被 Cancel 则无可替换对象 |

```gdscript
# TimingBus 在同一 timing 内：
# 1. Forced + Delayed（含 Replacement 注册的延时替换）按 06 §5.1 顺序 resolve
# 2. 玩家 🕭 Cancel 在对应 window 内 initiate
# 3. 以实际 resolve 先后为准，非 DAG 内固定 Cancel-before-Replacement

func on_pending_effect(pending: EffectRequest) -> void:
    # Replacement 作为 DelayedEffect 挂到 pending 的 resolve timing
    # Cancel 作为 Reaction 打断 pending 的 initiation / resolution
    pass
```

**引擎要点**：Cancel 绑定 **原始 pending effect 的 identity**；Replacement 先生效则该 identity 的 resolution 路径已改写 → Cancel 失效。Cancel 先生效则 pending 标记 `cancelled` → 后续 Replacement callback **fizzle**。

---

## 7. Instead / Would（Replacement）（已裁决 OQ-06-01）

- **Instead**：替换 resolution
- **Would**：更高优先级 when
- **冲突优先级**（非 LIFO / 非「最后注册」）：

| 优先级 | 来源 | 冲突处理 |
|---|---|---|
| **1（高）** | **Encounter 卡**（遭遇 / treachery / scenario 等） | 覆盖玩家卡 Replacement |
| **2** | **玩家卡**（investigator / player card） | — |
| **同优先级** | 多条同时适用 | **Lead Investigator** 选择哪条生效 |

```gdscript
enum ReplacementSourceTier { ENCOUNTER, PLAYER }

class ReplacementCandidate:
    var source_tier: ReplacementSourceTier
    var source_card: EntityId
    var replaces: EffectRequest
    var with_effect: EffectRequest

func resolve_replacement_conflict(candidates: Array[ReplacementCandidate]) -> ReplacementCandidate:
    var best_tier := candidates.map(c -> c.source_tier).min()  # ENCOUNTER < PLAYER
    var tier_matches := candidates.filter(c -> c.source_tier == best_tier)
    if tier_matches.size() == 1:
        return tier_matches[0]
    return ui.lead_investigator_choose(tier_matches)
```

应用时仍走 `ReplacementStack` 记录链，但 **选取哪条 Replacement 生效** 按上表，而非 push 顺序。

### 7.1 Replacement 与 Cancel（已裁决 OQ-07-06）

Replacement 能力通常实现为 **DelayedEffect**（到达指定 timing 时以 Forced 级优先级介入），与 Cancel 🕭 的交互见 **§6.1**：

- 非「Cancel 替换前还是替换后」的二选一，而是 **谁先在该 timing 实际 resolve**
- Replacement 先 → Cancel 不能发动
- Cancel 先 → Replacement 不结算（无可替换的可结算效果）

---

## 7.5 同时效果组（已裁决 OQ-01-02）

与 [01-game-state-zones.md §5.3](01-game-state-zones.md) 一致。

| 规则 | 引擎行为 |
|---|---|
| 「simultaneously / 同时」 | 同一 `TimingPoint` 内开始结算 |
| 「效果 A and 效果 B」 | A、B 归入同一 `SimultaneousEffectGroup` |
| `after` 触发 | **组 commit 完成后**才排队 |
| Unique 遭遇 vs 玩家同名 | 极少见；走同一机制，非专用分支 |

```gdscript
# EffectResolutionGraph 内
func resolve_group(effects: Array[EffectRequest]) -> void:
    var group := SimultaneousEffectGroup.new(current_timing)
    for e in effects:
        group.add(e)
    group.commit()  # 抑制组内 after；commit 后统一 flush after 队列
```

`submit_batch(..., simultaneous: true)` 应委托至 `SimultaneousEffectGroup`，与 For each 的 SIMULTANEOUS 模式区分：后者是**数值合并**，前者是**时点与 after 优先级**。

---

## 8. For Each 合并判定

Grimoire For each / For every：

| 可 simultaneous | 必须逐步 |
|---|---|
| 纯数值 horror（fail by X） | 每点选 lose action OR horror |
| 可一次算总量 | 含 choice / 多步依赖 |

```gdscript
func classify_for_each(template: EffectTemplate) -> ForEachMode:
    if template.has_player_choice_per_iter(): return SEQUENTIAL
    return SIMULTANEOUS
```

---

## 9. Modifiers 重算

Grimoire Modifiers p.16：

- 新 modifier 加入时 **从头重算**
- Additive/subtractive **先于** double/halve
- 分数向上取整
- 功能值不低于 0（excess negative 仍「存在」）

```gdscript
class ModifierEngine:
    func compute(base: int, mods: Array[Modifier]) -> int
    func compute_skill(inv: StringName, skill: SkillType, ctx: SkillTestContext) -> int
```

---

## 10. Lasting / Delayed

> **v0.2+**：统一为 [Registration + LifetimeSpec](06-registration-buff-model.md)。Lasting = `DURATION`；Delayed = `UNTIL_FIRED`；持续壳内 Listener 见该文档 §5。

```gdscript
class LastingEffect:
    var id: StringName
    var duration: DurationSpec      # until end of phase, for this skill test, ...
    var modifier: Modifier
    var affected_filter: Callable

class DelayedEffect:
    var timing: TimingPoint
    var effect: EffectRequest
    var kind: DelayedKind = GENERIC   # REPLACEMENT | GENERIC | ...
    var replaces_pending: EffectRequestId   # Replacement 专用：指向被替换的 pending 效果
    # 到达 timing 时以 Forced 同级优先级自动 resolve（OQ-07-06）
```

Lasting expires **before**「at end of phase」abilities（Grimoire Lasting Effects）。

---

## 11. 常见效果映射

| 卡牌文本模式 | EffectOp |
|---|---|
| draw 1 card | DRAW_CARDS amount=1 |
| gain 1 resource | GAIN_RESOURCE |
| discover 1 clue | DISCOVER_CLUE |
| place 1 doom on agenda | PLACE_DOOM target=agenda |
| heal 2 damage | HEAL type=damage |
| move 1 damage from X to Y | TRANSFER_AFFLICTION kind=damage |
| move 1 horror from X to Y | TRANSFER_AFFLICTION kind=horror |
| search top 5 | SEARCH_DECK |
| advance act | ADVANCE_ACT |

复杂分支 → `CUSTOM` + CardScript handler。

---

## 12. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| E-01 | 3 damage, Bodyguard soak 2 | 1 on investigator |
| E-02 | Direct horror 1 | 必须 investigator |
| E-03 | Cancel revelation | treachery 未 resolve |
| E-04 | Then draw then horror | horror before After draw |
| E-05 | For each fail by 3 horror | 一次 3 horror |
| E-06 | For each fail: lose action or horror | 3 次独立选择 |
| E-07 | Replacement 先于 Cancel resolve | Cancel 无法发动 |
| E-08 | Cancel 先于 Replacement resolve | Replacement fizzle |
| E-09 | Move 1 damage A→B | TRANSFER_AFFLICTION；不触发 After heal |

---

## 13. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-07-01 | P1 | 伤害分配 UI：何时必须玩家选 vs AI 默认（最保护 investigator？）？ |
| OQ-07-03 | P1 | Assign 阶段 prevent 部分 damage：剩余是否 re-assign 还是 fizzle？ |
| OQ-07-04 | P2 | Simultaneous discard 多张：owner 选顺序是否影响后续 search？ |
| OQ-07-05 | P1 | 「As much as possible resolve」— partial target invalid 时 DAG 如何剪枝？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-06-01 | Replacement 冲突：**Encounter 卡优先于玩家卡**；同优先级由 **Lead Investigator** 选择。见 §7。 | 2026-05-25 |
| OQ-07-06 | **看触发先后。** Replacement 一般为 Delayed，与 Forced 同优先级。Replacement 先 → Cancel 无法发动；Cancel 先 → Replacement 不结算（无可替换的可结算效果）。见 §6.1、§7.1。 | 2026-05-25 |
| OQ-07-02 | **是。** 独立 `EffectOp.TRANSFER_AFFLICTION`；**不算 heal**，不触发 heal 相关 🕭。见 §4.1。 | 2026-05-25 |

---

## 14. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-06-01 裁决：Replacement 优先级 Encounter > Player |
| 2026-05-25 | v0.3 | OQ-07-06 裁决：Cancel vs Replacement 看触发先后 |
| 2026-05-25 | v0.4 | OQ-07-02 裁决：TRANSFER_AFFLICTION 独立且不算 heal |
