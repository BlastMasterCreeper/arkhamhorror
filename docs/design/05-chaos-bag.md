# 05 — 混沌袋与场景参考 (ChaosBagSystem)

> **依赖**：[01-game-state-zones.md](01-game-state-zones.md), [04-skill-test-engine.md](04-skill-test-engine.md)  
> **规则来源**：Grimoire Chaos Tokens (p.7), Scenario Reference Card

---

## 1. 目标

管理 **Chaos Bag** 组成、揭示/归还、符号效果解析，并与 **Scenario Reference Card** 及 Investigator Elder Sign 绑定。

---

## 2. 数据结构

### 2.1 ChaosToken

```gdscript
enum ChaosTokenKind {
    NUMERIC,           # +1, -1, -2, ...
    SKULL,
    CULTIST,
    TABLET,
    ELDER_THING,
    ELDER_SIGN,
    AUTO_FAIL,
    BLESS,             # 扩展预留
    CURSE,
    FROST,
    CAMPAIGN_CUSTOM,
}

class ChaosToken:
    var kind: ChaosTokenKind
    var modifier: int                 # numeric 部分；符号可能 + 文本 modifier
    var campaign_symbol_id: StringName
    var sealed: bool                  # 扩展：封印不揭示
    var instance_id: StringName
```

### 2.2 ChaosBag

```gdscript
class ChaosBag:
    var tokens: Array[ChaosToken]
    var revealed_this_test: Array[ChaosToken]

    func shuffle() -> void
    func draw_random() -> ChaosToken
    func return_token(t: ChaosToken) -> void
    func return_all_revealed() -> void
    func add_token(t: ChaosToken) -> void
    func remove_token(t: ChaosToken) -> void
```

### 2.3 ScenarioReferenceDefinition

```gdscript
class ScenarioReferenceDefinition:
    var scenario_id: StringName
    var difficulty: Difficulty          # EASY_STANDARD | HARD_EXPERT
    var symbol_effects: Dictionary[ChaosTokenKind, AbilityDefinition]
    # 例：SKULL → "–X. X is current act number."
```

---

## 3. ChaosBagSystem API

```gdscript
class ChaosBagSystem:
    var bag: ChaosBag
    var reference: ScenarioReferenceDefinition

    func build_from_difficulty(scenario_id, difficulty) -> void
    func apply_campaign_modifiers(log: CampaignLog) -> void   # 战役间 bag 变化
    func reveal_for_skill_test(ctx: SkillTestContext) -> ChaosToken
    func resolve_symbol_effect(token: ChaosToken, ctx: SkillTestContext) -> void
    func get_elder_sign_effect(investigator_id: StringName) -> AbilityDefinition
    func persist_to_campaign() -> ChaosBagSnapshot
    func restore_from_campaign(snapshot: ChaosBagSnapshot) -> void
```

---

## 4. 揭示流程（与 ST.3–ST.4 协作）

```
ST.3: token = bag.draw_random()
      ctx.revealed_tokens.append(token)
ST.4: match token.kind:
        SKULL/CULTIST/... → reference.symbol_effects[kind].execute(ctx)
          · modifier 部分 → 写入 ctx（ST.5 重算）
          · 「fail by X+ …」类文本 → 注册 ST.7 fail 回调（**不在 ST.4 执行**，见 OQ-05-03）
        ELDER_SIGN → investigator.elder_sign_ability.execute(ctx)
        AUTO_FAIL → ctx.auto_fail = true
        NUMERIC → 仅 modifier
        CAMPAIGN_CUSTOM → ScenarioScript.resolve_chaos_symbol(id, ctx)
      若文本 "Reveal another token" → 递归 ST.3→ST.4（不回 ST.2；递归中无 Player Window；见 04 §3.4 OQ-04-01）
      整链结束后 → PW_SKILL_TEST_AFTER_REVEAL → ST.5
```

---

## 5. Modifier 与 Fail by 效果

| 类型 | 时点 | 示例 |
|---|---|---|
| **Modifier** | ST.4 注册 → ST.5 重算 | Skull `–X` |
| **Fail by 条件后果** | **ST.7**（作为失败效果的一部分） | Spreading Flames Skull「fail by 2+ draw Fire!」 |
| Reveal another token | ST.4 内递归 ST.3 | — |

- ST.6 仅判定 success/fail 并计算 `fail_by = difficulty - modified`
- ST.7 读取 `fail_by`，执行已注册的 fail by 条件效果
- Ignore chaos token：token 算已 draw 但 modifier/effect 不应用（Grimoire Ignore）

---

## 6. 战役持久化

Grimoire Setup 6：

- 战役第一场按 guide 组装 bag
- 后续场景使用**上一场结束时**的 bag 组成
- Epic/新 campaign transfer 时 reset bag

```gdscript
class ChaosBagSnapshot:
    var token_counts: Dictionary       # kind → count
    var custom_tokens: Array[ChaosToken]
    var sealed_tokens: Array[ChaosToken]
```

存入 `CampaignState`，非 `GameStateStore`（跨 scenario）。

---

## 7. Scenario Reference 数据化 vs 脚本

**推荐混合**：

| 内容 | 方式 |
|---|---|
| Core 2026 各场景 Skull/Cultist/... 标准效果 | `ScenarioReferenceDefinition` JSON |
| Spreading Flames「draw Fire! from discard」 | `ScenarioScript.on_chaos_symbol` override |
| Act 数动态 X | Expression：`X = current_act_number` |

```gdscript
# data/packs/core_2026/scenarios/spreading_flames_reference.tres
# symbol_effects[SKULL] = "-X. X is the current act number."
# symbol_effects[SKULL].on_fail_by = { threshold: 2, effect: draw_fire_from_discard }  # ST.7 执行
```

---

## 8. Elder Sign

- 揭示 [elder_sign] token 时触发 performing investigator 卡上 printed **Elder Sign** 能力
- 通常含 modifier + conditional effect（如 Joe Diamond：+1, succeed → draw + resource）

绑定：`InvestigatorDefinition.elder_sign_ability_id`

---

## 9. 扩展预留

| 机制 | 接口 |
|---|---|
| Seal token | `bag.seal(token)` |
| Bless/Curse | 额外 token kind |
| Pull from bag without test | `bag.draw_random()` + manual return |
| Empty bag | 不应发生；若 token 被 remove 至 0 → 错误日志 |

---

## 10. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| C-01 | Standard difficulty Spreading Flames bag | 与 guide 一致 |
| C-02 | Skull –X, act 2 | X=2 |
| C-03 | Auto-fail | test fail |
| C-04 | Elder Sign Joe | +1; succeed 分支 |
| C-05 | ST.8 return token | bag count 恢复 |
| C-06 | 战役 scenario 2 继承 bag | snapshot restore |

---

## 11. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-05-01 | P1 | 2026 Core 各场景 reference **全部 JSON 化** vs 部分 `ScenarioScript` — 你的偏好？ |
| OQ-05-02 | P1 | Campaign-specific symbol（guide 指引）插件接口：`CampaignScript` 还是 `ScenarioScript`？ |
| OQ-05-04 | P2 | Bless/Curse 在 Core 2026 是否需实现还是仅预留 enum？ |
| OQ-05-05 | P1 | Ignore vs Cancel chaos token 在 bag 中 token 是否仍算「revealed this test」？ |
| OQ-05-06 | P2 | 多 difficulty 切换 standalone：bag 是否在 setup 完全 rebuild？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-05-03 | **Fail by 条件效果在 ST.7 结算**（作为失败效果的一部分）。ST.6 仅判定 fail 并计算 `fail_by` 数值。见 §5。 | 2026-05-25 |

---

## 12. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-05-03 裁决：fail by 效果在 ST.7 结算 |
