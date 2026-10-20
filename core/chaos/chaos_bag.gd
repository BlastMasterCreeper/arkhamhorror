class_name ChaosBag
extends RefCounted

var tokens: Array[ChaosToken] = []
var revealed_this_test: Array[ChaosToken] = []
var _binding: PhysicalBinding = null


func bind_physical(binding: PhysicalBinding) -> void:
	_binding = binding
	if _binding != null:
		_binding.resync_chaos_bag_from_tokens(tokens)


func shuffle() -> void:
	tokens.shuffle()


func draw_random() -> ChaosToken:
	if tokens.is_empty():
		return null
	var idx := randi() % tokens.size()
	var token := tokens[idx]
	tokens.remove_at(idx)
	revealed_this_test.append(token)
	if _binding != null:
		_binding.mirror_chaos_draw(token)
	return token


func return_token(token: ChaosToken) -> void:
	if token == null:
		return
	revealed_this_test.erase(token)
	tokens.append(token)
	if _binding != null:
		_binding.mirror_chaos_return(token)


func return_all_revealed() -> void:
	while not revealed_this_test.is_empty():
		return_token(revealed_this_test[0])


func add_token(token: ChaosToken) -> void:
	tokens.append(token)
	if _binding != null:
		_binding.mirror_chaos_add_to_bag(token)


func clear() -> void:
	tokens.clear()
	revealed_this_test.clear()
	if _binding != null:
		_binding.resync_chaos_bag_from_tokens([])
