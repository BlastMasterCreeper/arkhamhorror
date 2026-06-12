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
- Eliminated from scenario，**不**改 🕣 count

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

## 10. Weakness 分流

| 类型 | Draw 时 |
|---|---|
| Encounter cardtype weakness | 当 encounter draw resolve |
| Player cardtype weakness | Revelation → hand；非 draw 进 hand 也当 draw resolve |
| Bearer | 加入 deck 不占 size |

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
| I-06 | Resign 4 player | 🕣 still 4 |

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
