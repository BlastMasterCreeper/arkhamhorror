class_name CardInstance
extends RefCounted

var id: EntityId
var owner_id: StringName = &""
var controller_id: StringName = &""
var zone: AhcEnums.Zone = AhcEnums.Zone.DECK
var zone_index: int = 0
var face: AhcEnums.CardFace = AhcEnums.CardFace.A
var exhausted: bool = false
var tokens: TokenBag = TokenBag.new()
var attachments: Array[EntityId] = []
var attached_to: EntityId = null
var lasting_effect_ids: Array[StringName] = []
var is_hidden: bool = false  ## 隐私（Hidden）关键词 · E4 秘密入手后为 true；expose 后 false
var face_visibility: CardFaceVisibility = CardFaceVisibility.new()
var skill_icons: Dictionary = {}
## @deprecated 优先 CardRegistry.limit_specs COMMIT_MAX；保留作竖切别名。
var max_committed_per_test: int = -1
## 进场世代：leave→re-enter 后 Limit per period 视为新实例（与 instance_id 组合）。
var limit_play_gen: int = 0


func face_known_to(observer: StringName) -> bool:
	return face_visibility.face_known_to(self, observer)


func limit_instance_key() -> StringName:
	if id == null:
		return &""
	return StringName("%s#%d" % [String(id.instance_id), limit_play_gen])
