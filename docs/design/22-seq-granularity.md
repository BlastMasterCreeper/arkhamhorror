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
| `seq.framework.*` / `seq.mythos.*` / `seq.agenda.*` / `seq.act.*` | Framework / 议程法令 | `seq.mythos.place_doom` |
| `seq.draw.*` | Drawing Cards（调查员 / 遭遇） | `seq.draw.investigator` |
| `seq.encounter.*` | 遭遇卡结算 nest 体 | `seq.encounter.revelation` |
| `seq.enter_hand` | 入手显现入口（跨来源） | NEST_BATCH |
| `seq.skill_test` | Skill Test Timing | 一条 + `params.skill` |
| `seq.action.*` | 基本/指定行动 **外壳**（耗 action、AOO） | `seq.action.fight` |
| `seq.enemy.*` | 敌人手续（移动 / 攻击 / 击败…） | `seq.enemy.attack` |
| `seq.effect.*` | 纸面无名但可解释的效果种类 | `seq.effect.damage` |
| `seq.keyword.*` | 关键词 **开火**（非创建） | `seq.keyword.surge` |
| `seq.interrupt.*` / `seq.replace.*` | Cancel / Ignore / Instead | 共享 |
| `seq.ability.resolve` | Initiation 装载帧（禁真空） | — |

**命名债**：

| 现状 | 状态 |
|---|---|
| ~~`seq.gain_resource`~~ | **已迁** → `seq.effect.gain_resource`（旧 id 别名） |
| `seq.engage` | **保留根 id**（统一交战内核，非「仅行动对称改名」）；见 §3.4 / M5 扩展 |

---

## 3. 现有 Catalog 对照表

### 3.1 抽牌 / 入手 / 显现

| flow_id | Grimoire | 粒度裁决（草案） |
|---|---|---|
| `seq.draw.investigator` | Drawing Cards（玩家库） | **保留**：词条内核 |
| `seq.action.draw` | Draw Action | **保留**：行动外壳 → Delegate 内核（OQ-SEQ-02：不同 RUN） |
| `seq.draw.encounter` | Drawing encounter / 1.4 | **保留** |
| `seq.draw.encounter.resolve_bound` | 弱点/重定向结算 | **保留为入口变体**（或将来降为同 flow + `mode=bound`； presently 独立 RUN 可接受） |
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
| `seq.effect.damage` | Dealing Damage/Horror | **已统一** take/deal；`kind`+`target`+`source` |
| `seq.effect.heal` | Heal | **保留** |
| `seq.effect.lose_resources` | （失去资源） | **保留**；`all` 参数 |
| `seq.effect.lose_action` | （失去行动） | **保留** |
| `seq.effect.discover_clue` | Clues / discover | **保留** |
| `seq.effect.place_clue` | 线索放到地点 | **保留**（与 discover 因果不同） |
| `seq.effect.place_doom` | Doom（卡面放置） | **保留**；**勿**并入 mythos |
| `seq.effect.discard_card` | Discard | **已统一**；`from=hand` / `card_id` / 寻址 |
| `seq.effect.attach` | Attach To | **保留** |
| `seq.effect.resign` | Resign | **保留** |
| `seq.effect.register` / `unregister` | lasting / Cannot / keyword 标记创建 | **保留**；勿为每个 keyword 开创建 seq |
| `seq.effect.gain_resource` | Gain resources | **已迁**；旧 `seq.gain_resource` 别名 |

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
| `seq.enemy.move` | Move（敌人） | **保留**：卡面/效果移敌内核 |
| `seq.enemy.3_2_hunter_patrol` | （误铸） | **删除** → 见 §4 M2 |
| `seq.enemy.3_2_patrol` | （误铸） | **删除** → 见 §4 M2 |
| `seq.enemy.3_2` | Framework **3.2** 基础手续 | **已收口**：枚举 + `ENEMY_3_2` 消费槽；**不含**移动路径 |
| `seq.keyword.hunter` | Hunter 开火 | **已铸**：从 3.2 摘出的移动体 |
| `seq.keyword.patrol` | Patrol 开火 | **已铸**：从 3.2 摘出的移动体 |
| `seq.enemy.attack` | Enemy attack | **保留**：单次攻击结算 |
| `seq.enemy.phase_attacks` | 3.3 Engaged attacks | **已收口**：固定手续；nest `seq.enemy.attack` |
| `seq.enemy.massive_phase_attacks` | （误铸） | **删除** |
| `seq.keyword.massive` | Massive REPLACE 体 | **已铸**：替换 `seq.enemy.attack`（PHASE→batch） |
| `seq.enemy.defeat` | Defeat（敌人） | **保留** |
| `seq.enemy.resolve_location` | Prey / 地点解析辅助 | **保留或降为内部**（若无独立订阅需求） |
| `seq.engage` | Engage（交战） | **扩展内核**：见下「交战 params」；外壳 `seq.action.engage` nest 本条 |

**交战 `seq.engage` params（已扩展 · 非改名前缀）**

交战 **不是**「仅行动外壳的对称改名」。常态语义：同地点敌人进入调查员威胁区（成对写入）。特殊：可不要求同地点；可不强调「进入」区划动作，仅赋予成对交战状态（`placement=grant`；日后可叠 Register Buff，仍走本 flow）。来源与是否调查员主动正交。

| 键 | 值 | 含义 |
|---|---|---|
| `source`（兼容旧 `mode`） | `auto` / `action` / `effect` | 入口：区域变更自动 / Engage 行动 / 卡面效果 |
| `initiation` | `automatic` / `investigator` | 是否调查员主动交战（订能力过滤用） |
| `placement` | `enter_threat` / `grant` | 进入威胁区 vs 仅成对状态 |
| `require_same_location` | bool | 默认随 placement；`grant` 可 false |
| `cause` | `location` / `engagement` / `ready` | 仅 auto：区域变更因由 |
| `enemy_id` / `investigator_id` / `location_tag` | 实体 | 成对双方；auto 可扫地点 |

**禁止**：另铸 `seq.enemy.auto_engage`；把自动/行动/效果拆成三条命名流程；把 `spawn_engaged`（L0 原子进场）与本内核混名。

### 3.5 框架 / 法令 / 中断

| flow_id | Grimoire | 粒度裁决（草案） |
|---|---|---|
| `seq.mythos.place_doom` | 1.2 | **保留**（≠ effect.place_doom） |
| `seq.mythos.check_doom_threshold` | 1.3 | **保留** |
| `seq.agenda.advance` / `seq.act.advance` | Agenda/Act advance | **保留** |
| `seq.act_agenda.resolve_back` | 背面结算 | **保留** |
| `seq.framework.investigation_phase_ends` | 2.3 | **保留**；其它 phase ends **缺** → §5 |
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
| M4 | `seq.gain_resource` | **已落地**：正式 `seq.effect.gain_resource`；旧 id 别名 | taxonomy | — |
| M5 | `seq.engage` | **已扩展**：保留根 id；params 轴 `source`/`initiation`/`placement`；行动外壳 nest 内核 | 交战≠行动对称改名；见 §3.4 | 订阅按 `source`/`initiation` 过滤 |

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
| G1 | **Move**（调查员，非行动外壳） | Composition `nest_move_to` 多半 **直写 location**，未压 `seq.action.move` 内核 | 铸造 **`seq.effect.move`**（或复用 move 内核 + `source=effect`），供「after you move」 |
| G2 | **Exhaust / Ready** | `exhaust_card` / enemy exhaust 多为 **L0 直写** | 若存在「after … is exhausted/readied」订阅 → 铸 **`seq.effect.exhaust` / `ready`**（`target` 参数）；否则保持 L0 |
| G3 | **Search** | roadmap 有、Catalog **无** | 铸 **`seq.effect.search`**（deck/discard + amount + 过滤）；勿按「搜顶 N / 搜弃牌」拆条 |
| G4 | **Put into play / Enter play**（非 Spawn） | 部分走 mutator / 生成专用 | 玩家牌进场若需被听到 → **`seq.effect.enter_play`**（与 `seq.encounter.spawn` 分源） |
| G5 | **Defeat**（调查员） | 淘汰多在 elimination 服务 | 若 Forced 订「when you are defeated」→ 明确 **`seq.effect.defeat`** 或挂在已有 elimination 帧 |
| G6 | **Phase begins/ends**（除调查结束） | 仅 `investigation_phase_ends` | 按需补 `seq.framework.*_phase_ends/begins`；**不要**一次铸满四阶段 |
| G7 | **Attack of opportunity** | 行动 Initiation 内联 | 保持内联，除非卡面大量订「after AOO」且难过滤 |
| G8 | **Play（打出）** | 刻意非 seq（`PLAY_CARD`） | **不铸** `seq.play` 进命名流程表（17 已裁） |
| G9 | **Commit** | ST.2 内 | **不另铸**；订检定窗即可 |
| G10 | **Spend**（费用） | CostPipeline | **不铸**为效果 seq；与效果「失去资源」分清 |
| G11 | **Peril / Hidden 限制** | 父遭遇帧 Register | **不另铸** check seq（15 已禁） |

---

## 6. 参数轴（确认粒度后、填卡前的白名单方向）

先定种类，再在叶上强制写全（应展尽展）。各类建议轴（**非**本轮实现清单）：

| 种类 | 典型 params |
|---|---|
| `damage` | `kind`, `amount`, `target`, `source`/`card_id`, `direct` |
| `discard_card` | `from`, `investigator`, `amount`, `mode`, `card_id`, `trait`, `at` |
| `heal` | `kind`, `amount`, `target` |
| `move`（若铸 G1） | `investigator`/`enemy`, `to`/`from`, `mode` |
| `skill_test` | `investigator`, `skill`, `difficulty` / `difficulty_source`, `st7` |
| `engage` | `source`/`mode`, `initiation`, `placement`, `require_same_location`, `enemy`, `investigator`, `cause` |
| `register` | `template`（含 Buff 种类与 lifetime） |

---

## 7. 待你确认的问题

请对下列选项拍板（可直接回「M2/M3 合并、G1 要铸、G2 暂缓」这类）：

1. ~~**M2**~~：**已落地** — `seq.enemy.3_2` 只枚举+消费槽；移动体 = `seq.keyword.hunter` / `patrol`  
2. ~~**M3**~~：**已落地** — `phase_attacks` nest 攻击；Massive REPLACE @ `seq.enemy.attack`  
3. ~~**M4**~~：**已落地** — `seq.effect.gain_resource`（旧 id 别名）  
4. ~~**M5**~~：**已扩展** — `seq.engage` params（source/initiation/placement）；非改名前缀  
5. **G1**：调查员效果移动是否升格为命名流程？  
6. **G2**：Exhaust/Ready 是否升格，或等出现真实订阅再铸？  
7. **G3**：Search 是否本阶段铸造？  
8. **`resolve_bound` / `resolve_location`**：保持独立 RUN，还是降为同 flow 的 mode？  
9. **交战 grant / Buff**：`placement=grant` 现阶段仍 L0 成对写入；是否另层 Register 表示「交战状态 Buff」？

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
