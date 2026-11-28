# arkham_rules

Functional rules kernel (Rust). Shape follows
[`docs/design/37-world-structure.md`](../docs/design/37-world-structure.md) and
[`docs/design/38-functional-data-world.md`](../docs/design/38-functional-data-world.md)
(`World_FP ≜ Data`).

## This PR (Data foundation)

- `Snapshot` = `data` ⊕ `derived` ⊕ `run` ⊕ `gen`
- `Data` = `Board` × `Facts` × `Constraints` × `Limits` × `Framework` × `Seats` (+ `Audience`)
- **Board** = cards + regions only（物理；勿称「世界」）
- `FactInsert` / `ConstraintInsert` → `commit` 回报 `CommitReport.created`
- `GuardIntent`：`GuardPolarity::{Restrict, Permit}` 同一扇门
- `legal` / `fold_guards`：匹配 Guard → Restrict∪Permit → `Ok|Forbid`（最小稳定序；完整竞争另开）
- **不**含 FoldStat 折叠 / AmountPlan / Chuck / Eff M2 / gdext

```bash
cd arkham_rules && cargo test
```
