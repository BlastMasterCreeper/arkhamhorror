# 19 — Core 2026（2.0 基础）卡牌翻译路线图

> **依赖**：[07-composition](07-composition.md)、[12-card-script-api](12-card-script-api.md)、[17-seq-runtime](17-seq-runtime.md)、[18-arkhamdb-card-data](18-arkhamdb-card-data.md)、[effect-translation.mdc](../../.cursor/rules/effect-translation.mdc)  
> **状态**：v0.2 · 2026-09-21 — A1 铸造 + 编译落地；基线对照见 §2  
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
| **A1 后** | 玩家 | 72 | **21** | 51 |
| **A1 后** | 遭遇 | 90 | **32** | 58 |
| **A1 后** | **合计** | **162** | **53** | **109** |

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

## 6. 本轮实施（A1 + B1 起步）✅

- 铸造：`seq.effect.discard_card`、`discard_from_hand`、`deal_damage`、`attach`（最近无同名 / 本地点）
- 编译：检定失败伤害（12165）、fail-by 弃手/资源（12128）、fail-by 行动/线索（12158）、Fire!/Flood/Arcane Lock 附着、地点治疗（12117）、威胁区自弃 `[action][action]`（B1）
- 指标：合计 35 → **53**；SEQ-EFF-06..08 / ADB-37..40

**下一批**：B1 运行时 activate_action 闭环测例；A3 Forced 地点伤；C1 Fight ammo。

---

## 7. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-09-21 | v0.2 | A1 落地；进度 53/162；heal Limit / Flood 首句 Attach |
| 2026-09-21 | v0.1 | 初稿；基线 35/162；开工 A1 |
