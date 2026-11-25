# 24 — 函数式 `World` 值模型（草案）

> **状态**：设计草案 v0.4 · 2026-11-25  
> **依赖**：[01-game-state-zones](01-game-state-zones.md)、[07-effect-primitives](07-effect-primitives.md)、[06-registration-payload-model](06-registration-payload-model.md)、[17-seq-runtime](17-seq-runtime.md)  
> **被依赖**：[25-functional-eff](25-functional-eff.md)（`Eff` 代数）、Intent 提交 / 纯查询投影（本文只定 **局面值**）  
> **键名与类型总表（权威形状）**：[37-world-structure](37-world-structure.md) — 若本文与 37 冲突，**以 37 为准**。  
> **与现实现关系**：对照 `PhysicalStore` · `GameStateStore` · `RegistrationStore` · `RulesMemory`；**不**要求立刻替换 Godot 对象图，先定值边界与不变量。

---

## 0. 目标与非目标

| 目标 | 非目标 |
|---|---|
| 把「规则可判定的局面」收成 **不可变值** `World` | 重写 Godot / 换语言 |
| 与物理三类 + Register + 薄 Chronicle **同构** | 把 UI、输入、网络塞进 `World` |
| 明确 **World vs Run**（局面 vs 执行游标） | 用 lens 宗教替代 Cancel/Instead 手续 |
| 为纯查询 / dry-run / 重放提供稳定自变量 | 每步深拷贝整桌当性能方案（实现可选结构共享） |

**一句话**：`World` = 存档级规则局面；`Run` = 正在走的手续栈与待确认选择。纯内核吃 `(World, RunEnv)`，写出 `(World', RunEnv') | NeedChoice`。

---

## 1. 总结构

快照要**分类**，不要把权威事实、派生投影、执行游标糊成一袋：

```text
Snapshot = {
  auth,      -- 权威局面（结算写这里）
  derived,   -- 派生（可重建；含可行性 Φ）
  run,       -- 进度游标
}
-- Catalog 外置，永不进 Snapshot
```

```text
Auth (狭义「桌上事实」；形状以 37 为准) = {
  cards, regions, seats,  -- 物理三类落点（§2；无嵌套 auth.physical）
  registrations,          -- 信息原语主量（含寿命）
  gains,                  -- Gain 特征（≠ Registration 载荷）
  chronicle,              -- 薄：日志∪记住
  audience,               -- 牌面可见性（非结算；CREATED 不计）
  limits,                 -- 次数配额等已发生计数
  framework,              -- 回合/场景等局面级框架
  next_id                 -- id 分配
}
-- 混乱袋剩余 = regions[place=chaos].token_stacks（不再单列 auth.entropy）
-- 检定已揭示挂 Run.skill_tests / augury；rng 若需另议，不默认进 auth

Derived = {
  index,         -- 登记倒排（34）
  feasibility,   -- Φ：当前焦点发起/must 可行性（35）
}

Run = {
  stack,         -- 手续帧栈
  open_choice,   -- NeedAsk | None
  skill_tests,   -- 检定栈
  memory,        -- 步间指称
  timing_phase,  -- 信封相位等
  focus,         -- 当前窗/控制者/打开的 must（枚举宇宙用）
}
```

实现上可用一个大记录叫 `World`，但字段必须打上 **auth / derived** 标签；`transit` 返回整份 `Snapshot`。口语「世界值」= `Snapshot`（或至少 `auth ⊕ derived`），**不是**只等于「物理三类」。

| 袋 | 分类 | 理由 |
|---|---|---|
| 卡在哪、横置、doom 数、席位行动 | **auth**（cards/regions/seats） | 物理原语 + 席位机 |
| Registration / payloads | **auth** | 信息原语（Registration 载荷） |
| Chronicle / limits / gains | **auth** | 已发生信息 |
| FaceAudience | **auth**（旁路） | 非结算，但属局面权限 |
| index / feasibility Φ | **derived** | 由 auth(+run 焦点) 重建；算时不读旧 Φ.answers |
| 「本手续选中的敌人」 | **run** | 步间指称 |
| 序列栈、检定步 | **run** | 执行游标 |
| CardDefinition 印刷 | **Catalog** | 外置 |
| PI 超时时钟 | **驱动** | 不纯；结果进 run 后再 transit |

```text
Catalog（外置）
Auth × Derived × Run × Catalog  →  query / plan / transit
transit 末尾：按 Touched 刷新 Derived（兴趣点）
```

---

## 2. 物理三类 — 落在 `auth.cards` / `regions` / `seats`（无嵌套 `physical`）

与 [07 §0](07-effect-primitives.md) 对齐。早期草案曾写 `auth.physical = {…}`；**现形状以 [37](37-world-structure.md) 为准**：不设嵌套 `physical` 袋，三类原语直接落在权威字段。

| 原语类 | 权威落点（37） | 读法 |
|---|---|---|
| ① 区/序 | `regions[].card_ids`（`host_card_id`+`place`） | `zone_of` · `order_in` · in-play |
| ② 标记 | `regions[].token_stacks`（宿主 `place:"tokens"` 等） | fold；经 `TransferToken` |
| ③ 形态 | `cards[].face` / `exhausted` | 翻面 / 横置 |
| 席位经济 / 结局 | `seats[]`（非 Card 脊骨） | 行动剩余 · eliminated |

**LIMBO**（[01 §3.5.0](01-game-state-zones.md)）：悬置区 `limbo_kind ∈ {resolving, committed}`。权威在 `regions`；`SkillTest.committed_ids` 是 **Run** 索引，须与之同步。

### 2.1 不变量（硬）

1. 每张卡至多出现在一个区的 `card_ids`（派生可建反向索引）。  
2. `attachments` / `under` / `beside` 的宿主卡必须存在。  
3. 在悬置区 ⇒ `limbo_kind` 有值；离开 ⇒ 清空。  
4. id **单调分配、不复用** → `auth.next_id`。  
5. **控制权 / 所有者** 在 `Card`（`owner_id` / `controller_id`），不单立原语；转移经 Intent。

### 2.2 与现实现映射

| 值字段（37） | 今日近似 |
|---|---|
| `cards` / `regions` | `PhysicalStore` 卡与区 |
| `token_stacks` | Domain `TokenBag` / 标记计数 |
| `seats` | `InvestigatorState` 行动/淘汰等 |
| 交战 | Registration `status/engagement`（非 Card 字段） |

---

## 3. `registrations` — 信息主量

```text
Registrations = Map RegId → Registration

Registration = {
  id, source,              -- AbilityUnitRef / card instance…
  lifetime,               -- WHILE_IN_PLAY | WHILE_COMMITTED | THIS_SKILL_TEST | …
  subject,                -- Bound | Matching
  payloads: [RegistrationPayload],  -- MODIFIER|GATE|DIRECTIVE|LISTENER|STATUS
  tags
}
```

- **Register / Unregister** 是对 `World.registrations` 的 Intent，不是第二套 store API。  
- **寿命 tick**（ST.8、阶段结束、离场）= 纯函数  
  `tick(event, World) → World'`（卸匹配 lifetime 的记录）。  
- **有效关键词** = 印刷 ∪ **Gain 特征**（非 Registration 载荷；查询层，不把「有效集」存回 World，除非做缓存且可丢弃）。

Silas / Daring 类：`uncommit` 只卸 `WHILE_COMMITTED` 与绑在该卡上的 `after_test_ends` 延时；**保留** `THIS_SKILL_TEST` lasting —— 全部由 lifetime 数据表达，不靠隐藏可变标志。

---

## 4. `chronicle` — 薄记事

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
- 进 `World` 是为了查询与同步仍是「局面的一部分」；权限层，不是第三类原语。

---

## 6. `framework` — 局面级游标（精简 · 对齐 37）

只放**存档仍有意义**且非区/Catalog/Run 的指针。权威形状见 [37 §1.4](37-world-structure.md)：

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
| `act_deck` / `agenda_deck` | `auth.regions` |
| `doom_threshold` | Catalog（密谋 definition） |
| `scenario_reference_id` | 冒险装载 / Catalog（不塞 Framework） |
| `phase_id` | `run.timing_phase` |
| 手续内「正在结算第几张」 | `Run.stack` 帧参数 |

---

## 7. 随机 / 混乱袋（不再单列 `auth.entropy`）

| 内容 | 落点（37） |
|---|---|
| 袋内剩余 | `regions` 中 `place:"chaos"` 的 `token_stacks` |
| 本次检定已揭示 | **`Run.skill_tests` 顶帧** 与/或 `augury` 区 |
| 仍需未抽尽的 `rng_seed` | **另议**；不默认进 auth（内核禁止隐式 `rand()`） |

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
- 存档：可序列化 auth；`Run` 可选（断点续算）或只存「玩家窗空闲」快照。

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
view : World → WorldView   -- 纯；可缓存
query : WorldView × Spec → Answer
plan  : World × Env × Eff → Intent[]
commit: World × Intent[] → World   -- 唯一写入口
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
| W1 | **World / Run 分立**：局面值 vs 执行游标；指称与栈不进存档级 World |
| W2 | **物理权威单一**：三类原语只写 `auth` 的 cards/regions（+ seats）；**不**嵌套 `auth.physical`；交战等为 Registration / 投影 |
| W3 | **Registration 在 World**：寿命未到期的 **payloads** 是局面的一部分 |
| W4 | **Catalog 外置**：印刷与编译树不是 World 字段 |
| W5 | **Audience 在 World、非结算**：与 form 正交 |
| W6 | **唯一写法 = Intent commit**；查询/投影只读 |
| W7 | **与现引擎兼容路径**：`PhysicalStore`≈cards/regions；`RegistrationStore`≈`registrations`；`RulesMemory`≈`Run.memory`；可先做 **快照导出** 供纯查询 |

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
