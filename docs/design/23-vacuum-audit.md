# 23 — 禁真空抽查（I2）

> **依赖**：[17 I2](17-seq-runtime.md)、[07 §1.0 DoD](07-composition.md)、[19 §3.1](19-core-2026-translation-roadmap.md)  
> **日期**：2026-10-13  
> **范围**：生产路径（非 test harness）；对照「Composition 只能在已压栈 `seq.*` RESOLVE 内 `execute`」

---

## 1. 结论（一句话）

`GameBootstrap` 主路径（Initiation / Forced / LISTENER / act-agenda 背文）经 **`CompositionMount` → `seq.ability.resolve`**，**无活跃真空 execute**。剩余是 **无栈守卫的 API + Catalog 缺失回退 + `run_mutator_only`**，属结构性债，不是「翻译未做完」。

| 档 | 数量（量级） | 含义 |
|---|---|---|
| **OK** | 主路径齐全 | Mount / Catalog / ST.7 / 抽牌 catalog.run |
| **SUSPECT** | ~6 处回退 | Catalog 缺失时裸 `execute` / 直写 `RegistrationStore` |
| **VACUUM（潜伏）** | `run_mutator_only` 等 | 无 `sequences`/`catalog` 的旁路；全量 bootstrap 下默认不走 |

---

## 2. 生产 `composition.execute` 位点

| 位点 | 栈上下文 | 判定 | 说明 |
|---|---|---|---|
| `sequence_catalog_bootstrap` · `seq.ability.resolve` handler | Catalog RUN 已压栈 | **OK** | 装载帧正典 |
| `skill_test_st7_composition`（success/fail/fail-by） | `seq.skill_test` 未 pop | **OK** | ST.7 内联（设计允许） |
| `draw_investigator_flow` reveal/enter_hand batch | 主路径：`seq.draw.investigator` | **OK** | 经 `DrawInvestigatorService` → catalog |
| `draw_subflow_handlers` shuffle+horror | 同上 | **OK** | D1 内联 Composition |
| `card_ability_service.resolve_revelations` | 依赖调用方已压栈 | **SUSPECT** | 无 `depth()` 断言；`sequences==null` 时真空 |
| `composition_mount.resolve_ability` 回退 | Catalog 无 `seq.ability.resolve` | **SUSPECT** | 裸 execute |
| `ability_initiation_pipeline` Mount 失败后再 execute | 同上 | **SUSPECT** | 双保险回退 |
| `triggered_ability_service` Mount 失败后再 execute | 同上 | **SUSPECT** | 同上 |

**潜伏真空 API**

| API | 判定 | 说明 |
|---|---|---|
| `DrawInvestigatorFlow.run_mutator_only` | **VACUUM** | 自造无栈 `GameContext`，再走 `_run_core` → execute；Composition atom `draw` / ActionSystem 未绑服务时可达 |

---

## 3. Register / 局面写入旁路

| 路径 | 判定 | 说明 |
|---|---|---|
| `EffectFlowHandlers.register_buff` | **OK** | `seq.effect.register` 本体 |
| `CompositionExecutor._register_via_effect_seq` 回退 | **SUSPECT** | nest 失败 → 直 `registrations.register` |
| `CompositionMount.register_effect` 回退 | **SUSPECT** | 同上 |
| Initiation `SKIP_AOO` / Engagement / gained-keyword Catalog 缺失回退 | **SUSPECT** | 优先 nest/run；失败直写 Store |
| L0 Atom via `StateMutator` | **OK iff** 父 `execute` 已在栈上 | `execute()` 本身无栈守卫 |

`on_custom_effect`：**生产 GDScript 中无实现**（与 12 禁令一致）。

---

## 4. 糖残留（非真空，但与「应展尽展」相关）

| 项 | 状态 |
|---|---|
| `engage_from_connecting` / 编译期 `nest_move_connecting` 展开 | ✅ 工厂/编译已展 |
| Executor 遗留 `&"nest_move_connecting"` atom | 糖残留（原始 ATOM 仍可一步跑 PI+move） |
| `CompositionNode.draw` L2 叶 | 糖；编译侧已用 `nest_draw_investigator` |
| `spend_clues_group` / 场景宏（defeat_surviving… 等） | 多步单 Atom；场景侧可后收 |

---

## 5. 已合规、勿拆的模式

- `CompositionMount.resolve_ability` / `register_effect`：**先 nest 再解释**
- Catalog `seq.ability.resolve` 作为 Initiation / Forced / LISTENER / act-back 装载帧
- ST.7 在 `seq.skill_test` 帧内 inline execute（禁止 pop 后父 Seq 再跑后果）
- Buff 创建优先 `seq.effect.register`
- 编译器：`draw` → `nest_draw_investigator`；连结移动/接战应展尽展

---

## 6. 建议修复顺序（下一刀）

1. ~~**`CompositionExecutor.execute` 硬门槛**~~：**已落地** — `depth() > 0` 否则 `push_error` 并返回 false（I2-01）  
2. ~~**删除 Mount / Initiation / Triggered 裸 execute 回退**~~：**已落地** — Catalog 缺失 = 错误；Register / Engagement / gained-keyword / SKIP_AOO 同理  
3. ~~**隔离 `run_mutator_only`**~~：**已落地** — 仅 dry-run/sim；生产 draw atom / ActionSystem 禁 mutator 旁路  
4. ~~**`CardAbilityService.resolve_revelations`**~~：**已落地** — 断言已压栈  
5. ~~**清糖残留**~~：**已落地** — executor 拒 `nest_move_connecting` ATOM；`CompositionNode.draw` → `nest_draw_investigator`；测试 helper 经 Mount

---

## 7. 变更记录

| 日期 | 说明 |
|---|---|
| 2026-10-13 | 首轮抽查：主路径 OK；回退 + `run_mutator_only` 为结构性债 |
| 2026-10-13 | §6 五项落地：execute 守卫、删回退、隔离 mutator 抽牌、revelations 断言、清糖 |
