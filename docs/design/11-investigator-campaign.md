# 11 — 调查员、牌组与战役 (InvestigatorCampaignSystem)

> **依赖**：[01-game-state-zones.md](01-game-state-zones.md), [07-effect-resolution.md](07-effect-resolution.md)  
> **规则来源**：Grimoire Deckbuilding, Campaign Play, Trauma, Experience, Weakness, Slots

---

## 1. 目标

管理 **Investigator 运行时状态**、槽位、牌组操作、淘汰/辞职、战役 Trauma/XP/Deckbuilding、Standalone/Epic 模式。

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

## 6. 战役状态 CampaignState

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

Scenario 后：

```
1. XP = victory display + guide bonuses + unspent
2. Purchase：level cost min 1；upgrade 付 level 差 min 1
3. 每加 1 卡（非 Permanent）移除 1 卡；maintain deck size
4. 遵守 deckbuilding options；weakness/required 不可移除
5. Record unspent XP
```

| 关键词 | 规则 |
|---|---|
| Permanent | deck creation only；不计 deck size |
| Exceptional | 2× XP cost；max 1 copy by title |
| Reward | 解锁后可用；golden corner |
| Bearer | 忽略 deckbuilding；不计 deck size |

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

### 10.1 按 cardtype 的 Weakness 路由

| Weakness cardtype | Grimoire 行为摘要 | 引擎管线 |
|---|---|---|
| **Enemy / Treachery** | as if drawn from **encounter deck** | `seq.draw.encounter.resolve_bound`（[15 §17.6](15-timing-entry-catalog.md)） |
| **Asset** | Revelation（若有）→ **add to hand** → 作 asset 使用 | `seq.draw.investigator` D2–D3 + `seq.enter_hand` |
| **Event** | 同上 → 作 event 使用 | 同上 |
| **Skill** | 同上 → 作 skill 使用 | 同上 |

```text
Weakness 子类型          Cardtype 轴
     │                    ├── ENEMY / TREACHERY  → 遭遇 draw 管线
     │                    ├── ASSET              → 调查员 draw → hand → play asset
     └─ (flaw/story…)     ├── EVENT              → 调查员 draw → hand → play event
                          └── SKILL              → 调查员 draw → hand → commit skill
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
| I-03 | Purchase level 0 card | cost 1 XP |
| I-04 | Permanent Collector | +5 deck size |
| I-05 | Draw weakness in opening | set aside, redraw |
| I-06 | Resign 4 player | [per_investigator] still 4 |
| WKN-01 | Draw **asset** weakness w/ Revelation | D3 enter_hand；**非** encounter draw |
| WKN-02 | Draw **event** weakness no Revelation | hand only；no enter_hand nest |
| WKN-03 | Draw **enemy** weakness from deck | `resolve_bound`；spawn_engaged or discard_spawn_failed |
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
