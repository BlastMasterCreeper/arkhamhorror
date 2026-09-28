# 19 — Core 2026（2.0 基础）卡牌翻译路线图

> **依赖**：[07-composition](07-composition.md)、[12-card-script-api](12-card-script-api.md)、[17-seq-runtime](17-seq-runtime.md)、[18-arkhamdb-card-data](18-arkhamdb-card-data.md)、[effect-translation.mdc](../../.cursor/rules/effect-translation.mdc)  
> **状态**：v0.9 · 2026-09-28 — 翻译硬门槛（禁真空 / 三分法 / 应展尽展）  
> **范围**：`core_2026` + `core_2026_encounter`（约 166 张 / 162 段能力）

---

## 1. 口径（已裁决）

| 来源 | 译法 |
|---|---|
| 规则书手续 | 命名流程 `seq.*` |
| 卡牌正文 | 效果组合（Composition）静态树 → 装载到已有 seq → 解释（**禁止真空**） |
| 纸面无名可解释效果 | 铸造 `seq.effect.*`（参数化）；**铸造 ≠ nest**；禁止 `seq.card…`、真空 Atom/Register |
| 玩家选择 | `PlayerInteractionGate` 有限期确认 + 默认；**≠ nest / 内联** |

覆盖率**不是 KPI**。完成度看：段落实例满足 §3 DoD（能在栈上 dry-run/resolve、三分法正确、无糖外壳）。

---

## 2. 基线与进度

| 时刻 | 包 | 段落 | 已编译 | 未编译 |
|---|---|---:|---:|---:|
| 开工前 | 玩家 `core_2026` | 72 | 17 | 55 |
| 开工前 | 遭遇 `core_2026_encounter` | 90 | 18 | 72 |
| 开工前 | **合计** | **162** | **35** | **127** |
| A1 后 | 玩家 / 遭遇 | 72 / 90 | 21 / 32 | 51 / 58 |
| A1 后 | **合计** | **162** | **53** | **109** |
| **B1+A3 后** | 玩家 / 遭遇 | 72 / 90 | **21** / **34** | 51 / 56 |
| **B1+A3 后** | **合计** | **162** | **55** | **107** |
| **12106–08 Parley 后** | 玩家 / 遭遇 | 72 / 90 | **21** / **36** | 51 / 54 |
| **12106–08 Parley 后** | **合计** | **162** | **57** | **105** |
| **12112 Resign 后** | 玩家 / 遭遇 | 72 / 90 | **21** / **41** | 51 / 49 |
| **12112 Resign 后** | **合计** | **162** | **62** | **100** |

数据源：`data/arkhamdb/imported/*.json` · `_meta.ability_compile_summary`。

---

## 3. 完成定义（DoD）

每段能力（与 [effect-translation DoD](../../.cursor/rules/effect-translation.mdc) 对齐；**硬门槛**）：

1. **禁止真空** — 解释落在已压栈 `seq.*` RESOLVE；无裸 `composition.execute` / 糖 Atom 直改局面
2. **三分法** — 每步标注：内联 | nest（仅 §4.0.5「是」）| PI 有限期确认（含 default）
3. **应展尽展** — 无多步糖；静态树逐步可读（控制流 + 效果叶 + PI 规格）
4. 所需 `seq.effect.*` / 规则 seq 已在 Catalog（若该叶可被 When/After 听到）
5. Hook：`register_as` + `match_kind` / `window` / `action_cost`
6. Headless：compile 形状 + 至少一条运行时路径（含默认确认路径）
7. 选型可查（template vs 手写同等树 · OQ-12-01）

### 3.1 翻译债（糖 / 真空）

| 债 | 状态 | 备注 |
|---|---|---|
| 12113 `engage_from_connecting` | ✅ 已展 | PI `pick_target` → **内联** `move_enemy_to` → **内联** `engage_target`（不 nest） |
| 12112 `resign` 糖 Atom | ✅ 已展 | **内联** `resign`（不 nest；`seq.effect.resign` 仅 §4.0.5 需要时） |
| Initiation / Forced 裸 `execute` | ✅ 收口 | nest `seq.ability.resolve` 装载帧后再解释 |
| `nest_move_connecting` 内嵌 PI | 待拆 | 12116：选地点确认应独立为 pick_target 步 |
| LISTENER / peril / act-agenda-back | 部分 | 仍有直 `execute` 路径；优先复用 `seq.ability.resolve` |
| 编译侧「叶子一律 nest」习惯 | 文档已裁 | 新译先判三分法 |

---

## 4. 分轨（按能力簇）

| 轨 | 内容 | 先铸的典型 `seq.effect.*` |
|---|---|---|
| **A** 遭遇显现 / Forced | 检定 fail / fail-by、Attach、弃手、地点直伤 | `discard_*`、`attach`、`damage`（take/deal 同 seq） |
| **B** 弱点闭环 | 进威胁区 → Forced → `[action][action]` 自弃 | `discard_card`（来源） |
| **C** Fight / Investigate 宏 | ammo/charge + 本检定 MODIFIER | `spend_token`、THIS_TEST register |
| **D** Free / 搜库 | `[fast]` 费用窗、Search top N | `search_deck`、`add_to_hand` |
| **E** 场景 / Codex / Resign | Parley、群体线索、Instead | 场景表 nest，非卡面 Policy |

**推荐顺序**：A1 → B1 → C1–C2 → A3–A4 → D → E。

---

## 5. 迭代形状（每批固定）

1. **Mint** Catalog + TC + handler（仅当种类需被听到 / 复用）  
2. **Compiler** 应展尽展：Python → JSON；每步标内联 / nest / PI；**禁糖**  
3. **Retarget / import** `python3 tools/arkhamdb_import.py`  
4. **Prove** headless（含默认确认路径）；同步 17 §5  

---

## 6. 本轮实施

### A1 + B1 起步 ✅
- 铸造：`discard_card` / `discard_from_hand` / `damage`（原 deal/take） / `attach`
- 编译：fail-by、附着、地点治疗、弱点自弃

### B1 运行时 + A3 ✅
- 威胁区弃置：`StateMutator` 清 `threat_area` / `play_area`
- `activate_action` 闭环（12102）：耗 2 行动 → 弃弱点 → 卸载触发
- `seq.framework.investigation_phase_ends` + Fire! Forced（非 Elite 有生命值卡）
- 附着后 `install_card`；地点调查员恐惧/伤害 template
- 指标：53 → **55**；SEQ-EFF-09 / ADB-41..43

**下一批**：C1 Fight ammo；敌人 defeated 触发（12132）；asset 承伤。

### 12106–08 Parley ✅
- 编译：`action_types: [activate, parley]`；成功 → `discard_card`（trait/title=Bystander @ controller_location）
- 借机：`AttackOfOpportunityResolver.provokes_for_types`；含 Parley/Resign/Fight/Evade 则不借机（**Engage 不豁免**）
- `seq.effect.discard_card` 统一去向：遭遇弃牌堆 / 玩家弃牌堆 / 否则 RFG

### 12112 Resign / 群体线索 ✅（应展尽展）
- Resign：`seq(resign)` 同帧内联；经 `seq.ability.resolve` 装载（禁真空）
- Fast 群体线索+伤：`spend_clues_group` + `deal_damage`（status=partial；分配交互后补）

### 12113 Engage（连结地点）✅（应展尽展）
- `seq`：PI `pick_target` → 内联 `move_enemy_to` → 内联 `engage_target`（§4.0.5 连续 then，不 nest）
- **Engage 默认会借机**；卡面「does not provoke…」→ `provokes_aoo: false` 覆盖
- 指标：ADB-48..50

### 12118–20 地点能力 ✅（Limit 运行时后补）
- 12118 Forced：discover → `discard_from_hand`（mode=choose）
- 12119 Reaction：discover → nest `seq.draw.investigator`（Limit once/round → partial）
- 12120 Action×2：`draw` amount=3（Limit once/game → partial）

### 12116 / 12122 / 12132 ✅
- 12116 Free：`nest_move_connecting` + `investigators_in_game_1_or_2`（Group limit → partial）
- 12132 Forced：`seq.enemy.defeat` WHEN → `take_horror` @ `each_at_source_location`
- 12122 Forced：`seq.enemy.attack` AFTER → `discard_card` @ `controlled_assets`
- 敌人进场 `install_triggered_abilities`；击败/弃置离场卸载

---

## 7. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-09-28 | v0.11 | 12112/12113 改内联（PI+L0）；纠正「有 Catalog 就 nest」 |
| 2026-09-28 | v0.10 | 12112/12113 应展尽展；`seq.effect.resign` / `seq.ability.resolve`；债清两笔 |
| 2026-09-28 | v0.9 | **翻译硬门槛**：禁真空；三分法（内联/nest/PI）；应展尽展禁糖；§3.1 债清单 |
| 2026-09-22 | v0.8 | `seq.enemy.defeat`；12116/22/32；controlled_assets discard；72/162 |
| 2026-09-22 | v0.7 | 12118–20 弃手/反应抽/双行动抽；nest_draw_investigator；68/162 |
| 2026-09-22 | v0.6 | 12113 Engage 连结；Engage 非借机豁免；`provokes_aoo` 覆盖；65/162 |
| 2026-09-22 | v0.5 | 12112 Resign 内联；群体线索 stub；62/162 |
| 2026-09-22 | v0.4 | 12106–08 Parley；action_types；discard 统一路由；57/162 |
| 2026-09-21 | v0.3 | B1 activate_action；A3 Fire! Forced；55/162 |
| 2026-09-21 | v0.2 | A1 落地；进度 53/162；heal Limit / Flood 首句 Attach |
| 2026-09-21 | v0.1 | 初稿；基线 35/162；开工 A1 |
