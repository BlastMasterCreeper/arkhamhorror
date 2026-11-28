//! Initiation paths — Constant **additional-cost → alternate PLAY_CARD path**.
//!
//! Thin cut: Chuck Fergus (09072) Fast **and** −2 resource options.
//! Prefs: Fast covers the **whole initiation** (广义打出); **not** Would / timing rewrite.
//! Resource discount = path-local fold on printed cost at feasibility (not a late Buff).
//! Personal SoT: `docs/reference/personal-card-text.md` · 09072.

use crate::intent::Intent;
use crate::world::{Data, TOKEN_SUPPLY};

/// Printed / path play form — kinds remain `PLAY_CARD` (06 §4.2).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum PlayForm {
    /// Default non-Fast: costs 1 Play action (≈ activate trigger symmetry).
    PlayAction,
    /// Fast, no timing point — Player Window; Taboo: during your turn.
    FastWindow,
    /// Fast with when/after timing (not used by Chuck thin cut).
    FastTiming,
}

impl PlayForm {
    /// Fast forms waive the Play-action spend for the **entire** initiation.
    pub fn waives_play_action(self) -> bool {
        matches!(self, Self::FastWindow | Self::FastTiming)
    }
}

/// Personal additional cost on an alternate initiation path (not RR resolve-step only).
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum AdditionalCost {
    Exhaust { card_id: String },
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum WindowConstraint {
    None,
    /// Taboo wording: *Play only during your turn.*
    DuringControllerTurn,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum InitiationKind {
    PlayCard,
}

/// One legal way to initiate playing a card (default or Constant-opened).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct InitiationPath {
    pub id: String,
    pub kind: InitiationKind,
    /// Event / asset being played.
    pub subject_id: String,
    pub play_form: PlayForm,
    pub additional_costs: Vec<AdditionalCost>,
    pub window: WindowConstraint,
    /// Path-local fold on printed resource cost (e.g. Chuck −2). Applied at feasibility.
    pub resource_cost_delta: i32,
    /// Constant source that opened this path (e.g. Chuck instance id).
    pub opened_by: Option<String>,
}

/// Bundle of alternate paths offered for one play attempt.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct PathOffer {
    pub paths: Vec<InitiationPath>,
}

/// Inputs for feasibility that live outside the static path (printed cost, payer, window clock).
#[derive(Clone, Debug)]
pub struct PathEvalContext {
    pub during_controller_turn: bool,
    pub printed_resource_cost: i32,
    pub payer_player_id: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum PathError {
    MissingCard(String),
    SourceExhausted(String),
    WindowNotOpen,
    MissingResourcePool(String),
    InsufficientResources { have: i32, need: i32 },
}

/// Cost view for choosing a path — evaluated **before** initiation timing exists.
#[derive(Clone, Debug)]
pub struct PathEvaluation {
    /// Play-action cost for this whole initiation (广义打出). Fast → 0.
    pub play_action_cost: i32,
    /// After path delta, floored at 0.
    pub effective_resource_cost: i32,
    /// Settlement intents: path additional costs (exhaust …) then resource pay if any.
    pub cost_intents: Vec<Intent>,
}

/// `max(0, printed + delta)` — resource discount never goes negative.
pub fn effective_resource_cost(printed: i32, delta: i32) -> i32 {
    printed.saturating_add(delta).max(0)
}

/// Default printed PLAY_CARD path (no Constant extra).
pub fn default_play_path(event_id: impl Into<String>, printed_fast: bool) -> InitiationPath {
    let subject_id = event_id.into();
    let play_form = if printed_fast {
        PlayForm::FastWindow
    } else {
        PlayForm::PlayAction
    };
    InitiationPath {
        id: format!("path.play.default:{subject_id}"),
        kind: InitiationKind::PlayCard,
        subject_id,
        play_form,
        additional_costs: Vec::new(),
        window: WindowConstraint::None,
        resource_cost_delta: 0,
        opened_by: None,
    }
}

/// Chuck 09072 Constant — Fast additional-cost initiation path.
///
/// Additional cost: exhaust Chuck. Play form: FastWindow + during your turn (Taboo).
/// Scope: whole initiation (广义打出), so Play action is waived from the start.
pub fn chuck_fast_path(chuck_id: impl Into<String>, event_id: impl Into<String>) -> InitiationPath {
    let chuck = chuck_id.into();
    let subject_id = event_id.into();
    InitiationPath {
        id: format!("path.play.chuck_fast:{chuck}:{subject_id}"),
        kind: InitiationKind::PlayCard,
        subject_id,
        play_form: PlayForm::FastWindow,
        additional_costs: vec![AdditionalCost::Exhaust {
            card_id: chuck.clone(),
        }],
        window: WindowConstraint::DuringControllerTurn,
        resource_cost_delta: 0,
        opened_by: Some(chuck),
    }
}

/// Chuck 09072 Constant — −2 resource additional-cost initiation path.
///
/// Still PlayAction (choose one — not Fast). Resource feasibility uses `resource_cost_delta = -2`.
pub fn chuck_cheap_path(chuck_id: impl Into<String>, event_id: impl Into<String>) -> InitiationPath {
    let chuck = chuck_id.into();
    let subject_id = event_id.into();
    InitiationPath {
        id: format!("path.play.chuck_cheap:{chuck}:{subject_id}"),
        kind: InitiationKind::PlayCard,
        subject_id,
        play_form: PlayForm::PlayAction,
        additional_costs: vec![AdditionalCost::Exhaust {
            card_id: chuck.clone(),
        }],
        window: WindowConstraint::None,
        resource_cost_delta: -2,
        opened_by: Some(chuck),
    }
}

/// Enumerate PLAY_CARD paths: default; when Chuck Constant applies → Fast + cheap.
///
/// `chuck_ready_id`: Some(chuck) when Chuck is in play, ready, and the event is Tactic/Trick
/// (caller already filtered trait / ownership — thin cut does not re-query traits).
pub fn offer_play_paths(
    event_id: impl Into<String>,
    printed_fast: bool,
    chuck_ready_id: Option<&str>,
) -> PathOffer {
    let event = event_id.into();
    let mut paths = vec![default_play_path(event.clone(), printed_fast)];
    if let Some(chuck) = chuck_ready_id {
        paths.push(chuck_fast_path(chuck, &event));
        paths.push(chuck_cheap_path(chuck, event));
    }
    PathOffer { paths }
}

/// Evaluate path costs. Must pass before any initiation timing is opened (prefs / validity).
///
/// Resource discount is a **path-local fold** on `printed_resource_cost` here — same moment as
/// other cost feasibility — not a Would / after-initiate Buff.
pub fn evaluate_path(
    data: &Data,
    path: &InitiationPath,
    ctx: &PathEvalContext,
) -> Result<PathEvaluation, PathError> {
    if path.window == WindowConstraint::DuringControllerTurn && !ctx.during_controller_turn {
        return Err(PathError::WindowNotOpen);
    }

    let mut cost_intents = Vec::new();
    for cost in &path.additional_costs {
        match cost {
            AdditionalCost::Exhaust { card_id } => {
                let card = data
                    .board
                    .cards
                    .get(card_id)
                    .ok_or_else(|| PathError::MissingCard(card_id.clone()))?;
                if card.exhausted {
                    return Err(PathError::SourceExhausted(card_id.clone()));
                }
                cost_intents.push(Intent::SetExhausted {
                    card_id: card_id.clone(),
                    exhausted: true,
                });
            }
        }
    }

    let effective = effective_resource_cost(ctx.printed_resource_cost, path.resource_cost_delta);
    if effective > 0 {
        let pool_id = player_region_id(data, &ctx.payer_player_id, "resource_pool").ok_or_else(
            || PathError::MissingResourcePool(ctx.payer_player_id.clone()),
        )?;
        let have = resources_of(data, &ctx.payer_player_id);
        if have < effective {
            return Err(PathError::InsufficientResources {
                have,
                need: effective,
            });
        }
        cost_intents.push(Intent::TransferToken {
            token_type: "resource".into(),
            amount: effective,
            from_region: pool_id,
            to_region: TOKEN_SUPPLY.into(),
        });
    }

    let play_action_cost = if path.play_form.waives_play_action() {
        0
    } else {
        1
    };
    Ok(PathEvaluation {
        play_action_cost,
        effective_resource_cost: effective,
        cost_intents,
    })
}

/// Paths are alternate initiations — never Would / OnTiming rewrites (prefs).
pub fn is_would_rewrite(_path: &InitiationPath) -> bool {
    false
}

fn player_region_id(data: &Data, player_id: &str, place: &str) -> Option<String> {
    data.board.regions.iter().find_map(|(id, r)| {
        if r.host_player_id == player_id && r.place == place {
            Some(id.clone())
        } else {
            None
        }
    })
}

fn resources_of(data: &Data, player_id: &str) -> i32 {
    data.board
        .regions
        .values()
        .find(|r| r.host_player_id == player_id && r.place == "resource_pool")
        .and_then(|r| r.token_stacks.get("resource").copied())
        .unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::intent::{commit, Intent};
    use crate::world::{Card, CardType, Face, Region, Snapshot};
    use std::collections::BTreeMap;

    fn ctx(printed: i32, during_turn: bool) -> PathEvalContext {
        PathEvalContext {
            during_controller_turn: during_turn,
            printed_resource_cost: printed,
            payer_player_id: "P1".into(),
        }
    }

    fn snap_with_chuck(exhausted: bool, resources: i32) -> Snapshot {
        let mut snap = Snapshot::default();
        snap.data.board.cards.insert(
            "chuck".into(),
            Card {
                id: "chuck".into(),
                definition_id: "09072".into(),
                card_type: CardType::Asset,
                owner_id: "P1".into(),
                controller_id: "inv1".into(),
                face: Face::A,
                exhausted,
                connections: Vec::new(),
            },
        );
        snap.data.board.cards.insert(
            "event".into(),
            Card {
                id: "event".into(),
                definition_id: "01023".into(),
                card_type: CardType::Event,
                owner_id: "P1".into(),
                controller_id: "inv1".into(),
                face: Face::A,
                exhausted: false,
                connections: Vec::new(),
            },
        );
        snap.data.board.regions.insert(
            "pool_P1".into(),
            Region {
                id: "pool_P1".into(),
                place: "resource_pool".into(),
                host_player_id: "P1".into(),
                token_stacks: BTreeMap::from([("resource".into(), resources)]),
                ..Region::default()
            },
        );
        snap
    }

    #[test]
    fn default_path_costs_play_action_and_full_resources() {
        let snap = snap_with_chuck(false, 5);
        let path = default_play_path("event", false);
        assert_eq!(path.play_form, PlayForm::PlayAction);
        assert_eq!(path.resource_cost_delta, 0);
        let eval = evaluate_path(&snap.data, &path, &ctx(3, true)).unwrap();
        assert_eq!(eval.play_action_cost, 1);
        assert_eq!(eval.effective_resource_cost, 3);
        assert_eq!(eval.cost_intents.len(), 1);
        assert!(!is_would_rewrite(&path));
    }

    #[test]
    fn chuck_fast_path_waives_action_whole_initiation() {
        let snap = snap_with_chuck(false, 5);
        let path = chuck_fast_path("chuck", "event");
        assert_eq!(path.play_form, PlayForm::FastWindow);
        assert_eq!(path.window, WindowConstraint::DuringControllerTurn);
        assert_eq!(path.opened_by.as_deref(), Some("chuck"));
        assert!(path.play_form.waives_play_action());
        assert!(!is_would_rewrite(&path));

        let eval = evaluate_path(&snap.data, &path, &ctx(3, true)).unwrap();
        assert_eq!(eval.play_action_cost, 0, "Fast covers 广义打出 from path open");
        assert_eq!(eval.effective_resource_cost, 3, "Fast path does not discount resources");
        assert_eq!(eval.cost_intents.len(), 2); // exhaust + pay 3
        match &eval.cost_intents[0] {
            Intent::SetExhausted { card_id, exhausted } => {
                assert_eq!(card_id, "chuck");
                assert!(*exhausted);
            }
            other => panic!("expected exhaust, got {other:?}"),
        }
    }

    #[test]
    fn chuck_cheap_path_folds_minus_two_at_feasibility() {
        let snap = snap_with_chuck(false, 2);
        let path = chuck_cheap_path("chuck", "event");
        assert_eq!(path.play_form, PlayForm::PlayAction);
        assert_eq!(path.resource_cost_delta, -2);
        assert_eq!(path.window, WindowConstraint::None);

        // Printed 3 with −2 → need 1; have 2 → ok. Without fold would need 3 and fail.
        let eval = evaluate_path(&snap.data, &path, &ctx(3, true)).unwrap();
        assert_eq!(eval.play_action_cost, 1);
        assert_eq!(eval.effective_resource_cost, 1);
        assert_eq!(effective_resource_cost(3, -2), 1);
        assert_eq!(effective_resource_cost(1, -2), 0);

        let default = default_play_path("event", false);
        let err = evaluate_path(&snap.data, &default, &ctx(3, true)).unwrap_err();
        assert_eq!(
            err,
            PathError::InsufficientResources { have: 2, need: 3 }
        );
    }

    #[test]
    fn cheap_path_pays_folded_resources_and_exhaust() {
        let snap = snap_with_chuck(false, 5);
        let path = chuck_cheap_path("chuck", "event");
        let eval = evaluate_path(&snap.data, &path, &ctx(4, true)).unwrap();
        assert_eq!(eval.effective_resource_cost, 2);
        let (after, report) = commit(snap, &eval.cost_intents).unwrap();
        assert!(report.created);
        assert!(after.data.board.cards["chuck"].exhausted);
        assert_eq!(resources_of(&after.data, "P1"), 3);
    }

    #[test]
    fn offer_lists_default_fast_and_cheap_when_ready() {
        let offer = offer_play_paths("event", false, Some("chuck"));
        assert_eq!(offer.paths.len(), 3);
        assert!(offer.paths[0].opened_by.is_none());
        assert!(offer.paths[1].id.contains("chuck_fast"));
        assert!(offer.paths[2].id.contains("chuck_cheap"));
        assert_eq!(offer.paths[2].resource_cost_delta, -2);
    }

    #[test]
    fn offer_only_default_without_chuck() {
        let offer = offer_play_paths("event", false, None);
        assert_eq!(offer.paths.len(), 1);
        assert_eq!(offer.paths[0].play_form, PlayForm::PlayAction);
    }

    #[test]
    fn exhausted_chuck_blocks_fast_path() {
        let snap = snap_with_chuck(true, 5);
        let path = chuck_fast_path("chuck", "event");
        let err = evaluate_path(&snap.data, &path, &ctx(0, true)).unwrap_err();
        assert_eq!(err, PathError::SourceExhausted("chuck".into()));
    }

    #[test]
    fn taboo_window_requires_controller_turn() {
        let snap = snap_with_chuck(false, 5);
        let path = chuck_fast_path("chuck", "event");
        let err = evaluate_path(&snap.data, &path, &ctx(0, false)).unwrap_err();
        assert_eq!(err, PathError::WindowNotOpen);
    }

    #[test]
    fn paying_additional_cost_exhausts_chuck_created() {
        let snap = snap_with_chuck(false, 5);
        let path = chuck_fast_path("chuck", "event");
        let eval = evaluate_path(&snap.data, &path, &ctx(0, true)).unwrap();
        let (after, report) = commit(snap, &eval.cost_intents).unwrap();
        assert!(report.created);
        assert!(after.data.board.cards["chuck"].exhausted);
        let err = evaluate_path(&after.data, &path, &ctx(0, true)).unwrap_err();
        assert_eq!(err, PathError::SourceExhausted("chuck".into()));
    }

    #[test]
    fn not_would_by_construction() {
        let fast = chuck_fast_path("chuck", "event");
        let cheap = chuck_cheap_path("chuck", "event");
        assert!(!is_would_rewrite(&fast));
        assert!(!is_would_rewrite(&cheap));
        assert_ne!(fast.play_form, PlayForm::PlayAction);
        assert_eq!(cheap.play_form, PlayForm::PlayAction);
        assert_eq!(cheap.resource_cost_delta, -2);
    }
}
