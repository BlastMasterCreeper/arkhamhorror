class_name PhysicalCard
extends RefCounted

## 物理层卡牌：所属卡区 + 外观态 + 卡上标记 counts。

var id: StringName = &""
var definition_id: StringName = &""
var region_id: StringName = &""
var face: AhcEnums.CardFace = AhcEnums.CardFace.A
var exhausted: bool = false
## flat 内渲染序；deck 不用。
var display_order: int = 0
var reveal_audience: AhcEnums.FaceAudience = AhcEnums.FaceAudience.HIDDEN_ALL
## 卡上标记：MarkerKey → int（0 省略）
var markers: Dictionary = {}
