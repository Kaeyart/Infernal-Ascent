extends CharacterBody2D
class_name IsoPhysicsTestPlayer


# T-009 Azazel boon mechanics. Placeholder mechanics until final boon UI/VFX exists.
var t009_owned_boons: Dictionary = {}
var t009_light_hit_count: int = 0
var t009_bound_step_cooldown: float = 0.0
# T-009 Azazel boon runtime. Placeholder combat hooks until final patron/VFX pass.
var t009_owned_boon_ids: Dictionary = {}
var t009_owned_boon_payloads: Dictionary = {}
var t009_light_hit_counter: int = 0
var t009_bound_step_touched: Dictionary = {}

# T004_Q_ABILITY_PLACEHOLDER_START
@export_group("T004 Q Ability Placeholder")
@export var q_ability_enabled: bool = true
@export var q_ability_cooldown: float = 4.25
@export var q_ability_damage: int = 2
@export var q_ability_radius: float = 82.0
@export var q_ability_forward_dot: float = 0.18
@export var q_ability_knockback: float = 210.0
@export var q_ability_judgment_gain_on_hit: float = 12.0
@export var q_ability_recovery_time: float = 0.34
@export var q_ability_flash_time: float = 0.18
@export var show_debug_q_ability: bool = true

var q_ability_cooldown_remaining: float = 0.0
var _t004_q_recovery_remaining: float = 0.0
var _t004_q_flash_remaining: float = 0.0
var _t004_q_key_was_down: bool = false
var _t004_q_hit_targets: Array = []
var _t004_q_last_direction: Vector2 = Vector2.DOWN
# T004_Q_ABILITY_PLACEHOLDER_END

# T005_ULTIMATE_PLACEHOLDER_START
@export_group("T005 Ultimate Placeholder")
@export var ultimate_enabled: bool = true
@export var ultimate_key_debug_enabled: bool = true
@export var ultimate_meter_cost: float = 100.0
@export var ultimate_damage: int = 5
@export var ultimate_stagger_damage: float = 45.0
@export var ultimate_radius: float = 138.0
@export var ultimate_forward_dot: float = -0.10
@export var ultimate_knockback: float = 360.0
@export var ultimate_recovery_time: float = 0.58
@export var ultimate_flash_time: float = 0.32
@export var ultimate_hit_pause: float = 0.085
@export var show_debug_ultimate: bool = true

var _t005_ultimate_recovery_remaining: float = 0.0
var _t005_ultimate_flash_remaining: float = 0.0
var _t005_ultimate_key_was_down: bool = false
var _t005_ultimate_last_direction: Vector2 = Vector2.DOWN
var _t005_ultimate_hit_targets: Array = []
# T005_ULTIMATE_PLACEHOLDER_END



const PERMANENT_UPGRADE_SCRIPT: Script = preload("res://scripts/run/PermanentUpgradeData.gd")
const INFERNAL_AUDIO_SCRIPT: Script = preload("res://scripts/audio/InfernalAudio.gd")

signal damaged(amount: int, remaining_health: int)
signal died
signal respawned


# --- T003 JUDGMENT METER DECLARATIONS START ---
signal judgment_meter_changed(current: float, maximum: float, ratio: float, is_full: bool)
signal judgment_meter_gained(amount: float, reason: String)
signal judgment_meter_spent(amount: float)

@export_category("Judgment Meter")
@export var judgment_meter_max: float = 100.0
@export var judgment_meter_start: float = 0.0
@export var judgment_gain_light_hit: float = 8.0
@export var judgment_gain_heavy_hit: float = 14.0
@export var judgment_ultimate_cost: float = 100.0
@export var enable_debug_judgment_keys: bool = true

var judgment_meter: float = 0.0
# --- T003 JUDGMENT METER DECLARATIONS END ---

@export var move_speed: float = 260.0
@export var attack_radius: float = 86.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 0.28
@export var heavy_attack_damage: int = 2
@export var heavy_attack_cooldown: float = 0.52
@export var heavy_attack_radius_multiplier: float = 1.18

@export_category("Player Health")
@export var max_health: int = 7
@export var contact_damage_iframe_duration: float = 0.68
@export var hit_flash_duration: float = 0.16
@export var enemy_hit_knockback_speed: float = 185.0
@export var enemy_hit_knockback_duration: float = 0.12
@export var show_player_health_bar: bool = true
@export var show_readability_hit_feedback: bool = true

@export_category("Collision")
@export var auto_create_collision_shape: bool = true
@export var collision_radius: float = 10.0
@export var collision_offset: Vector2 = Vector2(0.0, 8.0)
@export var physics_safe_margin: float = 0.001

@export_category("Dash")
@export var enable_dash: bool = true
@export var dash_speed_multiplier: float = 3.0
@export var dash_duration: float = 0.13
@export var dash_cooldown: float = 0.46

@export_category("Visuals")
@export var use_sprite_visuals: bool = true
@export var show_debug_footprint: bool = false
@export var show_fallback_drawn_body: bool = false
@export var visual_offset: Vector2 = Vector2(0.0, -30.0)
@export var visual_scale: Vector2 = Vector2(0.22, 0.22)
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
@export_category("Combat Timing")
@export var light_attack_active_start_frame: int = 2
@export var light_attack_active_end_frame: int = 3
@export var heavy_attack_active_start_frame: int = 3
@export var heavy_attack_active_end_frame: int = 4
@export var attack_uses_directional_cone: bool = true
@export var light_attack_arc_degrees: float = 122.0
@export var heavy_attack_arc_degrees: float = 152.0
@export var show_debug_combat_hitbox: bool = false

@export_category("Dash Timing")
@export var dash_invulnerable_start_frame: int = 0
@export var dash_invulnerable_end_frame: int = 2
@export var show_debug_dash_invulnerability: bool = false

@export_category("Feel Polish")
@export var movement_acceleration: float = 1900.0
@export var movement_deceleration: float = 2500.0
@export var attack_movement_multiplier: float = 0.66
@export var heavy_attack_movement_multiplier: float = 0.42
@export var hit_movement_multiplier: float = 0.28
@export var dash_exit_speed_retention: float = 0.35
@export var hit_pause_duration_light: float = 0.045
@export var hit_pause_duration_heavy: float = 0.065
@export var screen_shake_enabled: bool = true
@export var attack_hit_shake_strength: float = 4.0
@export var heavy_attack_hit_shake_strength: float = 6.0
@export var dash_shake_strength: float = 2.5
@export var player_damage_shake_strength: float = 7.0
@export var death_shake_strength: float = 10.0
@export var screen_shake_duration: float = 0.10
@export var show_dash_streak: bool = true
@export var show_death_respawn_bursts: bool = true


var facing: Vector2 = Vector2(1.0, 1.0).normalized()

var current_health: int = 0
var _damage_iframe_remaining: float = 0.0
var _hit_flash_remaining: float = 0.0
var _enemy_knockback_remaining: float = 0.0
var _enemy_knockback_velocity: Vector2 = Vector2.ZERO

var _attack_cooldown_remaining: float = 0.0
var _attack_flash_remaining: float = 0.0
var _heavy_attack_cooldown_remaining: float = 0.0
var _dash_cooldown_remaining: float = 0.0
var _dash_remaining: float = 0.0
var _dash_direction: Vector2 = Vector2(1.0, 1.0).normalized()
var _animation_lock_remaining: float = 0.0

var _active_attack_anim: String = ""
var _active_attack_damage: int = 0
var _active_attack_radius: float = 0.0
var _active_attack_arc_degrees: float = 0.0
var _active_attack_hit_targets: Dictionary = {}
var _active_attack_was_active_last_frame: bool = false

var _feel_hit_pause_remaining: float = 0.0
var _screen_shake_remaining: float = 0.0
var _screen_shake_total_duration: float = 0.0
var _screen_shake_strength: float = 0.0
var _screen_shake_camera: Camera2D = null
var _screen_shake_base_offset: Vector2 = Vector2.ZERO
var _death_burst_remaining: float = 0.0
var _respawn_burst_remaining: float = 0.0


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
	_initialize_judgment_meter_t003()
	add_to_group("player")
	if current_health <= 0:
		current_health = max_health
	PERMANENT_UPGRADE_SCRIPT.apply_to_player(self)
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
	_t009_update_azazel_dash_effects(delta)
	_t004_tick_q_ability(delta)
	if _t004_consume_q_input():
		_t004_try_start_q_ability()

	_update_timers(delta)
	var was_moving: bool = _update_movement(delta)
	_update_attack_input()
	var visual_delta: float = 0.0 if _feel_hit_pause_remaining > 0.0 else delta
	_update_visual_animation(visual_delta, was_moving)
	_update_combat_timing()
	_update_screen_shake(delta)
	queue_redraw()

func _update_timers(delta: float) -> void:
	var dash_was_active: bool = _dash_remaining > 0.0
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
	if _damage_iframe_remaining > 0.0:
		_damage_iframe_remaining = maxf(0.0, _damage_iframe_remaining - delta)
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = maxf(0.0, _hit_flash_remaining - delta)
	if _enemy_knockback_remaining > 0.0:
		_enemy_knockback_remaining = maxf(0.0, _enemy_knockback_remaining - delta)
	if _feel_hit_pause_remaining > 0.0:
		_feel_hit_pause_remaining = maxf(0.0, _feel_hit_pause_remaining - delta)
	if _death_burst_remaining > 0.0:
		_death_burst_remaining = maxf(0.0, _death_burst_remaining - delta)
	if _respawn_burst_remaining > 0.0:
		_respawn_burst_remaining = maxf(0.0, _respawn_burst_remaining - delta)
	if dash_was_active and _dash_remaining <= 0.0 and dash_exit_speed_retention > 0.0:
		velocity *= clampf(dash_exit_speed_retention, 0.0, 1.0)

func _update_movement(delta: float) -> bool:
	if _is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		_moving_this_frame = false
		return false

	if _enemy_knockback_remaining > 0.0:
		velocity = _enemy_knockback_velocity
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

	var movement_multiplier: float = _get_current_movement_multiplier()
	var target_velocity: Vector2 = input_vector * move_speed * movement_multiplier if moving else Vector2.ZERO
	var approach_speed: float = movement_acceleration if moving else movement_deceleration
	velocity = velocity.move_toward(target_velocity, maxf(approach_speed, 0.0) * delta)
	move_and_slide()
	_moving_this_frame = moving
	return moving

func _get_current_movement_multiplier() -> float:
	if _locked_anim == "heavy_attack" and _animation_lock_remaining > 0.0:
		return clampf(heavy_attack_movement_multiplier, 0.0, 1.0)
	if _locked_anim == "attack" and _animation_lock_remaining > 0.0:
		return clampf(attack_movement_multiplier, 0.0, 1.0)
	if _locked_anim == "hit" and _animation_lock_remaining > 0.0:
		return clampf(hit_movement_multiplier, 0.0, 1.0)
	return 1.0

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
	_play_audio_event("player_dash")
	_start_screen_shake(dash_shake_strength, screen_shake_duration * 0.75)
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

	var locked: bool = false
	if anim_name == "heavy_attack":
		_heavy_attack_cooldown_remaining = cooldown
		_attack_flash_remaining = _get_animation_duration("heavy_attack")
		locked = _lock_animation("heavy_attack", priority, _get_animation_duration("heavy_attack"), false, false)
	else:
		_attack_cooldown_remaining = cooldown
		_attack_flash_remaining = _get_animation_duration("attack")
		locked = _lock_animation("attack", priority, _get_animation_duration("attack"), false, false)

	if not locked:
		return

	_play_audio_event("player_heavy_attack" if anim_name == "heavy_attack" else "player_light_attack")
	_active_attack_anim = anim_name
	_active_attack_damage = damage_amount
	_active_attack_radius = attack_radius * radius_multiplier
	_active_attack_arc_degrees = heavy_attack_arc_degrees if anim_name == "heavy_attack" else light_attack_arc_degrees
	_active_attack_hit_targets.clear()
	_active_attack_was_active_last_frame = false


func _update_combat_timing() -> void:
	if _active_attack_anim == "":
		return
	if _current_anim != _active_attack_anim:
		_clear_active_attack()
		return
	if _locked_anim != _active_attack_anim and _animation_lock_remaining <= 0.0:
		_clear_active_attack()
		return

	var active_now: bool = _is_attack_active_frame(_active_attack_anim, _frame_index)
	if active_now:
		_apply_active_attack_hit()
	_active_attack_was_active_last_frame = active_now

func _is_attack_active_frame(anim_name: String, frame_index: int) -> bool:
	if anim_name == "heavy_attack":
		return frame_index >= heavy_attack_active_start_frame and frame_index <= heavy_attack_active_end_frame
	return frame_index >= light_attack_active_start_frame and frame_index <= light_attack_active_end_frame

func _apply_active_attack_hit() -> void:
	if _active_attack_anim == "" or _active_attack_damage <= 0:
		return
	var targets: Array[Node] = []
	targets.append_array(get_tree().get_nodes_in_group("iso_test_enemy"))
	targets.append_array(get_tree().get_nodes_in_group("attack_target"))
	for node: Node in targets:
		if not (node is Node2D):
			continue
		var target: Node2D = node as Node2D
		if not is_instance_valid(target):
			continue
		if not target.has_method("take_damage"):
			continue
		var target_id: int = int(target.get_instance_id())
		if _active_attack_hit_targets.has(target_id):
			continue
		if not _is_target_inside_attack_hitbox(target, _active_attack_radius, _active_attack_arc_degrees):
			continue
		_active_attack_hit_targets[target_id] = true
		_deliver_attack_damage_to_target(target)
		_register_successful_attack_hit(_active_attack_anim)


func _deliver_attack_damage_to_target(target: Node2D) -> void:
	if target.has_method("receive_player_hit"):
		target.call("receive_player_hit", _active_attack_damage, global_position, facing, _active_attack_anim)
		return
	target.call("take_damage", _active_attack_damage)

func _register_successful_attack_hit(anim_name: String) -> void:
	var hit_gain: float = judgment_gain_heavy_hit if anim_name == "heavy_attack" else judgment_gain_light_hit
	gain_judgment(hit_gain, "successful_" + anim_name)
	var pause_duration: float = hit_pause_duration_heavy if anim_name == "heavy_attack" else hit_pause_duration_light
	_feel_hit_pause_remaining = maxf(_feel_hit_pause_remaining, pause_duration)
	var shake_strength: float = heavy_attack_hit_shake_strength if anim_name == "heavy_attack" else attack_hit_shake_strength
	_start_screen_shake(shake_strength, screen_shake_duration)
	_play_audio_event("player_heavy_hit" if anim_name == "heavy_attack" else "player_light_hit")
	_attack_flash_remaining = maxf(_attack_flash_remaining, 0.08)
	queue_redraw()

func _is_target_inside_attack_hitbox(target: Node2D, active_radius: float, arc_degrees: float) -> bool:
	var to_target: Vector2 = target.global_position - global_position
	var distance: float = to_target.length()
	if distance > active_radius:
		return false
	if distance <= collision_radius:
		return true
	if not attack_uses_directional_cone:
		return true
	var facing_normalized: Vector2 = facing.normalized()
	if facing_normalized.length() <= 0.01:
		return true
	var target_normalized: Vector2 = to_target.normalized()
	var half_arc_radians: float = deg_to_rad(maxf(arc_degrees, 1.0) * 0.5)
	return absf(facing_normalized.angle_to(target_normalized)) <= half_arc_radians

func _clear_active_attack() -> void:
	_active_attack_anim = ""
	_active_attack_damage = 0
	_active_attack_radius = 0.0
	_active_attack_arc_degrees = 0.0
	_active_attack_hit_targets.clear()
	_active_attack_was_active_last_frame = false

func _is_dash_invulnerable() -> bool:
	if _current_anim != "dash":
		return false
	if _locked_anim != "dash" and _dash_remaining <= 0.0:
		return false
	return _frame_index >= dash_invulnerable_start_frame and _frame_index <= dash_invulnerable_end_frame

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

func receive_enemy_attack(amount: int = 1, source_global_position: Vector2 = Vector2.ZERO, knockback_direction: Vector2 = Vector2.ZERO, knockback_force: float = -1.0) -> bool:
	return take_damage(amount, source_global_position, knockback_direction, knockback_force)

func take_damage(amount: int = 1, source_global_position: Vector2 = Vector2.ZERO, knockback_direction: Vector2 = Vector2.ZERO, knockback_force: float = -1.0) -> bool:
	if _is_dead:
		return false
	if amount <= 0:
		return false
	if _is_dash_invulnerable():
		return false
	if _damage_iframe_remaining > 0.0:
		return false

	current_health = max(0, current_health - amount)
	_play_audio_event("player_hit")
	_start_screen_shake(player_damage_shake_strength, screen_shake_duration * 1.15)
	_apply_enemy_hit_knockback(source_global_position, knockback_direction, knockback_force)
	_damage_iframe_remaining = contact_damage_iframe_duration
	_hit_flash_remaining = hit_flash_duration
	_clear_active_attack()
	emit_signal("damaged", amount, current_health)

	if current_health <= 0:
		play_death_animation()
		return true

	_lock_animation("hit", _PRIORITY_HIT, _get_animation_duration("hit"), false, false)
	return true

func _apply_enemy_hit_knockback(source_global_position: Vector2, knockback_direction: Vector2, knockback_force: float = -1.0) -> void:
	var final_direction: Vector2 = knockback_direction
	if final_direction.length() <= 0.01 and source_global_position != Vector2.ZERO:
		final_direction = global_position - source_global_position
	if final_direction.length() <= 0.01:
		return
	var final_speed: float = knockback_force if knockback_force > 0.0 else enemy_hit_knockback_speed
	_enemy_knockback_velocity = final_direction.normalized() * final_speed
	_enemy_knockback_remaining = enemy_hit_knockback_duration

func heal_full() -> void:
	current_health = max_health
	_is_dead = false
	_damage_iframe_remaining = 0.0
	_hit_flash_remaining = 0.0
	_enemy_knockback_remaining = 0.0
	_enemy_knockback_velocity = Vector2.ZERO
	queue_redraw()

func get_health_text() -> String:
	return "%d/%d" % [current_health, max_health]

func play_death_animation() -> void:
	reset_judgment_meter()
	if _is_dead:
		return
	_is_dead = true
	velocity = Vector2.ZERO
	_dash_remaining = 0.0
	_enemy_knockback_remaining = 0.0
	_enemy_knockback_velocity = Vector2.ZERO
	_damage_iframe_remaining = 0.0
	_clear_active_attack()
	_death_burst_remaining = 0.52
	_play_audio_event("player_death")
	_start_screen_shake(death_shake_strength, screen_shake_duration * 1.6)
	emit_signal("died")
	_lock_animation("death", _PRIORITY_DEATH, _get_animation_duration("death"), true, true)

func play_respawn_animation() -> void:
	_is_dead = false
	current_health = max_health
	_damage_iframe_remaining = 0.0
	_hit_flash_remaining = 0.0
	_enemy_knockback_remaining = 0.0
	_enemy_knockback_velocity = Vector2.ZERO
	_clear_active_attack()
	_respawn_burst_remaining = 0.55
	_play_audio_event("player_respawn")
	_start_screen_shake(dash_shake_strength, screen_shake_duration)
	emit_signal("respawned")
	_lock_animation("respawn", _PRIORITY_RESPAWN, _get_animation_duration("respawn"), false, true)

func _play_audio_event(event_name: String) -> void:
	if INFERNAL_AUDIO_SCRIPT == null:
		return
	INFERNAL_AUDIO_SCRIPT.play_event_from_node(self, event_name, global_position)

func _start_screen_shake(strength: float, duration: float) -> void:
	if not screen_shake_enabled:
		return
	if strength <= 0.0 or duration <= 0.0:
		return
	_screen_shake_strength = maxf(_screen_shake_strength, strength)
	_screen_shake_remaining = maxf(_screen_shake_remaining, duration)
	_screen_shake_total_duration = maxf(_screen_shake_total_duration, duration)

func _update_screen_shake(delta: float) -> void:
	if not screen_shake_enabled:
		_restore_screen_shake_camera()
		return
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera != _screen_shake_camera:
		_restore_screen_shake_camera()
		_screen_shake_camera = camera
		_screen_shake_base_offset = camera.offset if camera != null else Vector2.ZERO
	if _screen_shake_remaining <= 0.0:
		_restore_screen_shake_camera()
		return
	_screen_shake_remaining = maxf(0.0, _screen_shake_remaining - delta)
	if _screen_shake_camera == null:
		return
	var ratio: float = clampf(_screen_shake_remaining / maxf(_screen_shake_total_duration, 0.01), 0.0, 1.0)
	var offset: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _screen_shake_strength * ratio
	_screen_shake_camera.offset = _screen_shake_base_offset + offset
	if _screen_shake_remaining <= 0.0:
		_restore_screen_shake_camera()

func _restore_screen_shake_camera() -> void:
	if _screen_shake_camera != null and is_instance_valid(_screen_shake_camera):
		_screen_shake_camera.offset = _screen_shake_base_offset
	_screen_shake_camera = null
	_screen_shake_strength = 0.0
	_screen_shake_total_duration = 0.0

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
	if _active_attack_anim == _locked_anim:
		_clear_active_attack()
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
	if anim_name != "attack" and anim_name != "heavy_attack" and _active_attack_anim != "":
		_clear_active_attack()
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


func _unhandled_input(event: InputEvent) -> void:
	_handle_judgment_debug_input_t003(event)

func _draw() -> void:
	if _t004_q_flash_remaining > 0.0:
		_t004_draw_q_ability_debug()
	_t004_draw_q_cooldown_debug()

	_draw_filled_ellipse(Rect2(Vector2(-20.0, 10.0), Vector2(40.0, 13.0)), Color(0.0, 0.0, 0.0, 0.34))
	if show_dash_streak and _dash_remaining > 0.0:
		_draw_dash_streak()
	if show_death_respawn_bursts:
		_draw_death_respawn_bursts()
	if show_readability_hit_feedback:
		_draw_readability_damage_state()
	else:
		if _hit_flash_remaining > 0.0:
			draw_arc(Vector2.ZERO, collision_radius + 14.0, 0.0, TAU, 28, Color(1.0, 0.35, 0.22, 0.78), 3.0)
		elif _damage_iframe_remaining > 0.0:
			draw_arc(Vector2.ZERO, collision_radius + 12.0, 0.0, TAU, 28, Color(0.55, 0.75, 1.0, 0.42), 2.0)
	if show_player_health_bar:
		_draw_player_health_bar()
	if _attack_flash_remaining > 0.0:
		draw_circle(Vector2.ZERO, attack_radius, Color(0.85, 0.62, 0.34, 0.10))
		draw_arc(Vector2.ZERO, attack_radius, 0.0, TAU, 64, Color(0.95, 0.80, 0.48, 0.72), 2.0)
	if show_debug_combat_hitbox and _active_attack_anim != "":
		var debug_color: Color = Color(1.0, 0.78, 0.30, 0.40) if _is_attack_active_frame(_active_attack_anim, _frame_index) else Color(0.65, 0.65, 0.65, 0.25)
		draw_arc(Vector2.ZERO, _active_attack_radius, 0.0, TAU, 64, debug_color, 2.0)
		draw_line(Vector2.ZERO, facing.normalized() * _active_attack_radius, debug_color, 2.0)
	if show_debug_dash_invulnerability and _is_dash_invulnerable():
		draw_arc(Vector2.ZERO, collision_radius + 8.0, 0.0, TAU, 24, Color(0.35, 0.65, 1.0, 0.85), 3.0)
	if show_debug_footprint:
		draw_arc(collision_offset, collision_radius, 0.0, TAU, 24, Color(0.3, 0.75, 1.0, 0.65), 1.0)
	if show_fallback_drawn_body or not use_sprite_visuals or _idle_texture == null:
		_draw_fallback_body()

func _draw_dash_streak() -> void:
	var dash_back: Vector2 = -_dash_direction.normalized()
	if dash_back.length() <= 0.01:
		dash_back = -facing.normalized()
	for i: int in range(3):
		var distance: float = 16.0 + float(i) * 12.0
		var alpha: float = 0.26 - float(i) * 0.06
		var start: Vector2 = dash_back * distance + Vector2(0.0, -16.0 + float(i) * 7.0)
		var end: Vector2 = start + dash_back * 18.0
		draw_line(start, end, Color(0.80, 0.82, 0.92, alpha), 3.0 - float(i) * 0.45)

func _draw_death_respawn_bursts() -> void:
	if _death_burst_remaining > 0.0:
		var t: float = clampf(_death_burst_remaining / 0.52, 0.0, 1.0)
		var radius: float = 22.0 + (1.0 - t) * 32.0
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, Color(0.92, 0.16, 0.08, 0.52 * t), 3.0)
		draw_circle(Vector2.ZERO, radius * 0.45, Color(0.16, 0.02, 0.02, 0.12 * t))
	if _respawn_burst_remaining > 0.0:
		var rt: float = clampf(_respawn_burst_remaining / 0.55, 0.0, 1.0)
		var rr: float = 18.0 + (1.0 - rt) * 28.0
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 36, Color(0.95, 0.62, 0.28, 0.46 * rt), 2.5)
		draw_arc(Vector2.ZERO, rr + 8.0, 0.0, TAU, 36, Color(0.55, 0.42, 0.22, 0.24 * rt), 1.5)

func _draw_readability_damage_state() -> void:
	if _hit_flash_remaining > 0.0:
		var t: float = clampf(_hit_flash_remaining / maxf(hit_flash_duration, 0.01), 0.0, 1.0)
		draw_circle(Vector2.ZERO, collision_radius + 17.0, Color(1.0, 0.08, 0.02, 0.10 + 0.18 * t))
		draw_arc(Vector2.ZERO, collision_radius + 18.0, 0.0, TAU, 30, Color(1.0, 0.34, 0.18, 0.88), 4.0)
		draw_line(Vector2(-18.0, -34.0), Vector2(18.0, 12.0), Color(1.0, 0.72, 0.38, 0.72), 2.0)
		draw_line(Vector2(18.0, -34.0), Vector2(-18.0, 12.0), Color(1.0, 0.72, 0.38, 0.72), 2.0)
	elif _damage_iframe_remaining > 0.0:
		var iframe_ratio: float = clampf(_damage_iframe_remaining / maxf(contact_damage_iframe_duration, 0.01), 0.0, 1.0)
		draw_arc(Vector2.ZERO, collision_radius + 14.0, 0.0, TAU, 28, Color(0.55, 0.75, 1.0, 0.30 + 0.28 * iframe_ratio), 2.0)

func _draw_player_health_bar() -> void:
	if max_health <= 0:
		return

	var bar_width: float = 54.0
	var bar_height: float = 6.0
	var bar_position: Vector2 = Vector2(-bar_width * 0.5, -78.0)
	var background_rect: Rect2 = Rect2(bar_position, Vector2(bar_width, bar_height))
	var health_ratio: float = clampf(float(current_health) / float(max_health), 0.0, 1.0)
	var fill_rect: Rect2 = Rect2(bar_position + Vector2(1.0, 1.0), Vector2((bar_width - 2.0) * health_ratio, bar_height - 2.0))

	draw_rect(background_rect.grow(1.0), Color(0.0, 0.0, 0.0, 0.52), true)
	draw_rect(background_rect, Color(0.08, 0.05, 0.045, 0.92), true)
	if current_health > 0:
		draw_rect(fill_rect, Color(0.78, 0.12, 0.08, 0.95), true)
	draw_rect(background_rect, Color(0.92, 0.66, 0.36, 0.78), false, 1.0)

	if max_health > 1 and max_health <= 12:
		for i: int in range(1, max_health):
			var x: float = bar_position.x + (bar_width * float(i) / float(max_health))
			draw_line(Vector2(x, bar_position.y + 1.0), Vector2(x, bar_position.y + bar_height - 1.0), Color(0.0, 0.0, 0.0, 0.55), 1.0)

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


# --- T003 JUDGMENT METER FUNCTIONS START ---
func _initialize_judgment_meter_t003() -> void:
	judgment_meter = clampf(judgment_meter_start, 0.0, judgment_meter_max)
	_emit_judgment_meter_changed_t003()

func get_judgment_meter_ratio() -> float:
	if judgment_meter_max <= 0.0:
		return 0.0
	return clampf(judgment_meter / judgment_meter_max, 0.0, 1.0)

func is_judgment_full() -> bool:
	return judgment_meter >= judgment_meter_max

func gain_judgment(amount: float, reason: String = "") -> void:
	if amount <= 0.0:
		return
	var previous_value: float = judgment_meter
	judgment_meter = clampf(judgment_meter + amount, 0.0, judgment_meter_max)
	var gained: float = judgment_meter - previous_value
	if gained <= 0.0:
		return
	emit_signal("judgment_meter_gained", gained, reason)
	_emit_judgment_meter_changed_t003()
	queue_redraw()

func can_spend_judgment(amount: float) -> bool:
	return amount > 0.0 and judgment_meter >= amount

func spend_judgment(amount: float) -> bool:
	if not can_spend_judgment(amount):
		return false
	judgment_meter = clampf(judgment_meter - amount, 0.0, judgment_meter_max)
	emit_signal("judgment_meter_spent", amount)
	_emit_judgment_meter_changed_t003()
	queue_redraw()
	return true

func reset_judgment_meter() -> void:
	judgment_meter = clampf(judgment_meter_start, 0.0, judgment_meter_max)
	_emit_judgment_meter_changed_t003()
	queue_redraw()

func get_judgment_ui_state() -> Dictionary:
	return {
		"current": judgment_meter,
		"max": judgment_meter_max,
		"ratio": get_judgment_meter_ratio(),
		"is_full": is_judgment_full(),
	}

func _emit_judgment_meter_changed_t003() -> void:
	emit_signal("judgment_meter_changed", judgment_meter, judgment_meter_max, get_judgment_meter_ratio(), is_judgment_full())

func _handle_judgment_debug_input_t003(event: InputEvent) -> void:
	if not enable_debug_judgment_keys:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if key_event.keycode == KEY_J:
			gain_judgment(25.0, "debug_key")
		elif key_event.keycode == KEY_U:
			spend_judgment(judgment_ultimate_cost)
# --- T003 JUDGMENT METER FUNCTIONS END ---


# T004_Q_ABILITY_PLACEHOLDER_FUNCTIONS_START
func _t004_tick_q_ability(delta: float) -> void:
	if q_ability_cooldown_remaining > 0.0:
		q_ability_cooldown_remaining = maxf(0.0, q_ability_cooldown_remaining - delta)
	if _t004_q_recovery_remaining > 0.0:
		_t004_q_recovery_remaining = maxf(0.0, _t004_q_recovery_remaining - delta)
	if _t004_q_flash_remaining > 0.0:
		_t004_q_flash_remaining = maxf(0.0, _t004_q_flash_remaining - delta)
		queue_redraw()


func _t004_consume_q_input() -> bool:
	var pressed_action: bool = false
	if InputMap.has_action("player_q"):
		pressed_action = Input.is_action_just_pressed("player_q")

	var key_is_down: bool = Input.is_key_pressed(KEY_Q)
	var pressed_key: bool = key_is_down and not _t004_q_key_was_down
	_t004_q_key_was_down = key_is_down

	return pressed_action or pressed_key


func _t004_try_start_q_ability() -> void:
	if not q_ability_enabled:
		return
	if q_ability_cooldown_remaining > 0.0:
		return
	if _t004_q_recovery_remaining > 0.0:
		return

	_t004_q_last_direction = facing.normalized()
	if _t004_q_last_direction.length_squared() <= 0.001:
		_t004_q_last_direction = Vector2.DOWN

	q_ability_cooldown_remaining = q_ability_cooldown
	_t004_q_recovery_remaining = q_ability_recovery_time
	_t004_q_flash_remaining = q_ability_flash_time
	_t004_q_hit_targets.clear()

	_t004_apply_q_ability_hit()
	queue_redraw()


func _t004_apply_q_ability_hit() -> void:
	var targets: Array = []
	_t004_append_group_nodes(targets, "attack_target")
	_t004_append_group_nodes(targets, "enemy")
	_t004_append_group_nodes(targets, "boss")

	var hit_count: int = 0
	for target_obj in targets:
		var target: Node2D = target_obj as Node2D
		if target == null:
			continue
		if target == self:
			continue
		if not is_instance_valid(target):
			continue

		var delta_to_target: Vector2 = target.global_position - global_position
		var distance_to_target: float = delta_to_target.length()
		if distance_to_target > q_ability_radius:
			continue

		var direction_to_target: Vector2 = delta_to_target.normalized()
		if distance_to_target <= 6.0:
			direction_to_target = _t004_q_last_direction

		if direction_to_target.dot(_t004_q_last_direction) < q_ability_forward_dot:
			continue

		if _t004_apply_damage_to_target(target, q_ability_damage, q_ability_knockback):
			_t004_q_hit_targets.append(target)
			hit_count += 1

	if hit_count > 0:
		_t004_gain_judgment_from_q(hit_count)


func _t004_append_group_nodes(targets: Array, group_name: String) -> void:
	if not get_tree().has_group(group_name):
		return
	var group_nodes: Array = get_tree().get_nodes_in_group(group_name)
	for node_obj in group_nodes:
		var node: Node = node_obj as Node
		if node == null:
			continue
		if not targets.has(node):
			targets.append(node)


func _t004_apply_damage_to_target(target: Node2D, amount: int, knockback_force: float) -> bool:
	if target.has_method("take_damage"):
		_t004_call_damage_method(target, "take_damage", amount, knockback_force)
		return true
	if target.has_method("receive_damage"):
		_t004_call_damage_method(target, "receive_damage", amount, knockback_force)
		return true
	if target.has_method("apply_damage"):
		_t004_call_damage_method(target, "apply_damage", amount, knockback_force)
		return true
	if target.has_method("damage"):
		_t004_call_damage_method(target, "damage", amount, knockback_force)
		return true
	if target.has_method("take_hit"):
		_t004_call_damage_method(target, "take_hit", amount, knockback_force)
		return true
	if target.has_method("hit"):
		_t004_call_damage_method(target, "hit", amount, knockback_force)
		return true
	return false




func _t004_call_damage_method(target: Node, arg1: Variant = null, arg2: Variant = null, arg3: Variant = null, arg4: Variant = null, arg5: Variant = null) -> void:
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("take_damage"):
		return

	var raw_args: Array = [arg1, arg2, arg3, arg4, arg5]

	var damage_amount: int = 1
	var damage_found: bool = false
	var hit_position: Vector2 = global_position
	var hit_direction: Vector2 = facing.normalized()
	var knockback_force: float = 0.0
	var stagger_amount: float = 0.0
	var attack_kind: String = "player_ability"
	var vector_values: Array = []

	for raw_value: Variant in raw_args:
		if raw_value == null:
			continue

		var raw_type: int = typeof(raw_value)

		if raw_type == TYPE_STRING:
			attack_kind = str(raw_value)
		elif raw_type == TYPE_INT:
			if not damage_found:
				damage_amount = int(raw_value)
				damage_found = true
			else:
				stagger_amount = float(raw_value)
		elif raw_type == TYPE_FLOAT:
			if not damage_found:
				damage_amount = int(round(float(raw_value)))
				damage_found = true
			elif knockback_force == 0.0:
				knockback_force = float(raw_value)
			else:
				stagger_amount = float(raw_value)
		elif raw_type == TYPE_VECTOR2:
			vector_values.append(raw_value)

	if vector_values.size() == 1:
		var only_vector: Vector2 = vector_values[0] as Vector2
		if only_vector.length() <= 2.0:
			hit_direction = only_vector.normalized()
			hit_position = global_position
		else:
			hit_position = only_vector
	elif vector_values.size() >= 2:
		hit_position = vector_values[0] as Vector2
		hit_direction = (vector_values[1] as Vector2).normalized()

	if hit_direction.length_squared() <= 0.001:
		if target is Node2D:
			hit_direction = ((target as Node2D).global_position - hit_position).normalized()
		if hit_direction.length_squared() <= 0.001:
			hit_direction = facing.normalized()
		if hit_direction.length_squared() <= 0.001:
			hit_direction = Vector2.RIGHT

	_t009_pre_damage_azazel_effects(target, attack_kind, hit_position, hit_direction)
	damage_amount = _t009_modify_azazel_damage(target, damage_amount, attack_kind)

	# T-006: allow normal enemies to react before damage is applied.
	if target.has_method("receive_player_ability_interaction"):
		target.call("receive_player_ability_interaction", attack_kind, damage_amount, hit_position, hit_direction, knockback_force, stagger_amount)

	# T-006: let enemies expose temporary vulnerability without changing every take_damage signature.
	if target.has_method("get_player_ability_damage_multiplier"):
		var multiplier: float = float(target.call("get_player_ability_damage_multiplier", attack_kind))
		damage_amount = max(1, int(ceil(float(damage_amount) * multiplier)))

	if _t009_is_q_attack_kind(attack_kind):
		_t009_on_q_hit(target)
	if _t009_is_heavy_attack_kind(attack_kind):
		damage_amount = _t009_apply_heavy_modifiers_to_damage(target, damage_amount)
	if _t009_is_ultimate_attack_kind(attack_kind):
		_t009_on_ultimate_hit(target)

	var method_args: Array = []
	for raw_method_info: Dictionary in target.get_method_list():
		var method_info: Dictionary = raw_method_info
		if str(method_info.get("name", "")) == "take_damage":
			method_args = method_info.get("args", [])
			break

	var script_path: String = ""
	var script_resource: Script = target.get_script() as Script
	if script_resource != null:
		script_path = script_resource.resource_path

	# Known boss signature:
	# take_damage(amount: int, source_global_position: Vector2, hit_direction: Vector2, attack_kind: String)
	if script_path.ends_with("AshWardenBoss.gd"):
		target.call("take_damage", damage_amount, hit_position, hit_direction, attack_kind)
		_t009_after_damage_azazel_effects(target, attack_kind, damage_amount)
		return

	# Known normal enemy signature:
	# take_damage(amount: int)
	if method_args.size() <= 1:
		target.call("take_damage", damage_amount)
		_t009_after_damage_azazel_effects(target, attack_kind, damage_amount)
		return

	var call_args: Array = []
	for i: int in range(method_args.size()):
		var arg_info: Dictionary = method_args[i] as Dictionary
		var arg_name: String = str(arg_info.get("name", "")).to_lower()
		var arg_type: int = int(arg_info.get("type", TYPE_NIL))

		if i == 0:
			call_args.append(damage_amount)
			continue

		match arg_type:
			TYPE_VECTOR2:
				if arg_name.find("dir") >= 0 or arg_name.find("normal") >= 0:
					call_args.append(hit_direction)
				elif arg_name.find("source") >= 0 or arg_name.find("pos") >= 0 or arg_name.find("origin") >= 0 or arg_name.find("global") >= 0:
					call_args.append(hit_position)
				else:
					call_args.append(hit_position)
			TYPE_STRING:
				call_args.append(attack_kind)
			TYPE_INT:
				if arg_name.find("stagger") >= 0:
					call_args.append(int(round(stagger_amount)))
				else:
					call_args.append(int(round(knockback_force)))
			TYPE_FLOAT:
				if arg_name.find("stagger") >= 0:
					call_args.append(stagger_amount)
				else:
					call_args.append(knockback_force)
			TYPE_BOOL:
				call_args.append(false)
			TYPE_OBJECT:
				call_args.append(self)
			_:
				if arg_name.find("kind") >= 0 or arg_name.find("type") >= 0:
					call_args.append(attack_kind)
				elif arg_name.find("dir") >= 0:
					call_args.append(hit_direction)
				elif arg_name.find("pos") >= 0 or arg_name.find("source") >= 0:
					call_args.append(hit_position)
				else:
					call_args.append(damage_amount)

	Callable(target, "take_damage").callv(call_args)
	_t009_after_damage_azazel_effects(target, attack_kind, damage_amount)

func _t004_get_method_args(target: Object, method_name: String) -> Array:
	if target == null:
		return []
	for method_info: Dictionary in target.get_method_list():
		if str(method_info.get("name", "")) == method_name:
			return method_info.get("args", []) as Array
	return []

func _t004_get_method_arg_count(target: Node, method_name: String) -> int:
	var methods: Array = target.get_method_list()
	for method_obj in methods:
		var method_data: Dictionary = method_obj as Dictionary
		if String(method_data.get("name", "")) != method_name:
			continue
		var args: Array = method_data.get("args", [])
		return args.size()
	return 1


func _t004_gain_judgment_from_q(hit_count: int) -> void:
	var gain_amount: float = q_ability_judgment_gain_on_hit * float(hit_count)
	if has_method("gain_judgment"):
		call("gain_judgment", gain_amount)
	elif has_method("_gain_judgment"):
		call("_gain_judgment", gain_amount)
	elif _t004_has_property("judgment_meter"):
		var current_judgment: float = float(get("judgment_meter"))
		set("judgment_meter", clampf(current_judgment + gain_amount, 0.0, 100.0))




func _t004_has_property(property_name: String) -> bool:
	var properties: Array = get_property_list()
	for property_obj in properties:
		var property_data: Dictionary = property_obj as Dictionary
		if String(property_data.get("name", "")) == property_name:
			return true
	return false

func _t004_get_q_cooldown_ratio() -> float:
	if q_ability_cooldown <= 0.001:
		return 0.0
	return clampf(q_ability_cooldown_remaining / q_ability_cooldown, 0.0, 1.0)


func _t004_draw_q_ability_debug() -> void:
	if not show_debug_q_ability:
		return
	var alpha: float = clampf(_t004_q_flash_remaining / maxf(q_ability_flash_time, 0.001), 0.0, 1.0)
	var center_color: Color = Color(0.88, 0.72, 0.36, 0.18 * alpha)
	var edge_color: Color = Color(1.0, 0.82, 0.38, 0.78 * alpha)
	var dir: Vector2 = _t004_q_last_direction.normalized()
	if dir.length_squared() <= 0.001:
		dir = Vector2.DOWN

	draw_circle(Vector2.ZERO, q_ability_radius, center_color)
	draw_arc(Vector2.ZERO, q_ability_radius, -0.25 * PI, 0.25 * PI, 24, edge_color, 3.0)

	var left_dir: Vector2 = dir.rotated(-0.95)
	var right_dir: Vector2 = dir.rotated(0.95)
	draw_line(Vector2.ZERO, left_dir * q_ability_radius, edge_color, 2.0)
	draw_line(Vector2.ZERO, right_dir * q_ability_radius, edge_color, 2.0)
	draw_line(Vector2.ZERO, dir * q_ability_radius, Color(1.0, 0.94, 0.62, 0.95 * alpha), 3.0)


func _t004_draw_q_cooldown_debug() -> void:
	if not show_debug_q_ability:
		return
	if q_ability_cooldown_remaining <= 0.0:
		return
	var ratio: float = _t004_get_q_cooldown_ratio()
	var radius: float = 18.0
	var start_angle: float = -PI * 0.5
	var end_angle: float = start_angle + TAU * ratio
	draw_arc(Vector2(0.0, -44.0), radius, start_angle, end_angle, 20, Color(0.82, 0.68, 0.32, 0.75), 2.0)
# T004_Q_ABILITY_PLACEHOLDER_FUNCTIONS_END


# T005_ULTIMATE_PLACEHOLDER_FUNCTIONS_START
func _t005_tick_ultimate(delta: float) -> void:
	if _t005_ultimate_recovery_remaining > 0.0:
		_t005_ultimate_recovery_remaining = maxf(0.0, _t005_ultimate_recovery_remaining - delta)
	if _t005_ultimate_flash_remaining > 0.0:
		_t005_ultimate_flash_remaining = maxf(0.0, _t005_ultimate_flash_remaining - delta)
		queue_redraw()


func _t005_consume_ultimate_input() -> bool:
	var pressed_action: bool = false
	if InputMap.has_action("player_ultimate"):
		pressed_action = Input.is_action_just_pressed("player_ultimate")

	if not ultimate_key_debug_enabled:
		return pressed_action

	var key_is_down: bool = Input.is_key_pressed(KEY_R)
	var pressed_key: bool = key_is_down and not _t005_ultimate_key_was_down
	_t005_ultimate_key_was_down = key_is_down
	return pressed_action or pressed_key


func _t005_try_start_ultimate() -> void:
	if not ultimate_enabled:
		return
	if _t005_ultimate_recovery_remaining > 0.0:
		return
	if not _t005_can_spend_ultimate_meter():
		_t005_pulse_failed_ultimate()
		return
	if not _t005_spend_ultimate_meter():
		_t005_pulse_failed_ultimate()
		return

	_t005_ultimate_last_direction = facing.normalized()
	if _t005_ultimate_last_direction.length_squared() <= 0.001:
		_t005_ultimate_last_direction = Vector2.DOWN

	_t005_ultimate_recovery_remaining = ultimate_recovery_time
	_t005_ultimate_flash_remaining = ultimate_flash_time
	_t005_ultimate_hit_targets.clear()
	_t005_apply_ultimate_hit()
	queue_redraw()


func _t005_can_spend_ultimate_meter() -> bool:
	if has_method("can_spend_judgment"):
		return bool(call("can_spend_judgment", ultimate_meter_cost))
	var meter_value: Variant = get("judgment_meter")
	if meter_value == null:
		return false
	return float(meter_value) >= ultimate_meter_cost


func _t005_spend_ultimate_meter() -> bool:
	if has_method("spend_judgment"):
		return bool(call("spend_judgment", ultimate_meter_cost))
	var meter_value: Variant = get("judgment_meter")
	if meter_value == null:
		return false
	var current_meter: float = float(meter_value)
	if current_meter < ultimate_meter_cost:
		return false
	set("judgment_meter", maxf(0.0, current_meter - ultimate_meter_cost))
	return true


func _t005_pulse_failed_ultimate() -> void:
	# Small local feedback only. Final UI/audio comes later.
	_t005_ultimate_flash_remaining = minf(0.10, maxf(ultimate_flash_time * 0.35, 0.06))
	queue_redraw()


func _t005_apply_ultimate_hit() -> void:
	var targets: Array = []
	_t005_append_group_nodes(targets, "attack_target")
	_t005_append_group_nodes(targets, "enemy")
	_t005_append_group_nodes(targets, "boss")

	var hit_count: int = 0
	for target_obj in targets:
		var target: Node2D = target_obj as Node2D
		if target == null:
			continue
		if target == self:
			continue
		if not is_instance_valid(target):
			continue

		var delta_to_target: Vector2 = target.global_position - global_position
		var distance_to_target: float = delta_to_target.length()
		if distance_to_target > ultimate_radius:
			continue

		var direction_to_target: Vector2 = delta_to_target.normalized()
		if distance_to_target <= 6.0:
			direction_to_target = _t005_ultimate_last_direction

		if direction_to_target.dot(_t005_ultimate_last_direction) < ultimate_forward_dot:
			continue

		if _t005_apply_damage_to_target(target, ultimate_damage, ultimate_knockback):
			_t005_ultimate_hit_targets.append(target)
			hit_count += 1
			_t005_apply_stagger_to_target(target)

	if hit_count > 0:
		_t005_apply_ultimate_hit_pause()


func _t005_append_group_nodes(targets: Array, group_name: String) -> void:
	var group_nodes: Array = get_tree().get_nodes_in_group(group_name)
	for node_obj in group_nodes:
		var node: Node = node_obj as Node
		if node == null:
			continue
		if not targets.has(node):
			targets.append(node)


func _t005_apply_damage_to_target(target: Node2D, amount: int, knockback_force: float) -> bool:
	if target.has_method("take_damage"):
		_t005_call_damage_method(target, "take_damage", amount, knockback_force)
		return true
	if target.has_method("receive_damage"):
		_t005_call_damage_method(target, "receive_damage", amount, knockback_force)
		return true
	if target.has_method("apply_damage"):
		_t005_call_damage_method(target, "apply_damage", amount, knockback_force)
		return true
	if target.has_method("damage"):
		_t005_call_damage_method(target, "damage", amount, knockback_force)
		return true
	if target.has_method("take_hit"):
		_t005_call_damage_method(target, "take_hit", amount, knockback_force)
		return true
	if target.has_method("hit"):
		_t005_call_damage_method(target, "hit", amount, knockback_force)
		return true
	return false


func _t005_call_damage_method(target: Node2D, method_name: String, amount: int, knockback_force: float) -> void:
	var method_arg_count: int = _t005_get_method_arg_count(target, method_name)
	var hit_direction: Vector2 = (target.global_position - global_position).normalized()
	if hit_direction.length_squared() <= 0.001:
		hit_direction = _t005_ultimate_last_direction

	if method_arg_count <= 1:
		target.call(method_name, amount)
	elif method_arg_count == 2:
		target.call(method_name, amount, global_position)
	elif method_arg_count == 3:
		target.call(method_name, amount, global_position, knockback_force)
	else:
		target.call(method_name, amount, global_position, knockback_force, hit_direction)


func _t005_get_method_arg_count(target: Node, method_name: String) -> int:
	var methods: Array = target.get_method_list()
	for method_obj in methods:
		var method_data: Dictionary = method_obj as Dictionary
		if String(method_data.get("name", "")) != method_name:
			continue
		var args: Array = method_data.get("args", [])
		return args.size()
	return 1


func _t005_apply_stagger_to_target(target: Node2D) -> void:
	if target.has_method("apply_stagger"):
		target.call("apply_stagger", ultimate_stagger_damage, global_position)
	elif target.has_method("add_stagger"):
		target.call("add_stagger", ultimate_stagger_damage)
	elif target.has_method("stagger"):
		target.call("stagger", ultimate_stagger_damage)


func _t005_apply_ultimate_hit_pause() -> void:
	# Several earlier feel patches used local pause timers. Use them if present, otherwise do nothing.
	var pause_value: Variant = get("_hit_pause_remaining")
	if pause_value != null:
		set("_hit_pause_remaining", maxf(float(pause_value), ultimate_hit_pause))
	var pause_value_alt: Variant = get("hit_pause_remaining")
	if pause_value_alt != null:
		set("hit_pause_remaining", maxf(float(pause_value_alt), ultimate_hit_pause))


func _t005_get_ultimate_ready_ratio() -> float:
	if has_method("get_judgment_meter_ratio"):
		return float(call("get_judgment_meter_ratio"))
	var meter_value: Variant = get("judgment_meter")
	var max_value: Variant = get("judgment_meter_max")
	if meter_value == null or max_value == null:
		return 0.0
	var max_meter: float = maxf(1.0, float(max_value))
	return clampf(float(meter_value) / max_meter, 0.0, 1.0)


func _t005_draw_ultimate_debug() -> void:
	if not show_debug_ultimate:
		return
	if _t005_ultimate_flash_remaining <= 0.0:
		return
	var alpha: float = clampf(_t005_ultimate_flash_remaining / maxf(ultimate_flash_time, 0.001), 0.0, 1.0)
	var dir: Vector2 = _t005_ultimate_last_direction.normalized()
	if dir.length_squared() <= 0.001:
		dir = Vector2.DOWN
	var left_dir: Vector2 = dir.rotated(-0.78)
	var right_dir: Vector2 = dir.rotated(0.78)
	var slash_poly: PackedVector2Array = PackedVector2Array([
		Vector2.ZERO,
		left_dir * (ultimate_radius * 0.72),
		dir * (ultimate_radius * 1.10),
		right_dir * (ultimate_radius * 0.72),
	])
	draw_colored_polygon(slash_poly, Color(1.0, 0.78, 0.30, 0.22 * alpha))
	draw_line(Vector2.ZERO, dir * ultimate_radius, Color(1.0, 0.93, 0.58, 0.95 * alpha), 5.0)
	draw_line(left_dir * 18.0, dir * (ultimate_radius * 1.05), Color(1.0, 0.63, 0.22, 0.82 * alpha), 3.0)
	draw_line(right_dir * 18.0, dir * (ultimate_radius * 1.05), Color(1.0, 0.63, 0.22, 0.82 * alpha), 3.0)
	draw_arc(Vector2.ZERO, ultimate_radius * 0.62, 0.0, TAU, 40, Color(0.82, 0.58, 0.20, 0.42 * alpha), 2.0)


func _t005_draw_ultimate_meter_hint() -> void:
	if not show_debug_ultimate:
		return
	if _t005_ultimate_flash_remaining > 0.0:
		return
	var ratio: float = _t005_get_ultimate_ready_ratio()
	if ratio < 1.0:
		return
	draw_arc(Vector2(0.0, -68.0), 24.0, 0.0, TAU, 28, Color(1.0, 0.76, 0.28, 0.82), 2.0)
# T005_ULTIMATE_PLACEHOLDER_FUNCTIONS_END


# T-009 — Called by the run controller when a boon is claimed.
func apply_run_boon(payload: Dictionary) -> void:
	var boon_id: String = str(payload.get("boon_id", payload.get("id", payload.get("reward_id", ""))))
	if boon_id == "":
		return
	t009_owned_boon_ids[boon_id] = true
	t009_owned_boon_payloads[boon_id] = payload.duplicate(true)
	queue_redraw()

func has_run_boon(boon_id: String) -> bool:
	return bool(t009_owned_boon_ids.get(boon_id, false))

func _t009_has_azazel_boon(boon_id: String) -> bool:
	return has_run_boon(boon_id)

func _t009_pre_damage_azazel_effects(target: Node, attack_kind: String, hit_position: Vector2, hit_direction: Vector2) -> void:
	if target == null or not is_instance_valid(target):
		return

	var kind: String = attack_kind.to_lower()

	if (kind.find("q") >= 0 or kind.find("riposte") >= 0) and _t009_has_azazel_boon("azazel_condemned_mark"):
		if target.has_method("apply_azazel_mark"):
			target.call("apply_azazel_mark")
		else:
			target.set_meta("t009_azazel_condemned_mark", true)

	if kind.find("heavy") >= 0:
		if _t009_has_azazel_boon("azazel_iron_sentence") and target.has_method("apply_azazel_bonus_stagger"):
			target.call("apply_azazel_bonus_stagger", 30.0)
		if _t009_has_azazel_boon("azazel_dragged_below") and target.has_method("apply_azazel_pull"):
			target.call("apply_azazel_pull", global_position, 42.0)

	if kind.find("ultimate") >= 0 and _t009_has_azazel_boon("azazel_final_shackle"):
		if target.has_method("apply_azazel_root"):
			target.call("apply_azazel_root", 2.0)

func _t009_modify_azazel_damage(target: Node, damage_amount: int, attack_kind: String) -> int:
	if target == null or not is_instance_valid(target):
		return damage_amount
	var kind: String = attack_kind.to_lower()
	var result: int = damage_amount

	if kind.find("heavy") >= 0 and _t009_has_azazel_boon("azazel_condemned_mark"):
		var marked: bool = false
		if target.has_method("consume_azazel_mark"):
			marked = bool(target.call("consume_azazel_mark"))
		elif target.has_meta("t009_azazel_condemned_mark"):
			marked = bool(target.get_meta("t009_azazel_condemned_mark"))
			target.remove_meta("t009_azazel_condemned_mark")
		if marked:
			result = max(1, int(ceil(float(result) * 1.2)))

	return result

func _t009_after_damage_azazel_effects(target: Node, attack_kind: String, damage_amount: int) -> void:
	if target == null or not is_instance_valid(target):
		return
	var kind: String = attack_kind.to_lower()

	if kind.find("light") >= 0 and _t009_has_azazel_boon("azazel_chain_echo"):
		t009_light_hit_counter += 1
		if t009_light_hit_counter >= 3:
			t009_light_hit_counter = 0
			_t009_chain_lash_nearby(target)

func _t009_chain_lash_nearby(primary_target: Node) -> void:
	if primary_target == null or not is_instance_valid(primary_target):
		return
	if not primary_target is Node2D:
		return
	var origin: Vector2 = (primary_target as Node2D).global_position
	var best: Node = null
	var best_dist: float = 999999.0
	for node: Node in get_tree().get_nodes_in_group("iso_test_enemy"):
		if node == primary_target or node == null or not is_instance_valid(node):
			continue
		if not node is Node2D:
			continue
		if not node.has_method("take_damage"):
			continue
		var dist: float = origin.distance_to((node as Node2D).global_position)
		if dist <= 180.0 and dist < best_dist:
			best = node
			best_dist = dist
	if best != null:
		_t004_call_damage_method(best, 1, origin, ((best as Node2D).global_position - origin).normalized(), 60.0, "azazel_chain_echo")

func _t009_update_bound_step_dash_slow() -> void:
	if not _t009_has_azazel_boon("azazel_bound_step"):
		return
	if not has_method("_is_dash_invulnerable"):
		return
	var dash_active: bool = bool(call("_is_dash_invulnerable"))
	if not dash_active:
		t009_bound_step_touched.clear()
		return
	for node: Node in get_tree().get_nodes_in_group("iso_test_enemy"):
		if node == null or not is_instance_valid(node):
			continue
		if not node is Node2D:
			continue
		var key: String = str(node.get_instance_id())
		if t009_bound_step_touched.has(key):
			continue
		if global_position.distance_to((node as Node2D).global_position) <= 48.0:
			t009_bound_step_touched[key] = true
			if node.has_method("apply_azazel_slow"):
				node.call("apply_azazel_slow", 1.5, 0.55)

func receive_run_boon(payload: Dictionary) -> void:
	var patron_id: String = str(payload.get("patron_id", ""))
	var boon_id: String = str(payload.get("boon_id", payload.get("id", "")))
	if patron_id != "patron_azazel_chains":
		return
	if boon_id == "":
		return
	t009_owned_boons[boon_id] = payload.duplicate(true)
	print("[T009] Azazel boon received: %s" % boon_id)

func _t009_has_boon_token(token: String) -> bool:
	for raw_key: Variant in t009_owned_boons.keys():
		var boon_id: String = str(raw_key)
		if boon_id.find(token) >= 0:
			return true
	return false

func _t009_is_q_attack_kind(attack_kind: String) -> bool:
	var kind: String = attack_kind.to_lower()
	return kind.find("q") >= 0 or kind.find("riposte") >= 0 or kind.find("cleave") >= 0

func _t009_is_heavy_attack_kind(attack_kind: String) -> bool:
	var kind: String = attack_kind.to_lower()
	return kind.find("heavy") >= 0 or kind.find("grave") >= 0

func _t009_is_ultimate_attack_kind(attack_kind: String) -> bool:
	var kind: String = attack_kind.to_lower()
	return kind.find("ultimate") >= 0 or kind.find("judgment") >= 0 or kind.find("break") >= 0

func _t009_apply_light_attack_damage(target: Node, base_damage: int) -> void:
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("take_damage"):
		return
	target.call("take_damage", base_damage)
	_t009_on_light_hit(target)

func _t009_apply_heavy_attack_damage(target: Node, base_damage: int) -> void:
	var final_damage: int = _t009_apply_heavy_modifiers_to_damage(target, base_damage)
	if target != null and is_instance_valid(target) and target.has_method("take_damage"):
		target.call("take_damage", final_damage)

func _t009_apply_heavy_modifiers_to_damage(target: Node, base_damage: int) -> int:
	var final_damage: int = base_damage
	var consumed_mark: bool = false
	if target != null and is_instance_valid(target) and target.has_method("t009_consume_azazel_mark"):
		consumed_mark = bool(target.call("t009_consume_azazel_mark"))
	elif target != null and is_instance_valid(target) and bool(target.get_meta("t009_azazel_marked", false)):
		target.set_meta("t009_azazel_marked", false)
		consumed_mark = true
	if consumed_mark and _t009_has_boon_token("riposte_mark"):
		final_damage += 2
	if _t009_has_boon_token("heavy_bonus") or _t009_has_boon_token("chain_stagger"):
		if target != null and is_instance_valid(target) and target.has_method("t009_add_stagger_pressure"):
			target.call("t009_add_stagger_pressure", 35.0)
	if _t009_has_boon_token("chain_stagger"):
		final_damage += 1
	if _t009_has_boon_token("dash_bind") or _t009_has_boon_token("root"):
		if target != null and is_instance_valid(target) and target.has_method("t009_pull_toward"):
			target.call("t009_pull_toward", global_position, 145.0)
	return final_damage

func _t009_on_light_hit(target: Node) -> void:
	if not _t009_has_boon_token("echo_lash"):
		return
	t009_light_hit_count += 1
	if t009_light_hit_count % 3 != 0:
		return
	var enemies: Array[Node] = get_tree().get_nodes_in_group("iso_test_enemy")
	var best_target: Node = null
	var best_distance: float = INF
	for enemy_node: Node in enemies:
		if enemy_node == target:
			continue
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if not enemy_node is Node2D:
			continue
		if not enemy_node.has_method("take_damage"):
			continue
		var distance: float = global_position.distance_to((enemy_node as Node2D).global_position)
		if distance < 190.0 and distance < best_distance:
			best_distance = distance
			best_target = enemy_node
	if best_target != null:
		best_target.call("take_damage", 1)
		if best_target.has_method("t009_apply_slow"):
			best_target.call("t009_apply_slow", 0.70, 0.8)

func _t009_on_q_hit(target: Node) -> void:
	if not _t009_has_boon_token("riposte_mark"):
		return
	if target == null or not is_instance_valid(target):
		return
	target.set_meta("t009_azazel_marked", true)
	if target.has_method("t009_apply_azazel_mark"):
		target.call("t009_apply_azazel_mark", 5.0)

func _t009_on_ultimate_hit(target: Node) -> void:
	if not _t009_has_boon_token("ultimate_shackle"):
		return
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("t009_apply_root"):
		target.call("t009_apply_root", 2.0)
	else:
		target.set_meta("t009_azazel_rooted", true)

func _t009_update_azazel_dash_effects(delta: float) -> void:
	if t009_bound_step_cooldown > 0.0:
		t009_bound_step_cooldown = maxf(0.0, t009_bound_step_cooldown - delta)
	if not _t009_has_boon_token("dash_bind"):
		return
	if t009_bound_step_cooldown > 0.0:
		return
	if not has_method("_is_dash_invulnerable"):
		return
	if not _is_dash_invulnerable():
		return
	var enemies: Array[Node] = get_tree().get_nodes_in_group("iso_test_enemy")
	for enemy_node: Node in enemies:
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if not enemy_node is Node2D:
			continue
		if global_position.distance_to((enemy_node as Node2D).global_position) <= 56.0:
			if enemy_node.has_method("t009_apply_slow"):
				enemy_node.call("t009_apply_slow", 0.45, 1.25)
			t009_bound_step_cooldown = 0.18
