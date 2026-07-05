class_name SpawnInstructionSpec
extends RefCounted

enum Mode { FRAMEWORK_DEFAULT, INSTRUCTION }

enum SelectorKind { DRAWER_LOCATION, NAMED_LOCATION, NEAREST_EMPTY, FARTHEST_EMPTY }


var mode: Mode = Mode.FRAMEWORK_DEFAULT
var selector_kind: SelectorKind = SelectorKind.DRAWER_LOCATION
var location_tag: StringName = &""


static func framework_default() -> SpawnInstructionSpec:
	return SpawnInstructionSpec.new()


static func at_drawer_location() -> SpawnInstructionSpec:
	var spec := SpawnInstructionSpec.new()
	spec.mode = Mode.INSTRUCTION
	spec.selector_kind = SelectorKind.DRAWER_LOCATION
	return spec


static func at_named_location(location_tag: StringName) -> SpawnInstructionSpec:
	var spec := SpawnInstructionSpec.new()
	spec.mode = Mode.INSTRUCTION
	spec.selector_kind = SelectorKind.NAMED_LOCATION
	spec.location_tag = location_tag
	return spec


static func nearest_empty() -> SpawnInstructionSpec:
	var spec := SpawnInstructionSpec.new()
	spec.mode = Mode.INSTRUCTION
	spec.selector_kind = SelectorKind.NEAREST_EMPTY
	return spec


static func farthest_empty() -> SpawnInstructionSpec:
	var spec := SpawnInstructionSpec.new()
	spec.mode = Mode.INSTRUCTION
	spec.selector_kind = SelectorKind.FARTHEST_EMPTY
	return spec
