# 25 — 函数式 `Eff` 代数（草案）

> **状态**：设计草案 v0.1 · 2026-11-23  
> **依赖**：[24-functional-world](24-functional-world.md)、[07-composition](07-composition.md)、[07-effect-primitives](07-effect-primitives.md)、[15-timing-entry-catalog](15-timing-entry-catalog.md) §4.0.5、[16-player-interaction](16-player-interaction.md)、[17-seq-runtime](17-seq-runtime.md)  
> **被依赖**：解释器 `step` / `plan`、编译器目标 IR、与现 Composition / Catalog 的对照落地  
> **定位**：规则内核的 **效果中间语言**；卡面与命名手续 **共用同一代数**，差别只在是否带时点信封与 `FlowId`。

---

## 0. 为何这一步重要

[24](24-functional-world.md) 定了 **写什么（World）**；本文定 **怎么写（Eff）**。

没有 `Eff`：

- Composition 与 `seq.*` 仍是两套叙事，函数式内核接不上；
- 内联 / nest / PI 三分法只能靠文档约定，不能进类型；
- dry-run / CREATED / Cancel 无法对「同一套树」做纯变换。

有了 `Eff`：

```text
编译：卡面 / 章节 → Eff
装载：挂到 Run 栈帧（带 FlowId 的手续）或帧内续跑
解释：step(World, Run, Eff) → (World', Run') | NeedChoice
提交：仅经 Intent commit（见 24 §10）
```

**硬门槛不变**（[07 §1.0](07-composition.md)）：禁止真空；三分法；应展尽展。

---

## 1. 设计原则（已裁）

| # | 原则 |
|---|---|
| E1 | **一套代数**：卡面树与手续体都是 `Eff`；禁止 `seq.card…` |
| E2 | **叶只有 Intent / 空结算 / 指名手续**：控制流不是效果，不铸造 `seq.then` |
| E3 | **三分法进构造子**：`Seq`≈内联 then；`Nest`≈新时点锚；`Ask`≈PI（非 nest、非 Then） |
| E4 | **时点是信封，不是树节点**：Would/When/After 属 `Flow` / 帧相位，不做成 `Eff.After(...)` 糖 |
| E5 | **Cancel / Instead = Nest 共享手续**（或对剩余 `cont` 的纯剪枝），不是光学改 World |
| E6 | **plan 与 commit 分离**：`plan : World × Env × Eff → Intent[]`；`commit` 唯一写 World |
| E7 | **与现引擎同构可迁移**：现 `CompositionNode` / Catalog handler 可视为 `Eff` 的具体编解码 |

---

## 2. 语法

### 2.1 核心构造子

```text
Eff ::=
    Do Intent                         -- 单叶结算（物理 / Register / Chronicle / AudienceSet…）
  | Empty                             -- EmptySettle（锚 09125；L7 认 CREATED，不写局面）
  | Seq Eff Eff                       -- 内联 then（同帧；无新时点锚）
  | Par Eff Eff                       -- 同时组（组内规范序钉死；组完才 After）
  | If Pred Eff Eff                   -- 条件；Pred 只读 World×Env
  | Nest FlowId Env                   -- 压子手续（Catalog 已有 / 铸造的 seq.*）
  | Ask ChoiceSpec Cont               -- PI：确认后 Cont(answer) 续跑
  | ForEach CollSpec (Elem → Eff)     -- 编译期或运行时展开；禁糖宏残留
  | Pass                              -- 无操作（≠ Empty：Empty 计发起完备；Pass 不计 CREATED）
```

> **`Empty` vs `Pass`**：`Empty` = 框架完备的空效果体（打出无正文）；`Pass` = 控制流占位（`If` 的 else 常为 Pass）。发起 dry-run：`Empty` → CREATED；`Pass` → 不贡献 CREATED。

### 2.2 派生 / 糖（编译期消去）

| 糖 | 展开为 |
|---|---|
| `Then[e1,e2,…,en]` | 右结合 `Seq` |
| `All[e1,…,en]` | 右结合 `Par` |
| `Optional Ask` | `Ask` + default=decline → `Pass` |
| Interrupt / Replace 卡面节点 | `Nest seq.interrupt.* / seq.replace.instead` + 目标 Env |
| L3 宏（多步） | **禁止**进运行时；编译展开为 `Seq`/`Ask`/`Nest` |

### 2.3 `Flow`：具名手续 = 时点信封 + 体

```text
Flow = {
  id: FlowId,                 -- seq.draw.investigator / seq.effect.take_horror / …
  timing: TimingEnvelope,     -- 是否开放 Would/When/After；槽位
  params: ParamSpec,          -- 静态参数模式
  body: Eff                   -- 手续体（可 Nest 其它 Flow、可 Ask）
}

TimingEnvelope = {
  has_would, has_when, has_after: Bool,
  -- 细节对齐 15；此处只强调：信封在 Flow，不在 Eff 节点
}
```

- **Catalog** = `Map FlowId → Flow`（外置，同 24 Catalog）。  
- 纸面无名效果句 → 铸造 `seq.effect.*` 的 `Flow`（[07 §1.3.3](07-composition.md)）；**铸造 ≠ 每次 Nest**：卡面引用时仍按 §4.0.5 决定 `Do`/`Seq` 内联解释体，或 `Nest`。

### 2.4 `Env`（指称环境）

```text
Env = {
  controller_id, card_id, ability_id, definition_id?,
  flow_id,                    -- 当前所在手续（provenance）
  targets…,                   -- test_enemy / chosen / memory 键
  amount?, mode?,             -- 效果参数
  interrupt_target?,          -- Cancel/Instead
  st7_slot?,                  -- on_success / on_fail / …
}
```

`Ask` 的答案写入 `Run.memory`，后续 `Pred` / `Env` 解析读指称——**不**把答案写进 `World`（除非答案本身是结算 Intent）。

---

## 3. 三分法 ↔ 构造子（硬映射）

对齐 [15 §4.0.5](15-timing-entry-catalog.md) + [16](16-player-interaction.md)：

| 形态 | 判据 | `Eff` 构造 | 对 Run 的影响 |
|---|---|---|---|
| **内联** | 上一步 **未** 打开本步时点锚 | `Seq` / `Do` / 同帧解释铸造体 | 不 push 帧；改 `cont` |
| **nest** | 时点已到且条件满足 → 独立结算 | `Nest FlowId Env` | push `Frame`；子 Flow 跑完再续 |
| **玩家确认** | choose / may / 选目标 / 选支 | `Ask ChoiceSpec Cont` | `NeedChoice`；**不** push 手续帧 |

**禁止**：

- `Nest` 包一层假 `seq.choose.*`；  
- 用 `Seq` 冒充选择；  
- 「Catalog 有条目 ⇒ 一律 `Nest`」。

**铸造体何时 `Nest`：** 仅当该效果种类需要可被 When/After 听到的 **独立结算帧**（§4.0.5 为是）。否则解释器把 `Flow.body` **内联**进当前帧（语义等于把体展开进 `Seq`，不 push）。

```text
卡面「Take 1 horror」
  └─ 卡面叶 → Nest seq.effect.deal（种类表 26 · K1）
     handler 内 TransferMarkers → 内联 Do（K2）
```


---

## 4. 操作语义（概念）

### 4.1 总形态

```text
Outcome =
    Continue { world: World, run: Run, cont: Eff }
  | NeedChoice { world, run, request: ChoiceRequest, resume: Answer → Eff }
  | Done { world, run }           -- 本帧/本根 Eff 耗尽
  | Blocked { reason }            -- Cannot / 无合法默认 等（少见；优先 default）
```

驱动循环：

```text
loop:
  match step(world, run, cont):
    Continue → 更新引用，继续
    NeedChoice → 驱动确认/超时默认 → cont' = resume(answer)
    Done → pop 帧或结束根
```

### 4.2 `plan` / `commit`

```text
plan(world, env, eff) → { intents: Intent[], created: Bool, asks: … }

-- dry-run / L7：不 commit；Created 规则同 07 §0 / §4
-- 真结算：commit(world, intents) → world'  后 再处理 Nest/Ask 控制
```

| 节点 | plan 行为 |
|---|---|
| `Do i` | 若可应用 → `[i]`，CREATED 按原语 |
| `Empty` | `[]`，**created=true**（完备空体） |
| `Pass` | `[]`，created=false |
| `Seq a b` | 真实序：先 a（可 commit）再 plan b；dry-run 常 OR |
| `Par a b` | 两支 plan 合并；顺序规范钉死；同时组提交策略对齐现 Simultaneous |
| `If p t e` | 求值 `p(world,env)`；只 plan 选中支 |
| `Nest` | plan **不**展开子手续叶（或标记「将 nest」）；CREATED 由子手续自己的 L7/发起规则另议 |
| `Ask` | 不产生 Intent；带 default 时 dry-run 可试默认支 |

### 4.3 `Nest` 与时点信封

```text
step(…, Nest fid env):
  flow = Catalog[fid]
  push Frame { flow_id=fid, env, cont=flow.body, phase=Would?… }
  -- 按 TimingEnvelope 走 Would → When → Resolve(body) → After
  -- Resolve 内再 step body
  pop 后回到父 cont 的后续
```

父树里的 `Seq(Nest draw, Do horror)`：`Nest` 跑完（含子 After）再 `Do horror`——对应现「抽牌 nest 完再 then」。

### 4.4 `Ask`

```text
step(…, Ask spec cont):
  cands = eligibility(world, spec)     -- 纯查询
  req = ChoiceRequest { cands, default, timeout_policy }
  return NeedChoice { …, resume = λ ans. cont(ans) }
```

默认 / 超时：驱动层选 `default`，**不**阻塞死。结果进 `Run.memory`，`cont` 闭包带上绑定。

### 4.5 Cancel / Instead

| 卡面 | `Eff` |
|---|---|
| Cancel … | `Nest seq.interrupt.cancel` + `InterruptTarget` |
| Ignore … | `Nest seq.interrupt.ignore` + target |
| Instead … | `Nest seq.replace.instead` + `ReplacementTarget` + `replacement: Eff` |

子手续对 **目标帧** 的 `cancelled` / 替换 `cont` 做纯更新（在 `Run.stack` 上），**不是**对 `World` 做 lens。

遭遇显现被 Cancel：**仍**跑父抽牌的 G4 discard（[07 §6.0.1](07-effect-resolution.md)）——由父 `Flow.body` 结构保证，不靠 Cancel 删掉父帧。

### 4.6 ST.7

成败后果挂在检定 `Flow` 的 ST.7 砖：**内联** `Eff`（`SkillTestSt7Plan`），**禁止** nest 新时点假装 success 窗。  
`If success` 是 `If Pred`，不是 `Nest`。

---

## 5. 谓词 `Pred`

```text
Pred = World × Env → Bool   -- 纯；可读 Catalog

典型：
  previous_step_created / not_created
  has_keyword / in_play / engaged
  test_success / fail_by ≥ n
  memory_bound(key)
```

`If` 的 `evaluate: after_step` 等（12160）= 解释器在 `Seq` 左支 commit 后，把 CREATED 痕迹放进 `Env`/`Run.memory` 再求 `Pred`。

---

## 6. 与现 Composition / seq 对照

| 现（07 / Catalog） | `Eff` |
|---|---|
| `CompositionNode` Seq / Then | `Seq` |
| Simultaneous | `Par` |
| If / if_else | `If Pred` |
| Atom / L0 | `Do Intent`（物理） |
| Register 节点 | `Do RegInsert` 或按 §4.0.5 `Nest seq.effect.register` |
| Choice / Optional | `Ask` |
| Interrupt / Replace | `Nest seq.interrupt.*` / `seq.replace.instead` |
| nest `flow_id` 模板 | `Nest FlowId Env` |
| 命名手续 handler 顺序砖 | `Flow.body` = `Seq`/`Nest`/… |
| 真空 `execute` | **禁止**；必有 `Run.stack` 帧 |
| `seq.card…` | **禁止** |

**迁移策略**：编译器继续产出 JSON 树 → 解码为 `Eff`；Catalog `register_run` 体改为 `Flow`；Godot 解释器可先 **适配层**（`Eff` → 现 Executor），再逐步收拢。

---

## 7. 等式与简化（可选推理）

实现不强制，但方便测试与优化：

```text
Seq(Pass, e)      ≡ e
Seq(e, Pass)      ≡ e
Seq(Seq(a,b), c)  ≡ Seq(a, Seq(b,c))
Par(Pass, e)      ≡ e          -- 若规范允许
If(True, t, _)    ≡ t
If(False, _, e)   ≡ e
Seq(Empty, e)     ≡ e          -- 结算后；发起 L7 单独论 Empty
```

**不**等式：`Nest` 与内联展开（时点可观察）——**不可**随便 η 变形掉 `Nest`。

---

## 8. 锚例（ Eff 形 ）

### 8.1 事件：「Draw 1. Then take 1 horror.」

```text
Seq(
  Nest seq.draw.investigator { amount=1, … },
  Nest seq.effect.deal { horror=1, … }          -- 卡面叶：Nest（26）
)
-- 跑在 PLAY_CARD resolve 帧内；禁止真空
```

### 8.2 12160 显现

```text
Seq(
  Nest-or-inline place_doom_nearest…,           -- 含 Ask 选目标若需要
  If (not previous_created)
     (Nest seq.effect.register surge_template)
     Pass
)
-- 装载于 Flow seq.encounter.revelation 的 body 片段
```

### 8.3 Daring on_commit / after_test_ends

```text
-- on_commit（投入时）：Nest seq.effect.register (KEYWORD retaliate+alert, THIS_SKILL_TEST)
-- after_test_ends：Register LISTENER @ skill_test_ends → body = Nest seq.effect.draw
-- 提前 uncommit：卸后者 lifetime；保留 THIS_SKILL_TEST（World.registrations）
```

此处「投入能力」装载点在 commit 手续帧；**不是**新的 `seq.card.06111`。

### 8.4 Ward Cancel revelation

```text
Nest seq.interrupt.cancel { target = revelation_frame }
-- 父 seq.draw.encounter 的 G4 仍在父 body 后续
```

---

## 9. 非 `Eff` 的东西（边界）

| 概念 | 放哪 |
|---|---|
| hook `(sequence_id, slot)` | Ability 装载元数据，不是 Eff 节点 |
| 费用 costs | Initiation 管线；过门后再跑效果 `Eff` |
| Prey / Spawn Spec | RuleParameter（Catalog 印刷）；Resolver 读，不 execute |
| Framework 步推进 | Driver + Framework 状态机；步内可 `Nest`/`run` Flow |
| UI / 超时时钟 | Driver；只把 Answer 喂回 `Ask` |

---

## 10. 裁决摘要

| # | 裁决 |
|---|---|
| F1 | `Eff` 统一卡面与手续体；`Flow = 信封 + Eff` |
| F2 | 构造子：`Do`/`Empty`/`Pass`/`Seq`/`Par`/`If`/`Nest`/`Ask`/`ForEach` |
| F3 | 三分法 = `Seq·Do` / `Nest` / `Ask` 硬映射 |
| F4 | 时点不进 Eff 节点；在 `Flow` / 帧相位 |
| F5 | Cancel/Instead = `Nest` 共享手续 + 改 `Run` 目标帧 |
| F6 | ST.7 后果 = 内联 `Eff`，不 nest 成败窗 |
| F7 | `Empty` 计发起 CREATED；`Pass` 不计 |
| F8 | 先解码适配现 Executor，再替换实现 |

---

## 11. 下一步

1. ~~**种类表**~~ → [26-eff-kind-table](26-eff-kind-table.md)（卡面叶默认 **Nest**；内联仅 handler/管线/ST.7 外壳）。  
2. **JSON ↔ Eff** 编解码（复用 `compiled_abilities` / template；按 26 强制 Nest）。  
3. **金样**：`plan` dry-run + `Ask` default + Cancel 保 G4（纯函数测，可先假 World）。  
4. Godot 适配：`CompositionExecutor` 包一层 `Eff` 解释，不一次铲掉。

---

## 12. 变更记录

| 日期 | 摘要 |
|---|---|
| 2026-11-23 | v0.1：语法、三分法映射、Flow 信封、plan/commit、对照 07/15/16、锚例 |
