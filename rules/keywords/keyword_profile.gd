class_name KeywordProfile
extends RefCounted

## 06 §3.2.5 · 关键词编译为三种 Buff。本表目前只挂 LISTENER 延时竖切（涌动）。
## 猎物 / 生成是指令，不进本类。

var keyword: StringName = &""
var buff_type: StringName = &"LISTENER"
var consume_slot: StringName = &""
var consume_flow_id: StringName = &""
