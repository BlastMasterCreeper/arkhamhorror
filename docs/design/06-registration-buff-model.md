# 06b — Registration 与 Buff 规格 (统一能力模型)

> **依赖**：[06-ability-initiation.md](06-ability-initiation.md), [07-effect-primitives.md](07-effect-primitives.md), [07-composition.md](07-composition.md)  
> **被依赖**：TimingBus、ModifierEngine、Initiation dry-run  
> **状态**：v0.4.18 · 2026-09-21 — ApplicationContext.referents ≠ 历史

---

## 1. 目标

用 **Register / Unregister + Buff + Context** 统一理解全部能力与持续/延时效果。

- **印刷能力类型**（Constant / Forced / [reaction] / [action]）→ 编译期 **tags**，不是运行时分支。
- **状态变更**由 [07-composition](07-composition.md)（Atom 节点）完成。
- **规则变更**由 **RegisterNode** 写入 `RegistrationStore`。
- **Buff 仅三种**；关键词（Surge、Peril…）、Cancel/Replacement **不是** Buff 类型。

---

## 2. 核心对象

```gdscript
class Registration:
    var id: StringName
    var source: SourceRef
    var lifetime: LifetimeSpec
    var scope: ScopeFilter
    var buffs: Array[BuffSpec]
    var tags: Array[StringName]

class BuffSpec:
    var type: BuffType
    var scope: ScopeFilter
    var condition: Condition
    var priority: BuffPriority
    var payload: Variant
    var tags: Array[StringName]
```

| 原语 | 含义 |
|---|---|
| **Register** | `RegistrationStore.register(reg)` |
| **Unregister** | id / filter / lifetime tick |
| **Buff** | `BuffSpec` + payload |
| **Context** | `ApplicationContext`（§9） |

---

## 3. BuffType（三种）

```gdscript
enum BuffType {
    MODIFIER,       # 被动改数值
    RESTRICTION,    # 被动禁止/允许；编译卡面 "cannot …"；Grimoire：cannot 绝对，不得 countermand（07 §3.2）
    LISTENER,       # timing 到点跑 Composition
}
```

| 非 Buff 机制 | 实现方式 |
|---|---|
| Surge（**印刷**） | `CardDefinition.keywords` 含 `surge` |
| Surge（**动态** `gains surge`） | G3 内 Register **KEYWORD 标记** · `WHILE_DRAWN_CARD_RESOLVING(card_id)`；G5 与印刷合并 evaluate，**不叠加**（见 §3.1、[15 §17.4.5](15-timing-entry-catalog.md)） |
| Peril、Aloof、Massive 等其它 **关键词** | `CardDefinition.keywords` + 编译为 MODIFIER/RESTRICTION/LISTENER |
| Cancel / Replacement | [07-composition](07-composition.md) 的 `CancelPending` / `ReplacePending` 节点 |
| Skill Test / Encounter 帧 | `SkillTestContext` 字段 + 子系统读 Context |

### 3.1 涌动（Surge）· 已裁决

**涌动** = 抽到并结算后挂上的 **延时效果**（Grimoire：*After … draws and resolves*）。印刷 `surge` 与 G3 内「gains surge」**不叠加**：至多再开 **一条** 抽 1 张的新指令。**不是** 本条抽牌指令队列里的下一圈 G1。

| 来源 | 引擎表示 | 延时 evaluate |
|---|---|---|
| 牌面印刷 **Surge** | `CardDefinition.keywords` | `CardRegistry.has_surge(def_id)` |
| 效果 **gains surge** | Register **KEYWORD 标记**（无 Composition payload） | `RegistrationStore.has_keyword_buff(card_id, &"surge")` |

**动态 surge 生命周期**：**`WHILE_DRAWN_CARD_RESOLVING(card_id)`** — 与本张遭遇 **结算期间** 绑定（抽出起至本条抽取后）；涌动再抽是新指令，无上一张 surge 标记。

**G3 内 Register 时机**：显现 composition 执行到「gains surge」效果步时 Register；**12124 Cosmic Evils** 仅在选择「受伤害+horror」分支时 Register；**12126 Forbidden Secrets** 在 G3 **入口**判定 `clue == 0` 时 Register 并 **跳过** intellect 分支；**12160 Raising Suspicions** 在 place-doom 步 **未 CREATED** 后 Register（`after_step` 条件，见 [07 §3.3](07-composition.md)）。

**Clues（已裁决）**：*your clues* 默认 = 调查员卡上 clue（`clues_on_card`）。

**本条 AFTER 之后**：`KeywordConsumer` @ `AFTER_DRAWN_CARD` → nest `seq.keyword.surge` → 若 `printed OR dynamic` 则再 nest `seq.draw.encounter`（amount=1）→ **Unregister** 本张动态 surge 标记。

### 3.2 Gained characteristics（动态特征 · 总纲 · 已裁决）

> **Grimoire**：*If a card gains a characteristic (such as an icon, a trait, a keyword, or ability text), the card functions as if it possesses the gained characteristic.*  
> **Gained ≠ printed** — 能力若指「印刷特征」，**不**含 gained；引擎查询须区分 `is_printed_*` 与 `has_effective_*`。

**整合原则（已裁决）**：

1. **Grant / Revoke 入口统一** — Composition L0 `EffectOp.GRANT_CHARACTERISTIC` / `REVOKE_CHARACTERISTIC`（或等价 Register 节点），带 `LifetimeSpec` + `source`。
2. **存储按 kind 分路由** — 不合并 handler；Surge 仍走抽取并结算后的延时、Retaliate 仍 fight 后、Initiation 仍 COLLECT 能力。
3. **查询统一** — `EffectiveCharacteristicQuery`（或 RegistrationStore 门面）：`has_effective_keyword` / `has_effective_trait` / `effective_abilities` / `effective_skill_icons` = **印刷 ∪ gained**（按 kind 叠加规则）。

```text
EffectOp.GRANT_CHARACTERISTIC
  target: card_id | investigator_id
  kind: KEYWORD | TRAIT | ICON | ABILITY
  payload: &"surge" | trait_id | icon | AbilitySpec ref
  lifetime: WHILE_DRAWN_CARD_RESOLVING | DURATION(THIS_TURN) | …
        │
        ├─ KEYWORD  → KEYWORD 标记 Register（无 Composition；§3.1 Surge 为首例）
        ├─ TRAIT    → TRAIT 标记 Register 或 CardInstance overlay
        ├─ ICON     → MODIFIER Register（常为 THIS_SKILL_TEST）或 ICON 标记
        └─ ABILITY  → LISTENER Register + AbilitySpec（until end of turn 等）
        │
        ▼
Effective* 查询 @ 各 consumer（G5 / Initiation / SkillTest / Target）
```

#### 3.2.1 Kind 路由与叠加

| Kind | 典型卡面 | 存储 | 生命周期常见 | 叠加 |
|---|---|---|---|---|
| **KEYWORD** | gains surge / gains Retaliate | KEYWORD 标记 Register | `WHILE_DRAWN_CARD_RESOLVING` 或 `WHILE_IN_PLAY` | **按 keyword 定**（Surge **不叠加**，§3.1） |
| **ABILITY** | gains: `[action]` … until end of turn | `LISTENER` + `AbilitySpec` | `DURATION(THIS_TURN)` / `THIS_PHASE` | 多条并存；各 Limit 独立 |
| **TRAIT** | gains the [[Cultist]] trait | TRAIT 标记 Register | 与 granting 效果同 lifetime | trait 集合 **union** |
| **ICON** | gains [wild]（检定中） | MODIFIER 或 ICON 标记 | `THIS_SKILL_TEST` | 与印刷图标 union |
| **数值** | gets +1 fight | 现有 **MODIFIER** Register | turn / phase / test | ModifierEngine 合并 |

**非本表（非 characteristic）**：`gain N resource` / `gain an action` = 资源/行动 **状态原语**，不走 Gained characteristics。

#### 3.2.2 查询 API（目标 · P0 竖切）

```gdscript
class EffectiveCharacteristicQuery:
    static func has_effective_keyword(card_id: StringName, kw: StringName) -> bool:
        # printed(definition_id) OR RegistrationStore.has_keyword_buff(card_id, kw)

    static func has_printed_keyword(def_id: StringName, kw: StringName) -> bool:
        return CardRegistry.has_keyword(def_id, kw)

    static func effective_abilities(card_id: StringName) -> Array[AbilitySpec]:
        # printed_abilities + gained LISTENER 展开（Initiation COLLECT）

    static func effective_traits(card_id: StringName) -> Array[StringName]:
        # CardDefinition.traits ∪ gained traits
```

**P0 竖切**：`has_effective_keyword` + Surge KEYWORD Register/UnRegister · **`draw_encounter_flow` G5** ✅（`EffectiveCharacteristicQuery` · `EncounterGainedKeyword` · ENC-SURGE-02/03 · GAIN-01）

**P1**：until end of turn 的 `[action]` / `[reaction]` → `GRANT ABILITY` + LISTENER。  
**P2**：trait / icon / 其它 keyword（Retaliate、Aloof…）按扩展包卡面增量。

#### 3.2.3 Core 2026 卡面统计

> 详表：[`data/arkhamdb/reports/core_2026_gained_characteristics.md`](../../data/arkhamdb/reports/core_2026_gained_characteristics.md)（`python tools/backfill_design_tables.py`）

| 模式 | 命中 | 引擎路由 | 备注 |
|---|---:|---|---|
| `gains surge` | 3 | KEYWORD · §3.1 | 12124 / 12126 / 12160 |
| `Deckbuilding Options gains` | 1 | **构筑元数据** · 非运行时 | 12181 Collector |
| `gain N resource(s)` | 9 | L0 资源原语 | 非 characteristic |
| until EOT + `[action]` 等 | 0 | ABILITY · P1 | Core 2026 无；扩展包再扫 |

#### 3.2.4 KeywordProfile：挂载 vs 表征 vs 消费（已裁决）

> **问题**：Listener **何时触发**由 [15 TimingCatalog](15-timing-entry-catalog.md) 的 emit 决定；**关键词本身何时挂载**是另一维度，**不能**统一为「抽取遭遇牌时 Register」。  
> **架构背景**：Grimoire G2–G5 已收成 **`ENCOUNTER_CARD_DRAWN` + FrameworkPriority**（15 §4.0.5.2）；keyword 译法见 [07 §0.1](07-effect-primitives.md#01-规则参数字段ruleparameter--信息型卡面描述) 三档（① Spec / ② 砖块 / ③ 编译订阅）。

**三层（勿混为一步 Register）**：

| 层 | 问什么 | 与 Listener 的关系 |
|---|---|---|
| **① 挂载 mount** | 规则上从何时起 **算拥有** keyword？ | 可 **早于** Listener 首次触发（Hunter） |
| **② 表征 representation** | 引擎如何存「有」？ | Listener 是表征之一，非全部 |
| **③ 消费 consume** | 哪个 handler **读**并执行？ | 由编译出的 **BuffType** 决定（§3.2.5）：RESTRICTION 查询 / LISTENER fire / MODIFIER 结算；**禁止**写进父管线砖块 |

```text
mount_moment     = 规则要求 card 最早具备 keyword 的 instant
representation   = DEFINITION | KEYWORD 标记 | 三种 Buff（MODIFIER / RESTRICTION / LISTENER）
unmount_moment   = 规则上不再具备 / 引擎卸表征
consumer_slot    = 读 effective 并做事的站点（可与 mount 不同步）
listener_trigger = 若表征含 LISTENER，Catalog emit 名（无则 —）
```

**`mount_moment` 枚举（增长表用）**：

| 值 | 含义 | 典型 |
|---|---|---|
| `AT_PRINT` | 印刷在 `CardDefinition.keywords`；实例存活期有效 | Surge、Aloof 印刷 |
| `LAZY_AT_CONSUMER` | 不单独挂载；consumer 读 Definition 即可 | 印刷涌动 @ `AFTER_DRAWN_CARD` |
| `AT_DRAW_G2` | 遭遇 G2 check peril（priority 100） | Peril 印刷 |
| `AT_ENTER_PLAY` | 进场 / enemy spawn 完成 | Hunter、Retaliate |
| `AT_REVELATION` | 显现子流程内（E4 / D3） | Hidden treachery |
| `AT_GRANT` | 效果步「gains X」resolve 瞬间 | gains surge / gains [action] |
| `AT_SETUP` | Setup / game begins | 绑定 set-aside；永久开场进场 |
| `AT_DEFEAT` | 击败结算内核读 | Doomed、Victory 敌人 |
| `AFTER_MULLIGAN` | 起手+换牌之后 | Starting |
| `AFTER_ENTER_PLAY` | 进场指令结算完毕之后 | Swarming X；Uses 也可作进场后缀 |

**兼容规则（已裁决）**：

1. **印刷 vs gained 共享 `consumer_slot`**，只改 `mount_moment` 与 `representation` 来源。  
2. **`AT_DRAW_G2` 不是 keyword 通用挂载点** — 仅 **早生效** keyword（Peril）使用。  
3. **晚判定 keyword**（Surge）：印刷 = `LAZY_AT_CONSUMER` 或进场/抽出后挂 **LISTENER**；gained = `AT_GRANT` + **KEYWORD 标记**（只表示拥有）再编译同一 LISTENER。Listener 开火时 nest `seq.draw.encounter`。当前 `KeywordConsumer` 是这条延时 LISTENER 的竖切，不是第四种 Buff。  
4. **G4 `unregister_by_drawn_card` 只卸 RESTRICTION**（Peril）；**不卸** KEYWORD 标记（涌动须留到 LISTENER 开火）。  
5. 新 keyword **先定编译成哪一种（或几种）Buff**（§3.2.5），再加 `KeywordProfile`。**猎物 / 生成是指令，不进本表。** **禁止**为每个 keyword 新建 BuffType；**禁止**写进父管线优先队列；**禁止**为单卡 proliferate `seq.check_*`。

**目标 API（P1+）**：

```gdscript
class KeywordProfile:
    var keyword: StringName
    var buff_types: Array[StringName]  # 子集 of MODIFIER | RESTRICTION | LISTENER；可叠加
    var mount_printed: StringName      # AT_PRINT | AT_DRAW_G2 | …
    var mount_gained: StringName       # AT_GRANT | …
    var unmount: StringName
    var listener_trigger: StringName   # LISTENER 的 Catalog emit；否则 &""
    var consume_flow_id: StringName    # LISTENER 开火 payload 若是命名 seq；否则 &""
    var register_flow_id: StringName   # seq.draw.encounter | seq.setup | &""（zone）
    var register_slot: StringName      # G2 | G4 | WHEN | AFTER | ENTER_PLAY | …
    var unregister_flow_id: StringName
    var unregister_slot: StringName
    var armed_zone: StringName         # PLAY | LIMBO | HAND | DECK | SET_ASIDE
    var lifetime_kind: StringName      # WHILE_IN_PLAY | WHILE_IN_DECK | UNTIL_FIRED | …

class KeywordMountService:
    static func mount_printed(ctx, card_id, profile) -> void  # 按 buff_types Register
    static func mount_gained(ctx, card_id, profile, provenance) -> void
    static func unmount(ctx, card_id, profile) -> void
```

**拥有 ≠ 行为**：gained 先 Register **KEYWORD 标记**（`has_effective_keyword`）；再按同一 `buff_types` 编译出真正的 MODIFIER / RESTRICTION / LISTENER。印刷可跳过标记、直接挂 Buff（或 lazy 到查询）。

`KeywordConsumer.consume_at(slot)` 只是 **延时 LISTENER 尚未接入 TimingCatalog 时** 的竖切：遍历 `buff_types` 含 LISTENER 且带 `consume_flow_id` 的行。RESTRICTION 由 Eligibility 查询；其它 LISTENER 由 Catalog emit；MODIFIER 由 ModifierEngine 结算。

##### Core 2026 · KeywordProfile 填表（遭遇 + 敌人 · 印刷路径）

> 卡量来源：Phase 4 回填 · [§16.8.3](#1683-listener--§165-增长) / [15 §17.14](15-timing-entry-catalog.md#1714-core-2026-遭遇卡清单arkhamdb-回填)  
> **校正**：qty 以首行 `Name.` 印刷为准；**猎物 / 生成不在本表**（§3.2.5）。

| keyword | Core 2026 约 qty | BuffType | mount（印刷） | unmount | 消费 | 备注 |
|---|---:|---|---|---|---|---|
| **surge** | 3 首行 | **LISTENER**（延时） | `LAZY` / 抽出后 | LISTENER 开火后卸标记 | After 本条抽取 · nest 再抽 | 竖切 `KeywordConsumer`；不进抽牌优先队列 |
| **peril** | 2 | **RESTRICTION** | **`AT_DRAW_G2`** | G4 初 Unregister | L4 REST-E-PLAY/TRIGGER/COMMIT | 挂载即生效 |
| **hidden** | **0** 印刷 | **RESTRICTION** + Domain 揭示 | **`AT_REVELATION`** | expose / 合法离手 | REST-E-MOVE | Core 无印刷隐私；ArkhamDB `hidden` 旗标 ≠ 本词 |
| **aloof** | 6 | **RESTRICTION** | `AT_ENTER_PLAY` | leave play | 禁自动交战；未交战 cannot Fight | spawn 内核读「拥有」以跳过 auto engage |
| **hunter** | 12 敌人 | **LISTENER** | **`AT_ENTER_PLAY`** | leave play | `@ seq.enemy.3_2` 移动 | 12074 导入误伤 |
| **retaliate** | 9 | **LISTENER** | **`AT_ENTER_PLAY`** | leave play | Fight 失败 post-ST7 → attack | 与 Alert 同攻击层 |
| **massive** | 2 | **RESTRICTION** + 交战修正 | **`AT_ENTER_PLAY`** | leave play | 永不进威胁区；虚拟交战 | 3.3 读交战结果，不另开 keyword seq |
| **permanent** | 1 | **RESTRICTION** + 构筑 | **`AT_SETUP`** | 仅卡面允许离场 | REST-E-MOVE | 兼 Reward；不计牌组规模走构筑 |

#### 3.2.5 实现路径：指令 / 参数 / 关键词 Buff（已裁决）

> **Buff 仅三种**（§3）：`MODIFIER` / `RESTRICTION` / `LISTENER`。关键词 **不是** 第四种 Buff。  
> **先定档再接线**：指令 → Spec；参数 → Spec 挂在指令或关键词上；关键词 → 拥有 + 编译 Buff（可叠加）。

```text
卡面印刷
 ├─ 指令   Spawn – / Prey –     → CardDefinition.*Spec → ② 内核 Resolver
 ├─ 参数   括号 / X / type      → 挂在指令或关键词的 Spec 上 → handler 内同步读
 └─ 关键词                      → 拥有（印刷 ∪ KEYWORD 标记）
      ├─ RESTRICTION            Eligibility / Intent 查询
      ├─ LISTENER               Catalog emit → Composition（延时 = UNTIL_FIRED）
      ├─ MODIFIER               ModifierEngine / Initiation 成本
      ├─ L0 / Domain            Uses 放 token、Victory 改去向、Seal 封印
      └─ 构筑                   11；对局不消费
```

**禁止**：为关键词新增 BuffType；把指令/参数写成 keyword 或 nest `seq.keyword.*`；把所有关键词塞进 `AFTER_DRAWN_CARD`。

##### A. 指令（不是关键词）

RR *enemy instructions (spawn and prey)* · [07 §0.1.2](07-effect-primitives.md#012-敌人指令spawn-与-prey已裁决)。

| 指令 | 提供 | Spec | 读参内核（②） | 实现路径 | 现状 |
|---|---|---|---|---|---|
| **Spawn –** | **WHERE** 进场地点 | `SpawnInstructionSpec` | G4 / enters play · `SpawnLocationResolver` | 导入编译 Spec；无文本 → `FRAMEWORK_DEFAULT`；有文本 → 同内核改落点；L0 进场在 spawn 砖块 | ✅ |
| **Prey –** | **WHO** 交战/等距人选 | `PreyInstructionSpec` | `auto_engage_at_location`；猎手 LISTENER 等距分支 · `PreyResolver` | 导入编译 Spec；**不**进 G4 落点；**禁止** LISTENER / Buff | ✅ |

无 Spawn 文本不是「缺指令」，是默认生成。猎物对 spawn location **无效果**。

##### B. 参数（① Spec，挂在指令或关键词上）

只改 **已在进行的** 内核/LISTENER 里的选点、选人、数量、类型。本身不执行效果、无独立 timing。

| 参数 | 挂在 | Spec | 谁读 | 实现路径 | 现状 |
|---|---|---|---|---|---|
| Spawn 地点选择器（farthest empty / named / …） | **指令** Spawn – | `SpawnInstructionSpec.selector` | `SpawnLocationResolver` | 与指令同一 Spec，不另开类型 | ✅ |
| Prey `(lowest [agility])` 等 | **指令** Prey – | `PreyInstructionSpec` 比较/过滤 | `PreyResolver.best_match` | 等距或同地点子集内比较；并列 Lead | ✅ |
| Patrol `(地点 / 目标)` | **关键词** 巡逻 | `PatrolTargetSpec` | 3.2 LISTENER handler 内 `PatrolTargetResolver` | **不是** 第三条指令；括号不 Register | △ 测试合成 |
| Uses `(X type)` 的 X 与 type | **关键词** Uses | `UsesSpec {count, type}` | 进场 L0 放 token；能力 cost 扣同 type | 禁止把 ammo 当成 charges | Domain `uses` 有；Spec 未模块化 |
| Victory **X** | **关键词** Victory | 标量 `victory: int` | 击败 / 场景结束改去向 | 不是 Buff | ✅ |
| Swarming **X** | **关键词** Swarming | 标量 count | 延时 LISTENER payload | 垫 X 张 facedown swarm | Core 无 |
| Seal 选哪个 token | **关键词** Seal | `SealSpec` | 打出成本 / 进场 L0 | `CHAOS_PICK` | Choice 已列；无卡 |

**禁止**：为括号单独 nest、单独 Register；把 Prey 括号当 Forced。

##### C. 关键词 → 三种 Buff

**拥有 ≠ 行为**。gained 先 KEYWORD 标记（`has_effective_keyword`），再按同一 `buff_types` 挂 Buff。印刷可直接挂 Buff（或 lazy 到查询）。一张卡可叠加多种（Elokoss：庞大 RESTRICTION + 反击 LISTENER）。

**C1 · RESTRICTION**（Eligibility / Intent 查询；mount 即生效）

| 关键词 | mount | Lifetime | payload / Intent | 消费 | 现状 |
|---|---|---|---|---|---|
| **Peril** 险境 | `AT_DRAW_G2` | `WHILE_DRAWN_CARD_RESOLVING` | `FORBID_PLAY` / `TRIGGER` / `COMMIT`（非 drawer） | L4 | ✅ |
| **Hidden** 隐私 | `AT_REVELATION` | 在手直至 expose | `FORBID_LEAVE_HAND`；另写 Domain `is_hidden` / FaceAudience | REST-E-MOVE；E4 秘密入手 | 运行时有；导入把 ArkhamDB `hidden` 旗标误当本词 |
| **Aloof** 冷漠 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | 禁自动交战；未交战 `FORBID` Fight | Fight / Engage Intent；spawn 内核读拥有以跳过 auto engage | ✅ |
| **Massive** 庞大 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | 永不进威胁区；虚拟交战同地点全体 | Engage / AOO / 3.3 读交战结果 | ✅ |
| **Permanent** 永久（对局） | `AT_SETUP` 开场进场 | 直至卡面允许离场 | `FORBID_MOVE` 离场 | REST-E-MOVE | △ Domain 旗标 |
| **Unique** 独特 | 打出/进场前查询 | in-play 期间 | 同名已在场 → 拒绝进场 | Initiation L5 | 待接线 |

**C2 · LISTENER**（Catalog emit；延时用 `UNTIL_FIRED`）

| 关键词 | mount | Lifetime | trigger | 开火 payload | 现状 |
|---|---|---|---|---|---|
| **Hunter** 猎手 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | `(seq.enemy.3_2, WHEN)` | 向最近调查员移 1 步；等距内读 **Prey 指令** | △ `enemy_phase_flow` 按名分支 |
| **Patrol** 巡逻 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | 同 3.2 | 向 **Patrol 参数** 移 1 步 | △ |
| **Retaliate** 反击 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | Fight 失败 · post-ST7 | `perform_attack(RETALIATE)` | ✅ |
| **Alert** 警戒 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | Evade 失败 · post-ST7 | `perform_attack(ALERT)` | ✅ 未进 `keywords[]` |
| **Elusive** 逃逸 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | 敌人攻击后 / 被 Fight 后 | disengage → 相邻 → exhaust | ✅ 未进 `keywords[]` |
| **Doomed** 厄运降临 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | 击败（非 discard） | 当前密谋 +1 毁灭 | ✅ 未进 `keywords[]` |
| **Surge** 涌动 | 印刷 lazy；gained `AT_GRANT` | 绑本条抽取；开火后卸标记 | 本条抽取 **AFTER**（已结算） | nest `seq.draw.encounter` amount=1 | ✅ `KeywordConsumer` 竖切 |
| **Starting** 起始 | `AT_SETUP` / 换牌后 | `UNTIL_FIRED` | 起手+mulligan 之后 | 检索 1 张 Starting 入手 | 无 |
| **Swarming** | `AFTER_ENTER_PLAY` | `UNTIL_FIRED` | 进场结算之后 | 垫 **X** 张 swarm 牌 | Core 无 |

涌动不是新 BuffType。`KeywordConsumer` 只是该 LISTENER 尚未接入 TimingCatalog 时的竖切。

**C3 · 快速：打出形式，不是能力、也不是单独成本政策**

快速（Fast）为 **事件打出 ↔ 支援触发** 的窗口/花费对称而设。**打出始终是 `PLAY_CARD`，不是能力**（[06-ability-initiation §4.2](06-ability-initiation.md#42-打出与触发对称fast打出-不是-能力)）。

| 打出形式 | 窗口/花费对称 | 种类 |
|---|---|---|
| 无 Fast | 激活触发 `[action]` | `PLAY_CARD` |
| Fast、无时点（含无时点快速支援） | 免费触发 `[free]` | `PLAY_CARD` |
| Fast、有时点 | 反应触发 `[reaction]` | `PLAY_CARD` |

编译：`KeywordProfileTable.play_form`。**禁止** 把打出收成 `ABILITY`；**禁止** 与 ArkhamDB `[fast]` 文本符号合并。

| 关键词 | mount | 改什么 | 消费 | 现状 |
|---|---|---|---|---|
| **Fast.** 快速 | 印刷；从 **HAND** 打出 | 选打出形式（上表） | 打出管线 | △ |

**C4 · 不走三种 Buff 的关键词**

| 关键词 | 落地 | 实现路径 | 现状 |
|---|---|---|---|
| **Uses (X)** | L0 进场放 typed token | 读 **B** 的 `UsesSpec`；扣 uses 走能力 cost | Domain 有 |
| **Victory X** | Domain 去向 | 击败敌人 / 场景结束已揭示无线索地点 → 胜利展示区 | ✅ |
| **Vengeance X** | 同去向，计分语义相反 | 与 Victory 共用展示区 | Core 无 |
| **Seal** | L0 封印混乱标记 | 打出成本或进场；离场释放 | Choice 已列 |
| **Permanent** 永久（牌组规模） | 构筑 | 不计 deck size；开场进场见 C1 | △ |
| **Exceptional / Myriad（多重） / Reward / Researched / Bonded（绑定） / Customizable** | 构筑 | [11](11-investigator-campaign.md) | Collector 有 Reward |

**不是关键词、也不是指令/参数**：Exile（能力）、`[fast]` / `[reaction]` / `[action]`、Forced、Revelation、Bearer。

##### 同卡多轨（对照）

```text
Servant of Flame：Hunter. Prey (lowest [agility]). Retaliate. Victory 2.
  猎手     → LISTENER @ 3.2
  猎物     → 指令 Spec（3.2 等距 / auto engage 读）
  反击     → LISTENER post-ST7
  Victory 2 → Domain 标量，击败改去向

巡逻敌人：Patrol (Miskatonic Quad). Prey (fewest remaining health).
  巡逻     → LISTENER @ 3.2
  括号地点 → PatrolTargetSpec（handler 内读）
  猎物     → 指令 Spec（移动后 auto engage / 等距）

资产：Fast. Uses (4 ammo).
  快速     → PLAY_FAST_WINDOW（无时点打出；种类仍是打出）
  Uses     → L0；参数 X=4 type=ammo
```

##### 接线顺序

1. 导入：首行 `Name.` → `keywords[]`；`Spawn –` / `Prey –` / 括号 → 对应 Spec，**不**进 keywords。
2. `KeywordProfile.buff_types` → AbilityCompiler 模板 Register；**禁止**新 BuffType。
3. RESTRICTION 模板：险境为样板；隐私、冷漠、庞大、永久、独特共用 mount。
4. LISTENER 模板：3.2 猎手/巡逻收 emit；反击/警戒/逃逸已有内核；涌动竖切收成 After-draw LISTENER。
5. 快速：打出形式（`play_form`），种类仍是 `PLAY_CARD`，不 Register LISTENER。
6. 参数 Spec：Uses / Seal 补齐；Patrol 括号已有测试路径。
7. 构筑类不进 `KeywordConsumer`。

##### 印刷 vs gained（同一 Buff 模板）

| keyword | 印刷 | gained | 行为 |
|---|---|---|---|
| surge | lazy / LISTENER | KEYWORD 标记 + 同 LISTENER | 延时再抽 |
| peril | RESTRICTION | 同模板立刻 | L4 |
| hunter | LISTENER | LISTENER `WHILE_IN_PLAY` | 3.2 |
| retaliate | LISTENER | 同 LISTENER | post-ST7 |
| aloof | RESTRICTION | 同 RESTRICTION | Fight/Engage |

##### 时间线（险境 RESTRICTION vs 涌动 LISTENER）

```text
G2  Peril mount RESTRICTION
G3  可能 AT_GRANT surge → KEYWORD 标记
G4  unmount Peril RESTRICTION（标记保留）
AFTER 本条抽取
  LISTENER 涌动开火 → nest seq.draw.encounter → 卸标记
```

#### 3.2.6 LISTENER / Buff 的注册与注销场合（已裁决）

> **问题**：支援资产的 Forced / `[reaction]` 可以 **进场 Register、离场 Unregister**（`WHILE_IN_PLAY`）。关键词和不少能力 **不在场上** 也要生效（涌动在暂存区、隐私在手、起始在牌库）。`on_card_leave_play` **只卸** `WHILE_IN_PLAY`，不能当唯一注销钩。
>
> **绑已有流程，不另开场合节点**：禁止 `PERIL_CHECK`、`DRAWN_CARD_FINALIZE`、`CARD_DRAWN` 一类 **只为挂载发明的独立钩**。注册/注销要么是 **已有 `seq.*` handler 里的砖**（G2 / G4 / WHEN / AFTER），要么是这些流程 **已经在做的 zone 变迁**（`ENTER_PLAY` 等 L0）。

**与能力 LISTENER 同一套 API**：`RegistrationStore.register` / `unregister`；差别只在 **绑哪条流程的哪一砖 / 哪次 zone 变迁**，不是第二套监听总线。

##### 两类锚（不是第三套 enum）

| 类 | 绑什么 | 例子 |
|---|---|---|
| **A. 已有 seq 砖** | `register_flow_id` + `register_slot` | 险境 Register = `seq.draw.encounter` **G2**（已有 `_step_peril_register`）；卸 = 同流程 **G4**（已有 `_step_g4_resolve`） |
| **B. 已有 zone 变迁** | `register_flow_id` 可空；`register_slot` = `ENTER_PLAY` / `LEAVE_PLAY` / `ENTER_HAND` / `LEAVE_HAND` / `ENTER_SET_ASIDE` / `LEAVE_SET_ASIDE` | 猎手：spawn / 打出里的 L0 进场；隐私：`seq.encounter.revelation` 秘密入手 |

`GRANT` = 效果 Register 砖（已有 Composition）；`FIRED` = `UNTIL_FIRED` 跑完自卸（已有 Lifetime）。二者都不是新检查节点。`seq.setup` = 现有开局管线（`ScenarioSetupFlow` / 换牌 / 游戏开始），不是为关键词另开的场合节点。

```text
on_card_leave_play(card)
  先：COLLECT When/After defeated（仍 WHILE_IN_PLAY）
  再：unregister lifetime == WHILE_IN_PLAY
  不碰：WHILE_DRAWN_CARD_RESOLVING / WHILE_HIDDEN_IN_HAND / WHILE_IN_DECK
        / WHILE_SET_ASIDE / UNTIL_FIRED / DURATION
```

**禁止**：`seq.encounter.check_peril` / `PERIL_CHECK` 场合；为 G4 另起 `DRAWN_CARD_FINALIZE` 顶层钩；为抽牌步骤另起 `CARD_DRAWN` 顶层钩（抽牌步骤已是 `seq.draw.*` WHEN）。

##### 关键词：绑哪条流程 / 哪一砖

| 关键词 | Buff | 注册 | 注销 | Lifetime | 武装时 zone |
|---|---|---|---|---|---|
| **Surge** 涌动 | LISTENER 延时 | `seq.draw.encounter` **WHEN**（抽取步骤后；gained：效果 `GRANT` 砖） | 同流程 **AFTER** 开火 = `FIRED` | `UNTIL_FIRED` | **LIMBO** |
| **Peril** 险境 | RESTRICTION | `seq.draw.encounter` **G2** | 同流程 **G4**（`unregister_by_drawn_card`；**不是** `LEAVE_PLAY`） | `WHILE_DRAWN_CARD_RESOLVING` | **LIMBO** |
| **Hidden** 隐私 | RESTRICTION | `seq.encounter.revelation` / `seq.enter_hand` 的 **ENTER_HAND** | **LEAVE_HAND** | `WHILE_HIDDEN_IN_HAND` | **HAND** |
| **Aloof / Massive** | RESTRICTION | **ENTER_PLAY**（`seq.encounter.spawn` / 打出已有 L0） | **LEAVE_PLAY** | `WHILE_IN_PLAY` | PLAY |
| **Hunter / Patrol** | LISTENER | **ENTER_PLAY** | **LEAVE_PLAY** | `WHILE_IN_PLAY` | PLAY |
| **Retaliate / Alert / Elusive** 逃逸 | LISTENER | **ENTER_PLAY** | **LEAVE_PLAY** | `WHILE_IN_PLAY` | PLAY |
| **Doomed** 厄运降临 | LISTENER | **ENTER_PLAY** | 击败内核开火后随 **LEAVE_PLAY** | `WHILE_IN_PLAY` | PLAY |
| **Swarming** 蜂拥 | LISTENER 延时 | **ENTER_PLAY** | 进场父流程 **AFTER** = `FIRED` | `UNTIL_FIRED` | PLAY |
| **Starting** 起始 | LISTENER 延时 | `seq.setup` 开局（牌在库） | 同流程换牌后砖 **AFTER** = `FIRED` | `WHILE_IN_DECK` + `UNTIL_FIRED` | **DECK** |
| **Permanent** 永久 | RESTRICTION | `seq.setup` 放入场 = **ENTER_PLAY**（**不是**从手打出） | 仅卡面允许离场或拥有者淘汰 | `WHILE_IN_PLAY` | PLAY |
| **Fast.** 快速 | 打出形式 | **不** Register LISTENER | — | 无 | **HAND**；种类始终 `PLAY_CARD` |
| **Unique** 独特 | RESTRICTION | 第一份 copy **ENTER_PLAY** | 该 copy **LEAVE_PLAY** | `WHILE_IN_PLAY` | PLAY |
| **Uses / Victory / Seal** | L0 / Domain | 进场放记 / 击败改去向 / 打出封印 | Uses 随离场清 token；Seal 离场释放 | 不走 LISTENER | PLAY 或击败瞬间 |
| **Bonded** 绑定 | 构筑 + `WHILE_SET_ASIDE` | `seq.setup` **ENTER_SET_ASIDE** | 宿主打出后 **LEAVE_SET_ASIDE** | `WHILE_SET_ASIDE` | **SET_ASIDE** |
| **Exceptional / Myriad** 多重 / Reward / Researched / Customizable | 构筑 | **不** Register | — | 无 | 对局不武装 |

**gained 关键词**：效果 `GRANT` 砖时源卡在哪，Buff 就挂在哪。`gains surge` 在 LIMBO → 涌动 LISTENER，Lifetime 仍绑本条抽取，**不**改成 `WHILE_IN_PLAY`。`gains Retaliate` 在场 → 与印刷反击同一 **ENTER_PLAY**。

##### 能力 LISTENER（对照，同样不只有进场）

§8 旧表「印刷 Forced = enter_play」只覆盖支援资产。完整场合：

| 能力 | 注册 | 注销 | Lifetime | 武装时 zone |
|---|---|---|---|---|
| 资产 / 敌人 Constant、Forced、`[reaction]`、`[action]`、`[free]` | **ENTER_PLAY** | **LEAVE_PLAY** | `WHILE_IN_PLAY` | PLAY |
| 地点 Constant / `[free]` | 地点揭示进场 | 地点离场 / 被替换 | `WHILE_IN_PLAY` | PLAY |
| 密谋 / 场景 Forced、Constant | 成为当前卡（`seq.setup` 或推进后进场） | **翻面离场**（a 面卸 `WHILE_IN_PLAY`；效果造的 `DURATION`/`UNTIL_FIRED` **保留**） | `WHILE_IN_PLAY` | PLAY |
| 调查员卡能力 | `seq.setup`（调查员开局即在场） | 淘汰 **LEAVE_PLAY** | `WHILE_IN_PLAY` | PLAY |
| **显现** Revelation | **不**长期 Register；抽到时 nest `seq.encounter.revelation` / `seq.enter_hand` | 子流程 pop | 无 | LIMBO / 入手瞬间 |
| 隐私牌上的 Constant / Forced / `[reaction]` | **ENTER_HAND**（与 Hidden 同时） | **LEAVE_HAND** | `WHILE_HIDDEN_IN_HAND` | **HAND** |
| Fast 事件「Play when/after …」 | **不**挂场上 LISTENER；`PLAY_FAST_TIMING`，种类仍是 `PLAY_CARD` | 打出后进 limbo 结算 | 无 | **HAND** |
| 效果创造的延时 | 效果 `GRANT` / Register 砖 | `FIRED` | `UNTIL_FIRED` | 不绑源卡 zone |
| 效果创造的持续 | 效果 Register 砖 | Duration tick；**默认不**随源卡离场（`WHILE_SOURCE_IN_PLAY` 才绑） | `DURATION` / `WHILE_SOURCE_IN_PLAY` | 任意 |
| 绑定 被召唤前 | `seq.setup` **ENTER_SET_ASIDE** | **LEAVE_SET_ASIDE** | `WHILE_SET_ASIDE` | **SET_ASIDE** |
| 牌库里尚未抽出的弱点 Forced | **不** Register | 抽出后再按 cardtype 走显现/进场 | — | DECK（未武装） |

**显现 vs 监听**：显现是抽牌流程里的一次性 nest，不是 `WHILE_IN_PLAY` LISTENER。不要在 `ENTER_PLAY` 给 treachery 挂显现。

##### 接线（已有流程里调 Store，不另开钩名）

| 已有流程 / L0 | 做什么 |
|---|---|
| `seq.encounter.spawn` / 打出落场 → **ENTER_PLAY** | Register `WHILE_IN_PLAY` 关键词与能力 |
| 离场 L0 → **LEAVE_PLAY** | **仅**卸 `WHILE_IN_PLAY`（先跑 defeated LISTENER） |
| `seq.draw.encounter` **WHEN** | 涌动 LISTENER（印刷）；不挂 Hunter |
| `seq.draw.encounter` **G2** | 险境 RESTRICTION（已有 `_step_peril_register`） |
| `seq.draw.encounter` **G4** | `unregister_by_drawn_card`：**仅**该卡 Peril RESTRICTION；**不**卸 KEYWORD 标记 / 涌动 LISTENER |
| `seq.encounter.revelation` / `seq.enter_hand` → **ENTER_HAND**；离手 L0 | `WHILE_HIDDEN_IN_HAND`、`WHILE_IN_HAND` |
| 离库 L0 | `WHILE_IN_DECK`（Starting 离开牌库） |
| **LEAVE_SET_ASIDE** | `WHILE_SET_ASIDE`（绑定被召唤） |
| `seq.setup` | Starting 在库；永久 **ENTER_PLAY**；绑定 **ENTER_SET_ASIDE**；换牌后砖开火 Starting |
| listener 跑完 | `UNTIL_FIRED` 自卸 |

**禁止**：用 `on_card_leave_play` 清涌动/险境；把 Fast 事件当成进场 LISTENER；把显现 Register 成 `WHILE_IN_PLAY`；为险境/G4/抽取步骤发明独立场合节点。

---

## 4. 持续 vs 延时：只有 Lifetime 不同

**持续效果**与**延时效果**本质都是 **Register**；玩家用语差别在 **`LifetimeSpec`**：

| 玩家说法 | LifetimeSpec | 典型 Buff | Registration 何时消失 |
|---|---|---|---|
| **持续效果** | `DURATION(...)` / `WHILE_*` | MODIFIER、RESTRICTION、LISTENER | 到期或条件满足 |
| **延时效果**（一次性） | `UNTIL_FIRED` | 通常 LISTENER | **第一次** listener 跑完后 Unregister |
| **持续能力（Constant）** | `WHILE_IN_PLAY` | MODIFIER / LISTENER | 源卡 leave play |

**不存在** LastingRegistry / DelayedRegistry；仅 **RegistrationStore**。

卡面把「获得持续/延时/Cannot/涌动」当效果写出来时，创建本身走命名流程 **`seq.effect.register`**（参数 = `RegistrationTemplate`）；CREATED = 插入成功。管线里为父手续挂载的 Register（G2 险境、进场 Hunter）仍是该父 seq 的砖，不另开 `PERIL_CHECK`。见 [07-composition §1.3.3](07-composition.md#133-catalog-必须覆盖一切可解释效果纸面可以无名)。

### 4.1 合法性（dry-run）

创建 Registration **即** 直接影响（见 [07-composition §4](07-composition.md)）。  
**不**检查创建后 Buff 是否退化、Listener 是否会触发。

---

## 5. 持续生命周期内的 Listener（重要）

### 5.1 一条 Registration，不是两层延时

例：**Until end of your turn, after you fight, draw 1 card.**

```gdscript
Registration {
    lifetime: DURATION(THIS_TURN),
    scope: controller = performer,
    buffs: [
        ListenerBuff {
            timing: AFTER_YOU_FIGHT,
            composition: Draw(1),    # 效果组合，见 07-composition
        },
    ],
}
```

- **持续** = 整条 Registration 活到 **回合结束**（`tick_durations(THIS_TURN)` → Unregister）。
- **Listener** = 生命周期 **内** 每次 `AFTER_YOU_FIGHT` 跑 `Draw(1)`。
- **不是** 内层再 Register 一个 `UNTIL_FIRED` 的「嵌套延时」；就是 **普通 Listener**。

### 5.2 两个时间轴

| 概念 | 含义 |
|---|---|
| **Registration 生命周期** | 规则条 **挂到何时**（turn / phase / test / in-play） |
| **Listener timing** | 生命周期 **内** 哪些时点 **执行** 子 composition |

### 5.3 时间线示例（单回合）

```text
T0  Event resolve → Register（DURATION THIS_TURN + Listener after fight）
T1  Investigate    → 不触发
T2  Fight #1       → Listener → Draw(1)
T3  Fight #2       → Listener → Draw(1)   （除非 Limit once…）
T4  Turn ends      → Unregister → 之后 fight 不再 Draw
```

T0 合法性：Register **已创建** 即通过；**不要求** T2/T3 发生。

### 5.4 多 Buff 同壳

**Until end of investigation phase, you get +1 [willpower], and after you discover a clue, draw 1.**

```text
Registration {
  lifetime: DURATION(THIS_INVESTIGATION_PHASE),
  buffs: [
    Modifier(+1 WILL),
    Listener(AFTER_DISCOVER_CLUE, Draw(1)),
  ],
}
```

一个 Lifecycle 罩住 Modifier + Listener；**一次 RegisterNode**。

### 5.5 与纯延时对比

**At the start of the next mythos phase, draw 1 card.**

```text
Registration {
  lifetime: UNTIL_FIRED,
  buffs: [ Listener(MYTHOS_1_1, Draw(1)) ],
}
```

| | 持续壳 + Listener | 纯延时 |
|---|---|---|
| Lifetime | `DURATION(...)` | `UNTIL_FIRED` |
| Listener 触发次数 | 寿命内 **可多次** | 通常 **一次**（整段 Unregister） |
| 典型文本 | until end of **turn/phase** | at start of **next** …（一次） |

### 5.6 与 Constant 对比

Asset：**After you fight, draw 1**（Constant）

```text
Registration {
  lifetime: WHILE_IN_PLAY,
  buffs: [ Listener(AFTER_YOU_FIGHT, Draw(1)) ],
}
```

与 Event「until end of **your turn**…」结构相同；仅 Lifetime 为 `THIS_TURN` vs `WHILE_IN_PLAY`。

---

## 6. MODIFIER

在 **ModifierQuery** 时改数值（技能、shroud、伤害量、cost…）。Constant 与 Lasting **相同 Payload**，仅 Lifetime 不同。

```gdscript
class ModifierPayload:
    var stat: StatRef
    var op: ModOp
    var value: int
    var stacking: StackingGroup
```

叠加：加算/减算 → 乘除 → ceil → 下限 0（Grimoire Modifiers）。

---

## 7. RESTRICTION

Initiation **dry-run** 与行动合法性：能否打出、移动、commit 等。**统一** `RestrictionEvaluator.block_reason`（L4 / Action / SkillTest / EffectGraph step 4）。

**应用场合**不由规则序列步数决定，而由 **[§16 Buff 应用场合清单](#16-buff-应用场合清单裁决方法)** 的 **Intent × 入口** 主表决定；新增 cannot 时先查 §16.4，再扩 `RestrictionKind` / `Intent` / 接线入口。

```gdscript
class RestrictionPayload:
    var kind: RestrictionKind   # FORBID_DRAW | FORBID_PLAY | FORBID_TRIGGER | FORBID_COMMIT_TO_TEST | …
    var drawer_id: StringName     # 险境 E3：豁免 actor
    var encounter_frame_id: StringName

enum LifetimeKind {
    …
    WHILE_ENCOUNTER_FRAME,   # 非 peril；peril 用 WHILE_DRAWN_CARD_RESOLVING
    WHILE_DRAWN_CARD_RESOLVING,   # 险境 E3 Register；G4 完 Unregister；不跨 Surge
}
```

**险境（Peril）译法** — **ENCOUNTER_CARD_DRAWN** timing · priority **100** · nest Register RESTRICTION；Lifetime **`WHILE_DRAWN_CARD_RESOLVING(card_id)`**（**不跨 Surge**，G4 完 Unregister）。见 [15 §4.0.5.2](15-timing-entry-catalog.md)。

```gdscript
RegistrationTemplate.peril_encounter_frame(drawer_id, frame_id)
# → 1× Registration，3× RESTRICTION buff，Lifetime WHILE_ENCOUNTER_FRAME
# provenance: AbilityUnitRef.from_framework("seq.draw.encounter")  # E3 内联步
```

卡面「本回合不能抽牌」→ `FORBID_DRAW` + `DURATION(THIS_TURN)`。**同 evaluator、同 L4**。

---

## 8. LISTENER

在 **TimingPoint** 执行 **Composition**（[07-composition](07-composition.md)）。

```gdscript
class ListenerPayload:
    var timing: TimingPoint
    var trigger: TriggerKind      # when | at | after
    var composition: CompositionNode
    var player_initiated: bool    # [reaction] / [free]
    var optional: bool
    var limit: LimitSpec
    var initiation_meta: Dictionary
```

| 来源 | Register 场合 | 典型 Lifetime | 注销 |
|---|---|---|---|
| 资产 / 敌人印刷 Forced、`[reaction]`、`[free]` | `ENTER_PLAY` | `WHILE_IN_PLAY` | `LEAVE_PLAY` |
| 密谋 / 场景印刷 Forced | 成为当前卡 | `WHILE_IN_PLAY` | 翻面离场（效果造的延时 **保留**） |
| 隐私牌 Constant / Forced | `ENTER_HAND` | `WHILE_HIDDEN_IN_HAND` | `LEAVE_HAND` |
| 显现 | **不**长期 Register；抽到 nest | — | 子流程 pop |
| 关键词涌动 | `seq.draw.encounter` WHEN / 效果 GRANT 砖 | `UNTIL_FIRED` | 同流程 AFTER 开火后 |
| 关键词猎手等 | `ENTER_PLAY` | `WHILE_IN_PLAY` | `LEAVE_PLAY` |
| 效果创建 lasting | 效果 resolve | `DURATION` | tick；默认不随离场 |
| 效果创建 delayed | 效果 resolve | `UNTIL_FIRED` | 开火后 |

完整场合表：[§3.2.6](#326-listener--buff-的注册与注销场合已裁决)。

**TimingBus**（06 §5.1）：Forced/Delayed 级 Listener → Framework → [reaction]；`UNTIL_FIRED` 的 Registration 在 listener 执行后 Unregister。

**Act flip**（OQ-02-02）：a 面 `WHILE_IN_PLAY` 注销；效果创建的 `DURATION` / `UNTIL_FIRED` **保留**。

---

## 9. LifetimeSpec

```gdscript
enum LifetimeKind {
    WHILE_IN_PLAY,                 # ENTER_PLAY 挂、LEAVE_PLAY 卸
    WHILE_SOURCE_IN_PLAY,          # 效果 Buff 绑源卡在场
    WHILE_DRAWN_CARD_RESOLVING,    # 险境 / 动态涌动标记；G4 只卸 RESTRICTION
    WHILE_HIDDEN_IN_HAND,          # 隐私入手挂、离手卸
    WHILE_IN_HAND,
    WHILE_IN_DECK,                 # Starting
    WHILE_SET_ASIDE,               # 绑定
    WHILE_ENCOUNTER_FRAME,         # 旧帧级；新路径用 WHILE_DRAWN_CARD_RESOLVING
    DURATION,
    UNTIL_FIRED,
    UNTIL_CONDITION,
}

class DurationAnchor {
    enum Kind {
        THIS_SKILL_TEST, THIS_TURN, THIS_PHASE, THIS_ROUND,
        END_OF_ENCOUNTER, CUSTOM,
    }
}
```

| 卡面信号 | Lifetime |
|---|---|
| until end of **your turn** | `DURATION(THIS_TURN)` |
| until end of **phase** | `DURATION(THIS_PHASE)` |
| for **this skill test** | `DURATION(THIS_SKILL_TEST)` |
| at **start of next mythos**（一次） | `UNTIL_FIRED` |
| 在场 Constant | `WHILE_IN_PLAY` |
| 抽到后结算期间（险境） | `WHILE_DRAWN_CARD_RESOLVING` |
| 隐私在手 | `WHILE_HIDDEN_IN_HAND` |
| 起始在库 | `WHILE_IN_DECK` |
| 绑定 set-aside | `WHILE_SET_ASIDE` |

**After / When** → Listener 的 `timing`；**until / for** → Registration 的 `lifetime`。

Duration tick **先于** 同边界「at end of phase」的 Listener（Grimoire Lasting Effects）。

---

## 10. Scope / Condition

见 v0.1 §5.1–5.2（ScopeFilter、Condition）；所有 BuffType 共用。

---

## 11. RegistrationStore

```gdscript
class RegistrationStore:
    func register(reg: Registration) -> StringName
    func unregister(id: StringName) -> void
    func collect(type: BuffType, ctx: ApplicationContext) -> Array[BuffSpec]
    func tick_durations(anchor: DurationAnchor.Kind, ctx: ApplicationContext) -> void
    func on_card_enter_play(card_id, templates: Array[RegistrationTemplate]) -> void
    func on_card_leave_play(card_id: StringName) -> void  # 只卸 WHILE_IN_PLAY
    func on_enter_hand(card_id) -> void                   # 显现 nest 的入手 L0
    func on_leave_hand(card_id) -> void                   # WHILE_HIDDEN_IN_HAND / WHILE_IN_HAND
    func on_leave_deck(card_id) -> void                   # WHILE_IN_DECK
    func on_leave_set_aside(card_id) -> void              # WHILE_SET_ASIDE
    func unregister_by_drawn_card(card_id) -> void        # 由 seq.draw.encounter G4 调用；只卸 Peril
```

---

## 12. ApplicationContext

**场合 = 正交维度拼凑**；**订阅键**只用其中粗索引（见 [06-ability-initiation §4.1](06-ability-initiation.md)）。修正值 / 监听 / Initiation **共用** `Condition.matches(ctx)`。

```gdscript
class ApplicationContext:
    var timing: StringName              # 粗时点名；L0 辅助
    var framework_step: FrameworkStep
    var controller_id: StringName
    var tags: Array[StringName]         # 开放集合；L3 情景，非封闭 enum
    var trigger: TriggeringCondition
    var payload: Dictionary
    var referents: Dictionary           # 从 RulesMemory 拷的本趟指称切片；≠ 对局历史
    var skill_test: SkillTestContext    # 检定时填充
    var pending: PendingResolution      # Cancel/Replace 窗口
    var initiation: InitiationIntent
```

| 维度 | 典型用途 | 订阅 L0 | 门槛 L3 |
|---|---|---|---|
| `timing` / 阶段+事件族 | 何时叫醒 | ✅ | — |
| `framework_step` | 仅 Upkeep 4.4 等 | ❌ | ✅ |
| `tags` | `framework`、`resource_action` | ❌ | ✅ |
| `controller_id` | 「当你…」 | 注册 scope | ✅ |
| `skill_test` | 本次检定 | ❌ | ✅ |
| `pending` | Instead / Cancel | 特殊 hook | ✅ |
| `payload` / `referents` | 数量、上一次… | ❌ | ✅ |

**不**为每种 stat×场合建枚举（如 `GainSourceKind`）；调查员 Upkeep 4.4 gain +1 = `framework_step` + `tags_all: [framework, gain_resource]`。

实现：`core/timing/application_context.gd`、`core/timing/condition.gd`。Eligibility 关卡见 [06 §5](06-ability-initiation.md)；时点入口见 **[15-timing-entry-catalog.md](15-timing-entry-catalog.md)**。

---

## 13. 编译与进场

```gdscript
class AbilityCompiler:
    func compile_card(def: CardDefinition) -> Array[RegistrationTemplate]:
        # 扫 lifetime 短语 + listener timing；不信 Constant/Forced 标题
        # keywords → MODIFIER/RESTRICTION/LISTENER 模板
        ...
```

`on_card_enter_play` → 展开 template → `register`。

---

## 14. 与旧概念映射

| 旧概念 | 新模型 |
|---|---|
| Constant | Register + WHILE_IN_PLAY |
| Lasting effect | Register + DURATION |
| Delayed effect | Register + UNTIL_FIRED + LISTENER |
| Forced / [reaction] | Register + LISTENER（或 enter_play template） |
| 关键词（印刷） | `CardDefinition.keywords` + ③ 编译 |
| 关键词 / trait / 能力（**动态 gains**） | §3.2 GRANT → KEYWORD / LISTENER / TRAIT；`EffectiveCharacteristicQuery` |

---

## 15. 实现顺序

| 阶段 | 交付 |
|---|---|
| P1 | BuffType×3、ModifierEngine、RegistrationStore |
| P2 | Lifetime tick、Scope/Condition |
| P3 | RESTRICTION + Initiation dry-run |
| P4 | LISTENER + TimingBus |
| P5 | CompositionExecutor + RegisterNode |
| P6 | AbilityCompiler、keywords |
| P6a | **Gained characteristics** · `EffectiveCharacteristicQuery`；P0 Surge KEYWORD 竖切 |

---

## 16. Buff 应用场合清单（裁决方法）

> **已裁决**：译 Grimoire / 实现卡面时，**用本清单决定 Buff 类型与应用站点**；禁止为段落或 `seq.*` 砖块逐步发明平行查询逻辑。  
> **Intent / StatRef / Timing** 会随实现增长；**入口站点**相对稳定（动作系统、Initiation、Effect 提交、数值查询站）。

### 16.1 总流程（译前先过四问）

```text
Grimoire 条文 / 卡面效果
  │
  ├─ Q1 改数值（+1 skill、gain +1 resource）？
  │     → MODIFIER → §16.3 查询站清单
  │
  ├─ Q2 禁止/允许某类动作或效果（cannot、immune、peril）？
  │     → RESTRICTION → §16.4 Intent×入口；Register 时机见 §16.7
  │
  ├─ Q3 某时点后执行子效果（When/After/Forced/[reaction]）？
  │     → LISTENER → §16.5 Timing 清单（详表 [15 §17](15-timing-entry-catalog.md)）
  │
  └─ Q4 以上皆否？
        → §16.6 非 Buff 路由（Domain 不变量 / L7 dry-run / Pipeline / Setup）
```

**Register 时机**（何时挂 Buff）仍由 **命名规则序列** 的 REGISTER 砖块或卡 `enter_play` 决定（[effect-translation.mdc](../../.cursor/rules/effect-translation.mdc)）；**本清单解决的是「挂好后在哪查、在哪生效」**。

### 16.2 第一关：是否 Buff？

| Grimoire / 卡面现象 | Buff？ | 实际路由 |
|---|---|---|
| cannot play / trigger / draw / commit（含 peril、lasting） | **RESTRICTION** | §16.4 |
| +N skill / shroud / damage amount / gain amount | **MODIFIER** | §16.3 |
| After you X, do Y / Forced / [reaction] | **LISTENER** | §16.5 |
| exhausted 不能再 exhaust | **否** | Domain：`set_flag` / exhaust 入口状态检查 |
| target 不合法不能 initiate | **否** | Eligibility **L7** `CompositionDryRunner` |
| assign 超过 asset 血量 | **否** | `DamagePipeline.assign` 规则 |
| deck 不能带两张同名 | **否** | Setup / deckbuild 校验 |
| Permanent 不能离场 | **混合** | Domain 关键词 + 可能 **MOVE** Intent（§16.4） |
| Immune to treachery / player card effects | **RESTRICTION** | EffectGraph step 4 + `EffectOp`→Intent |
| Aloof 不能攻击未 engage 敌人 | **RESTRICTION** | **FIGHT** Intent + `Condition`（engage 状态） |
| Instead / Cancel | **否** | [07-composition](07-composition.md) `CancelPending` / `ReplacePending` |
| Surge / Massive 流程 | **否** | 关键词 + **命名 seq**（非 BuffType） |
| 抽牌 D2 / 遭遇 E2 **Reveal** | **否**（非 Buff） | L0 **`AtomRevealCard`** / `StateMutator.reveal_to_*`；见 [07 §5.3](07-effect-primitives.md) |

### 16.3 MODIFIER · 查询站清单

**模式**：Register MODIFIER → 在 **下列站点** 调用 `ModifierEngine.compute(base, query, app_ctx)`；`Condition.matches(app_ctx)` 过滤场合。

| 查询站 ID | 何时调用 | `StatRef` | 典型 `ApplicationContext` | 状态 |
|---|---|---|---|---|
| **MOD-Q-SKILL** | 检定 ST.5 算 modified value | `SKILL_WILLPOWER` … `SKILL_AGILITY` | `skill_test` 填充 | **已实现**（`SkillTestEngine.step_calculate_modified_value`） |
| **MOD-Q-GAIN-RES** | `seq.gain_resource` 落 resource 前 | `RESOURCE_GAIN_AMOUNT` | `framework_step` + `tags`（如 `gain_resource`） | **已实现**（`SequenceCatalogBootstrap._resolve_gain_resource`） |
| **MOD-Q-SHROUD** | 地点 investigate 算 difficulty | `SHROUD`（待 enum） | location + tags | 待实现 |
| **MOD-Q-DAMAGE-AMT** | Deal damage Assign 前定 amount | `DAMAGE_AMOUNT`（待 enum） | source、target tags | 待实现 |
| **MOD-Q-HORROR-AMT** | Deal horror Assign 前 | `HORROR_AMOUNT`（待 enum） | 同上 | 待实现 |
| **MOD-Q-COST** | Initiation L6 前 | `ACTION_COST` / resource cost（待 enum） | `initiation` | 待实现 |

**新增 MODIFIER 卡面**：先在本表 **登记查询站**（或复用已有站 + `Condition`），再扩 `StatRef`；**不要**在 `seq.*` handler 内散落 `if card_id`.

### 16.4 RESTRICTION · Intent × 入口主表

**模式**：Register RESTRICTION（`RestrictionKind` + payload）→ 在 **入口** 调 `RestrictionEvaluator.block_reason(intent, actor, store, ctx)`。  
**`Intent`** 对齐 **可被禁止的动作/效果类**（与 `ActionType` / Initiation / 关键 `EffectOp` 同族），**不对齐** `seq.*` 砖块编号。

#### 16.4.1 入口站点（稳定层）

| 入口 ID | 子系统 | 检查时机 | 典型 Intent |
|---|---|---|---|
| **REST-E-PLAY** | `ActionSystem` play asset/event | 付 cost / commit play 前 | `PLAY` |
| **REST-E-TRIGGER** | `EligibilityPipeline` L4 | COLLECT / PRE_INITIATE | `TRIGGER` |
| **REST-E-DRAW** | `CompositionExecutor` draw atom | execute 前 | `DRAW` |
| **REST-E-COMMIT** | `SkillTestEngine.commit_card` | commit 前 | `COMMIT_TO_TEST` |
| **REST-E-ACTION** | `ActionSystem.execute` | 耗 action、发起 basic action 前 | `MOVE` `ENGAGE` `FIGHT` …（待扩） |
| **REST-E-EFFECT** | `EffectResolutionGraph` step 4 / Composition 等价点 | submit `EffectRequest` 前 | 按 `EffectOp`→Intent（待接） |
| **REST-E-ACTIVATE** | Asset `[action]` / `[free]` initiation | Pre-restrictions | `ACTIVATE`（待 enum） |

L4 与专用入口 **双查**（COLLECT 筛 eligible + 动作前再拦）对 **同一 Intent** 均可；payload / `drawer_id` 豁免在 `_matches` 内处理。

#### 16.4.2 Intent 与 RestrictionKind（增长表）

| Intent（`RestrictionEvaluator`） | 对齐 | 典型 `RestrictionKind` | Grimoire / 卡面来源 | 入口 | 状态 |
|---|---|---|---|---|---|
| `DRAW` | 抽牌 | `FORBID_DRAW` | peril 无关；卡面「不能抽牌」 | REST-E-DRAW | **已实现** |
| `PLAY` | 打出 asset/event | `FORBID_PLAY` | peril E3；immune play | REST-E-PLAY | Kind **已实现**；**ActionSystem 待接** |
| `TRIGGER` | initiate 能力 | `FORBID_TRIGGER` | peril E3；[reaction]/Forced | REST-E-TRIGGER | Kind **已实现**；**L4 待接** |
| `COMMIT_TO_TEST` | commit skill | `FORBID_COMMIT_TO_TEST` | peril E3 | REST-E-COMMIT | **已实现** |
| `LEAVE_HAND` | 卡牌离开 HAND（move / discard / spawn 等） | `FORBID_LEAVE_HAND` | 隐私（Hidden）E4 | REST-E-MOVE（`StateMutator.move_card`） | **已实现** |
| `MOVE` | 移动行动 / 效果移动调查员 | `FORBID_MOVE` | 「不能离开地点」 | REST-E-ACTION / REST-E-EFFECT | 待 enum + 接线 |
| `ENGAGE` | engage 行动 | `FORBID_ENGAGE` | aloof 等（常配合 Condition） | REST-E-ACTION | 待 |
| `FIGHT` | fight / 攻击敌人 | `FORBID_ATTACK` | aloof 未 engage | REST-E-ACTION | 待 |
| `INVESTIGATE` | investigate 行动 | `FORBID_INVESTIGATE` | 地点规则 | REST-E-ACTION | 待 |
| `EVADE` | evade 行动 | `FORBID_EVADE` | — | REST-E-ACTION | 待 |
| `ACTIVATE` | 启动 asset 能力 | `FORBID_ACTIVATE` | 「不能启动」 | REST-E-ACTIVATE | 待 |
| `DISCARD` | 从手牌弃牌（非自愿） | `FORBID_DISCARD` | weakness 等 | REST-E-EFFECT | 待 |
| `GAIN_HORROR` | 受到 horror | `FORBID_GAIN_HORROR` | 「不能受到 horror」 | REST-E-EFFECT | 待 |
| `GAIN_DAMAGE` | 受到 damage | `FORBID_GAIN_DAMAGE` | 同上 | REST-E-EFFECT | 待 |
| `SEARCH` | search 牌库/集合 | `FORBID_SEARCH` | — | REST-E-EFFECT | 待 |
| `CONFER` | peril 商议 | —（peril 用 PLAY/TRIGGER/COMMIT 覆盖） | Grimoire peril | — | 不单独 Intent |

**扩 Intent 规程**：① 在本表加一行；② 扩 `AhcEnums.RestrictionKind` + `RestrictionEvaluator._matches`；③ **只接一个入口 ID**；④ 卡面 Register 仍走 REGISTER 砖块，**禁止**新 Policy 类。

#### 16.4.3 EffectOp → Intent（REST-E-EFFECT 映射草案）

| `EffectOp` | Intent | 备注 |
|---|---|---|
| `DRAW_CARDS` | `DRAW` | 与 REST-E-DRAW 同 Intent |
| `GAIN_RESOURCE` | `GAIN_RESOURCE`（待） | 或 MODIFIER 减 amount + RESTRICTION 禁 entirely |
| `DEAL_HORROR` / `DEAL_DIRECT_HORROR` | `GAIN_HORROR`（待） | target 侧查 |
| `DEAL_DAMAGE` / `DEAL_DIRECT_DAMAGE` | `GAIN_DAMAGE`（待） | 同上 |
| `MOVE_INVESTIGATOR` | `MOVE` | |
| `DISCARD_CARDS` | `DISCARD` | |
| `SEARCH_DECK` | `SEARCH` | |
| `EXHAUST` / `READY` | `EXHAUST` / `READY`（待） | 效果层 vs 行动层 |
| `ENGAGE` / `DISENGAGE` | `ENGAGE` / `DISENGAGE`（待） | |

Immune（「immune to player card effects」）→ `RESTRICTION` + `Condition`（source tags）+ REST-E-EFFECT，**不是**新 BuffType。

### 16.5 LISTENER · Timing 订阅清单

**模式**：Register LISTENER → `TimingBus` / `ResolutionSequenceStack` 在 **Catalog 规范时刻** emit → Eligibility L0–L5 → Initiation → Composition。

| 清单项 | 订阅键 | emit 责任 | 文档索引 |
|---|---|---|---|
| 框架 after fight / draw / … | `timing` 字符串 或 `(sequence_id, AFTER)` | 框架 / Combat；抽牌 After = 该次抽取整段结算完毕 | [15 §3](15-timing-entry-catalog.md)、[15 §17](15-timing-entry-catalog.md) |
| 命名 seq WHEN/AFTER | `(sequence_id, WOULD\|WHEN\|AFTER)` | 对应 `seq.*` 砖块边界 | [15 §4](15-timing-entry-catalog.md)、[14](14-nested-sequences.md) |
| 卡面 [reaction] | `ListenerPayload.timing` + `player_initiated` | 同上；COLLECT 开窗 | [06-ability-initiation §5](06-ability-initiation.md) |
| UNTIL_FIRED 延时 | 同 timing；Lifetime 摘 registration | listener 跑完 unregister | §4.1 |

**新增 LISTENER**：先在 [15](15-timing-entry-catalog.md) 登记 TimingEntry / emit 点，再在本节补一行；**不要**为每张卡 invent 新 emit 通道。

### 16.6 非 Buff 路由（Q4 出口）

| 现象 | 机制 |
|---|---|
| 结构 / 牌组合法性 | Setup、deckbuild |
| 目标不存在、效果空转 | Eligibility L7 |
| Assign / prevent / soak | `DamagePipeline` + Wrapper |
| Instead 竞争 | `PendingResolution` + initiation_seq |
| 区域不变量（leave play token→pool） | `StateMutator` / [01 §5](01-game-state-zones.md) |
| 关键词流程（Surge 再抽） | **G5** nest evaluate + 再抽 G1（**G4 后**；不在 G1 Register） |
| **Reveal 卡牌**（D2/E2、窥探） | L0 `reveal_to_*`（**是效果**，非 Buff）；见 [07 §5.3](07-effect-primitives.md) |

### 16.7 Register 时机 vs 查询时机（对照）

| | Register（挂 Buff） | 查询（生效） |
|---|---|---|
| **险境** | E3 砖块 `REGISTER` | REST-E-PLAY / TRIGGER / COMMIT |
| **卡面 lasting cannot draw** | 效果 resolve REGISTER | REST-E-DRAW |
| **Asset Constant +1 Will** | `enter_play` template | MOD-Q-SKILL |
| **Until end of turn after fight draw 1** | 效果 resolve REGISTER | LISTENER timing + MOD/DRAW 子 Composition |

**规则序列多** → Register 时机多；**查询站点**仍按 §16.3–§16.5 **有限入口**扩展，而非每 seq 一步一查。

### 16.8 Core 2026 回填（ArkhamDB · Phase 4）

> **详表**：[`data/arkhamdb/reports/phase4_core_2026_backfill.md`](../../data/arkhamdb/reports/phase4_core_2026_backfill.md)  
> **生成**：`python tools/backfill_design_tables.py`（依赖 `tools/arkhamdb_import.py` 产出）

#### 16.8.1 MODIFIER（§16.3 增长）

| 卡面模式 | Core 2026 命中 | 查询站 |
|---|---:|---|
| `+N [skill]` / fight / evade | 24 | **MOD-Q-SKILL**（已实现） |
| `+N damage` | 11 | **MOD-Q-DAMAGE-AMT**（待 enum） |
| `+N shroud` | 1 | **MOD-Q-SHROUD**（待 enum） |
| `-N cost` | 0 | **MOD-Q-COST**（待 enum） |

#### 16.8.2 RESTRICTION（§16.4.2 样例）

| Intent 分类 | 张数 | 代表卡 |
|---|---:|---|
| `DOMAIN_PERMANENT` | 2 | 12012 The Necronomicon；12098 The Gold Bug |
| `FORBID_PLAY` | 1 | 12193 Langour |
| `FORBID_MOVE` | 1 | 12179 Elokoss（敌人指令 + 调查员禁移动） |
| `IF_YOU_CANNOT` | 5 | 条件分支，**非** Register RESTRICTION |
| `IMMUNITY` | 2 | 12169/12170 attached cannot be damaged |
| 待人工 | 1 | 12179b cannot attack you（回合 scope） |

#### 16.8.3 LISTENER（§16.5 增长）

| 订阅线索 | Core 2026 命中 | 引擎路由 |
|---|---:|---|
| Hunter 关键词 | 13 | 敌人 phase · `hunter_patrol_move`（待接 LISTENER） |
| Retaliate 关键词 | 9 | 攻击后 handler（见 08 §6） |
| `After you discover clues` | 6 | `after_clue` → TimingBus 增长 |
| `When investigation phase ends` | 4 | 框架步 AFTER |

---

## 17. StatProjection（历史谓词读模型）

> **详文**：[06c-stat-projections.md](06c-stat-projections.md)

Eligibility **L3/L5** 所需 **历史谓词**（本 turn action 次数等）**不是** Buff，**不**写入 `RegistrationStore` payload；由并行组件 **StatProjectionStore** 管理读模型：

| 时机 | 行为 |
|---|---|
| `register()` | `StatProjectionStore.attach(reg_id, template.stat_queries, scope)` — **DORMANT** |
| `TimingCatalog` → COLLECT | 首次 demand → **cold fold** `EventRecord` → **HOT** |
| Emitter | `on_event` 仅更新 HOT 投影 |
| `unregister()` / duration tick | `detach(reg_id)` → ref=0 丢弃 HOT |

**权威源** = `EventRecord`；**禁止**从 Domain 压扁字段推导 spend 次数。

`AbilityCompiler.compile_card` 产出 `stat_queries[]`（与 `RegistrationTemplate[]` 并列）。

---

## 18. 开放问题

| ID | v1 默认 |
|---|---|
| OQ-BUFF-03 | Forced/Delayed Listener **直跑 Composition**；[reaction] **完整 Initiation** |
| OQ-BUFF-04 | Lasting 默认 **不** 随源卡 leave play 结束；`WHILE_SOURCE_IN_PLAY` 才绑源卡 |

---

## 19. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-09-21 | v0.4.18 | §12：`referents` 是 Memory 切片，历史走 EventRecord / StatProjection（07 §1.4） |
| 2026-09-21 | v0.4.17 | §4：卡面创建 Buff = nest `seq.effect.register`；管线 Register 仍是父 seq 砖 |
| 2026-09-21 | v0.4.16 | 打出始终 `PLAY_CARD`；Fast 编译 `play_form`（窗口/花费对称），不收成 `ABILITY` |
| 2026-09-21 | v0.4.15 | **Fast.** 打出与支援触发对称：无 Fast≈激活、无时点≈免费、有时点≈反应；非单独成本政策 |
| 2026-09-21 | v0.4.14 | **§3.2.6** 注册/注销绑已有 `seq.*` 砖或 zone 变迁；禁止 `PERIL_CHECK` 等独立场合节点；译名：永久 / 绑定 / 独特 / 蜂拥 / 多重 |
| 2026-09-21 | v0.4.13 | **§3.2.6** 关键词/能力 LISTENER 注册与注销场合；不只有进场/离场 |
| 2026-09-21 | v0.4.12 | **§3.2.5** 分表：指令 / 参数 / 关键词三种 Buff 的实现路径 |
| 2026-09-21 | v0.4.11 | **§3.2.5** 关键词编译为三种 Buff；猎物/生成为指令，不进 KeywordProfile |
| 2026-09-21 | v0.4.10 | **§3.2.5** 关键词 `consume_shape`：仅 NEST_SEQ 才 nest `seq.keyword.*`；校正 Hidden/Hunter 导入误伤 |
| 2026-09-21 | v0.4.9 | 涌动消费改为 nest `seq.keyword.surge`；抽牌管线不再内联 G5 |
| 2026-07-06 | v0.4.5 | **§3.2.4** KeywordProfile 挂载/消费填表（Core 2026） |
| 2026-07-06 | v0.4.4 | P0 实现：`EffectiveCharacteristicQuery` · KEYWORD Buff · G5 surge |
| 2026-07-06 | v0.4.3 | **§3.2** Gained characteristics 总纲 + Core 2026 统计 |
| 2026-07-06 | v0.4.2 | **§3.1** 涌动：动态 surge = KEYWORD 标记 · 不叠加；OQ-ADB-02/03 |
| 2026-06-18 | v0.4.1 | **§17** StatProjection 读模型；链 [06c](06c-stat-projections.md) |
| 2026-06-18 | v0.4 | **§16** Buff 应用场合清单；Reveal 走 L0 非 Buff |
| 2026-05-25 | v0.3 | ApplicationContext 拼凑式场合；订阅键 vs L3 情景；链到 Eligibility L0–L7 |
| 2026-05-25 | v0.2 | Buff 三种；删 FRAME/PENDING；持续/延时=Lifetime；持续壳内 Listener 详述；dry-run 见 07-composition |
| 2026-05-25 | v0.1 | 初稿 |
