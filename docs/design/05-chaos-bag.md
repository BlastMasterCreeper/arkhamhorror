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
    var revealed_this_test: Array[ChaosToken]   # 物理工作区
    var reveal_ledger: Array[ChaosRevealRecord] # 本 scope 账本
    var reveal_scope_id: StringName

    func begin_reveal_scope(scope_id) / end_reveal_scope()
    func shuffle() -> void
    func draw_random(source := &"skill_test") -> ChaosToken
    func reveal_for_ability(amount) -> Array[ChaosToken]
    func finalize_ability_reveal(tokens) -> void  # 回袋；账本保留
    func cancel_reveal(token) -> void
    func has_uncanceled_kind(kind) / count_uncanceled_kind(kind)
    func return_token(t: ChaosToken) -> void
    func return_all_revealed() -> void
    func add_token(t: ChaosToken) -> void
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
ST.1 begin → bag.begin_reveal_scope(test_id)
ST.3: token = bag.draw_random(source=skill_test)
      ctx.revealed_tokens.append(token)   # 物理工作区 + 账本
ST.4: match token.kind: …（符号效果；reveal another → 再 ST.3）
整链结束 → PW_SKILL_TEST_AFTER_REVEAL（窗内能力揭示写入同一账本）
         → ST.4 后门槛 resolve_post_st4_if_revealed_gate（只读账本）
         → ST.5 …
ST.8 → return_all_revealed + end_reveal_scope
```

### 4.1 检定揭示账本（已裁决 · 引擎标准）

| 概念 | 含义 |
|---|---|
| **物理工作区** `revealed_this_test` | 尚未归袋；ST.8 清空 |
| **揭示账本** `reveal_ledger` | 本 scope 每次揭示一行；可已归袋；整枚 Cancel → `canceled` |
| **ST.4 后门槛** | *If … is revealed* 延时不在每个 ST.3 开火；PW_AFTER_REVEAL 关闭后查账本（binary / for-each） |

**能力揭示 disposition**：`reveal_for_ability` → 帧末 `finalize_ability_reveal` 必须回袋（账本保留）。禁止悬置。

**Cancel**：整枚 Cancel → 门槛不算揭示过。Ignore 是否剔除账本见 OQ-05-05。

---

## 5. Modifier 与 Fail by 效果

| 类型 | 时点 | 示例 |
|---|---|---|
| **modifier** | ST.4 注册 → ST.5 重算 | Skull `-X` |
| **Fail by 条件后果** | **ST.7** | Spreading Flames Skull |
| Reveal another token | ST.4 内递归 ST.3 | — |
| ***If … is revealed* 延时** | **ST.4 后门槛**（查账本） | 混乱之眼 0 binary；4 级 for-each |

- ST.6 仅判定 success/fail 并计算 `fail_by`
- ST.7 执行已注册 fail by 后果
- Ignore：modifier/effect 不施加；是否仍入未取消账本待 OQ-05-05

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
| Pull from bag without test / 能力揭示 | `reveal_for_ability` + **强制** `finalize_ability_reveal` |
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
| BAG-LEDGER-01 | 检定揭示入账本；ST.8 清空 scope | 物理堆空；ledger 空 |
| BAG-LEDGER-02 | 能力揭示 curse → finalize 归袋 → ST.4 后 binary | 门槛一次；袋守恒 |
| BAG-LEDGER-03 | Cancel 后门槛看不到 | `has_uncanceled_kind` false |
| BAG-LEDGER-04 | mode=each × N curse | 回调 N 次 |

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
| OQ-05-07 | **检定揭示账本 + ST.4 后门槛**：*If … is revealed* 延时查阅 `reveal_ledger`（未 Cancel）；能力揭示帧末必须归袋。见 §4.1。 | 2026-10-17 |

---

## 12. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-05-03 裁决：fail by 效果在 ST.7 结算 |
| 2026-10-17 | v0.3 | §4.1 揭示账本；ST.4 后 *If revealed* 门槛；能力揭示强制归袋（OQ-05-07） |
