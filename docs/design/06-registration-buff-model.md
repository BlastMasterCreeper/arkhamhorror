# 06b — Registration 与 Buff 规格 (统一能力模型)

> **依赖**：[06-ability-initiation.md](06-ability-initiation.md), [07-effect-primitives.md](07-effect-primitives.md), [07-composition.md](07-composition.md)  
> **被依赖**：TimingBus、ModifierEngine、Initiation dry-run  
> **状态**：v0.4.43 · 2026-10-26 — additional 全路径：攻击/发现 Plan · 敌伤标量 · 承伤 pipeline

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

| 词 | 含义 |
|---|---|
| **Register** | 结算动作：`RegistrationStore.register(reg)`（信息原语） |
| **Unregister** | 结算动作：按 id / filter / lifetime tick 卸下 |
| **Registration** | Store 里的一条记录（含 lifetime · scope · `buffs`） |
| **Buff** | `BuffSpec` + payload——登记的 **载荷**，不是另一套结算动词 |
| **Context** | `ApplicationContext`（§9） |

### 2.1 Register 与 Buff（关系 · 已对齐）

```text
Register（结算 · 不可见）
  只能创建 → Registration
              └─ 内含 1..n 个 BuffSpec（见下 · 载荷族）

Unregister（结算）→ 记录消失 → 其 Buff（含衍生）一并卸下
```

> **硬约束（已对齐）**：信息原语 Register **只能**写出 Buff（或你不愿全称 buff 时：Store 里的 Registration 载荷）。  
> **禁止** Register 旁路直接挂裸 `AbilitySpec` / 真空订时点。能力管线吃的是 **Gain 特征 Buff 衍生出的挂载**，不是第二套结算入口。

| | **Register** | **Buff（载荷）** |
|---|---|---|
| 词性 | **动词**（结算叶） | **名词**（Registration 内形状） |
| 做什么 | 把 lasting / 延时 / **Gain 特征** **写进/卸出** Store | 行为修正 **或** 特征授予（§3 / §3.2） |
| dry-run | 插入成功 → **CREATED** | 不单独 CREATED；随 Registration |
| 不是 | — | 不是第四层原语 |

**Buff 两族（同壳，非两种原语）**：

| 族 | 成员 | 角色 |
|---|---|---|
| **行为** | `MODIFIER` · `RESTRICTION` · `LISTENER` | 直接改数值 / 禁允 / 听时点跑 Composition |
| **Gain 特征** | `KEYWORD` · `TRAIT` · `ICON` · `ABILITY` | Grimoire *gains a characteristic*；**拥有**记录 |

**衍生（核心）**：Gain 特征 Buff **创建时**可按 profile **再 Register / 挂载衍生行为 Buff**（或能力管线挂载）。卸 Gain 壳 → 对称拆衍生。见 §2.3 / §3.2.1a。

与 [07 §5.4.2](07-effect-primitives.md) 对齐：信息原语 **主量** = Register/Unregister；Buff = 唯一可注册物。日志∪记住 = 薄 **Chronicle**。

### 2.2 原语语境：Register 不按 Buff 再拆结算

```text
信息原语结算面     ≈  Register / Unregister
Registration 壳    =  lifetime · scope · source（参数，非原语）
Buff 形态          =  行为三型 | Gain 特征族
衍生               =  Gain 创建 → 再挂行为 Buff / 能力挂载（仍经 Register 或同壳子载荷）
```

- **不要**为每种 BuffType 各造一个结算原语。  
- **不要**为持续/延时各造一套 Store（§4）。  
- **不要**「Register AbilitySpec」绕过 Buff——Ability 是 Gain.`ABILITY` 的 payload，初始化是 **衍生**。  
- 复杂度增长点：新 payload / RestrictionKind / Listener timing / Gain kind，不是新 Register 动词。

**包装**：唯一结算入口 `seq.effect.register` / `unregister`，参数 = `RegistrationTemplate`（壳 + `buffs[]`）。详 [07 §5.4.2b](07-effect-primitives.md)。

### 2.3 印刷能力 ≠ Buff；Gain 能力 = 特征 Buff → 衍生

> **已对齐**：纸面 **印刷** Forced / 触发 / Constant / Revelation / 关键词 = **能力 / characteristic**，进场挂载，**不是** Register 出来的 Buff。  
> **效果 gains …** = Register **Gain 特征 Buff**；该 Buff **会创建衍生**（行为 Buff 和/或能力管线挂载）。仍 **不是**把 Forced 改叫 `LISTENER`。

| | **印刷能力** | **Gain 特征 Buff** | **行为 Buff** |
|---|---|---|---|
| 从哪来 | 卡面定义 · 进场 | 效果 `gains …` → Register | 效果直接「until…」**或** Gain **衍生** |
| Store | 否（定义侧） | **是**（KEYWORD/TRAIT/ICON/ABILITY） | **是**（三型） |
| 运行 | AbilityKind 管线 | `effective_*`；创建时 **衍生** | Modifier / Eligibility / LISTENER fire |

```text
gains surge / Retaliate / Forced – …
  → Register Gain 特征 Buff（KEYWORD 或 ABILITY + payload）
  → 衍生：
       KEYWORD profile → 再挂 LISTENER / RESTRICTION / MODIFIER（拥有 ≠ 行为）
       ABILITY payload → 能力 Lifecycle mount（订时点 / COLLECT / Forced 槽 / Limit）
                       → Constant 数值句可再衍生 MODIFIER
  → Unregister Gain 壳 → 卸全部衍生
```

**LISTENER Buff 的合法例子**（行为族，可直接 Register 或由 Gain 衍生）：

- Event：*Until end of your turn, after you successfully evade, draw 1.*（效果直接造 LISTENER）  
- 延时：*At the beginning of the next mythos phase…*  
- `gains surge` **衍生**出的延时再抽 LISTENER（Gain 是 KEYWORD 标记；LISTENER 是衍生）

**不要举例成「Forced = LISTENER Buff」**：

- 支援 **印刷** *Forced – After you fight: draw 1.* → 印刷能力  
- *效果* *… gains “Forced – After you fight: draw 1.”* → **Gain.`ABILITY` Buff** → 衍生 Forced 挂载（实现可与 LISTENER **同形订阅**，分类仍是能力挂载，不是把 Gain 改叫 LISTENER）

---

## 3. BuffType（三种）

```gdscript
enum BuffType {
    MODIFIER,       # 被动改数值
    RESTRICTION,    # 被动禁止/允许；编译卡面 "cannot …"；Grimoire：cannot 绝对，不得 countermand（07 §3.2）
    LISTENER,       # lasting/延时：timing 到点跑 Composition（≠ 印刷 Forced/reaction 能力）
}
```

| 非 Buff（勿混入） | 实现方式 |
|---|---|
| **Forced / `[reaction]` / `[action]` / Constant / Revelation** | **`AbilitySpec`** + Initiation / COLLECT（§2.3）；**不是** LISTENER Buff |
| Surge（**印刷**） | `CardDefinition.keywords` 含 `surge` |
| Surge（**动态** `gains surge`） | Register **KEYWORD 标记** + 延时消费（§3.1） |
| Peril、Aloof、Massive 等关键词行为 | keywords + 编译 MODIFIER/RESTRICTION/LISTENER（关键词 ≠ 能力类型） |
| Cancel / Replacement | Composition Interrupt / Replace 节点 |
| Skill Test / Encounter 帧 | Context + 子系统 |

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
3. **查询统一** — `EffectiveCharacteristicQuery`（或 RegistrationStore 门面）：`has_effective_keyword` / `has_effective_trait` / `effective_abilities` / `effective_skill_icons` = **（印刷 − blank）∪ gained**（按 kind 叠加；**blank 不抹 gained**，见 RR / [07 §5.4](07-effect-primitives.md)）。

```text
seq.effect.register · Grant 特征 Buff
  kind: KEYWORD | TRAIT | ICON | ABILITY
  payload: &"surge" | trait_id | icon | AbilitySpec
  lifetime: …
        │
        ├─ 写出 Gain Buff（CREATED）
        └─ 衍生（CharacteristicDeriver）：
             KEYWORD → Profile 再挂 LISTENER / RESTRICTION / MODIFIER
             ABILITY → Lifecycle mount（Forced/触发/…）；Constant 可再衍生 MODIFIER
             TRAIT/ICON → 多只读；ICON 可衍生 MODIFIER
        │
        ▼
Effective* / COLLECT / 行为三型 consumer
```

#### 3.2.1 Kind 路由与叠加

| Kind | 典型卡面 | 存储 | 生命周期常见 | 叠加 |
|---|---|---|---|---|
| **KEYWORD** | gains surge / gains Retaliate | KEYWORD 标记 Register | `WHILE_DRAWN_CARD_RESOLVING` 或 `WHILE_IN_PLAY` | **按 keyword 定**（Surge **不叠加**，§3.1） |
| **ABILITY** | gains **任意能力类型**（见下） | **AbilitySpec** + lifetime 挂 Store | 与 granting 同 lifetime | 多条并存；Limit 各算 |
| **TRAIT** | gains the [[Cultist]] trait | TRAIT 标记 Register | 同上 | trait **union** |
| **ICON** | gains [wild] | MODIFIER 或 ICON 标记 | `THIS_SKILL_TEST` 等 | 与印刷 union |
| **数值** | gets +1 fight | **MODIFIER** | turn / phase / test | ModifierEngine |

**可获得 ≈ 几乎全部能力类型**（含关键词）。但 **读特征** 与 **文本能力** 落地重量不同：

#### 3.2.1a Gain Buff：只读 vs 文本能力（衍生）

> Register **只**写出 Buff。Gain = **特征族 Buff**；文本能力档在创建时 **衍生**行为 Buff / 能力挂载（§2.1 / §2.3）。

| 档 | Gain Buff 载荷 | 衍生？ | 消费 |
|---|---|---|---|
| **A. 只读特征** | TRAIT / ICON / 部分 KEYWORD「拥有」 | 通常 **无**（或仅 ICON→MODIFIER） | `effective_*` 并集 |
| **B. 文本能力 / 有行为的 keyword** | `ABILITY`（内嵌与印刷同构的 AbilitySpec）或 KEYWORD | **有** | 衍生挂载后走能力管线 / 行为三型 |

```text
gains 只读
  → Register Gain Buff（标记）
  → 查询并集；少衍生

gains 文本能力 / 行为 keyword
  → 编译 AbilitySpec 或 KeywordProfile 键
  → Register Gain Buff（壳 + 载荷）          ← 唯一 CREATED 结算
  → 【衍生】mount：
       · KeywordProfile → 再 Register LISTENER / RESTRICTION / MODIFIER
       · AbilitySpec    → Lifecycle（订时点 / COLLECT / Forced / Limit）
       · Constant 数值  → 可再衍生 MODIFIER
  → 之后与印刷能力 / 印刷 keyword **同 consumer**
  → Unregister Gain → 级联卸衍生
```

| 文本能力类型 | 衍生须做什么 |
|---|---|
| **Forced** | 订触发时点；窗到 **自动** 发起 |
| **`[reaction]` / `[free]`** | 订槽；进响应候选 |
| **`[action]`** | Activate 可发现 |
| **Constant** | Constant 查询集；数值可衍生 MODIFIER |
| **Revelation** | 仅显现入口解释 |
| **Keyword** | 标记已由 Gain 写出；**再**按 Profile 衍生行为 Buff |

> **禁止**：绕过 Gain Buff 真空挂 AbilitySpec；把 Forced **改叫** LISTENER；省略衍生只靠「effective 读到有这句话」。  
> **印刷** Forced = 能力，不经 Register。**效果 gains Forced** = Register Gain.`ABILITY` → **衍生** Forced 挂载。

**实现建议（薄）**：

```gdscript
# Template：一次 Register，buffs 含 Gain；衍生在 Store.on_register 回调
RegistrationTemplate.grant_characteristic(card_id, kind, payload, lifetime)
# on_register(gain_buff):
#   for derived in CharacteristicDeriver.expand(gain_buff):
#       register_child(derived)   # 行为 Buff，lifetime 绑父 Gain
#   if gain_buff.kind == ABILITY:
#       AbilityLifecycle.mount(gain_buff.ability_spec, bind)
```

**非本表**：`gain N resource` / `gain an action` = 状态原语，不走 Gain 特征。

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

**P1**：until-EOT `[reaction]` / Forced → Register Gain.`ABILITY` → 衍生 Lifecycle mount（**不是**改叫 LISTENER）。  
**P2**：trait / icon / 其它 keyword（Retaliate…）→ Gain 标记 + Profile **衍生**行为 Buff。

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
| Victory **X** | **关键词** Victory | 标量 `victory: int` | 击败 / 冒险结束改去向 | 不是 Buff | ✅ |
| Swarming **X** | **关键词** Swarming | 标量 count | 延时 LISTENER payload | 垫 X 张 facedown swarm | Core 无 |
| Seal 选哪个 token | **关键词** Seal | `SealSpec` / mode=choice | 打出成本 L6 + 进场 `pay_keyword_on_enter` | `CHAOS_PICK` | ✅ |

**禁止**：为括号单独 nest、单独 Register；把 Prey 括号当 Forced。

##### C. 关键词 → 三种 Buff

**拥有 ≠ 行为**。gained 先 KEYWORD 标记（`has_effective_keyword`），再按同一 `buff_types` 挂 Buff。印刷可直接挂 Buff（或 lazy 到查询）。一张卡可叠加多种（Elokoss：庞大 RESTRICTION + 反击 LISTENER）。

**C1 · RESTRICTION**（Eligibility / Intent 查询；mount 即生效）

| 关键词 | mount | Lifetime | payload / Intent | 消费 | 现状 |
|---|---|---|---|---|---|
| **Peril** 险境 | `AT_DRAW_G2` | `WHILE_DRAWN_CARD_RESOLVING` | `FORBID_PLAY` / `TRIGGER` / `COMMIT`（非 drawer） | L4 | ✅ |
| **Hidden** 隐私 | `AT_REVELATION` | 在手直至 expose | `FORBID_LEAVE_HAND`；另写 Domain `is_hidden` / FaceAudience | REST-E-MOVE；E4 秘密入手 | 运行时有；导入把 ArkhamDB `hidden` 旗标误当本词 |
| **Aloof** 冷漠 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | 禁自动交战；未交战 `FORBID` Fight | Fight / Engage Intent；spawn 内核读拥有以跳过 auto engage | ✅ |
| **Massive** 庞大 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | 永不进威胁区；虚拟交战同地点全体 | Engage / AOO 读交战；**3.3 攻击路径见 §3.2.7 REPLACE** | ✅ |
| **Permanent** 永久（对局） | `AT_SETUP` 开场进场 | 直至卡面允许离场 | `FORBID_MOVE` 离场 | REST-E-MOVE | △ Domain 旗标 |
| **Unique** 独特 | 打出/进场前查询 | in-play 期间 | 同名已在场 → 拒绝进场 | Initiation L5 | 待接线 |

**C2 · LISTENER**（Catalog emit；延时用 `UNTIL_FIRED`）

| 关键词 | mount | Lifetime | trigger | 开火 payload | 现状 |
|---|---|---|---|---|---|
| **Hunter** 猎手 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | `(seq.enemy.3_2, ENEMY_3_2)` · pri **10** | nest `seq.keyword.hunter`（移 1 步；等距读 Prey） | ✅ §3.2.7 |
| **Patrol** 巡逻 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | 同锚 · pri **20** | nest `seq.keyword.patrol`（向括号目标移 1 步） | ✅ §3.2.7 |
| **Retaliate** 反击 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | Fight 失败 · post-ST7 | `perform_attack(RETALIATE)` | ✅ |
| **Alert** 警戒 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | Evade 失败 · post-ST7 | `perform_attack(ALERT)` | ✅ 未进 `keywords[]` |
| **Elusive** 逃逸 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | 敌人攻击后 / 被 Fight 后 | disengage → 相邻 → exhaust | ✅ 未进 `keywords[]` |
| **Doomed** 厄运降临 | `AT_ENTER_PLAY` | `WHILE_IN_PLAY` | 击败（非 discard） | 当前密谋 +1 毁灭 | ✅ 未进 `keywords[]` |
| **Surge** 涌动 | 印刷 lazy；gained `AT_GRANT` | 绑本条抽取；开火后卸标记 | 本条抽取 **AFTER**（已结算） | nest `seq.draw.encounter` amount=1 | ✅ `KeywordConsumer` 竖切 |
| **Starting** 起始 | `AT_SETUP` / 换牌后 | `UNTIL_FIRED` | 起手+mulligan 之后 | 检索 1 张 Starting 入手 | 无 |
| **Swarming** | `AFTER_ENTER_PLAY` | `UNTIL_FIRED` | 进场结算之后 | 垫 **X** 张 swarm 牌 | Core 无 |

涌动不是新 BuffType。`KeywordConsumer` 只是该 LISTENER 尚未接入 TimingCatalog 时的竖切。

**C3 · 快速：打出形式，不是能力、也不是单独成本政策**

快速（Fast）为 **事件打出 ↔ 支援触发** 的窗口/**入口**对称而设。**打出始终是 `PLAY_CARD`，不是能力**；**打出本身无行动费用**，无快速时经 **Play 行动入口** 发起（[06-ability-initiation §4.2](06-ability-initiation.md#42-打出与触发对称fast打出-不是-能力)）。Fence/Chuck 与打出声明支通式见 [06 §4.2.1](06-ability-initiation.md#421-打出声明支额外费用包装--fence--chuck--可推广)。

| 打出形式 | 入口/窗口对称 | 种类 |
|---|---|---|
| 无 Fast | 激活触发 `[action]`（Play 行动入口） | `PLAY_CARD` |
| Fast、无时点（含无时点快速支援） | 免费触发 `[free]` | `PLAY_CARD` |
| Fast、有时点 | 反应触发 `[reaction]` | `PLAY_CARD` |

编译：`KeywordProfileTable.play_form`。**禁止** 把打出收成 `ABILITY`；**禁止** 与 ArkhamDB `[fast]` 文本符号合并；**禁止** 用宿主 `[free]` 冒充目标牌快速。

| 关键词 | mount | 改什么 | 消费 | 现状 |
|---|---|---|---|---|
| **Fast.** 快速 | 印刷；从 **HAND** 打出 | 选打出形式（上表） | 打出管线 | △ |

**C4 · 不走三种 Buff 的关键词**

| 关键词 | 落地 | 实现路径 | 现状 |
|---|---|---|---|
| **Uses (X)** | L0 进场放 typed token | 读 **B** 的 `UsesSpec`；扣 uses 走能力 cost | Domain 有 |
| **Victory X** | Domain 去向 | 击败敌人 / 冒险结束已揭示无线索地点 → 胜利展示区 | ✅ |
| **Vengeance X** | 同去向，计分语义相反 | 与 Victory 共用展示区 | Core 无 |
| **Seal** | L0 封印混乱标记 | 打出额外费用（L6 门槛）+ 进场 nest `seq.effect.seal`；离场释放；作刚揭示替换 | Domain ✅ |
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
> **绑已有流程，不另开场合节点**：禁止 `PERIL_CHECK`、`DRAWN_CARD_FINALIZE`、`CARD_DRAWN` 一类 **只为挂载发明的独立钩**。注册/注销要么是 **已有 `seq.*` handler 里的砖**（G2 / G4 / WHEN / AFTER），要么是这些流程 **已经在做的广义区划迁移**（L0 zone 写入）。
>
> **进场 / 离场不是第二套钩**（[22](22-seq-granularity.md)）：`ENTER_PLAY` / `LEAVE_PLAY` = 对**广义移动**的过滤别名（场外↔场上），不是独立 emit，也不是效果 seq。

**与能力 LISTENER 同一套 API**：`RegistrationStore.register` / `unregister`；差别只在 **绑哪条流程的哪一砖 / 哪次广义移动**，不是第二套监听总线。

##### 两类锚（不是第三套 enum）

| 类 | 绑什么 | 例子 |
|---|---|---|
| **A. 已有 seq 砖** | `register_flow_id` + `register_slot` | 险境 Register = `seq.draw.encounter` **G2**（已有 `_step_peril_register`）；卸 = 同流程 **G4**（已有 `_step_g4_resolve`） |
| **B. 广义移动（区划）** | `register_flow_id` 可空；`register_slot` = 过滤别名 `ENTER_PLAY` / `LEAVE_PLAY` / `ENTER_HAND` / … | 猎手：spawn / 打出里的 L0 广义移动且目标为场上；隐私：秘密入手 = 迁入手牌 |

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
| 密谋（Agenda）/ 场景（Act）Forced、Constant | 成为当前卡（`seq.setup` 或推进后进场） | **翻面离场**（a 面卸 `WHILE_IN_PLAY`；效果造的 `DURATION`/`UNTIL_FIRED` **保留**） | `WHILE_IN_PLAY` | PLAY |
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

#### 3.2.7 关键词监听：挂载时点 × 开火锚 × 优先级（已裁决）

> **前提**：关键词 LISTENER **不再由父流程 handler 内联管理**（例：`seq.enemy.3_2` 不含 Hunter/Patrol 移动路径）。因此必须写清三件事：**(1) 何时挂载**、**(2) 挂到哪条固定流程的哪个时点开火**、**(3) 同锚点多监听器的优先级**。

##### A. 三层勿混

| 层 | 字段（KeywordProfile） | 含义 |
|---|---|---|
| **挂载 mount** | `register_flow_id` + `register_slot`（或 zone `ENTER_PLAY`…） | 从何时起 **拥有 / 武装** LISTENER（可早于首次开火） |
| **开火锚 fire** | `fire_flow_id` + `consume_slot` | 监听 **哪条固定 `seq.*` 的哪一砖**；父流程只 **打开该槽**，不写关键词体 |
| **开火体 payload** | `consume_flow_id` → `seq.keyword.*` | nest 出去的移动/攻击/再抽等 |

```text
mount（进场 / G2 / …）
  └─ RegistrationStore LISTENER（武装）
固定流程到达 fire 锚
  └─ COLLECT 同锚 listeners
       ├─ 跨类：AbilityCategoryTier（06-ability §8.1）
       └─ 同类关键词：fire_priority 升序（本节 B）
            └─ nest consume_flow_id
```

**竖切现状**：`KeywordConsumer.consume_at(slot)` 在父流程 RESOLVE 砖内调用 = 落在 WHEN 响应批 **之后**，因而天然晚于同窗 **FORCED**（与 §8.1「LISTENER 整类在 FORCED 之后」一致）。目标态接入 TimingCatalog 后仍须保持该跨类序。

##### B. 优先级两层

| 层 | 规则 | 裁决者 |
|---|---|---|
| **跨类** | `FORCED` → `FRAMEWORK` → `TRIGGERED` → `DELAYED` → `LISTENER`（整批） | 引擎 · [06-ability §8.1](06-ability-initiation.md#8-timingbus-与优先级) |
| **同锚 · 关键词之间** | `KeywordProfile.fire_priority` **升序**（小者先）；并列 → keyword 名字典序 | **引擎固定**；**不可**队长强制对调关键词种类序 |
| **同锚 · 多实例同关键词** | 默认注册序；需要选用时走 Lead（§8.2 LISTENER 行） | 玩家 / 流程 |

`category_tier`：涌动 / Starting / Swarming = **`DELAYED`**（父流程 AFTER **之后** 另开或延时）；Hunter / Patrol / Retaliate / Alert / Elusive / Doomed = **`LISTENER`**。

##### C. 开火锚总表（Core 关键词 LISTENER）

| 关键词 | 挂载 | 开火锚 `(fire_flow_id, slot)` | tier | `fire_priority` | payload |
|---|---|---|---|---:|---|
| **Surge** | 抽牌 WHEN / GRANT | `(seq.draw.encounter, AFTER_DRAWN_CARD)` | DELAYED | 10 | `seq.keyword.surge` |
| **Hunter** | ENTER_PLAY | `(seq.enemy.3_2, ENEMY_3_2)` | LISTENER | **10** | `seq.keyword.hunter` |
| **Patrol** | ENTER_PLAY | `(seq.enemy.3_2, ENEMY_3_2)` | LISTENER | **20** | `seq.keyword.patrol` |
| **Massive** | ENTER_PLAY | `(seq.enemy.attack, ATTACK)` · PHASE kind | **REPLACE** | 10 | `seq.keyword.massive`（PHASE→batch；AOO 不替换为多目标） |
| **Retaliate** | ENTER_PLAY | `(seq.skill_test, POST_ST7_FAIL)` · Fight 失败 | LISTENER | 10 | attack（竖切） |
| **Alert** | ENTER_PLAY | `(seq.skill_test, POST_ST7_FAIL)` · Evade 失败 | LISTENER | 20 | attack（竖切） |
| **Elusive** | ENTER_PLAY | `(seq.enemy.attack, AFTER_ATTACK)`（含被 Fight） | LISTENER | 10 | flee+exhaust |
| **Doomed** | ENTER_PLAY | `(seq.effect.defeat, ON_DEFEAT)` | LISTENER | 10 | +1 agenda doom |
| **Starting** | setup / 库 | `(seq.setup, AFTER mulligan)` | DELAYED | 10 | 检索入手 |
| **Swarming** | ENTER_PLAY | `(seq.encounter.spawn, AFTER)` | DELAYED | 10 | 垫 X swarm |

**同锚已裁序**：

- **`ENEMY_3_2`**：Hunter **先于** Patrol（同敌双关键词时引擎固定；非玩家可选）。
- **`ATTACK`（庞大）**：**REPLACE** 挂在一般攻击效果 **`seq.enemy.attack`** 上 — PHASE kind 时替换为 batch；AOO 等仍单次（魔典）。敌军阶段 `phase_attacks` 只是固定手续 nest 攻击，**不是** REPLACE 锚。
- **`POST_ST7_FAIL`**：Retaliate / Alert 由 **行动种类**（Fight vs Evade）互斥过滤；`fire_priority` 仅防双合法时的引擎序。
- **遭遇抽牌队**：险境 / 显现 / G4 仍用 FrameworkPriority（[15 §4.0.5.2](15-timing-entry-catalog.md)）；**涌动不入该队**，在 AFTER 后以 DELAYED 开火。

##### D. 父流程职责（对照）

| 固定流程 | 基础手续（流程自己做） | 打开的关键词槽 | **不做** |
|---|---|---|---|
| `seq.enemy.3_2` | 枚举 ready / 未交战；开窗 | `ENEMY_3_2` | Hunter/Patrol 移动路径 |
| `seq.enemy.phase_attacks` | 玩家顺序；枚举交战敌人；**nest `seq.enemy.attack`（PHASE）** | —（不挂庞大） | 平行 massive 流程；在框架里写死 batch |
| `seq.enemy.attack` | 一般敌人攻击效果 | `ATTACK`（庞大 **REPLACE** · PHASE→batch）；`AFTER_ATTACK`（Elusive） | 把庞大写成 `phase_attacks` 的平行分支 |
| `seq.draw.encounter` | G1–G4 队列 | `AFTER_DRAWN_CARD`（涌动） | 把涌动写进 G1–G4 优先队 |
| `seq.skill_test` | ST.1–ST.8 | `POST_ST7_FAIL` | 在 ST handler 按名写死 Retaliate/Alert 体 |
| `seq.effect.defeat` | 击败内核（敌主体 TC=`enemy_defeated`） | `ON_DEFEAT` | 内联 Doomed 种类分支 |

**禁止**：为关键词另开与固定流程平行的 `seq.enemy.3_2_*` / `seq.enemy.massive_phase_attacks`；把庞大 REPLACE 锚错挂到 `phase_attacks`；在父 handler `match keyword` 写移动/攻击体；用队长选序跨越 Hunter↔Patrol 的 `fire_priority`。

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

### 4.1 合法性（dry-run）· 为何 Register 是原语

创建 Registration **即** 直接影响 / **CREATED**（见 [07-composition §4](07-composition.md)、[07-primitives §0](07-effect-primitives.md)）。

发起有效性与原语同一判据：**必须干了点什么**。若效果体 **既** 无任何物理原语能结算，**又** 无任何 Register 插入，则为 **空结算**，**禁止发起**。  
故「直到回合结束 +1」「获得 cannot」「挂上延时 LISTENER」等 **只靠 Register** 的效果体，必须把 Register 算作结算原语，否则合法挂 Buff 会被误判为空。

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

### 5.6 与印刷能力对比（勿称 Buff）

Asset 印刷 *Forced – After you fight: draw 1* / *After you fight, draw 1*（Constant/Forced）→ **`AbilitySpec`**，**不是**本条 LISTENER Buff 示例。

若实现把「在场订 `AFTER_YOU_FIGHT`」做成与 §5.1 **同形**挂载，lifetime 像 `WHILE_IN_PLAY`——那是机械复用；**概念上仍是能力**（§2.3）。  
真正的 LISTENER Buff 对照物：Event *Until end of your turn, after you fight, draw 1*（§5.1）——**效果创造**的持续壳 + Listener。

---

## 6. MODIFIER（数值修正 · 统一模型 · 已对齐）

> **定义**：Modifier = 对 **某个数值** 的修正。数值广泛存在；**不要**为每类数值各造一套引擎。  
> **实现面**：同一 `ModifierEngine` + `ModifierPayload` + `ModifierQuery`；差在 **数值域 / 值键 / 应用模式 / 查询站何时调用**。

### 6.1 三数值域（ValueRealm）

| 域 | 是什么 | 例子 | 典型消费时机 |
|---|---|---|---|
| **A. 印刷/特征量** | 卡面或实体上的印刷（及 gained）数值的 **有效读** | 玩家牌费用；地点 **隐藏值（shroud）**；调查员/支援生命·神智；调查员技能；敌人攻击/生命/躲避… | 读 effective 时 / 发起前算 cost / 建检定难度前读 shroud |
| **B. 效果量** | 即将 **结算** 的效果数量（可进 Plan） | 造成/治愈伤害·恐惧；发现/放置线索；获得/失去资源… | 效果 Plan 明确后、落点前 |
| **C. 序列标量** | **不是**效果结算，但是命名流程步上的比较/中间量 | **检定难度**；**检定技能值**（仅 ST 比较用）；**混乱标记**对本次检定的修正 | 命名流程砖内（如 ST.5 / 设 difficulty） |

**勿混**：

| | **印刷技能修正**（域 A） | **检定技能值**（域 C） |
|---|---|---|
| 含义 | 「你的战斗 +1」等，改实体有效技能 | 本次检定拿去 **和难度比较** 的那个数 |
| 组成 | 印刷 ∪ gained − blank 上的 MODIFIER | 常 = 有效技能 + 投入图标 + **序列修正**（含混乱） |
| 混乱标记 | **不**改域 A 印刷技能 | **属于**域 C（本次比较值或难度，按标记） |

### 6.2 统一构件（来源 · 载荷 · 查询 · 计算 · 寿命）

> **已对齐（2026-10-28）**：**信息层数值修正 = MODIFIER Buff**（经 `seq.effect.register`）。  
> 引擎算数仍只经 `ModifierEngine`；**混乱符号修正**属信息层，ST.4 创建 `THIS_SKILL_TEST` Buff，**不是** `SkillTestContext` 裸 int。  
> 投入图标等为检定组装底座（非信息原语），不 Register。

```text
数值修正系统（计算面 · 唯一）
  compute / apply_to_amount_plan
  叠加律共用（+/− → ×÷ → ceil → floor 0）
        ▲
        │ 汇入（按查询站收集）
        │
来源 Source
  ├─ Buff · Registration MODIFIER     ← seq.effect.register；含混乱符号能力修正
  ├─ 投入组装                         ← commit 图标加成（比较值底座；非 Buff）
  └─ 印刷底座                         ← compute 的 base（非 Buff）
```

| 来源 | 是 Buff？ | 寿命 | 例子 |
|---|---|---|---|
| Registration / Constant MODIFIER | **是** | `LifetimeSpec` / WHILE_IN_PLAY / **THIS_SKILL_TEST** | until… +1 fight；**混乱 token 技能修正**；费用 −1 |
| 投入组装 | **否** | 本次检定（已 commit） | 技能图标点数 |
| 印刷底座 | **否** | 实体上 | 未修正的 shroud / 技能印刷值（compute 的 `base`） |

```text
Buff 载荷 ModifierPayload（仅当来源是 Buff 时）
  value_key · op/value · match · apply_mode · plan_kind…

查询 ModifierQuery
  value_key + controller/subject + 上下文（test_id · location · skill · plan…）

引擎 ModifierEngine（唯一计算入口）
  compute(base, query)              → 汇入：匹配的 Buff +（若站需要）帧上短暂贡献
  apply_to_amount_plan(plan, …)   → 域 B：无名 +N 改已定效果的量（无目标）
```

**寿命**：Buff → Registration（混乱技能修正 = `THIS_SKILL_TEST`，ST.8 tick 卸）；投入 → 检定组装；**不**为每个 value_key 另造寿命系统。

**Buff 创建**：仍经 `seq.effect.register`；禁止真空 Store。dry-run：Register → CREATED。  
**混乱符号**：ST.4 = nest `seq.chaos.symbol`，挂在 `seq.chaos.reveal` 的 **After · Forced**（与其它 Forced 同档）；能力内 Register MODIFIER；Cancel/Ignore 对该能力帧及其 CREATED Buff。`SkillTestContext.chaos_modifier` 仅审计镜像。  
**非 Buff 来源**：commit 图标组装——**不是**信息原语 Register。

### 6.3 应用模式（与域的关系）

| apply_mode | 用于 | 行为 |
|---|---|---|
| **SCALAR** | 域 A 读值；域 C 序列量；单点效果量 | `compute(base, query)` |
| **CONSUME_CHOOSE_ONE_LEG** | 域 B Buff（每条用一次） | 无名 +N → `plan.apply_amount_bonus`；**修正不含目标** |

**主序（已裁决）**：**先确认目标 / 定效果** → **再**无名数值修正（只落在已定效果的量上）→ 物化/执行。

| `AmountEffectShape` | 卡面 | 定效果后 | 无名修正 | 执行 |
|---|---|---|---|---|
| **`DETERMINED`** | 单敌 / 03153 | 腿已定；攻击伤害 = primary | `+=` primary（攻击伤害量） | settle 腿 |
| **`ASSIGN`** | 04305 | 候选集已定；`amount` = 攻击伤害 | `+= amount` | Assign → legs → settle |

**禁止**：修正里带宿主；默认每腿 +1；把对敌量修混进调查员承伤 `DamagePipeline`。

### 6.4 值键增长规则

新增一种可修正数值时：

1. 归入域 A / B / C（上表）。  
2. 增加 **一个** `value_key`（或复用已有 Plan kind），**不要**新 Engine。  
3. 在 **有限查询站**（§16.3）挂一次 `compute` / `apply_to_amount_plan`。  
4. 多目标效果量 → AmountPlan + `effect_shape`（§16.3.2）。

```gdscript
## 示意 · 与实现 StatRef 对齐并扩展
enum ValueRealm { PRINTED, EFFECT_AMOUNT, SEQUENCE_SCALAR }

## 域 A 例：CARD_COST, SHROUD, HEALTH, SANITY, SKILL_*, ENEMY_FIGHT, ENEMY_EVADE…
## 域 B 例：plan_kind ATTACK_DAMAGE | DISCOVER；单点效果量亦可 SCALAR（资源等）
## 域 C 例：ST_DIFFICULTY, ST_SKILL_VALUE（比较用；含混乱贡献）
```

### 6.5 与现实现对照（迁移方向）

| 已有 | 域 | 备注 |
|---|---|---|
| `SKILL_*` / `SKILL_ANY` @ ST.5 | A→参与 C 组装 | 印刷维修正；ST.5 读有效技能后再加投入/混乱 |
| `SHROUD` @ Investigate | A | 读地点隐藏值 |
| `INITIATION_*_COST` | A | 费用 |
| `RESOURCE_GAIN_AMOUNT` | B | 单点效果量 |
| `AmountPlan`（仅 `ATTACK_DAMAGE` / `DISCOVER`） | B | 有消费式多腿场景才用 Plan；不为恐惧对称预留 |
| 混乱符号技能修正 | C（经 Buff） | ST.4 `seq.effect.register` · `THIS_SKILL_TEST`；ST.5 经 ModifierEngine；`chaos_modifier` 仅镜像 |

**ST.5**：`ST_SKILL_VALUE = 有效技能 + 投入 + ModifierEngine(含混乱 THIS_SKILL_TEST Buff)`；难度侧可 `ST_DIFFICULTY` 与域 A shroud 读分离（调查：先 A 读 shroud，再可叠加 C 的「本次难度」）。

详查询站与 Plan：§16.3。

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
| 密谋（Agenda）/ 场景（Act）印刷 Forced | 成为当前卡 | `WHILE_IN_PLAY` | 翻面离场（效果造的延时 **保留**） |
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
| Surge 流程 | **否** | 关键词 + **命名 seq**（非 BuffType） |
| Massive 攻击 | **否**（非第四 Buff） | **REPLACE** @ `seq.enemy.attack`（PHASE→`seq.keyword.massive`）；交战侧仍是 RESTRICTION；3.3 只 nest 攻击 |
| 抽牌 D2 / 遭遇 E2 **Reveal** | **否**（非 Buff） | L0 **`AtomRevealCard`** / `StateMutator.reveal_to_*`；见 [07 §5.3](07-effect-primitives.md) |

### 16.3 MODIFIER · 查询站清单

> **总纲**见 [§6](#6-modifier数值修正--统一模型--已对齐)：Modifier = 对数值的修正；三域（印刷量 / 效果量 / 序列标量）；**一个** Engine；查询站只决定 **何时** 调用。

**模式**：

| 模式 | API | 域 |
|---|---|---|
| 标量 | `ModifierEngine.compute(base, query)` | A 读值 · C 序列量 · B 单点 |
| 效果 Plan | `apply_to_amount_plan` | B：先定效果；无名 +N 改量（`effect_shape`） |

**禁止**：每类数值新 Engine；扁全球 `DAMAGE_AMOUNT` 冒充「本次攻击」；多腿效果量对每腿广播。

| 查询站 ID | 域 | 何时调用 | 键 | 状态 |
|---|---|---|---|---|
| **MOD-Q-SKILL** | A（喂 C） | 检定 ST.5 组装比较值 | `SKILL_*` / `SKILL_ANY` | **已实现** |
| **MOD-Q-ST-SKILL** | C | ST.5 比较用技能值（含混乱等序列贡献） | `ST_SKILL_VALUE` | 部分（混乱仍在 ctx；待收编） |
| **MOD-Q-ST-DIFF** | C | 设/改本次检定难度 | `ST_DIFFICULTY` | 待（与 shroud 读分离） |
| **MOD-Q-SHROUD** | A | 读地点隐藏值（常作调查难度底座） | `SHROUD` | **已实现** |
| **MOD-Q-COST** | A | Initiation 付费前 | resource/action cost | **已实现** |
| **MOD-Q-GAIN-RES** | B | 获得资源落点前 | `RESOURCE_GAIN_AMOUNT` | **已实现** |
| **MOD-Q-ATTACK-DAMAGE** | B | 攻击成功后、伤害落点前 | **AmountPlan** `ATTACK_DAMAGE` | **已实现** |
| **MOD-Q-DISCOVER** | B | 调查成功后、发现落点前 | **AmountPlan** `DISCOVER` | **已实现** |
| **MOD-Q-ENEMY-DAMAGE** | A | 敌人攻击造成前 | `ENEMY_DAMAGE` | **已实现** |
| **MOD-Q-ENEMY-HORROR** | A | 敌人攻击造成前 | `ENEMY_HORROR` | **已实现** |
| **MOD-Q-PRINTED-*** | A | 生命/神智/敌 fight·evade·health… | 对应 value_key | 待按卡增量 |

#### 16.3.1 技能：有类型 vs 无类型（`SKILL_ANY`）

| Payload.stat | ST.5 匹配 |
|---|---|
| `SKILL_COMBAT` 等 | 仅当本次检定技能相同 |
| **`SKILL_ANY`** | **任意**技能检定（纸面「+1 skill value」无指定维、类 wild） |

`compute`：标量载荷中 `stat == 本次技能 OR stat == SKILL_ANY`；`plan_kind != NONE` 的载荷 **不进** 标量 `compute`。

#### 16.3.2 攻击伤害 / 发现线索：Plan + 修正（重点）

基础 Fight →「对目标造成 1 伤害」；基础 Investigate →「在本地点发现 1 线索」。  
卡面常 **替换** 该效果（多目标伤、多地点发现等）。无名修正（致命打击、推理）必须作用在 **已定效果** 的量上。

**主序（已裁决 2026-10-26）**

1. **先确认目标 / 定效果**（单敌、多腿、或 ASSIGN 候选集）  
2. **再**无名数值修正——修正 **不含目标**，只改「本次攻击伤害 / 发现量」  
3. **再**物化（仅 `ASSIGN`：把已修正的攻击伤害 Assign 成腿）与 settle  

挂钩点是 **攻击/发现数值**，不是效果执行步，也不是 Assign 本身。04305 上「先修量再分」与「先分再修」若合格集相同则结果等价；规范仍用先修攻击伤害量。

**对敌造成 ≠ 调查员受到**：承伤量在「受到」才钉 → 先 Assign 再 `increase_pending`（[07 §4](07-effect-resolution.md)）。敌人承伤单主体、无 Assign。

```text
成功（Fight / Investigate / 指定行动）
  │
  ├─ 1–2. 定效果 → AmountPlan（kind + effect_shape + primary/candidates/legs）
  │
  ├─ 3. apply_to_amount_plan：无名 Buff 消费一次 → apply_amount_bonus
  │      DETERMINED：+= primary（攻击伤害线）
  │      ASSIGN：+= amount（攻击伤害数值）
  │
  └─ 4. settle：ASSIGN → nest `seq.effect.deal.assignable`；DETERMINED → nest `seq.effect.deal` + `legs[]`
```

**造成伤害/恐惧两条 seq（已裁决）**：`deal.assignable` = 待分配（伤+恐可同入参，可单边 0，Assign 后 **同时** Apply）；`deal` = 无分配已定（`legs_damage`/`legs_horror` 可单边空）。禁止伤/恐各开一条 assignable。发现线索仍一条 + `legs[]`。多目标 **不限单卡种**：凡有印刷生命/神智、或无印刷+`GRANT_CAPACITY` 的场上卡 ∪ 敌人 ∪ 调查员；无印刷+GRANT **不设可分配上限**；调查员伤/恐与敌人伤害分配无限。`DealSubject` 按 id 归类落点，L0 仍单目标。AFTER「受到伤害/恐惧/伤害和或恐惧」= 同一 `damage` 时点 + `affliction_filter`。

##### `AmountEffectShape`

| 形态 | 锚 | 定效果 | 无名 +N | 执行 |
|---|---|---|---|---|
| **`DETERMINED`** | 单敌 · 03153 | 腿已定 | 改 primary 攻击伤害 | settle |
| **`ASSIGN`** | 04305 | 候选已定；`amount`=攻击伤害 | 改 `amount` | Assign → settle |

```text
# DETERMINED（03153）
legs=[主:1, 旁:1] + 致命打击+1
  → [主:2, 旁:1]          ## 修正无目标；加在攻击伤害（主）上

# ASSIGN（04305）
amount=4, candidates=同地敌 + 致命打击+1
  → amount=5              ## 仍是攻击伤害数值
  → Assign(5) → legs      ## Gate ask_assign_among；逾期默认→primary
```

##### 发现线索

无名推理类同构：`DETERMINED` 下 += primary（调查地）。  
**指名落点**（09059 敌所在地、09108 任选地）由能力/事件 **效果步** 写入已定发现效果或另建腿——不是给无名 Buff 补宿主。

```gdscript
class AmountPlan:
    var kind: ModifierPlanKind
    var effect_shape: AmountEffectShape   # DETERMINED | ASSIGN
    var amount: int                       # ASSIGN=攻击伤害量；DETERMINED 与 primary 同步
    var legs: Array[AmountLeg]
    var primary_subject_id: StringName
    var candidate_ids: Array[StringName]
```

| 例子 | 行为 |
|---|---|
| 致命打击 @ 单敌/03153 | 改攻击伤害（primary） |
| 致命打击 @ 04305 | 改 `amount`；执行再 Assign |
| 推理 | 改调查地发现量 |
| 09059 / 09108 | 效果指名定发现对象；非无名 Buff 选腿 |
| Brand 替换 | 步骤 1–2 重写 Plan；再 apply |

**禁止**：`PER_EACH_LEG`；修正自带目标；用选腿冒充 04305 Assign；为恐惧对称预留 Plan kind。  
**Register**：`plan_kind` + `CONSUME_*`（用一次）；量变经 `apply_amount_bonus`。

##### additional 全路径（已对齐落地）

| 路径 | 序 | 入口 | 状态 |
|---|---|---|---|
| 玩家攻击伤害 | 定效果 → 无名改量 → settle | Fight ST.7 `AmountPlan` | ✅ |
| 发现线索 | 同上；指名 `add_named_bonus` | Investigate ST.7 / 效果步 | ✅ |
| 敌人攻击伤害/恐惧 | 定攻击 → 修印刷量 → **造成** | `EnemyAttack.build_from_enemy` → `DamagePipeline` | ✅ |
| 调查员承伤 +K | 先 Assign(N) → `increase_pending` | `DamagePipeline`（含敌人攻击） | ✅ |
| 04305 ASSIGN 物化 | 改 `amount` → Assign | `effect_shape=ASSIGN` | ✅ API + Gate（`ask_assign_among`） |
| 09059/09108 指名发现 | 效果步 `add_named_bonus` | Composition / 能力成功句 | ✅ API（MOD-12） |

**调查员承伤 additional（02221）≠ AmountPlan**：见 [07 §4](07-effect-resolution.md)。敌人攻击已并入同一承伤管线。

### 16.4 RESTRICTION · Intent × 入口主表

**模式**：Register RESTRICTION（`RestrictionKind` + payload）→ 在 **入口** 调 `RestrictionEvaluator.block_reason(intent, actor, store, ctx)`。  
**`Intent`** 对齐 **可被禁止的动作/效果类**（与 `ActionType` / Initiation / 关键 `EffectOp` 同族），**不对齐** `seq.*` 砖块编号。

**术语 · 兴趣类型（≠ LISTENER 订阅）**：某条命名流程（或等价结算入口）在 **RESOLVE 时必须检测** 的 `RestrictionKind` / Intent 集合。  
- **是**：handler / Flow 在规范时刻 **读** Store（拦 Intent 或原流程分支）。  
- **不是**：`(sequence_id, WOULD|WHEN|AFTER)` 订阅键；限制类 **不** 订时点、**不** 经 TimingBus emit。  
正向索引 = §16.4.2；**按 seq 反查** = [§16.4.4 兴趣类型报表](#1644-兴趣类型报表seq--须读的-restrictionkind)。

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
| **REST-E-AOO** | `AttackOfOpportunityResolver` @ INIT_2B | 付完 cost、跑借机前 | —（读 `SKIP_AOO` 供 **原流程分支**） |
| **REST-E-AUTO-ENGAGE** | `EnemySystem.auto_engage_at_location` | 区域变更后自动交战前 | —（读 `SUPPRESS_AUTO_ENGAGE`：跳过 Prey/Lead 自动交战） |

L4 与专用入口 **双查**（COLLECT 筛 eligible + 动作前再拦）对 **同一 Intent** 均可；payload / `drawer_id` 豁免在 `_matches` 内处理。

**限制类 Buff 的两种用法**（均 ≠ LISTENER、≠ Cancel/Ignore）：

| 用法 | 入口行为 | 例子 |
|---|---|---|
| **拦 Intent** | `RestrictionEvaluator.block_reason` → 拒绝发起 | `FORBID_PLAY` / peril |
| **原流程读取分支** | 规范时刻 **读** Restriction → 该流程自己改道（仍在同一 handler） | `SKIP_AOO` @ REST-E-AOO；`SUPPRESS_AUTO_ENGAGE` @ REST-E-AUTO-ENGAGE |

禁止把「原流程分支」译成 `seq.interrupt.cancel` / `ignore`，也禁止用 LISTENER 去「消掉」借机。

#### 16.4.2 Intent 与 RestrictionKind（增长表）

| Intent（`RestrictionEvaluator`） | 对齐 | 典型 `RestrictionKind` | Grimoire / 卡面来源 | 入口 | 状态 |
|---|---|---|---|---|---|
| `DRAW` | 抽牌 | `FORBID_DRAW` | peril 无关；卡面「不能抽牌」 | REST-E-DRAW | **已实现** |
| `PLAY` | 打出 asset/event | `FORBID_PLAY` | peril E3；immune play | REST-E-PLAY | Kind **已实现**；**ActionSystem 待接** |
| `TRIGGER` | initiate 能力 | `FORBID_TRIGGER` | peril E3；[reaction]/Forced | REST-E-TRIGGER | **已实现** · COLLECT L4 + Initiation |
| `COMMIT_TO_TEST` | commit skill | `FORBID_COMMIT_TO_TEST` | peril E3 | REST-E-COMMIT | **已实现** |
| `LEAVE_HAND` | 卡牌离开 HAND（move / discard / spawn 等） | `FORBID_LEAVE_HAND` | 隐私（Hidden）E4 | REST-E-MOVE（`StateMutator.move_card`） | **已实现** |
| —（原流程分支） | 借机不跑 | `SKIP_AOO` | 「This action does not provoke…」 | REST-E-AOO：`read_skip_aoo` | **已实现** · 翻译叶见 [20 §4](20-card-translation-schema.md) |
| —（原流程分支） | 自动交战不跑 | `SUPPRESS_AUTO_ENGAGE` | 「移入后 engages you」（明示交战，非 Prey/Lead；冷漠/横置仍靠 mode=effect） | REST-E-AUTO-ENGAGE：`read_suppress_auto_engage` | **已实现** · 理由见 [20 §4.2.1](20-card-translation-schema.md) |
| —（原流程读取） | 伤/恐分摊候选与约束 | `ASSIGN_CONSTRAINT` | 03109 prior-fill · 09007 min · 60232 max-trait · 04015/Bodyguard include · GRANT_CAPACITY | REST-E-ASSIGN：`DamageAssigner` @ `DamagePipeline` Assign | **已实现** · [07 §4](07-effect-resolution.md) |
| —（状态查询） | 成对交战状态 | `ENGAGEMENT` | 真实交战 / 视为交战（威胁区是区划检测，不是本 Buff） | `EngagementStatus` / `has_engagement` | **已实现** · [08 §3.1.1](08-enemy-engagement.md) |
| `DISCOVER_CLUE` | 发现线索 | `FORBID_DISCOVER_CLUE` | 「While engaged… cannot discover…」（01121b） | REST-E-EFFECT：`DiscoverClueFlow` | **已实现** · 与 ENGAGEMENT 同 Register，脱离卸 |
| `SPEND_CLUE` | 花费线索 | `FORBID_SPEND_CLUE` | 「…or spend clues」（01121b） | REST-E-EFFECT：`ActAdvanceFlow` / `spend_clues_group` | **已实现** · 同上 |
| `MOVE` | 移动行动 / 效果移动调查员 | `FORBID_MOVE` | 「不能离开地点」 | REST-E-ACTION / REST-E-EFFECT | 待 enum + 接线 |
| `ENGAGE` | engage 行动 | `FORBID_ENGAGE` | aloof 等（常配合 Condition） | REST-E-ACTION | 待 |
| `FIGHT` | fight / 攻击敌人 | `FORBID_ATTACK` | aloof 未 engage | REST-E-ACTION：`BasicActionResolver` / implicit | **已实现** · `AloofStatus.ensure_forbid_attack` @ 进场 |
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

#### 16.4.4 兴趣类型报表（seq → 须读的 RestrictionKind）

结算一条命名流程时，只查本行「兴趣类型」；**未列出的 Kind 本帧不必扫**。扩 cannot：先改 §16.4.2，再在本表给 **唯一** 消费方加一行（或并入已有行）；禁止在未登记流程里散落 `blocks_*`。

| 命名流程 / 结算入口 | 入口 ID | 兴趣类型（RestrictionKind） | 用法 | 状态 |
|---|---|---|---|---|
| `seq.effect.discover_clue`（`DiscoverClueFlow`） | REST-E-EFFECT | `FORBID_DISCOVER_CLUE` | 拦 Intent | **已实现** |
| `seq.act.advance`（`ActAdvanceFlow` 花线索） | REST-E-EFFECT | `FORBID_SPEND_CLUE` | 拦 Intent（该调查员不计入/不贡献） | **已实现** |
| Composition `spend_clues_group`（无独立 seq；与推进花线索同 Intent） | REST-E-EFFECT | `FORBID_SPEND_CLUE` | 拦 Intent | **已实现** |
| Composition draw atom / `seq.draw.investigator` 等价点 | REST-E-DRAW | `FORBID_DRAW` | 拦 Intent | **已实现** |
| `SkillTestEngine.commit_card`（检定 ST 投入；非独立 `seq.commit`） | REST-E-COMMIT | `FORBID_COMMIT_TO_TEST` | 拦 Intent | **已实现** |
| `StateMutator.move_card`（离手；隐私等） | REST-E-MOVE | `FORBID_LEAVE_HAND` | 拦 Intent | **已实现** |
| `seq.action.fight` / `BasicActionResolver.fight`（及 implicit 目标诊断） | REST-E-ACTION | `FORBID_ATTACK`（冷漠未交战） | 拦 Intent；已交战 Evaluator 放行 | **已实现** |
| Initiation INIT_2B · `AttackOfOpportunityResolver` | REST-E-AOO | `SKIP_AOO` | 原流程读取分支 | **已实现** |
| `EnemySystem.auto_engage_at_location`（常由 `seq.engage` mode=auto / 区域变更后触发） | REST-E-AUTO-ENGAGE | `SUPPRESS_AUTO_ENGAGE` | 原流程读取分支 | **已实现** |
| `DamagePipeline.deal_investigator` Assign（`DamageAssigner`） | REST-E-ASSIGN | `ASSIGN_CONSTRAINT` | 原流程读取（候选/先验/最小/最大） | **已实现** |
| `AbilityInitiationPipeline` / Action play·trigger 前 | REST-E-PLAY / REST-E-TRIGGER | `FORBID_PLAY` / `FORBID_TRIGGER` | 拦 Intent | Kind 有；接线见 §16.4.2 |
| `EffectResolutionGraph` step 4（`EffectRestrictionGate`） | REST-E-EFFECT | 按 `EffectOp`→Intent（§16.4.3） | 拦 Intent | 部分（如 DRAW） |
| （状态查询，非某 seq 结算兴趣） | — | `ENGAGEMENT` | `EngagementStatus` 成对查询 | **已实现** · 不进本表消费列 |

**与 LISTENER 对照**：LISTENER 的「兴趣」是 TimingBus 订阅键；本表的「兴趣」是 RESOLVE 读限制。二者不要写进同一列。

**规程**：新 `seq.*` 若可能被 cannot 挡住 → 在本表登记兴趣类型 + 在 handler 唯一入口调用 Evaluator；新 Kind 无消费方 → 不得标 ✅。

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
| Assign / prevent / reassign | `DamagePipeline` + Wrapper |
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
| Hunter 关键词 | 13 | `seq.enemy.3_2` → nest `seq.keyword.hunter` |
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
| 2026-10-26 | v0.4.49 | Assign Gate：`ask_assign_*` / among（04305） |
| 2026-10-26 | v0.4.49 | GRANT 无印刷不设上限；deal 双通道腿；AFTER 伤/恐/和或条件 |
| 2026-10-26 | v0.4.48 | `GRANT_CAPACITY`；deal legs 混装主体（敌/卡/调查员） |
| 2026-10-26 | v0.4.47 | 更名 `deal`；伤+恐同条 assignable、同时 Apply |
| 2026-10-26 | v0.4.46 | 明示 horror 与 damage 同两条 seq（`kind`） |
| 2026-10-26 | v0.4.45 | 伤害拆 `damage.assignable` / `damage`；ASSIGN settle → assignable |
| 2026-10-26 | v0.4.44 | settle 多目标：一条 seq + `legs[]`；L0 仍单目标（MOD-13/14/15） |
| 2026-10-26 | v0.4.43 | additional 全路径：敌伤 `ENEMY_DAMAGE` + 攻击进 `DamagePipeline`；指名 `add_named_bonus` |
| 2026-10-26 | v0.4.42 | §16.3.2：先定效果；无名 additional 只改攻击/发现量；`DETERMINED`/`ASSIGN` |
| 2026-10-26 | v0.4.41 | §16.3.2：对敌伤 `PIN_PRIMARY` / `ADD_TO_POOL`（由 v0.4.42 收成 effect_shape） |
| 2026-10-24 | v0.4.40 | incoming additional（02221）：保留 N 腿，仅增量 K @ 合法全合格集 |
| 2026-10-24 | v0.4.39 | 撤 AmountPlan HORROR kind/payload/settle 预留（无消费式多腿场景） |
| 2026-10-24 | v0.4.38 | 域 B：Attack/Discover Plan 收成 AmountPlan；统一 apply/settle |
| 2026-10-24 | v0.4.37 | 修正来源不全是 Buff：混乱/投入=检定帧贡献；Buff 只是来源之一 |
| 2026-10-24 | v0.4.36 | §6：Modifier=数值修正；三域印刷/效果量/序列标量；统一来源·计算·寿命·apply |
| 2026-10-24 | v0.4.35 | MOD-Q-SHROUD：StatRef.SHROUD + 基础 Investigate 算难度 |
| 2026-10-24 | v0.4.34 | DiscoverPlan 接线 Investigate；消费式发现修正 + PI；zero amount 不结算 |
| 2026-10-24 | v0.4.33 | MODIFIER 落地：SKILL_ANY；AttackDamagePlan 消费式+PI；基础 Fight 接线 |
| 2026-10-24 | v0.4.32 | Register 只写 Buff；Gain 特征族可衍生行为 Buff / 能力挂载；禁旁路 AbilitySpec |
| 2026-10-24 | v0.4.31 | 攻击/发现量修正消费式选一 leg；多候选触发 PI；禁对每个目标广播 |
| 2026-10-24 | v0.4.30 | §16.3：无类型技能 SKILL_ANY；AttackDamagePlan/DiscoverPlan 替代扁 DAMAGE/DISCOVER 量 |
| 2026-10-24 | v0.4.29 | §3.2.1a：gains 只读特征 vs 文本能力（须注册/初始化，同印刷挂载） |
| 2026-10-24 | v0.4.28 | §2.3：Forced/reaction/Constant = 能力 ≠ LISTENER Buff；修正 §5.6 举例 |
| 2026-10-24 | v0.4.27 | §2.2：结算面不按 BuffType/lasting 拆；控制等优先 Buff；Chronicle 外置 |
| 2026-10-24 | v0.4.26 | §2.1：Register（结算动词）与 Buff（Registration 载荷）；对齐 07 §5.4.2 |
| 2026-10-23 | v0.4.25 | 框架称呼：`SoakAssigner` → `DamageAssigner`（正式 Assign，弃用 soak） |
| 2026-10-23 | v0.4.24 | `ASSIGN_CONSTRAINT` 四算子；REST-E-ASSIGN / DamageAssigner；§16.4.2/§16.4.4 |
| 2026-10-20 | v0.4.23 | 冷漠 `FORBID_ATTACK`：进场 Register；Fight 入口读 Evaluator；§16.4.2/§16.4.4 标已实现；竖切 50026 Narôgath |
| 2026-10-20 | v0.4.22 | **§16.4.4** 兴趣类型报表：seq/入口 → 须读的 RestrictionKind（≠ LISTENER 订阅）；澄清「兴趣」= RESOLVE 检测 |
| 2026-10-10 | v0.4.21 | §3.2.7：庞大 REPLACE 锚改到 `seq.enemy.attack`；`phase_attacks` 仅为固定 nest 手续 |
| 2026-10-10 | v0.4.20 | §3.2.7：庞大 = REPLACE → `seq.keyword.massive`；删平行 massive 流程 |
| 2026-10-10 | v0.4.19 | **§3.2.7** 关键词挂载时点 × 开火锚 × 跨类/同锚优先级；`fire_priority`（Hunter 10 先于 Patrol 20） |
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
