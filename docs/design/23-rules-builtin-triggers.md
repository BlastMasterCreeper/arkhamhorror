# 23 — 基础规则自带触发（分类）

> **范围**：局面变化后规则必须自动发起的后果。  
> **不含**：混沌符号能力、关键词挂载、卡面 Forced / Reaction。  
> **判据**：[15 §4.0.5](15-timing-entry-catalog.md) — **达到时点 → 评估条件 → 满足则 nest**；内联 = 无因果时点的顺序 then；**同时** = 同一时间发生，全部完毕才轮到 After（[01 §5.3](01-game-state-zones.md)）。

---

## 1. 四分法

| 类 | 判据 | 做什么 |
|---|---|---|
| **nest 触发** | 时点已到，且条件满足 → 压独立结算 | `catalog.nest` 已有 `seq.*` |
| **内联 then** | 同一手续 RESOLVE 内连续步；**未**新开可听子时点 | handler / Composition then |
| **同时组** | 规则写 simultaneously；组内同一时间发生；**全部完**才 After | Domain / SimultaneousEffectGroup |
| **流程条件** | 框架步执行到此处才检查 | Framework 步内 `if` |

---

## 2. 清单（原 §1 触发式 · 重分）

| # | 规则后果 | 时点 | 条件 | 分类 | 落点 |
|---|---|---|---|---|---|
| 1 | **自动交战** | 同地点局面成立（生成 / 移入 / 重整后等） | 就绪、未交战；冷漠等为入口读限制 | **nest** | `seq.engage` mode=auto |
| 2 | **借机攻击** | Initiation **付完会引发借机的 cost 后**、主体效果前（INIT_2B） | 与就绪敌交战；行动类型会引发；无 `SKIP_AOO` | **nest** | 对该敌 `perform_attack` / 攻击体 |
| 3 | **击败**（伤/恐达上限） | 伤/恐写入后常态检测 | damage≥health / horror≥sanity | **nest** | `seq.effect.defeat` → 成功再 nest 退场 |
| 4 | **淘汰清理** | 调查员击败/撤退成功 | 主体为调查员 | **nest** 淘汰手续；清理项多为淘汰/离场的 **同时组** | elimination 路径 |
| 5 | **进未揭示地点 → 翻开+放线索** | 调查员 **进入** 该地点 | 地点未揭示 | **nest** | `seq.effect.reveal_location`（已落地） |
| 6 | 玩家库空还要抽 → 洗弃牌 + **1 恐** | 抽牌 collect（将抽） | 牌库空且弃牌非空 | **内联 then**（抽牌手续内条件分支；未另开子时点） | `seq.draw.investigator` collect |
| 7 | 遭遇库空还要抽 → 洗遭遇弃牌 | 遭遇抽牌 collect | 遭遇库空且弃牌非空 | **内联 then** | `seq.draw.encounter` E1 |
| 8 | 玩家库**与**弃牌皆空还要抽 → 击败 | 抽牌失败子时点 | 两堆皆空 | **nest** | `seq.draw.empty_piles_defeated` |
| 9 | Upkeep 手牌 > 8 → 弃到 8 | — | — | **流程条件**（非触发） | Framework 4.5 |
| 10 | Agenda doom ≥ 阈值 → 推进 | — | — | **流程条件**（非触发） | Framework 1.3 |
| 11 | 抽到敌人 → **生成**（默认交战生成；有 Spawn **指示**则按指示） | `ENCOUNTER_CARD_DRAWN` · G4 | enemy；Spawn 是**指示**（非能力）——有则改落点/是否 auto-engage，无则默认规则 | **nest** `seq.encounter.spawn`；指示只改手续内分支 | `spawn` / `spawn_engaged` |
| 12 | 抽到诡计 / 有显现 → 显现 | 入手 / 遭遇显现锚 | `has_revelation` | **nest** | `seq.encounter.revelation` / `seq.enter_hand` |
| 13 | Victory 敌击败 → 胜利区 | 击败成功后的退场去向 | 带 Victory | 退场/击败手续内 **去向分支**（非独立触发） | defeat leave 路由 |
| 14 | Lead 淘汰且仍有人 → 重选队长 | 淘汰同时组内 | 仍有调查员 | 淘汰 **同时组** 内步骤 | elimination |
| 15 | 无人剩余 → 场景结束 | 淘汰后 | 无剩余调查员 | 战役/场景结算（框架后） | guide |
| — | **token→pool、弃附属**（及 lasting 对该卡过期） | **广义移动**：卡从**场上区域 → 场外区域**（`seq.zone.move`） | **离场**（`LEAVE_PLAY` 过滤：was in-play ∧ now out） | 与该次移动列为 **同时组**（全部完才 After）；≠ 内联；≠「离场是时点」 | `ZoneMoveFlow` 在 `LEAVE_PLAY` 别名下捆绑 |

---

## 3. 曾存疑项（现钉）

| 项 | 旧犹豫 | 现裁决 |
|---|---|---|
| 进地点翻开+线索 | nest vs move 内联 | **nest**：时点=进入地点；条件=未揭示；结算=`reveal_location` |
| 借机 | 「手续砖」vs 触发 | **nest**：时点=付完引发借机的 cost 后；条件=交战就绪敌等；结算=攻击 |
| 空库洗+1 恐 / 遭遇洗回 | 内联？ | **内联 then**（抽牌 collect 条件分支）；双空 defeated 才 **nest** |
| Victory / Lead 重选 | 触发？ | **非独立触发**：退场去向 / 淘汰同时组内步骤 |
| 离场清理 | 曾误标「内联」；后又误把「离场」当时期 | **时点**=场上→场外区划移动；**条件**=离场（`LEAVE_PLAY`）；后果与该移动 **同时**；When/After「leaves play」同锚：听广义移动再过滤 |
| Spawn | — | **指示**（非能力）；有指示改生成分支，无则默认规则。#11 成立 |

---

## 4. 变更记录

| 日期 | 说明 |
|---|---|
| 2026-10-20 | 初稿：按时点→条件→nest 重分原「规则自带触发」清单；同时/流程条件/内联正交 |
| 2026-10-20 | 纠正：清理标记/附属的时点=场上→场外移动，离场是条件；Spawn=指示 |
