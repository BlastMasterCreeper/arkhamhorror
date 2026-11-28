//! Functional rules kernel — Data foundation.
//!
//! Shape: `docs/design/37-world-structure.md` · World_FP: `docs/design/38-functional-data-world.md`.

pub mod intent;
pub mod world;

pub use intent::{
    commit, engagement_relation, guard_policy, CommitError, CommitReport, Intent,
};
pub use world::{
    AssignConstraintBody, Audience, Board, Card, CardType, Chronicle, Constraints, Data,
    DirectivePayload, Face, Facts, Feasibility, Focus, Framework, GatePayload, GateScope,
    GuardPolarity, InfoShell, LimboKind, LimitStore, ListenerPayload, ModifierPayload, Policy,
    PolicyBody, PolicyKind, Region, RegionShape, Relation, RelationBody, Run, Seat, Snapshot,
    Subject, TOKEN_SUPPLY,
};
