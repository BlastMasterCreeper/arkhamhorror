# 24 — 函数式 `World` 值模型（草案）

> **状态**：设计草案 v0.1 · 2026-11-23  
> **依赖**：[01-game-state-zones](01-game-state-zones.md)、[07-effect-primitives](07-effect-primitives.md)、[06-registration-buff-model](06-registration-buff-model.md)、[17-seq-runtime](17-seq-runtime.md)  
> **被依赖**：[25-functional-eff](25-functional-eff.md)（`Eff` 代数）、Intent 提交 / 纯查询投影（本文只定 **局面值**）  
> **键名与类型总表**：[37-world-structure](37-world-structure.md)  
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
Auth (狭义「桌上事实」) = {
  physical,      -- ①区/序 · ②标记 · ③形态
  registrations, -- 信息原语主量（含寿命）
  chronicle,     -- 薄：日志∪记住
  audience,      -- 牌面可见性（非结算；在权威袋但 CREATED 不计）
  framework,     -- 回合/场景等局面级框架
  entropy,       -- 袋内剩余、已抽序列…
  limits,        -- 次数配额等已发生计数
  meta,          -- id 分配等
}

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

实现上可用一个大记录叫 `World`，但字段必须打上 **auth / derived** 标签；`transit` 返回整份 `Snapshot`。口语「世界值」= `Snapshot`（或至少 `auth ⊕ derived`），不是只等于 `physical`。

| 袋 | 分类 | 理由 |
|---|---|---|
| 卡在哪、横置、doom 数 | **auth** | 物理原语 |
| Registration / Buff | **auth** | 信息原语 |
| Chronicle / limits | **auth** | 已发生信息 |
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

## 2. `physical` — 对齐状态原语三类

与 [07 §0](07-effect-primitives.md) / 现有 `PhysicalStore` 对齐；**权威在物理袋**，Domain 标签（交战、当前密谋名）是投影或薄索引，不另造第二套真相。

### 2.1 形状（概念）

```text
Physical = {
  entities:  Map EntityId → EntitySpine,  -- 卡 / 调查员座位 / 地点座位…
  regions:   Map RegionId → Region,       -- 有序卡区、标记区
  placement: Map EntityId → Placement,    -- FREE|BESIDE|ATTACHED|UNDER|DECK_ORDERED…
  markers:   Map EntityId → MarkerBag,    -- damage/horror/doom/clue/resource/uses…
  form:      Map EntityId → Form,         -- face A/B · exhausted
}

Placement = { kind, region_id, index?, host_id? }
Form      = { face, exhausted }
MarkerBag = { damage, horror, doom, clue, resources?, uses?: Map UseKey → Int }
```

| 原语类 | 写入 | 读法 |
|---|---|---|
| ① 区/序 | 改 `placement` / `regions` 序 | `zone_of` · `order_in` · in-play 谓词 |
| ② 标记 | 改 `markers` | `doom_in_play` = fold |
| ③ 形态 | 改 `form` | `exhausted?` · `face` |

**LIMBO 子区**（[01 §3.5.0](01-game-state-zones.md)）：`Placement.kind = LIMBO` + `limbo_kind ∈ {RESOLVING, COMMITTED}` + 可选 `committed_test_id`。权威在 physical；`SkillTest.committed` 列表是 **Run** 内索引，须与之同步。

### 2.2 不变量（硬）

1. 每个卡实体至多一个 `Placement`。  
2. `ATTACHED` / `UNDER` / `BESIDE` 的 `host_id` 必须存在。  
3. `zone == LIMBO` ⇒ `limbo_kind` 有值；离开 LIMBO ⇒ 清空。  
4. id **单调分配、不复用**（与现 `PhysicalStore` 一致）→ `meta.next_entity_serial`。  
5. **控制权 / 所有者** 放实体脊骨字段（`owner_id` / `controller_id`），不单立原语；转移经效果 Intent，不是「光学改路径」。

### 2.3 与现实现映射

| 值字段 | 今日近似 |
|---|---|
| `entities` / `regions` | `PhysicalStore.players/cards/card_regions` |
| `markers` / `form` | `PhysicalCard` + Domain `TokenBag` 镜像 |
| 交战、威胁区语义 | Domain / Enemy 投影（可读 physical + regs） |

---

## 3. `registrations` — 信息主量

```text
Registrations = Map RegId → Registration

Registration = {
  id, source,           -- AbilityUnitRef / card instance…
  lifetime,            -- WHILE_IN_PLAY | WHILE_COMMITTED | THIS_SKILL_TEST | …
  scope,               -- 作用域过滤（值）
  buffs: [BuffSpec],   -- MODIFIER|RESTRICTION|LISTENER|KEYWORD|…
  tags
}
```

- **Register / Unregister** 是对 `World.registrations` 的 Intent，不是第二套 store API。  
- **寿命 tick**（ST.8、阶段结束、离场）= 纯函数  
  `tick(event, World) → World'`（卸匹配 lifetime 的记录）。  
- **有效关键词** = `physical` 印刷投影 ∪ Gain KEYWORD Buff（查询层，不把「有效集」存回 World，除非做缓存且可丢弃）。

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

## 6. `framework` — 局面级游标

只放**存档仍有意义**的框架字段：

```text
FrameworkSlice = {
  round_number,
  lead_investigator_id,
  active_investigator_id,   -- 若规则「谁的回合」属局面
  current_act_id,
  current_agenda_id,
  act_deck, agenda_deck,    -- 或 region 引用
  scenario_reference_id,
  doom_threshold?,          -- 或读自当前密谋 definition
  phase_id?,                -- Mythos/Action/… 若存档需要
}
```

**不放**：当前 Framework 步内的临时「正在结算 1.4 第几张」——属 `Run.stack` 帧参数。

---

## 7. `entropy` — 随机已决议

```text
Entropy = {
  chaos_bag: [Token],       -- 袋内剩余（多重集/序按实现）
  revealed_ledger: […],     -- 本次检定已揭示（亦可挂在 Run.skill_test）
  rng_seed: Seed,           -- 若仍需未抽尽的随机
}
```

规则内核内 **禁止**隐式 `rand()`：未抽完的随机必须来自 `entropy` 或驱动层预先注入的 token 列表。

检定进行中的「本测试已揭示」更常挂在 **`Run.skill_tests` 顶帧**；袋内剩余属 `World.entropy`。

---

## 8. `Run` — 执行游标（不进存档局面时可丢）

```text
Frame = {
  flow_id,           -- seq.*
  phase,             -- Would | When | Resolve | After…
  bind: Env,         -- card_id / controller / params
  cont: Eff,         -- 剩余效果树（值）
  cancelled: Bool
}

Run = {
  stack: [Frame],
  skill_tests: [SkillTestValue],
  memory: {
    referents: Map Controller → Map Key → Value,
    cancelled_keys: Set SequenceBindKey,
    encounter_frames: [EncounterFrameValue]
  },
  open_choice: ChoiceRequest | None
}
```

- **Ask / PI**：解释到 `Ask` ⇒ 返回 `NeedChoice(req, World, Run)`；驱动填答后纯续跑。  
- **Cancel**：置帧 `cancelled` 或对 `cont` 做纯剪枝（共享 Cancel 手续仍可 nest 为 `Eff`）。  
- 存档策略：可序列化 `World`；`Run` 可选（断点续算）或只存「玩家窗空闲」快照。

---

## 9. 投影（自变量裁切）

纯函数 **禁止**直接吃可变 `GameContext`。按需裁 `WorldView`：

| 用途 | 典型 View |
|---|---|
| `commit_only` / Eligibility | `test_kind` + 印刷 icons + 相关 regs |
| 有效关键词 | 实体 form + KEYWORD buffs + 印刷 |
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

```text
Intent =
  | PlaceEntity { id, placement }
  | Reorder { region_id, order }
  | TransferMarkers { … }
  | SetForm { id, face?, exhausted? }
  | RegInsert { registration }
  | RegRemove { filter }
  | ChronicleAppend { entry }
  | AudienceSet { id, audience }   -- 非 CREATED
```

- Composition / `seq` RESOLVE：**先** `plan` 得 `Intent[]`，**再** `commit`。  
- 真空禁令：无 `Run.stack` 顶帧（或框架允许的根 run）不得 `commit`。  
- Simultaneous：`Par` 的 plan 合并顺序由规范钉死，写入 Trace。

---

## 11. 设计裁决（本草案）

| # | 裁决 |
|---|---|
| W1 | **World / Run 分立**：局面值 vs 执行游标；指称与栈不进存档级 World |
| W2 | **物理权威单一**：三类原语只写 `physical`；交战等为投影 |
| W3 | **Registration 在 World**：寿命未到期的 Buff 是局面的一部分 |
| W4 | **Catalog 外置**：印刷与编译树不是 World 字段 |
| W5 | **Audience 在 World、非结算**：与 form 正交 |
| W6 | **唯一写法 = Intent commit**；查询/投影只读 |
| W7 | **与现引擎兼容路径**：`PhysicalStore`≈`physical`；`RegistrationStore`≈`registrations`；`RulesMemory`≈`Run.memory`；可先做 **快照导出 `World`** 供纯查询，不必一次替换对象图 |

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
