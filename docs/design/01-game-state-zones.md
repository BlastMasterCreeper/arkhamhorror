# 01 — 游戏状态与区域模型 (GameStateStore)

> **依赖**：[00-architecture-overview.md](../00-architecture-overview.md)  
> **被依赖**：所有 Rules / Script 子系统

---

## 1. 目标

定义 AHC LCG 的**纯状态模型**：实体、区域、标记、控制权，以及 In-Play / Out-of-Play 转换的不变量。本模块不含任何回合推进或卡牌文本逻辑。

---

## 2. 职责边界

| 负责 | 不负责 |
|---|---|
| 实体 CRUD、区域迁移、标记增减 | Framework 步骤推进 |
| In-Play / Out-of-Play 钩子触发（通知 TimingBus） | 能力 initiation |
| Control / Ownership 查询 | 伤害分配策略（属 Rules） |
| 全局查询：`doom_in_play`, `clues_at_location` | UI 可见性（Hidden 牌名过滤见 §3.6） |

---

## 3. 核心类型

### 3.1 EntityId 与 EntityKind

```gdscript
enum EntityKind {
    INVESTIGATOR,
    PLAYER_CARD,      # Asset, Event, Skill, Weakness（实例）
    ENEMY,
    LOCATION,
    ACT,
    AGENDA,
    ATTACHMENT,
    SCENARIO_REFERENCE,
    STORY,
}

class EntityId:
    var kind: EntityKind
    var instance_id: StringName   # 运行时唯一
    var definition_id: StringName # 卡牌印刷 ID，如 "01044"
```

### 3.2 CardInstance（玩家/遭遇卡实例）

```gdscript
class CardInstance:
    var id: EntityId
    var definition: CardDefinition
    var owner_id: StringName           # 牌组归属调查员；遭遇牌 owner = "encounter"
    var controller_id: StringName      # 当前控制者
    var zone: Zone
    var zone_index: int                # 牌组/弃牌堆顺序
    var face: CardFace                 # A / B（Act-Agenda-Location）
    var exhausted: bool
    var tokens: TokenBag               # damage, horror, doom, clue, uses
    var attachments: Array[EntityId]   # 附着于此卡的卡
    var attached_to: EntityId          # 若本卡为 attachment
    var lasting_effect_ids: Array[StringName]
    var script_handle: Variant         # CardScript 引用（Rules 层管理）
    var is_hidden: bool                # Hidden 关键词；Domain 真值（OQ-01-01）
```

### 3.3 InvestigatorState

```gdscript
class InvestigatorState:
    var id: StringName
    var definition_id: StringName
    var location_id: EntityId
    var play_area: Array[EntityId]     # 资产等
    var threat_area: Array[EntityId]   # 遭遇卡
    var hand: Array[EntityId]
    var deck: Array[EntityId]
    var discard: Array[EntityId]
    var slots: SlotOccupancy           # 6 类槽位
    var resource_pool: int
    var clues_on_card: int
    var actions_remaining: int
    var actions_bonus_next_turn: int
    var actions_penalty_next_turn: int
    var eliminated: bool
    var resigned: bool
    var is_active_turn: bool           # mini-card 灰面
```

### 3.4 SlotOccupancy

```gdscript
enum SlotType { ACCESSORY, HEAD, BODY, ALLY, HAND, ARCANE }

class SlotOccupancy:
    var accessory: EntityId
    var head: EntityId
    var body: EntityId
    var ally: EntityId
    var hand: Array[EntityId]        # max 2
    var arcane: Array[EntityId]      # max 2
```

### 3.5 Zone 枚举

```gdscript
enum Zone {
  # Out-of-Play
    DECK,
    HAND,
    DISCARD,
    SET_ASIDE,
    REMOVED_FROM_GAME,
    VICTORY_DISPLAY,
  # In-Play
    PLAY_AREA,
    THREAT_AREA,
    LOCATION_AREA,       # 放在地点上的遭遇卡
    ATTACHED,
    CURRENT_ACT,
    CURRENT_AGENDA,
    SCENARIO_REFERENCE,
  # 特殊
    LIMBO,               # 结算中，见 Grimoire p.23
}
```

**Limbo 语义**：Event/Treachery **显现结算中**时进 LIMBO；Limbo 中卡**不算 In-Play**（Grimoire Limbo）。**已 commit 的 Skill** 不进 LIMBO — 见 `SkillTestContext.committed`，zone 暂留 HAND 直至 ST.8（OQ-01-03）。

### 3.6 Hidden 与信息隔离（已裁决 OQ-01-01）

**Domain 层**在 `CardInstance.is_hidden` 标记 Hidden 状态。Rules / headless **保留完整 definition_id**。

**Presentation 层**对非 owner 隐藏牌名与文本，仅显示 Hidden 牌背；由 `VisibilityFilter` 分流 owner / observer 视图。

```gdscript
class VisibilityFilter:
    func get_display_title(card: EntityId, observer: StringName) -> String:
        var inst := state.get_card(card)
        if inst.is_hidden and inst.owner_id != observer:
            return "[Hidden]"
        return inst.definition.title
```

### 3.7 TokenBag

```gdscript
class TokenBag:
    var damage: int
    var horror: int
    var doom: int
    var clue: int
    var uses: Dictionary[StringName, int]  # "ammo", "charges", ...
```

全局 `TokenPool`（table 上 token pool）与卡上/调查员上 token 分开管理。

---

## 4. GameStateStore API（草案）

```gdscript
class GameStateStore:
    var investigators: Dictionary[StringName, InvestigatorState]
    var cards: Dictionary[EntityId, CardInstance]
    var locations: Dictionary[EntityId, LocationState]
    var act_deck: Array[EntityId]
    var agenda_deck: Array[EntityId]
    var current_act_id: EntityId
    var current_agenda_id: EntityId
    var encounter_deck: Array[EntityId]
    var encounter_discard: Array[EntityId]
    var victory_display: Array[EntityId]
    var set_aside: Array[EntityId]
    var global_token_pool: TokenPool
    var per_investigator_count: int      # 用于 per investigator 计算，含已淘汰

    # --- 查询 ---
    func is_in_play(entity: EntityId) -> bool
    func get_controller(entity: EntityId) -> StringName
    func get_owner(entity: EntityId) -> StringName
    func get_location_of_investigator(id: StringName) -> EntityId
    func get_entities_at_location(loc: EntityId) -> Array[EntityId]
    func get_doom_in_play() -> int
    func get_enemies_engaged_with(inv: StringName) -> Array[EntityId]

    # --- 迁移（仅 ZoneManager 或 Effect 回调应调用）---
    func move_card(card: EntityId, to_zone: Zone, ctx: MoveContext) -> Result
    func enter_play(card: EntityId, dest: Zone, ctx: EnterPlayContext) -> Result
    func leave_play(card: EntityId, dest: Zone, ctx: LeavePlayContext) -> Result
```

---

## 5. In-Play / Out-of-Play 转换

### 5.1 Enters Play（Grimoire p.23）

- 从 Out-of-Play → In-Play 区域。
- 若能力指定「以非默认状态进场」，**无过渡动画式状态**，直接处于该状态。
- 触发：`TimingBus.emit("enters_play", payload)`。

### 5.2 Leaves Play（Grimoire p.14）

**同时**发生：

1. 卡上所有 token 归还 `global_token_pool`
2. 所有 attachments 弃置（进各自 owner discard）
3. 影响该卡的 lasting / delayed effects 对该卡过期

然后卡迁入目标 Out-of-Play 区域。

### 5.3 同时效果（已裁决 OQ-01-02）

Grimoire 中「simultaneously / 同时」的电子化语义（资深玩家裁定）：

1. **目的**：保证被「同时」统领的状态变更不会在场上共存（如 Unique 冲突：遭遇版与玩家版同名卡不能同时在场）。
2. **时点**：「同时」= 这些效果在**同一 timing point** 触发或**开始结算**；不是简单的「按代码顺序一行行执行」。
3. **与 after 的关系**：所有 `after` 类触发必须等该**同时效果组全部结算完毕**后才可形成；组内不得插入 `after` 响应。
4. **泛化**：同样适用于「效果 A and 效果 B」—— A 与 B 视为同一同时组内的并列效果。
5. **频率**：Unique 遭遇/玩家同名冲突等情形**极少**，但机制应通用，不做 Unique 专用 hardcode。

```gdscript
class SimultaneousEffectGroup:
    ## 同一 timing point 内开始结算的一组 EffectRequest
    func begin(timing: TimingPoint) -> void
    func add(effect: EffectRequest) -> void
    func commit() -> void   # 组内全部 resolve 完成后，才释放 after 触发
```

Unique 冲突示例：遭遇 Naomi enters play + 玩家 Naomi discard → 同一 `SimultaneousEffectGroup.commit()` 内完成；其间不触发 enters play / leaves play 的 `after` 能力。

详见 [07-effect-resolution.md §7.5](07-effect-resolution.md)。

### 5.4 状态机（简化）

```
OutOfPlay --enter_play--> InPlay
InPlay --leave_play--> OutOfPlay
Hand/Deck --[play/initiate]--> Limbo --resolve--> InPlay | Discard
```

（原 §5.3 状态机顺延为 §5.4。）

---

## 6. Control vs Ownership

| 概念 | 定义 |
|---|---|
| **Owner** | 牌组归属；弱点 bearer；遭遇牌 owner = encounter deck |
| **Controller** | 谁可发起该卡上的 player 能力、谁分配伤害到 asset |

规则要点：

- 调查员**控制**其 play area 内资产、investigator 卡、手牌、牌组、弃牌堆。
- 遭遇卡 drawn 后由 drawing investigator **控制**结算，但 **owner** 仍为 encounter。
- 弱点进入 deck 后 owner 为 bearer；scenario 赋予的 story asset 同理。
- 淘汰时：owner 控制且 in-play 的卡 removed from game；owner 但不 control 的 in-play 卡留场，离场时 removed（Grimoire Elimination）。

---

## 7. 与其他子系统接口

| 子系统 | 交互 |
|---|---|
| `FrameworkFlowEngine` | 读 `actions_remaining`、阶段标志 |
| `ZoneManager` | 封装 `move_card` 合法性（如 ThreatArea 仅 enemy/treachery） |
| `EffectResolutionGraph` | 通过 `EffectApplier` 调用 `enter_play` / `leave_play` |
| `AbilityInitiationPipeline` | 校验 target in-play、controller |
| `LocationGraph` | 维护 `LocationState.connections`, `revealed` |
| `TimingBus` | `enters_play`, `leaves_play`, `zone_changed` |

---

## 8. LocationState（摘要）

```gdscript
class LocationState:
    var id: EntityId
    var definition_id: StringName
    var revealed: bool
    var clues_on_location: int
    var enemies_here: Array[EntityId]   # unengaged enemies
    var connections: Array[EntityId]  # 邻接地点
    var connection_directed: Dictionary  # 可选：单向边
```

---

## 9. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| S-01 | Asset play → PLAY_AREA | `is_in_play` true |
| S-02 | Asset defeated → DISCARD | tokens 归还 pool |
| S-03 | Attachment host leaves play | attachment discarded |
| S-04 | Treachery draw → LIMBO → DISCARD | Limbo 期间不算 in-play |
| S-05 | Investigator eliminated | hand/deck/play removed；engaged enemies → location |
| S-06 | Unique 玩家卡 in play，同名遭遇进场 | 玩家卡 discard simultaneous（Grimoire Unique） |

---

## 10. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-01-04 | P2 | `SET_ASIDE` 与 `REMOVED_FROM_GAME` 是否需子类型（campaign 指定 area）？ |
| OQ-01-05 | P1 | 多 copy 同 title 非 exceptional 卡 in play：instance_id 与 definition_id 在 Target 解析中的优先级？ |
| OQ-01-06 | P2 | Attachment 链（A attach B attach C）leave play 时 discard 顺序是否由 owner 选？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-01-02 | 通用「同时效果组」语义：同一 timing point 开始结算；组完成后才触发 `after`；适用于 Unique 冲突与「A and B」。原语 `SimultaneousEffectGroup`。 | 2026-05-25 |
| OQ-01-01 | **Domain** `CardInstance.is_hidden`；**Presentation** 对非 owner 隐藏牌名。见 §3.6。 | 2026-05-25 |
| OQ-01-03 | **B**：`SkillTestContext.committed` 追踪；zone **仍为 HAND** 至 ST.8；**不进 LIMBO**。见 §3.5 Limbo 说明、04 §4。 | 2026-05-25 |

---

## 11. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-01-02 裁决：SimultaneousEffectGroup 同时效果语义 |
| 2026-05-25 | v0.3 | OQ-01-01 裁决：Hidden Domain 标记 + Presentation 过滤 |
