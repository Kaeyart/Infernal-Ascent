extends CharacterBody2D

class_name IsoPhysicsTestPlayer

@export var move_speed: float = 260.0
@export var attack_radius: float = 82.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 0.28
@export var heavy_attack_damage: int = 2
@export var heavy_attack_cooldown: float = 0.52
@export var heavy_attack_radius_multiplier: float = 1.15

@export_category("Collision")
@export var auto_create_collision_shape: bool = true
@export var collision_radius: float = 10.0
@export var collision_offset: Vector2 = Vector2(0.0, 8.0)
@export var physics_safe_margin: float = 0.001

@export_category("Dash")
@export var enable_dash: bool = true
@export var dash_speed_multiplier: float = 3.0
@export var dash_duration: float = 0.13
@export var dash_cooldown: float = 0.48

@export_category("Visuals")
@export var use_sprite_visuals: bool = true
@export var show_debug_footprint: bool = false
@export var show_fallback_drawn_body: bool = false
@export var visual_offset: Vector2 = Vector2(0.0, -30.0)
@export var visual_scale: Vector2 = Vector2(0.42, 0.42)
@export var auto_detect_sprite_frame_size: bool = true
@export var frame_size: Vector2i = Vector2i(320, 320)
@export var direction_row_count: int = 4
@export var idle_sheet_path: String = "res://art/iso/player/penitent_v1/penitent_idle_iso_4x4.png"
@export var walk_sheet_path: String = "res://art/iso/player/penitent_v1/penitent_walk_iso_6x4.png"
@export var attack_sheet_path: String = "res://art/iso/player/penitent_v1/penitent_light_attack_iso_5x4.png"
@export var dash_sheet_path: String = "res://art/iso/player/penitent_v1/penitent_dash_iso_4x4.png"
@export var hit_sheet_path: String = "res://art/iso/player/penitent_v1/penitent_hit_iso_3x4.png"
@export var death_sheet_path: String = "res://art/iso/player/penitent_v1/penitent_death_iso_6x4.png"
@export var respawn_sheet_path: String = "res://art/iso/player/penitent_v1/penitent_respawn_iso_6x4.png"
@export var heavy_attack_sheet_path: String = "res://art/iso/player/penitent_v1/penitent_heavy_attack_iso_6x4.png"
@export var animation_fps: float = 8.0
@export var attack_animation_fps: float = 12.0
@export var heavy_attack_animation_fps: float = 10.0
@export var dash_animation_fps: float = 16.0
@export var hit_animation_fps: float = 12.0
@export var death_animation_fps: float = 8.0
@export var respawn_animation_fps: float = 8.0

@export_category("Animation Row Mapping")
# V6 uses deterministic screen-input facing:
#   D / Right        -> northeast row by default
#   A / Left         -> southwest row by default
#   W / Up           -> northwest row by default
#   S / Down         -> southeast row by default
# Diagonal input maps to the matching isometric quadrant.
# If a row still looks wrong in-game, change only these exported row values.
@export var row_for_southeast: int = 0
@export var row_for_southwest: int = 1
@export var row_for_northwest: int = 2
@export var row_for_northeast: int = 3
@export var attack_aims_at_mouse: bool = true
@export var keyboard_attack_faces_nearest_target: bool = true
@export var nearest_target_face_radius_multiplier: float = 1.55

var facing: Vector2 = Vector2(1.0, 1.0).normalized()

var _attack_cooldown_remaining: float = 0.0
var _attack_flash_remaining: float = 0.0
var _heavy_attack_cooldown_remaining: float = 0.0
var _dash_cooldown_remaining: float = 0.0
var _dash_remaining: float = 0.0
var _dash_direction: Vector2 = Vector2(1.0, 1.0).normalized()
var _animation_lock_remaining: float = 0.0

var _space_previous: bool = false
var _mouse_previous: bool = false
var _heavy_previous: bool = false
var _dash_previous: bool = false

var _visual_root: Node2D = null
var _sprite: Sprite2D = null
var _current_anim: String = "idle"
var _frame_index: int = 0
var _frame_timer: float = 0.0
var _locked_anim: String = ""
var _locked_priority: int = 0
var _locked_holds_final_frame: bool = false
var _is_dead: bool = false
var _moving_this_frame: bool = false
var _facing_dir_name: String = "se"

var _idle_texture: Texture2D = null
var _walk_texture: Texture2D = null
var _attack_texture: Texture2D = null
var _dash_texture: Texture2D = null
var _hit_texture: Texture2D = null
var _death_texture: Texture2D = null
var _respawn_texture: Texture2D = null
var _heavy_attack_texture: Texture2D = null

const _PRIORITY_NONE: int = 0
const _PRIORITY_DASH: int = 60
const _PRIORITY_ATTACK: int = 70
const _PRIORITY_HEAVY_ATTACK: int = 75
const _PRIORITY_HIT: int = 85
const _PRIORITY_RESPAWN: int = 95
const _PRIORITY_DEATH: int = 100

const _ANIM_FRAMES: Dictionary = {
	"idle": 4,
	"walk": 6,
	"attack": 5,
	"heavy_attack": 6,
	"dash": 4,
	"hit": 3,
	"death": 6,
	"respawn": 6,
}

func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	safe_margin = physics_safe_margin
	if auto_create_collision_shape:
		_ensure_collision_shape()
	_set_facing_from_vector(facing)
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
	if _heavy_attack_cooldown_remaining > 0.0:
		_heavy_attack_cooldown_remaining = maxf(0.0, _heavy_attack_cooldown_remaining - delta)
	if _dash_cooldown_remaining > 0.0:
		_dash_cooldown_remaining = maxf(0.0, _dash_cooldown_remaining - delta)
	if _dash_remaining > 0.0:
		_dash_remaining = maxf(0.0, _dash_remaining - delta)
	if _attack_flash_remaining > 0.0:
		_attack_flash_remaining = maxf(0.0, _attack_flash_remaining - delta)
	if _animation_lock_remaining > 0.0:
		_animation_lock_remaining = maxf(0.0, _animation_lock_remaining - delta)

func _update_movement() -> bool:
	if _is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		_moving_this_frame = false
		return false

	var input_vector: Vector2 = _read_movement_input()
	var moving: bool = input_vector.length() > 0.01

	if moving:
		input_vector = input_vector.normalized()
		_set_facing_from_vector(input_vector)

	_update_dash_input(input_vector if moving else facing)

	if _dash_remaining > 0.0:
		velocity = _dash_direction * move_speed * dash_speed_multiplier
		move_and_slide()
		_moving_this_frame = true
		return true

	if moving:
		velocity = input_vector * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_moving_this_frame = moving
	return moving

func _update_dash_input(direction: Vector2) -> void:
	if not enable_dash:
		return
	if _is_dead:
		return
	var dash_down: bool = Input.is_physical_key_pressed(KEY_SHIFT)
	var dash_pressed: bool = dash_down and not _dash_previous
	_dash_previous = dash_down
	if dash_pressed and _dash_cooldown_remaining <= 0.0 and _dash_remaining <= 0.0:
		_start_dash(direction)

func _start_dash(direction: Vector2) -> void:
	if not _can_start_action(_PRIORITY_DASH):
		return
	_dash_direction = direction.normalized() if direction.length() > 0.01 else facing.normalized()
	if _dash_direction.length() <= 0.01:
		_dash_direction = Vector2(1.0, 1.0).normalized()
	_set_facing_from_vector(_dash_direction)
	_dash_remaining = dash_duration
	_dash_cooldown_remaining = dash_cooldown
	_lock_animation("dash", _PRIORITY_DASH, _get_animation_duration("dash"), false, false)

func _update_attack_input() -> void:
	if _is_dead:
		_space_previous = Input.is_physical_key_pressed(KEY_SPACE)
		_mouse_previous = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		_heavy_previous = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_physical_key_pressed(KEY_F)
		return

	var space_down: bool = Input.is_physical_key_pressed(KEY_SPACE)
	var mouse_down: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var heavy_down: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_physical_key_pressed(KEY_F)

	var light_pressed: bool = (space_down and not _space_previous) or (mouse_down and not _mouse_previous)
	var heavy_pressed: bool = heavy_down and not _heavy_previous

	_space_previous = space_down
	_mouse_previous = mouse_down
	_heavy_previous = heavy_down

	if heavy_pressed and _heavy_attack_cooldown_remaining <= 0.0:
		_face_for_attack(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))
		_perform_attack("heavy_attack", heavy_attack_damage, heavy_attack_cooldown, heavy_attack_radius_multiplier)
	elif light_pressed and _attack_cooldown_remaining <= 0.0:
		_face_for_attack(mouse_down)
		_perform_attack("attack", attack_damage, attack_cooldown, 1.0)

func _face_for_attack(mouse_attack: bool) -> void:
	if mouse_attack and attack_aims_at_mouse:
		var mouse_vector: Vector2 = get_global_mouse_position() - global_position
		if mouse_vector.length() > 0.01:
			_set_facing_from_vector(mouse_vector)
			return
	if keyboard_attack_faces_nearest_target:
		var nearest_target: Node2D = _find_nearest_attack_target(attack_radius * nearest_target_face_radius_multiplier)
		if nearest_target != null:
			_set_facing_from_vector(nearest_target.global_position - global_position)

func _perform_attack(anim_name: String = "attack", damage_amount: int = 1, cooldown: float = 0.28, radius_multiplier: float = 1.0) -> void:
	var priority: int = _PRIORITY_HEAVY_ATTACK if anim_name == "heavy_attack" else _PRIORITY_ATTACK
	if not _can_start_action(priority):
		return

	if anim_name == "heavy_attack":
		_heavy_attack_cooldown_remaining = cooldown
		_attack_flash_remaining = 0.26
		_lock_animation("heavy_attack", priority, _get_animation_duration("heavy_attack"), false, false)
	else:
		_attack_cooldown_remaining = cooldown
		_attack_flash_remaining = 0.18
		_lock_animation("attack", priority, _get_animation_duration("attack"), false, false)

	var active_radius: float = attack_radius * radius_multiplier
	var targets: Dictionary = {}
	for enemy_node: Node in get_tree().get_nodes_in_group("iso_test_enemy"):
		targets[enemy_node] = true
	for training_node: Node in get_tree().get_nodes_in_group("attack_target"):
		targets[training_node] = true

	for target_value: Variant in targets.keys():
		if not (target_value is Node2D):
			continue
		var target: Node2D = target_value as Node2D
		if not is_instance_valid(target):
			continue
		if not target.has_method("take_damage"):
			continue
		if global_position.distance_to(target.global_position) <= active_radius:
			target.call("take_damage", damage_amount)

func _find_nearest_attack_target(max_distance: float) -> Node2D:
	var nearest_target: Node2D = null
	var nearest_distance: float = max_distance
	var targets: Array[Node] = []
	targets.append_array(get_tree().get_nodes_in_group("iso_test_enemy"))
	targets.append_array(get_tree().get_nodes_in_group("attack_target"))
	for node: Node in targets:
		if not (node is Node2D):
			continue
		var target: Node2D = node as Node2D
		if not is_instance_valid(target):
			continue
		var distance: float = global_position.distance_to(target.global_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_target = target
	return nearest_target

func take_damage(_amount: int = 1) -> void:
	if _is_dead:
		return
	_lock_animation("hit", _PRIORITY_HIT, _get_animation_duration("hit"), false, false)

func play_death_animation() -> void:
	_is_dead = true
	velocity = Vector2.ZERO
	_dash_remaining = 0.0
	_lock_animation("death", _PRIORITY_DEATH, _get_animation_duration("death"), true, true)

func play_respawn_animation() -> void:
	_is_dead = false
	_lock_animation("respawn", _PRIORITY_RESPAWN, _get_animation_duration("respawn"), false, true)

func _update_visual_animation(delta: float, moving: bool) -> void:
	if not use_sprite_visuals or _sprite == null:
		return

	_resolve_expired_animation_lock()

	if _locked_anim == "":
		if moving:
			_set_animation("walk")
		else:
			_set_animation("idle")

	_advance_animation_frame(delta)
	_sprite.flip_h = false

func _resolve_expired_animation_lock() -> void:
	if _locked_anim == "":
		return
	if _animation_lock_remaining > 0.0:
		return
	if _locked_holds_final_frame:
		_frame_index = _get_frame_count(_current_anim) - 1
		_apply_sprite_frame()
		return
	_locked_anim = ""
	_locked_priority = _PRIORITY_NONE
	_locked_holds_final_frame = false

func _advance_animation_frame(delta: float) -> void:
	_frame_timer += delta
	var frame_duration: float = 1.0 / maxf(_get_animation_fps(_current_anim), 1.0)
	if _frame_timer < frame_duration:
		return
	while _frame_timer >= frame_duration:
		_frame_timer -= frame_duration
		var frames: int = _get_frame_count(_current_anim)
		if _is_one_shot_animation(_current_anim):
			_frame_index = mini(_frame_index + 1, frames - 1)
		else:
			_frame_index = (_frame_index + 1) % frames
	_apply_sprite_frame()

func _is_one_shot_animation(anim_name: String) -> bool:
	return anim_name == "attack" or anim_name == "heavy_attack" or anim_name == "dash" or anim_name == "hit" or anim_name == "death" or anim_name == "respawn"

func _get_animation_fps(anim_name: String) -> float:
	if anim_name == "dash":
		return dash_animation_fps
	if anim_name == "heavy_attack":
		return heavy_attack_animation_fps
	if anim_name == "attack":
		return attack_animation_fps
	if anim_name == "hit":
		return hit_animation_fps
	if anim_name == "death":
		return death_animation_fps
	if anim_name == "respawn":
		return respawn_animation_fps
	return animation_fps

func _get_animation_duration(anim_name: String) -> float:
	return float(_get_frame_count(anim_name)) / maxf(_get_animation_fps(anim_name), 1.0)

func _can_start_action(priority: int) -> bool:
	if _locked_anim == "":
		return true
	if _animation_lock_remaining <= 0.0 and not _locked_holds_final_frame:
		return true
	return priority >= _locked_priority

func _set_animation(anim_name: String, restart: bool = false) -> void:
	if _current_anim == anim_name and not restart:
		return
	_current_anim = anim_name
	_frame_index = 0
	_frame_timer = 0.0
	_apply_sprite_frame()

func _lock_animation(anim_name: String, priority: int, duration: float = -1.0, hold_final_frame: bool = false, force: bool = false) -> bool:
	if not force and not _can_start_action(priority):
		return false
	_locked_anim = anim_name
	_locked_priority = priority
	_locked_holds_final_frame = hold_final_frame
	_animation_lock_remaining = duration if duration > 0.0 else _get_animation_duration(anim_name)
	_set_animation(anim_name, true)
	return true

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
	var frame_dimensions: Vector2i = _get_frame_size_for_texture(texture, _current_anim)
	var row_index: int = _get_direction_row()
	var frame_count: int = _get_frame_count(_current_anim)
	_frame_index = clampi(_frame_index, 0, frame_count - 1)
	_sprite.region_rect = Rect2(
		Vector2(float(_frame_index * frame_dimensions.x), float(row_index * frame_dimensions.y)),
		Vector2(float(frame_dimensions.x), float(frame_dimensions.y))
	)

func _get_frame_size_for_texture(texture: Texture2D, anim_name: String) -> Vector2i:
	if texture == null:
		return frame_size
	if not auto_detect_sprite_frame_size:
		return frame_size
	var columns: int = maxi(_get_frame_count(anim_name), 1)
	var rows: int = maxi(direction_row_count, 1)
	return Vector2i(int(texture.get_width() / columns), int(texture.get_height() / rows))

func _set_facing_from_vector(direction: Vector2) -> void:
	if direction.length() <= 0.01:
		return
	var previous_dir_name: String = _facing_dir_name
	facing = direction.normalized()
	_facing_dir_name = _direction_name_from_vector(facing)
	# Direction changes must update the sprite row immediately, even if the
	# animation state itself did not restart. This is what makes A/D/W/S feel
	# correct while walking, and makes the idle row persist after releasing input.
	if previous_dir_name != _facing_dir_name:
		_apply_sprite_frame()

func _direction_name_from_vector(direction: Vector2) -> String:
	var x_abs: float = absf(direction.x)
	var y_abs: float = absf(direction.y)
	if x_abs <= 0.05 and y_abs <= 0.05:
		return _facing_dir_name

	# V6: deterministic screen-direction mapping.
	# The V5 version used the previous facing to decide pure left/right/up/down.
	# That made D sometimes select the down-right row and sometimes the up-right row.
	# Here, the same input always selects the same row:
	#   right -> ne, left -> sw, up -> nw, down -> se.
	if x_abs > y_abs * 1.25:
		return "ne" if direction.x >= 0.0 else "sw"
	if y_abs > x_abs * 1.25:
		return "se" if direction.y >= 0.0 else "nw"

	# True diagonal movement keeps the expected isometric quadrant.
	if direction.y >= 0.0:
		return "se" if direction.x >= 0.0 else "sw"
	return "ne" if direction.x >= 0.0 else "nw"

func _get_direction_row() -> int:
	# V4/V5 sheet row order is normally: 0=southeast, 1=southwest, 2=northwest, 3=northeast.
	# Use the exported row variables if the generated sheet ever needs a manual remap.
	var row_index: int = row_for_southeast
	if _facing_dir_name == "sw":
		row_index = row_for_southwest
	elif _facing_dir_name == "nw":
		row_index = row_for_northwest
	elif _facing_dir_name == "ne":
		row_index = row_for_northeast
	return clampi(row_index, 0, direction_row_count - 1)

func _get_frame_count(anim_name: String) -> int:
	return int(_ANIM_FRAMES.get(anim_name, 4))

func _get_texture_for_current_animation() -> Texture2D:
	if _current_anim == "walk":
		return _walk_texture if _walk_texture != null else _idle_texture
	if _current_anim == "attack":
		return _attack_texture if _attack_texture != null else _idle_texture
	if _current_anim == "heavy_attack":
		return _heavy_attack_texture if _heavy_attack_texture != null else _attack_texture
	if _current_anim == "dash":
		return _dash_texture if _dash_texture != null else _walk_texture
	if _current_anim == "hit":
		return _hit_texture if _hit_texture != null else _idle_texture
	if _current_anim == "death":
		return _death_texture if _death_texture != null else _idle_texture
	if _current_anim == "respawn":
		return _respawn_texture if _respawn_texture != null else _idle_texture
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
	_dash_texture = _load_texture_if_exists(dash_sheet_path)
	_hit_texture = _load_texture_if_exists(hit_sheet_path)
	_death_texture = _load_texture_if_exists(death_sheet_path)
	_respawn_texture = _load_texture_if_exists(respawn_sheet_path)
	_heavy_attack_texture = _load_texture_if_exists(heavy_attack_sheet_path)
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
	if absf(facing.x) > absf(facing.y):
		var horizontal_sign: float = 1.0 if facing.x < 0.0 else -1.0
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
