class_name GameLog
extends RefCounted

var _entries: Array[Dictionary] = []


func log(category: AhcEnums.LogCategory, message: String, payload: Dictionary = {}) -> void:
	_entries.append({
		"category": category,
		"message": message,
		"payload": payload,
		"time_ms": Time.get_ticks_msec(),
	})


func get_entries() -> Array[Dictionary]:
	return _entries
