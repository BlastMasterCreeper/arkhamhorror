# 11 — 调查员、牌组与剧本 (InvestigatorCampaignSystem)

> **依赖**：[01-game-state-zones.md](01-game-state-zones.md), [07-effect-resolution.md](07-effect-resolution.md)  
> **规则来源**：Grimoire Deckbuilding, Campaign Play, Trauma, Experience, Weakness, Slots

---

## 1. 目标

管理 **Investigator 运行时状态**、槽位、牌组操作、淘汰/辞职、**剧本（Campaign）** Trauma/XP/Deckbuilding、Standalone/Epic 模式。

---

## 2. Investigator 运行时

见 [01-game-state-zones.md](01-game-state-zones.md) `InvestigatorState`。

额外：

```gdscript
class InvestigatorDefinition:
    var id: StringName
    var skills: Dictionary[SkillType, int]
    var health: int
    var sanity: int
    var elder_sign_ability_id: StringName
    var deckbuilding: DeckbuildingOptions
    var required_cards: Array[StringName]
    var signature_weakness: StringName
```

---

## 3. 槽位（Slots）

| 槽 | 数量 |
|---|---|
| Accessory | 1 |
| Head | 1 |
| Body | 1 |
| Ally | 1 |
| Hand | 2 |
| Arcane | 2 |

Play/gain asset 无 slot → 选 discard 已有 asset 腾位。

---

## 4. 牌组与手牌

| 规则 | 实现 |
|---|---|
| Deck size | 通常 30 + modifiers（Permanent 等） |
| Hand size max 8 | 仅 Upkeep 4.5 检查 |
| Draw empty deck | shuffle discard + 1 horror + draw |
| Discard empty | defeated + 1 mental trauma |
| Mulligan | opening hand 可换 once；weakness 重抽不 resolve |
| Starting | keyword：mulligan 后 search 1 copy 加入 hand |

---

## 5. 淘汰 / Resign / Elimination

### 5.1 Defeated

- Damage ≥ health OR horror ≥ sanity OR ability defeat
- Campaign：1 physical OR 1 mental trauma（同时满选一种）

### 5.2 Resign

- Clues/scenario tokens → current location
- Eliminated from scenario，**不**改 [per_investigator] count

### 5.3 Elimination 清理

Grimoire Elimination：removed from game 其 owner 控制物；clues → location；enemies threat → location；选新 lead investigator。

---

## 6. 剧本状态与开局（CampaignState / CampaignSetup）

> **落地**：`rules/campaign/campaign_state.gd` · `campaign_log.gd` · `campaign_setup.gd` · `investigator_setup_flow.gd`；门面挂在 `InvestigatorCampaignSystem`。测 CAMP-01..05。

```text
start_campaign(difficulty, flags)
  → select_investigator(def, choices)     # 附带 CHOICE；装 Signature
  → set_opening_deck(player_cards, rng) # 校验 size；random basic weakness（Starter 可跳过）
  → begin_scenario(scenario_id)           # prepare + 装库 + Framework Setup 01→14
       ├─ prepare_scenario → RulesConfig.setup_scenario_id + Catalog
       ├─ materialize_deck_into_context   # 牌库入局；创伤计数写入 InvestigatorState
       └─ Framework（setup_run_player_steps=true）
            SETUP_02 trauma → 03 lead → 04 shuffle → 07 资源5 → 08 起手5
            SETUP_10–14 冒险布局 / act·agenda / 参考卡 / game begins
```

| API | 作用 |
|---|---|
| `start_campaign` | 建 `CampaignState`（Log / 难度 / Starter 旗标） |
| `select_investigator` / `replace_investigator` | 选人或换人（换人不继承牌组）；未完成 CHOICE → 拒 |
| `install_required_cards` | `deck_requirements.card` → Signature 入组 |
| `set_opening_deck` / `validate_deck` | 构筑卡 + BW；`DeckLegality` |
| `prepare_scenario` | 写 `current_scenario_id`；返回已接线的 `RulesConfig` + layout |
| `begin_scenario` | 装库 + 打开玩家 Setup 闸 + 跑完 Framework 到 game begins |
| `InvestigatorSetupFlow.*` | SETUP_02/03/04/**06**/07/08；玩家步默认仅 `setup_run_player_steps`；**06 袋**在剧本绑定或该闸时组装 |
| `ChaosBagCatalog` | 四档袋配方（Brethren of Ash）；`easy_standard`→standard 袋；参考卡带 `reference_band` |

```gdscript
class CampaignState:
    var log: CampaignLog
    var investigators: Array[CampaignInvestigatorRecord]
    var difficulty: StringName  # easy|standard|hard|expert（袋）；别名 easy_standard/hard_expert
    var current_scenario_id: StringName
    var use_starter_deck_no_random_weakness: bool
    var claimed_basic_weaknesses: Array[StringName]
    var chaos_bag_id: StringName
    var chaos_bag_snapshot: Array  # 跨冒险延续

class CampaignInvestigatorRecord:
    var investigator_id: StringName
    var definition_id: StringName
    var deck: Array[DeckCardView]
    var physical_trauma: int
    var mental_trauma: int
    var unspent_xp: int
    var deckbuilding_choices: Dictionary
```

### 6.1 Campaign Log

- 精确短语记录（Campaign Notes）
- Cross out 忽略
- Remember vs Record：scenario 内 remember 不持久化

---

## 7. Experience 与 Deckbuilding

> **规则来源**：Grimoire *Experience*；FAQ Game Play **1.8**；2026 Core Rulebook *Earning and Spending Experience*；Customizable / Exceptional / Myriad / Exile / FAQ 1.18 / 1.37。  
> **实现状态（2026-11-03）**：`spend_xp_and_upgrade` 仅 API 壳；剧本幕间（interlude）流程 **未实现**。本节先定规则模型，供后续落地。

### 7.1 手续顺序（Scenario 后）

官方 Grimoire *Experience* 为 **3** 步；下行 3–4 为步骤 2 内约束拆条（实现检查项，非另开手续）。

```
1. Count experience
2. Purchase new cards（属手续）— 窗内逐张交易：NEW_CARD / UPGRADE / CUSTOM_CHECK …
   · 计入 size 的卡 +1 须 −1；weakness / required 不可因购卡移除
3. Record unspent experience
```

#### 7.1.1 Count experience 口径（含卡面加减 XP）

```
raw_earned =
    victory_display Σ Victory X     # 共享池；每名调查员同额（决议另有分配时除外）
  + campaign guide ±                # 决议奖励/惩罚
  + personal_resolution_delta       # 个人结算调整（可正可负）
earned_this_scenario = max(0, raw_earned)   # 本场贡献不掏已积未花 XP
unspent := prior_unspent + earned_this_scenario
```

| 通道 | 机制 | 锚例 |
|---|---|---|
| **胜利展示 Victory X** | 对局中进 `victory_display`；Count 时求和 | **02111 Delve Too Deep**（Victory 1） |
| **剧本 guide ±** | Campaign Guide 决议条文 | 「再得 2 经验」/「少得 N 经验」 |
| **个人结算 delta（+）** | *you earn N additional experience*（When earning / 结算时） | **06160**（+1）；**03308 Charon's Obol**（未淘汰 +2） |
| **个人结算 delta（−）** | *you earn N fewer experience* | **12006 Dead Ends**（手中结束 −2）；**Hospital Debts**（资源不足 −2） |

**勿混**：

- 02111 类 = **先**进 VD（印刷 Victory）→ 共享 VP；不是个人 delta。  
- 06160 / Dead Ends 类 = 个人 signed delta（加或减）；印刷未必有 Victory X。  
- 「fewer」只减**本场获得**，`earned` floor 0，**不**从 prior unspent 倒扣。  
- DtRH / Arcane Research = **花 XP** 购卡修饰器（步骤 2），不是 Count 通道。

API：`ExperienceCount.tally` / `delta` / `penalty`；`record.queue_resolution_xp_bonus(+n)` / `queue_resolution_xp_penalty(n)`；`count_and_begin_experience_window`。

卡面若改 deckbuilding / 购卡 / 升级（如 Adaptable、Underworld Market）：**逐张结算**，购入后立即对本 spend window 生效（FAQ 1.37）。

### 7.2 属种划分（白马非马）— 勿写成「升级不是购买」

Grimoire 把升级**写在**步骤 2「Purchase new cards」之下：

> When **purchasing** a higher level version of a card with the same title, the investigator may choose to "**upgrade**" …

故：**升级 ⊆ 购买（属 / 手续窗）**；同时：**升级 ∉ 「购新卡」种**。单说「购买」时，卡面/FAQ 常带隐含前提「非升级的购买」——要用措辞粒度判定，禁止一刀切布尔。

#### 「new card」指什么（非牌组集合论）

**不是**「牌组里目前没有的牌」——那几乎是废话：无论购新还是升级，进组的那张印刷品事先都不在牌组里；且购第二份同名同级也完全合法（牌组里已有同名）。

**也不是**简单的「非同名高级卡」——同名更高级仍可**不选 upgrade**、按全价当购新卡买入，并移除**另一张**无关卡（Grimoire：先是 *purchasing a higher level version*，再 *may choose to* upgrade）。

**是购入模式（mode）**：

| 种 | 何时成立 | 费用 / 换出 |
|---|---|---|
| **NEW_CARD** | 默认购入路径：把目标印刷品**当作新纳入**加入牌组 | 付印刷 level（FAQ 1.8 → min 1）；为维持尺寸移除**另一张**（非「被升级掉」的那张低级） |
| **UPGRADE** | 目标为同 title **更高** level，且玩家**选用** upgrade 选项 | 付 level 差（无购新卡 min-1）；**必须**移除那张低级同名 |

故卡面/FAQ 的 *new card(s)* ≈「走 NEW_CARD 模式的那次购入」，与 *upgrade* 对举；**不是**对牌组内容的集合谓词。

```text
Purchase（属 · Experience §2 手续窗 · 凡扣 XP 改牌组的交易）
├── NEW_CARD     「purchase (a) new card(s)」种 — 默认购入模式（可含同名高级全价）
├── UPGRADE      「upgrade」种 — 同 title 低→高且选用差额路径
└── CUSTOM_CHECK 已有 customizable 的 sheet 勾选（card-effect 亦算 upgrading）
```

| 说法 | 真假 | 说明 |
|---|---|---|
| 升级是购买（属） | **真** | 落在 Purchase 步骤；Grimoire：「when purchasing … upgrade」 |
| 升级是购新卡（种） | **假** | FAQ 1.8 / DtRH / Arcane Research 等把 *new card(s)* 与 *upgrade* 对举 |
| *new* = 牌组没有 | **假** | 集合论读法空洞；见上 |
| *new* = 非同名高级 | **过窄** | 同名高级全价买入仍是 NEW_CARD |
| 卡面裸 `purchase` | **慎判** | 多指购得该卡 / NEW_CARD 种；见 §7.4 |
| 卡面 `upgrade` | **种** | 只命中 UPGRADE（+ 规则写明的 CUSTOM_CHECK） |

**禁止**：`is_purchase == !is_upgrade` 互斥布尔；也禁止用「是否已在牌组」实现 *new*。  
**要求**：交易带 `XpSpendKind`（模式标签）；卡面按印刷措辞绑属或种。

#### 购入报价：选定目标印刷品时列出可选升级项

同名高级全价购入（留低级）是**合法**操作，不是要藏起来的边角。XP 必须在**提交前**确定，因此报价发生在「选定待购印刷品」这一刻，而不是事后改账：

```text
quote_purchase(target_def, deck, unspent_xp, modifiers…) → PurchaseOffer
  always:
    NEW_CARD 选项 — xp = NEW_CARD 公式（含 Exceptional×2、DtRH +1 等）
                   remove_candidates = 为维持尺寸可移除的牌（不含「必须换掉的低级」约束）
  for each 牌组内同 title、level < target.level、可作 upgrade 源的副本（或按 level 聚合）:
    UPGRADE 选项 — xp = (target.level − source.level)（再叠升级种修饰）
                   remove = 该源副本（锁定）
  if target 为 Customizable:
    另出 CUSTOM_CHECK / 带勾选的 NEW_CARD 路径（§7.2.1）
```

- 玩家选中**一条**选项后，费用与换出已定，再扣 XP、改牌组、触发「when you purchase / upgrade」类效果。  
- UI 不默认替玩家选 upgrade；只**列出**可选升级项（及全价 NEW_CARD）。  
- 无合格低级源 → 仅 NEW_CARD（或 Researched 禁止 NEW_CARD 时仅升级路径 / 非法）。

#### 7.2.1 构筑关键词对报价的影响（待接到 quote）

**Exceptional（卓越）** — Grimoire / RR：deckbuilding 关键词。

| 点 | 规则 | 报价落点 |
|---|---|---|
| XP | **2× 印刷经验费用（level）** 购买 | `NEW_CARD`：`2 * printed_level`；再与 FAQ 1.8 的关系见下 |
| 副本 | 同 title **最多 1 份** | `validate_deck` / Offer 合法性；≠ 普通 ≤2 |
| 升级 | 文面写 *to purchase*；同名更高 level 的 Exceptional 走 UPGRADE 时，差额是否再 ×2 → **OQ-11-10**（常见读法：印刷费用×2 只绑「购买该印刷品的费用」，upgrade 付差时对**目标印刷费用**作差：`2*new − 2*old` 或 `2*(new−old)` 等价） | 报价层必须显式分支，禁止默默只用 `new−old` |

与 min-1：L0 Exceptional 极少；若出现，先算印刷费用再 ×2，购新卡种仍受「至少 1」约束时以 FAQ 1.8 为准（通常 `max(1, 2*level)` 对 L0 仍为问题 — 记 OQ 若实卡出现）。

**Customizable（定制）** — 独立子系统，**不是**普通 level 印刷品换级。

| 点 | 规则 | 引擎落点 |
|---|---|---|
| Sheet | 每卡一张 upgrade sheet；1 XP = 勾 1 格；一项 upgrade 须勾满其全部格才算购得 | `CustomizationSheet` 状态挂在 **调查员拥有** 的该 title 上（非单张实例） |
| Level | `ceil(已勾格数 / 2)`；最多 10 格 → level ≤5 | 动态 level |
| 已在牌组上勾选 | 算 **upgrading**（DtRH / Arcane Research 等升级种修饰生效） | Offer 种 = `CUSTOM_CHECK`（∈ upgrade 种谓词） |
| 新买带勾选 | 只付勾选所需 XP；算 **purchasing a new card, not upgrading** | Offer 种 = `NEW_CARD`（可附初始勾选载荷）；**无**升级种减价 |
| 清空 | 最后一份离开牌组 → sheet 清空；回购当新卡空白 sheet | exile / 移除钩 |
| 回购 | 付 sheet 所示费用，**或**继续往 sheet 花钱免费加回一份（FAQ） | 报价第二路径 |
| 「When you purchase [this]」 | 选 trait / 记名等到 sheet（Raven Quill、Living Ink…） | 绑 NEW_CARD 事件，写 sheet 元数据 |

ArkhamDB：`customization_options[]`（`xp` / `text_change` / `real_traits` / `tags` / `real_slot` / …）；导入 hydrate；`CampaignInvestigatorRecord.customization_sheets`。

##### 有效卡面投影（勾选会改构筑身份 — 硬门槛）

定制项不只改能力正文，还会改 **DeckCardView 用于准入的字段**。ArkhamDB 锚例：

| `text_change` / 字段 | 效果 | 构筑后果例 |
|---|---|---|
| `trait` + `real_traits` | **替换**特性行（如 Hunter's Armor → 含 Relic；Runic Axe → 含 Weapon/Relic） | 新进「[[Relic]] / [[Weapon]] / [[Spell]]…」类 ALLOW；或触发 FORBID（如 Lily 禁 Firearm——若勾出相关特性） |
| `append`/`insert` + `tags` | 正文追加并打标（如 Glory → `hd`/`hh`） | 新进 Carolyn「heal horror」/`hh`、Vincent `hd` 等 **tag 带** |
| 勾格升高 level | `ceil(n/2)` | 可能超出副职/选型 level 上限 → **整张变非法** |
| `real_slot` / `cost` / `deck_limit` / `health`… | 槽位、费用、副本上限等 | 槽不直接改 options；`deck_limit` 影响同名上限 |

因此 **禁止**用印刷版 `DeckCardView` 验定制后的牌组。流程：

```text
base definition
  ⊕ CustomizationSheet（已购满的 options）
  → EffectiveDeckCardView（traits / tags / level / slot / …）
  → CardAccessMatcher / DeckLegality（FAQ 1.15 重新有序配位）
```

含义：

1. **CUSTOM_CHECK dry-run**：假设勾上目标项（及其中间格）后，投影所有该 title 副本 → 整副 `validate_deck`；失败则该勾选不可提交（XP 不够或勾后非法）。  
2. **配位可能换带**：勾前占 LIMIT「other」坑的卡，勾出 Spell/Relic 后可能改吃无限 ALLOW，**释放** LIMIT 名额（反之 level 超限则整卡 NONE/FORBIDDEN）。  
3. **list_accessible / 购新带勾**：候选费用与合法性按「买时勾选后的投影」算，不是空白 L0 印刷面。  
4. 对 **tag 带**调查员，append 带来的 `hd`/`hh`/`pa`… 与印刷 `tags` 同等生效。

```text
XpSpendKind（完整）:
  NEW_CARD        — 含：普通购新；Exceptional×2；Customizable「新买±初始勾选」
  UPGRADE         — 同 title 印刷品换级（非 customizable sheet）
  CUSTOM_CHECK    — 已有 customizable 的 sheet 勾选（upgrading 谓词）
```
### 7.3 min-1：绑在「购新卡」种，不绑升级种

| 来源 | NEW_CARD 种 | UPGRADE 种 |
|---|---|---|
| Grimoire | `level`，**floor 1** | 差额，文面另写 floor 1 |
| FAQ **1.8** | min 1；L0=1；*purchasing **new** cards* | **该 minimum 不适用于 upgrading** |
| 2026 Core RB | always ≥1 even if level 0 | 只写 level **difference**（无 floor） |

**引擎裁决**：`NEW_CARD → max(1, level)`（再乘 Exceptional 等）；`UPGRADE → new − old`（无 min-1）。整数升档时差额常 ≥1，与 Grimoire 升级句 floor **数值常重合**；语义仍属「种」而非把购新卡 min-1 渗进升级。旧稿「upgrade 差 min 1」作废。

### 7.4 卡面措辞普查（ArkhamDB 全文检索 · 锚例）

对举最干净的一张 — **Down the Rabbit Hole (08059)**：

- 「first 2 cards you **upgrade**」→ −1 XP（升级种）
- 「**purchase new cards**」→ +1 XP（购新卡种）  
同窗两句并列，证明印刷侧把两**种**拆开，而不是「升级∉购买属」。

| 措辞模式 | 锚例 | 绑到 |
|---|---|---|
| `purchase new card(s)` / `new card you purchase` | DtRH 加价；**Pelt Shipment (10109)** 减价 | **NEW_CARD** |
| `cards you upgrade` / `card you upgrade` / `to upgrade` | DtRH；**Arcane Research (04109)** Spell 升级减价；**Shrewd Analysis (04106)**；**Raven Quill (09042)** | **UPGRADE**（+ 规则写明的 CUSTOM_CHECK） |
| `When you purchase [this card]` | Arcane Research（购时创伤）；Thick of It；Ascetic；Eldritch Brand；Spiritual Healing；Customizable 选 sheet | 该卡进入牌组的 **NEW_CARD** 事件（购得本卡） |
| `Purchase (only) at deck creation` | DtRH、Geared Up、Forced Learning… | 构筑期限制，非幕间种判定 |
| `repurchase`（exile 后再买） | **Déjà Vu (60531)** | **NEW_CARD** 变体（FAQ 1.18 语境） |
| 裸 `next card you purchase`（无 new） | **Green Man Medallion (98002)** | **待裁定（OQ-11-07）**：属监听 vs 默认当 NEW_CARD 种 |

**官方澄清（Arcane Research）**：减价只对「正在 upgrade、且**源卡**带 Spell」生效；**购一张新 Spell** 不享受；非 Spell→Spell 的升级也不享受。说明 **upgrade 种 ≠ purchase-new 种**，且升级种还看源卡性质。

**Customizable 规则对举**（与卡面一致）：

- 对**已在牌组**的 customizable 花 XP 勾 sheet → *upgrading*（for card effects）
- **直接**购入带勾选的新副本 → *purchasing a new card, **not** upgrading*

### 7.5 费用与牌组约束（摘要）

| 种类 | XP | 牌组 |
|---|---|---|
| `NEW_CARD` | `max(1, printed)`；**Exceptional → ×2 printed**；Customizable 新买 = 勾选格合计 XP；Myriad 可连带 ≤2 同 level 0 XP | **计入 size** 的卡：+1 须 −1；Permanent / Signature / 弱点 / Bearer **免**；Exceptional 同 title ≤1 |
| `UPGRADE` | 印刷品换级：`new − old`（无购新卡 min-1；Exceptional 见 OQ-11-10） | 移除低级、加入高级 |
| Exile 后补牌至合法尺寸（FAQ 1.18） | 补足前 L0 可 **0 XP**；DtRH 加价**不**作用于此类补牌（FAQ） | 强制 maintain size |
| `CUSTOM_CHECK` | 1 XP / checkbox；满格才「购得」该项；sheet ≤10；level=`ceil(勾数/2)` | 已有副本：升级种；须再验 Profile 是否允许新 level |

#### 7.5.1 是否计入 Deck Size（已裁决）

谓词：`DeckCardView.counts_toward_deck_size()`。Rulebook *Deck Customization* + Grimoire Permanent / Bearer / Signature。

| 计入 size？ | 来源 | 备注 |
|---|---|---|
| **否** | **Permanent** | 仍须遵守 deck_options（≠ ignore） |
| **否** | **弱点**（basic / signature weakness） | Rulebook：Weaknesses do not count |
| **否** | **Signature**（`deck_requirements.card`） | 调查员专属玩家牌；`ignore_deckbuilding`；加载/导入打标 |
| **否** | **Bearer / 剧情入组** | 「become the bearer」→ ignore options + 不计 size；`add_bearer_card` |
| **是** | **Myriad** | **只**改副本上限 3 + 购时 ≤2 张同 level **0 XP**；每张仍占 size，购额外副本也须 −1 |
| **是** | 普通玩家牌 | 默认 |

**勿混**：`ignore_deckbuilding`（无视 options）⊃ Signature / Bearer；Permanent **不** ignore options，但 size exempt。Myriad **既不** ignore，**也不** size exempt。

| 关键词 / 来源 | 规则 |
|---|---|
| Permanent | deck creation only；不计 deck size；**仍**守 options |
| Exceptional | **2× printed XP**；max **1** copy by title；见 §7.2.1 |
| Customizable | sheet 子系统；见 §7.2.1；≠ 普通 UPGRADE |
| Reward | 解锁后可用；golden corner |
| Signature | `deck_requirements`；ignore options；不计 size |
| Bearer | 忽略 deckbuilding；不计 deck size |
| Myriad | 副本 ≤3；购时可 +≤2 同 level **0 XP**；**计入** size |
| Researched | 不可 NEW_CARD 高级；须从低级 UPGRADE + Campaign Log 任务 |

### 7.6 Deckbuilding Options 分类（购卡候选范围）

> **规则**：Grimoire *Deck Customization*；FAQ **1.15**（*other* / 卡面文本类）、**1.16**（多职阶）、购卡须遵守 investigator 背面 options。  
> **数据**：ArkhamDB `deck_options` / `deck_requirements`（本库 schema 已有字段；**勿**从 `back_text` 再解析散文）。普查 ≈105 名调查员（含平行 / 促销 / 新手）。

购卡/构筑时「这张能不能进我的牌组」= 对该调查员当前 **已解析的 DeckbuildingProfile** 做准入检验。选项不是扁平白名单，而是**若干类别（category）+ 全局禁制 + 配额/下限**。

#### 7.6.1 类别构件（单条 `deck_options[]` 条目能表达的谓词）

| 构件 | ArkhamDB 字段 | 含义 | 频次量级 |
|---|---|---|---|
| **职阶带 level** | `faction` + `level` | 主类 / 副类 / Neutral 等经典带 | ~165（最大宗） |
| **特性带 level** | `trait` + `level`（可加 `type`） | Spell / Tome / Relic / Tactic…；可限 cardtype | ~33+ |
| **文本/标签带** | `tag` / `text` / `uses` + `level` | 难解析能力：heal horror/damage、seals、parley、firearm-in-text、uses(charges) | 少但硬 |
| **有限职阶池** | `faction` + `level` + `limit`（+`error`） | 「最多 N 张某职阶/跨职阶」；常对应印刷 *other* | ~18+ |
| **通用越级池** | 仅 `level`+`limit`+`error`（无 faction） | Dunwich 式「最多 5 张非本职 L0」 | 6（Zoey 等） |
| **禁制** | `not: true` + `trait`/`permanent`/`text`… | 禁止匹配卡（Rex 禁 Fortune；Carolyn 禁 L1–5 Weapon…） | ~7 |
| **玩家选型职阶** | `faction_select` + `level`（+`type`/`limit`/`id`/`name`） | Secondary Class / Class Choice（Tony、Mandy、Charlie、Lola∥…） | ~9 |
| **玩家选型特性** | `option_select` | Wendy∥ Blessed/Cursed；Marion Trait Choice | 2 |
| **牌组尺寸选型** | `deck_size_select` | Mandy 30/40/50 | 1 |
| **全牌组下限** | `atleast` + `faction` | Lola「≥3 职阶各 ≥7」；5U-21「每职阶 ≥7」；Lola∥ `ignore_match` | 3 |
| **Permanent 过滤** | `permanent` | Jenny∥ Talent 限非 permanent；5U-21 禁 permanent | 少 |

**ArkhamDB `tags`（卡面侧标注，供选项匹配）**：`hh` heal horror；`hd` heal damage；`pa` parley；`se` seals token；`fa` firearm-in-text；历史 `st`/`uc` 等与 bonded/uses 并存。引擎以 **卡面 `tags` ∪ 结构化字段** 匹配，不在购卡时跑正则扫全文（`text` 正则仅作导入期打标 / 校验）。

#### 7.6.2 语义角色（实现时的规则角色，不是 JSON 键）

把每条选项归为四种角色（一条 JSON 可同时带匹配谓词 + 配额）：

| 角色 | 作用 | 例 |
|---|---|---|
| **ALLOW 带** | 匹配则*可以*纳入（受 level / type 等） | Guardian 0–5；Spell 0–5 |
| **LIMIT 池** | 匹配且**未**被更前的无限带吃掉时，占用配额 | 「最多 5 张 other L0」；「最多 15 张 L0–1 Seeker/Mystic」 |
| **FORBID** | 匹配则**禁止**（先于 ALLOW） | no Illicit；no Firearm；no L1–5 Weapon |
| **CHOICE / META** | 构筑前解析进 Profile，不直接验单卡 | `faction_select`、`option_select`、`deck_size_select` |
| **DECK_CONSTRAINT** | 验**整副牌**而非单卡 | `atleast`；deck size；signature 张数；random BW |

FAQ **1.15 *other***：LIMIT 池仅收「落不进任何更优先无限 ALLOW 带」的卡。实现 = **有序试配**：先无限 ALLOW，再 LIMIT；多职阶卡占坑规则见 FAQ **1.16**。

#### 7.6.3 调查员形态谱系（按印刷模式，非穷举每人）

| 谱系 | 典型 | Options 形状 |
|---|---|---|
| A. 本职 0–5 + 副职 0–2 + Neutral 0–5 | Core / 多数战役 | 仅 `faction`+`level` |
| B. 本职+Neutral 无限 + 有限越级 L0 | Dunwich 五人 | A + 无 faction 的 `limit:5` |
| C. 特性/文本扩展 + 有限跨职 | Marie Spell；Carolyn heal horror；Akachi charges；Daisy∥ Tome | `trait`/`tag`/`uses` + 跨职 `limit` |
| D. 倒置职阶（本职锁 L0，副职高 level） | EotE Daniela/Norman/… | 本职 L0 + 副职 L1–5 + 副职 L0 `limit:5` |
| E. 选型副职（事件/技能配额） | Tony / Mandy / Carson / Gloria | `faction_select` + `type` + `limit` |
| F. 双选型职阶 | Charlie；Lola∥ | 两个 `faction_select` + `id` |
| G. 选型特性 / 尺寸 | Wendy∥；Marion；Mandy size | `option_select` / `deck_size_select` |
| H. 整副约束 | Lola；5U-21 | `atleast`（± `ignore_match` / `base_level`） |
| I. 禁制叠加 | Preston；Lily；Rex∥；Carolyn | `not` |
| J. 新手单职 | Nathaniel Cho 等 | 仅本职+Neutral 0–5 |

Signature / required cards / basic weakness ∈ `deck_requirements`，**无视** options 限制且一般不计 deck size（Grimoire）；Bearer / 部分 story 同。

#### 7.6.4 与购卡窗的关系

`quote_purchase` / 候选列表的 **准入** =：

1. 目标印刷品通过 FORBID；  
2. 在当前 Profile 下存在一条配位路径（无限 ALLOW **或** 某 LIMIT 池仍有空位，含 FAQ *other* / 多职阶）；  
3. 加入后整副仍满足 DECK_CONSTRAINT（atleast、size、副本上限…）——升级换出低级时按置换后状态验；  
4. Reward / 未解锁 story 等另闸。

卡面改 options（FAQ 1.37：Underworld Market 等）→ **立即**重建 Profile 再继续本窗报价。

### 7.7 Deckbuilding 实现计划

> **落地（2026-11-04）**：`rules/deckbuilding/` 准入核（DB-*）；**P6** `rules/campaign/`；**§7.5.1** `counts_toward_deck_size`（Signature/弱点/Bearer/Permanent 不计；Myriad 计）+ loader requirements 打标；测 XP-01..06 / DB-08/09。**P6c Customizable 仍延后**。

**原则**：消费 ArkhamDB 结构化 `deck_options`；运行时只持有**已解析 Profile**；单卡匹配与整副校验分离；购卡 dry-run 复用同一验证器。

```text
导入
  CardDefinition.tags / traits / factions / level / type / uses / permanent
  InvestigatorDefinition.deck_options[]、deck_requirements
       ↓
选定调查员
  → 附带玩家选择（统一）：faction_select / option_select / deck_size_select
  → 答案写入 deckbuilding_choices
  → DeckbuildingProfile（冻结选型 + 展开 ALLOW/LIMIT/FORBID）
       ↓
DeckLegality
  match_card → 有序配位（FORBID → 无限 ALLOW → LIMIT 占坑）
  validate_deck → size / copies / atleast / required / limits 汇总
       ↓
购卡
  filter 候选 + quote_purchase 时 dry-run validate_deck(deck ⊕ choice)
```

#### 7.7.1 选定调查员后的附带玩家选择（已裁决）

副职阶、特性选型、牌组尺寸等 **不是** 各走一套机制，也 **不是** 对局内 seq 时点的 `PlayerInteractionGate`。

统一归入：**选好调查员之后、构筑/购卡之前** 的附带玩家选择束。

| 来源（`deck_options` Role.CHOICE） | 例子 | 答案键 |
|---|---|---|
| `faction_select` | Tony / Mandy / Carson **Secondary Class**；Charlie 双职阶 | `name` / `id` → 职阶码 |
| `option_select` | Wendy∥ Blessed/Cursed；Marion Trait | `id` / `name` |
| `deck_size_select` | Mandy **30/40/50** | 固定键 `deck_size` |

API：`DeckbuildingChoiceFlow.list_choices` → 提示列表；`apply_answers` / `bind_investigator` → 写入 `CampaignInvestigatorRecord.deckbuilding_choices` 并冻结 Profile。未答完 → `unresolved`；`validate_deck` 拒。

| 阶段 | 交付 | 说明 |
|---|---|---|
| **P0 数据** | hydrate `deck_options` → 内部 `DeckOptionRule`；卡面 `tags` | 与 ArkhamDB 键同构；`text` 正则只在导入打标 |
| **P1 匹配核** | `CardAccessMatcher` + FAQ 1.15 有序配位 | 先覆盖谱系 A/B/J（faction+level±越级 limit） |
| **P2 整副** | `validate_deck`：size、≤2 同名、requirements、LIMIT 计数 | 开局构筑硬闸 |
| **P3 附带选择** | `DeckbuildingChoiceFlow`：选调查员后统一 list/apply | 副职阶 / 特性 / size；谱系 E/F/G；Charlie 两 id 互异另测 |
| **P4 扩展谓词** | trait / type / tag / uses / permanent / not | 谱系 C/I |
| **P5 多职阶 + atleast** | FAQ 1.16；Lola / 5U-21 | 谱系 H |
| **P6 购卡接线** | `CampaignInvestigatorRecord` + `quote_purchase` / `commit_purchase` | NEW_CARD / UPGRADE 报价；嵌 `can_add_card`；扣 XP 改牌组 |
| **P6a list_accessible** | 卡池过滤目录 | 接 CardRegistry + Profile |
| **P6b Exceptional** | 费用 ×2 + 副本上限 1；UPGRADE 倍差 OQ-11-10 | 导入 `exceptional`；Offer / validate |
| **P6d Myriad / Permanent / Signature** | Myriad 副本 3（**计** size）；Permanent/Signature/弱点/Bearer **不计** size；Signature ignore options | `counts_toward_deck_size`；requirements 打标 |
| **P6e XP 修饰器** | DtRH / Arcane Research / Pelt；报价不吞次数、提交才消耗 | `build_modifiers`；叠用顺序 DtRH→AR→Pelt |
| **P6e′ size refill** | FAQ 1.18 Exile 等 undersize → L0 补牌 0 XP；**DtRH 不加价** | `KIND_SIZE_REFILL` |
| **P6f 幕间壳** | Experience 官方 3 步入口；Count 含 VD + guide + 个人 bonus | `ExperienceCount`；02111 / 06160 通道 |
| **P6c Customizable** | **延后**（投影改 traits/tags/level，子系统大） | 见 §7.2.1；不阻塞 P6–P6b/d |

**CampaignInvestigatorRecord 增补**（示意）：

```gdscript
var deckbuilding_choices: Dictionary  # faction_1 → guardian, trait_choice → cursed, deck_size → 40…
# 有效 Profile 可由 definition ⊕ choices ⊕ 运行时 modifiers（Market 等）惰性重建
```

**测试锚**（实现时）：

| ID | 覆盖 |
|---|---|
| DB-01 | Roland：Seek L2 可、L3 不可 |
| DB-02 | Zoey：第 6 张越级 L0 拒；多职阶本职不占坑 |
| DB-03 | Carolyn：heal-horror 标签卡走无限带；L1 Weapon FORBID |
| DB-04 | Tony：选调查员后附带 Secondary Class → Survivor 事件可、资产不可 |
| DB-05 | Mandy：附带 `deck_size=50` + 副职 → size 校验按 50 |
| DB-06 | Lola：仅 2 职阶各 7 → atleast 失败 |
| DB-07 | 购卡 dry-run：LIMIT 已满则该卡不进 Offer 候选 |
| DB-08 | size exempt：Signature / 弱点 / Permanent / Bearer |
| DB-09 | Myriad **计入** size |

**非目标（本阶段）**：从中文 `back_text` 编译 options；替代 ArkhamDB 人工 `tags` 的 NLP。

---

## 8. Starter Deck 2026

- 预构 deck 含 **指定 signature weakness**
- **不**追加 random basic weakness（campaign flag `use_starter_deck_no_random_weakness`）

---

## 9. Standalone / Epic

**Standalone**：

- 可用 higher level cards，按 total XP 加 random basic weaknesses
- Record → Remember（scenario 内）
- 50+ XP cards 禁止

**Epic**：跨 campaign transfer 规则（reset XP cards level 1–5, trauma/story assets 保留, reset log 等）。

---

## 10. Weakness 与 Revelation（分流）

> **规则来源**：Grimoire *Weakness* — resolved differently depending upon **cardtype**。

| 维度 | 说明 |
|---|---|
| **Weakness** | 卡**子类型**（缺陷/诅咒/伤/敌人/故事线等）；与 asset/event/skill/**enemy/treachery** 等 **cardtype 正交** |
| **Revelation** | **能力类型**（**Revelation –**）；可在 encounter 牌、weakness、Dilemma 等上出现；**按 `has_revelation` 判定**，非 weakness 子类型 |

### 10.1 抽出结算 = 卡面能力（类型默认能力包）

Weakness 是子类型；**结算键是卡面能力体系**（类型给出默认包），不是抽牌来源重定向。见 [15 §17.6](15-timing-entry-catalog.md)。

| cardtype（默认能力包） | Grimoire 行为摘要 | 引擎 |
|---|---|---|
| **Enemy / Treachery / Location**（ENCOUNTER 包） | 遭遇侧能力；地点常显现入场 | `seq.encounter.resolve_card` |
| **Asset**（INVESTIGATOR 包） | Revelation（若有）→ **add to hand** → 作 asset | `seq.draw.investigator` D2–D3 + `seq.enter_hand` |
| **Event** | 同上 → 作 event | 同上 |
| **Skill** | 同上 → 作 skill | 同上 |

```text
卡面能力 / 类型默认包
  ├── ENEMY / TREACHERY / LOCATION → ENCOUNTER 包（揭示·险境·显现·spawn/discard/地点进场）
  ├── ASSET              → INVESTIGATOR 包 → hand → play asset
  ├── EVENT              → INVESTIGATOR 包 → hand → play event
  └── SKILL              → INVESTIGATOR 包 → hand → commit skill
Weakness 子类型只调 owner / bearer / 剧本残留，不另开管线
可抽遭遇类型 = 诡计 / 敌人 / 地点（前两者为遭遇库大宗）
```

### 10.2 与 Revelation / 无显现

| 情况 | Draw / 入手时 |
|---|---|
| Encounter cardtype weakness | **encounter** E2–E6；**非** 调查员 D3 enter_hand |
| Player cardtype weakness，**无** Revelation | D3 进 hand；**无** `seq.enter_hand` nest |
| Player cardtype（含 weakness），**有** Revelation | D3 `nest_batch seq.enter_hand`（[15 §16](15-timing-entry-catalog.md)） |
| 非 draw 入手（任意 weakness） | Grimoire *as if just drawn* → 上表对应管线 |
| Bearer |  scenario 中加入 deck/hand/threat **不占** deck size |

### 10.3 引擎判定（禁止混用）

```gdscript
## 路由只看 cardtype + is_weakness；勿写 if weakness: always encounter
func is_encounter_cardtype_weakness(def: CardDefinition) -> bool:
    return def.is_weakness and def.cardtype in [CardType.ENEMY, CardType.TREACHERY]

func is_player_cardtype_weakness(def: CardDefinition) -> bool:
    return def.is_weakness and def.cardtype in [CardType.ASSET, CardType.EVENT, CardType.SKILL]
```

**Invariant**：asset/event/skill weakness **永不** 调用 `seq.draw.encounter`（除非未来印刷 explicit 双类型 — 当前无）。

---

## 11. InvestigatorCampaignSystem API

```gdscript
class InvestigatorCampaignSystem:
    func create_investigator(def_id, player_id) -> StringName
    func apply_trauma_at_setup(record: CampaignInvestigatorRecord) -> void
    func mulligan(inv: StringName, cards_to_replace: Array) -> void
    func check_hand_size(inv: StringName) -> void
    func eliminate(inv: StringName, reason: EliminationReason) -> void
    func resolve_deckbuilding_profile(record) -> DeckbuildingProfile
    func list_accessible_cards(record, filter := {}) -> Array[StringName]
    ## 选定 target 印刷品 → 列出 NEW_CARD + 各合法 UPGRADE 报价（XP 已算清；已做准入 dry-run）
    func quote_purchase(record, target_def_id: StringName) -> PurchaseOffer
    func commit_purchase(record, choice: PurchaseChoice) -> Result
    func validate_deck(record) -> Result
```

---

## 12. 测试场景

| ID | 场景 | 预期 |
|---|---|---|
| I-01 | Starter deck campaign start | 无 random basic weakness |
| I-02 | 4 trauma physical, health 7 | 第 4 场开始 3 damage — killed at 4th defeat? |
| I-03 | `NEW_CARD` level 0 | cost **1** XP（购新卡种 min-1） |
| I-03b | `UPGRADE` L0→L1 | cost **1** XP（差额；FAQ 1.8 种外） |
| I-03c | `UPGRADE` L2→L4 | cost **2** XP |
| I-03d | DtRH：upgrade −1 与 purchase new +1 | 同窗分种；升级不加价、购新卡不减价 |
| I-03e | Arcane Research：购新 Spell vs upgrade Spell | 仅后者吃减价 |
| I-03f | `When you purchase [this]` | 仅该卡 NEW_CARD 事件 |
| I-03g | 牌组有 L0，报价 L3 同名 | Offer 含 NEW_CARD(全价) + UPGRADE(差额)；两者皆可选 |
| I-03h | 牌组无低级同名，报价 L3 | Offer 仅 NEW_CARD |
| I-04 | Permanent Collector | +5 deck size |
| I-05 | Draw weakness in opening | set aside, redraw |
| I-06 | Resign 4 player | [per_investigator] still 4 |
| WKN-01 | Draw **asset** weakness w/ Revelation | D3 enter_hand；**非** encounter draw |
| WKN-02 | Draw **event** weakness no Revelation | hand only；no enter_hand nest |
| WKN-03 | Draw **enemy** weakness from deck | `seq.encounter.resolve_card`；spawn_engaged or discard_spawn_failed |
| WKN-04 | Draw **skill** weakness | D3 hand；可 commit 至检定 |

---

## 13. Open Questions

| ID | 优先级 | 问题 |
|---|---|---|
| OQ-11-01 | P1 | Starter deck flag 是否 per-campaign 还是 per-investigator？ |
| OQ-11-02 | P1 | Bearer weakness 中途获得 — 是否立即 shuffle 进 deck 还是下一场？ |
| OQ-11-03 | P2 | Epic mode transfer — 电子版是否 v1 不实现？ |
| OQ-11-04 | P1 | Deck validation 非法 deck — 阻止开始 scenario 还是 warning？ |
| OQ-11-05 | P2 | Random basic weakness 池 — 按 product 还是 global 池？ |
| OQ-11-06 | P1 | Physical+mental trauma 同时导致 killed **and** insane 的 edge case？ |
| OQ-11-07 | P2 | Green Man Medallion 裸「next card you purchase」——属（含升级）还是默认 NEW_CARD 种？ |
| OQ-11-08 | P2 | Charlie / Lola∥ 两个 `faction_select` 是否必须选不同职阶？（印刷未写死时以 FAQ/惯例为准） |
| OQ-11-09 | P2 | 动态 modifiers（Market 等）改 size/options 后，已超限的在组卡是强制立刻剔除还是仅阻止新购？ |
| OQ-11-10 | P1 | Exceptional 同名换级：差额是否按 `2*(new−old)`（对印刷费用加倍后再差）？ |

---

## 14. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 初稿 |
| 2026-06-18 | v0.2 | **§10** Weakness 全 cardtype 路由（asset/event/skill vs enemy/treachery）；WKN-01～04 |
| 2026-11-03 | v0.3 | **§7** Experience：FAQ 1.8 / 2026 RB；购新卡种 min-1 |
| 2026-11-03 | v0.4 | **§7** 属种（白马非马）：升级 ⊆ Purchase 属、∉ NEW_CARD 种；ArkhamDB 措辞普查（DtRH / Arcane Research / Pelt…）；OQ-11-07 Medallion |
| 2026-11-03 | v0.5 | **§7.2** 钉死 *new card* = 购入**模式**（非「牌组没有」、亦非「非同名高级」）；同名高级全价 = 仍 NEW_CARD |
| 2026-11-03 | v0.6 | **§7.2** 购入报价：选定目标时列出 NEW_CARD + 可选 UPGRADE 项并当场定价；API `quote_purchase` / `commit_purchase` |
| 2026-11-04 | v0.7 | **§7.6–7.7** Deckbuilding Options 分类（ArkhamDB 普查）+ 分阶段实现计划；FAQ 1.15/1.16；DB-01–07 |
| 2026-11-04 | v0.8 | **§7.7** 落地 `rules/deckbuilding/*` + 导入字段 + DB-01..07 headless |
| 2026-11-04 | v0.9 | **§7.2.1** Exceptional / Customizable 纳入报价待接；P6b/P6c；OQ-11-10 |
| 2026-11-04 | v0.10 | **§7.2.1** 定制勾选 → EffectiveDeckCardView（traits/tags/level）；准入必须投影后重配位 |
| 2026-11-04 | v0.11 | **P6c Customizable 延后**；重排缺口：P6 报价 → Exceptional / Myriad / 修饰器 / 幕间 |
| 2026-11-04 | v0.12 | **P6–P6b/d/e/f 落地** `InvestigatorCampaignSystem` + XP-01..06；Customizable 仍延后 |
| 2026-11-04 | v0.13 | **§7.5.1** `counts_toward_deck_size`：Permanent / Signature / 弱点 / Bearer 不计；**Myriad 计**；DB-08/09 |
| 2026-11-04 | v0.14 | **§7.7.1** 副职阶/尺寸/特性 = 选调查员后附带玩家选择；`DeckbuildingChoiceFlow`；DB-05 |
| 2026-11-04 | v0.15 | **§7.1.1** Count XP：VD Victory（02111）∪ guide ± ∪ 个人 When earning（06160 / Obol）；`ExperienceCount` |
| 2026-11-04 | v0.16 | **P6e** Arcane Research / Pelt + DtRH 叠用；**SIZE_REFILL** FAQ 1.18；报价 preview 不耗次数；XP-09/10 |
| 2026-11-04 | v0.17 | **§7.1.1** Count 个人通道为 signed delta：额外获得 ∪ *earn N fewer*（Dead Ends / Hospital Debts）；本场 floor 0 |
| 2026-11-04 | v0.18 | **§6** 剧本开局落地：选/换调查员、初始牌库、`prepare_scenario`；CAMP-01..04 |
| 2026-11-04 | v0.19 | **§6** `begin_scenario` + `InvestigatorSetupFlow`（SETUP_02/03/04/07/08）；CAMP-05 e2e |
| 2026-11-04 | v0.20 | **SETUP_06** `ChaosBagCatalog`（Brethren of Ash 四档袋）+ 快照跨场；BAG-01/02 |
