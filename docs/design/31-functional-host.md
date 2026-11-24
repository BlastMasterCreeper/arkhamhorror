# 31 — 函数核心语言选型与 Godot 对接

> **状态**：设计草案 v0.1 · 2026-11-24  
> **依赖**：[24-functional-world](24-functional-world.md)、[25-functional-eff](25-functional-eff.md)、[28-functional-scheme](28-functional-scheme.md)、[30-functional-primer](30-functional-primer.md)  
> **范围**：规则内核用哪门语言实现、怎样接到现有 Godot 宿主；**不**要求立刻删掉 GDScript 竖切。

---

## 0. 一句话

**规则内核用 Rust 写**（局面、效果树、提交、询问边界都是纯函数或代数数据类型）。  
**Godot 只做宿主**：表现、输入、有限期确认的时钟、资源加载。两边用一条窄桥交换「局面 + 进度」和「询问 / 答案」。

函数式编程约束的是**值与运算**，不是「必须用 Haskell」。Rust 能表达代数数据类型（algebraic data type）和不可变映射树；对 Godot 4 又有正式扩展接口。

---

## 1. 候选对比

| 语言 | 代数 / 不可变集合 | 与 Godot 对接 | 热路径 | 结论 |
|---|---|---|---|---|
| **Rust** | 枚举 = `Eff` / `Intent`；`im` / `rpds` = 树形字典 | **gdext** 同进程扩展；也可 C ABI | 无 GC，路径复制可控 | **首选** |
| OCaml | 原生代数与模式匹配最顺 | 几乎只能进程外或 C stub | GC，可调 | **备选**（更「古典 FP」时） |
| F# | ML 系，持久集合有库 | 经 Godot C# 间接 | CLR GC | 不优先（多一层 .NET） |
| Haskell | 最纯 | 基本只能进程外协议 | GC + 惰性难控 | 不优先 |
| GDScript | 弱 | 已在仓库内 | 字典浅拷贝键贵 | **宿主与过渡竖切**，不再当内核目标 |

不选「为了函数式而换掉 Godot 整棵树」：牌面资源、场景、输入循环仍适合留在 Godot。换的是 **Rules / Domain 的权威实现**。

---

## 2. 职责切分

```text
┌──────────────────────────────────────────────┐
│ Godot 宿主                                     │
│  场景树 · 输入 · Ask 计时 · 牌面/音频 · 联机壳   │
└────────────────────┬─────────────────────────┘
                     │ Bridge（同进程 gdext，或 MessagePack 管道）
┌────────────────────▼─────────────────────────┐
│ Rust 规则内核                                  │
│  World · Run · Eff · Catalog · Agenda · Machine │
│  commit / apply · step · dry-run · Trace       │
└──────────────────────────────────────────────┘
```

| 在 Rust | 在 Godot |
|---|---|
| `World` / `Run` 权威 | 只持有**当前快照句柄**或序列化副本，供 UI 读 |
| `Eff` 解释、`commit`、机器表 | 不裁定规则 |
| Catalog / 编译树装载 | 从 `res://` 读 JSON 字节交给内核 |
| `NeedAsk` 的候选与默认 | 画出候选、收玩家点选、超时回调 |
| Trace / 重放 | 可选：把 Trace 映到日志面板 |

**真空禁令不变**：Godot 脚本不得直接改 `World` 字段；只能调桥上的 `step` / `answer` / `run_flow`。

---

## 3. 桥上契约（对接面）

类型用 primer 里的名字；跨语言时序列化为 MessagePack 或 JSON（调试用 JSON，热路径用 MessagePack）。

```text
-- 推进一小步
step(world, run) →
    Next(world', run')
  | NeedAsk(world', run', request, ask_id)
  | Halt(reason)

-- 回答一次询问（有限期确认到期则宿主先填默认再调）
answer(world, run, ask_id, choice) →
    Next(...) | NeedAsk(...) | Halt(...)

-- 装载
load_catalog(bytes) → Result
boot_scenario(seed, seats) → (World, Run)

-- 只读投影（UI）
view(world, spec) → Answer
```

`Ask` 的时钟、默认解析器可以放在宿主：逾期时宿主构造「选了默认」再 `answer`。内核只看见答案值，不绑定 Godot 定时器。

### 3.1 同进程（默认）

```text
Godot ←gdext→ rustc 编译的 cdylib
  · World/Run 活在 Rust 堆，Godot 侧持 Handle(u64)
  · view / 调试导出时才序列化
  · 避免每步把整桌 JSON 来回拷
```

结构共享、分片字典或 HAMT 都在 Rust 内完成；桥只传句柄 + 小请求。

### 3.2 进程外（可选）

用于：独立规则回归、多语言实验、崩溃隔离。

```text
Godot/测试驱动 ──stdin/stdout 或 UDS──► arkham-rulesd
  帧：长度前缀 + MessagePack
```

语义与同进程相同；延迟更高，不作为实机热路径默认。

---

## 4. Rust 侧模块草图

```text
arkham_rules/
  world/       World, Card, Region, Registration, Chronicle…
  intent/      Intent, apply, commit（树形/分片 Map）
  eff/         Eff, interpret, plan
  catalog/     FlowId → agenda + body
  ask/         AskKind, Request, resume
  machine/     Framework, SkillTest, Chaos, Damage…
  bridge/      gdext 导出 + 序列化
  trace/       事件日志（重放）
```

`Eff` 与 primer 对齐：

```rust
enum Eff {
    Do(Intent),
    Empty,
    Pass,
    Seq(Box<Eff>, Box<Eff>),
    Par(Box<Eff>, Box<Eff>),
    If(PredId, Box<Eff>, Box<Eff>),
    Nest(FlowId, Env),
    Ask(AskSpec, ContId),
}
```

`commit` 唯一写 `World`；`Ask` 只改 `Run`（及机器状态里允许的游标）。

---

## 5. 数据与编译产物对接

现有仓库已有：

- `data/arkhamdb/imported/*.json`（含 `compiled_abilities`）
- 设计表 20 / 21 的 Composition 词汇

对接方式：

1. **短期**：Rust 读取同一套 imported JSON；Composition → `Eff` 的装载器在 Rust。
2. **中期**：Python / 现有 `tools/arkhamdb_abilities.py` 仍可出 JSON；权威解释只在 Rust。
3. **Godot 竖切测试**：逐步改为「boot 内核 → step 到断言点」，GDScript 只断言 `view` 结果。

印刷目录（技能值、生命上限）外置，不进 `World`——与 [30](30-functional-primer.md) 一致。

---

## 6. 迁移顺序（不一次砍光）

| 阶段 | 做啥 | 验收 |
|---|---|---|
| M0 | 本文 + 类型钉死 | 设计评审 |
| M1 | Rust：`World` + `commit` + 树/分片 Map；无 Godot | 纯测试：加标记、换区 |
| M2 | `Eff` 子集：`Do/Seq/If/Nest/Ask` + 一条抽牌议程 | 与现 headless 用例对拍 |
| M3 | gdext 句柄桥 + Godot 最小 `view` | 主场景能显示手牌张数 |
| M4 | 机器表：检定 ST.1–8、伤害分配、强制排序 | 06111 等竖切迁到内核 |
| M5 | GDScript 规则路径降为委托或删除 | 真空审计：无宿主直写 |

并行期允许 **双轨**：旧 GDScript 引擎继续跑未迁竖切；新内核只吃白名单手续。禁止两套同时写同一权威局面。

---

## 7. 为何不是「OCaml 内核 + Godot」作默认

OCaml 写 `Eff` 更短，但：

- 与 Godot 没有一等扩展；默认变成进程外协议，Ask 往返与调试成本高。
- 持久映射与代数都很强，却要把 Catalog、Trace、多机器长期养在第二运行时。

若团队更在意古典 FP 教学或形式化，允许 **OCaml 参考实现** 与 Rust **对拍同一套 fixture**；产品路径仍以 Rust + gdext 为准。

---

## 8. 裁决

| # | 裁决 |
|---|---|
| H1 | **规则内核语言 = Rust**；Godot = 宿主与表现 |
| H2 | **对接默认 = gdext 同进程句柄**；序列化用于存档、调试、进程外测试 |
| H3 | **桥契约 = `step` / `answer` / `view` / `load_*`**；宿主不 `commit` |
| H4 | **不可变集合在 Rust 内实现**（分片或 HAMT）；不依赖 Godot `Dictionary` 语义 |
| H5 | **现有 imported JSON / Composition 词汇继续用**；装载进 Rust Catalog |
| H6 | **迁移分阶段双轨**；权威局面不可双写 |

---

## 9. 修订

| 日期 | 说明 |
|---|---|
| 2026-11-24 | v0.1：Rust 首选、职责切分、桥契约、迁移序 |
