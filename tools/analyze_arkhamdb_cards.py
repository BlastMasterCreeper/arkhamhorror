#!/usr/bin/env python3
"""Analyze ArkhamDB JSON packs and emit design-facing reports."""

from __future__ import annotations

import json
import re
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "arkhamdb"
REPORTS = DATA / "reports"

# Ability / keyword patterns in card text (ArkhamDB symbol notation)
ABILITY_PATTERNS = {
    "reaction": re.compile(r"\[reaction\]", re.I),
    "action": re.compile(r"\[action\]", re.I),
    "fast": re.compile(r"\[fast\]", re.I),
    "elder_sign": re.compile(r"\[elder_sign\]", re.I),
    "revelation_bold": re.compile(r"<b>Revelation</b>", re.I),
    "forced_bold": re.compile(r"<b>Forced</b>", re.I),
    "spawn_line": re.compile(r"\bSpawn\b\s*[–-]", re.I),
    "prey_line": re.compile(r"\bPrey\b\s*[–-]", re.I),
    "patrol_paren": re.compile(r"\bPatrol\b\s*\(", re.I),
    "parley_bold": re.compile(r"<b>Parley\.</b>", re.I),
    "fight_bold": re.compile(r"<b>Fight</b>", re.I),
    "evade_bold": re.compile(r"<b>Evade</b>", re.I),
    "investigate_bold": re.compile(r"<b>Investigate</b>", re.I),
    "move_bold": re.compile(r"<b>Move</b>", re.I),
    "resign_bold": re.compile(r"<b>Resign</b>", re.I),
    "cannot": re.compile(r"\bcannot\b", re.I),
    "immune": re.compile(r"\bimmune\b", re.I),
    "surge_text": re.compile(r"\bSurge\b", re.I),
    "peril_text": re.compile(r"\bPeril\b", re.I),
    "aloof_text": re.compile(r"\bAloof\b", re.I),
    "hunter_text": re.compile(r"\bHunter\b", re.I),
    "retaliate_text": re.compile(r"\bRetaliate\b", re.I),
    "massive_text": re.compile(r"\bMassive\b", re.I),
    "hidden_text": re.compile(r"\bHidden\b", re.I),
    "limit_once": re.compile(r"Limit once per", re.I),
    "limit_per_round": re.compile(r"Limit .* per round", re.I),
}

NUMERIC_SENTINEL = {
    None: "-",
    -2: "X",
    -3: "*",
    -4: "?",
}


@dataclass
class PackStats:
    pack_code: str
    path: Path
    cards: list[dict[str, Any]] = field(default_factory=list)
    by_type: Counter = field(default_factory=Counter)
    by_subtype: Counter = field(default_factory=Counter)
    by_faction: Counter = field(default_factory=Counter)
    ability_hits: Counter = field(default_factory=Counter)
    bool_flags: Counter = field(default_factory=Counter)
    traits: Counter = field(default_factory=Counter)
    slots: Counter = field(default_factory=Counter)
    examples: dict[str, list[str]] = field(default_factory=lambda: defaultdict(list))


def load_pack(path: Path) -> list[dict[str, Any]]:
    with path.open(encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, list):
        raise ValueError(f"Expected array in {path}")
    return data


def card_text(card: dict[str, Any]) -> str:
    parts = [
        card.get("text") or "",
        card.get("back_text") or "",
        card.get("real_text") or "",
    ]
    return "\n".join(p for p in parts if p)


def decode_numeric(value: Any) -> str:
    if value in NUMERIC_SENTINEL:
        return NUMERIC_SENTINEL[value]
    return str(value)


def analyze_pack(path: Path) -> PackStats:
    pack_code = path.stem
    stats = PackStats(pack_code=pack_code, path=path)
    stats.cards = load_pack(path)

    for card in stats.cards:
        t = card.get("type_code") or "?"
        stats.by_type[t] += card.get("quantity", 1)

        st = card.get("subtype_code")
        if st:
            stats.by_subtype[st] += card.get("quantity", 1)

        fc = card.get("faction_code")
        if fc:
            stats.by_faction[fc] += card.get("quantity", 1)

        for flag in ("hidden", "permanent", "victory", "exceptional", "double_sided", "is_unique"):
            if card.get(flag):
                stats.bool_flags[flag] += 1

        slot = card.get("slot")
        if slot:
            stats.slots[slot] += 1

        traits_raw = card.get("traits") or card.get("back_traits") or ""
        for trait in re.split(r"[.\s]+", traits_raw):
            trait = trait.strip()
            if trait:
                stats.traits[trait] += 1

        text = card_text(card)
        for name, pat in ABILITY_PATTERNS.items():
            if pat.search(text):
                stats.ability_hits[name] += 1
                code = card.get("code", "?")
                name_s = card.get("name", "?")
                if len(stats.examples[name]) < 5:
                    stats.examples[name].append(f"{code} {name_s}")

        if card.get("hidden"):
            stats.ability_hits["hidden_flag"] += 1

    return stats


def md_counter(title: str, counter: Counter, limit: int = 40) -> list[str]:
    lines = [f"### {title}", "", "| 项 | 数量 |", "|---|---:|"]
    for key, count in counter.most_common(limit):
        lines.append(f"| `{key}` | {count} |")
    if not counter:
        lines.append("| — | 0 |")
    lines.append("")
    return lines


def render_pack_report(stats: PackStats) -> str:
    lines = [
        f"# Pack 分析：`{stats.pack_code}`",
        "",
        f"源文件：`{stats.path.relative_to(ROOT).as_posix()}`",
        f"卡条目数（含 quantity 展开前）：{len(stats.cards)}",
        "",
    ]
    lines.extend(md_counter("type_code 分布", stats.by_type))
    if stats.by_subtype:
        lines.extend(md_counter("subtype_code 分布", stats.by_subtype))
    if stats.by_faction:
        lines.extend(md_counter("faction_code 分布", stats.by_faction))
    lines.extend(md_counter("布尔字段", stats.bool_flags))
    if stats.slots:
        lines.extend(md_counter("slot（资产槽位）", stats.slots))
    lines.extend(md_counter("卡面文本模式（能力/关键词线索）", stats.ability_hits))

    lines.append("### 样例卡（每类最多 5 张）")
    lines.append("")
    for key in sorted(stats.examples.keys()):
        lines.append(f"- **{key}**：{', '.join(stats.examples[key])}")
    lines.append("")
    return "\n".join(lines)


def render_field_mapping() -> str:
    return """# ArkhamDB → 引擎字段映射（草案）

> 详见 `data/arkhamdb/schema/card_schema.json`。数值哨兵：`-2`=X，`-3"=*，`-4"=?，`null`=-。

| ArkhamDB 字段 | 引擎 / CardRegistry | 说明 |
|---|---|---|
| `code` | `definition_id` / EntityId | 5 位 + 可选后缀；全局唯一 |
| `name` | `title` | 显示名 |
| `type_code` | `card_type` | act/agenda/asset/enemy/event/… → `CardDefinition.card_type` |
| `subtype_code` | `is_weakness` 等 | `basicweakness` / `weakness` → weakness 路由（15 §17.6） |
| `faction_code` | `class` / deckbuilding | 调查员/玩家牌派系 |
| `cost` | `resource_cost` | Initiation L6；注意哨兵值 |
| `slot` | `slots[]` | Hand / Arcane / … |
| `skill_*` / `skill_wild` | `skills_icons` | 技能图标 |
| `health` / `sanity` | ally 血量 | asset 专用 |
| `enemy_*` / `health`+damage | `enemy` stats | 敌人战斗数值 |
| `shroud` / `clues` | location | 地点调查 |
| `doom` / `clues` | act/agenda | 场景卡 |
| `traits` | `traits[]` | 句号分隔 trait 串 |
| `text` | 编译输入 | `[reaction]`/Forced/Revelation → AbilitySpec |
| `hidden` | `keywords: hidden` | 隐私 E4 |
| `victory` | scenario | 胜利点 |
| `permanent` | Domain 关键词 | 非 Buff；Permanent 离场规则 |
| `exceptional` | deckbuilding | 非运行时 |
| `encounter_code` | scenario 分组 | 遭遇套牌 |
| `stage` | act/agenda 序号 | |
| `pack_code` | 数据包归属 | 非运行时 |
| `tags` | 特殊 deckbuilding | hh/hd/pa/se/fa（见 upstream README） |

## 能力文本 → 引擎路由（06 §2 / effect-translation）

| 卡面标记 | AbilityKind / 路由 | Initiation? |
|---|---|---|
| `<b>Revelation</b>` | REVELATION → `seq.enter_hand` / encounter revelation | 否（Forced 直执） |
| `<b>Forced</b>` | FORCED | **否**（自动，不经 Initiation） |
| `[reaction]` / `[action]` / `[fast]` | TRIGGERED_* | **是**（选用后 Initiation） |
| `[action]` on asset | `[action]` + AOO | Initiation + action_cost |
| `[fast]` | Fast 关键词 + 指定 window | Initiation 或 Player Window |
| Spawn – / Prey – | `spawn_instruction` / `prey_instruction` | 否（G4 内联） |
| Surge / Peril / Aloof… | 关键词 LISTENER 或 seq | 见 15 §17 |
"""


def main() -> None:
    REPORTS.mkdir(parents=True, exist_ok=True)
    pack_dir = DATA / "pack"
    pack_files = sorted(pack_dir.rglob("*.json"))
    if not pack_files:
        raise SystemExit(f"No pack JSON under {pack_dir}")

    all_stats: list[PackStats] = []
    for path in pack_files:
        stats = analyze_pack(path)
        all_stats.append(stats)
        report = render_pack_report(stats)
        out = REPORTS / f"{stats.pack_code}_inventory.md"
        out.write_text(report, encoding="utf-8")
        print(f"Wrote {out.relative_to(ROOT)}")

    (REPORTS / "field_mapping.md").write_text(render_field_mapping(), encoding="utf-8")
    print(f"Wrote {REPORTS / 'field_mapping.md'}")

    # design gaps with fixed render
    gaps = render_design_gaps_fixed(all_stats)
    (REPORTS / "core_2026_design_gaps.md").write_text(gaps, encoding="utf-8")
    print(f"Wrote {REPORTS / 'core_2026_design_gaps.md'}")

    summary_lines = [
        "# ArkhamDB 分析摘要",
        "",
        f"分析包：{', '.join(s.pack_code for s in all_stats)}",
        "",
    ]
    for stats in all_stats:
        summary_lines.append(f"- `{stats.pack_code}`：{len(stats.cards)} 条目")
    (REPORTS / "README.md").write_text("\n".join(summary_lines) + "\n", encoding="utf-8")
    print("Done.")


def render_design_gaps_fixed(all_stats: list[PackStats]) -> str:
    merged = Counter()
    examples: dict[str, list[str]] = defaultdict(list)
    for stats in all_stats:
        merged.update(stats.ability_hits)
        for k, v in stats.examples.items():
            for item in v:
                if len(examples[k]) < 8:
                    examples[k].append(item)

    lines = [
        "# Core 2026 → 设计表回填线索",
        "",
        "基于 `data/arkhamdb/pack/core/*.json` 自动统计。",
        "",
        "## 1. 关键词 / seq（15 §17 · 06 §16.2）",
        "",
        "| 模式 | 命中 | 引擎路由 | 样例 |",
        "|---|---:|---|---|",
    ]
    routing = {
        "surge_text": "Surge 链 · seq.draw.encounter",
        "peril_text": "peril Register · REST E3",
        "hidden_flag": "隐私 E4 · FORBID_LEAVE_HAND",
        "hidden_text": "隐私（文本）",
        "aloof_text": "FORBID_ATTACK / engage 条件",
        "hunter_text": "Hunter listener",
        "retaliate_text": "Retaliate handler",
        "massive_text": "engage 拒绝",
        "spawn_line": "SpawnInstructionSpec",
        "prey_line": "PreyInstructionSpec",
        "patrol_paren": "PatrolTargetSpec",
    }
    for key, route in routing.items():
        count = merged.get(key, 0)
        ex = ", ".join(examples.get(key, [])[:3]) or "—"
        lines.append(f"| `{key}` | {count} | {route} | {ex} |")

    lines += [
        "",
        "## 2. 能力类型（06 §2）",
        "",
        "| 模式 | 命中 | 管线 |",
        "|---|---:|---|",
    ]
    for key, route in [
        ("revelation_bold", "REVELATION"),
        ("forced_bold", "FORCED · 不经 Initiation"),
        ("reaction", "TRIGGERED_REACTION · Initiation"),
        ("action", "TRIGGERED_ACTION · Initiation+AOO"),
        ("fast", "Fast / Player Window"),
        ("elder_sign", "Elder Sign · ST 子流程"),
        ("limit_once", "LimitSpec · L5"),
    ]:
        lines.append(f"| `{key}` | {merged.get(key, 0)} | {route} |")

    lines += [
        "",
        "## 3. RESTRICTION 线索（06 §16.4.2）",
        "",
        "| 模式 | 命中 | 备注 |",
        "|---|---:|---|",
        f"| `cannot` | {merged.get('cannot', 0)} | 需 NLP/人工细分为 FORBID_* |",
        f"| `immune` | {merged.get('immune', 0)} | EffectGraph step 4 |",
        "",
        "## 4. MODIFIER 查询站需求（06 §16.3）",
        "",
        "Core 2026 卡面含大量 `+N [skill]`、`+N damage`、`-N cost` 类文本；需在编译期映射到",
        "`StatRef` 增长表（SKILL 已实现，SHROUD/DAMAGE/HORROR/COST 待 enum）。",
        "",
        "## 5. 待人工译码优先队列（建议）",
        "",
        "1. 全部 `<b>Revelation</b>` treachery（遭遇管线 ENT/ENC）",
        "2. `[reaction]` / `[action]` 资产（TriggeredAbilityService + Initiation）",
        "3. Spawn/Prey 敌人",
        "4. Hidden / Surge / Peril 关键词遭遇",
        "5. Agenda/Act `forced` 场景能力（场景脚本，非卡牌 Initiation）",
        "",
    ]
    return "\n".join(lines)


if __name__ == "__main__":
    main()
