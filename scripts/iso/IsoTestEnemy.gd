extends Node2D
class_name IsoTestEnemy


# T-006 enemy interaction state. Placeholder logic until final enemy art/animations exist.
var t006_stagger_value: float = 0.0
var t006_stagger_threshold: float = 100.0
var t006_stagger_recover_rate: float = 24.0
var t006_stagger_timer: float = 0.0
var t006_hit_react_timer: float = 0.0
var t006_vulnerability_timer: float = 0.0
var t006_last_player_attack_kind: String = ""
var t006_base_modulate: Color = Color.WHITE
var t006_base_modulate_captured: bool = false


const INFERNAL_AUDIO_SCRIPT: Script = preload("res://scripts/audio/InfernalAudio.gd")

signal died(enemy: Node)
signal damaged(amount: int, remaining_health: int)
signal feel_event(event_name: String, strength: float, world_position: Vector2)

enum EnemyState { IDLE, CHASE, WINDUP, ACTIVE, RECOVERY }

@export_enum("ash_grunt", "cinder_lunger", "ember_spitter", "chainbound_penitent", "furnace_imp", "bell_wretch") var enemy_type: String = "ash_grunt"
@export var max_health: int = 3
@export var move_enabled: bool = true
@export var move_speed: float = 55.0
@export var aggro_radius: float = 360.0
@export var leash_radius: float = 720.0

@export_category("Attack Telegraph")
@export var attack_enabled: bool = true
@export var attack_damage: int = 1
@export var attack_range: float = 58.0
@export var attack_hit_radius: float = 50.0
@export var attack_arc_degrees: float = 110.0
@export var attack_windup_duration: float = 0.45
@export var attack_active_duration: float = 0.14
@export var attack_recovery_duration: float = 0.58
@export var attack_cooldown: float = 0.72
@export var attack_player_knockback_force: float = 170.0

@export_category("Lunge")
@export var lunge_enabled: bool = false
@export var lunge_range: float = 210.0
@export var lunge_speed: float = 360.0
@export var lunge_duration: float = 0.18

@export_category("Spitter")
@export var projectile_enabled: bool = false
@export var projectile_range: float = 310.0
@export var projectile_speed: float = 175.0
@export var projectile_radius: float = 13.0
@export var projectile_lifetime: float = 2.6
@export var desired_spacing: float = 210.0
@export var spacing_dead_zone: float = 34.0

@export_category("Contact Damage")
@export var contact_damage_enabled: bool = false
@export var contact_damage: int = 1
@export var contact_radius: float = 34.0
@export var contact_damage_cooldown: float = 0.75

@export_category("Hit Reaction")
@export var hit_flash_duration: float = 0.14
@export var knockback_enabled: bool = true
@export var light_knockback_speed: float = 145.0
@export var heavy_knockback_speed: float = 230.0
@export var knockback_duration: float = 0.10
@export var death_free_delay: float = 0.20

@export_category("Readability")
@export var show_readability_labels: bool = true
@export var telegraph_warning_alpha: float = 0.62
@export var telegraph_active_alpha: float = 0.88
@export var telegraph_line_width: float = 4.0
@export var telegraph_lane_width: float = 32.0
@export var telegraph_label_font_size: int = 11
@export var role_marker_enabled: bool = true

@export_category("Support Role")
@export var support_pulse_enabled: bool = false
@export var support_pulse_range: float = 190.0
@export var support_pulse_strength: float = 0.35

@export_category("Feel Polish")
@export var spawn_intro_enabled: bool = true
@export var spawn_intro_duration: float = 0.34
@export var hit_burst_duration: float = 0.18
@export var death_burst_duration: float = 0.34
@export var attack_commit_flash_duration: float = 0.10
@export var telegraph_pulse_speed: float = 11.0
@export var feel_event_hooks_enabled: bool = true

@export_category("Debug")
@export var show_debug_contact_radius: bool = false
@export var show_debug_aggro_radius: bool = false
@export var show_debug_attack_range: bool = false
@export var show_debug_active_hitbox: bool = false

var health: int = 3
var is_dead: bool = false

var _state: EnemyState = EnemyState.IDLE
var _state_timer: float = 0.0
var _cooldown_remaining: float = 0.0
var _attack_has_hit_player: bool = false
var _attack_direction: Vector2 = Vector2.DOWN
var _spawn_position: Vector2 = Vector2.ZERO

var _hit_flash_remaining: float = 0.0
var _contact_cooldown_remaining: float = 0.0
var _knockback_remaining: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _damage_numbers: Array[Dictionary] = []
var _death_free_remaining: float = -1.0
var _support_pulse_remaining: float = 0.0
var _spawn_intro_remaining: float = 0.0
var _hit_burst_remaining: float = 0.0
var _death_burst_remaining: float = 0.0
var _attack_commit_flash_remaining: float = 0.0
var _visual_time: float = 0.0

func _ready() -> void:
	_spawn_position = global_position
	apply_encounter_profile(enemy_type)
	health = max_health
	add_to_group("iso_test_enemy")
	_spawn_intro_remaining = spawn_intro_duration if spawn_intro_enabled else 0.0
	_emit_feel_event("enemy_spawn", 0.35)
	queue_redraw()

func configure_for_encounter_type(profile_name: String, wave_index: int = 1) -> void:
	enemy_type = profile_name
	apply_encounter_profile(enemy_type)
	# Small per-cycle scaling without turning this into a balance problem.
	if wave_index >= 4:
		max_health += 1
		health = max_health
		attack_cooldown = maxf(0.48, attack_cooldown - 0.05)

func apply_encounter_profile(profile_name: String) -> void:
	# V18 enemy roster rule: every enemy has one clear role, one readable attack, and one visual identity marker.
	support_pulse_enabled = false
	_support_pulse_remaining = 0.0
	if profile_name == "cinder_lunger":
		enemy_type = "cinder_lunger"
		max_health = 3
		move_enabled = true
		move_speed = 66.0
		aggro_radius = 420.0
		attack_damage = 1
		attack_range = 185.0
		attack_hit_radius = 54.0
		attack_arc_degrees = 90.0
		attack_windup_duration = 0.64
		attack_active_duration = 0.20
		attack_recovery_duration = 0.80
		attack_cooldown = 1.12
		attack_player_knockback_force = 230.0
		lunge_enabled = true
		lunge_range = 230.0
		lunge_speed = 345.0
		lunge_duration = 0.18
		projectile_enabled = false
		contact_damage_enabled = false
		return
	if profile_name == "ember_spitter":
		enemy_type = "ember_spitter"
		max_health = 2
		move_enabled = true
		move_speed = 48.0
		aggro_radius = 500.0
		attack_damage = 1
		attack_range = 300.0
		attack_hit_radius = 30.0
		attack_arc_degrees = 35.0
		attack_windup_duration = 0.78
		attack_active_duration = 0.10
		attack_recovery_duration = 0.92
		attack_cooldown = 1.38
		attack_player_knockback_force = 155.0
		lunge_enabled = false
		projectile_enabled = true
		projectile_range = 330.0
		projectile_speed = 165.0
		projectile_radius = 12.0
		desired_spacing = 225.0
		spacing_dead_zone = 40.0
		contact_damage_enabled = false
		return
	if profile_name == "chainbound_penitent":
		enemy_type = "chainbound_penitent"
		max_health = 5
		move_enabled = true
		move_speed = 34.0
		aggro_radius = 380.0
		attack_damage = 2
		attack_range = 82.0
		attack_hit_radius = 72.0
		attack_arc_degrees = 135.0
		attack_windup_duration = 1.02
		attack_active_duration = 0.20
		attack_recovery_duration = 1.06
		attack_cooldown = 1.52
		attack_player_knockback_force = 255.0
		lunge_enabled = false
		projectile_enabled = false
		contact_damage_enabled = false
		light_knockback_speed = 80.0
		heavy_knockback_speed = 135.0
		return
	if profile_name == "furnace_imp":
		enemy_type = "furnace_imp"
		max_health = 1
		move_enabled = true
		move_speed = 100.0
		aggro_radius = 400.0
		attack_damage = 1
		attack_range = 44.0
		attack_hit_radius = 42.0
		attack_arc_degrees = 95.0
		attack_windup_duration = 0.36
		attack_active_duration = 0.10
		attack_recovery_duration = 0.42
		attack_cooldown = 0.68
		attack_player_knockback_force = 120.0
		lunge_enabled = false
		projectile_enabled = false
		contact_damage_enabled = false
		light_knockback_speed = 210.0
		heavy_knockback_speed = 285.0
		return
	if profile_name == "bell_wretch":
		enemy_type = "bell_wretch"
		max_health = 2
		move_enabled = true
		move_speed = 44.0
		aggro_radius = 470.0
		attack_damage = 0
		attack_range = 285.0
		attack_hit_radius = 190.0
		attack_arc_degrees = 360.0
		attack_windup_duration = 0.86
		attack_active_duration = 0.16
		attack_recovery_duration = 1.10
		attack_cooldown = 1.90
		attack_player_knockback_force = 90.0
		lunge_enabled = false
		projectile_enabled = false
		contact_damage_enabled = false
		support_pulse_enabled = true
		support_pulse_range = 190.0
		support_pulse_strength = 0.32
		desired_spacing = 245.0
		spacing_dead_zone = 52.0
		return
	enemy_type = "ash_grunt"
	max_health = 3
	move_enabled = true
	move_speed = 54.0
	aggro_radius = 360.0
	attack_damage = 1
	attack_range = 62.0
	attack_hit_radius = 54.0
	attack_arc_degrees = 115.0
	attack_windup_duration = 0.52
	attack_active_duration = 0.14
	attack_recovery_duration = 0.66
	attack_cooldown = 0.86
	attack_player_knockback_force = 170.0
	lunge_enabled = false
	projectile_enabled = false
	contact_damage_enabled = false
	light_knockback_speed = 145.0
	heavy_knockback_speed = 230.0

func _process(delta: float) -> void:
	_t006_update_enemy_interaction(delta)
	_visual_time += delta
	_update_timers(delta)
	_update_damage_numbers(delta)

	if is_dead:
		if _death_free_remaining >= 0.0:
			_death_free_remaining -= delta
			if _death_free_remaining <= 0.0:
				queue_free()
		queue_redraw()
		return

	if _spawn_intro_remaining > 0.0:
		queue_redraw()
		return

	if _knockback_remaining > 0.0:
		global_position += _knockback_velocity * delta
		_knockback_remaining = maxf(0.0, _knockback_remaining - delta)
		queue_redraw()
		return

	_update_enemy_brain(delta)
	_update_contact_damage()
	queue_redraw()

func _update_timers(delta: float) -> void:
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = maxf(0.0, _hit_flash_remaining - delta)
	if _contact_cooldown_remaining > 0.0:
		_contact_cooldown_remaining = maxf(0.0, _contact_cooldown_remaining - delta)
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	if _support_pulse_remaining > 0.0:
		_support_pulse_remaining = maxf(0.0, _support_pulse_remaining - delta)
	if _spawn_intro_remaining > 0.0:
		_spawn_intro_remaining = maxf(0.0, _spawn_intro_remaining - delta)
	if _hit_burst_remaining > 0.0:
		_hit_burst_remaining = maxf(0.0, _hit_burst_remaining - delta)
	if _death_burst_remaining > 0.0:
		_death_burst_remaining = maxf(0.0, _death_burst_remaining - delta)
	if _attack_commit_flash_remaining > 0.0:
		_attack_commit_flash_remaining = maxf(0.0, _attack_commit_flash_remaining - delta)

func _update_enemy_brain(delta: float) -> void:
	if not attack_enabled:
		if move_enabled:
			_update_simple_chase(delta)
		return
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if not (player_node is Node2D):
		_state = EnemyState.IDLE
		return
	var player_2d: Node2D = player_node as Node2D
	var to_player: Vector2 = player_2d.global_position - global_position
	var distance: float = to_player.length()
	if distance > leash_radius:
		_state = EnemyState.IDLE
		return

	match _state:
		EnemyState.IDLE:
			if distance <= aggro_radius:
				_state = EnemyState.CHASE
		EnemyState.CHASE:
			_update_chase_or_spacing(delta, player_2d, to_player, distance)
			if _can_start_attack(distance):
				_start_windup(to_player)
		EnemyState.WINDUP:
			_state_timer -= delta
			if to_player.length() > 0.01:
				_attack_direction = to_player.normalized()
			if _state_timer <= 0.0:
				_start_active()
		EnemyState.ACTIVE:
			_state_timer -= delta
			_update_active_attack(delta, player_2d)
			if _state_timer <= 0.0:
				_start_recovery()
		EnemyState.RECOVERY:
			_state_timer -= delta
			if _state_timer <= 0.0:
				_state = EnemyState.CHASE

func _can_start_attack(distance: float) -> bool:
	if _cooldown_remaining > 0.0:
		return false
	if projectile_enabled:
		return distance <= projectile_range
	if lunge_enabled:
		return distance <= lunge_range
	return distance <= attack_range

func _start_windup(to_player: Vector2) -> void:
	_audio_event("enemy_attack_warning")
	_state = EnemyState.WINDUP
	_state_timer = attack_windup_duration
	_attack_has_hit_player = false
	if to_player.length() > 0.01:
		_attack_direction = to_player.normalized()

func _start_active() -> void:
	_state = EnemyState.ACTIVE
	_attack_commit_flash_remaining = attack_commit_flash_duration
	_emit_feel_event("enemy_attack_active", 0.42)
	_state_timer = lunge_duration if lunge_enabled else attack_active_duration
	_attack_has_hit_player = false
	if projectile_enabled:
		_fire_projectile()
		_attack_has_hit_player = true

func _start_recovery() -> void:
	_state = EnemyState.RECOVERY
	_state_timer = attack_recovery_duration
	_cooldown_remaining = attack_cooldown

func _update_active_attack(delta: float, player_2d: Node2D) -> void:
	if lunge_enabled:
		global_position += _attack_direction * lunge_speed * delta
	if support_pulse_enabled:
		_apply_support_pulse()
		return
	if projectile_enabled:
		return
	if _attack_has_hit_player:
		return
	if not _is_player_inside_attack_hitbox(player_2d):
		return
	_attack_has_hit_player = true
	var hit_direction: Vector2 = _attack_direction
	if hit_direction.length() <= 0.01:
		hit_direction = (player_2d.global_position - global_position).normalized()
	if player_2d.has_method("receive_enemy_attack"):
		player_2d.call("receive_enemy_attack", attack_damage, global_position, hit_direction, attack_player_knockback_force)
	elif player_2d.has_method("take_damage"):
		player_2d.call("take_damage", attack_damage)

func _is_player_inside_attack_hitbox(player_2d: Node2D) -> bool:
	var to_player: Vector2 = player_2d.global_position - global_position
	var distance: float = to_player.length()
	var radius_to_use: float = attack_hit_radius
	if lunge_enabled:
		radius_to_use = maxf(attack_hit_radius, 58.0)
	if distance > radius_to_use:
		return false
	if distance <= 12.0:
		return true
	var facing_normalized: Vector2 = _attack_direction.normalized()
	if facing_normalized.length() <= 0.01:
		return true
	var half_arc: float = deg_to_rad(maxf(attack_arc_degrees, 1.0) * 0.5)
	return absf(facing_normalized.angle_to(to_player.normalized())) <= half_arc

func _fire_projectile() -> void:
	if get_parent() == null:
		return
	var bolt: AshBoltProjectile = AshBoltProjectile.new()
	bolt.name = "AshBoltProjectile"
	get_parent().add_child(bolt)
	bolt.setup(global_position + _attack_direction * 22.0, _attack_direction, projectile_speed, attack_damage, projectile_lifetime, projectile_radius, attack_player_knockback_force)

func _apply_support_pulse() -> void:
	if _attack_has_hit_player:
		return
	_attack_has_hit_player = true
	_support_pulse_remaining = 0.24
	var enemies: Array = get_tree().get_nodes_in_group("iso_test_enemy")
	for node: Node in enemies:
		if node == self:
			continue
		if not (node is Node and node.is_in_group("iso_test_enemy")):
			continue
		var enemy: Node = node
		if enemy.is_dead:
			continue
		if global_position.distance_to(enemy.global_position) <= support_pulse_range:
			enemy.receive_support_pulse(global_position, support_pulse_strength)
	_audio_event("enemy_attack_active")
	_spawn_damage_number("BELL", Color("#d8b66a"))

func receive_support_pulse(source_global_position: Vector2, strength: float = 0.35) -> void:
	if is_dead:
		return
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - strength)
	if _state == EnemyState.IDLE:
		_state = EnemyState.CHASE
	_hit_flash_remaining = maxf(_hit_flash_remaining, 0.08)
	_spawn_damage_number("Roused", Color("#d8b66a"))

func _update_chase_or_spacing(delta: float, player_2d: Node2D, to_player: Vector2, distance: float) -> void:
	if not move_enabled:
		return
	if projectile_enabled or support_pulse_enabled:
		if distance < desired_spacing - spacing_dead_zone and distance > 0.01:
			global_position -= to_player.normalized() * move_speed * delta
		elif distance > desired_spacing + spacing_dead_zone and distance <= aggro_radius:
			global_position += to_player.normalized() * move_speed * delta
		return
	if distance <= attack_range * 0.78 and not lunge_enabled:
		return
	if distance <= aggro_radius and distance > 4.0:
		global_position += to_player.normalized() * move_speed * delta

func _update_damage_numbers(delta: float) -> void:
	for i: int in range(_damage_numbers.size() - 1, -1, -1):
		var number_data: Dictionary = _damage_numbers[i]
		number_data["life"] = float(number_data.get("life", 0.0)) - delta
		number_data["offset"] = (number_data.get("offset", Vector2.ZERO) as Vector2) + Vector2(0.0, -30.0 * delta)
		_damage_numbers[i] = number_data
		if float(number_data.get("life", 0.0)) <= 0.0:
			_damage_numbers.remove_at(i)

func receive_player_hit(amount: int, source_global_position: Vector2, hit_direction: Vector2, attack_anim: String = "attack") -> void:
	if is_dead:
		return
	_apply_knockback(source_global_position, hit_direction, attack_anim)
	take_damage(amount)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	var final_amount: int = maxi(0, amount)
	if final_amount <= 0:
		return
	health = max(0, health - final_amount)
	_hit_flash_remaining = hit_flash_duration
	_hit_burst_remaining = hit_burst_duration
	_emit_feel_event("enemy_hit", 0.55)
	_spawn_damage_number("-" + str(final_amount), Color("#f2d27b"))
	emit_signal("damaged", final_amount, health)
	if health <= 0:
		_die()
	else:
		queue_redraw()

func _apply_knockback(source_global_position: Vector2, hit_direction: Vector2, attack_anim: String) -> void:
	if not knockback_enabled:
		return
	var away: Vector2 = global_position - source_global_position
	if away.length() <= 0.01:
		away = hit_direction
	if away.length() <= 0.01:
		return
	var speed: float = heavy_knockback_speed if attack_anim == "heavy_attack" else light_knockback_speed
	_knockback_velocity = away.normalized() * speed
	_knockback_remaining = knockback_duration
	# Getting hit interrupts enemy windups, so the player can stagger enemies.
	if _state == EnemyState.WINDUP:
		_state = EnemyState.RECOVERY
		_state_timer = minf(attack_recovery_duration, 0.24)

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	_hit_flash_remaining = hit_flash_duration
	_hit_burst_remaining = hit_burst_duration
	_emit_feel_event("enemy_hit", 0.55)
	_death_burst_remaining = death_burst_duration
	_spawn_damage_number("SLAIN", Color("#d06b4c"))
	_emit_feel_event("enemy_death", 0.75)
	emit_signal("died", self)
	_death_free_remaining = death_free_delay
	queue_redraw()

func _update_contact_damage() -> void:
	if not contact_damage_enabled:
		return
	if _contact_cooldown_remaining > 0.0:
		return
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if not (player_node is Node2D):
		return
	var player_2d: Node2D = player_node as Node2D
	if global_position.distance_to(player_2d.global_position) > contact_radius:
		return
	var direction_to_player: Vector2 = player_2d.global_position - global_position
	if player_node.has_method("receive_enemy_attack"):
		var result: Variant = player_node.call("receive_enemy_attack", contact_damage, global_position, direction_to_player, attack_player_knockback_force)
		if result is bool and result:
			_contact_cooldown_remaining = contact_damage_cooldown
	elif player_node.has_method("take_damage"):
		var fallback_result: Variant = player_node.call("take_damage", contact_damage)
		if fallback_result is bool:
			if fallback_result:
				_contact_cooldown_remaining = contact_damage_cooldown
		else:
			_contact_cooldown_remaining = contact_damage_cooldown

func _update_simple_chase(delta: float) -> void:
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if not (player_node is Node2D):
		return
	var player_2d: Node2D = player_node as Node2D
	var to_player: Vector2 = player_2d.global_position - global_position
	if to_player.length() <= aggro_radius and to_player.length() > 4.0:
		global_position += to_player.normalized() * move_speed * delta

func _draw() -> void:
	_draw_filled_ellipse(Rect2(Vector2(-20.0, 12.0), Vector2(40.0, 13.0)), Color(0.0, 0.0, 0.0, 0.34))
	_draw_spawn_intro()

	var body_color: Color = Color("#34201e")
	var outline_color: Color = Color("#c76b3a")
	var eye_color: Color = Color("#f08a32")
	if enemy_type == "cinder_lunger":
		body_color = Color("#3a1714")
		outline_color = Color("#df623d")
		eye_color = Color("#ffd06a")
	elif enemy_type == "ember_spitter":
		body_color = Color("#251b30")
		outline_color = Color("#b06cff")
		eye_color = Color("#ffb25a")
	elif enemy_type == "chainbound_penitent":
		body_color = Color("#2a2723")
		outline_color = Color("#a98a55")
		eye_color = Color("#f05f34")
	elif enemy_type == "furnace_imp":
		body_color = Color("#2d1511")
		outline_color = Color("#ff8f35")
		eye_color = Color("#ffe08a")
	elif enemy_type == "bell_wretch":
		body_color = Color("#2c2418")
		outline_color = Color("#d8b66a")
		eye_color = Color("#ffd27a")
	if is_dead:
		body_color = Color("#211512")
		outline_color = Color("#6f382a")
	elif _hit_flash_remaining > 0.0:
		body_color = Color("#f2d0a0")
		outline_color = Color("#ffffff")

	var body: PackedVector2Array = _get_body_shape()
	draw_colored_polygon(body, body_color)
	draw_polyline(PackedVector2Array([body[0], body[1], body[2], body[3], body[4], body[0]]), outline_color, 2.0)
	draw_circle(Vector2(0.0, -35.0), 7.0, Color("#120c0b"))
	draw_circle(Vector2(-4.0, -36.0), 1.5, eye_color)
	draw_circle(Vector2(4.0, -36.0), 1.5, eye_color)

	if enemy_type == "cinder_lunger":
		draw_line(Vector2(-16.0, -4.0), Vector2(16.0, -18.0), Color("#ff8b4c"), 2.0)
		draw_line(Vector2(16.0, -4.0), Vector2(-16.0, -18.0), Color("#ff8b4c"), 2.0)
	elif enemy_type == "ember_spitter":
		draw_arc(Vector2(0.0, -8.0), 18.0, deg_to_rad(210.0), deg_to_rad(330.0), 18, Color("#e58dff"), 2.0)
		draw_circle(Vector2(0.0, -12.0), 4.0, Color("#ffad4a"))
	elif enemy_type == "chainbound_penitent":
		draw_line(Vector2(-24.0, -6.0), Vector2(24.0, -6.0), Color("#b99b66"), 3.0)
		draw_line(Vector2(-18.0, 4.0), Vector2(18.0, 4.0), Color("#6f5a3a"), 2.0)
	elif enemy_type == "furnace_imp":
		draw_line(Vector2(-13.0, -34.0), Vector2(-24.0, -47.0), Color("#ff8f35"), 2.0)
		draw_line(Vector2(13.0, -34.0), Vector2(24.0, -47.0), Color("#ff8f35"), 2.0)
		draw_circle(Vector2(0.0, 11.0), 5.0, Color("#ff5a1f"))
	elif enemy_type == "bell_wretch":
		draw_arc(Vector2(0.0, -15.0), 19.0, deg_to_rad(25.0), deg_to_rad(155.0), 16, Color("#d8b66a"), 3.0)
		draw_line(Vector2(-16.0, 12.0), Vector2(16.0, 12.0), Color("#d8b66a"), 2.5)
		if _support_pulse_remaining > 0.0:
			draw_arc(Vector2.ZERO, support_pulse_range, 0.0, TAU, 64, Color(0.95, 0.72, 0.25, 0.38), 4.0)

	if _attack_commit_flash_remaining > 0.0 and not is_dead:
		var attack_flash_ratio: float = _attack_commit_flash_remaining / maxf(attack_commit_flash_duration, 0.01)
		draw_arc(Vector2.ZERO, attack_hit_radius + 8.0, 0.0, TAU, 42, Color(1.0, 0.58, 0.18, 0.18 * attack_flash_ratio), 3.0)

	if role_marker_enabled and show_readability_labels and not is_dead:
		_draw_role_marker()

	if is_dead:
		draw_line(Vector2(-18.0, -8.0), Vector2(18.0, 12.0), Color("#d06b4c"), 2.5)
		draw_line(Vector2(18.0, -8.0), Vector2(-18.0, 12.0), Color("#d06b4c"), 2.5)

	_draw_feel_bursts()

	_draw_telegraphs()
	_draw_health_bar()
	_draw_damage_numbers()
	if show_debug_contact_radius:
		draw_arc(Vector2.ZERO, contact_radius, 0.0, TAU, 36, Color(1.0, 0.3, 0.2, 0.65), 1.0)
	if show_debug_aggro_radius:
		draw_arc(Vector2.ZERO, aggro_radius, 0.0, TAU, 80, Color(0.2, 0.7, 1.0, 0.35), 1.0)
	if show_debug_attack_range:
		draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 64, Color(1.0, 0.9, 0.25, 0.45), 1.0)
	if show_debug_active_hitbox and _state == EnemyState.ACTIVE:
		draw_arc(Vector2.ZERO, attack_hit_radius, 0.0, TAU, 48, Color(1.0, 0.1, 0.1, 0.75), 2.0)
		draw_line(Vector2.ZERO, _attack_direction.normalized() * attack_hit_radius, Color(1.0, 0.1, 0.1, 0.75), 2.0)

func _draw_telegraphs() -> void:
	if _state == EnemyState.WINDUP:
		var t: float = 1.0
		if attack_windup_duration > 0.0:
			t = clampf(1.0 - (_state_timer / attack_windup_duration), 0.0, 1.0)
		if support_pulse_enabled:
			_draw_support_warning(t)
		elif projectile_enabled:
			_draw_projectile_warning(t)
		elif lunge_enabled:
			_draw_lunge_warning(t)
		else:
			_draw_melee_warning(t)
	elif _state == EnemyState.ACTIVE:
		if support_pulse_enabled:
			_draw_support_active()
			return
		if projectile_enabled:
			return
		if lunge_enabled:
			_draw_lunge_active()
		else:
			_draw_melee_active()

func _draw_melee_warning(progress: float) -> void:
	var pulse: float = 0.5 + 0.5 * sin(_visual_time * telegraph_pulse_speed)
	var fill: Color = Color(1.0, 0.44, 0.10, 0.22 + telegraph_warning_alpha * 0.36 * progress + 0.08 * pulse)
	_draw_warning_cone(attack_hit_radius, attack_arc_degrees, fill, Color(1.0, 0.80, 0.28, 0.82), telegraph_line_width)
	_draw_tick_ring(attack_hit_radius + 9.0, progress, Color(1.0, 0.72, 0.24, 0.78))
	if show_readability_labels:
		var label: String = "SWIPE"
		if enemy_type == "chainbound_penitent":
			label = "HEAVY"
		elif enemy_type == "furnace_imp":
			label = "NIP"
		_draw_telegraph_label(label, _attack_direction.normalized() * (attack_hit_radius + 22.0), Color(1.0, 0.82, 0.36, 0.95))

func _draw_melee_active() -> void:
	_draw_warning_cone(attack_hit_radius, attack_arc_degrees, Color(1.0, 0.04, 0.02, 0.48), Color(1.0, 0.92, 0.40, telegraph_active_alpha), telegraph_line_width + 1.0)

func _draw_lunge_warning(progress: float) -> void:
	var dir: Vector2 = _attack_direction.normalized()
	var length: float = lunge_range
	var half_width: float = telegraph_lane_width * 0.5
	var side: Vector2 = Vector2(-dir.y, dir.x)
	var end_point: Vector2 = dir * length
	var pts: PackedVector2Array = PackedVector2Array([side * half_width, end_point + side * half_width, end_point - side * half_width, -side * half_width])
	var pulse: float = 0.5 + 0.5 * sin(_visual_time * telegraph_pulse_speed)
	draw_colored_polygon(pts, Color(1.0, 0.16, 0.06, 0.18 + 0.26 * progress + 0.08 * pulse))
	draw_line(side * half_width, end_point + side * half_width, Color(1.0, 0.58, 0.18, 0.80), telegraph_line_width)
	draw_line(-side * half_width, end_point - side * half_width, Color(1.0, 0.58, 0.18, 0.80), telegraph_line_width)
	draw_line(Vector2.ZERO, end_point, Color(1.0, 0.28, 0.12, 0.55 + 0.25 * progress), maxf(2.0, telegraph_line_width - 1.0))
	_draw_tick_ring(22.0 + 10.0 * progress, progress, Color(1.0, 0.72, 0.24, 0.82))
	draw_circle(end_point, 10.0 + 6.0 * progress, Color(1.0, 0.30, 0.10, 0.30 + 0.25 * progress))
	if show_readability_labels:
		_draw_telegraph_label("LUNGE", dir * minf(length, 116.0) + Vector2(0.0, -18.0), Color(1.0, 0.78, 0.28, 0.96))

func _draw_lunge_active() -> void:
	var dir: Vector2 = _attack_direction.normalized()
	var length: float = maxf(attack_hit_radius, 64.0)
	var half_width: float = telegraph_lane_width * 0.5
	var side: Vector2 = Vector2(-dir.y, dir.x)
	var end_point: Vector2 = dir * length
	var pts: PackedVector2Array = PackedVector2Array([side * half_width, end_point + side * half_width, end_point - side * half_width, -side * half_width])
	draw_colored_polygon(pts, Color(1.0, 0.04, 0.02, 0.42))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(1.0, 0.92, 0.36, telegraph_active_alpha), telegraph_line_width + 1.0)

func _draw_projectile_warning(progress: float) -> void:
	var dir: Vector2 = _attack_direction.normalized()
	var length: float = projectile_range
	var side: Vector2 = Vector2(-dir.y, dir.x)
	var half_width: float = 11.0
	var end_point: Vector2 = dir * length
	draw_line(side * half_width, end_point + side * half_width, Color(1.0, 0.48, 0.14, 0.34 + 0.26 * progress), 2.5)
	draw_line(-side * half_width, end_point - side * half_width, Color(1.0, 0.48, 0.14, 0.34 + 0.26 * progress), 2.5)
	var pulse: float = 0.5 + 0.5 * sin(_visual_time * telegraph_pulse_speed)
	draw_line(Vector2.ZERO, end_point, Color(1.0, 0.82, 0.36, 0.30 + 0.40 * progress + 0.10 * pulse), telegraph_line_width)
	draw_arc(Vector2.ZERO, 22.0 + 14.0 * progress, 0.0, TAU, 28, Color(1.0, 0.65, 0.22, 0.86), 3.0)
	draw_circle(Vector2.ZERO, 7.0 + 4.0 * progress, Color(1.0, 0.38, 0.10, 0.72))
	if show_readability_labels:
		_draw_telegraph_label("SHOT", dir * 88.0 + Vector2(0.0, -18.0), Color(1.0, 0.82, 0.36, 0.96))

func _draw_warning_cone(radius: float, arc_degrees: float, fill_color: Color, outline_color: Color = Color(1.0, 0.78, 0.22, 0.88), outline_width: float = 3.0) -> void:
	var facing_angle: float = _attack_direction.angle()
	var half_arc: float = deg_to_rad(arc_degrees * 0.5)
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2.ZERO)
	var steps: int = 18
	for i: int in range(steps + 1):
		var ratio: float = float(i) / float(steps)
		var angle: float = facing_angle - half_arc + (half_arc * 2.0 * ratio)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, fill_color)
	draw_polyline(points, outline_color, outline_width)
	draw_line(Vector2.ZERO, _attack_direction.normalized() * radius, Color(outline_color.r, outline_color.g, outline_color.b, minf(1.0, outline_color.a + 0.10)), maxf(1.0, outline_width - 1.0))

func _draw_tick_ring(radius: float, progress: float, color: Color) -> void:
	var total: int = 10
	var lit: int = int(ceil(float(total) * clampf(progress, 0.0, 1.0)))
	for i: int in range(total):
		var a: float = TAU * float(i) / float(total)
		var p1: Vector2 = Vector2(cos(a), sin(a)) * radius
		var p2: Vector2 = Vector2(cos(a), sin(a)) * (radius + 8.0)
		var c: Color = color if i < lit else Color(0.45, 0.18, 0.10, 0.42)
		draw_line(p1, p2, c, 2.0)

func _draw_telegraph_label(text: String, pos: Vector2, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var bg: Rect2 = Rect2(pos + Vector2(-34.0, -telegraph_label_font_size - 5.0), Vector2(68.0, float(telegraph_label_font_size + 8)))
	draw_rect(bg, Color(0.05, 0.025, 0.015, 0.74), true)
	draw_rect(bg, Color(color.r, color.g, color.b, 0.70), false, 1.0)
	draw_string(font, pos + Vector2(-34.0, -4.0), text, HORIZONTAL_ALIGNMENT_CENTER, 68.0, telegraph_label_font_size, color)

func _get_body_shape() -> PackedVector2Array:
	if enemy_type == "chainbound_penitent":
		return PackedVector2Array([Vector2(0.0, -39.0), Vector2(25.0, -9.0), Vector2(20.0, 24.0), Vector2(-20.0, 24.0), Vector2(-25.0, -9.0)])
	if enemy_type == "furnace_imp":
		return PackedVector2Array([Vector2(0.0, -29.0), Vector2(14.0, -5.0), Vector2(9.0, 14.0), Vector2(-9.0, 14.0), Vector2(-14.0, -5.0)])
	if enemy_type == "bell_wretch":
		return PackedVector2Array([Vector2(0.0, -34.0), Vector2(21.0, -10.0), Vector2(16.0, 22.0), Vector2(-16.0, 22.0), Vector2(-21.0, -10.0)])
	return PackedVector2Array([Vector2(0.0, -32.0), Vector2(18.0, -8.0), Vector2(12.0, 18.0), Vector2(-12.0, 18.0), Vector2(-18.0, -8.0)])

func _get_role_text() -> String:
	match enemy_type:
		"ash_grunt":
			return "GRUNT"
		"cinder_lunger":
			return "LUNGER"
		"ember_spitter":
			return "SPITTER"
		"chainbound_penitent":
			return "ARMORED"
		"furnace_imp":
			return "IMP"
		"bell_wretch":
			return "SUPPORT"
	return "ENEMY"

func _draw_role_marker() -> void:
	var font: Font = ThemeDB.fallback_font
	var text: String = _get_role_text()
	var pos: Vector2 = Vector2(-34.0, -76.0)
	draw_rect(Rect2(pos, Vector2(68.0, 15.0)), Color(0.03, 0.018, 0.012, 0.62), true)
	draw_string(font, pos + Vector2(0.0, 12.0), text, HORIZONTAL_ALIGNMENT_CENTER, 68.0, 9, Color(0.92, 0.72, 0.42, 0.88))

func _draw_support_warning(progress: float) -> void:
	var radius: float = support_pulse_range
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 80, Color(1.0, 0.70, 0.20, 0.34 + 0.24 * progress), telegraph_line_width)
	draw_arc(Vector2.ZERO, radius * 0.62, 0.0, TAU, 64, Color(1.0, 0.52, 0.12, 0.18 + 0.25 * progress), 2.0)
	_draw_tick_ring(24.0 + 12.0 * progress, progress, Color(1.0, 0.76, 0.24, 0.82))
	if show_readability_labels:
		_draw_telegraph_label("BELL", Vector2(-34.0, -support_pulse_range - 12.0), Color(1.0, 0.82, 0.36, 0.96))

func _draw_support_active() -> void:
	draw_arc(Vector2.ZERO, support_pulse_range, 0.0, TAU, 88, Color(1.0, 0.86, 0.24, telegraph_active_alpha), telegraph_line_width + 2.0)
	draw_circle(Vector2.ZERO, 28.0, Color(1.0, 0.68, 0.20, 0.22))

func _draw_health_bar() -> void:
	var hp_width: float = 42.0
	var health_ratio: float = clampf(float(health) / float(max_health), 0.0, 1.0) if max_health > 0 else 0.0
	draw_rect(Rect2(Vector2(-21.0, -52.0), Vector2(hp_width, 5.0)), Color(0.0, 0.0, 0.0, 0.65), true)
	draw_rect(Rect2(Vector2(-20.0, -51.0), Vector2((hp_width - 2.0) * health_ratio, 3.0)), Color("#c95438"), true)

func _draw_damage_numbers() -> void:
	var font: Font = ThemeDB.fallback_font
	for number_data: Dictionary in _damage_numbers:
		var life: float = float(number_data.get("life", 0.0))
		var alpha: float = clamp(life / 0.65, 0.0, 1.0)
		var text: String = str(number_data.get("text", "0"))
		var offset: Vector2 = number_data.get("offset", Vector2.ZERO) as Vector2
		var color: Color = number_data.get("color", Color("#f2d27b")) as Color
		color.a = alpha
		draw_string(font, Vector2(-38.0, -68.0) + offset, text, HORIZONTAL_ALIGNMENT_CENTER, 76.0, 14, color)

func _spawn_damage_number(text: String, color: Color) -> void:
	_damage_numbers.append({
		"text": text,
		"life": 0.65,
		"offset": Vector2(randf_range(-8.0, 8.0), 0.0),
		"color": color,
	})

func _draw_spawn_intro() -> void:
	if _spawn_intro_remaining <= 0.0 or not spawn_intro_enabled:
		return
	var ratio: float = clampf(_spawn_intro_remaining / maxf(spawn_intro_duration, 0.01), 0.0, 1.0)
	var expand: float = 1.0 - ratio
	draw_arc(Vector2.ZERO, 18.0 + 36.0 * expand, 0.0, TAU, 48, Color(1.0, 0.58, 0.18, 0.78 * ratio), 3.0)
	draw_line(Vector2(-24.0, 18.0), Vector2(24.0, 18.0), Color(1.0, 0.38, 0.12, 0.45 * ratio), 2.0)

func _draw_feel_bursts() -> void:
	if _hit_burst_remaining > 0.0:
		var hit_ratio: float = _hit_burst_remaining / maxf(hit_burst_duration, 0.01)
		draw_arc(Vector2(0.0, -18.0), 26.0 + (1.0 - hit_ratio) * 18.0, 0.0, TAU, 36, Color(1.0, 0.86, 0.46, 0.72 * hit_ratio), 3.0)
		draw_line(Vector2(-26.0, -18.0), Vector2(26.0, -18.0), Color(1.0, 0.92, 0.66, 0.45 * hit_ratio), 2.0)
	if _death_burst_remaining > 0.0:
		var death_ratio: float = _death_burst_remaining / maxf(death_burst_duration, 0.01)
		draw_arc(Vector2.ZERO, 34.0 + (1.0 - death_ratio) * 42.0, 0.0, TAU, 56, Color(0.95, 0.25, 0.10, 0.70 * death_ratio), 4.0)
		draw_arc(Vector2.ZERO, 22.0 + (1.0 - death_ratio) * 28.0, 0.0, TAU, 40, Color(0.35, 0.12, 0.08, 0.48 * death_ratio), 2.0)

func _emit_feel_event(event_name: String, strength: float = 0.35) -> void:
	if not feel_event_hooks_enabled:
		return
	_audio_event(event_name)
	emit_signal("feel_event", event_name, strength, global_position)

func _audio_event(event_name: String) -> void:
	if INFERNAL_AUDIO_SCRIPT == null:
		return
	INFERNAL_AUDIO_SCRIPT.play_event_from_node(self, event_name, global_position)

func _draw_filled_ellipse(rect: Rect2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(24):
		var angle: float = TAU * float(i) / 24.0
		points.append(rect.position + rect.size * 0.5 + Vector2(cos(angle) * rect.size.x * 0.5, sin(angle) * rect.size.y * 0.5))
	draw_colored_polygon(points, color)


# T-006 — Called by IsoPhysicsTestPlayer before take_damage().
func receive_player_ability_interaction(attack_kind: String = "attack", damage_amount: int = 1, source_position: Vector2 = Vector2.ZERO, hit_direction: Vector2 = Vector2.RIGHT, knockback_force: float = 0.0, stagger_amount: float = 0.0) -> void:
	if not t006_base_modulate_captured:
		t006_base_modulate = modulate
		t006_base_modulate_captured = true

	t006_last_player_attack_kind = attack_kind
	var role_id: String = _t006_get_enemy_role_id()
	var stagger_gain: float = _t006_get_base_stagger_for_attack(attack_kind, stagger_amount)

	if role_id.find("cinder") >= 0 or role_id.find("lunger") >= 0:
		if attack_kind.find("q") >= 0 or attack_kind.find("riposte") >= 0 or attack_kind.find("ultimate") >= 0:
			stagger_gain *= 1.45
	elif role_id.find("ember") >= 0 or role_id.find("spitter") >= 0:
		if attack_kind.find("q") >= 0 or attack_kind.find("ultimate") >= 0:
			stagger_gain *= 1.25
	elif role_id.find("ash") >= 0 or role_id.find("grunt") >= 0:
		if attack_kind.find("heavy") >= 0:
			stagger_gain *= 1.20

	_t006_add_stagger(stagger_gain)
	t006_hit_react_timer = max(t006_hit_react_timer, 0.10)

	if attack_kind.find("ultimate") >= 0:
		t006_vulnerability_timer = max(t006_vulnerability_timer, 1.25)
	elif attack_kind.find("q") >= 0 or attack_kind.find("riposte") >= 0:
		t006_vulnerability_timer = max(t006_vulnerability_timer, 0.65)
	elif attack_kind.find("heavy") >= 0:
		t006_vulnerability_timer = max(t006_vulnerability_timer, 0.35)

	_t006_apply_placeholder_knockback(hit_direction, knockback_force, attack_kind)
	_t006_apply_placeholder_modulate()

func get_player_ability_damage_multiplier(attack_kind: String = "attack") -> float:
	var role_id: String = _t006_get_enemy_role_id()
	var multiplier: float = 1.0
	if t006_stagger_timer > 0.0:
		multiplier += 0.20
	if t006_vulnerability_timer > 0.0:
		multiplier += 0.10
	if role_id.find("cinder") >= 0 or role_id.find("lunger") >= 0:
		if attack_kind.find("q") >= 0 or attack_kind.find("riposte") >= 0:
			multiplier += 0.15
	if role_id.find("ember") >= 0 or role_id.find("spitter") >= 0:
		if attack_kind.find("ultimate") >= 0:
			multiplier += 0.15
	return multiplier

func is_t006_staggered() -> bool:
	return t006_stagger_timer > 0.0

func _t006_add_stagger(amount: float) -> void:
	t006_stagger_value = clamp(t006_stagger_value + amount, 0.0, t006_stagger_threshold)
	if t006_stagger_value >= t006_stagger_threshold:
		t006_stagger_timer = max(t006_stagger_timer, 0.80)
		t006_stagger_value = max(0.0, t006_stagger_threshold * 0.35)

func _t006_get_base_stagger_for_attack(attack_kind: String, explicit_stagger: float) -> float:
	if explicit_stagger > 0.0:
		return explicit_stagger
	if attack_kind.find("ultimate") >= 0:
		return 70.0
	if attack_kind.find("q") >= 0 or attack_kind.find("riposte") >= 0:
		return 42.0
	if attack_kind.find("heavy") >= 0:
		return 36.0
	return 16.0

func _t006_apply_placeholder_knockback(hit_direction: Vector2, knockback_force: float, attack_kind: String) -> void:
	var dir: Vector2 = hit_direction.normalized()
	if dir.length_squared() <= 0.001:
		dir = Vector2.RIGHT
	var force: float = knockback_force
	if force <= 0.0:
		if attack_kind.find("ultimate") >= 0:
			force = 180.0
		elif attack_kind.find("q") >= 0 or attack_kind.find("heavy") >= 0:
			force = 95.0
		else:
			force = 38.0

	if _t006_has_property("velocity"):
		var current_velocity: Variant = get("velocity")
		if typeof(current_velocity) == TYPE_VECTOR2:
			set("velocity", (current_velocity as Vector2) + dir * force)
	else:
		global_position += dir * min(force * 0.035, 10.0)

func _t006_update_enemy_interaction(delta) -> void:
	if not t006_base_modulate_captured:
		t006_base_modulate = modulate
		t006_base_modulate_captured = true

	if t006_stagger_timer > 0.0:
		t006_stagger_timer = max(0.0, t006_stagger_timer - delta)
	if t006_hit_react_timer > 0.0:
		t006_hit_react_timer = max(0.0, t006_hit_react_timer - delta)
	if t006_vulnerability_timer > 0.0:
		t006_vulnerability_timer = max(0.0, t006_vulnerability_timer - delta)

	if t006_stagger_timer <= 0.0 and t006_stagger_value > 0.0:
		t006_stagger_value = max(0.0, t006_stagger_value - t006_stagger_recover_rate * delta)

	_t006_apply_placeholder_modulate()

func _t006_apply_placeholder_modulate() -> void:
	if t006_stagger_timer > 0.0:
		modulate = Color(1.0, 0.86, 0.48, 1.0)
	elif t006_hit_react_timer > 0.0:
		modulate = Color(1.0, 0.72, 0.58, 1.0)
	elif t006_vulnerability_timer > 0.0:
		modulate = Color(0.95, 0.88, 1.0, 1.0)
	elif t006_base_modulate_captured:
		modulate = t006_base_modulate

func _t006_get_enemy_role_id() -> String:
	var chunks: Array[String] = [name.to_lower()]
	var possible_props: Array[String] = ["enemy_id", "enemy_type", "enemy_kind", "archetype", "display_name"]
	for prop_name: String in possible_props:
		if _t006_has_property(prop_name):
			chunks.append(str(get(prop_name)).to_lower())
	return " ".join(chunks)

func _t006_has_property(prop_name: String) -> bool:
	for prop_info: Dictionary in get_property_list():
		if str(prop_info.get("name", "")) == prop_name:
			return true
	return false

