extends Node2D

class_name IsoTestEnemy

signal died(enemy: IsoTestEnemy)
signal damaged(amount: int, remaining_health: int)

@export var max_health: int = 3
@export var move_enabled: bool = false
@export var move_speed: float = 55.0
@export var aggro_radius: float = 360.0

@export_category("Contact Damage")
@export var contact_damage_enabled: bool = true
@export var contact_damage: int = 1
@export var contact_radius: float = 34.0
@export var contact_damage_cooldown: float = 0.75
@export var show_debug_contact_radius: bool = false

@export_category("Hit Reaction")
@export var hit_flash_duration: float = 0.14
@export var knockback_enabled: bool = true
@export var light_knockback_speed: float = 145.0
@export var heavy_knockback_speed: float = 230.0
@export var knockback_duration: float = 0.10
@export var death_free_delay: float = 0.18

var health: int = 3
var is_dead: bool = false

var _hit_flash_remaining: float = 0.0
var _contact_cooldown_remaining: float = 0.0
var _knockback_remaining: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _damage_numbers: Array[Dictionary] = []
var _death_free_remaining: float = -1.0

func _ready() -> void:
	health = max_health
	add_to_group("iso_test_enemy")
	queue_redraw()

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
	elif move_enabled:
		_update_simple_chase(delta)

	_update_contact_damage()
	queue_redraw()

func _update_timers(delta: float) -> void:
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = maxf(0.0, _hit_flash_remaining - delta)
	if _contact_cooldown_remaining > 0.0:
		_contact_cooldown_remaining = maxf(0.0, _contact_cooldown_remaining - delta)

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
	if player_node.has_method("take_damage"):
		var result: Variant = player_node.call("take_damage", contact_damage)
		if result is bool:
			if result:
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
	draw_circle(Vector2(-4.0, -36.0), 1.5, Color("#f08a32"))
	draw_circle(Vector2(4.0, -36.0), 1.5, Color("#f08a32"))

	if is_dead:
		draw_line(Vector2(-18.0, -8.0), Vector2(18.0, 12.0), Color("#d06b4c"), 2.5)
		draw_line(Vector2(18.0, -8.0), Vector2(-18.0, 12.0), Color("#d06b4c"), 2.5)

	_draw_health_bar()
	_draw_damage_numbers()
	if show_debug_contact_radius:
		draw_arc(Vector2.ZERO, contact_radius, 0.0, TAU, 36, Color(1.0, 0.3, 0.2, 0.65), 1.0)

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
