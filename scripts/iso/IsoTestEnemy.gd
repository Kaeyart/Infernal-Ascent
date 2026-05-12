extends Node2D

class_name IsoTestEnemy

signal died(enemy: IsoTestEnemy)
signal damaged(amount: int, remaining_health: int)

enum EnemyState { IDLE, CHASE, WINDUP, ACTIVE, RECOVERY }

@export_enum("ash_grunt", "cinder_lunger", "ember_spitter") var enemy_type: String = "ash_grunt"
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

func _ready() -> void:
	_spawn_position = global_position
	apply_encounter_profile(enemy_type)
	health = max_health
	add_to_group("iso_test_enemy")
	queue_redraw()

func configure_for_encounter_type(profile_name: String, wave_index: int = 1) -> void:
	enemy_type = profile_name
	apply_encounter_profile(enemy_type)
	# Small per-cycle scaling without turning this into a balance problem.
	if wave_index >= 3:
		max_health += 1
		health = max_health
		attack_cooldown = maxf(0.48, attack_cooldown - 0.05)

func apply_encounter_profile(profile_name: String) -> void:
	# Default: Ash Grunt. Slow readable melee enemy.
	if profile_name == "cinder_lunger":
		enemy_type = "cinder_lunger"
		max_health = 3
		move_enabled = true
		move_speed = 70.0
		aggro_radius = 420.0
		attack_damage = 1
		attack_range = 185.0
		attack_hit_radius = 54.0
		attack_arc_degrees = 90.0
		attack_windup_duration = 0.58
		attack_active_duration = 0.20
		attack_recovery_duration = 0.72
		attack_cooldown = 1.02
		attack_player_knockback_force = 230.0
		lunge_enabled = true
		lunge_range = 230.0
		lunge_speed = 380.0
		lunge_duration = 0.20
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
		attack_windup_duration = 0.68
		attack_active_duration = 0.10
		attack_recovery_duration = 0.82
		attack_cooldown = 1.25
		attack_player_knockback_force = 155.0
		lunge_enabled = false
		projectile_enabled = true
		projectile_range = 330.0
		projectile_speed = 185.0
		projectile_radius = 13.0
		desired_spacing = 225.0
		spacing_dead_zone = 40.0
		contact_damage_enabled = false
		return
	enemy_type = "ash_grunt"
	max_health = 3
	move_enabled = true
	move_speed = 58.0
	aggro_radius = 360.0
	attack_damage = 1
	attack_range = 62.0
	attack_hit_radius = 54.0
	attack_arc_degrees = 115.0
	attack_windup_duration = 0.44
	attack_active_duration = 0.14
	attack_recovery_duration = 0.58
	attack_cooldown = 0.75
	attack_player_knockback_force = 170.0
	lunge_enabled = false
	projectile_enabled = false
	contact_damage_enabled = false

func _process(delta: float) -> void:
	_update_timers(delta)
	_update_damage_numbers(delta)

	if is_dead:
		if _death_free_remaining >= 0.0:
			_death_free_remaining -= delta
			if _death_free_remaining <= 0.0:
				queue_free()
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
	_state = EnemyState.WINDUP
	_state_timer = attack_windup_duration
	_attack_has_hit_player = false
	if to_player.length() > 0.01:
		_attack_direction = to_player.normalized()

func _start_active() -> void:
	_state = EnemyState.ACTIVE
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

func _update_chase_or_spacing(delta: float, player_2d: Node2D, to_player: Vector2, distance: float) -> void:
	if not move_enabled:
		return
	if projectile_enabled:
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
	_spawn_damage_number("SLAIN", Color("#d06b4c"))
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
	if is_dead:
		body_color = Color("#211512")
		outline_color = Color("#6f382a")
	elif _hit_flash_remaining > 0.0:
		body_color = Color("#f2d0a0")
		outline_color = Color("#ffffff")

	var body: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -32.0),
		Vector2(18.0, -8.0),
		Vector2(12.0, 18.0),
		Vector2(-12.0, 18.0),
		Vector2(-18.0, -8.0),
	])
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

	if is_dead:
		draw_line(Vector2(-18.0, -8.0), Vector2(18.0, 12.0), Color("#d06b4c"), 2.5)
		draw_line(Vector2(18.0, -8.0), Vector2(-18.0, 12.0), Color("#d06b4c"), 2.5)

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
		var danger_color: Color = Color(1.0, 0.28, 0.12, 0.20 + 0.35 * t)
		if projectile_enabled:
			draw_line(Vector2.ZERO, _attack_direction.normalized() * projectile_range, Color(1.0, 0.42, 0.12, 0.28 + 0.35 * t), 4.0)
			draw_arc(Vector2.ZERO, 24.0 + 10.0 * t, 0.0, TAU, 28, Color(1.0, 0.55, 0.20, 0.7), 2.0)
		elif lunge_enabled:
			draw_line(Vector2.ZERO, _attack_direction.normalized() * lunge_range, Color(1.0, 0.18, 0.12, 0.32 + 0.35 * t), 6.0)
			draw_circle(_attack_direction.normalized() * minf(lunge_range, 90.0), 10.0 + 6.0 * t, danger_color)
		else:
			_draw_warning_cone(attack_hit_radius, attack_arc_degrees, danger_color)
	elif _state == EnemyState.ACTIVE and not projectile_enabled:
		_draw_warning_cone(attack_hit_radius, attack_arc_degrees, Color(1.0, 0.08, 0.04, 0.48))

func _draw_warning_cone(radius: float, arc_degrees: float, color: Color) -> void:
	var facing_angle: float = _attack_direction.angle()
	var half_arc: float = deg_to_rad(arc_degrees * 0.5)
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2.ZERO)
	var steps: int = 12
	for i: int in range(steps + 1):
		var ratio: float = float(i) / float(steps)
		var angle: float = facing_angle - half_arc + (half_arc * 2.0 * ratio)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
	draw_polyline(points, Color(color.r, color.g, color.b, minf(1.0, color.a + 0.25)), 1.5)

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

func _draw_filled_ellipse(rect: Rect2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(24):
		var angle: float = TAU * float(i) / 24.0
		points.append(rect.position + rect.size * 0.5 + Vector2(cos(angle) * rect.size.x * 0.5, sin(angle) * rect.size.y * 0.5))
	draw_colored_polygon(points, color)
