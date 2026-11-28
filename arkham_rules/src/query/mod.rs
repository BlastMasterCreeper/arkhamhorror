//! Query-station folds — minimal FoldStat (38).
//!
//! `query_stat(data, base, key) = fold(folds(data), base)`.
//! AmountPlan / Assign / Chuck are **out of scope**.

use crate::world::{Data, ModifierPayload, Policy, PolicyBody};

/// Fold all matching `FoldStat` policies onto `base` for `stat_key`.
/// Stable order = policy id (BTreeMap). Ops: `add` | `set` (unknown op = no-op).
/// Empty `condition` always matches; non-empty condition matching is stubbed as always-true (M2).
pub fn query_stat(data: &Data, base: i32, stat_key: &str) -> i32 {
    fold_stats(data.constraints.policies.values(), base, stat_key)
}

pub fn fold_stats<'a, I>(policies: I, mut value: i32, stat_key: &str) -> i32
where
    I: IntoIterator<Item = &'a Policy>,
{
    for policy in policies {
        let PolicyBody::FoldStat { fold } = &policy.body else {
            continue;
        };
        if !fold_matches(fold, stat_key) {
            continue;
        }
        value = apply_op(value, fold);
    }
    value
}

fn fold_matches(fold: &ModifierPayload, stat_key: &str) -> bool {
    if fold.stat != stat_key {
        return false;
    }
    // Condition language deferred; empty = always, non-empty = treat as match for thin cut.
    true
}

fn apply_op(current: i32, fold: &ModifierPayload) -> i32 {
    match fold.op.as_str() {
        "add" => current.saturating_add(fold.value),
        "set" => fold.value,
        _ => current,
    }
}

/// Helper: FoldStat policy shell.
pub fn fold_stat_policy(
    id: impl Into<String>,
    source_card_id: impl Into<String>,
    fold: ModifierPayload,
) -> Policy {
    use crate::world::{InfoShell, Subject};
    let id = id.into();
    let source = source_card_id.into();
    Policy {
        shell: InfoShell {
            id: id.clone(),
            source_card_id: source.clone(),
            subject: Subject::Bound { card_id: source },
            lifetime: "while_in_play".into(),
            bound_id: String::new(),
        },
        body: PolicyBody::FoldStat { fold },
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::world::{Constraints, Data};
    use std::collections::BTreeMap;

    fn data_with(policies: Vec<Policy>) -> Data {
        let mut map = BTreeMap::new();
        for p in policies {
            map.insert(p.shell.id.clone(), p);
        }
        Data {
            constraints: Constraints { policies: map },
            ..Data::default()
        }
    }

    #[test]
    fn no_folds_returns_base() {
        let data = Data::default();
        assert_eq!(query_stat(&data, 4, "combat"), 4);
    }

    #[test]
    fn add_stacks_in_id_order() {
        let data = data_with(vec![
            fold_stat_policy(
                "a_plus1",
                "A",
                ModifierPayload {
                    stat: "combat".into(),
                    op: "add".into(),
                    value: 1,
                    ..ModifierPayload::default()
                },
            ),
            fold_stat_policy(
                "b_plus2",
                "B",
                ModifierPayload {
                    stat: "combat".into(),
                    op: "add".into(),
                    value: 2,
                    ..ModifierPayload::default()
                },
            ),
        ]);
        // Catalog base fight 4 → +1 +2 = 7
        assert_eq!(query_stat(&data, 4, "combat"), 7);
    }

    #[test]
    fn set_overrides_then_later_add() {
        let data = data_with(vec![
            fold_stat_policy(
                "a_add",
                "A",
                ModifierPayload {
                    stat: "willpower".into(),
                    op: "add".into(),
                    value: 3,
                    ..ModifierPayload::default()
                },
            ),
            fold_stat_policy(
                "m_set",
                "M",
                ModifierPayload {
                    stat: "willpower".into(),
                    op: "set".into(),
                    value: 1,
                    ..ModifierPayload::default()
                },
            ),
            fold_stat_policy(
                "z_add",
                "Z",
                ModifierPayload {
                    stat: "willpower".into(),
                    op: "add".into(),
                    value: 1,
                    ..ModifierPayload::default()
                },
            ),
        ]);
        // base 5 → +3 → set 1 → +1 = 2
        assert_eq!(query_stat(&data, 5, "willpower"), 2);
    }

    #[test]
    fn other_stat_ignored() {
        let data = data_with(vec![fold_stat_policy(
            "g1",
            "A",
            ModifierPayload {
                stat: "agility".into(),
                op: "add".into(),
                value: 9,
                ..ModifierPayload::default()
            },
        )]);
        assert_eq!(query_stat(&data, 2, "combat"), 2);
    }

    #[test]
    fn unknown_op_is_noop() {
        let data = data_with(vec![fold_stat_policy(
            "g1",
            "A",
            ModifierPayload {
                stat: "combat".into(),
                op: "mul".into(),
                value: 99,
                ..ModifierPayload::default()
            },
        )]);
        assert_eq!(query_stat(&data, 4, "combat"), 4);
    }
}
