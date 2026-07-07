# 规则疑点汇总表 (Open Questions Master)

> **用途**：供资深玩家审阅并裁决；裁决结果将回填各子系统设计文档。  
> **版本**：v0.3 · 2026-05-25（OQ-00-06 ~ OQ-10-01 等已裁决）  
> **合计**：81 条（P0: 16 · P1: 43 · P2: 22）  
> **同步来源**：`00-architecture-overview.md` + `design/00`–`12` 各文档 Open Questions 节

---

## 如何使用

1. 优先回复 **P0**（阻塞框架实现）。
2. 在「裁决」列填写你的结论；可引用 Grimoire 条目或 house rule。
3. 若需新增疑点，使用 `OQ-NEW-xx` 编号，并同步写入对应子文档。

| 列 | 说明 |
|---|---|
| ID | 全局唯一编号 |
| P | 优先级：P0 阻塞 / P1 大量卡牌 / P2 边缘 |
| 来源 | 设计文档 |
| 问题 | 待裁决内容（与子文档原文一致） |
| 裁决 | （留空供填写） |

---

## P0 — 阻塞框架实现（16 条）

| ID | 来源 | 问题 | 裁决 |
|---|---|---|---|
| OQ-00-06 | [00-architecture](00-architecture-overview.md) | 单进程 headless 规则服务器 vs 嵌入式 Godot Node：是否需支持无 UI 批量回归？ | **需要。** v1 即支持 headless；Rules/Domain 与 UI 解耦；CI 用 `godot --headless -s tests/run_headless.gd` + 固定 seed 回归。见架构 §5.5。 |
| OQ-01-02 | [01-state](design/01-game-state-zones.md) | 同名 Unique 遭遇与玩家卡同时进场 discard 的**精确同时性**：是否需要 `SimultaneousBatch` 原语？ | **需要通用「同时效果」语义，非 Unique 专用 hardcode。** 「同时」= 同一时点触发/开始结算；组内全部 resolve 完毕后，`after` 类触发才形成。适用于 Unique 冲突、「效果 A and 效果 B」等。引擎原语：`SimultaneousEffectGroup`。见 01 §5.3、07 §7.5。 |
| OQ-02-01 | [02-framework](design/02-framework-flow.md) | Setup step 9 回溯：除 step 8 外是否还可能回溯 6/7/10？需 campaign 数据驱动还是硬编码？ | **数据驱动 `rewind_to(step)`。** 卡牌效果/战役设置可影响 **6（混沌袋）、7（资源）、8（起手牌）** 并触发重入；**10（scenario setup）一般固定**，不作 intro 回溯默认路径。 |
| OQ-02-02 | [02-framework](design/02-framework-flow.md) | Act flip 期间 a 面 **Reaction** 能否响应 b 面结算中产生的事件？ | **不能。** Flip 后 a 面不在场，a 面一切能力不可触发（含 Reaction/Forced）。**例外**：a 面已创建的 **Delayed 延时效果**继续生效。Agenda 同则。见 02 §7。 |
| OQ-03-01 | [03-action](design/03-action-system.md) | Rulebook p.17 写 Fight「engaged enemy」，Grimoire Fight Action 允许同地点 unengaged — **以 Grimoire 为准是否确认**？ | **以 Grimoire 为准。** 基础 Fight 目标 = 调查员当前**地点**上的敌人（unengaged、自己 threat 区、同地点他人 engaged）。卡牌能力可扩展至地点外。见 03 §6.8。 |
| OQ-03-02 | [03-action](design/03-action-system.md) / [08-enemy](design/08-enemy-engagement.md) | AOO、Alert、Retaliate 是否统一为 `EnemyAttack` + `AttackKind`？ | **攻击效果层统一** `EnemyAttack` + `AttackKind`；**触发条件 + 时点 + 攻击效果** 三层结构，前两层各 kind 独立 Resolver，第三层共用 `perform_attack()`。均属 enemy attack。见 08 §6.1。 |
| OQ-04-01 | [04-skill-test](design/04-skill-test-engine.md) | 「Reveal another token」每次是否重新打开 ST.2 后 Player Window？ | **否。** Window 仅在 ST.2 commit 后及 ST.3–ST.4 **整链结束**后各一次。Reveal another **仅递归 ST.3→ST.4**，不回 ST.2，递归中 **无 Window**。 |
| OQ-04-02 | [04-skill-test](design/04-skill-test-engine.md) | 嵌套检定的 Peril 是否继承父 encounter？ | **是。** Peril 覆盖 encounter **整个结算帧**；嵌套检定 ST.8 后入队，仍在帧内 → 不可协助。见 04 §4.1、§5。 |
| OQ-04-03 | [04-skill-test](design/04-skill-test-engine.md) | Symbol 效果 ST.4 发起嵌套检定，父检定 ST.5 是否等待？ | **否。** 子检定入队；父检定 ST.5→ST.8 不等待；子检定父 ST.8 后执行。 |
| OQ-05-03 | [05-chaos-bag](design/05-chaos-bag.md) | Spreading Flames Skull「fail by 2+ draw Fire!」— fail by 在 ST.6 还是 ST.7 判定？ | **ST.7。** 作为失败效果的一部分结算；ST.6 仅判定 fail 并计算 `fail_by`。见 05 §5。 |
| OQ-06-01 | 多条 Replacement 同 triggering condition 冲突 | **最后 initiate**（`initiation_seq` 最大）。Grimoire *Instead*。见 07 §3.4、§7。 |
| OQ-REPL-01 | [07-effect](design/07-effect-resolution.md) | `initiation_seq` 与嵌套/would 改 condition 后的边界 | **v0**：COMMENCE 单调序号；would 改 condition 后原 condition 候选剔除。嵌套 initiate 见 §3.4。待卡牌用例补测。 |
| OQ-06-02 | [06-ability](design/06-ability-initiation.md) | Play restriction 是否需要 dry-run simulate？ | **需要。** L7 终端 dry-run；COLLECT 不批量 dry-run。见 06 §7.2。 |
| OQ-07-02 | [07-effect](design/07-effect-resolution.md) | Moving damage/horror 是否独立 `EffectOp.TRANSFER_AFFLICTION` 且不算 heal？ | **是。** 独立 `TRANSFER_AFFLICTION`；**不算 heal**。见 07 §4.1。 |
| OQ-07-06 | [07-effect](design/07-effect-resolution.md) | Replacement stack 与 Cancel 交互：cancel 已替换后的 effect 还是原始 trigger？ | **看触发先后。** Replacement 一般为 Delayed，与 Forced 同优先级。Replacement 先 → Cancel 无法发动；Cancel 先 → Replacement 不结算。见 07 §6.1。 |
| OQ-08-02 | [08-enemy](design/08-enemy-engagement.md) | Massive 攻击中途 exhaust：剩余攻击取消时点？ | **batch 发起时锁定序列**，尽量全部结算；**中途横置不取消**后续攻击。见 08 §6.3。 |
| OQ-10-01 | [10-scenario](design/10-scenario-encounter.md) | Setup surge：无 player window 时 nested surge 如何 UI？ | **场景不存在。** Setup 1–13 不结算显现 → 无 Surge 链。若有 setup 显现/涌动，仅在 **Setup 14 game begins** 结算。见 10 §2.1。 |
| OQ-12-01 | [12-api](design/12-card-script-api.md) | AbilityTemplate vs CardScript 目标比例？ | **不设固定比例**；实现时 **逐卡选型**，优先 Template。见 12 §1.1。 |

---

## P1 — 影响大量卡牌或 UX（43 条）

| ID | 来源 | 问题 | 裁决 |
|---|---|---|---|
| OQ-00-01 | [00-architecture](00-architecture-overview.md) | 电子版默认 `grim_rule_mode`？ | **`DISABLED`**；完备冲突栈；`AUTO_WORST` 仅 headless 显式配置。Grim = 实体查书兜底。见 00 §6。 |
| OQ-00-02 | [00-architecture](00-architecture-overview.md) | 多人 hot-seat vs 网络：Lead Investigator 裁定权是否仅本地主机持有？ | |
| OQ-00-04 | [00-architecture](00-architecture-overview.md) | 实现阶段是否迁移 addon，还是在 `arkhamhorror` 全新实现并仅参考 API 形状？ | |
| OQ-IDX-01 | [00-framework-step-index](design/00-framework-step-index.md) | ST.1–ST.8 是否注册为 `FrameworkStep` 子枚举还是独立 `SkillTestStep`？ | **独立 `SkillTestStep`**，`SkillTestEngine` 独占。见 IDX Skill Test 表。 |
| OQ-IDX-02 | [00-framework-step-index](design/00-framework-step-index.md) | Initiation 步骤是否写入 EventRecord 与 Framework 同级？ | **是**，完整可回放。见 06 §4、架构 §7.2。 |
| OQ-01-01 | [01-state](design/01-game-state-zones.md) | **隐私（Hidden）** 卡：Domain 标记还是仅 Presentation 隐藏？ | **Domain** `CardInstance.is_hidden` + **Presentation** 对非 owner 隐藏牌名。见 01 §3.6、15 §17.4.3。 |
| OQ-01-03 | [01-state](design/01-game-state-zones.md) | Committed skill：LIMBO 还是 Context？ | **`SkillTestContext.committed`**；zone 留 **HAND** 至 ST.8；不进 LIMBO。 |
| OQ-03-03 | [03-action](design/03-action-system.md) | Parley current agenda 是否同地点？ | **否。** Agenda **无地点**；可 Activate 其能力，不适用 Parley 同地点。见 03 §6.10。 |
| OQ-06-03 | [06-ability](design/06-ability-initiation.md) | 多个 [reaction] 谁选顺序？ | **Lead Investigator**（均已选用后）；选用权在控制者。见 06 §8.2。 |
| OQ-TIMING-01 | [15-timing](design/15-timing-entry-catalog.md) | When you draw 锚点 | **D2–D3 区间**（§16.3）。 |
| OQ-TIMING-02 | [15-timing](design/15-timing-entry-catalog.md) | Move leave/enter | **MOVE_ATOMIC** 单 brick、单 entry。见 15 §5.3。 |
| OQ-TIMING-03 | [15-timing](design/15-timing-entry-catalog.md) | Draw would/when | **SPLIT**；WOULD=D1 后 D2 前；WHEN=D2–D3。见 15 §16。 |
| OQ-TIMING-04 | [15-timing](design/15-timing-entry-catalog.md) | 玩家牌 **Revelation 能力** 于入手时的 nest 时点 | **ENTER_HAND（D3）**；`seq.enter_hand` + `TriggeringCondition.enter_hand`；**按 `has_revelation` 判定**，与 weakness 子类型无关。见 15 §16.2。 |
| OQ-TIMING-05 | [15-timing](design/15-timing-entry-catalog.md) | `enter_hand` 时点多张牌 / 多条显现的 **同类内** 顺序 | **设计师待定**；FORCED 类内自排；`EnterHandTimingPolicy`。跨类优先级见 06 §8.1。 |
| OQ-TIMING-06 | [15-timing](design/15-timing-entry-catalog.md) | 遭遇 draw WHEN 区间 | **E2–E5**（§17.3）；Surge 每圈独立 WHEN。 |
| OQ-TIMING-07 | [15-timing](design/15-timing-entry-catalog.md) | 遭遇 draw WOULD 锚点 | **E1 bind 后、E2 前**（§17.3）。 |
| OQ-TIMING-08 | [15-timing](design/15-timing-entry-catalog.md) | `amount > 1` encounter draw | **顺序** full resolve（含 Surge 链）再下一张。见 15 §17.2 E6。 |
| OQ-ENC-01 | [15-timing §17](design/15-timing-entry-catalog.md) | 遭遇 deck + discard 皆空 | v0：**RULES_GAP**。 |
| OQ-ENC-02 | [08-enemy §7.4](design/08-enemy-engagement.md) | drawer 无 location 时 spawn_engaged | v0：**`discard_spawn_failed`**。 |
| OQ-PERIL-01 | [04-skill-test §4](design/04-skill-test-engine.md) | drawer confer | **Presentation**；引擎不拦 drawer 行动。 |
| OQ-08-03 | [08-enemy](design/08-enemy-engagement.md) | Alert 时 enemy 不在 threat area 是否 deal？ | **是**，仍 deal。见 08 §6.4。 |
| OQ-01-05 | [01-state](design/01-game-state-zones.md) | 多 copy 同 title 非 exceptional 卡 in play：instance_id 与 definition_id 在 Target 解析中的优先级？ | |
| OQ-02-03 | [02-framework](design/02-framework-flow.md) | `INV_2_2` 选顺序：电子化是否每轮都 UI 选，还是允许「固定顺时针」可选规则？ | |
| OQ-02-04 | [02-framework](design/02-framework-flow.md) | Player Window「无响应」时：自动关闭 vs 显式「Pass」？ | **自动关闭**（`player_window_auto_close_ms` 可配置）。见 02 §4.1。 |
| OQ-02-06 | [02-framework](design/02-framework-flow.md) | 全员淘汰时是否立即 SCENARIO_RESOLUTION 还是完成当前 Framework 步？ | |
| OQ-03-04 | [03-action](design/03-action-system.md) | `[action]`×n 一次扣还是分步？AOO 几次？ | **一次花费** `actions -= n`；整次 initiating **至多 1 轮 AOO**。见 03 §3.2。 |
| OQ-08-01 | [08-enemy](design/08-enemy-engagement.md) | Hunter 等距 + Prey？ | **等距子集 → Prey 过滤 → Lead 选**；Prey 不可选非等距。见 08 §4。 |
| OQ-03-06 | [03-action](design/03-action-system.md) | Play asset 时 slot 弃置：玩家选顺序还是引擎默认最旧 asset？ | |
| OQ-04-03 | [04-skill-test](design/04-skill-test-engine.md) | Symbol 效果在 ST.4 发起 fight 嵌套检定，父检定 ST.5 是否等待子检定完成？ | **否。** 子检定入队；父 ST.5→ST.8 不等待；父 ST.8 后执行。 |
| OQ-04-04 | [04-skill-test](design/04-skill-test-engine.md) | Cancel 整个 skill test vs Cancel 单个 chaos token：状态回滚深度？ | |
| OQ-04-06 | [04-skill-test](design/04-skill-test-engine.md) | Committed 的 skill 在 ST.7 前被 discard 的 edge case（Limbo 保护）？ | |
| OQ-05-01 | [05-chaos-bag](design/05-chaos-bag.md) | 2026 Core 各场景 reference **全部 JSON 化** vs 部分 `ScenarioScript` — 你的偏好？ | |
| OQ-05-02 | [05-chaos-bag](design/05-chaos-bag.md) | Campaign-specific symbol（guide 指引）插件接口：`CampaignScript` 还是 `ScenarioScript`？ | |
| OQ-05-05 | [05-chaos-bag](design/05-chaos-bag.md) | Ignore vs Cancel chaos token 在 bag 中 token 是否仍算「revealed this test」？ | |
| OQ-06-04 | [06-ability](design/06-ability-initiation.md) | Forced [reaction] 是否存在？（通常无，但 scenario 卡） | |
| OQ-06-06 | [06-ability](design/06-ability-initiation.md) | Ignore 效果仍计 Limit — 触发时 record 还是 resolve 后 record？ | |
| OQ-07-01 | [07-effect](design/07-effect-resolution.md) | 伤害分配 UI：何时必须玩家选 vs AI 默认（最保护 investigator？）？ | |
| OQ-07-03 | [07-effect](design/07-effect-resolution.md) | Assign 阶段 prevent 部分 damage：剩余是否 re-assign 还是 fizzle？ | |
| OQ-07-05 | [07-effect](design/07-effect-resolution.md) | 「As much as possible resolve」— partial target invalid 时 DAG 如何剪枝？ | |
| OQ-08-05 | [08-enemy](design/08-enemy-engagement.md) | Engage 抢怪：同时 disengage 原调查员是否触发「leaves engagement」类能力？ | |
| OQ-09-01 | [09-location](design/09-location-graph.md) | Setup 放置 vs Move enter：是否统一 `enter_location()` 单入口？ | |
| OQ-09-03 | [09-location](design/09-location-graph.md) | Reveal 后 shroud/clue 动态修改（能力）— 已放置 clue 是否重算？ | |
| OQ-09-05 | [09-location](design/09-location-graph.md) | Your Friend's Room `[action]` Engage 跨连接 — Move enemy + engage 是否 provoke AOO？（文本说不） | |
| OQ-10-02 | [10-scenario](design/10-scenario-encounter.md) | Objective must advance 无 window — 自动 advance 还是暂停提示？ | |
| OQ-10-03 | [10-scenario](design/10-scenario-encounter.md) | Agenda 非 1.3 advance（卡牌 explicit）— 框架如何插入 ad-hoc advance 步？ | |
| OQ-10-05 | [10-scenario](design/10-scenario-encounter.md) | Act b side 变 Enemy — 是否立即 spawn 还是入 encounter 区？ | |
| OQ-11-01 | [11-investigator](design/11-investigator-campaign.md) | Starter deck flag 是否 per-campaign 还是 per-investigator？ | |
| OQ-11-02 | [11-investigator](design/11-investigator-campaign.md) | Bearer weakness 中途获得 — 是否立即 shuffle 进 deck 还是下一场？ | |
| OQ-11-04 | [11-investigator](design/11-investigator-campaign.md) | Deck validation 非法 deck — 阻止开始 scenario 还是 warning？ | |
| OQ-11-06 | [11-investigator](design/11-investigator-campaign.md) | Physical+mental trauma 同时导致 killed **and** insane 的 edge case？ | |
| OQ-12-02 | [12-api](design/12-card-script-api.md) | Codex 📖 交互：引擎 `read_codex(n)` 返回文本 + UI 展示，还是 ScenarioScript 完全控制 narrative？ | |
| OQ-12-03 | [12-api](design/12-card-script-api.md) | CardScript 热重载（开发时）是否需求？ | |
| OQ-12-05 | [12-api](design/12-card-script-api.md) | `request_player_choice` 同步阻塞 vs async signal — Godot 主线程模型选型？ | |
| OQ-12-06 | [12-api](design/12-card-script-api.md) | AbilityTemplate YAML 放 `data/` 还是 `.tres`？ | **纯 `data/*.yaml`**，启动加载。见 12 §6。 |

---

## P2 — 边缘案例 / 2026 澄清（22 条）

| ID | 来源 | 问题 | 裁决 |
|---|---|---|---|
| OQ-00-03 | [00-architecture](00-architecture-overview.md) | `EventRecord` 是否需持久化到磁盘以支持战役中断恢复？ | |
| OQ-00-05 | [00-architecture](00-architecture-overview.md) | AI 控制同伴调查员时，Hidden/Peril 信息隔离是否在 Presentation 层模拟「不读牌名」？ | |
| OQ-IDX-03 | [00-framework-step-index](design/00-framework-step-index.md) | Encounter draw 1.4 内 surge 递归是否单独子步骤 ID？ | |
| OQ-01-04 | [01-state](design/01-game-state-zones.md) | `SET_ASIDE` 与 `REMOVED_FROM_GAME` 是否需子类型（campaign 指定 area）？ | |
| OQ-01-06 | [01-state](design/01-game-state-zones.md) | Attachment 链（A attach B attach C）leave play 时 discard 顺序是否由 owner 选？ | |
| OQ-02-05 | [02-framework](design/02-framework-flow.md) | Framework 与嵌套 Skill Test 的 EventRecord 层级如何缩进展示？ | |
| OQ-03-05 | [03-action](design/03-action-system.md) | Elusive 在 AOO 后是否仍触发（AOO 算 attack）？ | |
| OQ-04-05 | [04-skill-test](design/04-skill-test-engine.md) | 同时 reveal 多 token（极少数卡）：ST.3 扩展协议？ | |
| OQ-05-04 | [05-chaos-bag](design/05-chaos-bag.md) | Bless/Curse 在 Core 2026 是否需实现还是仅预留 enum？ | |
| OQ-05-06 | [05-chaos-bag](design/05-chaos-bag.md) | 多 difficulty 切换 standalone：bag 是否在 setup 完全 rebuild？ | |
| OQ-06-05 | [06-ability](design/06-ability-initiation.md) | Constant ability 在 out-of-play 被引用（少数卡）— 如何标记 `references_out_of_play`？ | |
| OQ-07-04 | [07-effect](design/07-effect-resolution.md) | Simultaneous discard 多张：owner 选顺序是否影响后续 search？ | |
| OQ-08-04 | [08-enemy](design/08-enemy-engagement.md) | Patrol 目标 location 不在 play — 不移动还是 discard？ | |
| OQ-08-06 | [08-enemy](design/08-enemy-engagement.md) | Enemy 与 investigator 同地点但 aloof + ready：Investigate 合法，Fight 不合法 — 确认？ | |
| OQ-09-02 | [09-location](design/09-location-graph.md) | 同 title 多 copy location（罕见）— 仍算 different locations — 如何 instance 化？ | |
| OQ-09-04 | [09-location](design/09-location-graph.md) | Farthest location 计算：blocked path 是否参与？ | |
| OQ-09-06 | [09-location](design/09-location-graph.md) | Location enter play already revealed — clues 在 setup 还是 enter 时放？ | |
| OQ-10-04 | [10-scenario](design/10-scenario-encounter.md) | Encounter deck shuffle mid-ability | v0：**collect 立即洗**；嵌套效果 defer shuffle（[15 §17.11](design/15-timing-entry-catalog.md)）。 |
| OQ-10-06 | [10-scenario](design/10-scenario-encounter.md) | Forbidden Secrets surge 条件 — 引擎 evaluate 时机在 revelation 前还是后？ | **G3 显现入口**判定 clue 分支；动态 `gains surge` = KEYWORD 标记 Register · `WHILE_DRAWN_CARD_RESOLVING`；与印刷 surge **不叠加**。见 [15 §17.4.5](design/15-timing-entry-catalog.md)、[06 §3.1](design/06-registration-buff-model.md)。 |
| OQ-11-03 | [11-investigator](design/11-investigator-campaign.md) | Epic mode transfer — 电子版是否 v1 不实现？ | |
| OQ-11-05 | [11-investigator](design/11-investigator-campaign.md) | Random basic weakness 池 — 按 product 还是 global 池？ | |
| OQ-12-04 | [12-api](design/12-card-script-api.md) | 非 GDScript 卡牌逻辑（Lua/DSL）是否在路线图中？ | |

---

## 按子系统统计

| 子系统文档 | P0 | P1 | P2 | 合计 |
|---|---|---|---|---|
| 00 架构 | 1 | 3 | 2 | 6 |
| 00 Framework 索引 | 0 | 2 | 1 | 3 |
| 01 状态 | 1 | 3 | 2 | 6 |
| 02 框架 | 2 | 3 | 1 | 6 |
| 03 行动 | 2 | 3 | 1 | 6 |
| 04 检定 | 2 | 3 | 1 | 6 |
| 05 混沌袋 | 1 | 3 | 2 | 6 |
| 06 能力 | 2 | 3 | 1 | 6 |
| 07 效果 | 2 | 3 | 1 | 6 |
| 08 敌人 | 1 | 3 | 2 | 6 |
| 09 地点 | 0 | 3 | 3 | 6 |
| 10 场景 | 1 | 3 | 2 | 6 |
| 11 战役 | 0 | 4 | 2 | 6 |
| 12 API | 1 | 4 | 1 | 6 |
| **合计** | **16** | **43** | **22** | **81** |

---

## ArkhamDB 卡面驱动（Core 2026 回填 · Phase 4）

> 来源：[`data/arkhamdb/reports/phase4_core_2026_backfill.md`](../data/arkhamdb/reports/phase4_core_2026_backfill.md)

| ID | 关联 | 说明 | 优先级 |
|---|---|---|---|
| OQ-ADB-01 | [09-location §8](design/09-location-graph.md) / 12099 | Farthest empty spawn：blocked path 是否参与最短路径？与 OQ-09-04 同源 | P2 |
| OQ-ADB-04 | [06 §16.4](design/06-registration-buff-model.md) / 12012 | Necronomicon：`cannot leave play` + threat area — Permanent Domain vs RESTRICTION | P2 |
| OQ-ADB-05 | [15 §17.4.3](design/15-timing-entry-catalog.md) / 12179b | Hidden enemy 手牌 spawn — ENC-22/23 已竖切；多 copy 待补 | P2 |

**已裁决（涌动 · 动态 surge 编译）**：

| ID | 裁决 |
|---|---|
| OQ-ADB-02 | 动态 `gains surge` = KEYWORD 标记 · `WHILE_DRAWN_CARD_RESOLVING`；G5 与印刷 surge 合并 evaluate，**不叠加**。12124 选伤害分支时 G3 Register。见 [15 §17.4.5](design/15-timing-entry-catalog.md)。 |
| OQ-ADB-03 | 12126：`clue==0` 在 **G3 显现入口**判定；Register surge 标记并跳过 intellect；与印刷 surge 仍只 G5 再抽 1 次。同 OQ-10-06。 |
| OQ-ADB-06 | *your clues* 默认 = **调查员卡上** clue（`clues_on_card`）。见 [07 §3.3](design/07-composition.md)。 |
| OQ-ADB-07 | 12160 *no doom was placed* = place 步 **未 CREATED**；`after_step` if；nearest 等距 **当前交互玩家**选。见 07 §3.3、16 §7.2.1。 |
| OQ-ADB-08 | 12124 **must choose** 可执行项 + doom 支 **密谋推进框架**（阈值检测）。见 07 §3.3、16 §7.2.1。 |
| OQ-ADB-09 | 12126 fail-by either/or：印刷漏 **must**，按 must choose 可执行项。见 07 §3.3。 |
| OQ-ADB-10 | Forced **When + if** 等多要素 **能拆就拆**（timing · condition · cost · effect）。见 07 §3.3。 |

---

1. ~~**OQ-03-01**~~ — Fight 目标范围
2. ~~**OQ-03-02**~~ / ~~**OQ-08-02**~~ — 攻击原语与 Massive
3. ~~**OQ-06-01**~~ / ~~**OQ-07-06**~~ — Replacement 与 Cancel 栈
4. ~~**OQ-04-01**~~ / ~~**OQ-05-03**~~ — 混沌链与 fail by 时点
5. ~~**OQ-12-01**~~ / ~~**OQ-12-06**~~ — 数据驱动 vs 脚本边界
6. ~~**OQ-IDX-01**~~ / ~~**OQ-IDX-02**~~ — SkillTestStep 与 EventRecord
7. 其余 P1 按 Spreading Flames 战役经验优先

---

## 变更记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-05-25 | v0.1 | 从 12 份子文档汇总 78 条疑点 |
| 2026-05-25 | v0.2 | 修正 P0/P1/P2 计数 |
| 2026-05-25 | v0.3 | 与子文档全文同步；新增 OQ-IDX-01~03 |
| 2026-05-25 | v0.3.1 | OQ-00-06 裁决：需要 headless 规则运行 |
| 2026-05-25 | v0.3.2 | OQ-01-02 裁决：同时效果组语义（SimultaneousEffectGroup） |
| 2026-05-25 | v0.3.3 | OQ-02-01 裁决：Setup rewind 6/7/8，数据驱动 |
| 2026-05-25 | v0.3.4 | OQ-02-02 裁决：Flip 时 a 面不在场；Delayed 延续 |
| 2026-05-25 | v0.3.5 | OQ-03-01 裁决：Fight 以 Grimoire 同地点目标为准 |
| 2026-05-25 | v0.3.6 | OQ-03-02 裁决：EnemyAttack 统一攻击效果层 |
| 2026-05-25 | v0.3.7 | OQ-03-02 补充：触发 / 时点 / 攻击效果三层结构 |
| 2026-05-25 | v0.3.8 | OQ-04-01 裁决：Reveal another 递归无 Player Window |
| 2026-05-25 | v0.3.9 | OQ-04-02 裁决：Peril 覆盖 encounter 结算帧 |
| 2026-05-25 | v0.4.0 | OQ-05-03 裁决：fail by 效果在 ST.7 |
| 2026-05-25 | v0.4.1 | OQ-06-01/02 裁决：Replacement + Initiation dry-run |
| 2026-06-18 | v0.4.4 | OQ-06-01 细化：最后 initiate；新增 OQ-REPL-01；07 §3.2–§3.4 同时点竞争 |
| 2026-05-25 | v0.4.2 | OQ-07-06 裁决：Cancel vs Replacement 触发先后 |
| 2026-05-25 | v0.4.3 | OQ-07-02 裁决：TRANSFER_AFFLICTION 不算 heal |
| 2026-05-25 | v0.4.4 | OQ-08-02 裁决：Massive batch 锁定攻击序列 |
| 2026-05-25 | v0.4.5 | OQ-10-01 裁决：Setup 不结算显现；game begins 时结算 |
| 2026-05-25 | v0.4.6 | OQ-12-01 裁决：Template/Script 逐卡选型，无固定比例 |
| 2026-05-25 | v0.5.0 | 批次 P1：IDX-01/02、12-06、01-01、02-04、00-01 裁决 |
| 2026-05-25 | v0.5.1 | 批次 B 部分：01-03、03-03、06-03、08-03 裁决 |
| 2026-07-07 | v0.5.5 | OQ-ADB-06～10：clues 域、must choose、12160 after_step、多要素拆分 |
| 2026-07-06 | v0.5.4 | OQ-ADB-02/03、OQ-10-06 裁决：涌动 KEYWORD 标记 · 不叠加 |
| 2026-07-06 | v0.5.3 | 新增 OQ-ADB-01～05（ArkhamDB Phase 4 回填） |
| 2026-05-25 | v0.5.2 | OQ-03-04、OQ-08-01 裁决 |
