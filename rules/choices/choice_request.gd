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
## first_option / skip / lead_tiebreak（21 · 16 §3.1）；空则从 context 或按 kind 推断。
var default_policy: StringName = &""
## >0 = UI 有限期（毫秒，本切片不实现倒计时）；-1 = 立即走默认自动选用。
var deadline_ms: int = -1


## 解析后的默认策略（请求字段优先，否则 context，再按 kind）。
func resolved_default_policy() -> StringName:
	if default_policy != &"":
		return default_policy
	if typeof(context) == TYPE_DICTIONARY and context.has("default_policy"):
		var raw: Variant = context["default_policy"]
		if str(raw) != "":
			return StringName(str(raw))
	match kind:
		AhcEnums.ChoiceKind.OPTIONAL_EFFECT, AhcEnums.ChoiceKind.USE_ABILITY:
			return &"skip" if default_index <= 0 else &"first_option"
		AhcEnums.ChoiceKind.PICK_MULTI:
			return &"skip" if min_picks <= 0 else &"first_option"
		_:
			return &"first_option"
