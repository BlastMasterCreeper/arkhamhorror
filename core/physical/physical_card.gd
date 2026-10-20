class_name PhysicalCard
extends RefCounted

## 物理层卡牌：所属卡区 + 外观态 + 卡上标记 counts。
## id = 运行时实体 id（PhysicalStore 分配）；definition_id = 牌面/目录编号。

var id: StringName = &""
var definition_id: StringName = &""
var region_id: StringName = &""
## 朝上的一面（翻面）；L0 揭示的物理写入落在此。
var face: AhcEnums.CardFace = AhcEnums.CardFace.A
var exhausted: bool = false
## flat 内渲染序；deck 不用。
var display_order: int = 0
## 谁可见牌面：信息层 FaceAudience；非 L0 揭示的物理语义。
var reveal_audience: AhcEnums.FaceAudience = AhcEnums.FaceAudience.HIDDEN_ALL
## 卡上标记：MarkerKey → int（0 省略）
var markers: Dictionary = {}
