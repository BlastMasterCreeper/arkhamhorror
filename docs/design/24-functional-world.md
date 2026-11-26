# 24 — 函数式 `World` 值模型（草案）

> **状态**：设计草案 v0.7 · 2026-11-26  
> **依赖**：[01-game-state-zones](01-game-state-zones.md)、[07-effect-primitives](07-effect-primitives.md)、[06-registration-payload-model](06-registration-payload-model.md)、[17-seq-runtime](17-seq-runtime.md)  
> **被依赖**：[25-functional-eff](25-functional-eff.md)（`Eff` 代数）、Intent 提交 / 纯查询投影  
> **键名与类型总表（权威形状）**：[37-world-structure](37-world-structure.md) — 若本文与 37 冲突，**以 37 为准**。  
> **函数世界定义**：[38-functional-data-world](38-functional-data-world.md)（`World_FP ≜ Data`）。  
> **口径**：`Snapshot.data` = Data；分区 **Board × Facts × Constraints**（+ Audience）；物理袋叫 **Board**，不叫世界；Control=`Run`；CREATED = 改 Data（Audience 可除外）。

---

## 0. 目标与非目标

| 目标 | 非目标 |
|---|---|
| 定 **Snapshot** = Data × Control × Derived | 重写 Godot / 换语言 |
| Data 内按代数角色分区（物理只是一类 sort） | 把「世界」说成只有桌上物理 |
| 明确 Data vs Run vs Catalog | 用 lens 宗教替代 Cancel/Instead |
| 为 dry-run / 重放提供稳定自变量 | 每步深拷贝整桌当性能方案 |

**一句话**：函数世界 = **Data**；Run = 控制；Catalog 外置。详见 [38](38-functional-data-world.md)。
---

## 1. 总结构

快照要**分类**，不要把权威事实、派生投影、执行游标糊成一袋：

```text
Snapshot = {
  data,      -- World_FP = Data（结算写这里）
  derived,   -- 派生（可重建；含可行性 Φ）
  run,       -- 进度游标（Control）
}
-- Catalog 外置，永不进 Snapshot
```

```text
Data（形状以 37 为准；≡ World_FP）= {
  board:        Board,         -- 物理分区：cards/regions/seats + framework
  facts:        Facts,         -- relations · gains · chronicle
  constraints:  Constraints,   -- policies（Fold/Guard/Divert/OnTiming）
  limits:       LimitStore,    -- 配额计数（非物理；不进 Board）
  audience,                    -- 权限旁路；CREATED 不计
  next_id
}
-- 混乱袋 = board.regions[place=chaos].token_stacks
-- 检定已揭示挂 Run.skill_tests；rng 若需另议

Derived = { index, feasibility }
Run = { stack, open_choice, skill_tests, memory, timing_phase, focus }
```

**函数世界 = `data`（整袋 Data）**。Board 只是物理分区。详见 [37 §0](37-world-structure.md) / [38](38-functional-data-world.md)。

| 袋 | 分类 | 理由 |
|---|---|---|
| cards / regions / seats / framework | **board** | 物理分区（+ 框架游标） |
| relations / gains / chronicle | **facts** | 断言与薄记事 |
| policies | **constraints** | 运作叠层（非桌上物） |
| LimitStore | **limits** | 次数/配额（非物理；不进 Board） |
| FaceAudience | **audience** 旁路 | 非结算 |
| index / feasibility Φ | **derived** | 可重建 |
| 手续栈 / 选择 / as-if 叠镜 | **run** | 执行游标 |
| CardDefinition | **Catalog** | 外置 |

```text
Catalog（外置）
Data × Run × Catalog  →  query / plan / transit
```

---

## 2. 物理三类 — 落在 `data.board`（cards / regions / seats）

与 [07 §0](07-effect-primitives.md) 对齐；形状以 [37](37-world-structure.md) 为准。

| 原语类 | 权威落点（37） | 读法 |
|---|---|---|
| ① 区/序 | `board.regions[].card_ids` | `zone_of` · `order_in` · in-play |
| ② 标记 | `board.regions[].token_stacks` | fold；经 `TransferToken` |
| ③ 形态 | `board.cards[].face` / `exhausted` | 翻面 / 横置 |
| 席位经济 / 结局 | `board.seats[]` | 行动剩余 · eliminated |

**LIMBO**（[01 §3.5.0](01-game-state-zones.md)）：悬置区 `limbo_kind ∈ {resolving, committed}`。权威在 `regions`；`SkillTest.committed_ids` 是 **Run** 索引，须与之同步。

### 2.1 不变量（硬）

1. 每张卡至多出现在一个区的 `card_ids`（派生可建反向索引）。  
2. `attachments` / `under` / `beside` 的宿主卡必须存在。  
3. 在悬置区 ⇒ `limbo_kind` 有值；离开 ⇒ 清空。  
4. id **单调分配、不复用** → `data.next_id`。  
5. **控制权 / 所有者** 在 `Card`（`owner_id` / `controller_id`），不单立原语；转移经 Intent。

### 2.2 与现实现映射

| 值字段（37） | 今日近似 |
|---|---|
| `cards` / `regions` | `PhysicalStore` 卡与区 |
| `token_stacks` | Domain `TokenBag` / 标记计数 |
| `seats` | `InvestigatorState` 行动/淘汰等 |
| 交战 | `data.facts.relations` · Engagement（非 Card；威胁区在 world.regions） |

---

## 3. `facts` / `constraints` — Data 分区（与 Board 并列）

```text
Facts = { relations, gains, chronicle }
Constraints = { policies }   -- PolicyBody = FoldStat | GuardIntent | DivertFlow | OnTiming
```

- **FactInsert / ConstraintInsert / CompanionRemove** 写伴件；插入成功 = CREATED。  
- **寿命 tick** = 纯函数卸匹配 lifetime 的 Relation/Policy。  
- **有效关键词** = 印刷 ∪ **Gain**（Facts）；行为衍生进 Constraints。  
- 旧 `registrations.payloads` 五类：status→Relation；其余四类→PolicyBody。

Silas / Daring：`uncommit` 只卸 `WHILE_COMMITTED` 与绑卡延时；**保留** `THIS_SKILL_TEST` lasting —— 由 lifetime 表达。

---

## 4. `chronicle` — 薄记事（∈ Facts）

```text
Chronicle = {
  log: [LogEntry],           -- 可截断的事件迹（重放/调试）
  remembered: Map Key → Value  -- 「记住」类；≠ RulesMemory 指称
}
```

- 计入 CREATED（[07 §0](07-effect-primitives.md)）。  
- **不要**把步间 `set_referent` 塞进 chronicle；那是 `Run.memory`。

---

## 5. `audience` — 可见性（非结算）

```text
Audience = Map EntityId → FaceAudience   -- HIDDEN_ALL | CONTROLLER | ALL
```

- 与 `form.face` **正交**（背面仍可知）。  
- dry-run **不**因仅改 audience 而 CREATED。  
- 挂在 `data.audience`（旁路）；权限层，不是窄 World，也不是第三类原语。

---

## 6. `framework` — 局面级游标（精简 · 对齐 37）

只放**存档仍有意义**且非区/Catalog/Run 的指针。权威形状见 [37](37-world-structure.md)（Framework ∈ Board）：

```text
Framework = {
  round:                   Int,
  lead_investigator_id:    String,
  active_investigator_id:  String,
  current_act_id:          String,
  current_agenda_id:       String
}
```

| 早期草案字段 | 现落点 |
|---|---|
| `act_deck` / `agenda_deck` | `data.board.regions` |
| `doom_threshold` | Catalog（密谋 definition） |
| `scenario_reference_id` | 冒险装载 / Catalog（不塞 Framework） |
| `phase_id` | `run.timing_phase` |
| 手续内「正在结算第几张」 | `Run.stack` 帧参数 |

---

## 7. 随机 / 混乱袋（不再单列 `data.entropy`）

| 内容 | 落点（37） |
|---|---|
| 袋内剩余 | `board.regions` 中 `place:"chaos"` 的 `token_stacks` |
| 本次检定已揭示 | **`Run.skill_tests` 顶帧** 与/或 `augury` 区 |
| 仍需未抽尽的 `rng_seed` | **另议**；不默认进 Data（内核禁止隐式 `rand()`） |

规则内核内未抽完的随机必须来自已决议的袋堆或驱动层预先注入的 token 列表。

---

## 8. `Run` — 执行游标（对齐 37 §3）

权威形状见 [37 §3](37-world-structure.md)。摘要：

```text
Run = {
  stack,           -- Frame[]：flow_id / env / step_index / cancelled / created / cont_after
  open_choice,     -- ChoiceState | null（效果体内有限期确认）
  skill_tests,
  memory,          -- controller → (key → value)；扁平，无 encounter_frames 专用袋
  focus,           -- window / controller / must / InitiationPool ids / ResponsePool ids
  timing_phase     -- 信封相位摘要（≠ Frame 微步）
}
```

- **Ask / PI**：解释到 `Ask` ⇒ `NeedAsk`；驱动填答后纯续跑。  
- **Cancel**：置帧 `cancelled` 或剪枝 `cont_after`（共享 Cancel 仍可 nest）。  
- **Focus 池 ids**：粘性池权威成员（[16](16-player-interaction.md)），属 Run 而非 derived。  
- 存档：可序列化 `data`；`Run` 可选（断点续算）或只存「玩家窗空闲」快照。

---

## 9. 投影（自变量裁切）

纯函数 **禁止**直接吃可变 `GameContext`。按需裁 `WorldView`：

| 用途 | 典型 View |
|---|---|
| `commit_only` / Eligibility | `test_kind` + 印刷 icons + 相关 regs |
| 有效关键词 | 实体 form + Gain 特征 + 印刷 |
| dry-run CREATED | 目标实体 markers/placement + regs（只读） |
| 地点连通移动 | locations 图 + placement |

```text
view : Snapshot → WorldView   -- 纯；可缓存（可读 world/facts/constraints）
query : WorldView × Spec → Answer
plan  : Snapshot × Env × Eff → Intent[]
commit: Snapshot × Intent[] → Snapshot   -- 唯一写入口；可触 World/Facts/Constraints
```

---

## 10. Intent 与提交（World 的唯一变法）

权威 Intent 枚举以 **[37 §5.1](37-world-structure.md)** 为准（`TransferToken` / `MoveCard` / `FlipToken` / Reg* / Seat* …）。下文仅为早期示意，勿再当作形状源。

- Composition / `seq` RESOLVE：**先** `plan` 得 `Intent[]`，**再** `commit`。  
- 真空禁令：无 `Run.stack` 顶帧（或框架允许的根 run）不得 `commit`。  
- Simultaneous：`Par` 的 plan 合并顺序由规范钉死，写入 Trace。

---

## 11. 设计裁决（本草案）

| # | 裁决 |
|---|---|
| W1 | **窄 World / Run 分立**：物理局面 vs 执行游标；指称与栈不进 World |
| W2 | **物理只在 Board**：三类原语写 `data.board`；**不**嵌套 `data.physical` |
| W3 | **Facts × Constraints 是 Data 分区，与 Board 合称世界**：Relation/Policy 有寿命、可 CREATED，但口语「世界」不含它们 |
| W4 | **Catalog 外置**：印刷与编译树不是 Snapshot 字段 |
| W5 | **Audience 旁路、非结算**：与 form 正交；不计 CREATED |
| W6 | **唯一写法 = Intent commit**；查询/投影只读 |
| W7 | **兼容路径**：`PhysicalStore`≈board；旧 RegistrationStore≈data.facts.relations∪data.constraints.policies；`RulesMemory`≈`Run.memory` |

---

## 12. 下一步（非本文范围）

1. ~~`Eff` 代数~~ → [25-functional-eff](25-functional-eff.md)。  
2. `World` 快照导出器（从现 `GameContext` → 值）+ 1～2 个纯查询金样（有效关键词、commit_only）。  
3. dry-run `plan` 对齐 `CompositionDryRunner` / `Eff.plan`。

---

## 13. 变更记录

| 日期 | 摘要 |
|---|---|
| 2026-11-23 | v0.1 初稿：World/Run 分立、physical/regs/chronicle/audience/framework/entropy、Intent 唯一写 |
| 2026-11-25 | v0.2：对齐 37 — Auth 扁平（无 `physical`/`entropy` 袋）；W2 改写；Intent/混乱袋指向 37 |
| 2026-11-25 | v0.3：Framework 收成 37 五字段；剔除 deck/threshold/phase 等 |
| 2026-11-25 | v0.4：Run/Focus 对齐 37；去掉 memory 专用袋 / Frame.phase 旧形 |
| 2026-11-25 | v0.5：统一口径 — 窄 World；Facts×Constraints；改 W1–W7；废「Registration 在 World」 |
| 2026-11-25 | v0.6：对齐 38 — 函数世界=Data；分区表语义；指针改 38 |
| 2026-11-26 | v0.7：对齐 38/37 — Auth→Data；World→Board；废窄世界称谓 |
