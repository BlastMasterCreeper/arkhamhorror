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

## 3. Reveal 流程

触发：

- Investigator **enters** unrevealed location（含 Move、Spawn 到该地点、Setup 放置）
- 卡牌能力 instruct reveal

```
1. Flip to revealed side
2. clues = clue_value × per_investigator_multiplier（[per_investigator]）
3. Place clues from token pool onto location
4. 应用连接变化（若 revealed 面修改 connections）
5. Trigger Forced/enter play effects
```

Setup 时 investigator  placed at location → **算 enter** → reveal + clues（Grimoire Clues）。

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

```gdscript
class LocationGraph:
    func move_investigator(inv: StringName, dest: EntityId) -> Result:
        # leave + enter simultaneous
        # unrevealed dest → reveal
        # auto engage ready enemies at dest
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
| L-01 | 4 player, clue [per_investigator]2 | 8 clues placed |
| L-02 | Move to unrevealed | reveal + clues |
| L-03 | Setup start at unrevealed | reveal at setup |
| L-04 | Resign 后 [per_investigator] 不变 | act threshold 仍 ×4 |
| L-05 | Haunted fail investigate | Haunted resolves |
| L-06 | Connection 单向 | 不能反向 Move |

---

## 11. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-09-01 | P1 | Setup 放置 vs Move enter：是否统一 `enter_location()` 单入口？ |
| OQ-09-02 | P2 | 同 title 多 copy location（罕见）— 仍算 different locations — 如何 instance 化？ |
| OQ-09-03 | P1 | Reveal 后 shroud/clue 动态修改（能力）— 已放置 clue 是否重算？ |
| OQ-09-04 | P2 | Farthest location 计算：blocked path 是否参与？ |
| OQ-09-05 | P1 | Your Friend's Room [action] Engage 跨连接 — Move enemy + engage 是否 provoke AOO？（文本说不） |
| OQ-09-06 | P2 | Location enter play already revealed — clues 在 setup 还是 enter 时放？ |

---

## 12. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
