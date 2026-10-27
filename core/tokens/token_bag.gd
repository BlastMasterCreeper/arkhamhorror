class_name TokenBag
extends RefCounted

var damage: int = 0
var horror: int = 0
var doom: int = 0
var clue: int = 0
var uses: Dictionary = {}  # StringName -> int
## 封印在此卡上的混乱标记（与 ChaosBag.sealed_tokens 同步）。
var sealed: Array = []  # Array[ChaosToken]
