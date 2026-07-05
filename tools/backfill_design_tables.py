#!/usr/bin/env python3
"""Generate Phase 4 design-table backfill from imported Core 2026 JSON."""

from __future__ import annotations

import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
IMPORTED = ROOT / "data" / "arkhamdb" / "imported"
REPORTS = ROOT / "data" / "arkhamdb" / "reports"

STRIP_HTML = re.compile(r"<[^>]+>")

MODIFIER_PATTERNS = [
    ("skill_bonus", re.compile(r"\+(\d+)\s*\[(willpower|intellect|combat|agility|wild)\]", re.I)),
    ("skill_penalty", re.compile(r"-(\d+)\s*\[(willpower|intellect|combat|agility|wild)\]", re.I)),
    ("damage_bonus", re.compile(r"\+(\d+)\s*damage", re.I)),
    ("horror_bonus", re.compile(r"\+(\d+)\s*horror", re.I)),
    ("shroud_bonus", re.compile(r"\+(\d+)\s*shroud", re.I)),
    ("cost_reduce", re.compile(r"-(\d+)\s*cost|reduce.*cost by (\d+)", re.I)),
    ("fight_bonus", re.compile(r"\+(\d+)\s*\[?fight\]?", re.I)),
    ("evade_bonus", re.compile(r"\+(\d+)\s*\[?evade\]?", re.I)),
]

CANNOT_RULES: list[tuple[str, re.Pattern[str], str]] = [
    ("DOMAIN_PERMANENT", re.compile(r"cannot leave play", re.I), "Domain · Permanent 关键词"),
    ("FORBID_DRAW", re.compile(r"(?<![a-z])cannot draw\b", re.I), "REST-E-DRAW"),
    ("FORBID_PLAY", re.compile(r"(?<![a-z])cannot play\b", re.I), "REST-E-PLAY"),
    ("FORBID_TRIGGER", re.compile(r"(?<![a-z])cannot trigger\b", re.I), "REST-E-TRIGGER"),
    ("FORBID_COMMIT_TO_TEST", re.compile(r"(?<![a-z])cannot commit\b", re.I), "REST-E-COMMIT"),
    ("FORBID_MOVE", re.compile(r"(?<![a-z])cannot move\b", re.I), "REST-E-ACTION / 敌人指令"),
    ("FORBID_DISCARD", re.compile(r"(?<![a-z])cannot discard\b", re.I), "REST-E-EFFECT"),
    ("FORBID_GAIN_HORROR", re.compile(r"(?<![a-z])cannot (?:take|gain)[^.]{0,20}horror", re.I), "REST-E-EFFECT"),
    ("FORBID_GAIN_DAMAGE", re.compile(r"(?<![a-z])cannot (?:take|gain)[^.]{0,20}damage", re.I), "REST-E-EFFECT"),
    ("FORBID_LEAVE_HAND", re.compile(r"cannot leave your hand", re.I), "REST-E-MOVE"),
    ("FORBID_ACTIVATE", re.compile(r"(?<![a-z])cannot activate\b", re.I), "REST-E-ACTIVATE"),
    ("IMMUNITY", re.compile(r"cannot be (?:damaged|canceled)", re.I), "免疫 · 非 FORBID Intent"),
    ("IF_YOU_CANNOT", re.compile(r"\bif you cannot\b", re.I), "条件分支 · 非 RESTRICTION Register"),
]

AFTER_TRIGGERS = [
    ("after_fight", re.compile(r"After (?:you )?fight", re.I)),
    ("after_enemy_defeated", re.compile(r"After (?:an )?enemy (?:is )?defeated", re.I)),
    ("after_draw", re.compile(r"After (?:you )?draw", re.I)),
    ("after_reveal", re.compile(r"After .*reveal", re.I)),
    ("after_engagement", re.compile(r"After .*engage", re.I)),
    ("after_evade", re.compile(r"After (?:you )?evade", re.I)),
    ("after_damage_dealt", re.compile(r"After you deal damage", re.I)),
    ("after_clue", re.compile(r"After you (?:discover|gain).*clue", re.I)),
    ("after_phase", re.compile(r"When (?:the )?investigation phase ends", re.I)),
]


def plain(text: str) -> str:
    return STRIP_HTML.sub("", text or "").strip()


def load_cards() -> list[dict[str, Any]]:
    cards: list[dict[str, Any]] = []
    for name in ("core_2026.json", "core_2026_encounter.json"):
        path = IMPORTED / name
        if not path.exists():
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        for code, entry in data.items():
            if code.startswith("_") or not isinstance(entry, dict):
                continue
            entry = dict(entry)
            entry["_code"] = code
            entry["_pack"] = name.replace(".json", "")
            cards.append(entry)
    return cards


def card_ref(c: dict[str, Any]) -> str:
    return f"{c['_code']} {c.get('title', '')}"


def modifier_hits(cards: list[dict[str, Any]]) -> tuple[Counter, dict[str, list[str]]]:
    counts: Counter = Counter()
    examples: dict[str, list[str]] = defaultdict(list)
    stat_ref = {
        "skill_bonus": "MOD-Q-SKILL",
        "skill_penalty": "MOD-Q-SKILL",
        "damage_bonus": "MOD-Q-DAMAGE-AMT",
        "horror_bonus": "MOD-Q-HORROR-AMT",
        "shroud_bonus": "MOD-Q-SHROUD",
        "cost_reduce": "MOD-Q-COST",
        "fight_bonus": "MOD-Q-SKILL (combat)",
        "evade_bonus": "MOD-Q-SKILL (agility)",
    }
    for card in cards:
        text = plain(card.get("text", ""))
        for key, pat in MODIFIER_PATTERNS:
            if pat.search(text):
                counts[key] += 1
                label = stat_ref.get(key, "?")
                bucket = f"{key} → {label}"
                if len(examples[bucket]) < 6:
                    examples[bucket].append(card_ref(card))
    return counts, examples


def classify_cannot(cards: list[dict[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for card in cards:
        text = plain(card.get("text", ""))
        if "cannot" not in text.lower():
            continue
        snippet = ""
        for m in re.finditer(r"[^.!?]*cannot[^.!?]*[.!?]", text, re.I):
            snippet = m.group(0).strip()
            break
        intent = "FORBID_UNCLASSIFIED"
        entry = "待人工"
        for name, pat, rest_entry in CANNOT_RULES:
            if name == "IF_YOU_CANNOT":
                continue
            if pat.search(text):
                intent = name
                entry = rest_entry
                break
        if intent == "FORBID_UNCLASSIFIED" and re.search(r"\bif you cannot\b", text, re.I):
            intent = "IF_YOU_CANNOT"
            entry = "条件分支 · 非 RESTRICTION Register"
        rows.append(
            {
                "code": card["_code"],
                "title": card.get("title", ""),
                "intent": intent,
                "entry": entry,
                "snippet": snippet[:100],
            }
        )
    return rows


def listener_rows(cards: list[dict[str, Any]]) -> dict[str, list[str]]:
    out: dict[str, list[str]] = defaultdict(list)
    for card in cards:
        text = plain(card.get("text", ""))
        if card.get("hunter") or "hunter" in card.get("keywords", []):
            out["keyword_hunter"].append(card_ref(card))
        if card.get("retaliate") or "retaliate" in card.get("keywords", []):
            out["keyword_retaliate"].append(card_ref(card))
        for key, pat in AFTER_TRIGGERS:
            if pat.search(text) and len(out[key]) < 12:
                out[key].append(card_ref(card))
        for seg in card.get("ability_segments", []):
            if seg.get("kind") == "forced" and seg.get("trigger"):
                bucket = f"forced:{seg['trigger'][:40]}"
                if len(out[bucket]) < 4:
                    out[bucket].append(card_ref(card))
    return out


def encounter_pipeline(cards: list[dict[str, Any]]) -> dict[str, list[str]]:
    buckets: dict[str, list[str]] = defaultdict(list)

    def add(bucket: str, card: dict[str, Any]) -> None:
        if len(buckets[bucket]) < 20:
            buckets[bucket].append(card_ref(card))

    for card in cards:
        kws = set(card.get("keywords", []))
        if "surge" in kws:
            add("surge", card)
        if "peril" in kws:
            add("peril", card)
        if card.get("hidden") or "hidden" in kws:
            add("hidden", card)
        if card.get("aloof") or "aloof" in kws:
            add("aloof", card)
        if card.get("massive") or "massive" in kws:
            add("massive", card)
        if card.get("spawn_instruction"):
            add("spawn_instruction", card)
        if card.get("prey_instruction"):
            add("prey_instruction", card)
    return buckets


def template_selection(cards: list[dict[str, Any]]) -> dict[str, list[str]]:
    template: list[str] = []
    partial: list[str] = []
    script: list[str] = []
    for card in cards:
        compiled = card.get("compiled_abilities", [])
        segments = card.get("ability_segments", [])
        if not segments:
            continue
        ref = card_ref(card)
        if compiled:
            statuses = {c.get("status") for c in compiled}
            if statuses == {"full"}:
                template.append(ref)
            else:
                partial.append(ref)
        else:
            script.append(ref)
    return {"template_full": template, "template_partial": partial, "script_needed": script}


def render_markdown(cards: list[dict[str, Any]]) -> str:
    mod_counts, mod_examples = modifier_hits(cards)
    cannot_rows = classify_cannot(cards)
    listeners = listener_rows(cards)
    enc = encounter_pipeline(cards)
    selection = template_selection(cards)

    meta_skill = sum(mod_counts.get(k, 0) for k in ("skill_bonus", "skill_penalty", "fight_bonus", "evade_bonus"))

    lines = [
        "# Phase 4 · Core 2026 设计表回填",
        "",
        "数据源：`data/arkhamdb/imported/core_2026*.json`（Phase 1–3 导入层）。",
        f"卡牌数：**{len(cards)}**（两包合计，已跳过 stub）。",
        "",
        "回填目标：[06 §16.3–16.5](../design/06-registration-buff-model.md)、[15 §17](../design/15-timing-entry-catalog.md)、[12 §1.1](../design/12-card-script-api.md)。",
        "",
        "---",
        "",
        "## 1. MODIFIER 查询站（06 §16.3）",
        "",
        "| 卡面模式 | 命中卡数 | 建议 StatRef / 查询站 | 样例 |",
        "|---|---:|---|---|",
    ]
    rows = [
        ("`+N [skill]` / fight / evade", meta_skill, "MOD-Q-SKILL", mod_examples),
        ("`+N damage`", mod_counts.get("damage_bonus", 0), "MOD-Q-DAMAGE-AMT", mod_examples),
        ("`+N horror`", mod_counts.get("horror_bonus", 0), "MOD-Q-HORROR-AMT", mod_examples),
        ("`+N shroud`", mod_counts.get("shroud_bonus", 0), "MOD-Q-SHROUD", mod_examples),
        ("`-N cost` / reduce cost", mod_counts.get("cost_reduce", 0), "MOD-Q-COST", mod_examples),
    ]
    for label, count, stat, ex in rows:
        sample = "；".join(
            v for k, vals in ex.items() if stat.split()[0].replace("MOD-Q-", "") in k or stat in k for v in vals[:2]
        )
        if not sample:
            sample = "—"
        lines.append(f"| {label} | {count} | **{stat}** | {sample} |")

    lines += [
        "",
        "## 2. RESTRICTION Intent（06 §16.4.2）",
        "",
        f"含 `cannot` 卡面：**{len(cannot_rows)}** 张（ArkhamDB 统计原为 12，含 back_text / 多句扩展）。",
        "",
        "| 卡码 | 卡名 | 建议 Intent | 入口 | 片段 |",
        "|---|---|---|---|---|",
    ]
    for row in sorted(cannot_rows, key=lambda r: r["code"]):
        lines.append(
            f"| {row['code']} | {row['title']} | `{row['intent']}` | {row['entry']} | {row['snippet']} |"
        )

    lines += [
        "",
        "## 3. LISTENER / 关键词（06 §16.5）",
        "",
        "### 3.1 引擎关键词（已编译进 CardDefinition）",
        "",
        "| 键 | 卡数 | 卡清单（前 12） |",
        "|---|---:|---|",
    ]
    for key in ("keyword_hunter", "keyword_retaliate"):
        refs = listeners.get(key, [])
        lines.append(f"| `{key}` | {len(refs)} | {'; '.join(refs[:12]) or '—'} |")

    lines += [
        "",
        "### 3.2 Forced / After 触发片段（LISTENER 增长线索）",
        "",
        "| 触发模式 | 命中 | 样例 |",
        "|---|---:|---|",
    ]
    for key, pat in AFTER_TRIGGERS:
        refs = listeners.get(key, [])
        lines.append(f"| `{key}` | {len(refs)} | {'; '.join(refs[:3]) or '—'} |")

    lines += [
        "",
        "## 4. 遭遇管线卡清单（15 §17）",
        "",
        "| 分类 | 卡数 | 卡码 · 卡名 |",
        "|---|---:|---|",
    ]
    labels = {
        "surge": "Surge 关键词",
        "peril": "Peril 关键词",
        "hidden": "Hidden 隐私",
        "aloof": "Aloof",
        "massive": "Massive",
        "spawn_instruction": "Spawn 指令（已编译）",
        "prey_instruction": "Prey 指令（已编译）",
    }
    for key, label in labels.items():
        refs = enc.get(key, [])
        lines.append(f"| {label} | {len(refs)} | {'; '.join(refs) or '—'} |")

    lines += [
        "",
        "## 5. Template vs Script 选型（12 §1.1）",
        "",
        "| 选型 | 卡数 | 说明 |",
        "|---|---:|---|",
        f"| **Template 全匹配** | {len(selection['template_full'])} | `compiled_abilities` status=full |",
        f"| **Template 部分** | {len(selection['template_partial'])} | 首句模板 + 条件/检定待 Script |",
        f"| **Script 优先** | {len(selection['script_needed'])} | 有能力段但未命中 Phase 3 模板 |",
        "",
        "### 5.1 Template 全匹配",
        "",
    ]
    lines += [f"- {r}" for r in selection["template_full"][:15]] or ["- —"]
    lines += ["", "### 5.2 Script 优先（节选）", ""]
    lines += [f"- {r}" for r in selection["script_needed"][:20]] or ["- —"]
    lines += [
        "",
        "## 6. 卡面驱动 open questions（新增线索）",
        "",
        "| ID | 来源卡 | 说明 |",
        "|---|---|---|",
        "| OQ-ADB-01 | 12099 The Nameless Lurker | Farthest empty spawn — blocked path 见 OQ-09-04 |",
        "| OQ-ADB-02 | 12124 Cosmic Evils | Peril + 动态 surge 赋予 — evaluate 时机 |",
        "| OQ-ADB-03 | 12126 Forbidden Secrets | 无 clue 时 gains surge — revelation 前/后 |",
        "| OQ-ADB-04 | 12012 The Necronomicon | cannot leave play + threat area — Permanent 混合 |",
        "| OQ-ADB-05 | 12179b Elokoss | Hidden enemy + spawn 分支 — ENC-22/23 已测 |",
        "",
    ]
    return "\n".join(lines)


def main() -> None:
    cards = load_cards()
    if not cards:
        raise SystemExit("No imported cards; run tools/arkhamdb_import.py first")
    REPORTS.mkdir(parents=True, exist_ok=True)
    out = REPORTS / "phase4_core_2026_backfill.md"
    out.write_text(render_markdown(cards), encoding="utf-8")
    print(f"Wrote {out.relative_to(ROOT)} ({len(cards)} cards)")


if __name__ == "__main__":
    main()
