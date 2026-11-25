# arkham_rules

Functional rules kernel (Rust). Shape follows [`docs/design/37-world-structure.md`](../docs/design/37-world-structure.md).

## Current (M1 + M2)

- `Snapshot` = `auth` ⊕ `derived` ⊕ `run` ⊕ `gen`
- Token stacks on `Region`; `owned_regions` / `place` (not asset slots)
- Investigator turn economy / eliminated / resigned on `Auth.seats` (not `Card`)
- `RegistrationPayload` ×5; engagement = `status`
- `LimitStore`: `limit_key` + `occupancies` (not `slot_id` / asset-slot confusion)
- `commit(Intent[])`: token/card/reg/exhaust + `SetSeatActions` / `SetSeatOutcome`
- **Eff** subset: `Do` / `Empty` / `Pass` / `Seq` / `If` / `Nest` / `Ask` + `plan` / `step` / `answer`
- Sample flow: `seq.draw.investigator` body = `MoveCard` deck→hand

```bash
cd arkham_rules && cargo test
```

Godot / gdext bridge is later (see [31-functional-host](../docs/design/31-functional-host.md) M3).
