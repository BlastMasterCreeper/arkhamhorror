# Core 2026 · Gained characteristics 统计

数据源：`data/arkhamdb/imported/core_2026*.json`。
设计总纲：[06 §3.2](../../docs/design/06-registration-buff-model.md#32-gained-characteristics动态特征--总纲--已裁决)。

卡牌数：**166**（两包合计）。

## 1. Characteristic 模式（Grimoire *gains a characteristic*）

| 模式 | 命中 | Kind | 路由 | 卡清单 |
|---|---:|---|---|---|
| `keyword_surge` | 3 | KEYWORD | WHILE_DRAWN_CARD_RESOLVING · §06 3.1 | 12124 Cosmic Evils; 12126 Forbidden Secrets; 12160 Raising Suspicions |
| `keyword_other` | 0 | KEYWORD | 按 keyword consumer · P2 | — |
| `ability_action` | 0 | ABILITY | LISTENER + AbilitySpec · P1 | — |
| `ability_forced` | 0 | ABILITY | LISTENER · Forced 文本 | — |
| `trait` | 0 | TRAIT | TRAIT 标记 · P2 | — |
| `icon` | 0 | ICON | MODIFIER / ICON · THIS_SKILL_TEST | — |
| `until_eot_ability` | 0 | ABILITY | DURATION(THIS_TURN) · P1 | — |
| `deckbuilding_meta` | 1 | META | 构筑元数据 · 非运行时 characteristic | 12181 Collector |

## 2. 非 characteristic（勿误入 Gained 层）

| 模式 | 命中 | 路由 | 卡清单 |
|---|---:|---|---|
| `gain_resources` | 9 | L0 资源原语 | 12004 Joe Diamond; 12005 Detective's Intuition; 12018 Logan Hastings; 12030 Dorothy Simmons; 12048 Sticky Fingers; 12054 Sticky Fingers; 12055 Decisive Strike; 12145 Downtown … +1 more |
| `gain_action` | 0 | L0 行动原语 | — |

## 3. 实现优先级（Core 2026）

| 优先级 | 内容 | 卡例 |
|---|---|---|
| **P0** | `has_effective_keyword` + Surge KEYWORD Register | 12124, 12126, 12160 |
| **P1** | until EOT + `[action]` / `[reaction]`（扩展包为主） | Core 2026：**0** |
| **P2** | trait / icon / 其它 keyword gains | Core 2026：**0** |
| — | Deckbuilding Options gains | 12181 Collector（META） |
