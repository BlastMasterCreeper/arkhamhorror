# arkham_rules

Functional rules kernel (Rust). Shape follows [`docs/design/37-world-structure.md`](../docs/design/37-world-structure.md).

## M1 (current)

- `Snapshot` = `auth` ⊕ `derived` ⊕ `run` ⊕ `gen`
- Token stacks on `Region`; `owned_regions` / `place` (not asset slots)
- `RegistrationPayload` ×5; engagement = `status`
- `commit(Intent[])`: `AdjustToken`, `FlipToken`, `MoveCard`, `RegInsert`/`RegRemove`, `SetExhausted`

```bash
cd arkham_rules && cargo test
```

Godot / gdext bridge is later (see [31-functional-host](../docs/design/31-functional-host.md)).
