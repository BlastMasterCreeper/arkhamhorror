#!/usr/bin/env python3
"""Fetch ArkhamDB rules page and save as searchable Markdown."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from urllib.request import Request, urlopen

DEFAULT_URL = "https://zh.arkhamdb.com/rules"
USER_AGENT = "arkhamhorror-rules-engine/1.0 (local docs mirror; non-commercial)"


def _html_to_text(html: str) -> str:
	# Minimal cleanup when the endpoint returns HTML instead of markdown-like text.
	text = re.sub(r"(?is)<script.*?>.*?</script>", "", html)
	text = re.sub(r"(?is)<style.*?>.*?</style>", "", text)
	text = re.sub(r"(?i)<br\s*/?>", "\n", text)
	text = re.sub(r"(?i)</p>", "\n\n", text)
	text = re.sub(r"(?i)</h([1-6])>", r"\n\n", text)
	text = re.sub(r"<[^>]+>", "", text)
	text = re.sub(r"\n{3,}", "\n\n", text)
	return text.strip()


def fetch_rules(url: str) -> str:
	req = Request(url, headers={"User-Agent": USER_AGENT})
	with urlopen(req, timeout=60) as resp:
		raw = resp.read()
	charset = resp.headers.get_content_charset() or "utf-8"
	body = raw.decode(charset, errors="replace")
	if "<html" in body.lower():
		return _html_to_text(body)
	return body.strip()


def build_markdown(body: str, url: str) -> str:
	lines = body.splitlines()
	if lines and lines[0].strip() in ("Rules · ArkhamDB", "Rules | ArkhamDB"):
		lines = lines[1:]
	while lines and not lines[0].strip():
		lines.pop(0)
	clean_body = "\n".join(lines).strip()
	header = f"""# Arkham Horror LCG — Rules Reference (ArkhamDB)

> **在线来源：** [{url}]({url})  
> **内容：** 第一版 Core Set Rules Reference，含豪华扩增订（站内标红）与旧版官方 FAQ 增补（站内标蓝）  
> **本项目：** **次级参考**；引擎裁定以 [2026 Grimoire](arkham-grimoire-v1.0.pdf) 为准。社区经验：2.0 Rules Reference 与此合集 **几乎无出入**。  
> **刷新：** `python tools/fetch_arkhamdb_rules.py`

---

"""
	return header + clean_body + "\n"


def main() -> int:
	root = Path(__file__).resolve().parents[1]
	parser = argparse.ArgumentParser(description="Mirror ArkhamDB rules to docs/reference.")
	parser.add_argument("--url", default=DEFAULT_URL, help="Rules page URL")
	parser.add_argument(
		"--out",
		type=Path,
		default=root / "docs" / "reference" / "arkhamdb-rules-reference.md",
	)
	args = parser.parse_args()
	try:
		body = fetch_rules(args.url)
	except OSError as exc:
		print(f"FETCH FAILED: {exc}", file=sys.stderr)
		return 1
	args.out.parent.mkdir(parents=True, exist_ok=True)
	args.out.write_text(build_markdown(body, args.url), encoding="utf-8")
	print(f"OK {args.url} -> {args.out} ({len(body)} chars)")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
