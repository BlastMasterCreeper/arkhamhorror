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

### 3.5.1 放置关系（Placement · 已裁决 2026-10-24）

> **问题**：旁置、附着、垫下（可背面）、牌库、特殊区域「是否在场」常被揉成 `ATTACHED` / `SET_ASIDE` 一种。  
> **裁决**：物理层用 **放置关系** 区分地址；场上/场外是 **规则谓词**（可被卡面改写）；可见性仍正交。

#### 放置种类（物理地址 · 状态原语 ①）

| Kind | 物理像什么 | 与宿主关系 | 典型 |
|---|---|---|---|
| **FREE** | 独立区（play / threat / location_area…） | 无宿主叠放 | 场上支援、威胁区敌人 |
| **BESIDE** | 宿主实体**旁**的独立 flat 区 | `beside_host_id`；**不**叠在宿主下 | 旁置地点/密谋/行动/场景实体的指示物牌、探索辅堆等 |
| **ATTACHED** | 叠在宿主上并重叠（Grimoire *attach*） | `attached_to`；宿主离场默认带走弃置 | 附着地点的 treachery、武器附着等 |
| **UNDER** | 垫在宿主**之下**（可正面/背面） | `under_host_id` + 序；**不是** attach | 蜂拥垫牌、部分「放这张卡下」 |
| **DECK_ORDERED** | 有序牌堆（Shape.DECK） | 库/弃的序 | 调查员库、遭遇库、部分特殊有序堆 |

```text
禁止混用：
  ATTACHED ≠ UNDER     （规则：附着 vs 垫下；离场默认不同）
  UNDER ≠ DECK_ORDERED （垫下通常可知「是哪张/有几张」；牌库默认不知内容）
  BESIDE ≠ SET_ASIDE   （旁置有宿主座位；set-aside 是全局场外区，可再亚型）
```

物理区 id 建议：`beside_<host>` / `under_<host>` / 既有 `threat_*` / `deck_*`；Domain 可咽喉双写 `attached_to` / `under_host_id` / `beside_host_id`（派生索引，非信息原语）。

#### 场上 / 场外（规则谓词 · 非单纯 zone）

- **默认表**：play / threat / location_area / attached / under（若卡面未另说）/ current act·agenda / scenario reference → 常 **in play**；deck / hand / discard / set-aside / RFG / victory / limbo → **out of play**。  
- **特殊区域**：卡面或区域规格可写明 *in play* / *out of play*（或「视为在场」）。该声明 **覆盖默认表**。  
- **互动范围**：Eligibility 默认用 in-play 筛玩家可触发/可选目标；**不是**铁律——卡面写「即使场外也可」「仅手牌」等时放宽或收紧。  
- **实现注意**：`ZoneMoveFlow.zone_is_in_play` 过窄（仅 PLAY/THREAT）须升到与本表 + 区域规格一致；进场/离场别名钩听 **谓词变迁**，不听「zone 字符串集合」硬编码。

#### 离场默认捆绑 vs 保留（§5.2 细则）

默认（宿主 **离开 in-play** 时，与 Move 同事务）：

1. 宿主标记回 ∞ 池（Transfer）  
2. **ATTACHED** → 各 owner 弃牌堆  
3. **UNDER** → 默认随规则：常见弃置或回遭遇库底（蜂拥等另规）；**不**自动当 attachment 弃  
4. `WHILE_IN_PLAY` Register 卸除  

**卡面可改写**（`LeavePlayPolicy` / 命名流程参数）：

| 旗 | 含义 |
|---|---|
| `retain_tokens` | 离场不剥标记（交换宿主、部分放逐例外等） |
| `retain_attachments` | 附着不弃，随宿主或改挂 |
| `retain_under` | 垫下牌不散，随宿主迁移 |
| `attachments_to_victory` | Victory 附着进胜利区（FAQ 类） |

禁止把「默认剥光」写成唯一实现且无视卡面保留句。

#### 垫下背面 vs 牌库（可见性）

| | **UNDER + 背面** | **DECK_ORDERED** |
|---|---|---|
| 物理形态 | `CardFace` 背 / exhausted 无关 | 牌库形区 + 序 |
| 默认 `FaceAudience` | 常 **ALL 或 CONTROLLER**（玩家**知道是哪张/可知身份**；「背面」只是朝向） | **HIDDEN_ALL**（不知内容） |
| 信息层 | 身份通常已在生效特征查询里可知 | 未 reveal 前观察者不知 `definition_id`（规则层仍持有） |

> 背面 ≠ 不可知。垫下背面是 **形态**；牌库隐藏是 **可见性**。二者正交（§3.6）。

### 3.6 牌面可见性（按观察者）

**牌面可见性是针对玩家（调查员观察者）的**，与 **zone** 正交。  
Rules / headless **始终保留完整 `definition_id`**；可见性决定 **某观察者是否知晓牌面**，以及 Presentation 如何渲染。

> **已裁决 · 可见性是权限/信息管理，不是结算原语**（[07 §5.4.1](07-effect-primitives.md)）  
> 写 `FaceAudience`（`reveal_to_*` / `hide_from_all`）= **谁被允许知道牌面**；手续可同步，**本身不算结算**，dry-run **不**单独 **CREATED**。  
> **物理 ③** 只管翻面与横置/重整；可见性与面向正交（面朝下仍可可知）。  
> Headless 始终保留完整 `definition_id`。抽牌 **D2** = 权限同步（zone 仍未 HAND）；**WHEN draw** 在 D3。见 [15 §3.1](15-timing-entry-catalog.md)。

#### 3.6.1 三档受众（FaceAudience）

| 档位 | 含义 | 典型 |
|---|---|---|
| **HIDDEN_ALL** | **所有玩家**均不知牌面（可知「此处有牌」） | 牌库顶、他人手牌、未揭示的 deck/discard 窥探前 |
| **CONTROLLER** | **仅控制者**知牌面 | 自己手牌、Hidden 遭遇（控制者）、抽牌 D2 后 |
| **ALL** | **所有调查员**知牌面 | 场上公开 treachery、「全体看牌库顶」类效果 |

```gdscript
enum FaceAudience { HIDDEN_ALL, CONTROLLER, ALL }

class CardFaceVisibility:
    var audience: FaceAudience = FaceAudience.HIDDEN_ALL
    ## 可选：显式观察者集合（非常规 reveal）；默认由 audience + controller_id 推导

    func face_known_to(card: CardInstance, observer: StringName) -> bool:
        match audience:
            FaceAudience.HIDDEN_ALL:
                return false
            FaceAudience.CONTROLLER:
                return card.controller_id == observer
            FaceAudience.ALL:
                return true
        return false
```

**控制者 vs 所有者**：触发与 peek 以 **`controller_id`** 为准（遭遇 draw 后控制者常为 drawer）；owner 用于 deck/weakness bearer 等，见 §6。

#### 3.6.2 与 zone / 隐私（Hidden）关键词

| 概念 | 层 | 说明 |
|---|---|---|
| **zone** | Domain | 牌在哪个 pile（deck/hand/…） |
| **FaceAudience** | Domain | 谁看得到 **牌面** |
| **隐私（Hidden）** | 规则 → Domain | 遭遇/弱点关键词；E4 秘密入手后通常 **CONTROLLER** 对控制者，**HIDDEN_ALL** 对他人 |
| **`is_hidden`** | Domain 标记 | 对应卡牌关键词 `hidden`；**不替代** FaceAudience，由 E4 / expose 同步 |

**隐私 · 离手不变量**（Grimoire p.14）：隐私牌在手牌期间 **除该卡牌面能力所述方式外，不能以任何方式离开手牌**。引擎：**E4 Register `FORBID_LEAVE_HAND`**（`WHILE_HIDDEN_IN_HAND`）；`move_card` 入口查询；G4 Framework skip 为不发起非法 Intent 的优化。见 [15 §17.4.3](15-timing-entry-catalog.md)。

**禁止**用 zone 推导牌面可见性（例如「还在 deck 则无人可见」仅作 **默认策略**，D2 reveal 后可为 CONTROLLER 而 zone 仍为 deck/Limbo）。

#### 3.6.3 权限同步（非结算）与「非进场可知」

| 操作 | 改什么 | 是否结算/效果 | 是否改 zone |
|---|---|---|---|
| **抽牌 D2** | `audience → CONTROLLER` | **否**（权限同步；可另伴物理翻面） | 否（D3 才 HAND） |
| **遭遇抽 E2** | 默认 `ALL`；隐私常对控制者 | **否**（权限同步） | G1 已 LIMBO；G4 才落场/弃 |
| **窥探牌库/弃牌堆顶** | CONTROLLER 或 ALL | **否**（权限；结束常 hide） | 否 |
| **Search 展示** | 按文本设 audience | **否**（权限） | 视后续 MoveCard（取牌才结算） |
| **ENTER_HAND** | zone 变更 | **是**（MoveCard · 物理 ①） | 是 |

写 `FaceAudience` **≠** enter play，**≠** 物理翻面，**≠** CREATED；与 MoveCard 分步（D2 权限 → D3 入手）。

#### 3.6.4 Presentation 分流

```gdscript
class VisibilityFilter:
    func get_display_title(card: EntityId, observer: StringName) -> String:
        var inst := state.get_card(card)
        if inst.face.face_known_to(inst, observer):
            return inst.definition.title
        return "[Hidden]"  # Presentation · 非控制者未见牌面（含隐私牌）
```

Presentation **只读** Domain 的 `CardFaceVisibility`；不在 UI 层单独维护「谁看到了什么」。

#### 3.6.5 与 Peril / 多人

- **Peril**： encounter 帧内仅 drawer 为 relevant observer（协助/打牌限制）；与 FaceAudience 叠加，见 [04-skill-test-engine](04-skill-test-engine.md)。  
- **Headless**：规则用完整 `definition_id`；测试可见性时 assert `face_known_to(card, observer)`。

### 3.7 TokenBag

```gdscript
class TokenBag:
    var damage: int
    var horror: int
    var doom: int
    var clue: int
    var uses: Dictionary[StringName, int]  # "ammo", "charges", ...
```

全局 `TokenPool`（table 上 token **无穷供给池**）与卡上/调查员上 token 分开管理：取出不尽、回池不记账；桌面标记变更一律经 Transfer（见 [07-effect-primitives §5.2](07-effect-primitives.md)）。

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

### 5.2 Leaves Play（Grimoire p.14 · 保留例外见 §3.5.1）

**默认**与迁出 **同事务**发生（可用 `LeavePlayPolicy` 改写）：

1. 卡上 token → ∞ 供给池（`transfer_marker`；`retain_tokens` 则跳过）  
2. **ATTACHED** → 各 owner discard（`retain_attachments` / 改挂 / 进胜利区则例外）  
3. **UNDER** 按垫下规则处理（默认不与 attachment 混用同一弃置例程）  
4. 影响该卡且绑 `WHILE_IN_PLAY` 的 Register 卸除（其它 lasting 见 06 OQ-BUFF-04）

然后卡迁入目标区域；目标区的 **in-play 谓词** 由 §3.5.1 决定（特殊区可仍算在场）。

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
| OQ-01-05 | P1 | 多 copy 同 title 非 exceptional 卡 in play：instance_id 与 definition_id 在 Target 解析中的优先级？ |
| OQ-01-06 | P2 | Attachment 链（A attach B attach C）leave play 时 discard 顺序是否由 owner 选？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-01-02 | 通用「同时效果组」语义：同一 timing point 开始结算；组完成后才触发 `after`；适用于 Unique 冲突与「A and B」。原语 `SimultaneousEffectGroup`。 | 2026-05-25 |
| OQ-01-01 | **Domain** `CardInstance.is_hidden`；**Presentation** 对非 owner 隐藏牌名。见 §3.6。 | 2026-05-25 |
| OQ-01-03 | **B**：`SkillTestContext.committed` 追踪；zone **仍为 HAND** 至 ST.8；**不进 LIMBO**。见 §3.5 Limbo 说明、04 §4。 | 2026-05-25 |
| OQ-01-04 | **亚型可建**：set-aside / RFG / 旁置特殊区用区域规格（`play_membership` + PlacementKind）；不单靠一个扁平 SET_ASIDE。见 §3.5.1。 | 2026-10-24 |
| OQ-01-07 | **ATTACHED ≠ UNDER ≠ DECK**：垫下背面默认可知身份；牌库默认 HIDDEN_ALL。离场保留用 `LeavePlayPolicy`。见 §3.5.1 / §5.2。 | 2026-10-24 |

---

## 11. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-10-24 | v0.5 | §3.5.1 放置关系；场上谓词可覆盖；离场保留；垫下 vs 牌库可见性 |
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-01-02 裁决：SimultaneousEffectGroup 同时效果语义 |
| 2026-05-25 | v0.4 | §3.6 牌面可见性三档（HIDDEN_ALL / CONTROLLER / ALL）；与 zone 正交 |
| 2026-09-20 | v0.4.1 | 抽牌 When 时调查员 HAND、遭遇 LIMBO；Would 时仍 DECK（15 §3.1） |
