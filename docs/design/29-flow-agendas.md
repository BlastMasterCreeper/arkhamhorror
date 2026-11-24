# 29 — Flow 议程表（第一批）

> **状态**：设计草案 v0.1 · 2026-11-23  
> **依赖**：[28-functional-scheme](28-functional-scheme.md) §4、[15 §3](15-timing-entry-catalog.md)、[06 §8](06-ability-initiation.md)、`EncounterDrawPriority`  
> **范围**：把总纲里的 Agenda **写成可逐步求值的表**。本批三张：`standard_ability_window`、`seq.draw.encounter`、`seq.draw.investigator`（后两张是一对 SPLIT，不能只钉遭遇）。

---

## 0. 议程步类型

```text
AgendaStep =
  | WouldCollect                          -- Q：替换/Cancel 候选
  | WouldResolve                          -- 按竞争规则跑；可 Ask ORDER/PICK；可 Nest
  | Impact { bricks: [Brick] }            -- 内联 Do；不开新三槽
  | Pipeline { id, fn }                   -- 父手续砖（K3）；可 Nest 子 Flow
  | CollectSlot { slot, tier }            -- 一类能力整批
  | ResolveBody                           -- interpret(Flow.body)
  | AfterCollect                          -- 整段完毕后的槽（不是「步骤 After」）
  | Exit

Brick = Do Intent 规格 | Reveal | EnterZone
```

求值函数（伪）：

```text
advance(ctx):
  step = flow.agenda[frame.agenda_ix]
  o = run(step, ctx)
  bind(o, ctx2 →
    if step 完成且未 Halt:
      frame.agenda_ix += 1
      if ix 越界: pop；续 cont_after
      else advance(ctx2))
```

`NeedAsk` 不增加 `agenda_ix`，直到 `resume` 宣布本步完成。

---

## 1. `standard_ability_window`

用于 **声明了标准能力时点** 的 Flow（例如多数 `seq.effect.*` 的 Would/When/After）。  
**不用于** 遭遇抽牌、调查员抽牌（见 §2、§3）。

槽 `WHEN` 与 `AFTER` 结构相同，只是 `slot` 不同。`ResolveBody` 在 When 整类结束之后、After 之前。

| ix | 步 | 函数 | 玩家决策 | 写入 |
|---|---|---|---|---|
| 0 | `WouldCollect` | `Q.collectWould(flow)` | 无 | 无 |
| 1 | `WouldResolve` | 竞争：最后发起；Forced 多个先序 | `ORDER_FORCED` 仅当多个 Forced 替换要排 initiate；否则无 Ask | 胜者 `Nest` 替换手续；败者丢弃 |
| 2 | 若 `cancelled` | 跳到 `Exit` | 无 | 无 |
| 3 | `Impact` | 本 Flow 若有「发起 impact」砖则内联；效果种类通常 **无** 单独 impact，空步 | 无 | 视砖 |
| 4 | `CollectSlot(WHEN, FORCED)` | `runClassBatch` | `≥2 → ORDER_FORCED`（不可 decline） | 各能力 `interpret`/`Nest` |
| 5 | `CollectSlot(WHEN, FRAMEWORK)` | 同上 | 类内序 | 同上 |
| 6 | `CollectSlot(WHEN, TRIGGERED)` | `runResponsePool` | `JOIN_POOL` / `PICK_RESPONSE` | 放行后 Nest |
| 7 | `CollectSlot(WHEN, DELAYED)` | 批或池（按该延时是否可选） | 视种类 | 视种类 |
| 8 | `CollectSlot(WHEN, LISTENER)` | 默认注册序 | 通常无 | 视 listener |
| 9 | `ResolveBody` | `interpret(body)` | 体内 `Ask` | `Do`→commit |
| 10–14 | `CollectSlot(AFTER, …)` | 与 4–8 相同五类顺序 | 同左 | 同左 |
| 15 | `Exit` | pop | 无 | 无 |

**不变量**

- 上一 `tier` 整类结束才进下一类。  
- 显现 **不** 出现在本表。  
- `ResolveBody` 前不解释 `body`。  
- 父 `Seq` 右支在 `Exit` 之后。

`seq.effect.deal` / `heal` / `move` / `register` 等卡面叶 `Nest` 时，默认套本表（除非该 Flow 另注册议程）。`body` 只有 L0（K2）。

---

## 2. `seq.draw.encounter`（单张）

对齐 `EncounterDrawPriority` 与 15 §3。**险境在 When 之前**；When 只覆盖抽取步骤完成后的玩家窗；显现与 G4 是 When 之后的管线，不是「抽取时」。

一张牌的议程（`amount>1` 时外层按张循环；每张走完本表再下一张。涌动 **不在** 本表内）。

| ix | 步 | 档 | 做什么 | Ask | World |
|---|---|---|---|---|---|
| 0 | `WouldCollect` | — | 将要抽取；牌仍在 **DECK** | 无 | 不 pop |
| 1 | `WouldResolve` | — | 替换/取消这次抽取 | 竞争规则 | 胜者可改 cont |
| 2 | 若取消抽取 | — | `Exit`（整次未抽） | 无 | 仍在 DECK |
| 3 | `Impact` | — | G1：pop + reveal（Hidden **跳过公开** reveal）→ **LIMBO** | 无 | 离库 |
| 4 | `Pipeline(peril)` | **100** | 带险境则父砖 Register RESTRICTION（K3，不走卡面 Nest） | 无 | Registration |
| 5 | `CollectSlot(WHEN, *)` | **95** | **标准五类**（§1 的 4–8），只服务「抽取时」 | 窗内 Ask | 牌已在 LIMBO |
| 6 | `Pipeline(revelation)` | **90** | `Nest seq.encounter.revelation`（独立类，不在 ix5 的 Forced 批） | 显现体内 | 显现结算 |
| 7 | 若显现被 Cancel | — | **不** 跳过 ix8 | 无 | 无显现 CREATED |
| 8 | `Pipeline(G4)` | **80** | 敌人 spawn / 诡计 `finalize_limbo_discard`；Hidden 秘密入手则跳过默认弃置 | 视 spawn | 进场或弃置 |
| 9 | `Pipeline(peril_end)` | — | Unregister 该卡 peril | 无 | 卸 RESTRICTION |
| 10 | `CollectSlot(AFTER, *)` | **75** | 抽取后五类；整段（含显现与 G4）已完 | 窗内 Ask | — |
| 11 | `Exit` | — | pop 本张帧 | 无 | — |

**涌动**：`seq.keyword.surge` 在 **本张 Exit 且本条指令结束后** 另 `Nest seq.draw.encounter`。不占 ix6–10。

**禁止**：在 ix0 pop；把 ix6/ix8 并进 ix5；Cancel 显现时删掉 ix8。

多张：`ForEach` 抽到的实例 **顺序** 跑完 §2 再算指令级 After（15：抽取后 = 这几张的显现/G4 都完）。指令级 Would 在 **第一张 pop 之前**（N 张都还在库）。

---

## 3. `seq.draw.investigator`（单张 / 一批的步骤边界）

| ix | 步 | 做什么 | 区 | Ask |
|---|---|---|---|---|
| 0 | `WouldCollect` | 将要抽；牌在 **DECK** | DECK | 无 |
| 1 | `WouldResolve` | 替换这次抽取 | DECK | 竞争 |
| 2 | 取消则 `Exit` | | DECK | |
| 3 | `Impact` | D1 pop + D2 reveal + D3 物理入手 | → **HAND** | 无（揭示是权限同步，不计单独 CREATED） |
| 4 | `CollectSlot(WHEN, *)` | 抽取时五类 | HAND | 窗内 |
| 5 | `Pipeline(enter_hand)` | `Nest seq.enter_hand`（显现在此，REVELATION 类内序） | HAND | 体内 |
| 6 | `CollectSlot(AFTER, *)` | 显现 nest 完后的抽取后 | HAND | 窗内 |
| 7 | `Exit` | | | |

两堆皆空：在 Impact 的 pop **失败** 时 `Nest seq.draw.empty_piles_defeated`，不进入 WHEN。  
多张：收集循环在 **同一 Would/When 政策** 下按 15：抽取时 = N 张都已入手；抽取后 = 各张入手显现都完。实现可以是外层 `repeat` 本表，但 **WHEN 的打开点** 仍是「抽取步骤完成」而不是每张 D1 单独一套 Would。

与遭遇的差别要写进数据：调查员 When 时 zone=HAND；遭遇 When 时 zone=LIMBO；显现入口不同（`enter_hand` vs `encounter.revelation`）。

---

## 4. 三张表怎么挂到 Catalog

```text
Catalog["standard_ability_window"] = template   -- 不是可 Nest 的 flow_id
Catalog["seq.draw.encounter"].agenda = §2
Catalog["seq.draw.investigator"].agenda = §3
Catalog["seq.effect.deal"].agenda = template standard_ability_window
Catalog["seq.effect.deal"].body = Do(TransferMarkers …)   -- K2
```

卡面「抽一张遭遇」= `Nest("seq.draw.encounter", {amount:1})`，进入 §2，**不**套 §1。

---

## 5. 手算（遭遇一张非 Hidden 诡计，显现被 Cancel）

```text
ix0 Would：牌在遭遇库顶。无替换。
ix3 Impact：pop → LIMBO。World 库少一张。
ix4 无 peril，空。
ix5 When：无能力。仍在 LIMBO。
ix6 Nest revelation：Ward Cancel → 子帧 cancelled，Exit。无显现 CREATED。
ix8 G4：仍然 discard 到遭遇弃牌堆。World 弃牌堆 +1。
ix9 无 peril。
ix10 After：无。
ix11 Exit。
```

涌动若在 After 延时上：本帧 Exit 之后 **另一条** `Nest draw.encounter`，不在 ix10 里 dequeue。

---

## 6. 本批不做

检定 ST 议程、`deal.assignable` 内部分配机、行动外壳（耗行动再 Delegate 到上表）。见 28 §13 第 2 步起。

---

## 7. 变更记录

| 日期 | 摘要 |
|---|---|
| 2026-11-23 | v0.1：标准能力窗五类；遭遇抽牌 100/95/90/80/75；调查员抽牌 SPLIT；Cancel 显现仍 G4 |
