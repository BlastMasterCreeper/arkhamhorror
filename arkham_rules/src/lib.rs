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
pub use intent::{commit, engagement_reg, Intent};
pub use world::{
    AssignConstraintBody, Auth, Audience, Card, CardType, Chronicle, DirectivePayload, Face,
    Feasibility, Focus, Framework, LimboKind, Region, RegionShape, Registration, RegistrationKind,
    RegistrationPayload, Run, Seat, Snapshot, StatusPayload, Subject, TOKEN_SUPPLY,
};
