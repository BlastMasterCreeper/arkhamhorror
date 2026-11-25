//! Unique auth writers — commit(Intent[]) → Snapshot'.

use crate::world::{
    Registration, RegistrationPayload, Snapshot, StatusPayload, Subject, TOKEN_SUPPLY,
};

#[derive(Clone, Debug)]
pub enum Intent {
    /// 1 source → 1 target token move (07 AtomTransferMarker). Supply = `TOKEN_SUPPLY`.
    TransferToken {
        token_type: String,
        amount: i32,
        from_region: String,
        to_region: String,
    },
    /// Move one card between regions (order: append to dest end).
    MoveCard {
        card_id: String,
        from_region: String,
        to_region: String,
    },
    /// Flip dual token via Catalog dual_of — same-region type remapping (not Adjust).
    FlipToken {
        region_id: String,
        from_type: String,
        to_type: String,
        n: i32,
    },
    RegInsert {
        registration: Registration,
    },
    RegRemove {
        reg_id: String,
    },
    SetExhausted {
        card_id: String,
        exhausted: bool,
    },
    SetSeatActions {
        investigator_id: String,
        actions_remaining: i32,
    },
    SetSeatOutcome {
        investigator_id: String,
        eliminated: Option<bool>,
        resigned: Option<bool>,
    },
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum CommitError {
    MissingRegion(String),
    MissingCard(String),
    MissingSeat(String),
    MissingRegistration(String),
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

/// Apply intents in order; bumps `gen` once if any auth change lands.
pub fn commit(mut snap: Snapshot, intents: &[Intent]) -> Result<Snapshot, CommitError> {
    let mut touched = false;
    for intent in intents {
        apply_one(&mut snap, intent)?;
        touched = true;
    }
    if touched {
        snap.gen = snap.gen.saturating_add(1);
    }
    Ok(snap)
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
        Intent::FlipToken {
            region_id,
            from_type,
            to_type,
            n,
        } => {
            if *n <= 0 {
                return Err(CommitError::NonPositiveAmount(*n));
            }
            debit_stack(snap, region_id, from_type, *n)?;
            credit_stack(snap, region_id, to_type, *n)?;
            Ok(())
        }
        Intent::MoveCard {
            card_id,
            from_region,
            to_region,
        } => {
            {
                let from = snap
                    .auth
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
                .auth
                .regions
                .get_mut(to_region)
                .ok_or_else(|| CommitError::MissingRegion(to_region.clone()))?;
            to.card_ids.push(card_id.clone());
            Ok(())
        }
        Intent::RegInsert { registration } => {
            snap.auth
                .registrations
                .insert(registration.id.clone(), registration.clone());
            Ok(())
        }
        Intent::RegRemove { reg_id } => {
            if snap.auth.registrations.remove(reg_id).is_none() {
                return Err(CommitError::MissingRegistration(reg_id.clone()));
            }
            Ok(())
        }
        Intent::SetExhausted { card_id, exhausted } => {
            let card = snap
                .auth
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
                .auth
                .seats
                .get_mut(investigator_id)
                .ok_or_else(|| CommitError::MissingSeat(investigator_id.clone()))?;
            seat.actions_remaining = *actions_remaining;
            Ok(())
        }
        Intent::SetSeatOutcome {
            investigator_id,
            eliminated,
            resigned,
        } => {
            let seat = snap
                .auth
                .seats
                .get_mut(investigator_id)
                .ok_or_else(|| CommitError::MissingSeat(investigator_id.clone()))?;
            if let Some(v) = eliminated {
                seat.eliminated = *v;
            }
            if let Some(v) = resigned {
                seat.resigned = *v;
            }
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
        // Infinite supply: never fails, no stock to decrement.
        return Ok(());
    }
    let region = snap
        .auth
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
        // Return to supply does not accumulate inventory.
        return Ok(());
    }
    let region = snap
        .auth
        .regions
        .get_mut(region_id)
        .ok_or_else(|| CommitError::MissingRegion(region_id.to_string()))?;
    let cur = region.token_stacks.get(token_type).copied().unwrap_or(0);
    region
        .token_stacks
        .insert(token_type.to_string(), cur + amount);
    Ok(())
}

/// Helper: engagement STATUS registration.
pub fn engagement_reg(
    id: impl Into<String>,
    source_card_id: impl Into<String>,
    enemy_id: impl Into<String>,
    investigator_id: impl Into<String>,
) -> Registration {
    let enemy = enemy_id.into();
    let inv = investigator_id.into();
    Registration {
        id: id.into(),
        source_card_id: source_card_id.into(),
        subject: Subject::Bound {
            card_id: enemy.clone(),
        },
        lifetime: "while_in_play".into(),
        bound_id: String::new(),
        payloads: vec![RegistrationPayload::Status {
            status: StatusPayload::engagement(enemy, inv),
        }],
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::world::{
        Auth, Card, CardType, Face, Region, RegionShape, Seat, Snapshot, TOKEN_SUPPLY,
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
                controller_id: "I".into(),
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
                owner_id: "I".into(),
                controller_id: "I".into(),
                ..Card::default()
            },
        );

        let mut regions = BTreeMap::new();
        regions.insert(
            "pool_I".into(),
            Region {
                id: "pool_I".into(),
                place: "resource_pool".into(),
                host_card_id: "I".into(),
                token_stacks: BTreeMap::from([("resource".into(), 5)]),
                ..Region::default()
            },
        );
        regions.insert(
            "tok_I".into(),
            Region {
                id: "tok_I".into(),
                place: "tokens".into(),
                host_card_id: "I".into(),
                token_stacks: BTreeMap::new(),
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
                shape: RegionShape::Deck,
                host_card_id: "I".into(),
                place: "deck".into(),
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
        regions.insert(
            "tok_L".into(),
            Region {
                id: "tok_L".into(),
                place: "tokens".into(),
                host_card_id: "L".into(),
                token_stacks: BTreeMap::from([("clue".into(), 1)]),
                ..Region::default()
            },
        );

        let mut seats = BTreeMap::new();
        seats.insert("I".into(), Seat::fresh(3));

        Snapshot {
            auth: Auth {
                cards,
                regions,
                seats,
                next_id: 8,
                ..Auth::default()
            },
            gen: 1,
            ..Snapshot::default()
        }
    }

    #[test]
    fn seat_actions_not_on_card() {
        let s0 = mini_snap();
        assert_eq!(s0.auth.seats["I"].actions_remaining, 3);
        let s1 = commit(
            s0,
            &[Intent::SetSeatActions {
                investigator_id: "I".into(),
                actions_remaining: 2,
            }],
        )
        .unwrap();
        assert_eq!(s1.auth.seats["I"].actions_remaining, 2);
    }

    #[test]
    fn sealed_chaos_lives_on_host_tokens() {
        // Seal = Transfer chaos-type onto host tokens place (no sealed region).
        let s0 = mini_snap();
        let s1 = commit(
            s0,
            &[Intent::TransferToken {
                token_type: "skull".into(),
                amount: 1,
                from_region: TOKEN_SUPPLY.into(),
                to_region: "tok_I".into(),
            }],
        )
        .unwrap();
        assert_eq!(s1.token_on_card("I", "skull"), 1);
        assert!(s1.region_for_place("I", "sealed").is_none());
    }

    #[test]
    fn resource_pool_is_independent_region_not_card_tokens() {
        let s0 = mini_snap();
        assert_eq!(s0.resources_of("I"), 5);
        assert_eq!(s0.resource_pool_region_id("I"), Some(&"pool_I".to_string()));
        // Not on investigator card tokens; Seat has no resource field.
        assert_eq!(s0.token_on_card("I", "resource"), 0);
        assert_eq!(s0.auth.seats["I"].actions_remaining, 3);
        let s1 = commit(
            s0,
            &[Intent::TransferToken {
                token_type: "resource".into(),
                amount: 2,
                from_region: "pool_I".into(),
                to_region: TOKEN_SUPPLY.into(),
            }],
        )
        .unwrap();
        assert_eq!(s1.resources_of("I"), 3);
        assert_eq!(s1.token_on_card("I", "resource"), 0);
        assert_eq!(s1.auth.seats["I"].actions_remaining, 3);
    }

    #[test]
    fn place_damage_from_supply() {
        let s0 = mini_snap();
        assert_eq!(s0.resources_of("I"), 5);
        let s1 = commit(
            s0,
            &[Intent::TransferToken {
                token_type: "damage".into(),
                amount: 1,
                from_region: TOKEN_SUPPLY.into(),
                to_region: "tok_I".into(),
            }],
        )
        .unwrap();
        assert_eq!(s1.token_on_card("I", "damage"), 1);
        assert_eq!(s1.resources_of("I"), 5);
        assert_eq!(s1.gen, 2);
    }

    #[test]
    fn heal_damage_to_supply() {
        let mut s0 = mini_snap();
        s0.auth
            .regions
            .get_mut("tok_I")
            .unwrap()
            .token_stacks
            .insert("damage".into(), 2);
        let s1 = commit(
            s0,
            &[Intent::TransferToken {
                token_type: "damage".into(),
                amount: 1,
                from_region: "tok_I".into(),
                to_region: TOKEN_SUPPLY.into(),
            }],
        )
        .unwrap();
        assert_eq!(s1.token_on_card("I", "damage"), 1);
    }

    #[test]
    fn draw_moves_card_deck_to_hand() {
        let s0 = mini_snap();
        let s1 = commit(
            s0,
            &[Intent::MoveCard {
                card_id: "C1".into(),
                from_region: "deck_I".into(),
                to_region: "hand_I".into(),
            }],
        )
        .unwrap();
        assert!(s1.auth.regions["deck_I"].card_ids.is_empty());
        assert_eq!(s1.auth.regions["hand_I"].card_ids, vec!["C1".to_string()]);
    }

    #[test]
    fn location_of_uses_on_place() {
        let s = mini_snap();
        assert_eq!(s.location_of("I").map(|s| s.as_str()), Some("L"));
    }

    #[test]
    fn engagement_is_status_payload() {
        let s0 = mini_snap();
        let reg = engagement_reg("r1", "E", "E", "I");
        assert_eq!(reg.payloads[0].kind(), crate::world::RegistrationKind::Status);
        let s1 = commit(s0, &[Intent::RegInsert { registration: reg }]).unwrap();
        assert!(s1.auth.registrations.contains_key("r1"));
    }

    #[test]
    fn status_payload_is_engagement_variant() {
        let s = crate::world::StatusPayload::engagement("E", "I");
        match &s {
            crate::world::StatusPayload::Engagement {
                subject_id,
                drawer_id,
            } => {
                assert_eq!(subject_id, "E");
                assert_eq!(drawer_id, "I");
            }
        }
        let v = serde_json::to_value(&s).unwrap();
        assert_eq!(v["kind"], "engagement");
        assert!(v.get("kind").is_some());
    }

    #[test]
    fn listener_payload_stays_homogeneous() {
        let listener = crate::world::ListenerPayload {
            timing: "after_evade".into(),
            composition: "comp_draw_1".into(),
        };
        let payload = crate::world::RegistrationPayload::Listener { listener };
        assert_eq!(payload.kind(), crate::world::RegistrationKind::Listener);
    }

    #[test]
    fn choice_state_carries_bind_and_controller() {
        let ch = crate::world::ChoiceState {
            ask_id: "pick".into(),
            kind: "pick_target".into(),
            controller_id: "I".into(),
            bind_key: "chosen".into(),
            default_value: "A".into(),
            candidates: vec!["A".into(), "B".into()],
        };
        let v = serde_json::to_value(&ch).unwrap();
        let obj = v.as_object().unwrap();
        assert_eq!(obj.len(), 6);
        assert_eq!(v["controller_id"], "I");
        assert_eq!(v["bind_key"], "chosen");
        assert!(!obj.contains_key("deadline_ms"));
    }

    #[test]
    fn skill_test_has_st_step_cursor() {
        let st = crate::world::SkillTest {
            test_id: "t1".into(),
            investigator_id: "I".into(),
            skill: "intellect".into(),
            difficulty: 3,
            committed_ids: vec!["C1".into()],
            st_step: "st6".into(),
            success: Some(false),
            fail_by: 2,
        };
        assert_eq!(st.st_step, "st6");
        assert_eq!(st.fail_by, 2);
    }

    #[test]
    fn focus_keeps_sticky_pools() {
        let focus = crate::world::Focus {
            window: "player_window".into(),
            controller_id: "I".into(),
            open_must_ask_id: String::new(),
            initiation_pool_ids: vec!["play:C1".into()],
            response_pool_ids: vec!["react:r9".into()],
        };
        let v = serde_json::to_value(&focus).unwrap();
        let obj = v.as_object().unwrap();
        assert_eq!(obj.len(), 5);
        assert!(obj.contains_key("initiation_pool_ids"));
        assert!(obj.contains_key("response_pool_ids"));
    }

    #[test]
    fn framework_is_slim_five_fields() {
        let fw = crate::world::Framework {
            round: 1,
            lead_investigator_id: "I".into(),
            active_investigator_id: "I".into(),
            current_act_id: "act1".into(),
            current_agenda_id: "ag1".into(),
        };
        // Serialize round-trip keeps only the slim set (no deck/phase/threshold keys).
        let v = serde_json::to_value(&fw).unwrap();
        let obj = v.as_object().unwrap();
        assert_eq!(obj.len(), 5);
        assert!(obj.contains_key("round"));
        assert!(!obj.contains_key("phase_id"));
        assert!(!obj.contains_key("doom_threshold"));
    }

    #[test]
    fn modifier_payload_stays_homogeneous() {
        let m = crate::world::ModifierPayload {
            stat: "combat".into(),
            op: "add".into(),
            value: 1,
            condition: String::new(),
            plan_kind: "none".into(),
            apply_mode: "scalar".into(),
        };
        let payload = crate::world::RegistrationPayload::Modifier { modifier: m };
        assert_eq!(payload.kind(), crate::world::RegistrationKind::Modifier);
    }

    #[test]
    fn gate_payload_typed_by_kind() {
        use crate::world::{GatePayload, GateScope, RegistrationPayload};
        let peril = GatePayload::ForbidPlay {
            scope: GateScope::Peril {
                drawer_id: "I".into(),
                drawn_card_id: "T1".into(),
                encounter_frame_id: "ef1".into(),
            },
        };
        assert_eq!(peril.kind_name(), "forbid_play");
        let lasting = GatePayload::ForbidDraw {
            subject_id: "I".into(),
        };
        assert_eq!(lasting.kind_name(), "forbid_draw");
        let payload = RegistrationPayload::Gate { gate: peril };
        assert_eq!(payload.kind(), crate::world::RegistrationKind::Gate);
    }

    #[test]
    fn flip_token_moves_between_types() {
        let mut s0 = mini_snap();
        s0.auth
            .regions
            .get_mut("tok_I")
            .unwrap()
            .token_stacks
            .insert("tablet".into(), 1);
        let s1 = commit(
            s0,
            &[Intent::FlipToken {
                region_id: "tok_I".into(),
                from_type: "tablet".into(),
                to_type: "elder_thing".into(),
                n: 1,
            }],
        )
        .unwrap();
        assert_eq!(s1.token_on_card("I", "tablet"), 0);
        assert_eq!(s1.token_on_card("I", "elder_thing"), 1);
    }
}
