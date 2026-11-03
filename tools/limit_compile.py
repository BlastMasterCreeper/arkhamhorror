"""Compile ArkhamDB Limit / Max clauses to LimitSpec JSON dicts (06d).

Mirrors rules/limits/limit_spec.gd try_parse_paren_clause. Dicts hydrate via
LimitSpec.from_dict in GDScript.
"""

from __future__ import annotations

import re
from typing import Any

STRIP_HTML = re.compile(r"<[^>]+>")

# Find candidate clauses in free text (paren or standalone).
CLAUSE_FINDER = re.compile(
    r"(?:"
    r"\((?:Group\s+)?[Ll]imit[^)]+\)"
    r"|\(max\s+\d+\s+cards?\s+beneath[^)]*\)"
    r"|Max\s+\d+\s+committed\s+per\s+(?:skill\s+)?test\.?"
    r"|Max\s+\d+\s+\[\[[^\]]+\]\]\s+per\s+(?:turn|round|phase|game)\.?"
    r"|Max\s+\d+\s+per\s+(?:turn|round|phase|game|attack|investigation)\.?"
    r"|Limit\s+\d+\s+\[\[[^\]]+\]\]\s+in\s+play\.?"
    r"|Limit\s+\d+\s+(?:\[\[[^\]]+\]\]\s+)?per\s+(?:investigator|location|deck|asset|enemy|agenda/act)\.?"
    r")",
    re.I,
)

CARD_LEVEL_KINDS = frozenset({"ZONE_OCCUPANCY", "DECKBUILDING", "COMMIT_MAX"})
ABILITY_LEVEL_KINDS = frozenset(
    {"INITIATE_QUOTA", "USE_QUOTA", "EVENT_QUOTA"}
)


def plain_text(raw: str) -> str:
    text = STRIP_HTML.sub("", raw or "")
    return re.sub(r"\s+", " ", text).strip()


def _spec(
    *,
    kind: str,
    amount: int = 1,
    period: str = "NONE",
    audience: str = "PLAYER",
    zone: str = "NONE",
    match: str = "BY_TITLE",
    trait_name: str = "",
    card_type: str = "",
    event_key: str = "",
    title_key: str = "",
    limit_id: str = "",
) -> dict[str, Any]:
    out: dict[str, Any] = {
        "id": limit_id,
        "kind": kind,
        "amount": amount,
        "period": period,
        "audience": audience,
        "zone": zone,
        "match": match,
        "trait_name": trait_name,
        "card_type": card_type,
        "event_key": event_key,
        "title_key": title_key,
    }
    return out


def _period_from_word(raw: str) -> str:
    return {
        "turn": "TURN",
        "round": "ROUND",
        "phase": "PHASE",
        "game": "GAME",
        "attack": "ATTACK",
        "investigation": "INVESTIGATION",
    }.get(raw.lower(), "NONE")


def _parse_count_word(raw: str) -> int:
    key = raw.lower()
    if key in ("once", "one"):
        return 1
    if key in ("twice", "two"):
        return 2
    if key in ("thrice", "three"):
        return 3
    try:
        return max(int(raw), 1)
    except ValueError:
        return 1


def try_parse_clause(text: str) -> dict[str, Any] | None:
    """Parse one Limit/Max clause; unknown → None. Same surface as GDScript."""
    t = plain_text(text).strip()
    if not t:
        return None

    m = re.match(
        r"(?i)^Max\s+(\d+)\s+committed\s+per\s+(?:skill\s+)?test\.?$", t
    )
    if m:
        return _spec(
            kind="COMMIT_MAX",
            amount=int(m.group(1)),
            period="SKILL_TEST",
            audience="TITLE",
            limit_id="max_committed",
        )

    m = re.match(
        r"(?i)^\(\s*Limit\s+(\d+)\s+resources\s+per\s+round\s*\.??\)$", t
    )
    if m:
        return _spec(
            kind="EVENT_QUOTA",
            amount=int(m.group(1)),
            period="ROUND",
            event_key="resource_gain",
            limit_id="resources_per_round",
        )

    m = re.match(
        r"(?i)^\(\s*(Group\s+)?[Ll]imit\s+(\d+|once)\s+success(?:es)?\s+per\s+game\s*\.??\)$",
        t,
    )
    if m:
        group = bool(m.group(1) and m.group(1).strip())
        amt_s = m.group(2).lower()
        amt = 1 if amt_s == "once" else int(amt_s)
        return _spec(
            kind="EVENT_QUOTA",
            amount=amt,
            period="GAME",
            audience="GROUP" if group else "PLAYER",
            event_key="success",
            limit_id="group_success_per_game" if group else "success_per_game",
        )

    m = re.match(
        r"(?i)^\(\s*Limit\s+(once|twice|thrice|one|two|three|\d+)\s+"
        r"(?:times\s+)?per\s+(attack|investigation)\s*\.??\)$",
        t,
    )
    if m:
        amt = _parse_count_word(m.group(1))
        scope = m.group(2).lower()
        period = "ATTACK" if scope == "attack" else "INVESTIGATION"
        return _spec(
            kind="USE_QUOTA",
            amount=amt,
            period=period,
            limit_id="per_attack" if period == "ATTACK" else "per_investigation",
        )

    m = re.match(
        r"(?i)^\(\s*Limit\s+once\s+for\s+each\s+investigator\s+per\s+"
        r"(turn|round|phase|game)\s*\.??\)$",
        t,
    )
    if m:
        return _spec(
            kind="INITIATE_QUOTA",
            amount=1,
            period=_period_from_word(m.group(1)),
            audience="PER_TARGET_INVESTIGATOR",
            limit_id="per_target_investigator",
        )

    m = re.match(
        r"(?i)^\(\s*Limit\s+once\s+per\s+(turn|round|phase|game)\s+for\s+each\s+"
        r"(?:vehicle|asset)\s*\.??\)$",
        t,
    )
    if m:
        return _spec(
            kind="INITIATE_QUOTA",
            amount=1,
            period=_period_from_word(m.group(1)),
            audience="PER_ASSET_INSTANCE",
            limit_id="per_asset_instance",
        )

    m = re.match(
        r"(?i)^\(\s*Limit\s+(\d+)\s+attached\s+"
        r"(asset|event|skill|enemy|treachery|cards?)\s*\.??\)$",
        t,
    )
    if m:
        ct = m.group(2).lower()
        if ct.startswith("card"):
            return _spec(
                kind="ZONE_OCCUPANCY",
                amount=int(m.group(1)),
                zone="ATTACHED",
                match="ANY",
                limit_id="attached",
            )
        return _spec(
            kind="ZONE_OCCUPANCY",
            amount=int(m.group(1)),
            zone="ATTACHED",
            match="BY_CARD_TYPE",
            card_type=ct,
            limit_id="attached",
        )

    m = re.match(
        r"(?i)^\(?\s*max\s+(\d+)\s+cards?\s+beneath(?:\s+\w+)?\s*\.?\s*\)?$", t
    )
    if m:
        return _spec(
            kind="ZONE_OCCUPANCY",
            amount=int(m.group(1)),
            zone="BENEATH",
            match="ANY",
            limit_id="beneath",
        )

    m = re.match(
        r"(?i)^Max\s+(\d+)\s+\[\[([^\]]+)\]\]\s+per\s+(turn|round|phase|game)\.?$",
        t,
    )
    if m:
        return _spec(
            kind="INITIATE_QUOTA",
            amount=int(m.group(1)),
            period=_period_from_word(m.group(3)),
            audience="TITLE",
            title_key=m.group(2).strip(),
            limit_id="max_trait_period",
        )

    m = re.match(
        r"(?i)^Max\s+(\d+)\s+per\s+(turn|round|phase|game|attack|investigation)\.?$",
        t,
    )
    if m:
        return _spec(
            kind="INITIATE_QUOTA",
            amount=int(m.group(1)),
            period=_period_from_word(m.group(2)),
            audience="TITLE",
            limit_id="max_title",
        )

    m = re.match(
        r"(?i)^Limit\s+(\d+)\s+(?:\[\[([^\]]+)\]\]|(.+?))\s+in\s+play\.?$", t
    )
    if m:
        trait = (m.group(2) or "").strip()
        if trait:
            return _spec(
                kind="ZONE_OCCUPANCY",
                amount=int(m.group(1)),
                zone="IN_PLAY",
                match="BY_TRAIT",
                trait_name=trait,
                limit_id="in_play",
            )
        return _spec(
            kind="ZONE_OCCUPANCY",
            amount=int(m.group(1)),
            zone="IN_PLAY",
            limit_id="in_play",
        )

    m = re.match(
        r"(?i)^Limit\s+(\d+)\s+(?:\[\[([^\]]+)\]\]\s+)?"
        r"per\s+(investigator|location|deck|asset|enemy|agenda/act)\.?$",
        t,
    )
    if m:
        n = int(m.group(1))
        trait = (m.group(2) or "").strip()
        where = m.group(3).lower()
        if where == "deck":
            return _spec(
                kind="DECKBUILDING",
                amount=n,
                zone="PER_DECK",
                match="BY_TRAIT" if trait else "BY_TITLE",
                trait_name=trait,
                limit_id="per_deck",
            )
        zone_map = {
            "investigator": "PER_INVESTIGATOR",
            "location": "PER_LOCATION",
            "asset": "PER_ASSET",
            "enemy": "PER_ENEMY",
            "agenda/act": "PER_AGENDA_ACT",
        }
        return _spec(
            kind="ZONE_OCCUPANCY",
            amount=n,
            zone=zone_map[where],
            match="BY_TRAIT" if trait else "BY_TITLE",
            trait_name=trait,
            limit_id=f"per_{where.replace('/', '_')}",
        )

    m = re.match(
        r"(?i)^\(\s*(Group\s+)?limit\s+(once|\d+)\s+per\s+(turn|round|phase|game)\s*\.??\)$",
        t,
    )
    if m:
        group = bool(m.group(1) and m.group(1).strip())
        once_or_n = m.group(2).lower()
        period_s = m.group(3).lower()
        amount = 1 if once_or_n == "once" else int(once_or_n)
        period = _period_from_word(period_s)
        lid = f"per_{period_s}"
        if group:
            lid = f"group_{lid}"
        return _spec(
            kind="INITIATE_QUOTA",
            amount=amount,
            period=period,
            audience="GROUP" if group else "PLAYER",
            limit_id=lid,
        )

    return None


def extract_clauses(text: str) -> list[dict[str, Any]]:
    """Find and parse all Limit/Max clauses in text; dedupe by stable key."""
    body = plain_text(text)
    if not body:
        return []
    seen: set[str] = set()
    out: list[dict[str, Any]] = []
    for match in CLAUSE_FINDER.finditer(body):
        clause = match.group(0).strip()
        spec = try_parse_clause(clause)
        if spec is None:
            continue
        key = (
            f"{spec['kind']}|{spec['id']}|{spec['amount']}|{spec['period']}|"
            f"{spec['audience']}|{spec['zone']}|{spec['trait_name']}|"
            f"{spec['card_type']}|{spec['event_key']}|{spec['title_key']}"
        )
        if key in seen:
            continue
        seen.add(key)
        out.append(spec)
    return out


def split_card_and_ability_limits(
    specs: list[dict[str, Any]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    card: list[dict[str, Any]] = []
    ability: list[dict[str, Any]] = []
    for spec in specs:
        kind = str(spec.get("kind", ""))
        if kind in CARD_LEVEL_KINDS:
            card.append(spec)
        elif kind in ABILITY_LEVEL_KINDS:
            ability.append(spec)
    return card, ability


def attach_limits_to_compiled(
    entry: dict[str, Any], body: str
) -> dict[str, Any]:
    """Attach ability-level limits parsed from segment body."""
    specs = extract_clauses(body)
    _card, ability = split_card_and_ability_limits(specs)
    if not ability:
        return entry
    existing = entry.get("limits")
    merged: list[dict[str, Any]] = list(existing) if isinstance(existing, list) else []
    for spec in ability:
        if spec not in merged:
            merged.append(spec)
    entry["limits"] = merged
    return entry


def collect_card_limits(text: str) -> list[dict[str, Any]]:
    """Card-level limits from full face text (occupancy / commit / deckbuilding)."""
    specs = extract_clauses(text)
    card, _ability = split_card_and_ability_limits(specs)
    return card
