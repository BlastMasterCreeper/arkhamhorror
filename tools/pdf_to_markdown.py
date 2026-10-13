#!/usr/bin/env python3
"""Extract PDF text to searchable Markdown (page-marked sections).

Custom icon-font glyphs are escaped to ArkhamDB `[symbol]` notation
(see `docs/reference/arkham-symbol-notation.md`).
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from arkham_symbol_escape import escape_game_symbols, rewrite_markdown


def _clean_page_text(text: str) -> str:
    lines = [ln.rstrip() for ln in text.splitlines()]
    out: list[str] = []
    blank_run = 0
    for ln in lines:
        if not ln.strip():
            blank_run += 1
            if blank_run <= 2:
                out.append("")
            continue
        blank_run = 0
        out.append(ln)
    while out and not out[-1].strip():
        out.pop()
    return "\n".join(out)


def pdf_to_markdown(pdf_path: Path, out_path: Path, title: str) -> int:
    try:
        from pypdf import PdfReader
    except ImportError:
        print("Missing pypdf. Install: python -m pip install pypdf", file=sys.stderr)
        raise SystemExit(1)
    reader = PdfReader(str(pdf_path))
    page_count = len(reader.pages)
    parts: list[str] = [
        f"# {title}",
        "",
        f"> **Source:** `{pdf_path.name}`  ",
        f"> **Pages:** {page_count}  ",
        "> **Note:** Machine extraction for agent/search use; authoritative wording is the PDF.  ",
        "> **Symbols:** Custom PDF glyphs are escaped to ArkhamDB `[symbol]` notation "
        "(see [`arkham-symbol-notation.md`](arkham-symbol-notation.md)).",
        "",
        "---",
        "",
    ]
    for i, page in enumerate(reader.pages):
        raw = page.extract_text() or ""
        text = escape_game_symbols(_clean_page_text(raw))
        parts.append(f"## Page {i + 1}")
        parts.append("")
        if text:
            parts.append(text)
        else:
            parts.append("*(no extractable text on this page)*")
        parts.append("")
        parts.append("---")
        parts.append("")
    body = "\n".join(parts).rstrip() + "\n"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(body, encoding="utf-8")
    return page_count


def _jobs(ref_dir: Path) -> list[tuple[Path, Path, str]]:
    return [
        (
            ref_dir / "arkham-grimoire-v1.0.pdf",
            ref_dir / "arkham-grimoire-v1.0.md",
            "Arkham Grimoire v1.0 (2026 Core Set)",
        ),
        (
            ref_dir / "2026-core-rulebook.pdf",
            ref_dir / "2026-core-rulebook.md",
            "Arkham Horror LCG — 2026 Core Set Rulebook",
        ),
    ]


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    ref = root / "docs" / "reference"
    parser = argparse.ArgumentParser(description="Convert reference PDFs to Markdown.")
    parser.add_argument(
        "--ref-dir",
        type=Path,
        default=ref,
        help="Directory containing PDFs (default: docs/reference)",
    )
    parser.add_argument(
        "--rewrite-md",
        action="store_true",
        help="Escape glyphs in existing extracted Markdown (no PDF required).",
    )
    args = parser.parse_args()
    ref_dir: Path = args.ref_dir
    jobs = _jobs(ref_dir)
    if args.rewrite_md:
        for _pdf_path, md_path, _title in jobs:
            if not md_path.is_file():
                print(f"SKIP (missing): {md_path}", file=sys.stderr)
                continue
            stats = rewrite_markdown(md_path)
            print(
                f"OK {md_path.name} changed={stats['changed']} pua_left={stats['pua_left']}"
            )
        return 0
    for pdf_path, md_path, title in jobs:
        if not pdf_path.is_file():
            print(f"SKIP (missing): {pdf_path}", file=sys.stderr)
            continue
        pages = pdf_to_markdown(pdf_path, md_path, title)
        print(f"OK {pdf_path.name} -> {md_path.name} ({pages} pages)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
