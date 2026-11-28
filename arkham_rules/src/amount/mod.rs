//! AmountPlan — build → FoldStat stack amount → Assign (PI) → settle → Intent[].
//!
//! Preferences: **Assign is PI confirmation, not settlement.**
//! Thin cut: ATTACK_DAMAGE / DISCOVER · DETERMINED / ASSIGN shapes.
//! Chuck / full deal.assignable seq / gdext — out of scope.

use crate::intent::Intent;
use crate::query::query_stat;
use crate::world::{Data, TOKEN_SUPPLY};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AmountPlanKind {
    AttackDamage,
    Discover,
}

impl AmountPlanKind {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::AttackDamage => "attack_damage",
            Self::Discover => "discover",
        }
    }

    /// Token type written on settle (thin: damage / clue stacks).
    pub fn token_type(self) -> &'static str {
        match self {
            Self::AttackDamage => "damage",
            Self::Discover => "clue",
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AmountEffectShape {
    /// Legs already fixed; FoldStat adjusts primary (then legs[0] for thin cut).
    Determined,
    /// `amount` is pooled; Assign (PI) materializes legs.
    Assign,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct AmountLeg {
    pub subject_id: String,
    pub amount: i32,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct AmountPlan {
    pub kind: AmountPlanKind,
    pub effect_shape: AmountEffectShape,
    /// ASSIGN: pooled attack/discover amount. DETERMINED: mirrors primary after fold.
    pub amount: i32,
    pub legs: Vec<AmountLeg>,
    pub primary_subject_id: String,
    pub candidate_ids: Vec<String>,
}

/// Step 1–2: open a plan before FoldStat / Assign.
pub fn build_plan(
    kind: AmountPlanKind,
    shape: AmountEffectShape,
    base_amount: i32,
    primary_subject_id: impl Into<String>,
    candidate_ids: Vec<String>,
) -> AmountPlan {
    let primary = primary_subject_id.into();
    let mut plan = AmountPlan {
        kind,
        effect_shape: shape,
        amount: base_amount.max(0),
        legs: Vec::new(),
        primary_subject_id: primary.clone(),
        candidate_ids,
    };
    if shape == AmountEffectShape::Determined {
        plan.legs.push(AmountLeg {
            subject_id: primary,
            amount: plan.amount,
        });
    }
    plan
}

/// Step 3: FoldStat stack onto plan amount (`stat` = kind key, e.g. `attack_damage`).
/// DETERMINED: also bumps primary leg. ASSIGN: only `amount` (legs still empty).
pub fn apply_folds(data: &Data, plan: &mut AmountPlan) {
    let folded = query_stat(data, plan.amount, plan.kind.as_str()).max(0);
    plan.amount = folded;
    if plan.effect_shape == AmountEffectShape::Determined {
        if let Some(leg) = plan.legs.first_mut() {
            leg.amount = folded;
        }
    }
}

/// Step 3b (ASSIGN only): PI materialization — not settlement.
/// `parts`: (subject_id, amount); sum must equal `plan.amount`.
/// Empty `parts` → default: all amount on primary (overdue Gate default).
pub fn assign(plan: &mut AmountPlan, parts: &[(String, i32)]) -> Result<(), AssignError> {
    if plan.effect_shape != AmountEffectShape::Assign {
        return Err(AssignError::NotAssignable);
    }
    let parts: Vec<(String, i32)> = if parts.is_empty() {
        vec![(plan.primary_subject_id.clone(), plan.amount)]
    } else {
        parts.to_vec()
    };
    let sum: i32 = parts.iter().map(|(_, n)| *n).sum();
    if sum != plan.amount {
        return Err(AssignError::SumMismatch {
            expected: plan.amount,
            got: sum,
        });
    }
    for (id, n) in &parts {
        if *n < 0 {
            return Err(AssignError::NegativeAmount);
        }
        if !plan.candidate_ids.is_empty() && !plan.candidate_ids.iter().any(|c| c == id) {
            return Err(AssignError::NotCandidate(id.clone()));
        }
    }
    plan.legs = parts
        .into_iter()
        .filter(|(_, n)| *n > 0)
        .map(|(subject_id, amount)| AmountLeg {
            subject_id,
            amount,
        })
        .collect();
    Ok(())
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum AssignError {
    NotAssignable,
    SumMismatch { expected: i32, got: i32 },
    NegativeAmount,
    NotCandidate(String),
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum SettleError {
    NotAssigned,
    MissingTokensRegion(String),
}

/// Step 4: settlement — produce TransferToken intents (does not commit).
/// `tokens_region_of(subject_id) -> region_id` for that card's `tokens` place.
pub fn settle_intents(
    plan: &AmountPlan,
    tokens_region_of: impl Fn(&str) -> Option<String>,
) -> Result<Vec<Intent>, SettleError> {
    if plan.legs.is_empty() {
        return Err(SettleError::NotAssigned);
    }
    let token = plan.kind.token_type();
    let mut out = Vec::new();
    for leg in &plan.legs {
        let region = tokens_region_of(&leg.subject_id)
            .ok_or_else(|| SettleError::MissingTokensRegion(leg.subject_id.clone()))?;
        out.push(Intent::TransferToken {
            token_type: token.into(),
            amount: leg.amount,
            from_region: TOKEN_SUPPLY.into(),
            to_region: region,
        });
    }
    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::query::fold_stat_policy;
    use crate::world::{Constraints, ModifierPayload};
    use std::collections::BTreeMap;

    fn data_with_combat_bonus(n: i32) -> Data {
        let mut policies = BTreeMap::new();
        let p = fold_stat_policy(
            "fatal",
            "card",
            ModifierPayload {
                stat: "attack_damage".into(),
                op: "add".into(),
                value: n,
                ..ModifierPayload::default()
            },
        );
        policies.insert(p.shell.id.clone(), p);
        Data {
            constraints: Constraints { policies },
            ..Data::default()
        }
    }

    #[test]
    fn determined_fold_then_settle() {
        let data = data_with_combat_bonus(1);
        let mut plan = build_plan(
            AmountPlanKind::AttackDamage,
            AmountEffectShape::Determined,
            1,
            "E1",
            vec!["E1".into()],
        );
        assert_eq!(plan.legs[0].amount, 1);
        apply_folds(&data, &mut plan);
        assert_eq!(plan.amount, 2);
        assert_eq!(plan.legs[0].amount, 2);
        let intents = settle_intents(&plan, |id| Some(format!("tok_{id}"))).unwrap();
        assert_eq!(intents.len(), 1);
        match &intents[0] {
            Intent::TransferToken {
                token_type,
                amount,
                to_region,
                ..
            } => {
                assert_eq!(token_type, "damage");
                assert_eq!(*amount, 2);
                assert_eq!(to_region, "tok_E1");
            }
            other => panic!("unexpected {other:?}"),
        }
    }

    #[test]
    fn assign_is_pi_not_auto_settle() {
        let data = Data::default();
        let mut plan = build_plan(
            AmountPlanKind::AttackDamage,
            AmountEffectShape::Assign,
            4,
            "E1",
            vec!["E1".into(), "E2".into()],
        );
        apply_folds(&data, &mut plan);
        assert_eq!(plan.amount, 4);
        assert!(plan.legs.is_empty());
        assert!(matches!(
            settle_intents(&plan, |_| Some("x".into())),
            Err(SettleError::NotAssigned)
        ));

        // PI default: empty parts → primary gets all
        assign(&mut plan, &[]).unwrap();
        assert_eq!(plan.legs.len(), 1);
        assert_eq!(plan.legs[0].subject_id, "E1");
        assert_eq!(plan.legs[0].amount, 4);
    }

    #[test]
    fn assign_among_candidates_then_settle() {
        let data = data_with_combat_bonus(1);
        let mut plan = build_plan(
            AmountPlanKind::AttackDamage,
            AmountEffectShape::Assign,
            4,
            "E1",
            vec!["E1".into(), "E2".into()],
        );
        apply_folds(&data, &mut plan);
        assert_eq!(plan.amount, 5);
        assign(
            &mut plan,
            &[("E1".into(), 3), ("E2".into(), 2)],
        )
        .unwrap();
        let intents = settle_intents(&plan, |id| Some(format!("tok_{id}"))).unwrap();
        assert_eq!(intents.len(), 2);
    }

    #[test]
    fn discover_determined() {
        let mut plan = build_plan(
            AmountPlanKind::Discover,
            AmountEffectShape::Determined,
            1,
            "L1",
            vec!["L1".into()],
        );
        apply_folds(&Data::default(), &mut plan);
        let intents = settle_intents(&plan, |_| Some("tok_L1".into())).unwrap();
        match &intents[0] {
            Intent::TransferToken {
                token_type,
                amount,
                ..
            } => {
                assert_eq!(token_type, "clue");
                assert_eq!(*amount, 1);
            }
            other => panic!("{other:?}"),
        }
    }
}
