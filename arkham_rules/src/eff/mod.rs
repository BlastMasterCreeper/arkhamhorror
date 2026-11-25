//! Eff algebra subset (M2): Do / Empty / Pass / Seq / If / Nest / Ask.
//! Aligns with docs/design/25-functional-eff.md.

use std::collections::BTreeMap;

use crate::catalog::Catalog;
use crate::intent::{commit, Intent};
use crate::world::{ChoiceState, Frame, Snapshot};

/// Read-only predicate id (M2: tiny built-in set).
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Pred {
    /// Token count on card's `tokens` place >= n.
    TokenAtLeast {
        card_id: String,
        token_type: String,
        n: i32,
    },
    /// Region has at least one card.
    RegionNonEmpty { region_id: String },
    /// Always true / false (tests).
    Const(bool),
}

#[derive(Clone, Debug)]
pub enum Eff {
    Do(Intent),
    Empty,
    Pass,
    Seq(Box<Eff>, Box<Eff>),
    If {
        pred: Pred,
        then_branch: Box<Eff>,
        else_branch: Box<Eff>,
    },
    Nest {
        flow_id: String,
        env: BTreeMap<String, String>,
    },
    /// PI confirmation; `cont` runs after answer is bound into `run.memory[controller][bind_key]`.
    Ask {
        ask_id: String,
        kind: String,
        candidates: Vec<String>,
        default_value: String,
        bind_key: String,
        controller_id: String,
        cont: Box<Eff>,
    },
    /// Internal: pop nest frame after nested body finishes (M2).
    NestPop,
}

#[derive(Clone, Debug)]
pub struct AskRequest {
    pub ask_id: String,
    pub kind: String,
    pub candidates: Vec<String>,
    pub default_value: String,
    pub bind_key: String,
    pub controller_id: String,
}

#[derive(Clone, Debug)]
pub enum StepResult {
    Next {
        snap: Snapshot,
        cont: Eff,
    },
    NeedAsk {
        snap: Snapshot,
        request: AskRequest,
        cont: Eff,
    },
    Done {
        snap: Snapshot,
    },
    Halt {
        reason: String,
    },
}

#[derive(Clone, Debug, Default)]
pub struct PlanResult {
    pub intents: Vec<Intent>,
    pub created: bool,
}

pub fn eval_pred(snap: &Snapshot, pred: &Pred) -> bool {
    match pred {
        Pred::Const(b) => *b,
        Pred::TokenAtLeast {
            card_id,
            token_type,
            n,
        } => snap.token_on_card(card_id, token_type) >= *n,
        Pred::RegionNonEmpty { region_id } => snap
            .auth
            .regions
            .get(region_id)
            .map(|r| !r.card_ids.is_empty())
            .unwrap_or(false),
    }
}

/// Dry-run style intent collection (no Nest expansion, no Ask).
pub fn plan(snap: &Snapshot, eff: &Eff) -> PlanResult {
    match eff {
        Eff::Do(i) => PlanResult {
            intents: vec![i.clone()],
            created: true,
        },
        Eff::Empty => PlanResult {
            intents: vec![],
            created: true,
        },
        Eff::Pass => PlanResult {
            intents: vec![],
            created: false,
        },
        Eff::Seq(a, b) => {
            let pa = plan(snap, a);
            // dry-run OR: still plan b against same snap
            let pb = plan(snap, b);
            let mut intents = pa.intents;
            intents.extend(pb.intents);
            PlanResult {
                intents,
                created: pa.created || pb.created,
            }
        }
        Eff::If {
            pred,
            then_branch,
            else_branch,
        } => {
            if eval_pred(snap, pred) {
                plan(snap, then_branch)
            } else {
                plan(snap, else_branch)
            }
        }
        Eff::Nest { .. } | Eff::Ask { .. } | Eff::NestPop => PlanResult::default(),
    }
}

/// One reduction step. `catalog` required for Nest.
pub fn step(snap: Snapshot, catalog: &Catalog, eff: Eff) -> StepResult {
    match eff {
        Eff::Pass | Eff::Empty => StepResult::Done { snap },
        Eff::NestPop => {
            let mut snap = snap;
            snap.run.stack.pop();
            StepResult::Done { snap }
        }
        Eff::Do(intent) => match commit(snap, &[intent]) {
            Ok(snap) => StepResult::Done { snap },
            Err(e) => StepResult::Halt {
                reason: format!("{e:?}"),
            },
        },
        Eff::Seq(a, b) => match step(snap, catalog, *a) {
            StepResult::Done { snap } => StepResult::Next { snap, cont: *b },
            StepResult::Next { snap, cont } => StepResult::Next {
                snap,
                cont: Eff::Seq(Box::new(cont), b),
            },
            StepResult::NeedAsk {
                snap,
                request,
                cont,
            } => StepResult::NeedAsk {
                snap,
                request,
                cont: Eff::Seq(Box::new(cont), b),
            },
            halt @ StepResult::Halt { .. } => halt,
        },
        Eff::If {
            pred,
            then_branch,
            else_branch,
        } => {
            let branch = if eval_pred(&snap, &pred) {
                *then_branch
            } else {
                *else_branch
            };
            StepResult::Next {
                snap,
                cont: branch,
            }
        }
        Eff::Nest { flow_id, env } => {
            let Some(flow) = catalog.get(&flow_id) else {
                return StepResult::Halt {
                    reason: format!("unknown flow {flow_id}"),
                };
            };
            let mut snap = snap;
            snap.run.stack.push(Frame {
                flow_id: flow_id.clone(),
                env,
                step_index: 0,
                cancelled: false,
                created: false,
                cont_after: String::new(),
            });
            let body = Eff::Seq(Box::new(flow.body.clone()), Box::new(Eff::NestPop));
            StepResult::Next {
                snap,
                cont: body,
            }
        }
        Eff::Ask {
            ask_id,
            kind,
            candidates,
            default_value,
            bind_key,
            controller_id,
            cont,
        } => {
            let mut snap = snap;
            snap.run.open_choice = Some(ChoiceState {
                ask_id: ask_id.clone(),
                kind: kind.clone(),
                controller_id: controller_id.clone(),
                bind_key: bind_key.clone(),
                default_value: default_value.clone(),
                candidates: candidates.clone(),
            });
            StepResult::NeedAsk {
                snap,
                request: AskRequest {
                    ask_id,
                    kind,
                    candidates,
                    default_value,
                    bind_key,
                    controller_id,
                },
                cont: *cont,
            }
        }
    }
}

/// Drive until Done / NeedAsk / Halt (bounded steps).
pub fn run_to_ask_or_done(
    mut snap: Snapshot,
    catalog: &Catalog,
    mut cont: Eff,
    max_steps: usize,
) -> StepResult {
    for _ in 0..max_steps {
        match step(snap, catalog, cont) {
            StepResult::Next {
                snap: s,
                cont: c,
            } => {
                snap = s;
                cont = c;
            }
            other => return other,
        }
    }
    StepResult::Halt {
        reason: "step limit".into(),
    }
}

/// Bind Ask answer into run.memory then continue.
pub fn answer(
    mut snap: Snapshot,
    catalog: &Catalog,
    request: &AskRequest,
    choice: &str,
    cont: Eff,
) -> StepResult {
    let entry = snap
        .run
        .memory
        .entry(request.controller_id.clone())
        .or_default();
    entry.insert(request.bind_key.clone(), choice.to_string());
    snap.run.open_choice = None;
    step(snap, catalog, cont)
}

/// Built-in: draw top card from investigator deck place → hand place.
pub fn draw_one_eff(investigator_id: &str, snap: &Snapshot) -> Result<Eff, String> {
    let card = snap
        .auth
        .cards
        .get(investigator_id)
        .ok_or_else(|| format!("missing investigator {investigator_id}"))?;
    let deck_id = card
        .owned_regions
        .get("deck")
        .ok_or("missing deck place")?
        .clone();
    let hand_id = card
        .owned_regions
        .get("hand")
        .ok_or("missing hand place")?
        .clone();
    let top = snap
        .auth
        .regions
        .get(&deck_id)
        .and_then(|r| r.card_ids.first())
        .cloned()
        .ok_or_else(|| "deck empty".to_string())?;
    Ok(Eff::Do(Intent::MoveCard {
        card_id: top,
        from_region: deck_id,
        to_region: hand_id,
    }))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::catalog::{Catalog, Flow};
    use crate::intent::Intent;
    use crate::world::{
        Auth, Card, CardType, Face, Region, RegionShape, Snapshot, TOKEN_SUPPLY,
    };

    fn snap_with_deck() -> Snapshot {
        let mut cards = BTreeMap::new();
        let mut owned = BTreeMap::new();
        owned.insert("deck".into(), "deck_I".into());
        owned.insert("hand".into(), "hand_I".into());
        owned.insert("tokens".into(), "tok_I".into());
        cards.insert(
            "I".into(),
            Card {
                id: "I".into(),
                card_type: CardType::Investigator,
                controller_id: "I".into(),
                face: Face::A,
                owned_regions: owned,
                ..Card::default()
            },
        );
        cards.insert(
            "C1".into(),
            Card {
                id: "C1".into(),
                card_type: CardType::Skill,
                owner_id: "I".into(),
                controller_id: "I".into(),
                ..Card::default()
            },
        );
        let mut regions = BTreeMap::new();
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
            "hand_I".into(),
            Region {
                id: "hand_I".into(),
                place: "hand".into(),
                host_card_id: "I".into(),
                ..Region::default()
            },
        );
        regions.insert(
            "tok_I".into(),
            Region {
                id: "tok_I".into(),
                place: "tokens".into(),
                host_card_id: "I".into(),
                token_stacks: BTreeMap::from([("damage".into(), 0)]),
                ..Region::default()
            },
        );
        // damage 0 key optional — start empty stacks
        regions.get_mut("tok_I").unwrap().token_stacks.clear();

        Snapshot {
            auth: Auth {
                cards,
                regions,
                ..Auth::default()
            },
            gen: 1,
            ..Snapshot::default()
        }
    }

    #[test]
    fn seq_do_transfer_token() {
        let s0 = snap_with_deck();
        let cat = Catalog::new();
        let eff = Eff::Seq(
            Box::new(Eff::Do(Intent::TransferToken {
                token_type: "damage".into(),
                amount: 1,
                from_region: TOKEN_SUPPLY.into(),
                to_region: "tok_I".into(),
            })),
            Box::new(Eff::Pass),
        );
        let out = run_to_ask_or_done(s0, &cat, eff, 16);
        match out {
            StepResult::Done { snap } => {
                assert_eq!(snap.token_on_card("I", "damage"), 1);
            }
            other => panic!("unexpected {other:?}"),
        }
    }

    #[test]
    fn if_picks_branch() {
        let s0 = snap_with_deck();
        let cat = Catalog::new();
        let eff = Eff::If {
            pred: Pred::Const(false),
            then_branch: Box::new(Eff::Do(Intent::TransferToken {
                token_type: "damage".into(),
                amount: 9,
                from_region: TOKEN_SUPPLY.into(),
                to_region: "tok_I".into(),
            })),
            else_branch: Box::new(Eff::Do(Intent::TransferToken {
                token_type: "horror".into(),
                amount: 1,
                from_region: TOKEN_SUPPLY.into(),
                to_region: "tok_I".into(),
            })),
        };
        let out = run_to_ask_or_done(s0, &cat, eff, 8);
        match out {
            StepResult::Done { snap } => {
                assert_eq!(snap.token_on_card("I", "horror"), 1);
                assert_eq!(snap.token_on_card("I", "damage"), 0);
            }
            other => panic!("unexpected {other:?}"),
        }
    }

    #[test]
    fn nest_draw_moves_card() {
        let s0 = snap_with_deck();
        let body = draw_one_eff("I", &s0).unwrap();
        let mut cat = Catalog::new();
        cat.insert(
            "seq.draw.investigator".into(),
            Flow {
                id: "seq.draw.investigator".into(),
                body,
            },
        );
        let eff = Eff::Nest {
            flow_id: "seq.draw.investigator".into(),
            env: BTreeMap::from([("who".into(), "I".into())]),
        };
        let out = run_to_ask_or_done(s0, &cat, eff, 8);
        match out {
            StepResult::Done { snap } => {
                assert!(snap.auth.regions["deck_I"].card_ids.is_empty());
                assert_eq!(snap.auth.regions["hand_I"].card_ids, vec!["C1".to_string()]);
                assert_eq!(snap.run.stack.len(), 0);
            }
            other => panic!("unexpected {other:?}"),
        }
    }

    #[test]
    fn ask_then_adjust_bound_target() {
        let s0 = snap_with_deck();
        let cat = Catalog::new();
        let eff = Eff::Ask {
            ask_id: "pick".into(),
            kind: "pick_target".into(),
            candidates: vec!["tok_I".into()],
            default_value: "tok_I".into(),
            bind_key: "chosen_region".into(),
            controller_id: "I".into(),
            cont: Box::new(Eff::Do(Intent::TransferToken {
                token_type: "clue".into(),
                amount: 1,
                from_region: TOKEN_SUPPLY.into(),
                to_region: "tok_I".into(),
            })),
        };
        let out = run_to_ask_or_done(s0, &cat, eff, 4);
        let (snap, req, cont) = match out {
            StepResult::NeedAsk {
                snap,
                request,
                cont,
            } => (snap, request, cont),
            other => panic!("expected ask, got {other:?}"),
        };
        assert_eq!(req.default_value, "tok_I");
        assert!(snap.run.open_choice.is_some());
        assert_eq!(
            snap.run.open_choice.as_ref().unwrap().bind_key,
            "chosen_region"
        );
        let after = answer(snap, &cat, &req, "tok_I", cont);
        let snap = match after {
            StepResult::Done { snap } => snap,
            StepResult::Next { snap, cont } => match run_to_ask_or_done(snap, &cat, cont, 8) {
                StepResult::Done { snap } => snap,
                other => panic!("unexpected resume {other:?}"),
            },
            other => panic!("unexpected answer {other:?}"),
        };
        assert_eq!(snap.token_on_card("I", "clue"), 1);
        assert_eq!(snap.run.memory["I"]["chosen_region"], "tok_I");
        assert!(snap.run.open_choice.is_none());
    }

    #[test]
    fn plan_empty_created() {
        let s = snap_with_deck();
        let p = plan(&s, &Eff::Empty);
        assert!(p.created);
        assert!(p.intents.is_empty());
        let p2 = plan(&s, &Eff::Pass);
        assert!(!p2.created);
    }
}
