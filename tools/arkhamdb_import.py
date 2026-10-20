#!/usr/bin/env python3
"""Import ArkhamDB pack JSON into engine-normalized definition files."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

from arkhamdb_abilities import compile_card_abilities, summarize_compile

ROOT = Path(__file__).resolve().parents[1]
PACK_DIR = ROOT / "data" / "arkhamdb" / "pack"
OUT_DIR = ROOT / "data" / "arkhamdb" / "imported"

COST_SENTINEL = {
    None: "dash",
    -2: "x",
    -3: "star",
    -4: "question",
}

WEAKNESS_SUBTYPES = {"weakness", "basicweakness"}

KEYWORD_LINE_PATTERNS = [
    ("surge", re.compile(r"\bSurge\b", re.I)),
    ("peril", re.compile(r"\bPeril\b", re.I)),
    ("aloof", re.compile(r"\bAloof\b", re.I)),
    ("hunter", re.compile(r"\bHunter\b", re.I)),
    ("retaliate", re.compile(r"\bRetaliate\b", re.I)),
    ("massive", re.compile(r"\bMassive\b", re.I)),
    ("hidden", re.compile(r"\bHidden\b", re.I)),
]

ABILITY_HINT_PATTERNS = [
    ("reaction", re.compile(r"\[reaction\]", re.I)),
    ("action", re.compile(r"\[action\]", re.I)),
    ("fast", re.compile(r"\[fast\]", re.I)),
    ("elder_sign", re.compile(r"\[elder_sign\]", re.I)),
    ("revelation", re.compile(r"<b>Revelation</b>", re.I)),
    ("forced", re.compile(r"<b>Forced</b>", re.I)),
]

SKILL_FIELDS = [
    ("skill_willpower", "willpower"),
    ("skill_intellect", "intellect"),
    ("skill_combat", "combat"),
    ("skill_agility", "agility"),
    ("skill_wild", "wild"),
]


def decode_cost(value: Any) -> tuple[int, str]:
    if value in COST_SENTINEL:
        return 0, COST_SENTINEL[value]
    if isinstance(value, int) and value >= 0:
        return value, "none"
    return 0, "none"


def card_text(card: dict[str, Any]) -> str:
    parts = [card.get("text") or "", card.get("back_text") or ""]
    return "\n".join(p for p in parts if p)


def parse_traits(raw: str | None) -> list[str]:
    if not raw:
        return []
    out: list[str] = []
    for part in re.split(r"[.\n]+", raw):
        t = part.strip()
        if t:
            out.append(t)
    return out


def extract_keywords(card: dict[str, Any], text: str) -> list[str]:
    """关键词来自卡面文本行；`permanent` 可用 JSON 字段。

    ArkhamDB JSON 的 `hidden: true` **不是** 隐私（Hidden）关键词——常表示
    linked/b 面不单独进遭遇库列表（如 01121b / 12179b）。隐私只认文本 `Hidden`。

    关键词常在 Spawn/Prey 行之后单独成行（如 01121b 的 `Hunter.`），故扫前若干行。
    """
    keywords: list[str] = []
    if card.get("permanent"):
        keywords.append("permanent")
    lines = [ln.strip() for ln in (text or "").split("\n") if ln.strip()]
    for line in lines[:8]:
        # 能力体开始后不再当关键词行（避免 Flavor/规则句误伤）
        if re.match(r"^(Forced|Revelation|\[action\]|\[reaction\]|\[fast\])", line, re.I):
            break
        if re.match(r"^While\b", line, re.I):
            break
        for name, pat in KEYWORD_LINE_PATTERNS:
            if pat.search(line) and name not in keywords:
                keywords.append(name)
    return keywords


def extract_ability_hints(text: str) -> list[str]:
    hints: list[str] = []
    for name, pat in ABILITY_HINT_PATTERNS:
        if pat.search(text):
            hints.append(name)
    return hints


def skills_icons(card: dict[str, Any]) -> dict[str, int]:
    icons: dict[str, int] = {}
    for field, key in SKILL_FIELDS:
        val = card.get(field)
        if isinstance(val, int) and val > 0:
            icons[key] = val
    return icons


def _health_bonus_per_investigator(text: str) -> int:
    """卡面「gets +N health per investigator」（非印刷 [per_investigator] 图标）。"""
    match = re.search(
        r"gets?\s*\+(\d+)\s*health\s*per\s*investigator",
        text or "",
        re.I,
    )
    return int(match.group(1)) if match else 0


def _forbids_clues_while_engaged(text: str) -> bool:
    """交战期间不能发现/花费线索（01121b Masked Hunter）。"""
    return bool(
        re.search(
            r"while you are engaged with .+?,\s*you cannot discover or spend clues",
            text or "",
            re.I | re.S,
        )
    )


def enemy_block(card: dict[str, Any], text: str = "") -> dict[str, Any]:
    keys = [
        "health",
        "enemy_fight",
        "enemy_evade",
        "enemy_damage",
        "enemy_horror",
    ]
    if not any(k in card for k in keys):
        return {}
    block: dict[str, Any] = {}
    if "health" in card:
        block["health"] = card["health"]
    if card.get("health_per_investigator"):
        block["health_per_investigator"] = True
    for src, dst in [
        ("enemy_fight", "fight"),
        ("enemy_evade", "evade"),
        ("enemy_damage", "damage"),
        ("enemy_horror", "horror"),
    ]:
        if src in card:
            block[dst] = card[src]
    bonus = _health_bonus_per_investigator(text)
    if bonus > 0:
        block["health_bonus_per_investigator"] = bonus
    return block


def location_block(card: dict[str, Any]) -> dict[str, Any]:
    block: dict[str, Any] = {}
    if "shroud" in card:
        cost, sentinel = decode_cost(card["shroud"])
        block["shroud"] = cost if sentinel == "none" else sentinel
    if "clues" in card:
        cost, sentinel = decode_cost(card["clues"])
        block["clues"] = cost if sentinel == "none" else sentinel
    if card.get("clues_fixed"):
        block["clues_fixed"] = True
    return block


SKILL_ICON_TO_NAME = {
    "[willpower]": "willpower",
    "[intellect]": "intellect",
    "[combat]": "combat",
    "[agility]": "agility",
    "[wild]": "wild",
}


def extract_spawn_line(text: str) -> str | None:
    match = re.search(r"<b>Spawn</b>\s*[-–]\s*(.+?)(?:\n|<b>|$)", text, re.I | re.S)
    if match:
        return match.group(1).strip().rstrip(".")
    match = re.search(r"(?m)^Spawn\s*[-–]\s*(.+)$", text or "", re.I)
    if match:
        return match.group(1).strip().rstrip(".")
    return None


def compile_spawn(text: str) -> dict[str, Any] | None:
    line = extract_spawn_line(text)
    if not line:
        return None
    lower = line.lower()
    if lower in ("your location", "the drawer's location"):
        return {"selector": "drawer_location"}
    if lower == "nearest empty location":
        return {"selector": "nearest_empty"}
    if lower == "farthest empty location":
        return {"selector": "farthest_empty"}
    if lower == "engaged with prey":
        return {"selector": "engaged_with_prey"}
    return {"selector": "named_location", "location_title": line}


def extract_prey_line(text: str) -> str | None:
    match = re.search(r"Prey\s*\(([^)]+)\)", text or "", re.I)
    if match:
        return match.group(1).strip()
    match = re.search(r"<b>Prey</b>\s*[-–]\s*(.+?)(?:\n|<b>|$)", text or "", re.I | re.S)
    if match:
        return match.group(1).strip().rstrip(".")
    match = re.search(r"(?m)^Prey\s*[-–]\s*(.+)$", text or "", re.I)
    if match:
        return match.group(1).strip().rstrip(".")
    return None


def compile_prey(text: str) -> dict[str, Any] | None:
    inner = extract_prey_line(text)
    if not inner:
        return None
    inner_l = inner.lower()
    if inner_l.endswith(" only"):
        return {
            "kind": "investigator_only",
            "investigator_title": inner[: -len(" only")].strip(),
        }
    if "most clues" in inner_l:
        return {"kind": "clues", "metric": "clues", "compare": "highest"}
    if "fewest clues" in inner_l:
        return {"kind": "clues", "metric": "clues", "compare": "lowest"}
    if "most resources" in inner_l:
        return {"kind": "skill", "metric": "resources", "compare": "highest"}
    if "fewest resources" in inner_l:
        return {"kind": "skill", "metric": "resources", "compare": "lowest"}
    skill = "willpower"
    for token, name in SKILL_ICON_TO_NAME.items():
        if token in inner_l:
            skill = name
            break
    if "lowest" in inner_l:
        return {"kind": "skill", "metric": "skill", "compare": "lowest", "skill": skill}
    if "highest" in inner_l:
        return {"kind": "skill", "metric": "skill", "compare": "highest", "skill": skill}
    return None


def _merge_encounter_back(out: dict[str, Any], linked: dict[str, Any]) -> None:
    """Act/Agenda linked_card 为遭遇类型 → 写入 back_card_type 与背面敌人参数。"""
    linked_type = linked.get("type_code") or ""
    if linked_type not in ("enemy", "treachery", "location"):
        return
    out["back_card_type"] = linked_type
    out["back_definition_id"] = linked.get("code", "")
    out["back_name"] = linked.get("name", "")
    linked_text = linked.get("real_text") or linked.get("text") or ""
    if linked_text and not out.get("back_text"):
        out["back_text"] = linked_text
    if linked_type == "enemy":
        eb = enemy_block(linked, linked_text)
        if eb:
            out["enemy"] = eb
        if linked.get("victory"):
            out["victory"] = int(linked.get("victory") or 0)
        traits = parse_traits(linked.get("traits") or linked.get("real_traits"))
        if traits:
            out["back_traits"] = traits
        if _forbids_clues_while_engaged(linked_text):
            out["forbid_clues_while_engaged"] = True
    linked_kw = extract_keywords(linked, linked_text)
    for kw in linked_kw:
        if kw not in out["keywords"]:
            out["keywords"].append(kw)
    spawn = compile_spawn(linked_text)
    if spawn:
        out["spawn_instruction"] = spawn
    prey = compile_prey(linked_text)
    if prey:
        out["prey_instruction"] = prey


def convert_card(card: dict[str, Any]) -> dict[str, Any] | None:
    type_code = card.get("type_code")
    if not type_code:
        return None

    text = card_text(card)
    resource_cost, cost_sentinel = decode_cost(card.get("cost"))
    subtype = card.get("subtype_code") or ""
    is_weakness = subtype in WEAKNESS_SUBTYPES
    keywords = extract_keywords(card, text)

    out: dict[str, Any] = {
        "definition_id": card["code"],
        "title": card.get("name", ""),
        "card_type": type_code,
        "pack_code": card.get("pack_code", ""),
        "resource_cost": resource_cost,
        "resource_cost_sentinel": cost_sentinel,
        "is_weakness": is_weakness,
        "subtype_code": subtype,
        ## 隐私 = 关键词 Hidden；≠ ArkhamDB JSON `hidden`（b 面列表隐藏）。
        "hidden": "hidden" in keywords,
        "aloof": "aloof" in keywords,
        "permanent": bool(card.get("permanent")),
        "victory": int(card.get("victory", 0) or 0),
        "keywords": keywords,
        "traits": parse_traits(card.get("traits")),
        "faction_code": card.get("faction_code", ""),
        "slot": card.get("slot", ""),
        "skills_icons": skills_icons(card),
        "enemy": enemy_block(card, text),
        "location": location_block(card),
        "encounter_code": card.get("encounter_code", ""),
        "ability_hints": extract_ability_hints(text),
        "text": text,
    }
    if "doom" in card and card.get("doom") is not None:
        out["doom"] = int(card["doom"])
    if card.get("back_text"):
        out["back_text"] = card.get("back_text")
    if card.get("back_name"):
        out["back_name"] = card.get("back_name")
    # 能力分段只用正面文本；背面是翻面效果，勿并入 Forced 捕获。
    front_text = card.get("text") or ""
    segments, compiled = compile_card_abilities(front_text)
    if segments:
        out["ability_segments"] = segments
    if compiled:
        out["compiled_abilities"] = compiled
    spawn = compile_spawn(text)
    if spawn:
        out["spawn_instruction"] = spawn
    prey = compile_prey(text)
    if prey:
        out["prey_instruction"] = prey
    if type_code == "enemy" and _forbids_clues_while_engaged(text):
        out["forbid_clues_while_engaged"] = True
    linked = card.get("linked_card")
    if isinstance(linked, dict) and type_code in ("act", "agenda"):
        _merge_encounter_back(out, linked)
    if card.get("duplicate_of"):
        out["duplicate_of"] = card["duplicate_of"]
    return out


def import_pack(pack_name: str) -> dict[str, Any]:
    path = PACK_DIR / "core" / f"{pack_name}.json"
    if not path.exists():
        # search all pack subdirs
        matches = list(PACK_DIR.rglob(f"{pack_name}.json"))
        if not matches:
            raise FileNotFoundError(path)
        path = matches[0]
    cards = json.loads(path.read_text(encoding="utf-8"))
    out: dict[str, Any] = {
        "_meta": {
            "source": str(path.relative_to(ROOT)).replace("\\", "/"),
            "pack": pack_name,
            "count": 0,
            "skipped": 0,
        }
    }
    for card in cards:
        converted = convert_card(card)
        if converted is None:
            out["_meta"]["skipped"] += 1
            continue
        out[card["code"]] = converted
        out["_meta"]["count"] += 1
    out["_meta"]["ability_compile_summary"] = summarize_compile(out)
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description="Import ArkhamDB packs to engine JSON")
    parser.add_argument(
        "packs",
        nargs="*",
        default=["core_2026", "core_2026_encounter"],
        help="Pack file stems (e.g. core_2026)",
    )
    args = parser.parse_args()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for pack in args.packs:
        data = import_pack(pack)
        out_path = OUT_DIR / f"{pack}.json"
        out_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        meta = data["_meta"]
        print(f"Wrote {out_path.relative_to(ROOT)} ({meta['count']} cards, skipped {meta['skipped']})")


if __name__ == "__main__":
    main()
