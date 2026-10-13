class_name PatrolTargetSpec
extends RefCounted

## Patrol 括号内 designated target（① 规则参数）。

enum Mode { NAMED_LOCATION, NAMED_LOCATION_CHOICE }


var mode: Mode = Mode.NAMED_LOCATION
var location_tag: StringName = &""
var location_candidates: Array[StringName] = []


static func at_named_location(location_tag: StringName) -> PatrolTargetSpec:
	var spec := PatrolTargetSpec.new()
	spec.mode = Mode.NAMED_LOCATION
	spec.location_tag = location_tag
	return spec


static func choose_named_location(candidates: Array[StringName]) -> PatrolTargetSpec:
	var spec := PatrolTargetSpec.new()
	spec.mode = Mode.NAMED_LOCATION_CHOICE
	spec.location_candidates = candidates.duplicate()
	return spec
