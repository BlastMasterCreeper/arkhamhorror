# 07b — 效果组合 Composition 规格

> **依赖**：[07-effect-primitives.md](07-effect-primitives.md), [06-registration-buff-model.md](06-registration-buff-model.md)  
> **被依赖**：[06-ability-initiation.md](06-ability-initiation.md)（dry-run）、LISTENER Buff  
> **状态**：v0.3 · 2026-06-18

---

## 1. 目标

定义 **效果组合（Composition）**：可执行的组合树，连接卡面文本、Initiation resolve 与 **效果**（**状态原语** L0 Atom + **Register**）。

**英文（代码）**：`Composition` / `CompositionNode` / `CompositionExecutor` / `CompositionDryRunner`  
**中文（文档）**：效果组合 / 组合节点

**揭示（Reveal）卡牌** 经 L0 **`AtomRevealCard`** 写入 Domain，**参与** §4 dry-run **CREATED** — 见 [07-effect-primitives §5.3](07-effect-primitives.md)、[01 §3.6](01-game-state-zones.md)。

---

## 2. 游戏结算的两类「直接影响」（= 效果）

几乎 **全部卡面效果 resolve** 对局面/规则的 **可 CREATED 写入** 只做两件事之一：

| 类型 | 改什么 | 组合节点 | 是否效果 |
|---|---|---|---|
| **状态变更** | `GameStateStore` | L0 **Atom**（**状态原语** 三类；含 **Reveal**） | **是** |
| **规则变更** | `RegistrationStore`（Buff） | L2 **Register** / **Unregister** | **是** |

Grimoire **Reveal 卡牌** = L0 **`reveal_to_*`**（③ 揭示状态），**不是** Register 之外的第三类机制；命名流程 D2/E2 的 reveal 步 **是效果施加**。

Cancel / Replacement、Draw、DealDamage 等 **不是** 第四类 CREATED 机制：前者是 L2 组合节点；后者是 **命名流程 / L3 宏** 展开。

---

## 3. 组合节点分层

```mermaid
flowchart TB
    subgraph L3 [L3 语义宏 — 编译期 / Builder API]
        Macro[Draw / Discover / DealDamage / ...]
    end
    subgraph L2 [L2 规则节点]
        Reg[Register / Unregister]
        Pend[Interrupt / Replace / ResolvePending]
    end
    subgraph L1 [L1 控制流]
        Seq[Seq / Then]
        Sim[Simultaneous]
        Loop[ForEach / Choice / Optional / If]
    end
    subgraph L0 [L0 状态节点]
        Atom[AtomMoveCard / Transfer / SetFlag / SetRef]
    end
    Macro --> L1
    L2 --> L1
    L1 --> L0
    L1 --> L2
```

### 3.1 Runtime 节点 kind（v1）

| 层 | kind | 说明 |
|---|---|---|
| L0 | `Atom` | [07-effect-primitives §5](07-effect-primitives.md) **三类状态原语** |
| L2 | `Register` | 插入 `Registration` |
| L2 | `Unregister` | 移除 Registration |
| L2 | `Interrupt` | 统一 Cancel / Ignore（nest `seq.interrupt.*` 或 `CompositionNode.interrupt_*`） |
| L2 | `Replace` | 统一 Instead（nest `seq.replace.instead` 或 `CompositionNode.replace_instead`） |
| L2 | `ResolvePending` | 窗口结束后 resolve pending |
| L1 | `Seq` | 顺序；Grimoire **Then** = 标记的 Seq |
| L1 | `Simultaneous` | 同时组；组 commit 后才 flush after |
| L1 | `ForEach` | 枚举目标 |
| L1 | `Choice` / `Optional` | 玩家选择 — **`PlayerInteractionGate`**（[16](16-player-interaction.md)） |
| L1 | `If` | 条件分支 |

**L3 宏不进入 serialized tree**；`CompositionBuilder` 在编译期或调用时展开。

### 3.2 RegisterNode

```gdscript
class RegisterNode extends CompositionNode:
    var template: RegistrationTemplate   # lifetime + scope + buffs[]
```

创建 **持续 / 延时 / 进场能力** 均为此节点；差别在 `LifetimeSpec`（见 [06-registration-buff-model §6](06-registration-buff-model.md)）。

---

## 4. 合法性 Dry-run（CompositionDryRunner）

> 完整 Initiation 流程见 [06 §7.2](06-ability-initiation.md)。Eligibility L7 终端 dry_run；COLLECT 不批量 dry_run。

### 4.1 原则（已裁决）

**有效性检测只关注「效果是否被创建」这一直接影响。**

- **Register**：`RegistrationStore` 中 **成功插入一条 Registration** → 该节点 **CREATED**（**Buff 写入是效果**）
- **Atom**（含 **`reveal_to_*`**、SetFlag/SetRef）：`StateMutator` 在 fork 上 **执行成功** → **CREATED**（**状态原语**）
- **Interrupt / Replace / ResolvePending**：pending 存在且操作成功 → **CREATED**

**Presentation** 只 **读** Domain 揭示状态渲染 UI；**不** 单独维护「谁看到了什么」。

**创建之后** Buff 是否退化、Listener 将来能否触发、MODIFIER 是否用到、牌堆是否会在未来变空 — **一律不查**。

### 4.2 发起合法条件

```text
initiation 合法  ⟺  play restrictions 过
                AND  cost 可付
                AND  simulate(composition).has_any_created == true
```

```gdscript
enum DryRunOutcome { CREATED, FIZZLE }

class CompositionDryRunner:
    func simulate(node: CompositionNode, sim: GameSimulator) -> DryRunResult:
        match node.kind:
            Atom:
                return CREATED if sim.apply_atom(node) else FIZZLE
            Register:
                return CREATED if sim.register(node.template) else FIZZLE
            Seq:
                var any := false
                for c in node.children:
                    any = any or simulate(c, sim).has_any_created
                return DryRunResult.new(has_any_created = any)
            Choice:
                return DryRunResult.new(
                    has_any_created = any(simulate(opt, sim).has_any_created for opt in node.options)
                )
            ...
```

### 4.3 Fork 范围

`GameSimulator.fork()` 必须包含：

- `GameStateStore`
- **`RegistrationStore`**
- （若测 Cancel）`PendingResolution` 队列

### 4.4 Dry-run vs 真实结算

| | 合法性 dry-run | 真实 resolve |
|---|---|---|
| **Seq / Then** | 子节点 **OR**：任一段 CREATED 即可发起 | **顺序**执行；Then 前段须 resolve 才进后段（Grimoire Then） |
| **Register** | 插入即 CREATED | 同左 |
| **Choice** | 任可选分支 CREATED | 玩家选一支执行 |

### 4.5 示例

| 卡面 | dry-run |
|---|---|
| Until end of your turn, after you fight, draw 1 | **Register CREATED** → 合法（即使本回合不 fight） |
| Draw 1（仅一段，牌堆空） | Atom FIZZLE → 非法 |
| Draw 1 + Register（上例） | Register CREATED → **合法** |
| Heal 2（无受伤目标，且无 Register） | Atom FIZZLE → 非法 |

---

## 5. CompositionExecutor

```gdscript
class CompositionExecutor:
    func execute(node: CompositionNode, ctx: ApplicationContext) -> void
```

- L0 → `StateMutator`
- Register → `RegistrationStore.register`
- Listener Buff 内嵌的 composition 由 `TimingBus` 回调同一 Executor
- 每步写 `EventRecord`（`composition_step` / `atom` / `register`）

---

## 6. 与 Initiation 的关系

```
Initiation Pre  →  RestrictionEvaluator + CompositionDryRunner
Initiation 4    →  CompositionExecutor.execute(intent.composition)
Listener 触发   →  CompositionExecutor.execute(listener.composition)
```

---

## 7. 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-06-18 | v0.3 | **AtomRevealCard** 参与 CREATED；撤销 Information 非效果 |
| 2026-06-18 | v0.2 | §2 效果仅 Atom+Register；§4.1 dry-run 原则 |
| 2026-05-25 | v0.1 | 初稿：分层、dry-run 仅关注创建、Register 合法 |
