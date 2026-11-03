# 11 — 调查员、牌组与剧本 (InvestigatorCampaignSystem)

> **依赖**：[01-game-state-zones.md](01-game-state-zones.md), [07-effect-resolution.md](07-effect-resolution.md)  
> **规则来源**：Grimoire Deckbuilding, Campaign Play, Trauma, Experience, Weakness, Slots

---

## 1. 目标

管理 **Investigator 运行时状态**、槽位、牌组操作、淘汰/辞职、**剧本（Campaign）** Trauma/XP/Deckbuilding、Standalone/Epic 模式。

---

## 2. Investigator 运行时

见 [01-game-state-zones.md](01-game-state-zones.md) `InvestigatorState`。

额外：

```gdscript
class InvestigatorDefinition:
    var id: StringName
    var skills: Dictionary[SkillType, int]
    var health: int
    var sanity: int
    var elder_sign_ability_id: StringName
    var deckbuilding: DeckbuildingOptions
    var required_cards: Array[StringName]
    var signature_weakness: StringName
```

---

## 3. 槽位（Slots）

| 槽 | 数量 |
|---|---|
| Accessory | 1 |
| Head | 1 |
| Body | 1 |
| Ally | 1 |
| Hand | 2 |
| Arcane | 2 |

Play/gain asset 无 slot → 选 discard 已有 asset 腾位。

---

## 4. 牌组与手牌

| 规则 | 实现 |
|---|---|
| Deck size | 通常 30 + modifiers（Permanent 等） |
| Hand size max 8 | 仅 Upkeep 4.5 检查 |
| Draw empty deck | shuffle discard + 1 horror + draw |
| Discard empty | defeated + 1 mental trauma |
| Mulligan | opening hand 可换 once；weakness 重抽不 resolve |
| Starting | keyword：mulligan 后 search 1 copy 加入 hand |

---

## 5. 淘汰 / Resign / Elimination

### 5.1 Defeated

- Damage ≥ health OR horror ≥ sanity OR ability defeat
- Campaign：1 physical OR 1 mental trauma（同时满选一种）

### 5.2 Resign

- Clues/scenario tokens → current location
- Eliminated from scenario，**不**改 [per_investigator] count

### 5.3 Elimination 清理

Grimoire Elimination：removed from game 其 owner 控制物；clues → location；enemies threat → location；选新 lead investigator。

---

## 6. 剧本状态（CampaignState）

```gdscript
class CampaignState:
    var log: CampaignLog
    var investigators: Array[CampaignInvestigatorRecord]
    var chaos_bag_snapshot: ChaosBagSnapshot
    var difficulty: Difficulty

class CampaignInvestigatorRecord:
    var investigator_id: StringName
    var deck_list: Array[DeckEntry]
    var physical_trauma: int
    var mental_trauma: int
    var unspent_xp: int
    var story_assets: Array[StringName]
    var story_weaknesses: Array[StringName]
    var killed: bool
    var insane: bool
```

### 6.1 Campaign Log

- 精确短语记录（Campaign Notes）
- Cross out 忽略
- Remember vs Record：scenario 内 remember 不持久化

---

## 7. Experience 与 Deckbuilding

> **规则来源**：Grimoire *Experience*；FAQ Game Play **1.8**；2026 Core Rulebook *Earning and Spending Experience*；Customizable / Exceptional / Myriad / Exile / FAQ 1.18 / 1.37。  
> **实现状态（2026-11-03）**：`spend_xp_and_upgrade` 仅 API 壳；剧本幕间（interlude）流程 **未实现**。本节先定规则模型，供后续落地。

### 7.1 手续顺序（Scenario 后）

```
1. Count XP = victory display + guide ± + prior unspent
2. Spend window：逐张 NEW_PURCHASE / UPGRADE /（Customizable 勾选）…
3. 每加 1 张非 Permanent → 须移除 1 张；maintain deck size
4. 遵守 deckbuilding；weakness / required 不可因购卡移除
5. Record unspent XP
```

卡面若改 deckbuilding / 购卡 / 升级（如 Adaptable、Underworld Market）：**逐张结算**，购入后立即对本 spend window 生效（FAQ 1.37）。

### 7.2 雷点：min-1 只绑「购新卡」，不绑「升级」

| 来源 | 购新卡（new card） | 同名升级（upgrade） |
|---|---|---|
| Grimoire *Experience* | `cost = level`，**floor 1**（L0 仍付 1） | `cost = level差`，文面另写 **floor 1** |
| FAQ **1.8** | 明确：购新卡最少付 1；L0 = 1 | **明确：该 minimum 不适用于 upgrade**；也不永久改印刷 level |
| 2026 Core RB | 「always costs at least 1… even if level 0」 | 「spend … equal to the **difference in level**」——**无** floor 1 |

**引擎裁决（已定）**：以 FAQ 1.8 + 2026 RB 为准。

- `NEW_PURCHASE`：`xp_cost = max(1, printed_level)`（再乘 Exceptional 等修饰）。
- `UPGRADE`：`xp_cost = new_level - old_level`（**无** min-1 floor）。  
  标准整数 level、且必须升到**更高** level 时，差值本身 ≥ 1，与 Grimoire 升级句的 floor 1 **数值上通常重合**；差别在语义归属，避免把「购新卡 min-1」渗进升级谓词与边角（见 Customizable / 差值为 0 的非法请求）。

`11` 旧稿「upgrade 付 level 差 min 1」→ **作废**，改为上式。

### 7.3 升级是不是「购买」？

**分两层，禁止混成一个谓词：**

| 层 | 结论 | 依据 |
|---|---|---|
| **手续窗** | 升级落在 Experience 步骤 2「Purchase new cards」同一 spend window；Grimoire 用 “when purchasing a higher level version… may choose to upgrade”；“purchased (or upgraded) individually” | 同窗、逐张、扣 XP、改牌组 |
| **卡面 / FAQ 谓词** | **升级 ≠ 购新卡（purchase a new card）** | FAQ 1.8 把 min-1 限定在 purchasing new cards；Customizable：「直接买带勾选的新卡 = purchasing a new card, **not** upgrading」；「对已有 customizable 勾选 = upgrading for card effects」 |

因此引擎必须区分交易种类（建议枚举），**不要**用单一 `is_purchase` 覆盖两者：

```text
XpSpendKind:
  NEW_PURCHASE   — 加入一张牌组中尚无对应副本关系的新卡（含「直接买高亮 customizable」）
  UPGRADE        — 同 title 低级→高级：付差额、移除低级、加入高级
  CUSTOM_CHECK   — 已有 customizable 的 upgrade sheet 勾选（card-effect 亦算 upgrading）
```

卡面「when you purchase / when you upgrade」分别听 `NEW_PURCHASE` / `UPGRADE|CUSTOM_CHECK`。  
口语「买升级」只描述 spend window，**不能**写成规则谓词上的 purchase。

### 7.4 费用与牌组约束（摘要）

| 种类 | XP | 牌组 |
|---|---|---|
| `NEW_PURCHASE` | `max(1, level)`；Exceptional → ×2 印刷费用；Myriad 可连带最多 2 张同 level 副本 0 XP | 非 Permanent：+1 须 −1；deckbuilding 准入 |
| `UPGRADE` | `new − old`（无 min-1）；须同 title 且 new > old；Researched 只能走升级且 log 任务已完成 | 移除低级、加入高级（通常净尺寸不变） |
| Exile 后补牌至合法尺寸（FAQ 1.18） | 在补足尺寸前，L0 可 **0 XP** 购入 | 强制 maintain size |
| Customizable 勾选 | 1 XP / checkbox；满格才算购得该 upgrade；sheet 合计 ≤10 | 已有副本：算 upgrading；新卡带勾选一次付清：算 NEW_PURCHASE |

| 关键词 | 规则 |
|---|---|
| Permanent | deck creation only；不计 deck size |
| Exceptional | 2× 印刷 XP cost；max 1 copy by title |
| Reward | 解锁后可用；golden corner |
| Bearer | 忽略 deckbuilding；不计 deck size |
| Myriad | 购一张可再 +≤2 同 level 0 XP；计总 XP 时第 2/3 副本不计 |
| Researched | 不可 `NEW_PURCHASE` 高级；须从低级 upgrade + Campaign Log 任务 |
| Customizable | 见上；清空最后副本 → sheet 清空；回购当新卡 |

---

## 8. Starter Deck 2026

- 预构 deck 含 **指定 signature weakness**
- **不**追加 random basic weakness（campaign flag `use_starter_deck_no_random_weakness`）

---

## 9. Standalone / Epic

**Standalone**：

- 可用 higher level cards，按 total XP 加 random basic weaknesses
- Record → Remember（scenario 内）
- 50+ XP cards 禁止

**Epic**：跨 campaign transfer 规则（reset XP cards level 1–5, trauma/story assets 保留, reset log 等）。

---

## 10. Weakness 与 Revelation（分流）

> **规则来源**：Grimoire *Weakness* — resolved differently depending upon **cardtype**。

| 维度 | 说明 |
|---|---|
| **Weakness** | 卡**子类型**（缺陷/诅咒/伤/敌人/故事线等）；与 asset/event/skill/**enemy/treachery** 等 **cardtype 正交** |
| **Revelation** | **能力类型**（**Revelation –**）；可在 encounter 牌、weakness、Dilemma 等上出现；**按 `has_revelation` 判定**，非 weakness 子类型 |

### 10.1 抽出结算 = 卡面能力（类型默认能力包）

Weakness 是子类型；**结算键是卡面能力体系**（类型给出默认包），不是抽牌来源重定向。见 [15 §17.6](15-timing-entry-catalog.md)。

| cardtype（默认能力包） | Grimoire 行为摘要 | 引擎 |
|---|---|---|
| **Enemy / Treachery / Location**（ENCOUNTER 包） | 遭遇侧能力；地点常显现入场 | `seq.encounter.resolve_card` |
| **Asset**（INVESTIGATOR 包） | Revelation（若有）→ **add to hand** → 作 asset | `seq.draw.investigator` D2–D3 + `seq.enter_hand` |
| **Event** | 同上 → 作 event | 同上 |
| **Skill** | 同上 → 作 skill | 同上 |

```text
卡面能力 / 类型默认包
  ├── ENEMY / TREACHERY / LOCATION → ENCOUNTER 包（揭示·险境·显现·spawn/discard/地点进场）
  ├── ASSET              → INVESTIGATOR 包 → hand → play asset
  ├── EVENT              → INVESTIGATOR 包 → hand → play event
  └── SKILL              → INVESTIGATOR 包 → hand → commit skill
Weakness 子类型只调 owner / bearer / 剧本残留，不另开管线
可抽遭遇类型 = 诡计 / 敌人 / 地点（前两者为遭遇库大宗）
```

### 10.2 与 Revelation / 无显现

| 情况 | Draw / 入手时 |
|---|---|
| Encounter cardtype weakness | **encounter** E2–E6；**非** 调查员 D3 enter_hand |
| Player cardtype weakness，**无** Revelation | D3 进 hand；**无** `seq.enter_hand` nest |
| Player cardtype（含 weakness），**有** Revelation | D3 `nest_batch seq.enter_hand`（[15 §16](15-timing-entry-catalog.md)） |
| 非 draw 入手（任意 weakness） | Grimoire *as if just drawn* → 上表对应管线 |
| Bearer |  scenario 中加入 deck/hand/threat **不占** deck size |

### 10.3 引擎判定（禁止混用）

```gdscript
## 路由只看 cardtype + is_weakness；勿写 if weakness: always encounter
func is_encounter_cardtype_weakness(def: CardDefinition) -> bool:
    return def.is_weakness and def.cardtype in [CardType.ENEMY, CardType.TREACHERY]

func is_player_cardtype_weakness(def: CardDefinition) -> bool:
    return def.is_weakness and def.cardtype in [CardType.ASSET, CardType.EVENT, CardType.SKILL]
```

**Invariant**：asset/event/skill weakness **永不** 调用 `seq.draw.encounter`（除非未来印刷 explicit 双类型 — 当前无）。

---

## 11. InvestigatorCampaignSystem API

```gdscript
class InvestigatorCampaignSystem:
    func create_investigator(def_id, player_id) -> StringName
    func apply_trauma_at_setup(record: CampaignInvestigatorRecord) -> void
    func mulligan(inv: StringName, cards_to_replace: Array) -> void
    func check_hand_size(inv: StringName) -> void
    func eliminate(inv: StringName, reason: EliminationReason) -> void
    func spend_xp_and_upgrade(record, purchases: Array) -> Result
    func validate_deck(record) -> Result
```

---

## 12. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| I-01 | Starter deck campaign start | 无 random basic weakness |
| I-02 | 4 trauma physical, health 7 | 第 4 场开始 3 damage — killed at 4th defeat? |
| I-03 | `NEW_PURCHASE` level 0 | cost **1** XP（min-1） |
| I-03b | `UPGRADE` L0→L1 | cost **1** XP（纯差额；非购新卡 min-1 谓词） |
| I-03c | `UPGRADE` L2→L4 | cost **2** XP；不计购新卡 |
| I-03d | 卡面「when you purchase」vs upgrade | 仅 `NEW_PURCHASE` 触发 purchase 谓词 |
| I-04 | Permanent Collector | +5 deck size |
| I-05 | Draw weakness in opening | set aside, redraw |
| I-06 | Resign 4 player | [per_investigator] still 4 |
| WKN-01 | Draw **asset** weakness w/ Revelation | D3 enter_hand；**非** encounter draw |
| WKN-02 | Draw **event** weakness no Revelation | hand only；no enter_hand nest |
| WKN-03 | Draw **enemy** weakness from deck | `seq.encounter.resolve_card`；spawn_engaged or discard_spawn_failed |
| WKN-04 | Draw **skill** weakness | D3 hand；可 commit 至检定 |

---

## 13. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-11-01 | P1 | Starter deck flag 是否 per-campaign 还是 per-investigator？ |
| OQ-11-02 | P1 | Bearer weakness 中途获得 — 是否立即 shuffle 进 deck 还是下一场？ |
| OQ-11-03 | P2 | Epic mode transfer — 电子版是否 v1 不实现？ |
| OQ-11-04 | P1 | Deck validation 非法 deck — 阻止开始 scenario 还是 warning？ |
| OQ-11-05 | P2 | Random basic weakness 池 — 按 product 还是 global 池？ |
| OQ-11-06 | P1 | Physical+mental trauma 同时导致 killed **and** insane 的 edge case？ |

---

## 14. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-06-18 | v0.2 | **§10** Weakness 全 cardtype 路由（asset/event/skill vs enemy/treachery）；WKN-01～04 |
| 2026-11-03 | v0.3 | **§7** Experience：FAQ 1.8 / 2026 RB 裁决 min-1 仅 `NEW_PURCHASE`；升级 ≠ 购新卡谓词；`XpSpendKind`；废「upgrade 差 min 1」旧稿 |
