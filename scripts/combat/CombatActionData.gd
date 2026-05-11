extends Resource
class_name CombatActionData

@export var action_id: String = ""
@export var action_type: String = "attack"
@export var display_name: String = "Action"
@export var weapon_id: String = ""
@export var weapon_name: String = ""
@export var tags: Array[String] = []
@export var damage: float = 0.0
@export var radius: float = 0.0
@export var startup: float = 0.0
@export var active_time: float = 0.0
@export var recovery: float = 0.0


func has_tag(tag: String) -> bool:
	var normalized: String = tag.strip_edges().to_lower()

	for value in tags:
		if str(value).strip_edges().to_lower() == normalized:
			return true

	return false


func to_dictionary() -> Dictionary:
	return {
		"action_id": action_id,
		"action_type": action_type,
		"display_name": display_name,
		"weapon_id": weapon_id,
		"weapon_name": weapon_name,
		"tags": tags.duplicate(),
		"damage": damage,
		"radius": radius,
		"startup": startup,
		"active_time": active_time,
		"recovery": recovery
	}
