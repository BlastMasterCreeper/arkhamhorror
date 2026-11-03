#!/usr/bin/env python3
"""Unit tests for limit_compile / ArkhamDB Limit attachment."""

from __future__ import annotations

import unittest

from arkhamdb_abilities import compile_card_abilities
from limit_compile import collect_card_limits, extract_clauses, try_parse_clause


class LimitCompileTests(unittest.TestCase):
    def test_parse_group_once_per_round(self) -> None:
        spec = try_parse_clause("(Group limit once per round.)")
        assert spec is not None
        self.assertEqual(spec["kind"], "INITIATE_QUOTA")
        self.assertEqual(spec["audience"], "GROUP")
        self.assertEqual(spec["period"], "ROUND")

    def test_parse_limit_per_investigator(self) -> None:
        spec = try_parse_clause("Limit 1 per investigator.")
        assert spec is not None
        self.assertEqual(spec["kind"], "ZONE_OCCUPANCY")
        self.assertEqual(spec["zone"], "PER_INVESTIGATOR")

    def test_parse_max_committed(self) -> None:
        spec = try_parse_clause("Max 1 committed per skill test")
        assert spec is not None
        self.assertEqual(spec["kind"], "COMMIT_MAX")

    def test_sticky_fingers_card_limits(self) -> None:
        text = (
            "Limit 1 per investigator.\n"
            "[reaction] After you successfully evade an enemy, exhaust Sticky Fingers: "
            "Gain 1 resource."
        )
        card_limits = collect_card_limits(text)
        self.assertEqual(len(card_limits), 1)
        self.assertEqual(card_limits[0]["zone"], "PER_INVESTIGATOR")
        _segs, compiled, card2 = compile_card_abilities(text)
        self.assertEqual(card2, card_limits)
        self.assertTrue(compiled)

    def test_dormitories_ability_limit(self) -> None:
        text = "[action]: Heal 1 damage and 1 horror. (Limit once per game.)"
        _segs, compiled, card_limits = compile_card_abilities(text)
        self.assertEqual(card_limits, [])
        self.assertEqual(len(compiled), 1)
        limits = compiled[0].get("limits", [])
        self.assertEqual(len(limits), 1)
        self.assertEqual(limits[0]["period"], "GAME")
        self.assertEqual(limits[0]["kind"], "INITIATE_QUOTA")
        ## heal 1 damage + 1 horror → seq 仍可 partial；limit 已挂即达标。
        self.assertIn("limits", compiled[0])

    def test_miskatonic_quad_group_limit(self) -> None:
        text = (
            "[fast] During your turn, if there are exactly 1 or 2 investigators "
            "in the game: Move to a connecting location. (Group limit once per round.)"
        )
        _segs, compiled, _card = compile_card_abilities(text)
        self.assertEqual(len(compiled), 1)
        limits = compiled[0].get("limits", [])
        self.assertEqual(len(limits), 1)
        self.assertEqual(limits[0]["audience"], "GROUP")

    def test_out_of_sight_commit_max(self) -> None:
        text = (
            "Max 1 committed per skill test.\n"
            "If this test is successful by 2 or more, draw 1 card."
        )
        card_limits = collect_card_limits(text)
        self.assertEqual(len(card_limits), 1)
        self.assertEqual(card_limits[0]["kind"], "COMMIT_MAX")

    def test_extract_multiple(self) -> None:
        text = "Limit 1 per investigator. (Limit once per round.)"
        specs = extract_clauses(text)
        kinds = {s["kind"] for s in specs}
        self.assertIn("ZONE_OCCUPANCY", kinds)
        self.assertIn("INITIATE_QUOTA", kinds)


if __name__ == "__main__":
    unittest.main()
