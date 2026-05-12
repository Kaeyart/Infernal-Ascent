extends CharacterBody2D
class_name IsoPhysicsTestPlayer

@export var move_speed: float = 260.0
@export var attack_radius: float = 82.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 0.28

@export_category("Collision")
@export var auto_create_collision_shape: bool = true
@export var collision_radius: float = 10.0
@export var collision_offset: Vector2 = Vector2(0.0, 8.0)
@export var physics_safe_margin: float = 0.001

@export_category("Visuals")
@export var use_sprite_visuals: bool = true
@export var show_debug_footprint: bool = false
@export var show_fallback_drawn_body: bool = false
@export var visual_offset: Vector2 = Vector2(0.0, -36.0)
@export var visual_scale: Vector2 = Vector2(1.0, 1.0)
@export var frame_size: Vector2i = Vector2i(64, 80)
@export var idle_sheet_path: String = "res://art/iso/player/penitent_v1/penitent_idle_4x1.png"
@export var walk_sheet_path: String = "res://art/iso/player/penitent_v1/penitent_walk_4x1.png"
@export var attack_sheet_path: String = "res://art/iso/player/penitent_v1/penitent_attack_4x1.png"
@export var animation_fps: float = 8.0

var facing: Vector2 = Vector2.DOWN

var _attack_cooldown_remaining: float = 0.0
var _attack_flash_remaining: float = 0.0
var _space_previous: bool = false
var _mouse_previous: bool = false

var _visual_root: Node2D = null
var _sprite: Sprite2D = null
var _current_anim: String = "idle"
var _frame_index: int = 0
var _frame_timer: float = 0.0
var _idle_texture: Texture2D = null
var _walk_texture: Texture2D = null
var _attack_texture: Texture2D = null

func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	safe_margin = physics_safe_margin

	if auto_create_collision_shape:
		_ensure_collision_shape()

	if use_sprite_visuals:
		_ensure_visual_rig()
		_load_visual_textures()

	queue_redraw()

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	var was_moving: bool = _update_movement()
	_update_attack_input()
	_update_visual_animation(delta, was_moving)
	queue_redraw()

func _update_timers(delta: float) -> void:
	if _attack_cooldown_remaining > 0.0:
		_attack_cooldown_remaining = maxf(0.0, _attack_cooldown_remaining - delta)
	if _attack_flash_remaining > 0.0:
		_attack_flash_remaining = maxf(0.0, _attack_flash_remaining - delta)

func _update_movement() -> bool:
	var input_vector: Vector2 = _read_movement_input()
	var moving: bool = input_vector.length() > 0.01

	if moving:
		input_vector = input_vector.normalized()
		facing = input_vector
		velocity = input_vector * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	return moving

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
	_attack_flash_remaining = 0.16
	_set_animation("attack")

	var enemies: Array[Node] = get_tree().get_nodes_in_group("iso_test_enemy")
	for enemy_node: Node in enemies:
		if enemy_node is IsoTestEnemy:
			var test_enemy: IsoTestEnemy = enemy_node as IsoTestEnemy
			if not test_enemy.is_dead and global_position.distance_to(test_enemy.global_position) <= attack_radius:
				test_enemy.take_damage(attack_damage)

func _update_visual_animation(delta: float, moving: bool) -> void:
	if not use_sprite_visuals or _sprite == null:
		return

	if _attack_flash_remaining > 0.0:
		_set_animation("attack")
	elif moving:
		_set_animation("walk")
	else:
		_set_animation("idle")

	_frame_timer += delta
	var frame_duration: float = 1.0 / maxf(animation_fps, 1.0)
	if _frame_timer >= frame_duration:
		_frame_timer = 0.0
		_frame_index = (_frame_index + 1) % 4
		_apply_sprite_frame()

	if abs(facing.x) > 0.05:
		_sprite.flip_h = facing.x < 0.0

func _set_animation(anim_name: String) -> void:
	if _current_anim == anim_name:
		return
	_current_anim = anim_name
	_frame_index = 0
	_frame_timer = 0.0
	_apply_sprite_frame()

func _apply_sprite_frame() -> void:
	if _sprite == null:
		return

	var texture: Texture2D = _get_texture_for_current_animation()
	if texture == null:
		_sprite.visible = false
		return

	_sprite.visible = true
	_sprite.texture = texture
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(
		Vector2(float(_frame_index * frame_size.x), 0.0),
		Vector2(float(frame_size.x), float(frame_size.y))
	)

func _get_texture_for_current_animation() -> Texture2D:
	if _current_anim == "walk":
		return _walk_texture if _walk_texture != null else _idle_texture
	if _current_anim == "attack":
		return _attack_texture if _attack_texture != null else _idle_texture
	return _idle_texture

func _ensure_visual_rig() -> void:
	_visual_root = get_node_or_null("VisualRoot") as Node2D
	if _visual_root == null:
		_visual_root = Node2D.new()
		_visual_root.name = "VisualRoot"
		add_child(_visual_root)

	_visual_root.position = visual_offset
	_visual_root.scale = visual_scale

	_sprite = _visual_root.get_node_or_null("PenitentSprite") as Sprite2D
	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.name = "PenitentSprite"
		_visual_root.add_child(_sprite)

	_sprite.centered = true
	_sprite.position = Vector2.ZERO
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _load_visual_textures() -> void:
	_idle_texture = _load_texture_if_exists(idle_sheet_path)
	_walk_texture = _load_texture_if_exists(walk_sheet_path)
	_attack_texture = _load_texture_if_exists(attack_sheet_path)

	if _idle_texture == null:
		push_warning("[IsoPhysicsTestPlayer] Missing idle visual texture: " + idle_sheet_path)
	else:
		_apply_sprite_frame()

func _load_texture_if_exists(path: String) -> Texture2D:
	if path.strip_edges() == "":
		return null
	if not ResourceLoader.exists(path):
		return null
	var resource: Resource = load(path)
	if resource is Texture2D:
		return resource as Texture2D
	return null

func _draw() -> void:
	_draw_filled_ellipse(Rect2(Vector2(-20.0, 10.0), Vector2(40.0, 13.0)), Color(0.0, 0.0, 0.0, 0.34))

	if _attack_flash_remaining > 0.0:
		draw_circle(Vector2.ZERO, attack_radius, Color(0.85, 0.62, 0.34, 0.10))
		draw_arc(Vector2.ZERO, attack_radius, 0.0, TAU, 64, Color(0.95, 0.80, 0.48, 0.72), 2.0)

	if show_debug_footprint:
		draw_arc(collision_offset, collision_radius, 0.0, TAU, 24, Color(0.3, 0.75, 1.0, 0.65), 1.0)

	if show_fallback_drawn_body or not use_sprite_visuals or _idle_texture == null:
		_draw_fallback_body()

func _draw_fallback_body() -> void:
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

func _ensure_collision_shape() -> void:
	for child_node: Node in get_children():
		if child_node is CollisionShape2D:
			var existing_shape: CollisionShape2D = child_node as CollisionShape2D
			if existing_shape.shape is CircleShape2D:
				(existing_shape.shape as CircleShape2D).radius = collision_radius
				existing_shape.position = collision_offset
				return
			if existing_shape.shape != null:
				return

	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.position = collision_offset

	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = collision_radius
	collision_shape.shape = circle_shape

	add_child(collision_shape)

func _draw_filled_ellipse(rect: Rect2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(24):
		var angle: float = TAU * float(i) / 24.0
		points.append(rect.position + rect.size * 0.5 + Vector2(cos(angle) * rect.size.x * 0.5, sin(angle) * rect.size.y * 0.5))
	draw_colored_polygon(points, color)
