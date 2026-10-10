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

**命名债**（确认后可改，但不改语义）：

| 现状 | 建议 |
|---|---|
| `seq.gain_resource` | 宜归 `seq.effect.gain_resource`（或保留别名） |
| `seq.engage` | 宜归 `seq.enemy.engage` 或 `seq.effect.engage`（与 `seq.action.engage` 外壳对称） |

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
| `seq.gain_resource` | Gain resources | **保留种类**；建议改名前缀（§2） |

### 3.4 敌人 / 交战

| flow_id | Grimoire | 粒度裁决（草案） |
|---|---|---|
| `seq.enemy.move` | Move（敌人） | **保留**：卡面/效果移敌 |
| `seq.enemy.3_2_hunter_patrol` | 3.2 Hunter | **合并候选** → 见 §4 |
| `seq.enemy.3_2_patrol` | 3.2 Patrol | **合并候选** → 见 §4 |
| `seq.enemy.attack` | Enemy attack | **保留**：单次攻击结算 |
| `seq.enemy.phase_attacks` | 3.3 Engaged attacks | **合并候选** → 见 §4 |
| `seq.enemy.massive_phase_attacks` | Massive @ 3.3 | **合并候选** → 见 §4 |
| `seq.enemy.defeat` | Defeat（敌人） | **保留** |
| `seq.enemy.resolve_location` | Prey / 地点解析辅助 | **保留或降为内部**（若无独立订阅需求） |
| `seq.engage` | Engage | **保留内核**；与 `seq.action.engage` 外壳成对 |

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
| M2 | `3_2_hunter_patrol` + `3_2_patrol` | 并成 **`seq.framework.enemy_3_2`**（或 `seq.enemy.phase_move`），内部按 Hunter/Patrol 分支 | 同属 Framework 3.2 一步 | 若卡面要「仅 Hunter 移动后」→ tag/`keyword` 过滤，勿再铸平行 |
| M3 | `phase_attacks` + `massive_phase_attacks` | 并成 **`seq.enemy.phase_attacks`** + `massive: bool` / 分批 params | 同属 3.3 | Massive 批量打断仍是同 kind |
| M4 | `seq.gain_resource` 命名 | **不改种类**，只校正前缀别名 | taxonomy | — |
| M5 | `seq.engage` 命名 | **不改种类**，只校正前缀别名 | 与 action.engage 对称 | — |

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
| `engage` | `enemy`, `investigator`, `mode` |
| `register` | `template`（含 Buff 种类与 lifetime） |

---

## 7. 待你确认的问题

请对下列选项拍板（可直接回「M2/M3 合并、G1 要铸、G2 暂缓」这类）：

1. **M2 / M3**：敌人阶段 3.2 / 3.3 是否合并为单框架 seq + params？  
2. **G1**：调查员效果移动是否升格为命名流程？  
3. **G2**：Exhaust/Ready 是否升格，或等出现真实订阅再铸？  
4. **G3**：Search 是否本阶段铸造？  
5. **命名债 M4/M5**：是否接受别名迁移（`gain_resource` / `engage` 前缀），还是冻结 id、只写文档？  
6. **`resolve_bound` / `resolve_location`**：保持独立 RUN，还是降为同 flow 的 mode？

确认后：

- 改 Catalog（合并 / 铸造缺口）  
- 再按 **已有卡牌** 填精细参数（不先发明用不到的轴）

---

## 8. 变更记录

| 日期 | 说明 |
|---|---|
| 2026-10-10 | 初稿：对照 Grimoire + 现 Catalog；并入 discard 的敏感度原则；列出 M* / G* |
