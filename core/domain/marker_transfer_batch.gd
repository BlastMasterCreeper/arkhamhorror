class_name MarkerTransferBatch
extends RefCounted

## 包装层（非 L0）：多来源 / 多目标标记转移。
## 展开为若干 **原子** `StateMutator.transfer_marker`（每腿 1 from → 1 to）。
## 不改状态原语；不铸 `seq.effect.*`；不在单次 L0 内吞多腿（避免伪原子与嵌套窗错位）。
##
## `sources` / `targets`：`Array` of `{ "slot": MarkerSlot, "amount": int }`。
## 守恒：sum(sources) == sum(targets) > 0，否则失败。


## 展开为 1:1 腿：`[{ "from": MarkerSlot, "to": MarkerSlot, "amount": int }, …]`。
static func expand(sources: Array, targets: Array) -> Array[Dictionary]:
	var from_legs := _normalize(sources)
	var to_legs := _normalize(targets)
	var empty: Array[Dictionary] = []
	if from_legs.is_empty() or to_legs.is_empty():
		return empty
	var sum_from := 0
	var sum_to := 0
	for leg in from_legs:
		sum_from += int(leg.get("amount", 0))
	for leg in to_legs:
		sum_to += int(leg.get("amount", 0))
	if sum_from != sum_to or sum_from <= 0:
		return empty
	## 贪心配对：按源/目标顺序切段，每段一条原子腿。
	var si := 0
	var ti := 0
	var s_rem := int(from_legs[0].get("amount", 0))
	var t_rem := int(to_legs[0].get("amount", 0))
	var out: Array[Dictionary] = []
	while si < from_legs.size() and ti < to_legs.size():
		var n := mini(s_rem, t_rem)
		if n <= 0:
			return empty
		out.append(
			{
				"from": from_legs[si].get("slot"),
				"to": to_legs[ti].get("slot"),
				"amount": n,
			}
		)
		s_rem -= n
		t_rem -= n
		if s_rem == 0:
			si += 1
			if si < from_legs.size():
				s_rem = int(from_legs[si].get("amount", 0))
		if t_rem == 0:
			ti += 1
			if ti < to_legs.size():
				t_rem = int(to_legs[ti].get("amount", 0))
	if si != from_legs.size() or ti != to_legs.size() or s_rem != 0 or t_rem != 0:
		return empty
	return out


## 预检守恒并展开后，逐腿调用原子 `transfer_marker`。任腿失败即返回 false（已成功腿不回滚）。
static func execute(
	mutator: StateMutator,
	kind: AhcEnums.MarkerKind,
	sources: Array,
	targets: Array
) -> bool:
	if mutator == null:
		return false
	var legs := expand(sources, targets)
	if legs.is_empty():
		return false
	for leg in legs:
		var from_slot: MarkerSlot = leg.get("from") as MarkerSlot
		var to_slot: MarkerSlot = leg.get("to") as MarkerSlot
		var amount := int(leg.get("amount", 0))
		if from_slot == null or to_slot == null or amount <= 0:
			return false
		if not mutator.transfer_marker(kind, amount, from_slot, to_slot):
			return false
	return true


static func _normalize(legs: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item in legs:
		if not (item is Dictionary):
			return []
		var d: Dictionary = item
		var slot: MarkerSlot = d.get("slot") as MarkerSlot
		var amount := int(d.get("amount", 0))
		if slot == null or amount <= 0:
			return []
		out.append({"slot": slot, "amount": amount})
	return out
