# Limit / Max · 全量 ArkhamDB 搜集与分类

数据源：[Kamalisk/arkhamdb-json-data](https://github.com/Kamalisk/arkhamdb-json-data) 全量 `pack/**/*.json`（临时克隆分析，未把全库入库）。
命中：**670** 张；漏抽：**15**。

> 仅 Core 2026（26 张）不够定规格；以全量为准。

## 0. 落地状态（2026-10-29）

| 项 | 状态 |
|---|---|
| `LimitSpec` / 枚举（`AhcEnums.Limit*`） | ✅ |
| `LimitTracker`（initiate 计数 + occupancy 现读 + ignore） | ✅ |
| Initiation L5：`intent.limits` → `can_initiate` / `INIT_3_COMMENCE` 记账 | ✅ |
| 入区：`occupancy_limits` / `CardRegistry.limit_specs` · PLAY 预检 | ✅ |
| `InterruptTarget.LIMIT` → ignore | ✅ |
| 括号句 `try_parse_paren_clause`（once per turn/round/phase/game · Group） | ✅ |
| USE_QUOTA / EVENT_QUOTA / COMMIT_MAX 运行时 | ⬜ 下一批 |
| ArkhamDB 编译器自动挂 `LimitSpec` | ⬜ 下一批 |
| StatProjection / EventRecord 重建计数 | ⬜（竖切为增量计数） |

## 1. 五族规模

| 族 | 卡数 | 门槛 |
|---|---|---|
| **A** 发起/使用/事件配额 | 459 | L5 / 使用点 / 计量事件 |
| **B** 投入 Max | 45 | Commit 有效性 |
| **C** 占位（区域·附着·beneath·trait） | 112 | 入区/附着有效性 |
| **D** 构筑 | 58 | 牌组构建 |
| **E** 缩放封顶 | 15 | 效果参数钳制（非 LimitSpec） |
| **X** 未归 | 0 | — |

## 2. 子型

| n | key | 例 |
|---|---|---|
| 237 | `A/use_or_initiate` | `13008` Water Street: (Limit once per turn.) |
| 215 | `A/group` | `13042` Loading Dock: (Group limit once per game.) |
| 59 | `C/per_investigator` | `13065` Echoing in Darkness: Limit 1 per investigator |
| 58 | `D/per_deck` | `13118` The Blood Blight: Limit 1 per deck |
| 45 | `B/committed_per_test` | `01089` Guts: Max 1 committed per skill test |
| 15 | `C/per_location` | `12157` Arcane Lock: Limit 1 per location |
| 12 | `C/in_play` | `08027` Combat Training: Limit 1 [[Composure]] in play |
| 10 | `E/paren_max` | `02333` Vast Expanse: (max 5) |
| 7 | `C/attached` | `08089` Quickdraw Holster: (Limit 1 attached asset.) |
| 7 | `C/per_asset` | `10028` Tinker: Limit 1 per asset |
| 5 | `A/event_meter` | `90084` Jenny Barnes: (Limit 5 resources per round.) |
| 5 | `C/beneath` | `98019` Gloria Goldberg: (max 3 cards beneath her) |
| 5 | `E/to_a_maximum` | `10029` Purified: to a maximum of 5 |
| 3 | `A/max_per` | `08079` Blood Will Have Blood: Max 1 per attack |
| 2 | `A/per_each_investigator` | `03002` Minh Thi Phan: (Limit once for each investigator per round.) |
| 2 | `C/attached_capacity` | `08067` Astronomical Atlas: (max 5 cards attached) |
| 2 | `C/per_agenda_act` | `02085` Light of Aforgomon: Limit 1 per agenda/act |
| 2 | `C/per_enemy` | `11516` End of Negotiations: Limit 1 per enemy |
| 1 | `C/token_per_location` | `09614` If It Bleeds...: (Limit 1 scouting report per [[Wilderness]] location.) |

## 3. 高频短语 Top 25

| n | phrase |
|---|---|
| 113 | `(Group limit once per game.)` |
| 94 | `(Limit once per round.)` |
| 56 | `(Group limit once per round.)` |
| 45 | `Limit 1 per investigator` |
| 45 | `Limit 1 per deck` |
| 44 | `(Limit once per game.)` |
| 42 | `Max 1 committed per skill test` |
| 32 | `(Limit once per turn.)` |
| 27 | `(Limit once per test.)` |
| 23 | `(Group limit once per game)` |
| 14 | `(Limit once per phase.)` |
| 12 | `Limit 1 per location` |
| 11 | `Limit 1 [[Mask]] per investigator` |
| 10 | `Limit 1 [[Composure]] in play` |
| 10 | `(Limit once per game for each vehicle.)` |
| 9 | `(max 5)` |
| 7 | `Limit 1 per asset` |
| 5 | `Limit 1 [[Covenant]] per deck` |
| 4 | `(Group limit once per phase.)` |
| 3 | `Limit 1 [[Footwear]] per investigator` |
| 3 | `Limit 1 [[Trap]] per location` |
| 3 | `(Limit once per round)` |
| 3 | `(Group limit twice per game.)` |
| 3 | `Max 1 committed per test` |
| 3 | `(Limit 1 success per game.)` |

## 4. 相对 Core 2026 必须扩的规格点

| 形态 | 族 | 规格 |
|---|---|---|
| once/twice/N · turn/round/phase/game/test | A | `amount` + `period`（含 PHASE/SKILL_TEST） |
| Group limit · campaign/act/location/vehicle/depth | A | `audience=GROUP` + `anchor` |
| success / resources per period | A | `EVENT_QUOTA` |
| N times per attack/investigation | A | `USE_QUOTA` + 行动作用域 |
| Max N per game/turn/attack | A | `audience=TITLE` |
| once per asset / each investigator | A | 按实例或目标调查员 |
| Limit N **[[Trait]]** per investigator/location/in play | C | `match=BY_TRAIT` |
| per asset/enemy/agenda·act；attached；beneath；in play | C | `zone` 扩枚举 |
| Limit N per deck | D | 构筑 |
| (Max N) / to a maximum of N | E | 不进 LimitSpec |

## 5. 裁决

1. **不进** Registration payload；**不衍生 GATE**；独特 ≠ Limit。
2. 统一 `LimitSpec`；到门槛现读。
3. A 计量事件不限于 `ABILITY_COMMENCED`（另有 use-within-scope / success / resource_gain）。
4. C 匹配 ⊆ {by title, by trait}；区域含 play/threat、location、in play、attached、beneath。
5. Ignore → `InterruptTarget.LIMIT`。

### LimitSpec 草图

```gdscript
enum LimitKind { INITIATE_QUOTA, USE_QUOTA, EVENT_QUOTA, COMMIT_MAX, ZONE_OCCUPANCY, DECKBUILDING }
enum LimitPeriod { NONE, TURN, ROUND, PHASE, GAME, CAMPAIGN, SKILL_TEST, ATTACK, INVESTIGATION, ACT, LOCATION, CUSTOM_ANCHOR }
enum LimitAudience { PLAYER, GROUP, TITLE, PER_TARGET_INVESTIGATOR, PER_ASSET_INSTANCE, PER_ANCHOR }
enum OccupancyMatch { BY_TITLE, BY_TRAIT }
enum ZoneConstraint {
    NONE, PER_INVESTIGATOR, PER_LOCATION, IN_PLAY, PER_DECK,
    PER_ASSET, PER_ENEMY, PER_AGENDA_ACT, ATTACHED, BENEATH, VICTORY_DISPLAY,
}

class LimitSpec:
    var kind: LimitKind
    var amount: int
    var period: LimitPeriod
    var audience: LimitAudience
    var zone: ZoneConstraint
    var match: OccupancyMatch
    var trait: StringName
    var event_key: StringName
    var anchor_key: StringName
```

## 6. 变更记录

| 日期 | 说明 |
|---|---|
| 2026-10-29 | 竖切落地：LimitTracker + Initiation L5 + occupancy + Ignore LIMIT；测试 LIM-01…05 |
| 2026-10-29 | 全量 pack 搜集；扩 A/C 与 LimitSpec |
| 2026-10-29 | 初版仅 Core 2026 |

## 附录 · 仍漏抽

| code | name | snip |
|---|---|---|
| `05279` | Dayana Esperence | Uses (3 secrets). \| [fast]: Attach a non-weakness [[Spell]] event from your hand to Dayana Esperence |
| `05233` | Investments | Uses (0 supplies). Limit 10 supplies on Investments. \| [fast] Exhaust Investments: Place 1 supply on |
| `04204` | Ornate Bow | Uses (1 ammo). Limit 1 ammo on Ornate Bow. \| [action] Spend 1 ammo: <b>Fight.</b> This attack uses [ |
| `04031` | Protective Incantation | Group limit 2 copies of Protective Incantation in play. \| Seal (any except [auto_fail]). \| <b>Forced |
| `07211a` | Thomas Dawson's Car | Vehicle. Limit 2 investigators in this vehicle. \| This vehicle is running. Investigators cannot ente |
| `07211b` | Thomas Dawson's Car | Vehicle. Limit 2 investigators in this vehicle. \| This vehicle is stopped. \| [action] If you are thi |
| `07212a` | Elina Harper's Car | Vehicle. Limit 2 investigators in this vehicle. \| This vehicle is running. Investigators cannot ente |
| `07212b` | Elina Harper's Car | Vehicle. Limit 2 investigators in this vehicle. \| This vehicle is stopped. \| [action] If you are thi |
| `09006` | On the Mend | Limit 1 On the Mend in your hand. \| Commit only to a test you are performing. \| <b>Forced</b> - When |
| `09106` | Making Preparations | Max 2 [[Dilemma]] per round. \| <b>Revelation</b> - Choose two skills ([willpower], [intellect], [com |
| `09107` | Predator or Prey | Max 2 [[Dilemma]] per round. \| <b>Revelation</b> - If there are no enemies in play, draw 1 card. Oth |
| `09109` | At a Crossroads | Max 2 [[Dilemma]] per round. \| <b>Revelation</b> - Choose an investigator and decide (choose one): \| |
| `09111` | Nature of the Beast | Max 2 [[Dilemma]] per round. \| <b>Revelation</b> - Reveal the top 3 cards of the encounter deck. Cho |
| `09115` | Heed the Dream | Max 2 [[Dilemma]] per round. \| <b>Revelation</b> - Reveal the top card from each investigator's deck |
| `09118` | Fickle Fortune | Max 2 [[Dilemma]] per round. \| <b>Revelation</b> - You must decide (choose one): \| - Place 1 doom on |