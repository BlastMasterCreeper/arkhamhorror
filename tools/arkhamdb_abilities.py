"""Segment and template-compile ArkhamDB card ability text.

Compile policy: reuse established templates/conditions (07 §3.3, prior vertical slices).
Split timing · condition · cost · effect when possible. Ask before extending when no precedent.
"""

from __future__ import annotations

import re
from typing import Any

REVELATION = re.compile(
    r"<b>Revelation</b>\s*[-–]\s*(.+?)(?=\n<b>|\[(?:reaction|action|fast)\]|\Z)",
    re.I | re.S,
)
FORCED = re.compile(
    r"<b>Forced</b>\s*[-–]\s*(.+?)(?=\n<b>|\[(?:reaction|action|fast)\]|\Z)",
    re.I | re.S,
)
TRIGGERED = re.compile(
    r"\[(reaction|action|fast)\]\s*:?\s*(.+?)(?=\n\[|\n<b>|\Z)",
    re.I | re.S,
)

STRIP_HTML = re.compile(r"<[^>]+>")

# Forced / Reaction / LISTENER 共用触发短语 → match_kind / SequencePhase。
# 仅映射已有命名流程 kind；未映射则 JSON 可带效果但不 register_triggered。
TRIGGER_PHRASE_MAP: list[tuple[re.Pattern[str], str, str]] = [
    (
        re.compile(r"^After doom is placed on the agenda\.?$", re.I),
        "mythos_place_doom",
        "AFTER",
    ),
    (
        re.compile(r"^After you discover 1 or more clues(?: at .+)?\.?$", re.I),
        "discover_clue",
        "AFTER",
    ),
    (
        re.compile(r"^When the investigation phase ends\.?$", re.I),
        "investigation_phase_ends",
        "WHEN",
    ),
]

LEAD_DRAW_FIRE = re.compile(
    r"^The lead investigator draws the topmost copy of Fire! "
    r"in the encounter discard pile",
    re.I,
)

TAKE_HORROR = re.compile(r"^Take (\d+) (direct )?horror\.?", re.I)
TAKE_DAMAGE = re.compile(r"^Take (\d+) (direct )?damage\.?", re.I)
LOSE_RESOURCES = re.compile(r"^Lose (\d+) resource", re.I)
LOSE_ALL_RESOURCES = re.compile(r"^Lose all of your resources\.?", re.I)
GAIN_RESOURCES = re.compile(r"^Gain (\d+) resource", re.I)
ENTER_THREAT = re.compile(r"^Put .+ into play in your threat area\.?", re.I)
LOSE_ACTION = re.compile(r"^Lose (\d+) actions?\.?$", re.I)
PLACE_DOOM_ON_IT = re.compile(r"^Place (\d+) doom on it\.?$", re.I)
PLACE_DOOM_NEAREST_TO_NAMED = re.compile(
    r"^Place 1 doom on the enemy with no doom on it nearest to .+\.?$",
    re.I,
)
LOSE_OR_ATTACK = re.compile(
    r"^Lose (\d+) resource(?:s)?\. If you cannot, this enemy attacks you\.?$",
    re.I,
)
HEAL_SELF = re.compile(r"^Heal (\d+) (damage|horror)\.?$", re.I)
HEAL_DAMAGE_AND_HORROR = re.compile(
    r"^Heal (\d+) damage and (\d+) horror\.?(?:\s*\(Limit once per game\.?\))?\s*\.?$",
    re.I,
)
DISCARD_SOURCE = re.compile(
    r"^(?:\[action\]:\s*)?Discard ([A-Za-z0-9'!\-]+(?:\s+[A-Za-z0-9'!\-]+){0,4})\.?$",
    re.I,
)
CHOOSE_DISCARD_FROM_HAND = re.compile(
    r"^Choose and discard (\d+) cards? from your hand\.?$",
    re.I,
)
DRAW_CARDS = re.compile(
    r"^(?:\[action\]:\s*)?Draw (\d+) cards?\."
    r"(?:\s*\(Limit once per (?:game|round|phase)\.?\))?\s*$",
    re.I,
)
ATTACH_NEAREST_WITHOUT = re.compile(
    r"^Attach .+ to the nearest location without .+ attached\.?$",
    re.I,
)
ATTACH_YOUR_LOCATION = re.compile(
    r"^Attach .+ to your location(?:\. Limit 1 per location)?\.?$",
    re.I,
)
TEST_SKILL_FAIL_DAMAGE = re.compile(
    r"^Test \[(willpower|intellect|combat|agility)\] \((\d+)\)\. "
    r"If you fail, each investigator at your location takes (\d+) damage\.?$",
    re.I,
)
TEST_SKILL_FAIL_BY_DISCARD_OR_LOSE = re.compile(
    r"^Test \[(willpower|intellect|combat|agility)\] \((\d+)\)\. "
    r"For each point you fail by, you must either "
    r"discard 1 card at random from your hand, or lose 1 resource\.?$",
    re.I,
)
TEST_SKILL_FAIL_BY_ACTION_OR_CLUE = re.compile(
    r"^Test \[(willpower|intellect|combat|agility)\] \((\d+)\)\. "
    r"For each point you fail by, you must either "
    r"lose 1 action or place 1 of your clues on your location\.?$",
    re.I,
)
TEST_SKILL_SUCCEED_DISCARD_SOURCE = re.compile(
    r"^Test \[(willpower|intellect|combat|agility)\] \((\d+)\)\. "
    r"If you succeed, discard .+\.?$",
    re.I,
)
TEST_WP_OR_INT_SUCCEED_DISCARD = re.compile(
    r"^Test \[willpower\] or \[intellect\] \((\d+)\)\. "
    r"If you succeed, discard .+\.?$",
    re.I,
)
TEST_WP_OR_AGI_FAIL_BY = re.compile(
    r"^Test \[willpower\] or \[agility\] \((\d+)\)\. "
    r"Take (\d+) damage for each point you fail by\.?$",
    re.I,
)
EACH_INV_AT_LOCATION_HORROR = re.compile(
    r"^Each investigator at (?:its|your|this|the attached) location "
    r"takes (\d+) (direct )?horror\.?$",
    re.I,
)
EACH_INV_AT_LOCATION_DAMAGE = re.compile(
    r"^Each investigator at (?:its|your|this|the attached) location "
    r"takes (\d+) (direct )?damage\.?$",
    re.I,
)
FIRE_LOCATION_HEALTH_DAMAGE = re.compile(
    r"^Each non-\[\[Elite\]\] card with health at this location "
    r"takes (\d+) direct damage\.?$",
    re.I,
)

# 12126 · If = L3 情景条件（非 timing）；Otherwise = 互斥效果支
FORBIDDEN_SECRETS_IF_ELSE = re.compile(
    r"^If you have no clues, .+ gains surge\.\s*Otherwise,\s*(.+)\.?\s*$",
    re.I | re.S,
)
RAISING_SUSPICIONS = re.compile(
    r"^Place 1 doom on the nearest enemy with no doom on it\.\s*"
    r"If no doom was placed by this effect, .+ gains surge\.?\s*$",
    re.I | re.S,
)
AERIAL_PURSUIT = re.compile(
    r"^The nearest non-\[\[Elite\]\] enemy moves once toward your location\.\s*"
    r"If it engages an investigator, it makes an immediate attack\.?\s*$",
    re.I | re.S,
)
COSMIC_EVILS = re.compile(
    r"^You must either \(choose one\):\s*"
    r"- Place 1 doom on the current agenda\..*?"
    r"- Take 1 direct damage and 1 direct horror\..+ gains surge\.?\s*$",
    re.I | re.S,
)
FORBIDDEN_SECRETS_FAIL_BY = re.compile(
    r"^test \[intellect\] \(3\)\. For each point you fail by, you must either "
    r"place 1 of your clues on your location, or take 1 horror\.?\s*$",
    re.I | re.S,
)

RESIGN_ABILITY = re.compile(r"^Resign\b", re.I)
GROUP_SPEND_CLUES_DEAL_DAMAGE = re.compile(
    r"^Spend (\d+) \[per_investigator\] clues, as a group:\s*"
    r"Deal (\d+) \[per_investigator\] damage to an enemy at your location\.?$",
    re.I,
)

# Agenda Parley：检定成功后弃掉同地点旁人敌人（title/trait Bystander）
PARLEY_TEST_DISCARD_BYSTANDER = re.compile(
    r"^Parley\.\s*Test \[intellect\] \((\d+)\)\.\s*"
    r"If you succeed, discard a (?:\[\[)?Bystander(?:\]\])? enemy at your location\.?$",
    re.I,
)

# Location Engage：选连结地点敌人 → 移至本地点并交战；卡面可显式豁免借机。
# Engage 类型本身会引发借机攻击；仅正文写明「does not provoke…」时才覆盖。
ENGAGE_FROM_CONNECTING = re.compile(
    r"^Engage\.\s*"
    r"Choose an enemy at a connecting location\.\s*"
    r"That enemy moves to this location and engages you\.?"
    r"(?:\s*This action does not provoke attacks? of opportunity\.?)?$",
    re.I,
)
NO_AOO_PHRASE = re.compile(
    r"This action does not provoke attacks? of opportunity\.?",
    re.I,
)

# ArkhamDB Core 玩家牌用 [fast] 标记 Free triggered（闪电图标）；≠ Fast 关键词打出。
FAST_DURING_TURN_EXHAUST_MOVE = re.compile(
    r"^During your turn,\s*exhaust\s+.+?:\s*Move to a connecting location\.?\s*$",
    re.I,
)

# If 子句分类（编译元数据 · 07-composition §3.3）
# 能力多要素：Forced When=timing、if=condition、能拆就拆（OQ-ADB-10）
IF_TIMING_HINTS = re.compile(
    r"\b(during this test|when you draw|after you|before you|at the start of|"
    r"when your turn begins|while .+ test is resolving)\b",
    re.I,
)
IF_REVEAL_TOKEN = re.compile(r"if you reveal a \[", re.I)


def plain_text(raw: str) -> str:
    text = STRIP_HTML.sub("", raw)
    return re.sub(r"\s+", " ", text).strip()


def match_trigger_phrase(trigger: str) -> dict[str, str] | None:
    text = plain_text(trigger).rstrip(".").strip()
    if not text:
        return None
    for pattern, match_kind, phase in TRIGGER_PHRASE_MAP:
        if pattern.match(text):
            return {
                "match_kind": match_kind,
                "phase": phase,
                "timing": f"{phase.lower()}_{match_kind}",
            }
    return None


def split_forced_body(body: str) -> tuple[str, str]:
    if ":" in body:
        trigger, effect = body.split(":", 1)
        return trigger.strip(), effect.strip()
    return "", body.strip()


def classify_if_kind(body: str, segment_kind: str) -> str:
    """Classify leading If: timing | condition | both."""
    if not body.lower().startswith("if "):
        return ""
    if segment_kind in ("reaction", "action", "fast", "forced"):
        trigger, _ = split_forced_body(body) if segment_kind == "forced" else ("", body)
        if trigger:
            return "timing"
    if IF_REVEAL_TOKEN.search(body) and IF_TIMING_HINTS.search(body):
        return "both"
    if IF_TIMING_HINTS.search(body):
        return "timing"
    return "condition"


def segment_abilities(text: str) -> list[dict[str, Any]]:
    if not text:
        return []
    hits: list[tuple[int, dict[str, Any]]] = []
    for match in REVELATION.finditer(text):
        body = plain_text(match.group(1))
        hits.append(
            (
                match.start(),
                {
                    "kind": "revelation",
                    "body": body,
                },
            )
        )
    for match in FORCED.finditer(text):
        raw = match.group(1)
        body = plain_text(raw)
        trigger, effect = split_forced_body(body)
        hits.append(
            (
                match.start(),
                {
                    "kind": "forced",
                    "body": effect if effect else body,
                    "trigger": trigger,
                },
            )
        )
    for match in TRIGGERED.finditer(text):
        kind = match.group(1).lower()
        body = plain_text(match.group(2))
        hits.append(
            (
                match.start(),
                {
                    "kind": kind,
                    "body": body,
                },
            )
        )
    hits.sort(key=lambda item: item[0])
    segments: list[dict[str, Any]] = []
    for index, (_, payload) in enumerate(hits):
        payload["index"] = index
        if_kind = classify_if_kind(str(payload.get("body", "")), str(payload.get("kind", "")))
        if if_kind:
            payload["if_kind"] = if_kind
        segments.append(payload)
    return segments


def compile_forbidden_secrets_fail_by(body: str) -> dict[str, Any] | None:
    if not FORBIDDEN_SECRETS_FAIL_BY.match(body.strip()):
        return None
    return {
        "template": "skill_test",
        "skill": "intellect",
        "difficulty": 3,
        "st7": {
            "on_fail_by_each": {
                "template": "choice_must",
                "prompt_id": "12126:fail_by",
                "options": [
                    {"id": "clue", "template": "place_clue_on_location"},
                    {"id": "horror", "template": "take_horror", "amount": 1},
                ],
            },
        },
    }


def compile_cosmic_evils(body: str) -> dict[str, Any] | None:
    if not COSMIC_EVILS.match(body):
        return None
    return {
        "template": "choice_must",
        "prompt_id": "12124:revelation",
        "options": [
            {"id": "agenda", "template": "place_doom_on_current_agenda", "may_advance_agenda": True},
            {
                "id": "punish",
                "template": "seq",
                "steps": [
                    {"template": "take_damage", "amount": 1, "direct": True},
                    {"template": "take_horror", "amount": 1, "direct": True},
                    {"template": "grant_surge"},
                ],
            },
        ],
    }


def compile_revelation_if_else(body: str) -> dict[str, Any] | None:
    m = FORBIDDEN_SECRETS_IF_ELSE.match(body)
    if not m:
        return None
    else_body = m.group(1).strip()
    else_compiled = compile_forbidden_secrets_fail_by(else_body)
    if else_compiled is None:
        else_compiled = {
            "template": "uncompiled",
            "body": else_body,
            "status": "stub",
        }
    return {
        "template": "if_else",
        "if_kind": "condition",
        "evaluate": "at_entry",
        "condition": "investigator_has_no_clues",
        "then": {"template": "grant_surge"},
        "else": else_compiled,
    }


def compile_aerial_pursuit(body: str) -> dict[str, Any] | None:
    if not AERIAL_PURSUIT.match(body):
        return None
    return {
        "template": "seq",
        "steps": [
            {"template": "resolve_location", "target": "drawer_location"},
            {
                "template": "nest_enemy_move",
                "trait_exclude": ["Elite"],
            },
            {
                "template": "if_else",
                "if_kind": "condition",
                "evaluate": "after_step",
                "condition": "previous_step_engaged_investigator",
                "then": {"template": "nest_enemy_attack"},
            },
        ],
    }


def compile_raising_suspicions(body: str) -> dict[str, Any] | None:
    # 12160 · Seq(place_doom → if_else after_step · 07 §3.3)
    if not RAISING_SUSPICIONS.match(body):
        return None
    return {
        "template": "seq",
        "steps": [
            {"template": "place_doom_nearest_enemy_without_doom"},
            {
                "template": "if_else",
                "if_kind": "condition",
                "evaluate": "after_step",
                "condition": "previous_step_not_created",
                "then": {"template": "grant_surge"},
            },
        ],
    }


def compile_lose_or_attack(body: str) -> dict[str, Any] | None:
    m = LOSE_OR_ATTACK.match(body.strip())
    if not m:
        return None
    return {
        "template": "seq",
        "steps": [
            {"template": "lose_resources", "amount": int(m.group(1))},
            {
                "template": "if_else",
                "if_kind": "condition",
                "evaluate": "after_step",
                "condition": "previous_step_not_created",
                "then": {
                    "template": "nest_enemy_attack",
                    "enemy": "source",
                    "target": "controller",
                },
            },
        ],
    }


def compile_test_wp_or_agi_fail_by(body: str) -> dict[str, Any] | None:
    m = TEST_WP_OR_AGI_FAIL_BY.match(body.strip())
    if not m:
        return None
    difficulty = int(m.group(1))
    amount = int(m.group(2))
    st7 = {
        "on_fail_by_each": {"template": "take_damage", "amount": amount},
    }
    return {
        "template": "choice_must",
        "prompt_id": "skill_test:willpower_or_agility",
        "options": [
            {
                "id": "willpower",
                "template": "skill_test",
                "skill": "willpower",
                "difficulty": difficulty,
                "st7": dict(st7),
            },
            {
                "id": "agility",
                "template": "skill_test",
                "skill": "agility",
                "difficulty": difficulty,
                "st7": {
                    "on_fail_by_each": {"template": "take_damage", "amount": amount},
                },
            },
        ],
    }


def compile_resign(body: str) -> dict[str, Any] | None:
    if not RESIGN_ABILITY.match(body.strip()):
        return None
    return {
        "template": "resign",
        "action_types": ["activate", "resign"],
    }


def compile_group_spend_clues_deal_damage(body: str) -> dict[str, Any] | None:
    m = GROUP_SPEND_CLUES_DEAL_DAMAGE.match(body.strip())
    if not m:
        return None
    spend_n = int(m.group(1))
    dmg_n = int(m.group(2))
    return {
        "template": "seq",
        "steps": [
            {
                "template": "spend_clues_group",
                "amount": spend_n,
                "per_investigator": True,
            },
            {
                "template": "deal_damage",
                "amount": dmg_n,
                "per_investigator": True,
                "target": "enemy_at_controller_location",
            },
        ],
    }


def compile_engage_from_connecting(body: str) -> dict[str, Any] | None:
    text = body.strip()
    if not ENGAGE_FROM_CONNECTING.match(text):
        return None
    entry: dict[str, Any] = {
        "template": "engage_from_connecting",
        "action_types": ["activate", "engage"],
    }
    # Engage 不在借机豁免类型内；仅卡面显式声明时覆盖为 false。
    if NO_AOO_PHRASE.search(text):
        entry["provokes_aoo"] = False
    return entry


def compile_parley_discard_bystander(body: str) -> dict[str, Any] | None:
    m = PARLEY_TEST_DISCARD_BYSTANDER.match(body.strip())
    if not m:
        return None
    return {
        "template": "skill_test",
        "skill": "intellect",
        "difficulty": int(m.group(1)),
        "action_types": ["activate", "parley"],
        "st7": {
            "on_success": {
                "template": "discard_card",
                "trait": "Bystander",
                "at": "controller_location",
                "mode": "choose",
            },
        },
    }


def compile_heal_damage_and_horror(body: str) -> dict[str, Any] | None:
    m = HEAL_DAMAGE_AND_HORROR.match(body.strip())
    if not m:
        return None
    return {
        "template": "seq",
        "steps": [
            {"template": "heal", "kind": "damage", "amount": int(m.group(1))},
            {"template": "heal", "kind": "horror", "amount": int(m.group(2))},
        ],
    }


def compile_discard_source(body: str) -> dict[str, Any] | None:
    m = DISCARD_SOURCE.match(body.strip())
    if not m:
        return None
    name = m.group(1).strip().lower()
    # 排除「弃遭遇牌库顶直至…」等手续句，仅匹配弃置具名来源卡。
    if any(tok in name for tok in ("from the", "until", "cards", "top of")):
        return None
    return {"template": "discard_source"}


def compile_choose_discard_from_hand(body: str) -> dict[str, Any] | None:
    m = CHOOSE_DISCARD_FROM_HAND.match(body.strip())
    if not m:
        return None
    return {
        "template": "discard_from_hand",
        "amount": int(m.group(1)),
        "mode": "choose",
    }


def compile_draw_cards(body: str) -> dict[str, Any] | None:
    m = DRAW_CARDS.match(body.strip())
    if not m:
        return None
    return {
        "template": "draw",
        "amount": int(m.group(1)),
    }


def compile_attach(body: str) -> dict[str, Any] | None:
    text = body.strip()
    if ATTACH_NEAREST_WITHOUT.match(text):
        return {"template": "attach_nearest_without_same"}
    if ATTACH_YOUR_LOCATION.match(text):
        return {"template": "attach_controller_location"}
    # 显现段常附带 lasting / 附加句；只译首句 Attach（其余标 partial）
    if text.lower().startswith("attach "):
        parts = [p.strip() for p in text.split(".") if p.strip()]
        for end in range(1, min(len(parts), 2) + 1):
            prefix = ". ".join(parts[:end]) + "."
            if ATTACH_NEAREST_WITHOUT.match(prefix):
                return {"template": "attach_nearest_without_same"}
            if ATTACH_YOUR_LOCATION.match(prefix):
                return {"template": "attach_controller_location"}
    return None


def compile_test_wp_or_int_succeed_discard(body: str) -> dict[str, Any] | None:
    m = TEST_WP_OR_INT_SUCCEED_DISCARD.match(body.strip())
    if not m:
        return None
    difficulty = int(m.group(1))
    st7 = {"on_success": {"template": "discard_source"}}
    return {
        "template": "choice_must",
        "prompt_id": "skill_test:willpower_or_intellect",
        "options": [
            {
                "id": "willpower",
                "template": "skill_test",
                "skill": "willpower",
                "difficulty": difficulty,
                "st7": dict(st7),
            },
            {
                "id": "intellect",
                "template": "skill_test",
                "skill": "intellect",
                "difficulty": difficulty,
                "st7": {"on_success": {"template": "discard_source"}},
            },
        ],
    }


def compile_each_investigator_at_location(body: str) -> dict[str, Any] | None:
    text = body.strip()
    m = EACH_INV_AT_LOCATION_HORROR.match(text)
    if m:
        return {
            "template": "take_horror",
            "amount": int(m.group(1)),
            "direct": bool(m.group(2)),
            "target": "each_at_source_location",
        }
    m = EACH_INV_AT_LOCATION_DAMAGE.match(text)
    if m:
        return {
            "template": "take_damage",
            "amount": int(m.group(1)),
            "direct": bool(m.group(2)),
            "target": "each_at_source_location",
        }
    return None


def compile_fire_location_health_damage(body: str) -> dict[str, Any] | None:
    m = FIRE_LOCATION_HEALTH_DAMAGE.match(body.strip())
    if not m:
        return None
    return {
        "template": "deal_damage",
        "amount": int(m.group(1)),
        "direct": True,
        "target": "non_elite_with_health_at_attached_location",
    }


def compile_test_skill_fail_damage(body: str) -> dict[str, Any] | None:
    m = TEST_SKILL_FAIL_DAMAGE.match(body.strip())
    if not m:
        return None
    return {
        "template": "skill_test",
        "skill": m.group(1).lower(),
        "difficulty": int(m.group(2)),
        "st7": {
            "on_fail": {
                "template": "deal_damage",
                "amount": int(m.group(3)),
                "target": "each_at_controller_location",
            },
        },
    }


def compile_test_fail_by_discard_or_lose(body: str) -> dict[str, Any] | None:
    m = TEST_SKILL_FAIL_BY_DISCARD_OR_LOSE.match(body.strip())
    if not m:
        return None
    return {
        "template": "skill_test",
        "skill": m.group(1).lower(),
        "difficulty": int(m.group(2)),
        "st7": {
            "on_fail_by_each": {
                "template": "choice_must",
                "prompt_id": "fail_by:discard_or_lose_resource",
                "options": [
                    {
                        "id": "discard",
                        "template": "discard_from_hand",
                        "amount": 1,
                        "mode": "random",
                    },
                    {"id": "resource", "template": "lose_resources", "amount": 1},
                ],
            },
        },
    }


def compile_test_fail_by_action_or_clue(body: str) -> dict[str, Any] | None:
    m = TEST_SKILL_FAIL_BY_ACTION_OR_CLUE.match(body.strip())
    if not m:
        return None
    return {
        "template": "skill_test",
        "skill": m.group(1).lower(),
        "difficulty": int(m.group(2)),
        "st7": {
            "on_fail_by_each": {
                "template": "choice_must",
                "prompt_id": "fail_by:lose_action_or_clue",
                "options": [
                    {"id": "action", "template": "lose_action", "amount": 1},
                    {"id": "clue", "template": "place_clue_on_location"},
                ],
            },
        },
    }


def compile_test_succeed_discard_source(body: str) -> dict[str, Any] | None:
    m = TEST_SKILL_SUCCEED_DISCARD_SOURCE.match(body.strip())
    if not m:
        return None
    return {
        "template": "skill_test",
        "skill": m.group(1).lower(),
        "difficulty": int(m.group(2)),
        "st7": {"on_success": {"template": "discard_source"}},
    }


def compile_effect_body(body: str) -> dict[str, Any] | None:
    if not body:
        return None
    cosmic = compile_cosmic_evils(body)
    if cosmic is not None:
        return cosmic
    revelation_branch = compile_revelation_if_else(body)
    if revelation_branch is not None:
        return revelation_branch
    raising = compile_raising_suspicions(body)
    if raising is not None:
        return raising
    aerial = compile_aerial_pursuit(body)
    if aerial is not None:
        return aerial
    lose_or_attack = compile_lose_or_attack(body)
    if lose_or_attack is not None:
        return lose_or_attack
    each_loc = compile_each_investigator_at_location(body)
    if each_loc is not None:
        return each_loc
    fire_dmg = compile_fire_location_health_damage(body)
    if fire_dmg is not None:
        return fire_dmg
    skill_choice = compile_test_wp_or_agi_fail_by(body)
    if skill_choice is not None:
        return skill_choice
    wp_or_int = compile_test_wp_or_int_succeed_discard(body)
    if wp_or_int is not None:
        return wp_or_int
    fail_dmg = compile_test_skill_fail_damage(body)
    if fail_dmg is not None:
        return fail_dmg
    fail_by_disc = compile_test_fail_by_discard_or_lose(body)
    if fail_by_disc is not None:
        return fail_by_disc
    fail_by_act = compile_test_fail_by_action_or_clue(body)
    if fail_by_act is not None:
        return fail_by_act
    succeed_disc = compile_test_succeed_discard_source(body)
    if succeed_disc is not None:
        return succeed_disc
    parley = compile_parley_discard_bystander(body)
    if parley is not None:
        return parley
    engage_conn = compile_engage_from_connecting(body)
    if engage_conn is not None:
        return engage_conn
    resign = compile_resign(body)
    if resign is not None:
        return resign
    group_clues = compile_group_spend_clues_deal_damage(body)
    if group_clues is not None:
        return group_clues
    attach = compile_attach(body)
    if attach is not None:
        return attach
    discard_src = compile_discard_source(body)
    if discard_src is not None:
        return discard_src
    discard_hand = compile_choose_discard_from_hand(body)
    if discard_hand is not None:
        return discard_hand
    draw_cards = compile_draw_cards(body)
    if draw_cards is not None:
        return draw_cards
    heal_both = compile_heal_damage_and_horror(body)
    if heal_both is not None:
        return heal_both
    m = HEAL_SELF.match(body.strip())
    if m:
        return {
            "template": "heal",
            "kind": m.group(2).lower(),
            "amount": int(m.group(1)),
        }
    m = PLACE_DOOM_ON_IT.match(body.strip())
    if m:
        return {"template": "place_doom_on_source", "amount": int(m.group(1))}
    if PLACE_DOOM_NEAREST_TO_NAMED.match(body.strip()):
        return {"template": "place_doom_nearest_to_source", "amount": 1}
    m = LOSE_ACTION.match(body.strip())
    if m:
        return {"template": "lose_action", "amount": int(m.group(1))}
    if LOSE_ALL_RESOURCES.match(body):
        return {"template": "lose_all_resources"}
    m = LOSE_RESOURCES.match(body)
    if m:
        return {"template": "lose_resources", "amount": int(m.group(1))}
    m = GAIN_RESOURCES.match(body)
    if m:
        return {"template": "gain_resources", "amount": int(m.group(1))}
    m = TAKE_HORROR.match(body)
    if m:
        return {
            "template": "take_horror",
            "amount": int(m.group(1)),
            "direct": bool(m.group(2)),
        }
    m = TAKE_DAMAGE.match(body)
    if m:
        return {
            "template": "take_damage",
            "amount": int(m.group(1)),
            "direct": bool(m.group(2)),
        }
    if ENTER_THREAT.match(body):
        return {"template": "enter_threat_area"}
    if LEAD_DRAW_FIRE.match(body):
        return {
            "template": "lead_draw_topmost_encounter_discard_copy",
            "definition_id": "12129",
        }
    return None


def compile_fast_segment(segment: dict[str, Any]) -> dict[str, Any] | None:
    """Compile ArkhamDB [fast] segment as Free triggered ability（免费触发能力）."""
    body = str(segment.get("body", "")).strip()
    if FAST_DURING_TURN_EXHAUST_MOVE.match(body):
        return {
            "segment_index": segment["index"],
            "register_as": "free",
            "ability_id": f"free:{segment['index']}",
            "ability_kind": "free",
            "window": "during_your_turn",
            "status": "full",
            "template": "seq",
            "steps": [
                {"template": "exhaust_source"},
                {"template": "nest_move_connecting"},
            ],
        }
    group_clues = compile_group_spend_clues_deal_damage(body)
    if group_clues is not None:
        return {
            "segment_index": segment["index"],
            "register_as": "free",
            "ability_id": f"free:{segment['index']}",
            "ability_kind": "free",
            "window": "during_your_turn",
            # 群体线索分配交互后补；先落地效果骨架。
            "status": "partial",
            **group_clues,
        }
    return None


def compile_action_segment(segment: dict[str, Any]) -> dict[str, Any] | None:
    """Compile [action] segment as Action ability（行动能力）."""
    body = str(segment.get("body", "")).strip()
    compiled = compile_effect_body(body)
    if compiled is None:
        return None
    # 弱点自弃常为 [action][action]；分段后 body 可能只剩 Discard …
    action_cost = 2 if compiled.get("template") == "discard_source" else 1
    if body.lower().startswith("[action]"):
        action_cost = 2
    action_types = compiled.pop("action_types", ["activate"])
    if not isinstance(action_types, list) or not action_types:
        action_types = ["activate"]
    status = "full"
    if compiled.get("template") in ("if_else", "seq", "choice_must"):
        status = "partial"
    elif compiled.get("template") == "skill_test" and "parley" not in [
        str(t).lower() for t in action_types
    ]:
        status = "partial"
    elif "(limit" in body.lower():
        status = "partial"
    # Resign / Engage-from-connecting 效果体为单 atom，视为 full。
    if compiled.get("template") in ("resign", "engage_from_connecting"):
        status = "full"
    entry: dict[str, Any] = {
        "segment_index": segment["index"],
        "register_as": "action",
        "ability_id": f"action:{segment['index']}",
        "ability_kind": "action",
        "window": "during_your_turn",
        "action_cost": action_cost,
        "action_types": action_types,
        "status": status,
        **compiled,
    }
    return entry


def compile_segment(segment: dict[str, Any]) -> dict[str, Any] | None:
    kind = segment.get("kind", "")
    body = str(segment.get("body", ""))
    if kind == "revelation":
        compiled = compile_effect_body(body)
        if compiled is None and body.lower().startswith("take "):
            compiled = compile_effect_body(body.split(".")[0] + ".")
        if compiled is None:
            return None
        status = "full"
        if compiled.get("template") in ("if_else", "seq", "choice_must", "skill_test"):
            status = "partial"
        elif plain_text(body) != _template_body_preview(compiled):
            status = "partial"
        entry: dict[str, Any] = {
            "segment_index": segment["index"],
            "register_as": "revelation",
            "ability_id": f"revelation:{segment['index']}",
            "status": status,
            **compiled,
        }
        if segment.get("if_kind"):
            entry["if_kind"] = segment["if_kind"]
        return entry
    if kind == "forced":
        effect = compile_effect_body(body)
        if effect is None:
            return None
        entry = {
            "segment_index": segment["index"],
            "register_as": "forced",
            "ability_id": f"forced:{segment['index']}",
            "ability_kind": "forced",
            "status": "effect_only",
            "trigger": segment.get("trigger", ""),
            **effect,
        }
        timing = match_trigger_phrase(str(segment.get("trigger", "")))
        if timing is not None:
            entry.update(timing)
            entry["status"] = "full"
        if segment.get("if_kind"):
            entry["if_kind"] = segment["if_kind"]
        return entry
    if kind == "fast":
        return compile_fast_segment(segment)
    if kind == "action":
        return compile_action_segment(segment)
    if kind == "reaction":
        return compile_reaction_segment(segment)
    return None


def compile_reaction_segment(segment: dict[str, Any]) -> dict[str, Any] | None:
    """Compile [reaction] as Reaction triggered ability（反应触发能力）."""
    body = str(segment.get("body", "")).strip()
    trigger, effect = split_forced_body(body)
    compiled = compile_effect_body(effect if effect else body)
    if compiled is None:
        return None
    entry: dict[str, Any] = {
        "segment_index": segment["index"],
        "register_as": "reaction",
        "ability_id": f"reaction:{segment['index']}",
        "ability_kind": "reaction",
        "status": "effect_only",
        "trigger": trigger,
        **compiled,
    }
    timing = match_trigger_phrase(trigger)
    if timing is not None:
        entry.update(timing)
        entry["status"] = "full"
    if "(limit" in body.lower():
        entry["status"] = "partial"
    if segment.get("if_kind"):
        entry["if_kind"] = segment["if_kind"]
    return entry


def _template_body_preview(compiled: dict[str, Any]) -> str:
    template = compiled.get("template", "")
    amount = compiled.get("amount", 0)
    direct = "direct " if compiled.get("direct") else ""
    if template == "take_horror":
        return f"Take {amount} {direct}horror.".replace("  ", " ")
    if template == "take_damage":
        return f"Take {amount} {direct}damage.".replace("  ", " ")
    if template == "lose_resources":
        return f"Lose {amount} resource."
    if template == "gain_resources":
        return f"Gain {amount} resource."
    if template == "lose_all_resources":
        return "Lose all of your resources."
    if template == "lose_action":
        return f"Lose {amount} action." if amount == 1 else f"Lose {amount} actions."
    if template == "heal":
        kind = compiled.get("kind", "damage")
        return f"Heal {amount} {kind}."
    if template == "place_doom_on_source":
        return f"Place {compiled.get('amount', 1)} doom on it."
    if template == "place_doom_nearest_to_source":
        return "Place 1 doom on the enemy with no doom on it nearest to …"
    if template == "enter_threat_area":
        return "Put … into play in your threat area."
    if template == "discard_source":
        return "Discard …"
    if template == "discard_from_hand":
        mode = str(compiled.get("mode", "random")).lower()
        n = int(compiled.get("amount", 1))
        card_word = "card" if n == 1 else "cards"
        if mode == "choose":
            return f"Choose and discard {n} {card_word} from your hand."
        return f"Discard {n} {card_word} at random from your hand."
    if template == "draw":
        n = int(compiled.get("amount", 1))
        return f"Draw {n} card." if n == 1 else f"Draw {n} cards."
    if template == "attach_nearest_without_same":
        return "Attach … to the nearest location without … attached."
    if template == "attach_controller_location":
        return "Attach … to your location."
    if template == "deal_damage":
        return f"Deal {amount} damage."
    if template == "skill_test":
        return "Test …"
    if template == "lead_draw_topmost_encounter_discard_copy":
        return (
            "The lead investigator draws the topmost copy of Fire! "
            "in the encounter discard pile."
        )
    if template == "if_else":
        return "If you have no clues, … gains surge."
    if template == "seq":
        steps = compiled.get("steps", [])
        if steps:
            first = steps[0]
            if first.get("template") == "resolve_location":
                return (
                    "The nearest non-[[Elite]] enemy moves once toward your location. "
                    "If it engages an investigator, it makes an immediate attack."
                )
            if first.get("template") == "lose_resources":
                return "Lose 1 resource. If you cannot, this enemy attacks you."
            if first.get("template") == "heal":
                return "Heal 1 damage and 1 horror."
            if (
                len(steps) >= 2
                and first.get("template") == "exhaust_source"
                and steps[1].get("template") == "nest_move_connecting"
            ):
                return "During your turn, exhaust …: Move to a connecting location."
        return "Place 1 doom on the nearest enemy…"
    if template == "choice_must":
        prompt = str(compiled.get("prompt_id", ""))
        if prompt == "skill_test:willpower_or_agility":
            return (
                "Test [willpower] or [agility] (3). "
                "Take 1 damage for each point you fail by."
            )
        return "You must either (choose one)…"
    return ""


def compile_card_abilities(text: str) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    segments = segment_abilities(text)
    compiled: list[dict[str, Any]] = []
    for segment in segments:
        entry = compile_segment(segment)
        if entry is not None:
            compiled.append(entry)
    return segments, compiled


def summarize_compile(all_cards: dict[str, Any]) -> dict[str, Any]:
    segment_total = 0
    compiled_total = 0
    by_kind: dict[str, int] = {}
    by_template: dict[str, int] = {}
    for key, card in all_cards.items():
        if key.startswith("_") or not isinstance(card, dict):
            continue
        for seg in card.get("ability_segments", []):
            segment_total += 1
            by_kind[seg.get("kind", "unknown")] = by_kind.get(seg.get("kind", "unknown"), 0) + 1
        for comp in card.get("compiled_abilities", []):
            compiled_total += 1
            tpl = comp.get("template", "unknown")
            by_template[tpl] = by_template.get(tpl, 0) + 1
    return {
        "segment_total": segment_total,
        "compiled_total": compiled_total,
        "by_kind": by_kind,
        "by_template": by_template,
    }
