//! Minimal `legal` / `fold_guards` — GuardIntent Restrict ∪ Permit → Ok|Forbid.
//!
//! Full competition / tier / Silver Rule are **out of scope** (38: details elsewhere).
//! Provisional fold: stable policy-id order; match → Restrict sets Forbid, Permit sets Ok
//! (later matching Permit can clear an earlier Restrict).

use crate::world::{
    Data, GatePayload, GateScope, GuardPolarity, Policy, PolicyBody,
};

/// Verdict of folding all matching GuardIntent rows.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum LegalVerdict {
    Ok,
    Forbid,
}

/// Initiation class under guard (not every Data Intent is gated yet).
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum GuardedAct {
    Play { actor_id: String },
    Draw { actor_id: String },
    Trigger { actor_id: String },
    CommitToTest { actor_id: String },
    LeaveHand { actor_id: String },
    DiscoverClue { actor_id: String },
    SpendClue { actor_id: String },
    Attack { actor_id: String },
}

impl GuardedAct {
    pub fn actor_id(&self) -> &str {
        match self {
            Self::Play { actor_id }
            | Self::Draw { actor_id }
            | Self::Trigger { actor_id }
            | Self::CommitToTest { actor_id }
            | Self::LeaveHand { actor_id }
            | Self::DiscoverClue { actor_id }
            | Self::SpendClue { actor_id }
            | Self::Attack { actor_id } => actor_id,
        }
    }

    pub fn gate_kind(&self) -> &'static str {
        match self {
            Self::Play { .. } => "play",
            Self::Draw { .. } => "draw",
            Self::Trigger { .. } => "trigger",
            Self::CommitToTest { .. } => "commit_to_test",
            Self::LeaveHand { .. } => "leave_hand",
            Self::DiscoverClue { .. } => "discover_clue",
            Self::SpendClue { .. } => "spend_clue",
            Self::Attack { .. } => "attack",
        }
    }
}

/// `legal(data, act) = fold_guards(guards(data), act)` (38).
pub fn legal(data: &Data, act: &GuardedAct) -> LegalVerdict {
    fold_guards(data.constraints.policies.values(), act)
}

/// Fold matching GuardIntent policies in **policy id** order (BTreeMap).
pub fn fold_guards<'a, I>(policies: I, act: &GuardedAct) -> LegalVerdict
where
    I: IntoIterator<Item = &'a Policy>,
{
    let mut verdict = LegalVerdict::Ok;
    for policy in policies {
        let PolicyBody::GuardIntent { polarity, gate } = &policy.body else {
            continue;
        };
        if !gate_matches(gate, act) {
            continue;
        }
        match polarity {
            GuardPolarity::Restrict => verdict = LegalVerdict::Forbid,
            GuardPolarity::Permit => verdict = LegalVerdict::Ok,
        }
    }
    verdict
}

fn gate_matches(gate: &GatePayload, act: &GuardedAct) -> bool {
    if gate.kind_name() != act.gate_kind() {
        return false;
    }
    match gate {
        GatePayload::Draw { subject_id }
        | GatePayload::LeaveHand { subject_id }
        | GatePayload::DiscoverClue { subject_id }
        | GatePayload::SpendClue { subject_id }
        | GatePayload::Attack { subject_id } => subject_id == act.actor_id(),
        GatePayload::Play { scope }
        | GatePayload::Trigger { scope }
        | GatePayload::CommitToTest { scope } => scope_matches(scope, act.actor_id()),
    }
}

fn scope_matches(scope: &GateScope, actor_id: &str) -> bool {
    match scope {
        GateScope::Subject { subject_id } => subject_id == actor_id,
        // Peril frame: drawer is exempt from the restrict; others match.
        // Minimal: treat drawn frame as matching any non-drawer actor check
        // when asking about drawer → no match (exempt); when asking about
        // other actors we don't model yet — for foundation, peril Restrict
        // matches when actor_id != drawer_id (cannot play for non-drawer).
        GateScope::Peril { drawer_id, .. } => actor_id != drawer_id.as_str(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::intent::guard_policy;
    use crate::world::{Constraints, Data, GatePayload, GateScope, GuardPolarity};
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
    fn no_guards_is_ok() {
        let data = Data::default();
        let act = GuardedAct::Play {
            actor_id: "I".into(),
        };
        assert_eq!(legal(&data, &act), LegalVerdict::Ok);
    }

    #[test]
    fn restrict_play_forbids() {
        let data = data_with(vec![guard_policy(
            "g1",
            "T1",
            GuardPolarity::Restrict,
            GatePayload::Play {
                scope: GateScope::Subject {
                    subject_id: "I".into(),
                },
            },
        )]);
        assert_eq!(
            legal(
                &data,
                &GuardedAct::Play {
                    actor_id: "I".into()
                }
            ),
            LegalVerdict::Forbid
        );
        // Different actor — no match
        assert_eq!(
            legal(
                &data,
                &GuardedAct::Play {
                    actor_id: "J".into()
                }
            ),
            LegalVerdict::Ok
        );
    }

    #[test]
    fn permit_clears_prior_restrict() {
        // BTreeMap id order: a_restrict then z_permit → Permit last wins
        let data = data_with(vec![
            guard_policy(
                "a_restrict",
                "src",
                GuardPolarity::Restrict,
                GatePayload::Play {
                    scope: GateScope::Subject {
                        subject_id: "I".into(),
                    },
                },
            ),
            guard_policy(
                "z_permit",
                "src",
                GuardPolarity::Permit,
                GatePayload::Play {
                    scope: GateScope::Subject {
                        subject_id: "I".into(),
                    },
                },
            ),
        ]);
        assert_eq!(
            legal(
                &data,
                &GuardedAct::Play {
                    actor_id: "I".into()
                }
            ),
            LegalVerdict::Ok
        );
    }

    #[test]
    fn restrict_after_permit_forbids() {
        // id order: a_permit then z_restrict → Restrict last
        let data = data_with(vec![
            guard_policy(
                "a_permit",
                "src",
                GuardPolarity::Permit,
                GatePayload::Draw {
                    subject_id: "I".into(),
                },
            ),
            guard_policy(
                "z_restrict",
                "src",
                GuardPolarity::Restrict,
                GatePayload::Draw {
                    subject_id: "I".into(),
                },
            ),
        ]);
        assert_eq!(
            legal(
                &data,
                &GuardedAct::Draw {
                    actor_id: "I".into()
                }
            ),
            LegalVerdict::Forbid
        );
    }

    #[test]
    fn peril_restrict_exempts_drawer() {
        let data = data_with(vec![guard_policy(
            "peril",
            "T1",
            GuardPolarity::Restrict,
            GatePayload::Play {
                scope: GateScope::Peril {
                    drawer_id: "I".into(),
                    drawn_card_id: "T1".into(),
                    encounter_frame_id: "ef1".into(),
                },
            },
        )]);
        assert_eq!(
            legal(
                &data,
                &GuardedAct::Play {
                    actor_id: "I".into()
                }
            ),
            LegalVerdict::Ok
        );
        assert_eq!(
            legal(
                &data,
                &GuardedAct::Play {
                    actor_id: "J".into()
                }
            ),
            LegalVerdict::Forbid
        );
    }

    #[test]
    fn kind_mismatch_ignored() {
        let data = data_with(vec![guard_policy(
            "g1",
            "src",
            GuardPolarity::Restrict,
            GatePayload::Attack {
                subject_id: "I".into(),
            },
        )]);
        assert_eq!(
            legal(
                &data,
                &GuardedAct::Play {
                    actor_id: "I".into()
                }
            ),
            LegalVerdict::Ok
        );
    }
}
