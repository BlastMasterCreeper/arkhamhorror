//! Functional rules kernel — Snapshot / Eff / commit.
//!
//! Shape: `docs/design/37-world-structure.md` · Eff: `docs/design/25-functional-eff.md`.

pub mod catalog;
pub mod eff;
pub mod intent;
pub mod world;

pub use catalog::{Catalog, Flow};
pub use eff::{
    answer, draw_one_eff, eval_pred, plan, run_to_ask_or_done, step, AskRequest, Eff, PlanResult,
    Pred, StepResult,
};
pub use intent::{commit, engagement_relation, Intent};
pub use world::{
    AssignConstraintBody, Audience, Board, Card, CardType, Chronicle, Constraints, Data,
    DirectivePayload, Face, Facts, Feasibility, Focus, Framework, GatePayload, GateScope, InfoShell,
    LimboKind, ListenerPayload, ModifierPayload, Policy, PolicyBody, PolicyKind, Region,
    RegionShape, Relation, RelationBody, Run, Seat, Snapshot, Subject, TOKEN_SUPPLY,
};
