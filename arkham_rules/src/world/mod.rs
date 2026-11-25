//! Authoritative Snapshot types — see docs/design/37-world-structure.md.

use std::collections::BTreeMap;
use serde::{Deserialize, Serialize};

pub type CardId = String;
pub type RegionId = String;
pub type RegId = String;

/// Infinite token supply endpoint for `TransferToken` (07 Transfer-only).
/// Not required as a real `Region` entry; from-side never insufficient, to-side does not grow stacks.
pub const TOKEN_SUPPLY: &str = "$supply";

/// Whole functional operand: auth ⊕ derived ⊕ run ⊕ gen.
#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Snapshot {
    pub auth: Auth,
    pub derived: Derived,
    pub run: Run,
    pub gen: u64,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Auth {
    pub cards: BTreeMap<CardId, Card>,
    pub regions: BTreeMap<RegionId, Region>,
    /// Investigator seat state (turn economy / eliminated / resigned). Key = investigator card id.
    pub seats: BTreeMap<CardId, Seat>,
    pub registrations: BTreeMap<RegId, Registration>,
    /// Gain characteristics (KEYWORD/TRAIT/ICON/ABILITY) — not Registration payloads.
    pub gains: BTreeMap<String, GainedCharacteristic>,
    pub chronicle: Chronicle,
    pub audience: BTreeMap<CardId, Audience>,
    pub limits: LimitStore,
    pub framework: Framework,
    pub next_id: u64,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Derived {
    pub index: RegIndex,
    pub feasibility: Feasibility,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Run {
    pub stack: Vec<Frame>,
    pub open_choice: Option<ChoiceState>,
    pub skill_tests: Vec<SkillTest>,
    /// controller_id → (key → value)
    pub memory: BTreeMap<String, BTreeMap<String, String>>,
    pub focus: Focus,
    pub timing_phase: String,
}

// —— Card / Region ——

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Card {
    pub id: CardId,
    pub definition_id: String,
    pub card_type: CardType,
    pub owner_id: String,
    pub controller_id: String,
    pub face: Face,
    pub exhausted: bool,
    /// place → region_id (not rules asset slots).
    pub owned_regions: BTreeMap<String, RegionId>,
    pub connections: Vec<CardId>,
}

impl Default for Card {
    fn default() -> Self {
        Self {
            id: String::new(),
            definition_id: String::new(),
            card_type: CardType::Asset,
            owner_id: String::new(),
            controller_id: String::new(),
            face: Face::A,
            exhausted: false,
            owned_regions: BTreeMap::new(),
            connections: Vec::new(),
        }
    }
}

/// Investigator seat — turn economy and scenario outcome flags (not Card spine).
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Seat {
    pub investigator_id: CardId,
    pub actions_remaining: i32,
    pub actions_bonus_next_turn: i32,
    pub actions_penalty_next_turn: i32,
    pub eliminated: bool,
    pub resigned: bool,
}

impl Seat {
    pub fn fresh(investigator_id: impl Into<String>, actions: i32) -> Self {
        Self {
            investigator_id: investigator_id.into(),
            actions_remaining: actions,
            actions_bonus_next_turn: 0,
            actions_penalty_next_turn: 0,
            eliminated: false,
            resigned: false,
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CardType {
    Investigator,
    Asset,
    Event,
    Skill,
    Enemy,
    Treachery,
    Location,
    Act,
    Agenda,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub enum Face {
    A,
    B,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Region {
    pub id: RegionId,
    pub shape: RegionShape,
    pub host_card_id: String,
    /// Placement-face role; ≠ asset slot.
    pub place: String,
    pub card_ids: Vec<CardId>,
    /// token type → count (terminal stacks).
    pub token_stacks: BTreeMap<String, i32>,
    pub limbo_kind: LimboKind,
}

impl Default for Region {
    fn default() -> Self {
        Self {
            id: String::new(),
            shape: RegionShape::Flat,
            host_card_id: String::new(),
            place: String::new(),
            card_ids: Vec::new(),
            token_stacks: BTreeMap::new(),
            limbo_kind: LimboKind::None,
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum RegionShape {
    Deck,
    Flat,
    Bag,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum LimboKind {
    #[default]
    #[serde(rename = "")]
    None,
    Resolving,
    Committed,
}

// —— Registration ——

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Registration {
    pub id: RegId,
    pub source_card_id: CardId,
    pub subject: Subject,
    pub lifetime: String,
    pub bound_id: String,
    pub payloads: Vec<RegistrationPayload>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(tag = "tag", rename_all = "snake_case")]
pub enum Subject {
    Bound { card_id: CardId },
    Matching {
        filter_id: String,
        filter_args: BTreeMap<String, String>,
    },
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum RegistrationPayload {
    Modifier { modifier: ModifierPayload },
    Gate { gate: GatePayload },
    Directive { directive: DirectivePayload },
    Listener { listener: ListenerPayload },
    Status { status: StatusPayload },
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum RegistrationKind {
    Modifier,
    Gate,
    Directive,
    Listener,
    Status,
}

impl RegistrationPayload {
    pub fn kind(&self) -> RegistrationKind {
        match self {
            Self::Modifier { .. } => RegistrationKind::Modifier,
            Self::Gate { .. } => RegistrationKind::Gate,
            Self::Directive { .. } => RegistrationKind::Directive,
            Self::Listener { .. } => RegistrationKind::Listener,
            Self::Status { .. } => RegistrationKind::Status,
        }
    }
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct ModifierPayload {
    pub stat: String,
    pub op: String,
    pub value: i32,
    pub condition: String,
    pub plan_kind: String,
    pub apply_mode: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct GatePayload {
    pub kind: String,
    pub drawer_id: String,
    pub drawn_card_id: String,
    pub encounter_frame_id: String,
    pub subject_id: String,
}

/// Per-kind body — not a flat union of every directive field (spine slim).
#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum DirectivePayload {
    SkipAoo {
        #[serde(default)]
        drawer_id: String,
        #[serde(default)]
        drawn_card_id: String,
        #[serde(default)]
        subject_id: String,
    },
    SuppressAutoEngage {
        #[serde(default)]
        subject_id: String,
    },
    AssignConstraint {
        assign: AssignConstraintBody,
    },
    SkillRedirect {
        redirect_from: i32,
        redirect_to: i32,
        #[serde(default)]
        subject_id: String,
    },
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct AssignConstraintBody {
    pub assign_op: String,
    pub assign_affliction: String,
    pub assign_direct_scope: String,
    pub assign_expand_scope: String,
    pub assign_trait: String,
    pub assign_amount: i32,
    pub assign_if_able: bool,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct ListenerPayload {
    pub timing: String,
    /// Catalog / loaded composition handle id.
    pub composition: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct StatusPayload {
    pub kind: String,
    pub subject_id: String,
    pub drawer_id: String,
}

impl StatusPayload {
    pub fn engagement(enemy_id: impl Into<String>, investigator_id: impl Into<String>) -> Self {
        Self {
            kind: "engagement".into(),
            subject_id: enemy_id.into(),
            drawer_id: investigator_id.into(),
        }
    }
}

/// Gain characteristic record (auth.gains) — not a Registration payload.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct GainedCharacteristic {
    pub id: String,
    pub card_id: CardId,
    pub kind: String,
    pub characteristic_id: String,
    pub source_kind: String,
    pub lifetime: String,
}

// —— Chronicle / Audience / Framework / Limits ——

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Chronicle {
    pub log: Vec<LogEntry>,
    pub remembered: BTreeMap<String, String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct LogEntry {
    pub text: String,
    pub round: i32,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Audience {
    HiddenAll,
    Controller,
    All,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Framework {
    pub round: i32,
    pub lead_investigator_id: String,
    pub active_investigator_id: String,
    pub current_act_id: String,
    pub current_agenda_id: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct LimitStore {
    pub counters: BTreeMap<String, LimitCounter>,
    /// Max-N occupancy (not rules asset slots).
    pub occupancies: BTreeMap<String, Occupancy>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct LimitCounter {
    pub limit_key: String,
    pub spec_id: String,
    pub period: String,
    pub scope: String,
    pub subject_id: String,
    pub used: i32,
    pub cap: i32,
    pub window_id: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Occupancy {
    pub limit_key: String,
    pub kind: String,
    pub subject_id: String,
    pub holders: Vec<CardId>,
    pub cap: i32,
}

// —— Derived / Run helpers ——

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct RegIndex {
    pub by_bound: BTreeMap<String, Vec<RegId>>,
    pub by_aspect: BTreeMap<String, Vec<RegId>>,
    pub by_bound_aspect: BTreeMap<String, Vec<RegId>>,
    pub matching_by_aspect: BTreeMap<String, Vec<RegId>>,
    pub by_source: BTreeMap<String, Vec<RegId>>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Feasibility {
    pub focus_fp: String,
    pub answers: BTreeMap<String, LegalAnswer>,
    pub deps: BTreeMap<String, Vec<String>>,
    pub reverse: BTreeMap<String, Vec<String>>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct LegalAnswer {
    pub data_ok: bool,
    pub effect_ok: bool,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Focus {
    pub window: String,
    pub controller_id: String,
    pub open_must_ask_id: String,
    pub initiation_pool_ids: Vec<String>,
    pub response_pool_ids: Vec<String>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Frame {
    pub flow_id: String,
    pub env: BTreeMap<String, String>,
    pub step_index: i32,
    pub cancelled: bool,
    pub created: bool,
    pub cont_after: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct ChoiceState {
    pub ask_id: String,
    pub kind: String,
    pub default_value: String,
    pub candidates: Vec<String>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct SkillTest {
    pub test_id: String,
    pub investigator_id: String,
    pub skill: String,
    pub difficulty: i32,
    pub committed_ids: Vec<CardId>,
    pub success: Option<bool>,
    pub fail_by: i32,
}

impl Snapshot {
    /// Token count on a card's `tokens` place (0 if missing).
    pub fn token_on_card(&self, card_id: &str, token_type: &str) -> i32 {
        let Some(card) = self.auth.cards.get(card_id) else {
            return 0;
        };
        let Some(rid) = card.owned_regions.get("tokens") else {
            return 0;
        };
        self.auth
            .regions
            .get(rid)
            .and_then(|r| r.token_stacks.get(token_type).copied())
            .unwrap_or(0)
    }

    /// Location card whose `on` region contains `card_id`.
    pub fn location_of(&self, card_id: &str) -> Option<&CardId> {
        for (loc_id, card) in &self.auth.cards {
            if card.card_type != CardType::Location {
                continue;
            }
            let Some(on_id) = card.owned_regions.get("on") else {
                continue;
            };
            let Some(region) = self.auth.regions.get(on_id) else {
                continue;
            };
            if region.card_ids.iter().any(|id| id == card_id) {
                return Some(loc_id);
            }
        }
        None
    }
}
