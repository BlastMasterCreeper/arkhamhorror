# 22 — 命名流程粒度审计（相对 Grimoire 章节）

> **依赖**：[17-seq-runtime §1.1](17-seq-runtime.md)、[07-composition §1.3.3](07-composition.md)、[15-timing-entry-catalog](15-timing-entry-catalog.md)、[00-framework-step-index](00-framework-step-index.md)、Grimoire v1.0 Glossary  
> **状态**：草案 · 待确认 · 2026-10-10  
> **目的**：在「按卡填精细参数」之前，先钉死 **哪些手续该是一条 `seq.*`、哪些该进 params、哪些不铸**。

---

## 1. 裁决原则（沿用 + 补一条敏感度）

已有（17 §1.1 / 07 §1.3.3）：

1. **按魔典章节 / 词条** 定 `flow_id` 前缀与种类。
2. **`seq.*` 只做时点切分**；条件 / 视角 / 数量 / 区域 → **params**（及 Eligibility）。
3. **铸造判据**：可 CREATED 的效果种类 + 可能被 Would/When/After 听到或跨卡复用。
4. **铸造 ≠ nest**；框架步与卡面效果可同名因果但 **不同手续**（如 mythos doom vs 卡面 place doom）。

补（本轮讨论）：

5. **敏感度**：并得越宽，订该 `sequence_id` 的能力被 **枚举/试探** 的次数越多；必须用 **params / tags / ApplicationContext** 做第二道门槛，否则空转。若过滤成本高于多铸一条，或订阅语义 **必须** 靠不同 `sequence_id` 表达 → **拆**。

```text
固有（铸一条）     = Grimoire 词条级「可被听到的因果种类」
参数（不铸）       = amount / skill / kind / from / target / mode / …
不铸              = 单卡段落、控制流、L0 碎步、父管线服务砖（险境 Register…）
```

---

## 2. 前缀分类（目标 taxonomy）

| 前缀 | 对应 | 例 |
|---|---|---|
| `seq.framework.*` / `seq.mythos.*` / `seq.agenda.*` / `seq.act.*` | Framework / 密谋·场景 | `seq.mythos.place_doom` |
| `seq.draw.*` | Drawing Cards（调查员 / 遭遇） | `seq.draw.investigator` |
| `seq.encounter.*` | 遭遇卡结算 nest 体 | `seq.encounter.revelation` |
| `seq.enter_hand` | 入手显现入口（跨来源） | NEST_BATCH |
| `seq.skill_test` | Skill Test Timing | 一条 + `params.skill` |
| `seq.action.*` | 基本/指定行动 **外壳**（耗 action、AOO） | `seq.action.fight` |
| `seq.enemy.*` | 敌人手续（移动 / 攻击 / 击败…） | `seq.enemy.attack` |
| `seq.effect.*` | 纸面无名但可解释的效果种类 | `seq.effect.deal` |
| `seq.keyword.*` | 关键词 **开火**（非创建） | `seq.keyword.surge` |
| `seq.interrupt.*` / `seq.replace.*` | Cancel / Ignore / Instead | 共享 |
| `seq.ability.resolve` | Initiation 装载帧（禁真空） | — |

**命名债**：

| 现状 | 状态 |
|---|---|
| ~~`seq.gain_resource`~~ | **已删** → 仅 `seq.effect.gain_resource` |
| `seq.engage` | **保留根 id**；仅 `auto`/`effect`（行动=效果交战）；见 §3.4 / M5 |

---

## 3. 现有 Catalog 对照表

### 3.1 抽牌 / 入手 / 显现

| flow_id | Grimoire | 粒度裁决（草案） |
|---|---|---|
| `seq.draw.investigator` | Drawing Cards（玩家库） | **保留**：词条内核 |
| `seq.action.draw` | Draw Action | **保留**：行动外壳 → Delegate 内核（OQ-SEQ-02：不同 RUN） |
| `seq.draw.encounter` | Drawing encounter / 1.4 | **保留** |
| ~~`seq.draw.encounter.resolve_bound`~~ | （已废）重定向 | **删除** → `seq.encounter.resolve_card`（卡面能力包；非来源重定向） |
| `seq.encounter.resolve_card` | 已持有实例 → 遭遇侧能力体系 | **保留**：与抽遭遇后结算同体 |
| `seq.draw.empty_piles_defeated` | 空库+空弃 → defeated | **保留**：因果 nest 子手续 |
| `seq.enter_hand` | Revelation @ 入手 | **保留**：跨 draw/add 共用入口 |
| `seq.encounter.revelation` | Revelation（遭遇帧 E4） | **保留**：与 `enter_hand` 分源（遭遇 vs 玩家入手） |
| `seq.encounter.spawn` | Spawn / G4 enemy | **保留**：与 treachery discard 同档不同支 |
| `seq.keyword.surge` | Surge（延时再抽） | **保留**：开火 ≠ 创建 |

### 3.2 检定 / 行动外壳

| flow_id | Grimoire | 粒度裁决（草案） |
|---|---|---|
| `seq.skill_test` | Skill Test Timing | **保留一条**；`skill`/`difficulty` 参数 |
| `seq.action.{move,investigate,fight,engage,evade,gain_resource}` | Basic / designated actions | **保留外壳**；内核另 nest |
| `seq.action.draw` | 同上 | 见上 |

### 3.3 效果种类 `seq.effect.*`

| flow_id | Grimoire 词条 | 粒度裁决（草案） |
|---|---|---|
| `seq.effect.deal.assignable` | Dealing Damage/Horror（待分配） | 伤+恐可同入参；Assign 后同时 Apply |
| `seq.effect.deal` | Dealing Damage/Horror（无分配） | 已定；伤+恐用 Simultaneous；**无** Assign |
| `seq.effect.heal` | Heal | **保留** |
| `seq.effect.lose_resources` | （失去资源） | **保留**；`all` 参数 |
| `seq.effect.lose_action` | （失去行动） | **保留** |
| `seq.effect.discover_clue` | Clues / discover | **保留**；多地 `legs[]`（一帧；L0 单目标） |
| `seq.effect.place_clue` | 线索放到地点 | **保留**（与 discover 因果不同） |
| `seq.effect.place_doom` | Doom（卡面放置） | **保留**；**勿**并入 mythos |
| `seq.effect.discard_card` | Discard | **已统一**；`from=hand` / `card_id` / 寻址 |
| `seq.effect.attach` | Attach To | **保留** |
| `seq.effect.resign` | Resign | **保留** |
| `seq.effect.register` / `unregister` | lasting / Cannot / keyword 标记创建 | **保留**；勿为每个 keyword 开创建 seq |
| `seq.effect.gain_resource` | Gain resources | **已迁**；旧根 id 已删 |
| `seq.effect.evade` | Evade（效果） | **已铸**；横置+解除交战；`mode` attempt\|automatic；卡面**执行**=自动躲避；「evade」措辞多用于时点 |
| `seq.effect.search` | Search | **已铸**；见 G3 |
| `seq.effect.exhaust` / `ready` | Exhaust / Ready | **已铸**；见 G2 |
| `seq.effect.move` | Move（狭义） | **已铸**；见 G1 |
| `seq.effect.defeat` | Defeat | **已铸**；见 G5 |
| `seq.effect.reveal_location` | Reveal location + 首次放线索 | **已铸**；进入未揭示地点 nest（`LocationEnterRules`） |
| `seq.effect.seal` / `release_seal` | Seal Domain | **已铸**；混乱袋封印 / 释放（见 [05](05-chaos-bag.md)） |

### 3.4 敌军阶段 / 敌人 / 交战

**敌军阶段 III 本身有基础流程**（[00](00-framework-step-index.md) / Grimoire pp.29），**不是**「只靠关键词 LISTENER 撑起来的空壳」：

```text
3.1 ENEMY_3_1_PHASE_BEGINS          阶段开始（形式化）
3.2 ENEMY_3_2_HUNTER_PATROL_MOVE    → seq.enemy.3_2（见下）
      └─ PW_ENEMY_AFTER_MOVE
3.3 ENEMY_3_3_ENGAGED_ATTACKS       → seq.enemy.phase_attacks（按玩家顺序）
      └─ PW_ENEMY_BETWEEN_ATTACKS（每位之间）
3.4 ENEMY_3_4_PHASE_ENDS            阶段结束（形式化）
```

**3.2 框架步基础手续**（`seq.enemy.3_2` · **不含**关键词移动路径）：

1. 枚举 **ready、未交战** 的敌人  
2. 对每个敌人打开关键词消费槽 `ENEMY_3_2`（KeywordConsumer → nest `seq.keyword.*`）  
3. 步末玩家窗口  

**关键词部分已摘出**：

| 开火 seq | 职责 |
|---|---|
| `seq.keyword.hunter` | Hunter 移动体（最近调查员 1 步） |
| `seq.keyword.patrol` | Patrol 移动体（向括号目标 1 步） |

禁止再铸 `seq.enemy.3_2_hunter_patrol` / `3_2_patrol`（那是把关键词写回框架）。

挂载 / 开火锚 / `fire_priority` 总表 → [06 §3.2.7](06-registration-buff-model.md#327-关键词监听挂载时点--开火锚--优先级已裁决)（Hunter 10 先于 Patrol 20）。

| flow_id | Grimoire | 粒度裁决（草案） |
|---|---|---|
| ~~`seq.enemy.move`~~ | Move（敌人） | **已并并删别名** → `seq.effect.move`（`subject=enemy`） |
| `seq.enemy.3_2_hunter_patrol` | （误铸） | **删除** → 见 §4 M2 |
| `seq.enemy.3_2_patrol` | （误铸） | **删除** → 见 §4 M2 |
| `seq.enemy.3_2` | Framework **3.2** 基础手续 | **已收口**：枚举 + `ENEMY_3_2` 消费槽；**不含**移动路径 |
| `seq.keyword.hunter` | Hunter 开火 | **已铸**：从 3.2 摘出的移动体 |
| `seq.keyword.patrol` | Patrol 开火 | **已铸**：从 3.2 摘出的移动体 |
| `seq.enemy.attack` | Enemy attack | **保留**：单次攻击结算 |
| `seq.enemy.phase_attacks` | 3.3 Engaged attacks | **已收口**：固定手续；nest `seq.enemy.attack` |
| `seq.enemy.massive_phase_attacks` | （误铸） | **删除** |
| `seq.keyword.massive` | Massive REPLACE 体 | **已铸**：替换 `seq.enemy.attack`（PHASE→batch） |
| ~~`seq.enemy.defeat`~~ | Defeat（敌人） | **已并并删别名** → `seq.effect.defeat`；敌主体 TC.kind=`enemy_defeated` |
| `seq.enemy.resolve_location` | Prey / 地点解析辅助 | **保留或降为内部**（若无独立订阅需求） |
| `seq.engage` | Engage（交战） | **扩展内核**：见下「交战 params」；外壳 `seq.action.engage` nest 本条 |
| `seq.effect.move` | 狭义 Move | **统一核**：`subject` = investigator / enemy / attachment / marker |

**移动三分（已裁决）**

| 种类 | 含义 | 是否本阶段命名流程 |
|---|---|---|
| **狭义地点变更** | 已位于地点的调查员 / 敌人 / 地点附属 / 标记，从当前地点到新地点 | **是**：统一 `seq.effect.move` |
| ├ **移动** | 须沿地点连接 | `move_kind=move`（默认行动 / Hunter / Patrol / Elusive / `nest_enemy_move_to`） |
| └ **移动到地点** | 无视连接，一次落到目标 | `move_kind=move_to`（`move_enemy_to` / 附属·标记卡面常见） |
| **广义「移动」** | 场内外任意区域之间的转移（弃牌、入手、进场/离场…） | **否** — **不**并入 `seq.effect.move`；**已铸** `seq.zone.move`（L0 `move_card` 成功后）；见下「进场」 |
| **地点交换** | 两地点上实体互换位置（如 Ethereal Slip） | **否** — 原子；**不可 nest**；**不触发**狭义移动时点 |

同核 params（仅狭义）：`subject` + `move_kind`（+ 敌 `mode` toward/direct 仅在 `move` 下）。订阅用 tags 过滤。

**进场（Enter play · 已裁决）**

| | |
|---|---|
| **是什么** | **信息**：某次**广义移动**的结果满足「源 = 场外、目标 = 场上」 |
| **不是什么** | **不是效果**；**不铸** `seq.effect.enter_play`；**不另开**进场专用监听通道 |
| **怎么听** | 听**广义移动**（`seq.zone.move` · L0 `move_card` / `notify_zone_set`）；用谓词过滤场外→场上。`AT_ENTER_PLAY` / `ENTER_PLAY` / after enters play = 该过滤的**别名**，不是第二套 emit |
| **与 Spawn / 打出** | 手续里做广义移动；进场只是结果信息。离场 = 对称过滤（场上→场外） |
| **翻译注意** | 卡面「弃置 / 放入场 / 移出游戏 / 入手…」等措辞 = **区划转移序列**，落地为 L0 写入（可被 `seq.zone.move` 听到）；**勿**另铸进场效果 seq，也**勿**为去向加时点 facade |

**击败（Defeat · 已裁决）**

| | |
|---|---|
| **是什么** | **明确的效果**（可 Cancel / 可被听到）——**大信封**：击败效果体 **包含** 退场（区划转移），不是「空壳再另起后续」 |
| **不是什么** | 不是「仅宣告、无内容」；也不是把退场误当成与击败无关的第二套效果。退场 **是** 击败信封内的主体结算，经 **nest** 打开场上→场外移动时点 |
| **产生途径** | ① **伤害 / 恐惧** 达到该卡生命 / 神智上限（**常态检测**，同交战一类）；② 卡面 / 效果直接 **击败** |
| **主体** | 敌人 / 调查员 / **支援资产**（`subject=asset`） |
| **效果体** | resolve 成功 → **nest** `seq.defeat.leave_play`（广义移动 · 离场条件 · 去向指示）。**禁止**把退场内联进击败叶 |
| **可被击败** | 有生命/神智的主体：调查员、支援、敌人（**敌人-地点** 后议） |
| **退场去向** | 见下表；Victory/复仇 = **去向指示**（同 Spawn），优先于默认堆 |
| **Cancel** | Cancel **整封击败** → 信封内退场不执行。① 伤/恐路径可再触；② 纯效果击败不自动重触 |

**击败退场去向（默认；指示可改）**

| 主体 | 默认去向 | 备注 |
|---|---|---|
| 调查员 | 淘汰（退场 / elimination） | 信封内走 `InvestigatorElimination` |
| 玩家支援 | **所有者弃牌堆** | ≠ `seq.effect.discard_card` |
| 无主剧情支援 | **从游戏中移除**（REMOVED） | FAQ · Lita Chantler（01117）：临时控制、非牌组成员时离场 → remove from the game；≠ 置一边 |
| 弱点敌人 | **所有者弃牌堆** | owner = bearer |
| 遭遇敌人 | **遭遇弃牌堆** | |
| 任一有 Victory/复仇 | **胜利区** | 指示优先 |

（敌人-地点等特殊主体：后议。）

```text
伤害/恐惧写入 → 常态检测 → nest/run 击败效果（大信封）
卡面击败效果 ──────────────→ nest/run 击败效果（大信封）
                                ├─ Cancel 信封 → 停；退场不跑
                                └─ resolve → nest 退场（效果体 · 场上→场外移动）
```

**交战 `seq.engage`（两条路径 · 非改名前缀）**

只分 **框架自动** 与 **效果交战**。基础 Engage 行动 = 调查员自带能力 → 外壳 nest **`mode=effect`**（与卡面效果同路径）。溯源靠序列栈，**不**另做 source / initiation 专轴。

交战状态 = ENGAGEMENT Buff。威胁区 = 区划占位（检测用，不是 Buff）。`enter_threat` 常伴随移入威胁区；`grant` 只 Register Buff。

| 键 | 值 | 含义 |
|---|---|---|
| `mode` | `auto` / `effect` | 框架自动 vs 效果（含行动外壳 nest） |
| `placement` | `enter_threat` / `grant` | 是否伴随移入威胁区（区划）；交战状态一律 Register Buff |
| `require_same_location` | bool | 默认随 placement；`grant` 可 false |
| `cause` | `location` / `engagement` / `ready` | 仅 auto：区域变更因由 |
| `enemy_id` / `investigator_id` / `location_tag` | 实体 | 成对双方；auto 可扫地点 |

**禁止**：另铸 `seq.enemy.auto_engage`；为行动单独开 `mode=action` / source 专轴；把 `spawn_engaged`（L0 原子进场）与本内核混名。

### 3.5 框架 / 法令 / 中断

| flow_id | Grimoire | 粒度裁决（草案） |
|---|---|---|
| `seq.mythos.place_doom` | 1.2 | **保留**（≠ effect.place_doom） |
| `seq.mythos.check_doom_threshold` | 1.3 | **保留** |
| `seq.agenda.advance` / `seq.act.advance` | Agenda/Act advance | **保留** |
| `seq.act_agenda.resolve_back` | 背面结算 | **保留** |
| `seq.framework.phase_boundary` | 各阶段 begins/ends | **已铸**（G6 · **一条**）；`phase`+`boundary` params；TC.kind 仍细分（如 `investigation_phase_ends`）；旧 flow 别名已删 |
| `seq.chaos.reveal` | Chaos bag reveal（ST.3） | **已铸**；WHEN 窗收集替换 → RESOLVE 离袋（[05](05-chaos-bag.md)） |
| `seq.interrupt.cancel` / `ignore` | Cancel / Ignore | **保留** |
| `seq.replace.instead` | Instead / Would | **保留** |
| `seq.ability.resolve` | Initiation 装载 | **保留**（工程帧，非词条） |

---

## 4. 合并候选（建议确认）

| ID | 现状 | 建议 | 理由 | 敏感度注意 |
|---|---|---|---|---|
| M1 | ~~`discard_from_hand`~~ | **已并**入 `discard_card` + `from` | 同词条 Discard | Eligibility 须读 `from` / tag `from_hand` |
| M2 | `3_2_hunter_patrol` / `3_2_patrol` | **已落地**：框架只留 **`seq.enemy.3_2`**（枚举 + 消费槽）；Hunter/Patrol 移动体摘为 **`seq.keyword.hunter` / `seq.keyword.patrol`**（KeywordConsumer @ `ENEMY_3_2`） | [08 §5](08-enemy-engagement.md)、[06 §3.2.5](06-registration-buff-model.md) | 关键词 ≠ 框架 handler 内联 |
| M3 | `phase_attacks` + `massive_phase_attacks` | **已落地**：只留 **`seq.enemy.phase_attacks`**（固定 nest 攻击）；庞大 = 对一般攻击 **`seq.enemy.attack`** 的 **REPLACE**（PHASE→`seq.keyword.massive`）；删平行 massive 流程 | [06 §3.2.7](06-registration-buff-model.md)、[08 §6.3](08-enemy-engagement.md) | REPLACE 锚在攻击效果，不在 3.3 框架 |
| M4 | `seq.gain_resource` | **已落地**：正式 `seq.effect.gain_resource`；旧根 id **已删** | taxonomy | — |
| M5 | `seq.engage` | **已收口**：交战状态 = **ENGAGEMENT Buff**；威胁区仅区划检测；`grant` 不移入威胁区 | 行动=效果交战 | `EngagementStatus` vs `threat_area` 分查 |

**不建议合并**（已确认或强烈倾向）：

| 对 | 原因 |
|---|---|
| `seq.action.*` vs 内核 `seq.draw.*` / `seq.skill_test` / `seq.engage` | 外壳有耗 action / AOO / 窗口；内核可被非行动入口 nest |
| `seq.mythos.place_doom` vs `seq.effect.place_doom` | 议程进度 vs 卡面效果；订阅语义不同 |
| `seq.enter_hand` vs `seq.encounter.revelation` | 玩家入手显现 vs 遭遇帧显现；来源与隐私不同 |
| `seq.effect.discover_clue` vs `seq.effect.place_clue` | 发现（调查员获得）vs 放置（放到地点） |
| `seq.effect.register` vs `seq.keyword.surge` | 创建标记 vs 开火 |

---

## 5. 缺漏（Grimoire 词条 / 常听时点尚无独立 seq）

按「铸造判据」筛：需要被听到或跨入口复用才列。**框架步进本身**可继续用 `FrameworkStep`，不必每步一条 seq；下列是 **卡面/Forced 常订** 或 **效果叶已真空/半真空** 的缺口。

| ID | 词条 / 语义 | 现状 | 建议 |
|---|---|---|---|
| G1 | **狭义 Move** | **`seq.effect.move`**（investigator/enemy/attachment/marker） | **已统一**；`seq.enemy.move` 别名；广义转移与地点交换 **不**入此 seq |
| G2 | **Exhaust / Ready / Evade effect** | **已铸** `seq.effect.exhaust` / `ready` / **`evade`** | 横置/重整；躲避效果核 = **横置∥脱离同时组**；费用 exhaust 仍走 Cost |
| G3 | **Search** | **已铸** `seq.effect.search` | 单条；`area`/`scope`/`amount`/`filter`/`take_count`；搜牌库须洗（整库/顶 N）；≠ look/find |
| G4 | **Put into play / Enter play** | 区划事实（场外→场上） | **不铸** `seq.effect.enter_play` — **不是效果**；见下「进场」 |
| G5 | **Defeat**（击败） | **已铸** `seq.effect.defeat`；退场 nest `seq.defeat.leave_play`；敌主体 TC=`enemy_defeated` | 伤/恐上限常态检测；Cancel → 无退场；卡面 `cause=effect` |
| G6 | **Phase begins/ends** | **已铸** 单条 `seq.framework.phase_boundary` | params：`phase` × `boundary`；框架步进进入时 `run`；订阅靠 TC.kind |
| G7 | **Attack of opportunity** | **不另铸**；仍是攻击 | 嵌套来源辨认；见下 |
| G8 | **Play（打出）** | **要对 Initiation 加打出包装** | 完整流程 + 可响应时点；见下（**改裁**） |
| G9 | **Commit（投入）** | **待议** | 疑点多；暂不锁「仅 ST.2 / 不铸」 |
| G10 | **Cost / Spend（费用）** | **不另铸** Spend seq | 费用 = 效果属性；见下（**改裁**） |
| G11 | **Peril（险境）** | **不另铸**；无物理层序列 | Buff / 信息层；见下 |

**G7 · 借机攻击（已确认）**

借机攻击 **就是** 敌人攻击（`seq.enemy.attack` / `perform_attack`）。**禁止** `seq.aoo`。  
是否借机 = 看 **攻击嵌套的来源**（挂在 Initiation 付完费用后、主体效果前的 AOO 砖 / 栈溯源）。`AttackKind.OPPORTUNITY` 仍可作叶上快捷过滤，不是唯一辨识轴。

**G8 · 打出（改裁 · 2026-10-27；赋快速/降费 · 2026-10-28）**

打出是 **完整流程**，有可响应时点；**不是**「只靠裸 Initiation 种类名凑合听」。  
**要**在已有发起手续（`PLAY_CARD` Initiation 七步）外加一层 **打出包装**（命名流程或等价包装帧），使打出窗与包装时点订在包装上，而不是散落在通用 Initiation。  
进场区划结果仍听 `seq.zone.move`（场外→场上）。包装的精确 `flow_id` / 与 Initiation 分槽 → 实现时钉（候选如 `seq.play` 包装 nest/委托 Initiation；**禁止**把打出收成 `AbilityKind`）。

**打出本身无行动费用**；无快速时经 **Play 行动入口** 发起包装，快速只改入口/窗口/AOO（见 [06 §4.2](06-ability-initiation.md#42-打出与触发对称fast打出-不是-能力)）。

**赋快速 / 降费类（Fence · Chuck Fergus）**：纸面「When you play … gains fast / reduce cost」不按后置反应实现；**改写为独立打出包装能力**——**获得快速**与**降低资源费用**必须拆成两条（快速 → `PLAY_FAST_*` 包装；降费 → 仍 `PLAY_ACTION` + `cost_delta`）；**禁止**用宿主 `[free]` 冒充目标快速。结算期修正（如 +2 技能）可另挂。全文：[06 §4.2.1](06-ability-initiation.md#421-赋快速--降费类fence--chuck-fergus--改写为独立打出包装能力)。

**G9 · 投入（待议）**

暂缓锁死。现网多挂在 `seq.skill_test` ST.2，但是否足够、要否独立包装/时点，**需另开讨论**。禁止在未裁决前为「好听」另铸 `seq.commit`。

**通则 · 同原子、异包装（已裁决 2026-10-27）**

纸面多词条常 **共用同一 L0 状态原语**；差别在 **命名流程 / 效果包装**（时点、可响应性、与后续体的门闩）。  
**时点响应订包装，不订裸原子。** 禁止为每个近义词再铸一套平行写核。

| L0（同） | 包装 A | 包装 B | 备注 |
|---|---|---|---|
| 资源标记 → 池 | **花费**（费用结算包装 / cost 属性） | **失去**（`seq.effect.lose_resources`） | 见 G10 |
| 伤害/恐惧标记 → 承载者 | **受到**（take 视角；常 `deal.assignable`） | **放置/造成**（deal 外向 / 已定腿） | 同核 `deal*`；视角与 Assign 不同 |
| 伤害/恐惧标记 → 池 | **治愈**（`seq.effect.heal`） | **移除**（非 heal 语义的剥记；若可响应须自有包装，勿冒充 heal AFTER） | 写核可同 `transfer_marker` |
| 牌 → HAND | **抽取**（`seq.draw.*` 手续） | **加入手牌**（非抽牌手续的入手；显现入口仍可 `seq.enter_hand`） | 勿把 add 译成 draw 整段 |

推广：进场/离场听 `seq.zone.move` 过滤；封印/释放等同记不同包装——凡「物理一样、规则词不同」先复用原子，再分包装。

**G10 · 费用（改裁 · 2026-10-27）**

支付费用 **本身也是结算**：这段结算可影响后续效果体能否/如何结算；费用在语义上也可以是效果。  
**建模**：费用 **只作效果属性**（资源费用 / 能力费用 / 额外费用等），挂在 **已有** `seq.*`（或其效果叶）上，**不**另铸 `seq.spend` / `seq.effect.spend_token` 之类「第二种扣资源原语」。  
实例见上表「花费 / 失去」：同 L0，异包装。翻译进 **cost / gates + 费用包装**；不要 nest 一条与 `lose_resources` 抢通道的 Spend 效果 seq。

**G11 · 险境（已确认）**

险境多种效果由 **Buff（RESTRICTION 等）** 实现，属 **信息层**；**没有**物理层序列结算。**禁止** `seq.peril.check`。Eligibility / Intent 读 Buff；生命周期跟遭遇帧等既有注销点。

---

## 6. 参数轴（确认粒度后、填卡前的白名单方向）

先定种类，再在叶上强制写全（应展尽展）。各类建议轴（**非**本轮实现清单）：

| 种类 | 典型 params |
|---|---|
| `damage` | `kind`, `amount`, `target`, `source`/`card_id`, `direct` |
| `discard_card` | `from`, `investigator`, `amount`, `mode`, `card_id`, `trait`, `at` |
| `heal` | `kind`, `amount`, `target` |
| `move`（狭义 · G1） | `subject`, `move_kind`（move\|move_to）, `destination_id`/`to`, 主体 id，`mode`/`steps`（敌·仅 move）, `amount`/`marker_kind`/`from_location`, `auto_engage_*` |
| `search`（G3） | `controller_id`, `area`(s), `scope` entire\|top, `amount`（顶 N）, `definition_id`/`trait`/`card_type`, `take_count` |
| `defeat`（G5） | `subject`（enemy/investigator/asset）, `cause`（damage_cap / horror_cap / effect）, 实体 id；成功后 nest 退场；asset 退场≠ discard 效果 |
| `skill_test` | `investigator`, `skill`, `difficulty` / `difficulty_source`, `st7` |
| `engage` | `mode`（auto/effect）, `placement`, `require_same_location`, `enemy`, `investigator`, `cause` |
| `register` | `template`（含 Buff 种类与 lifetime） |

---

## 7. 待你确认的问题

请对下列选项拍板（可直接回「M2/M3 合并、G1 要铸、G2 暂缓」这类）：

1. ~~**M2**~~：**已落地** — `seq.enemy.3_2` 只枚举+消费槽；移动体 = `seq.keyword.hunter` / `patrol`  
2. ~~**M3**~~：**已落地** — `phase_attacks` nest 攻击；Massive REPLACE @ `seq.enemy.attack`  
3. ~~**M4**~~：**已落地** — `seq.effect.gain_resource`（旧 id 别名）  
4. ~~**M5**~~：**已收口** — `seq.engage` 仅 auto/effect；行动=效果交战  
5. ~~**G1**~~：**已统一** — 狭义移动 = `seq.effect.move`（四主体）；见「移动三分」  
6. ~~**G2**~~：**已落地** — `seq.effect.exhaust` / `ready`；4.3 / 卡面 / 攻击后横置 / Elusive 接线  
6b. ~~**躲避效果**~~：**已落地** — `seq.effect.evade`（attempt / automatic；横置∥脱离**同时组**）；卡面执行=自动躲避；≠ `seq.action.evade`；四层见术语表 / 03 §6.7  


7. ~~**G3**~~：**已落地** — `seq.effect.search`；搜牌库须洗（整库/顶 N）；look/find 不入本 seq  
8. ~~**G4**~~：**已裁决并落地** — `seq.zone.move`；进场/离场 = 过滤别名；**不铸** `seq.effect.enter_play`  
9. ~~**G5**~~：**已落地** — `seq.effect.defeat` + nest `seq.defeat.leave_play`；伤/恐常态检测；敌主体 TC=`enemy_defeated`  

9b. ~~**G6**~~：**已落地** — 单条 `seq.framework.phase_boundary`（phase/boundary params） |
10. ~~**`resolve_bound` / `resolve_location`**~~：**已裁决** — 废除重定向；抽出按**卡面能力**（类型默认能力包）结算 → `seq.encounter.resolve_card`。`resolve_location` 仍可降内部（落点辅助）。  
11. ~~**交战 grant / Buff**~~：**已落地** — ENGAGEMENT Buff；威胁区是区划检测，不是第二套状态写入

确认后：

- 改 Catalog（合并 / 铸造缺口）  
- 再按 **已有卡牌** 填精细参数（不先发明用不到的轴）

---

## 8. 变更记录

| 日期 | 说明 |
|---|---|
| 2026-10-10 | 初稿：对照 Grimoire + 现 Catalog；并入 discard 的敏感度原则；列出 M* / G* |
| 2026-10-10 | 纠正 M2：Hunter/Patrol 不是固定流程，应按 06 §3.2.5 为 LISTENER @ `seq.enemy.3_2` |
| 2026-10-10 | 再纠：敌军阶段 III（3.1–3.4）与 3.2 本身有基础流程，不是空壳；LISTENER 只承担关键词移动体；M2 确认 |
| 2026-10-10 | M2 落地：关键词移动体摘出为 `seq.keyword.hunter` / `patrol`；`seq.enemy.3_2` 只做枚举+消费槽 |
| 2026-10-10 | 链 06 §3.2.7：关键词开火锚与同锚 fire_priority |
| 2026-10-10 | M3 落地：删 massive_phase_attacks；庞大 = REPLACE 体 `seq.keyword.massive` |
| 2026-10-10 | M3 纠正：庞大 = 对一般攻击效果 `seq.enemy.attack` 的 REPLACE（PHASE→batch）；敌军阶段 `phase_attacks` 只是固定手续 nest 攻击 |
| 2026-10-10 | M4：`seq.effect.gain_resource`；M5：扩展 `seq.engage`（source/initiation/placement），保留根 id |
| 2026-10-10 | M5 收口：仅 `auto`/`effect`；行动外壳 nest effect；去掉 source/initiation 专轴 |
| 2026-10-10 | 交战状态 = ENGAGEMENT Buff；与威胁区脱钩 |
| 2026-10-12 | 纠正：威胁区 = 区划检测信息，不是「写入/不写」的 Buff 并列层 |
| 2026-10-12 | G1：铸造 `seq.effect.move`（狭义）；文档三分狭义 / 广义转移 / 地点交换 |
| 2026-10-12 | G1 收编：`seq.enemy.move`→别名；扩展 attachment/marker；统一 TC `move` + subject tags |
| 2026-10-12 | G1 接线：Elusive / move_enemy_to / Hunter / Patrol 均经 `seq.effect.move`；删 InvestigatorMoveFlow |
| 2026-10-12 | G1：区分 **移动**（`move_kind=move` 遵守连接）与 **移动到地点**（`move_to` 无视连接） |
| 2026-10-12 | G2：铸 `seq.effect.exhaust` / `ready`；平放区+在场敌人；接线 4.3 / composition / combat / Elusive |
| 2026-10-12 | 躲避四层：行动 / 躲避尝试 / 躲避效果 / 自动躲避（包装效果）；≠ 自动成功的尝试 |
| 2026-10-12 | 纠正：躲避效果可由成功尝试**或**自动躲避产生，非仅前者 |
| 2026-10-12 | 废除 `resolve_bound` 重定向；`CardAbilityPackage` + `seq.encounter.resolve_card` |
| 2026-10-12 | 遭遇能力包含 location；可抽遭遇 = 诡计/敌人/地点；G4 地点默认进场 |
| 2026-10-12 | G3：铸 `seq.effect.search`；接线 lead_search；搜牌库须洗（整库/顶 N）；弃牌堆不洗 |
| 2026-10-12 | G3 纠正：洗牌条件是「搜了牌库」，不是「仅整库」 |
| 2026-10-12 | G4：进场 = 场外→场上区划信息，非效果；不铸 `seq.effect.enter_play` |
| 2026-10-12 | G4 补：听进场 = 听广义移动 + 场外→场上过滤；`ENTER_PLAY` 是别名非第二通道 |
| 2026-10-20 | G5 表述：击败=大信封；退场是效果体（nest），非信封外后续 |
| 2026-10-20 | G5 去向表：玩家弃牌 / 无主剧情→REMOVED（FAQ · Lita 01117）/ 遭遇弃牌；Victory·复仇指示；敌人-地点后议 |
| 2026-10-20 | 铸造 `seq.effect.evade`：躲避效果核；横置∥脱离**同时组**（非 nest→内联）；`mode=attempt\|automatic` |
| 2026-10-12 | G5：击败是效果；退场 nest 不内联；伤/恐上限常态检测（Cancel 可再触） |
| 2026-10-12 | G5 落地：`DefeatFlow`；`seq.effect.defeat` / `seq.enemy.defeat`；nest `seq.defeat.leave_play` |
| 2026-10-12 | G5：支援资产 `subject=asset`；退场 L0 进弃牌堆，不走 discard 效果包装 |
| 2026-10-13 | G4 落地：`seq.zone.move`；进场/离场 = 过滤别名 |
| 2026-10-13 | G6 落地：单条 `seq.framework.phase_boundary`；旧 investigation_phase_ends 别名 |
| 2026-10-13 | G7–G11：不另铸；时点从攻击 / PLAY_CARD / ST / Cost / Register 过滤信息 |
| 2026-10-13 | AOO 可栈溯源或 AttackKind；Spend/失去资源同 L0、场合不同 |
| 2026-10-13 | 落地 `seq.effect.evade`（躲避效果核；automatic = 自动躲避） |
| 2026-10-13 | 裁决：卡面「evade」效果措辞→时点；执行→自动躲避（无独立 effect mode） |
| 2026-10-13 | I2 真空抽查 → [23-vacuum-audit](23-vacuum-audit.md)；铸造清单已收口，下一刀偏结构性硬门槛 |
| 2026-10-27 | §9 Catalog 全量审计：初扫 66（含别名） |
| 2026-10-27 | §9.2：**去掉全部 flow 别名**；正式 **60** 条；`damage*`/`gain_resource`/`enemy.move`/`enemy.defeat`/`investigation_phase_ends` 已删；`skill_type_for_flow` 死代码已删 |
| 2026-10-28 | G8：赋快速/降费 → 独立打出包装能力（[06 §4.2.1](06-ability-initiation.md#421-赋快速--降费类fence--chuck-fergus--改写为独立打出包装能力)）；打出无行动费用 |
| 2026-10-27 | G7–G11 改裁：费用=效果属性；AOO=攻击嵌套来源；**打出要 Initiation 包装**；投入待议；险境=Buff 信息层 |
| 2026-10-27 | G10 补例：花费/失去资源 **同 L0**，**异包装时点**；响应订包装不订裸原子 |
| 2026-10-27 | 通则：同原子异包装 — 受到/放置伤恐、治愈/移除、抽取/加入手牌 |

---

## 9. Catalog 全量审计（2026-10-27）

对照 `bootstrap/sequence_catalog_bootstrap.gd` + 代码引用（不含 conversation-export 历史噪音）。

### 9.1 结论

| 档 | 结论 |
|---|---|
| **G1–G11 / M1–M5** | **无铸造缺漏**；已废 id 测试断言不存在 |
| **运行时调用** | `.gd` / 现网 JSON **无** nest/run 未注册 `flow_id` |
| **注册总数** | **60**（无别名）；`SEQ-AUDIT-01` 锁清单 |

### 9.2 已删别名（统一正式名）

| 曾用别名 | 正式 |
|---|---|
| `seq.gain_resource` | `seq.effect.gain_resource` |
| `seq.enemy.move` | `seq.effect.move`（`subject=enemy`） |
| `seq.effect.damage` / `damage.assignable` | `seq.effect.deal` / `deal.assignable` |
| `seq.enemy.defeat` | `seq.effect.defeat`（敌主体 TC.kind=`enemy_defeated`） |
| `seq.framework.investigation_phase_ends` | `seq.framework.phase_boundary` + `phase`/`boundary` params |

订阅靠 TC.`kind` / tags，不靠 flow_id 字符串相等。

### 9.3 刻意不铸（非缺漏）

| id | 理由 |
|---|---|
| `seq.setup` | KeywordProfile 挂载锚（Starting / Permanent / Bonded）；开局仍走 `FrameworkStep` / `ScenarioSetupFlow`；[17 §6.4](17-seq-runtime.md) 后置 |
| `seq.effect.spend_token` / `seq.spend` | **费用 = 效果属性**（G10）；挂已有 seq，不另铸 |
| `seq.aoo` | **就是攻击**（G7）；嵌套来源辨认 |
| `seq.peril.check` | **纯 Buff / 信息**（G11）；无物理序列 |
| `seq.effect.enter_play` | **不是效果**（G4）；听 `seq.zone.move` |
| `seq.commit` | **G9 待议**；未裁决前不铸 |
| `seq.skill_test.{intellect,combat,agility}` | 已并 → 单条 `seq.skill_test` + `params.skill` |

### 9.4 文档债（本轮已收）

- §3 / §9 与 Catalog 对齐；[17 §5](17-seq-runtime.md) 指向本清单
