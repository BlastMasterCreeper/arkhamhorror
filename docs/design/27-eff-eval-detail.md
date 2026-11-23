# 27 — `Eff` 求值细则（信封 · Ask 分型 · Forced/响应池）

> **状态**：设计草案 v0.1 · 2026-11-23  
> **依赖**：[25-functional-eff](25-functional-eff.md)、[26-eff-kind-table](26-eff-kind-table.md)、[24-functional-world](24-functional-world.md)、[16-player-interaction](16-player-interaction.md)、[15 §4.0.5](15-timing-entry-catalog.md)、[17-seq-runtime](17-seq-runtime.md)  
> **目的**：把此前偏粗的「`step` + Nest 压栈」拆成 **可手算的分层函数**；纠正「Forced 无 Ask」；把时点响应做成与卡面选择 **同一 `Ask` 代数、不同 `AskKind`**。  
> **总纲**：[28-functional-scheme](28-functional-scheme.md)。本文 WhenForced→WhenPool **过平**，已由 28 §4 Agenda（类别整批、显现独立、遭遇抽牌专用议程）修订；Forced 排序 Ask 仍有效。

---

## 0. 先前过粗之处（本文件要补上的）

| 过粗说法 | 细化 |
|---|---|
| `step(World, Run, Eff) → Outcome` 一层搞定 | 拆成 **信封驱动** / **树解释** / **池回路** 三层函数，共用 `Outcome` |
| `Nest` = 压栈后立刻跑 body | 压栈后先走 **EnvelopeFSM**；**Resolve 才** `interpret(body)` |
| Forced 无 Ask | Forced **不能拒绝发动**；**同批排序**仍 `Ask(ORDER_FORCED)`；效果体内仍可 `Ask` |
| 时点响应 = 再来一个 Ask 就完 | 对齐 16：**Forced 批** → **粘性 ResponsePool 回路**（多次 `Ask`，每次放行 1 条） |
| `resume` 随便接 | `resume` 必须说明 **回到哪一层**（信封相位 / 池 loop / 父 Seq） |

---

## 1. 值：求值上下文（比 Run 更细）

```text
EvalCtx = {
  world: World,
  run: Run,                    -- stack / memory / skill_tests
  envelope: EnvelopeState | None,  -- 栈顶帧的相位机（可内嵌在 Frame 上）
  pool: PoolState | None,      -- 当前时点窗的 Forced 批或 ResponsePool
}

Frame = {
  flow_id, env,
  phase: EnvelopePhase,        -- 见 §2
  body: Eff,                   -- Catalog[flow].body；Resolve 才解释
  cont_after: Eff,             -- 本帧 Done 后父侧续体（Seq 右支等）
  cancelled: Bool,
  created_trace: CreatedTrace  -- 供 If(previous_created) 等
}

EnvelopePhase =
  Enter
  | WouldCollect | WouldAsk | WouldRun
  | Impact        -- 若 SPLIT：Would 与 When 之间的内联发起 impact（抽牌等）
  | WhenForced    -- Forced 批（§4）
  | WhenPool      -- 可选响应粘性池（§5）
  | ResolveBody   -- ★ 进入函数体 interpret(body)
  | AfterForced | AfterPool
  | Exit
```

`Outcome` 仍是：

```text
Outcome =
  | Next     { ctx: EvalCtx }                 -- 纯推进（换 phase / 换 cont）
  | NeedAsk  { ctx, req: ChoiceRequest, resume: Answer → EvalCtx }
  | Halt     { ctx, reason }                  -- 少见
```

驱动层唯一杂质：解 `NeedAsk`（超时 → `default_*`）再 `resume`。

---

## 2. 信封驱动函数（Nest 之后、body 之前）

```text
nestEnter(ctx, flowId, env, cont_after) → Outcome
  frame = Frame{ flow_id, env, phase: Enter, body: Catalog[flowId].body,
                 cont_after, cancelled: false, created_trace: ∅ }
  ctx' = push(ctx, frame)
  return advanceEnvelope(ctx')
```

```text
advanceEnvelope(ctx) → Outcome
  match top.phase:
    Enter        → setPhase(WouldCollect)  |> advanceEnvelope
    WouldCollect → collectWould(ctx)       -- 纯查询替换/Cancel 候选
                 → if 需选序/选哪个 Instead: NeedAsk(ORDER_OR_PICK_WOULD, resume→WouldRun)
                 → else WouldRun
    WouldRun     → 按序跑替换/Cancel 的 Eff（可再 nestEnter）
                 → 若 cancelled: phase:=Exit
                 → 否则 → Impact 或 WhenForced（按 Flow 政策 / SPLIT）
    Impact       → interpret 内联 impact 砖（Do…）；非 body 全文
                 → WhenForced
    WhenForced   → runForcedBatch(ctx, slot=WHEN)   -- §4
    WhenPool     → runResponsePool(ctx, slot=WHEN) -- §5
    ResolveBody  → interpret(ctx, top.body)         -- §3 ★ 进函数体
                 → 完成后 AfterForced
    AfterForced  → runForcedBatch(ctx, slot=AFTER)
    AfterPool    → runResponsePool(ctx, slot=AFTER)
    Exit         → pop；把 cont_after 交回父 interpret
```

**进函数体的唯一点**：`phase = ResolveBody` 时调用 `interpret`。  
Would/When/After 的 Ask 与 Nest **可以发生在 body 之外**。

---

## 3. 树解释函数 `interpret`

```text
interpret(ctx, eff) → Outcome
  match eff:
    Do i →
      w' = commit(ctx.world, [i])
      trace' = trace ∪ created?(i)
      return Next{ ctx with world=w', created_trace=trace' }

    Seq(a,b) →
      o = interpret(ctx, a)
      return bindOutcome(o, ctx2 → interpret(ctx2, b))

    Nest(fid, env) →
      return nestEnter(ctx, fid, env, cont_after=Pass)
      -- 父 Seq 的 b 通过 Frame.cont_after / bindOutcome 接上，不插进子 body

    Ask(spec, k) →
      cands = eligibility(ctx.world, ctx.run, spec)
      req = ChoiceRequest{ kind: spec.ask_kind, cands, default_* }
      return NeedAsk{ ctx, req, resume: λ ans.
        run' = bindAnswer(ctx.run, spec, ans)
        interpret(ctx with run=run', k(ans)) }

    If(p,t,e) →
      interpret(ctx, p(ctx.world, ctx.run) ? t : e)

    Empty → Next{ ctx }  -- 发起侧另计 CREATED
    Pass  → Next{ ctx }
```

`bindOutcome`：若 `o` 为 `NeedAsk`，把「后续 `b`」塞进 `resume`（Kleisli）；若子 `Nest` 尚未 Exit，父 `b` 在 `cont_after`。

---

## 4. Ask 分型（同一构造子，不同 `AskKind`）

| `AskKind` | 谁问 | 能否 decline | default 典型 | 出现相位 |
|---|---|---|---|---|
| `ORDER_FORCED` | 队长（或规则指定） | **否**（必须给出全序） | COLLECT 稳定序 / AutoChoice | WhenForced / AfterForced |
| `PICK_RESPONSE` | 队长从**池中**放行 1 条 | 可「池暂空等」但默认常 auto | AutoChoice / 队首选 | WhenPool / AfterPool |
| `JOIN_POOL` | 各控制者：是否把本能力加入响应池 | 是（不加入） | 响应模式偏好 / 不加入 | Pool COLLECT |
| `WITHDRAW_POOL` | 控制者撤已入池未锁条目 | 是 | 不撤 | Pool |
| `PICK_TARGET` / `PICK_OPTION` | 效果或 Initiation 内 | 视 must/may | default_index / 合法 head | ResolveBody 内 / 能力体 |
| `OPTIONAL_EFFECT` | may 子效果 | **是**（跳过） | 跳过 | body 内 |
| `ORDER_WOULD` / `PICK_INSTEAD` | 竞争替换 | 否或规则定 | tier / 队长 | Would* |

**Forced 与 Ask**：

```text
Forced ⇒ 不进 ResponsePool；不可 Ask「跳过发动」
Forced ⇒ 仍可 Ask(ORDER_FORCED) 当 |batch|≥2
Forced.effect ⇒ 仍可 Ask(PICK_TARGET) 等
```

---

## 5. Forced 批 = 函数 `runForcedBatch`

对齐 16 §7.1.1「Forced 不进池；≥2 条队长选序」。

```text
runForcedBatch(ctx, slot) → Outcome
  batch = collectForced(ctx.world, ctx.run, top.flow_id, slot)  -- 纯；过 L4
  if batch = ∅:
    return Next{ setPhase(nextAfterForced(slot)) }  -- WHEN→WhenPool 或 AFTER→Exit 路径

  if |batch| = 1:
    return fireForced(ctx, batch[0], rest=[], slot)

  return NeedAsk{
    req: { kind: ORDER_FORCED, items: batch, default: stableOrder(batch) },
    resume: λ order. fireForcedChain(ctx, order, slot)
  }

fireForcedChain(ctx, [a,...rest], slot) → Outcome
  -- 不可 decline；逐个：
  o = initiateForced(ctx, a)   -- L6–L7；产物是装载到栈上的 Eff（常 nestEnter 子能力）
  return bindOutcome(o, ctx2 →
    if rest=∅ then Next{ setPhase(nextAfterForced(slot)) }
    else fireForcedChain(ctx2, rest, slot))
```

`initiateForced`：**没有** `OPTIONAL` 的「不发动」分支；失败仅限合法性/L7 fizzle（按外层规则）。

---

## 6. 粘性响应池 = 函数 `runResponsePool`

对齐 16 §7.1 回路（**每次放行 1 条**；nest 后可再 COLLECT）。

```text
PoolState = {
  slot,
  members: [ResponseEntry],     -- 已入池未结算
  resolved: Set AbilityKey,     -- 本窗已结算
  locked: ResponseEntry | None  -- 放行中
}

runResponsePool(ctx, slot) → Outcome
  ctx1 = ensurePool(ctx, slot)
  -- 1) COLLECT 潜在可选
  pot = collectOptional(ctx1.world, ctx1.run, slot) \ pool.resolved \ alreadyInPool
  -- 2) 对各控制者 JOIN（可合并为一次多主体 Ask，或按偏好 auto）
  return askJoinThen(ctx1, pot, λ ctx2 →
    if pool.members=∅ ∧ noNewJoins:
      return Next{ setPhase(nextAfterPool(slot)); clearPool }
    -- 3) 队长放行 1 条
    return NeedAsk{
      req: { kind: PICK_RESPONSE, cands: pool.members, default: autoHead },
      resume: λ pick.
        ctx3 = lock(ctx2, pick)
        o = initiateOptional(ctx3, pick)   -- nest 能力 Eff
        bindOutcome(o, ctx4 →
          ctx5 = unlockAndResolveMark(ctx4, pick)
          -- 4) nest 返回：出池非法者；再 runResponsePool（递归）
          runResponsePool(ctx5, slot))
    })
```

要点：

- **不是**一次 `ORDER_SIMULTANEOUS` 锁死总序（16 已废）。  
- 函数式表现 = **尾递归**的 `runResponsePool`，中间夹多次 `NeedAsk`。  
- 每次 `initiateOptional` 可再 `nestEnter`，子信封跑完再回到池函数。

---

## 7. 「何时进函数体 / 何时运算」——嵌套 + 响应版

以 `Nest(deal)` 且 When 上有 2 条 Forced + 可选反应为例：

```text
时刻                         进谁的 body？          commit？        Ask？
───────────────────────────  ───────────────────  ─────────────  ────────────────
nestEnter(deal)              否                    否              否
Would*                       否（或进替换手续 body） 视替换           或 ORDER/PICK
WhenForced COLLECT           否                    否              否
\|batch|≥2                   否                    否              ORDER_FORCED
fire Forced₁.effect          是（能力 Eff / 常再 Nest） 是（其 Do）    能力体内可有
fire Forced₂ …               同上
WhenPool loop                否                    否              JOIN / PICK_RESPONSE
放行反应 → nest 能力          是（反应 effect）       是              …
ResolveBody(deal)            ★ deal.body           是（伤害 Do）     body 内可有
AfterForced / AfterPool      同 When 结构           视能力           同 Ask 分型
Exit pop → 父 cont_after     父树                   视父            …
```

**父 `Seq` 的右支**只在 deal **Exit 之后**进入——不会夹在 Forced 与 ResolveBody 之间执行。

---

## 8. 手算片段（Forced 排序 + 进 body）

```text
World 略
栈顶：Nest(deal) 已 push，phase 刚到 WhenForced
batch = [F_A, F_B]   -- 同优先 Forced

① advanceEnvelope → runForcedBatch
   → NeedAsk{ kind: ORDER_FORCED, cands:[F_A,F_B], default:[F_A,F_B] }

② 队长答 [F_B, F_A]
   resume → fireForcedChain(F_B, then F_A)

③ F_B.effect = Nest(seq.effect.gain_resource, {n:1})
   nestEnter(gain_resource) … ResolveBody → Do … commit
   World 资源 +1；pop gain_resource

④ F_A.effect = Ask(PICK_TARGET, λ t. Nest(deal, {horror:1,t}))
   → NeedAsk 目标；答后 Nest 子 deal…（又一层信封）
   全部 Exit 后回到 fireForcedChain 结束

⑤ phase := WhenPool → …（若无可选，直接 ResolveBody）

⑥ ResolveBody：interpret(deal.body) → Do damage → commit
⑦ After* … Exit → 父 cont_after
```

每一步的 **返回** 不是「神秘回调」，而是：`Next`（更新后的 `EvalCtx`）或 `NeedAsk`（`resume: Answer → EvalCtx`）。

---

## 9. 与 Initiation / 装载

```text
initiate*(ctx, ability) → Outcome
  -- L6 费用等（可含 Ask）；L7 dry-run plan(effect)
  -- 通过后：在「已有栈帧」上 interpret(effectEff)
  --   或 §4.0.5 为是时 nestEnter(子手续)
  -- Forced：跳过「是否发动」Ask；Optional：可能先 Ask(PICK_RESPONSE)/偏好
```

能力 **effect** 仍是 `Eff`；Initiation 是 **进 interpret 之前的门函数**，不是第二套效果代数。

---

## 10. 不变量（细则级）

| # | 不变量 |
|---|---|
| D1 | 唯 `Do`/`commit`（及框架 tick）改 `World`；`Ask` 只改 `Run.memory` / pool |
| D2 | `ResolveBody` 之前不解释 `Catalog[fid].body` |
| D3 | Forced 批失败模式不含「玩家拒绝发动」 |
| D4 | 响应池每次至多锁 1 条；nest 返回后才再 COLLECT |
| D5 | 父 `cont_after` 不插入子信封的 When/Resolve 之间 |
| D6 | 所有玩家决策 ∈ `AskKind` 表；禁止隐式 UI 副作用 |

---

## 11. 相对 25 的修订声明

- 25 §4「Forced 无选用」**作废**，以本文 §4–§5 为准。  
- 25 的 `step` 视为 **`advanceEnvelope` ∘ `interpret` ∘ 池函数** 的粗复合；实现/推理以本文分层为准。  
- 26 种类表（卡面叶 Nest）不变；本文补的是 **Nest 之后信封内** 的函数。

---

## 12. 下一步

1. 把 `AskKind` 与现 `ChoiceRequest` / 16 表逐字段对齐（实现名）。  
2. 金样：Forced 双条 ORDER → 再 ResolveBody（纯 Ctx 断言栈相位）。  
3. 金样：Pool 放行 1 条 → 子 Nest → 返回后再 JOIN。  

---

## 13. 变更记录

| 日期 | 摘要 |
|---|---|
| 2026-11-23 | v0.1：EvalCtx；信封 FSM；Ask 分型；Forced 批与粘性池函数；进 body 时机表；废「Forced 无 Ask」 |
