//! Functional rules kernel — Snapshot / Auth / commit (M1 world types).
//!
//! Shape aligns with `docs/design/37-world-structure.md`.

pub mod intent;
pub mod world;

pub use intent::{commit, Intent};
pub use world::{
    Auth, Audience, Card, CardType, Chronicle, Face, Feasibility, Focus, Framework, LimboKind,
    Region, RegionShape, Registration, RegistrationKind, RegistrationPayload, Run, Snapshot,
    StatusPayload, Subject,
};
