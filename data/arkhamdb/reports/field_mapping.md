# ArkhamDB → 引擎字段映射（草案）

> 详见 `data/arkhamdb/schema/card_schema.json`。数值哨兵：`-2`=X，`-3"=*，`-4"=?，`null`=-。

| ArkhamDB 字段 | 引擎 / CardRegistry | 说明 |
|---|---|---|
| `code` | `definition_id` / EntityId | 5 位 + 可选后缀；全局唯一 |
| `name` | `title` | 显示名 |
| `type_code` | `card_type` | act/agenda/asset/enemy/event/… → `CardDefinition.card_type` |
| `subtype_code` | `is_weakness` 等 | `basicweakness` / `weakness` → weakness 路由（15 §17.6） |
| `faction_code` | `class` / deckbuilding | 调查员/玩家牌派系 |
| `cost` | `resource_cost` | Initiation L6；注意哨兵值 |
| `slot` | `slots[]` | Hand / Arcane / … |
| `skill_*` / `skill_wild` | `skills_icons` | 技能图标 |
| `health` / `sanity` | ally 血量 | asset 专用 |
| `enemy_*` / `health`+damage | `enemy` stats | 敌人战斗数值 |
| `shroud` / `clues` | location | 地点调查 |
| `doom` / `clues` | act/agenda | 场景卡 |
| `traits` | `traits[]` | 句号分隔 trait 串 |
| `text` | 编译输入 | `[reaction]`/Forced/Revelation → AbilitySpec |
| `hidden` | `keywords: hidden` | 隐私 E4 |
| `victory` | scenario | 胜利点 |
| `permanent` | Domain 关键词 | 非 Buff；Permanent 离场规则 |
| `exceptional` | deckbuilding | 非运行时 |
| `encounter_code` | scenario 分组 | 遭遇套牌 |
| `stage` | act/agenda 序号 | |
| `pack_code` | 数据包归属 | 非运行时 |
| `tags` | 特殊 deckbuilding | hh/hd/pa/se/fa（见 upstream README） |

## 能力文本 → 引擎路由（06 §2 / effect-translation）

| 卡面标记 | AbilityKind / 路由 | Initiation? |
|---|---|---|
| `<b>Revelation</b>` | REVELATION → `seq.enter_hand` / encounter revelation | 否（Forced 直执） |
| `<b>Forced</b>` | FORCED | **否**（自动，不经 Initiation） |
| `[reaction]` / `[action]` / `[fast]` | TRIGGERED_* | **是**（选用后 Initiation） |
| `[action]` on asset | `[action]` + AOO | Initiation + action_cost |
| `[fast]` | Fast 关键词 + 指定 window | Initiation 或 Player Window |
| Spawn – / Prey – | `spawn_instruction` / `prey_instruction` | 否（G4 内联） |
| Surge / Peril / Aloof… | 关键词 LISTENER 或 seq | 见 15 §17 |
