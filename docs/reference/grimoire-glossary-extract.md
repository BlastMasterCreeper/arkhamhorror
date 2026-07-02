# Arkham Grimoire v1.0 — Glossary Extract (Markdown)

> **来源**：[`arkham-grimoire-v1.0.pdf`](arkham-grimoire-v1.0.pdf)（2026 Core Set）  
> **符号**：[`arkham-symbol-notation.md`](arkham-symbol-notation.md)（`[reaction]` 等）  
> **全文检索**：[`arkham-grimoire-v1.0.md`](arkham-grimoire-v1.0.md)（`## Page 9–10`）· 对照 [`arkhamdb-rules-reference.md`](arkhamdb-rules-reference.md)（`## Drawing Cards`）  
> **用途**：引擎设计 / 实现对照的**策展摘录**；权威措辞仍以 Grimoire PDF 为准。

---

## Drawing Cards（PDF p.9–10）

When a player is instructed to draw one or more cards, those cards are drawn from the top of their investigator deck and added to their hand.

When a player is instructed to draw one or more encounter cards, those cards are drawn from the top of the encounter deck, and resolved following the rules for drawing encounter cards under framework step 1.4, “Each investigator draws 1 encounter card.” on page 27.

- When a player draws two or more cards as the result of a **single ability or game step**, those cards are drawn **simultaneously**. If multiple weaknesses or encounter cards are drawn this way, their effects are resolved **in the order that they entered that player's hand**. If a deck empties mid-draw, reset the deck and complete the draw.
- There is no limit to the number of cards a player may draw each round.
- If an investigator with an empty deck needs to draw 1 or more cards, that investigator immediately shuffles their discard pile back into their deck, then draws the card and takes one horror.
  - Drawing the card and taking the horror occur **simultaneously**.
  - If an investigator would draw from an empty deck and has no cards in their discard pile, that investigator is immediately defeated and suffers 1 mental trauma.

### 引擎映射（草案）

| 规则 | 引擎含义 |
|---|---|
| `draw one or more` = **一条指令** | `DrawInstruction { amount, source }`；不是 N 次独立 triggering condition |
| 单次 ability / game step 抽 ≥2 张 | **`SimultaneousEffectGroup`**：牌库顶 → 手牌 **同时** 完成；见 [01 §5.3](../design/01-game-state-zones.md) |
| 多张带 Revelation 的牌 | 全部入手后，按 **进入手牌顺序** 依次 nest / resolve（Grimoire p.10；与是否为 weakness 无关） |
| 抽牌中牌库空 | shuffle discard → deck，**与** horror（若适用）**同时**；然后 **完成本次 draw**（非终止整批） |
| Draw **行动** | 见 **Draw Action**（每次仅 1 张）；与「指令抽 N 张」区分 |

---

## Draw Action（PDF p.9）

“Draw” is an action an investigator may take during their turn in the investigation phase.

When an investigator takes this action, that investigator draws **one** card from their deck.

- Taking a draw action provokes attacks of opportunity.

---

## Effects — timing priority（PDF p.10，摘录）

- All aspects of an effect have timing priority over all “after...” triggering conditions that might arise as a consequence of that effect. For example, if an effect reads “Gain 3 resources and draw 3 cards,” resolve both aspects of the effect (gaining resources and drawing cards) before initiating an ability that reads “After drawing a card...”

---

## 隐私 Hidden（Grimoire p.14 · Dream-Eaters FAQ）

**中文裁定名**：**隐私**（英文关键词 `Hidden`）。

> Hidden cards have Revelation abilities that secretly add them to an investigator's hand. This should be done without revealing that card or its text to the other investigators.

**引擎映射**：

| 规则 | 引擎 |
|---|---|
| 显现秘密入手 | E4 · `commit_hidden_enter_hand` · `is_hidden=true` |
| 计入手牌上限 | Domain · `inv.hand` |
| **除卡面能力外不得离手** | E4 Register `FORBID_LEAVE_HAND` · `move_card` 查 Restrictions；G4 skip 为 Framework 优化 |
| 隐私 treachery 视为威胁区 | Eligibility 模拟；zone 仍为 HAND |
| 隐私 enemy 不进威胁区 | G4 skip spawn；`expose_hidden` → `spawn_encounter_enemy` |
| 弃置 → 遭遇弃牌堆 | `move_card` → encounter discard |
| 淘汰时手牌隐私牌 | `InvestigatorElimination` → encounter discard · FAQ 1.22 |

详述：[15 §17.4.3](../design/15-timing-entry-catalog.md) · [01 §3.6.2](../design/01-game-state-zones.md)

---

## 待增补条目（引擎常查）

- [ ] When / After / Triggering Condition（p.4–5, p.23–25）
- [ ] Then / Priority of Simultaneous Resolution（p.19–22）
- [ ] Initiation Sequence（p.31）
- [ ] Framework 1.4 encounter draw（p.27）
- [ ] Skill Test Timing ST.1–ST.8（p.30）
