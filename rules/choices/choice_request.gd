class_name ChoiceRequest
extends RefCounted

## 玩家交互请求。见 docs/design/16-player-interaction.md

var kind: AhcEnums.ChoiceKind = AhcEnums.ChoiceKind.PICK_OPTION
var decider_id: StringName = &""
var prompt_id: StringName = &""
var prompt: String = ""
var options: Array = []
var min_picks: int = 1
var max_picks: int = 1
var context: Dictionary = {}
var default_index: int = 0
