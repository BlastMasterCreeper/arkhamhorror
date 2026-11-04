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

## 6. 剧本状态（CampaignState）

```gdscript
class CampaignState:
    var log: CampaignLog
    var investigators: Array[CampaignInvestigatorRecord]
    var chaos_bag_snapshot: ChaosBagSnapshot
    var difficulty: Difficulty

class CampaignInvestigatorRecord:
    var investigator_id: StringName
    var deck_list: Array[DeckEntry]
    var physical_trauma: int
    var mental_trauma: int
    var unspent_xp: int
    var deckbuilding_choices: Dictionary  ## faction_select / option_select / deck_size_select 解析结果
    var story_assets: Array[StringName]
    var story_weaknesses: Array[StringName]
    var killed: bool
    var insane: bool
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

```
1. Count XP = victory display + guide ± + prior unspent
2. Purchase new cards（属手续）— 窗内逐张交易：NEW_CARD / UPGRADE / CUSTOM_CHECK …
3. 每加 1 张非 Permanent → 须移除 1 张；maintain deck size
4. 遵守 deckbuilding；weakness / required 不可因购卡移除
5. Record unspent XP
```

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
    NEW_CARD 选项 — xp = NEW_CARD 公式（含 DtRH +1 等购新卡修饰）
                   remove_candidates = 为维持尺寸可移除的牌（不含「必须换掉的低级」约束）
  for each 牌组内同 title、level < target.level、可作 upgrade 源的副本（或按 level 聚合）:
    UPGRADE 选项 — xp = (target.level − source.level)（再叠升级种修饰：Arcane Research / DtRH −1…）
                   remove = 该源副本（锁定）
  （Customizable / Researched 等另附合法选项）
```

- 玩家选中**一条**选项后，费用与换出已定，再扣 XP、改牌组、触发「when you purchase / upgrade」类效果。  
- UI 不默认替玩家选 upgrade；只**列出**可选升级项（及全价 NEW_CARD）。  
- 无合格低级源 → 仅 NEW_CARD（或 Researched 禁止 NEW_CARD 时仅升级路径 / 非法）。

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
| `NEW_CARD` | `max(1, level)`；Exceptional → ×2 印刷费用；Myriad 可连带最多 2 张同 level 副本 0 XP | 非 Permanent：+1 须 −1；deckbuilding 准入 |
| `UPGRADE` | `new − old`（无 min-1）；须同 title 且 new > old；Researched 只能走升级且 log 任务已完成 | 移除低级、加入高级（通常净尺寸不变） |
| Exile 后补牌至合法尺寸（FAQ 1.18） | 补足前 L0 可 **0 XP**；DtRH 加价**不**作用于此类补牌（FAQ） | 强制 maintain size |
| `CUSTOM_CHECK` | 1 XP / checkbox；满格才算购得该 upgrade；sheet ≤10 | 已有副本：升级种；新卡带勾选一次付清：NEW_CARD |

| 关键词 | 规则 |
|---|---|
| Permanent | deck creation only；不计 deck size |
| Exceptional | 2× 印刷 XP cost；max 1 copy by title |
| Reward | 解锁后可用；golden corner |
| Bearer | 忽略 deckbuilding；不计 deck size |
| Myriad | 购一张可再 +≤2 同 level 0 XP；计总 XP 时第 2/3 副本不计 |
| Researched | 不可 NEW_CARD 高级；须从低级 UPGRADE + Campaign Log 任务 |
| Customizable | 见上；清空最后副本 → sheet 清空；回购当新卡 |

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

**原则**：消费 ArkhamDB 结构化 `deck_options`；运行时只持有**已解析 Profile**；单卡匹配与整副校验分离；购卡 dry-run 复用同一验证器。

```text
导入
  CardDefinition.tags / traits / factions / level / type / uses / permanent
  InvestigatorDefinition.deck_options[]、deck_requirements
       ↓
构筑前 CHOICE
  解析 faction_select / option_select / deck_size_select
  → DeckbuildingProfile（冻结选型 + 展开后的 ALLOW/LIMIT/FORBID 列表）
       ↓
DeckLegality
  match_card → 有序配位（FORBID → 无限 ALLOW → LIMIT 占坑）
  validate_deck → size / copies / atleast / required / limits 汇总
       ↓
购卡
  filter 候选 + quote_purchase 时 dry-run validate_deck(deck ⊕ choice)
```

| 阶段 | 交付 | 说明 |
|---|---|---|
| **P0 数据** | hydrate `deck_options` → 内部 `DeckOptionRule`；卡面 `tags` | 与 ArkhamDB 键同构；`text` 正则只在导入打标 |
| **P1 匹配核** | `CardAccessMatcher` + FAQ 1.15 有序配位 | 先覆盖谱系 A/B/J（faction+level±越级 limit） |
| **P2 整副** | `validate_deck`：size、≤2 同名、requirements、LIMIT 计数 | 开局构筑硬闸 |
| **P3 选型** | Profile 绑定 `faction_select` / `option_select` / size | 谱系 E/F/G；Charlie 两 id 互异等约束另测 |
| **P4 扩展谓词** | trait / type / tag / uses / permanent / not | 谱系 C/I |
| **P5 多职阶 + atleast** | FAQ 1.16；Lola / 5U-21 | 谱系 H |
| **P6 购卡接线** | `list_accessible` + `quote_purchase` dry-run | 与 §7.2 报价合并；动态 options 修饰 |

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
| DB-04 | Tony：选型 Survivor 后 L0–1 Survivor **事件**可、资产不可超限 |
| DB-05 | Mandy：size 50 时 size 校验 |
| DB-06 | Lola：仅 2 职阶各 7 → atleast 失败 |
| DB-07 | 购卡 dry-run：LIMIT 已满则该卡不进 Offer 候选 |

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
