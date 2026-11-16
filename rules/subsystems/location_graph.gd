class_name LocationGraph
extends RefCounted

## 信息层地点拓扑。
## 有效邻接 = 地点符号边（LocationState.connections）∪ 冒险设置写入的连接法则。
## 距离、路径、一步邻接都从这里问；移动和各查询不直接翻 connections。

const LAW_LINK := &"link"
const LAW_SAME_TRAIT := &"same_trait"
const LAW_COMPLETE := &"complete"


static func neighbors(state: GameStateStore, location_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	if state == null or location_id == &"":
		return out
	var loc := state.registry.get_location(location_id)
	if loc == null:
		return out
	var seen: Dictionary = {}
	for conn in loc.connections:
		_append_neighbor(out, seen, location_id, conn as StringName)
	for law in state.connection_laws:
		for extra in _law_neighbors(state, location_id, law):
			_append_neighbor(out, seen, location_id, extra)
	return out


static func is_adjacent(
	state: GameStateStore,
	from_id: StringName,
	to_id: StringName
) -> bool:
	if from_id == &"" or to_id == &"" or from_id == to_id:
		return false
	return neighbors(state, from_id).has(to_id)


static func distance(
	state: GameStateStore,
	from_id: StringName,
	to_id: StringName
) -> int:
	if state == null or from_id == &"" or to_id == &"":
		return -1
	if from_id == to_id:
		return 0
	var queue: Array = [[from_id, 0]]
	var seen: Dictionary = {from_id: true}
	while not queue.is_empty():
		var item: Array = queue.pop_front()
		var here: StringName = item[0]
		var dist: int = item[1]
		for nxt in neighbors(state, here):
			if nxt == to_id:
				return dist + 1
			if not seen.has(nxt):
				seen[nxt] = true
				queue.append([nxt, dist + 1])
	return -1


static func shortest_path(
	state: GameStateStore,
	from_id: StringName,
	to_id: StringName
) -> Array[StringName]:
	var empty: Array[StringName] = []
	if state == null or from_id == &"" or to_id == &"":
		return empty
	if from_id == to_id:
		return [from_id]
	var queue: Array[StringName] = [from_id]
	var prev: Dictionary = {}
	var seen: Dictionary = {from_id: true}
	var found := false
	while not queue.is_empty():
		var here: StringName = queue.pop_front()
		for nxt in neighbors(state, here):
			if seen.has(nxt):
				continue
			seen[nxt] = true
			prev[nxt] = here
			if nxt == to_id:
				found = true
				queue.clear()
				break
			queue.append(nxt)
	if not found:
		return empty
	var rev: Array[StringName] = [to_id]
	var cursor: StringName = to_id
	while cursor != from_id:
		cursor = prev[cursor]
		rev.append(cursor)
	rev.reverse()
	return rev


static func grant_link(
	state: GameStateStore,
	from_id: StringName,
	to_id: StringName,
	bidirectional: bool = true
) -> void:
	if state == null or from_id == &"" or to_id == &"" or from_id == to_id:
		return
	_add_link(state, from_id, to_id)
	if bidirectional:
		_add_link(state, to_id, from_id)


static func grant_same_trait(state: GameStateStore, trait_name: StringName) -> void:
	if state == null or trait_name == &"":
		return
	for law in state.connection_laws:
		if law.get("kind", &"") == LAW_SAME_TRAIT and law.get("trait", &"") == trait_name:
			return
	state.connection_laws.append({"kind": LAW_SAME_TRAIT, "trait": trait_name})


static func grant_complete(state: GameStateStore) -> void:
	if state == null:
		return
	for law in state.connection_laws:
		if law.get("kind", &"") == LAW_COMPLETE:
			return
	state.connection_laws.append({"kind": LAW_COMPLETE})


static func duplicate_laws(laws: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for law in laws:
		out.append(law.duplicate(true))
	return out


static func _add_link(state: GameStateStore, from_id: StringName, to_id: StringName) -> void:
	for law in state.connection_laws:
		if law.get("kind", &"") != LAW_LINK:
			continue
		if law.get("from", &"") == from_id and law.get("to", &"") == to_id:
			return
	state.connection_laws.append({
		"kind": LAW_LINK,
		"from": from_id,
		"to": to_id,
	})


static func _append_neighbor(
	out: Array[StringName],
	seen: Dictionary,
	origin: StringName,
	candidate: StringName
) -> void:
	if candidate == &"" or candidate == origin or seen.has(candidate):
		return
	seen[candidate] = true
	out.append(candidate)


static func _law_neighbors(
	state: GameStateStore,
	location_id: StringName,
	law: Dictionary
) -> Array[StringName]:
	var out: Array[StringName] = []
	var kind: StringName = law.get("kind", &"")
	match kind:
		LAW_LINK:
			if law.get("from", &"") == location_id:
				var dest: StringName = law.get("to", &"")
				if dest != &"":
					out.append(dest)
		LAW_SAME_TRAIT:
			var trait_name: StringName = law.get("trait", &"")
			if trait_name == &"" or not CardRegistry.has_trait(location_id, trait_name):
				return out
			for other_id in state.registry.all_location_ids():
				if other_id != location_id and CardRegistry.has_trait(other_id, trait_name):
					out.append(other_id)
		LAW_COMPLETE:
			for other_id in state.registry.all_location_ids():
				if other_id != location_id:
					out.append(other_id)
	return out
