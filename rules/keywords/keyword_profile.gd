class_name KeywordProfile
extends RefCounted

## 06 §3.2.5–§3.2.7 · 对局行为编译为三种 Buff；Fast 走 Initiation 档（非第四 BuffType）。
## 注册/注销绑已有 seq.* 砖或 zone 变迁（L0），禁止 PERIL_CHECK 一类独立场合节点。
## LISTENER：mount ≠ fire；开火锚 = (fire_flow_id, consume_slot) + fire_priority。
## 猎物 / 生成是指令，不进本类。

var keyword: StringName = &""
var buff_type: StringName = &"LISTENER"
## 开火槽（KeywordConsumer.consume_at）；与 fire_flow_id 组成锚点。
var consume_slot: StringName = &""
## 开火 payload 命名流程（seq.keyword.*）；空 = 非 nest 开火。
var consume_flow_id: StringName = &""
## 挂载：Register 绑哪条固定流程 / 哪一砖（可空 = zone 变迁）。
var register_flow_id: StringName = &""
var register_slot: StringName = &""
var unregister_flow_id: StringName = &""
var unregister_slot: StringName = &""
var armed_zone: StringName = &""
var lifetime_kind: StringName = &""
## 开火锚：监听哪条固定流程（流程本身不管理关键词体）。
var fire_flow_id: StringName = &""
## 同锚点内引擎固定序；数值越小越先（见 06 §3.2.7）。
var fire_priority: int = 100
## 跨类档：与 AbilityCategoryTier / SequenceHandler.Tier 对齐（LISTENER / DELAYED…）。
var category_tier: StringName = &"LISTENER"
## 开火体：静态 nest 规格（与卡面 Composition 的 nest 叶同一种语言）。
## `$card_id` / `$drawer_id` / `$def_id` / `$investigator_id` 在开火时代入。
## 单步用 effect_flow_id；多步用 effect_steps（`{flow_id, params}`）。
var effect_flow_id: StringName = &""
var effect_params: Dictionary = {}
var effect_steps: Array = []
## 开火门：skill / success / ready / same_location。空 = 不额外过滤。
var effect_when: Dictionary = {}
## `surge`：UNTIL_FIRED 卸标记，并把再抽结果包成涌动报告。
var effect_report: StringName = &""
