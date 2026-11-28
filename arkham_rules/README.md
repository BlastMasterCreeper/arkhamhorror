# arkham_rules

Functional rules kernel (Rust). Shape follows
[`docs/design/37-world-structure.md`](../docs/design/37-world-structure.md) and
[`docs/design/38-functional-data-world.md`](../docs/design/38-functional-data-world.md)
(`World_FP ≜ Data`).

## Current

- `Snapshot` = `data` ⊕ `derived` ⊕ `run` ⊕ `gen`
- `Data` = `Board` × `Facts` × `Constraints` × `Limits` × `Framework` × `Seats` (+ `Audience`)
- **Board** = cards + regions only（物理；勿称「世界」）
- `commit` / `dry_run` · `legal` / `fold_guards` · Gain / Chronicle
- **M2 Eff**：`Do`/`Empty`/`Pass`/`Seq`/`If`/`Nest`/`Ask` + `plan`/`step`/`answer`；外置 `Catalog`
- **FoldStat**：`query_stat` / `fold_stats`（`add`/`set`）
- **AmountPlan**：建 Plan → FoldStat 叠量 → Assign（PI）→ `settle_intents`；**不**含 Chuck / gdext

```bash
cd arkham_rules && cargo test
```
