class_name RestrictionPayload
extends RefCounted

var kind: AhcEnums.RestrictionKind = AhcEnums.RestrictionKind.FORBID_DRAW


static func forbid_draw() -> RestrictionPayload:
	var p := RestrictionPayload.new()
	p.kind = AhcEnums.RestrictionKind.FORBID_DRAW
	return p
