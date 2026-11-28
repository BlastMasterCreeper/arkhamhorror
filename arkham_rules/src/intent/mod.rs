//! Unique Data writers — commit(Intent[]) → (Snapshot', CommitReport).

use crate::world::{
    Audience, Data, GatePayload, GainedCharacteristic, GuardPolarity, InfoShell, LogEntry, Policy,
    PolicyBody, Relation, Snapshot, Subject, TOKEN_SUPPLY,
};

#[derive(Clone, Debug)]
pub enum Intent {
    TransferToken {
        token_type: String,
        amount: i32,
        from_region: String,
        to_region: String,
    },
    MoveCard {
        card_id: String,
        from_region: String,
        to_region: String,
    },
    /// Insert a Facts.Relation (CREATED).
    FactInsert {
        relation: Relation,
    },
    /// Insert a Constraints.Policy (CREATED).
    ConstraintInsert {
        policy: Policy,
    },
    /// Insert Facts.gains row (CREATED) — possession mark, not Policy.
    GainInsert {
        gain: GainedCharacteristic,
    },
    /// Remove Facts.gains by id (CREATED when present).
    GainRemove {
        id: String,
    },
    /// Append Chronicle log line (CREATED).
    ChronicleLog {
        text: String,
        round: i32,
    },
    /// Upsert Chronicle remembered key (CREATED).
    ChronicleRemember {
        key: String,
        value: String,
    },
    CompanionRemove {
        id: String,
    },
    SetExhausted {
        card_id: String,
        exhausted: bool,
    },
    SetSeatActions {
        investigator_id: String,
        actions_remaining: i32,
    },
    /// Permission write — authoritative but **never** CREATED (38 / 07).
    SetAudience {
        card_id: String,
        audience: Audience,
    },
}

/// Settlement-sort write happened on Data (**Audience excluded**).
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct CommitReport {
    pub created: bool,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum CommitError {
    MissingRegion(String),
    MissingCard(String),
    MissingSeat(String),
    MissingCompanion(String),
    MissingGain(String),
    NonPositiveAmount(i32),
    InsufficientTokens {
        region_id: String,
        token_type: String,
        have: i32,
        need: i32,
    },
    CardNotInRegion {
        card_id: String,
        region_id: String,
    },
}

/// Apply intents in order. `created` iff settlement-sort Data changed (Audience ignored).
pub fn commit(mut snap: Snapshot, intents: &[Intent]) -> Result<(Snapshot, CommitReport), CommitError> {
    let before = settlement_fingerprint(&snap.data);
    for intent in intents {
        apply_one(&mut snap, intent)?;
    }
    let created = settlement_fingerprint(&snap.data) != before;
    if created {
        snap.gen = snap.gen.saturating_add(1);
    }
    Ok((snap, CommitReport { created }))
}

/// Sandbox commit: clone → apply → report; **does not** mutate `snap`.
/// Same CREATED rule as [`commit`] (Audience writes do not set `created`).
pub fn dry_run(snap: &Snapshot, intents: &[Intent]) -> Result<CommitReport, CommitError> {
    let (_sandbox, report) = commit(snap.clone(), intents)?;
    Ok(report)
}

/// Fingerprint of Data settlement partitions — excludes `audience` (Permission, non-CREATED).
fn settlement_fingerprint(data: &Data) -> String {
    let view = serde_json::json!({
        "board": data.board,
        "facts": data.facts,
        "constraints": data.constraints,
        "limits": data.limits,
        "framework": data.framework,
        "seats": data.seats,
        "next_id": data.next_id,
    });
    serde_json::to_string(&view).expect("settlement fingerprint")
}

fn apply_one(snap: &mut Snapshot, intent: &Intent) -> Result<(), CommitError> {
    match intent {
        Intent::TransferToken {
            token_type,
            amount,
            from_region,
            to_region,
        } => {
            if *amount <= 0 {
                return Err(CommitError::NonPositiveAmount(*amount));
            }
            debit_stack(snap, from_region, token_type, *amount)?;
            credit_stack(snap, to_region, token_type, *amount)?;
            Ok(())
        }
        Intent::MoveCard {
            card_id,
            from_region,
            to_region,
        } => {
            {
                let from = snap
                    .data
                    .board
                    .regions
                    .get_mut(from_region)
                    .ok_or_else(|| CommitError::MissingRegion(from_region.clone()))?;
                let pos = from
                    .card_ids
                    .iter()
                    .position(|c| c == card_id)
                    .ok_or_else(|| CommitError::CardNotInRegion {
                        card_id: card_id.clone(),
                        region_id: from_region.clone(),
                    })?;
                from.card_ids.remove(pos);
            }
            let to = snap
                .data
                .board
                .regions
                .get_mut(to_region)
                .ok_or_else(|| CommitError::MissingRegion(to_region.clone()))?;
            to.card_ids.push(card_id.clone());
            Ok(())
        }
        Intent::FactInsert { relation } => {
            snap.data
                .facts
                .relations
                .insert(relation.shell.id.clone(), relation.clone());
            Ok(())
        }
        Intent::ConstraintInsert { policy } => {
            snap.data
                .constraints
                .policies
                .insert(policy.shell.id.clone(), policy.clone());
            Ok(())
        }
        Intent::GainInsert { gain } => {
            snap.data
                .facts
                .gains
                .insert(gain.id.clone(), gain.clone());
            Ok(())
        }
        Intent::GainRemove { id } => {
            if snap.data.facts.gains.remove(id).is_none() {
                return Err(CommitError::MissingGain(id.clone()));
            }
            Ok(())
        }
        Intent::ChronicleLog { text, round } => {
            snap.data.facts.chronicle.log.push(LogEntry {
                text: text.clone(),
                round: *round,
            });
            Ok(())
        }
        Intent::ChronicleRemember { key, value } => {
            snap.data
                .facts
                .chronicle
                .remembered
                .insert(key.clone(), value.clone());
            Ok(())
        }
        Intent::CompanionRemove { id } => {
            let gone = snap.data.facts.relations.remove(id).is_some()
                || snap.data.constraints.policies.remove(id).is_some();
            if !gone {
                return Err(CommitError::MissingCompanion(id.clone()));
            }
            Ok(())
        }
        Intent::SetExhausted { card_id, exhausted } => {
            let card = snap
                .data
                .board
                .cards
                .get_mut(card_id)
                .ok_or_else(|| CommitError::MissingCard(card_id.clone()))?;
            card.exhausted = *exhausted;
            Ok(())
        }
        Intent::SetSeatActions {
            investigator_id,
            actions_remaining,
        } => {
            let seat = snap
                .data
                .seats
                .get_mut(investigator_id)
                .ok_or_else(|| CommitError::MissingSeat(investigator_id.clone()))?;
            seat.actions_remaining = *actions_remaining;
            Ok(())
        }
        Intent::SetAudience { card_id, audience } => {
            snap.data.audience.insert(card_id.clone(), *audience);
            Ok(())
        }
    }
}

fn debit_stack(
    snap: &mut Snapshot,
    region_id: &str,
    token_type: &str,
    amount: i32,
) -> Result<(), CommitError> {
    if region_id == TOKEN_SUPPLY {
        return Ok(());
    }
    let region = snap
        .data
        .board
        .regions
        .get_mut(region_id)
        .ok_or_else(|| CommitError::MissingRegion(region_id.to_string()))?;
    let cur = region.token_stacks.get(token_type).copied().unwrap_or(0);
    if cur < amount {
        return Err(CommitError::InsufficientTokens {
            region_id: region_id.to_string(),
            token_type: token_type.to_string(),
            have: cur,
            need: amount,
        });
    }
    let next = cur - amount;
    if next == 0 {
        region.token_stacks.remove(token_type);
    } else {
        region.token_stacks.insert(token_type.to_string(), next);
    }
    Ok(())
}

fn credit_stack(
    snap: &mut Snapshot,
    region_id: &str,
    token_type: &str,
    amount: i32,
) -> Result<(), CommitError> {
    if region_id == TOKEN_SUPPLY {
        return Ok(());
    }
    let region = snap
        .data
        .board
        .regions
        .get_mut(region_id)
        .ok_or_else(|| CommitError::MissingRegion(region_id.to_string()))?;
    let cur = region.token_stacks.get(token_type).copied().unwrap_or(0);
    region
        .token_stacks
        .insert(token_type.to_string(), cur + amount);
    Ok(())
}

pub fn engagement_relation(
    id: impl Into<String>,
    source_card_id: impl Into<String>,
    enemy_id: impl Into<String>,
    investigator_id: impl Into<String>,
) -> Relation {
    Relation::engagement(id, source_card_id, enemy_id, investigator_id)
}

/// Helper: Facts.gains row (possession mark).
pub fn gained(
    id: impl Into<String>,
    card_id: impl Into<String>,
    kind: impl Into<String>,
    characteristic_id: impl Into<String>,
) -> GainedCharacteristic {
    GainedCharacteristic {
        id: id.into(),
        card_id: card_id.into(),
        kind: kind.into(),
        characteristic_id: characteristic_id.into(),
        source_kind: "effect".into(),
        lifetime: "while_in_play".into(),
    }
}

/// Helper: GuardIntent policy with given polarity (foundation stub).
pub fn guard_policy(
    id: impl Into<String>,
    source_card_id: impl Into<String>,
    polarity: GuardPolarity,
    gate: GatePayload,
) -> Policy {
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
        body: PolicyBody::GuardIntent { polarity, gate },
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::world::{
        Board, Card, CardType, Data, Face, GatePayload, GateScope, GuardPolarity, PolicyBody,
        Region, Seat, Snapshot,
    };
    use std::collections::BTreeMap;

    fn mini_snap() -> Snapshot {
        let mut cards = BTreeMap::new();
        cards.insert(
            "I".into(),
            Card {
                id: "I".into(),
                definition_id: "01001".into(),
                card_type: CardType::Investigator,
                owner_id: "P1".into(),
                controller_id: "P1".into(),
                face: Face::A,
                ..Card::default()
            },
        );
        cards.insert(
            "L".into(),
            Card {
                id: "L".into(),
                definition_id: "01111".into(),
                card_type: CardType::Location,
                face: Face::B,
                ..Card::default()
            },
        );
        cards.insert(
            "C1".into(),
            Card {
                id: "C1".into(),
                definition_id: "06111".into(),
                card_type: CardType::Skill,
                owner_id: "P1".into(),
                controller_id: "P1".into(),
                ..Card::default()
            },
        );

        let mut regions = BTreeMap::new();
        regions.insert(
            "pool_P1".into(),
            Region {
                id: "pool_P1".into(),
                place: "resource_pool".into(),
                host_player_id: "P1".into(),
                token_stacks: BTreeMap::from([("resource".into(), 5)]),
                ..Region::default()
            },
        );
        regions.insert(
            "hand_I".into(),
            Region {
                id: "hand_I".into(),
                place: "hand".into(),
                host_card_id: "I".into(),
                ..Region::default()
            },
        );
        regions.insert(
            "deck_I".into(),
            Region {
                id: "deck_I".into(),
                place: "deck".into(),
                host_card_id: "I".into(),
                shape: crate::world::RegionShape::Deck,
                card_ids: vec!["C1".into()],
                ..Region::default()
            },
        );
        regions.insert(
            "on_L".into(),
            Region {
                id: "on_L".into(),
                place: "on".into(),
                host_card_id: "L".into(),
                card_ids: vec!["I".into()],
                ..Region::default()
            },
        );

        let mut seats = BTreeMap::new();
        seats.insert("I".into(), Seat::fresh(3));

        Snapshot {
            data: Data {
                board: Board { cards, regions },
                seats,
                framework: crate::world::Framework {
                    round: 1,
                    lead_investigator_id: "I".into(),
                    active_investigator_id: "I".into(),
                    ..Default::default()
                },
                ..Data::default()
            },
            ..Snapshot::default()
        }
    }

    #[test]
    fn empty_commit_is_not_created() {
        let s0 = mini_snap();
        let gen0 = s0.gen;
        let (s1, report) = commit(s0, &[]).unwrap();
        assert!(!report.created);
        assert_eq!(s1.gen, gen0);
    }

    #[test]
    fn fact_insert_engagement_is_created() {
        let s0 = mini_snap();
        let rel = engagement_relation("r1", "E", "E", "I");
        let (s1, report) = commit(s0, &[Intent::FactInsert { relation: rel }]).unwrap();
        assert!(report.created);
        assert!(s1.data.facts.relations.contains_key("r1"));
        assert!(s1.is_engaged_with("E", "I"));
        assert_eq!(s1.gen, 1);
    }

    #[test]
    fn constraint_insert_restrict_and_permit_are_created() {
        let s0 = mini_snap();
        let restrict = guard_policy(
            "g_restrict",
            "T1",
            GuardPolarity::Restrict,
            GatePayload::Play {
                scope: GateScope::Peril {
                    drawer_id: "I".into(),
                    drawn_card_id: "T1".into(),
                    encounter_frame_id: "ef1".into(),
                },
            },
        );
        let permit = guard_policy(
            "g_permit",
            "A1",
            GuardPolarity::Permit,
            GatePayload::Play {
                scope: GateScope::Subject {
                    subject_id: "I".into(),
                },
            },
        );
        let (s1, report) = commit(
            s0,
            &[
                Intent::ConstraintInsert { policy: restrict },
                Intent::ConstraintInsert { policy: permit },
            ],
        )
        .unwrap();
        assert!(report.created);
        assert!(s1.data.constraints.policies.contains_key("g_restrict"));
        assert!(s1.data.constraints.policies.contains_key("g_permit"));
        match &s1.data.constraints.policies["g_restrict"].body {
            PolicyBody::GuardIntent {
                polarity: GuardPolarity::Restrict,
                gate,
            } => assert_eq!(gate.kind_name(), "play"),
            other => panic!("expected Restrict GuardIntent, got {other:?}"),
        }
        match &s1.data.constraints.policies["g_permit"].body {
            PolicyBody::GuardIntent {
                polarity: GuardPolarity::Permit,
                ..
            } => {}
            other => panic!("expected Permit GuardIntent, got {other:?}"),
        }
    }

    #[test]
    fn resource_pool_binds_player_not_investigator_card() {
        let s = mini_snap();
        let pool = s.region_for_player_place("P1", "resource_pool").unwrap();
        assert!(pool.host_card_id.is_empty());
        assert_eq!(pool.host_player_id, "P1");
        assert_eq!(s.resources_of("P1"), 5);
        assert!(s.region_for_place("I", "resource_pool").is_none());
    }

    #[test]
    fn move_card_and_seat_write_are_created() {
        let s0 = mini_snap();
        let (s1, report) = commit(
            s0,
            &[
                Intent::MoveCard {
                    card_id: "C1".into(),
                    from_region: "deck_I".into(),
                    to_region: "hand_I".into(),
                },
                Intent::SetSeatActions {
                    investigator_id: "I".into(),
                    actions_remaining: 2,
                },
            ],
        )
        .unwrap();
        assert!(report.created);
        assert_eq!(s1.data.board.regions["hand_I"].card_ids, vec!["C1".to_string()]);
        assert_eq!(s1.data.seats["I"].actions_remaining, 2);
        // seats live on Data, not Board
        let board = serde_json::to_value(&s1.data.board).unwrap();
        assert!(!board.as_object().unwrap().contains_key("seats"));
    }

    #[test]
    fn dry_run_reports_created_without_mutating() {
        let s0 = mini_snap();
        let gen0 = s0.gen;
        let rel = engagement_relation("r_dry", "E", "E", "I");
        let report = dry_run(
            &s0,
            &[Intent::FactInsert {
                relation: rel.clone(),
            }],
        )
        .unwrap();
        assert!(report.created);
        // Original unchanged
        assert!(!s0.data.facts.relations.contains_key("r_dry"));
        assert_eq!(s0.gen, gen0);
        // Live commit still works
        let (s1, live) = commit(s0, &[Intent::FactInsert { relation: rel }]).unwrap();
        assert!(live.created);
        assert!(s1.data.facts.relations.contains_key("r_dry"));
    }

    #[test]
    fn audience_write_is_not_created() {
        use crate::world::Audience;
        let s0 = mini_snap();
        let gen0 = s0.gen;
        let report = dry_run(
            &s0,
            &[Intent::SetAudience {
                card_id: "C1".into(),
                audience: Audience::Controller,
            }],
        )
        .unwrap();
        assert!(!report.created);
        let (s1, live) = commit(
            s0,
            &[Intent::SetAudience {
                card_id: "C1".into(),
                audience: Audience::Controller,
            }],
        )
        .unwrap();
        assert!(!live.created);
        assert_eq!(s1.gen, gen0);
        assert_eq!(s1.data.audience.get("C1"), Some(&Audience::Controller));
    }

    #[test]
    fn dry_run_propagates_commit_errors() {
        let s0 = mini_snap();
        let err = dry_run(
            &s0,
            &[Intent::MoveCard {
                card_id: "missing".into(),
                from_region: "deck_I".into(),
                to_region: "hand_I".into(),
            }],
        )
        .unwrap_err();
        assert!(matches!(err, CommitError::CardNotInRegion { .. }));
        assert!(!s0.data.board.regions["deck_I"].card_ids.is_empty());
    }

    #[test]
    fn gain_insert_and_remove_are_created() {
        let s0 = mini_snap();
        let g = gained("gain1", "C1", "keyword", "surge");
        let report = dry_run(&s0, &[Intent::GainInsert { gain: g.clone() }]).unwrap();
        assert!(report.created);
        assert!(!s0.data.facts.gains.contains_key("gain1"));

        let (s1, live) = commit(s0, &[Intent::GainInsert { gain: g }]).unwrap();
        assert!(live.created);
        assert_eq!(s1.data.facts.gains["gain1"].characteristic_id, "surge");

        let (s2, rem) = commit(
            s1,
            &[Intent::GainRemove {
                id: "gain1".into(),
            }],
        )
        .unwrap();
        assert!(rem.created);
        assert!(!s2.data.facts.gains.contains_key("gain1"));
    }

    #[test]
    fn chronicle_log_and_remember_are_created() {
        let s0 = mini_snap();
        let (s1, report) = commit(
            s0,
            &[
                Intent::ChronicleLog {
                    text: "remembered the elder sign".into(),
                    round: 1,
                },
                Intent::ChronicleRemember {
                    key: "visited_museum".into(),
                    value: "true".into(),
                },
            ],
        )
        .unwrap();
        assert!(report.created);
        assert_eq!(s1.data.facts.chronicle.log.len(), 1);
        assert_eq!(s1.data.facts.chronicle.log[0].round, 1);
        assert_eq!(
            s1.data.facts.chronicle.remembered.get("visited_museum"),
            Some(&"true".to_string())
        );
    }
}
