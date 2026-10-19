class_name LocationState
extends RefCounted

var id: StringName = &""
var shroud: int = 0
## 当前地点上的线索标记数。
var clues: int = 0
## 印刷 clue value（每位调查员基数）；-1 = 未设，查 CardRegistry（dash 亦为 -1）。
var printed_clues: int = -1
## 默认 true 便于测试旁路；setup / 未揭示布局须显式 false。
var revealed: bool = true
var connections: Array[StringName] = []
