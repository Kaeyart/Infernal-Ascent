extends Node2D

@export var show_armor: bool = true
@export var show_ultimate: bool = true

@export var bar_width: float = 54.0
@export var hp_bar_height: float = 6.0
@export var armor_bar_height: float = 4.0

@export var vertical_offset: float = -58.0

var player: Node = null
var pulse_time: float = 0.0

var current_hp: float = 0.0
var current_max_hp: float = 100.0
var current_armor: float = 0.0
var current_max_armor: float = 1.0
var current_ultimate: float = 0.0

var previous_hp: float = -1.0
var previous_armor: float = -1.0
var previous_ultimate: float = -1.0

var hp_damage_timer: float = 0.0
var hp_heal_timer: float = 0.0
var armor_damage_timer: float = 0.0
var ultimate_visible_timer: float = 0.0
var ultimate_pop_timer: float = 0.0
var ultimate_full_timer: float = 0.0
var shake_timer: float = 0.0


func _ready() -> void:
	player = get_parent()
	z_index = 100
	z_as_relative = true
	queue_redraw()


func _process(delta: float) -> void:
	pulse_time += delta

	if player == null or not is_instance_valid(player):
		player = get_parent()

	_read_values()
	_tick_reactive_timers(delta)
	queue_redraw()


func _read_values() -> void:
	if player == null:
		return

	var new_hp: float = _safe_get_float(player, "hp", 0.0)
	var new_max_hp: float = maxf(1.0, _safe_get_float(player, "max_hp", 100.0))

	var new_armor: float = _safe_get_float(player, "armor", 0.0)
	var new_max_armor: float = maxf(1.0, _safe_get_float(player, "max_armor", 1.0))

	var new_ultimate: float = _safe_get_float(player, "ultimate", 0.0)

	if previous_hp < 0.0:
		previous_hp = new_hp
		previous_armor = new_armor
		previous_ultimate = new_ultimate

		current_hp = new_hp
		current_max_hp = new_max_hp
		current_armor = new_armor
		current_max_armor = new_max_armor
		current_ultimate = new_ultimate
		return

	if new_hp < current_hp - 0.01:
		hp_damage_timer = 0.36
		shake_timer = 0.22
	elif new_hp > current_hp + 0.01:
		hp_heal_timer = 0.42

	if new_armor < current_armor - 0.01:
		armor_damage_timer = 0.30
		shake_timer = maxf(shake_timer, 0.16)

	if new_ultimate > current_ultimate + 0.01:
		ultimate_visible_timer = 1.15
		ultimate_pop_timer = 0.24

	if current_ultimate < 100.0 and new_ultimate >= 99.9:
		ultimate_visible_timer = 2.1
		ultimate_full_timer = 2.1
		ultimate_pop_timer = 0.35

	if new_ultimate < current_ultimate - 0.01:
		ultimate_visible_timer = 0.75

	previous_hp = current_hp
	previous_armor = current_armor
	previous_ultimate = current_ultimate

	current_hp = new_hp
	current_max_hp = new_max_hp
	current_armor = new_armor
	current_max_armor = new_max_armor
	current_ultimate = new_ultimate


func _tick_reactive_timers(delta: float) -> void:
	hp_damage_timer = maxf(0.0, hp_damage_timer - delta)
	hp_heal_timer = maxf(0.0, hp_heal_timer - delta)
	armor_damage_timer = maxf(0.0, armor_damage_timer - delta)
	ultimate_visible_timer = maxf(0.0, ultimate_visible_timer - delta)
	ultimate_pop_timer = maxf(0.0, ultimate_pop_timer - delta)
	ultimate_full_timer = maxf(0.0, ultimate_full_timer - delta)
	shake_timer = maxf(0.0, shake_timer - delta)


func _draw() -> void:
	if player == null:
		return

	var hp_ratio: float = clampf(current_hp / current_max_hp, 0.0, 1.0)
	var armor_ratio: float = clampf(current_armor / current_max_armor, 0.0, 1.0)
	var ultimate_ratio: float = clampf(current_ultimate / 100.0, 0.0, 1.0)

	var shake_offset := _get_shake_offset()

	_draw_hp_bar(hp_ratio, shake_offset)

	if show_armor:
		_draw_armor_bar(armor_ratio, shake_offset)

	if show_ultimate:
		_draw_ultimate_meter(ultimate_ratio)


func _get_shake_offset() -> Vector2:
	if shake_timer <= 0.0:
		return Vector2.ZERO

	var strength: float = shake_timer / 0.22
	return Vector2(
		sin(pulse_time * 92.0) * 2.0,
		sin(pulse_time * 131.0) * 1.1
	) * strength


func _draw_hp_bar(ratio: float, extra_offset: Vector2) -> void:
	var pos := Vector2(-bar_width * 0.5, vertical_offset) + extra_offset
	var size := Vector2(bar_width, hp_bar_height)

	draw_rect(
		Rect2(pos + Vector2(1, 1), size),
		Color(0.0, 0.0, 0.0, 0.55)
	)

	draw_rect(
		Rect2(pos, size),
		Color("#1a0606")
	)

	draw_rect(
		Rect2(pos, Vector2(bar_width * ratio, hp_bar_height)),
		_get_hp_color(ratio)
	)

	if hp_damage_timer > 0.0:
		var flash: float = hp_damage_timer / 0.36
		draw_rect(
			Rect2(pos - Vector2(2, 2), size + Vector2(4, 4)),
			Color(1.0, 0.10, 0.04, 0.46 * flash),
			false,
			2.0
		)

	if hp_heal_timer > 0.0:
		var heal_flash: float = hp_heal_timer / 0.42
		draw_rect(
			Rect2(pos - Vector2(2, 2), size + Vector2(4, 4)),
			Color(0.45, 1.0, 0.55, 0.36 * heal_flash),
			false,
			2.0
		)

	draw_rect(
		Rect2(pos, size),
		Color(0.95, 0.72, 0.42, 0.75),
		false,
		1.0
	)

	if ratio <= 0.28:
		var alpha: float = 0.35 + 0.35 * absf(sin(pulse_time * 7.0))
		draw_rect(
			Rect2(pos - Vector2(2, 2), size + Vector2(4, 4)),
			Color(1.0, 0.08, 0.03, alpha),
			false,
			2.0
		)


func _draw_armor_bar(ratio: float, extra_offset: Vector2) -> void:
	if ratio <= 0.0:
		return

	var armor_width := bar_width * 0.82
	var pos := Vector2(-armor_width * 0.5, vertical_offset + hp_bar_height + 3.0) + extra_offset
	var size := Vector2(armor_width, armor_bar_height)

	draw_rect(
		Rect2(pos + Vector2(1, 1), size),
		Color(0.0, 0.0, 0.0, 0.50)
	)

	draw_rect(
		Rect2(pos, size),
		Color("#071016")
	)

	draw_rect(
		Rect2(pos, Vector2(armor_width * ratio, armor_bar_height)),
		Color("#8fc9df")
	)

	if armor_damage_timer > 0.0:
		var flash: float = armor_damage_timer / 0.30
		draw_rect(
			Rect2(pos - Vector2(2, 2), size + Vector2(4, 4)),
			Color(0.65, 0.95, 1.0, 0.46 * flash),
			false,
			2.0
		)

	draw_rect(
		Rect2(pos, size),
		Color(0.80, 0.95, 1.0, 0.60),
		false,
		1.0
	)


func _draw_ultimate_meter(ratio: float) -> void:
	var alpha: float = clampf(ultimate_visible_timer / 0.28, 0.0, 1.0)

	if ultimate_visible_timer > 0.28:
		alpha = 1.0

	if ultimate_full_timer > 0.0:
		alpha = maxf(alpha, 0.82)

	if alpha <= 0.02:
		return

	var center := Vector2(-bar_width * 0.5 - 17.0, vertical_offset + 5.0)
	var base_radius := 9.0

	var pop_scale: float = 1.0
	if ultimate_pop_timer > 0.0:
		pop_scale += 0.28 * (ultimate_pop_timer / 0.24)

	var radius: float = base_radius * pop_scale

	draw_circle(center, radius, Color(0.0, 0.0, 0.0, 0.58 * alpha))
	draw_arc(center, radius, 0.0, TAU, 32, Color(0.45, 0.32, 0.18, 0.65 * alpha), 2.0)

	if ratio > 0.0:
		draw_arc(
			center,
			radius,
			-PI * 0.5,
			-PI * 0.5 + TAU * ratio,
			32,
			Color(1.0, 0.48, 0.08, alpha),
			3.0
		)

	if ratio >= 1.0:
		var pulse: float = 0.4 + 0.4 * absf(sin(pulse_time * 6.0))
		draw_arc(
			center,
			radius + 4.0,
			0.0,
			TAU,
			32,
			Color(1.0, 0.80, 0.25, pulse * alpha),
			2.0
		)
		draw_circle(center, 3.0, Color(1.0, 0.83, 0.30, alpha))

		for i in range(6):
			var angle: float = TAU * float(i) / 6.0 + pulse_time * 1.4
			var spark_pos: Vector2 = center + Vector2.RIGHT.rotated(angle) * (radius + 7.0 + sin(pulse_time * 6.0 + i) * 1.6)
			draw_circle(spark_pos, 1.5, Color(1.0, 0.58, 0.12, alpha * 0.75))
	else:
		draw_circle(center, 2.4, Color(0.36, 0.16, 0.08, alpha))


func _get_hp_color(ratio: float) -> Color:
	if ratio <= 0.28:
		return Color("#ff2b1f")

	if ratio <= 0.55:
		return Color("#df6a2a")

	return Color("#d63a2f")


func _safe_get_float(object: Object, property_name: String, fallback: float) -> float:
	if object == null:
		return fallback

	if not _object_has_property(object, property_name):
		return fallback

	var value = object.get(property_name)

	if value == null:
		return fallback

	return float(value)


func _object_has_property(object: Object, property_name: String) -> bool:
	if object == null:
		return false

	for property in object.get_property_list():
		if str(property["name"]) == property_name:
			return true

	return false
