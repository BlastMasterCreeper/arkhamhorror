class_name KeywordProfile
extends RefCounted

## 06 §3.2.5–§3.2.6 · 关键词编译为三种 Buff；LISTENER / RESTRICTION 按场合 Register/Unregister。
## 猎物 / 生成是指令，不进本类。

var keyword: StringName = &""
var buff_type: StringName = &"LISTENER"
var consume_slot: StringName = &""
var consume_flow_id: StringName = &""
var register_occasion: StringName = &""
var unregister_occasion: StringName = &""
var armed_zone: StringName = &""
var lifetime_kind: StringName = &""
