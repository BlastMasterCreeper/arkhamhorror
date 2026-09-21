# 06b — Registration 与 Buff 规格 (统一能力模型)

> **依赖**：[06-ability-initiation.md](06-ability-initiation.md), [07-effect-primitives.md](07-effect-primitives.md), [07-composition.md](07-composition.md)  
> **被依赖**：TimingBus、ModifierEngine、Initiation dry-run  
> **状态**：v0.4.10 · 2026-09-21 — §3.2.5 关键词消费形状；非一律 nest `seq.keyword.*`

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
| **③ 消费 consume** | 哪个 handler **读**并执行？ | 由 **`consume_shape`** 决定（§3.2.5）；**仅 NEST_SEQ** 才 nest `seq.keyword.*`；**禁止**写进父管线砖块 |

```text
mount_moment     = 规则要求 card 最早具备 keyword 的 instant
representation   = DEFINITION | KEYWORD_BUFF | RESTRICTION | LISTENER
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
| `AT_SETUP` | Setup / game begins | Bonded set-aside；Permanent 开场进场 |
| `AT_DEFEAT` | 击败结算内核读 | Doomed、Victory 敌人 |
| `AFTER_MULLIGAN` | 起手+换牌之后 | Starting |
| `AFTER_ENTER_PLAY` | 进场指令结算完毕之后 | Swarming X；Uses 也可作进场后缀 |

**兼容规则（已裁决）**：

1. **印刷 vs gained 共享 `consumer_slot`**，只改 `mount_moment` 与 `representation` 来源。  
2. **`AT_DRAW_G2` 不是 keyword 通用挂载点** — 仅 **早生效** keyword（Peril）使用。  
3. **晚判定 keyword**（Surge）：印刷 = `LAZY_AT_CONSUMER`；gained = `AT_GRANT` + `KEYWORD_BUFF`；**消费** = nest `seq.keyword.surge`（`AFTER_DRAWN_CARD`）。**不是**所有 keyword 都用这一档。  
4. **G4 `unregister_by_drawn_card` 只卸 RESTRICTION**（Peril）；**不卸** `KEYWORD_BUFF`（涌动须留到 consume nest）。  
5. 新 keyword **先定 `consume_shape`（§3.2.5）**，再加 `KeywordProfile` 行。**仅 `NEST_SEQ`** 才有 `consume_flow_id`。**禁止**把 Restriction / Listener / 内核查询 / Spec / 构筑 keyword 都做成 `AFTER_DRAWN_CARD` nest；**禁止**写进父管线优先队列；**禁止**为单卡 proliferate `seq.check_*`。

**目标 API（P1+）**：

```gdscript
class KeywordProfile:
    var keyword: StringName
    var consume_shape: StringName      # NEST_SEQ | REGISTER | LISTENER | KERNEL_QUERY | SPEC | DECKBUILDING
    var mount_printed: StringName      # AT_PRINT | AT_DRAW_G2 | …
    var mount_gained: StringName       # AT_GRANT | …
    var representation_printed: StringName
    var representation_gained: StringName
    var unmount: StringName
    var consumer_slot: StringName      # 仅 NEST_SEQ / REGISTER 挂载点需要
    var consume_flow_id: StringName    # 仅 NEST_SEQ；否则 &""
    var listener_trigger: StringName   # 仅 LISTENER；否则 &""

class KeywordMountService:
    static func mount_printed(ctx, card_id, profile) -> void
    static func mount_gained(ctx, card_id, profile, provenance) -> void
    static func unmount(ctx, card_id, profile) -> void
```

`KeywordConsumer.consume_at(slot)` **只遍历 `NEST_SEQ`** 且 `consume_slot == slot` 的行。REGISTER 由 Eligibility / Intent 查询；LISTENER 由 Catalog emit；KERNEL_QUERY / SPEC 由已有 seq 内核同步读。

##### Core 2026 · KeywordProfile 填表（遭遇 + 敌人 · 印刷路径）

> 卡量来源：Phase 4 回填 · [§16.8.3](#1683-listener--§165-增长) / [15 §17.14](15-timing-entry-catalog.md#1714-core-2026-遭遇卡清单arkhamdb-回填)  
> **校正（2026-09-21）**：下表 qty 以 **首行关键词印刷** 为准；导入层误伤见 §3.2.5 数据缺口。

| keyword | Core 2026 约 qty | consume_shape | mount（印刷） | 表征（印刷） | unmount | consumer_slot | listener_trigger | 备注 |
|---|---:|---|---|---|---|---|---|---|
| **surge** | 3 首行 | **NEST_SEQ** | `LAZY_AT_CONSUMER` | `DEFINITION` | consume nest 后 | **`seq.keyword.surge`** @ `AFTER_DRAWN_CARD` | — | 不进抽牌优先队列；gained 见下行 |
| **peril** | 2 | **REGISTER** | **`AT_DRAW_G2`** | **RESTRICTION** Register | **G4 初** Unregister RESTRICTION | **L4** REST-E-PLAY/TRIGGER/COMMIT | — | 挂载即 peril 生效 |
| **hidden** | **0** 印刷 | **REGISTER** + Domain | **`AT_REVELATION`** E4 | `is_hidden` + **RESTRICTION** `FORBID_LEAVE_HAND` | expose / 合法离手 | **REST-E-MOVE** · E4/E5 | — | Core 2026 **无**隐私关键词；ArkhamDB `hidden` 旗标 ≠ 本词（§3.2.5） |
| **aloof** | 6（遭遇 5 + 玩家弱点 1） | **KERNEL_QUERY** + REST | `AT_ENTER_PLAY` spawn | `DEFINITION` + **REST-E-FIGHT** | leave play | **SPAWN** / **FIGHT** / **ENGAGE** | — | spawn 内核读 aloof；Fight 未交战 cannot |
| **hunter** | 12 敌人（遭遇 11 + 弱点 1） | **LISTENER** | **`AT_ENTER_PLAY`** spawn | **LISTENER** @ enemy phase | leave play / defeat | **③** Hunter 移动内核 | **`ENEMY_3_2`** | 12074 *Hunter's Instinct* 是导入误伤，不是猎手 |
| **retaliate** | 9 | **LISTENER** | **`AT_ENTER_PLAY`** | fight 失败后 attack 内核 | leave play | **Fight 失败** · post-ST7 | **after investigator fight** | 与 Alert 同攻击层 |
| **massive** | 2 | **KERNEL_QUERY** | **`AT_ENTER_PLAY`** | `DEFINITION` + 虚拟交战 | leave play | **ENGAGE** / **AOO** / 3.3 攻击 | — | 非 Hunter 移动 |
| **permanent** | 1（Collector） | **DECKBUILDING** + REST | **`AT_SETUP`** 开场进场 | Domain `permanent` + MOVE Intent | 仅卡面允许离场 | **REST-E-MOVE** / 构筑 | — | 兼 Reward；非 encounter draw |

#### 3.2.5 消费形状 `consume_shape`（已裁决：非一律涌动式 nest）

> **问题**：涌动的实现（`KeywordConsumer` @ `AFTER_DRAWN_CARD` → nest `seq.keyword.surge`）**不能**推广到全部关键词。魔典 *Keywords are used as shorthand for some game effects. Each keyword has its own unique rules.*  
> **裁决**：先定 **消费形状**，再决定要不要 `seq.keyword.*`。

| `consume_shape` | 消费方式 | 要不要 `seq.keyword.*` | 典型 |
|---|---|---|---|
| **NEST_SEQ** | 某指令/事件 **结算完毕之后**，另开一条命名流程 | **要** | 涌动再抽；Starting 检索；Swarming 垫牌 |
| **REGISTER** | 挂载 Restriction；Eligibility / Intent **查询** | **不要** | 险境、隐私离手、常驻离场 |
| **LISTENER** | Catalog **emit** → COLLECT → 共享攻击/移动内核 | **不要**（fire 时 nest 的是 3.2 / `perform_attack`，不是 keyword consume seq） | 猎手、巡逻、反击、警戒、逃逸、厄运降临 |
| **KERNEL_QUERY** | **已有** seq 内核同步读 `has_effective_keyword` | **不要** | 冷漠生成、庞大交战、快速打出路径、独一、胜利点去向、Uses 进场放标记 |
| **SPEC** | ① `*Spec` + Resolver；本身不执行效果 | **不要** | 猎物、生成指令、巡逻括号、Uses (X type)、Seal 选标记 |
| **DECKBUILDING** | 构筑 / 战役日志；对局无 consume | **不要** | Exceptional、Myriad、Reward、Researched、Permanent 不计牌组规模 |

**判据（NEST_SEQ）**：Grimoire 正文是 *After … resolves / After you put into play / after opening hand*，且结果是 **另开一条游戏指令**（再抽、检索、垫 swarm 牌）。  
**判据（不要 NEST_SEQ）**：只改 **正在进行的** 内核分支（生成落点、交战、打出是否耗行动）、只挂 **Cannot**、或只在 Framework 固定步移动/攻击。

**勿混**：

| 易混对 | 区别 |
|---|---|
| **Fast.** 关键词 vs `[fast]` | **Fast.** = 打出不耗 Play 行动、不引起借机攻击（KERNEL_QUERY · Initiation）。`[fast]` = 免费触发能力符号 → `register_as:free`（Card Ability，不是 keyword consume） |
| ArkhamDB JSON `hidden` vs **隐私 Hidden** | 前者 = 数据未列出的卡背（Elokoss `12179b`）；后者 = 秘密入手关键词。Core 2026 **零张**印刷隐私 |
| 标题含 Hunter vs **猎手** | 首行必须是 `Hunter.` 词条；禁止 `\bHunter\b` 扫到 *Hunter's Instinct* |

##### Grimoire 2026 关键词全表（玩家 + 遭遇）

来源：[arkham-grimoire-v1.0](../reference/arkham-grimoire-v1.0.md) *is a keyword ability* / *deckbuilding keyword*；Core 2026 数量来自 `data/arkhamdb/imported/` + 首行印刷校正。

| 关键词 | 简中 | 侧 | Core 2026 | shape | 实现路径 | 现状 |
|---|---|---|---:|---|---|---|
| **Surge** | 涌动 | 遭遇 | 3 印刷 + 多张 gained | NEST_SEQ | `KeywordConsumer` @ `AFTER_DRAWN_CARD` → `seq.keyword.surge` | ✅ |
| **Peril** | 险境 | 遭遇 | 2 | REGISTER | `AT_DRAW_G2` mount REST；L4 查询 | ✅ Register；待接入 MountService |
| **Hidden** | 隐私 | 遭遇/弱点 | **0** | REGISTER + Domain | E4 秘密入手 + `FORBID_LEAVE_HAND`；**不要**用 ArkhamDB `hidden` 旗标 | 运行时已有；导入误伤 12179b |
| **Aloof** | 冷漠 | 敌人 | 6 | KERNEL + REST | G4 spawn 读 aloof；Fight/Engage Intent REST | ✅ `EnemySystem` |
| **Hunter** | 猎手 | 敌人 | 12 | LISTENER | AbilityCompiler 模板 @ `(seq.enemy.3_2, WHEN)` | △ `enemy_phase_flow` 按名分支，待改为 LISTENER 模板 |
| **Patrol** | 巡逻 | 敌人 | 0（测试合成） | LISTENER + ① 括号 | 与 Hunter 同槽；括号 `PatrolTargetSpec` | △ 同 3.2 内核 |
| **Prey** | 猎物 | 敌人 | 3 Spec | **SPEC** | `PreyInstructionSpec`；engage / 猎手等距读 | ✅ 禁止 nest |
| **Spawn –** | 生成指令 | 敌人 | 1 玩家弱点 + 遭遇编译 | **SPEC** in ② | `SpawnInstructionSpec`；G4 spawn 内核 | ✅ 禁止独立 timing |
| **Retaliate** | 反击 | 敌人 | 9 | LISTENER | post-ST7 → `perform_attack(RETALIATE)` | ✅ `retaliate_alert_resolver` |
| **Alert** | 警戒 | 敌人 | 1（Cornelia） | LISTENER | post-ST7 evade fail → `perform_attack(ALERT)` | ✅ resolver；**未**进 `keywords[]` |
| **Elusive** | 逃逸 | 敌人 | 3 | LISTENER | `perform_attack` 后 / 被 Fight 后 flee | ✅ `elusive_resolver`；**未**进 `keywords[]` |
| **Massive** | 庞大 | 敌人 | 2 | KERNEL_QUERY | 虚拟交战、永不进威胁区、3.3 batch | ✅ `MassiveEngagement` |
| **Doomed** | 厄运降临 | 敌人 | 1（Bystander） | LISTENER / KERNEL | 击败内核 +1 毁灭（discard ≠ defeat） | ✅ `doomed_resolver`；**未**进 `keywords[]` |
| **Victory X** | 胜利点 | 遭遇 | 24（敌 14 / 地 10） | KERNEL_QUERY | 击败/场景结束改去向；X 是标量 | ✅ `enemy_defeat_resolver` |
| **Fast** | 快速 | 玩家 | 6 张 `Fast.` | KERNEL_QUERY | Initiation：不耗 Play 行动、无 AOO；窗来自 Play 指示 | △ 行动系统；**勿**与 11 张 `[fast]` 合并 |
| **Uses (X)** | 使用次数 | 玩家资产 | 12 | KERNEL + ① | 进场内核放 X 枚 typed token；`UsesSpec` | △ Domain `uses` 有；进场放记未模块化 |
| **Permanent** | 常驻 | 玩家 | 1 Collector | DECKBUILDING + REST | 不计牌组；开场进场；cannot leave play | △ Domain 旗标；构筑/离场 REST 待接 |
| **Exceptional** | 卓越 | 玩家 | 0 | DECKBUILDING | 2× XP；同名最多 1 | 文档 11；无运行时 |
| **Reward** | 奖励 | 玩家/战役 | 1（同 Collector） | DECKBUILDING | 解锁后可构筑；常驻奖励每组最多 1 | 同 Permanent 卡 |
| **Researched** | 已研究 | 玩家 | 0 | DECKBUILDING | 战役日志鉴定后才可升级纳入 | 无 |
| **Myriad** | 混响 | 玩家 | 0 | DECKBUILDING | 同名最多 3；额外 2 张 0 XP | Grimoire 有；Core 2026 无 |
| **Starting** | 起始 | 玩家 | 0 | NEST_SEQ | 换牌后 nest `seq.keyword.starting` 检索 1 张入手 | 无 |
| **Seal** | 封印 | 玩家 | 0 | KERNEL + ① | 打出成本 / 进场封印混乱标记；`SealSpec` | Choice `CHAOS_PICK` 已列；无卡 |
| **Unique `[unique]`** | 独一 | 两侧 | 玩家 14 / 遭遇 14 | KERNEL_QUERY | 标题属性；L5 同名 in-play 拒绝 | 06 Initiation 已写；待接线 |
| **Bearer** | 持有者 | 弱点 | — | DECKBUILDING | 忽略构筑限制、不计规模 | 11 |

**不是关键词**（常被误收进本表）：Exile（能力，非常驻规则词）、`[fast]` / `[reaction]` / `[action]`（触发符号）、Forced / Revelation（能力类型）。

##### 后续循环（RR 增补，Core 2026 无）

| 关键词 | 来源 | shape | 路径建议 |
|---|---|---|---|
| **Bonded** | Dream-Eaters | SETUP + DECKBUILDING | 开局 set-aside；宿主打出时召唤；**不要**当涌动 |
| **Swarming X** | Dream-Eaters | **NEST_SEQ** + ① X | *After you put into play* → `seq.keyword.swarming` @ `AFTER_ENTER_PLAY`（与涌动同形、不同槽） |
| **Vengeance X** | Forgotten Age | KERNEL_QUERY | 与 Victory **同去向**（胜利展示区），计分语义相反 |
| **Customizable** | Scarlet Keys | DECKBUILDING | 战役 XP 解锁选项；改印刷能力，不是对局 consume |

##### 实现路径（建议顺序）

不要先做 `KeywordMountService` 全表接线。按形状分批：

1. **导入卫生（P0）** — 首行只认 `Name.` 词条；**不要**把 ArkhamDB `hidden`/`permanent` 数据旗标直接写入 `keywords[]`；补 `alert` / `elusive` / `doomed` / `Fast.`；修 12074 误伤。`EffectiveCharacteristicQuery` 仍是印刷 ∪ gained 的唯一查询。
2. **NEST_SEQ 扩槽，不扩抽牌管线** — `KeywordConsumer.consume_at` 已按 slot 分发。下一张同形词（Starting、Swarming）只加 profile 行 + `seq.keyword.*`，在 **自己的** 结算后槽调用 `consume_at`。**禁止**把它们塞进 `AFTER_DRAWN_CARD`。
3. **REGISTER** — Peril 已是样板。隐私、常驻离场走同一 `KeywordMountService.mount_printed`，消费仍是 L4 / MOVE Intent，**不** nest consume seq。
4. **LISTENER** — 反击/警戒/逃逸/猎手已有内核。P1 只把 `enemy_phase_flow` 的按名分支收成 3.2 LISTENER 模板（08 已写目标）；**不要**再包一层 `seq.keyword.hunter`。
5. **KERNEL_QUERY / SPEC** — 冷漠、庞大、快速、独一、Victory、Uses、Prey、Spawn 留在现有 seq 内核。Profile 表只做文档与 `has_effective_keyword` 读点，**不**新建 consume seq。
6. **DECKBUILDING** — 全部进 [11](11-investigator-campaign.md)；运行时 `KeywordConsumer` 不遍历这些行。

**实现状态**：涌动 NEST_SEQ ✅；其余形状以现有内核/Register 竖切为主；MountService / 导入卫生 / 3.2 LISTENER 模板 — 待分批。

##### 印刷 vs gained · 对照（同一 consumer）

| keyword | mount（印刷） | mount（gained） | 表征（印刷） | 表征（gained） | consumer（共用） |
|---|---|---|---|---|---|
| **surge** | `LAZY_AT_CONSUMER` | **`AT_GRANT`**（G3 效果步） | `DEFINITION` | **KEYWORD_BUFF** | nest `seq.keyword.surge` → 再抽 |
| **peril** | `AT_DRAW_G2` | **`AT_GRANT`**（立刻） | RESTRICTION | RESTRICTION（同模板） | L4 险境查询 |
| **hunter** | `AT_ENTER_PLAY` | **`AT_GRANT`** | LISTENER | LISTENER + `DURATION`/`WHILE_IN_PLAY` | 3.2 Hunter 移动 |
| **retaliate** | `AT_ENTER_PLAY` | **`AT_GRANT`** | LISTENER / attack 内核 | LISTENER 或 KEYWORD_BUFF | fight 后 perform_attack |
| **aloof** | `AT_ENTER_PLAY` | **`AT_GRANT`** | DEFINITION + Condition | KEYWORD_BUFF 或 RESTRICTION | FIGHT/ENGAGE |
| **[action] 文本** | `AT_ENTER_PLAY` / constant | **`AT_GRANT`** | AbilitySpec 印刷 | **LISTENER** + AbilitySpec | Initiation COLLECT @ 各 timing |

##### 时间线示意（Surge vs Peril · 同一次 draw）

```text
G1 Draw bind
G2  Peril：mount RESTRICTION（仅 peril 类）
G3  Revelation · 可能 AT_GRANT surge → KEYWORD_BUFF
G4  unmount RESTRICTION（peril）· discard/spawn
    （KEYWORD_BUFF 保留）
AFTER this card
KeywordConsumer @ AFTER_DRAWN_CARD
  nest seq.keyword.surge · consume · unmount KEYWORD_BUFF
    nest seq.draw.encounter（新指令）
```

**实现状态**：涌动 NEST_SEQ（印刷 LAZY + gained KEYWORD_BUFF + nest `seq.keyword.surge`）✅。其余形状见 §3.2.5：不要为它们复制涌动槽。

---

## 4. 持续 vs 延时：只有 Lifetime 不同

**持续效果**与**延时效果**本质都是 **Register**；玩家用语差别在 **`LifetimeSpec`**：

| 玩家说法 | LifetimeSpec | 典型 Buff | Registration 何时消失 |
|---|---|---|---|
| **持续效果** | `DURATION(...)` / `WHILE_*` | MODIFIER、RESTRICTION、LISTENER | 到期或条件满足 |
| **延时效果**（一次性） | `UNTIL_FIRED` | 通常 LISTENER | **第一次** listener 跑完后 Unregister |
| **持续能力（Constant）** | `WHILE_IN_PLAY` | MODIFIER / LISTENER | 源卡 leave play |

**不存在** LastingRegistry / DelayedRegistry；仅 **RegistrationStore**。

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

| 来源 | Register 时机 | 典型 Lifetime |
|---|---|---|
| 印刷 Forced | enter_play | WHILE_IN_PLAY |
| 印刷 [reaction] | enter_play | WHILE_IN_PLAY |
| 效果创建 lasting | effect resolve | DURATION |
| 效果创建 delayed | effect resolve | UNTIL_FIRED |

**TimingBus**（06 §5.1）：Forced/Delayed 级 Listener → Framework → [reaction]；`UNTIL_FIRED` 的 Registration 在 listener 执行后 Unregister。

**Act flip**（OQ-02-02）：a 面 `WHILE_IN_PLAY` 注销；effect 创建的 `DURATION` / `UNTIL_FIRED` **保留**。

---

## 9. LifetimeSpec

```gdscript
enum LifetimeKind {
    WHILE_IN_PLAY,
    WHILE_SOURCE_IN_PLAY,
    DURATION,
    UNTIL_FIRED,
    UNTIL_CONDITION,
    MANUAL,
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
    func on_card_leave_play(card_id: StringName) -> void
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
    var referents: Dictionary           # RulesMemory；历史条件
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
