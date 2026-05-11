extends Node
class_name IsoRoomLoader

const ISO_ROOM_ROOT := "res://scenes/iso/rooms"

static func get_circle0_combat_room_path(room_id: String = "ash_intake_hall_01") -> String:
	match room_id:
		"ash_intake_hall_01", "combat", "default":
			return "%s/circle0/combat_ash_intake_hall_01_iso.tscn" % ISO_ROOM_ROOT
		_:
			return "%s/circle0/combat_ash_intake_hall_01_iso.tscn" % ISO_ROOM_ROOT


static func load_room(path: String) -> PackedScene:
	if ResourceLoader.exists(path):
		return load(path) as PackedScene

	push_warning("IsoRoomLoader could not find room scene: %s" % path)
	return null


static func instantiate_room(path: String) -> Node2D:
	var scene := load_room(path)

	if scene == null:
		return null

	return scene.instantiate() as Node2D
