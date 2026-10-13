"""Escape Arkham Horror PDF Private-Use glyphs to ArkhamDB `[symbol]` notation.

2026 Core / Grimoire PDFs embed a custom icon font. Text extraction yields
unreadable PUA codepoints (BMP `U+F2xx`, and a supplementary-plane copy
offset by `0xEF20` on some pages). Map them to the notation in
`docs/reference/arkham-symbol-notation.md`.
"""

from __future__ import annotations

from pathlib import Path

# Grimoire p.47 / Rulebook back cover labels the BMP PUA glyphs.
SYMBOL_BY_CODEPOINT: dict[int, str] = {
    0xF250: "willpower",
    0xF251: "agility",
    0xF252: "intellect",
    0xF253: "combat",
    0xF254: "rogue",
    0xF255: "survivor",
    0xF256: "guardian",
    0xF257: "mystic",
    0xF258: "seeker",
    0xF259: "action",
    0xF25A: "free",
    0xF25B: "skull",
    0xF25C: "cultist",
    0xF25D: "auto_fail",
    0xF25E: "elder_thing",
    0xF25F: "elder_sign",
    0xF260: "tablet",
    0xF261: "unique",
    0xF263: "per_investigator",
    0xF26C: "wild",
    0xF26D: "reaction",
    0xF278: "codex",
}

# Rulebook back-cover pages sometimes emit the same glyphs at BMP + 0xE2F20
# (e.g. U+F218D = U+F26D reaction).
SUPPLEMENT_OFFSET = 0xE2F20

_EXTRACTION_NOTE_OLD = (
    "> **Note:** Machine extraction for agent/search use; authoritative wording is the PDF."
)
_EXTRACTION_NOTE_NEW = (
    "> **Note:** Machine extraction for agent/search use; authoritative wording is the PDF.  \n"
    "> **Symbols:** Custom PDF glyphs are escaped to ArkhamDB `[symbol]` notation "
    "(see [`arkham-symbol-notation.md`](arkham-symbol-notation.md))."
)


def _symbol_name(codepoint: int) -> str | None:
    name = SYMBOL_BY_CODEPOINT.get(codepoint)
    if name is not None:
        return name
    shifted = codepoint - SUPPLEMENT_OFFSET
    if shifted in SYMBOL_BY_CODEPOINT:
        return SYMBOL_BY_CODEPOINT[shifted]
    return None


def escape_game_symbols(text: str) -> str:
    """Replace PDF icon glyphs (and NBSP) with readable Markdown."""
    out: list[str] = []
    for ch in text:
        name = _symbol_name(ord(ch))
        if name is not None:
            out.append(f"[{name}]")
            continue
        if ch == "\xa0":
            out.append(" ")
            continue
        out.append(ch)
    escaped = "".join(out)
    if _EXTRACTION_NOTE_OLD in escaped and _EXTRACTION_NOTE_NEW not in escaped:
        escaped = escaped.replace(_EXTRACTION_NOTE_OLD, _EXTRACTION_NOTE_NEW, 1)
    return escaped


def remaining_pua(text: str) -> list[tuple[str, int]]:
    """Return leftover private-use characters and counts (for verification)."""
    counts: dict[str, int] = {}
    for ch in text:
        cat_ok = 0xE000 <= ord(ch) <= 0xF8FF or 0xF0000 <= ord(ch) <= 0xFFFFD
        if cat_ok:
            counts[ch] = counts.get(ch, 0) + 1
    return sorted(counts.items(), key=lambda item: (-item[1], ord(item[0])))


def rewrite_markdown(path: Path) -> dict[str, int]:
    original = path.read_text(encoding="utf-8")
    updated = escape_game_symbols(original)
    leftover = remaining_pua(updated)
    if updated != original:
        path.write_text(updated, encoding="utf-8")
    return {
        "changed": int(updated != original),
        "chars": len(original),
        "pua_left": sum(n for _, n in leftover),
    }


if __name__ == "__main__":
    assert escape_game_symbols("\uf26d") == "[reaction]"
    assert escape_game_symbols("\uf259") == "[action]"
    assert escape_game_symbols("\uf25a") == "[free]"
    assert escape_game_symbols(chr(0xF218D)) == "[reaction]"
    for codepoint, name in SYMBOL_BY_CODEPOINT.items():
        assert escape_game_symbols(chr(codepoint)) == f"[{name}]"
        assert escape_game_symbols(chr(codepoint + SUPPLEMENT_OFFSET)) == f"[{name}]"
    print("arkham_symbol_escape: ok")
