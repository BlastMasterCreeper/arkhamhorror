//! Authoritative Snapshot types — see docs/design/37-world-structure.md · 38.

use std::collections::BTreeMap;
use serde::{Deserialize, Serialize};

pub type CardId = String;
pub type RegionId = String;
pub type RegId = String;

/// Infinite token supply endpoint for `TransferToken` (07 Transfer-only).
pub const TOKEN_SUPPLY: &str = "$supply";

/// Snapshot = data ⊕ derived ⊕ run ⊕ gen.
///
/// **Data** = World_FP (38). **Board** = physical partition only — not the functional world.
#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Snapshot {
    pub data: Data,
    pub derived: Derived,
    pub run: Run,
    pub gen: u64,
}

/// Functional world (World_FP): Board × Facts × Constraints × Limits × Framework × Seats
/// (+ Audience, not CREATED).
#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Data {
    pub board: Board,
    pub facts: Facts,
    pub constraints: Constraints,
    pub limits: LimitStore,
    pub framework: Framework,
    /// Key = investigator card id.
    pub seats: BTreeMap<CardId, Seat>,
    /// Permission bypass — authoritative but never CREATED.
    pub audience: BTreeMap<CardId, Audience>,
    pub next_id: u64,
}

/// Physical partition only: Placement ∪ Measure ∪ Form (cards + regions).
#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Board {
    pub cards: BTreeMap<CardId, Card>,
    pub regions: BTreeMap<RegionId, Region>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Facts {
    pub relations: BTreeMap<RegId, Relation>,
    pub gains: BTreeMap<String, GainedCharacteristic>,
    pub chronicle: Chronicle,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Constraints {
    pub policies: BTreeMap<RegId, Policy>,
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
            connections: Vec::new(),
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Seat {
    pub actions_remaining: i32,
    pub eliminated: bool,
    pub resigned: bool,
}

impl Seat {
    pub fn fresh(actions: i32) -> Self {
        Self {
            actions_remaining: actions,
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
    /// Player-hosted regions (`resource_pool`). Never investigator CardId.
    pub host_player_id: String,
    pub place: String,
    pub card_ids: Vec<CardId>,
    pub token_stacks: BTreeMap<String, i32>,
    pub limbo_kind: LimboKind,
}

impl Default for Region {
    fn default() -> Self {
        Self {
            id: String::new(),
            shape: RegionShape::Flat,
            host_card_id: String::new(),
            host_player_id: String::new(),
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

// —— Facts · Relations / Constraints · Policies ——

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
pub struct InfoShell {
    pub id: RegId,
    pub source_card_id: CardId,
    pub subject: Subject,
    pub lifetime: String,
    pub bound_id: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Relation {
    pub shell: InfoShell,
    pub body: RelationBody,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum RelationBody {
    Engagement {
        enemy_id: String,
        investigator_id: String,
    },
}

impl Relation {
    pub fn engagement(
        id: impl Into<String>,
        source_card_id: impl Into<String>,
        enemy_id: impl Into<String>,
        investigator_id: impl Into<String>,
    ) -> Self {
        let enemy = enemy_id.into();
        Self {
            shell: InfoShell {
                id: id.into(),
                source_card_id: source_card_id.into(),
                subject: Subject::Bound {
                    card_id: enemy.clone(),
                },
                lifetime: "while_in_play".into(),
                bound_id: String::new(),
            },
            body: RelationBody::Engagement {
                enemy_id: enemy,
                investigator_id: investigator_id.into(),
            },
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Policy {
    pub shell: InfoShell,
    pub body: PolicyBody,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum PolicyBody {
    /// Query-station fold shell (fold / AmountPlan not implemented in foundation).
    FoldStat { fold: ModifierPayload },
    /// Intent → Ok|Forbid door; Restrict ∪ Permit (38 v0.8).
    GuardIntent {
        polarity: GuardPolarity,
        gate: GatePayload,
    },
    DivertFlow { divert: DirectivePayload },
    OnTiming { on_timing: ListenerPayload },
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum PolicyKind {
    FoldStat,
    GuardIntent,
    DivertFlow,
    OnTiming,
}

impl PolicyBody {
    pub fn kind(&self) -> PolicyKind {
        match self {
            Self::FoldStat { .. } => PolicyKind::FoldStat,
            Self::GuardIntent { .. } => PolicyKind::GuardIntent,
            Self::DivertFlow { .. } => PolicyKind::DivertFlow,
            Self::OnTiming { .. } => PolicyKind::OnTiming,
        }
    }
}

/// Restrict = cannot / peril Forbid end; Permit = allow exception → Ok end.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum GuardPolarity {
    Restrict,
    Permit,
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

/// What class of Intent the guard matches — polarity lives on GuardIntent.
#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum GatePayload {
    Draw { subject_id: String },
    Play { scope: GateScope },
    Trigger { scope: GateScope },
    CommitToTest { scope: GateScope },
    LeaveHand { subject_id: String },
    DiscoverClue { subject_id: String },
    SpendClue { subject_id: String },
    Attack { subject_id: String },
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(tag = "tag", rename_all = "snake_case")]
pub enum GateScope {
    Subject { subject_id: String },
    Peril {
        drawer_id: String,
        drawn_card_id: String,
        encounter_frame_id: String,
    },
}

impl GatePayload {
    pub fn kind_name(&self) -> &'static str {
        match self {
            Self::Draw { .. } => "draw",
            Self::Play { .. } => "play",
            Self::Trigger { .. } => "trigger",
            Self::CommitToTest { .. } => "commit_to_test",
            Self::LeaveHand { .. } => "leave_hand",
            Self::DiscoverClue { .. } => "discover_clue",
            Self::SpendClue { .. } => "spend_clue",
            Self::Attack { .. } => "attack",
        }
    }
}

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
    pub composition: String,
}

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
    pub controller_id: String,
    pub bind_key: String,
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
    pub st_step: String,
    pub success: Option<bool>,
    pub fail_by: i32,
}

impl Snapshot {
    pub fn region_for_place(&self, host_card_id: &str, place: &str) -> Option<&Region> {
        self.data
            .board
            .regions
            .values()
            .find(|r| r.host_card_id == host_card_id && r.place == place)
    }

    pub fn region_id_for_place(&self, host_card_id: &str, place: &str) -> Option<&RegionId> {
        self.data.board.regions.iter().find_map(|(id, r)| {
            if r.host_card_id == host_card_id && r.place == place {
                Some(id)
            } else {
                None
            }
        })
    }

    pub fn region_for_player_place(&self, host_player_id: &str, place: &str) -> Option<&Region> {
        self.data
            .board
            .regions
            .values()
            .find(|r| r.host_player_id == host_player_id && r.place == place)
    }

    /// Token count on a card's `tokens` place (0 if missing).
    pub fn token_on_card(&self, card_id: &str, token_type: &str) -> i32 {
        self.region_for_place(card_id, "tokens")
            .and_then(|r| r.token_stacks.get(token_type).copied())
            .unwrap_or(0)
    }

    pub fn resources_of(&self, player_id: &str) -> i32 {
        self.region_for_player_place(player_id, "resource_pool")
            .and_then(|r| r.token_stacks.get("resource").copied())
            .unwrap_or(0)
    }

    pub fn location_of(&self, card_id: &str) -> Option<&CardId> {
        for (loc_id, card) in &self.data.board.cards {
            if card.card_type != CardType::Location {
                continue;
            }
            let Some(region) = self.region_for_place(loc_id, "on") else {
                continue;
            };
            if region.card_ids.iter().any(|id| id == card_id) {
                return Some(loc_id);
            }
        }
        None
    }

    pub fn is_engaged_with(&self, enemy_id: &str, investigator_id: &str) -> bool {
        self.data.facts.relations.values().any(|r| match &r.body {
            RelationBody::Engagement {
                enemy_id: e,
                investigator_id: i,
            } => e == enemy_id && i == investigator_id,
        })
    }
}

#[cfg(test)]
mod shape_tests {
    use super::*;

    #[test]
    fn data_partitions_exist_board_is_cards_regions_only() {
        let snap = Snapshot::default();
        let v = serde_json::to_value(&snap.data).unwrap();
        let obj = v.as_object().unwrap();
        for key in [
            "board",
            "facts",
            "constraints",
            "limits",
            "framework",
            "seats",
            "audience",
            "next_id",
        ] {
            assert!(obj.contains_key(key), "missing data.{key}");
        }
        let board = obj["board"].as_object().unwrap();
        assert_eq!(board.len(), 2);
        assert!(board.contains_key("cards"));
        assert!(board.contains_key("regions"));
        assert!(!board.contains_key("limits"));
        assert!(!board.contains_key("framework"));
        assert!(!board.contains_key("seats"));
    }

    #[test]
    fn guard_intent_carries_both_polarities() {
        let restrict = PolicyBody::GuardIntent {
            polarity: GuardPolarity::Restrict,
            gate: GatePayload::Play {
                scope: GateScope::Subject {
                    subject_id: "I".into(),
                },
            },
        };
        let permit = PolicyBody::GuardIntent {
            polarity: GuardPolarity::Permit,
            gate: GatePayload::Play {
                scope: GateScope::Subject {
                    subject_id: "I".into(),
                },
            },
        };
        assert_eq!(restrict.kind(), PolicyKind::GuardIntent);
        assert_eq!(permit.kind(), PolicyKind::GuardIntent);
        match (&restrict, &permit) {
            (
                PolicyBody::GuardIntent {
                    polarity: GuardPolarity::Restrict,
                    ..
                },
                PolicyBody::GuardIntent {
                    polarity: GuardPolarity::Permit,
                    ..
                },
            ) => {}
            _ => panic!("expected Restrict and Permit ends"),
        }
    }
}
