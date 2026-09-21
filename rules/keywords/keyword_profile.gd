class_name KeywordProfile
extends RefCounted

## 06 §3.2.5–§3.2.6 · 对局行为编译为三种 Buff；Fast 走 Initiation 档（非第四 BuffType）。
## 注册/注销绑已有 seq.* 砖或 zone 变迁（L0），禁止 PERIL_CHECK 一类独立场合节点。
## 猎物 / 生成是指令，不进本类。

var keyword: StringName = &""
var buff_type: StringName = &"LISTENER"
var consume_slot: StringName = &""
var consume_flow_id: StringName = &""
var register_flow_id: StringName = &""
var register_slot: StringName = &""
var unregister_flow_id: StringName = &""
var unregister_slot: StringName = &""
var armed_zone: StringName = &""
var lifetime_kind: StringName = &""
