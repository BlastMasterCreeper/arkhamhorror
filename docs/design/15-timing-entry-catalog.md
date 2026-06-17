# 15 — 规范时点入口 (Timing Entry Catalog)

> **依赖**：[06-ability-initiation.md](06-ability-initiation.md), [14-nested-sequences.md](14-nested-sequences.md), [06-registration-buff-model.md](06-registration-buff-model.md), [07-effect-primitives.md](07-effect-primitives.md)  
> **符号记法**：[ArkhamDB 标准](../reference/arkham-symbol-notation.md)  
> **状态**：v0.2 · 2026-05-25

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
| **MOVE_INTENT_COMMITTED** | `seq.action.move` | from/to **已确定**；leave+enter **规则上同时**（一个 brick） |
| **FIGHT_COMMITTED** | `seq.action.fight` | Fight 行动 **开始 RESOLVE**；默认与内嵌 test 的 AFTER **merge**（§7） |
| **GAIN_COMMITTED** | `seq.action.gain_resource` | 一次 gain 结算 commit（已实现竖切） |
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
| **WOULD_AND_WHEN_SPLIT** | would/when **不可互换**；有 **明确步骤分界** | **`seq.draw.investigator`**、encounter reveal |

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

D1  确定来源 + 绑定 instance（RESOLVE_SOURCE + BIND）
    · 牌库非空 → bind 顶牌 instance_id
    · 空库 → nest seq.draw.shuffle_and_horror → 再 bind
    · 两堆皆空 → nest seq.draw.empty_piles_defeated → 本张 draw 终止
    信息：HIDDEN_ALL（控制者亦不知牌面）

D2  INFORMATION — reveal_to(controller)
    牌面：HIDDEN_ALL → **CONTROLLER**（控制者）  ★ D2 ★
    区域：仍可 deck / Limbo（实现）；触发不读 zone

D3  ENTER_HAND — zone → HAND
    信息：CONTROLLER（控制者）；他人仍 HIDDEN_ALL
    区域：→ HAND
    · 若该牌 **具备 Revelation 能力**（`Revelation –`）：**进入手牌时** nest `seq.revelation.on_enter_hand`
      （Forced；**不是** D5 之后、**不是** 独立 D4 尾巴）
      · **Weakness ⊄ Revelation**：弱点不一定有显现；无显现则仅入手
      · **Revelation ⊄ Weakness**：Dilemma 等玩家牌亦可有显现；同一 nest 规则

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
  … 可 refresh；可 nest seq.revelation（D3 内）…
close TimingWindow                              # D3 ENTER_HAND + revelation nest 完成
```

**「When you draw」** 能力在 **控制者已为 CONTROLLER 之后、draw 序列 pop 之前** 均可响应，**包括** 正在入手与 **显现结算期间**（仍在 D3 内）。

**「When you would draw」** → 订阅 **WOULD**（D2 前）。

### 16.4 Bricks 与 emit

```text
seq.draw.investigator
  bricks:
    1. RESOLVE_SOURCE      # D1 含空库分支 nest
    2. BIND_INSTANCE       # D1
    3. INFORMATION         # D2
    4. ENTER_HAND          # D3 + on_enter_hand → 若 has_revelation → nest seq.revelation.on_enter_hand

  emit:
    WOULD  — after brick 2, before brick 3
    WHEN   — open after brick 3; close after brick 4（含 revelation nest）
    AFTER  — on pop
```

```gdscript
class EnterHandBrick:
    func execute(ctx):
        move_zone(instance, HAND)
        if card.has_revelation_ability():  # 能力存在性；与 weakness 卡类型正交
            sequences.nest(TriggeringCondition.revelation_on_enter_hand(...), ...)
```

### 16.5 与遭遇抽牌、Weakness 分流

| | `seq.draw.investigator` | `seq.draw.encounter` |
|---|---|---|
| 来源 | 调查员 deck | encounter deck |
| Revelation | **D3 入手时**，仅 **has Revelation** 的玩家牌 | 遭遇帧内 revelation（另 catalog） |
| WHEN 区间 | D2–D3（本节） | 另定 |

**Weakness（卡子类型）** 与 **Revelation（能力类型）** 正交（Grimoire Glossary 分列）：

| 情况 | 行为 |
|---|---|
| 玩家牌 **有 Revelation**，经本序列入手 | D3 nest `seq.revelation.on_enter_hand` |
| 玩家牌 **无 Revelation**（含部分 weakness） | D3 仅 zone→hand |
| **Encounter cardtype weakness** 被当作遭遇抽出 | 走 `seq.draw.encounter` / 遭遇帧，**非**本节 D3 |

### 16.6 实现状态（Domain 竖切）

| 已有 | 待建 |
|---|---|
| `CardFaceVisibility` + `FaceAudience`（[01 §3.6](01-game-state-zones.md)） | `TimingCatalog` / WHEN 区间窗口 |
| `InformationExecutor.reveal_to_controller / reveal_to_all` | `TimingCatalog` / WHEN 区间窗口 |
| `StateMutator.execute_draw_instruction`（≥2 同时、mid-draw shuffle+horror） | **Revelation** nest（`has_revelation_ability`；按入手顺序） |
| `DrawInvestigatorService.draw_cards` → `sequences.run` | WOULD/WHEN emit |

---

## 17. Timing Entry Catalog 索引表（TBD）

> **原则**：先定 **§16 等流程明细** 与 Domain brick；catalog 表在流程稳定后 **反推登记**，不在此过早填全。

占位：gain / draw / move / fight / skill_test / revelation 的 `(sequence_id, slot)` 将在流程评审通过后写入。

---

## 18. 测试建议

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

---

## 19. Open Questions（引擎政策）

| ID | 问题 | v0 默认 |
|---|---|---|
| OQ-TIMING-01 | When you draw 锚点 | **D2–D3 区间**（§16.3） |
| OQ-TIMING-02 | Move leave/enter | **MOVE_ATOMIC**，单 entry |
| OQ-TIMING-03 | Draw would/when | **SPLIT**；WOULD=D1 后 D2 前；WHEN=D2–D3 |
| OQ-TIMING-04 | 玩家牌 **Revelation 能力** 于入手时 nest 时点 | **ENTER_HAND（D3）**；`seq.revelation.on_enter_hand`；**按能力判定**，非 weakness 卡类型 |

---

## 20. 实现映射（当前 / 待建）

| 已有 | 待建 |
|---|---|
| `CardFaceVisibility`、`InformationExecutor` | `TimingCatalog` |
| `StateMutator` D2/D3 抽牌拆分 | `seq.draw.investigator` sequence stack |
| `ResolutionSequenceStack` push/pop | WHEN 区间窗口、Revelation nest |
| `ResourceGainService` → `seq.action.gain_resource` | WOULD/AFTER emit |

---

## 21. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿：RuleSequence、三槽、Anchor Policy、Brick、merge、PreImpact |
| 2026-05-25 | v0.2 | **§16 调查员抽牌**：D0–D5；D2 牌面 CONTROLLER；WHEN=D2–D3；Revelation=D3 入手 |
| 2026-05-25 | v0.2.1 | §16.1 对齐 [01 §3.6](01-game-state-zones.md) FaceAudience 三档 |
| 2026-05-25 | v0.2.2 | Catalog §8–9、§17 标 TBD；Domain D2/D3 竖切 |
