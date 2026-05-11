extends Node2D

signal room_choice_requested(room_type: String)

@export var interaction_radius: float = 78.0
@export var sprite_scale: Vector2 = Vector2(2, 2)

var room_type := "combat"
var display_name := "Combat"
var orientation := "north"

var player: Node2D = null
var player_near := false
var pulse_time := 0.0

var door_sprite: Sprite2D = null
var room_label: Label = null
var prompt_label: Label = null


func setup(new_room_type: String, new_orientation: String = "north") -> void:
	room_type = new_room_type
	orientation = _normalize_orientation(new_orientation)

	if RunState.has_method("get_room_display_name"):
		display_name = RunState.get_room_display_name(room_type)
	else:
		display_name = room_type.capitalize()

	_refresh_visuals()


func _ready() -> void:
	add_to_group("choice_door")
	z_index = 160

	_build_nodes()
	_refresh_visuals()
	set_process(true)


func _process(delta: float) -> void:
	pulse_time += delta

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D

	player_near = false

	if player != null:
		player_near = global_position.distance_to(player.global_position) <= interaction_radius

		if player_near and _is_interact_pressed():
			room_choice_requested.emit(room_type)

	_update_visual_state()


func _is_interact_pressed() -> bool:
	if InputMap.has_action("interact") and Input.is_action_just_pressed("interact"):
		return true

	return Input.is_physical_key_pressed(KEY_E)


func _build_nodes() -> void:
	if door_sprite == null:
		door_sprite = get_node_or_null("DoorSprite") as Sprite2D

	if door_sprite == null:
		door_sprite = Sprite2D.new()
		door_sprite.name = "DoorSprite"
		add_child(door_sprite)

	door_sprite.centered = true
	door_sprite.scale = sprite_scale

	if room_label == null:
		room_label = get_node_or_null("RoomLabel") as Label

	if room_label == null:
		room_label = Label.new()
		room_label.name = "RoomLabel"
		room_label.size = Vector2(156, 24)
		room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		room_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(room_label)

	if prompt_label == null:
		prompt_label = get_node_or_null("PromptLabel") as Label

	if prompt_label == null:
		prompt_label = Label.new()
		prompt_label.name = "PromptLabel"
		prompt_label.size = Vector2(132, 24)
		prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(prompt_label)

	prompt_label.visible = false


func _refresh_visuals() -> void:
	if door_sprite == null:
		return

	_load_texture_for_current_depth()
	_position_labels()

	var color := _get_room_color()

	if room_label != null:
		room_label.text = display_name
		room_label.add_theme_font_size_override("font_size", 14)
		room_label.add_theme_color_override("font_color", color)
		room_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
		room_label.add_theme_constant_override("shadow_offset_x", 2)
		room_label.add_theme_constant_override("shadow_offset_y", 2)

	if prompt_label != null:
		prompt_label.text = "Press E"
		prompt_label.add_theme_font_size_override("font_size", 13)
		prompt_label.add_theme_color_override("font_color", Color("#f7e8d4"))
		prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
		prompt_label.add_theme_constant_override("shadow_offset_x", 2)
		prompt_label.add_theme_constant_override("shadow_offset_y", 2)


func _load_texture_for_current_depth() -> void:
	if door_sprite == null:
		return

	var tier: int = _get_hell_tier()
	var visual_orientation := orientation

	# We do not have a true south-facing row yet.
	# Use the north/front-facing door as fallback.
	if visual_orientation == "south":
		visual_orientation = "north"

	var path := "res://art/props/room_doors/circle_%02d_%s.png" % [tier, visual_orientation]

	if not ResourceLoader.exists(path):
		path = "res://art/props/room_doors/circle_01_%s.png" % visual_orientation

	if not ResourceLoader.exists(path):
		path = "res://art/props/room_doors/circle_01_north.png"

	if not ResourceLoader.exists(path):
		push_warning("Missing room door asset. Expected res://art/props/room_doors/circle_XX_orientation.png")
		return

	var texture := load(path) as Texture2D

	if texture != null:
		door_sprite.texture = texture


func _get_hell_tier() -> int:
	if room_type == RunState.ROOM_BOSS:
		return 5

	var depth: int = 1

	if _object_has_property(RunState, "depth"):
		depth = int(RunState.get("depth"))

	if depth <= 2:
		return 1
	elif depth <= 4:
		return 2
	elif depth <= 6:
		return 3
	elif depth <= 8:
		return 4

	return 5


func _normalize_orientation(value: String) -> String:
	match value:
		"north", "east", "west", "south":
			return value
		_:
			return "north"


func _position_labels() -> void:
	if room_label == null or prompt_label == null:
		return

	match orientation:
		"north":
			room_label.position = Vector2(-78, 88)
			prompt_label.position = Vector2(-66, 112)

		"east":
			room_label.position = Vector2(-98, 72)
			prompt_label.position = Vector2(-86, 96)

		"west":
			room_label.position = Vector2(-58, 72)
			prompt_label.position = Vector2(-46, 96)

		_:
			room_label.position = Vector2(-78, 88)
			prompt_label.position = Vector2(-66, 112)


func _update_visual_state() -> void:
	var pulse := 0.78 + 0.18 * absf(sin(pulse_time * 3.0))

	if door_sprite != null:
		if player_near:
			door_sprite.modulate = Color(1.0, 0.92 + pulse * 0.08, 0.82 + pulse * 0.10, 1.0)
			door_sprite.scale = sprite_scale * 1.04
		else:
			door_sprite.modulate = Color.WHITE
			door_sprite.scale = sprite_scale

	if prompt_label != null:
		prompt_label.visible = player_near


func _get_room_color() -> Color:
	match room_type:
		RunState.ROOM_COMBAT:
			return Color("#dfaa46")
		RunState.ROOM_UPGRADE:
			return Color("#9ed8cd")
		RunState.ROOM_SHOP:
			return Color("#7fdc54")
		RunState.ROOM_FORGE:
			return Color("#ff684a")
		RunState.ROOM_SHRINE:
			return Color("#b49ce2")
		RunState.ROOM_ELITE:
			return Color("#b49ce2")
		RunState.ROOM_MINIBOSS:
			return Color("#ff8a4c")
		RunState.ROOM_BOSS:
			return Color("#ff321f")
		RunState.ROOM_FOUNTAIN:
			return Color("#8fd8ff")
		_:
			return Color("#f7e8d4")


func _object_has_property(object: Object, property_name: String) -> bool:
	if object == null:
		return false

	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true

	return false
