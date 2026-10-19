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
    func cancel_reveal(token) -> void   # 从未抽到
    func ignore_reveal(token) -> void   # 仍揭示，不 resolve
    func has_revealed_kind / count_revealed_kind / revealed_records   # 未 Cancel（含 Ignore）
    func has_resolved_kind / count_resolved_kind / resolved_records   # 未 Cancel 且未 Ignore
    func has_uncanceled_kind / count_uncanceled_kind                 # = revealed_*（兼容别名）
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

### 4.0 隐式符号能力（已裁决 · OQ-04-07）

ST.3/ST.4 **融合**为一条链：揭示产出 token → **发起隐式符号能力**（modifier + 效果）。能力源 = 冒险参考卡 / 调查员 Elder Sign / 规则 Auto-fail / 剧本自定义。Cancel·Ignore·Instead·空白 的回溯对象即「这一次揭示」或「这一次符号能力」。详见 [04 §3.3–3.4](04-skill-test-engine.md)。

```
ST.1 begin → bag.begin_reveal_scope(test_id)
ST.3: ChaosRevealIntentPlanner.plan_and_reveal（见 §4.2）
      → 同时离袋；resolved 入 ctx.revealed_tokens；其余 → ignore_reveal
      → **紧贴** notify_resolved → if_revealed_watchers（早于 ST.4）
ST.4: 对每枚 resolved **发起隐式符号能力**；任一 reveal another → 再 nest ST.3→能力
整链结束 → PW_SKILL_TEST_AFTER_REVEAL（窗内 Rod 式揭示：finalize 时同样 notify）
         → ST.5 …
ST.8 → return_all_revealed + end_reveal_scope
```

### 4.1 检定揭示账本（已裁决 · 引擎标准）

| 概念 | 含义 |
|---|---|
| **物理工作区** `revealed_this_test` | 尚未归袋；ST.8 清空 |
| **揭示账本** `reveal_ledger` | 本 scope 每次揭示一行；可已归袋；审计 / Cancel·Ignore |
| ***If … is revealed*** | **紧贴 resolved 结算**触发（非固定时点再读账本）；见 §4.1.2 |

**能力揭示 disposition**：`reveal_for_ability` →（可选 Cancel/Ignore）→ `finalize_ability_reveal` 归袋并 **notify resolved**。禁止悬置。

### 4.1.1 Cancel vs Ignore（已裁决 · OQ-05-05）

Grimoire *Ignore*：*cancelled* chaos token = never drawn；*ignored* = still drawn，但 modifier/effects 不 resolve。

| | Cancel（`canceled`） | Ignore（`ignored`） |
|---|---|---|
| 曾抽到 / 账本「曾揭示」 | **否** | **是** |
| ST.4 符号 / ST.5 修饰 | 否 | 否 |
| *If revealed*（FAQ 2.5 / resolved 观察者） | 否 | **否** |
| 「每枚揭示」反应计数（Candles 式听揭示） | 否 | **是**（`revealed_*`） |

API：`ignore_reveal` ≠ `cancel_reveal`。Olive「ignore the other」走 Ignore。

### 4.1.2 *If … is revealed* 紧贴揭示（已裁决 · 修订 OQ-05-07）

不再在 PW_AFTER_REVEAL 关闭后统一扫账本。观察者挂在 `SkillTestContext.if_revealed_watchers`；**disposition 定案为 resolved 的当下**由 `ChaosBag.on_resolved_reveal` / `notify_resolved_tokens` 驱动：

| 生产者 | 定案点 | 相对符号能力 |
|---|---|---|
| ST.3 检定揭示 | `plan_and_reveal` 后 `notify_resolved_tokens` | **早于**本批 ST.4（皱缩术 FAQ） |
| Rod / `reveal_for_ability` | `finalize_ability_reveal`（仍 resolved 时） | 无该枚的 ST.4；在 finalize 当下 |

| mode | 语义 |
|---|---|
| `any`（默认） | **自肃**：本检定该观察者至多一次（`fired` latch）；不因多枚 / Rod+ST.3 连发 |
| `each` | **for-each**：每枚匹配的 resolved 触发一次，**不自肃** |

匹配可用单 `kind` 或 `kinds[]`（皱缩术符号表）共享同一 latch（仅 `any`）。账本仍保留供审计与 Ignore/Cancel 查询。

### 4.2 多能力「将要揭示」替换（已裁决 · OQ-04-05）

FAQ：Olive + Grotesque Statue 等同时替换「揭示 1 枚」时，**先声明意图再抽**；全部物理标记 **同时** 离袋 = **一次** ST.3 手续（载荷可多枚），不是 N 次 ST.3。

| 步 | PI / 运算 | 入口 |
|---|---|---|
| 1 能力次序 | 队长 `ORDER_SIMULTANEOUS` | `chaos:reveal_replace_order` |
| 2 作用槽 | 控制者对**当前预期叶** `PICK_OPTION` | `chaos:reveal_replace_target:<ability_id>` |
| 3 展开 | 1 叶 → `reveal_count` 叶（`ChaosRevealReplaceAbility`） | 意图树，尚未离袋 |
| 4 同时揭示 | 每叶 `draw_random` | 账本多行；手续仍一次 |
| 5 结算子集 | 控制者 `CHAOS_PICK`（`resolve_count`） | `chaos:resolve_pick:<ability_id>` |

挂载：`SkillTestContext.pending_reveal_replace` → ST.3 消费。无挂载时 `base_expected=1` 等价单抽。

**卡面接线**（本线已收口）：

| 构件 | 落点 |
|---|---|
| 入口 | `seq.chaos.reveal`（ST.3）：WHEN 窗 → 反应挂 pending；RESOLVE → 意图规划并离袋 |
| 反应匹配 | `match_kind=reveal_chaos_token` |
| 效果体 | `spend_use` → `chaos_reveal_replace` →（可选）`after_reveal_if_resolved_symbol` |
| Uses Domain | 进场 `ZoneMoveFlow` 按 `uses` / 正文 `Uses (N type)` 放 typed token；离场清空 |
| 符号后果 | 反应体在 WHEN 排队；批 resolve 后若任一 resolved 为符号 → 解释钩子（Mask：take horror） |
| Olive 式 | 编译 `Reveal N … instead of 1, choose M` → 同核 `chaos_reveal_replace`（Core 无 Olive 卡，pattern 已备） |

竖切：**Mask of Silenus（12068）** — 编译 `status=full`（三步）。

**不是** Framework Player Window（OQ-04-01 仍成立）；PI 在揭示手续内经由 `PlayerInteractionGate`。

**已开线**：冒险参考卡 JSON（OQ-05-01 · Spreading Flames 竖切）。仍范围外：OQ-05-02 战役符号脚本、Bless/Curse、Premonition / seal。**不是缺口**：整次检定 Cancel——发动后不存在（[04 §3.0](04-skill-test-engine.md) · OQ-04-04）。

---

## 5. Modifier 与 Fail by 效果

| 类型 | 时点 | 示例 |
|---|---|---|
| **modifier** | ST.4 注册 → ST.5 重算 | Skull `-X` |
| **Fail by 条件后果** | **ST.7** | Spreading Flames Skull |
| Reveal another token | ST.4 内递归 ST.3 | — |
| ***If … is revealed*** | **紧贴 resolved**；`any` 自肃 / `each` 不自肃（§4.1.2） | Recall / 皱缩术；混乱之眼 for-each |

- ST.6 仅判定 success/fail 并计算 `fail_by`
- ST.7 执行已注册 fail by 后果
- Ignore：modifier/effect 不施加；账本仍「曾揭示」、不入 resolved（OQ-05-05）

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

## 7. 冒险参考卡（Scenario Reference）数据化 vs 脚本

**已落地（混合 · JSON-first）**：

| 内容 | 方式 |
|---|---|
| Core 2026 各冒险 Skull/Cultist/... 标准效果 | `data/scenarios/<id>/reference.json` → `ScenarioReferenceDefinition` |
| Spreading Flames「draw Fire! from discard」 | JSON `on_fail` / `on_fail_by` → Composition 模板 |
| Act 数动态 X | modifier expr：`neg_act` / `neg_act_plus_1` |
| 战役自定义符号 | 预留 `ScenarioScript` / `CampaignScript`（OQ-05-02） |

竖切：Spreading Flames（12105）；`ScenarioReferenceBinder` → 卡上 `symbol_abilities`；ST.4 `ScenarioReferenceApplier` 发起；`text_box_blank` 跳过印刷条（OQ-04-07）。

```json
# data/scenarios/spreading_flames/reference.json
# "skull": { "modifier": { "expr": "neg_act" } }
# "elder_thing": { "modifier": -3, "on_fail_by": { "threshold": 2, "body": { "template": "lead_draw_..." } } }
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
| BAG-LEDGER-02 | 能力揭示 curse → finalize 即 binary | finalize 时一次；链后不连发；袋守恒 |
| BAG-LEDGER-03 | Cancel 后 if_revealed 不开火 | `has_uncanceled_kind` false |
| BAG-LEDGER-04 | `any` 自肃：Rod×2 + ST.3 再 curse | fires=1 |
| BAG-LEDGER-04b | `each`：Rod×2 curse | fires=2（不自肃） |
| BAG-LEDGER-05 | ST.3 curse → eager 在 ST_3；窗后不连发 | `at_step==ST_3`；fires=1 |
| BAG-INTENT-01 | 无替换体 | 单叶；等同单抽 |
| BAG-INTENT-02 | Olive 揭 3 解 2 | leaf=3；resolved=2；ignored=1 |
| BAG-INTENT-03 | Olive→Statue 次序 + 槽 | 先 ORDER 再 target；leaf=4 |
| BAG-INTENT-04 | Statue→Olive 次序 | Olive 的 3 叶挂在 Statue 未忽略槽上 |
| BAG-INTENT-05 | ST.3 多 resolved 修饰累加 | ST.4 扫本批全部 resolved |
| BAG-IGNORE-01 | Olive ignore ≠ cancel | revealed=3；resolved=2；if_revealed 只见 resolved |
| BAG-IGNORE-02 | Cancel 排除 revealed 与 resolved | 两者皆无 |
| BAG-IGNORE-03 | Ignore 后 finalize 不触发 if_revealed | fires=0；revealed 仍可见 |
| BAG-WIRE-01 | 编译 12068 | WHEN + full 三步（spend / replace / symbol horror）+ Uses |
| BAG-WIRE-02 | 12068 竖切 · 数字 | Uses 进场 3；揭 2 解 1；扣 charge；无 horror |
| BAG-WIRE-03 | 12068 竖切 · 符号 | resolved 符号 → take 1 horror |
| BAG-USES-01 | Uses Domain | 进场放 charges；离场清空 |
| REF-01 | SF 加载 reference JSON | easy/hard skull expr |
| REF-02 | SF skull –act | act=2 → modifier -2 |
| REF-03 | SF tablet | -1 + reveal_another；fail → +1 damage |
| REF-04 | SF elder_thing fail-by | fail_by≥2 → 抽 Fire! |
| REF-05 | SF hard skull | -(act+1) |
| SHRIV-01 | 编译 skill_test.if_revealed 皱缩术 kinds | specs×1 · kinds=5 |
| SHRIV-02 | skull → take horror @ ST.3 早于 ST.4 | horror 先；modifier 后 |
| SHRIV-03 | 两枚 skull + any 自肃 | horror 只 +2 一次 |
| CF-01 | 12059 编译 if_revealed skull | action fight + if_else source_has_use |
| CF-02 | 12059 揭 skull 扣 charge | 3→2 |
| CF-03 | 12059 无 charge 揭 skull | +1 damage + discard |

---

## 11. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-05-01 | P1 | ~~冒险参考卡全部 JSON vs ScenarioScript？~~ → **JSON-first**（SF 竖切）；脚本预留。见 §7。 |
| OQ-04-07 | P1 | ~~ST.3/ST.4 与符号文本如何统一？~~ → **隐式符号能力**融合；见 §4.0 / [04 §3.3–3.4](04-skill-test-engine.md)。 |
| OQ-05-02 | P1 | Campaign-specific symbol（guide 指引）插件接口：`CampaignScript` 还是 `ScenarioScript`？ |
| OQ-05-04 | P2 | Bless/Curse 在 Core 2026 是否需实现还是仅预留 enum？ |
| OQ-05-05 | P1 | ~~Ignore vs Cancel chaos token 是否仍算「revealed this test」？~~ → **已裁决** 见 §4.1.1 |
| OQ-05-06 | P2 | 多 difficulty 切换 standalone：bag 是否在 setup 完全 rebuild？ |

### 已裁决

| ID | 裁决 | 日期 |
|---|---|---|
| OQ-05-03 | **Fail by 条件效果在 ST.7 结算**（作为失败效果的一部分）。ST.6 仅判定 fail 并计算 `fail_by` 数值。见 §5。 | 2026-05-25 |
| OQ-05-07 | **检定揭示账本 + 紧贴揭示**：*If … is revealed* 在 resolved 定案时触发；`any` 自肃一次、`each` 不自肃；**不再**固定时点扫账本。能力揭示帧末必须归袋并 notify。见 §4.1 / §4.1.2。 | 2026-10-19 |
| OQ-04-05 | **多 token 同时揭示 = 一次 ST.3 + 意图规划**（次序 / 预期槽 / CHAOS_PICK）。见 §4.2。 | 2026-10-19 |
| OQ-05-05 | **Cancel ≠ Ignore**：Cancel=从未抽到；Ignore=仍揭示但不 resolve；if_revealed 与 ST.4/5 用 resolved。见 §4.1.1。 | 2026-10-19 |
| OQ-04-07 | **隐式符号能力**融合 ST.3/ST.4；回溯以该能力为锚。见 §4.0。 | 2026-10-19 |

---

## 12. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-05-25 | v0.2 | OQ-05-03 裁决：fail by 效果在 ST.7 结算 |
| 2026-10-17 | v0.3 | §4.1 揭示账本；*If revealed* 初版门槛；能力揭示强制归袋（OQ-05-07） |
| 2026-10-19 | v0.4 | §4.2 多能力揭示意图（ORDER + 预期槽 + CHAOS_PICK）；裁决 OQ-04-05 |
| 2026-10-19 | v0.5 | §4.1.1 Cancel vs Ignore（OQ-05-05）；门槛改查 resolved |
| 2026-10-19 | v0.6 | §4.2 卡面接线：`seq.chaos.reveal` + Mask of Silenus（12068） |
| 2026-10-19 | v0.7 | §4.2 收口：Uses Domain + `after_reveal_if_resolved_symbol`；12068 full；Olive instead-of-1 编译 |
| 2026-10-19 | v0.8 | §7 冒险参考卡 JSON-first；Spreading Flames 竖切；裁决 OQ-05-01 |
| 2026-10-19 | v0.9 | §4.0 隐式符号能力融合 ST.3/ST.4（OQ-04-07） |
| 2026-10-19 | v0.10 | §7：符号能力绑参考卡实例；空白跳过印刷条 |
| 2026-10-19 | v0.11 | §4.1.2：*If revealed* 改紧贴 resolved 结算；废止 ST.4 后扫账本门槛 |
| 2026-10-19 | v0.12 | §4.1.2：`any` 自肃一次；`each` for-each 不自肃 |
| 2026-10-19 | v0.13 | §4.2 尾：去掉「整次检定 Cancel」伪缺口（OQ-04-04） |
