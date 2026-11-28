class_name CardAccessMatcher
extends RefCounted

## FAQ 1.15 有序配位：FORBID → 无限 ALLOW → LIMIT 占坑。

const KIND_FORBIDDEN := &"forbidden"
const KIND_UNLIMITED := &"unlimited"
const KIND_LIMITED := &"limited"
const KIND_NONE := &"none"


## 返回 { kind, rule, reason }
static func classify(card: DeckCardView, profile: DeckbuildingProfile) -> Dictionary:
	if card == null or profile == null:
		return {"kind": KIND_NONE, "rule": null, "reason": "missing"}
	if card.ignore_deckbuilding:
		return {"kind": KIND_UNLIMITED, "rule": null, "reason": "ignore_deckbuilding"}
	for rule in profile.forbids:
		if rule.matches_card(card):
			var reason := rule.error if rule.error != "" else "forbidden"
			return {"kind": KIND_FORBIDDEN, "rule": rule, "reason": reason}
	for rule in profile.unlimited:
		if rule.matches_card(card):
			return {"kind": KIND_UNLIMITED, "rule": rule, "reason": ""}
	for rule in profile.limited:
		if rule.matches_card(card):
			return {"kind": KIND_LIMITED, "rule": rule, "reason": ""}
	return {"kind": KIND_NONE, "rule": null, "reason": "no_access"}


static func can_access(card: DeckCardView, profile: DeckbuildingProfile) -> bool:
	var kind: StringName = classify(card, profile).get("kind", KIND_NONE)
	return kind == KIND_UNLIMITED or kind == KIND_LIMITED
