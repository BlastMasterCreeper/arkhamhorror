class_name StatFolder
extends RefCounted


static func fold(records: Array, query: StatQuery, scope: StatScope) -> Variant:
	match query.key:
		AhcEnums.StatKey.TURN_ACTION_SPEND_COUNT, AhcEnums.StatKey.TURN_ACTION_SPEND_EMPTY:
			return _count_action_spends(records, scope)
	return 0


static func _count_action_spends(records: Array, scope: StatScope) -> int:
	var voided: Dictionary = {}
	for rec in records:
		if not rec is EventRecord:
			continue
		if rec.kind == AhcEnums.EventRecordKind.ACTION_SPEND_VOID:
			var sid: Variant = rec.payload.get("spend_id", -1)
			voided[int(sid)] = true
	var count := 0
	for rec in records:
		if not rec is EventRecord:
			continue
		if rec.kind != AhcEnums.EventRecordKind.ACTION_SPEND:
			continue
		if rec.payload.get("inv_id") != scope.inv_id:
			continue
		var spend_id := int(rec.payload.get("spend_id", rec.seq))
		if voided.has(spend_id):
			continue
		count += int(rec.payload.get("cost", 1))
	return count
