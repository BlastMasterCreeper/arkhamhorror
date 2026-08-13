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
ENTER_THREAT = re.compile(r"^Put .+ into play in your threat area\.?", re.I)

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
    if LOSE_ALL_RESOURCES.match(body):
        return {"template": "lose_all_resources"}
    m = LOSE_RESOURCES.match(body)
    if m:
        return {"template": "lose_resources", "amount": int(m.group(1))}
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
    return None


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
        if compiled.get("template") in ("if_else", "seq", "choice_must"):
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
    return None


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
    if template == "lose_all_resources":
        return "Lose all of your resources."
    if template == "enter_threat_area":
        return "Put … into play in your threat area."
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
            if (
                len(steps) >= 2
                and first.get("template") == "exhaust_source"
                and steps[1].get("template") == "nest_move_connecting"
            ):
                return "During your turn, exhaust …: Move to a connecting location."
        return "Place 1 doom on the nearest enemy…"
    if template == "choice_must":
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
