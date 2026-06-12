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
var is_hidden: bool = false
var skill_icons: Dictionary = {}
var max_committed_per_test: int = -1
