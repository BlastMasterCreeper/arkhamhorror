# 15 — 规范时点入口 (Timing Entry Catalog)

> **依赖**：[06-ability-initiation.md](06-ability-initiation.md), [14-nested-sequences.md](14-nested-sequences.md), [06-registration-buff-model.md](06-registration-buff-model.md), [07-effect-primitives.md](07-effect-primitives.md)  
> **符号记法**：[ArkhamDB 标准](../reference/arkham-symbol-notation.md)  
> **状态**：v0.5 · 2026-06-18

---

## 1. 目标

为 Grimoire 的 **Would / When / After** 与卡牌能力订阅，提供 **唯一权威的 Timing Entry Catalog**。规则书行文可简略；**引擎以 catalog + Triggering Anchor Policy 为准**，不临时 `emit_timing` 字符串。

---

## 2. 核心概念

| 概念 | 含义 |
|---|---|
| **RuleSequence（规则序列 / 事件族）** | 规则定义的、由 **brick**（效果 / 信息 / 子序列 / 框架步）组成的序列模板；运行时 `push → … → pop` |
| **TimingEntry** | catalog 登记项：`(sequence_id, slot)` |
| **TimingOffer** | 运行时一次 emit：`entry + ApplicationContext` |
| **push / pop** | 嵌套栈压入 / 弹出；**pop 时** 发出 `AFTER`（遵守 merge 规则） |
| **Triggering Anchor** | 序列 **WHEN** 槽在 RESOLVE 内的 **规范时刻**（**不**由 zone 坐标推导） |

```gdscript
enum TimingSlot { WOULD, WHEN, AFTER }

class TimingSubscription:
    var sequence_id: StringName
    var slot: TimingSlot

class TimingOffer:
    var sequence_id: StringName
    var slot: TimingSlot
    var instance_id: StringName
    var app_ctx: ApplicationContext
```

**订阅键（Eligibility L0）** = `(sequence_id, slot)`。  
**情景、tags、framework_step** → `ApplicationContext` + Condition（L3），见 [06 §4.1](06-ability-initiation.md)、[06b §12](06-registration-buff-model.md)。

---

## 3. 三槽语义：Would / When / After

| Slot | 语义 | 与序列 / pop 的关系 |
|---|---|---|
| **WOULD** | 将要；PreImpact；序列 **未 push** 或 **信息未对控制者成立**（见 §6） | **不** bind pop |
| **WHEN** | 当…时；序列 **已 push**；**具体区间由 sequence 定义**（draw 为 D2–D3，§16） | **不** bind pop |
| **AFTER** | …之后；**本序列 RESOLVE + nest + AFTER 响应完毕**，**pop** | **bind pop** |

```text
[WOULD]  optional emit（PreImpact 前段；draw 见 §16）
push(sequence)
RESOLVE  bricks…
[WHEN]   open/close 区间因 sequence 而异（draw：D2 完成 → D3 完成，§16）
[AFTER]  AFTER 响应 → pop → emit
```

**After** 是唯一与 **序列完成（pop）** 强绑定的 slot。  
**Would / When** 的 **精确区间** 写在各 `RuleSequenceDef`；多数 action 可 ALIAS，**draw 必须 SPLIT**（§16）。

---

## 4. RuleSequence 与 Brick

### 4.1 Brick 种类

```gdscript
enum BrickKind {
    EFFECT,          # L0 原子 / Composition 落地（改 zone、伤害等）
    INFORMATION,     # 信息可见 / 控制者 confirm（改 InformationState，非 effect 施加）
    SUBSEQUENCE,     # 嵌套另一条 RuleSequence
    FRAMEWORK_STEP,  # 框架步（框架通道）
}
```

| Brick | 是否「效果施加」 | 典型 |
|---|---|---|
| **EFFECT** | 是 | MoveCard、DealDamage、move_transaction |
| **INFORMATION** | 否（牌面受众变更） | `FaceAudience` → CONTROLLER / ALL（见 [01 §3.6](01-game-state-zones.md)） |
| **ENTER_HAND** | 是（zone） | deck/limbo → hand；**带 Revelation 能力的玩家牌** 在入手时 nest（见 §16.2） |
| **SUBSEQUENCE** | — | fight 内嵌 skill_test、shuffle+horror |

### 4.2 RuleSequenceDef

```gdscript
class RuleSequenceDef:
    var id: StringName                    # seq.action.draw_cards
    var bricks: Array[SequenceBrick]
    var run_via: RunVia                   # SEQUENCE_STACK | FRAMEWORK_ENGINE | …
    var when_anchor: WhenAnchorPolicy     # §5
    var pre_impact: PreImpactSlotPolicy   # §6
    var after_merge: AfterMergePolicy     # §7
    var zone_semantics: String            # 文档：给人读的 zone 说明
```

---

## 5. Triggering Anchor Policy（引擎裁定）

**原则：触发时机 ≠ 区域坐标。**  
Grimoire 未定义 deck→hand、leave→enter 中间态时，**不**用 zone 推导 When；用 **Committed / Atomic 意图** 对齐桌游直觉，用 **单 brick 事务** 对齐严格实现。

### 5.1 全局 When 规则（默认）

> **多数行动序列：`WHEN` = push 之后、RESOLVE 内第一个 **EFFECT** brick 执行之前 emit 一次。**  
> **例外：`seq.draw.investigator` 使用 **WHEN 区间 D2–D3**（§16），非单点 emit。

### 5.2 政策表（v0）

| Policy | 适用 sequence | 含义 |
|---|---|---|
| **DRAW_WHEN_SPAN_D2_D3** | `seq.draw.investigator` | WHEN **窗口** = 控制者 **CONTROLLER**（D2 后）至 ENTER_HAND 完成（D3 后，含显现 nest） |
| **DRAW_WOULD_BEFORE_D2** | `seq.draw.investigator` | WOULD = instance 已 bind（D1 后）、**D2 信息 reveal 前** |
| **DRAW_ENCOUNTER_WOULD_BEFORE_E2** | `seq.draw.encounter` | WOULD = E1 bind 后、**E2 公开 reveal 前** |
| **DRAW_ENCOUNTER_WHEN_SPAN_E2_E5** | `seq.draw.encounter` | WHEN **窗口** = E2 后至 E5 类型落点完成（含 `seq.encounter.revelation` nest） |
| **ENCOUNTER_REVELATION_COMMITTED** | `seq.encounter.revelation` | 遭遇显现；**非** `seq.enter_hand`；Forced；`pre_impact=SPLIT` |
| **MOVE_INTENT_COMMITTED** | `seq.action.move` | from/to **已确定**；leave+enter **规则上同时**（一个 brick） |
| **FIGHT_COMMITTED** | `seq.action.fight` | Fight 行动 **开始 RESOLVE**；默认与内嵌 test 的 AFTER **merge**（§7） |
| **GAIN_COMMITTED** | `seq.gain_resource`（设计别名 `seq.action.gain_resource`） | 一次 gain 结算 commit（已实现竖切） |
| **REVEAL_COMMITTED** | `seq.encounter.reveal` | 遭遇显现；`pre_impact=SPLIT` |

### 5.3 Move 事务

**Move — `move_transaction`（一个 EFFECT brick）：**

```text
inv.location := to    # leave + enter 一次提交；不拆 leave/enter 两个 entry
```

**禁止**用 `card.zone == HAND` / `inv.location` 判断「是否算 draw/move 时」；draw 用 **CardFaceVisibility**（§16、[01 §3.6](01-game-state-zones.md)）。

---

## 6. Would 与 When：PreImpact 政策

| Policy | 含义 | 典型 sequence |
|---|---|---|
| **WHEN_ONLY** | 只登记 WHEN | 多数 action |
| **WOULD_AND_WHEN_ALIAS** | would/when **可互换**；编译映射同一 PreImpact；**无**结构分叉 | fight、gain、move（默认） |
| **WOULD_AND_WHEN_SPLIT** | would/when **不可互换**；有 **明确步骤分界** | **`seq.draw.investigator`**、**`seq.draw.encounter`**、encounter reveal |

**要点：**

- 大多数序列 **would/when 可 ALIAS**；差别是 **印刷 / 编译**。  
- **Cancel/Replace** 绑 **pending 生命周期**（`replaceable_until`），不绑 would/when 字面。  
- **Draw** 必须 SPLIT：WOULD / WHEN / AFTER 各有 **规范步骤区间**（§16）。

---

## 7. After 与嵌套 merge（Fight / ST.8）

**原则：一个 pop 一次 AFTER offer**（同帧 merge 除外）。

| 情况 | 行为 |
|---|---|
| 父序列 **仅含** 一个 SUBSEQUENCE brick，且 pop 子序列后 **无后续 brick** | **只 emit 父 AFTER**；子 AFTER **defer**（默认 Fight ≈ attack test） |
| 子序列 pop 后 **还有** post brick（如「本次 attack 后」追加效果） | **先 emit 子 AFTER**，父 pop 时再 emit 父 AFTER |
| 独立 Event 检定 | 仅 `seq.skill_test.*` 的 AFTER |

**Fight 与 ST.8：** 不是「哲学上两个入口」，而是 **bricks 是否延伸** 决定是否两个 pop、两个 AFTER。默认 **对齐 merge**；延伸 Fight 才分叉。

---

## 8. emit 唯一出口（TBD）

> **状态**：流程明细稳定后再建 **TimingCatalog** 索引表；本节仅保留接口形状。

```gdscript
class TimingCatalog:
    func emit(sequence_id: StringName, slot: TimingSlot, app_ctx: ApplicationContext) -> void
    # → EligibilityPipeline COLLECT (L0–L5)
    # → ResponseWindow
    # → Initiation L6–L7（若适用）
```

**Invariant（目标）**：旁路 `TimingBus.emit_timing("after_*")` 逐步废除；emit 只从 **已登记流程** 的边界发出。

---

## 9. Catalog 准入（TBD）

流程 `RuleSequenceDef` 定稿后再写准入四问与索引表。见 §17。

---

## 10. 与 Eligibility / ResponseWindow 的分工

| 层 | 职责 |
|---|---|
| **TimingCatalog.emit**（TBD） | L0 叫醒 |
| **EligibilityPipeline** | L1–L5 收集；L6–L7 Initiation（[06 §5](06-ability-initiation.md)） |
| **ResponseWindow** | `[reaction]` 选用、队长排序、关闭时点 — **不是关卡**（[06 §6](06-ability-initiation.md)） |

---

---

## 16. 调查员抽牌：`seq.draw.investigator`（规范流程）

> **定义**：将一张或多张牌从牌库顶经 **信息揭示** 移入手牌的过程（Grimoire **Drawing Cards**）。  
> **一次指令**（`amount` 张）= **一次** `sequences.run`；`amount ≥ 2` 且同一 ability/game step → **同时** reveal + 入手（非 N 次独立 push）。  
> **Draw 行动** = `amount = 1` 的特例（外壳见 [03-action-system §6.1](03-action-system.md)）。

### 16.1 牌面可见性（Domain）

见 **[01-game-state-zones §3.6](01-game-state-zones.md)**。抽牌使用 **FaceAudience**，与 zone **正交**。

| 步骤 | 对 **控制者** 的牌面 | 对 **其他调查员** |
|---|---|---|
| D0–D1 | HIDDEN_ALL | HIDDEN_ALL |
| **D2 后** | **CONTROLLER**（已知牌面） | HIDDEN_ALL（仍只见手牌/牌背或未知） |
| D3 后（在手牌） | CONTROLLER | HIDDEN_ALL |
| 效果「全体揭示牌库顶」 | ALL | ALL |

```gdscript
# INFORMATION brick（D2）示意
func reveal_to_controller(card_id, controller_id):
    card.face.audience = FaceAudience.CONTROLLER
    card.controller_id = controller_id  # 若尚未设置
```

**信息首次对控制者可见 = D2 结束**（INFORMATION brick）。**不是** D3 进 hand 时才首次可见。

### 16.2 步骤 D0–D5

```text
D0  抽牌意图成立（push 前 / push 瞬间）
    信息：HIDDEN_ALL（控制者亦不知牌面）
    区域：未动牌

D1  收集单张（循环 nest `seq.draw.collect_one`，直至 `amount` 或终止）
    · 牌库非空 → `pop_deck_top` → 写入 `RulesMemory.draw_pending`
    · 空库 → L1 `shuffle_and_horror`（`shuffle_discard_into_deck` + `HORROR_TAKEN`）→ 再 pop
    · 两堆皆空 → nest `seq.draw.empty_piles_defeated` → 本张 draw 终止
    信息：HIDDEN_ALL（控制者亦不知牌面）

D2  INFORMATION — `reveal_batch`（L1 Composition of `reveal_to_controller`）
    牌面：HIDDEN_ALL → **CONTROLLER**（控制者）  ★ D2 ★
    区域：仍可 deck / Limbo（实现）；触发不读 zone

D3  ENTER_HAND — `enter_hand_batch`（L1 Composition of `commit_enter_hand`）
    信息：CONTROLLER（控制者）；他人仍 HIDDEN_ALL
    区域：→ HAND（或卡定义 `enter_zone`，如 LIMBO）
    · **全部** pending 牌 D2 完成后 **批量** reveal；再 **批量** commit 入手
    · 入手后 `nest_batch seq.enter_hand`：对 **具备 Revelation 能力** 的牌逐张 nest timing `enter_hand`
      （Forced；**不是** D5 之后、**不是** 独立 D4 尾巴）
      · **Weakness ⊄ Revelation**：弱点不一定有显现；无显现则仅 timing 跳过
      · **Revelation ⊄ Weakness**：Dilemma 等玩家牌亦可有显现；同一 `seq.enter_hand` 规则

D5  pop → emit AFTER
    「After you draw」；含 D3 内各 Revelation nest 全部完成后
```

**无 D4。** **Revelation 结算**是 **D3 入手事务的一部分**（仅当该 instance 带 Revelation 能力），不是抽牌 pop 之后的附带步。

### 16.3 Would / When / After 的 **准确位置**

| Slot | 步骤区间 | 控制者牌面 | 说明 |
|---|---|---|---|
| **WOULD** | **D1 完成后 → D2 开始前** | HIDDEN_ALL | 「将要抽」；instance 可已 bind |
| **WHEN** | **D2 完成后 → D3 完成后** | **CONTROLLER** | 「抽牌时」= **D2–D3 整段**（含入手、Revelation nest） |
| **AFTER** | **D5 pop 后** | CONTROLLER，已在 hand | 各 Revelation nest 已返回 |

**WHEN 是区间，不是 D2 与 D3 之间的单点：**

```text
open TimingWindow(seq.draw.investigator, WHEN)   # D2 INFORMATION 完成
  … 可 refresh；D3 内 `seq.enter_hand` nest 显现 …
close TimingWindow                              # D3 ENTER_HAND + seq.enter_hand nest 完成
```

**「When you draw」** 能力在 **控制者已为 CONTROLLER 之后、draw 序列 pop 之前** 均可响应，**包括** 正在入手与 **显现结算期间**（仍在 D3 内）。

**「When you would draw」** → 订阅 **WOULD**（D2 前）。

### 16.4 Bricks 与 SequenceCatalog 映射

**原则**：规则步骤 = **SequenceCatalog 条目** + **L1 Composition 树**；不为每个 flow  proliferate Service。薄 facade（`DrawInvestigatorService`）仅 `catalog.run(flow_id, params)`。

```text
seq.draw.investigator          # RUN · catalog.register_run
  RESOLVE:
    init RulesMemory (draw_pending / draw_shuffles / draw_horror_taken)
    while pending.size < amount:
      nest seq.draw.collect_one     # 编排循环，非 L0 效果
    execute reveal_batch              # L1 · D2
    execute enter_hand_batch          # L1 · D3 物理落点
    nest_batch seq.enter_hand         # NEST_BATCH · D3 显现 timing

seq.draw.collect_one           # RUN · nest 于 collect 循环内
  RESOLVE:
    if deck empty:
      if discard empty → nest seq.draw.empty_piles_defeated → abort
      else execute shuffle_and_horror   # L1: shuffle_discard + HORROR_TAKEN
    execute pop_deck_top                # L0 → append draw_pending

seq.draw.empty_piles_defeated  # RUN · nest 于 collect_one 内
  RESOLVE:
    set_flag(ELIMINATED)

seq.enter_hand                 # NEST_BATCH · 所有「进入手牌」来源共用
  for card_id in card_ids (按顺序):
    if has_revelation(card_id):
      nest TriggeringCondition.enter_hand
      CardAbilityService.resolve_revelations → Composition
    if still LIMBO → finalize_limbo_discard
```

**Timing emit（目标，待 TimingCatalog）**：

```text
  WOULD  — after collect 绑定 instance、before D2 reveal_batch
  WHEN   — open after D2; close after nest_batch(seq.enter_hand)
  AFTER  — on seq.draw.investigator pop
```

```gdscript
# seq.enter_hand handler 示意（已实现）
func nest_enter_hand(game_ctx, params):
    for card_id in params.card_ids:
        if not abilities.has_revelation(game_ctx, card_id):
            continue
        game_ctx.sequences.nest(
            TriggeringCondition.enter_hand(controller_id, card_id, tags),
            func(): abilities.resolve_revelations(game_ctx, controller_id, card_id, provenance_flow_id)
        )
```

### 16.4.1 显现结算顺序（设计师待定 · 可配置占位）

**状态**：Grimoire / 设计师 **尚未最终裁定** `enter_hand` 时点多张牌、多条显现能力之间的 **同类内** 顺序。引擎 **不硬编码** 最终规则，通过 `RulesConfig.enter_hand_timing`（`EnterHandTimingPolicy`）集中配置。

**与 [06 §8](06-ability-initiation.md) 两层模型对齐**：

| 层 | enter_hand 语境 | v0 |
|---|---|---|
| **类别优先级** | 显现（Revelation）nest 属 **FORCED 类**；整类先于同窗口 TRIGGERED [reaction] | 引擎 tier；`revelation_forced_sub_tier` 占位 |
| **同类内顺序** | 多张牌 / 单卡多条显现单元 **均在 FORCED 类内** 的自排 | 默认 `SOURCE_ORDER` + Registry 登记序 |

| 维度 | v0 默认 | 预留（**仅同类内**） |
|---|---|---|
| **多张牌同时入手** | `SOURCE_ORDER`：按来源 `card_ids` 顺序 | `CONTROLLER_CHOICE`；`DEFINITION_PRIORITY` |
| **单卡多条 Revelation 单元** | `CardRegistry` 登记序 | `order_ability_units()` |
| **显现 vs 其他 enter_hand [reaction]** | **跨类**：FORCED 批整体先于 TRIGGERED | 非玩家自排；见 06 §8.1 |

```gdscript
# rules/config/enter_hand_timing_policy.gd
class EnterHandTimingPolicy:
    enum CardRevelationOrder { SOURCE_ORDER, CONTROLLER_CHOICE, DEFINITION_PRIORITY }
    var card_revelation_order = CardRevelationOrder.SOURCE_ORDER
    var revelation_forced_sub_tier: int = 100   # ForcedSubTier.REVELATION_FORCED

# RulesConfig
var enter_hand_timing: EnterHandTimingPolicy = EnterHandTimingPolicy.new()
```

**调用链**：`seq.enter_hand` → `order_cards_for_revelation()` → 逐张 nest → `order_ability_units()` → Composition execute。

**Open Question**：OQ-TIMING-05（见 [open-questions-master](../open-questions-master.md)）。

### 16.5 与遭遇抽牌、Weakness 分流

| | `seq.draw.investigator` | `seq.draw.encounter`（§17） |
|---|---|---|
| 来源 | 调查员 deck | encounter deck（或 weakness 重定向，§17.6） |
| 牌面默认 | D2 → **CONTROLLER** | E2 → **ALL**（Hidden 例外，§17.2） |
| Revelation | **D3** 经 `nest_batch seq.enter_hand` | E4 经 **`seq.encounter.revelation`** |
| 空库 | 洗弃 + 1 horror | 洗遭遇弃牌堆，**无 horror** |
| Surge | — | E6 同帧内回到 E1 |
| WHEN 区间 | D2–D3（本节） | E2–E5（§17.3） |

**Weakness（卡子类型）** 与 **Revelation（能力类型）** 正交（Grimoire Glossary 分列）。  
**Weakness 按 cardtype 分流**（Grimoire *Weakness*）：**仅 encounter cardtype**（enemy / treachery）走遭遇管线；**player cardtype**（asset / event / skill 等）走调查员 draw + 入手。

| Weakness cardtype | 从调查员 deck 抽出时 | Revelation | 入手后 |
|---|---|---|---|
| **Enemy / Treachery**（遭遇型） | **重定向** §17.6 → `resolve_bound`；**非** D2–D3 | E4 `seq.encounter.revelation` | enemy spawn / treachery discard 等（§17 E5） |
| **Asset**（支援型弱点） | **本节** D2–D3 | 若有 → D3 `seq.enter_hand` | 作 **asset** 使用（play 进 play area / 槽位） |
| **Event**（事件型弱点） | **本节** D2–D3 | 若有 → D3 `seq.enter_hand` | 作 **event** 从 hand play |
| **Skill**（技能型弱点） | **本节** D2–D3 | 若有 → D3 `seq.enter_hand` | 作 **skill** commit 至检定（**不能** play） |
| **任意 player 型，无 Revelation** | D2–D3 仅 zone→hand | 无 nest | 留在 hand；**不可** 主动 discard（除非卡牌另说） |

| 情况（非 weakness 维度） | 行为 |
|---|---|
| 玩家牌 **有 Revelation**（含 Dilemma 等非 weakness） | D3 `nest_batch seq.enter_hand` |
| 玩家牌 **无 Revelation** | D3 仅 zone→hand |

> 详表与 `CardDefinition` 判定：[11 §10](11-investigator-campaign.md)、[15 §17.6](15-timing-entry-catalog.md)。

### 16.6 实现状态（Domain 竖切）

| 已有 | 待建 |
|---|---|
| `CardFaceVisibility` + `FaceAudience`（[01 §3.6](01-game-state-zones.md)） | `TimingCatalog` / WOULD·WHEN 区间 emit（TIM-01～04） |
| L0：`pop_deck_top`、`shuffle_discard_into_deck`、`commit_enter_hand`、`reveal_to_controller` | `seq.draw.encounter` |
| L1：`DrawInvestigatorComposition`（`shuffle_and_horror`、`reveal_batch`、`enter_hand_batch`） | 设计别名 `seq.action.gain_resource` → 代码 `seq.gain_resource` 对齐（可选） |
| `SequenceCatalog`：`seq.draw.investigator`、`seq.draw.collect_one`、`seq.draw.empty_piles_defeated`、`seq.enter_hand`、`seq.gain_resource` | `TimingCatalog` 索引表（§17） |
| `DrawInvestigatorFlow` + `DrawSubflowHandlers`；`DrawInvestigatorService` → `catalog.run` | D1 per-card instance bind（当前以 `card_id` + pending 列表） |
| `CardRegistry.register_revelation` → Composition；ENT-01～03 测试 | encounter draw 共用 `seq.enter_hand` |
| `StateMutator.execute_draw_instruction` dry-run 回退（`run_mutator_only`） | |

**测试**：VIS-01/02、ACT-13～15、DRAW-02/03、ENT-01～03 已通过；TIM-01～04 待 TimingCatalog 后补测。

---

## 17. 遭遇抽牌：`seq.draw.encounter`（规范流程）

> **定义**：将一张或多张牌从 **遭遇牌库顶** 抽出，并按 Grimoire **Framework 1.4** / **Drawing encounter cards** 逐步结算的过程。  
> **一次指令**（`amount` 张）= **一次** `sequences.run`；每张牌 **完整** 走 E1–E6（含 Surge 链）后再抽批量中的下一张。  
> **Mythos 1.4** = `drawer_id` + `amount = 1` 的特例；Surge **不**另 push 外层序列。

> **依赖**：[10-scenario-encounter.md §2](10-scenario-encounter.md)、[04-skill-test-engine.md §4.1](04-skill-test-engine.md)（Peril 帧）、[08-enemy-engagement.md](08-enemy-engagement.md)（Spawn）。

### 17.1 牌面可见性（Domain）

遭遇牌 **默认公开**；与调查员抽牌（D2→CONTROLLER）不同。

| 步骤 | 对 **全体调查员** | 对 **drawer** | 说明 |
|---|---|---|---|
| E0–E1 | HIDDEN_ALL | HIDDEN_ALL | 尚未 bind 具体牌 |
| **E2 后（默认）** | **ALL** | **ALL** | 遭遇 draw 后全体见牌面 |
| **Hidden 关键词** | HIDDEN_ALL | CONTROLLER | 显现 **秘密** 入手；E2 **跳过** 公开 reveal |
| E5 后 enemy 在场 | ALL（公开 enemy） | — | zone 迁移；audience 随进场策略 |

```gdscript
# INFORMATION brick（E2 默认）示意
func reveal_encounter_drawn(card_id: StringName) -> void:
    card.face.audience = FaceAudience.ALL
```

**Hidden** 由卡定义/register 在 E4 分支处理，**不**在 E2 对全体 `ALL`。

### 17.2 步骤 E0–E7

```text
E0  遭遇抽牌意图成立（push / run 前）
    drawer_id 已知；EncounterResolutionFrame 将创建
    信息：HIDDEN_ALL

E1  收集单张（Surge 循环或批量中的每一张）
    · pop_encounter_deck_top → RulesMemory.encounter_pending（frame 级 referent）
    · 空库 → shuffle_encounter_discard_into_deck（**无 horror**）
    · 两堆皆空 → RULES_GAP（遭遇无「 defeated」等价；见 OQ-ENC-01）
    信息：HIDDEN_ALL（控制者亦不知，除非已从 deck 外 bind）

E2  INFORMATION — reveal_encounter（默认 ALL）
    牌面：HIDDEN_ALL → **ALL**（默认）  ★ E2 ★
    区域：仍为 deck / Limbo；**不**读 zone 判触发
    Hidden 卡：跳过本步公开 reveal

E3  PERIL — check_peril(frame)
    若 drawn 卡带 peril → frame.peril = true（**粘性**至 frame pop）
    激活 **Register RESTRICTION**（`EncounterPeril.apply_e3_check`，[04 §4](04-skill-test-engine.md)）；**非** Eligibility 软过滤
    覆盖本 frame 内 Surge 链与嵌套检定

E4  REVELATION — nest seq.encounter.revelation
    · **Forced**；**非** seq.enter_hand
    · encounter 卡 Forced **先于** player 卡（Grimoire Simultaneous Priority）
    · 可嵌 skill test；仍在 peril frame 内
    · Hidden：显现秘密加 hand；audience drawer=CONTROLLER，他人 HIDDEN_ALL

E5  TYPE_DISPATCH — nest seq.encounter.dispatch
    · **enemy** → nest seq.encounter.spawn（见 §17.4.1）
      · **无 Spawn 文本**（非 Aloof）→ **`spawn_engaged(drawer)`** 原子进场
      · **有 Spawn 文本** → spawn_at_location → **auto_engage_at_location**（除非 Aloof）
      · **Aloof**（含无 Spawn draw）→ spawn_at_location(drawer.location)，unengaged
      · **无合法 location** → **`discard_spawn_failed`** → owner 对应弃牌堆（08 §7.4）
    · **treachery** → encounter discard（除非能力留 threat / in play）
    · **story asset** 等 → 按 CardDefinition 默认落点

E6  SURGE_CHECK
    · surge → **同一 EncounterResolutionFrame** 内回到 **E1**（不 pop 外层）
    · 否 → 若批量 `amount` 仍有下一张 → E1；否则 E7

E7  pop frame → emit AFTER
    「After you draw an encounter card」= **本张** E1–E5 完成后、**Surge 下一圈 E1 之前**
    Grimoire *Then* 优先于本 AFTER（见 14 §2、Grimoire Then）
```

**无 enter_hand。** 玩家牌显现仍仅经 `seq.enter_hand`（§16）；遭遇显现 **永不** 复用该 nest。

### 17.3 Would / When / After 的 **准确位置**

| Slot | 步骤区间 | 牌面（默认） | 说明 |
|---|---|---|---|
| **WOULD** | **E1 bind 后 → E2 开始前** | HIDDEN_ALL | 「将要遭遇抽」 |
| **WHEN** | **E2 完成后 → E5 完成后** | **ALL** | 「遭遇抽牌时」= E2–E5（含 revelation nest、spawn/discard） |
| **AFTER** | **本张 E5 后、Surge 下一圈 E1 前** | ALL 或已落场 | Surge **不**延长本张 AFTER |

**Surge 链**：每一圈 E1–E5 各自 **独立** WHEN 窗口；外层 `seq.draw.encounter` 的 AFTER 在 **全部** Surge + 批量抽完后 E7 pop。

```text
open TimingWindow(seq.draw.encounter, WHEN)   # E2 reveal 完成
  … seq.encounter.revelation nest …
  … seq.encounter.dispatch …
close TimingWindow                              # E5 完成
emit AFTER (per card, before Surge E1)
```

**「When you would draw an encounter card」** → 订阅 **WOULD**（E2 前）。

### 17.4 Bricks 与 SequenceCatalog 映射

**原则**：与 §16 相同 — 步骤 = **Catalog 条目** + **L1 Composition**；**EncounterResolutionFrame** 跨 Surge 圈持有 `peril` / `drawer_id`。

```text
seq.draw.encounter                 # RUN · catalog.register_run
  RESOLVE:
    push EncounterResolutionFrame(drawer_id)     # RulesMemory frame stack
    init RulesMemory (encounter_pending, shuffles, cards_resolved)
    for i in amount:
      loop:                         # Surge loop（单张内）
        nest seq.draw.encounter.collect_one      # E1（或 resolve_bound skip）
        nest seq.draw.encounter.resolve_card     # E2–E6 共享子 flow
        if surge(card): continue loop
        else: break loop
      append cards_resolved
    pop frame → AFTER

seq.draw.encounter.resolve_card    # RUN · nest；单张 E2–E6（§17.10）
  params: drawer_id, card_id（默认 encounter_pending）
  RESOLVE:
    execute reveal_encounter（Hidden → skip ALL，§17.4.3）
    nest seq.encounter.check_peril               # E3
    nest seq.encounter.revelation                # E4
    nest seq.encounter.dispatch                  # E5

seq.draw.encounter.resolve_bound   # RUN · nest；weakness / as-if-drawn
  params: drawer_id, card_id, skip_collect=true
  RESOLVE:
    bind card_id → encounter_pending（无 E1 pop）
    nest seq.draw.encounter.resolve_card         # 同上 E2–E6

seq.draw.encounter.collect_one     # RUN · nest 于 E1
  RESOLVE:
    if encounter_deck empty:
      if encounter_discard empty → RULES_GAP（OQ-ENC-01）
      else execute shuffle_encounter_discard     # L1 · 无 horror（§17.13）
    execute pop_encounter_deck_top               # L0 → encounter_pending

seq.encounter.revelation           # NEST · E4
  CardAbilityService.resolve_encounter_revelations
  → Composition（Forced；flow_id = seq.encounter.revelation）

seq.encounter.check_peril          # NEST · E3
  EncounterPeril.apply_e3_check(game_ctx, frame, has_peril_keyword)
  # 见 [04 §4.11](04-skill-test-engine.md)

seq.encounter.dispatch             # NEST · E5（§17.4.2 / §17.4.3）
  branch cardtype → spawn | treachery_discard | hidden_hand | put_into_play

seq.encounter.spawn                # NEST · E5 enemy
  EnemySystem.spawn_from_encounter_draw(card_id, drawer_id)
  # 见 §17.4.1
```

### 17.4.1 E5 Enemy：`spawn_engaged` vs `auto_engage_at_location`

Grimoire / FAQ *Spawning an Enemy*：investigator **draw** 时若无 `Spawn –`，敌人 **spawns engaged with drawer**（**unless Aloof**）。这是 **进场态** 一次写入，**不是** Engage 行动，也 **不是** 「先进 location 再 auto engage」。

| 条件 | 引擎路径 | Domain 结果 |
|---|---|---|
| 无 Spawn，非 Aloof | **`spawn_engaged(drawer)`** | `engaged_with = drawer`；threat area；location = drawer.location |
| 无 Spawn，**Aloof** | **`spawn_at_location`** | drawer.location；**unengaged**；不进 threat area |
| 有 Spawn 文本，非 Aloof | spawn_at_location → **`auto_engage_at_location`** | 同地点多人 → Lead / Prey（[08 §3](08-enemy-engagement.md)） |
| 有 Spawn 文本，Aloof | spawn_at_location only | unengaged at location |
| **无合法 spawn location** | **`discard_spawn_failed`** | **owner 对应 discard pile**；不 enter play（[08 §7.4](08-enemy-engagement.md)） |

```gdscript
func spawn_from_encounter_draw(enemy_id: StringName, drawer_id: StringName) -> void:
    var instruction := card.spawn_instruction(enemy_id)
    if instruction.is_empty():
        var loc := drawer_location(drawer_id)
        if loc == null:
            discard_spawn_failed(enemy_id)
            return
        if card.aloof(enemy_id):
            spawn_at_location(enemy_id, loc)
        else:
            spawn_engaged(enemy_id, drawer_id)   # 禁止调用 engage() / auto_engage
    else:
        var loc := resolve_spawn_location(instruction, drawer_id)
        if loc == null:
            discard_spawn_failed(enemy_id)
            return
        spawn_at_location(enemy_id, loc)
        if not card.aloof(enemy_id):
            auto_engage_at_location(enemy_id, loc)
```

**Invariant**：`spawn_engaged` **不得** nest `ActionSystem.engage` 或 `auto_engage_at_location` — drawer 已由规则唯一确定。

### 17.4.2 E5 Treachery 与非 Enemy 落点

Grimoire Framework 1.4 Step 4：**treachery → encounter discard pile**，除非能力另有指示。

| 分支 | 条件 | E5 行为 | 弃牌堆 |
|---|---|---|---|
| **默认 treachery** | E4 后 zone **非** hand | `discard_to_encounter_pile` | encounter discard |
| **留场 / threat** | Revelation 或 constant 将牌 put into play / threat | 按 Composition 已写入的 zone | — |
| **Hidden 已在 hand** | E4 秘密入手（§17.4.3） | **跳过** 默认 discard | — |
| **spawn 失败 enemy** | 无合法 location | `discard_spawn_failed` | **owner** 堆（08 §7.4） |
| **story asset** | CardDefinition | 默认 play area 或 scenario 脚本 | owner / encounter 视定义 |

```gdscript
func dispatch_treachery(card_id: StringName, drawer_id: StringName) -> void:
    if card.is_hidden and card.zone == Zone.HAND:
        return   # Hidden 已在手；E4 已处理
    if card.zone == Zone.IN_PLAY or card.in_threat_area:
        return   # 能力已留场
    mutator.discard_to_encounter_pile(card_id)
```

**Cancel treachery 效果**：Grimoire — 仍视为 **已 draw**；仍进 encounter discard（能力取消 **不** 取消「已抽」事实）。E5 在 cancel 解析完成后执行 discard，除非 cancel 文本明确改落点。

### 17.4.3 Hidden 关键词分支

Grimoire *Hidden*：Revelation **秘密** 加 hand；不向其他调查员公开牌面或文本。

| 步骤 | 与默认 encounter draw 的差异 |
|---|---|
| **E2** | **跳过** `reveal_encounter`（ALL）；保持 HIDDEN_ALL（他人）/ drawer 在 E4 后 CONTROLLER |
| **E3 Peril** | 照常；若 drawn 卡 peril，仍 `frame.peril = true` |
| **E4** | Revelation Composition：`commit_enter_hand` + `is_hidden=true` + `audience=CONTROLLER`（drawer） |
| **E5** | treachery 默认 discard **不执行**（牌在 hand）；enemy 罕见，按 CardDefinition |

```gdscript
func reveal_encounter_step(card_id: StringName, drawer_id: StringName) -> void:
    if card.has_keyword(&"hidden"):
        return
    executor.execute(DrawEncounterComposition.reveal_to_all(card_id))
```

**Domain 不变量**：Hidden 在 hand 期间 **视为** threat area（规则语义）；`CardInstance.is_hidden` + Eligibility 过滤；discard 时 → **encounter discard pile**（Grimoire Hidden 第二条 bullet）。

### 17.4.4 Surge 与 Then / AFTER 边界（规范）

```text
单张牌生命周期:
  E1 bind → [WOULD] → E2 → open WHEN → E3–E5 → close WHEN
  → emit AFTER(card)     # 「After you draw an encounter card」
  → E6 surge? → 下一圈 E1（同一 frame）

效果文本: 「Draw encounter. Then, X」
  → E5 完成 → Then X → 然后 AFTER(card) 能力可 initiate（Grimoire Then 优先）
```

Surge **不**合并多张牌的 AFTER；每张 **独立** AFTER，均在下一 Surge E1 之前。

**Timing emit（目标，待 TimingCatalog）**：

```text
  WOULD  — after E1 bind、before E2 reveal_encounter
  WHEN   — open after E2; close after seq.encounter.dispatch
  AFTER  — per resolved card, after E5, before Surge next E1
  OUTER AFTER — on seq.draw.encounter pop (E7)
```

**与调查员 draw 子 flow 对照**：

| 调查员 | 遭遇 |
|---|---|
| `seq.draw.collect_one` | `seq.draw.encounter.collect_one` |
| `shuffle_and_horror` | `shuffle_encounter_discard`（仅洗，无 marker） |
| `reveal_batch` → CONTROLLER | `reveal_encounter` → ALL |
| `enter_hand_batch` + `seq.enter_hand` | `seq.encounter.revelation` + `dispatch` |
| `empty_piles_defeated` | （无）两堆空 → RULES_GAP |

### 17.5 EncounterResolutionFrame

```gdscript
class EncounterResolutionFrame:
    var drawer_id: StringName
    var peril: bool = false              # E3 置位后粘性至 pop
    var cards_resolved: Array[StringName]
    var surge_depth: int = 0             # 诊断 / UI

# RulesMemory referents（frame 级，key = drawer_id 或 frame_id）
const ENCOUNTER_PENDING := &"encounter_pending"
const ENCOUNTER_SHUFFLES := &"encounter_shuffles"
```

**Peril** = E3 **Register** 三条 `RESTRICTION`；L4 / Action / SkillTest / EffectGraph 统一 **`RestrictionEvaluator`**（[04 §4](04-skill-test-engine.md)）。`ApplicationContext.tags` 可含 `peril_active` 供 Condition，**不**替代 L4。

**嵌套检定**：revelation 内 skill test 走 `seq.skill_test.*` nest；ST.8 后入队仍属 **同一 frame**（OQ-04-02 已裁决）。

### 17.6 Weakness 与跨管线重定向

> **Grimoire**：*Weaknesses are resolved differently depending upon their **cardtype**.*  
> **Encounter cardtype**（enemy / treachery weakness）≈ 遭遇抽牌；**Player cardtype**（asset / event / skill weakness）≈ 调查员抽牌 + 入手。

#### 17.6.1 路由判定（引擎）

**第一键 = `CardDefinition.cardtype`**，**第二键 = `is_weakness` 子类型**；**不**用 weakness 子类型 alone 推断管线。

```gdscript
enum WeaknessRoute { INVESTIGATOR_DRAW, ENCOUNTER_DRAW, AS_IF_ENCOUNTER }

func weakness_route(def: CardDefinition) -> WeaknessRoute:
    if not def.is_weakness:
        return INVESTIGATOR_DRAW   # 非 weakness；普通玩家牌
    match def.cardtype:
        AhcEnums.CardType.ENEMY, AhcEnums.CardType.TREACHERY:
            return ENCOUNTER_DRAW
        AhcEnums.CardType.ASSET, AhcEnums.CardType.EVENT, AhcEnums.CardType.SKILL:
            return INVESTIGATOR_DRAW
        _:
            return INVESTIGATOR_DRAW   # 其它 player 印刷类型；默认调查员线
```

| cardtype | 典型印刷 | 管线 | 牌面 reveal（从 deck 抽） |
|---|---|---|---|
| **ENEMY** weakness | 弱点敌人 | `resolve_bound` → E2–E6 | E2 **ALL**（遭遇规则） |
| **TREACHERY** weakness | 弱点诡计 | 同上 | E2 ALL 或 Hidden 分支 |
| **ASSET** weakness | 诅咒资产、故事弱点资产 | D2–D3 + `seq.enter_hand` | D2 **CONTROLLER** |
| **EVENT** weakness | 事件型弱点 | D2–D3 + `seq.enter_hand` | D2 CONTROLLER |
| **SKILL** weakness | 技能型弱点 | D2–D3 + `seq.enter_hand` | D2 CONTROLLER |

**Player cardtype weakness** 入手后按 **该 cardtype** 正常打牌（Grimoire：*used as any other player card of its cardtype*）；**不**进 encounter discard（除非 defeat 等另定规则）。

#### 17.6.2 来源与入口

| 来源 | 路由 |
|---|---|
| Mythos 1.4 / 效果「draw encounter」 | 正常 `seq.draw.encounter` |
| 调查员 deck **collect_one** + **encounter cardtype** weakness | **重定向** `resolve_bound`；skip E1；abort 调查员 D2 |
| 调查员 deck **collect_one** + **player cardtype** weakness | **不**重定向；完整 D2–D3 + `seq.enter_hand`（若有 Revelation） |
| Weakness **非 draw** 入手（search/add 等） | player 型：`seq.enter_hand` / as-if-drawn 调查员线；encounter 型：`resolve_bound`（Grimoire as if drawn from encounter deck） |
| Setup mulligan 抽到 weakness | set aside redraw；**不** resolve（[11 §6](11-investigator-campaign.md)） |

```text
seq.draw.investigator / collect_one:
  card_id := pop_deck_top(...)
  match weakness_route(card.definition):
    ENCOUNTER_DRAW:
      nest seq.draw.encounter.resolve_bound
        { drawer_id: inv_id, card_id, skip_collect: true }
      return   # 本张 **不** 进入 draw_pending / D2 reveal_batch
    INVESTIGATOR_DRAW:
      append draw_pending; continue  # 含 asset/event/skill weakness
```

`resolve_bound` → **`nest seq.draw.encounter.resolve_card`**（§17.4）；与主循环 **同一** E2–E6 实现。

#### 17.6.3 Owner 与弃牌堆（spawn 失败 / defeat）

| Weakness cardtype | `owner_id` | spawn 失败 discard | defeat 默认 |
|---|---|---|---|
| Encounter 型 | **bearer** 调查员 | bearer **discard**（08 §7.4） | owner discard 或 encounter discard 视 defeat 规则 |
| Player 型 | bearer | 不适用（无 spawn） | owner discard |

---

### 17.7 与 ScenarioSystem / Framework 的边界

| 调用方 | 入口 |
|---|---|
| Mythos 1.4（每位调查员） | `ScenarioSystem.resolve_encounter_draw(inv)` → `catalog.run(seq.draw.encounter, {drawer_id, amount: 1})` |
| 卡牌效果「draw N encounter cards」 | 同上，`amount = N` |
| Setup 14 game begins | 仅结算 **deferred** 显现；Setup 1–13 **不**进入本管线（OQ-10-01） |
| Act/Agenda b 面 encounter | 按 encounter cardtype 规则；可 nest 同一 `seq.encounter.*` 子 flow |

`ScenarioSystem` **不** proliferate 逐步逻辑；只做 framework 步进与 `catalog.run` 委托（对齐 [10 §2](10-scenario-encounter.md)）。

### 17.8 DrawEncounterComposition（L0 / L1）

与 [§16.4 `DrawInvestigatorComposition`](15-timing-entry-catalog.md) 对称；**不** proliferate Service。

| Brick | 层级 | 说明 |
|---|---|---|
| `pop_encounter_deck_top` | L0 | deck → limbo/pending；append `encounter_pending` |
| `shuffle_encounter_discard_into_deck` | L0 | 遭遇弃牌堆洗回牌库 |
| `shuffle_encounter_discard` | L1 Seq | 仅洗弃，**无** horror marker |
| `reveal_to_all` | L0 INFORMATION | `FaceAudience.ALL` |
| `discard_to_encounter_pile` | L0 | treachery 默认 E5 |
| `discard_spawn_failed` | L0 | owner 路由（委托 08 §7.4） |

```gdscript
class_name DrawEncounterComposition
extends RefCounted

const PENDING_KEY := &"encounter_pending"
const SHUFFLES_KEY := &"encounter_shuffles"
const RESOLVED_KEY := &"encounter_cards_resolved"

static func shuffle_encounter_discard() -> CompositionNode:
    return CompositionNode.shuffle_encounter_discard_into_deck()

static func reveal_to_all(card_id: StringName) -> CompositionNode:
    return CompositionNode.reveal_to_all(card_id)   # 待增 L0 factory

static func discard_treachery_default(card_id: StringName) -> CompositionNode:
    return CompositionNode.move_card(card_id, CardSlot.encounter_discard_top())
```

**RulesMemory**（frame 作用域，key 建议 `frame_id` 或 `drawer_id + frame_generation`）：

| Referent | 用途 |
|---|---|
| `encounter_pending` | 当前 E2–E6 处理的 `card_id` |
| `encounter_shuffles` | 本 frame 内洗弃次数 |
| `encounter_cards_resolved` | 已完成 E5 的 card_id 列表（含 Surge 链） |
| `encounter_frame_id` | 栈顶 frame 关联 |

### 17.9 DrawEncounterFlow 与 Facade

```gdscript
class_name DrawEncounterFlow
extends RefCounted

## 与 DrawInvestigatorFlow 对称；catalog 子 flow 收集 + Composition 批量 E2。
static func run(game_ctx: GameContext, drawer_id: StringName, amount: int) -> Dictionary

class_name DrawEncounterService
extends RefCounted
## 薄 facade → catalog.run(&"seq.draw.encounter", …)

func draw_encounter_cards(
    game_ctx: GameContext,
    drawer_id: StringName,
    amount: int,
    source_tags: Array[StringName] = []
) -> Dictionary
```

**返回形状**（与调查员 draw 对齐，便于测试 harness）：

```gdscript
{
    "ok": true,
    "drawn": Array[StringName],      # 本 run 全部 resolved card（含 Surge）
    "drew": bool,
    "shuffled": bool,
    "shuffles": int,
    "surge_depth_max": int,
    "peril": bool,                   # frame 最终 peril 粘性
    "spawn_failed_discards": Array[StringName],
    "revelations": Array[StringName], # 有 encounter revelation 的 card_id
}
```

`DrawEncounterSubflowHandlers`：`resolve_collect_one` / `resolve_resolve_bound` — 对标 `DrawSubflowHandlers`。

### 17.10 TriggeringCondition 与 ApplicationContext tags

```gdscript
static func draw_encounter(
    drawer_id: StringName,
    amount: int,
    source_tags: Array[StringName] = [],
    after_timing: StringName = &"after_draw_encounter"
) -> TriggeringCondition
# kind = &"draw_encounter"; controller_id = drawer_id; payload = {amount}

static func draw_encounter_collect_one(drawer_id: StringName) -> TriggeringCondition
# tags: [&"draw_encounter", &"draw_collect"]

static func encounter_revelation(
    drawer_id: StringName,
    card_id: StringName
) -> TriggeringCondition
# kind = &"encounter_revelation"; nest 于 E4

static func draw_encounter_resolve_bound(
    drawer_id: StringName,
    card_id: StringName
) -> TriggeringCondition
# weakness 重定向；tags 含 &"weakness_encounter"
```

**ApplicationContext.tags**（frame 注入，供 Peril / Eligibility）：

| Tag | 何时 |
|---|---|
| `draw_encounter` | 整个 `seq.draw.encounter` frame |
| `peril_active` | `frame.peril == true` |
| `encounter_drawer:{id}` | drawer 身份 |
| `surge_chain` | Surge 循环内（可选，诊断） |

### 17.11 空库洗弃与 mid-ability shuffle（OQ-10-04）

| 场景 | v0 政策 |
|---|---|
| **E1 collect_one**，牌库空、弃牌堆非空 | **立即** `shuffle_encounter_discard` 再 pop（Framework 1.4 常规 draw） |
| **Revelation / 嵌套效果**执行中牌库抽空 | Grimoire：该 **效果完全 resolve 后** 再 shuffle；frame 设 `deferred_encounter_shuffle`，当前 Composition 子树 **不** 中断 |
| 两堆皆空 | **RULES_GAP**（OQ-ENC-01） |

```text
collect_one:     empty deck → shuffle now → pop
nested effect:   empty deck → flag defer → on subtree pop → shuffle → 若效果还需 draw 则再 collect
```

### 17.12 CardAbilityService：遭遇 vs 玩家显现

| 方法 | 用于 | flow_id | finalize |
|---|---|---|---|
| `resolve_revelations` | **玩家牌** `seq.enter_hand` | `seq.enter_hand` / draw provenance | `finalize_limbo_discard` → hand |
| `resolve_encounter_revelations` | **E4** 遭遇显现 | `seq.encounter.revelation` | **不** 走 enter_hand；按 Composition 落点 |

```gdscript
func resolve_encounter_revelations(
    game_ctx: GameContext,
    drawer_id: StringName,
    card_id: StringName,
    flow_id: StringName = &"seq.encounter.revelation"
) -> bool:
    # 同 resolve_revelations 结构；register 用 revelation_units_at
    # Forced tier；encounter 先于 player（06 §8 / Grimoire Priority）
    # 不调用 finalize_limbo_discard 除非 builder 显式 enter_hand（Hidden）
```

**禁止** E4 调用 `seq.enter_hand` nest — 订阅键 `(seq.enter_hand, slot)` 与遭遇 draw WHEN 窗口 **不同**。

### 17.13 实现状态

| 已有（可复用） | 待建 |
|---|---|
| `CardAbilityService.resolve_revelations` + Composition | `DrawEncounterFlow` + `DrawEncounterComposition` |
| `ResolutionSequenceStack` nest / run | L0：`pop_encounter_deck_top`、`reveal_to_all`、`shuffle_encounter_discard` |
| **`EncounterResolutionFrame` + E3 RESTRICTION Register + 帧栈**（04 §4.11）；commit → `RestrictionEvaluator` | Action / Eligibility L4 play·trigger（PERIL-02/03） |
| `FaceAudience` / `reveal_to_controller` 模式 | `TriggeringCondition.draw_encounter` 等（§17.10） |
| `DrawInvestigatorService` facade 模式 | `DrawEncounterService` |
| `SequenceCatalog` / bootstrap 模式 | Catalog 全家桶（§17.4）含 `resolve_card` / `resolve_bound` |
| `EnemySystem` spawn 设计（08 §7） | `spawn_engaged` / `discard_spawn_failed` 实现 |
| | `resolve_encounter_revelations` |
| | `ScenarioSystem.resolve_encounter_draw` |
| | ENC-01～12+ 测试 |

---

## 18. Timing Entry Catalog 索引表（TBD）

> **原则**：先定 **§16 等流程明细** 与 Domain brick；catalog 表在流程稳定后 **反推登记**，不在此过早填全。

**已实现 SequenceCatalog 条目（v0.3 部分索引）**：

| flow_id | kind | 说明 |
|---|---|---|
| `seq.draw.investigator` | RUN | 调查员抽 N 张；RESOLVE 后 `nest_batch seq.enter_hand` |
| `seq.draw.collect_one` | RUN（nest） | 单张收集：空库洗弃+horror 或 pop |
| `seq.draw.empty_piles_defeated` | RUN（nest） | 两堆皆空 → ELIMINATED |
| `seq.enter_hand` | NEST_BATCH | 入手 timing + Revelation Composition（全来源共用） |
| `seq.gain_resource` | RUN | 资源 gain + modifier |

占位：move / fight / skill_test 的 `(sequence_id, slot)` 将在流程评审通过后写入。

**已设计 / 待实现 SequenceCatalog 条目（v0.4 部分索引）**：

| flow_id | kind | 说明 |
|---|---|---|
| `seq.draw.investigator` | RUN | 调查员抽 N 张；RESOLVE 后 `nest_batch seq.enter_hand` |
| `seq.draw.collect_one` | RUN（nest） | 单张收集：空库洗弃+horror 或 pop |
| `seq.draw.empty_piles_defeated` | RUN（nest） | 两堆皆空 → ELIMINATED |
| `seq.enter_hand` | NEST_BATCH | 入手 timing + Revelation Composition（**玩家牌**） |
| `seq.gain_resource` | RUN | 资源 gain + modifier |
| `seq.draw.encounter` | RUN | 遭遇抽 N 张；Surge 同帧；push/pop frame |
| `seq.draw.encounter.collect_one` | RUN（nest） | E1；遭遇库 pop；空库洗弃 |
| `seq.draw.encounter.resolve_card` | RUN（nest） | **E2–E6 共享**；主循环与 resolve_bound 共用 |
| `seq.draw.encounter.resolve_bound` | RUN（nest） | weakness / as-if-drawn；skip E1 |
| `seq.encounter.revelation` | NEST | E4 遭遇显现 Forced |
| `seq.encounter.check_peril` | NEST | E3 peril → frame |
| `seq.encounter.dispatch` | NEST | E5 treachery / hidden / enemy 分支 |
| `seq.encounter.spawn` | NEST | `spawn_engaged` / auto engage / discard_spawn_failed |

---

## 19. 测试建议

| ID | 场景 |
|---|---|
| VIS-01 | D2 reveal 后控制者可见、牌仍在 deck |
| VIS-02 | 抽牌后仅控制者 `face_known_to` |
| TIM-01 | draw：WOULD 在 D2 前；WHEN 窗口覆盖 D2–D3 |
| TIM-02 | draw：D2 后 REVEALED；D3 前 zone 可仍 deck/limbo |
| TIM-03 | 有 Revelation 的玩家牌：nest 在 ENTER_HAND（D3），非 draw AFTER 之后 |
| TIM-04 | draw AFTER 在 D3 内各 Revelation nest pop 之后 |
| TIM-05 | move：单 brick；无 leave/enter 双 entry |
| TIM-06 | fight 默认：仅一次 AFTER（merge） |
| TIM-07 | 能力触发 **不** 断言 zone，只断言 entry + slot + information level |
| ENC-01 | 遭遇空库洗弃；**无** horror |
| ENC-02 | Surge：第二圈在 **同一 frame** 内 E1，外层不 pop |
| ENC-03 | AFTER 在本张 E5 后、Surge 下一 E1 前 |
| ENC-04 | Peril 粘性：嵌套检定中他人不可 commit |
| ENC-05 | 遭遇 revelation 走 `seq.encounter.revelation`，**非** `seq.enter_hand` |
| ENC-06 | E2 默认 ALL；Hidden 不公开 |
| ENC-07 | encounter cardtype weakness 从 inv deck 重定向 resolve_bound |
| ENC-08 | 无 Spawn enemy draw | `spawn_engaged`；不调用 auto engage / Engage action |
| ENC-09 | 有 Spawn + 非 Aloof | spawn_at_location 后 `auto_engage_at_location` |
| ENC-10 | Aloof encounter draw（无 Spawn） | unengaged at drawer location；不进 threat area |
| ENC-11 | Spawn 目标 location 未进场 | `discard_spawn_failed` → encounter discard |
| ENC-12 | Weakness enemy spawn 失败 | → bearer **investigator discard** |
| ENC-13 | Hidden treachery | E2 不 ALL；E4 秘密 hand；E5 不 discard |
| ENC-14 | Cancel treachery 效果 | 仍 encounter discard；仍算 drawn |
| ENC-15 | `resolve_bound` vs 主 draw | 同一 `resolve_card` handler |
| WKN-01 | Asset weakness + Revelation | 调查员 D3 `enter_hand`；非 encounter 管线 |
| WKN-02 | Event weakness 无 Revelation | D3 hand only |
| WKN-03 | Enemy weakness from inv deck | `resolve_bound` / E5 spawn |
| WKN-04 | Skill weakness | D3 hand；player cardtype 规则 |

---

## 20. Open Questions（引擎政策）

| ID | 问题 | v0 默认 |
|---|---|---|
| OQ-TIMING-01 | When you draw 锚点 | **D2–D3 区间**（§16.3） |
| OQ-TIMING-02 | Move leave/enter | **MOVE_ATOMIC**，单 entry |
| OQ-TIMING-03 | Draw would/when | **SPLIT**；WOULD=D1 后 D2 前；WHEN=D2–D3 |
| OQ-TIMING-04 | 玩家牌 **Revelation 能力** 于入手时 nest 时点 | **ENTER_HAND（D3）**；`seq.enter_hand` + `TriggeringCondition.enter_hand`；**按能力判定**，非 weakness 卡类型 |
| OQ-TIMING-05 | `enter_hand` 时点多张牌 / 多条显现的 **同类内** 顺序 | **待定**；属 FORCED **类内** 自排；`EnterHandTimingPolicy`，默认 `SOURCE_ORDER`。跨类见 06 §8.1。 |
| OQ-TIMING-06 | 遭遇 draw WHEN 区间 | **E2–E5**（§17.3）；Surge 每圈独立 WHEN |
| OQ-TIMING-07 | 遭遇 draw WOULD 锚点 | **E1 bind 后、E2 前**（§17.3） |
| OQ-TIMING-08 | `amount > 1` encounter draw | **顺序** full resolve（含 Surge 链）再下一张；非 batch reveal |
| OQ-ENC-01 | 遭遇 deck + discard **皆空** | v0：**RULES_GAP**；非正常 scenario 状态 |
| OQ-ENC-02 | drawer 无 location 时 `spawn_engaged` | v0：**`discard_spawn_failed`**（同 spawn 失败，[08 §7.4](08-enemy-engagement.md)） |
| OQ-10-04 | Encounter deck shuffle mid-ability | v0：**collect 立即洗**；嵌套效果内抽空 → **defer 至子树 pop 后**（§17.11）。 |

---

## 21. 实现映射（当前 / 待建）

| 已有 | 待建 |
|---|---|
| `CardFaceVisibility`、`StateMutator` L0 原子 | `TimingCatalog` |
| `CompositionExecutor` + `DrawInvestigatorComposition` | WOULD/WHEN emit（draw WHEN 区间） |
| `SequenceCatalog` + `SequenceCatalogBootstrap`（draw 子 flow、`seq.enter_hand`、`seq.gain_resource`） | **`seq.draw.encounter` 全家桶**（§17.4） |
| `ResolutionSequenceStack` push/pop/nest + `SequenceCatalog.nest` / `nest_batch` | `EncounterResolutionFrame` |
| `DrawInvestigatorService` / `ResourceGainService` 薄 facade → `catalog.run` | `DrawEncounterFlow` / `DrawEncounterComposition` |
| `CardAbilityService` + `CardRegistry.register_revelation` | `resolve_encounter_revelations`（或复用 + flow_id 分支） |
| `EnterHandTimingPolicy`（显现顺序占位，默认 SOURCE_ORDER） | L0 遭遇 pop/shuffle；`ScenarioSystem.resolve_encounter_draw` |
| | §18 完整 Timing 索引表 |
| | ENC-01～15 测试 |

---

## 22. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿：RuleSequence、三槽、Anchor Policy、Brick、merge、PreImpact |
| 2026-05-25 | v0.2 | **§16 调查员抽牌**：D0–D5；D2 牌面 CONTROLLER；WHEN=D2–D3；Revelation=D3 入手 |
| 2026-05-25 | v0.2.1 | §16.1 对齐 [01 §3.6](01-game-state-zones.md) FaceAudience 三档 |
| 2026-05-25 | v0.2.2 | Catalog §8–9、§17 标 TBD；Domain D2/D3 竖切 |
| 2026-06-18 | v0.3 | **§16.4** SequenceCatalog 映射（collect_one / empty_piles / enter_hand）；显现统一 `seq.enter_hand`；§16.6/§20 对齐代码 |
| 2026-06-18 | v0.3.1 | **§16.4.1** 显现顺序 `EnterHandTimingPolicy` 占位；OQ-TIMING-05 |
| 2026-06-18 | v0.4 | **§17 遭遇抽牌**：E0–E7；`seq.encounter.revelation`；Surge 同帧；weakness 重定向；ENC-01～07 |
| 2026-06-18 | v0.4.1 | **§17.4.1** E5 `spawn_engaged` vs `auto_engage_at_location`；ENC-08～10；对齐 [08 §7](08-enemy-engagement.md) |
| 2026-06-18 | v0.4.2 | spawn 失败 **`discard_spawn_failed`**（owner 弃牌堆）；ENC-11～12；OQ-ENC-02 |
| 2026-06-18 | v0.5 | **§17.4** `resolve_card` 共享子 flow；§17.4.2–4 Treachery/Hidden/Surge；§17.8–12 Composition/Flow/Trigger/shuffle/CardAbility；ENC-13～15；OQ-10-04 |
| 2026-06-18 | v0.5.1 | **§17.6.1–3** Weakness 全 cardtype 路由（asset/event/skill vs enemy/treachery）；WKN-01～04；对齐 [11 §10](11-investigator-campaign.md) |
