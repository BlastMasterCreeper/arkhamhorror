class_name ModifierEngine
extends RefCounted

var _store: RegistrationStore


func _init(store: RegistrationStore) -> void:
	_store = store


func compute(base: int, query: ModifierQuery) -> int:
	var mods := _store.collect_modifiers(query.controller_id)
	var add_total := 0
	var mul_factor := 1.0
	for mod in mods:
		if mod.stat != query.stat:
			continue
		match mod.op:
			AhcEnums.ModOp.ADD:
				add_total += mod.value
			AhcEnums.ModOp.SUB:
				add_total -= mod.value
			AhcEnums.ModOp.DOUBLE:
				mul_factor *= 2.0
			AhcEnums.ModOp.HALVE:
				mul_factor *= 0.5
	var result := int(ceil((base + add_total) * mul_factor))
	return maxi(result, 0)
