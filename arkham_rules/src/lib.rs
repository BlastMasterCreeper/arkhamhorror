//! Functional rules kernel — Data foundation + M2 Eff subset.
//!
//! Shape: `docs/design/37-world-structure.md` · World_FP: `docs/design/38-functional-data-world.md`.
//! Eff: `docs/design/25-functional-eff.md`.

pub mod catalog;
pub mod eff;
pub mod intent;
pub mod legal;
pub mod query;
pub mod world;

pub use catalog::{Catalog, Flow};
pub use eff::{
    answer, draw_one_eff, eval_pred, plan, run_to_ask_or_done, step, AskRequest, Eff, PlanResult,
    Pred, StepResult,
};
pub use intent::{
    commit, dry_run, engagement_relation, gained, guard_policy, CommitError, CommitReport, Intent,
};
pub use legal::{fold_guards, legal, GuardedAct, LegalVerdict};
pub use query::{fold_stat_policy, fold_stats, query_stat};
pub use world::{
    AssignConstraintBody, Audience, Board, Card, CardType, Chronicle, Constraints, Data,
    DirectivePayload, Face, Facts, Feasibility, Focus, Framework, GatePayload, GateScope,
    GainedCharacteristic, GuardPolarity, InfoShell, LimboKind, LimitStore, ListenerPayload,
    LogEntry, ModifierPayload, Policy, PolicyBody, PolicyKind, Region, RegionShape, Relation,
    RelationBody, Run, Seat, Snapshot, Subject, TOKEN_SUPPLY,
};
