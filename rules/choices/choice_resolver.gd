class_name ChoiceResolver
extends RefCounted

## Headless / UI shared interface for player decisions.

func resolve(request: ChoiceRequest) -> Variant:
	push_warning("ChoiceResolver.resolve not implemented: %s" % request.prompt)
	if request.options.is_empty():
		return null
	return request.options[0]
