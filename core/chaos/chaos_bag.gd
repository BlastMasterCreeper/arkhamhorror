class_name ChaosBag
extends RefCounted

var tokens: Array[ChaosToken] = []
var revealed_this_test: Array[ChaosToken] = []


func shuffle() -> void:
	tokens.shuffle()


func draw_random() -> ChaosToken:
	if tokens.is_empty():
		return null
	var idx := randi() % tokens.size()
	var token := tokens[idx]
	tokens.remove_at(idx)
	revealed_this_test.append(token)
	return token


func return_token(token: ChaosToken) -> void:
	if token == null:
		return
	revealed_this_test.erase(token)
	tokens.append(token)


func return_all_revealed() -> void:
	while not revealed_this_test.is_empty():
		return_token(revealed_this_test[0])


func add_token(token: ChaosToken) -> void:
	tokens.append(token)


func clear() -> void:
	tokens.clear()
	revealed_this_test.clear()
