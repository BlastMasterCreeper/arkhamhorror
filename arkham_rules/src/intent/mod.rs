//! Unique auth writers — commit(Intent[]) → Snapshot'.

use crate::world::{
    Registration, RegistrationPayload, Snapshot, StatusPayload, Subject,
};

#[derive(Clone, Debug)]
pub enum Intent {
    /// Δ token stack on a region (PlaceToken / RemoveToken).
    AdjustToken {
        region_id: String,
        token_type: String,
        delta: i32,
    },
    /// Move one card between regions (order: append to dest end).
    MoveCard {
        card_id: String,
        from_region: String,
        to_region: String,
    },
    /// Flip dual token via Catalog dual_of — caller passes both types.
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
        Intent::AdjustToken {
            region_id,
            token_type,
            delta,
        } => {
            let region = snap
                .auth
                .regions
                .get_mut(region_id)
                .ok_or_else(|| CommitError::MissingRegion(region_id.clone()))?;
            let cur = region.token_stacks.get(token_type).copied().unwrap_or(0);
            let next = cur + delta;
            if next < 0 {
                return Err(CommitError::InsufficientTokens {
                    region_id: region_id.clone(),
                    token_type: token_type.clone(),
                    have: cur,
                    need: -delta,
                });
            }
            if next == 0 {
                region.token_stacks.remove(token_type);
            } else {
                region.token_stacks.insert(token_type.clone(), next);
            }
            Ok(())
        }
        Intent::FlipToken {
            region_id,
            from_type,
            to_type,
            n,
        } => {
            apply_one(
                snap,
                &Intent::AdjustToken {
                    region_id: region_id.clone(),
                    token_type: from_type.clone(),
                    delta: -n,
                },
            )?;
            apply_one(
                snap,
                &Intent::AdjustToken {
                    region_id: region_id.clone(),
                    token_type: to_type.clone(),
                    delta: *n,
                },
            )
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
                    .position(|id| id == card_id)
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

/// Convenience: engagement STATUS registration.
pub fn engagement_reg(
    id: impl Into<String>,
    source_card_id: impl Into<String>,
    enemy_id: impl Into<String>,
    investigator_id: impl Into<String>,
) -> Registration {
    let enemy_id = enemy_id.into();
    Registration {
        id: id.into(),
        source_card_id: source_card_id.into(),
        subject: Subject::Bound {
            card_id: enemy_id.clone(),
        },
        lifetime: "while_in_play".into(),
        bound_id: String::new(),
        payloads: vec![RegistrationPayload::Status {
            status: StatusPayload::engagement(enemy_id, investigator_id),
        }],
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::world::{
        Auth, Card, CardType, Face, Region, RegionShape, Seat, Snapshot,
    };
    use std::collections::BTreeMap;

    fn mini_snap() -> Snapshot {
        let mut cards = BTreeMap::new();
        let mut owned = BTreeMap::new();
        owned.insert("tokens".into(), "tok_I".into());
        owned.insert("hand".into(), "hand_I".into());
        owned.insert("deck".into(), "deck_I".into());
        cards.insert(
            "I".into(),
            Card {
                id: "I".into(),
                definition_id: "01001".into(),
                card_type: CardType::Investigator,
                controller_id: "I".into(),
                face: Face::A,
                owned_regions: owned,
                ..Card::default()
            },
        );
        let mut loc_owned = BTreeMap::new();
        loc_owned.insert("on".into(), "on_L".into());
        loc_owned.insert("tokens".into(), "tok_L".into());
        cards.insert(
            "L".into(),
            Card {
                id: "L".into(),
                definition_id: "01111".into(),
                card_type: CardType::Location,
                face: Face::B,
                owned_regions: loc_owned,
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
        let mut stacks = BTreeMap::new();
        stacks.insert("resource".into(), 5);
        regions.insert(
            "tok_I".into(),
            Region {
                id: "tok_I".into(),
                shape: RegionShape::Flat,
                host_card_id: "I".into(),
                place: "tokens".into(),
                token_stacks: stacks,
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
        seats.insert("I".into(), Seat::fresh("I", 3));

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
    fn place_damage_on_investigator_tokens() {
        let s0 = mini_snap();
        assert_eq!(s0.token_on_card("I", "resource"), 5);
        let s1 = commit(
            s0,
            &[Intent::AdjustToken {
                region_id: "tok_I".into(),
                token_type: "damage".into(),
                delta: 1,
            }],
        )
        .unwrap();
        assert_eq!(s1.token_on_card("I", "damage"), 1);
        assert_eq!(s1.gen, 2);
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
    fn flip_token_moves_between_types() {
        let mut s0 = mini_snap();
        s0.auth.regions.get_mut("tok_I").unwrap().token_stacks.insert("tablet".into(), 1);
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
