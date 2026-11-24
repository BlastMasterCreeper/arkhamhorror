# 26 — `Eff` 种类表：Nest vs 内联（已裁草案）

> **状态**：设计草案 v0.1 · 2026-11-23（**种类默认已裁**）  
> **依赖**：[25-functional-eff](25-functional-eff.md)、[15 §4.0.5](15-timing-entry-catalog.md)、[07-composition §1.3.3](07-composition.md)、[22-seq-granularity](22-seq-granularity.md)、[20-card-translation-schema](20-card-translation-schema.md)  
> **权威实现对照**：`bootstrap/sequence_catalog_bootstrap.gd` · `CompositionNode` nest 叶  
> **范围**：卡面 / ST.7 / lasting 体里的 **效果叶** 编成 `Nest` 还是内联 `Do`；**不含** UI。

---

## 0. 一句话裁决

> **卡面（及同类效果体）引用已铸造的效果种类 → 默认 `Nest` 该 `FlowId`。**  
> **内联**只留给：同 Flow 的 handler 碎步、已由父手续砖拥有的时点、以及控制流/`Ask`/`Empty`/`Pass`。  
> **铸造 ≠ 可内联偷跑**；铸造是为了种类可被听到——卡面叶要听到，就得 `Nest` 打开信封。

这与「Catalog 有条目 ≠ 机械一律 nest」**不矛盾**：§4.0.5 的「否」落在 **handler 内 L0** 与 **父管线砖**，不落在「卡面写了 take horror 却 `Do` 掉 TC」。

---

## 1. 元规则（硬）

| # | 规则 |
|---|---|
| **K1** | **卡面效果叶 → 默认 `Nest FlowId`**（凡引用 `seq.effect.*` / 指名规则手续） |
| **K2** | **`Flow.body` / handler 内部** 的 L0（`transfer_marker`、单次 `set_exhausted`…）→ **内联 `Do`**；禁止再升格 `seq.atom.*` |
| **K3** | **父手续管线砖**（遭遇 G2 险境 Register、ENTER_PLAY 挂 Hunter…）→ 内联在该父 `seq.*` 的 RESOLVE；**不要**为了管线再 `Nest seq.effect.register`（卡面「获得…」创建仍走 K1） |
| **K4** | **ST.7 成败/fail-by 单元** → 挂在检定帧 **内联解释**；单元内部若引用抽牌/造成伤害等种类 → 仍按 K1 `Nest` |
| **K5** | **`Ask` / `If` / `Seq` / `Par` / `Empty` / `Pass`** → 不是效果种类；无 Nest/内联之争 |
| **K6** | **禁止铸造** 的 id（`seq.effect.enter_play`、独立 `seq.spend`…）→ 不进本表；见 [22](22-seq-granularity.md) |
| **K7** | 模板糖（`take_horror`）→ **解码到正式 `FlowId` 再 Nest**（下表「模板别名」）；禁止真空 Atom |

### 1.1 与 §4.0.5 对齐读法

```text
卡面「Take 1 horror. Then draw 1.」
  → Seq(
      Nest seq.effect.deal { horror=1, … },   -- K1：打开 deal 时点
      Nest seq.draw.investigator { amount=1 } -- 指名手续，必 Nest
    )

seq.effect.deal 的 handler 内
  → Do TransferMarkers …                    -- K2：碎步内联
```

「无新时点锚 → 内联」= **已经在该种类的信封里**，或 **父砖已提供锚**；不是「卡面叶可以跳过信封」。

---

## 2. 正式 `seq.effect.*` 种类表

列说明：

- **卡面叶**：编译进 Composition/`Eff` 时  
- **可听**：该 Flow 是否作为独立 TC / 时点入口（能力 hook 目标）  
- **备注**：例外与参数要点  

| `FlowId` | 卡面叶 | 可听 | 备注 |
|---|---|---|---|
| `seq.effect.deal` | **Nest** | 是 | 伤/恐已定；模板 `take_horror` / `take_damage` / `deal` → 本 id |
| `seq.effect.deal.assignable` | **Nest** | 是 | 待分配；Assign Gate 在本 Flow 内（Ask），不是另造 choose seq |
| `seq.effect.heal` | **Nest** | 是 | ≠ 非 heal 剥记；后者勿冒充 heal AFTER |
| `seq.effect.gain_resource` | **Nest** | 是 | 行动外壳可 Delegate；卡面叶仍 Nest 本 id |
| `seq.effect.lose_resources` | **Nest** | 是 | 与「花费」正交（费用=属性，不铸 spend） |
| `seq.effect.lose_action` | **Nest** | 是 | |
| `seq.effect.place_doom` | **Nest** | 是 | **≠** `seq.mythos.place_doom`（议程进度） |
| `seq.effect.place_clue` | **Nest** | 是 | ≠ discover |
| `seq.effect.discover_clue` | **Nest** | 是 | 多地 `legs[]` 一帧 |
| `seq.effect.register` | **Nest** | 是 | 卡面创建 Buff/KEYWORD/限制；**管线砖除外（K3）** |
| `seq.effect.unregister` | **Nest** | 是 | 卡面明示卸；寿命 tick 可走框架内联卸 |
| `seq.effect.discard_card` | **Nest** | 是 | 统一弃牌；G4 limbo discard 属父抽牌砖，不走本叶冒充 |
| `seq.effect.attach` | **Nest** | 是 | |
| `seq.effect.resign` | **Nest** | 是 | 卡面不展开体内留置线索 |
| `seq.effect.move` | **Nest** | 是 | 狭义；`subject`/`move_kind` 参数化 |
| `seq.effect.exhaust` | **Nest** | 是 | 费用 exhaust 仍走 Cost，不 Nest 本 id 当费用 |
| `seq.effect.ready` | **Nest** | 是 | |
| `seq.effect.evade` | **Nest** | 是 | 效果核；`mode=automatic`=卡面执行；≠ `seq.action.evade` |
| `seq.effect.search` | **Nest** | 是 | 含库内 Ask；搜库须洗 |
| `seq.effect.seal` | **Nest** | 是 | 进场关键词支付亦 Nest（非真空） |
| `seq.effect.release_seal` | **Nest** | 是 | |
| `seq.effect.reveal_location` | **Nest** | 是 | 进入未揭示地点规则自 nest |
| `seq.effect.defeat` | **Nest** | 是 | 成功后 **再 Nest** `seq.defeat.leave_play`（退场不内联进击败叶） |

**本表无「卡面叶 = 内联」行**：现行已铸造效果种类在卡面侧 **一律 Nest**。内联只出现在 K2–K5。

---

## 3. 常与卡面叶一起出现的非 `effect` 手续

| `FlowId` | 卡面叶 | 备注 |
|---|---|---|
| `seq.draw.investigator` | **Nest** | 「抽 N 张」 |
| `seq.draw.encounter` | **Nest** | 罕见卡面；涌动开火另见 keyword |
| `seq.enter_hand` | **Nest** | 显现入口；由入手规则 nest，卡面少直写 |
| `seq.skill_test.*` | **Nest** | 检定；ST.7 后果内联在检定帧（K4） |
| `seq.engage` | **Nest** | `mode=effect` 等；冷漠/横置不靠改 auto 布尔 |
| `seq.zone.move` | **Nest** | 广义区划；进场/离场=过滤，**不铸** `seq.effect.enter_play` |
| `seq.defeat.leave_play` | **Nest** | 仅由击败成功后 nest |
| `seq.interrupt.cancel` / `ignore` | **Nest** | Cancel/Ignore |
| `seq.replace.instead` | **Nest** | Instead |
| `seq.keyword.surge` 等 | **Nest** | **开火**；创建走 `seq.effect.register` |

---

## 4. 模板别名 → 正式 Nest 目标

编译 JSON `template` → `Eff` 时先归一：

| 模板 / 旧称 | 解码为 |
|---|---|
| `take_horror` / `take_damage` / `deal_damage` | `Nest seq.effect.deal`（或 assignable，若需分配） |
| `draw` | `Nest seq.draw.investigator` |
| `gain_resource` / `gain_resources` | `Nest seq.effect.gain_resource` |
| `place_doom` | `Nest seq.effect.place_doom` |
| `discover` / `discover_clue` | `Nest seq.effect.discover_clue` |
| `grant_keyword` / `register` / 具名限制叶 | `Nest seq.effect.register` |
| `heal` | `Nest seq.effect.heal` |
| `exhaust` / `ready` | `Nest seq.effect.exhaust` / `ready` |
| `move` / `move_to` / `nest_enemy_move_*` | `Nest seq.effect.move` + params |
| `search` | `Nest seq.effect.search` |
| `evade`（执行） | `Nest seq.effect.evade` `mode=automatic` |
| `resign` | `Nest seq.effect.resign` |
| `discard` | `Nest seq.effect.discard_card` |

---

## 5. 明确的内联清单（非种类默认）

| 情境 | 形态 | 理由 |
|---|---|---|
| 任意 `seq.effect.*` handler 内 L0 | `Do Intent` | K2；碎步无独立 TC |
| 遭遇抽牌 G2 险境 Register | 父 `seq.draw.encounter` 砖 | K3 |
| 进场挂 Hunter / Massive 等 profile | 父进场/区划手续砖 | K3 |
| 寿命 tick 卸 Registration | 框架/`tick` 纯更新或薄 unregister | 非卡面叶；可内联卸 |
| ST.7 `on_success` / `on_fail` / `on_fail_by_each` 外壳 | 检定帧内联 `Eff` | K4；**禁止** nest 成败窗 |
| `Empty` 空打出正文 | `Empty` | 发起 CREATED；无 Nest |
| `Ask` 选目标后再 Nest move | `Ask` 然后 `Nest` | 选择不是 nest |

---

## 6. 禁止与易混

| 错误 | 正确 |
|---|---|
| 卡面 take horror → 真空 `Do TransferMarkers` | `Nest seq.effect.deal` |
| 因「Catalog 有」在 handler 里再 Nest 自己 | handler 内联 L0（K2） |
| 卡面创建涌动 → 内联 Store.register | `Nest seq.effect.register` |
| 管线险境 → 再 Nest `seq.effect.register` | 父砖 Register（K3） |
| 击败成功 → 内联弃置敌人 | `Nest seq.effect.defeat` 成功后再 `Nest` 退场 |
| 进场 → `Nest seq.effect.enter_play` | **不存在**；听 `seq.zone.move` |
| 费用花资源 → `Nest seq.effect.lose_resources` | 费用属性；与失去效果分轨（G10） |

---

## 7. 对 `Eff` 编译器的含义

```text
compile_effect_leaf(template, params) =
  let fid = resolve_flow_id(template)   -- §4 别名表
  in  Nest fid (env_from params)        -- K1；无「可选内联」开关

compile_flow_body(handler) =
  Seq/Do …                              -- 仅 Intent；不 Nest 同 fid
```

卡面 JSON **不应**再出现「同一 take_horror 有时 nest 有时 atom」双路径；竖切与 `CompositionNode.*` nest 叶与本表对齐。

---

## 8. 与实现差距（跟踪）

| 项 | 现状 | 目标 |
|---|---|---|
| `CompositionNode` 效果叶 | 大多已 `nest_flow_id` | 保持；禁回流真空 Atom |
| dry-run | 走 Executor | 将来 `Eff.plan` 对 `Nest` 标「将 nest」/委派子 L7 |
| 文档 25 锚例「或内联 Do」 | 含糊 | **以本表为准**：卡面叶 Nest |

---

## 9. 下一步

1. JSON↔`Eff` 编解码按本表强制 Nest。  
2. 审计 imported `compiled_abilities` 是否仍有真空叶。  
3. 纯测：卡面 deal Nest 可被 LISTENER 听到；handler 内 L0 不再开子帧。

---

## 10. 变更记录

| 日期 | 摘要 |
|---|---|
| 2026-11-23 | v0.1：K1–K7；全表卡面叶默认 Nest；内联仅 K2–K5；模板别名 |
