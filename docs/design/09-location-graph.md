# 09 — 地点、地图与线索 (LocationGraph)

> **依赖**：[01-game-state-zones.md](01-game-state-zones.md)  
> **规则来源**：Grimoire Location Cards, Clues, Empty Location, Move

---

## 1. 目标

维护 **地点连接图**、Reveal 流程、线索放置与发现、Victory location 条件。

---

## 2. LocationGraph 结构

```gdscript
class LocationGraph:
    var nodes: Dictionary[EntityId, LocationState]

    func add_location(def: LocationDefinition, revealed: bool) -> EntityId
    func connect(a: EntityId, b: EntityId, directed: bool = false) -> void
    func disconnect(a: EntityId, b: EntityId) -> void
    func get_connections(loc: EntityId) -> Array[EntityId]
    func shortest_path(from: EntityId, to: EntityId) -> Array[EntityId]
    func farthest_from_all_investigators(candidates: Array[EntityId]) -> EntityId
```

**电子版**：维护显式 **edge 列表**（connector token 仅为 UI 辅助）；支持 setup 后 **连接变化**（锁门、单向）。

```gdscript
class LocationState:
    var id: EntityId
    var definition_id: StringName
    var revealed: bool
    var shroud: int              # 仅 revealed 有效
    var clue_value: int          # 印刷值；实际放置用 per_investigator 计算
    var clues_on_location: int
    var victory_value: int
    var haunted_abilities: Array[AbilityDefinition]
    var enemies_present: Array[EntityId]
```

---

## 3. Reveal 流程（规则自带 · 已落地）

触发（**不是**关键词、**不是**卡面 Forced）：

- 调查员 **进入** 未揭示地点（`seq.effect.move` / 行动移动 → `LocationEnterRules.on_investigator_enter`）
- Setup / 进场已揭示布局（starting location、`put_location_into_play`、遭遇抽到地点）→ 直接 `reveal_and_place_clues`
- 卡牌能力 instruct reveal → nest `seq.effect.reveal_location`

```
1. Flip to revealed side（LocationState.revealed）
2. clues = printed_clues × per_investigator_count（dash / -1 → 0）
3. Place onto location（`loc.clues`）
4. （后续）连接变化 / Forced — 未竖切
```

实现：`LocationEnterRules` + Catalog `seq.effect.reveal_location`。已揭示再进入 **不**再放线索。

---

## 4. 线索（Clues）

| 操作 | 规则 |
|---|---|
| Discover | 成功 investigate 或能力；clue 从 location → investigator 卡 |
| Spend (advance act) | group spend from investigator cards |
| Place on location | from pool 或能力 |
| Investigator defeated | clues on investigator → current location |
| 「Clues on location」 | undiscovered tokens on card |

---

## 5. Per Investigator ([per_investigator])

```gdscript
func per_investigator(base: int) -> int:
    return base * game.per_investigator_count
```

`per_investigator_count`：**开局调查员数**，含已淘汰/resigned（Grimoire）。Elimination 不改变此值。

---

## 6. Move 集成

**狭义地点变更**走统一 `seq.effect.move`（`subject` + `move_kind`）：  
- **移动**（`move`）遵守地点连接；**移动到地点**（`move_to`）无视连接。  
**广义转移**与 **地点交换** **不**并入 — 见 [22 §3.4](22-seq-granularity.md)。

```gdscript
class LocationGraph:
    func move_entity(subject: StringName, id: StringName, dest: EntityId, move_kind: StringName) -> Result:
        # leave + enter simultaneous · seq.effect.move
        # move: along connections; move_to: ignore connections
```

---

## 7. Haunted

Location 含 Haunted –：investigator **fail** investigate test at this location → after ST.7 resolve all Haunted abilities on location。

---

## 8. Empty Location

无 investigators 且无 enemies（Grimoire Empty Location）。

---

## 9. Victory Location

Scenario end：in play, revealed, no clues on location, victory X → victory display → XP。

---

## 10. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| L-01 | 2 investigator, printed 2 | 4 clues placed |
| L-02 | Move to unrevealed | reveal + clues |
| L-02b | Re-enter revealed | 不再放线索 |
| L-02c | Enemy move to unrevealed | **不**翻开 |
| L-03 | Setup start at unrevealed | reveal at setup |
| L-04 | Resign 后 [per_investigator] 不变 | act threshold 仍 ×4 |
| L-05 | Haunted fail investigate | Haunted resolves |
| L-06 | Connection 单向 | 不能反向 Move |

---

## 11. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-09-01 | P1 | ~~Setup vs Move enter 单入口？~~ → **统一** `LocationEnterRules` / `seq.effect.reveal_location`；Move 走 `on_investigator_enter`；setup 已揭示直跑 `reveal_and_place_clues`。 |
| OQ-09-02 | P2 | 同 title 多 copy location（罕见）— 仍算 different locations — 如何 instance 化？ |
| OQ-09-03 | P1 | Reveal 后 shroud/clue 动态修改（能力）— 已放置 clue 是否重算？ |
| OQ-09-04 | P2 | Farthest location 计算：blocked path 是否参与？ |
| OQ-09-05 | P1 | Your Friend's Room [action] Engage 跨连接 — 文本不借机 → ✅ 限制类 `SKIP_AOO`，INIT_2B 原流程读取分支 |
| OQ-09-06 | P2 | Location enter play already revealed — clues 在 setup 还是 enter 时放？ |

---

## 12. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-10-19 | v0.2 | §3 落地：进入未揭示翻开 + 首次放线索；`LocationEnterRules`；L-02/L-01 竖切；裁决 OQ-09-01 |
