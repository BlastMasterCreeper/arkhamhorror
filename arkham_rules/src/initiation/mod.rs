//! Initiation paths — Constant **additional-cost → second PLAY_CARD path**.
//!
//! Thin cut: Chuck Fergus (09072) Fast option.
//! Prefs: Fast covers the **whole initiation** (广义打出); **not** Would / timing rewrite.
//! Personal SoT: `docs/reference/personal-card-text.md` · 09072.

use crate::intent::Intent;
use crate::world::Data;

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
    /// Constant source that opened this path (e.g. Chuck instance id).
    pub opened_by: Option<String>,
}

/// Bundle of alternate paths offered for one play attempt.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct PathOffer {
    pub paths: Vec<InitiationPath>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum PathError {
    MissingCard(String),
    SourceExhausted(String),
    WindowNotOpen,
}

/// Cost view for choosing a path — evaluated **before** initiation timing exists.
#[derive(Clone, Debug)]
pub struct PathEvaluation {
    /// Play-action cost for this whole initiation (广义打出). Fast → 0.
    pub play_action_cost: i32,
    /// Settlement intents that pay path additional costs (exhaust …).
    pub cost_intents: Vec<Intent>,
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
        opened_by: None,
    }
}

/// Chuck 09072 Constant — Fast additional-cost second initiation path.
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
        opened_by: Some(chuck),
    }
}

/// Enumerate PLAY_CARD paths: always the default; optionally Chuck Fast when Constant applies.
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
        paths.push(chuck_fast_path(chuck, event));
    }
    PathOffer { paths }
}

/// Evaluate path costs. Must pass before any initiation timing is opened (prefs / validity).
pub fn evaluate_path(
    data: &Data,
    path: &InitiationPath,
    during_controller_turn: bool,
) -> Result<PathEvaluation, PathError> {
    if path.window == WindowConstraint::DuringControllerTurn && !during_controller_turn {
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

    let play_action_cost = if path.play_form.waives_play_action() {
        0
    } else {
        1
    };
    Ok(PathEvaluation {
        play_action_cost,
        cost_intents,
    })
}

/// Paths are alternate initiations — never Would / OnTiming rewrites (prefs).
pub fn is_would_rewrite(_path: &InitiationPath) -> bool {
    false
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::intent::{commit, Intent};
    use crate::world::{Card, CardType, Face, Snapshot};

    fn snap_with_chuck(exhausted: bool) -> Snapshot {
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
        snap
    }

    #[test]
    fn default_path_costs_play_action() {
        let path = default_play_path("event", false);
        assert_eq!(path.play_form, PlayForm::PlayAction);
        assert!(!path.play_form.waives_play_action());
        let eval = evaluate_path(&Data::default(), &path, true).unwrap();
        assert_eq!(eval.play_action_cost, 1);
        assert!(eval.cost_intents.is_empty());
        assert!(!is_would_rewrite(&path));
    }

    #[test]
    fn chuck_fast_path_waives_action_whole_initiation() {
        let snap = snap_with_chuck(false);
        let path = chuck_fast_path("chuck", "event");
        assert_eq!(path.play_form, PlayForm::FastWindow);
        assert_eq!(path.window, WindowConstraint::DuringControllerTurn);
        assert_eq!(path.opened_by.as_deref(), Some("chuck"));
        assert!(path.play_form.waives_play_action());
        assert!(!is_would_rewrite(&path));

        let eval = evaluate_path(&snap.data, &path, true).unwrap();
        assert_eq!(eval.play_action_cost, 0, "Fast covers 广义打出 from path open");
        assert_eq!(eval.cost_intents.len(), 1);
        match &eval.cost_intents[0] {
            Intent::SetExhausted { card_id, exhausted } => {
                assert_eq!(card_id, "chuck");
                assert!(*exhausted);
            }
            other => panic!("expected exhaust, got {other:?}"),
        }
    }

    #[test]
    fn offer_lists_default_and_chuck_when_ready() {
        let offer = offer_play_paths("event", false, Some("chuck"));
        assert_eq!(offer.paths.len(), 2);
        assert!(offer.paths[0].opened_by.is_none());
        assert_eq!(offer.paths[1].opened_by.as_deref(), Some("chuck"));
        assert_eq!(offer.paths[1].play_form, PlayForm::FastWindow);
    }

    #[test]
    fn offer_only_default_without_chuck() {
        let offer = offer_play_paths("event", false, None);
        assert_eq!(offer.paths.len(), 1);
        assert_eq!(offer.paths[0].play_form, PlayForm::PlayAction);
    }

    #[test]
    fn exhausted_chuck_blocks_fast_path() {
        let snap = snap_with_chuck(true);
        let path = chuck_fast_path("chuck", "event");
        let err = evaluate_path(&snap.data, &path, true).unwrap_err();
        assert_eq!(err, PathError::SourceExhausted("chuck".into()));
    }

    #[test]
    fn taboo_window_requires_controller_turn() {
        let snap = snap_with_chuck(false);
        let path = chuck_fast_path("chuck", "event");
        let err = evaluate_path(&snap.data, &path, false).unwrap_err();
        assert_eq!(err, PathError::WindowNotOpen);
    }

    #[test]
    fn paying_additional_cost_exhausts_chuck_created() {
        let snap = snap_with_chuck(false);
        let path = chuck_fast_path("chuck", "event");
        let eval = evaluate_path(&snap.data, &path, true).unwrap();
        let (after, report) = commit(snap, &eval.cost_intents).unwrap();
        assert!(report.created);
        assert!(after.data.board.cards["chuck"].exhausted);
        // Second evaluate fails — Constant path no longer available while exhausted.
        let err = evaluate_path(&after.data, &path, true).unwrap_err();
        assert_eq!(err, PathError::SourceExhausted("chuck".into()));
    }

    #[test]
    fn not_would_by_construction() {
        let path = chuck_fast_path("chuck", "event");
        assert!(!is_would_rewrite(&path));
        // Choosing Fast path never invents OnTiming / Would rewrite of a PlayAction start.
        assert_ne!(path.play_form, PlayForm::PlayAction);
    }
}
