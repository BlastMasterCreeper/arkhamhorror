# 19 — Core 2026（2.0 基础）卡牌翻译路线图

> **依赖**：[07-composition](07-composition.md)、[12-card-script-api](12-card-script-api.md)、[17-seq-runtime](17-seq-runtime.md)、[18-arkhamdb-card-data](18-arkhamdb-card-data.md)、[effect-translation.mdc](../../.cursor/rules/effect-translation.mdc)  
> **状态**：v0.3 · 2026-09-21 — A1 + B1 运行时 + A3 Fire! Forced  
> **范围**：`core_2026` + `core_2026_encounter`（约 166 张 / 162 段能力）

---

## 1. 口径（已裁决）

| 来源 | 译法 |
|---|---|
| 规则书手续 | 命名流程 `seq.*` |
| 卡牌正文 | 效果组合（Composition）静态树 → 装载到已有 seq → 解释 |
| 纸面无名可解释效果 | 铸造 `seq.effect.*`（参数化），禁止 `seq.card…`、真空 Atom/Register |

覆盖率**不是 KPI**。完成度看：段落实例能 dry-run、能 nest、能被 When/After 听到。

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

数据源：`data/arkhamdb/imported/*.json` · `_meta.ability_compile_summary`。

---

## 3. 完成定义（DoD）

每段能力：

1. 静态树：控制流 + 叶子 `nest flow_id`
2. 所需 `seq.effect.*` / 规则 seq 已在 Catalog
3. Hook：`register_as` + `match_kind` / `window` / `action_cost`
4. Headless：compile 形状 + 至少一条运行时路径
5. 选型可查（template vs 手写同等树 · OQ-12-01）

---

## 4. 分轨（按能力簇）

| 轨 | 内容 | 先铸的典型 `seq.effect.*` |
|---|---|---|
| **A** 遭遇显现 / Forced | 检定 fail / fail-by、Attach、弃手、地点直伤 | `discard_*`、`attach`、`deal_damage` |
| **B** 弱点闭环 | 进威胁区 → Forced → `[action][action]` 自弃 | `discard_card`（来源） |
| **C** Fight / Investigate 宏 | ammo/charge + 本检定 MODIFIER | `spend_token`、THIS_TEST register |
| **D** Free / 搜库 | `[fast]` 费用窗、Search top N | `search_deck`、`add_to_hand` |
| **E** 场景 / Codex / Resign | Parley、群体线索、Instead | 场景表 nest，非卡面 Policy |

**推荐顺序**：A1 → B1 → C1–C2 → A3–A4 → D → E。

---

## 5. 迭代形状（每批固定）

1. **Mint** Catalog + TC + handler  
2. **Compiler** Python template → JSON；GDScript nest 节点  
3. **Retarget / import** `python3 tools/arkhamdb_import.py`  
4. **Prove** headless；同步 17 §5  

---

## 6. 本轮实施

### A1 + B1 起步 ✅
- 铸造：`discard_card` / `discard_from_hand` / `deal_damage` / `attach`
- 编译：fail-by、附着、地点治疗、弱点自弃

### B1 运行时 + A3 ✅
- 威胁区弃置：`StateMutator` 清 `threat_area` / `play_area`
- `activate_action` 闭环（12102）：耗 2 行动 → 弃弱点 → 卸载触发
- `seq.framework.investigation_phase_ends` + Fire! Forced（非 Elite 有生命值卡）
- 附着后 `install_card`；地点调查员恐惧/伤害 template
- 指标：53 → **55**；SEQ-EFF-09 / ADB-41..43

**下一批**：C1 Fight ammo；敌人 defeated 触发（12132）；asset 承伤。

---

## 7. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-09-21 | v0.3 | B1 activate_action；A3 Fire! Forced；55/162 |
| 2026-09-21 | v0.2 | A1 落地；进度 53/162；heal Limit / Flood 首句 Attach |
| 2026-09-21 | v0.1 | 初稿；基线 35/162；开工 A1 |
