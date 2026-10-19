class_name ChaosRevealReplaceAbility
extends RefCounted

## 「将要揭示」替换体：揭 N 代 1、再选 M 枚结算（Olive / Grotesque Statue 等）。
## 多条同时可用时，先 ORDER 次序，再选作用到哪一枚**预期槽**（尚未离袋）。

var ability_id: StringName = &""
var controller_id: StringName = &""
## 把 1 个预期槽展开成几枚物理揭示。
var reveal_count: int = 1
## 展开后保留/resolve 几枚；-1 = 全部 resolve；其余 ignore（整枚）。
var resolve_count: int = -1


static func create(
	ability_id: StringName,
	controller_id: StringName,
	reveal_count: int,
	resolve_count: int = -1
) -> ChaosRevealReplaceAbility:
	var a := ChaosRevealReplaceAbility.new()
	a.ability_id = ability_id
	a.controller_id = controller_id
	a.reveal_count = maxi(reveal_count, 1)
	a.resolve_count = resolve_count
	return a
