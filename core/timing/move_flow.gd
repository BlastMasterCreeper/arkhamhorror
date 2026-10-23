class_name MoveFlow
extends RefCounted

## 狭义地点变更内核 · `seq.effect.move`。
## 已位于地点的调查员 / 敌人 / 地点附属 / 地点标记 → 新地点（leave+enter 同时）。
## 不含：场内外区域广义转移；两地点实体交换（原子、不可 nest、不触发移动时点）。
##
## `move_kind`（连接规则 · 一等语义）：
## - `move`：**移动** — 必须沿地点连接（调查员邻接；敌人寻路步进 / 邻接直达）
## - `move_to`：**移动到地点** — 无视连接，一次落到目标地点

const SUBJECT_INVESTIGATOR := &"investigator"
const SUBJECT_ENEMY := &"enemy"
const SUBJECT_ATTACHMENT := &"attachment"
const SUBJECT_MARKER := &"marker"

const KIND_MOVE := &"move"
const KIND_MOVE_TO := &"move_to"

## 敌人在 `move` 下的路径实现：`toward` = 寻路步进（默认）；`direct` = 邻接一次写（仍校验连接）。
const MODE_TOWARD := &"toward"
const MODE_DIRECT := &"direct"


static func nest_or_run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	## 有 Catalog 时 nest 压栈（可被移动时点听到）；否则直跑内核。
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(&"seq.effect.move")
	):
		return game_ctx.sequence_catalog.nest(game_ctx, &"seq.effect.move", params)
	return run(game_ctx, params)


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	var subject := resolve_subject(params)
	match subject:
		SUBJECT_INVESTIGATOR:
			return _move_investigator(game_ctx, params)
		SUBJECT_ENEMY:
			return _move_enemy(game_ctx, params)
		SUBJECT_ATTACHMENT:
			return _move_attachment(game_ctx, params)
		SUBJECT_MARKER:
			return _move_marker(game_ctx, params)
	return {"ok": false, "error": "unknown_subject", "subject": subject}


static func resolve_move_kind(params: Dictionary) -> StringName:
	var explicit: StringName = params.get("move_kind", &"") as StringName
	if explicit == KIND_MOVE or explicit == KIND_MOVE_TO:
		return explicit
	## 兼容旧 params：require_connected=false → 移动到地点。
	if params.has("require_connected") and not bool(params.get("require_connected")):
		return KIND_MOVE_TO
	## 兼容旧敌人 mode=direct 且未声明 kind → 视为移动到地点。
	if (
		params.get("mode", &"") == MODE_DIRECT
		and resolve_subject(params) == SUBJECT_ENEMY
	):
		return KIND_MOVE_TO
	return KIND_MOVE


static func resolve_subject(params: Dictionary) -> StringName:
	var explicit: StringName = params.get("subject", &"") as StringName
	if explicit != &"":
		return explicit
	if params.get("enemy_id", &"") != &"":
		return SUBJECT_ENEMY
	if (
		params.get("marker_kind", null) != null
		or params.has("amount") and (
			params.get("from_location", &"") != &""
			or params.get("source_location", &"") != &""
		)
	):
		## 地点标记移动：显式 kind，或 amount + 源地点。
		if (
			params.get("card_id", &"") == &""
			and params.get("attachment_id", &"") == &""
		):
			return SUBJECT_MARKER
	if (
		params.get("attachment_id", &"") != &""
		or params.get("card_id", &"") != &""
	):
		return SUBJECT_ATTACHMENT
	if (
		params.get("investigator_id", &"") != &""
		or params.get("inv_id", &"") != &""
	):
		return SUBJECT_INVESTIGATOR
	return &""


static func _destination(params: Dictionary) -> StringName:
	return params.get(
		"destination_id",
		params.get("to", params.get("target_location", &""))
	) as StringName


static func _move_investigator(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var inv_id: StringName = params.get(
		"investigator_id", params.get("inv_id", &"")
	)
	var dest_id := _destination(params)
	var move_kind := resolve_move_kind(params)
	if inv_id == &"" or dest_id == &"":
		return {"ok": false, "error": "missing_investigator_or_destination"}
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator"}
	var dest := game_ctx.state.registry.get_location(dest_id)
	if dest == null:
		return {"ok": false, "error": "unknown_location"}
	var from_id: StringName = inv.location_tag
	if from_id == &"":
		return {"ok": false, "error": "not_at_location"}
	if move_kind == KIND_MOVE:
		var conn_err := _reject_if_not_connected(game_ctx, from_id, dest_id)
		if conn_err != &"":
			return {"ok": false, "error": conn_err, "move_kind": move_kind}
	if from_id == dest_id:
		return _ok_skipped(SUBJECT_INVESTIGATOR, inv_id, from_id, dest_id, {
			"investigator_id": inv_id,
			"move_kind": move_kind,
		})
	inv.location_tag = dest_id
	if bool(params.get("reveal_on_enter", true)) and not dest.revealed:
		dest.revealed = true
		if dest.clues < 1:
			if game_ctx.mutator != null:
				game_ctx.mutator.transfer_marker(
					AhcEnums.MarkerKind.CLUE,
					1,
					MarkerSlot.supply(AhcEnums.MarkerKind.CLUE),
					MarkerSlot.location(dest_id, AhcEnums.MarkerKind.CLUE)
				)
			else:
				dest.clues = 1
	if _auto_engage(params, true):
		EngageFlow.nest_after_area_change(game_ctx, dest_id)
	_log_move(game_ctx, SUBJECT_INVESTIGATOR, inv_id, from_id, dest_id, {
		"move_kind": move_kind,
	})
	return _ok_moved(SUBJECT_INVESTIGATOR, inv_id, from_id, dest_id, {
		"investigator_id": inv_id,
		"move_kind": move_kind,
	})


static func _move_enemy(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var enemy_id: StringName = params.get("enemy_id", &"")
	var target_loc := _destination(params)
	var move_kind := resolve_move_kind(params)
	if enemy_id == &"" or target_loc == &"":
		return {"ok": false, "error": "missing_enemy_or_location"}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "error": "unknown_enemy"}
	var from_id: StringName = enemy.location_tag
	if from_id == &"":
		return {"ok": false, "error": "not_at_location"}
	if game_ctx.state.registry.get_location(target_loc) == null:
		return {"ok": false, "error": "unknown_location"}
	var do_auto_engage := _auto_engage(params, true)
	## 移动到地点：无视连接，一次落到目标。
	if move_kind == KIND_MOVE_TO:
		return _move_enemy_direct(
			game_ctx, enemy, enemy_id, from_id, target_loc, do_auto_engage, move_kind, MODE_DIRECT
		)
	## 移动：沿连接。mode=direct 时仅允许邻接一次写；默认 toward 寻路步进。
	var mode: StringName = params.get("mode", MODE_TOWARD) as StringName
	if mode == MODE_DIRECT:
		var conn_err := _reject_if_not_connected(game_ctx, from_id, target_loc)
		if conn_err != &"":
			return {"ok": false, "error": conn_err, "move_kind": move_kind}
		return _move_enemy_direct(
			game_ctx, enemy, enemy_id, from_id, target_loc, do_auto_engage, move_kind, MODE_DIRECT
		)
	var steps: int = maxi(1, int(params.get("steps", 1)))
	var last := {
		"ok": true,
		"subject": SUBJECT_ENEMY,
		"enemy_id": enemy_id,
		"from": from_id,
		"to": from_id,
		"destination_id": target_loc,
		"target_location": target_loc,
		"moved": false,
		"mode": MODE_TOWARD,
		"move_kind": move_kind,
	}
	for _i in steps:
		var hop := EnemyMovement.move_one_step_toward_location(
			game_ctx, enemy_id, target_loc
		)
		if not bool(hop.get("moved", false)):
			break
		var to_loc: StringName = hop.get("to_location", &"") as StringName
		last["moved"] = true
		last["from"] = hop.get("from_location", from_id)
		last["to"] = to_loc
		last["to_location"] = to_loc
		if to_loc != &"" and do_auto_engage:
			var engage := EngageFlow.nest_after_area_change(game_ctx, to_loc, enemy_id)
			last["engaged_investigator"] = engage.get("investigator_id", &"")
			var moved_enemy := game_ctx.state.registry.get_enemy(enemy_id)
			if moved_enemy != null and moved_enemy.massive:
				MassiveEngagement.sync_for_enemy(game_ctx, enemy_id)
	_log_move(
		game_ctx,
		SUBJECT_ENEMY,
		enemy_id,
		last.get("from", from_id),
		last.get("to", from_id),
		{"move_kind": move_kind}
	)
	return last


static func _move_enemy_direct(
	game_ctx: GameContext,
	enemy: EnemyState,
	enemy_id: StringName,
	from_id: StringName,
	dest_id: StringName,
	do_auto_engage: bool,
	move_kind: StringName,
	mode: StringName
) -> Dictionary:
	if from_id == dest_id:
		return _ok_skipped(SUBJECT_ENEMY, enemy_id, from_id, dest_id, {
			"enemy_id": enemy_id,
			"target_location": dest_id,
			"mode": mode,
			"move_kind": move_kind,
		})
	enemy.location_tag = dest_id
	var out := _ok_moved(SUBJECT_ENEMY, enemy_id, from_id, dest_id, {
		"enemy_id": enemy_id,
		"target_location": dest_id,
		"to_location": dest_id,
		"mode": mode,
		"move_kind": move_kind,
	})
	if do_auto_engage:
		var engage := EngageFlow.nest_after_area_change(game_ctx, dest_id, enemy_id)
		out["engaged_investigator"] = engage.get("investigator_id", &"")
		if enemy.massive:
			MassiveEngagement.sync_for_enemy(game_ctx, enemy_id)
	_log_move(game_ctx, SUBJECT_ENEMY, enemy_id, from_id, dest_id, {
		"move_kind": move_kind,
	})
	return out


static func _move_attachment(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var card_id: StringName = params.get(
		"attachment_id", params.get("card_id", &"")
	)
	var dest_id := _destination(params)
	var move_kind := resolve_move_kind(params)
	if card_id == &"" or dest_id == &"":
		return {"ok": false, "error": "missing_attachment_or_destination"}
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return {"ok": false, "error": "unknown_card"}
	if card.zone != AhcEnums.Zone.ATTACHED or card.attached_to == null:
		return {"ok": false, "error": "not_location_attachment"}
	var from_id := _attached_location_id(game_ctx, card)
	if from_id == &"":
		return {"ok": false, "error": "not_at_location"}
	if game_ctx.state.registry.get_location(dest_id) == null:
		return {"ok": false, "error": "unknown_location"}
	if move_kind == KIND_MOVE:
		var conn_err := _reject_if_not_connected(game_ctx, from_id, dest_id)
		if conn_err != &"":
			return {"ok": false, "error": conn_err, "move_kind": move_kind}
	if from_id == dest_id:
		return _ok_skipped(SUBJECT_ATTACHMENT, card_id, from_id, dest_id, {
			"card_id": card_id,
			"attachment_id": card_id,
			"move_kind": move_kind,
		})
	var old_host := game_ctx.state.registry.get_card(card.attached_to.instance_id)
	if old_host == null:
		old_host = game_ctx.state.registry.get_card(card.attached_to.definition_id)
	if old_host != null:
		var idx := old_host.attachments.find(card.id)
		if idx >= 0:
			old_host.attachments.remove_at(idx)
	var new_host := game_ctx.state.registry.get_card(dest_id)
	if new_host == null:
		ScenarioLayoutSetup.materialize_card(
			game_ctx, dest_id, AhcEnums.Zone.LOCATION_AREA, &"loc", dest_id
		)
		new_host = game_ctx.state.registry.get_card(dest_id)
	if new_host == null:
		return {"ok": false, "error": "cannot_attach_destination"}
	card.zone = AhcEnums.Zone.ATTACHED
	card.attached_to = new_host.id
	if not new_host.attachments.has(card.id):
		new_host.attachments.append(card.id)
	_log_move(game_ctx, SUBJECT_ATTACHMENT, card_id, from_id, dest_id, {
		"move_kind": move_kind,
	})
	return _ok_moved(SUBJECT_ATTACHMENT, card_id, from_id, dest_id, {
		"card_id": card_id,
		"attachment_id": card_id,
		"move_kind": move_kind,
	})


static func _move_marker(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var dest_id := _destination(params)
	var from_id: StringName = params.get(
		"from_location", params.get("source_location", &"")
	) as StringName
	var amount: int = maxi(1, int(params.get("amount", 1)))
	var kind: int = int(params.get("marker_kind", AhcEnums.MarkerKind.CLUE))
	var move_kind := resolve_move_kind(params)
	if dest_id == &"" or from_id == &"":
		return {"ok": false, "error": "missing_from_or_destination"}
	var from_loc := game_ctx.state.registry.get_location(from_id)
	var dest_loc := game_ctx.state.registry.get_location(dest_id)
	if from_loc == null or dest_loc == null:
		return {"ok": false, "error": "unknown_location"}
	if move_kind == KIND_MOVE:
		var conn_err := _reject_if_not_connected(game_ctx, from_id, dest_id)
		if conn_err != &"":
			return {"ok": false, "error": conn_err, "move_kind": move_kind}
	if from_id == dest_id:
		return _ok_skipped(SUBJECT_MARKER, &"", from_id, dest_id, {
			"marker_kind": kind,
			"amount": amount,
			"move_kind": move_kind,
		})
	## 地点上的标记：Domain 以 LocationState.clues 承载；经 Transfer 搬运。
	if kind != AhcEnums.MarkerKind.CLUE and kind != int(AhcEnums.MarkerKind.CLUE):
		return {"ok": false, "error": "unsupported_location_marker"}
	if from_loc.clues < amount:
		return {"ok": false, "error": "insufficient_markers"}
	if game_ctx.mutator == null:
		return {"ok": false, "error": "no_mutator"}
	if not game_ctx.mutator.transfer_marker(
		AhcEnums.MarkerKind.CLUE,
		amount,
		MarkerSlot.location(from_id, AhcEnums.MarkerKind.CLUE),
		MarkerSlot.location(dest_id, AhcEnums.MarkerKind.CLUE)
	):
		return {"ok": false, "error": "transfer_failed"}
	_log_move(game_ctx, SUBJECT_MARKER, &"clue", from_id, dest_id, {
		"amount": amount,
		"move_kind": move_kind,
	})
	return _ok_moved(SUBJECT_MARKER, &"clue", from_id, dest_id, {
		"marker_kind": kind,
		"amount": amount,
		"from_location": from_id,
		"move_kind": move_kind,
	})


static func _auto_engage(params: Dictionary, default_val: bool) -> bool:
	if params.has("auto_engage_after"):
		return bool(params.get("auto_engage_after"))
	if params.has("auto_engage"):
		return bool(params.get("auto_engage"))
	return default_val


static func _attached_location_id(game_ctx: GameContext, card: CardInstance) -> StringName:
	if card == null or card.attached_to == null:
		return &""
	var host_id := card.attached_to.instance_id
	if game_ctx.state.registry.get_location(host_id) != null:
		return host_id
	if game_ctx.state.registry.get_location(card.attached_to.definition_id) != null:
		return card.attached_to.definition_id
	return host_id


static func _is_connected(from_loc: LocationState, to_id: StringName) -> bool:
	if from_loc.id == to_id:
		return true
	return from_loc.connections.has(to_id)


static func _reject_if_not_connected(
	game_ctx: GameContext,
	from_id: StringName,
	dest_id: StringName
) -> StringName:
	var current := game_ctx.state.registry.get_location(from_id)
	if current == null:
		return &"not_at_location"
	if not _is_connected(current, dest_id):
		return &"not_connected"
	return &""


static func _ok_skipped(
	subject: StringName,
	entity_id: StringName,
	from_id: StringName,
	dest_id: StringName,
	extra: Dictionary = {}
) -> Dictionary:
	var out := {
		"ok": true,
		"skipped": true,
		"moved": false,
		"subject": subject,
		"from": from_id,
		"to": dest_id,
		"destination_id": dest_id,
	}
	if entity_id != &"":
		out["entity_id"] = entity_id
	for k in extra:
		out[k] = extra[k]
	return out


static func _ok_moved(
	subject: StringName,
	entity_id: StringName,
	from_id: StringName,
	dest_id: StringName,
	extra: Dictionary = {}
) -> Dictionary:
	var out := {
		"ok": true,
		"moved": true,
		"subject": subject,
		"entity_id": entity_id,
		"from": from_id,
		"to": dest_id,
		"destination_id": dest_id,
	}
	for k in extra:
		out[k] = extra[k]
	return out


static func _log_move(
	game_ctx: GameContext,
	subject: StringName,
	entity_id: StringName,
	from_id: StringName,
	to_id: StringName,
	extra: Dictionary = {}
) -> void:
	if game_ctx.log == null:
		return
	var payload := {
		"subject": subject,
		"entity_id": entity_id,
		"from": from_id,
		"to": to_id,
	}
	for k in extra:
		payload[k] = extra[k]
	game_ctx.log.log(AhcEnums.LogCategory.SCENARIO, "effect:move", payload)
