class_name CardFaceVisibility
extends RefCounted

var audience: AhcEnums.FaceAudience = AhcEnums.FaceAudience.HIDDEN_ALL


func face_known_to(card: CardInstance, observer: StringName) -> bool:
	if card == null or observer == &"":
		return false
	match audience:
		AhcEnums.FaceAudience.HIDDEN_ALL:
			return false
		AhcEnums.FaceAudience.CONTROLLER:
			var controller := card.controller_id
			if controller == &"":
				controller = card.owner_id
			return controller == observer
		AhcEnums.FaceAudience.ALL:
			return true
	return false
