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

GAINED_CHARACTERISTIC_PATTERNS: list[tuple[str, re.Pattern[str], str, str]] = [
    (
        "keyword_surge",
        re.compile(r"gains\s+surge", re.I),
        "KEYWORD",
        "WHILE_DRAWN_CARD_RESOLVING · §06 3.1",
    ),
    (
        "keyword_other",
        re.compile(r"gains\s+(?:the\s+)?(peril|retaliate|hunter|aloof|massive|fast)\b", re.I),
        "KEYWORD",
        "按 keyword consumer · P2",
    ),
    (
        "ability_action",
        re.compile(r"gains\s*:?\s*(\[action\]|\[reaction\]|\[free\])", re.I),
        "ABILITY",
        "LISTENER + AbilitySpec · P1",
    ),
    (
        "ability_forced",
        re.compile(r"gains\s+[^.]{0,120}\bForced\b", re.I),
        "ABILITY",
        "LISTENER · Forced 文本",
    ),
    (
        "trait",
        re.compile(r"gains?\s+the?\s*(\[\[[^\]]+\]\]|\w+)\s+trait", re.I),
        "TRAIT",
        "TRAIT 标记 · P2",
    ),
    (
        "icon",
        re.compile(r"gains?\s+\[(willpower|intellect|combat|agility|wild)\]", re.I),
        "ICON",
        "MODIFIER / ICON · THIS_SKILL_TEST",
    ),
    (
        "until_eot_ability",
        re.compile(
            r"until end of (?:your )?turn[^.]{0,100}(\[action\]|\[reaction\]|\[free\]|Forced)",
            re.I,
        ),
        "ABILITY",
        "DURATION(THIS_TURN) · P1",
    ),
    (
        "deckbuilding_meta",
        re.compile(r"Deckbuilding Options gains", re.I),
        "META",
        "构筑元数据 · 非运行时 characteristic",
    ),
]

NOT_CHARACTERISTIC_PATTERNS: list[tuple[str, re.Pattern[str], str]] = [
    ("gain_resources", re.compile(r"\bgain\s+\d+\s+resource", re.I), "L0 资源原语"),
    ("gain_action", re.compile(r"\bgain\s+(?:an?\s+)?action\b", re.I), "L0 行动原语"),
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


def card_text_blob(c: dict[str, Any]) -> str:
    parts = [plain(c.get("text", "")), plain(c.get("back_text", ""))]
    for seg in c.get("ability_segments") or []:
        parts.append(plain(seg.get("body", "")))
    return "\n".join(p for p in parts if p)


def analyze_gained_characteristics(cards: list[dict[str, Any]]) -> tuple[str, dict[str, list[str]]]:
    by_pattern: dict[str, list[str]] = defaultdict(list)
    not_char: dict[str, list[str]] = defaultdict(list)
    for c in cards:
        text = card_text_blob(c)
        ref = card_ref(c)
        matched_char = False
        for key, pat, _kind, _route in GAINED_CHARACTERISTIC_PATTERNS:
            if pat.search(text):
                by_pattern[key].append(ref)
                matched_char = True
        for key, pat, _route in NOT_CHARACTERISTIC_PATTERNS:
            if pat.search(text):
                not_char[key].append(ref)
    lines = [
        "# Core 2026 · Gained characteristics 统计",
        "",
        "数据源：`data/arkhamdb/imported/core_2026*.json`。",
        "设计总纲：[06 §3.2](../../docs/design/06-registration-buff-model.md#32-gained-characteristics动态特征--总纲--已裁决)。",
        "",
        f"卡牌数：**{len(cards)}**（两包合计）。",
        "",
        "## 1. Characteristic 模式（Grimoire *gains a characteristic*）",
        "",
        "| 模式 | 命中 | Kind | 路由 | 卡清单 |",
        "|---|---:|---|---|---|",
    ]
    for key, pat, kind, route in GAINED_CHARACTERISTIC_PATTERNS:
        refs = by_pattern.get(key, [])
        lines.append(
            f"| `{key}` | {len(refs)} | {kind} | {route} | {'; '.join(refs) or '—'} |"
        )
    lines += [
        "",
        "## 2. 非 characteristic（勿误入 Gained 层）",
        "",
        "| 模式 | 命中 | 路由 | 卡清单 |",
        "|---|---:|---|---|",
    ]
    for key, _pat, route in NOT_CHARACTERISTIC_PATTERNS:
        refs = not_char.get(key, [])
        ref_cell = "; ".join(refs[:8]) or "—"
        if len(refs) > 8:
            ref_cell += f" … +{len(refs) - 8} more"
        lines.append(f"| `{key}` | {len(refs)} | {route} | {ref_cell} |")
    lines += [
        "",
        "## 3. 实现优先级（Core 2026）",
        "",
        "| 优先级 | 内容 | 卡例 |",
        "|---|---|---|",
        "| **P0** | `has_effective_keyword` + Surge KEYWORD Register | 12124, 12126, 12160 |",
        "| **P1** | until EOT + `[action]` / `[reaction]`（扩展包为主） | Core 2026：**0** |",
        "| **P2** | trait / icon / 其它 keyword gains | Core 2026：**0** |",
        "| — | Deckbuilding Options gains | 12181 Collector（META） |",
        "",
    ]
    return "\n".join(lines), dict(by_pattern)


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
        "## 6. 卡面驱动 open questions",
        "",
        "| ID | 来源卡 | 说明 |",
        "|---|---|---|",
        "| OQ-ADB-01 | 12099 The Nameless Lurker | Farthest empty spawn — blocked path 见 OQ-09-04 |",
        "| OQ-ADB-04 | 12012 The Necronomicon | cannot leave play + threat area — Permanent 混合 |",
        "| OQ-ADB-05 | 12179b Elokoss | Hidden enemy + spawn 分支 — ENC-22/23 已测 |",
        "",
        "**已裁决**：OQ-ADB-02/03（涌动）— 见 [06 §3.1–3.2](../../docs/design/06-registration-buff-model.md#31-涌动surge--已裁决)。",
        "",
        "Gained characteristics 统计：[`core_2026_gained_characteristics.md`](core_2026_gained_characteristics.md)。",
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
    gained_md, _ = analyze_gained_characteristics(cards)
    gained_out = REPORTS / "core_2026_gained_characteristics.md"
    gained_out.write_text(gained_md, encoding="utf-8")
    print(f"Wrote {out.relative_to(ROOT)} ({len(cards)} cards)")
    print(f"Wrote {gained_out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
