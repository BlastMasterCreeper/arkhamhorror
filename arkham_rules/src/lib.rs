//! Functional rules kernel — Data foundation + M2 Eff subset + initiation paths.
//!
//! Shape: `docs/design/37-world-structure.md` · World_FP: `docs/design/38-functional-data-world.md`.
//! Eff: `docs/design/25-functional-eff.md`.
//! Chuck Fast path: personal Constant additional-cost → second `PLAY_CARD` initiation.

pub mod amount;
pub mod catalog;
pub mod eff;
pub mod initiation;
pub mod intent;
pub mod legal;
pub mod query;
pub mod world;

pub use amount::{
    apply_folds, assign, build_plan, settle_intents, AmountEffectShape, AmountLeg, AmountPlan,
    AmountPlanKind, AssignError, SettleError,
};
pub use catalog::{Catalog, Flow};
pub use eff::{
    answer, draw_one_eff, eval_pred, plan, run_to_ask_or_done, step, AskRequest, Eff, PlanResult,
    Pred, StepResult,
};
pub use initiation::{
    chuck_fast_path, default_play_path, evaluate_path, is_would_rewrite, offer_play_paths,
    AdditionalCost, InitiationKind, InitiationPath, PathError, PathEvaluation, PathOffer, PlayForm,
    WindowConstraint,
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
