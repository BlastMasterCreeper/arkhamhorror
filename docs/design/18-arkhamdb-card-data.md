# 18 — ArkhamDB 卡牌数据与引擎对照

> **数据源**：[`data/arkhamdb/`](../../data/arkhamdb/)（upstream [arkhamdb-json-data](https://github.com/Kamalisk/arkhamdb-json-data) 子集）  
> **状态**：v0.4 · 2026-07-06 · **Phase 4 完成**（Core 2026 设计表回填）

---

## 1. 目标

1. 以 **ArkhamDB JSON** 为卡池真值，对照本引擎 `CardDefinition` / `CardRegistry` / 设计增长表。
2. 从真实卡面统计 **关键词、能力类型、Restriction 线索**，回填 `06 §16`、`15 §17`、`12` 等待填表。
3. 分阶段导入：**Core 2026 → Revised Core → 各 Cycle**，避免一次性把 2000+ 张卡塞进仓库。

**裁定优先级不变**：Grimoire > 2026 Rulebook > ArkhamDB RR；JSON **文本**用于编译，**行为**以 design/ 为准。

---

## 2. 本地数据布局

```
data/arkhamdb/
  schema/           # card_schema.json 等
  index/            # types, packs, factions, cycles, encounters, subtypes
  pack/core/        # core_2026.json, core_2026_encounter.json（已同步）
  translations/zh-cn/pack/core/   # 中文卡名/文本（可选）
  reports/          # 分析脚本输出
  SOURCE.txt        # upstream 路径记录
tools/
  sync_arkhamdb_data.ps1      # 从本机 upstream 增量复制 pack
  analyze_arkhamdb_cards.ps1  # 统计报告（Windows，无需 Python）
  analyze_arkhamdb_cards.py   # 同上（跨平台，需 Python 3）
```

同步更多扩展：

```powershell
.\tools\sync_arkhamdb_data.ps1 -PackCodes dwl,tmm,tece -IncludeZhCn
python tools/analyze_arkhamdb_cards.py
```

> Windows：Python 请**手动安装**；勿用 Agent 跑 `winget` / 安装包（易被杀毒拦截）。见 [`setup-local-tools.md`](../setup-local-tools.md)。

---

## 3. Schema 要点（`schema/card_schema.json`）

| 字段 | 含义 | 引擎映射 |
|---|---|---|
| `code` | 全局唯一 ID（5 位+后缀） | `definition_id` |
| `type_code` | act/agenda/asset/enemy/event/skill/treachery/… | `CardDefinition.card_type` |
| `subtype_code` | weakness / basicweakness 等 | weakness 路由（15 §17.6） |
| `cost` | 资源费用；`null`=-，`-2`=X | `CardRegistry.resource_cost` |
| `text` / `back_text` | 卡面 HTML + `[symbol]` | Ability 编译输入 |
| `traits` | 句号分隔 | `traits[]` |
| `slot` | Hand / Arcane / … | asset 槽位 |
| `skill_*` | 技能图标 | commit / 检定 |
| `health` / `sanity` | 盟友 | asset |
| `enemy_*` | 战斗/猎杀数值 | `enemy_stats()` |
| `shroud` / `clues` | 地点 | investigate |
| `doom` | 场景 | act/agenda |
| `hidden` | 布尔 | 隐私 E4 |
| `encounter_code` | 遭遇套 | scenario deck |
| `tags` | hh/hd/pa/se/fa | 构筑规则（非运行时） |

数值哨兵见 upstream README：`null`→`-`，`-2`→`X`，`-3`→`*`，`-4`→`?`。

---

## 4. Core 2026 首轮统计（2026-07-06）

来源：`data/arkhamdb/reports/*.md`（`analyze_arkhamdb_cards.ps1`）。

### 4.1 玩家牌 `core_2026`（104 条目）

| type_code | 约 qty |
|---|---:|
| asset | 87 |
| event | 31 |
| skill | 12 |
| treachery（weakness） | 5 |
| investigator | 5 |

### 4.2 遭遇 `core_2026_encounter`（92 条目）

| type_code | 约 qty |
|---|---:|
| treachery | 54 |
| enemy | 33 |
| location | 26 |
| agenda / act / scenario | 18 |

### 4.3 能力/关键词文本命中（两包合计）

| 模式 | 命中 | 设计表 / 管线 |
|---|---:|---|
| `forced_bold` | 33 | **Forced · 直执**，不经 Initiation（已裁决） |
| `revelation_bold` | 32 | REVELATION · `seq.enter_hand` / encounter revelation |
| `action` | 49 | TRIGGERED_ACTION · Initiation + AOO |
| `reaction` | 29 | TRIGGERED_REACTION · Initiation |
| `fast` | 17 | Fast · Player Window |
| `elder_sign` | 5 | 调查员签名 · ST 子流程 |
| `hunter_text` | 13 | Hunter listener（③） |
| `retaliate_text` | 9 | Retaliate handler |
| `aloof_text` | 6 | REST / engage 条件 |
| `spawn_line` | 6 | `SpawnInstructionSpec`（①） |
| `prey_line` | 3 | `PreyInstructionSpec`（①） |
| `surge_text` | 4 | Surge 链 · 同 frame |
| `peril_text` | 2 | peril Register |
| `massive_text` | 2 | engage 拒绝 |
| `cannot` | 12 | RESTRICTION 增长表（人工细分 Intent） |
| `immune` | 0 | Core 2026 两包无 immune 文本 |
| `hidden` 字段 | ≥1 | 隐私 E4（见 encounter 包具体卡） |

---

## 5. 分阶段实施计划

### Phase 0 — 基础设施 ✅（本迭代）

- [x] 镜像 `schema` + `index` + Core 2026 英文/中文
- [x] `sync_arkhamdb_data.ps1` / `analyze_arkhamdb_cards.ps1`
- [x] 首轮 `reports/` + 本文档

### Phase 1 — 字段适配层（P0）✅

- [x] `tools/arkhamdb_import.py`：`ArkhamDbCard` → 引擎 `CardDefinition` 字典 → `data/arkhamdb/imported/{pack}.json`
- [x] `scripts/arkhamdb_card_loader.gd`：`load_imported_file` / `load_core_2026()` → `CardRegistry.register_definition`
- [x] 映射 `type_code`、`cost` 哨兵、`subtype_code`→weakness；首行关键词（Surge/Peril/Aloof/Hunter 等）；`ability_hints`（revelation/spawn/prey…）
- [x] 单元测试 ADB-01～06：Core 2026 166 张 + Local Map / In Harm's Way / Aerial Pursuit / Elokos / Cosmic Evils

**运行**：`python tools/arkhamdb_import.py`（导入后 Godot 测试通过 `ArkhamDbCardLoader` 读 `res://data/arkhamdb/imported/`）

### Phase 2 — 关键词与指令（P0/P1）✅

- [x] 首行文本解析 **Surge / Peril / Aloof / Hunter / Retaliate / Massive**（Phase 1 导入层；`hidden`/`permanent` 来自 JSON 字段）
- [x] 回填 `CardRegistry` 布尔/关键词字段：`is_hunter` / `is_retaliate` / `is_massive` / `has_surge` / `has_peril` / `is_permanent`；loader 同步 `hunter`/`retaliate`/`massive`
- [x] Spawn/Prey 文本 → JSON spec → `ArkhamDbInstructionCompiler` → `SpawnInstructionSpec` / `PreyInstructionSpec`
- [x] Core 2026 四张指令卡：12099 Farthest empty · 12114 lowest agility · 12164 most resources · 12009 Trish only
- [x] `SpawnLocationResolver`：`nearest_empty` / `farthest_empty`；`PreyResolver`：`resources` / `investigator_only`
- [x] 单元测试 ADB-07～13

**运行**：`python tools/arkhamdb_import.py` → Godot `ArkhamDbCardLoader.load_core_2026()`

### Phase 3 — 能力编译（P1）✅（竖切）

- [x] 文本分段：`tools/arkhamdb_abilities.py` → `ability_segments`（revelation / forced / reaction / action / fast）
- [x] 模板编译 → `compiled_abilities` JSON + `ArkhamDbAbilityCompiler` → `CardRegistry.register_revelation` / `register_triggered`
- [x] 首批模板：`take_horror` / `take_damage` / `lose_resources` / `lose_all_resources` / `enter_threat_area`
- [x] Core 2026 统计：分段存档；模板可表达子集已编译（`ability_compile_summary` in `_meta`）
- [ ] Forced → `TriggeredAbilityService` 直执 / LISTENER（效果模板已识别，触发器注册待接）
- [ ] Reaction/Action → `register_triggered` + Initiation（分段已存，待模板/脚本）
- [x] Free triggered（ArkhamDB `[fast]`）→ `register_as:free` + Player Window `list_free_abilities` / `activate_free`；锚 12046 ✅
- [ ] 全量 32+29+49 能力覆盖（当前为模板可表达子集）

**运行**：`python tools/arkhamdb_import.py` → `ArkhamDbCardLoader.load_core_2026()`

### Phase 4 — 设计表迭代回填（P1/P2）✅

- [x] `tools/backfill_design_tables.py` → [`data/arkhamdb/reports/phase4_core_2026_backfill.md`](../data/arkhamdb/reports/phase4_core_2026_backfill.md)
- [x] [06 §16.8 MODIFIER/RESTRICTION/LISTENER](06-registration-buff-model.md#168-core-2026-回填arkhamdb--phase-4)
- [x] [15 §17.14 遭遇卡清单](15-timing-entry-catalog.md#1714-core-2026-遭遇卡清单arkhamdb-回填)
- [x] [12 §1.2 Template/Script 快照](12-card-script-api.md#12-core-2026-选型快照arkhamdb--phase-4)
- [x] [open-questions-master.md](open-questions-master.md) OQ-ADB-01～05

**运行**：`python tools/arkhamdb_import.py` → `python tools/backfill_design_tables.py`

Gained characteristics 统计：[`core_2026_gained_characteristics.md`](../data/arkhamdb/reports/core_2026_gained_characteristics.md) · 设计 [06 §3.2–3.2.4](06-registration-buff-model.md#324-keywordprofile挂载-vs-表征-vs-消费已裁决)

### Phase 5 — 扩展包（P2+）

- [ ] `rcore` / `dwl` / … 按 cycle 同步
- [ ] Taboo / parallel / promo 单独策略
- [ ] CI：`analyze_arkhamdb_cards.ps1` 回归报告 diff

---

## 6. 与现有引擎模块对照

| ArkhamDB 现象 | 已有引擎 | 缺口 |
|---|---|---|
| 打出 asset/event | `Initiation` + `play_card` | on_play 编译（部分） |
| Revelation treachery | `CardAbilityService` + G3/G4 | Phase 3 模板编译 + 注册 ✅（部分） |
| Forced | `TriggeredAbilityService` 直执 | 分段+效果模板已识别，触发器注册待接 |
| Reaction/Action | Initiation + ResponseWindow | 分段已存，待模板/脚本 |
| Spawn/Prey | `SpawnInstructionSpec` / `PreyInstructionSpec` | Phase 2 编译 + 运行时解析 ✅ |
| Hidden | E4 + `FORBID_LEAVE_HAND` | 从 `hidden` 字段批量 |
| Surge/Peril | ENC 测试 + Register | 卡表驱动测试 fixture |

---

## 7. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-07-06 | v0.5 | Phase 4 完成 + Gained characteristics 报告（06 §3.2） |
| 2026-07-06 | v0.4 | Phase 4：设计表回填报告 + 06/12/15/OQ 同步 |
| 2026-07-06 | v0.3 | Phase 3：能力分段、模板编译、ADB-14～17 |
| 2026-07-06 | v0.2 | Phase 2：关键词回填、Spawn/Prey 编译、ADB-07～13 |
| 2026-07-06 | v0.1 | Phase 0：Core 2026 镜像、分析脚本、首轮统计、实施计划 |
