# 06d — Limit / Max（配额 · 基于 Core 2026 搜集）

> **依赖**：[06-ability-initiation.md](06-ability-initiation.md) L5、[06c-stat-projections.md](06c-stat-projections.md)、[06-registration-buff-model.md](06-registration-buff-model.md)、[07-effect-resolution.md](07-effect-resolution.md) InterruptTarget  
> **状态**：v0.1 · 2026-10-29 — 先搜集 Core 2026 再分类设计  
> **范围**：`core_2026` 玩家 + 遭遇 imported/pack；命中 **26** 张

---

## 1. 搜集摘要

| 印刷形态 | n | 例 |
|---|---|---|
| `(Limit once per round/game.)` | 13 | 12001 Daniela；12119 Warren Observatory |
| `(Group limit once per round.)` | 2 | 12116 Miskatonic Quad；12153 Southside |
| `Max 1 committed per skill test` | 4 | 12053/57 Out of Sight；12081 Timely Intervention；12084 On the Brink |
| `Limit 1 per investigator` | 5 | 12048/54 Sticky Fingers；12074 Hunter's Instinct；12125 Unspeakable Truths；12193 Languor |
| `Limit 1 per location` | 1 | 12157 Arcane Lock |
| `Limit 1 per deck` | 1 | 12181 Collector（Reward Permanent） |
| `Max N per period` / `Max N in play` / `(Max N)` 缩放 | **0**（本包） | 仍按 Grimoire 预留 |

完整逐卡表见运行产物 `limit-max-core2026-inventory.md`（artifacts）；下文按**设计族**收口。

---

## 2. 分类（设计族）

| 族 | 卡面 | Core 2026 | 门槛 | 计数权威 |
|---|---|---|---|---|
| **A · 发起配额** | Limit/Group limit once per period；能力上 Max per period | 15 | Eligibility **L5**（initiate） | `EventRecord` / StatProjection（`ABILITY_COMMENCED`） |
| **B · 投入 Max** | Max N committed per skill test | 4 | **Commit** 有效性 | 本检定已 commit 同名份数 |
| **C · 区域占位** | Limit N per investigator/location；Limit/Max in play 等 | 6 | **入区 / 进场 / 附着** 有效性 | Domain 同名在目标区域 |
| **D · 构筑** | Limit N per deck | 1 | 牌组构建 | deck list（对局外） |
| **E · 缩放封顶** | `(Max N)` / to a maximum of N | 0 | 效果结算钳制 | 当次量（**非**本配额系统） |

**默认**：Limit = per-player；**Group limit** = 全组共享。  
**Max**（能力全文）= 同名 title 全部复制品合计发起次数。  
**独特** ≠ Limit：关键词自有编译路径，**不**并入本表。

---

## 3. 设计裁决

1. **不是** `RegistrationKind`，**不进** `Registration.payloads[]`。声明 = `LimitSpec`（挂在能力 / 卡定义上）。
2. **A–D 统一：都不衍生 GATE。** 触顶 = 对应门槛现读失败；不 Register/Unregister 禁入场 GATE。
3. **Ignore the limit** → `InterruptTarget.kind = LIMIT`，绑定具体 `LimitSpec`；该次门槛跳过。Cancel/Ignore **效果**仍计 **A**（已 initiate）。
4. **E** 走效果参数 / MODIFIER 钳制，不进 `LimitSpec`。

```text
AbilitySpec.limits: LimitSpec[]     # A（及能力级 Max）
CardDefinition.limits: LimitSpec[]  # C / D（占位、构筑）；B 可在 skill 定义上
Commit / EnterZone / L5             # 各门槛读 LimitSpec + 计数
seq.interrupt.ignore · LIMIT        # 跳过该次检查
```

### 3.1 `LimitSpec` 草图

```gdscript
enum LimitKind { INITIATE_QUOTA, COMMIT_MAX, ZONE_OCCUPANCY, DECKBUILDING }
enum LimitPeriod { NONE, TURN, ROUND, PHASE, GAME, SKILL_TEST }
enum LimitAudience { PLAYER, GROUP, TITLE }  # TITLE = 同名合计（Max on ability）
enum ZoneConstraint {
    NONE,
    PER_INVESTIGATOR,
    PER_LOCATION,
    IN_PLAY,
    PER_DECK,
    VICTORY_DISPLAY,
    # …
}

class LimitSpec:
    var kind: LimitKind
    var amount: int
    var period: LimitPeriod
    var audience: LimitAudience
    var zone: ZoneConstraint
```

| 族 | kind | period | audience | zone |
|---|---|---|---|---|
| A Limit once per round | INITIATE_QUOTA | ROUND | PLAYER | NONE |
| A Group limit once per round | INITIATE_QUOTA | ROUND | GROUP | NONE |
| A Limit once per game | INITIATE_QUOTA | GAME | PLAYER | NONE |
| B Max 1 committed per skill test | COMMIT_MAX | SKILL_TEST | TITLE | NONE |
| C Limit 1 per investigator | ZONE_OCCUPANCY | NONE | PLAYER* | PER_INVESTIGATOR |
| C Limit 1 per location | ZONE_OCCUPANCY | NONE | — | PER_LOCATION |
| D Limit 1 per deck | DECKBUILDING | NONE | PLAYER | PER_DECK |

\*占位类「per investigator」= 每位调查员控制区/威胁区至多 N；与 A 的 PLAYER 发起配额不同轴。

---

## 4. 与 Registration / Ignore 的边界

| 机制 | 是否 payload | 说明 |
|---|---|---|
| Limit/Max（A–D） | **否** | 门槛现读 |
| 独特 | **否（本表）** | 关键词；可编译 GATE，但不是 LimitSpec |
| Ignore limit | InterruptTarget | 不是卸 Registration |
| 缩放 Max（E） | 否（非配额） | 量封顶 |

---

## 5. 实现顺序（建议）

1. `LimitSpec` + 编译器从能力/卡面抽出 A/B/C（Core 2026 竖切）
2. L5：`INITIATE_QUOTA` + commence 记账（含 Group / per game）
3. Commit 路径：`COMMIT_MAX`
4. 入区：`ZONE_OCCUPANCY`（Sticky Fingers / Arcane Lock / 威胁区 treachery）
5. `InterruptTarget.LIMIT`
6. 构筑 D 可后置；E 随效果参数

---

## 6. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-10-29 | v0.1 | Core 2026 搜集 26 张；五族分类；不进 payload、不衍生 GATE；独特分开 |
