"""Segment and template-compile ArkhamDB card ability text."""

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

TAKE_HORROR = re.compile(r"^Take (\d+) (direct )?horror\.?", re.I)
TAKE_DAMAGE = re.compile(r"^Take (\d+) (direct )?damage\.?", re.I)
LOSE_RESOURCES = re.compile(r"^Lose (\d+) resource", re.I)
LOSE_ALL_RESOURCES = re.compile(r"^Lose all of your resources\.?", re.I)
ENTER_THREAT = re.compile(r"^Put .+ into play in your threat area\.?", re.I)


def plain_text(raw: str) -> str:
    text = STRIP_HTML.sub("", raw)
    return re.sub(r"\s+", " ", text).strip()


def split_forced_body(body: str) -> tuple[str, str]:
    if ":" in body:
        trigger, effect = body.split(":", 1)
        return trigger.strip(), effect.strip()
    return "", body.strip()


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
        segments.append(payload)
    return segments


def compile_effect_body(body: str) -> dict[str, Any] | None:
    if not body:
        return None
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
        status = "full" if plain_text(body) == _template_body_preview(compiled) else "partial"
        return {
            "segment_index": segment["index"],
            "register_as": "revelation",
            "ability_id": f"revelation:{segment['index']}",
            "status": status,
            **compiled,
        }
    if kind == "forced":
        effect = compile_effect_body(body)
        if effect is None:
            return None
        return {
            "segment_index": segment["index"],
            "register_as": "forced",
            "ability_id": f"forced:{segment['index']}",
            "status": "effect_only",
            "trigger": segment.get("trigger", ""),
            **effect,
        }
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
