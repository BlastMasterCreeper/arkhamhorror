#!/usr/bin/env python3
"""Extract PDF text to searchable Markdown (page-marked sections)."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
	from pypdf import PdfReader
except ImportError:
	print("Missing pypdf. Install: python -m pip install pypdf", file=sys.stderr)
	sys.exit(1)


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
	reader = PdfReader(str(pdf_path))
	page_count = len(reader.pages)
	parts: list[str] = [
		f"# {title}",
		"",
		f"> **Source:** `{pdf_path.name}`  ",
		f"> **Pages:** {page_count}  ",
		"> **Note:** Machine extraction for agent/search use; authoritative wording is the PDF.",
		"",
		"---",
		"",
	]
	for i, page in enumerate(reader.pages):
		raw = page.extract_text() or ""
		text = _clean_page_text(raw)
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
	args = parser.parse_args()
	ref_dir: Path = args.ref_dir
	jobs = [
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
	for pdf_path, md_path, title in jobs:
		if not pdf_path.is_file():
			print(f"SKIP (missing): {pdf_path}", file=sys.stderr)
			continue
		pages = pdf_to_markdown(pdf_path, md_path, title)
		print(f"OK {pdf_path.name} -> {md_path.name} ({pages} pages)")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
