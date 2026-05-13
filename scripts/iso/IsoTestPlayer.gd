extends Node2D
class_name IsoTestPlayer

@export var move_speed: float = 260.0
@export var room_min: Vector2 = Vector2(220.0, 180.0)
@export var room_max: Vector2 = Vector2(1060.0, 625.0)
@export var attack_radius: float = 82.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 0.28

var facing: Vector2 = Vector2.DOWN
var _attack_cooldown_remaining: float = 0.0
var _attack_flash_remaining: float = 0.0
var _space_previous: bool = false
var _mouse_previous: bool = false

func _ready() -> void:
	add_to_group("player")
	queue_redraw()

func _process(delta: float) -> void:
	_update_timers(delta)
	_update_movement(delta)
	_update_attack_input()
	queue_redraw()

func _update_timers(delta: float) -> void:
	if _attack_cooldown_remaining > 0.0:
		_attack_cooldown_remaining = maxf(0.0, _attack_cooldown_remaining - delta)
	if _attack_flash_remaining > 0.0:
		_attack_flash_remaining = maxf(0.0, _attack_flash_remaining - delta)

func _update_movement(delta: float) -> void:
	var input_vector: Vector2 = _read_movement_input()
	if input_vector.length() > 0.01:
		input_vector = input_vector.normalized()
		facing = input_vector
		position += input_vector * move_speed * delta
		position.x = clamp(position.x, room_min.x, room_max.x)
		position.y = clamp(position.y, room_min.y, room_max.y)

func _update_attack_input() -> void:
	var space_down: bool = Input.is_physical_key_pressed(KEY_SPACE)
	var mouse_down: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var attack_pressed: bool = (space_down and not _space_previous) or (mouse_down and not _mouse_previous)
	_space_previous = space_down
	_mouse_previous = mouse_down

	if attack_pressed and _attack_cooldown_remaining <= 0.0:
		_perform_attack()

func _perform_attack() -> void:
	_attack_cooldown_remaining = attack_cooldown
	_attack_flash_remaining = 0.12

	var enemies: Array[Node] = get_tree().get_nodes_in_group("iso_test_enemy")
	for enemy_node: Node in enemies:
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if not enemy_node is Node2D:
			continue
		if not enemy_node.has_method("take_damage"):
			continue

		var enemy_position: Vector2 = (enemy_node as Node2D).global_position
		var enemy_is_dead: bool = false
		if "is_dead" in enemy_node:
			enemy_is_dead = bool(enemy_node.get("is_dead"))

		if not enemy_is_dead and global_position.distance_to(enemy_position) <= attack_radius:
			enemy_node.call("take_damage", attack_damage)

func _draw() -> void:
	var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.32)
	_draw_filled_ellipse(Rect2(Vector2(-18.0, 10.0), Vector2(36.0, 12.0)), shadow_color)

	if _attack_flash_remaining > 0.0:
		draw_circle(Vector2.ZERO, attack_radius, Color(0.85, 0.62, 0.34, 0.12))
		draw_arc(Vector2.ZERO, attack_radius, 0.0, TAU, 64, Color(0.95, 0.80, 0.48, 0.75), 2.0)

	var cape_color: Color = Color("#6d1d1d")
	var armor_color: Color = Color("#1c2025")
	var trim_color: Color = Color("#d1a45b")
	var blade_color: Color = Color("#d9d2c0")

	var body: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -34.0),
		Vector2(17.0, -10.0),
		Vector2(10.0, 16.0),
		Vector2(-10.0, 16.0),
		Vector2(-17.0, -10.0),
	])

	draw_colored_polygon(PackedVector2Array([
		Vector2(-16.0, -8.0),
		Vector2(-4.0, -2.0),
		Vector2(-6.0, 20.0),
		Vector2(-22.0, 24.0),
	]), cape_color)

	draw_colored_polygon(body, armor_color)
	draw_polyline(PackedVector2Array([body[0], body[1], body[2], body[3], body[4], body[0]]), trim_color, 2.0)
	draw_circle(Vector2(0.0, -38.0), 9.0, Color("#101216"))
	draw_arc(Vector2(0.0, -38.0), 11.0, 0.0, TAU, 24, trim_color, 1.5)

	var blade_end: Vector2 = Vector2(22.0, -6.0)
	if abs(facing.x) > abs(facing.y):
		var horizontal_sign: float = 1.0
		if facing.x < 0.0:
			horizontal_sign = -1.0
		blade_end = Vector2(30.0 * horizontal_sign, -8.0)
	elif facing.y < 0.0:
		blade_end = Vector2(9.0, -46.0)
	else:
		blade_end = Vector2(18.0, 18.0)

	draw_line(Vector2(8.0, -8.0), blade_end, blade_color, 3.0)
	draw_circle(Vector2(8.0, -8.0), 3.0, trim_color)

	var hp_back: Rect2 = Rect2(Vector2(-24.0, -58.0), Vector2(48.0, 5.0))
	draw_rect(hp_back, Color(0.0, 0.0, 0.0, 0.60), true)
	draw_rect(Rect2(hp_back.position + Vector2(1.0, 1.0), Vector2(46.0, 3.0)), Color("#a83d32"), true)

func _read_movement_input() -> Vector2:
	var input_vector: Vector2 = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		input_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		input_vector.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		input_vector.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		input_vector.y += 1.0
	return input_vector

func _draw_filled_ellipse(rect: Rect2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(24):
		var angle: float = TAU * float(i) / 24.0
		points.append(rect.position + rect.size * 0.5 + Vector2(cos(angle) * rect.size.x * 0.5, sin(angle) * rect.size.y * 0.5))
	draw_colored_polygon(points, color)
