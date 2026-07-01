class_name EventIndex
extends RefCounted

## turn 窗口索引：TURN_BEGIN 开 span，TURN_END 关 span。

var _spans: Array[Dictionary] = []
var _open: Dictionary = {}  # inv_id -> { turn_id, start_seq }


func on_turn_begin(turn_id: int, inv_id: StringName, start_seq: int) -> void:
	_open[inv_id] = {"turn_id": turn_id, "start_seq": start_seq}


func on_turn_end(turn_id: int, inv_id: StringName, end_seq: int) -> void:
	var open: Variant = _open.get(inv_id)
	if open is Dictionary:
		var o: Dictionary = open
		if int(o.get("turn_id", -1)) == turn_id:
			_spans.append(
				{
					"turn_id": turn_id,
					"inv_id": inv_id,
					"start_seq": int(o.get("start_seq", 0)),
					"end_seq": end_seq,
				}
			)
			_open.erase(inv_id)


func window_for(inv_id: StringName, turn_id: int, last_seq: int) -> Dictionary:
	for span in _spans:
		if span.get("inv_id") == inv_id and int(span.get("turn_id", -1)) == turn_id:
			return span
	var open: Variant = _open.get(inv_id)
	if open is Dictionary:
		var o: Dictionary = open
		if int(o.get("turn_id", -1)) == turn_id:
			return {
				"turn_id": turn_id,
				"inv_id": inv_id,
				"start_seq": int(o.get("start_seq", 0)),
				"end_seq": last_seq,
			}
	return {"start_seq": 0, "end_seq": last_seq}
