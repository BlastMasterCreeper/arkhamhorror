class_name StatProjection
extends RefCounted

enum State { DORMANT, HOT }

var query_key: StringName = &""
var query: StatQuery = null
var scope: StatScope = null
var state: State = State.DORMANT
var ref_count: int = 0
var value: Variant = 0
var watermark_seq: int = -1
