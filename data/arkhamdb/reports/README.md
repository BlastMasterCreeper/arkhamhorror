# ArkhamDB 分析报告

| 报告 | 说明 |
|---|---|
| [`core_2026_inventory.md`](core_2026_inventory.md) | 玩家包字段/能力模式统计 |
| [`core_2026_encounter_inventory.md`](core_2026_encounter_inventory.md) | 遭遇包统计 |
| [`core_2026_design_gaps.md`](core_2026_design_gaps.md) | 设计表回填线索（原始 pack 分析） |
| [`field_mapping.md`](field_mapping.md) | ArkhamDB 字段 → 引擎字段 |
| [`phase4_core_2026_backfill.md`](phase4_core_2026_backfill.md) | **Phase 4** 设计表回填（imported JSON） |
| [`core_2026_gained_characteristics.md`](core_2026_gained_characteristics.md) | **Gained characteristics** 模式统计（06 §3.2） |

**生成**：

```bash
python tools/analyze_arkhamdb_cards.py
python tools/arkhamdb_import.py
python tools/backfill_design_tables.py
```
